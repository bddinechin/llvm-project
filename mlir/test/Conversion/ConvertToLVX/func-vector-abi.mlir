// RUN: mlir-opt %s -convert-to-lvx | FileCheck %s

// A vector argument occupies consecutive argument registers, with no alignment
// padding -- the ABI lvx-gcc implements:
//
//   v4sf f(v4sf a, v4sf b)       $r0r1 and $r2r3
//   v4sf f(double a, v4sf b)     a in $r0, b in $r1,$r2 -- MISALIGNED, and gcc
//                                emits `copyd $r0=$r1; copyd $r1=$r2`
//   v8sf g(double a, v8sf b)     b in $r1..$r4, four copies to an aligned quad
//
// A misaligned tuple has no type -- `PairRegister` has only even bases and
// `typeFor` asserts on anything else -- so each ABI slot is pinned as a single
// register and the parts are concatenated in the entry block. Those copies are
// exactly gcc's, and where the argument arrives aligned the allocator may
// coalesce them away.
//
// Rounding a slot up to the tuple's width instead would skip a register and
// read the argument from the wrong place, with no diagnostic.

// Two pair arguments, both aligned: r0r1 and r2r3, the memref after them.
// CHECK-LABEL: lvx_func.func @two_pairs
// CHECK-SAME: !lvx.reg<r0>, %{{.*}}: !lvx.reg<r1>, %{{.*}}: !lvx.reg<r2>
// CHECK-SAME: !lvx.reg<r3>, %{{.*}}: !lvx.reg<r4>
func.func @two_pairs(%a: vector<4xf32>, %b: vector<4xf32>, %o: memref<8xf32>) {
  %i = arith.constant 0 : index
  %z = arith.addf %a, %b : vector<4xf32>
  vector.store %z, %o[%i] : memref<8xf32>, vector<4xf32>
  return
}

// -----

// A scalar first, so the pair lands misaligned at r1,r2 -- not r2,r3.
// CHECK-LABEL: lvx_func.func @misaligned_pair
// CHECK-SAME: !lvx.reg<r0>, %{{.*}}: !lvx.reg<r1>, %{{.*}}: !lvx.reg<r2>
// CHECK-SAME: !lvx.reg<r3>
// CHECK: lvx.concat
func.func @misaligned_pair(%s: f64, %b: vector<4xf32>, %o: memref<8xf32>) {
  %i = arith.constant 0 : index
  %z = arith.addf %b, %b : vector<4xf32>
  vector.store %z, %o[%i] : memref<8xf32>, vector<4xf32>
  return
}

// -----

// The same for a quad: r1..r4, four slots, concatenated into an aligned quad.
// CHECK-LABEL: lvx_func.func @misaligned_quad
// CHECK-SAME: !lvx.reg<r0>, %{{.*}}: !lvx.reg<r1>, %{{.*}}: !lvx.reg<r2>
// CHECK-SAME: !lvx.reg<r3>, %{{.*}}: !lvx.reg<r4>, %{{.*}}: !lvx.reg<r5>
// CHECK: lvx.concat
func.func @misaligned_quad(%s: f64, %b: vector<8xf32>, %o: memref<16xf32>) {
  %i = arith.constant 0 : index
  %z = arith.addf %b, %b : vector<8xf32>
  vector.store %z, %o[%i] : memref<16xf32>, vector<8xf32>
  return
}
