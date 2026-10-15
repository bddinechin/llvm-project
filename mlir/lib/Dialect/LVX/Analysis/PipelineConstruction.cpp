//===- PipelineConstruction.cpp - Software pipeline construction ----------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/LVX/Analysis/PipelineConstruction.h"

#include "llvm/ADT/STLExtras.h"

#include <algorithm>
#include <cassert>

using namespace mlir;
using namespace mlir::lvx;

unsigned mlir::lvx::computePipelineUnroll(llvm::ArrayRef<int64_t> lifetimes,
                                          int64_t period) {
  assert(period > 0 && "a pipeline needs a positive period");
  int64_t names = 1;
  for (int64_t l : lifetimes) {
    // A live range no longer than the period fits in one name.
    int64_t need = l <= period ? 1 : (l + period - 1) / period;
    names = std::max(names, need);
  }
  unsigned unroll = 1;
  while (unroll < names)
    unroll *= 2;
  return unroll;
}

PipelineConstruction::PipelineConstruction(llvm::ArrayRef<int64_t> dates,
                                           int64_t period, unsigned unroll)
    : period(period), unroll(unroll) {
  assert(period > 0 && "a pipeline needs a positive period");
  assert(unroll > 0 && "the kernel is unrolled at least once");

  stages.reserve(dates.size());
  offsets.reserve(dates.size());
  for (int64_t d : dates) {
    assert(d >= 0 && "a local schedule starts at zero");
    stages.push_back(static_cast<unsigned>(d / period));
    offsets.push_back(d % period);
    numStages = std::max(numStages, stages.back() + 1);
  }

  // The steady state. Trip `t` issues operation `i` from source iteration
  // `t - stage(i)`: every stage runs at once, each on a different iteration,
  // which is what the period buys. Unrolling repeats that `unroll` times, one
  // period apart, and the iteration offsets shift with the copy.
  for (unsigned c = 0; c != unroll; ++c)
    for (unsigned i = 0, e = stages.size(); i != e; ++i)
      kernel.push_back({i, static_cast<int64_t>(c) - stages[i],
                        static_cast<int64_t>(c) * period + offsets[i]});
  llvm::sort(kernel);

  // Ramp-up. Section `p` is the trip at which only stages 0..p have a source
  // iteration to work on, so it issues those, from iterations p..0.
  prologue.resize(numStages - 1);
  for (unsigned p = 0; p + 1 != numStages; ++p) {
    for (unsigned i = 0, e = stages.size(); i != e; ++i)
      if (stages[i] <= p)
        prologue[p].push_back(
            {i, static_cast<int64_t>(p - stages[i]), offsets[i]});
    llvm::sort(prologue[p]);
  }

  // Drain, the mirror image: section `e` is a trip past the last the kernel
  // covered, so the stages that have already consumed their last iteration
  // fall away and only stages e+1.. remain. Their iteration offsets are
  // relative to the last source iteration, hence non-positive.
  epilogue.resize(numStages - 1);
  for (unsigned e = 0; e + 1 != numStages; ++e) {
    for (unsigned i = 0, n = stages.size(); i != n; ++i)
      if (stages[i] >= e + 1)
        epilogue[e].push_back(
            {i, static_cast<int64_t>(e) - static_cast<int64_t>(stages[i]) + 1,
             offsets[i]});
    llvm::sort(epilogue[e]);
  }
}

llvm::ArrayRef<PipelineTask>
PipelineConstruction::getPrologue(unsigned section) const {
  assert(section < prologue.size() && "no such prologue section");
  return prologue[section];
}

llvm::ArrayRef<PipelineTask>
PipelineConstruction::getEpilogue(unsigned section) const {
  assert(section < epilogue.size() && "no such epilogue section");
  return epilogue[section];
}

int64_t
PipelineConstruction::getKernelTripCount(int64_t sourceTripCount) const {
  // The kernel covers the trips the prologue and epilogue do not: all of them
  // but the `numStages - 1` the ramp and drain complete between them. Rounded
  // down to whole unrolled bodies, the rest being the remainder loop's.
  int64_t covered = sourceTripCount - (numStages - 1);
  if (covered <= 0)
    return 0;
  return covered / unroll;
}

int64_t
PipelineConstruction::getPipelinedTripCount(int64_t sourceTripCount) const {
  if (sourceTripCount < getMinimumTripCount())
    return 0;
  return getKernelTripCount(sourceTripCount) * unroll + (numStages - 1);
}

int64_t
PipelineConstruction::getRemainderTripCount(int64_t sourceTripCount) const {
  return sourceTripCount - getPipelinedTripCount(sourceTripCount);
}
