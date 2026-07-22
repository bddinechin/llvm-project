// RUN: mlir-opt %s --pass-pipeline='builtin.module(any(lvx-print-live-intervals))' -mlir-disable-threading -o /dev/null 2>&1 | FileCheck %s

// Straight-line code: a simple sequential chain of defs/uses, plus
// ABI-pinned fixed intervals for the entry arguments and the pinned
// return value.
// CHECK-LABEL: Testing : straight
// CHECK-NEXT: %arg0 : [0, 1] fixed=r0
// CHECK-NEXT: %arg1 : [0, 2] fixed=r1
// CHECK-NEXT: %0 : [1, 4]
// CHECK-NEXT: %1 : [2, 3]
// CHECK-NEXT: %2 : [3, 4]
// CHECK-NEXT: %3 : [4, 5]
// CHECK-NEXT: %4 : [5, 6] fixed=r0
lvx_func.func @straight(%a: !lvx.reg<r0>, %b: !lvx.reg<r1>) -> !lvx.reg<r0> {
  %0 = lvx.mv %a : (!lvx.reg<r0>) -> !lvx.reg
  %1 = lvx.mv %b : (!lvx.reg<r1>) -> !lvx.reg
  %2 = lvx.addd %0, %1 : (!lvx.reg, !lvx.reg) -> !lvx.reg
  %3 = lvx.muld %2, %0 : (!lvx.reg, !lvx.reg) -> !lvx.reg
  %4 = lvx.mv %3 : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %4 : !lvx.reg<r0>
}

// A branch diamond: `%ov` is defined in the entry block, passes through
// `^bb1` untouched, and is only used in `^bb2`. Its computed interval
// spans the whole way through, covering the block it passes through with
// no direct reference in it.
// CHECK-LABEL: Testing : branches
// CHECK-NEXT: %arg0 : [0, 1] fixed=r0
// CHECK-NEXT: %arg1 : [0, 2] fixed=r1
// CHECK-NEXT: %0 : [1, 7]
// CHECK-NEXT: %1 : [2, 3]
// CHECK-NEXT: %2 : [7, 8]
// CHECK-NEXT: %3 : [8, 9] fixed=r0
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

// `lvx_scf.for`: `%ov` is captured from the enclosing scope and used
// inside the loop body -- its interval extends to cover that use with no
// special-cased "loop extension" logic, purely because the loop body is
// numbered inline right after the `lvx_scf.for` op. `%arg1` (the
// induction variable) is unused and gets a trivial single-point interval;
// `%arg2` (the loop-carried accumulator) and the yielded value each get
// their own honest, separate interval, since they are distinct SSA
// values.
// CHECK-LABEL: Testing : loop
// CHECK-NEXT: %arg0 : [0, 1] fixed=r0
// CHECK-NEXT: %0 : [1, 8]
// CHECK-NEXT: %1 : [2, 6]
// CHECK-NEXT: %2 : [3, 6]
// CHECK-NEXT: %3 : [4, 6]
// CHECK-NEXT: %4 : [5, 6]
// CHECK-NEXT: %5 : [6, 10]
// CHECK-NEXT: %arg1 : [7, 7]
// CHECK-NEXT: %arg2 : [7, 8]
// CHECK-NEXT: %7 : [8, 9]
// CHECK-NEXT: %6 : [10, 11] fixed=r0
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
