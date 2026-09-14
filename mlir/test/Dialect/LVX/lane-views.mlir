// RUN: mlir-opt %s --pass-pipeline='builtin.module(any(lvx-allocate-registers))' | FileCheck %s

// Lane views (lvx-mlir/docs/RegisterAllocation.md, "Lane views"): `lvx.lane
// %p[k]` names lane k of a tuple as a value of the narrower type, and the
// allocator places it *in* the tuple's block at offset k, so that after
// allocation the view is the register that lane is and emits nothing.
//
// `divmod` is the first user. Its result is one `!lvx.pair` -- the hardware
// writes an aligned pair, quotient in the even register, remainder in the
// odd -- and the lowering reads each out with a view. This replaced the
// `-lvx-rewrite-divmod` pass, which pinned two independently allocated
// results to the scratch pair r62:r63 after the fact and copied each back
// out: the pair is now an ordinary allocation, first free pair in the
// caller pool, and no copy is needed.

// Both lanes used: the pair lands in r2r3 (r0/r1 hold the arguments), the
// views are typed r2 and r3, and the sum reads them directly.
// CHECK-LABEL: lvx_func.func @both
// CHECK-NEXT: %[[QR:.*]] = lvx.divmodd %arg0, %arg1 : (!lvx.reg<r0>, !lvx.reg<r1>) -> !lvx.pair<r2r3>
// CHECK-NEXT: %[[Q:.*]] = lvx.lane %[[QR]][0] : (!lvx.pair<r2r3>) -> !lvx.reg<r2>
// CHECK-NEXT: %[[R:.*]] = lvx.lane %[[QR]][1] : (!lvx.pair<r2r3>) -> !lvx.reg<r3>
// CHECK-NEXT: lvx.addd %[[Q]], %[[R]] : (!lvx.reg<r2>, !lvx.reg<r3>) -> !lvx.reg<r0>
lvx_func.func @both(%a: !lvx.reg<r0>, %b: !lvx.reg<r1>) -> !lvx.reg<r0> {
  %qr = lvx.divmodd %a, %b : (!lvx.reg<r0>, !lvx.reg<r1>) -> !lvx.pair
  %q = lvx.lane %qr[0] : (!lvx.pair) -> !lvx.reg
  %r = lvx.lane %qr[1] : (!lvx.pair) -> !lvx.reg
  %sum = lvx.addd %q, %r : (!lvx.reg, !lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %sum : !lvx.reg<r0>
}

// `arith.divsi`/`remsi` each lower to their own full `lvx.divmodd`, so it is
// common for only one lane to be read. The pair is still a pair.
// CHECK-LABEL: lvx_func.func @quotient_only
// CHECK-NEXT: %[[QR:.*]] = lvx.divmodd %arg0, %arg1 : (!lvx.reg<r0>, !lvx.reg<r1>) -> !lvx.pair<r2r3>
// CHECK-NEXT: %[[Q:.*]] = lvx.lane %[[QR]][0] : (!lvx.pair<r2r3>) -> !lvx.reg<r2>
// CHECK-NEXT: lvx.mv %[[Q]] : (!lvx.reg<r2>) -> !lvx.reg<r0>
lvx_func.func @quotient_only(%a: !lvx.reg<r0>, %b: !lvx.reg<r1>) -> !lvx.reg<r0> {
  %qr = lvx.divmodd %a, %b : (!lvx.reg<r0>, !lvx.reg<r1>) -> !lvx.pair
  %q = lvx.lane %qr[0] : (!lvx.pair) -> !lvx.reg
  %out = lvx.mv %q : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %out : !lvx.reg<r0>
}

// CHECK-LABEL: lvx_func.func @remainder_only
// CHECK-NEXT: %[[QR:.*]] = lvx.divmodd %arg0, %arg1 : (!lvx.reg<r0>, !lvx.reg<r1>) -> !lvx.pair<r2r3>
// CHECK-NEXT: %[[R:.*]] = lvx.lane %[[QR]][1] : (!lvx.pair<r2r3>) -> !lvx.reg<r3>
// CHECK-NEXT: lvx.mv %[[R]] : (!lvx.reg<r3>) -> !lvx.reg<r0>
lvx_func.func @remainder_only(%a: !lvx.reg<r0>, %b: !lvx.reg<r1>) -> !lvx.reg<r0> {
  %qr = lvx.divmodd %a, %b : (!lvx.reg<r0>, !lvx.reg<r1>) -> !lvx.pair
  %r = lvx.lane %qr[1] : (!lvx.pair) -> !lvx.reg
  %out = lvx.mv %r : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %out : !lvx.reg<r0>
}

// A view of a *pinned* tuple: the group is fixed at the tuple's block, and
// the view is typed from it -- here lane 1 of the argument pair r0r1 is r1.
// CHECK-LABEL: lvx_func.func @of_pinned
// CHECK-NEXT: %[[HI:.*]] = lvx.lane %arg0[1] : (!lvx.pair<r0r1>) -> !lvx.reg<r1>
// CHECK-NEXT: lvx.mv %[[HI]] : (!lvx.reg<r1>) -> !lvx.reg<r0>
lvx_func.func @of_pinned(%p: !lvx.pair<r0r1>) -> !lvx.reg<r0> {
  %hi = lvx.lane %p[1] : (!lvx.pair<r0r1>) -> !lvx.reg
  %out = lvx.mv %hi : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %out : !lvx.reg<r0>
}

// Nested views: a pair of a quad, and a single of that pair, all in one
// block. The quad takes the first free quad in the caller pool, r4r5r6r7
// (r0r1r2r3 holds the arguments' units r0 and r1).
// CHECK-LABEL: lvx_func.func @nested
// CHECK-NEXT: %[[Q:.*]] = lvx.lo %arg0, 0 : i64 : (!lvx.reg<r0>) -> !lvx.quad<r4r5r6r7>
// CHECK-NEXT: %[[HI:.*]] = lvx.lane %[[Q]][2] : (!lvx.quad<r4r5r6r7>) -> !lvx.pair<r6r7>
// CHECK-NEXT: %[[T:.*]] = lvx.lane %[[HI]][1] : (!lvx.pair<r6r7>) -> !lvx.reg<r7>
// CHECK-NEXT: lvx.mv %[[T]] : (!lvx.reg<r7>) -> !lvx.reg<r0>
lvx_func.func @nested(%base: !lvx.reg<r0>) -> !lvx.reg<r0> {
  %q = lvx.lo %base, 0 : i64 : (!lvx.reg<r0>) -> !lvx.quad
  %hi = lvx.lane %q[2] : (!lvx.quad) -> !lvx.pair
  %t = lvx.lane %hi[1] : (!lvx.pair) -> !lvx.reg
  %out = lvx.mv %t : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %out : !lvx.reg<r0>
}
