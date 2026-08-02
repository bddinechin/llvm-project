// RUN: mlir-opt %s --pass-pipeline='builtin.module(any(lvx-allocate-registers),any(lvx-rewrite-divmod),any(lvx-scf-to-cf),lvx-emit-asm)' -o /dev/null | FileCheck %s

// This is also, deliberately, an integration test against the real
// sibling-project toolchain (docs/lvx/AssemblyEmission.md, "Testing"):
// every function emitted here was hand-assembled with the real
// `lvx-mbr-as` and round-tripped through `lvx-mbr-objdump` before these
// CHECK lines were written, and the RUN line below re-assembles the same
// output on every test run. If `/home/bd3/lvx-csw` ever moves,
// update the path here rather than deleting the check.
//
// RUN: mlir-opt %s --pass-pipeline='builtin.module(any(lvx-allocate-registers),any(lvx-rewrite-divmod),any(lvx-scf-to-cf),lvx-emit-asm)' -o /dev/null 2>/dev/null | /home/bd3/lvx-csw/lvx-toolchain/bin/lvx-mbr-as - -o %t.o

// Straight-line code: `lvx.mv`/`lvx.li` lower to real `copyd`/`maked`
// opcodes, and every op gets its own `;;`-terminated bundle.
// CHECK-LABEL: straight:
// CHECK-NEXT: copyd $r2 = $r0
// CHECK-NEXT: ;;
// CHECK-NEXT: copyd $r0 = $r1
// CHECK-NEXT: ;;
// CHECK-NEXT: addd $r1 = $r2, $r0
// CHECK-NEXT: ;;
// CHECK-NEXT: muld $r0 = $r1, $r2
// CHECK-NEXT: ;;
// CHECK-NEXT: copyd $r0 = $r0
// CHECK-NEXT: ;;
// CHECK-NEXT: ret
// CHECK-NEXT: ;;
lvx_func.func @straight(%a: !lvx.reg<r0>, %b: !lvx.reg<r1>) -> !lvx.reg<r0> {
  %0 = lvx.mv %a : (!lvx.reg<r0>) -> !lvx.reg
  %1 = lvx.mv %b : (!lvx.reg<r1>) -> !lvx.reg
  %2 = lvx.addd %0, %1 : (!lvx.reg, !lvx.reg) -> !lvx.reg
  %3 = lvx.muld %2, %0 : (!lvx.reg, !lvx.reg) -> !lvx.reg
  %4 = lvx.mv %3 : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %4 : !lvx.reg<r0>
}

// `sbfd` is a real "subtract FROM" opcode: `sbfd $rd = $rs1, $rs2` computes
// `$rs2 - $rs1`, not `$rs1 - $rs2` -- confirmed against
// lvx-mds/refs/FE/YAML/lvx/lvx_v1/Description.yml's own description ("The
// %2 is subtracted from the %3") and empirically on real gem5
// (docs/lvx/EndToEndValidation.md, where a naively-printed "subtract" of 5
// and 0 executed to -5). `lvx.sbfd %lhs, %rhs`'s own IR-level semantics
// still mean the natural "result = lhs - rhs" that `arith.subi` and every
// other caller assumes; only the *printed* operand order is swapped
// (`%1, %0` below, not `%0, %1`) to compensate at the assembly boundary --
// see `emitBinarySubtractFrom` in EmitAsm.cpp.
// CHECK-LABEL: subtract:
// CHECK-NEXT: copyd $r2 = $r0
// CHECK-NEXT: ;;
// CHECK-NEXT: copyd $r0 = $r1
// CHECK-NEXT: ;;
// CHECK-NEXT: sbfd $r1 = $r0, $r2
// CHECK-NEXT: ;;
// CHECK-NEXT: copyd $r0 = $r1
// CHECK-NEXT: ;;
// CHECK-NEXT: ret
// CHECK-NEXT: ;;
lvx_func.func @subtract(%a: !lvx.reg<r0>, %b: !lvx.reg<r1>) -> !lvx.reg<r0> {
  %0 = lvx.mv %a : (!lvx.reg<r0>) -> !lvx.reg
  %1 = lvx.mv %b : (!lvx.reg<r1>) -> !lvx.reg
  %2 = lvx.sbfd %0, %1 : (!lvx.reg, !lvx.reg) -> !lvx.reg
  %3 = lvx.mv %2 : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %3 : !lvx.reg<r0>
}

