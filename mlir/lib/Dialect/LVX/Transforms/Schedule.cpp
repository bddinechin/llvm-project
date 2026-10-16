//===- Schedule.cpp - LVX list scheduling into bundles --------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// The bundler: a cycle list scheduler over each block's dependence DAG,
// after register allocation and loop lowering (lvx-mlir/docs/Bundling.md).
//
// A bundle is legal when, for every resource, what its instructions reserve
// sums to at most what the bundle provides -- the counted-resource check
// `lvx-mbr-as` applies from the same MDS reservations (§2). Dependence
// latencies are differences of the cycles each op reads and writes its
// operands in (`LVXLatency.inc`, §3):
//
//   RAW   b_c - b_p >= max(1, write_p - read_c)
//   WAR   b_w - b_r >= max(0, read_r - write_w + 1)   -- 0: the VLIW property,
//                                                       reads precede writes
//   WAW   b_2 - b_1 >= max(1, write_1 - write_2 + 1)
//
// The clamps are the ISS's own rule: within a bundle every source is read
// before any result is written, and results commit in syllable order, so a
// reader in the same bundle sees the old value (RAW >= 1), a later writer in
// the same bundle is not later (WAW >= 1), and a reader with a later writer
// in the same bundle is fine (WAR >= 0).
//
// The result is a `cycle` attribute on every op of the block -- its issue
// cycle relative to the block's start, as lvx-gcc's scheduler records it --
// with the block reordered so equal cycles are contiguous; `-lvx-emit-asm`
// closes a bundle where the cycle changes. An op without the attribute is
// printed as its own bundle, so IR that never went through this pass emits
// as before.
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/LVX/Transforms/Passes.h"

#include "mlir/Dialect/LVX/IR/LVX.h"
#include "mlir/Dialect/LVX/IR/LVXImmediates.h"
#include "mlir/Dialect/LVX/IR/LVXLatency.h"
#include "mlir/Dialect/LVX/IR/LVXScheduling.h"
#include "mlir/Dialect/LVX/IR/RegisterUnits.h"
#include "mlir/Dialect/LVXCF/IR/LVXCF.h"
#include "mlir/Dialect/LVXFunc/IR/LVXFunc.h"
#include "mlir/Interfaces/SideEffectInterfaces.h"
#include "llvm/ADT/SmallString.h"
#include "llvm/ADT/SmallVector.h"

namespace mlir {
namespace lvx {
#define GEN_PASS_DEF_LVXSCHEDULEPASS
#include "mlir/Dialect/LVX/Transforms/Passes.h.inc"
} // namespace lvx
} // namespace mlir

using namespace mlir;
using namespace mlir::lvx;

