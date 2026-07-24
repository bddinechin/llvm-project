// RUN: mlir-opt %s --pass-pipeline='builtin.module(any(lvx-allocate-registers),any(lvx-scf-to-cf),lvx-emit-asm)' -o /dev/null | FileCheck %s

// This is also, deliberately, an integration test against the real
// sibling-project toolchain (docs/lvx/AssemblyEmission.md, "Testing"):
// every function emitted here was hand-assembled with the real
// `lvx-mbr-as` and round-tripped through `lvx-mbr-objdump` before these
// CHECK lines were written, and the RUN line below re-assembles the same
// output on every test run. If `/home/guembu/bd3/lvx-csw` ever moves,
// update the path here rather than deleting the check.
//
// RUN: mlir-opt %s --pass-pipeline='builtin.module(any(lvx-allocate-registers),any(lvx-scf-to-cf),lvx-emit-asm)' -o /dev/null 2>/dev/null | /home/guembu/bd3/lvx-csw/lvx-toolchain/bin/lvx-mbr-as - -o %t.o

// Straight-line code: `lvx.mv`/`lvx.li` lower to real `copyd`/`make`
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
// the induction variable's explicit copy-in becomes a real (here,
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
// CHECK-NEXT: make $r0 = 0
// CHECK-NEXT: ;;
// CHECK-NEXT: make $r2 = 10
// CHECK-NEXT: ;;
// CHECK-NEXT: make $r3 = 1
// CHECK-NEXT: ;;
// CHECK-NEXT: make $r4 = 0
// CHECK-NEXT: ;;
// CHECK-NEXT: sbfd $r29 = $r2, $r0
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
