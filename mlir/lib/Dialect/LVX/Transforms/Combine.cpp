//===- Combine.cpp - Peephole-combine lvx operations ---------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// See lvx-mlir/docs/InstructionSelection.md. `-convert-to-lvx` is a
// legalizer: it visits each illegal op once and never revisits one whose
// operands changed, so it structurally cannot peephole. This pass is the
// greedy fixed-point driver that can, and it only ever rewrites lvx to lvx,
// so it cannot produce illegal IR.
//
// Patterns are hand-written C++ rather than DRR for now. DRR would be the
// tidier long-term home (and is what the design doc proposes), but matching
// a constant *attribute* through `lvx.li` is the fiddly part either way, and
// C++ keeps the prototype's moving parts down to one file.
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/LVX/Transforms/Passes.h"

#include "mlir/IR/PatternMatch.h"
#include "mlir/Transforms/GreedyPatternRewriteDriver.h"

namespace mlir {
namespace lvx {
#define GEN_PASS_DEF_LVXCOMBINEPASS
#include "mlir/Dialect/LVX/Transforms/Passes.h.inc"
} // namespace lvx
} // namespace mlir

using namespace mlir;
using namespace mlir::lvx;

namespace {

/// If `v` is `lvx.li <constant>` with a positive power-of-two integer value
/// in [2, 64], returns that value; otherwise nullopt. The range is the
/// ADDX family's: scales 2, 4, 8, 16, 32, 64 (shifts 1..6).
static std::optional<unsigned> matchAddxScale(Value v) {
  auto li = v.getDefiningOp<LiOp>();
  if (!li)
    return std::nullopt;
  auto intAttr = dyn_cast<IntegerAttr>(li.getValue());
  if (!intAttr)
    return std::nullopt;
  APInt value = intAttr.getValue();
  // Guard the width first: getZExtValue() asserts above 64 bits.
  if (value.getActiveBits() > 7 || !value.isPowerOf2())
    return std::nullopt;
  unsigned scale = value.getZExtValue();
  if (scale < 2 || scale > 64)
    return std::nullopt;
  return scale;
}

/// `addd(muld(x, 2^n), b)` -> `addx<2^n>d(x, b)`, and the `w` equivalent.
///
/// The multiply must have exactly one use. Otherwise the `muld` stays live
/// for its other users and folding it here duplicates the work rather than
/// removing it -- a bigger instruction count, not a smaller one.
///
/// Operand order matters and is not symmetric: real `addx<N>d $rW = $rZ,
/// $rY` computes `rY + (rZ << log2(N))`, so the shifted value is $lhs and
/// the addend is $rhs.
template <typename AddOp, typename MulOp, typename... AddxOps>
struct FoldMulAddToAddx : public OpRewritePattern<AddOp> {
  using OpRewritePattern<AddOp>::OpRewritePattern;

