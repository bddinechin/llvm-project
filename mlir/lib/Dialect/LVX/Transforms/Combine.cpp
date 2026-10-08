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
#include "mlir/Dialect/LVX/IR/LVXImmediates.h"
#include "mlir/Dialect/LVXSCF/IR/LVXSCF.h"

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

using FoldEorToNotD = FoldEorAllOnesToNot<EordOp, NotdOp>;
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
    Operation *src = op.getOperand().getDefiningOp();
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
    if (op.getResult().getType() != src->getResult(0).getType())
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
    Operation *src = op.getOperand().getDefiningOp();
    if (!src || !carriesSignExtW(src) || src->hasAttr("sx"))
      return failure();
    if (!src->hasOneUse())
      return failure();
    if (op.getResult().getType() != src->getResult(0).getType())
      return failure();
    rewriter.modifyOpInPlace(
        src, [&] { src->setAttr("sx", rewriter.getUnitAttr()); });
    rewriter.replaceOp(op, src->getResult(0));
    return success();
  }
};

/// `<op>wq(%v, splatwq(li C))` -> `<op>wq_i(%v, C)`: a lane-parallel op against
/// a constant vector, using the ISA's immediate form instead of materialising
/// and broadcasting the constant.
///
/// What this is and is not worth. The immediate form is `ALU_LITE.X` -- two
/// syllables, always, there being no narrow variant -- while `li` and `splatwq`
/// are loop-invariant and hoist. So in a loop this does not remove an
/// instruction: it trades one `issue` slot for one fewer register held across
/// the loop. That is usually a good trade, because `tiny` (4 a bundle, and
/// every ALU and LSU op takes one) is what binds a bundle rather than `issue`
/// (8), and because register pressure is a hard error in this back end. In
/// straight-line code it is a plain win, three instructions to one.
///
/// Restricted to 32-bit lanes on purpose. There a 32-bit immediate is exactly
/// one lane, which is the case measured on the ISS (`addwq $d = $s, 5` adds 5
/// to all four lanes). At 64-bit lanes the same 32-bit immediate has to be
/// extended or splatted to fill the lane -- what the `splat32` modifier is
/// for -- and at 8 and 16 bits it would have to be replicated; none of that is
/// established here, so none of it is folded.
struct FoldSplatConstantIntoImmediate : public RewritePattern {
  FoldSplatConstantIntoImmediate(MLIRContext *ctx)
      : RewritePattern(MatchAnyOpTypeTag(), /*benefit=*/1, ctx) {}

  LogicalResult matchAndRewrite(Operation *op,
                                PatternRewriter &rewriter) const override {
    if (op->getDialect() != op->getContext()->getLoadedDialect("lvx"))
      return failure();
    if (op->getNumOperands() != 2 || op->getNumResults() != 1)
      return failure();
    StringRef mnemonic = op->getName().stripDialect();
    // 32-bit lanes only (see above), and not an immediate form already.
    if (!mnemonic.ends_with("wq") || mnemonic.ends_with("_i"))
      return failure();
    // `sbf`/`fsbf` are "subtract from": the printed operand order is reversed
    // (EmitAsm's emitBinarySubtractFrom), so which side the immediate belongs
    // on is not the IR's order and this fold would silently swap the operands.
    if (mnemonic.starts_with("sbf") || mnemonic.starts_with("fsbf"))
      return failure();

    std::string immName = (mnemonic + "_i").str();
    const OpImmediate *info = immediateOf(immName);
    if (!info)
      return failure();

    // The second operand must be a splat of a materialised constant, and both
    // must be dead afterwards -- otherwise the constant stays live and this
    // adds a syllable for nothing.
    Operation *splat = op->getOperand(1).getDefiningOp();
    if (!splat || !isa<SplatwqOp>(splat) || !splat->hasOneUse())
      return failure();
    auto li = dyn_cast_or_null<LiOp>(splat->getOperand(0).getDefiningOp());
    if (!li || !li->hasOneUse())
      return failure();
    auto value = dyn_cast<IntegerAttr>(li.getValue());
    if (!value)
      return failure();
    // It has to fit some form of the immediate, or -lvx-schedule would later
    // fail to choose a format for it.
    bool fits = false;
    for (unsigned k = 0; k != info->numForms; ++k)
      fits |= valueFits(value.getValue(), info->forms[k]);
    if (!fits)
      return failure();

    OperationState state(op->getLoc(), ("lvx." + immName));
    state.addOperands(op->getOperand(0));
    state.addTypes(op->getResult(0).getType());
    state.addAttribute(info->attribute, value);
    for (NamedAttribute attr : op->getAttrs())
      if (attr.getName() != info->attribute)
        state.addAttribute(attr.getName(), attr.getValue());
    rewriter.replaceOp(op, rewriter.create(state)->getResults());
    return success();
  }
};

