//===- RegisterAllocation.cpp - LVX linear-scan register assignment -----===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Step 2 of the linear-scan register allocator described in
// docs/lvx/RegisterAllocation.md. See that file for the full design
// rationale, including two corrections made relative to the original
// walkthrough: call-clobbering is enforced via a precomputed per-item
// "crosses a call" restriction rather than synthetic fixed intervals, and
// `lvx_scf.for` loop-carried channels are coalesced into single allocation
// items to satisfy `ForOp`'s own type-equality verifier.
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/LVX/Transforms/Passes.h"

#include "mlir/Dialect/LVX/Analysis/LiveIntervals.h"
#include "mlir/Dialect/LVXFunc/IR/LVXFunc.h"
#include "mlir/Dialect/LVXSCF/IR/LVXSCF.h"
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

  bool isFixed() const { return fixedReg.has_value(); }
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
    // Callee-saved last -- using one forces prologue/epilogue save/restore
    // we don't emit yet.
    Register::r14,
    Register::r18, Register::r19, Register::r20, Register::r21,
    Register::r22, Register::r23, Register::r24, Register::r25,
    Register::r26, Register::r27, Register::r28, Register::r29,
    Register::r30, Register::r31,
};

// The callee-saved suffix of kFullOrder, in the same relative order --
// used for items whose range straddles a call.
static const Register *const kCalleeSavedOrder = kFullOrder + 47;
static constexpr unsigned kCalleeSavedCount = 15;
static_assert(std::size(kFullOrder) == 62,
              "expected 62 allocatable GPRs (all but R12/R13)");

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

  func.walk([&](lvx_scf::ForOp forOp) {
    OperandRange initArgs = forOp.getInitArgs();
    Block::BlockArgListType iterArgs = forOp.getRegionIterArgs();
    ResultRange results = forOp.getResults();
    auto yieldOp = cast<lvx_scf::YieldOp>(forOp.getBody()->getTerminator());
    OperandRange yieldOperands = yieldOp.getResults();
    for (unsigned i = 0, e = initArgs.size(); i != e; ++i) {
      AllocItem item;
      // Detect a genuine conflicting-fixed-register case explicitly
      // (mergeValue only records "some" fixed reg; check all four here).
      Value vInit = initArgs[i];
      Value vIter = iterArgs[i];
      Value vYield = yieldOperands[i];
      Value vResult = results[i];
      SmallVector<Register, 4> fixedRegsSeen;
      for (Value v : {vInit, vIter, vYield, vResult}) {
        mergeValue(item, v, live);
        if (const LiveInterval &iv = live.getInterval(v); iv.isFixed())
          fixedRegsSeen.push_back(*iv.fixedReg);
      }
      if (!fixedRegsSeen.empty() &&
          !llvm::all_equal(fixedRegsSeen))
        conflictingFixedGroup = true;
      grouped.insert(initArgs[i]);
      grouped.insert(iterArgs[i]);
      grouped.insert(yieldOperands[i]);
      grouped.insert(results[i]);
      items.push_back(std::move(item));
    }
  });

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
// The scan (Poletto & Sarkar Fig. 1, SpillAtInterval replaced by a hard
// error -- see docs/lvx/RegisterAllocation.md, "Bail-out semantics").
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
      std::optional<Register> reg = pickFree(order, this->maxRegisters, inUse);
      if (!reg) {
        mlir::emitError(item.values.front().getLoc())
            << "linear scan register allocation failed: no free"
            << (item.crossesCall ? " callee-saved" : "")
            << " register for value with live range [" << item.start << ", "
            << item.end << "]";
        return signalPassFailure();
      }
      item.assigned = *reg;
      inUse[static_cast<unsigned>(*reg)] = true;
      insertActive(idx);
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
  }
};

} // namespace
