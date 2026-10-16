//===- SCFToCF.cpp - Lower lvx_scf.for to lvx_cf, post-allocation --------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// See lvx-mlir/docs/AssemblyEmission.md, "lvx-scf-to-cf: lowering after
// allocation". Deliberately runs *after* -lvx-allocate-registers (real
// assembly has no structured loops, but the allocator needs lvx_scf.for
// intact for its loop-carried coalescing); the two brand-new values this
// pass introduces (the loop-test comparison and the induction-variable
// increment) reuse Step 3's reserved spill-scratch registers rather than
// going through any allocation decision of their own.
//
// Eligible loops (constant step 1, no nested lvx_scf.for) instead lower to
// a hardware zero-overhead loop (LOOPDO) -- see lvx-mlir/docs/HardwareLoops.md.
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/LVX/Transforms/Passes.h"
#include "mlir/Dialect/LVX/Transforms/IdentityCopies.h"
#include "mlir/Dialect/LVX/Transforms/ScratchRegisters.h"

#include "mlir/Dialect/LVXCF/IR/LVXCF.h"
#include "mlir/Dialect/LVXFunc/IR/LVXFunc.h"
#include "mlir/Dialect/LVXSCF/IR/LVXSCF.h"
#include "mlir/IR/Builders.h"
#include "llvm/Support/MathExtras.h"

namespace mlir {
namespace lvx {
#define GEN_PASS_DEF_LVXSCFTOCFPASS
#include "mlir/Dialect/LVX/Transforms/Passes.h.inc"
} // namespace lvx
} // namespace mlir

using namespace mlir;
using namespace mlir::lvx;

