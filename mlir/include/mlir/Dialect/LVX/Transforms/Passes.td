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
  let summary = "Assign physical registers via linear scan, with spilling";
  let description = [{
    Steps 2 and 3 of the linear-scan register allocator described in
    docs/lvx/RegisterAllocation.md (Poletto & Sarkar, TOPLAS 1999, Fig. 1):
    runs `LVXLiveIntervals` (Step 1) to compute live intervals, coalesces
    each `lvx_scf.for` loop-carried channel (init operand / body iter_arg /
    yield operand / result) into a single allocation item, restricts
    register choice to callee-saved registers for any item whose range
    strictly straddles an `lvx_func.call`, then runs the standard
    increasing-start-order scan with `ExpireOldIntervals`, assigning each
    unfixed item the first free register in a fixed preference order --
    falling back to `SpillAtInterval` (spilling whichever of the current
    item or the furthest-ending spillable active item lives longer) when
    none is free.

    Spilled values are memory-resident for their whole original interval
    (no live-range splitting): a spill store is inserted right after the
    value's definition, and a fresh reload right before each use, using a
    small reserved scratch-register pool disjoint from the general
    allocatable one. A stack-pointer-relative prologue/epilogue is emitted
    automatically whenever at least one spill occurs. Two cases remain a
    hard error rather than being spilled: a coalesced `lvx_scf.for`
    loop-carried channel (not yet implemented), and a single instruction
    needing more simultaneously-reloaded operands than the scratch pool
    holds (realistically only `lvx_func.call` with many spilled
    arguments). Every successfully assigned or already-ABI-pinned value
    has its `!lvx.reg` type rewritten in place to `!lvx.reg<rN>`.
  }];
  let options = [
    Option<"maxRegisters", "max-registers", "unsigned", /*default=*/"59",
           "Size of the allocatable register pool, counted from the start "
           "of the fixed preference order. Exists so lit tests can force "
           "spilling (or, at the extreme, the remaining hard-error paths) "
           "without hand-writing dozens of live values; the real pool "
           "(all GPRs except the reserved R12/R13 and the 3 spill-scratch "
           "registers) is 59.">,
  ];
}

def LVXSCFToCFPass
    : Pass<"lvx-scf-to-cf", "::mlir::lvx_func::FuncOp"> {
  let summary = "Lower lvx_scf.for to lvx_cf branches, after allocation";
  let dependentDialects = ["lvx_cf::LVXCFDialect"];
  let description = [{
    See docs/lvx/AssemblyEmission.md ("lvx-scf-to-cf: lowering after
    allocation"). Must run strictly after `-lvx-allocate-registers`: real
    assembly has no structured loops, but the allocator's loop-carried
    coalescing needs `lvx_scf.for` intact, so this pass exists to lower it
    only once allocation is done. The two brand-new values it introduces
    (the loop-test comparison, the induction-variable increment) reuse
    Step 3's reserved spill-scratch registers rather than going through a
    fresh allocation decision -- this pass is not meant to run at any
    other pipeline point.
  }];
}

def LVXEmitAsmPass : Pass<"lvx-emit-asm", "::mlir::ModuleOp"> {
  let summary = "Print real LVX assembly text for every lvx_func.func";
  let description = [{
    See docs/lvx/AssemblyEmission.md. Must run after
    `-lvx-allocate-registers` and `-lvx-scf-to-cf` (every value needs a
    pinned `!lvx.reg<rN>` type, and there must be no structured
    `lvx_scf.for` left). Prints to stdout; combine with `-o /dev/null` to
    discard the normal (unchanged) IR dump this pass leaves behind. Two op
    families are an explicit, documented hard error rather than silently
    wrong output -- see "Scope: supported ops" in the design doc.
  }];
}

#endif // MLIR_DIALECT_LVX_TRANSFORMS_PASSES
