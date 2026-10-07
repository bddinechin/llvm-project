// RUN: mlir-opt %s -split-input-file \
// RUN:   --pass-pipeline='builtin.module(func.func(lvx-lower-vector-transfers),convert-to-lvx,any(lvx-combine),cse)' \
// RUN:   | FileCheck %s

// Data-movement rows of docs/VectorCoverage.md (Phase 3) that lower today.
// See README.md for the row format.

// ROW: vector.interleave | f32x4
// CHECK-LABEL: @interleave_f32x4
// CHECK: lvx.zipwdq
// CHECK: lvx.zipwdq
// CHECK: lvx.concat
func.func @interleave_f32x4(%a: memref<8xf32>, %b: memref<8xf32>, %c: memref<8xf32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xf32>, vector<4xf32>
  %y = vector.load %b[%i] : memref<8xf32>, vector<4xf32>
  // ROW-OP
  %z = vector.interleave %x, %y : vector<4xf32> -> vector<8xf32>
  vector.store %z, %c[%i] : memref<8xf32>, vector<8xf32>
  return
}

// -----

// ROW: vector.interleave | i8x16
// CHECK-LABEL: @interleave_i8x16
// CHECK: lvx.zipbdq
// CHECK: lvx.zipbdq
func.func @interleave_i8x16(%a: memref<32xi8>, %b: memref<32xi8>, %c: memref<32xi8>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<32xi8>, vector<16xi8>
  %y = vector.load %b[%i] : memref<32xi8>, vector<16xi8>
  // ROW-OP
  %z = vector.interleave %x, %y : vector<16xi8> -> vector<32xi8>
  vector.store %z, %c[%i] : memref<32xi8>, vector<32xi8>
  return
}

// -----

// ROW: vector.interleave | i16x8
// CHECK-LABEL: @interleave_i16x8
// CHECK: lvx.ziphdq
func.func @interleave_i16x8(%a: memref<16xi16>, %b: memref<16xi16>, %c: memref<16xi16>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<16xi16>, vector<8xi16>
  %y = vector.load %b[%i] : memref<16xi16>, vector<8xi16>
  // ROW-OP
  %z = vector.interleave %x, %y : vector<8xi16> -> vector<16xi16>
  vector.store %z, %c[%i] : memref<16xi16>, vector<16xi16>
  return
}

// -----

// Zipping double words is catenating them: there is no ZIPDDQ.
// ROW: vector.interleave | i64x2
// CHECK-LABEL: @interleave_i64x2
// CHECK: lvx.catdq
// CHECK: lvx.catdq
func.func @interleave_i64x2(%a: memref<4xi64>, %b: memref<4xi64>, %c: memref<4xi64>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<4xi64>, vector<2xi64>
  %y = vector.load %b[%i] : memref<4xi64>, vector<2xi64>
  // ROW-OP
  %z = vector.interleave %x, %y : vector<2xi64> -> vector<4xi64>
  vector.store %z, %c[%i] : memref<4xi64>, vector<4xi64>
  return
}

// -----

// ROW: vector.deinterleave | f32x8
// CHECK-LABEL: @deinterleave_f32x8
// CHECK: lvx.evenwq
// CHECK: lvx.oddwq
func.func @deinterleave_f32x8(%a: memref<8xf32>, %d: memref<8xf32>, %e: memref<8xf32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xf32>, vector<8xf32>
  // ROW-OP
  %ev, %od = vector.deinterleave %x : vector<8xf32> -> vector<4xf32>
  vector.store %ev, %d[%i] : memref<8xf32>, vector<4xf32>
  vector.store %od, %e[%i] : memref<8xf32>, vector<4xf32>
  return
}

// -----

// ROW: vector.deinterleave | i8x32
// CHECK-LABEL: @deinterleave_i8x32
// CHECK: lvx.evenbq
// CHECK: lvx.oddbq
func.func @deinterleave_i8x32(%a: memref<32xi8>, %d: memref<32xi8>, %e: memref<32xi8>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<32xi8>, vector<32xi8>
  // ROW-OP
  %ev, %od = vector.deinterleave %x : vector<32xi8> -> vector<16xi8>
  vector.store %ev, %d[%i] : memref<32xi8>, vector<16xi8>
  vector.store %od, %e[%i] : memref<32xi8>, vector<16xi8>
  return
}

// -----

