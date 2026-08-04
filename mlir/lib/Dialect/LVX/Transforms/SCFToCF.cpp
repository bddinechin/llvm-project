//===- SCFToCF.cpp - Lower lvx_scf.for to lvx_cf, post-allocation --------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// See docs/lvx/AssemblyEmission.md, "lvx-scf-to-cf: lowering after
// allocation". Deliberately runs *after* -lvx-allocate-registers (real
// assembly has no structured loops, but the allocator needs lvx_scf.for
// intact for its loop-carried coalescing); the two brand-new values this
// pass introduces (the loop-test comparison and the induction-variable
// increment) reuse Step 3's reserved spill-scratch registers rather than
// going through any allocation decision of their own.
//
// Eligible loops (constant step 1, no nested lvx_scf.for) instead lower to
// a hardware zero-overhead loop (LOOPDO) -- see docs/lvx/HardwareLoops.md.
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/LVX/Transforms/Passes.h"
#include "mlir/Dialect/LVX/Transforms/ScratchRegisters.h"

#include "mlir/Dialect/LVXCF/IR/LVXCF.h"
#include "mlir/Dialect/LVXFunc/IR/LVXFunc.h"
#include "mlir/Dialect/LVXSCF/IR/LVXSCF.h"
#include "mlir/IR/Builders.h"

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
// docs/lvx/RegisterAllocation.md "Reserved scratch registers") -- safe to
// reuse here because it is held out of the general allocation pool, so
// nothing else in the function is ever resident in it. Taken from the
// shared header rather than respelled: this pass runs *after* allocation,
// so naming a register the allocator can hand out silently clobbers it.
static constexpr Register kLoopTestScratchReg = kScratchReg;

// See docs/lvx/HardwareLoops.md, "Lowering". Only constant-step-1, leaf
// (no nested lvx_scf.for) loops are eligible -- everything else keeps
// using the branch-based lowering below.
static bool isHardwareLoopEligible(lvx_scf::ForOp forOp, Block *body) {
  auto stepLi = forOp.getStep().getDefiningOp<LiOp>();
  if (!stepLi)
    return false;
  auto stepAttr = dyn_cast<IntegerAttr>(stepLi.getValue());
  if (!stepAttr || stepAttr.getValue() != 1)
    return false;
  bool hasNestedFor = false;
  body->walk([&](lvx_scf::ForOp) { hasNestedFor = true; });
  return !hasNestedFor;
}

// See docs/lvx/HardwareLoops.md. `%next_iv`'s result is never read by
// anything else in the IR -- its correctness comes entirely from being
// pinned to the exact same register as `%iv` itself (a real hardware loop
// has no mechanism to pass values into its own next iteration; the
// physical register simply persists, so the increment must overwrite it
// in place). Same "register-pinned op has a load-bearing effect invisible
// to SSA use-count" caveat as the prologue/epilogue's SP restore
// (docs/lvx/RegisterAllocation.md) -- fine today since nothing runs DCE.
static void lowerForHardware(lvx_scf::ForOp forOp) {
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
  // trip = ub - lb (step == 1, checked by isHardwareLoopEligible).
  Value trip = builder.create<SbfdOp>(loc, tripTy, forOp.getUpperBound(),
                                      forOp.getLowerBound());
  Value ivInit = builder.create<MvOp>(loc, indVarTy, forOp.getLowerBound());
  SmallVector<Value> bodyOperands{ivInit};
  llvm::append_range(bodyOperands, forOp.getInitArgs());
  SmallVector<Value> exitOperands(forOp.getInitArgs());
  builder.create<lvx_cf::LoopdoOp>(loc, trip, body, bodyOperands, remainder,
                                   exitOperands);

  // Body end: increment iv in place (same register, see comment above),
  // then branch to exit -- never actually printed (-lvx-emit-asm elides a
  // branch to the immediately-following block; required for correctness
  // here, not just cosmetic, since a real printed `goto` would override
  // the hardware back-edge).
  builder.setInsertionPoint(yieldOp);
  Value iv = body->getArgument(0);
  builder.create<AdddOp>(loc, iv.getType(), iv, forOp.getStep());
  builder.create<lvx_cf::BranchOp>(loc, remainder,
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
  if (isHardwareLoopEligible(forOp, forOp.getBody()))
    lowerForHardware(forOp);
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
  }
};

} // namespace
