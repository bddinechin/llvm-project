//===- Pipeline.cpp - Software pipeline an lvx_scf.for --------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Builds the software pipeline a modulo schedule describes. The input is the
// schedule and nothing else -- an issue date per body operation (`lvx.date`)
// and the initiation interval on the loop (`lvx.ii`) -- and everything else is
// derived here: the stages, the unrolling the lifetimes force, and the code.
// See lvx-mlir/docs/SoftwarePipelining.md and
// lvx-csw/docs/mlir-pipeliner-design.md §1 and §1b.
//
// The construction is [PaCT97]'s, as LVX GCC implements it
// (`lvx_cms_build_plan`, `lvx_cms_emit_pipeline`):
//
//  - THE MASTER SCHEDULE. Instance (op, l) issues at date(op) + l * II, and
//    the instances are walked in (date, iteration, body position) order. That
//    order is the whole of what keeps memory right: the schedule satisfied the
//    memory arcs, and the walk issues in schedule order. Nothing else may
//    reorder a section.
//
//  - THE LOOPBACK is a task of its own. `lvx_scf.for` has no branch, so it is
//    a virtual one, after every operation of the body in position and at
//    phase 0 in date: iteration l's test that iteration l+1 runs. A counted
//    loop knows its count, so the test can be that early, and then every
//    instance the walk reaches before an exit belongs to an iteration that
//    really runs -- nothing is speculated and nothing has to be discarded.
//
//  - THE KERNEL is the `kunroll * II` cycles ending at ITER_SLOT, the first
//    loopback instance late enough that every operation has `kunroll`
//    instances in the window. Its `kunroll - 1` other loopback instances are
//    exits, and so are the prologue's.
//
//  - THE DRAINS. Exiting at iteration L runs, of iterations 0..L, every
//    instance the walk has not reached yet. With constant bounds the exit
//    taken is known here, so only that one drain is emitted: the prologue, a
//    kernel loop of whole trips, the leading part of one more trip up to the
//    exit instance, and the drain. A trip count shorter than the pipeline
//    exits from the prologue, which needs no guard.
//
//  - A RUN-TIME TRIP COUNT is GCC's arrangement exactly (ROUNDING DOWN in
//    `lvx_cms_emit_pipeline`, cms-foundations.md §7tricies.62), in one
//    `lvx_scf.loop` whose breaks are the exits. With M the count, K the
//    unrolling and L0 the loopbacks the prologue holds:
//
//      a test that M is zero, then the prologue, each of its loopback
//      instances l an exit when M == l + 1, to that exit's drain;
//      T = (M - 1 - L0) >> log2 K whole trips of the kernel, which has no
//      exit, so it stays one block and LOOPDO repeats it for nothing;
//      the remainder copy, one more trip in straight line, whose loopback
//      instance j < K - 1 exits when J = (M - 1 - L0) & (K - 1) is j;
//      its closing instance dropped, falling into the main drain.
//
//    The remainder runs 1 to K iterations, never 0, and T may be 0, which
//    LOOPDO skips. At K = 1 there is no remainder copy: the kernel runs
//    M - L0 trips and its own closing instance is the main exit.
//
//    Rounding up instead -- ceil(M / K) trips with the counted exits inside
//    the kernel -- is legal here, since nothing downstream has to recognise
//    the hardware loop (mlir-pipeliner-design.md §6d), and it would save the
//    remainder copy. It is not taken because the exits would cut the kernel
//    into K blocks, and the bundler schedules a block at a time.

// In SSA the renaming GCC's construction has to do over hard registers is the
// allocator's ordinary job: every instance defines a fresh value, and a value
// crossing the kernel's back edge is an `iter_arg` yielded a fresh instance,
// never another `iter_arg`. `kunroll` is what makes that coalescable: the
// fewest copies, rounded up to a power of two, for which every read of a
// value comes before, in walk order, the instance `kunroll` iterations later
// that reuses its register.
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/LVX/IR/LVX.h"
#include "mlir/Dialect/LVX/IR/LVXLatency.h"
#include "mlir/Dialect/LVX/IR/LVXTiedOperands.h"
#include "mlir/Dialect/LVX/Transforms/Passes.h"
#include "mlir/Dialect/LVX/Transforms/ModuloScheduling.h"
#include "mlir/Dialect/LVX/Transforms/Pipeline.h"
#include "mlir/Dialect/LVX/Transforms/RegisterAllocation.h"
#include "mlir/Dialect/LVXFunc/IR/LVXFunc.h"
#include "mlir/Dialect/LVXSCF/IR/LVXSCF.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/IRMapping.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/MapVector.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/MathExtras.h"

#include <functional>
#include <limits>
#include <tuple>

#define DEBUG_TYPE "lvx-pipeline"

namespace mlir {
namespace lvx {
#define GEN_PASS_DEF_LVXPIPELINEPASS
#include "mlir/Dialect/LVX/Transforms/Passes.h.inc"
} // namespace lvx
} // namespace mlir

using namespace mlir;
using namespace mlir::lvx;

