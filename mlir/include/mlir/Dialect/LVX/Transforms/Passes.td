//===- Passes.td - LVX dialect transform pass definitions ---*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_DIALECT_LVX_TRANSFORMS_PASSES
#define MLIR_DIALECT_LVX_TRANSFORMS_PASSES

include "mlir/Pass/PassBase.td"

def LVXAllocateRegistersPass
    : Pass<"lvx-allocate-registers", "::mlir::lvx_func::FuncOp"> {
  let summary = "Assign physical registers via linear scan (no spilling)";
  let description = [{
    Step 2 of the linear-scan register allocator described in
    docs/lvx/RegisterAllocation.md (Poletto & Sarkar, TOPLAS 1999, Fig. 1):
    runs `LVXLiveIntervals` (Step 1) to compute live intervals, coalesces
    each `lvx_scf.for` loop-carried channel (init operand / body iter_arg /
    yield operand / result) into a single allocation item, restricts
    register choice to callee-saved registers for any item whose range
    strictly straddles an `lvx_func.call`, then runs the standard
    increasing-start-order scan with `ExpireOldIntervals`, assigning each
    unfixed item the first free register in a fixed preference order.

    There is no spilling in this step: if no free register (of the
    allowed kind) exists for an item, the pass emits an error naming the
    value and its live range and fails, rather than falling back to
    memory. Every successfully assigned or already-ABI-pinned value has
    its `!lvx.reg` type rewritten in place to `!lvx.reg<rN>`; no new
    operations are inserted.
  }];
  let options = [
    Option<"maxRegisters", "max-registers", "unsigned", /*default=*/"62",
           "Size of the allocatable register pool, counted from the start "
           "of the fixed preference order. Exists so lit tests can force "
           "the bail-out path without hand-writing 62 live values; the "
           "real pool (all GPRs except the reserved R12/R13) is 62.">,
  ];
}

#endif // MLIR_DIALECT_LVX_TRANSFORMS_PASSES
