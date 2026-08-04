//===- RewriteDivmod.cpp - Pin divmod's dual result, post-allocation ----===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// See docs/lvx/AssemblyEmission.md, "A narrower fix for divmod". Real
// hardware's DIVMODD/etc. write quotient and remainder into one aligned
// register pair (the `registerM` operand class), but Steps 1-3 of
// -lvx-allocate-registers treat the dialect's `lvx.divmodd`'s two results
// as ordinary, independently allocated values (docs/lvx/
// RegisterAllocation.md, "What remains a hard error" does not need to
// change: this never becomes a coalesced group). This pass runs strictly
// after that allocation and retypes both results to the fixed pair
// r30:r31 (already reserved as spill scratch, see kSpillScratchRegs in
// RegisterAllocation.cpp), then bridges each result that has a real use
// back to wherever it was originally allocated with an ordinary `lvx.mv`
// copy -- the same "pinned result + copy-out" shape already used for the
// hardware-loop trip count and the induction-variable copy-in in
// SCFToCF.cpp.
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/LVX/Transforms/Passes.h"
#include "mlir/Dialect/LVX/Transforms/ScratchRegisters.h"

#include "mlir/Dialect/LVXFunc/IR/LVXFunc.h"
#include "mlir/IR/Builders.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"

namespace mlir {
namespace lvx {
#define GEN_PASS_DEF_LVXREWRITEDIVMODPASS
#include "mlir/Dialect/LVX/Transforms/Passes.h.inc"
} // namespace lvx
} // namespace mlir

using namespace mlir;
using namespace mlir::lvx;

namespace {

// Confirmed against real ground truth (lvx-mds/lvx-refs' Description.yml,
// its Format entries) and empirically on real gem5: the low-numbered register
// of the pair holds the quotient, the high-numbered one the remainder.
// R62:R63 rather than the original R30:R31 because the spill-scratch pool
// these come from moved to caller-saved registers -- R30/R31 are callee-saved
// per `Convention.table`, so pinning a result there clobbered the caller's
// value with no matching save. Must stay an even/odd aligned pair.
static constexpr Register kQuotientReg = kScratchPairLo;
static constexpr Register kRemainderReg = kScratchPairHi;

// Retypes `result` to `pinned` and, if it has any use, inserts an `lvx.mv`
// copy immediately after `op` from the pinned register back to `result`'s
// original allocation, redirecting every use to the copy. Mirrors
// RegisterAllocation.cpp's insertLoopCarriedPreservingCopies: the copy
// itself must keep reading the now-pinned `result` directly, not the copy
// it is about to produce.
static void pinAndCopyOut(Operation *op, Value result, Register pinned,
                          OpBuilder &builder) {
  Type originalTy = result.getType();
  result.setType(RegisterType::get(op->getContext(), pinned));
  if (result.use_empty())
    return;
  builder.setInsertionPointAfter(op);
  auto copy = builder.create<MvOp>(op->getLoc(), originalTy, result);
  llvm::SmallPtrSet<Operation *, 1> keep{copy};
  result.replaceAllUsesExcept(copy, keep);
}

struct LVXRewriteDivmodPass
    : public lvx::impl::LVXRewriteDivmodPassBase<LVXRewriteDivmodPass> {
  using LVXRewriteDivmodPassBase::LVXRewriteDivmodPassBase;

  void runOnOperation() override {
    lvx_func::FuncOp func = getOperation();
    if (func.isExternal())
      return;

    SmallVector<Operation *> divmods;
    func.walk([&](Operation *op) {
      if (isa<DivmoddOp, DivmodudOp, DivmodwOp, DivmoduwOp>(op))
        divmods.push_back(op);
    });

    OpBuilder builder(&getContext());
    for (Operation *op : divmods) {
      pinAndCopyOut(op, op->getResult(0), kQuotientReg, builder);
      pinAndCopyOut(op, op->getResult(1), kRemainderReg, builder);
    }
  }
};

} // namespace