namespace {

/// The schedule `-lvx-decomposed-pipeline` writes: a date per operation and
/// the initiation interval on the loop.
constexpr llvm::StringLiteral kDateAttr = "lvx.date";
constexpr llvm::StringLiteral kIIAttr = "lvx.ii";
/// A bare stage per operation, for hand-written tests: read as a date at an
/// initiation interval of one, which keeps the stages and orders a section the
/// way stage-then-body order would.
constexpr llvm::StringLiteral kStageAttr = "lvx.stage";

/// Whether `loop` is innermost. Modulo scheduling is for innermost loops --
/// an outer loop's "operations" include the inner loop, whose cost is a trip
/// count, not a latency.
static bool isInnermost(lvx_scf::ForOp loop) {
  WalkResult r = loop.getBody()->walk([&](lvx_scf::ForOp inner) {
    return inner == loop ? WalkResult::advance() : WalkResult::interrupt();
  });
  return !r.wasInterrupted();
}

/// Constant-bounded loop arithmetic. The pass requires constant bounds, so the
/// trip count, the exit taken and every peeled induction value are known.
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

/// One instance of the master schedule. `op` indexes the body, and the body's
/// size is the loopback.
struct Slot {
  unsigned op;
  int64_t iter;
  int64_t date;
  auto key() const { return std::make_tuple(date, iter, op); }
  bool operator<(const Slot &o) const { return key() < o.key(); }
};

/// What an operand of a body operation reads: a body result `iterations`
/// back, the induction value, or something defined outside the loop.
struct Read {
  enum Kind { Body, Induction, External } kind;
  Value value;          // the body result, for `Body`
  unsigned distance;    // iterations back: 1 through an iter_arg
};

class PipelineBuilder {
public:
  PipelineBuilder(lvx_scf::ForOp loop, ArrayRef<int64_t> dates, int64_t ii,
                  std::optional<Bounds> bounds, int64_t step, bool keepDates)
      : loop(loop), dates(dates), ii(ii), bounds(bounds), step(step),
        keepDates(keepDates),
        yield(cast<lvx_scf::YieldOp>(loop.getBody()->getTerminator())) {
    for (Operation &op : loop.getBody()->without_terminator()) {
      index[&op] = ops.size();
      ops.push_back(&op);
    }
    for (int64_t d : dates)
      maxDate = std::max(maxDate, d);
    numStages = maxDate / ii + 1;
  }

  unsigned getNumStages() const { return numStages; }
  unsigned getUnroll() const { return unroll; }

  /// Everything that can refuse, before anything is changed.
  LogicalResult plan();
  /// Rewrites the loop. Only after `plan` succeeded.
  LogicalResult emit();

  static constexpr unsigned kMaxUnroll = 16;

private:
  unsigned loopback() const { return ops.size(); }
  int64_t dateOf(unsigned op, int64_t iter) const {
    return (op == loopback() ? 0 : dates[op]) + iter * ii;
  }
  Slot slot(unsigned op, int64_t iter) const {
    return {op, iter, dateOf(op, iter)};
  }

  Read readOf(Value operand);
  LogicalResult computeUnroll();

  // Straight-line code: the value of `operand` as read by an instance of
  // iteration `iter` of the current section.
  Value straight(OpBuilder &b, Value operand, int64_t iter);
  Value producedAt(Value v, int64_t iter);
  void emitStraight(OpBuilder &b, const Slot &s);
  Value inductionAt(OpBuilder &b, int64_t iter);

  /// The kernel loop over the window, from `lb` to `ub` by `st`. Its inits
  /// are read from the current section, which must be the prologue's.
  FailureOr<lvx_scf::ForOp> buildKernel(OpBuilder &b, Value lb, Value ub,
                                        Value st);
  void dateKernel(lvx_scf::ForOp kernel);
  /// Starts the section after the kernel: only what the kernel carried out of
  /// its last trip, in that trip's window iterations, is readable.
  void afterKernel(lvx_scf::ForOp kernel);
  /// What is in flight when iteration `exitIter`'s loopback exits: every
  /// instance of an iteration up to it that the walk has not reached yet.
  void emitDrain(OpBuilder &b, int64_t exitIter);
  /// A counted exit: when `test` passes `cond`, the drain of `exitIter` runs
  /// and the pipeline is left, through `token`, with that iteration's yielded
  /// values.
  void emitExit(OpBuilder &b, Value token, BcuCond cond, Value test,
                int64_t exitIter);

  LogicalResult emitConstant();
  LogicalResult emitRuntime();

  lvx_scf::ForOp loop;
  ArrayRef<int64_t> dates;
  int64_t ii;
  std::optional<Bounds> bounds; // when constant
  int64_t step;
  /// Whether the kernel copies carry their dates on to `-lvx-schedule`.
  bool keepDates;
  lvx_scf::YieldOp yield;

  SmallVector<Operation *> ops;
  DenseMap<Operation *, unsigned> index;
  int64_t maxDate = 0;
  unsigned numStages = 1;
  unsigned unroll = 1;

  // The plan.
  int64_t iterIteration = 0; // ITER_SLOT is the loopback of this iteration
  int64_t kernelFirst = 0;   // first date of the kernel window
  SmallVector<Slot> prologue, window;
  int64_t exitIter = 0;      // the iteration whose loopback exits
  int64_t kernelTrips = 0;   // whole trips of the kernel loop
  bool partial = false;      // a leading part of one more trip follows them
  int64_t partialExit = 0;   // its exit, as a window iteration
  /// Window instances whose value outlives the trip: the iter_args.
  SmallVector<std::pair<Value, int64_t>> carried;

  /// (value, section iteration) -> the instance's result, in straight-line
  /// code and for what the kernel loop leaves behind.
  DenseMap<std::pair<Value, int64_t>, Value> produced;
  bool failedResolve = false;

