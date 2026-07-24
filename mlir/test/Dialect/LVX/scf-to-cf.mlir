// RUN: mlir-opt %s --pass-pipeline='builtin.module(any(lvx-allocate-registers),any(lvx-scf-to-cf))' | FileCheck %s

// Must run after -lvx-allocate-registers (docs/lvx/AssemblyEmission.md,
// "lvx-scf-to-cf: lowering after allocation").

// A constant-step-1, non-nested loop is eligible for the hardware-loop
// path (docs/lvx/HardwareLoops.md): `lvx_cf.loopdo` replaces the
// compare+cond_br header entirely, and the induction variable's entry
// value is still copied in via an explicit `lvx.mv` (%6) for the same
// reason the branch-based path needs it -- the lower bound and the body's
// own induction-variable argument are independently allocated by Steps
// 1-3, with no guarantee they share a register.
// CHECK-LABEL: lvx_func.func @loop
// CHECK: %5 = lvx.sbfd %2, %1 : (<r2>, <r0>) -> <r29>
// CHECK-NEXT: %6 = lvx.mv %1 : (!lvx.reg<r0>) -> !lvx.reg<r0>
// CHECK-NEXT: lvx_cf.loopdo %5 : <r29>, ^bb1(%6, %4 : !lvx.reg<r0>, !lvx.reg<r4>), ^bb2(%4 : !lvx.reg<r4>)
// CHECK-NEXT: ^bb1(%7: !lvx.reg<r0>, %8: !lvx.reg<r4>):
// CHECK-NEXT: %9 = lvx.addd %8, %0 : (<r4>, <r1>) -> <r4>
// CHECK-NEXT: %10 = lvx.addd %7, %3 : (<r0>, <r3>) -> <r0>
// CHECK-NEXT: lvx_cf.br ^bb2(%9 : !lvx.reg<r4>)
// CHECK-NEXT: ^bb2(%11: !lvx.reg<r4>):
// CHECK-NEXT: %12 = lvx.mv %11 : (!lvx.reg<r4>) -> !lvx.reg<r0>
// CHECK-NEXT: lvx_func.return %12 : !lvx.reg<r0>
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

// Non-constant-step-1 loops (here, step 2) are not eligible for the
// hardware-loop path and keep using the branch-based lowering: an
// explicit compare (`lvx.compd lt`, pinned to r29 like the hardware
// loop's own trip-count value) and cond_br header, with the same
// induction-variable copy-in (%5) for the same reason.
// CHECK-LABEL: lvx_func.func @loop_step2
// CHECK: %5 = lvx.mv %1 : (!lvx.reg<r0>) -> !lvx.reg<r0>
// CHECK-NEXT: lvx_cf.br ^bb1(%5, %4 : !lvx.reg<r0>, !lvx.reg<r4>)
// CHECK-NEXT: ^bb1(%6: !lvx.reg<r0>, %7: !lvx.reg<r4>):
// CHECK-NEXT: %8 = lvx.compd lt %6, %2 : (<r0>, <r2>) -> <r29>
// CHECK-NEXT: lvx_cf.cond_br wnez %8 : <r29>, ^bb2(%6, %7 : !lvx.reg<r0>, !lvx.reg<r4>), ^bb3(%7 : !lvx.reg<r4>)
// CHECK-NEXT: ^bb2(%9: !lvx.reg<r0>, %10: !lvx.reg<r4>):
// CHECK-NEXT: %11 = lvx.addd %10, %0 : (<r4>, <r1>) -> <r4>
// CHECK-NEXT: %12 = lvx.addd %6, %3 : (<r0>, <r3>) -> <r0>
// CHECK-NEXT: lvx_cf.br ^bb1(%12, %11 : !lvx.reg<r0>, !lvx.reg<r4>)
// CHECK-NEXT: ^bb3(%13: !lvx.reg<r4>):
// CHECK-NEXT: %14 = lvx.mv %13 : (!lvx.reg<r4>) -> !lvx.reg<r0>
// CHECK-NEXT: lvx_func.return %14 : !lvx.reg<r0>
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

// A loop with a nested lvx_scf.for is meant to be excluded from the
// hardware-loop path even with constant step 1 -- LC/LS/LE are a single
// register set, not a stack (docs/lvx/HardwareLoops.md, "No nesting").
// `isHardwareLoopEligible`'s nested-for check implements this, but there
// is deliberately no end-to-end test of it here: nested `lvx_scf.for` was
// found, while building this, to already be broken further upstream for
// unrelated reasons -- a value that is simultaneously an inner loop's
// result and an outer loop's directly-yielded operand can't be part of
// two independent Step 2/3 coalescing groups at once (one wants it in
// register X, the other in register Y), which either fails
// -lvx-allocate-registers' own verifier or crashes this pass outright
// depending on the exact shape. That gap predates and is unrelated to
// hardware loops; fixing it is future work, tracked here rather than
// silently worked around.
