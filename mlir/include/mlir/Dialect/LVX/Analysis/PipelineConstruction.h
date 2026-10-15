//===- PipelineConstruction.h - Software pipeline construction --*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Turns a local schedule -- a date per loop-body operation, and a period --
// into the instances that make up a software pipeline: a prologue that ramps
// the stages up, a kernel that runs them all at once, and an epilogue that
// drains them. After Dupont de Dinechin, "A Unified Software Pipeline
// Construction Scheme for Modulo Scheduled Loops", PaCT 1997.
//
// This is deliberately free of IR: it answers "which instance of which
// operation issues where", and a pass turns that into blocks. Keeping it
// separate is also what [PaCT97]'s generality costs nothing here — the flat
// ordered task list is the representation its exit-branch machinery needs,
// should `scf.while` or an early exit ever reach this back end.
//
// See lvx-mlir/docs/SoftwarePipelining.md §§4–6.
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_DIALECT_LVX_ANALYSIS_PIPELINECONSTRUCTION_H
#define MLIR_DIALECT_LVX_ANALYSIS_PIPELINECONSTRUCTION_H

#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/SmallVector.h"

#include <cstdint>

namespace mlir {
namespace lvx {

/// One instance of a loop-body operation in the pipeline.
///
/// `iteration` is relative to the section that holds the instance: in the
/// kernel it is an offset from the trip, so the negative values are the stages
/// still in flight; in the prologue and epilogue it is an offset from the first
/// and last source iteration respectively. A pass reading this needs the
/// offset, never an absolute iteration number, because the trip count is a
/// run-time value.
struct PipelineTask {
  /// Index into the local schedule, i.e. position in the original loop body.
  unsigned op = 0;
  /// Which source iteration, relative to the section. See above.
  int64_t iteration = 0;
  /// Issue cycle within the section. Kernel cycles lie in [0, unroll*period).
  int64_t cycle = 0;

  /// The order [PaCT97] linearises instances by: cycle, then iteration, then
  /// position in the original body. Instances that issue together keep the
  /// older iteration first, and within one iteration the original order.
  bool operator<(const PipelineTask &o) const {
    if (cycle != o.cycle)
      return cycle < o.cycle;
    if (iteration != o.iteration)
      return iteration < o.iteration;
    return op < o.op;
  }
  bool operator==(const PipelineTask &o) const {
    return op == o.op && iteration == o.iteration && cycle == o.cycle;
  }
};

/// The kernel unrolling a set of live ranges forces.
///
/// A value whose live range outlasts the period needs `ceil(l / period)` names
/// rotated cyclically, and the rotation only closes at the kernel's back edge
/// if that count divides the unrolling. Rounding each count up to a power of
/// two makes every requirement divide every larger one, so the answer is a
/// single power of two below `2 * max`, where taking the least common multiple
/// would be a product -- three and five names would force fifteen copies of
/// the body rather than eight.
///
/// The names the rounding adds cost no registers: a value wanting three names
/// still has only three live at once, so the fourth takes a register one of
/// them has finished with. Interference is the live ranges, not the spelling.
/// See SoftwarePipelining.md §5.
unsigned computePipelineUnroll(llvm::ArrayRef<int64_t> lifetimes,
                               int64_t period);

/// Builds the instances of a software pipeline from a local schedule.
///
/// Only the counted single-exit loop is handled, which under LOOPDO has no
/// exit branch at all, so the construction degenerates to prologue, kernel and
/// epilogue by stage.
///
/// *Reading the offsets.* A section's `iteration` is relative, and this is the
/// mapping back to a source iteration -- the one a pass needs to pick the right
/// rotated name, and the one the unit test replays to prove every operation of
/// every covered iteration issues exactly once:
///
///   prologue section p, task t   ->  t.iteration
///   kernel loop trip r, task t   ->  numStages - 1 + r * unroll + t.iteration
///   epilogue section e, task t   ->  getPipelinedTripCount() - 1 + t.iteration
///
/// The kernel's trips are `getKernelTripCount()`, so the three ranges tile
/// `[0, getPipelinedTripCount())` and the remainder loop takes the rest.
class PipelineConstruction {
public:
  /// `dates[i]` is the date assigned to operation `i` of the loop body, in body
  /// order; `period` is the initiation interval; `unroll` is the kernel
  /// unrolling, which must be positive and is normally
  /// `computePipelineUnroll`'s answer.
  PipelineConstruction(llvm::ArrayRef<int64_t> dates, int64_t period,
                       unsigned unroll = 1);