  LogicalResult matchAndRewrite(AddOp op,
                                PatternRewriter &rewriter) const override {
    // `addd` is commutative, so the multiply may be on either side.
    for (unsigned i = 0; i < 2; ++i) {
      Value maybeMul = op->getOperand(i);
      Value addend = op->getOperand(1 - i);
      auto mul = maybeMul.getDefiningOp<MulOp>();
      if (!mul || !mul->hasOneUse())
        continue;
      // The constant may itself be on either side of the multiply.
      for (unsigned j = 0; j < 2; ++j) {
        std::optional<unsigned> scale = matchAddxScale(mul->getOperand(j));
        if (!scale)
          continue;
        Value shifted = mul->getOperand(1 - j);
        if (failed(build(rewriter, op, *scale, shifted, addend)))
          return failure();
        return success();
      }
    }
    return failure();
  }

private:
  /// Picks the AddxOp matching `scale` from the parameter pack, in the
  /// order 2, 4, 8, 16, 32, 64.
  static LogicalResult build(PatternRewriter &rewriter, AddOp op,
                             unsigned scale, Value shifted, Value addend) {
    static constexpr unsigned kScales[] = {2, 4, 8, 16, 32, 64};
    unsigned idx = 0;
    for (unsigned i = 0; i < 6; ++i)
      if (kScales[i] == scale)
        idx = i;
    Type ty = op.getResult().getType();
    Value repl;
    unsigned k = 0;
    // Fold over the pack: instantiate the one whose index matches.
    (void)std::initializer_list<int>{
        (k++ == idx ? (repl = rewriter.create<AddxOps>(op.getLoc(), ty,
                                                       shifted, addend),
                       0)
                    : 0)...};
    if (!repl)
      return failure();
    rewriter.replaceOp(op, repl);
    return success();
  }
};

using FoldMulAddToAddxD =
    FoldMulAddToAddx<AdddOp, MuldOp, Addx2dOp, Addx4dOp, Addx8dOp, Addx16dOp,
                     Addx32dOp, Addx64dOp>;
using FoldMulAddToAddxW =
    FoldMulAddToAddx<AddwOp, MulwOp, Addx2wOp, Addx4wOp, Addx8wOp, Addx16wOp,
                     Addx32wOp, Addx64wOp>;

/// The 32-bit ALU ops that carry the real `signextw` modifier. Spelled out
/// rather than probed, because a unit attribute is *absent* when false --
/// `hasAttr("sx")` cannot distinguish "a w op set to zero-extend" from "not
/// a w op at all".
///
/// The ALU_BWRW unary ops joined this list on 2026-08-05. That format
/// reserved the `signextw` encoding bit but never wired it into its operand
/// list, so `notw.sx` was unencodable and the real assembler rejected it.
/// Fixed in lvx-mds' Format.yml, regenerated, and confirmed against the
/// rebuilt assembler before being relied on here.
static bool carriesSignExtW(Operation *op) {
  return isa<AddwOp, SbfwOp, MulwOp, AndwOp, IorwOp, EorwOp, SllwOp, SrawOp,
             SrlwOp, Addx2wOp, Addx4wOp, Addx8wOp, Addx16wOp, Addx32wOp,
             Addx64wOp,
             // ALU_BWRW, unary.
             NotwOp, NegwOp, AbswOp, ClzwOp, CtzwOp, CbswOp, ClswOp>(op);
}

/// `eor(x, -1)` -> `not(x)`.
///
/// Two instructions become one, and the `lvx.li -1` usually dies with them.
/// More to the point it is the only thing that produces `lvx.notw`/`notd`:
/// MLIR spells bitwise complement as `arith.xori %x, -1`, so without this
/// the not instructions are unreachable from any input.
template <typename EorOp, typename NotOp>
struct FoldEorAllOnesToNot : public OpRewritePattern<EorOp> {
  using OpRewritePattern<EorOp>::OpRewritePattern;
  LogicalResult matchAndRewrite(EorOp op,
                                PatternRewriter &rewriter) const override {
    // xor is commutative, so the constant may be on either side.
    for (unsigned i = 0; i < 2; ++i) {
      auto li = op->getOperand(i).template getDefiningOp<LiOp>();
      if (!li)
        continue;
      auto attr = dyn_cast<IntegerAttr>(li.getValue());
      if (!attr || !attr.getValue().isAllOnes())
        continue;
      auto notOp = rewriter.replaceOpWithNewOp<NotOp>(
          op, op.getResult().getType(), op->getOperand(1 - i));
      // Carry the signextw modifier across. FoldSxwdIntoW may already have
      // set it on the eor, and the two-operand builder does not copy
      // attributes -- dropping it here would silently turn a required
      // sign-extension into a zero-extension, i.e. a wrong number rather
      // than a failure. Only the 32-bit ops have the attribute at all.
      if (op->hasAttr("sx"))
        notOp->setAttr("sx", rewriter.getUnitAttr());
      return success();
    }
    return failure();
  }
};

using FoldEorToNotD = FoldEorAllOnesToNot<EorddOp, NotdOp>;
using FoldEorToNotW = FoldEorAllOnesToNot<EorwOp, NotwOp>;

/// `zxwd(wop)` -> `wop`.
///
/// Not a fold so much as a deletion: the bare 32-bit form *already*
/// zero-extends its result into the 64-bit register (Description.yml,
/// signextw members `[ ., .SX ]`, where `.` is Zero Extend), so an explicit
/// zero-extension of it is redundant.
///
/// Safe regardless of how many users `wop` has -- it is not modified, and
/// its result already is the zero-extended value.
struct DropRedundantZxwd : public OpRewritePattern<ZxwdOp> {
  using OpRewritePattern::OpRewritePattern;
  LogicalResult matchAndRewrite(ZxwdOp op,
                                PatternRewriter &rewriter) const override {
    Operation *src = op.getIn().getDefiningOp();
    if (!src || !carriesSignExtW(src))
      return failure();
    // If it is set to sign-extend, the zxwd is doing real work.
    if (src->hasAttr("sx"))
      return failure();
    // The extend's users take the producer's value directly, so the two
    // must agree on type. Pre-allocation -- where this pass runs -- every
    // value is the same unpinned `!lvx.reg`, so this is not a restriction
    // in practice; it stops the pattern from forging invalid IR if it is
    // ever run somewhere else.
    if (op.getOut().getType() != src->getResult(0).getType())
      return failure();
    rewriter.replaceOp(op, src->getResult(0));
    return success();
  }
};

/// `sxwd(wop)` -> `wop.sx`, two instructions to one.
///
/// Unlike the zxwd case this *mutates* `wop`, changing the value every user
/// of it sees, so it requires the extend to be its only use.
struct FoldSxwdIntoW : public OpRewritePattern<SxwdOp> {
  using OpRewritePattern::OpRewritePattern;
  LogicalResult matchAndRewrite(SxwdOp op,
                                PatternRewriter &rewriter) const override {
    Operation *src = op.getIn().getDefiningOp();
    if (!src || !carriesSignExtW(src) || src->hasAttr("sx"))
      return failure();
    if (!src->hasOneUse())
      return failure();
    if (op.getOut().getType() != src->getResult(0).getType())
      return failure();
    rewriter.modifyOpInPlace(
        src, [&] { src->setAttr("sx", rewriter.getUnitAttr()); });
    rewriter.replaceOp(op, src->getResult(0));
    return success();
  }
};

struct LVXCombinePass
    : public lvx::impl::LVXCombinePassBase<LVXCombinePass> {
  void runOnOperation() override {
    RewritePatternSet patterns(&getContext());
    patterns.add<FoldMulAddToAddxD, FoldMulAddToAddxW,
                 DropRedundantZxwd, FoldSxwdIntoW,
                 FoldEorToNotD, FoldEorToNotW>(&getContext());
    if (failed(applyPatternsGreedily(getOperation(), std::move(patterns))))
      signalPassFailure();
  }
};

} // namespace
