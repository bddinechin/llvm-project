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

struct LVXCombinePass
    : public lvx::impl::LVXCombinePassBase<LVXCombinePass> {
  void runOnOperation() override {
    RewritePatternSet patterns(&getContext());
    patterns.add<FoldMulAddToAddxD, FoldMulAddToAddxW>(&getContext());
    if (failed(applyPatternsGreedily(getOperation(), std::move(patterns))))
      signalPassFailure();
  }
};

} // namespace
