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