// A branch diamond: `lvx_cf.cond_br`'s bcucond modifier concatenates onto
// `cb` with a leading dot (`cb.wnez`, not `cb wnez`). The false edge
// (^bb1 -> ^bb2, i.e. .LBB0 -> .LBB1) and ^bb1's own unconditional branch
// to ^bb2 are both to the block immediately following in emission order,
// so both are elided entirely -- real assembly just falls through (the
// same rule that's required for correctness on a hardware loop's body
// exit, see the @loop case below, applied here purely as a cleanup).
// Block-label numbers are a single counter for the whole module, not
// reset per function (see scf-to-cf.mlir's neighbor doc comment /
// docs/lvx/AssemblyEmission.md's "Confirmed syntax" gotcha), so this
// matches them by capture rather than hardcoding which number lands here.
// CHECK-LABEL: branches:
// CHECK-NEXT: copyd $r2 = $r0
// CHECK-NEXT: ;;
// CHECK-NEXT: copyd $r0 = $r1
// CHECK-NEXT: ;;
// CHECK-NEXT: cb.wnez $r0? [[BB0:\.LBB[0-9]+]]
// CHECK-NEXT: ;;
// CHECK-NEXT: goto [[BB1:\.LBB[0-9]+]]
// CHECK-NEXT: ;;
// CHECK-NEXT: [[BB0]]:
// CHECK-NEXT: [[BB1]]:
// CHECK-NEXT: addd $r0 = $r2, $r2
// CHECK-NEXT: ;;
// CHECK-NEXT: copyd $r0 = $r0
// CHECK-NEXT: ;;
// CHECK-NEXT: ret
// CHECK-NEXT: ;;
lvx_func.func @branches(%a: !lvx.reg<r0>, %cond: !lvx.reg<r1>) -> !lvx.reg<r0> {
  %ov = lvx.mv %a : (!lvx.reg<r0>) -> !lvx.reg
  %c = lvx.mv %cond : (!lvx.reg<r1>) -> !lvx.reg
  lvx_cf.cond_br wnez %c : !lvx.reg, ^bb1, ^bb2
^bb1:
  lvx_cf.br ^bb2
^bb2:
  %r = lvx.addd %ov, %ov : (!lvx.reg, !lvx.reg) -> !lvx.reg
  %p = lvx.mv %r : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %p : !lvx.reg<r0>
}

