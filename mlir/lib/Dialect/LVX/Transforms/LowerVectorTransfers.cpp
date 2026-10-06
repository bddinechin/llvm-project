//===- LowerVectorTransfers.cpp - vector.transfer_* -> load/store/bcast --===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// The vectorization stage of lvx-mlir is upstream's affine super-vectorizer;
// this pass is the glue that brings its output into the vector subset
// `-convert-to-lvx` lowers (`vector.load`/`store`/`broadcast`/`fma`). Both
// halves are upstream utilities that only exist behind the transform dialect
// (`transform.structured.hoist_redundant_vector_transfers`,
// `transform.apply_patterns.vector.lower_transfer`); a pass is what the
// one-invocation-per-stage build script wants, and what a lit test can name.
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/LVX/Transforms/Passes.h"

#include "mlir/Dialect/Arith/IR/Arith.h"

#include "mlir/Dialect/Linalg/Transforms/Hoisting.h"
#include "mlir/Dialect/Vector/Transforms/LoweringPatterns.h"
#include "mlir/Dialect/Vector/Transforms/VectorRewritePatterns.h"
#include "mlir/Dialect/Vector/Transforms/VectorTransforms.h"
#include "mlir/Transforms/GreedyPatternRewriteDriver.h"

namespace mlir {
namespace lvx {
#define GEN_PASS_DEF_LVXLOWERVECTORTRANSFERSPASS
#include "mlir/Dialect/LVX/Transforms/Passes.h.inc"
} // namespace lvx
} // namespace mlir

using namespace mlir;

