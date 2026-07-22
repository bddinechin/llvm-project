//===- TestLiveIntervals.cpp - Test LVX live interval computation -------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Test pass for mlir::lvx::LVXLiveIntervals (see
// mlir/include/mlir/Dialect/LVX/Analysis/LiveIntervals.h and
// docs/lvx/RegisterAllocation.md). Mirrors the existing
// mlir/test/lib/Analysis/TestLiveness.cpp convention.
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/LVX/Analysis/LiveIntervals.h"
#include "mlir/Dialect/LVXFunc/IR/LVXFunc.h"
#include "mlir/IR/AsmState.h"
#include "mlir/Pass/Pass.h"

using namespace mlir;
using namespace mlir::lvx;

namespace {

struct TestLVXLiveIntervalsPass
    : public PassWrapper<TestLVXLiveIntervalsPass,
                         OperationPass<lvx_func::FuncOp>> {
  MLIR_DEFINE_EXPLICIT_INTERNAL_INLINE_TYPE_ID(TestLVXLiveIntervalsPass)

  StringRef getArgument() const final { return "lvx-print-live-intervals"; }
  StringRef getDescription() const final {
    return "Print the live intervals computed by LVXLiveIntervals.";
  }

  void runOnOperation() override {
    lvx_func::FuncOp func = getOperation();
    llvm::errs() << "Testing : " << func.getName() << "\n";
    if (func.isExternal()) {
      llvm::errs() << "  (external, no body)\n";
      return;
    }

    LVXLiveIntervals live(func);
    AsmState state(func);
    for (const LiveInterval &interval : live.getIntervals()) {
      llvm::errs() << "  ";
      interval.value.printAsOperand(llvm::errs(), state);
      llvm::errs() << " : [" << interval.start << ", " << interval.end
                   << "]";
      if (interval.isFixed())
        llvm::errs() << " fixed=" << stringifyRegister(*interval.fixedReg);
      llvm::errs() << "\n";
    }
  }
};

} // namespace

namespace mlir {
namespace test {
void registerTestLVXLiveIntervalsPass() {
  PassRegistration<TestLVXLiveIntervalsPass>();
}
} // namespace test
} // namespace mlir