namespace {

/// What makes a bundle legal: the execution-unit and resource counters, and
/// nothing else. For every resource, the sum of what the bundle's instructions
/// reserve must be at most `kResourceAvailability` -- TINY 4, LITE 2, FULL 1,
/// LSU 2, BCU 2, EXT 4, and IMMX 8, the immediate-extension syllables.
///
/// There is deliberately no separate instruction or syllable count here.
/// `LVX_MAXBUNDLEISSUE` (10) and `LVX_MAXBUNDLEWORDS` (18) in lvx-binutils'
/// `include/opcode/lvx.h` are consequences of the unit counts rather than
/// independent limits: 4 TINY + 2 BCU + 4 EXT is itself 10, and 18 is those 10
/// instruction words plus IMMX's own availability of 8. Checking them again
/// here would be checking the same machine twice, and the second copy is the
/// one that goes stale -- which is how the retired `ISSUE` resource, 8
/// syllables, outlived its own deletion in this file's comments.
///
/// IMMX is worth naming because it is the one resource that counts something
/// other than a unit, and because it was briefly wrong on both sides: gas took
/// only six, its `lvx_immx_buffer` being dimensioned `LVX_MAXOPERANDS` (7)
/// with a bound test that incremented before it compared. That off-by-one was
/// unreachable while the budget covered whole instruction words and became
/// reachable when lvx-mds narrowed it to extensions (69b9cba, 2026-10-07). It
/// is fixed in lvx-binutils, so the description's 8 is what both sides hold.
/// The attribute the schedule is recorded in: `cycle`, the issue cycle
/// relative to the block's start, declared on every op of the four dialects
/// (LVX_CycleAttr in LVXBase.td), so it is the op's own typed state rather
/// than a discardable annotation. A bundle is the ops of one cycle.
constexpr StringLiteral kCycleAttr = "cycle";

//===----------------------------------------------------------------------===//
// What an op is to the scheduler: the instruction it prints (if any), and
// so its reservation and timing.
//===----------------------------------------------------------------------===//

/// The mnemonic of the instruction `op` prints, which is the key into the
/// generated tables. A pseudo that prints nothing has none; a pseudo that
/// prints a real instruction (`lvx.li` prints `maked`, `lvx.mv` a copy at
/// its width) is that instruction.
/// The instruction `op` really is. An `lvx.guarded` is a prefix wrapped round
/// one instruction: what it reserves, reads, writes and prints is that
/// instruction's, and the prefix is accounted separately by `prefixOf` so two
/// guarded ops sharing a condition share one syllable.
static Operation *instructionOf(Operation *op) {
  if (auto guarded = dyn_cast<GuardedOp>(op))
    return guarded.guardedOp();
  return op;
}

static std::optional<StringRef> printedMnemonic(Operation *op) {
  if (auto guarded = dyn_cast<GuardedOp>(op))
    return printedMnemonic(guarded.guardedOp());
  if (isa<LiOp>(op))
    return StringRef("maked");
  if (auto mv = dyn_cast<MvOp>(op)) {
    switch (widthOf(mv.getResult().getType())) {
    case 1:
      return StringRef("copyd");
    case 2:
      return StringRef("catdq");
    default:
      return StringRef("copyo");
    }
  }
  // A masked access reserves its LSU slot as the bare access does; the BCU
  // syllable its `maskm` prefix takes is accounted separately, since two
  // masked ops sharing a prefix share that one syllable (`prefixOf`).
  if (auto ml = dyn_cast<lvx::MaskedLoadOp>(op))
    return widthOf(ml.getResult().getType()) == 4 ? StringRef("lo")
                                                  : StringRef("lq");
  if (auto ms = dyn_cast<lvx::MaskedStoreOp>(op))
    return widthOf(ms.getValue().getType()) == 4 ? StringRef("so")
                                                 : StringRef("sq");
  if (isa<LaneOp, ConcatOp, SpOp, RegLiveInOp, RegLiveOutOp>(op))
    return std::nullopt;
  if (isa<lvx_cf::LoopendOp>(op))
    return std::nullopt; // a comment; the loop-back is the hardware's
  if (isa<lvx_cf::BranchOp>(op))
    return StringRef("goto");
  if (isa<lvx_cf::CondBranchOp>(op))
    return StringRef("cb");
  if (isa<lvx_cf::LoopdoOp>(op))
    return StringRef("loopdo");
  if (isa<lvx_func::CallOp>(op))
    return StringRef("call");
  if (isa<lvx_func::ReturnOp>(op))
    return StringRef("ret");
  if (op->getDialect() && op->getDialect()->getNamespace() == "lvx")
    return op->getName().stripDialect();
  return std::nullopt;
}

/// The cycle `op` reads operand `i` in, and writes result `i` in. RR = 1 and
/// E1 = 2 where the table has nothing to say: a pseudo, or a control op
/// whose operands are registers read at issue.
/// `readCycleOf` and `writeCycleOf` are shared with the pipeliner, in
/// LVXLatency.h: the two must agree, a pipeline staged for a three-cycle load
/// not covering a fifteen-cycle one.
static unsigned readCycle(const OpTiming *t, unsigned i) {
  return readCycleOf(t, i);
}

//===----------------------------------------------------------------------===//
// Format selection: the ISSUE count of a reservation depends on the format,
// and an op's format is chosen from its immediate's value (§2).
//===----------------------------------------------------------------------===//

/// Sets `format` on an op with an immediate that has none yet: the narrowest
/// form the immediate fits, among the forms whose required unit modifiers
/// are exactly the ones the op carries (a `.m` form wants `splat32` and a
/// bare form wants its absence). Fails if no form fits, which is an
/// immediate the ISA cannot encode in this instruction.
static LogicalResult chooseFormat(Operation *op, StringRef mnemonic) {
  const OpImmediate *imm = immediateOf(mnemonic);
  if (!imm || op->hasAttr("format"))
    return success();
  auto valueAttr = dyn_cast_or_null<TypedAttr>(op->getAttr(imm->attribute));
  // `lvx.li` is a hand-written pseudo and keeps its immediate in `value`,
  // while the table is written for the real `maked` and calls it `signed16`.
  // Every other op that prints an immediate agrees with the table by name --
  // the generated `*_i` ops carry `signed10` and the memory ops `offset`, the
  // masked-access pseudos included -- so this is the one exception.
  //
  // It mattered: without it `chooseFormat` found nothing, returned success
  // with no `format`, and the bare form stood, so a 64-bit `maked` was billed
  // as one syllable instead of the three its `.Y` form takes. Four of them in
  // a bundle then overflowed the syllable budget and gas refused the output
  // -- "resource ISSUE over-used in bundle: 9 used, 8 available" as the
  // resource was then spelled. Since the 2026-10-07 rename it is `IMMX`,
  // counting extensions alone, and four `.Y` forms are exactly its
  // availability of 8 -- legal, and all four TINY slots. Going past 8 needs a
  // unit that carries an extension without a TINY slot, which is `BCU2_X`
  // (1 IMMX, 0 TINY, availability 2), so the reachable ceiling is 10 and the
  // limit is real rather than shadowed by TINY. Latent until non-splat vector
  // constants started emitting large immediates in quantity.
  if (!valueAttr)
    if (auto li = dyn_cast<LiOp>(op))
      valueAttr = dyn_cast_or_null<TypedAttr>(li.getValueAttr());
  if (!valueAttr)
    return success(); // not this op's shape (a register form); bare stands
  APInt value;
  if (auto i = dyn_cast<IntegerAttr>(valueAttr))
    value = i.getValue();
  else if (auto f = dyn_cast<FloatAttr>(valueAttr))
    value = f.getValue().bitcastToAPInt();
  else
    return success();

  ArrayRef<ImmediateForm> forms(imm->forms, imm->numForms);
  for (const ImmediateForm &form : forms) {
    // The op's unit modifiers must be exactly the form's.
    bool match = true;
    for (unsigned k = 0; k != form.numRequiredUnits; ++k)
      match &= op->hasAttr(form.requiredUnits[k]);
    for (const ImmediateForm &other : forms)
      for (unsigned k = 0; k != other.numRequiredUnits; ++k) {
        bool required = false;
        for (unsigned j = 0; j != form.numRequiredUnits; ++j)
          required |= form.requiredUnits[j] == other.requiredUnits[k];
        if (!required && op->hasAttr(other.requiredUnits[k]))
          match = false;
      }
    if (!match || !valueFits(value, form))
      continue;
    if (form.formatSlot != kBareFormatSlot)
      op->setAttr("format",
                  FormatAttr::get(op->getContext(),
                                  static_cast<Format>(form.formatSlot)));
    return success();
  }
  SmallString<32> text;
  value.toStringSigned(text);
  return op->emitError("lvx-schedule: immediate ")
         << text << " fits no format of " << mnemonic;
}

//===----------------------------------------------------------------------===//
// The dependence DAG of one block.
//===----------------------------------------------------------------------===//

struct Edge {
  unsigned to;
  unsigned latency;
};

/// What a BCU prefix is, for the purpose of sharing one between the syllables
/// of a bundle: the mask register it reads and the modifier it applies. Two
/// prefixed ops in one bundle need one syllable between them when these agree
/// and one each when they do not -- the rule lvx-gcc's `lvx_sched_dfa_new_cycle`
/// implements with `rtx_equal_p` on the guard condition.
struct PrefixKey {
  Value mask;
  StringRef modifier;
  bool operator==(const PrefixKey &o) const {
    return mask == o.mask && modifier == o.modifier;
  }
};

/// The BCU prefix `op` needs, if any. `maskm.mt` for a masked access; a
/// `guard`-predicated op would key the same way on its condition register.
static std::optional<PrefixKey> prefixOf(Operation *op) {
  if (auto ml = dyn_cast<lvx::MaskedLoadOp>(op))
    return PrefixKey{ml.getMask(), "maskm.mt"};
  if (auto ms = dyn_cast<lvx::MaskedStoreOp>(op))
    return PrefixKey{ms.getMask(), "maskm.mt"};
  // The condition *and* the sense: `guard.wnez $r5?` and `guard.weqz $r5?`
  // are two prefixes, which is what makes an if-converted diamond's two arms
  // cost two syllables in a bundle holding both and one in a bundle holding
  // either.
  if (auto guarded = dyn_cast<GuardedOp>(op))
    return PrefixKey{guarded.getCondition(),
                     stringifyBcuCond(guarded.getExecpred())};
  return std::nullopt;
}

struct Node {
  Operation *op;
  const Reservation *reservation = nullptr; // null: takes no resources
  std::optional<PrefixKey> prefix;          // the BCU prefix syllable it needs
  const OpTiming *timing = nullptr;
  SmallVector<Edge, 4> succs;
  unsigned numPreds = 0;
  unsigned height = 0;    // longest latency path to the end of the block
  unsigned earliest = 0;  // the first bundle every predecessor allows
  unsigned predsPlaced = 0;
  std::optional<unsigned> bundle;
  /// Which register unit this op reads and writes, and in which cycle --
  /// recorded as the dependence edges are built, so the cross-iteration
  /// analysis (§4, `buildCarried`) can run over the same facts without
  /// repeating how an operand's units are found.
  SmallVector<std::pair<unsigned, unsigned>, 4> unitReads, unitWrites;
  /// Whether it touches memory, and whether it writes.
  bool touchesMemory = false, writesMemory = false;
  /// The first bundle the back edge allows, for a cyclic block: a use of a
  /// value the previous trip defined cannot issue before that definition's
  /// latency has elapsed, counting the body length (`listSchedule`).
  unsigned release = 0;
};

/// A dependence that crosses the back edge of a hardware-loop body: the
/// definition is in one trip and the use in the next, so for a body of `L`
/// cycles the constraint is
///
///   cycle[def] + latency <= cycle[use] + L
///
/// which is a bound on `L` once both are placed, and a release date on the
/// use once `L` is fixed. Modulo scheduling's one constraint, for the one
/// block shape where nothing else expresses it.
struct Carried {
  unsigned def, use, latency;
};

/// A value's defining node in this block, looked through `lvx.lane`: a lane
/// is the register its source's lane is, so a use of it depends on the
/// source's producer, not on the (empty) lane op.
static Value throughLanes(Value v) {
  while (auto lane = v.getDefiningOp<LaneOp>())
    v = lane.getSource();
  return v;
}

class BlockScheduler {
public:
  BlockScheduler(Block &block) : block(block) {}

