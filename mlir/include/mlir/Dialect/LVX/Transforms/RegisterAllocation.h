//===- RegisterAllocation.h - Allocate registers as a utility ---*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// The body of `-lvx-allocate-registers`, exposed so that a caller can allocate
// a function and act on the outcome. See lvx-mlir/docs/RegisterAllocation.md.
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_DIALECT_LVX_TRANSFORMS_REGISTERALLOCATION_H
#define MLIR_DIALECT_LVX_TRANSFORMS_REGISTERALLOCATION_H

#include "mlir/Dialect/LVXFunc/IR/LVXFunc.h"
#include "mlir/Support/LLVM.h"

namespace mlir {
namespace lvx {

/// The size of the allocatable pool the pass uses by default; the pass option
/// `max-registers` shrinks it, which is how the spill path is tested.
constexpr unsigned kDefaultMaxRegisters = 64;

/// Allocates physical registers in `func`, emitting diagnostics on it and
/// returning failure when it cannot be done -- a conflicting pin, or more
/// pressure than `maxRegisters` can hold.
///
/// The software pipeliner is why this is a function: modulo variable expansion
/// raises register demand, its bail-out is "keep the unpipelined version", and
/// a pass cannot run another pass. So the pipeliner allocates a clone and
/// discards it on failure (lvx-mlir/docs/SoftwarePipelining.md §1).
LogicalResult allocateRegisters(lvx_func::FuncOp func,
                                unsigned maxRegisters = kDefaultMaxRegisters);

} // namespace lvx
} // namespace mlir

#endif // MLIR_DIALECT_LVX_TRANSFORMS_REGISTERALLOCATION_H
