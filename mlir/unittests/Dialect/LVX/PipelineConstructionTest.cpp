//===- PipelineConstructionTest.cpp ---------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/LVX/Analysis/PipelineConstruction.h"
#include "gtest/gtest.h"

#include <map>
#include <set>

using namespace mlir::lvx;

namespace {

/// Replays a constructed pipeline over `tripCount` source iterations and
/// returns how many times each (operation, source iteration) pair issues.
///
/// This is the property that matters and the one a shape test cannot see: the
/// pipeline must execute every operation of every iteration it claims to
/// cover, exactly once, with none left in flight and none run twice.
static std::map<std::pair<unsigned, int64_t>, unsigned>
replay(const PipelineConstruction &p, unsigned numOps, int64_t tripCount) {
  std::map<std::pair<unsigned, int64_t>, unsigned> issued;
  int64_t stages = p.getNumStages();
  int64_t kernelTrips = p.getKernelTripCount(tripCount);
  int64_t unroll = p.getUnroll();
  int64_t covered = p.getPipelinedTripCount(tripCount);
  if (covered == 0)
    return {}; // the pipeline is not entered; it is all the remainder's

  for (unsigned s = 0; s != p.getNumPrologueSections(); ++s)
    for (const PipelineTask &t : p.getPrologue(s))
      ++issued[{t.op, t.iteration}];

  for (int64_t r = 0; r != kernelTrips; ++r)
    for (const PipelineTask &t : p.getKernel())
      ++issued[{t.op, stages - 1 + r * unroll + t.iteration}];

  for (unsigned s = 0; s != p.getNumEpilogueSections(); ++s)
    for (const PipelineTask &t : p.getEpilogue(s))
      ++issued[{t.op, covered - 1 + t.iteration}];

  return issued;
}

/// Checks the replay covers exactly the pipelined iterations, once each.
static void expectExactCoverage(const PipelineConstruction &p, unsigned numOps,
                                int64_t tripCount) {
  int64_t covered = p.getPipelinedTripCount(tripCount);
  auto issued = replay(p, numOps, tripCount);
  for (unsigned i = 0; i != numOps; ++i)
    for (int64_t j = 0; j != covered; ++j) {
      auto it = issued.find({i, j});
      ASSERT_NE(it, issued.end())
          << "op " << i << " of iteration " << j << " never issues";
      EXPECT_EQ(it->second, 1u)
          << "op " << i << " of iteration " << j << " issues twice";
    }
  EXPECT_EQ(issued.size(), numOps * static_cast<size_t>(covered))
      << "an instance issues outside the covered iterations";
  // And the remainder accounts for the rest.
  EXPECT_EQ(covered + p.getRemainderTripCount(tripCount), tripCount);
}

/// The textbook two-stage pipeline: a load at stage 0, its use at stage 1.
TEST(PipelineConstruction, TwoStages) {
  int64_t dates[] = {0, 3}; // period 2: stage 0 offset 0, stage 1 offset 1
  PipelineConstruction p(dates, /*period=*/2);

  EXPECT_EQ(p.getNumStages(), 2u);
  EXPECT_EQ(p.getStage(0), 0u);
  EXPECT_EQ(p.getOffset(0), 0);
  EXPECT_EQ(p.getStage(1), 1u);
  EXPECT_EQ(p.getOffset(1), 1);

  ASSERT_EQ(p.getNumPrologueSections(), 1u);
  ASSERT_EQ(p.getPrologue(0).size(), 1u);
  EXPECT_EQ(p.getPrologue(0)[0], (PipelineTask{0, 0, 0}));

  ASSERT_EQ(p.getKernel().size(), 2u);
  EXPECT_EQ(p.getKernel()[0], (PipelineTask{0, 0, 0}));  // this iteration
  EXPECT_EQ(p.getKernel()[1], (PipelineTask{1, -1, 1})); // the previous one

  ASSERT_EQ(p.getNumEpilogueSections(), 1u);
  ASSERT_EQ(p.getEpilogue(0).size(), 1u);
  EXPECT_EQ(p.getEpilogue(0)[0], (PipelineTask{1, 0, 1}));

  EXPECT_EQ(p.getMinimumTripCount(), 1);
  expectExactCoverage(p, 2, 10);
}

/// A single stage is a loop that needs no pipelining at all.
TEST(PipelineConstruction, OneStageIsNotAPipeline) {
  int64_t dates[] = {0, 1, 2};
  PipelineConstruction p(dates, /*period=*/4);

  EXPECT_EQ(p.getNumStages(), 1u);
  EXPECT_EQ(p.getNumPrologueSections(), 0u);
  EXPECT_EQ(p.getNumEpilogueSections(), 0u);
  EXPECT_EQ(p.getKernel().size(), 3u);
  EXPECT_EQ(p.getMinimumTripCount(), 0);
  expectExactCoverage(p, 3, 7);
}

/// Unrolling repeats the steady state, shifting the iteration offsets with the
/// copy, and leaves the ramp and drain alone.
TEST(PipelineConstruction, UnrollRepeatsTheKernel) {
  int64_t dates[] = {0, 3};
  PipelineConstruction p(dates, /*period=*/2, /*unroll=*/2);

  ASSERT_EQ(p.getKernel().size(), 4u);
  EXPECT_EQ(p.getKernel()[0], (PipelineTask{0, 0, 0}));
  EXPECT_EQ(p.getKernel()[1], (PipelineTask{1, -1, 1}));
  EXPECT_EQ(p.getKernel()[2], (PipelineTask{0, 1, 2}));
  EXPECT_EQ(p.getKernel()[3], (PipelineTask{1, 0, 3}));

  EXPECT_EQ(p.getNumPrologueSections(), 1u);
  EXPECT_EQ(p.getNumEpilogueSections(), 1u);
  expectExactCoverage(p, 2, 10);
}

/// Deep pipelines: every stage count, unrolling and trip count must still
/// cover each iteration exactly once.
TEST(PipelineConstruction, CoverageAcrossShapes) {
  for (int64_t period : {1, 2, 3, 5})
    for (unsigned stages : {1u, 2u, 3u, 5u})
      for (unsigned unroll : {1u, 2u, 4u})
        for (int64_t trips : {0, 1, 2, 7, 16, 33}) {
          // One operation per stage, spread over the offsets.
          llvm::SmallVector<int64_t> dates;
          for (unsigned s = 0; s != stages; ++s)
            dates.push_back(s * period + (s % period));
          PipelineConstruction p(dates, period, unroll);
          ASSERT_EQ(p.getNumStages(), stages)
              << "period " << period << " stages " << stages;
          expectExactCoverage(p, stages, trips);
        }
}

/// Below the minimum trip count the kernel never runs and everything is the
/// remainder loop's -- which is the guard a pass must emit.
TEST(PipelineConstruction, ShortLoopsFallToTheRemainder) {
  int64_t dates[] = {0, 2, 4}; // three stages at period 2
  PipelineConstruction p(dates, /*period=*/2);

  EXPECT_EQ(p.getNumStages(), 3u);
  EXPECT_EQ(p.getMinimumTripCount(), 2);
  EXPECT_EQ(p.getKernelTripCount(0), 0);
  EXPECT_EQ(p.getRemainderTripCount(0), 0);
  EXPECT_EQ(p.getKernelTripCount(1), 0);
  EXPECT_EQ(p.getRemainderTripCount(1), 1);
  // At exactly the minimum the pipeline is entered with no kernel trips: the
  // ramp and the drain between them are the whole loop, straight-line.
  EXPECT_EQ(p.getKernelTripCount(2), 0);
  EXPECT_EQ(p.getPipelinedTripCount(2), 2);
  EXPECT_EQ(p.getRemainderTripCount(2), 0);
  EXPECT_EQ(p.getKernelTripCount(5), 3);
  EXPECT_EQ(p.getRemainderTripCount(5), 0);
}

/// The trip count splits into whole unrolled bodies plus a remainder.
TEST(PipelineConstruction, TripCountSplit) {
  int64_t dates[] = {0, 2};
  PipelineConstruction p(dates, /*period=*/2, /*unroll=*/4);

  // Two stages, so one trip is spent ramping up; the rest divide by four.
  EXPECT_EQ(p.getKernelTripCount(13), 3); // (13 - 1) / 4
  EXPECT_EQ(p.getRemainderTripCount(13), 0);
  EXPECT_EQ(p.getKernelTripCount(14), 3);
  EXPECT_EQ(p.getRemainderTripCount(14), 1);
  expectExactCoverage(p, 2, 14);
}

/// Instances are linearised by cycle, then iteration, then position in the
/// body -- so an older iteration issues first when two share a cycle.
TEST(PipelineConstruction, OrderIsCycleThenIterationThenPosition) {
  int64_t dates[] = {1, 1, 3}; // two ops at cycle 1 of stage 0, one at stage 1
  PipelineConstruction p(dates, /*period=*/2);

  llvm::ArrayRef<PipelineTask> k = p.getKernel();
  ASSERT_EQ(k.size(), 3u);
  // Cycle 1 holds all three: the stage-1 instance is from the older iteration
  // and comes first; the two stage-0 ones keep their body order.
  EXPECT_EQ(k[0], (PipelineTask{2, -1, 1}));
  EXPECT_EQ(k[1], (PipelineTask{0, 0, 1}));
  EXPECT_EQ(k[2], (PipelineTask{1, 0, 1}));
}

/// The unrolling a set of live ranges forces, rounded to a power of two.
TEST(PipelineConstruction, UnrollIsAPowerOfTwo) {
  // Nothing outlasts the period.
  EXPECT_EQ(computePipelineUnroll({1, 2, 4}, 4), 1u);
  // One name over: two copies.
  EXPECT_EQ(computePipelineUnroll({5}, 4), 2u);
  // Exactly two periods is still two names.
  EXPECT_EQ(computePipelineUnroll({8}, 4), 2u);
  // Three names round to four.
  EXPECT_EQ(computePipelineUnroll({9}, 4), 4u);

  // The case the rounding exists for: three and five names would force
  // fifteen copies by least common multiple, and force eight this way.
  int64_t threeAndFive[] = {3 * 4, 5 * 4};
  EXPECT_EQ(computePipelineUnroll(threeAndFive, 4), 8u);

  EXPECT_EQ(computePipelineUnroll({}, 3), 1u);
}

} // namespace