  LogicalResult run() {
    cyclic = !block.empty() && block.mightHaveTerminator() &&
             isa<lvx_cf::LoopendOp>(block.getTerminator());
    if (failed(build()))
      return failure();
    schedule();
    apply();
    return success();
  }

private:
  Block &block;
  SmallVector<Node> nodes;
  DenseMap<Operation *, unsigned> index;
  /// Whether this block is a hardware-loop body, so that its last bundle is
  /// followed by its first. `lvx_cf.loopend` is what says so.
  bool cyclic = false;
  /// The dependences crossing the back edge, for a cyclic block.
  SmallVector<Carried> carried;
  /// The body length the back edge forces, once scheduled: the longest a
  /// trip must last for every carried dependence to hold. For an acyclic
  /// block this is the span and nothing more.
  unsigned bodyCycles = 0;

  void addEdge(unsigned from, unsigned to, unsigned latency) {
    if (from == to)
      return;
    nodes[from].succs.push_back({to, latency});
    ++nodes[to].numPreds;
  }

  LogicalResult build() {
    for (Operation &op : block) {
      index[&op] = nodes.size();
      Node n;
      n.op = &op;
      if (std::optional<StringRef> mnemonic = printedMnemonic(&op)) {
        Operation *insn = instructionOf(&op);
        if (failed(chooseFormat(insn, *mnemonic)))
          return failure();
        std::optional<Format> format;
        if (auto f = insn->getAttrOfType<FormatAttr>("format"))
          format = f.getValue();
        n.reservation = reservationOf(*mnemonic, format);
        n.timing = timingOf(*mnemonic);
      }
      n.prefix = prefixOf(&op);
      nodes.push_back(n);
    }

    // Register dependences, per unit: the last writer and the readers since.
    struct Access {
      unsigned node;
      unsigned cycle;
    };
    DenseMap<unsigned, Access> lastWriter;
    DenseMap<unsigned, SmallVector<Access, 4>> readersSince;
    // Memory: every access since the last barrier, and whether it wrote.
    SmallVector<std::pair<unsigned, bool>> memoryOps;
    std::optional<unsigned> lastBarrier;

    auto unitsOf = [](Value v) -> std::optional<PhysLoc> {
      return pinnedLoc(v.getType());
    };

    for (auto [i, n] : llvm::enumerate(nodes)) {
      // The guarded instruction's own operands and results are the reads and
      // writes; the wrapper holds only the condition, which the prefix reads
      // and which the edge below adds.
      Operation *op = instructionOf(n.op);

      // Reads, in operand order: the units of each pinned operand.
      for (auto [k, operand] : llvm::enumerate(op->getOperands())) {
        std::optional<PhysLoc> loc = unitsOf(throughLanes(operand));
        if (!loc)
          continue;
        unsigned r = readCycle(n.timing, k);
        for (unsigned u = loc->base; u != loc->end(); ++u) {
          if (auto w = lastWriter.find(u); w != lastWriter.end()) {
            unsigned lat = w->second.cycle > r ? w->second.cycle - r : 0;
            addEdge(w->second.node, i, std::max(1u, lat));
          }
          readersSince[u].push_back({(unsigned)i, r});
          n.unitReads.push_back({u, r});
        }
      }
      // The prefix's own read: an `lvx.guarded` holds the condition register,
      // not the instruction, so the loop above (which walks the instruction's
      // operands, and uses their index to find their read cycle) never sees
      // it. Without this edge the guarded op could be placed before the
      // compare that produced its condition. Cycle 1, which is what
      // `LVXLatency.inc` gives `guard`.
      if (auto guarded = dyn_cast<GuardedOp>(n.op)) {
        if (std::optional<PhysLoc> loc =
                unitsOf(throughLanes(guarded.getCondition())))
          for (unsigned u = loc->base; u != loc->end(); ++u) {
            if (auto w = lastWriter.find(u); w != lastWriter.end())
              addEdge(w->second.node, i,
                      std::max(1u, w->second.cycle > 1 ? w->second.cycle - 1 : 0));
            readersSince[u].push_back({(unsigned)i, 1});
            n.unitReads.push_back({u, 1});
          }
      }

      // Writes: the units of each pinned result. A lane or concat op
      // writes nothing (its result IS its source's register, or its parts'
      // registers) and a reg_live_in names an incoming value: all are
      // placed by their uses alone.
      if (!isa<LaneOp, ConcatOp>(op)) {
        for (auto [k, result] : llvm::enumerate(op->getResults())) {
          std::optional<PhysLoc> loc = unitsOf(result);
          if (!loc)
            continue;
          unsigned w = writeCycleOf(op, n.timing, k);
          for (unsigned u = loc->base; u != loc->end(); ++u) {
            if (auto prev = lastWriter.find(u); prev != lastWriter.end()) {
              unsigned lat = prev->second.cycle + 1 > w ? prev->second.cycle + 1 - w : 0;
              addEdge(prev->second.node, i, std::max(1u, lat));
            }
            for (const Access &rd : readersSince[u]) {
              unsigned lat = rd.cycle + 1 > w ? rd.cycle + 1 - w : 0;
              addEdge(rd.node, i, lat);
            }
            readersSince[u].clear();
            lastWriter[u] = {(unsigned)i, w};
            n.unitWrites.push_back({u, w});
          }
        }
      }
      // A lane's result must still follow its source in the block (SSA
      // order), at no cost.
      if (auto lane = dyn_cast<LaneOp>(op))
        if (Operation *def = lane.getSource().getDefiningOp())
          if (auto it = index.find(def); it != index.end())
            addEdge(it->second, i, 0);
      if (auto concat = dyn_cast<ConcatOp>(op))
        for (Value part : concat.getParts())
          if (Operation *def = part.getDefiningOp())
            if (auto it = index.find(def); it != index.end())
              addEdge(it->second, i, 0);
      // And symmetrically, an op reading a pseudo's result must follow it.
      // The register edges above do not cover this: a lane's reader is made
      // to follow the *tuple's* producer (`throughLanes`), which is the real
      // dependence, but nothing then orders it after the lane op itself.
      // That is invisible in the assembly -- the pseudo prints nothing --
      // and fatal in the IR, which must stay valid SSA: `operand #0 does not
      // dominate this use`. A quad's low pair stored straight through a
      // lane view is the shape that found it.
      for (Value operand : op->getOperands())
        if (Operation *def = operand.getDefiningOp())
          if (isa<LaneOp, ConcatOp>(def))
            if (auto it = index.find(def); it != index.end())
              addEdge(it->second, i, 0);
      // And every pseudo result's user follows it: the register edges above
      // cover real ops; a pseudo with a pinned result (sp, reg_live_in) is
      // covered too, since it writes its units. An unpinned result cannot
      // reach here after allocation.

      // Memory and barriers.
      bool isBarrier = false, reads = false, writes = false;
      if (op->hasTrait<OpTrait::IsTerminator>() || isa<lvx_func::CallOp>(op)) {
        isBarrier = true;
      } else if (auto effects = dyn_cast<MemoryEffectOpInterface>(op)) {
        SmallVector<MemoryEffects::EffectInstance> instances;
        effects.getEffects(instances);
        for (const auto &e : instances) {
          reads |= isa<MemoryEffects::Read>(e.getEffect());
          writes |= isa<MemoryEffects::Write>(e.getEffect());
        }
      } else if (!op->hasTrait<OpTrait::IsTerminator>() &&
                 !isa<LaneOp, SpOp, RegLiveInOp, RegLiveOutOp>(op)) {
        // No effect interface at all: unknown effects, a barrier.
        isBarrier = true;
      }
      if (isBarrier) {
        // Everything before it precedes it; everything after follows it.
        for (unsigned j = 0; j != i; ++j)
          addEdge(j, i, isa<lvx_func::CallOp>(nodes[j].op) ? 1 : 0);
        lastBarrier = i;
        memoryOps.clear();
      } else {
        if (lastBarrier)
          addEdge(*lastBarrier, i, 0);
        if (reads || writes) {
          for (auto [j, wrote] : memoryOps)
            if (wrote || writes)
              addEdge(j, i, 1);
          memoryOps.push_back({(unsigned)i, writes});
          n.touchesMemory = true;
          n.writesMemory = writes;
        }
      }
    }

    // A terminator ends the block: nothing may be placed after it, which
    // the barrier edges say, and its own bundle is the last. Ops after the
    // terminator do not exist.
    if (cyclic)
      buildCarried();
    return success();
  }