// A counted, constant-step-1 loop is eligible for the hardware-loop path
// (docs/lvx/HardwareLoops.md): a single `loopdo` replaces the
// compare+cond_br header entirely. `%trip` (r29) = ub - lb via `sbfd`;
// real `sbfd`/`sbfw`/`fsbfd`/`fsbfw` are "subtract FROM" opcodes --
// `sbfd $rd = $rs1, $rs2` computes `$rs2 - $rs1`, the reverse of every
// other binary op's `$rd = $rs1 op $rs2` reading (confirmed against
// lvx-mds's Description.yml and empirically on real gem5) -- so the
// *printed* operand order below is `lb, ub` even though the IR-level
// `lvx.sbfd` operands are `(ub, lb)`; see emitBinarySubtractFrom's comment
// in EmitAsm.cpp. The induction variable's explicit copy-in becomes a real (here,
// same-register, harmless) `copyd $r0 = $r0`. `loopdo`'s `body` successor
// is never printed as a jump target -- real hardware falls through to it
// -- and, critically, the body's own branch back to `exit` is *also*
// never printed: exit is the block immediately following body in emission
// order, so the fallthrough-elision rule applies, and here that's a
// correctness requirement, not just a cleanup -- an explicit `goto` there
// would override LOOPDO's implicit hardware back-edge and truncate the
// loop to one iteration regardless of trip count (see
// docs/lvx/HardwareLoops.md).
// CHECK-LABEL: loop:
// CHECK-NEXT: copyd $r1 = $r0
// CHECK-NEXT: ;;
// CHECK-NEXT: maked $r0 = 0
// CHECK-NEXT: ;;
// CHECK-NEXT: maked $r2 = 10
// CHECK-NEXT: ;;
// CHECK-NEXT: maked $r3 = 1
// CHECK-NEXT: ;;
// CHECK-NEXT: maked $r4 = 0
// CHECK-NEXT: ;;
// CHECK-NEXT: sbfd $r29 = $r0, $r2
// CHECK-NEXT: ;;
// CHECK-NEXT: copyd $r0 = $r0
// CHECK-NEXT: ;;
// CHECK-NEXT: loopdo $r29, [[EXIT:\.LBB[0-9]+]]
// CHECK-NEXT: ;;
// CHECK-NEXT: {{\.LBB[0-9]+}}:
// CHECK-NEXT: addd $r4 = $r4, $r1
// CHECK-NEXT: ;;
// CHECK-NEXT: addd $r0 = $r0, $r3
// CHECK-NEXT: ;;
// CHECK-NEXT: [[EXIT]]:
// CHECK-NEXT: copyd $r0 = $r4
// CHECK-NEXT: ;;
// CHECK-NEXT: ret
// CHECK-NEXT: ;;
lvx_func.func @loop(%a: !lvx.reg<r0>) -> !lvx.reg<r0> {
  %ov = lvx.mv %a : (!lvx.reg<r0>) -> !lvx.reg
  %lb = lvx.li 0 : i64 : !lvx.reg
  %ub = lvx.li 10 : i64 : !lvx.reg
  %step = lvx.li 1 : i64 : !lvx.reg
  %init = lvx.li 0 : i64 : !lvx.reg
  %r = lvx_scf.for %lb : !lvx.reg to %ub : !lvx.reg step %step : !lvx.reg iter_args(%init) : (!lvx.reg) -> (!lvx.reg) {
  ^bb0(%iv: !lvx.reg, %acc: !lvx.reg):
    %use = lvx.addd %acc, %ov : (!lvx.reg, !lvx.reg) -> !lvx.reg
    lvx_scf.yield %use : !lvx.reg
  }
  %p = lvx.mv %r : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %p : !lvx.reg<r0>
}

// `divmodd`'s destination is the real `registerM` pairedReg operand class,
// spelled `$r<even>r<odd>` with no separator (confirmed by hand-assembling
// with the real `lvx-mbr-as` and disassembling the result, and the
// low=quotient/high=remainder assignment confirmed by actually executing a
// `divmodd` on real gem5 -- docs/lvx/AssemblyEmission.md). `-lvx-rewrite-
// divmod` pins both results to r30:r31 and copies each used one back out
// to wherever Steps 1-3 originally allocated it (`$r2`/`$r3` below).
// CHECK-LABEL: divmod:
// CHECK-NEXT: copyd $r2 = $r0
// CHECK-NEXT: ;;
// CHECK-NEXT: copyd $r0 = $r1
// CHECK-NEXT: ;;
// CHECK-NEXT: divmodd $r30r31 = $r2, $r0
// CHECK-NEXT: ;;
// CHECK-NEXT: copyd $r3 = $r31
// CHECK-NEXT: ;;
// CHECK-NEXT: copyd $r1 = $r30
// CHECK-NEXT: ;;
// CHECK-NEXT: addd $r0 = $r1, $r3
// CHECK-NEXT: ;;
// CHECK-NEXT: copyd $r0 = $r0
// CHECK-NEXT: ;;
// CHECK-NEXT: ret
// CHECK-NEXT: ;;
lvx_func.func @divmod(%a: !lvx.reg<r0>, %b: !lvx.reg<r1>) -> !lvx.reg<r0> {
  %0 = lvx.mv %a : (!lvx.reg<r0>) -> !lvx.reg
  %1 = lvx.mv %b : (!lvx.reg<r1>) -> !lvx.reg
  %q, %r = lvx.divmodd %0, %1 : (!lvx.reg, !lvx.reg) -> (!lvx.reg, !lvx.reg)
  %sum = lvx.addd %q, %r : (!lvx.reg, !lvx.reg) -> !lvx.reg
  %p = lvx.mv %sum : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %p : !lvx.reg<r0>
}

