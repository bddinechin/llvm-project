//===- RegisterAllocation.cpp - LVX linear-scan register assignment -----===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Steps 2 and 3 of the linear-scan register allocator described in
// lvx-mlir/docs/RegisterAllocation.md, as one pass: Step 2 is Fig. 1's scan with
// `SpillAtInterval` replaced by a hard error; Step 3 is the same scan with
// real spilling. See that file for the full design rationale, including
// corrections made relative to the original walkthrough: call-clobbering is
// enforced via a precomputed per-item "crosses a call" restriction rather
// than synthetic fixed intervals; `lvx_scf.for` loop-carried channels are
// coalesced into single allocation items to satisfy `ForOp`'s own
// type-equality verifier; and spilling reserves a small fixed scratch-
// register pool rather than re-running the competitive scan on decomposed
// micro-intervals.
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/LVX/Transforms/Passes.h"
#include "mlir/Dialect/LVX/Transforms/ScratchRegisters.h"
#include "mlir/Dialect/LVX/IR/LVXConvention.h"
#include "mlir/Dialect/LVX/IR/LVXTiedOperands.h"
#include "mlir/Dialect/LVX/IR/RegisterUnits.h"

#include <array>

#include "mlir/Dialect/LVX/Analysis/LiveIntervals.h"
#include "mlir/Dialect/LVXFunc/IR/LVXFunc.h"
#include "mlir/Dialect/LVXSCF/IR/LVXSCF.h"
#include "mlir/IR/Builders.h"
#include "mlir/Interfaces/ControlFlowInterfaces.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallSet.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"

namespace mlir {
namespace lvx {
#define GEN_PASS_DEF_LVXALLOCATEREGISTERSPASS
#include "mlir/Dialect/LVX/Transforms/Passes.h.inc"
} // namespace lvx
} // namespace mlir

using namespace mlir;
using namespace mlir::lvx;

namespace {

/// One unit of register assignment: either a single SSA value (the common
/// case) or a coalesced group of values forced to share one physical
/// register -- an `lvx_scf.for` loop-carried channel (init operand, body
/// iter_arg, yield operand, and the op's own result), an `lvx_cf` branch
/// edge (forwarded operand and destination block argument), or an
/// `ffma`/`ffms` accumulator (the `c` operand and the op's own result) --
/// see lvx-mlir/docs/RegisterAllocation.md.
///
/// An item occupies a block of `width` units (RegisterUnits.h); each member
/// sits at an `offset` within it. The coalescing edges above all join values
/// of one type, at offset 0; a lane view (`lvx.lane %p[k]`, lvx-mlir/docs/
/// RegisterAllocation.md, "Lane views") joins the narrower value at offset
/// k, so that after allocation it is the register that lane is.
struct AllocMember {
  Value value;
  unsigned offset;
  unsigned width;
};

struct AllocItem {
  SmallVector<AllocMember, 4> members;
  unsigned start = 0;
  unsigned end = 0;
  /// The widest extent any member reaches: max over members of
  /// `offset + width`.
  unsigned width = 1;
  /// The item's block, when some member's type is pinned.
  std::optional<PhysLoc> fixed;
  bool crossesCall = false;
  /// The base unit the scan chose; the block is `{*assigned, width}`.
  std::optional<unsigned> assigned;
  // Step 3: set when this item is memory-resident instead of assigned a
  // register. `spillOffset` is its 8-byte-aligned slot in the frame,
  // relative to the post-prologue stack pointer.
  bool spilled = false;
  std::optional<unsigned> spillOffset;

  /// Whether some member was joined by a loop-carried, branch-edge or
  /// tied-operand edge. Such a group is tied together by control flow, and
  /// reloading one member does not put the value where the others expect
  /// it, so it is not spillable -- lvx-mlir/docs/RegisterAllocation.md,
  /// "What remains a hard error". A group joined only by lane views is tied
  /// by layout, which a spill slot preserves, and spills like any item.
  bool coalescedByControl = false;

  bool isFixed() const { return fixed.has_value(); }
  bool isGroup() const { return coalescedByControl; }
  /// Whether the scan may evict this item, or spill it when it cannot be
  /// placed: not a control group, and not a quad -- the scratch set has no
  /// quad to reload one into (lvx-mlir/docs/RegisterAllocation.md,
  /// "Spilling a tuple").
  bool isSpillable() const { return !isGroup() && width < 4; }