  /// The dependences that cross a hardware loop's back edge.
  ///
  /// The body of an `lvx_cf.loopdo` is a block whose back edge is not in the
  /// CFG: `lvx_cf.loopend` branches to the *exit*, the loop-carried values
  /// arrive as block arguments fed only by the preheader, and the next trip
  /// reads what this trip wrote only because the allocator gave them the same
  /// register. So nothing in the DAG above says that after the body's last
  /// bundle its first bundle issues again, and a register written late and
  /// read early is read before its write lands. A *branch* loop never had the
  /// problem: its back branch carries the value as a block argument, so the
  /// terminator's read is an ordinary RAW edge and the bound follows.
  ///
  /// What crosses, per register unit, is the pairing of this trip's end with
  /// the next trip's beginning: the last writer against the uses that read
  /// the incoming value (RAW) and against the first writer (WAW), and the
  /// reads left after the last write against that first writer (WAR). Memory
  /// crosses wholesale -- every access of a trip precedes every access of the
  /// next -- so each pair of which one writes is serialised at 1, as within
  /// the block.
  void buildCarried() {
    struct Access {
      unsigned node, cycle;
    };
    DenseMap<unsigned, Access> firstWriter, lastWriter;
    DenseMap<unsigned, SmallVector<Access, 2>> incomingReaders, trailingReaders;
    SmallVector<std::pair<unsigned, bool>> memory;

    for (auto [i, n] : llvm::enumerate(nodes)) {
      if (isPhantom(n.op))
        continue; // not an instruction: see `isPhantom`
      // Reads before writes, as the edge builder does: an op that reads a
      // unit and writes it back (a tied accumulator) reads the old value.
      for (auto [u, r] : n.unitReads) {
        if (!firstWriter.count(u))
          incomingReaders[u].push_back({(unsigned)i, r});
        trailingReaders[u].push_back({(unsigned)i, r});
      }
      for (auto [u, w] : n.unitWrites) {
        if (!firstWriter.count(u))
          firstWriter[u] = {(unsigned)i, w};
        lastWriter[u] = {(unsigned)i, w};
        trailingReaders[u].clear();
      }
      if (n.touchesMemory)
        memory.push_back({(unsigned)i, n.writesMemory});
    }

    for (auto &[u, last] : lastWriter) {
      for (const Access &rd : incomingReaders[u])
        carried.push_back({last.node, rd.node,
                           std::max(1u, last.cycle > rd.cycle
                                            ? last.cycle - rd.cycle
                                            : 0u)});
      const Access &first = firstWriter[u];
      if (first.node != last.node)
        carried.push_back(
            {last.node, first.node,
             std::max(1u, last.cycle + 1 > first.cycle
                              ? last.cycle + 1 - first.cycle
                              : 0u)});
    }
    for (auto &[u, first] : firstWriter)
      for (const Access &rd : trailingReaders[u])
        carried.push_back({rd.node, first.node,
                           rd.cycle + 1 > first.cycle
                               ? rd.cycle + 1 - first.cycle
                               : 0u});
    for (auto [a, writesA] : memory)
      for (auto [b, writesB] : memory)
        if (writesA || writesB)
          carried.push_back({a, b, 1});
  }

