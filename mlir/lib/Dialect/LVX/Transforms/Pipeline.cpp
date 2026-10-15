//===- Pipeline.cpp - Software pipeline an lvx_scf.for --------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Emits the software pipeline a stage assignment describes: a peeled prologue
// that starts the first iterations, a kernel whose every stage runs at once on
// a different iteration, and a peeled epilogue that finishes the last ones.
// See lvx-mlir/docs/SoftwarePipelining.md §§4-6.
//
// Modulo variable expansion is a *shift register in SSA*: a value a later stage
// still needs becomes an `iter_arg`, and the kernel yields the newer versions
// so each slides back one trip. That is all correctness needs. Unrolling the
// kernel (§5) removes the copies the shift implies by letting each copy read a
// statically different name; it is an optimisation on top, not a prerequisite,
// and this pass does not do it yet.
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/LVX/Analysis/CrossStageValues.h"
#include "mlir/Dialect/LVX/IR/LVX.h"
#include "mlir/Dialect/LVX/Transforms/Passes.h"
#include "mlir/Dialect/LVXFunc/IR/LVXFunc.h"
#include "mlir/Dialect/LVXSCF/IR/LVXSCF.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/IRMapping.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/MapVector.h"

namespace mlir {
namespace lvx {
#define GEN_PASS_DEF_LVXPIPELINEPASS
#include "mlir/Dialect/LVX/Transforms/Passes.h.inc"
} // namespace lvx
} // namespace mlir

using namespace mlir;
using namespace mlir::lvx;

namespace {

/// The stage an operation belongs to, as a discardable attribute -- the same
/// per-operation shape as `cycle`, and for the same reason: it has to survive
/// the body being reordered. Discardable rather than declared because the ops
/// are generated from the machine description, and a pass-produced annotation
/// does not belong in the ISA's definition of an instruction.
constexpr llvm::StringLiteral kStageAttr = "lvx.stage";

/// Where a value a body operation reads comes from, and how many kernel trips
/// back the reader needs it.
///
/// `source` is the value as the *producer* names it: an operation's result, the
/// induction variable, or -- for something arriving through an `iter_arg` --
/// the `lvx_scf.yield` operand that produced it an iteration earlier. Naming a
/// loop-carried value by what yields it rather than by the `iter_arg` is what
/// makes the version arithmetic uniform: every source has a defining stage, and
/// a use is some number of trips later than it.
struct Reference {
  Value source;
  unsigned version = 0;
  bool external = false; // defined outside the loop; use it directly
};

/// Constant-bounded loop arithmetic. The pass requires constant bounds (§6's
/// guard and remainder loop are not emitted yet), so the trip count and every
/// peeled iteration's induction value are known here.
struct Bounds {
  int64_t lb = 0, ub = 0, step = 1;
  int64_t tripCount() const {
    if (step <= 0 || ub <= lb)
      return 0;
    return (ub - lb + step - 1) / step;
  }
  int64_t ivAt(int64_t iteration) const { return lb + iteration * step; }
};

static std::optional<int64_t> constantOf(Value v) {
  auto li = v.getDefiningOp<LiOp>();
  if (!li)
    return std::nullopt;
  if (auto i = dyn_cast<IntegerAttr>(li.getValue()))
    return i.getValue().getSExtValue();
  return std::nullopt;
}

static std::optional<Bounds> boundsOf(lvx_scf::ForOp loop) {
  auto lb = constantOf(loop.getLowerBound());
  auto ub = constantOf(loop.getUpperBound());
  auto st = constantOf(loop.getStep());
  if (!lb || !ub || !st)
    return std::nullopt;
  return Bounds{*lb, *ub, *st};
}

/// Emits one software pipeline for `loop`, whose body operations are assigned
/// the given stages.
class PipelineEmitter {
public:
  PipelineEmitter(lvx_scf::ForOp loop, ArrayRef<unsigned> stages, Bounds bounds)
      : loop(loop), stages(stages), bounds(bounds),
        yield(cast<lvx_scf::YieldOp>(loop.getBody()->getTerminator())) {
    for (Operation &op : loop.getBody()->without_terminator()) {
      index[&op] = ops.size();
      ops.push_back(&op);
    }
    for (unsigned s : stages)
      numStages = std::max(numStages, s + 1);
  }