  unsigned base() const { return fixed ? fixed->base : *assigned; }
  PhysLoc loc() const { return {base(), width}; }
  PhysLoc locOf(const AllocMember &m) const {
    return {base() + m.offset, m.width};
  }
  Value frontValue() const { return members.front().value; }
};

/// The block-marking view of `inUse[]`: a block is in use if any of its
/// units is, and is taken or released as a whole.
static bool anyInUse(const bool *inUse, PhysLoc l) {
  for (unsigned u = l.base; u != l.end(); ++u)
    if (inUse[u])
      return true;
  return false;
}
static void markInUse(bool *inUse, PhysLoc l, bool v) {
  for (unsigned u = l.base; u != l.end(); ++u)
    inUse[u] = v;
}

//===----------------------------------------------------------------------===//
// Register pool: preference order per lvx-mlir/docs/RegisterAllocation.md
// ("Allocation order"), BUILT from `Convention-lvx_v1-regular` rather than
// transcribed from it -- the sets come from the generated LVXConvention.inc.
//
// The membership is the ABI's and the order is this pass's, and keeping the
// two apart is the point. What the convention says is which registers a
// caller must save and which a callee must preserve; what this pass decides
// is that a caller-saved register is the better first choice, because using a
// callee-saved one costs a prologue/epilogue save/restore pair that
// `collectCalleeSavedToSave` below has to emit. Reserved registers (R12, the
// stack pointer, and R13) and the spill scratch (see ScratchRegisters.h) are
// excluded; the ABI has no opinion about either exclusion, so both are stated
// here.
//===----------------------------------------------------------------------===//

// Every scratch register is caller-saved, so removing them removes that many
// entries from the caller set and none from the callee set. ScratchRegisters.h
// asserts the same thing for its own reasons; stated again here because this
// arithmetic is wrong without it, and an off-by-N in a constexpr array bound
// reports as "__builtin_unreachable() is not a constant expression".
static_assert(isIn(kScratchRegs[0], kCallerSavedRegs) &&
                  isIn(kScratchRegs[1], kCallerSavedRegs) &&
                  isIn(kScratchRegs[2], kCallerSavedRegs),
              "the scratch registers must all be caller-saved");

static constexpr unsigned kAllocatableCount =
    kNumCallerSavedRegs - kNumScratchRegs + kNumCalleeSavedRegs;

/// Caller-saved first (in the convention's own order, which runs $r0-$r11 --
/// the argument/result registers -- ahead of the rest), then callee-saved.
static constexpr std::array<Register, kAllocatableCount> makeFullOrder() {
  std::array<Register, kAllocatableCount> order{};
  unsigned n = 0;
  for (Register r : kCallerSavedRegs)
    if (!isIn(r, kScratchRegs))
      order[n++] = r;
  for (Register r : kCalleeSavedRegs)
    order[n++] = r;
  return order;
}

static constexpr std::array<Register, kAllocatableCount> kFullOrderStorage =
    makeFullOrder();
static constexpr ArrayRef<Register> kFullOrder(kFullOrderStorage);

static_assert(kAllocatableCount == 59,
              "expected 59 allocatable GPRs (all but R12/R13 and the 3 "
              "spill-scratch registers below)");
// The reserved registers must not have reached the pool. The convention says
// they are reserved; it does not say they are absent from `caller`/`callee`,
// and in fact R12/R13 are in neither -- so this asserts the coincidence the
// pool relies on rather than assuming it.
static_assert(!isIn(kStackReg, kCallerSavedRegs) &&
                  !isIn(kStackReg, kCalleeSavedRegs) &&
                  !isIn(kLocalReg, kCallerSavedRegs) &&
                  !isIn(kLocalReg, kCalleeSavedRegs),
              "a reserved register appears in the allocation pool");

/// True if `r` is callee-saved per `Convention-lvx_v1-regular`'s `callee`
/// set (R14, R18-R31), i.e. the caller's value in it must be preserved
/// across this function.
static bool isCalleeSaved(Register r) { return isIn(r, kCalleeSavedRegs); }

//===----------------------------------------------------------------------===//
// Spill scratch registers: reserved out of the general pool above (never
// handed to an ordinary long-lived item), used exclusively for a spilled
// value's transient def-then-store or reload-then-use window. Sized for
// the worst case among currently-defined ops needing several
// simultaneously (lvx.cmoved/cmovew's 3 register operands) -- see
// lvx-mlir/docs/RegisterAllocation.md, "Reserved scratch registers".
//
// These must be *caller*-saved (R61-R63 are, per `Convention.table`): the
// scratch window is transient and never crosses a call, so nothing has to
// be preserved across it -- but a callee-saved choice would silently
// clobber the caller's value in a register it is entitled to get back,
// with no save to match. R29-R31 (the previous choice) are callee-saved,
// which made every spilling function ABI-illegal against lvx-gcc callers.
// R62:R63 is an even/odd aligned pair: the scratch a spilled `!lvx.pair`
// is stored from and reloaded into (ScratchUnits below).
//===----------------------------------------------------------------------===//

static constexpr const Register *kSpillScratchRegs = kScratchRegs;
static constexpr unsigned kNumSpillScratchRegs = kNumScratchRegs;

/// One past the largest value the Register enum takes. The enum's values are
/// dwarfIds, NOT positions -- the general-purpose file is 0-63 and the system
/// file 64-255 -- so an array indexed by a Register has to be this big, not
/// `number of registers`. It was literally sized 65 while the enum held
/// r0-r63 plus $ra=67, which was already two past the end for any value
/// pinned to $ra and would have been 188 past it once the system file
/// arrived (O5).
static constexpr unsigned kRegisterIdBound = getMaxEnumValForRegister() + 1;

//===----------------------------------------------------------------------===//
// The pool at every width (lvx-mlir/docs/RegisterAllocation.md, "Step 4",
// "Preference orders"). The ABI states caller/callee for singles and a tuple
// inherits by containment: a block of W units is allocatable iff every unit
// is, and its preference is the same policy kFullOrder expresses for singles
// -- the fewer callee-saved units it costs a save for, the earlier -- with
// kFullOrder's own order breaking ties, so that makeOrder<1>() IS kFullOrder.
//
// Over lvx_v2's ABI that gives 29 pairs (21 wholly caller-saved, then
// r14r15 -- r14 the frame pointer and callee-saved, r15 the struct-return
// register and caller-saved -- then the 7 wholly callee-saved r18r19 ..
// r30r31; absent: r12r13, reserved, and r60r61/r62r63, which contain
// scratch) and 14 quads (10, then r16..r19, then r20..r31's three; absent:
// r12..r15 and r60..r63).
//===----------------------------------------------------------------------===//

/// A unit's position in kFullOrder, or kNotAllocatable. The `max-registers`
/// test knob bounds the pool by this rank, at every width: a block is in the
/// pool iff every unit's rank is below the bound.
static constexpr unsigned kNotAllocatable = ~0u;
static constexpr std::array<unsigned, kRegisterIdBound> makePoolRank() {
  std::array<unsigned, kRegisterIdBound> rank{};
  for (unsigned &r : rank)
    r = kNotAllocatable;
  for (unsigned i = 0; i != kAllocatableCount; ++i)
    rank[static_cast<unsigned>(kFullOrderStorage[i])] = i;
  return rank;
}
static constexpr std::array<unsigned, kRegisterIdBound> kPoolRank =
    makePoolRank();

static constexpr bool isAllocatableBlock(unsigned base, unsigned width) {
  for (unsigned u = base; u != base + width; ++u)
    if (kPoolRank[u] == kNotAllocatable)
      return false;
  return true;
}
static constexpr unsigned calleeSavedUnits(unsigned base, unsigned width) {
  unsigned n = 0;
  for (unsigned u = base; u != base + width; ++u)
    if (isIn(static_cast<Register>(u), kCalleeSavedRegs))
      ++n;
  return n;
}

template <unsigned W> static constexpr unsigned countBlocks() {
  unsigned n = 0;
  for (unsigned base = 0; base + W <= kNumGPRUnits; base += W)
    if (isAllocatableBlock(base, W))
      ++n;
  return n;
}

/// The candidate bases of width W, in preference order.
template <unsigned W>
static constexpr std::array<unsigned, countBlocks<W>()> makeOrder() {
  std::array<unsigned, countBlocks<W>()> order{};
  unsigned n = 0;
  for (unsigned base = 0; base + W <= kNumGPRUnits; base += W)
    if (isAllocatableBlock(base, W))
      order[n++] = base;
  // Insertion sort by (callee-saved units, rank of the first unit) -- a
  // constexpr-friendly sort over at most 59 entries.
  auto before = [](unsigned a, unsigned b) {
    unsigned ca = calleeSavedUnits(a, W), cb = calleeSavedUnits(b, W);
    return ca != cb ? ca < cb : kPoolRank[a] < kPoolRank[b];
  };
  for (unsigned i = 1; i < n; ++i)
    for (unsigned j = i; j > 0 && before(order[j], order[j - 1]); --j) {
      unsigned tmp = order[j];
      order[j] = order[j - 1];
      order[j - 1] = tmp;
    }
  return order;
}

static constexpr auto kOrder1 = makeOrder<1>();
static constexpr auto kOrder2 = makeOrder<2>();
static constexpr auto kOrder4 = makeOrder<4>();

// The single-width order must be kFullOrder itself, so that nothing about a
// single register's allocation changed when the block machinery arrived.
static constexpr bool singleOrderIsFullOrder() {
  if (kOrder1.size() != kAllocatableCount)
    return false;
  for (unsigned i = 0; i != kAllocatableCount; ++i)
    if (kOrder1[i] != static_cast<unsigned>(kFullOrderStorage[i]))
      return false;
  return true;
}
static_assert(singleOrderIsFullOrder(),
              "makeOrder<1>() must reproduce kFullOrder");
static_assert(kOrder2.size() == 29 && kOrder4.size() == 14,
              "expected 29 allocatable pairs and 14 allocatable quads (see "
              "the pool comment above)");

static ArrayRef<unsigned> orderFor(unsigned width) {
  switch (width) {
  case 1:
    return kOrder1;
  case 2:
    return kOrder2;
  case 4:
    return kOrder4;
  }
  llvm_unreachable("a block is 1, 2 or 4 units wide");
}

/// Whether `loc` may be handed to an item: every unit within the first
/// `maxRegisters` of kFullOrder, and callee-saved if the item's range
/// straddles a call.
static bool inPool(PhysLoc loc, bool crossesCall, unsigned maxRegisters) {
  for (unsigned u = loc.base; u != loc.end(); ++u) {
    if (kPoolRank[u] >= maxRegisters)
      return false;
    if (crossesCall && !isIn(static_cast<Register>(u), kCalleeSavedRegs))
      return false;
  }
  return true;
}

/// Picks the first free block of `width` units in the pool, or nullopt.
static std::optional<unsigned> pickFree(unsigned width, bool crossesCall,
                                        unsigned maxRegisters,
                                        const bool inUse[kRegisterIdBound]) {
  for (unsigned base : orderFor(width)) {
    PhysLoc loc{base, width};
    if (inPool(loc, crossesCall, maxRegisters) && !anyInUse(inUse, loc))
      return base;
  }
  return std::nullopt;
}

//===----------------------------------------------------------------------===//
// Allocation item construction
//===----------------------------------------------------------------------===//

/// Merges the live interval of `value` (as computed by `live`) into the
/// item under construction, as a member at `offset`.
static void mergeValue(AllocItem &item, Value value,
                       const LVXLiveIntervals &live, unsigned offset = 0) {
  const LiveInterval &iv = live.getInterval(value);
  bool first = item.members.empty();
  item.members.push_back({value, offset, iv.width});
  item.start = first ? iv.start : std::min(item.start, iv.start);
  item.end = first ? iv.end : std::max(item.end, iv.end);
  item.width = first ? offset + iv.width
                     : std::max(item.width, offset + iv.width);
  if (iv.isFixed()) {
    // A pinned member pins the item's block at `fixedBase - offset`.
    PhysLoc block{iv.fixed->base - offset, item.width};
    if (item.fixed && item.fixed->base != block.base) {
      // Two members of the same loop-carried channel are independently
      // pinned to different physical registers -- not satisfiable.
      item.fixed = std::nullopt; // signal handled by caller via a
                                 // dedicated conflict check below.
    } else {
      item.fixed = block;
    }
  }
  // A later, wider member widens the block the pin describes.
  if (item.fixed)
    item.fixed->width = item.width;
}

//===----------------------------------------------------------------------===//
// Preserving copies for loop-carried init args also used independently
// elsewhere -- lvx-mlir/docs/RegisterAllocation.md, "Narrower gap discovered
// while verifying the fix": `buildAllocItems` below force-coalesces an
// `lvx_scf.for`'s whole {initArg, iterArg, yieldOperand, result} channel
// into one register (mechanically required -- `ForOp`'s verifier demands
// initArg/yield/result share a type, i.e. after allocation, a register).
// If the init-arg value is *also* used somewhere other than as this one
// operand (the confirmed failing shape: an outer loop's iterArg fed into
// a nested loop's initArg, then read again after that inner loop, e.g.
// `%sum = lvx.addd %acc, %innerResult`), that other use silently observes
// whatever the loop's own iterations last left in the shared register,
// not the value %acc actually held going in -- concretely, a self-add
// (`addd $r3 = $r3, $r3`) instead of the intended sum.
//
// This is real code motion, not a coalescing decision, and it has to run
// *before* Step 1 builds live intervals (`LVXLiveIntervals`, constructed
// from the unmodified IR in `runOnOperation` below) -- a fixup added
// inside `buildAllocItems` itself would be too late to give the new copy
// its own, correctly-computed interval. For every `lvx_scf.for` init
// operand with a use outside that one operand, insert an `lvx.mv` copy
// immediately before the loop and redirect every *other* use to the
// copy: the loop's own channel still coalesces around the original value
// exactly as before (unaffected -- its only use inside the loop's own
// tuple is untouched), while the copy is an ordinary, independently
// allocated value whose interval naturally spans the loop, verified by
// Step 2's normal conflict-avoidance like any other value with a long
// live range. Conservative by design (checks "any other use," not
// specifically "a use positioned after the loop") -- matches this
// project's general preference for simple-and-safe over precise
// elsewhere in this file (e.g. the fixed-register conflict check above);
// the only cost of over-triggering is an occasional redundant copy, not
// a correctness risk. Confirmed to be a no-op on every existing loop
// test (`register-allocation.mlir`, `scf-to-cf.mlir`): none of their
// init args have a use beyond the loop that defines them.
static void insertLoopCarriedPreservingCopies(lvx_func::FuncOp func) {
  SmallVector<lvx_scf::ForOp> forOps;
  func.walk([&](lvx_scf::ForOp op) { forOps.push_back(op); });
  for (lvx_scf::ForOp forOp : forOps) {
    for (Value v : forOp.getInitArgs()) {
      bool hasOtherUse = llvm::any_of(v.getUses(), [&](OpOperand &use) {
        return use.getOwner() != forOp;
      });
      if (!hasOtherUse)
        continue;
      OpBuilder builder(forOp);
      auto copy = builder.create<MvOp>(forOp.getLoc(), v.getType(), v);
      llvm::SmallPtrSet<Operation *, 2> keep{forOp, copy};
      v.replaceAllUsesExcept(copy, keep);
    }
  }
}

// Same "preserving copy" idea as `insertLoopCarriedPreservingCopies` above,
// for a different coalescing source: `lvx.ffmad`/`lvx.ffmaw`/`lvx.ffmsd`/
// `lvx.ffmsw`'s third operand (`c`, the accumulator) is force-coalesced
// with the op's own result in `buildAllocItems` below (real hardware has
// no separate destination register -- see lvx-mlir/docs/RegisterAllocation.md,
// "`ffma`/`ffms` accumulator coalescing"). If `c`'s value is read anywhere
// else too, that other read must not observe the register being
// overwritten in place by this op -- so redirect every *other* use to an
// independent copy made right before the op, exactly mirroring the loop
// case (the op itself keeps reading the original value; only outside
// readers move to the copy).
/// Ops whose operand #2 must land in the same register as their result,
/// because real hardware overwrites that operand in place.
///
/// Two families, for the same underlying reason. `ffma`/`ffms` accumulate
/// into their destination: `ffmad $rW = $rZ, $rY` computes
/// `rW := rZ * rY + rW`. `cmoved` conditionally overwrites its destination:
/// `cmoved.cond $rZ? $rW = $rY` leaves `rW` alone when the guard fails, so
/// `rW`'s prior value is live into the op. Both are modelled here as an
/// ordinary SSA operand (index 2) that happens to be tied to the result.
/// The operands `op` reads through its destination, from the generated
/// LVXTiedOperands.inc. This was `isa<FfmadOp, FfmawOp, FfmsdOp, FfmswOp,
/// CmovedOp>` with the tie assumed to be operand 2 -- true of those five and
/// of nothing else; see LVXTiedOperands.h.
static ArrayRef<TiedOperand> tiedOperands(Operation *op) {
  return tiedOperandsOf(op->getName().stripDialect());
}

static bool hasTiedAccumulator(Operation *op) {
  return !tiedOperands(op).empty();
}

static void insertFmaAccumulatorPreservingCopies(lvx_func::FuncOp func) {
  SmallVector<Operation *> fmaOps;
  func.walk([&](Operation *op) {
    if (hasTiedAccumulator(op))
      fmaOps.push_back(op);
  });
  for (Operation *op : fmaOps) {
    for (TiedOperand tie : tiedOperands(op)) {
    Value c = op->getOperand(tie.operand);
    bool hasOtherUse = llvm::any_of(c.getUses(), [&](OpOperand &use) {
      return use.getOwner() != op;
    });
    if (!hasOtherUse)
      continue;
    // Give the *ffma* a private copy, rather than redirecting the other
    // readers to one.
    //
    // Redirecting the readers was the original approach and it was wrong.
    // The copy has to sit immediately before the ffma (that is where `c`
    // is still intact), so any reader *earlier* than the ffma would be
    // rewired to a value defined after it -- `operand #N does not dominate
    // this use`, a hard verifier failure. Ordering it the other way round
    // has the same problem for a reader inside a loop, whose next
    // iteration would read the register after the ffma overwrote it, and
    // that one would be silent rather than caught.
    //
    // Copying into the ffma avoids both: `c` itself is never touched, so
    // every other reader keeps working whatever its position or trip
    // count, and the value that gets overwritten in place is the copy --
    // which has exactly one reader, this op.
    OpBuilder builder(op);
    auto copy = builder.create<MvOp>(op->getLoc(), c.getType(), c);
    op->setOperand(tie.operand, copy);
    }
  }
}

static SmallVector<AllocItem> buildAllocItems(lvx_func::FuncOp func,
                                              const LVXLiveIntervals &live,
                                              bool &conflictingFixedGroup,
                                              bool &conflictingLaneGroup) {
  conflictingFixedGroup = false;
  conflictingLaneGroup = false;
  DenseSet<Value> grouped;
  SmallVector<AllocItem> items;

  // Union-find over loop-carried channel members. Unioning within just one
  // lvx_scf.for's own {initArg, iterArg, yieldOperand, result} tuple is
  // not sufficient once loops nest: an inner loop's result can *be* an
  // outer loop's directly-yielded operand (the same SSA value playing
  // both roles), and every value transitively reachable through such an
  // overlap must end up sharing exactly one register -- deciding the
  // inner and outer channels as two independent groups can each pick a
  // different register for that shared value, which is exactly the bug
  // this fixes (lvx-mlir/docs/RegisterAllocation.md, "nested lvx_scf.for").
  //
  // The union-find is weighted: each value has an offset within its group's
  // block, and `delta[v]` is offset(v) - offset(parent[v]). Every edge but a
  // lane view joins two values at the same offset; a lane view joins the
  // lane at `index` above its source. Offsets are relative to the root and
  // may be negative until the item normalizes them.
  DenseMap<Value, Value> parent;
  DenseMap<Value, int> delta;
  // Returns the root and v's offset relative to it.
  auto find = [&](Value v) -> std::pair<Value, int> {
    SmallVector<Value, 8> path;
    Value root = v;
    int offset = 0;
    for (auto it = parent.find(root); it != parent.end() && it->second != root;
         it = parent.find(root)) {
      path.push_back(root);
      offset += delta.lookup(root);
      root = it->second;
    }
    // Path compression, keeping each node's offset relative to the root.
    int acc = offset;
    for (Value cur : path) {
      int own = delta.lookup(cur);
      parent[cur] = root;
      delta[cur] = acc;
      acc -= own;
    }
    return {root, offset};
  };
  // Records offset(a) == offset(b) + d; false if the group already says
  // otherwise.
  auto uniteAt = [&](Value a, Value b, int d) {
    auto [ra, oa] = find(a);
    auto [rb, ob] = find(b);
    if (ra == rb)
      return oa == ob + d;
    parent[ra] = rb;
    delta[ra] = ob + d - oa;
    return true;
  };
  // The control-flow edges: a value joined by one makes its group
  // unspillable (AllocItem::coalescedByControl).
  DenseSet<Value> controlJoined;
  auto unite = [&](Value a, Value b) {
    (void)uniteAt(a, b, 0);
    controlJoined.insert(a);
    controlJoined.insert(b);
  };

  SmallVector<Value> orderedValues;
  func.walk([&](lvx_scf::ForOp forOp) {
    OperandRange initArgs = forOp.getInitArgs();
    Block::BlockArgListType iterArgs = forOp.getRegionIterArgs();
    ResultRange results = forOp.getResults();
    auto yieldOp = cast<lvx_scf::YieldOp>(forOp.getBody()->getTerminator());
    OperandRange yieldOperands = yieldOp.getResults();
    for (unsigned i = 0, e = initArgs.size(); i != e; ++i) {
      Value vInit = initArgs[i];
      Value vIter = iterArgs[i];
      Value vYield = yieldOperands[i];
      Value vResult = results[i];
      unite(vInit, vIter);
      unite(vIter, vYield);
      unite(vYield, vResult);
      orderedValues.append({vInit, vIter, vYield, vResult});
    }
  });

  // Union-find over ordinary `lvx_cf` branch edges too: a `BranchOpInterface`
  // op's forwarded operand at position `i` and the destination block's
  // argument at position `i` are the same value flowing across the edge --
  // there is no real branch-argument-passing mechanism at the assembly
  // level (`lvx_cf.br`/`cond_br` are GOTO/CB, no register moves), so they
  // must land in the same physical register or the branch is simply wrong.
  // This is the exact same JOIN/phi-coalescing idea as the loop-tuple
  // unioning above, just over `cf`-style edges instead of `lvx_scf.for`'s
  // implicit ones; every existing hand-written test happened to only use
  // bare (argument-less) blocks for `lvx_cf.br`/`cond_br`, so this gap went
  // unnoticed until real `-convert-to-lvx` output (which always splits the
  // entry block off into its own argument-passing edge) was run through
  // this pass end-to-end. A genuine multi-predecessor merge point unions
  // fine here too: every incoming edge's operand and the shared block
  // argument all end up in one connected component, exactly like a real
  // phi.
  func.walk([&](Operation *op) {
    auto branch = dyn_cast<BranchOpInterface>(op);
    if (!branch)
      return;
    for (unsigned i = 0, e = op->getNumSuccessors(); i != e; ++i) {
      Block *succ = op->getSuccessor(i);
      OperandRange forwarded =
          branch.getSuccessorOperands(i).getForwardedOperands();
      for (auto [operand, blockArg] :
          llvm::zip_equal(forwarded, succ->getArguments())) {
        unite(operand, blockArg);
        orderedValues.append({operand, blockArg});
      }
    }
  });

  // Union-find over `ffma`/`ffms`'s accumulator operand (`c`) and the op's
  // own result: real FFMAD/FFMAW/FFMSD/FFMSW have only two explicit source
  // registers (registerZ, registerY); the destination (registerW) doubles
  // as the third, implicit accumulate-into operand, so `c`'s register and
  // `result`'s register must be identical or the instruction has no way to
  // be printed at all -- see lvx-mlir/docs/RegisterAllocation.md, "`ffma`/`ffms`
  // accumulator coalescing". Same JOIN-style idea as the loop/branch
  // unioning above, just a 2-value group.
  // `insertFmaAccumulatorPreservingCopies` (run before this pass builds
  // live intervals) already guarantees any *other* use of `c` reads an
  // independent copy first, so merging `c` and `result` here can never
  // silently corrupt a value still needed elsewhere.
  func.walk([&](Operation *op) {
    for (TiedOperand tie : tiedOperands(op)) {
      Value c = op->getOperand(tie.operand);
      Value result = op->getResult(tie.result);
      unite(c, result);
      orderedValues.append({c, result});
    }
  });

  // Lane views: `lvx.lane %s[k]` names the units `k .. k+width` of `%s`'s
  // block, so the result joins the source's group at offset k. Two views
  // that would place one value at two offsets -- a branch that merges lane
  // 0 with lane 1, say -- cannot be satisfied and are reported.
  func.walk([&](LaneOp lane) {
    if (!uniteAt(lane.getResult(), lane.getSource(), lane.getIndex()))
      conflictingLaneGroup = true;
    orderedValues.append({lane.getSource(), lane.getResult()});
  });

  // Build one AllocItem per union-find root, in first-encountered order
  // (deterministic -- driven by `orderedValues`, not by DenseMap iteration
  // order). A value already merged into its group (`grouped`) is skipped
  // on later occurrences, which is exactly how a shared inner/outer value
  // ends up contributing to its group only once despite appearing in two
  // tuples above.
  //
  // Offsets are normalized per item so the lowest member sits at 0: the
  // root's offset is 0 by construction, but a tuple joined *after* one of
  // its lanes sits below it.
  DenseMap<Value, unsigned> rootToItemIndex;
  DenseMap<Value, int> lowestOffset;
  for (Value v : orderedValues) {
    auto [root, offset] = find(v);
    auto [it, inserted] = lowestOffset.try_emplace(root, offset);
    if (!inserted)
      it->second = std::min(it->second, offset);
  }
  for (Value v : orderedValues) {
    if (!grouped.insert(v).second)
      continue;
    auto [root, offset] = find(v);
    auto [it, inserted] = rootToItemIndex.try_emplace(root, items.size());
    if (inserted)
      items.emplace_back();
    AllocItem &item = items[it->second];
    mergeValue(item, v, live, offset - lowestOffset.lookup(root));
    item.coalescedByControl |= controlJoined.contains(v);
  }

  // Detect a genuine conflicting-fixed-register case across each merged
  // group's full membership (mergeValue's own running `fixed` field
  // only reflects the *last* mismatch seen, not a durable "any conflict
  // occurred" signal).
  // With members at offsets, "the same register" means the same block base:
  // a pinned member at offset k pins the block at `base - k`.
  for (AllocItem &item : items) {
    SmallVector<unsigned, 4> fixedBasesSeen;
    for (const AllocMember &m : item.members)
      if (const LiveInterval &iv = live.getInterval(m.value); iv.isFixed())
        fixedBasesSeen.push_back(iv.fixed->base - m.offset);
    if (!fixedBasesSeen.empty() && !llvm::all_equal(fixedBasesSeen))
      conflictingFixedGroup = true;
  }

  for (const LiveInterval &iv : live.getIntervals()) {
    if (grouped.contains(iv.value))
      continue;
    AllocItem item;
    mergeValue(item, iv.value, live);
    items.push_back(std::move(item));
  }

  // Fixed items are processed before non-fixed items at the same `start`:
  // a fixed item's register is non-negotiable, while a non-fixed item can
  // always fall back to a different candidate, so ties should let the
  // hard requirement claim its register first.
  llvm::stable_sort(items, [](const AllocItem &a, const AllocItem &b) {
    if (a.start != b.start)
      return a.start < b.start;
    return a.isFixed() && !b.isFixed();
  });
  return items;
}

static void markCallCrossings(lvx_func::FuncOp func,
                              const LVXLiveIntervals &live,
                              MutableArrayRef<AllocItem> items) {
  SmallVector<unsigned> callNumbers;
  func.walk([&](lvx_func::CallOp call) {
    callNumbers.push_back(live.getNumber(call));
  });
  if (callNumbers.empty())
    return;
  llvm::sort(callNumbers);
  for (AllocItem &item : items)
    item.crossesCall = llvm::any_of(callNumbers, [&](unsigned n) {
      return item.start < n && n < item.end;
    });
}

//===----------------------------------------------------------------------===//
// Step 3 rewrite: prologue/epilogue and spill store/reload insertion. See
// lvx-mlir/docs/RegisterAllocation.md, "Frame layout and prologue/epilogue" and
// "No interval splitting / no lifetime holes".
//===----------------------------------------------------------------------===//

/// Inserts `%sp0 = lvx.sp; %off = lvx.li frameSize; %spBase = lvx.sbfd %sp0,
/// %off` at the top of `func`'s entry block, and mirrors the subtraction
/// with an `lvx.addd` restore before every `lvx_func.return` in the
/// function. `off`/`off2` are pinned directly to `kSpillScratchRegs[0]`
/// (r29) rather than left for a later allocation decision -- this pass
/// runs strictly after Step 2/3's own scan, so nothing would ever assign
/// them a register otherwise, and `-lvx-emit-asm` hard-errors on an
/// unallocated value. Safe for the usual transient reason: each dies at
/// its one use (the immediately following `lvx.sbfd`/`lvx.addd`), so nothing
/// else can observe it live. If `raOffset` is set (only for a non-leaf
/// function -- one that itself executes an `lvx_func.call`), also
/// snapshots $ra into that frame slot right after establishing the frame
/// and restores it right before each `lvx.addd` epilogue restore -- see
/// lvx-mlir/docs/RegisterAllocation.md, "Return-address save/restore": $ra is
/// otherwise silently overwritten by the function's own call(s) before its
/// own `ret` gets to use it. The snapshot/restore values are pinned to the
/// same `kSpillScratchRegs[0]`, for the same transient-and-sequential
/// reason: each entry/exit site's `off`/`raVal` pair never overlaps in
/// time (one is always fully consumed before the next is defined).
/// Returns the value spill loads/stores should use as their base operand.
/// Only called when `frameSize > 0`.
static Value insertPrologueEpilogue(lvx_func::FuncOp func, unsigned frameSize,
                                    std::optional<unsigned> raOffset,
                                    ArrayRef<std::pair<Register, unsigned>>
                                        calleeSaved,
                                    MLIRContext *ctx) {
  Type r12Ty = RegisterType::get(ctx, kStackReg);
  Type raScratchTy = RegisterType::get(ctx, kSpillScratchRegs[0]);
  Type raTy = RegisterType::get(ctx, kReturnReg);
  OpBuilder builder(ctx);

  Block &entry = func.getBody().front();
  builder.setInsertionPointToStart(&entry);
  Location loc = func.getLoc();
  Value sp0 = builder.create<SpOp>(loc, r12Ty);
  Value off = builder.create<LiOp>(loc, raScratchTy,
                                   builder.getI64IntegerAttr(frameSize));
  Value spBase = builder.create<SbfdOp>(loc, r12Ty, sp0, off);

  if (raOffset) {
    auto raOffsetAttr = builder.getI64IntegerAttr(*raOffset);
    // `lvx.reg_live_in` names $ra's incoming value and emits nothing; the
    // `lvx.get` that reads it is the real `get $rN = $ra`. This was a
    // hand-written `lvx.getra` pseudo until the Register enum could name a
    // system register at all (O5) -- with `!lvx.reg<ra>` expressible, the
    // generated `lvx.get` says the same thing with no pseudo behind it.
    Value raLive = builder.create<RegLiveInOp>(loc, raTy);
    Value raVal = builder.create<GetOp>(loc, raScratchTy, raLive);
    builder.create<SdOp>(loc, raVal, spBase, raOffsetAttr);
  }

  // Save the caller's value in every callee-saved register this function
  // went on to use. `lvx.reg_live_in` emits nothing -- it only names the
  // incoming register so the `lvx.sd` has an operand to store.
  for (auto [reg, offset] : calleeSaved) {
    Type regTy = RegisterType::get(ctx, reg);
    auto offsetAttr = builder.getI64IntegerAttr(offset);
    Value live = builder.create<RegLiveInOp>(loc, regTy);
    builder.create<SdOp>(loc, live, spBase, offsetAttr);
  }

  func.walk([&](lvx_func::ReturnOp ret) {
    builder.setInsertionPoint(ret);
    // The restore is an ordinary `lvx.ld` whose result is typed with the
    // pinned register -- it *is* `ld $rN = off[$r12]` -- followed by
    // `lvx.reg_live_out`, which emits nothing and only says the register
    // must hold that value on exit.
    //
    // The pseudo is not decoration. Nothing consumes the load's result, and
    // `lvx.ld` declares `MemoryEffects<[MemRead]>`, so by MLIR's own rule an
    // unused read is trivially dead: `-canonicalize` on allocated IR deleted
    // the restore and left the caller's register clobbered. See
    // LVX_RegLiveOutOp's description.
    for (auto [reg, offset] : calleeSaved) {
      Type regTy = RegisterType::get(ctx, reg);
      auto offsetAttr =
          builder.getI64IntegerAttr(offset);
      Value restored =
          builder.create<LdOp>(ret.getLoc(), regTy, spBase, offsetAttr);
      builder.create<RegLiveOutOp>(ret.getLoc(), restored);
    }
    if (raOffset) {
      auto raOffsetAttr =
          builder.getI64IntegerAttr(*raOffset);
      Value raVal = builder.create<LdOp>(ret.getLoc(), raScratchTy, spBase,
                                         raOffsetAttr);
      // `set $ra = $rN`: the generated op's *result* is the system register
      // written, typed `!lvx.reg<ra>`, and nothing consumes it. That is not
      // dead code -- `lvx.set` is not Pure, because the `ret` that follows
      // depends on $ra with no SSA edge to say so.
      builder.create<SetOp>(ret.getLoc(), raTy, raVal);
    }
    Value off2 = builder.create<LiOp>(ret.getLoc(), raScratchTy,
                                      builder.getI64IntegerAttr(frameSize));
    builder.create<AdddOp>(ret.getLoc(), r12Ty, spBase, off2);
  });

  return spBase;
}

/// The spill scratch, by width (lvx-mlir/docs/RegisterAllocation.md,
/// "Reserved scratch registers", "Step 4 changes the pair's job"): the
/// three singles, and the one aligned pair among them. Nothing here for a
/// quad; a quad is never spilled (AllocItem::isSpillable).
///
/// Within one consuming op the reloads share the three units, so they are
/// handed out as units: a single takes the first free of r61, r62, r63 and
/// a pair takes r62r63 whole. One single and one pair fit together; two
/// singles and a pair are four units and do not, whichever order they come.
struct ScratchUnits {
  bool used[kNumSpillScratchRegs] = {};
  static constexpr unsigned kPairIndex = 1; // kScratchPairLo

