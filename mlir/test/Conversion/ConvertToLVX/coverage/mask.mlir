// RUN: mlir-opt %s -split-input-file -convert-to-lvx | FileCheck %s

// Mask rows of docs/VectorCoverage.md (Phase 2): a `vector<Nxi1>` is a
// register holding one bit per lane, `comp*q`/`fcomp*q` write it and
// `blend*` reads it. See README.md for the row format.

// ROW: arith.cmpi | i32x4
// CHECK-LABEL: @cmpi_i32x4
// CHECK: lvx.compwq lt %{{.*}}, %{{.*}} : (!lvx.pair, !lvx.pair) -> !lvx.reg
func.func @cmpi_i32x4(%a: memref<8xi32>, %b: memref<8xi32>, %c: memref<8xi32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xi32>, vector<4xi32>
  %y = vector.load %b[%i] : memref<8xi32>, vector<4xi32>
  // ROW-OP
  %m = arith.cmpi slt, %x, %y : vector<4xi32>
  %z = arith.select %m, %x, %y : vector<4xi1>, vector<4xi32>
  vector.store %z, %c[%i] : memref<8xi32>, vector<4xi32>
  return
}

// -----

// ROW: arith.cmpi | i8x16
// CHECK-LABEL: @cmpi_i8x16
// CHECK: lvx.compbx ltu
func.func @cmpi_i8x16(%a: memref<32xi8>, %b: memref<32xi8>, %c: memref<32xi8>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<32xi8>, vector<16xi8>
  %y = vector.load %b[%i] : memref<32xi8>, vector<16xi8>
  // ROW-OP
  %m = arith.cmpi ult, %x, %y : vector<16xi8>
  %z = arith.select %m, %x, %y : vector<16xi1>, vector<16xi8>
  vector.store %z, %c[%i] : memref<32xi8>, vector<16xi8>
  return
}

// -----

// ROW: arith.cmpi | i64x2
// CHECK-LABEL: @cmpi_i64x2
// CHECK: lvx.compdp ge
func.func @cmpi_i64x2(%a: memref<4xi64>, %b: memref<4xi64>, %c: memref<4xi64>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<4xi64>, vector<2xi64>
  %y = vector.load %b[%i] : memref<4xi64>, vector<2xi64>
  // ROW-OP
  %m = arith.cmpi sge, %x, %y : vector<2xi64>
  %z = arith.select %m, %x, %y : vector<2xi1>, vector<2xi64>
  vector.store %z, %c[%i] : memref<4xi64>, vector<2xi64>
  return
}

// -----

// `ogt` has no opcode of its own: the lowering compares `olt` with the
// operands swapped, which leaves the select's arms alone.
// ROW: arith.cmpf | f32x4
// CHECK-LABEL: @cmpf_f32x4
// CHECK: %[[X:.*]] = lvx.lq %{{.*}}, 0
// CHECK: %[[Y:.*]] = lvx.lq %{{.*}}, 0
// CHECK: lvx.fcompwq olt %[[Y]], %[[X]] : (!lvx.pair, !lvx.pair) -> !lvx.reg
func.func @cmpf_f32x4(%a: memref<8xf32>, %b: memref<8xf32>, %c: memref<8xf32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xf32>, vector<4xf32>
  %y = vector.load %b[%i] : memref<8xf32>, vector<4xf32>
  // ROW-OP
  %m = arith.cmpf ogt, %x, %y : vector<4xf32>
  %z = arith.select %m, %x, %y : vector<4xi1>, vector<4xf32>
  vector.store %z, %c[%i] : memref<8xf32>, vector<4xf32>
  return
}

// -----

// ROW: arith.cmpf | f64x2
// CHECK-LABEL: @cmpf_f64x2
// CHECK: lvx.fcompdp oeq
func.func @cmpf_f64x2(%a: memref<4xf64>, %b: memref<4xf64>, %c: memref<4xf64>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<4xf64>, vector<2xf64>
  %y = vector.load %b[%i] : memref<4xf64>, vector<2xf64>
  // ROW-OP
  %m = arith.cmpf oeq, %x, %y : vector<2xf64>
  %z = arith.select %m, %x, %y : vector<2xi1>, vector<2xf64>
  vector.store %z, %c[%i] : memref<4xf64>, vector<2xf64>
  return
}

// -----

// The blend writes through its destination, so the false value is the tied
// operand; `-lvx-allocate-registers` copies it when it is live past the
// select, as it does for an `ffma` accumulator.
// ROW: arith.select | i32x4
// CHECK-LABEL: @select_i32x4
// CHECK: %[[M:.*]] = lvx.compwq
// CHECK: lvx.blendwq %{{.*}}, %[[M]], %{{.*}} : (!lvx.pair, !lvx.reg, !lvx.pair) -> !lvx.pair
func.func @select_i32x4(%a: memref<8xi32>, %b: memref<8xi32>, %c: memref<8xi32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xi32>, vector<4xi32>
  %y = vector.load %b[%i] : memref<8xi32>, vector<4xi32>
  %m = arith.cmpi slt, %x, %y : vector<4xi32>
  // ROW-OP
  %z = arith.select %m, %x, %y : vector<4xi1>, vector<4xi32>
  vector.store %z, %c[%i] : memref<8xi32>, vector<4xi32>
  return
}

// -----

// ROW: arith.select | f32x4
// CHECK-LABEL: @select_f32x4
// CHECK: lvx.blendwq
func.func @select_f32x4(%a: memref<8xf32>, %b: memref<8xf32>, %c: memref<8xf32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xf32>, vector<4xf32>
  %y = vector.load %b[%i] : memref<8xf32>, vector<4xf32>
  %m = arith.cmpf olt, %x, %y : vector<4xf32>
  // ROW-OP
  %z = arith.select %m, %x, %y : vector<4xi1>, vector<4xf32>
  vector.store %z, %c[%i] : memref<8xf32>, vector<4xf32>
  return
}

// -----

// ROW: arith.select | i8x16
// CHECK-LABEL: @select_i8x16
// CHECK: lvx.blendbx
func.func @select_i8x16(%a: memref<32xi8>, %b: memref<32xi8>, %c: memref<32xi8>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<32xi8>, vector<16xi8>
  %y = vector.load %b[%i] : memref<32xi8>, vector<16xi8>
  %m = arith.cmpi ult, %x, %y : vector<16xi8>
  // ROW-OP
  %z = arith.select %m, %x, %y : vector<16xi1>, vector<16xi8>
  vector.store %z, %c[%i] : memref<32xi8>, vector<16xi8>
  return
}

// -----

// ROW: arith.select | i64x2
// CHECK-LABEL: @select_i64x2
// CHECK: lvx.blenddp
func.func @select_i64x2(%a: memref<4xi64>, %b: memref<4xi64>, %c: memref<4xi64>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<4xi64>, vector<2xi64>
  %y = vector.load %b[%i] : memref<4xi64>, vector<2xi64>
  %m = arith.cmpi sge, %x, %y : vector<2xi64>
  // ROW-OP
  %z = arith.select %m, %x, %y : vector<2xi1>, vector<2xi64>
  vector.store %z, %c[%i] : memref<4xi64>, vector<2xi64>
  return
}
