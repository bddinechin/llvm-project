//===- ModuloScheduling.cpp - The modulo scheduling framework -------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// The framework half of LVX GCC's late modulo scheduling, in this IR: the
// dependence graph, RecMII and ResMII, the II ladder and acceptance, and the
// `-lvx-modulo-schedule` pass that drives an engine through them. See
// ModuloScheduling.h, and lvx-gcc config/lvx/lvx-lms.{h,cc} for the original.
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/LVX/Transforms/ModuloScheduling.h"

#include "mlir/Dialect/LVX/Analysis/ParametricLabelCorrecting.h"
#include "mlir/Dialect/LVX/IR/LVX.h"
#include "mlir/Dialect/LVX/IR/LVXLatency.h"
#include "mlir/Dialect/LVX/IR/LVXTiedOperands.h"
#include "mlir/Dialect/LVX/IR/RegisterUnits.h"
#include "mlir/Dialect/LVX/Transforms/Passes.h"
#include "mlir/Dialect/LVX/Transforms/Pipeline.h"
#include "mlir/Dialect/LVXFunc/IR/LVXFunc.h"
#include "mlir/IR/Builders.h"
#include "mlir/Interfaces/SideEffectInterfaces.h"

#include "llvm/ADT/DenseMap.h"
#include "llvm/Support/Debug.h"

#define DEBUG_TYPE "lvx-modulo-schedule"

namespace mlir {
namespace lvx {
#define GEN_PASS_DEF_LVXMODULOSCHEDULEPASS
#include "mlir/Dialect/LVX/Transforms/Passes.h.inc"
} // namespace lvx
} // namespace mlir

using namespace mlir;
using namespace mlir::lvx;

/// The modulo schedule `-lvx-pipeline` consumes: an issue date per body
/// operation and the initiation interval on the loop. Everything else --
/// stages, the unrolling, the prologue and the drains -- is derived from
/// these two by the construction (lvx-csw/docs/mlir-pipeliner-design.md §1).
static constexpr llvm::StringLiteral kDateAttr = "lvx.date";
static constexpr llvm::StringLiteral kIIAttr = "lvx.ii";

static bool readsMemory(Operation *op) {
  auto iface = dyn_cast<MemoryEffectOpInterface>(op);
  return iface && iface.hasEffect<MemoryEffects::Read>();
}
static bool writesMemory(Operation *op) {
  auto iface = dyn_cast<MemoryEffectOpInterface>(op);
  return iface && iface.hasEffect<MemoryEffects::Write>();
}

bool mlir::lvx::isInnermostLoop(lvx_scf::ForOp loop) {
  WalkResult r = loop.getBody()->walk([&](lvx_scf::ForOp inner) {
    return inner == loop ? WalkResult::advance() : WalkResult::interrupt();
  });
  return !r.wasInterrupted();
}

//===----------------------------------------------------------------------===//
// The problem: the dependence graph and the two bounds.
//===----------------------------------------------------------------------===//

/// What `op` reserves at issue, charged as `-lvx-schedule` charges it: the
/// generated reservation of the instruction it prints, in the format the
/// bundler will choose, and one BCU syllable for a prefix.
static ResourceVector demandOf(Operation *op) {
  ResourceVector d{};
  if (std::optional<StringRef> m = lvxPrintedMnemonic(op))
    if (const Reservation *r = reservationOf(*m, formatOf(op)))
      for (unsigned u = 0; u != r->numUses; ++u)
        d[static_cast<unsigned>(r->uses[u].resource)] += r->uses[u].count;
  if (needsBcuPrefix(op))
    d[static_cast<unsigned>(Resource::bcu)] += 1;
  return d;
}