// ROW: vector.deinterleave | i64x4
// CHECK-LABEL: @deinterleave_i64x4
// CHECK: lvx.evendq
// CHECK: lvx.odddq
func.func @deinterleave_i64x4(%a: memref<4xi64>, %d: memref<4xi64>, %e: memref<4xi64>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<4xi64>, vector<4xi64>
  // ROW-OP
  %ev, %od = vector.deinterleave %x : vector<4xi64> -> vector<2xi64>
  vector.store %ev, %d[%i] : memref<4xi64>, vector<2xi64>
  vector.store %od, %e[%i] : memref<4xi64>, vector<2xi64>
  return
}

// -----

// A 64-bit lane of a pair is a register: the extract is a lane view and
// emits nothing.
// ROW: vector.extract | i64x2
// CHECK-LABEL: @extract_i64x2
// CHECK: %[[L:.*]] = lvx.lane %{{.*}}[1] : (!lvx.pair) -> !lvx.reg
// CHECK: lvx.mv %[[L]] : (!lvx.reg) -> !lvx.reg<r0>
func.func @extract_i64x2(%a: memref<4xi64>) -> i64 {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<4xi64>, vector<2xi64>
  // ROW-OP
  %s = vector.extract %x[1] : i64 from vector<2xi64>
  return %s : i64
}

// -----

// A narrower lane is a bit field of the register that holds it.
// ROW: vector.extract | f32x4
// CHECK-LABEL: @extract_f32x4
// CHECK: lvx.lane %{{.*}}[1]
// CHECK: lvx.extfzd %{{.*}}, 32 : i64, 0 : i64
func.func @extract_f32x4(%a: memref<8xf32>) -> f32 {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xf32>, vector<4xf32>
  // ROW-OP
  %s = vector.extract %x[2] : f32 from vector<4xf32>
  return %s : f32
}

// -----

// ROW: vector.extract | i8x16
// CHECK-LABEL: @extract_i8x16
// CHECK: lvx.extfzd %{{.*}}, 8 : i64, 40 : i64
func.func @extract_i8x16(%a: memref<32xi8>) -> i8 {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<32xi8>, vector<16xi8>
  // ROW-OP
  %s = vector.extract %x[13] : i8 from vector<16xi8>
  return %s : i8
}

// -----

// Inserting a whole register: the untouched one is copied, and `lvx.concat`
// puts the two side by side (no instruction).
// ROW: vector.insert | i64x2
// CHECK-LABEL: @insert_i64x2
// CHECK: lvx.lane %{{.*}}[1]
// CHECK: lvx.mv
// CHECK: lvx.concat
func.func @insert_i64x2(%a: memref<4xi64>, %c: memref<4xi64>, %s: i64) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<4xi64>, vector<2xi64>
  // ROW-OP
  %y = vector.insert %s, %x[0] : i64 into vector<2xi64>
  vector.store %y, %c[%i] : memref<4xi64>, vector<2xi64>
  return
}

// -----

// Inserting a bit field: a copy of the unit it goes into (`insfd` writes
// through that operand), the `insfd`, and a copy of the other unit.
// ROW: vector.insert | f32x4
// CHECK-LABEL: @insert_f32x4
// CHECK: lvx.insfd
// CHECK: lvx.concat
func.func @insert_f32x4(%a: memref<8xf32>, %c: memref<8xf32>, %s: f32) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xf32>, vector<4xf32>
  // ROW-OP
  %y = vector.insert %s, %x[2] : f32 into vector<4xf32>
  vector.store %y, %c[%i] : memref<8xf32>, vector<4xf32>
  return
}

// -----

// A quad keeps its untouched pair in one `copyq`, not two `copyd`.
// ROW: vector.insert | f32x8
// CHECK-LABEL: @insert_f32x8
// CHECK: lvx.mv %{{.*}} : (!lvx.pair) -> !lvx.pair
// CHECK: lvx.insfd
// CHECK: lvx.concat
func.func @insert_f32x8(%a: memref<8xf32>, %c: memref<8xf32>, %s: f32) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xf32>, vector<8xf32>
  // ROW-OP
  %y = vector.insert %s, %x[5] : f32 into vector<8xf32>
  vector.store %y, %c[%i] : memref<8xf32>, vector<8xf32>
  return
}

// -----

// The even lanes of two vectors, spelled as a mask: one `evenwq`.
// ROW: vector.shuffle(even) | f32x4
// CHECK-LABEL: @shuffle_even_f32x4
// CHECK: lvx.evenwq
func.func @shuffle_even_f32x4(%a: memref<8xf32>, %b: memref<8xf32>, %c: memref<8xf32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xf32>, vector<4xf32>
  %y = vector.load %b[%i] : memref<8xf32>, vector<4xf32>
  // ROW-OP
  %z = vector.shuffle %x, %y [0, 2, 4, 6] : vector<4xf32>, vector<4xf32>
  vector.store %z, %c[%i] : memref<8xf32>, vector<4xf32>
  return
}

