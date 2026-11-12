//===- DecomposedPipeline.cpp - Assign stages by decomposed pipelining ---===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Decomposed software pipelining, after Gasperoni & Schwiegelshohn: fix each
// operation's stage from a *resource-free* schedule at the recurrence-bound
// period, then let an ordinary acyclic scheduler place the rest. Dupont de
// Dinechin's habilitation, "Deterministic Scheduling" §2.3.1, states it as
//
//   - build a resource-free schedule {sigma*} at lambda* = RecMII;
//   - the stage of i is floor(sigma*_i / lambda*);
//   - delete the dependences the row numbers violate, leaving an acyclic
//     graph, and list-schedule *that* under the resource constraints.
//
// Only the first half is here, and the second half needs no code: once
// `-lvx-pipeline` has emitted the kernel, every value crossing a trip arrives
// through an `iter_arg`, so the kernel block's dependence DAG *is* the
// acyclified graph -- and `-lvx-schedule` already list-schedules a block
// against the real reservation tables. The decomposition falls out of the pass
// pipeline rather than having to be built.
//
// DSP is one engine of the modulo scheduling framework (ModuloScheduling.h),
// which owns the dependence graph, the bounds, the II ladder and acceptance.
// This file is the engine, plus `-lvx-decomposed-pipeline`, which is the
// framework's driver with this engine named.
//
// See lvx-mlir/docs/SoftwarePipelining.md §§2-3 and §8.
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/LVX/Analysis/ParametricLabelCorrecting.h"
#include "mlir/Dialect/LVX/Transforms/ModuloScheduling.h"
#include "mlir/Dialect/LVX/Transforms/Passes.h"
#include "mlir/Dialect/LVXFunc/IR/LVXFunc.h"

namespace mlir {
namespace lvx {
#define GEN_PASS_DEF_LVXDECOMPOSEDPIPELINEPASS
#include "mlir/Dialect/LVX/Transforms/Passes.h.inc"
} // namespace lvx
} // namespace mlir

using namespace mlir;
using namespace mlir::lvx;

namespace {

/// PLC's earliest potentials at the period, which is the resource-free
/// schedule. PLC settles on max(RecMII, floor), so solving with the floor at
/// the asked interval is the whole of scheduling at it -- the ladder starts
/// at max(RecMII, ResMII), so the floor is never below RecMII.
class DSPEngine : public ModuloEngine {
public:
  explicit DSPEngine(const ModuloProblem &p) : p(p) {}

  StringRef name() const override { return "dsp"; }
  bool honoursResources() const override { return false; }

  bool scheduleAtII(int64_t ii, SmallVectorImpl<int64_t> &dates,
                    std::string &why) override {
    ParametricLabelCorrecting g;
    p.addTo(g);
    if (g.solve(ii) != ParametricLabelCorrecting::Result::Solved) {
      why = "no resource-free schedule";
      return false;
    }
    if (g.getPeriod() != ii) {
      why = "the recurrences need a period of " + std::to_string(g.getPeriod());
      return false;
    }
    dates.clear();
    for (unsigned i = 0; i != p.numNodes(); ++i)
      dates.push_back(g.getDate(i + 1));
    return true;
  }

private:
  const ModuloProblem &p;
};

struct LVXDecomposedPipelinePass
    : public lvx::impl::LVXDecomposedPipelinePassBase<
          LVXDecomposedPipelinePass> {
  using LVXDecomposedPipelinePassBase::LVXDecomposedPipelinePassBase;

  void runOnOperation() override {
    ModuloDriverOptions o;
    o.engine = "dsp";
    o.maxRegisters = maxRegisters;
    o.annotatePeriod = annotatePeriod;
    if (failed(moduloScheduleFunction(getOperation(), o)))
      signalPassFailure();
  }
};

} // namespace

std::unique_ptr<ModuloEngine>
mlir::lvx::createDSPEngine(const ModuloProblem &p) {
  return std::make_unique<DSPEngine>(p);
}