FailureOr<ModuloProblem> ModuloProblem::build(lvx_scf::ForOp loop) {
  ModuloProblem p;
  p.loop = loop;
  DenseMap<Operation *, unsigned> index;
  for (Operation &op : loop.getBody()->without_terminator()) {
    index[&op] = p.ops.size();
    p.ops.push_back(&op);
  }
  auto yield = cast<lvx_scf::YieldOp>(loop.getBody()->getTerminator());
  auto arc = [&](unsigned src, unsigned dst, int64_t theta, int64_t omega,
                 ModuloArcKind kind) {
    p.arcs.push_back({src, dst, theta, omega, kind});
  };

  // Flow dependences. A value arriving through an `iter_arg` is produced by
  // the previous iteration's yield operand, hence an arc of distance one --
  // the recurrence that bounds the period.
  for (unsigned j = 0; j != p.ops.size(); ++j) {
    Operation *use = p.ops[j];
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
      arc(index[def], j, rawLatencyOf(def, resultIdx, use, k), omega,
          ModuloArcKind::RegRaw);
    }
  }

  // Ties. An operand read through the destination shares the result's
  // register, so the op overwrites it, and every other reader of that value
  // has to read first -- an anti-dependence SSA does not show, because the
  // result is a new value. `legalizeTiedOperands` has already moved readers
  // after the op onto a copy, so what is left precedes it in the same
  // iteration (omega 0). The latency is the bundler's WAR rule: the write may
  // share the reader's bundle only if it lands after the read.
  for (unsigned t = 0; t != p.ops.size(); ++t) {
    Operation *tying = p.ops[t];
    const OpTiming *tt = lvxTimingOf(tying);
    for (TiedOperand tie : tiedOperandsOf(tying->getName().stripDialect())) {
      Value c = tying->getOperand(tie.operand);
      int64_t write = writeCycleOf(tying, tt, tie.result);
      for (OpOperand &use : c.getUses()) {
        Operation *reader =
            loop.getBody()->findAncestorOpInBlock(*use.getOwner());
        if (!reader || reader == tying || !index.count(reader))
          continue;
        int64_t read =
            readCycleOf(lvxTimingOf(use.getOwner()), use.getOperandNumber());
        arc(index[reader], t, std::max<int64_t>(0, read - write + 1), 0,
            ModuloArcKind::RegWar);
      }
    }
  }

  // Memory, conservatively: any two accesses of which at least one writes
  // keep their program order within an iteration, and do not cross one.
  // Without a dependence test this is all that can be said, and it is what
  // keeps the period honest rather than optimistic.
  for (unsigned a = 0; a != p.ops.size(); ++a) {
    if (!readsMemory(p.ops[a]) && !writesMemory(p.ops[a]))
      continue;
    if (writesMemory(p.ops[a]))
      arc(a, a, 1, 1, ModuloArcKind::MemCross); // its own next iteration
    for (unsigned b = a + 1; b != p.ops.size(); ++b) {
      bool touches = readsMemory(p.ops[b]) || writesMemory(p.ops[b]);
      if (!touches || (!writesMemory(p.ops[a]) && !writesMemory(p.ops[b])))
        continue;
      arc(a, b, 1, 0, ModuloArcKind::MemIntra);
      arc(b, a, 1, 1, ModuloArcKind::MemCross);
    }
  }

  // The induction's increment, when the body reads the induction variable:
  // an `addd` an iteration. The increment of iteration i computes iv(i+1),
  // so iteration i's readers read what iteration i-1's increment wrote --
  // distance one, both to the readers and around its own recurrence.
  unsigned induction = p.ops.size();
  const OpTiming *adddTiming = timingOf("addd");
  int64_t ivWrite =
      adddTiming ? resultWriteOf(*adddTiming, 0, std::nullopt) : 2;
  for (unsigned j = 0; j != p.ops.size(); ++j)
    for (OpOperand &use : loop.getInductionVar().getUses()) {
      Operation *reader = loop.getBody()->findAncestorOpInBlock(*use.getOwner());
      if (reader != p.ops[j])
        continue;
      int64_t read =
          readCycleOf(lvxTimingOf(use.getOwner()), use.getOperandNumber());
      arc(induction, j, std::max<int64_t>(1, ivWrite - read), 1,
          ModuloArcKind::RegRaw);
      p.induction = true;
    }
  if (p.induction)
    arc(induction, induction,
        std::max<int64_t>(1, ivWrite - readCycleOf(adddTiming, 0)), 1,
        ModuloArcKind::RegRaw);

  // What each node reserves, and how wide the value it defines is.
  SmallVector<unsigned> demandTotal(kNumResources, 0);
  for (Operation *op : p.ops)
    p.demand.push_back(demandOf(op));
  if (p.induction) {
    ResourceVector d{};
    if (const Reservation *r = reservationOf("addd", std::nullopt))
      for (unsigned u = 0; u != r->numUses; ++u)
        d[static_cast<unsigned>(r->uses[u].resource)] += r->uses[u].count;
    p.demand.push_back(d);
  }
  for (const ResourceVector &d : p.demand)
    for (unsigned r = 0; r != kNumResources; ++r)
      demandTotal[r] += d[r];
  p.width.assign(p.numNodes(), 0);
  for (const ModuloArc &a : p.arcs)
    if (a.kind == ModuloArcKind::RegRaw && !p.width[a.src]) {
      if (a.src == induction) {
        p.width[a.src] = 1;
        continue;
      }
      for (Type t : p.ops[a.src]->getResultTypes())
        p.width[a.src] = std::max(p.width[a.src], std::max(1u, widthOf(t)));
    }

  // ResMII: for each resource, the total demand over its availability,
  // rounded up.
  for (unsigned r = 0; r != kNumResources; ++r) {
    unsigned avail = kResourceAvailability[r];
    if (avail && demandTotal[r])
      p.resMII = std::max<int64_t>(p.resMII,
                                   (demandTotal[r] + avail - 1) / avail);
  }

  // RecMII: the period PLC settles on with no floor.
  if (!p.ops.empty()) {
    ParametricLabelCorrecting g;
    p.addTo(g);
    auto result = g.solve(1);
    if (result == ParametricLabelCorrecting::Result::InfeasibleCircuit)
      return loop.emitError("the loop body has a dependence circuit with "
                            "no iteration distance: no period makes it "
                            "feasible");
    if (result != ParametricLabelCorrecting::Result::Solved)
      return loop.emitError("could not compute a resource-free schedule for "
                            "this loop body");
    p.recMII = g.getPeriod();
  }
  return p;
}