  /// Whether `op` is the block's terminator and prints no instruction, which
  /// is `lvx_cf.loopend` and nothing else. Such an op occupies no cycle: it
  /// is a comment standing for a back edge the hardware takes, and its
  /// operands are the values the *exit* block receives, not reads the loop
  /// performs. Both matter, because the dependence edge from its operand's
  /// producer places it well past the body's last real bundle -- harmless
  /// while nothing asked how long the body is, and an overstatement of four
  /// cycles on `mymma`'s kernel once something did.
  /// `mightHaveTerminator` because not every block has one: `lvx.guarded`
  /// wraps its instruction in a region whose block is a bare op list, and
  /// the pass schedules every block it walks. `getTerminator` asserts there.
  bool isPhantom(Operation *op) const {
    return block.mightHaveTerminator() && op == block.getTerminator() &&
           !printedMnemonic(op);
  }

  /// The span of the current placement: one past the last bundle that issues
  /// an instruction. `-lvx-emit-asm` closes the block after the last op that
  /// prints anything, so that is the block's length.
  unsigned span() const {
    unsigned s = 0;
    for (const Node &n : nodes)
      if (n.bundle && !isPhantom(n.op))
        s = std::max(s, *n.bundle + 1);
    return s;
  }

  /// How long a trip must last for every carried dependence to hold, given
  /// where the current placement put each end of it.
  unsigned carriedBound() const {
    unsigned bound = 0;
    for (const Carried &c : carried) {
      unsigned def = *nodes[c.def].bundle, use = *nodes[c.use].bundle;
      if (def + c.latency > use)
        bound = std::max(bound, def + c.latency - use);
    }
    return bound;
  }