  // The current section. Iteration `it` has induction value
  // `ivBase + (it + ivShift) * step`, or the constant `bounds->ivAt(it)` when
  // `ivBase` is null; an iteration before 0 reads `incoming`, if allowed.
  Value ivBase;
  int64_t ivShift = 0;
  DenseMap<int64_t, Value> ivCache;
  SmallVector<Value> incoming;
  bool allowIncoming = true;
};

Read PipelineBuilder::readOf(Value operand) {
  if (operand == loop.getInductionVar())
    return {Read::Induction, Value(), 0};
  if (auto arg = dyn_cast<BlockArgument>(operand)) {
    if (arg.getOwner() != loop.getBody())
      return {Read::External, operand, 0};
    Value y = yield.getOperand(arg.getArgNumber() - 1);
    // `plan` refused any yield that is not a body result.
    return {Read::Body, y, 1};
  }
  Operation *def = operand.getDefiningOp();
  if (!def || !index.count(def))
    return {Read::External, operand, 0};
  return {Read::Body, operand, 0};
}

/// The fewest names every value needs, as the least `kunroll` for which each
/// read of instance (d, 0) comes, in walk order, before (d, kunroll) -- the
/// instance that will reuse its register once the kernel's iter_args are
/// coalesced with what is yielded into them. A read by (d, kunroll) itself is
/// the accumulator reading its previous value, and is in time.
///
/// A tie stretches the requirement: the tying op's result shares its operand's
/// register, so the result's readers are the operand's readers too. A tie whose
/// result is the value again is the recurrence itself, one register by the
/// ISA, and adds nothing (SoftwarePipelining.md §8, 0b).
LogicalResult PipelineBuilder::computeUnroll() {
  // Readers of each body value, with the iteration they read it in.
  DenseMap<Value, SmallVector<std::tuple<unsigned, unsigned, unsigned>>>
      readers; // value -> (reader op, operand, distance)
  for (auto [r, op] : llvm::enumerate(ops))
    for (OpOperand &use : op->getOpOperands()) {
      Read rd = readOf(use.get());
      if (rd.kind == Read::Body)
        readers[rd.value].push_back(
            {static_cast<unsigned>(r), use.getOperandNumber(), rd.distance});
    }

  unsigned need = 1;
  for (auto [d, op] : llvm::enumerate(ops))
    for (Value root : op->getResults()) {
      SmallVector<Slot> reads;
      SmallPtrSet<Value, 4> visited;
      std::function<void(Value, int64_t)> reach = [&](Value v, int64_t base) {
        for (auto [r, operand, distance] : readers.lookup(v)) {
          int64_t iter = base + distance;
          reads.push_back(slot(r, iter));
          for (TiedOperand tie :
               tiedOperandsOf(ops[r]->getName().stripDialect())) {
            if (tie.operand != operand)
              continue;
            Value result = ops[r]->getResult(tie.result);
            if (result != root && visited.insert(result).second)
              reach(result, iter);
          }
        }
      };
      reach(root, 0);
      unsigned k = 1;
      for (const Slot &rd : reads) {
        while (k <= kMaxUnroll) {
          Slot redefined = slot(d, k);
          if (rd < redefined || (rd.op == d && rd.iter == k))
            break;
          ++k;
        }
      }
      if (k > kMaxUnroll)
        return loop.emitError("a value of this loop stays alive across more "
                              "than ")
               << kMaxUnroll << " iterations of the schedule";
      need = std::max(need, k);
    }
  unroll = llvm::PowerOf2Ceil(need);
  if (unroll > kMaxUnroll)
    return loop.emitError("this schedule would unroll the kernel ")
           << unroll << " times; the limit is " << kMaxUnroll;
  return success();
}

LogicalResult PipelineBuilder::plan() {
  for (Value y : yield.getOperands()) {
    Operation *def = y.getDefiningOp();
    if (!def || !index.count(def))
      return loop.emitError("software pipelining needs every yielded value "
                            "to be computed in the body");
  }

  // Every read must come after what it reads, in walk order: that is what a
  // schedule is, and what lets each instance find its operands emitted.
  for (auto [r, op] : llvm::enumerate(ops))
    for (Value operand : op->getOperands()) {
      Read rd = readOf(operand);
      if (rd.kind != Read::Body)
        continue;
      unsigned d = index.lookup(rd.value.getDefiningOp());
      if (!(slot(d, 0) < slot(r, rd.distance)))
        return loop.emitError("the schedule is not one: an operation issues "
                              "before a value it reads");
    }

  if (failed(computeUnroll()))
    return failure();

  // ITER_SLOT: the first loopback instance, past iteration 0, whose window of
  // `unroll * II` cycles reaches back far enough to hold `unroll` instances of
  // every operation -- every phase up to the latest must fit before it.
  int64_t adjusted = maxDate + (static_cast<int64_t>(unroll) - 1) * ii;
  iterIteration = std::max<int64_t>(1, (adjusted + ii - 1) / ii);
  int64_t iterDate = iterIteration * ii;
  kernelFirst = std::max<int64_t>(0, iterDate - unroll * ii + 1);

  SmallVector<Slot> walk;
  for (int64_t l = 0; l <= iterIteration; ++l)
    for (unsigned i = 0; i <= ops.size(); ++i)
      if (dateOf(i, l) <= iterDate)
        walk.push_back(slot(i, l));
  llvm::sort(walk);
  for (const Slot &s : walk)
    (s.date < kernelFirst ? prologue : window).push_back(s);

  // STEADYBAD, as GCC calls it: a kernel that holds an operation other than
  // `unroll` times is short of it on every trip, which is a wrong answer and
  // not a slow one.
  SmallVector<unsigned> per(ops.size() + 1, 0);
  for (const Slot &s : window)
    ++per[s.op];
  for (unsigned c : per)
    if (c != unroll)
      return loop.emitError("internal: the kernel window is not a steady "
                            "state");

  // The exit taken: the loopback of the last iteration, when it is known.
  // With a run-time count the pipeline always leaves by the main drain, after
  // whole trips, and the iterations short of that are peeled ahead of it.
  int64_t trips = bounds ? bounds->tripCount() : 0;
  if (!bounds)
    kernelTrips = 1; // at least one, under the guard
  exitIter = trips - 1;
  int64_t firstKernelExit = iterIteration - unroll + 1;
  if (bounds && trips > 0 && exitIter >= firstKernelExit) {
    int64_t x = exitIter - firstKernelExit;
    int64_t r = x / unroll, j = x % unroll;
    if (j == static_cast<int64_t>(unroll) - 1) {
      kernelTrips = r + 1;
    } else {
      kernelTrips = r;
      partial = true;
      partialExit = firstKernelExit + j;
    }
  }

  // The kernel's iter_args: window instances whose value is read after the
  // window ends -- by the next trip, or by the remainder or the drain after
  // the last one -- or that are the loop's result.
  if (kernelTrips > 0) {
    DenseMap<Value, SmallVector<std::pair<unsigned, unsigned>>> readers;
    for (auto [r, op] : llvm::enumerate(ops))
      for (Value operand : op->getOperands()) {
        Read rd = readOf(operand);
        if (rd.kind == Read::Body)
          readers[rd.value].push_back({static_cast<unsigned>(r), rd.distance});
      }
    DenseSet<Value> yielded(yield.getOperands().begin(),
                            yield.getOperands().end());
    for (const Slot &s : window) {
      if (s.op == loopback())
        continue;
      for (Value v : ops[s.op]->getResults()) {
        bool live = yielded.contains(v) && s.iter == iterIteration;
        for (auto [r, distance] : readers.lookup(v))
          live |= dateOf(r, s.iter + distance) > iterDate;
        if (live)
          carried.push_back({v, s.iter});
      }
    }
  }

  LLVM_DEBUG(llvm::dbgs() << "lvx-pipeline: II=" << ii << " nstages="
                          << numStages << " kunroll=" << unroll
                          << " iter_slot=" << iterIteration
                          << " kernel_first=" << kernelFirst << " prologue="
                          << prologue.size() << " kernel=" << window.size()
                          << " trips=" << trips << " kernel_trips="
                          << kernelTrips << " partial=" << partial
                          << " carried=" << carried.size() << "\n");
  return success();
}

Value PipelineBuilder::producedAt(Value v, int64_t iter) {
  if (iter < 0 && allowIncoming) {
    // Before the pipeline: a yielded value is what enters its iter_arg.
    for (auto [j, y] : llvm::enumerate(yield.getOperands()))
      if (y == v)
        return incoming[j];
  }
  auto it = produced.find({v, iter});
  if (it == produced.end()) {
    failedResolve = true;
    return Value();
  }
  return it->second;
}

Value PipelineBuilder::straight(OpBuilder &b, Value operand, int64_t iter) {
  Read rd = readOf(operand);
  switch (rd.kind) {
  case Read::External:
    return rd.value;
  case Read::Induction:
    return inductionAt(b, iter);
  case Read::Body:
    return producedAt(rd.value, iter - rd.distance);
  }
  llvm_unreachable("unknown read");
}

/// `addd`'s immediate form takes a signed 10-bit value; past it, materialise.
static Value addConstant(OpBuilder &b, Location loc, Value base, int64_t imm) {
  if (imm == 0)
    return base;
  if (imm >= -512 && imm < 512)
    return b.create<AdddImmOp>(loc, base.getType(), base,
                               b.getI64IntegerAttr(imm));
  Value k = b.create<LiOp>(loc, base.getType(), b.getI64IntegerAttr(imm));
  return b.create<AdddOp>(loc, base.getType(), base, k);
}

Value PipelineBuilder::inductionAt(OpBuilder &b, int64_t iter) {
  Type t = loop.getInductionVar().getType();
  if (!ivBase)
    return b.create<LiOp>(loop.getLoc(), t,
                          b.getI64IntegerAttr(bounds->ivAt(iter)));
  Value &v = ivCache[iter];
  if (!v)
    v = addConstant(b, loop.getLoc(), ivBase, (iter + ivShift) * step);
  return v;
}

void PipelineBuilder::emitStraight(OpBuilder &b, const Slot &s) {
  if (s.op == loopback())
    return;
  Operation *op = ops[s.op];
  IRMapping map;
  for (Value operand : op->getOperands())
    if (Value v = straight(b, operand, s.iter))
      map.map(operand, v);
  if (failedResolve)
    return;
  Operation *clone = b.clone(*op, map);
  for (auto [orig, fresh] : llvm::zip(op->getResults(), clone->getResults()))
    produced[{orig, s.iter}] = fresh;
}

FailureOr<lvx_scf::ForOp> PipelineBuilder::buildKernel(OpBuilder &b,
                                                        Value lb, Value ub,
                                                        Value st) {
  Location loc = loop.getLoc();
  SmallVector<Value> inits;
  SmallVector<Type> types;
  for (auto [v, rel] : carried) {
    Value init = producedAt(v, rel - unroll);
    if (!init) {
      // Nothing reads the slot on the first trip; any value of its type will
      // do, and an earlier instance of the same value is the obvious one.
      failedResolve = false;
      for (auto &[key, val] : produced)
        if (key.first == v) {
          init = val;
          break;
        }
      if (!init) {
        loop.emitError("internal: no initial value for an iter_arg of the "
                       "kernel");
        return failure();
      }
    }
    inits.push_back(init);
    types.push_back(v.getType());
  }
  // The kernel's induction variable is read only through `iv` below, so it
  // may count from any iteration of the window: from the first one whose
  // instance reads it, the reads are at 0, 1, ... and the earliest needs no
  // add. Counting from the trip's first iteration instead left every read
  // an `addd` of its own -- one more instruction a trip than the iterations
  // need, which no modulo scheduler was charged for. Shifting both bounds
  // keeps the trip count, and nothing after the kernel reads its induction
  // variable.
  int64_t ivFirst = std::numeric_limits<int64_t>::max();
  for (const Slot &s : window)
    if (s.op != loopback())
      for (Value operand : ops[s.op]->getOperands())
        if (readOf(operand).kind == Read::Induction)
          ivFirst = std::min(ivFirst, s.iter);
  if (ivFirst == std::numeric_limits<int64_t>::max())
    ivFirst = 0;
  if (ivFirst != 0) {
    // A constant bound shifts into a new constant rather than an add.
    auto shift = [&](Value bound) -> Value {
      if (auto li = bound.getDefiningOp<LiOp>())
        if (auto c = dyn_cast<IntegerAttr>(li.getValueAttr()))
          return b.create<LiOp>(loc, bound.getType(),
                                b.getI64IntegerAttr(c.getInt() +
                                                    ivFirst * step));
      return addConstant(b, loc, bound, ivFirst * step);
    };
    Value oldLb = lb, oldUb = ub;
    lb = shift(lb);
    ub = shift(ub);
    // Nothing downstream removes a dead constant, and the allocator would
    // give it a register and the bundler a slot.
    if (auto li = oldLb.getDefiningOp<LiOp>(); li && li->use_empty())
      li->erase();
    if (oldUb != oldLb)
      if (auto li = oldUb.getDefiningOp<LiOp>(); li && li->use_empty())
        li->erase();
  }
  auto kernel = b.create<lvx_scf::ForOp>(loc, types, lb, ub, st, inits);

  OpBuilder::InsertionGuard guard(b);
  Block *body = b.createBlock(&kernel.getRegion());
  body->addArgument(loop.getInductionVar().getType(), loc);
  for (Type t : types)
    body->addArgument(t, loc);
  b.setInsertionPointToStart(body);

  DenseMap<std::pair<Value, int64_t>, Value> slotArg, fresh;
  for (auto [i, c] : llvm::enumerate(carried))
    slotArg[c] = kernel.getRegionIterArgs()[i];
  // Window iteration `l` of a trip has the trip's induction value plus `l`
  // steps.
  DenseMap<int64_t, Value> ivs;
  auto iv = [&](int64_t rel) -> Value {
    Value &v = ivs[rel];
    if (!v)
      v = addConstant(b, loc, kernel.getInductionVar(), (rel - ivFirst) * step);
    return v;
  };

  for (const Slot &s : window) {
    if (s.op == loopback())
      continue;
    Operation *op = ops[s.op];
    IRMapping map;
    for (Value operand : op->getOperands()) {
      Read rd = readOf(operand);
      if (rd.kind == Read::External) {
        map.map(operand, rd.value);
        continue;
      }
      if (rd.kind == Read::Induction) {
        map.map(operand, iv(s.iter));
        continue;
      }
      int64_t from = s.iter - rd.distance;
      unsigned d = index.lookup(rd.value.getDefiningOp());
      Value v = dateOf(d, from) >= kernelFirst
                    ? fresh.lookup({rd.value, from})
                    : slotArg.lookup({rd.value, from + unroll});
      if (!v) {
        loop.emitError("internal: a kernel instance reads a value the "
                       "kernel does not hold");
        return failure();
      }
      map.map(operand, v);
    }
    Operation *clone = b.clone(*op, map);
    clone->setAttr(kKernelCycleAttr, b.getI64IntegerAttr(s.date - kernelFirst));
    if (keepDates)
      clone->setAttr(kKernelDateAttr, b.getI64IntegerAttr(s.date - kernelFirst));
    for (auto [orig, res] : llvm::zip(op->getResults(), clone->getResults()))
      fresh[{orig, s.iter}] = res;
  }

  SmallVector<Value> yielded;
  for (auto c : carried)
    yielded.push_back(fresh.lookup(c));
  b.create<lvx_scf::YieldOp>(loc, yielded);
  dateKernel(kernel);
  return kernel;
}

/// Leaves the kernel's schedule for the allocator: the period on the loop, and
/// a cycle on every operation. The window's instances have theirs already.
/// What the construction added -- the induction values of the window's later
/// iterations -- the modulo schedule never placed, so each is dated as late as
/// its earliest reader allows, which is where the bundler can still put it:
/// a register the allocator keeps free from that cycle cannot hold it back.
/// Dating it at its reader instead would let the allocator reuse a register
/// the bundler then has to wait for, which is what cost `mymma` VEC=4 its
/// fourth cycle (SoftwarePipelining.md §8, "Allocating against the kernel's
/// cycles").
void PipelineBuilder::dateKernel(lvx_scf::ForOp kernel) {
  OpBuilder b(kernel);
  kernel->setAttr(kKernelPeriodAttr,
                  b.getI64IntegerAttr(static_cast<int64_t>(unroll) * ii));
  Block *body = kernel.getBody();
  auto cycleOf = [](Operation *op) -> std::optional<int64_t> {
    if (auto a = op->getAttrOfType<IntegerAttr>(kKernelCycleAttr))
      return a.getInt();
    return std::nullopt;
  };
  // Backwards, so a constant feeding an added `addd` sees it dated.
  for (Operation &op : llvm::reverse(body->without_terminator())) {
    if (cycleOf(&op))
      continue;
    int64_t cycle = std::numeric_limits<int64_t>::max();
    for (OpResult res : op.getResults())
      for (OpOperand &use : res.getUses()) {
        Operation *user = body->findAncestorOpInBlock(*use.getOwner());
        std::optional<int64_t> c = user ? cycleOf(user) : std::nullopt;
        if (c)
          cycle = std::min(cycle, *c - rawLatencyOf(&op, res.getResultNumber(),
                                                    user,
                                                    use.getOperandNumber()));
      }
    if (cycle == std::numeric_limits<int64_t>::max())
      cycle = 0;
    op.setAttr(kKernelCycleAttr, b.getI64IntegerAttr(std::max<int64_t>(0, cycle)));
  }
}

void PipelineBuilder::afterKernel(lvx_scf::ForOp kernel) {
  produced.clear();
  for (auto [i, c] : llvm::enumerate(carried))
    produced[c] = kernel.getResult(i);
  // Nothing after the kernel reads back past its last trip's window, the
  // lifetimes being shorter than `unroll * II`: an iteration before 0 here is
  // a fault, not the loop's init.
  allowIncoming = false;
}

LogicalResult PipelineBuilder::emit() {
  return bounds ? emitConstant() : emitRuntime();
}

LogicalResult PipelineBuilder::emitConstant() {
  OpBuilder b(loop);
  Location loc = loop.getLoc();
  int64_t trips = bounds->tripCount();
  incoming.assign(loop.getInitArgs().begin(), loop.getInitArgs().end());

  if (trips == 0) {
    for (auto [result, init] :
         llvm::zip(loop.getResults(), loop.getInitArgs()))
      result.replaceAllUsesWith(init);
    loop.erase();
    return success();
  }

  Slot exitSlot = slot(loopback(), exitIter);

  // --- Prologue, up to the exit if it is taken there.
  for (const Slot &s : prologue) {
    emitStraight(b, s);
    if (s.op == loopback() && s.iter == exitIter)
      break;
  }

  // --- The kernel loop, `kernelTrips` whole trips. Window iteration `l` of
  // trip `t` is iteration `l + t * unroll`. What it leaves behind is keyed in
  // absolute iterations here, the sections after it being numbered so.
  if (kernelTrips > 0) {
    auto constant = [&](int64_t c) {
      return b.create<LiOp>(loc, loop.getLowerBound().getType(),
                            b.getI64IntegerAttr(c));
    };
    Value lb = constant(bounds->ivAt(0));
    Value ub = constant(bounds->ivAt(kernelTrips * unroll));
    Value st = constant(step * static_cast<int64_t>(unroll));
    FailureOr<lvx_scf::ForOp> kernel = buildKernel(b, lb, ub, st);
    if (failed(kernel))
      return failure();
    int64_t last = (kernelTrips - 1) * unroll;
    for (auto [i, c] : llvm::enumerate(carried))
      produced[{c.first, c.second + last}] = kernel->getResult(i);
  }

  // --- The leading part of one more trip, up to its exit.
  if (partial) {
    int64_t shift = kernelTrips * unroll;
    for (const Slot &s : window) {
      emitStraight(b, {s.op, s.iter + shift, s.date + shift * ii});
      if (s.op == loopback() && s.iter == partialExit)
        break;
    }
  }

  // --- The drain: every instance of iterations 0..exit not yet run.
  // `lvx_cms_build_plan`'s epilogue loop, at the one exit taken.
  emitDrain(b, exitIter);

  // --- The loop's results are the last iteration's yielded values.
  SmallVector<Value> results;
  for (Value y : yield.getOperands())
    results.push_back(producedAt(y, exitIter));
  if (failedResolve)
    return loop.emitError("internal: an instance reads a value no emitted "
                          "instance produced");
  for (auto [result, v] : llvm::zip(loop.getResults(), results))
    result.replaceAllUsesWith(v);
  loop.erase();
  return success();
}

void PipelineBuilder::emitDrain(OpBuilder &b, int64_t exitIter) {
  Slot exitSlot = slot(loopback(), exitIter);
  SmallVector<Slot> drain;
  int64_t lo = std::max<int64_t>(0, exitIter - numStages + 1);
  for (int64_t l = lo; l <= exitIter; ++l)
    for (unsigned i = 0; i != ops.size(); ++i) {
      Slot s = slot(i, l);
      if (exitSlot < s)
        drain.push_back(s);
    }
  llvm::sort(drain);
  for (const Slot &s : drain)
    emitStraight(b, s);
}

void PipelineBuilder::emitExit(OpBuilder &b, Value token, BcuCond cond,
                               Value test, int64_t exitIter) {
  Location loc = loop.getLoc();
  auto exit = b.create<lvx_scf::IfOp>(loc, cond, test);
  OpBuilder::InsertionGuard guard(b);
  Operation *fallThrough = exit.getThenBlock()->getTerminator();
  b.setInsertionPoint(fallThrough);
  // What the drain produces lives in the exit's region and is gone after it,
  // and so are the induction values it materialised there: the straight line
  // that continues past the `if` must not read either.
  auto outerProduced = produced;
  auto outerIvs = ivCache;
  emitDrain(b, exitIter);
  SmallVector<Value> results;
  for (Value y : yield.getOperands())
    results.push_back(producedAt(y, exitIter));
  if (!failedResolve) {
    b.create<lvx_scf::BreakOp>(loc, token, results);
    fallThrough->erase();
  }
  produced = std::move(outerProduced);
  ivCache = std::move(outerIvs);
}

LogicalResult PipelineBuilder::emitRuntime() {
  Location loc = loop.getLoc();
  Type t = loop.getInductionVar().getType();
  OpBuilder b(loop);
  auto i64 = [&](int64_t v) { return b.getI64IntegerAttr(v); };
  int64_t k = unroll;
  int64_t l0 = iterIteration - k + 1; // loopbacks the prologue holds

  // --- The count, as SCFToCF computes LOOPDO's. A negative one exits at the
  // first test, which is `dlez` for that reason.
  Value m = b.create<SbfdOp>(loc, t, loop.getUpperBound(),
                             loop.getLowerBound());
  if (step != 1) {
    m = b.create<AdddImmOp>(loc, t, m, i64(step - 1));
    m = b.create<SrsdImmOp>(loc, t, m, i64(llvm::Log2_64(step)));
  }

  // Shifts by zero are what a unit step and `kunroll` = 1 would otherwise
  // leave in every pipelined loop.
  auto shl = [&](Value v, int64_t by) -> Value {
    return by ? b.create<SlldImmOp>(loc, t, v, i64(by)).getResult() : v;
  };
  // M - c, each made once: the prologue's last exit test is K = 1's count.
  DenseMap<int64_t, Value> mMinus;
  auto minus = [&](int64_t c) {
    Value &v = mMinus[c];
    if (!v)
      v = addConstant(b, loc, m, -c);
    return v;
  };

  auto pipeline = b.create<lvx_scf::LoopOp>(loc, loop.getResultTypes());
  Value token = pipeline.getToken();
  b.setInsertionPointToStart(pipeline.getBody());

  // --- No iteration at all: leave with what the loop was entered with.
  ivBase = loop.getLowerBound();
  ivShift = 0;
  incoming.assign(loop.getInitArgs().begin(), loop.getInitArgs().end());
  allowIncoming = true;
  emitExit(b, token, BcuCond::dlez, m, -1);

  // --- Prologue. Its loopback instance of iteration l is the exit taken when
  // l is the last iteration; the earlier ones having failed, `dlez` on
  // M - (l + 1) is that test.
  for (const Slot &s : prologue) {
    emitStraight(b, s);
    if (s.op == loopback())
      emitExit(b, token, BcuCond::dlez, minus(s.iter + 1), s.iter);
  }

  // --- SETUP: the whole trips, and which of the remainder's exits is taken.
  // Past the prologue M >= L0 + 1, so X is not negative.
  Value trips, which;
  if (k == 1) {
    trips = minus(l0);
  } else {
    Value x = minus(l0 + 1);
    trips = b.create<SrldImmOp>(loc, t, x, i64(llvm::Log2_64(k)));
    which = b.create<AnddImmOp>(loc, t, x, i64(k - 1));
  }

  // --- The kernel, exit-free: `trips` whole trips from the lower bound.
  Value kub = b.create<AdddOp>(loc, t, loop.getLowerBound(),
                               shl(trips, llvm::Log2_64(k * step)));
  Value kst = b.create<LiOp>(loc, t, i64(k * step));
  FailureOr<lvx_scf::ForOp> kernel =
      buildKernel(b, loop.getLowerBound(), kub, kst);
  if (failed(kernel))
    return failure();

  // --- After it, iterations are numbered as the last trip's window: `l` is
  // `kub + (l - K) * step`, and the remainder copy is that window again, K
  // iterations on.
  afterKernel(*kernel);
  ivBase = kub;
  ivShift = -k;
  ivCache.clear();
  int64_t mainExit = iterIteration;
  if (k > 1) {
    for (const Slot &s : window) {
      Slot next{s.op, s.iter + k, s.date + k * ii};
      emitStraight(b, next);
      if (s.op == loopback() && s.iter != iterIteration)
        emitExit(b, token, BcuCond::deqz,
                 addConstant(b, loc, which, -(s.iter - l0)), next.iter);
    }
    mainExit = iterIteration + k;
  }

  // --- The main drain, where the closing instance's exit went.
  emitDrain(b, mainExit);
  SmallVector<Value> results;
  for (Value y : yield.getOperands())
    results.push_back(producedAt(y, mainExit));
  if (failedResolve)
    return loop.emitError("internal: an instance reads a value no emitted "
                          "instance produced");
  b.create<lvx_scf::BreakOp>(loc, token, results);

  for (auto [orig, piped] : llvm::zip(loop.getResults(), pipeline.getResults()))
    orig.replaceAllUsesWith(piped);
  loop.erase();
  return success();
}

/// Pipelines `loop` at the modulo schedule (`dates`, `ii`), its body already
/// stripped of the schedule's attributes. Refuses what the construction
/// cannot build, with a diagnostic, before changing anything; a schedule of
/// one stage is left alone.
static LogicalResult buildPipeline(lvx_scf::ForOp loop,
                                   ArrayRef<int64_t> dates, int64_t ii,
                                   bool keepDates = false) {
  std::optional<int64_t> step = constantOf(loop.getStep());
  if (!step || *step <= 0 || !llvm::isPowerOf2_64(*step))
    return loop.emitError("software pipelining needs a constant power-of-two "
                          "step: the trip count is a shift");
  PipelineBuilder builder(loop, dates, ii, boundsOf(loop), *step, keepDates);
  if (builder.getNumStages() <= 1)
    return success(); // nothing in flight across the back edge
  if (failed(builder.plan()))
    return failure();
  return builder.emit();
}

/// Removes the schedule's attributes from `loop` and its body.
static void stripSchedule(lvx_scf::ForOp loop) {
  for (Operation &op : loop.getBody()->without_terminator()) {
    op.removeAttr(kDateAttr);
    op.removeAttr(kStageAttr);
  }
  loop->removeAttr(kIIAttr);
  loop->removeAttr(kKeepDatesAttr);
}

namespace {
/// A detached copy of the function holding `loop`, and `loop`'s copy in it,
/// for trying something without committing to it.
struct Trial {
  lvx_func::FuncOp func;
  lvx_scf::ForOp loop;