namespace {

/// A masked `vector.reduction`: put the reduction's *identity* in the lanes
/// the mask clears, then reduce unmasked.
///
/// Upstream has no lowering for this. `-lower-vector-mask` covers only the
/// side-effecting maskable ops (transfer_read/write/gather), and the one
/// consumer of a masked reduction anywhere is `ConvertVectorToLLVM`, which
/// maps it to `llvm.intr.vp.reduce.*` -- a route this back end does not take.
/// So it needs one here, and it is cheap: one `blend*` ahead of the reduction
/// tree Phase 4 already builds.
///
/// It matters because this is what a *reduction* loop looks like after
/// vectorization when the trip count does not divide the vector length --
/// a dot product over a dynamic extent arrives as exactly this.
///
/// The identity values come from `arith::getIdentityValueAttr`, through a
/// mapping of `CombiningKind` onto `AtomicRMWKind`, rather than being
/// tabulated again here: the distinctions that are easy to get wrong -- the
/// 754-2008 `minnum` family against the 754-2019 `minimum` one, and the
/// finite-value variant -- are upstream's and stay there.
///
/// One caveat, inherent to padding with an identity rather than to this
/// implementation: for `add` on floats the identity is `+0.0`, so a reduction
/// whose active lanes sum to `-0.0` yields `+0.0`. Every pad-with-identity
/// scheme has it, linalg's own `SplitReduction` included.
static std::optional<arith::AtomicRMWKind>
atomicKindOf(vector::CombiningKind kind, bool isFloat) {
  using CK = vector::CombiningKind;
  using RK = arith::AtomicRMWKind;
  switch (kind) {
  case CK::ADD:     return isFloat ? RK::addf : RK::addi;
  case CK::MUL:     return isFloat ? RK::mulf : RK::muli;
  case CK::AND:     return RK::andi;
  case CK::OR:      return RK::ori;
  case CK::XOR:     return RK::xori;
  case CK::MINSI:   return RK::mins;
  case CK::MAXSI:   return RK::maxs;
  case CK::MINUI:   return RK::minu;
  case CK::MAXUI:   return RK::maxu;
  case CK::MINIMUMF: return RK::minimumf;
  case CK::MAXIMUMF: return RK::maximumf;
  case CK::MINNUMF:  return RK::minnumf;
  case CK::MAXNUMF:  return RK::maxnumf;
  }
  return std::nullopt;
}

/// `vector.reduction <k>, %v, %acc` becomes `<k>(reduction(%v), %acc)`: the
/// tree over the lanes, then one scalar op folding the accumulator in.
///
/// This fixes a **silently wrong answer**, not a missing feature.
/// `VectorReductionToLVX` never read the accumulator operand, and because
/// nothing refused it either, a reduction carrying one legalized cleanly and
/// dropped it -- the stored result was the bare tree. `-convert-to-lvx` now
/// refuses an accumulator outright so it cannot happen again, and this is
/// what removes it beforehand.
///
/// The fold is built with `vector::makeArithReduction`, so the scalar op per
/// combining kind, and its 64-against-32-bit choice, come from the existing
/// `arith` lowering rather than from a second table here. Doing it in the
/// vector dialect is the whole point: a fold inside the conversion would have
/// to pick the mnemonic itself, and for `min`/`max` on lanes narrower than a
/// register that is not simply the 64-bit op -- the reduced register's upper
/// bits hold a copy of the answer, not a sign extension.
struct ReductionAccumulatorToArith
    : public OpRewritePattern<vector::ReductionOp> {
  using OpRewritePattern::OpRewritePattern;
  LogicalResult matchAndRewrite(vector::ReductionOp op,
                                PatternRewriter &rewriter) const override {
    Value acc = op.getAcc();
    if (!acc)
      return rewriter.notifyMatchFailure(op, "no accumulator");
    Location loc = op.getLoc();
    // The same kind and fastmath, minus the accumulator; the replacement has
    // none, so this pattern does not re-fire on it.
    Value tree = rewriter.create<vector::ReductionOp>(
        loc, op.getKind(), op.getVector(), op.getFastmath());
    Value folded = vector::makeArithReduction(rewriter, loc, op.getKind(),
                                              tree, acc, op.getFastmathAttr());
    rewriter.replaceOp(op, folded);
    return success();
  }
};

struct MaskedReductionToSelect : public OpRewritePattern<vector::MaskOp> {
  using OpRewritePattern::OpRewritePattern;
  LogicalResult matchAndRewrite(vector::MaskOp maskOp,
                                PatternRewriter &rewriter) const override {
    if (maskOp.hasPassthru())
      return rewriter.notifyMatchFailure(maskOp, "passthru on a reduction");
    auto red = dyn_cast_or_null<vector::ReductionOp>(maskOp.getMaskableOp());
    if (!red)
      return rewriter.notifyMatchFailure(maskOp, "not a masked reduction");

    auto vecTy = cast<VectorType>(red.getVector().getType());
    Type elemTy = vecTy.getElementType();
    std::optional<arith::AtomicRMWKind> rmw =
        atomicKindOf(red.getKind(), isa<FloatType>(elemTy));
    if (!rmw)
      return rewriter.notifyMatchFailure(maskOp, "no identity for this kind");
    TypedAttr identity = arith::getIdentityValueAttr(
        *rmw, elemTy, rewriter, red.getLoc(), /*useOnlyFiniteValue=*/false);
    if (!identity)
      return rewriter.notifyMatchFailure(maskOp, "no identity value");

    Location loc = maskOp.getLoc();
    Value pad = rewriter.create<arith::ConstantOp>(
        loc, vecTy, DenseElementsAttr::get(vecTy, identity));
    Value selected = rewriter.create<arith::SelectOp>(
        loc, maskOp.getMask(), red.getVector(), pad);
    // The accumulator, if any, is outside the mask's reach and carries over
    // untouched: it is not a lane.
    arith::FastMathFlags fmf = red.getFastmath();
    if (Value acc = red.getAcc())
      rewriter.replaceOpWithNewOp<vector::ReductionOp>(
          maskOp, red.getKind(), selected, acc, fmf);
    else
      rewriter.replaceOpWithNewOp<vector::ReductionOp>(
          maskOp, red.getKind(), selected, fmf);
    return success();
  }
};

/// `vector.load %m[...] : vector<T>` (0-d, what a transfer_read of a scalar
/// broadcast operand reduces to) -> `memref.load` + `vector.broadcast` to
/// the 0-d vector. Upstream only lowers a 0-d transfer_read that feeds a
/// `vector.extract`; ours feeds a `vector.broadcast`, and the broadcast of
/// this broadcast folds into one (`BroadcastFolder`), leaving the scalar
/// load and the wide broadcast `-convert-to-lvx` turns into `ld`+`splatwq`.
struct ZeroDimLoadToScalar : public OpRewritePattern<vector::LoadOp> {
  using OpRewritePattern::OpRewritePattern;
  LogicalResult matchAndRewrite(vector::LoadOp op,
                                PatternRewriter &rewriter) const override {
    VectorType vecTy = op.getVectorType();
    if (vecTy.getRank() != 0)
      return failure();
    Value scalar = rewriter.create<memref::LoadOp>(
        op.getLoc(), op.getBase(), op.getIndices(), op.getNontemporal());
    rewriter.replaceOpWithNewOp<vector::BroadcastOp>(op, vecTy, scalar);
    return success();
  }
};

/// The widest vector shape an LVX register tuple holds: 256 bits, one
/// dimension. A `!lvx.quad` is four 64-bit units, so `vector<8xf32>` and
/// `vector<4xi64>` are the largest that have a type at all -- above that, and
/// at any rank above one, the type converter has nothing to map the vector to
/// and every op on it fails to legalize, starting at the load.
///
/// So this answers, for each op, the shape to cut it down to: the last
/// dimension capped at what fits, every leading dimension to one. A 2-D
/// `vector<4x4xf32>` becomes four `vector<1x4xf32>`, which
/// `populateCastAwayVectorLeadingOneDimPatterns` then flattens to
/// `vector<4xf32>`; a `vector<16xf32>` becomes two `vector<8xf32>`.
///
/// `std::nullopt` aborts the unrolling for that op, which is what an op that
/// already fits wants -- there is nothing to cut.
static constexpr unsigned kNativeBits = 256;

static std::optional<SmallVector<int64_t>> lvxNativeShape(Operation *op) {
  auto unrollable = dyn_cast<VectorUnrollOpInterface>(op);
  if (!unrollable)
    return std::nullopt;
  std::optional<SmallVector<int64_t>> shape = unrollable.getShapeForUnroll();
  if (!shape || shape->empty())
    return std::nullopt;

  // The element width, from whichever vector the op carries.
  VectorType vecTy;
  for (Value v : op->getResults())
    if (auto t = dyn_cast<VectorType>(v.getType())) { vecTy = t; break; }
  if (!vecTy)
    for (Value v : op->getOperands())
      if (auto t = dyn_cast<VectorType>(v.getType())) { vecTy = t; break; }
  if (!vecTy || !vecTy.getElementType().isIntOrFloat())
    return std::nullopt;
  unsigned elemBits = vecTy.getElementTypeBitWidth();
  if (!elemBits)
    return std::nullopt;
  int64_t lanes = kNativeBits / elemBits;

  SmallVector<int64_t> native(*shape);
  for (size_t i = 0; i + 1 < native.size(); ++i)
    native[i] = 1;
  native.back() = std::min(native.back(), lanes);
  if (native == *shape)
    return std::nullopt; // already a shape the register file holds
  return native;
}

struct LVXLowerVectorTransfersPass
    : public lvx::impl::LVXLowerVectorTransfersPassBase<
          LVXLowerVectorTransfersPass> {
  void runOnOperation() override {
    func::FuncOp func = getOperation();

    // 1. The accumulator: a transfer_read/transfer_write pair on the same
    // loop-invariant address becomes an scf.for iter_arg. Before the
    // transfers are lowered, because the hoister only knows transfers.
    linalg::hoistRedundantVectorTransfers(func);

    // 2. What remains are per-iteration transfers. Three pattern sets, by
    // benefit: strip broadcast dimensions off the permutation map first
    // (a rank-reduced transfer plus vector.broadcast), lower a 0-d read
    // that feeds an extract to a scalar memref.load, and lower the
    // in-bounds identity transfers that are left into vector.load/store;
    // then the 0-d vector.load that leaves behind, and the broadcast chain.
    // 1b. `vector.contract` and `vector.multi_reduction`: the reduced shapes,
    // which upstream emits for a dot product or a matmul vectorised along k
    // and which nothing here can lower directly -- the type converter has no
    // register tuple for a 2-D vector.
    //
    // `Dot` is the strategy to want: it rewrites a contraction into
    // `vector.extract` + `vector.reduction` + `vector.insert`, every one of
    // which already lowers (Phase 3 for the lane ops, Phase 4 for the
    // reduction tree). `OuterProduct` would leave `vector.outerproduct` on a
    // 2-D vector, and `Matmul` a `vector.shape_cast` to a linearised form on
    // the way to `llvm.matrix.multiply`, which this back end does not go
    // through. `InnerReduction` for the multi-reduction, so the reduced
    // dimension ends up innermost where a 1-D `vector.reduction` can take it.
    //
    // Done in its own pattern application, before the transfers: a contraction
    // decomposes into extracts and inserts on the *vectors*, and those want to
    // be in place before anything rewrites how the vectors are read.
    {
      RewritePatternSet contractions(&getContext());
      vector::populateVectorReductionToContractPatterns(contractions);
      vector::populateVectorContractLoweringPatterns(
          contractions, vector::VectorContractLowering::Dot);
      // The multi-reduction lowering is three stages upstream, and all three
      // are needed to reach a 1-D `vector.reduction`: Reorder moves the
      // reduced dimensions innermost, Flattening collapses what is left to
      // two, Unrolling turns a 2-D reduction into per-row
      // `vector.reduction`s (`[TwoDimMultiReductionToReduction]`).
      auto mrOpt = vector::VectorMultiReductionLowering::InnerReduction;
      vector::populateVectorMultiReductionReorderPatterns(contractions, mrOpt);
      vector::populateVectorMultiReductionFlatteningPatterns(contractions,
                                                            mrOpt);
      vector::populateVectorMultiReductionUnrollingPatterns(contractions,
                                                           mrOpt);
      if (failed(applyPatternsGreedily(func, std::move(contractions))))
        return signalPassFailure();
    }

    // 1c. Cut every vector down to a shape a register tuple holds: at most
    // 256 bits, one dimension.  This is what lets a contraction's 2-D operand
    // be extracted from at all, and what an oversized 1-D vector needs --
    // `vector<16xf32>` has no type here, so every op on it fails to legalize.
    // Both are the same defect, a shape the register file cannot hold.
    //
    // Cast-away-leading-one-dims comes with it: unrolling a 2-D vector yields
    // `vector<1xN>` pieces, and it is that pattern set which flattens them to
    // the `vector<N>` the rest of the back end speaks.
    {
      RewritePatternSet shapes(&getContext());
      vector::populateVectorUnrollPatterns(
          shapes, vector::UnrollVectorOptions().setNativeShapeFn(
                      lvxNativeShape));
      vector::populateCastAwayVectorLeadingOneDimPatterns(shapes);
      if (failed(applyPatternsGreedily(func, std::move(shapes))))
        return signalPassFailure();
    }

    // 1d. `vector.mask`, the region wrapper, becomes a mask *operand* on the
    // op it wraps -- which is the form this back end already takes:
    // `lvx.masked_load`/`masked_store` carry their mask as an operand, and a
    // masked `vector.transfer_read`/`write` is what the stage below turns
    // into `vector.maskedload`/`maskedstore`.
    //
    // This is the shape that matters for vectorized code: `linalg`
    // vectorization expresses a conditional as `vector.mask` and never as a
    // branch (docs/IfConversion.md, "Reachability"), so a loop whose trip
    // count does not divide the vector length arrives here wrapped.
    //
    // After the unrolling above, deliberately. The unrolling patterns
    // understand masked ops and re-wrap each piece they produce, so splitting
    // an oversized masked transfer has to happen while the wrapper is still
    // there; unwrapping first would leave the pieces unmasked. Before the
    // transfer lowering, equally deliberately: that stage reads the mask as
    // an operand and has nothing to say about a region.
    //
    // Upstream's `-lower-vector-mask` is these same two populates, so running
    // it separately is equivalent -- it lives here so the bridge is one pass.
    {
      RewritePatternSet masks(&getContext());
      vector::populateVectorMaskLoweringPatternsForSideEffectingOps(masks);
      vector::MaskOp::getCanonicalizationPatterns(masks, &getContext());
      // Upstream's set stops at the side-effecting ops; a masked reduction
      // needs the identity in its cleared lanes, which is ours.
      masks.add<MaskedReductionToSelect>(&getContext());
      // And the accumulator the conversion refuses -- after the mask pattern,
      // which preserves it, and in the same application so either order of
      // discovery converges.
      masks.add<ReductionAccumulatorToArith>(&getContext());
      if (failed(applyPatternsGreedily(func, std::move(masks))))
        return signalPassFailure();
    }

    RewritePatternSet patterns(&getContext());
    vector::populateVectorTransferPermutationMapLoweringPatterns(patterns,
                                                                 /*benefit=*/3);
    vector::populateScalarVectorTransferLoweringPatterns(
        patterns, /*benefit=*/2, /*allowMultipleUses=*/true);
    vector::populateVectorTransferLoweringPatterns(patterns,
                                                   /*maxTransferRank=*/1);
    patterns.add<ZeroDimLoadToScalar>(&getContext());
    vector::BroadcastOp::getCanonicalizationPatterns(patterns, &getContext());
    if (failed(applyPatternsGreedily(func, std::move(patterns))))
      signalPassFailure();
  }
};

} // namespace