  void schedule() {
    // Heights: longest latency path to a sink, over the reverse order (edges
    // only go forward in block order).
    for (unsigned i = nodes.size(); i-- > 0;) {
      unsigned h = 0;
      for (const Edge &e : nodes[i].succs)
        h = std::max(h, nodes[e.to].height + e.latency);
      nodes[i].height = h;
    }

    listSchedule();
    bodyCycles = std::max(span(), carriedBound());
    if (carried.empty())
      return;

    // A cyclic block takes `max(span, carriedBound)` cycles, the hardware
    // interlocking over the difference. The span is a lower bound on that and
    // the list scheduler already minimises it, so what is left is to bring the
    // bound down to it -- by holding each carried *use* until the definition
    // it reads has had its latency, counting a trip of the target length. A
    // use is otherwise placed as early as it is ready, which is the worst
    // place for this bound and costs nothing to give up: in `mymma`'s
    // pipelined kernel the store of the previous trip's accumulator sits in
    // cycle 0 for no reason at all, and moving it to cycle 2 takes the body
    // from 9 cycles to 7 with the same six bundles.
    //
    // Iterate, because a release can lengthen the span (the WAR edge from a
    // delayed read to the in-trip writer pushes that writer, and its readers,
    // later) and then the target moves. Three rounds, keeping the best, is
    // enough for the shapes we have; it is a fixpoint on the cyclic schedule
    // rather than a modulo scheduler, which is §8 step 4's job.
    SmallVector<unsigned> best;
    auto remember = [&] {
      best.clear();
      for (const Node &n : nodes)
        best.push_back(*n.bundle);
    };
    remember();
    unsigned target = span();
    for (unsigned round = 0; round != 3 && bodyCycles > target; ++round) {
      bool moved = false;
      for (const Carried &c : carried) {
        unsigned need = *nodes[c.def].bundle + c.latency;
        unsigned release = need > target ? need - target : 0;
        if (release > nodes[c.use].release) {
          nodes[c.use].release = release;
          moved = true;
        }
      }
      if (!moved)
        break;
      listSchedule();
      unsigned length = std::max(span(), carriedBound());
      if (length >= bodyCycles)
        break; // no better; keep what `best` holds
      bodyCycles = length;
      remember();
    }
    for (auto [i, n] : llvm::enumerate(nodes))
      n.bundle = best[i];
  }