void ModuloProblem::addTo(ParametricLabelCorrecting &g) const {
  for (unsigned i = 0; i != numNodes() + 1; ++i)
    g.addNode();
  for (unsigned i = 0; i != numNodes(); ++i)
    g.addArc(0, i + 1, 0, 0);
  for (const ModuloArc &a : arcs)
    g.addArc(a.src + 1, a.dst + 1, a.theta, a.omega);
}

//===----------------------------------------------------------------------===//
// Acceptance.
//===----------------------------------------------------------------------===//

static int64_t rowOf(int64_t date, int64_t ii) {
  return ((date % ii) + ii) % ii;
}

std::optional<std::string>
mlir::lvx::checkDependences(const ModuloProblem &p, int64_t ii,
                            ArrayRef<int64_t> dates) {
  if (dates.size() != p.numNodes())
    return std::string("not one date per node");
  for (const ModuloArc &a : p.arcs)
    if (dates[a.dst] - dates[a.src] < a.theta - a.omega * ii)
      return ("arc " + Twine(a.src) + " -> " + Twine(a.dst) + " (theta " +
              Twine(a.theta) + ", omega " + Twine(a.omega) + ") violated")
          .str();
  return std::nullopt;
}

std::optional<std::string>
mlir::lvx::checkResources(const ModuloProblem &p, int64_t ii,
                          ArrayRef<int64_t> dates) {
  SmallVector<ResourceVector> rows(ii, ResourceVector{});
  for (unsigned i = 0; i != p.numNodes(); ++i)
    for (unsigned r = 0; r != kNumResources; ++r)
      rows[rowOf(dates[i], ii)][r] += p.demand[i][r];
  for (int64_t row = 0; row != ii; ++row)
    for (unsigned r = 0; r != kNumResources; ++r)
      if (rows[row][r] > kResourceAvailability[r])
        return (kResourceName[r] + " oversubscribed in row " + Twine(row))
            .str();
  return std::nullopt;
}

ModuloEngine::~ModuloEngine() = default;

std::optional<ModuloSchedule> mlir::lvx::scheduleLoop(const ModuloProblem &p,
                                                      ModuloEngine &engine,
                                                      unsigned maxRegisters,
                                                      std::string &why) {
  // THE LADDER, AND IT IS ALL THE DRIVER DOES. Whatever search the engine
  // does at one interval is behind `scheduleAtII`; acceptance is the
  // framework's, so an engine's answer -- an external solver's included --
  // cannot reach the construction unverified. A wrong answer is a refusal,
  // never wrong code.
  int64_t first = p.lower();
  LLVM_DEBUG(llvm::dbgs() << "lvx-modulo-schedule: " << engine.name() << ": "
                          << p.ops.size() << " operations"
                          << (p.induction ? " and the induction, " : ", ")
                          << p.arcs.size()
                          << " arcs, RecMII " << p.recMII << ", ResMII "
                          << p.resMII << "\n");
  for (int64_t ii = first; ii <= first + kMaxPeriodRaise; ++ii) {
    ModuloSchedule s;
    s.ii = ii;
    std::string refusal;
    auto refuse = [&](const Twine &reason) {
      why = (engine.name() + " at II = " + Twine(ii) + ": " + reason).str();
      LLVM_DEBUG(llvm::dbgs() << "lvx-modulo-schedule: " << why << "\n");
    };
    if (!engine.scheduleAtII(ii, s.dates, refusal)) {
      refuse(refusal);
      continue;
    }
    if (s.dates.size() != p.numNodes()) {
      refuse("not one date per node");
      continue;
    }
    // The operations' dates from zero, which is what the construction reads
    // stages from. The induction has no operation, and its date only says
    // which row its increment was charged to.
    int64_t lo = s.dates.front();
    for (unsigned i = 0; i != p.ops.size(); ++i)
      lo = std::min(lo, s.dates[i]);
    int64_t maxStage = 0;
    for (auto [i, d] : llvm::enumerate(s.dates)) {
      d -= lo;
      if (i < p.ops.size())
        maxStage = std::max(maxStage, d / ii);
    }
    if (auto bad = checkDependences(p, ii, s.dates)) {
      refuse(*bad);
      continue;
    }
    if (engine.honoursResources())
      if (auto bad = checkResources(p, ii, s.dates)) {
        refuse(*bad);
        continue;
      }
    // One stage: nothing crosses the back edge, and nothing to build.
    if (maxStage == 0)
      return s;
    if (!pipelineAllocates(p.loop, ArrayRef(s.dates).take_front(p.ops.size()),
                           ii, maxRegisters)) {
      refuse("the pipeline does not allocate as well as the loop");
      continue;
    }
    LLVM_DEBUG(if (ii != first) llvm::dbgs()
               << "lvx-modulo-schedule: " << engine.name()
               << " period raised from " << first << " to " << ii << "\n");
    s.pipelined = true;
    s.fitsResources = engine.honoursResources();
    return s;
  }
  return std::nullopt;
}

