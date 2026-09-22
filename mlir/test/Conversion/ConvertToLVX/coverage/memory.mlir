// RUN: mlir-opt %s -split-input-file -convert-to-lvx | FileCheck %s

// Memory rows of docs/VectorCoverage.md (Phase 6), and the broadcasts that
// are loads (Phase 3). See README.md for the row format.

// ROW: vector.load | f32x4
// CHECK-LABEL: @load_f32x4
// CHECK: lvx.lq
func.func @load_f32x4(%a: memref<8xf32>, %c: memref<8xf32>) {
  %i = arith.constant 0 : index
  // ROW-OP
  %x = vector.load %a[%i] : memref<8xf32>, vector<4xf32>
  vector.store %x, %c[%i] : memref<8xf32>, vector<4xf32>
  return
}

// -----

// ROW: vector.load | f32x8
// CHECK-LABEL: @load_f32x8
// CHECK: lvx.lo
func.func @load_f32x8(%a: memref<8xf32>, %c: memref<8xf32>) {
  %i = arith.constant 0 : index
  // ROW-OP
  %x = vector.load %a[%i] : memref<8xf32>, vector<8xf32>
  vector.store %x, %c[%i] : memref<8xf32>, vector<8xf32>
  return
}

// -----

// ROW: vector.store | f32x4
// CHECK-LABEL: @store_f32x4
// CHECK: lvx.sq
func.func @store_f32x4(%a: memref<8xf32>, %c: memref<8xf32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xf32>, vector<4xf32>
  // ROW-OP
  vector.store %x, %c[%i] : memref<8xf32>, vector<4xf32>
  return
}

// -----

// ROW: vector.store | f32x8
// CHECK-LABEL: @store_f32x8
// CHECK: lvx.so
func.func @store_f32x8(%a: memref<8xf32>, %c: memref<8xf32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xf32>, vector<8xf32>
  // ROW-OP
  vector.store %x, %c[%i] : memref<8xf32>, vector<8xf32>
  return
}

// -----

// ROW: vector.broadcast(scalar) | f32x4
// CHECK-LABEL: @broadcast_f32x4
// CHECK: lvx.splatwq
func.func @broadcast_f32x4(%s: f32, %c: memref<8xf32>) {
  %i = arith.constant 0 : index
  // ROW-OP
  %x = vector.broadcast %s : f32 to vector<4xf32>
  vector.store %x, %c[%i] : memref<8xf32>, vector<4xf32>
  return
}

// -----

// ROW: vector.broadcast(scalar) | i8x16
// CHECK-LABEL: @broadcast_i8x16
// CHECK: lvx.splatbq
func.func @broadcast_i8x16(%s: i8, %c: memref<32xi8>) {
  %i = arith.constant 0 : index
  // ROW-OP
  %x = vector.broadcast %s : i8 to vector<16xi8>
  vector.store %x, %c[%i] : memref<32xi8>, vector<16xi8>
  return
}

// -----

// ROW: vector.broadcast(scalar) | i16x8
// CHECK-LABEL: @broadcast_i16x8
// CHECK: lvx.splathq
func.func @broadcast_i16x8(%s: i16, %c: memref<16xi16>) {
  %i = arith.constant 0 : index
  // ROW-OP
  %x = vector.broadcast %s : i16 to vector<8xi16>
  vector.store %x, %c[%i] : memref<16xi16>, vector<8xi16>
  return
}

// -----

// ROW: vector.broadcast(scalar) | i64x2
// CHECK-LABEL: @broadcast_i64x2
// CHECK: lvx.splatdq
func.func @broadcast_i64x2(%s: i64, %c: memref<4xi64>) {
  %i = arith.constant 0 : index
  // ROW-OP
  %x = vector.broadcast %s : i64 to vector<2xi64>
  vector.store %x, %c[%i] : memref<4xi64>, vector<2xi64>
  return
}

// -----

// The lvx-2 load-and-splat: a broadcast of a loaded element to a quad.
// ROW: vector.broadcast(load) | f32x8
// CHECK-LABEL: @broadcast_load_f32x8
// CHECK: lvx.lwso
func.func @broadcast_load_f32x8(%a: memref<8xf32>, %c: memref<8xf32>) {
  %i = arith.constant 0 : index
  %s = memref.load %a[%i] : memref<8xf32>
  // ROW-OP
  %x = vector.broadcast %s : f32 to vector<8xf32>
  vector.store %x, %c[%i] : memref<8xf32>, vector<8xf32>
  return
}
