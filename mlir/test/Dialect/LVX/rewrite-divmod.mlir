// RUN: mlir-opt %s --pass-pipeline='builtin.module(any(lvx-allocate-registers),any(lvx-rewrite-divmod))' | FileCheck %s

// Must run after -lvx-allocate-registers (docs/lvx/AssemblyEmission.md, "A
// narrower fix for divmod"): Steps 1-3 allocate `divmodd`'s quotient and
// remainder as two ordinary, independently allocated values (here, r2 and
// r3), then this pass retypes both results in place to the fixed, aligned
// scratch pair r30:r31 (real hardware's `registerM` destination operand)
// and inserts an `lvx.mv` copy from each pinned result back to wherever
// Steps 1-3 originally put it.

// Both results used: two copies inserted, remainder's copy first (walk
// order visits result 1 before result 0 is retargeted -- irrelevant to
// correctness, but pinned here since FileCheck matches exact order).
// CHECK-LABEL: lvx_func.func @both
// CHECK-NEXT: %quotient, %remainder = lvx.divmodd %arg0, %arg1 : (<r0>, <r1>) -> (<r30>, <r31>)
// CHECK-NEXT: %0 = lvx.mv %remainder : (!lvx.reg<r31>) -> !lvx.reg<r3>
// CHECK-NEXT: %1 = lvx.mv %quotient : (!lvx.reg<r30>) -> !lvx.reg<r2>
// CHECK-NEXT: %2 = lvx.addd %1, %0 : (<r2>, <r3>) -> <r0>
// CHECK-NEXT: lvx_func.return %2 : !lvx.reg<r0>
lvx_func.func @both(%a: !lvx.reg<r0>, %b: !lvx.reg<r1>) -> !lvx.reg<r0> {
  %q, %r = lvx.divmodd %a, %b : (!lvx.reg<r0>, !lvx.reg<r1>) -> (!lvx.reg, !lvx.reg)
  %sum = lvx.addd %q, %r : (!lvx.reg, !lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %sum : !lvx.reg<r0>
}

// `arith.divsi`/`remsi` each lower to their own full `lvx.divmodd`
// (docs/lvx/AssemblyEmission.md's "duplicates the divmod computation"
// note), so it's common for only one of the two results to have a real
// use -- the remainder is still retyped to r31 (real hardware writes it
// regardless), but no copy-out is inserted for it since nothing reads it.
// CHECK-LABEL: lvx_func.func @quotient_only
// CHECK-NEXT: %quotient, %remainder = lvx.divmodd %arg0, %arg1 : (<r0>, <r1>) -> (<r30>, <r31>)
// CHECK-NEXT: %0 = lvx.mv %quotient : (!lvx.reg<r30>) -> !lvx.reg<r2>
// CHECK-NEXT: %1 = lvx.mv %0 : (!lvx.reg<r2>) -> !lvx.reg<r0>
// CHECK-NEXT: lvx_func.return %1 : !lvx.reg<r0>
lvx_func.func @quotient_only(%a: !lvx.reg<r0>, %b: !lvx.reg<r1>) -> !lvx.reg<r0> {
  %q, %r = lvx.divmodd %a, %b : (!lvx.reg<r0>, !lvx.reg<r1>) -> (!lvx.reg, !lvx.reg)
  %out = lvx.mv %q : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %out : !lvx.reg<r0>
}

// Symmetric case: only the remainder is used.
// CHECK-LABEL: lvx_func.func @remainder_only
// CHECK-NEXT: %quotient, %remainder = lvx.divmodd %arg0, %arg1 : (<r0>, <r1>) -> (<r30>, <r31>)
// CHECK-NEXT: %0 = lvx.mv %remainder : (!lvx.reg<r31>) -> !lvx.reg<r3>
// CHECK-NEXT: %1 = lvx.mv %0 : (!lvx.reg<r3>) -> !lvx.reg<r0>
// CHECK-NEXT: lvx_func.return %1 : !lvx.reg<r0>
lvx_func.func @remainder_only(%a: !lvx.reg<r0>, %b: !lvx.reg<r1>) -> !lvx.reg<r0> {
  %q, %r = lvx.divmodd %a, %b : (!lvx.reg<r0>, !lvx.reg<r1>) -> (!lvx.reg, !lvx.reg)
  %out = lvx.mv %r : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %out : !lvx.reg<r0>
}