// -----

// ROW: vector.shuffle(odd) | f32x4
// CHECK-LABEL: @shuffle_odd_f32x4
// CHECK: lvx.oddwq
func.func @shuffle_odd_f32x4(%a: memref<8xf32>, %b: memref<8xf32>, %c: memref<8xf32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xf32>, vector<4xf32>
  %y = vector.load %b[%i] : memref<8xf32>, vector<4xf32>
  // ROW-OP
  %z = vector.shuffle %x, %y [1, 3, 5, 7] : vector<4xf32>, vector<4xf32>
  vector.store %z, %c[%i] : memref<8xf32>, vector<4xf32>
  return
}

// -----

// The perfect shuffle as a mask: the same two `zipwdq` as vector.interleave.
// ROW: vector.shuffle(zip) | f32x4
// CHECK-LABEL: @shuffle_zip_f32x4
// CHECK: lvx.zipwdq
// CHECK: lvx.zipwdq
func.func @shuffle_zip_f32x4(%a: memref<8xf32>, %b: memref<8xf32>, %c: memref<8xf32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xf32>, vector<4xf32>
  %y = vector.load %b[%i] : memref<8xf32>, vector<4xf32>
  // ROW-OP
  %z = vector.shuffle %x, %y [0, 4, 1, 5, 2, 6, 3, 7] : vector<4xf32>, vector<4xf32>
  vector.store %z, %c[%i] : memref<8xf32>, vector<8xf32>
  return
}

// -----

// A register-aligned mask: two copies and a placement.
// ROW: vector.shuffle(halves) | f32x4
// CHECK-LABEL: @shuffle_swap_f32x4
// CHECK: lvx.mv
// CHECK: lvx.mv
// CHECK: lvx.concat
func.func @shuffle_swap_f32x4(%a: memref<8xf32>, %b: memref<8xf32>, %c: memref<8xf32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xf32>, vector<4xf32>
  %y = vector.load %b[%i] : memref<8xf32>, vector<4xf32>
  // ROW-OP
  %z = vector.shuffle %x, %y [2, 3, 0, 1] : vector<4xf32>, vector<4xf32>
  vector.store %z, %c[%i] : memref<8xf32>, vector<4xf32>
  return
}

// -----

// One aligned piece of one source: a lane view, no instruction at all.
// ROW: vector.shuffle(lane) | f32x8
// CHECK-LABEL: @shuffle_low_f32x8
// CHECK: %[[L:.*]] = lvx.lane %{{.*}}[0] : (!lvx.quad) -> !lvx.pair
// CHECK: lvx.sq %[[L]]
func.func @shuffle_low_f32x8(%a: memref<8xf32>, %b: memref<8xf32>, %c: memref<8xf32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xf32>, vector<8xf32>
  %y = vector.load %b[%i] : memref<8xf32>, vector<8xf32>
  // ROW-OP
  %z = vector.shuffle %x, %y [0, 1, 2, 3] : vector<8xf32>, vector<8xf32>
  vector.store %z, %c[%i] : memref<8xf32>, vector<4xf32>
  return
}

// -----

// The tuple does not change, so these are nothing at all.
// ROW: vector.shape_cast | f32x4
// CHECK-LABEL: @shape_cast_f32x4
// CHECK: %[[X:.*]] = lvx.lq
// CHECK: lvx.sq %[[X]]
func.func @shape_cast_f32x4(%a: memref<8xf32>, %c: memref<4xi64>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xf32>, vector<4xf32>
  %b = vector.bitcast %x : vector<4xf32> to vector<2xi64>
  // ROW-OP
  %z = vector.shape_cast %b : vector<2xi64> to vector<2xi64>
  vector.store %z, %c[%i] : memref<4xi64>, vector<2xi64>
  return
}

// -----

// ROW: vector.bitcast | f32x4
// CHECK-LABEL: @bitcast_f32x4
// CHECK: %[[X:.*]] = lvx.lq
// CHECK: lvx.sq %[[X]]
func.func @bitcast_f32x4(%a: memref<8xf32>, %c: memref<4xi32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xf32>, vector<4xf32>
  // ROW-OP
  %z = vector.bitcast %x : vector<4xf32> to vector<4xi32>
  vector.store %z, %c[%i] : memref<4xi32>, vector<4xi32>
  return
}

// -----

