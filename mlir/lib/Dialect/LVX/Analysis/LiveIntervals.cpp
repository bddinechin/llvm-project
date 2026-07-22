//===- LiveIntervals.cpp - Live interval analysis for LVX register alloc ===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/LVX/Analysis/LiveIntervals.h"
#include "mlir/Dialect/LVXSCF/IR/LVXSCF.h"
#include "mlir/Analysis/Liveness.h"
#include "mlir/IR/RegionGraphTraits.h"
#include "llvm/ADT/PostOrderIterator.h"

using namespace mlir;
using namespace mlir::lvx;

//===----------------------------------------------------------------------===//
// Numbering
//===----------------------------------------------------------------------===//

void LVXLiveIntervals::numberBlock(Block *block, unsigned &counter) {
  // Reserve a slot for the block's own entry / its arguments' definition
  // point, strictly before its first operation.
  blockNumber[block] = counter++;
  for (Operation &op : *block) {
    opNumber[&op] = counter++;
    if (auto forOp = dyn_cast<lvx_scf::ForOp>(op))
      numberBlock(forOp.getBody(), counter);
  }
}

//===----------------------------------------------------------------------===//
// Interval construction
//===----------------------------------------------------------------------===//

static LiveInterval &getOrCreate(Value value,
                                 DenseMap<Value, unsigned> &valueToIndex,
                                 SmallVectorImpl<LiveInterval> &intervals) {
  auto it = valueToIndex.find(value);
  if (it != valueToIndex.end())
    return intervals[it->second];
  unsigned idx = intervals.size();
  valueToIndex[value] = idx;
  intervals.push_back(LiveInterval{value, 0, 0, std::nullopt});
  return intervals.back();
}

static void setFixedRegIfPinned(LiveInterval &iv) {
  if (auto regTy = dyn_cast<RegisterType>(iv.value.getType()))
    iv.fixedReg = regTy.getReg();
}

void LVXLiveIntervals::buildIntervals(lvx_func::FuncOp func) {
  // Seed every value's interval at its definition point: block arguments
  // at their block's reserved entry slot, op results at the op's number.
  // A value that turns out to be a pinned `!lvx.reg<rN>` (ABI-constrained)
  // becomes a fixed interval.
  func.walk([&](Block *block) {
    for (BlockArgument arg : block->getArguments()) {
      LiveInterval &iv = getOrCreate(arg, valueToIntervalIndex, intervals);
      iv.start = iv.end = getNumber(block);
      setFixedRegIfPinned(iv);
    }
  });
  func.walk([&](Operation *op) {
    if (!opNumber.count(op))
      return; // `func` itself, and anything outside the numbered body.
    unsigned n = getNumber(op);
    for (Value result : op->getResults()) {
      LiveInterval &iv = getOrCreate(result, valueToIntervalIndex, intervals);
      iv.start = iv.end = n;
      setFixedRegIfPinned(iv);
    }
    for (Value operand : op->getOperands()) {
      LiveInterval &iv = getOrCreate(operand, valueToIntervalIndex, intervals);
      iv.end = std::max(iv.end, n);
    }
  });

  // Extend intervals for values that pass through a block untouched (live
  // out of it per real dataflow liveness, but with no direct use recorded
  // above because the block never references them). A value's `start` is
  // always already exactly its definition point and never needs a
  // live-in-based correction.
  Liveness liveness(func);
  func.walk([&](Block *block) {
    const LivenessBlockInfo *info = liveness.getLiveness(block);
    if (!info || block->empty())
      return;
    unsigned blockEnd = getNumber(&block->back());
    for (Value value : info->out()) {
      LiveInterval &iv = getOrCreate(value, valueToIntervalIndex, intervals);
      iv.end = std::max(iv.end, blockEnd);
    }
  });

  llvm::sort(intervals, [](const LiveInterval &a, const LiveInterval &b) {
    return a.start < b.start;
  });
  valueToIntervalIndex.clear();
  for (auto [idx, iv] : llvm::enumerate(intervals))
    valueToIntervalIndex[iv.value] = idx;
}

LVXLiveIntervals::LVXLiveIntervals(lvx_func::FuncOp func) {
  if (func.isExternal())
    return;
  unsigned counter = 0;
  llvm::ReversePostOrderTraversal<Block *> rpo(&func.getBody().front());
  for (Block *block : rpo)
    numberBlock(block, counter);
  buildIntervals(func);
}

const LiveInterval &LVXLiveIntervals::getInterval(Value value) const {
  auto it = valueToIntervalIndex.find(value);
  assert(it != valueToIntervalIndex.end() &&
        "value has no computed live interval");
  return intervals[it->second];
}
