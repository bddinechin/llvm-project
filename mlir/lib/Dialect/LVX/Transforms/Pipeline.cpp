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
// Modulo variable expansion is *unrolling in SSA*. The kernel holds `kunroll`
// copies of the body, and copy `c` reads the value a later stage needs `v`
// trips back as copy `c - v`'s result, or, when that is negative, as the
// `iter_arg` the previous kernel trip filled from copy `kunroll + c - v`. Every
// `iter_arg` is yielded a fresh result, never another `iter_arg`, which is what
// lets allocation coalesce each one with what is yielded into it (§5, and §8
// step 2). `kunroll` is an output: the fewest copies, rounded up to a power of
// two, for which no version is still read when the copy that reuses its
// register writes it. Iterations the unrolled kernel cannot take whole are
// peeled ahead of the prologue.
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/LVX/Analysis/CrossStageValues.h"
#include "mlir/Dialect/LVX/IR/LVX.h"
#include "mlir/Dialect/LVX/IR/LVXTiedOperands.h"
#include "mlir/Dialect/LVX/Transforms/Passes.h"
#include "mlir/Dialect/LVXFunc/IR/LVXFunc.h"
#include "mlir/Dialect/LVXSCF/IR/LVXSCF.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/IRMapping.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/MapVector.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Support/MathExtras.h"

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

  /// The kernel unrolling the stage assignment needs; see `computeUnroll`.
  unsigned getUnroll() const { return unroll; }

  /// The most copies `computeUnroll` may ask for before the pass gives up.
  static constexpr unsigned kMaxUnroll = 16;

  /// Computes `getUnroll()`, or fails if it would exceed `kMaxUnroll`.
  LogicalResult computeUnroll();

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

  /// Whether `a` issues no later than `b` within one copy of the body.
  bool issuesBefore(Operation *a, Operation *b) const {
    if (a == b)
      return true;
    unsigned sa = stageOf(a), sb = stageOf(b);
    if (sa != sb)
      return sa > sb;
    return index.lookup(a) < index.lookup(b);
  }

  /// The induction value for the iteration `delta` trips after the kernel's
  /// own, in the kernel body being built.
  Value kernelIV(OpBuilder &b, Location loc, Value iv, int64_t delta);

  /// The value of `source` for absolute source `iteration`, peeling a constant
  /// induction value or reaching back to the loop's init operands as needed.
  Value peeledValue(OpBuilder &b, Location loc, Value source, int64_t iteration);

  /// Clones `op` for `iteration` into the current insertion point, resolving
  /// its operands through `peeled`.
  void clonePeeled(OpBuilder &b, Operation *op, int64_t iteration);

  /// The order operations issue in within a section, which is *not* body
  /// order once the stages differ.
  ///
  /// A section holds instances of several iterations at once: stage `s` works
  /// on the iteration `s` trips back, so a higher stage is an *older*
  /// iteration and has to issue first. [PaCT97] linearises by cycle, then
  /// iteration, then position in the body; without cycles here, the iteration
  /// tie-break alone -- stage descending, body order within a stage -- is what
  /// keeps memory in order.
  ///
  /// SSA dependences do not need it: a cross-stage read takes a version, which
  /// is an `iter_arg`, and a same-stage read keeps body order. Memory
  /// dependences are not SSA edges, so nothing else preserves them, and
  /// emitting a store after the loads of a newer iteration silently
  /// miscompiles -- which is how this was found, on `vtail`.
  SmallVector<Operation *> issueOrder() const {
    SmallVector<Operation *> order(ops.begin(), ops.end());
    llvm::stable_sort(order, [&](Operation *a, Operation *b) {
      return stages[index.lookup(a)] > stages[index.lookup(b)];
    });
    return order;
  }

  lvx_scf::ForOp loop;
  ArrayRef<unsigned> stages;
  Bounds bounds;
  lvx_scf::YieldOp yield;

  SmallVector<Operation *> ops;
  DenseMap<Operation *, unsigned> index;
  unsigned numStages = 1;
  unsigned unroll = 1;

  /// Kernel induction values by trip offset, for the body being built.
  DenseMap<int64_t, Value> ivAt;

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