  LogicalResult emit();

private:
  unsigned stageOf(Operation *op) const {
    auto it = index.find(op);
    assert(it != index.end() && "operation is not in the body");
    return stages[it->second];
  }

  /// Resolves an operand read by an operation at `useStage`.
  Reference referenceOf(Value operand, unsigned useStage);

  /// Collects, for every source, how many trips back the furthest reader is.
  void computeVersions();

  /// The value of `source` for absolute source `iteration`, peeling a constant
  /// induction value or reaching back to the loop's init operands as needed.
  Value peeledValue(OpBuilder &b, Location loc, Value source, int64_t iteration);

  /// Clones `op` for `iteration` into the current insertion point, resolving
  /// its operands through `peeled`.
  void clonePeeled(OpBuilder &b, Operation *op, int64_t iteration);

  lvx_scf::ForOp loop;
  ArrayRef<unsigned> stages;
  Bounds bounds;
  lvx_scf::YieldOp yield;

  SmallVector<Operation *> ops;
  DenseMap<Operation *, unsigned> index;
  unsigned numStages = 1;

  /// Sources needing more than their freshest version, in a stable order, with
  /// the furthest trip any reader looks back.
  llvm::MapVector<Value, unsigned> maxVersion;
  /// The stage at which each source is produced.
  DenseMap<Value, unsigned> defStage;