/// Is `v` a value this pass can prove is not negative?
///
/// The whole correctness of `FoldTaildFromZeroBase` rests on this, so it is
/// deliberately narrow and structural: the two forms a vectorized loop's
/// bound and index actually take, each non-negative by construction rather
/// than by arithmetic.
///
/// Not `ValueBoundsConstraintSet`, which would be more general: its reasoning
/// lives in external interface models that have to be registered, and when
/// they are not it answers "unknown" rather than failing -- so the fold would
/// silently stop happening depending on how the tool was assembled. A
/// structural check either matches or does not, and a lit test says which.
static bool isKnownNonNegative(Value v, unsigned depth = 0) {
  if (depth > 4) // a lower bound built from a lower bound built from...
    return false;
  // A materialised constant that is not negative.
  if (auto li = v.getDefiningOp<LiOp>())
    if (auto attr = dyn_cast_or_null<IntegerAttr>(li.getValueAttr()))
      return !attr.getValue().isNegative();
  // A loop's induction variable, if the loop starts at a non-negative bound.
  // This is why the fold lives here and not in `-convert-to-lvx`: during the
  // conversion the loop body's block is detached, so the induction variable
  // cannot be recognised as one (its block's parent operation is null).
  if (auto arg = dyn_cast<BlockArgument>(v))
    if (auto forOp =
            dyn_cast_or_null<lvx_scf::ForOp>(arg.getOwner()->getParentOp()))
      if (arg == forOp.getInductionVar())
        return isKnownNonNegative(forOp.getLowerBound(), depth + 1);
  return false;
}

/// `taild(0, max(dim - offset, 0))` -> `taild(offset, dim)`.
///
/// `taild` already takes a base -- lane *i* is active iff
/// `base + i <u bound` -- so a mask counted from zero over a subtracted bound
/// is doing by hand what the instruction does itself. Three instructions and
/// two cycles fewer per iteration, and the shape is not hypothetical: it is
/// what every masked loop tail lowers to, `-lvx-lower-vector-transfers`
/// masking an out-of-bounds transfer with `create_mask(dim - offset)` and
/// `-convert-to-lvx` turning that into `sbfd` + `maxd_i` + `li 0` + `taild`.
///
/// Sound only when **both** `dim` and `offset` are non-negative, and the
/// failure otherwise is a wrong mask rather than a crash, so the condition is
/// checked. With `n = dim - offset`:
///
///   - `dim >= 0, offset >= 0`: the clamped form gives lane *i* iff `i < n`;
///     `taild(offset, dim)` gives `offset + i <u dim`, and both being
///     non-negative the unsigned compare is the signed one, so `i < n`. The
///     same. This covers `offset > dim`, where `n` is negative: the clamp
///     makes it zero and activates nothing, and `taild` finds
///     `offset + i <u dim` false for every lane. Also the same.
///   - `offset < 0`: `n > dim`, so the clamped form activates *every* lane
///     (`taild` clears above its lane count, so a bound past the end is the
///     full mask). `taild(offset, dim)` reads `offset` as a huge unsigned and
///     activates *none*. The exact inverse.
///   - `dim < 0`: the clamped form activates nothing; `taild`'s bound is a
///     huge unsigned and it activates everything. Inverse again.
///
/// No overflow concern in the surviving case: `taild` forms `base + i` at 65
/// bits precisely so it cannot wrap into a lane that should be off.
struct FoldTaildFromZeroBase : public OpRewritePattern<TaildOp> {
  using OpRewritePattern<TaildOp>::OpRewritePattern;
  LogicalResult matchAndRewrite(TaildOp op,
                                PatternRewriter &rewriter) const override {
    // The base must be a materialised zero.
    auto base = op.getLhs().getDefiningOp<LiOp>();
    if (!base)
      return failure();
    auto baseAttr = dyn_cast_or_null<IntegerAttr>(base.getValueAttr());
    if (!baseAttr || !baseAttr.getValue().isZero())
      return failure();

    // The bound must be the clamp over a subtraction. `lvx.sbfd(a, b)` is
    // `a - b` in the dialect -- the emitter swaps the operands for the ISA's
    // "the %2 is subtracted from the %3" order -- so the dimension is the
    // left operand and the offset the right, as in the `arith.subi` it came
    // from.
    auto clamp = op.getRhs().getDefiningOp<MaxdImmOp>();
    if (!clamp)
      return failure();
    // `getSigned10()` hands back the immediate as a `TypedAttr`, so compare
    // the value and not the attribute: `getSigned10() != 0` tests the
    // attribute against a null one and is therefore always true.
    auto clampAttr = dyn_cast_or_null<IntegerAttr>(clamp.getSigned10());
    if (!clampAttr || !clampAttr.getValue().isZero())
      return failure();
    auto sub = clamp.getOperand().getDefiningOp<SbfdOp>();
    if (!sub)
      return failure();

    Value dim = sub.getLhs(), offset = sub.getRhs();
    if (!isKnownNonNegative(dim) || !isKnownNonNegative(offset))
      return rewriter.notifyMatchFailure(
          op, "cannot prove the dimension and offset are non-negative");

    rewriter.replaceOpWithNewOp<TaildOp>(op, op.getType(), op.getLanecount(),
                                         offset, dim);
    return success();
  }
};

struct LVXCombinePass
    : public lvx::impl::LVXCombinePassBase<LVXCombinePass> {
  void runOnOperation() override {
    RewritePatternSet patterns(&getContext());
    patterns.add<FoldMulAddToAddxD, FoldMulAddToAddxW,
                 DropRedundantZxwd, FoldSxwdIntoW,
                 FoldEorToNotD, FoldEorToNotW,
                 FoldSplatConstantIntoImmediate,
                 FoldTaildFromZeroBase>(&getContext());
    if (failed(applyPatternsGreedily(getOperation(), std::move(patterns))))
      signalPassFailure();
  }
};

} // namespace