// `ffmad`/`ffmsd`: real hardware has no separate destination register --
// the `c` operand and the result share one physical register in place
// (docs/lvx/RegisterAllocation.md, "`ffma`/`ffms` accumulator
// coalescing"). Two chained ops (`%5`'s result feeds `%6`'s `c`) confirm
// the whole chain coalesces to one register (`$r3` throughout) rather than
// each op getting an independent one.
// CHECK-LABEL: ffma:
// CHECK-NEXT: copyd $r5 = $r0
// CHECK-NEXT: ;;
// CHECK-NEXT: copyd $r0 = $r1
// CHECK-NEXT: ;;
// CHECK-NEXT: copyd $r1 = $r2
// CHECK-NEXT: ;;
// CHECK-NEXT: copyd $r2 = $r3
// CHECK-NEXT: ;;
// CHECK-NEXT: copyd $r3 = $r4
// CHECK-NEXT: ;;
// CHECK-NEXT: ffmad $r3 = $r5, $r0
// CHECK-NEXT: ;;
// CHECK-NEXT: ffmsd $r3 = $r1, $r2
// CHECK-NEXT: ;;
// CHECK-NEXT: copyd $r0 = $r3
// CHECK-NEXT: ;;
// CHECK-NEXT: ret
// CHECK-NEXT: ;;
lvx_func.func @ffma(%a: !lvx.reg<r0>, %b: !lvx.reg<r1>, %c: !lvx.reg<r2>,
                    %d: !lvx.reg<r3>, %acc0: !lvx.reg<r4>) -> !lvx.reg<r0> {
  %0 = lvx.mv %a : (!lvx.reg<r0>) -> !lvx.reg
  %1 = lvx.mv %b : (!lvx.reg<r1>) -> !lvx.reg
  %2 = lvx.mv %c : (!lvx.reg<r2>) -> !lvx.reg
  %3 = lvx.mv %d : (!lvx.reg<r3>) -> !lvx.reg
  %4 = lvx.mv %acc0 : (!lvx.reg<r4>) -> !lvx.reg
  %5 = lvx.ffmad cs %0, %1, %4 : (!lvx.reg, !lvx.reg, !lvx.reg) -> !lvx.reg
  %6 = lvx.ffmsd cs %2, %3, %5 : (!lvx.reg, !lvx.reg, !lvx.reg) -> !lvx.reg
  %p = lvx.mv %6 : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %p : !lvx.reg<r0>
}

// The step-2 fallback (non-unit step, not eligible for the hardware-loop
// path -- see scf-to-cf.mlir) still assembles correctly with ordinary
// branches, exercising the fallthrough-elision rule on the entry edge too
// (entry falls straight into the header with no printed `goto`).
// CHECK-LABEL: loop_step2:
// CHECK: copyd $r0 = $r0
// CHECK-NEXT: ;;
// CHECK-NEXT: {{\.LBB[0-9]+}}:
// CHECK-NEXT: compd.lt $r29 =
lvx_func.func @loop_step2(%a: !lvx.reg<r0>) -> !lvx.reg<r0> {
  %ov = lvx.mv %a : (!lvx.reg<r0>) -> !lvx.reg
  %lb = lvx.li 0 : i64 : !lvx.reg
  %ub = lvx.li 10 : i64 : !lvx.reg
  %step = lvx.li 2 : i64 : !lvx.reg
  %init = lvx.li 0 : i64 : !lvx.reg
  %r = lvx_scf.for %lb : !lvx.reg to %ub : !lvx.reg step %step : !lvx.reg iter_args(%init) : (!lvx.reg) -> (!lvx.reg) {
  ^bb0(%iv: !lvx.reg, %acc: !lvx.reg):
    %use = lvx.addd %acc, %ov : (!lvx.reg, !lvx.reg) -> !lvx.reg
    lvx_scf.yield %use : !lvx.reg
  }
  %p = lvx.mv %r : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %p : !lvx.reg<r0>
}
