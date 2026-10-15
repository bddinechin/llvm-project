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
// See lvx-mlir/docs/SoftwarePipelining.md §§2-3 and §8.
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/LVX/Analysis/ParametricLabelCorrecting.h"
#include "mlir/Dialect/LVX/IR/LVX.h"
#include "mlir/Dialect/LVX/IR/LVXLatency.h"
#include "mlir/Dialect/LVX/IR/LVXScheduling.h"
#include "mlir/Dialect/LVX/Transforms/Passes.h"
#include "mlir/Dialect/LVXFunc/IR/LVXFunc.h"
#include "mlir/Dialect/LVXSCF/IR/LVXSCF.h"
#include "mlir/IR/Builders.h"
#include "mlir/Interfaces/SideEffectInterfaces.h"

#include "llvm/ADT/DenseMap.h"

namespace mlir {
namespace lvx {
#define GEN_PASS_DEF_LVXDECOMPOSEDPIPELINEPASS
#include "mlir/Dialect/LVX/Transforms/Passes.h.inc"
} // namespace lvx
} // namespace mlir

using namespace mlir;
using namespace mlir::lvx;

namespace {

constexpr llvm::StringLiteral kStageAttr = "lvx.stage";

static std::optional<StringRef> mnemonicOf(Operation *op) {
  if (op->getDialect() && op->getDialect()->getNamespace() == "lvx")
    return op->getName().stripDialect();
  return std::nullopt;
}

/// The cycle an operation reads its i-th operand, and writes its i-th result.
/// The defaults are `-lvx-schedule`'s: a pseudo reads at issue and writes at
/// the next cycle.
static unsigned readCycle(const OpTiming *t, unsigned i) {
  return t && i < t->numOperands ? t->operandRead[i] : 1;
}
static unsigned writeCycle(const OpTiming *t, unsigned i) {
  return t && i < t->numResults ? t->resultWrite[i] : 2;
}

/// A dependence latency, with the clamp the ISS's bundle rule imposes: within
/// one bundle every source is read before any result is written, so a reader
/// in the producer's own bundle would see the old value -- RAW is at least 1.
static int64_t rawLatency(Operation *def, unsigned resultIdx, Operation *use,
                          unsigned operandIdx) {
  const OpTiming *dt = nullptr, *ut = nullptr;
  if (auto m = mnemonicOf(def))
    dt = timingOf(*m);
  if (auto m = mnemonicOf(use))
    ut = timingOf(*m);
  int64_t raw = static_cast<int64_t>(writeCycle(dt, resultIdx)) -
                static_cast<int64_t>(readCycle(ut, operandIdx));
  return std::max<int64_t>(1, raw);
}

/// Whether an operation touches memory at all, and whether it writes.
static bool readsMemory(Operation *op) {
  auto iface = dyn_cast<MemoryEffectOpInterface>(op);
  return iface && iface.hasEffect<MemoryEffects::Read>();
}
static bool writesMemory(Operation *op) {
  auto iface = dyn_cast<MemoryEffectOpInterface>(op);
  return iface && iface.hasEffect<MemoryEffects::Write>();
}

/// The period the resources alone force: for each resource, the total demand
/// over its availability, rounded up. `Resource.yml`'s counters through the
/// generated reservation tables.
static int64_t resourceBound(ArrayRef<Operation *> ops) {
  SmallVector<int64_t> demand(kNumResources, 0);
  for (Operation *op : ops) {
    auto m = mnemonicOf(op);
    if (!m)
      continue;
    // The format decides a reservation's ISSUE count; before `-lvx-schedule`
    // has chosen one the bare form is the right estimate, and ResMII is a
    // lower bound either way.
    std::optional<Format> format;
    if (auto f = op->getAttrOfType<FormatAttr>("format"))
      format = f.getValue();
    const Reservation *r = reservationOf(*m, format);
    if (!r)
      continue;
    for (unsigned u = 0; u != r->numUses; ++u)
      demand[static_cast<unsigned>(r->uses[u].resource)] += r->uses[u].count;
  }
  int64_t bound = 1;
  for (unsigned i = 0; i != kNumResources; ++i) {
    unsigned avail = kResourceAvailability[i];
    if (avail == 0 || demand[i] == 0)
      continue;
    bound = std::max<int64_t>(bound, (demand[i] + avail - 1) / avail);
  }
  return bound;
}

/// Whether `loop` is innermost. Modulo scheduling is for innermost loops --
/// an outer loop's "operations" include the inner loop, whose cost is a trip
/// count, not a latency. And pipelining an inner loop replaces it with code
/// that carries no stage of the outer one, so annotating both and emitting
/// outside in would leave the outer body half-assigned.
static bool isInnermost(lvx_scf::ForOp loop) {
  WalkResult r = loop.getBody()->walk([&](lvx_scf::ForOp inner) {
    return inner == loop ? WalkResult::advance() : WalkResult::interrupt();
  });
  return !r.wasInterrupted();
}

/// Assigns `lvx.stage` to every operation of `loop`'s body.
static LogicalResult assignStages(lvx_scf::ForOp loop, bool annotatePeriod) {
  SmallVector<Operation *> ops;
  DenseMap<Operation *, unsigned> index;
  for (Operation &op : loop.getBody()->without_terminator()) {
    index[&op] = ops.size();
    ops.push_back(&op);
  }
  if (ops.empty())
    return success();

  auto yield = cast<lvx_scf::YieldOp>(loop.getBody()->getTerminator());

  // Node 0 is the source; body operation i is node i+1.
  ParametricLabelCorrecting g;
  for (unsigned i = 0; i != ops.size() + 1; ++i)
    g.addNode();
  for (unsigned i = 0; i != ops.size(); ++i)
    g.addArc(0, i + 1, 0, 0);

  // Flow dependences. A value arriving through an `iter_arg` is produced by
  // the previous iteration's yield operand, hence an arc of distance one --
  // the recurrence that bounds the period.
  for (unsigned j = 0; j != ops.size(); ++j) {
    Operation *use = ops[j];
    for (auto [k, operand] : llvm::enumerate(use->getOperands())) {
      Operation *def = operand.getDefiningOp();
      int64_t omega = 0;
      unsigned resultIdx = 0;
      if (auto arg = dyn_cast<BlockArgument>(operand)) {
        if (arg.getOwner() != loop.getBody() || arg.getArgNumber() == 0)
          continue; // the induction variable, or something from outside
        Value yielded = yield.getOperand(arg.getArgNumber() - 1);
        def = yielded.getDefiningOp();
        omega = 1;
        if (def)
          resultIdx = cast<OpResult>(yielded).getResultNumber();
      } else if (def) {
        resultIdx = cast<OpResult>(operand).getResultNumber();
      }
      if (!def || !index.count(def))
        continue;
      g.addArc(index[def] + 1, j + 1,
               rawLatency(def, resultIdx, use, k), omega);
    }
  }

  // Memory, conservatively: any two accesses of which at least one writes keep
  // their program order within an iteration, and do not cross one. Without a
  // dependence test this is all that can be said, and it is what keeps the
  // period honest rather than optimistic.
  for (unsigned a = 0; a != ops.size(); ++a) {
    if (!readsMemory(ops[a]) && !writesMemory(ops[a]))
      continue;
    if (writesMemory(ops[a]))
      g.addArc(a + 1, a + 1, 1, 1); // its own next iteration
    for (unsigned b = a + 1; b != ops.size(); ++b) {
      bool touches = readsMemory(ops[b]) || writesMemory(ops[b]);
      if (!touches || (!writesMemory(ops[a]) && !writesMemory(ops[b])))
        continue;
      g.addArc(a + 1, b + 1, 1, 0);
      g.addArc(b + 1, a + 1, 1, 1);
    }
  }

  int64_t resMII = resourceBound(ops);
  auto result = g.solve(resMII);
  if (result != ParametricLabelCorrecting::Result::Solved) {
    if (result == ParametricLabelCorrecting::Result::InfeasibleCircuit)
      return loop.emitError("the loop body has a dependence circuit with no "
                            "iteration distance: no period makes it feasible");
    return loop.emitError("could not compute a resource-free schedule for "
                          "this loop body");
  }

  int64_t period = g.getPeriod();
  unsigned maxStage = 0;
  SmallVector<unsigned> stages(ops.size());
  for (unsigned i = 0; i != ops.size(); ++i) {
    stages[i] = static_cast<unsigned>(g.getDate(i + 1) / period);
    maxStage = std::max(maxStage, stages[i]);
  }
  if (maxStage == 0)
    return success(); // one stage: nothing crosses the back edge

  OpBuilder b(loop);
  for (unsigned i = 0; i != ops.size(); ++i)
    ops[i]->setAttr(kStageAttr, b.getI64IntegerAttr(stages[i]));
  if (annotatePeriod)
    loop->setAttr("lvx.period", b.getI64IntegerAttr(period));
  return success();
}

struct LVXDecomposedPipelinePass
    : public lvx::impl::LVXDecomposedPipelinePassBase<
          LVXDecomposedPipelinePass> {
  using LVXDecomposedPipelinePassBase::LVXDecomposedPipelinePassBase;

  void runOnOperation() override {
    SmallVector<lvx_scf::ForOp> loops;
    getOperation().walk([&](lvx_scf::ForOp loop) {
      if (isInnermost(loop))
        loops.push_back(loop);
    });
    for (lvx_scf::ForOp loop : loops)
      if (failed(assignStages(loop, this->annotatePeriod)))
        return signalPassFailure();
  }
};

} // namespace