/// A value's register is reused by the copy of the body that produces the same
/// source `kunroll` trips later, so every reader of a version has to be done
/// with it by then. Reading version `v` needs `kunroll > v`, or `kunroll == v`
/// when the reader issues before the producer within a copy -- a higher stage,
/// or the same stage earlier in the body, as an accumulator's own `ffma` reads
/// its previous value.
///
/// A tie stretches that. The result shares the tied operand's register, so its
/// readers are readers of the source's register too, at the sum of the two
/// distances: scalar `mymma`'s loaded element lives through the `ffma` that
/// overwrites it, to the store of the sum. A tie whose result is the source
/// again is the recurrence itself, one register by the ISA, and adds nothing
/// (SoftwarePipelining.md §8 step 0b).
LogicalResult PipelineEmitter::computeUnroll() {
  // Every non-external read, by source.
  struct Read {
    Operation *op;
    unsigned operand;
    unsigned version;
  };
  llvm::MapVector<Value, SmallVector<Read>> readers;
  for (Operation *op : ops)
    for (OpOperand &use : op->getOpOperands()) {
      Reference ref = referenceOf(use.get(), stageOf(op));
      if (ref.external || ref.source == loop.getInductionVar())
        continue;
      readers[ref.source].push_back({op, use.getOperandNumber(), ref.version});
    }

  unsigned need = 1;
  for (auto &entry : readers) {
    Value root = entry.first;
    Operation *writer = root.getDefiningOp();
    unsigned maxV = 0;
    bool late = false; // a reader at maxV issues after the writer
    SmallPtrSet<Value, 4> visited;
    std::function<void(Value, unsigned)> reach = [&](Value src,
                                                     unsigned offset) {
      for (const Read &r : readers.lookup(src)) {
        unsigned total = offset + r.version;
        bool after = writer && !issuesBefore(r.op, writer);
        if (total > maxV) {
          maxV = total;
          late = after;
        } else if (total == maxV) {
          late |= after;
        }
        for (TiedOperand tie : tiedOperandsOf(r.op->getName().stripDialect())) {
          if (tie.operand != r.operand)
            continue;
          Value result = r.op->getResult(tie.result);
          if (result == root || !visited.insert(result).second)
            continue;
          reach(result, total);
        }
      }
    };
    reach(root, 0);
    if (maxV == 0)
      continue;
    need = std::max(need, maxV + (late ? 1u : 0u));
  }
  unroll = llvm::PowerOf2Ceil(need);
  if (unroll > kMaxUnroll)
    return loop.emitError("this stage assignment keeps a value alive across ")
           << need << " kernel trips, which would unroll the kernel " << unroll
           << " times; the limit is " << kMaxUnroll;
  return success();
}