void mlir::lvx::annotateSchedule(const ModuloProblem &p,
                                 const ModuloSchedule &s) {
  OpBuilder b(p.loop);
  for (unsigned i = 0; i != p.ops.size(); ++i)
    p.ops[i]->setAttr(kDateAttr, b.getI64IntegerAttr(s.dates[i]));
  p.loop->setAttr(kIIAttr, b.getI64IntegerAttr(s.ii));
  if (s.fitsResources)
    p.loop->setAttr(kKeepDatesAttr, b.getUnitAttr());
}

//===----------------------------------------------------------------------===//
// The pass.
//===----------------------------------------------------------------------===//

LogicalResult mlir::lvx::moduloScheduleFunction(lvx_func::FuncOp func,
                                                const ModuloDriverOptions &o) {
  // The copies a tie needs are instructions the stages must place, so they
  // are made now rather than at allocation.
  legalizeTiedOperands(func);
  SmallVector<lvx_scf::ForOp> loops;
  func.walk([&](lvx_scf::ForOp loop) {
    if (isInnermostLoop(loop))
      loops.push_back(loop);
  });

  for (lvx_scf::ForOp loop : loops) {
    if (loop.getBody()->without_terminator().empty())
      continue;
    FailureOr<ModuloProblem> p = ModuloProblem::build(loop);
    if (failed(p))
      return failure();

    std::unique_ptr<ModuloEngine> engine =
        o.engine == "rcms" ? createRCMSEngine(*p, o.rcms) : createDSPEngine(*p);
    std::string why;
    std::optional<ModuloSchedule> s =
        scheduleLoop(*p, *engine, o.maxRegisters, why);

    // DSP is what runs when the solver fails: it needs nothing outside the
    // compiler, so it is the incumbent an RCMS answer has to replace.
    if (!s && o.engine == "rcms" && o.fallback) {
      std::unique_ptr<ModuloEngine> dsp = createDSPEngine(*p);
      std::string dspWhy;
      s = scheduleLoop(*p, *dsp, o.maxRegisters, dspWhy);
      loop.emitRemark("rcms found no schedule (")
          << why << "); " << (s ? "dsp's is taken" : "nor did dsp");
      if (!s)
        why = dspWhy;
    }

    if (!s) {
      loop.emitRemark("not software-pipelined: no period from ")
          << p->lower() << " to " << p->lower() + kMaxPeriodRaise
          << " is accepted; the last refusal: " << why;
      continue;
    }
    if (!s->pipelined)
      continue;
    annotateSchedule(*p, *s);
    if (o.annotatePeriod)
      loop->setAttr("lvx.period", OpBuilder(loop).getI64IntegerAttr(s->ii));
  }
  return success();
}

namespace {

struct LVXModuloSchedulePass
    : public lvx::impl::LVXModuloSchedulePassBase<LVXModuloSchedulePass> {
  using LVXModuloSchedulePassBase::LVXModuloSchedulePassBase;

  void runOnOperation() override {
    ModuloDriverOptions o;
    o.engine = engine;
    if (o.engine != "dsp" && o.engine != "rcms") {
      getOperation().emitError("lvx-modulo-schedule: unknown engine '")
          << o.engine << "'; expected dsp or rcms";
      return signalPassFailure();
    }
    o.maxRegisters = maxRegisters;
    o.annotatePeriod = annotatePeriod;
    o.fallback = fallback;
    o.rcms.solver = rcmsSolver;
    o.rcms.seconds = rcmsSeconds;
    o.rcms.dir = rcmsDir;
    o.rcms.margin = rcmsMargin;
    o.rcms.objective = rcmsObjective;
    if (failed(moduloScheduleFunction(getOperation(), o)))
      signalPassFailure();
  }
};

} // namespace