  /// Peeled code: (source, absolute source iteration) -> value.
  DenseMap<std::pair<Value, int64_t>, Value> peeled;
};

Reference PipelineEmitter::referenceOf(Value operand, unsigned useStage) {
  if (operand == loop.getInductionVar())
    return {operand, useStage, false};

  if (auto arg = dyn_cast<BlockArgument>(operand)) {
    if (arg.getOwner() == loop.getBody()) {
      // An iter_arg: the previous iteration's yield operand is the producer.
      unsigned j = arg.getArgNumber() - 1;
      Value yielded = yield.getOperand(j);
      Operation *def = yielded.getDefiningOp();
      if (!def || index.find(def) == index.end())
        return {yielded, 0, true}; // loop-invariant through the channel
      return {yielded, useStage + 1 - stageOf(def), false};
    }
    return {operand, 0, true};
  }

  Operation *def = operand.getDefiningOp();
  if (!def || index.find(def) == index.end())
    return {operand, 0, true};
  return {operand, useStage - stageOf(def), false};
}

void PipelineEmitter::computeVersions() {
  defStage[loop.getInductionVar()] = 0;
  for (Operation *op : ops)
    for (Value r : op->getResults())
      defStage[r] = stageOf(op);

  auto note = [&](Value operand, unsigned useStage) {
    Reference ref = referenceOf(operand, useStage);
    if (ref.external)
      return;
    unsigned &slot = maxVersion[ref.source];
    slot = std::max(slot, ref.version);
    if (Operation *d = ref.source.getDefiningOp())
      if (index.count(d))
        defStage[ref.source] = stageOf(d);
  };

  for (Operation *op : ops)
    for (Value operand : op->getOperands())
      note(operand, stageOf(op));
  // The yield's own operands are read by the next iteration, which the
  // iter_arg uses above already account for; nothing more is needed here.
}

Value PipelineEmitter::peeledValue(OpBuilder &b, Location loc, Value source,
                                   int64_t iteration) {
  if (source == loop.getInductionVar())
    return b.create<LiOp>(loc, source.getType(),
                          b.getI64IntegerAttr(bounds.ivAt(iteration)));
  if (iteration < 0) {
    // Before the loop: a loop-carried source comes from the init operand.
    for (auto [j, y] : llvm::enumerate(yield.getOperands()))
      if (y == source)
        return loop.getInitArgs()[j];
    llvm_unreachable("a non-carried source cannot predate the loop");
  }
  auto it = peeled.find({source, iteration});
  assert(it != peeled.end() && "peeled value not yet emitted");
  return it->second;
}

void PipelineEmitter::clonePeeled(OpBuilder &b, Operation *op,
                                  int64_t iteration) {
  IRMapping map;
  unsigned useStage = stageOf(op);
  for (Value operand : op->getOperands()) {
    Reference ref = referenceOf(operand, useStage);
    if (ref.external) {
      map.map(operand, ref.source);
      continue;
    }
    // `version` counts trips back from the reader's trip; in peeled code the
    // reader is working on `iteration`, and a same-iteration reference is
    // version `useStage - defStage`, so the producer's iteration is the same
    // one -- except across the back edge, where it is one earlier.
    int64_t producerIteration =
        iteration - (ref.version > useStage - defStage[ref.source] ? 1 : 0);
    map.map(operand,
            peeledValue(b, op->getLoc(), ref.source, producerIteration));
  }
  Operation *clone = b.clone(*op, map);
  for (auto [orig, fresh] : llvm::zip(op->getResults(), clone->getResults()))
    peeled[{orig, iteration}] = fresh;
}

LogicalResult PipelineEmitter::emit() {
  if (numStages <= 1)
    return success(); // nothing is in flight; not a pipeline

  int64_t trips = bounds.tripCount();
  if (trips < static_cast<int64_t>(numStages) - 1)
    return loop.emitError("loop runs fewer iterations than the pipeline has "
                          "stages; a guard around an unpipelined copy is not "
                          "emitted yet");

  computeVersions();

  OpBuilder b(loop);
  Location loc = loop.getLoc();

  // --- Prologue: trips 0 .. numStages-2, stage `s` working on iteration p-s.
  for (unsigned p = 0; p + 1 != numStages; ++p)
    for (Operation *op : ops)
      if (stageOf(op) <= p)
        clonePeeled(b, op, static_cast<int64_t>(p) - stageOf(op));

  // --- Kernel: one iter_arg per version a later stage still needs.
  SmallVector<Value> inits;
  SmallVector<Type> types;
  SmallVector<std::pair<Value, unsigned>> slots; // (source, version)
  for (auto &[source, maxV] : maxVersion)
    for (unsigned v = 1; v <= maxV; ++v) {
      // At the first kernel trip, version `v` holds what was produced `v`
      // trips earlier, which the prologue emitted.
      int64_t producerTrip = static_cast<int64_t>(numStages) - 1 - v;
      int64_t iteration = producerTrip - defStage[source];
      inits.push_back(peeledValue(b, loc, source, iteration));
      types.push_back(source.getType());
      slots.push_back({source, v});
    }

  Value newLb = b.create<LiOp>(
      loc, loop.getLowerBound().getType(),
      b.getI64IntegerAttr(bounds.ivAt(numStages - 1)));
  auto kernel = b.create<lvx_scf::ForOp>(loc, types, newLb,
                                         loop.getUpperBound(), loop.getStep(),
                                         inits);

  {
    OpBuilder::InsertionGuard guard(b);
    // The generated builder leaves the region empty: the entry block, its
    // induction variable and one argument per iter_arg are ours to make.
    Block *body = b.createBlock(&kernel.getRegion());
    body->addArgument(loop.getInductionVar().getType(), loc);
    for (Type t : types)
      body->addArgument(t, loc);
    b.setInsertionPointToStart(body);

    // version[source][v]: the value of `source` from `v` trips back.
    DenseMap<Value, SmallVector<Value>> version;
    for (auto &[source, maxV] : maxVersion)
      version[source].assign(maxV + 1, Value());
    for (auto [i, slot] : llvm::enumerate(slots))
      version[slot.first][slot.second] = kernel.getRegionIterArgs()[i];
    // The freshest induction value is the kernel's own.
    if (version.count(loop.getInductionVar()))
      version[loop.getInductionVar()][0] = kernel.getInductionVar();

    for (Operation *op : ops) {
      IRMapping map;
      unsigned useStage = stageOf(op);
      for (Value operand : op->getOperands()) {
        Reference ref = referenceOf(operand, useStage);
        if (ref.external) {
          map.map(operand, ref.source);
          continue;
        }
        Value v = version[ref.source][ref.version];
        assert(v && "a version was read before it was produced");
        map.map(operand, v);
      }
      Operation *clone = b.clone(*op, map);
      for (auto [orig, fresh] : llvm::zip(op->getResults(), clone->getResults()))
        if (version.count(orig))
          version[orig][0] = fresh;
    }

    // Yield the shifted register: what was version v-1 this trip is version v
    // next trip.
    SmallVector<Value> yielded;
    for (auto [source, v] : slots)
      yielded.push_back(version[source][v - 1]);
    b.create<lvx_scf::YieldOp>(loc, yielded);
  }

  // --- Seed the peeled map with what the kernel leaves in flight, so the
  // epilogue can read it: after the last trip (numStages-2+trips), version `v`
  // of a source holds the value it produced `v` trips before that.
  // A result is the final value of its iter_arg, which is what the last trip
  // *yielded* -- version v-1 of that trip, not version v. One trip out here and
  // the epilogue reads a value an iteration too old.
  int64_t lastTrip = trips - 1;
  for (auto [i, slot] : llvm::enumerate(slots)) {
    int64_t producerTrip = lastTrip - (static_cast<int64_t>(slot.second) - 1);
    peeled[{slot.first, producerTrip - defStage[slot.first]}] =
        kernel.getResult(i);
  }

  // --- Epilogue: trips `trips` .. `trips + numStages - 2`, draining the
  // stages that still have iterations to finish.
  b.setInsertionPointAfter(kernel);
  for (unsigned e = 0; e + 1 != numStages; ++e)
    for (Operation *op : ops)
      if (stageOf(op) >= e + 1)
        clonePeeled(b, op, static_cast<int64_t>(trips) + e - stageOf(op));

  // --- The loop's results are the last iteration's yielded values.
  for (auto [j, result] : llvm::enumerate(loop.getResults())) {
    Value y = yield.getOperand(j);
    Value last = peeledValue(b, loc, y, trips - 1);
    result.replaceAllUsesWith(last);
  }
  loop.erase();
  return success();
}

struct LVXPipelinePass : public lvx::impl::LVXPipelinePassBase<LVXPipelinePass> {
  using LVXPipelinePassBase::LVXPipelinePassBase;