  void listSchedule() {
    for (Node &n : nodes) {
      n.earliest = n.release;
      n.predsPlaced = 0;
      n.bundle = std::nullopt;
    }

    // Cycle scheduling: one bundle at a time, by priority among the ready.
    unsigned placed = 0, bundle = 0;
    SmallVector<unsigned> ready; // every pred placed, whatever its cycle
    for (auto [i, n] : llvm::enumerate(nodes))
      if (n.numPreds == 0)
        ready.push_back(i);

    while (placed != nodes.size()) {
      unsigned used[kNumResources] = {};
      // Syllables and instructions issued in this bundle. The unit resources
      // bound each function unit; these bound the bundle as a whole, which no
      // resource does since ISSUE was retired.
      // The distinct BCU prefixes already issued in this bundle. A prefixed
      // op whose prefix is among them costs no further syllable: the
      // assembler merges it into the one already there (gas
      // `lvx_cond_insn_merge`, which ORs the new unit into that syllable's
      // activate mask). One that is not needs a BCU slot of its own, and
      // there are two -- so a bundle holds at most two distinct prefixes,
      // however many syllables they govern between them.
      SmallVector<PrefixKey, 2> prefixes;
      bool progress = true;
      while (progress) {
        progress = false;
        // Highest height first; source order breaks ties, for a
        // deterministic schedule.
        llvm::stable_sort(ready, [&](unsigned a, unsigned b) {
          return nodes[a].height > nodes[b].height;
        });
        for (unsigned k = 0; k != ready.size(); ++k) {
          Node &n = nodes[ready[k]];
          if (n.earliest > bundle)
            continue;
          // A prefix already in this bundle is free; a new one takes a BCU
          // slot, on top of whatever the op itself reserves. That is its whole
          // cost here: it occupies a syllable but carries no immediate
          // extension, so it belongs against `bcu` and not against `immx`.
          // With `bcu` availability 2 this is exactly lvx-gcc's rule in
          // `lvx_sched_dfa_new_cycle` -- a bundle holds at most two distinct
          // prefixes.
          bool newPrefix = n.prefix && !llvm::is_contained(prefixes, *n.prefix);
          unsigned extra[kNumResources] = {};
          if (newPrefix)
            extra[static_cast<unsigned>(Resource::bcu)] = 1;
          bool fits = true;
          for (unsigned idx = 0; idx != kNumResources; ++idx)
            if (extra[idx] &&
                used[idx] + extra[idx] > kResourceAvailability[idx])
              fits = false;
          if (n.reservation) {
            for (unsigned r = 0; r != n.reservation->numUses; ++r) {
              const ResourceUse &use = n.reservation->uses[r];
              unsigned idx = static_cast<unsigned>(use.resource);
              if (used[idx] + extra[idx] + use.count >
                  kResourceAvailability[idx])
                fits = false;
            }
          }
          if (!fits)
            continue;
          for (unsigned idx = 0; idx != kNumResources; ++idx)
            used[idx] += extra[idx];
          if (newPrefix)
            prefixes.push_back(*n.prefix);
          if (n.reservation) {
            for (unsigned r = 0; r != n.reservation->numUses; ++r)
              used[static_cast<unsigned>(n.reservation->uses[r].resource)] +=
                  n.reservation->uses[r].count;
          }
          n.bundle = bundle;
          ++placed;
          for (const Edge &e : n.succs) {
            Node &s = nodes[e.to];
            s.earliest = std::max(s.earliest, bundle + e.latency);
            if (++s.predsPlaced == s.numPreds)
              ready.push_back(e.to);
          }
          ready.erase(ready.begin() + k);
          progress = true;
          break; // re-sort: new nodes may be ready in this same bundle
        }
      }
      ++bundle;
    }
  }

