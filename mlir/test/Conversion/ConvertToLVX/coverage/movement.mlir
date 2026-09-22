// RUN: mlir-opt %s -split-input-file -convert-to-lvx | FileCheck %s

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
