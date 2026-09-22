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