  void apply() {
    // Reorder the block by (bundle, original order) and stamp the index.
    SmallVector<Operation *> order;
    for (Node &n : nodes)
      order.push_back(n.op);
    llvm::stable_sort(order, [&](Operation *a, Operation *b) {
      return *nodes[index[a]].bundle < *nodes[index[b]].bundle;
    });
    OpBuilder builder(block.getParentOp()->getContext());
    // What a trip of a hardware loop really costs. The bundles say `span()`,
    // and the back edge can make it more -- LVX interlocks, so the difference
    // is stalls the hardware takes rather than a wrong answer, but it is a
    // cost nothing else records and the one number a loop is measured by.
    // `-lvx-emit-asm` prints it on the body's closing comment.
    if (cyclic && !nodes.empty())
      block.getTerminator()->setAttr(
          "lvx.body_cycles", builder.getI64IntegerAttr(bodyCycles));
    Operation *prev = nullptr;
    for (Operation *op : order) {
      op->setAttr(kCycleAttr,
                  builder.getI64IntegerAttr(*nodes[index[op]].bundle));
      if (prev)
        op->moveAfter(prev);
      else
        op->moveBefore(&block, block.begin());
      prev = op;
    }
  }
};

//===----------------------------------------------------------------------===//
// The pass
//===----------------------------------------------------------------------===//

struct LVXSchedulePass : public lvx::impl::LVXSchedulePassBase<LVXSchedulePass> {
  using LVXSchedulePassBase::LVXSchedulePassBase;

  void runOnOperation() override {
    lvx_func::FuncOp func = getOperation();
    if (func.isExternal())
      return;
    // Every block, innermost first; a block is scheduled on its own and an
    // op with a region (a structured loop the pipeline did not lower) is a
    // barrier in its block.
    SmallVector<Block *> blocks;
    func.walk([&](Block *b) { blocks.push_back(b); });
    for (Block *b : blocks) {
      BlockScheduler scheduler(*b);
      if (failed(scheduler.run()))
        return signalPassFailure();
    }
  }
};

} // namespace