  explicit Trial(lvx_scf::ForOp original) {
    IRMapping map;
    func = cast<lvx_func::FuncOp>(
        original->getParentOfType<lvx_func::FuncOp>()->clone(map));
    loop = cast<lvx_scf::ForOp>(map.lookup(original.getOperation()));
    stripSchedule(loop);
  }
  ~Trial() { func->erase(); }
};
} // namespace

/// Whether the construction accepts (`dates`, `ii`) for `loop`, tried on a
/// copy so that a refusal leaves the loop intact. The copy keeps the loop's
/// locations, so its diagnostics point where the reader expects.
static LogicalResult checkBuildable(lvx_scf::ForOp loop,
                                    ArrayRef<int64_t> dates, int64_t ii) {
  Trial trial(loop);
  return buildPipeline(trial.loop, dates, ii);
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
        if (op.hasAttr(kDateAttr) || op.hasAttr(kStageAttr)) {
          loops.push_back(loop);
          return;
        }
    });

    for (lvx_scf::ForOp loop : loops) {
      // Per operation, so the schedule survives anything that reorders the
      // body. A positional list on the loop would not.
      int64_t ii = 1;
      StringRef attr = kStageAttr;
      if (auto a = loop->getAttrOfType<IntegerAttr>(kIIAttr)) {
        ii = a.getInt();
        attr = kDateAttr;
      }
      SmallVector<int64_t> dates;
      for (Operation &op : loop.getBody()->without_terminator()) {
        auto a = op.getAttrOfType<IntegerAttr>(attr);
        if (!a || a.getInt() < 0) {
          loop.emitError("some body operations carry `" + attr +
                         "` and some do not: a partial schedule is not a "
                         "schedule");
          return signalPassFailure();
        }
        dates.push_back(a.getInt());
      }
      if (ii <= 0) {
        loop.emitError("`" + Twine(kIIAttr) + "` must be positive");
        return signalPassFailure();
      }
      bool keepDates = loop->hasAttr(kKeepDatesAttr);
      stripSchedule(loop);

      // What the construction refuses is an error: the schedule is wrong.
      // That is decided on a clone first, so the loop is still intact.
      if (failed(checkBuildable(loop, dates, ii)))
        return signalPassFailure();
      // What allocation refuses is an outcome: the loop stays as it was.
      if (!pipelineAllocates(loop, dates, ii, maxRegisters)) {
        loop.emitRemark("not software-pipelined: at II = ")
            << ii << " it does not allocate as well as the loop it replaces";
        continue;
      }
      if (failed(buildPipeline(loop, dates, ii, keepDates)))
        return signalPassFailure();
    }
  }
};

} // namespace

bool mlir::lvx::pipelineAllocates(lvx_scf::ForOp loop,
                                  ArrayRef<int64_t> dates, int64_t ii,
                                  unsigned maxRegisters) {
  // A trial's refusals are its answer, not the user's errors.
  ScopedDiagnosticHandler quiet(loop.getContext(),
                                [](Diagnostic &) { return success(); });
  AllocationStats before, after;
  bool baseline;
  {
    Trial trial(loop);
    baseline = succeeded(allocateRegisters(trial.func, maxRegisters, &before));
  }
  Trial trial(loop);
  if (failed(buildPipeline(trial.loop, dates, ii)))
    return false;
  if (failed(allocateRegisters(trial.func, maxRegisters, &after)))
    return !baseline; // no worse than a function that cannot allocate anyway
  if (!baseline)
    return true;
  LLVM_DEBUG(llvm::dbgs() << "lvx-pipeline: at II = " << ii << " "
                          << after.spilled << " spilled against "
                          << before.spilled << ", " << after.kernelMisses
                          << " kernel misses\n");
  return after.spilled <= before.spilled && after.kernelMisses == 0;
}