  std::optional<PhysLoc> take(unsigned width) {
    if (width == 1) {
      for (unsigned i = 0; i != kNumSpillScratchRegs; ++i)
        if (!used[i]) {
          used[i] = true;
          return PhysLoc{static_cast<unsigned>(kSpillScratchRegs[i]), 1};
        }
      return std::nullopt;
    }
    if (width == 2 && !used[kPairIndex] && !used[kPairIndex + 1]) {
      used[kPairIndex] = used[kPairIndex + 1] = true;
      return PhysLoc{static_cast<unsigned>(kScratchPairLo), 2};
    }
    return std::nullopt;
  }
};
static_assert(static_cast<unsigned>(kScratchPairHi) ==
                  static_cast<unsigned>(kScratchPairLo) + 1 &&
              static_cast<unsigned>(kScratchPairLo) % 2 == 0,
              "the scratch pair must be an aligned pair");

/// The store that spills a `width`-unit value and the load that reloads
/// one: `sd`/`ld`, `sq`/`lq`.
static void createSpillStore(OpBuilder &b, Location loc, Value v, Value base,
                             TypedAttr offset) {
  switch (widthOf(v.getType())) {
  case 1:
    b.create<SdOp>(loc, v, base, offset);
    return;
  case 2:
    b.create<SqOp>(loc, v, base, offset);
    return;
  }
  llvm_unreachable("only singles and pairs are spilled");
}
static Value createSpillLoad(OpBuilder &b, Location loc, Type ty, Value base,
                             TypedAttr offset) {
  switch (widthOf(ty)) {
  case 1:
    return b.create<LdOp>(loc, ty, base, offset);
  case 2:
    return b.create<LqOp>(loc, ty, base, offset);
  }
  llvm_unreachable("only singles and pairs are spilled");
}

/// Rewrites every spilled item: gives its defining site a scratch-register
/// type and a store right after it, and replaces each use with a freshly
/// inserted reload (sharing one reload per consuming op across repeated
/// operand slots referencing the same spilled value, e.g. `lvx.addd
/// %spilled, %spilled`, rather than double-reloading it).
///
/// A lane group spills as one block: the tuple is stored whole at the slot
/// and each lane view's uses reload at `slot + 8 * offset` with the lane's
/// own width -- the `lvx.lane` op itself, which named a register the item
/// no longer holds, is erased (lvx-mlir/docs/RegisterAllocation.md, "Lane
/// groups are spillable").
static LogicalResult rewriteSpills(MLIRContext *ctx, ArrayRef<AllocItem> items,
                                   Value spBase) {
  DenseMap<Operation *, ScratchUnits> scratchForOp;
  OpBuilder builder(ctx);

  for (const AllocItem &item : items) {
    if (!item.spilled)
      continue;
    // Control groups are never spilled -- the scan hard-errors first; see
    // lvx-mlir/docs/RegisterAllocation.md, "What remains a hard error".
    assert(!item.isGroup() && "coalesced control group reached spill rewrite");

    // The members that are lane views of another member, whose ops go, and
    // the one that is not, which is stored.
    SmallVector<Operation *> laneOpsToErase;
    for (const AllocMember &m : item.members) {
      auto offsetAttr =
          builder.getI64IntegerAttr(*item.spillOffset + 8 * m.offset);
      Value v = m.value;
      auto lane = v.getDefiningOp<LaneOp>();
      bool isView = lane && llvm::any_of(item.members, [&](const AllocMember &o) {
        return o.value == lane.getSource();
      });

      // Snapshot uses before inserting the store, which itself uses `v` --
      // otherwise the store would show up as one more "use" to reload.
      SmallVector<OpOperand *> uses;
      for (OpOperand &use : v.getUses())
        uses.push_back(&use);

      if (!isView) {
        ScratchUnits storeScratch;
        std::optional<PhysLoc> loc = storeScratch.take(m.width);
        assert(loc && "a spillable width has a store scratch");
        v.setType(typeFor(ctx, *loc));
        if (Operation *defOp = v.getDefiningOp())
          builder.setInsertionPointAfter(defOp);
        else
          builder.setInsertionPointToStart(cast<BlockArgument>(v).getOwner());
        createSpillStore(builder, v.getLoc(), v, spBase, offsetAttr);
      } else {
        laneOpsToErase.push_back(lane);
      }

      DenseMap<Operation *, Value> reloadForThisMember;
      for (OpOperand *usePtr : uses) {
        OpOperand &use = *usePtr;
        Operation *useOp = use.getOwner();
        // A lane op of this same item reads nothing: it is erased below.
        if (isa<LaneOp>(useOp) &&
            llvm::any_of(item.members, [&](const AllocMember &o) {
              return o.value == useOp->getResult(0);
            }))
          continue;
        Value reload = reloadForThisMember.lookup(useOp);
        if (!reload) {
          std::optional<PhysLoc> loc = scratchForOp[useOp].take(m.width);
          if (!loc) {
            if (m.width == 1)
              return mlir::emitError(useOp->getLoc())
                     << "linear scan register allocation failed: "
                        "instruction needs more than "
                     << kNumSpillScratchRegs
                     << " simultaneously-reloaded spilled operands";
            return mlir::emitError(useOp->getLoc())
                   << "linear scan register allocation failed: instruction "
                      "needs more than one simultaneously-reloaded spilled "
                      "pair operand (the scratch set has one aligned pair)";
          }
          builder.setInsertionPoint(useOp);
          reload = createSpillLoad(builder, useOp->getLoc(), typeFor(ctx, *loc),
                                   spBase, offsetAttr);
          reloadForThisMember[useOp] = reload;
        }
        use.set(reload);
      }
    }
    for (Operation *lane : laneOpsToErase) {
      assert(lane->use_empty() && "lane view still used after spill rewrite");
      lane->erase();
    }
  }
  return success();
}

//===----------------------------------------------------------------------===//
// The scan (Poletto & Sarkar Fig. 1, extended with `SpillAtInterval` --
// see lvx-mlir/docs/RegisterAllocation.md, "Step 3").
//===----------------------------------------------------------------------===//

struct LVXAllocateRegistersPass
    : public lvx::impl::LVXAllocateRegistersPassBase<
          LVXAllocateRegistersPass> {
  using LVXAllocateRegistersPassBase::LVXAllocateRegistersPassBase;

  void runOnOperation() override {
    lvx_func::FuncOp func = getOperation();
    if (func.isExternal())
      return;

    insertLoopCarriedPreservingCopies(func);
    insertFmaAccumulatorPreservingCopies(func);

    LVXLiveIntervals live(func);
    bool conflictingFixedGroup = false, conflictingLaneGroup = false;
    SmallVector<AllocItem> items = buildAllocItems(
        func, live, conflictingFixedGroup, conflictingLaneGroup);
    if (conflictingLaneGroup) {
      func.emitError("a value is placed at two different lanes of one "
                     "register tuple (lvx.lane views joined by a "
                     "loop-carried channel, branch edge or tie)");
      return signalPassFailure();
    }
    if (conflictingFixedGroup) {
      func.emitError("a coalesced register group (lvx_scf.for loop-carried "
                      "channel, lvx_cf branch edge, or ffma/ffms "
                      "accumulator) has members pinned to different "
                      "physical registers");
      return signalPassFailure();
    }
    markCallCrossings(func, live, items);

    bool inUse[kRegisterIdBound] = {};
    // active: indices into `items`, kept sorted by increasing `end`.
    SmallVector<unsigned> active;

    // `includeBoundary`: whether an active item ending *exactly* at `start`
    // should also be expired. Fig. 1's own rule (`end < start`, strict) is
    // what we want for ordinary items -- it's what forces e.g. an op's
    // result into a different register than an operand it still reads at
    // the same op, matching this dialect's "no operand/result register
    // reuse" stance. But that same strictness is wrong when checking a
    // *fixed* item's register for a real conflict: an operand whose last
    // use is the very op that produces the fixed value (e.g. `%x` in
    // `lvx.mv %x : (...) -> !lvx.reg<r0>`) has `end == start` and does not
    // actually contend for the register -- it dies being read by that same
    // op. So fixed-item processing expires with `end <= start` instead.
    auto expireOldIntervals = [&](unsigned start, bool includeBoundary) {
      while (!active.empty() &&
             (includeBoundary ? items[active.front()].end <= start
                              : items[active.front()].end < start)) {
        markInUse(inUse, items[active.front()].loc(), false);
        active.erase(active.begin());
      }
    };
    auto insertActive = [&](unsigned idx) {
      auto pos = llvm::upper_bound(active, items[idx].end,
                                   [&](unsigned end, unsigned candidate) {
                                     return end < items[candidate].end;
                                   });
      active.insert(pos, idx);
    };

    unsigned frameSize = 0;
    // A slot is 8 * width bytes, aligned to its own size: `sq`/`so` want
    // their natural alignment, and the frame's base is 32-byte aligned.
    auto allocateSpillSlot = [&](AllocItem &victim) {
      unsigned size = 8 * victim.width;
      frameSize = (frameSize + size - 1) / size * size;
      victim.spilled = true;
      victim.spillOffset = frameSize;
      frameSize += size;
    };
    for (unsigned idx = 0, e = items.size(); idx != e; ++idx) {
      AllocItem &item = items[idx];
      expireOldIntervals(item.start, item.isFixed());

      if (item.isFixed()) {
        if (anyInUse(inUse, *item.fixed)) {
          mlir::emitError(item.frontValue().getLoc())
              << "register " << spellingOf(*item.fixed)
              << " is already in use by an overlapping live range";
          return signalPassFailure();
        }
        markInUse(inUse, *item.fixed, true);
        insertActive(idx);
        continue;
      }

      if (std::optional<unsigned> base = pickFree(
              item.width, item.crossesCall, this->maxRegisters, inUse)) {
        item.assigned = *base;
        markInUse(inUse, item.loc(), true);
        insertActive(idx);
        continue;
      }

      // SpillAtInterval (Fig. 1), over blocks (lvx-mlir/docs/
      // RegisterAllocation.md, "Step 4", "The scan"): for each candidate
      // block of `item`'s width in its pool, the occupants are the active
      // items whose block overlaps it -- one for a single, possibly several
      // narrower ones or one wider one for a tuple. A block is eligible if
      // every occupant is spillable, and its cost is the earliest occupant
      // end: the block is worth taking only if every occupant outlives
      // `item`, which is Fig. 1's `victim.end > item.end` applied to all of
      // them. Take the eligible block of greatest cost; among equals, the
      // one that spills fewest, then the one whose occupant sits latest in
      // `active` -- which for a single is exactly "scan `active` from the
      // back for the first eligible item", the rule this had before.
      std::optional<unsigned> bestBase;
      unsigned bestCost = 0, bestCount = 0, bestLast = 0;
      SmallVector<unsigned, 4> bestOccupants, occupants;
      for (unsigned base : orderFor(item.width)) {
        PhysLoc loc{base, item.width};
        if (!inPool(loc, item.crossesCall, this->maxRegisters))
          continue;
        occupants.clear();
        unsigned cost = ~0u, last = 0;
        bool eligible = true;
        for (auto [pos, actIdx] : llvm::enumerate(active)) {
          const AllocItem &cand = items[actIdx];
          if (!cand.loc().overlaps(loc))
            continue;
          if (cand.isFixed() || !cand.isSpillable()) {
            eligible = false;
            break;
          }
          occupants.push_back(actIdx);
          cost = std::min(cost, cand.end);
          last = pos;
        }
        if (!eligible || occupants.empty())
          continue;
        unsigned count = occupants.size();
        bool better = !bestBase || cost > bestCost ||
                      (cost == bestCost &&
                       (count < bestCount ||
                        (count == bestCount && last > bestLast)));
        if (better) {
          bestBase = base;
          bestCost = cost;
          bestCount = count;
          bestLast = last;
          bestOccupants = occupants;
        }
      }

      if (bestBase && bestCost > item.end) {
        for (unsigned victimIdx : bestOccupants) {
          AllocItem &victim = items[victimIdx];
          // The whole of a wider occupant's block is released, not just
          // the part under `item` -- evicting a quad for a pair frees the
          // other two units too.
          markInUse(inUse, victim.loc(), false);
          victim.assigned = std::nullopt;
          allocateSpillSlot(victim);
          active.erase(llvm::find(active, victimIdx));
        }
        item.assigned = *bestBase;
        markInUse(inUse, item.loc(), true);
        insertActive(idx);
        continue;
      }

      if (item.isGroup()) {
        mlir::emitError(item.frontValue().getLoc())
            << "linear scan register allocation failed: spilling a "
               "coalesced register group (lvx_scf.for loop-carried "
               "channel, lvx_cf branch edge, or ffma/ffms accumulator) is "
               "not yet implemented (live range [" << item.start << ", "
            << item.end << "])";
        return signalPassFailure();
      }
      if (!item.isSpillable()) {
        mlir::emitError(item.frontValue().getLoc())
            << "linear scan register allocation failed: no free aligned "
               "quadruple, and a quad cannot be spilled -- the scratch set "
               "has no quad to reload it into (live range [" << item.start
            << ", " << item.end << "])";
        return signalPassFailure();
      }
      allocateSpillSlot(item);
      // Not inserted into `active`: a spilled item holds no register.
    }

    // Rewrite: every item holding a block updates all of its member values'
    // types in place -- a fixed item too, since a lane view of a pinned
    // tuple is a member whose own type is not yet pinned. (Re-setting the
    // pinned member's type is a no-op.) Spilled items are typed by
    // rewriteSpills.
    for (AllocItem &item : items) {
      if (item.spilled || (!item.assigned && !item.fixed))
        continue;
      for (const AllocMember &m : item.members) {
        Value v = m.value;
        v.setType(typeFor(&getContext(), item.locOf(m)));
      }
    }

    // A function that itself executes a call clobbers its own $ra before
    // its own `ret` gets to use it (lvx-mlir/docs/RegisterAllocation.md,
    // "Return-address save/restore") -- reserve one more frame slot and
    // force a prologue/epilogue to exist even if nothing was spilled.
    bool isNonLeaf = false;
    func.walk([&](lvx_func::CallOp) { isNonLeaf = true; });
    std::optional<unsigned> raOffset;
    if (isNonLeaf) {
      raOffset = frameSize;
      frameSize += 8;
    }

    // Every callee-saved register this function actually used must be given
    // back to the caller unchanged (`Convention.table`'s `callee` set), so
    // reserve a frame slot per distinct one and save/restore it around the
    // body. Walking the final types rather than `items` catches the
    // registers pinned by other means too -- ABI-pinned entry arguments --
    // which never appear as an assigned item. Sorted, so the prologue is
    // deterministic.
    SmallVector<std::pair<Register, unsigned>> calleeSaved;
    {
      llvm::SmallSet<Register, 16> used;
      // A tuple type names every unit it covers: a pair in r18r19 uses
      // both, and a pair in r14r15 uses the callee-saved r14 alone.
      auto note = [&](Type t) {
        std::optional<PhysLoc> loc = pinnedLoc(t);
        if (!loc)
          return;
        for (unsigned u = loc->base; u != loc->end(); ++u)
          if (isCalleeSaved(static_cast<Register>(u)))
            used.insert(static_cast<Register>(u));
      };
      func.walk([&](Operation *op) {
        for (Value r : op->getResults())
          note(r.getType());
        for (Value o : op->getOperands())
          note(o.getType());
      });
      for (Block &b : func.getBody())
        for (BlockArgument a : b.getArguments())
          note(a.getType());

      SmallVector<Register> sorted(used.begin(), used.end());
      llvm::sort(sorted, [](Register a, Register b) {
        return static_cast<unsigned>(a) < static_cast<unsigned>(b);
      });
      for (Register r : sorted) {
        calleeSaved.emplace_back(r, frameSize);
        frameSize += 8;
      }
    }

    if (frameSize > 0) {
      Value spBase = insertPrologueEpilogue(func, frameSize, raOffset,
                                            calleeSaved, &getContext());
      if (failed(rewriteSpills(&getContext(), items, spBase)))
        return signalPassFailure();
    }
  }
};

} // namespace
