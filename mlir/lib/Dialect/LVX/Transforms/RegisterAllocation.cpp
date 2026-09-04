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
struct AllocItem {
  SmallVector<Value, 4> values;
  unsigned start = 0;
  unsigned end = 0;
  std::optional<Register> fixedReg;
  bool crossesCall = false;
  std::optional<Register> assigned;
  // Step 3: set when this item is memory-resident instead of assigned a
  // register. `spillOffset` is its 8-byte-aligned slot in the frame,
  // relative to the post-prologue stack pointer.
  bool spilled = false;
  std::optional<unsigned> spillOffset;

  bool isFixed() const { return fixedReg.has_value(); }
  // Coalesced `lvx_scf.for` channels aren't spillable yet -- see
  // lvx-mlir/docs/RegisterAllocation.md, "What remains a hard error".
  bool isGroup() const { return values.size() > 1; }
};

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

// The callee-saved suffix of kFullOrder, in the same relative order --
// used for items whose range straddles a call.
static constexpr unsigned kCalleeSavedCount = kNumCalleeSavedRegs;
static constexpr const Register *kCalleeSavedOrder =
    kFullOrderStorage.data() + (kAllocatableCount - kCalleeSavedCount);

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
// simultaneously (lvx.cmoved/cmovew's 3 register operands,
// lvx.divmodd/.../'s 2 results) -- see lvx-mlir/docs/RegisterAllocation.md,
// "Reserved scratch registers".
//
// These must be *caller*-saved (R61-R63 are, per `Convention.table`): the
// scratch window is transient and never crosses a call, so nothing has to
// be preserved across it -- but a callee-saved choice would silently
// clobber the caller's value in a register it is entitled to get back,
// with no save to match. R29-R31 (the previous choice) are callee-saved,
// which made every spilling function ABI-illegal against lvx-gcc callers.
// R62:R63 is an even/odd aligned pair, which `lvx.divmodd`'s `registerM`
// destination requires (see RewriteDivmod.cpp).
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

/// Picks the first free register in `order` (truncated to `poolSize`
/// entries), or nullopt if none is free.
static std::optional<Register> pickFree(ArrayRef<Register> order,
                                        unsigned poolSize,
                                        const bool inUse[kRegisterIdBound]) {
  for (Register r : order.take_front(std::min<size_t>(poolSize, order.size())))
    if (!inUse[static_cast<unsigned>(r)])
      return r;
  return std::nullopt;
}

//===----------------------------------------------------------------------===//
// Allocation item construction
//===----------------------------------------------------------------------===//

