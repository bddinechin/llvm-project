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

/// A bundle's size limits, tracking lvx-binutils' include/opcode/lvx.h.
///
/// `LVX_MAXBUNDLEISSUE` is 10 because that is the issue slots a bundle has:
/// 2x BCU + 2x ALU + 2x LSU + 2x EXT + 2x TINY, the TINY pair being what the
/// planned LSU/TINY decoupling extracts from the LSU. `LVX_MAXBUNDLEWORDS` is
/// 18 = those 10 instruction words plus at most 8 immediate extension
/// syllables -- and that 8 is exactly IMMX's availability in Resource.yml.
///
/// So the two are not independent: words = issues + immx, and since the IMMX
/// resource already caps immx at 8, bounding issues at 10 implies words <= 18.
/// The word count is still carried and checked, because it is the limit gas
/// actually tests ("bundle has too many syllables: %d instead of %d" in
/// tc-lvx.c, on `word_cnt + lvx_immx_cnt`) and the one a reader will compare
/// against; if the relation above ever stops holding, this is where it shows.
///
/// These replace the ISSUE resource, which used to cap a bundle at 8 syllables
/// and is gone from Resource.yml; IMMX inherited its availability of 8 but
/// counts only extension words, so it bounds a part of a bundle, not the whole.
constexpr unsigned kMaxBundleIssue = 10; // LVX_MAXBUNDLEISSUE
constexpr unsigned kMaxBundleWords = 18; // LVX_MAXBUNDLEWORDS

/// The immediate extensions a bundle may carry: 8, which is `IMMX`'s
/// `availability` in Resource.yml and the number `LVX_MAXBUNDLEWORDS` is built
/// from (18 = 10 instruction words + 8 extensions).
///
/// gas accepted only six for a while, and not by design: `lvx_immx_buffer` was
/// dimensioned `LVX_MAXOPERANDS` (7) and the bound test incremented before it
/// compared, so the seventh was fatal -- "[lvx_insn_add_immx] max number of
/// IMMX exceeded: 7". That off-by-one was unreachable while the syllable budget
/// covered whole words, and became reachable when the budget narrowed to
/// extensions only; it is fixed in lvx-binutils, which now takes 8.
///
/// So this must not go below 8 again without checking the assembler, and must
/// not go above it without checking Resource.yml. lvx-llvm's LVXBundler holds
/// the same number as `MaxImmxPerBundle`.
constexpr unsigned kMaxBundleImmx = 8;

/// The immediate extension words an op's reservation takes -- the `.X` and `.Y`
/// formats. Equivalently all of an instruction's syllables but the first, which
/// is how lvx-llvm's `immxOf` computes it.
static unsigned immxOf(const Reservation *reservation) {
  unsigned immx = 0;
  if (reservation)
    for (unsigned i = 0; i != reservation->numUses; ++i)
      if (reservation->uses[i].resource == Resource::immx)
        immx += reservation->uses[i].count;
  return immx;
}

/// The syllables an op occupies: its own instruction word plus its extensions.
/// This is gas' `length + immx` for one instruction.
static unsigned syllablesOf(const Reservation *reservation) {
  return 1 + immxOf(reservation);
}

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
static unsigned readCycle(const OpTiming *t, unsigned i) {
  return t && i < t->numOperands ? t->operandRead[i] : 1;
}
static unsigned writeCycle(const OpTiming *t, unsigned i) {
  return t && i < t->numResults ? t->resultWrite[i] : 2;
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
  // resource was then spelled; since the 2026-10-07 rename it is `IMMX` and
  // the same four `.Y` forms are refused by `lvx_insn_add_immx` instead (see
  // `kGasMaxImmx`). Latent until non-splat vector constants started emitting
  // large immediates in quantity.
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

/// The IMMX syllables a bundle holds, which is **not** what the generated
/// table says. `kResourceAvailability` gives 8, the ISA's figure; the real
/// assembler takes 6.
///
/// `lvx_immx_buffer` in `lvx-binutils`' `gas/config/tc-lvx.c` is dimensioned
/// `LVX_MAXOPERANDS` -- the most operands one *instruction* can have, 7 --
/// which has nothing to do with how many extension syllables a *bundle* may
/// carry, and the bound test increments before comparing (`lvx_immx_cnt++`
/// then `>= NELEMS`), losing one more. So gas dies with
/// "[lvx_insn_add_immx] max number of IMMX exceeded: 7" on the seventh,
/// measured 2026-10-07: three `.Y` immediates in a bundle assemble, four do
/// not, and so do six `.X` against seven.
///
/// This did not matter until 2026-10-07. While the resource counted
/// instruction *words* against 8, a bundle could not reach six extensions --
/// two three-word instructions are six syllables for four of them, and a
/// fifth word leaves no room for a sixth. Counting extensions alone against
/// the same 8 does reach it, so honouring the table here would start emitting
/// bundles the assembler refuses.
///
/// Raise this to `kResourceAvailability` once gas sizes that buffer by a
/// bundle constant.
static constexpr unsigned kGasMaxImmx = 6;

static unsigned availabilityOf(unsigned idx) {
  if (idx == static_cast<unsigned>(Resource::immx))
    return std::min(kResourceAvailability[idx], kGasMaxImmx);
  return kResourceAvailability[idx];
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
          unsigned w = writeCycle(n.timing, k);
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
        }
      }
    }

    // A terminator ends the block: nothing may be placed after it, which
    // the barrier edges say, and its own bundle is the last. Ops after the
    // terminator do not exist.
    return success();
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
      unsigned words = 0;
      unsigned issues = 0;
      unsigned immx = 0;
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
          // A prefix already in this bundle is free; a new one takes a BCU slot,
          // on top of whatever the op itself reserves.
          //
          // It also takes a syllable, counted in `words` rather than against a
          // resource: the charge used to go against `Resource::issue`, and `immx`
          // -- which inherited that resource's availability of 8 -- counts only
          // immediate extension words, so a prefix does not belong there.
          bool newPrefix = n.prefix && !llvm::is_contained(prefixes, *n.prefix);
          unsigned extra[kNumResources] = {};
          if (newPrefix)
            extra[static_cast<unsigned>(Resource::bcu)] = 1;
          // A prefix is a syllable and takes an issue slot of its own, so it
          // counts toward both limits.
          // A prefix is a syllable and an issue slot, but carries no immediate
          // extension of its own.
          unsigned extraImmx = immxOf(n.reservation);
          unsigned extraWords = syllablesOf(n.reservation) + (newPrefix ? 1 : 0);
          unsigned extraIssues = 1 + (newPrefix ? 1 : 0);
          bool fits = words + extraWords <= kMaxBundleWords &&
                      issues + extraIssues <= kMaxBundleIssue &&
                      immx + extraImmx <= kMaxBundleImmx;
          for (unsigned idx = 0; idx != kNumResources; ++idx)
            if (extra[idx] && used[idx] + extra[idx] > availabilityOf(idx))
              fits = false;
          if (n.reservation) {
            for (unsigned r = 0; r != n.reservation->numUses; ++r) {
              const ResourceUse &use = n.reservation->uses[r];
              unsigned idx = static_cast<unsigned>(use.resource);
              if (used[idx] + extra[idx] + use.count > availabilityOf(idx))
                fits = false;
            }
          }
          if (!fits)
            continue;
          for (unsigned idx = 0; idx != kNumResources; ++idx)
            used[idx] += extra[idx];
          words += extraWords;
          issues += extraIssues;
          immx += extraImmx;
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
