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

// -----

// A masked access is one op in the IR and two syllables in the bundle: the
// `maskm` prefix plus the access. `extb4d` widens the 4-lane mask to the 16
// byte enables the LSU consumes, f32 lanes being 4 bytes each.

// ROW: vector.maskedload | f32x4
// CHECK-LABEL: @maskedload_f32x4
// CHECK: lvx.extb4d
// CHECK: lvx.masked_load
func.func @maskedload_f32x4(%a: memref<8xf32>, %c: memref<8xf32>, %m: vector<4xi1>) {
  %i = arith.constant 0 : index
  %p = arith.constant dense<0.0> : vector<4xf32>
  // ROW-OP
  %x = vector.maskedload %a[%i], %m, %p : memref<8xf32>, vector<4xi1>, vector<4xf32> into vector<4xf32>
  vector.store %x, %c[%i] : memref<8xf32>, vector<4xf32>
  return
}

// -----

// A pass-thru that is not zero costs a blend after the load: `maskm` zeroes
// the inactive lanes and has no merge form, by design.

// ROW: vector.maskedload(passthru) | f32x4
// CHECK-LABEL: @maskedload_passthru_f32x4
// CHECK: lvx.extb4d
// CHECK: lvx.masked_load
// CHECK: lvx.blendwq
func.func @maskedload_passthru_f32x4(%a: memref<8xf32>, %b: memref<8xf32>, %c: memref<8xf32>, %m: vector<4xi1>) {
  %i = arith.constant 0 : index
  %p = vector.load %b[%i] : memref<8xf32>, vector<4xf32>
  // ROW-OP
  %x = vector.maskedload %a[%i], %m, %p : memref<8xf32>, vector<4xi1>, vector<4xf32> into vector<4xf32>
  vector.store %x, %c[%i] : memref<8xf32>, vector<4xf32>
  return
}

// -----

// ROW: vector.maskedstore | f32x4
// CHECK-LABEL: @maskedstore_f32x4
// CHECK: lvx.extb4d
// CHECK: lvx.masked_store
func.func @maskedstore_f32x4(%a: memref<8xf32>, %c: memref<8xf32>, %m: vector<4xi1>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xf32>, vector<4xf32>
  // ROW-OP
  vector.maskedstore %c[%i], %m, %x : memref<8xf32>, vector<4xi1>, vector<4xf32>
  return
}

// -----

// i64 lanes are 8 bytes, so the widening is `extb8d`; i8 lanes are already
// byte-granular and need none.

// ROW: vector.maskedstore | i64x2
// CHECK-LABEL: @maskedstore_i64x2
// CHECK: lvx.extb8d
// CHECK: lvx.masked_store
func.func @maskedstore_i64x2(%a: memref<4xi64>, %c: memref<4xi64>, %m: vector<2xi1>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<4xi64>, vector<2xi64>
  // ROW-OP
  vector.maskedstore %c[%i], %m, %x : memref<4xi64>, vector<2xi1>, vector<2xi64>
  return
}

// -----

// ROW: vector.maskedstore | i8x16
// CHECK-LABEL: @maskedstore_i8x16
// CHECK-NOT: lvx.extb
// CHECK: lvx.masked_store
func.func @maskedstore_i8x16(%a: memref<32xi8>, %c: memref<32xi8>, %m: vector<16xi1>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<32xi8>, vector<16xi8>
  // ROW-OP
  vector.maskedstore %c[%i], %m, %x : memref<32xi8>, vector<16xi1>, vector<16xi8>
  return
}