/// Merges the live interval of `value` (as computed by `live`) into the
/// item under construction.
static void mergeValue(AllocItem &item, Value value,
                       const LVXLiveIntervals &live) {
  const LiveInterval &iv = live.getInterval(value);
  item.values.push_back(value);
  item.start = item.values.size() == 1 ? iv.start : std::min(item.start, iv.start);
  item.end = std::max(item.end, iv.end);
  if (iv.isFixed()) {
    if (item.fixedReg && *item.fixedReg != *iv.fixedReg) {
      // Two members of the same loop-carried channel are independently
      // pinned to different physical registers -- not satisfiable.
      item.fixedReg = std::nullopt; // signal handled by caller via a
                                     // dedicated conflict check below.
    } else {
      item.fixedReg = iv.fixedReg;
    }
  }
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
                                              bool &conflictingFixedGroup) {
  conflictingFixedGroup = false;
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
  DenseMap<Value, Value> parent;
  auto find = [&](Value v) {
    Value root = v;
    for (auto it = parent.find(root); it != parent.end() && it->second != root;
        it = parent.find(root))
      root = it->second;
    for (Value cur = v; cur != root;) {
      Value next = parent.lookup(cur);
      parent[cur] = root;
      cur = next;
    }
    return root;
  };
  auto unite = [&](Value a, Value b) {
    Value ra = find(a), rb = find(b);
    if (ra != rb)
      parent[ra] = rb;
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

  // Build one AllocItem per union-find root, in first-encountered order
  // (deterministic -- driven by `orderedValues`, not by DenseMap iteration
  // order). A value already merged into its group (`grouped`) is skipped
  // on later occurrences, which is exactly how a shared inner/outer value
  // ends up contributing to its group only once despite appearing in two
  // tuples above.
  DenseMap<Value, unsigned> rootToItemIndex;
  for (Value v : orderedValues) {
    if (!grouped.insert(v).second)
      continue;
    Value root = find(v);
    auto [it, inserted] = rootToItemIndex.try_emplace(root, items.size());
    if (inserted)
      items.emplace_back();
    mergeValue(items[it->second], v, live);
  }

  // Detect a genuine conflicting-fixed-register case across each merged
  // group's full membership (mergeValue's own running `fixedReg` field
  // only reflects the *last* mismatch seen, not a durable "any conflict
  // occurred" signal).
  for (AllocItem &item : items) {
    SmallVector<Register, 4> fixedRegsSeen;
    for (Value v : item.values)
      if (const LiveInterval &iv = live.getInterval(v); iv.isFixed())
        fixedRegsSeen.push_back(*iv.fixedReg);
    if (!fixedRegsSeen.empty() && !llvm::all_equal(fixedRegsSeen))
      conflictingFixedGroup = true;
  }

  for (const LiveInterval &iv : live.getIntervals()) {
    if (grouped.contains(iv.value))
      continue;
    AllocItem item;
    item.values.push_back(iv.value);
    item.start = iv.start;
    item.end = iv.end;
    item.fixedReg = iv.fixedReg;
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

/// Rewrites every spilled item: gives its defining site a scratch-register
/// type and a store right after it, and replaces each use with a freshly
/// inserted reload (sharing one reload per consuming op across repeated
/// operand slots referencing the same spilled value, e.g. `lvx.addd
/// %spilled, %spilled`, rather than double-reloading it).
static LogicalResult rewriteSpills(MLIRContext *ctx, ArrayRef<AllocItem> items,
                                   Value spBase) {
  Type storeScratchTy = RegisterType::get(ctx, kSpillScratchRegs[0]);
  DenseMap<Operation *, unsigned> scratchCountForOp;
  OpBuilder builder(ctx);

  for (const AllocItem &item : items) {
    if (!item.spilled)
      continue;
    // Groups are never spilled -- the scan hard-errors first; see
    // lvx-mlir/docs/RegisterAllocation.md, "What remains a hard error".
    assert(!item.isGroup() && "coalesced group reached spill rewrite");
    Value v = item.values.front();
    auto offsetAttr = builder.getI64IntegerAttr(*item.spillOffset);

    // Snapshot uses before inserting the store, which itself uses `v` --
    // otherwise the store would show up as one more "use" to reload.
    SmallVector<OpOperand *> uses;
    for (OpOperand &use : v.getUses())
      uses.push_back(&use);

    v.setType(storeScratchTy);
    if (Operation *defOp = v.getDefiningOp())
      builder.setInsertionPointAfter(defOp);
    else
      builder.setInsertionPointToStart(cast<BlockArgument>(v).getOwner());
    builder.create<SdOp>(v.getLoc(), v, spBase, offsetAttr);

    DenseMap<Operation *, Value> reloadForThisItem;
    for (OpOperand *usePtr : uses) {
      OpOperand &use = *usePtr;
      Operation *useOp = use.getOwner();
      Value reload = reloadForThisItem.lookup(useOp);
      if (!reload) {
        unsigned scratchIdx = scratchCountForOp[useOp]++;
        if (scratchIdx >= kNumSpillScratchRegs) {
          mlir::emitError(useOp->getLoc())
              << "linear scan register allocation failed: instruction "
                 "needs more than "
              << kNumSpillScratchRegs
              << " simultaneously-reloaded spilled operands";
          return failure();
        }
        Type scratchTy = RegisterType::get(ctx, kSpillScratchRegs[scratchIdx]);
        builder.setInsertionPoint(useOp);
        reload =
            builder.create<LdOp>(useOp->getLoc(), scratchTy, spBase, offsetAttr);
        reloadForThisItem[useOp] = reload;
      }
      use.set(reload);
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
    bool conflictingFixedGroup = false;
    SmallVector<AllocItem> items =
        buildAllocItems(func, live, conflictingFixedGroup);
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

    auto regOf = [](const AllocItem &item) {
      return item.isFixed() ? *item.fixedReg : *item.assigned;
    };
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
        inUse[static_cast<unsigned>(regOf(items[active.front()]))] = false;
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
    auto allocateSpillSlot = [&](AllocItem &victim) {
      victim.spilled = true;
      victim.spillOffset = frameSize;
      frameSize += 8;
    };
    auto isInPool = [](Register r, ArrayRef<Register> order,
                       unsigned poolSize) {
      return llvm::is_contained(
          order.take_front(std::min<size_t>(poolSize, order.size())), r);
    };

    for (unsigned idx = 0, e = items.size(); idx != e; ++idx) {
      AllocItem &item = items[idx];
      expireOldIntervals(item.start, item.isFixed());

      if (item.isFixed()) {
        Register r = *item.fixedReg;
        if (inUse[static_cast<unsigned>(r)]) {
          mlir::emitError(item.values.front().getLoc())
              << "register " << stringifyRegister(r)
              << " is already in use by an overlapping live range";
          return signalPassFailure();
        }
        inUse[static_cast<unsigned>(r)] = true;
        insertActive(idx);
        continue;
      }

      ArrayRef<Register> order =
          item.crossesCall
              ? ArrayRef<Register>(kCalleeSavedOrder, kCalleeSavedCount)
              : kFullOrder;
      if (std::optional<Register> reg =
              pickFree(order, this->maxRegisters, inUse)) {
        item.assigned = *reg;
        inUse[static_cast<unsigned>(*reg)] = true;
        insertActive(idx);
        continue;
      }

      // SpillAtInterval (Fig. 1): among the currently-active items whose
      // register would actually help `item` (in its allowed pool, not
      // fixed, not an unspillable coalesced group), spill whichever ends
      // furthest -- `active` is sorted by increasing end, so scan from the
      // back for the first eligible one. See lvx-mlir/docs/RegisterAllocation.md,
      // "Spill heuristic".
      std::optional<unsigned> victimIdx;
      for (auto it = active.rbegin(), ie = active.rend(); it != ie; ++it) {
        const AllocItem &cand = items[*it];
        if (cand.isFixed() || cand.isGroup())
          continue;
        if (!isInPool(*cand.assigned, order, this->maxRegisters))
          continue;
        victimIdx = *it;
        break;
      }

      if (victimIdx && items[*victimIdx].end > item.end) {
        AllocItem &victim = items[*victimIdx];
        Register freed = *victim.assigned;
        victim.assigned = std::nullopt;
        allocateSpillSlot(victim);
        active.erase(llvm::find(active, *victimIdx));
        item.assigned = freed;
        // inUse[freed] stays true -- it moves from victim to item.
        insertActive(idx);
        continue;
      }

      if (item.isGroup()) {
        mlir::emitError(item.values.front().getLoc())
            << "linear scan register allocation failed: spilling a "
               "coalesced register group (lvx_scf.for loop-carried "
               "channel, lvx_cf branch edge, or ffma/ffms accumulator) is "
               "not yet implemented (live range [" << item.start << ", "
            << item.end << "])";
        return signalPassFailure();
      }
      allocateSpillSlot(item);
      // Not inserted into `active`: a spilled item holds no register.
    }

    // Rewrite: every item with a newly-assigned register updates all of
    // its member values' types in place. Already-fixed items are already
    // correctly typed and are left untouched.
    for (AllocItem &item : items) {
      if (!item.assigned)
        continue;
      Type newTy = RegisterType::get(&getContext(), *item.assigned);
      for (Value v : item.values)
        v.setType(newTy);
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
    // registers pinned by other means too -- ABI-pinned entry arguments,
    // and RewriteDivmod's result pair -- which never appear as an assigned
    // item. Sorted, so the prologue is deterministic.
    SmallVector<std::pair<Register, unsigned>> calleeSaved;
    {
      llvm::SmallSet<Register, 16> used;
      auto note = [&](Type t) {
        auto regTy = dyn_cast<RegisterType>(t);
        if (!regTy || !regTy.isAllocated())
          return;
        if (isCalleeSaved(*regTy.getReg()))
          used.insert(*regTy.getReg());
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
