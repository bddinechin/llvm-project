// RUN: mlir-opt %s --pass-pipeline='builtin.module(any(lvx-allocate-registers{max-registers=1}))' | FileCheck %s

// Straight-line code with the allocatable pool artificially shrunk to 1
// register (test-only `max-registers` option), forcing Step 3's spill path
// for every non-ABI-pinned value. The prologue subtracts the sum of all
// spill slots (16 = two 8-byte slots for `%0` and `%2`) from the stack
// pointer; the epilogue adds it back before the return. Each spilled value
// is stored once, right after its def, and reloaded independently at each
// of its uses (e.g. `%0` is reloaded separately for the `addd` and the
// `muld`, since those are two different consuming ops).
// CHECK-LABEL: lvx_func.func @straight
// CHECK-NEXT: %0 = lvx.sp : !lvx.reg<r12>
// CHECK-NEXT: %1 = lvx.li 16 : i64 : !lvx.reg<r61>
// CHECK-NEXT: %2 = lvx.sbfd %0, %1 : (!lvx.reg<r12>, !lvx.reg<r61>) -> !lvx.reg<r12>
// CHECK-NEXT: %3 = lvx.mv %arg0 : (!lvx.reg<r0>) -> !lvx.reg<r61>
// CHECK-NEXT: lvx.sd %3, %2, 0 : (!lvx.reg<r61>, !lvx.reg<r12>)
// CHECK-NEXT: %4 = lvx.mv %arg1 : (!lvx.reg<r1>) -> !lvx.reg<r0>
// CHECK-NEXT: %5 = lvx.ld %2, 0 : (!lvx.reg<r12>) -> !lvx.reg<r61>
// CHECK-NEXT: %6 = lvx.addd %5, %4 : (!lvx.reg<r61>, !lvx.reg<r0>) -> !lvx.reg<r61>
// CHECK-NEXT: lvx.sd %6, %2, 8 : (!lvx.reg<r61>, !lvx.reg<r12>)
// CHECK-NEXT: %7 = lvx.ld %2, 0 : (!lvx.reg<r12>) -> !lvx.reg<r61>
// CHECK-NEXT: %8 = lvx.ld %2, 8 : (!lvx.reg<r12>) -> !lvx.reg<r62>
// CHECK-NEXT: %9 = lvx.muld %8, %7 : (!lvx.reg<r62>, !lvx.reg<r61>) -> !lvx.reg<r0>
// CHECK-NEXT: %10 = lvx.mv %9 : (!lvx.reg<r0>) -> !lvx.reg<r0>
// CHECK-NEXT: %11 = lvx.li 16 : i64 : !lvx.reg<r61>
// CHECK-NEXT: %12 = lvx.addd %2, %11 : (!lvx.reg<r12>, !lvx.reg<r61>) -> !lvx.reg<r12>
// CHECK-NEXT: lvx_func.return %10 : !lvx.reg<r0>
lvx_func.func @straight(%a: !lvx.reg<r0>, %b: !lvx.reg<r1>) -> !lvx.reg<r0> {
  %0 = lvx.mv %a : (!lvx.reg<r0>) -> !lvx.reg
  %1 = lvx.mv %b : (!lvx.reg<r1>) -> !lvx.reg
  %2 = lvx.addd %0, %1 : (!lvx.reg, !lvx.reg) -> !lvx.reg
  %3 = lvx.muld %2, %0 : (!lvx.reg, !lvx.reg) -> !lvx.reg
  %4 = lvx.mv %3 : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %4 : !lvx.reg<r0>
}

// A branch diamond with two `lvx_func.return`s: the epilogue (stack-pointer
// restore) must be inserted before *both* of them, not just one, and each
// spilled value reloaded independently in whichever branch actually uses
// it -- the value stored at offset 8 is only reloaded in `^bb1`, the one at
// offset 16 only in `^bb2`.
// CHECK-LABEL: lvx_func.func @branches
// CHECK: lvx.sd %{{[0-9]+}}, %{{[0-9]+}}, 8 : (!lvx.reg<r61>, !lvx.reg<r12>)
// CHECK: lvx.sd %{{[0-9]+}}, %{{[0-9]+}}, 16 : (!lvx.reg<r61>, !lvx.reg<r12>)
// CHECK: ^bb1:
// CHECK-NEXT: %{{[0-9]+}} = lvx.ld %{{[0-9]+}}, 8 : (!lvx.reg<r12>) -> !lvx.reg<r61>
// CHECK-NEXT: %{{[0-9]+}} = lvx.mv %{{.*}} : (!lvx.reg<r61>) -> !lvx.reg<r0>
// CHECK: lvx_func.return
// CHECK: ^bb2:
// CHECK-NEXT: %{{[0-9]+}} = lvx.ld %{{[0-9]+}}, 16 : (!lvx.reg<r12>) -> !lvx.reg<r61>
// CHECK-NEXT: %{{[0-9]+}} = lvx.mv %{{.*}} : (!lvx.reg<r61>) -> !lvx.reg<r0>
// CHECK: lvx_func.return
lvx_func.func @branches(%a: !lvx.reg<r0>, %cond: !lvx.reg<r1>) -> !lvx.reg<r0> {
  %0 = lvx.mv %a : (!lvx.reg<r0>) -> !lvx.reg
  %1 = lvx.mv %cond : (!lvx.reg<r1>) -> !lvx.reg
  %2 = lvx.addd %0, %0 : (!lvx.reg, !lvx.reg) -> !lvx.reg
  %3 = lvx.muld %0, %2 : (!lvx.reg, !lvx.reg) -> !lvx.reg
  lvx_cf.cond_br wnez %1 : !lvx.reg, ^bb1, ^bb2
^bb1:
  %p1 = lvx.mv %2 : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %p1 : !lvx.reg<r0>
^bb2:
  %p2 = lvx.mv %3 : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %p2 : !lvx.reg<r0>
}