namespace {

// The shared reserved scratch register (ScratchRegisters.h,
// lvx-mlir/docs/RegisterAllocation.md "Reserved scratch registers") -- safe to
// reuse here because it is held out of the general allocation pool, so
// nothing else in the function is ever resident in it. Taken from the
// shared header rather than respelled: this pass runs *after* allocation,
// so naming a register the allocator can hand out silently clobbers it.
static constexpr Register kLoopTestScratchReg = kScratchReg;

// See lvx-mlir/docs/HardwareLoops.md, "Lowering". A leaf loop (no nested
// lvx_scf.for) whose step is a constant power of two is eligible, and the
// step is what the caller needs back; everything else keeps the branch-based
// lowering below.
//
// Step 1 was the only case until 2026-10-16, and the restriction was costing
// the vectorised loops twice over. A `VEC=4` loop has step 4, so `gemm`'s and
// `vtail`'s kernels were branch loops: they paid a `goto` of their own, and
// they paid it on the critical path, because a branch loop's carried value is
// read by the back branch at relative cycle 1 where a store reads its data at
// 2. That is the whole of the one-cycle regression software pipelining showed
// on all three of them (docs/SoftwarePipelining.md §11) -- pipelining moves
// the store into the next trip and leaves the branch as the only consumer.
// A power of two is the limit because the trip count is a division: anything
// else needs a real divide where this needs an add and a shift.
static std::optional<int64_t> hardwareLoopStep(lvx_scf::ForOp forOp,
                                               Block *body) {
  auto stepLi = forOp.getStep().getDefiningOp<LiOp>();
  if (!stepLi)
    return std::nullopt;
  auto stepAttr = dyn_cast<IntegerAttr>(stepLi.getValue());
  if (!stepAttr)
    return std::nullopt;
  int64_t step = stepAttr.getValue().getSExtValue();
  if (step <= 0 || !llvm::isPowerOf2_64(step))
    return std::nullopt;
  bool hasNestedFor = false;
  body->walk([&](lvx_scf::ForOp) { hasNestedFor = true; });
  if (hasNestedFor)
    return std::nullopt;
  return step;
}

// See lvx-mlir/docs/HardwareLoops.md. `%next_iv`'s result is never read by
// anything else in the IR -- its correctness comes entirely from being
// pinned to the exact same register as `%iv` itself (a real hardware loop
// has no mechanism to pass values into its own next iteration; the
// physical register simply persists, so the increment must overwrite it
// in place). Same "register-pinned op has a load-bearing effect invisible
// to SSA use-count" caveat as the prologue/epilogue's SP restore
// (lvx-mlir/docs/RegisterAllocation.md) -- fine today since nothing runs DCE.
static void lowerForHardware(lvx_scf::ForOp forOp, int64_t step) {
  Location loc = forOp.getLoc();
  MLIRContext *ctx = forOp.getContext();
  Block *currentBlock = forOp->getBlock();
  Block *body = forOp.getBody();
  auto yieldOp = cast<lvx_scf::YieldOp>(body->getTerminator());

  Block *remainder = currentBlock->splitBlock(Block::iterator(forOp));
  unsigned numResults = forOp.getNumResults();
  SmallVector<Value> exitArgs;
  for (unsigned i = 0; i < numResults; ++i)
    exitArgs.push_back(remainder->addArgument(forOp.getResultTypes()[i], loc));
  for (unsigned i = 0; i < numResults; ++i)
    forOp.getResult(i).replaceAllUsesWith(exitArgs[i]);

  Region *parentRegion = currentBlock->getParent();
  parentRegion->getBlocks().splice(remainder->getIterator(),
                                   forOp.getRegion().getBlocks());

  Type indVarTy = body->getArgument(0).getType();
  Type tripTy = RegisterType::get(ctx, kLoopTestScratchReg);

  OpBuilder builder(ctx);
  builder.setInsertionPointToEnd(currentBlock);
  // LOOPDO counts *trips*, not induction values, so the count is
  // ceil((ub - lb) / step) -- which for the power-of-two step
  // `hardwareLoopStep` allows is `(ub - lb + step - 1) >> log2(step)`, an add
  // and a shift. Every intermediate lands in the same reserved scratch
  // register: this pass runs after allocation, so there is no other register
  // to use, and the chain is three ops reading and writing one unit, which is
  // what the scheduler's dependence edges are for.
  //
  // The shift is `srsd`, "shift right symmetric", which biases a negative
  // value by `2^k - 1` so the division rounds toward zero. `srad` rounds
  // toward minus infinity and would give a count one too large for a
  // negative difference; `srld` would make it enormous. `ub >= lb` is
  // assumed either way, as it was for the step-1 form -- LOOPDO
  // zero-extends `trip`, so a negative count was never going to work -- and
  // `srsd` is simply the least wrong of the three when it does not hold.
  // `ub == lb` gives zero, which LOOPDO skips: it is zero-safe, unlike
  // KVX's (docs/SoftwarePipelining.md §6).
  Value trip = builder.create<SbfdOp>(loc, tripTy, forOp.getUpperBound(),
                                      forOp.getLowerBound());
  if (step != 1) {
    auto i64 = builder.getI64Type();
    trip = builder.create<AdddImmOp>(
        loc, tripTy, trip, IntegerAttr::get(i64, step - 1));
    trip = builder.create<SrsdImmOp>(
        loc, tripTy, trip, IntegerAttr::get(i64, llvm::Log2_64(step)));
  }
  Value ivInit = builder.create<MvOp>(loc, indVarTy, forOp.getLowerBound());
  SmallVector<Value> bodyOperands{ivInit};
  llvm::append_range(bodyOperands, forOp.getInitArgs());
  SmallVector<Value> exitOperands(forOp.getInitArgs());
  builder.create<lvx_cf::LoopdoOp>(loc, trip, body, bodyOperands, remainder,
                                   exitOperands);

  // Body end: increment iv in place (same register, see comment above),
  // then terminate with the exit edge.
  builder.setInsertionPoint(yieldOp);
  Value iv = body->getArgument(0);
  builder.create<AdddOp>(loc, iv.getType(), iv, forOp.getStep());
  // lvx_cf.loopend, not lvx_cf.br: same edge, same forwarded operands, but
  // -lvx-emit-asm prints only a comment for it. A real `goto` here would
  // override LOOPDO's implicit back-edge and run the body exactly once.
  builder.create<lvx_cf::LoopendOp>(loc, remainder,
                                    SmallVector<Value>(yieldOp.getResults()));
  yieldOp.erase();

  forOp.erase();
}

static void lowerForBranch(lvx_scf::ForOp forOp) {
  Location loc = forOp.getLoc();
  MLIRContext *ctx = forOp.getContext();
  Block *currentBlock = forOp->getBlock();
  Block *body = forOp.getBody();
  auto yieldOp = cast<lvx_scf::YieldOp>(body->getTerminator());

  Block *remainder = currentBlock->splitBlock(Block::iterator(forOp));
  unsigned numResults = forOp.getNumResults();
  SmallVector<Value> exitArgs;
  for (unsigned i = 0; i < numResults; ++i)
    exitArgs.push_back(remainder->addArgument(forOp.getResultTypes()[i], loc));
  for (unsigned i = 0; i < numResults; ++i)
    forOp.getResult(i).replaceAllUsesWith(exitArgs[i]);

  // Move the existing body block into the parent region, right before
  // `remainder`; it keeps its own block arguments (iv, iter_args)
  // untouched, so nothing inside it needs rewiring.
  Region *parentRegion = currentBlock->getParent();
  parentRegion->getBlocks().splice(remainder->getIterator(),
                                   forOp.getRegion().getBlocks());

  // The induction variable's *inside-the-body* register (`indVarTy`) is
  // the canonical one -- header's matching argument must use it too, since
  // header branches directly into body with no operand-passing mechanism
  // at the real-assembly level (see checkBranchOperands in EmitAsm.cpp).
  // Unlike the iter_arg channel (deliberately coalesced across
  // initArg/bodyIterArg/yieldOperand/result by Step 2/3), the lower bound
  // feeding the *first* iteration has no such guarantee -- it's an
  // ordinary, independently-allocated item that may have landed on a
  // different register by sheer allocation order. An explicit `lvx.mv`
  // copy-in on the entry edge closes that gap unconditionally (cheap even
  // when it happens to be a same-register copy).
  // Note: `forOp.getInductionVar()`/`getBody()` resolve via `forOp`'s own
  // region, which the splice above just emptied -- use the captured
  // `body` pointer directly instead.
  Type indVarTy = body->getArgument(0).getType();
  OpBuilder builder(ctx);
  SmallVector<Type> headerArgTypes{indVarTy};
  SmallVector<Location> headerArgLocs{loc};
  for (Value iterArg : forOp.getInitArgs()) {
    headerArgTypes.push_back(iterArg.getType());
    headerArgLocs.push_back(loc);
  }
  Block *header = builder.createBlock(body, headerArgTypes, headerArgLocs);

  // Entry: currentBlock -> header(lb-copied-into-iv-reg, init...).
  builder.setInsertionPointToEnd(currentBlock);
  Value lbCopy = builder.create<MvOp>(loc, indVarTy, forOp.getLowerBound());
  SmallVector<Value> entryArgs{lbCopy};
  llvm::append_range(entryArgs, forOp.getInitArgs());
  builder.create<lvx_cf::BranchOp>(loc, header, entryArgs);

  // Header: test iv < ub; branch into body or out to remainder(acc...).
  builder.setInsertionPointToEnd(header);
  Value iv = header->getArgument(0);
  Type testTy = RegisterType::get(ctx, kLoopTestScratchReg);
  Value test = builder.create<CompdOp>(loc, testTy, IntComp::lt, iv,
                                       forOp.getUpperBound());
  SmallVector<Value> bodyOperands(header->getArguments());
  SmallVector<Value> exitOperands(header->getArguments().drop_front());
  builder.create<lvx_cf::CondBranchOp>(loc, test, BcuCond::wnez, body,
                                       bodyOperands, remainder, exitOperands);

  // Body end: replace `lvx_scf.yield` with iv-increment + branch back to
  // header(iv + step, yielded...).
  builder.setInsertionPoint(yieldOp);
  Value nextIv = builder.create<AdddOp>(loc, iv.getType(), iv, forOp.getStep());
  SmallVector<Value> backArgs{nextIv};
  llvm::append_range(backArgs, yieldOp.getResults());
  builder.create<lvx_cf::BranchOp>(loc, header, backArgs);
  yieldOp.erase();

  forOp.erase();
}

static void lowerFor(lvx_scf::ForOp forOp) {
  if (std::optional<int64_t> step = hardwareLoopStep(forOp, forOp.getBody()))
    lowerForHardware(forOp, *step);
  else
    lowerForBranch(forOp);
}

struct LVXSCFToCFPass
    : public lvx::impl::LVXSCFToCFPassBase<LVXSCFToCFPass> {
  using LVXSCFToCFPassBase::LVXSCFToCFPassBase;

  void runOnOperation() override {
    lvx_func::FuncOp func = getOperation();
    SmallVector<lvx_scf::ForOp> forOps;
    // Pre-order, outer before inner: `Operation::walk`'s default is
    // *post-order* (`mlir/include/mlir/IR/Operation.h`), which would
    // process a nested loop before its containing one -- `lowerFor*`
    // assumes it's the first thing to touch its own body region (a single
    // intact block), and an inner loop's own restructuring, run first,
    // splits that block out from under the not-yet-processed outer loop
    // before it gets its turn (found as a real crash: `body->getTerminator()`
    // stops being the expected `lvx_scf.yield` once the inner loop has
    // already spliced pieces of the outer's body elsewhere).
    func.walk<WalkOrder::PreOrder>(
        [&](lvx_scf::ForOp op) { forOps.push_back(op); });
    for (lvx_scf::ForOp forOp : forOps)
      lowerFor(forOp);

    // This pass creates copies of its own -- a loop's induction-variable
    // channel move among them -- and some land on the register they came
    // from. The allocator's sweep has already run by then, so without this
    // one a `copyd $r2 = $r2` goes straight into the bundler and takes a
    // TINY slot. Found by comparing a vectorized loop against lvx-gcc's
    // output for the same source.
    eraseIdentityCopies(func);
  }
};

} // namespace