// A vector constant that is not a splat is its raw bytes: one `li` per 64-bit
// register word, joined by a free `lvx.concat`. `dense<7>` lowered long before
// this and `dense<[...]>` did not, so any shuffle index vector, lookup table or
// non-uniform mask fell in the hole.
// ROW: arith.constant(dense) | i32x4
// CHECK-LABEL: @dense_constant_i32x4
// CHECK: lvx.li
// CHECK: lvx.li
func.func @dense_constant_i32x4(%c: memref<8xi32>) {
  %i = arith.constant 0 : index
  // ROW-OP
  %k = arith.constant dense<[16909060, 286397204, 555885348, 825373492]> : vector<4xi32>
  vector.store %k, %c[%i] : memref<8xi32>, vector<4xi32>
  return
}

// -----

// `vector.step` lowers -- the pattern in `-lvx-lower-vector-transfers` says
// it is the constant `[0, 1, ... N-1]`, which nothing upstream folds it to
// (its only canonicalization is `StepCompareFolder`). The element type is
// `index`, so four lanes are a quad: four `li`.
//
// **Deliberately not a `// ROW:`**, because no cost is attributable to the op.
// Written with the `arith.index_cast` that any real use needs, the cast folds
// the constant and the folded result carries the *cast's* location, so every
// `li` is attributed to that line and the step measures as free -- which it
// is not. Written without the cast, `vector.store` of a `vector<4xindex>` has
// no lowering of its own and the row comes out class D -- which is also not
// true of the step. Its cost is the `arith.constant(dense)` row above; this
// chunk exists to pin that it lowers at all.
// CHECK-LABEL: @step_lowers
// CHECK: lvx.li
// CHECK: lvx.li
func.func @step_lowers(%c: memref<8xi64>) {
  %i = arith.constant 0 : index
  %s = vector.step : vector<4xindex>
  %t = arith.index_cast %s : vector<4xindex> to vector<4xi64>
  vector.store %t, %c[%i] : memref<8xi64>, vector<4xi64>
  return
}


// -----

// An `extract_strided_slice` on register boundaries is a run of whole units,
// so it is a lane view and costs nothing. The *high* pair is taken, which is
// the half that moves if the unit offset is dropped.
// ROW: vector.extract_strided_slice | i32x8
// CHECK-LABEL: @extract_strided_slice_i32x8
// CHECK: lvx.lane %{{.*}}[2]
func.func @extract_strided_slice_i32x8(%a: memref<8xi32>, %c: memref<8xi32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xi32>, vector<8xi32>
  // ROW-OP
  %s = vector.extract_strided_slice %x {offsets = [4], sizes = [4], strides = [1]}
       : vector<8xi32> to vector<4xi32>
  vector.store %s, %c[%i] : memref<8xi32>, vector<4xi32>
  return
}

// -----

// The insert side: the destination's units with the source's substituted. The
// source goes through a copy because `lvx.concat` *places* its parts, so a
// part already placed elsewhere would have to sit at two offsets at once.
// ROW: vector.insert_strided_slice | i32x4
// CHECK-LABEL: @insert_strided_slice_i32x4
// CHECK: lvx.concat
func.func @insert_strided_slice_i32x4(%a: memref<8xi32>, %c: memref<8xi32>) {
  %i = arith.constant 0 : index
  %q = vector.load %a[%i] : memref<8xi32>, vector<8xi32>
  %p = vector.load %a[%i] : memref<8xi32>, vector<4xi32>
  // ROW-OP
  %s = vector.insert_strided_slice %p, %q {offsets = [4], strides = [1]}
       : vector<4xi32> into vector<8xi32>
  vector.store %s, %c[%i] : memref<8xi32>, vector<8xi32>
  return
}

// -----

// The quad width of the splatting load, the deinterleave and the slice.

// ROW: vector.broadcast(load) | i8x32
// CHECK-LABEL: @broadcast_load_i8x32
// CHECK: lvx.lbso
func.func @broadcast_load_i8x32(%a: memref<64xi8>, %c: memref<64xi8>) {
  %i = arith.constant 0 : index
  %s = memref.load %a[%i] : memref<64xi8>
  // ROW-OP
  %x = vector.broadcast %s : i8 to vector<32xi8>
  vector.store %x, %c[%i] : memref<64xi8>, vector<32xi8>
  return
}
// -----

