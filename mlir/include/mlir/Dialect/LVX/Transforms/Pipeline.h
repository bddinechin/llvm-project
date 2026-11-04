//===- Pipeline.h - Software pipelining as a utility ------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// The back half of `-lvx-pipeline`, exposed so that a modulo scheduler can ask
// whether an initiation interval has a register solution before it settles on
// one. See lvx-mlir/docs/SoftwarePipelining.md §8, step 3, and
// lvx-csw/docs/mlir-pipeliner-design.md §1a.
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_DIALECT_LVX_TRANSFORMS_PIPELINE_H
#define MLIR_DIALECT_LVX_TRANSFORMS_PIPELINE_H

#include "mlir/Dialect/LVX/Transforms/RegisterAllocation.h"
#include "mlir/Dialect/LVXSCF/IR/LVXSCF.h"
#include "mlir/Support/LLVM.h"

namespace mlir {
namespace lvx {

/// Whether software-pipelining `loop` at the modulo schedule `dates` (one per
/// body operation, in body order) and `ii` leaves a function that allocates
/// as well as the one holding the loop unpipelined: no more spills, and every
/// kernel value kept free in its own cycles. A schedule the construction
/// refuses does not. Tried on copies; nothing is changed, and nothing is
/// reported.
///
/// This is the scheduler's register feasibility test, GCC's colourability at
/// an II: a scheduler that does not ask may settle on an II with no register
/// solution.
bool pipelineAllocates(lvx_scf::ForOp loop, ArrayRef<int64_t> dates,
                       int64_t ii,
                       unsigned maxRegisters = kDefaultMaxRegisters);

} // namespace lvx
} // namespace mlir

#endif // MLIR_DIALECT_LVX_TRANSFORMS_PIPELINE_H
