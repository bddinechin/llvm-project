// RUN: mlir-opt %s --pass-pipeline='builtin.module(any(lvx-allocate-registers),any(lvx-scf-to-cf))' | FileCheck %s

// Must run after -lvx-allocate-registers (docs/lvx/AssemblyEmission.md,
// "lvx-scf-to-cf: lowering after allocation") -- the induction variable's
// header-block argument is copied in from the lower bound via an explicit
// `lvx.mv` (%5 below): the lower bound and the body's own induction
// variable are independently allocated by Steps 1-3 (unlike the
// deliberately-coalesced iter_arg channel, %4/%7/%10/%13's r4), so nothing
// guarantees they land on the same register, and a real `goto` has no
// mechanism to pass a value into a block argument otherwise.
// CHECK-LABEL: lvx_func.func @loop
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
