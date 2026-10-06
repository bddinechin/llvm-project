// RUN: mlir-opt %s -split-input-file \
// RUN:   --pass-pipeline='builtin.module(func.func(lvx-lower-vector-transfers),convert-to-lvx,any(lvx-combine),cse)' \
// RUN:   | FileCheck %s

// `vector.reduction`'s *accumulator*, which used to be silently dropped:
// `VectorReductionToLVX` never read the operand and nothing refused it, so a
// reduction carrying one legalized cleanly and the accumulator vanished. The
// stored result was the bare tree -- a wrong answer with no diagnostic.
//
// It is now folded in the vector dialect, by `-lvx-lower-vector-transfers`,
// into a scalar op over the tree's result. That placement is the point: the
// scalar op per combining kind, and its 64-against-32-bit choice, come from
// the existing `arith` lowering. Folding inside the conversion would mean
// picking the mnemonic there, and for `min`/`max` on lanes narrower than a
// register that is *not* the 64-bit op -- the reduced register's upper bits
// hold a copy of the answer, not a sign extension.

// i32 lanes: the even/odd tree, then `addw` -- the 32-bit op, not `addd`.
// CHECK-LABEL: @acc_add_i32x4
// CHECK: lvx.addwq
// CHECK: lvx.addwq
// CHECK: %[[T:.*]] = lvx.lane
// CHECK: lvx.addw %[[T]],
func.func @acc_add_i32x4(%a: memref<4xi32>, %c: memref<4xi32>, %acc: i32) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<4xi32>, vector<4xi32>
  %r = vector.reduction <add>, %x, %acc : vector<4xi32> into i32
  memref.store %r, %c[%i] : memref<4xi32>
  return
}

// -----

// A signed minimum at i32 lanes is the case that makes the placement matter:
// the fold must be `minw`, since the reduced register's high half holds a copy
// of the answer rather than a sign extension, so a 64-bit `mind` could pick
// the wrong operand.
// CHECK-LABEL: @acc_minsi_i32x4
// CHECK: lvx.minwq
// CHECK: lvx.minw
func.func @acc_minsi_i32x4(%a: memref<4xi32>, %c: memref<4xi32>, %acc: i32) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<4xi32>, vector<4xi32>
  %r = vector.reduction <minsi>, %x, %acc : vector<4xi32> into i32
  memref.store %r, %c[%i] : memref<4xi32>
  return
}

// -----

// i64 lanes, where the register *is* the lane and the fold is `addd`.
// CHECK-LABEL: @acc_add_i64x2
// CHECK: lvx.addd
func.func @acc_add_i64x2(%a: memref<2xi64>, %c: memref<2xi64>, %acc: i64) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<2xi64>, vector<2xi64>
  %r = vector.reduction <add>, %x, %acc : vector<2xi64> into i64
  memref.store %r, %c[%i] : memref<2xi64>
  return
}

// -----

// An integer `vector.contract` decomposes into exactly this shape -- the dot
// product's init is the accumulator -- which is why it did not lower until
// now. (The float form still declines, on the deliberate rule that a float
// reduction without `reassoc` is the sequential chain, not a tree.)
// CHECK-LABEL: @contract_i32x4
// CHECK: lvx.addwq
// CHECK: lvx.addw
#d = affine_map<(d0) -> (d0)>
#s = affine_map<(d0) -> ()>
func.func @contract_i32x4(%a: memref<4xi32>, %b: memref<4xi32>,
                          %c: memref<4xi32>, %acc: i32) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<4xi32>, vector<4xi32>
  %y = vector.load %b[%i] : memref<4xi32>, vector<4xi32>
  %r = vector.contract {indexing_maps = [#d, #d, #s],
                        iterator_types = ["reduction"],
                        kind = #vector.kind<add>} %x, %y, %acc
       : vector<4xi32>, vector<4xi32> into i32
  memref.store %r, %c[%i] : memref<4xi32>
  return
}
