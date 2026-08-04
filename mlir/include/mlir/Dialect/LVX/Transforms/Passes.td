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
    lvx-mlir/docs/RegisterAllocation.md (Poletto & Sarkar, TOPLAS 1999, Fig. 1):
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

def LVXRewriteDivmodPass
    : Pass<"lvx-rewrite-divmod", "::mlir::lvx_func::FuncOp"> {
  let summary = "Pin divmod's dual result to the r30:r31 scratch pair, post-allocation";
  let description = [{
    See lvx-mlir/docs/AssemblyEmission.md ("A narrower fix for divmod, sketched
    but not implemented" -- now implemented). Must run after
    `-lvx-allocate-registers`: `lvx.divmodd`/`divmodud`/`divmodw`/
    `divmoduw`'s quotient and remainder are ordinary, independently
    allocated values during Steps 1-3 (no allocator changes needed). This
    pass retypes both results in place to the fixed, aligned scratch pair
    `!lvx.reg<r30>`/`!lvx.reg<r31>` (real hardware's `registerM`
    destination operand -- confirmed low register = quotient, high
    register = remainder, and the `$rEVENrODD` assembly spelling, both by
    hand-assembling with the real `lvx-mbr-as` and executing on real
    gem5), then inserts an `lvx.mv` copy from each pinned result back to
    wherever Steps 1-3 originally allocated it -- only for a result that
    actually has a use, since `arith.divsi`/`remsi` each lower to their
    own full `lvx.divmodd` and often only one of the two results is ever
    read. `r30:r31` is already inside Step 3's existing spill-scratch
    reservation (`kSpillScratchRegs`), so no new register is carved out of
    the general pool, and the pinned window is always transient (dead
    before the next instruction), the same non-overlap argument already
    used for that reservation's other consumers.
  }];
}

def LVXSCFToCFPass
    : Pass<"lvx-scf-to-cf", "::mlir::lvx_func::FuncOp"> {
  let summary = "Lower lvx_scf.for to lvx_cf branches or a hardware loop, after allocation";
  let dependentDialects = ["lvx_cf::LVXCFDialect"];
  let description = [{
    See lvx-mlir/docs/AssemblyEmission.md ("lvx-scf-to-cf: lowering after
    allocation") and lvx-mlir/docs/HardwareLoops.md. Must run strictly after
    `-lvx-allocate-registers`: real assembly has no structured loops, but
    the allocator's loop-carried coalescing needs `lvx_scf.for` intact, so
    this pass exists to lower it only once allocation is done. Eligible
    loops (constant step 1, no nested `lvx_scf.for`) lower to a hardware
    zero-overhead loop (`lvx_cf.loopdo`, real `LOOPDO` opcode); everything
    else falls back to ordinary `lvx_cf` branches. Either way, the
    brand-new values this pass introduces reuse Step 3's reserved
    spill-scratch registers rather than going through a fresh allocation
    decision -- this pass is not meant to run at any other pipeline point.
  }];
}

def LVXCombinePass : Pass<"lvx-combine"> {
  let summary = "Peephole-combine lvx operations into stronger ones";
  let description = [{
    Greedy pattern rewriting over the `lvx` dialect only: every pattern
    rewrites `lvx` to `lvx`, so this pass cannot produce illegal IR and is
    safe to omit -- the pipeline still works without it, just with more
    instructions. Correctness lives in `-convert-to-lvx`; quality lives
    here. See lvx-mlir/docs/InstructionSelection.md.

    Must run after `-convert-to-lvx` (the patterns match `lvx` ops) and
    before `-lvx-allocate-registers` (combining changes which values are
    live). `-cse` afterwards is worthwhile: folding exposes new common
    subexpressions.

    Currently one family of pattern: `addd(muld(x, 2^n), b)` becomes
    `addx<2^n>d(x, b)`, and the 32-bit equivalent, which is the shape every
    affine array index has.
  }];
  let dependentDialects = ["::mlir::lvx::LVXDialect"];
}

def LVXEmitAsmPass : Pass<"lvx-emit-asm", "::mlir::ModuleOp"> {
  let summary = "Print real LVX assembly text for every lvx_func.func";
  let description = [{
    See lvx-mlir/docs/AssemblyEmission.md. Must run after
    `-lvx-allocate-registers` and `-lvx-scf-to-cf` (every value needs a
    pinned `!lvx.reg<rN>` type, and there must be no structured
    `lvx_scf.for` left). Prints to stdout; combine with `-o /dev/null` to
    discard the normal (unchanged) IR dump this pass leaves behind. Two op
    families are an explicit, documented hard error rather than silently
    wrong output -- see "Scope: supported ops" in the design doc.
  }];
}

#endif // MLIR_DIALECT_LVX_TRANSFORMS_PASSES
