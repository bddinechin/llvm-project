//===- TestCrossStageValues.cpp - Test the cross-stage analysis ----------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Prints what mlir::lvx::CrossStageValues computes for every `lvx_scf.for`
// carrying an `lvx.stages` attribute -- one stage per body operation, the
// terminator excluded. Mirrors TestLiveIntervals.cpp.
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/LVX/Analysis/CrossStageValues.h"
#include "mlir/Dialect/LVXFunc/IR/LVXFunc.h"
#include "mlir/IR/AsmState.h"
#include "mlir/IR/BuiltinAttributes.h"
#include "mlir/Pass/Pass.h"

using namespace mlir;
using namespace mlir::lvx;

namespace {

struct TestLVXCrossStageValuesPass
    : public PassWrapper<TestLVXCrossStageValuesPass,
                         OperationPass<lvx_func::FuncOp>> {
  MLIR_DEFINE_EXPLICIT_INTERNAL_INLINE_TYPE_ID(TestLVXCrossStageValuesPass)

  StringRef getArgument() const final { return "lvx-print-cross-stage"; }
  StringRef getDescription() const final {
    return "Print the values an `lvx.stages` assignment leaves in flight.";
  }

  void runOnOperation() override {
    lvx_func::FuncOp func = getOperation();
    AsmState state(func);
    func.walk([&](lvx_scf::ForOp loop) {
      auto attr = loop->getAttrOfType<ArrayAttr>("lvx.stages");
      if (!attr)
        return;
      SmallVector<unsigned> stages;
      for (Attribute a : attr)
        stages.push_back(cast<IntegerAttr>(a).getInt());

      CrossStageValues csv(loop, stages);
      llvm::errs() << "loop: stages=" << csv.getNumStages()
                   << " valid=" << (csv.isValid() ? "yes" : "no")
                   << " names=" << csv.getMaxNames() << "\n";
      if (!csv.isValid())
        return;
      for (const CrossStageValues::Crossing &c : csv.getCrossings()) {
        llvm::errs() << "  ";
        c.value.printAsOperand(llvm::errs(), state);
        llvm::errs() << " def=" << c.defStage << " use=" << c.lastUseStage
                     << (c.loopCarried ? " carried" : "")
                     << " distance=" << c.distance()
                     << " names=" << c.names() << "\n";
      }
    });
  }
};

} // namespace

namespace mlir {
namespace test {
void registerTestLVXCrossStageValuesPass() {
  PassRegistration<TestLVXCrossStageValuesPass>();
}
} // namespace test
} // namespace mlir