  int64_t getPeriod() const { return period; }
  unsigned getUnroll() const { return unroll; }

  /// The number of stages the local schedule spans. One means the loop needs
  /// no pipelining: there is nothing in flight across the back edge.
  unsigned getNumStages() const { return numStages; }

  /// The stage and the offset within it of operation `i`.
  unsigned getStage(unsigned i) const { return stages[i]; }
  int64_t getOffset(unsigned i) const { return offsets[i]; }

  /// Ramp-up sections, `getNumStages() - 1` of them, in issue order. Section
  /// `p` issues the operations of stages 0..p, from source iterations p..0.
  unsigned getNumPrologueSections() const { return numStages - 1; }
  llvm::ArrayRef<PipelineTask> getPrologue(unsigned section) const;

  /// The steady state: `unroll` trips' worth of instances, sorted, with cycles
  /// in [0, unroll * period). An instance's `iteration` is its offset from the
  /// trip, so stage `s` of copy `c` carries `c - s`.
  llvm::ArrayRef<PipelineTask> getKernel() const { return kernel; }

  /// Drain sections, `getNumStages() - 1` of them, in issue order. Section `e`
  /// issues the operations of stages e+1..numStages-1, whose `iteration` is
  /// the non-positive offset from the last source iteration the pipelined code
  /// completes, `getPipelinedTripCount() - 1`.
  unsigned getNumEpilogueSections() const { return numStages - 1; }
  llvm::ArrayRef<PipelineTask> getEpilogue(unsigned section) const;

  /// The smallest source trip count for which the pipeline is worth entering:
  /// below it the prologue and epilogue alone would do the work, and the
  /// kernel would run a negative number of times. A guard must send shorter
  /// loops to an unpipelined copy.
  int64_t getMinimumTripCount() const { return numStages - 1; }

  /// How many times the kernel runs, given a source trip count -- the trips it
  /// covers, rounded down to a whole number of unrolled bodies. Since `unroll`
  /// is a power of two this is a mask on the LOOPDO count, not a division.
  int64_t getKernelTripCount(int64_t sourceTripCount) const;

  /// How many source iterations the pipelined code completes.
  ///
  /// Zero below `getMinimumTripCount()`, where the pipeline is not entered at
  /// all. At or above it this is the kernel's trips plus the `numStages - 1`
  /// that the ramp and drain complete between them -- note that a kernel
  /// running zero times is still correct and still covers those, the prologue
  /// and epilogue being a straight-line version of the whole loop.
  int64_t getPipelinedTripCount(int64_t sourceTripCount) const;

  /// What is left for an unpipelined copy: the source trip count less
  /// `getPipelinedTripCount`.
  int64_t getRemainderTripCount(int64_t sourceTripCount) const;

private:
  int64_t period;
  unsigned unroll;
  unsigned numStages = 1;
  llvm::SmallVector<unsigned> stages;
  llvm::SmallVector<int64_t> offsets;
  llvm::SmallVector<PipelineTask> kernel;
  llvm::SmallVector<llvm::SmallVector<PipelineTask>> prologue, epilogue;
};

} // namespace lvx
} // namespace mlir

#endif // MLIR_DIALECT_LVX_ANALYSIS_PIPELINECONSTRUCTION_H