// ROW: vector.broadcast(load) | i16x16
// CHECK-LABEL: @broadcast_load_i16x16
// CHECK: lvx.lhso
func.func @broadcast_load_i16x16(%a: memref<64xi16>, %c: memref<64xi16>) {
  %i = arith.constant 0 : index
  %s = memref.load %a[%i] : memref<64xi16>
  // ROW-OP
  %x = vector.broadcast %s : i16 to vector<16xi16>
  vector.store %x, %c[%i] : memref<64xi16>, vector<16xi16>
  return
}
// -----

// ROW: vector.broadcast(load) | i32x8
// CHECK-LABEL: @broadcast_load_i32x8
// CHECK: lvx.lwso
func.func @broadcast_load_i32x8(%a: memref<64xi32>, %c: memref<64xi32>) {
  %i = arith.constant 0 : index
  %s = memref.load %a[%i] : memref<64xi32>
  // ROW-OP
  %x = vector.broadcast %s : i32 to vector<8xi32>
  vector.store %x, %c[%i] : memref<64xi32>, vector<8xi32>
  return
}
// -----

// ROW: vector.broadcast(load) | i64x4
// CHECK-LABEL: @broadcast_load_i64x4
// CHECK: lvx.ldso
func.func @broadcast_load_i64x4(%a: memref<64xi64>, %c: memref<64xi64>) {
  %i = arith.constant 0 : index
  %s = memref.load %a[%i] : memref<64xi64>
  // ROW-OP
  %x = vector.broadcast %s : i64 to vector<4xi64>
  vector.store %x, %c[%i] : memref<64xi64>, vector<4xi64>
  return
}
// -----

// ROW: vector.broadcast(load) | f64x4
// CHECK-LABEL: @broadcast_load_f64x4
// CHECK: lvx.ldso
func.func @broadcast_load_f64x4(%a: memref<64xf64>, %c: memref<64xf64>) {
  %i = arith.constant 0 : index
  %s = memref.load %a[%i] : memref<64xf64>
  // ROW-OP
  %x = vector.broadcast %s : f64 to vector<4xf64>
  vector.store %x, %c[%i] : memref<64xf64>, vector<4xf64>
  return
}
// -----

// ROW: vector.deinterleave | i16x16
// CHECK-LABEL: @deinterleave_i16x16
// CHECK: lvx.evenhq
// CHECK: lvx.oddhq
func.func @deinterleave_i16x16(%a: memref<64xi16>, %d: memref<64xi16>, %e: memref<64xi16>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xi16>, vector<16xi16>
  // ROW-OP
  %ev, %od = vector.deinterleave %x : vector<16xi16> -> vector<8xi16>
  vector.store %ev, %d[%i] : memref<64xi16>, vector<8xi16>
  vector.store %od, %e[%i] : memref<64xi16>, vector<8xi16>
  return
}
// -----

// ROW: vector.deinterleave | i32x8
// CHECK-LABEL: @deinterleave_i32x8
// CHECK: lvx.evenwq
// CHECK: lvx.oddwq
func.func @deinterleave_i32x8(%a: memref<64xi32>, %d: memref<64xi32>, %e: memref<64xi32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xi32>, vector<8xi32>
  // ROW-OP
  %ev, %od = vector.deinterleave %x : vector<8xi32> -> vector<4xi32>
  vector.store %ev, %d[%i] : memref<64xi32>, vector<4xi32>
  vector.store %od, %e[%i] : memref<64xi32>, vector<4xi32>
  return
}
// -----

// ROW: vector.deinterleave | f64x4
// CHECK-LABEL: @deinterleave_f64x4
// CHECK: lvx.evendq
// CHECK: lvx.odddq
func.func @deinterleave_f64x4(%a: memref<64xf64>, %d: memref<64xf64>, %e: memref<64xf64>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xf64>, vector<4xf64>
  // ROW-OP
  %ev, %od = vector.deinterleave %x : vector<4xf64> -> vector<2xf64>
  vector.store %ev, %d[%i] : memref<64xf64>, vector<2xf64>
  vector.store %od, %e[%i] : memref<64xf64>, vector<2xf64>
  return
}
// -----

// The float quad of the slice already measured at i32x8: still a lane view.
// ROW: vector.extract_strided_slice | f32x8
// CHECK-LABEL: @extract_strided_slice_f32x8
// CHECK: lvx.lane %{{.*}}[2]
func.func @extract_strided_slice_f32x8(%a: memref<64xf32>, %c: memref<64xf32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xf32>, vector<8xf32>
  // ROW-OP
  %s = vector.extract_strided_slice %x {offsets = [4], sizes = [4], strides = [1]}
       : vector<8xf32> to vector<4xf32>
  vector.store %s, %c[%i] : memref<64xf32>, vector<4xf32>
  return
}