Value PipelineEmitter::kernelIV(OpBuilder &b, Location loc, Value iv,
                                int64_t delta) {
  Value &v = ivAt[delta];
  if (v)
    return v;
  int64_t imm = delta * bounds.step;
  // `addd`'s immediate form takes a signed 10-bit value.
  if (imm >= -512 && imm < 512) {
    v = b.create<AdddImmOp>(loc, iv.getType(), iv,
                            b.getI64IntegerAttr(imm));
  } else {
    Value k = b.create<LiOp>(loc, iv.getType(), b.getI64IntegerAttr(imm));
    v = b.create<AdddOp>(loc, iv.getType(), iv, k);
  }
  return v;
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
  // The induction value is recomputed per copy rather than carried.
  maxVersion.erase(loop.getInductionVar());
  // A yielded value's last iteration may be produced in the kernel's last
  // copy, and the loop's result reads it from there: keep a slot for it.
  for (Value y : yield.getOperands())
    if (Operation *d = y.getDefiningOp(); d && index.count(d)) {
      unsigned &slot = maxVersion[y];
      slot = std::max(slot, 1u);
    }

  // Iterations are numbered from 0. The first `base` are peeled ahead of the
  // prologue, in body order, so that what the pipeline covers -- its
  // `numStages - 1` ramp iterations and `kernelTrips` whole unrolled bodies --
  // is exactly the rest. With constant bounds this is the round-down of §8
  // step 2; a run-time trip count would mask instead.
  int64_t steady = trips - (static_cast<int64_t>(numStages) - 1);
  int64_t kernelTrips = steady / unroll;
  int64_t base = steady % unroll;
  // Virtual trip `T` of the pipeline runs stage `s` on iteration
  // `base + T - s`; the kernel covers virtual trips
  // [numStages - 1, numStages - 1 + kernelTrips * unroll).
  int64_t kernelStart = static_cast<int64_t>(numStages) - 1;
  int64_t kernelEnd = kernelStart + kernelTrips * unroll;

  OpBuilder b(loop);
  Location loc = loop.getLoc();

  // --- Peel: iterations 0 .. base-1, unpipelined.
  for (int64_t i = 0; i != base; ++i)
    for (Operation *op : ops)
      clonePeeled(b, op, i);

  // --- Prologue: virtual trips 0 .. numStages-2.
  SmallVector<Operation *> order = issueOrder();
  for (unsigned p = 0; p + 1 != numStages; ++p)
    for (Operation *op : order)
      if (stageOf(op) <= p)
        clonePeeled(b, op, base + static_cast<int64_t>(p) - stageOf(op));

  // --- Kernel: slot (source, k) holds what the previous kernel trip's copy
  // `unroll - k` produced, for k = 1 .. the furthest version read.
  SmallVector<Value> inits;
  SmallVector<Type> types;
  SmallVector<std::pair<Value, unsigned>> slots; // (source, k)
  for (auto &[source, maxV] : maxVersion)
    for (unsigned k = 1; k <= maxV; ++k) {
      // Before the first kernel trip, slot k holds virtual trip
      // kernelStart - k.
      int64_t iteration = base + kernelStart - k - defStage[source];
      inits.push_back(peeledValue(b, loc, source, iteration));
      types.push_back(source.getType());
      slots.push_back({source, k});
    }

  auto constant = [&](int64_t v) {
    return b.create<LiOp>(loc, loop.getLowerBound().getType(),
                          b.getI64IntegerAttr(v));
  };
  // The peel and the ramp end the kernel exactly at the loop's last
  // iteration, so its upper bound is the loop's own; so is its step when it
  // is not unrolled. Reusing them rather than materialising equal constants
  // is not cosmetic: a fresh `li` is one more value for allocation to place,
  // and on `mymma` at `VEC=4` that alone took the kernel from 4 cycles to 6.
  Value newLb = constant(bounds.ivAt(base + kernelStart));
  Value newUb = loop.getUpperBound();
  Value newStep = unroll == 1
                      ? loop.getStep()
                      : constant(bounds.step * static_cast<int64_t>(unroll));
  auto kernel =
      b.create<lvx_scf::ForOp>(loc, types, newLb, newUb, newStep, inits);

  {
    OpBuilder::InsertionGuard guard(b);
    // The generated builder leaves the region empty: the entry block, its
    // induction variable and one argument per iter_arg are ours to make.
    Block *body = b.createBlock(&kernel.getRegion());
    body->addArgument(loop.getInductionVar().getType(), loc);
    for (Type t : types)
      body->addArgument(t, loc);
    b.setInsertionPointToStart(body);
    ivAt.clear();
    ivAt[0] = kernel.getInductionVar();

    // fresh[source][c]: what copy c produced this kernel trip.
    DenseMap<Value, SmallVector<Value>> fresh;
    DenseMap<std::pair<Value, unsigned>, Value> slotArg;
    for (auto [i, slot] : llvm::enumerate(slots))
      slotArg[slot] = kernel.getRegionIterArgs()[i];

    for (unsigned c = 0; c != unroll; ++c)
      for (Operation *op : order) {
        IRMapping map;
        unsigned useStage = stageOf(op);
        for (Value operand : op->getOperands()) {
          Reference ref = referenceOf(operand, useStage);
          if (ref.external) {
            map.map(operand, ref.source);
            continue;
          }
          int64_t from = static_cast<int64_t>(c) - ref.version;
          if (ref.source == loop.getInductionVar()) {
            map.map(operand, kernelIV(b, op->getLoc(), kernel.getInductionVar(),
                                      from));
            continue;
          }
          Value v;
          if (from >= 0)
            v = fresh[ref.source][from];
          else
            v = slotArg.lookup({ref.source, static_cast<unsigned>(-from)});
          assert(v && "a version was read before it was produced");
          map.map(operand, v);
        }
        Operation *clone = b.clone(*op, map);
        for (auto [orig, res] : llvm::zip(op->getResults(), clone->getResults()))
          if (maxVersion.count(orig)) {
            SmallVector<Value> &f = fresh[orig];
            f.resize(unroll);
            f[c] = res;
          }
      }

    SmallVector<Value> yielded;
    for (auto [source, k] : slots)
      yielded.push_back(fresh[source][unroll - k]);
    b.create<lvx_scf::YieldOp>(loc, yielded);
  }

  // --- Seed the epilogue with what the kernel leaves in flight: slot k holds
  // virtual trip kernelEnd - k, whether the kernel ran or not.
  for (auto [i, slot] : llvm::enumerate(slots))
    peeled[{slot.first, base + kernelEnd - slot.second - defStage[slot.first]}] =
        kernel.getResult(i);

  // --- Epilogue: virtual trips kernelEnd .. kernelEnd + numStages - 2,
  // draining the stages that still have iterations to finish.
  b.setInsertionPointAfter(kernel);
  for (unsigned e = 0; e + 1 != numStages; ++e)
    for (Operation *op : order)
      if (stageOf(op) >= e + 1)
        clonePeeled(b, op, base + kernelEnd + e - stageOf(op));

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
      if (!isInnermost(loop))
        return;
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
      PipelineEmitter emitter(loop, stages, *bounds);
      if (failed(emitter.computeUnroll()) || failed(emitter.emit()))
        return signalPassFailure();
    }
  }
};

} // namespace
