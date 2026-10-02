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

// The other three sides of a call. The argument side above was made
// width-aware when the vector ABI landed; a function's *results* and both
// halves of a *call* were not, and each pinned by operand index -- one single
// register per value whatever its width. So a pair result produced
// `lvx.mv (!lvx.pair) -> !lvx.reg<r0>` and failed the move's own verifier
// ("source and result must be the same width"): no function could return a
// vector, and no call could pass or receive one. All four now share one
// helper, `abiSlotTypes`, so they cannot disagree again.

// A pair result occupies two result registers.
// CHECK-LABEL: lvx_func.func @ret_pair
// CHECK-SAME: -> (!lvx.reg<r0>, !lvx.reg<r1>)
// CHECK: lvx_func.return %{{.*}}, %{{.*}} : !lvx.reg<r0>, !lvx.reg<r1>
func.func @ret_pair(%a: memref<4xi32>) -> vector<4xi32> {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<4xi32>, vector<4xi32>
  return %x : vector<4xi32>
}

// -----

// A quad result fills all four: the convention has exactly four result
// registers, so this is the widest single result there is.
// CHECK-LABEL: lvx_func.func @ret_quad
// CHECK-SAME: -> (!lvx.reg<r0>, !lvx.reg<r1>, !lvx.reg<r2>, !lvx.reg<r3>)
func.func @ret_quad(%a: memref<8xi32>) -> vector<8xi32> {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xi32>, vector<8xi32>
  return %x : vector<8xi32>
}

// -----

// A scalar then a pair: the pair lands at $r1,$r2, misaligned, exactly as on
// the argument side. This used to be refused outright ("a tuple result at a
// misaligned slot needs the return to split it into single registers");
// splitting into singles is now what every slot does, so there is nothing
// special left about it.
// CHECK-LABEL: lvx_func.func @ret_scalar_then_pair
// CHECK-SAME: -> (!lvx.reg<r0>, !lvx.reg<r1>, !lvx.reg<r2>)
func.func @ret_scalar_then_pair(%a: memref<4xi32>) -> (i32, vector<4xi32>) {
  %i = arith.constant 0 : index
  %s = memref.load %a[%i] : memref<4xi32>
  %x = vector.load %a[%i] : memref<4xi32>, vector<4xi32>
  return %s, %x : i32, vector<4xi32>
}

// -----

// A call passing a vector: two argument slots for the pair, the scalar after
// it at $r2 -- the callee's own signature pins the same three.
// CHECK-LABEL: @call_pair_arg
// CHECK: lvx_func.call @sink(%{{.*}}, %{{.*}}, %{{.*}}) : (!lvx.reg<r0>, !lvx.reg<r1>, !lvx.reg<r2>) -> ()
func.func private @sink(%v: vector<4xi32>, %s: i32)
func.func @call_pair_arg(%a: memref<4xi32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<4xi32>, vector<4xi32>
  %s = memref.load %a[%i] : memref<4xi32>
  func.call @sink(%x, %s) : (vector<4xi32>, i32) -> ()
  return
}

// -----

// A call receiving a vector: two result slots copied out and rebuilt into one
// pair with `lvx.concat`, so the call still has one result where the source
// had one.
// CHECK-LABEL: @call_pair_result
// CHECK: %[[C:.*]]:2 = lvx_func.call @source() : () -> (!lvx.reg<r0>, !lvx.reg<r1>)
// CHECK: lvx.concat
func.func private @source() -> vector<4xi32>
func.func @call_pair_result(%b: memref<4xi32>) {
  %i = arith.constant 0 : index
  %v = func.call @source() : () -> vector<4xi32>
  vector.store %v, %b[%i] : memref<4xi32>, vector<4xi32>
  return
}
