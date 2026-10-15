//===- CrossStageValues.h - What a stage assignment leaves in flight -*- C++ -*-//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// A software pipeline overlaps iterations, so a value computed in one stage and
// consumed in a later one is alive while the kernel has started the iterations
// in between. Those are the values the kernel has to carry, and the ones modulo
// variable expansion gives more than one name.
//
// This computes them from a stage assignment over an `lvx_scf.for` body, and
// with them the number of names the kernel needs -- which is what decides the
// unrolling (PipelineConstruction.h, lvx-mlir/docs/SoftwarePipelining.md §5).
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_DIALECT_LVX_ANALYSIS_CROSSSTAGEVALUES_H
#define MLIR_DIALECT_LVX_ANALYSIS_CROSSSTAGEVALUES_H

#include "mlir/Dialect/LVXSCF/IR/LVXSCF.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/SmallVector.h"

namespace mlir {
namespace lvx {

/// The values an `lvx_scf.for` body leaves in flight under a stage assignment.
class CrossStageValues {
public:
  /// A value alive across one or more kernel trips.
  struct Crossing {
    /// The value, as defined in the original body.
    Value value;
    /// The stage that defines it. For a value entering through an `iter_arg`
    /// this is the stage of the `lvx_scf.yield` operand that produced it.
    unsigned defStage = 0;
    /// The latest stage that reads it.
    unsigned lastUseStage = 0;
    /// Whether the value reaches its use through the loop's back edge, which
    /// adds a trip to the distance.
    bool loopCarried = false;

    /// How many kernel trips separate the definition from the last use. A
    /// loop-carried value crosses the back edge as well, hence the extra trip.
    unsigned distance() const {
      return lastUseStage - defStage + (loopCarried ? 1 : 0);
    }
    /// How many names the kernel needs for it: one per trip it stays alive in,
    /// counting the trip that defines it.
    unsigned names() const { return distance() + 1; }
  };

  /// `stages[i]` is the stage assigned to the i-th operation of `loop`'s body
  /// in body order, excluding the terminator.
  CrossStageValues(lvx_scf::ForOp loop, llvm::ArrayRef<unsigned> stages);

  /// Whether the stage assignment is self-consistent: no value is read in an
  /// earlier stage than the one that computes it. A schedule that violates
  /// this cannot be made into a pipeline at all, and the pass must reject it
  /// rather than emit code that reads an undefined register.
  bool isValid() const { return valid; }

  llvm::ArrayRef<Crossing> getCrossings() const { return crossings; }

  /// The largest `names()` over all crossings, which is the rotation the
  /// kernel has to support; one when nothing crosses a stage.
  unsigned getMaxNames() const { return maxNames; }

  /// The stage assignment this was built from, and the stage count it spans.
  llvm::ArrayRef<unsigned> getStages() const { return stages; }
  unsigned getNumStages() const { return numStages; }

private:
  void note(Value value, unsigned defStage, unsigned useStage,
            bool loopCarried);

  llvm::SmallVector<unsigned> stages;
  llvm::SmallVector<Crossing> crossings;
  unsigned numStages = 1;
  unsigned maxNames = 1;
  bool valid = true;
};

} // namespace lvx
} // namespace mlir

#endif // MLIR_DIALECT_LVX_ANALYSIS_CROSSSTAGEVALUES_H
