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
#include "llvm/ADT/StringRef.h"

namespace mlir {
namespace lvx {

/// The schedule of a software-pipelined kernel, as `-lvx-pipeline` leaves it
/// for allocation: the kernel loop's period, `kunroll * II` cycles, and each
/// body operation's issue cycle within it. The allocator keeps two values out
/// of one register when their occupancies meet modulo the period, which
/// program order alone cannot see (SoftwarePipelining.md §8, "Allocating
/// against the kernel's cycles"). Allocation consumes and removes both.
constexpr llvm::StringLiteral kKernelPeriodAttr = "lvx.kernel_period";
constexpr llvm::StringLiteral kKernelCycleAttr = "lvx.kernel_cycle";

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

/// Establishes what a tie requires of the IR: an operand read through the
/// destination is dead after the op that overwrites it. Readers of it after
/// the op move to a copy made just before it when the op's result recurs into
/// that operand through a loop; otherwise the op itself reads a private copy.
/// Allocation calls it, and so must anything that schedules before allocation
/// -- the copies are real instructions -- which is why it is exposed.
/// Idempotent. See lvx-mlir/docs/SoftwarePipelining.md §8, "Ties".
void legalizeTiedOperands(lvx_func::FuncOp func);

} // namespace lvx
} // namespace mlir

#endif // MLIR_DIALECT_LVX_TRANSFORMS_REGISTERALLOCATION_H
