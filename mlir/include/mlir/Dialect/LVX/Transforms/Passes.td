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

def LVXIfConvertPass
    : Pass<"lvx-if-convert", "::mlir::lvx_func::FuncOp"> {
  let summary = "Replace a small scf.if with `guard`-predicated instructions";
  let description = [{
    If-conversion for the `GUARD` BCU prefix, the same transformation
    lvx-gcc does in CE2/CE3 (see `lvx_ifcvt_*` in `lvx.cc`). A branch
    around a short arm becomes straight-line code in which each remaining
    instruction carries `guard.<cond> $rN?`, so the arm's work can be
    bundled with the code around it instead of costing a taken branch.

    An **optimization, not an enabling pass**: what it declines is left as
    `scf.if` for `-convert-scf-to-cf` to turn into an ordinary branch
    diamond, which `-convert-to-lvx` already lowers. That is why this is a
    separate pass and not a pattern inside `-convert-to-lvx`, whose
    `applyFullConversion` cannot let a pattern decline on cost grounds
    without failing the whole conversion.

    It runs **after** `-convert-to-lvx`, on the branch form, which is where
    lvx-gcc's CE3 runs too. The structured form looks easier -- `scf.if`'s
    arms are explicit regions and no diamond has to be recognized -- and is
    wrong, because a store's address arithmetic does not exist yet: the
    conversion materializes `lvx.li`/`muld`/`addd` where the store is, so an
    arm holding one store would become a guard over four ops, three of them
    pure and needlessly predicated. After the lowering those three are
    ordinary speculation candidates.

    Two decisions, lvx-gcc's:

    1. **Speculate what is free.** An op with no memory effects that is
       safe to speculate runs unconditionally, outside the guard, costing
       no prefix syllable at all. This is CE3's rule ("a non-memory,
       non-trapping insn whose destination is dead after the block"), and
       it is why the `lvx.guarded` body can be restricted to result-less
       ops: what has a result and is worth having is hoisted, not guarded.
    2. **Convert only what is short enough.** `max-guarded` bounds the ops
       left to guard across both arms, the analogue of GCC's
       `MAX_CONDITIONAL_EXECUTE`: past that, the branch is cheaper than
       predicating every syllable of a long arm.

    Declines, each leaving the branch alone: a value crossing an edge or a
    join taking arguments (that is a phi, so a select, which is one
    instruction and better), an already-guarded op, a call (**a BCU
    instruction cannot be guarded** -- the prefix is itself a BCU syllable),
    or an op that is neither free to speculate nor result-less.

    **Run `-cse` after it.** Speculating hoists each arm's ops into the
    common block, and two arms very often compute the same address, so the
    hoist creates duplicates that no earlier `-cse` can see.

    It only ever sees arms that genuinely differ: `-lvx-combine`'s region
    simplification merges two blocks holding the same sequence of ops first,
    promoting every operand they differ in to a block argument. That is the
    right division of labour -- one block plus phis is the select shape, and
    a select is one instruction -- and it means the `max-guarded` budget is
    never spent on a symmetric diamond.
  }];
  let options = [
    Option<"maxGuarded", "max-guarded", "unsigned", /*default=*/"4",
           "Most instructions left to guard, across both arms, before the "
           "branch is kept instead">,
  ];
  let dependentDialects = ["::mlir::lvx::LVXDialect",
                           "lvx_cf::LVXCFDialect"];
}

def LVXLowerVectorTransfersPass
    : Pass<"lvx-lower-vector-transfers", "::mlir::func::FuncOp"> {
  let summary = "Hoist loop-carried vector transfers into iter_args, then lower the rest to load/store/broadcast";
  let description = [{
    The bridge between an upstream vectorizer and `-convert-to-lvx`. The
    affine super-vectorizer (`-affine-super-vectorize`) leaves a matmul's
    accumulator as a `vector.transfer_read`/`transfer_write` pair on the
    output memref inside the reduction loop, and reads the broadcast
    operand through a permutation map; `-convert-to-lvx` takes only
    `vector.load`/`store`/`broadcast`/`fma`. This pass runs, in order:

    1. `linalg::hoistRedundantVectorTransfers`: a transfer_read/write pair
       on a loop-invariant address, with no other access to that memref in
       the loop, becomes a loop-carried `scf.for` iter_arg -- the
       register-promoted accumulator the hand-written `mymma_vec*.mlir`
       spell directly. As upstream says of it, this assumes the memrefs
       accessed in the loop do not alias one another, which is what
       `linalg` ins/outs already promise.
    2. The upstream transfer lowering patterns: permutation maps with
       broadcast dimensions become a rank-reduced read plus
       `vector.broadcast`, a 0-d read becomes a `memref.load`, and an
       in-bounds identity transfer becomes `vector.load`/`vector.store`.

    Run `-canonicalize` after it: the padding constants (`ub.poison`) are
    dead, and a loop the vector width made single-trip folds away.
  }];
  let dependentDialects = ["::mlir::memref::MemRefDialect",
                           "::mlir::scf::SCFDialect",
                           "::mlir::vector::VectorDialect"];
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

def LVXSchedulePass : Pass<"lvx-schedule", "::mlir::lvx_func::FuncOp"> {
  let summary = "Bundle each block's ops by list scheduling, after allocation";
  let description = [{
    lvx-mlir/docs/Bundling.md. Runs after `-lvx-allocate-registers` and
    `-lvx-scf-to-cf`, on blocks of ops over physical registers: builds each
    block's dependence DAG (register RAW/WAR/WAW over units with latencies
    from the generated LVXLatency.inc, memory ordering, barriers), then
    places ops one bundle at a time by longest-path priority, a bundle being
    legal when no resource of the generated LVXScheduling.inc reservations
    is oversubscribed -- the same counted check `lvx-mbr-as` applies. An op
    with an immediate and no `format` gets one chosen from the immediate's
    value (LVXImmediates.inc), since the ISSUE count depends on it.

    The result is a `cycle` attribute on every op -- its issue cycle relative
    to the block's start -- and the block reordered by it; `-lvx-emit-asm`
    closes a bundle where the cycle changes, printing `;;  # (end cycle N)`.
    Without the attribute the emitter prints one bundle per op, as before
    this pass.
  }];
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