  void runOnOperation() override {
    lvx_func::FuncOp func = getOperation();
    SmallVector<lvx_scf::ForOp> loops;
    func.walk([&](lvx_scf::ForOp loop) {
      for (Operation &op : loop.getBody()->without_terminator())
        if (op.hasAttr(kStageAttr)) {
          loops.push_back(loop);
          return;
        }
    });

    for (lvx_scf::ForOp loop : loops) {
      // Per operation, like `cycle`, so the assignment survives anything that
      // reorders the body. A positional list on the loop would not.
      SmallVector<unsigned> stages;
      bool complete = true;
      for (Operation &op : loop.getBody()->without_terminator()) {
        auto a = op.getAttrOfType<IntegerAttr>(kStageAttr);
        if (!a) {
          complete = false;
          break;
        }
        stages.push_back(a.getInt());
      }
      if (!complete) {
        loop.emitError("some body operations carry `" + Twine(kStageAttr) +
                       "` and some do not: a partial stage assignment is not "
                       "a schedule");
        return signalPassFailure();
      }

      CrossStageValues csv(loop, stages);
      if (!csv.isValid()) {
        loop.emitError("`" + Twine(kStageAttr) +
                       "` is not a feasible stage assignment: a value is read "
                       "before the stage that computes it");
        return signalPassFailure();
      }
      std::optional<Bounds> bounds = boundsOf(loop);
      if (!bounds) {
        loop.emitError("software pipelining needs constant loop bounds for "
                       "now: the guard and remainder loop are not emitted");
        return signalPassFailure();
      }
      for (Operation &op : loop.getBody()->without_terminator())
        op.removeAttr(kStageAttr);
      if (failed(PipelineEmitter(loop, stages, *bounds).emit()))
        return signalPassFailure();
    }
  }
};

} // namespace
