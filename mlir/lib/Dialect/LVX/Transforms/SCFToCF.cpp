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
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/LVX/Transforms/Passes.h"

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

// Step 3's own store-scratch register (docs/lvx/RegisterAllocation.md,
// "Reserved scratch registers") -- safe to reuse here for the same reason
// it's safe there: r29 is permanently excluded from the general
// allocation pool, so nothing else in the function is ever resident in it.
static constexpr Register kLoopTestScratchReg = Register::r29;

static void lowerFor(lvx_scf::ForOp forOp) {
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

struct LVXSCFToCFPass
    : public lvx::impl::LVXSCFToCFPassBase<LVXSCFToCFPass> {
  using LVXSCFToCFPassBase::LVXSCFToCFPassBase;

  void runOnOperation() override {
    lvx_func::FuncOp func = getOperation();
    SmallVector<lvx_scf::ForOp> forOps;
    func.walk([&](lvx_scf::ForOp op) { forOps.push_back(op); });
    for (lvx_scf::ForOp forOp : forOps)
      lowerFor(forOp);
  }
};

} // namespace
