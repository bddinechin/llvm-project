//===- RegisterAllocation.cpp - LVX linear-scan register assignment -----===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Steps 2 and 3 of the linear-scan register allocator described in
// docs/lvx/RegisterAllocation.md, as one pass: Step 2 is Fig. 1's scan with
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

#include "mlir/Dialect/LVX/Analysis/LiveIntervals.h"
#include "mlir/Dialect/LVXFunc/IR/LVXFunc.h"
#include "mlir/Dialect/LVXSCF/IR/LVXSCF.h"
#include "mlir/IR/Builders.h"
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
/// case) or a coalesced `lvx_scf.for` loop-carried channel (init operand,
/// body iter_arg, yield operand, and the op's own result, all sharing one
/// physical register -- see docs/lvx/RegisterAllocation.md).
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
  // docs/lvx/RegisterAllocation.md, "What remains a hard error".
  bool isGroup() const { return values.size() > 1; }
};

//===----------------------------------------------------------------------===//
// Register pool: preference order per docs/lvx/RegisterAllocation.md
// ("Allocation order"), derived from lvx_Convention.yml's `regular`
// convention. R12 (stack pointer) and R13 (local/TLS) are always reserved
// and never appear here.
//===----------------------------------------------------------------------===//

static const Register kFullOrder[] = {
    // Argument/result registers first.
    Register::r0, Register::r1, Register::r2, Register::r3, Register::r4,
    Register::r5, Register::r6, Register::r7, Register::r8, Register::r9,
    Register::r10, Register::r11,
    // Remaining caller-saved scratch.
    Register::r15, Register::r16, Register::r17,
    Register::r32, Register::r33, Register::r34, Register::r35,
    Register::r36, Register::r37, Register::r38, Register::r39,
    Register::r40, Register::r41, Register::r42, Register::r43,
    Register::r44, Register::r45, Register::r46, Register::r47,
    Register::r48, Register::r49, Register::r50, Register::r51,
    Register::r52, Register::r53, Register::r54, Register::r55,
    Register::r56, Register::r57, Register::r58, Register::r59,
    Register::r60, Register::r61, Register::r62, Register::r63,
    // Callee-saved last -- using one forces the prologue/epilogue
    // save/restore this pass now emits when spilling is in play.
    Register::r14,
    Register::r18, Register::r19, Register::r20, Register::r21,
    Register::r22, Register::r23, Register::r24, Register::r25,
    Register::r26, Register::r27, Register::r28,
};

// The callee-saved suffix of kFullOrder, in the same relative order --
// used for items whose range straddles a call.
static const Register *const kCalleeSavedOrder = kFullOrder + 47;
static constexpr unsigned kCalleeSavedCount = 12;
static_assert(std::size(kFullOrder) == 59,
              "expected 59 allocatable GPRs (all but R12/R13 and the 3 "
              "spill-scratch registers below)");

//===----------------------------------------------------------------------===//
// Spill scratch registers: reserved out of the general pool above (never
// handed to an ordinary long-lived item), used exclusively for a spilled
// value's transient def-then-store or reload-then-use window. Sized for
// the worst case among currently-defined ops needing several
// simultaneously (lvx.cmoved/cmovew's 3 register operands,
// lvx.divmodd/.../'s 2 results) -- see docs/lvx/RegisterAllocation.md,
// "Reserved scratch registers".
//===----------------------------------------------------------------------===//

static const Register kSpillScratchRegs[] = {Register::r29, Register::r30,
                                             Register::r31};
static constexpr unsigned kNumSpillScratchRegs = 3;

/// Picks the first free register in `order` (truncated to `poolSize`
/// entries), or nullopt if none is free.
static std::optional<Register> pickFree(ArrayRef<Register> order,
                                        unsigned poolSize,
                                        const bool inUse[65]) {
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
  // this fixes (docs/lvx/RegisterAllocation.md, "nested lvx_scf.for").
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
// docs/lvx/RegisterAllocation.md, "Frame layout and prologue/epilogue" and
// "No interval splitting / no lifetime holes".
//===----------------------------------------------------------------------===//

/// Inserts `%sp0 = lvx.sp; %off = lvx.li frameSize; %spBase = lvx.sbfd %sp0,
/// %off` at the top of `func`'s entry block, and mirrors the subtraction
/// with an `lvx.addd` restore before every `lvx_func.return` in the
/// function. Returns the value spill loads/stores should use as their base
/// operand. Only called when `frameSize > 0`.
static Value insertPrologueEpilogue(lvx_func::FuncOp func, unsigned frameSize,
                                    MLIRContext *ctx) {
  Type r12Ty = RegisterType::get(ctx, Register::r12);
  Type genTy = RegisterType::get(ctx, std::nullopt);
  OpBuilder builder(ctx);

  Block &entry = func.getBody().front();
  builder.setInsertionPointToStart(&entry);
  Location loc = func.getLoc();
  Value sp0 = builder.create<SpOp>(loc, r12Ty);
  Value off =
      builder.create<LiOp>(loc, genTy, builder.getI64IntegerAttr(frameSize));
  Value spBase = builder.create<SbfdOp>(loc, r12Ty, sp0, off);

  func.walk([&](lvx_func::ReturnOp ret) {
    builder.setInsertionPoint(ret);
    Value off2 = builder.create<LiOp>(ret.getLoc(), genTy,
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
    // docs/lvx/RegisterAllocation.md, "What remains a hard error".
    assert(!item.isGroup() && "coalesced group reached spill rewrite");
    Value v = item.values.front();
    auto offsetAttr = builder.getSI32IntegerAttr(
        static_cast<int32_t>(*item.spillOffset));

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
// see docs/lvx/RegisterAllocation.md, "Step 3").
//===----------------------------------------------------------------------===//

struct LVXAllocateRegistersPass
    : public lvx::impl::LVXAllocateRegistersPassBase<
          LVXAllocateRegistersPass> {
  using LVXAllocateRegistersPassBase::LVXAllocateRegistersPassBase;

  void runOnOperation() override {
    lvx_func::FuncOp func = getOperation();
    if (func.isExternal())
      return;

    LVXLiveIntervals live(func);
    bool conflictingFixedGroup = false;
    SmallVector<AllocItem> items =
        buildAllocItems(func, live, conflictingFixedGroup);
    if (conflictingFixedGroup) {
      func.emitError("lvx_scf.for loop-carried channel has members pinned "
                      "to different physical registers");
      return signalPassFailure();
    }
    markCallCrossings(func, live, items);

    bool inUse[65] = {};
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
              : ArrayRef<Register>(kFullOrder);
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
      // back for the first eligible one. See docs/lvx/RegisterAllocation.md,
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
               "coalesced lvx_scf.for loop-carried channel is not yet "
               "implemented (live range [" << item.start << ", " << item.end
            << "])";
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

    if (frameSize > 0) {
      Value spBase = insertPrologueEpilogue(func, frameSize, &getContext());
      if (failed(rewriteSpills(&getContext(), items, spBase)))
        return signalPassFailure();
    }
  }
};

} // namespace
