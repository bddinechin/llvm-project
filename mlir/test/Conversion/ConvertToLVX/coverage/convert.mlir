// RUN: mlir-opt %s -split-input-file -convert-to-lvx | FileCheck %s

// Conversion rows of docs/VectorCoverage.md (Phase 5). Three shapes, chosen
// by how many bits a lane gains or loses: same width is one instruction on a
// pair, narrowing one instruction from a quad to a pair, widening two (one
// per half of the source pair) plus a free `lvx.concat`. See README.md for
// the row format. The shape column names the *operand's* shape.

// ROW: arith.sitofp | i32x4
// CHECK-LABEL: @sitofp_i32x4
// CHECK: lvx.floatwq
func.func @sitofp_i32x4(%a: memref<8xi32>, %c: memref<8xf32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xi32>, vector<4xi32>
  // ROW-OP
  %y = arith.sitofp %x : vector<4xi32> to vector<4xf32>
  vector.store %y, %c[%i] : memref<8xf32>, vector<4xf32>
  return
}

// -----

// ROW: arith.sitofp | i64x2
// CHECK-LABEL: @sitofp_i64x2
// CHECK: lvx.floatdp
func.func @sitofp_i64x2(%a: memref<4xi64>, %c: memref<4xf64>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<4xi64>, vector<2xi64>
  // ROW-OP
  %y = arith.sitofp %x : vector<2xi64> to vector<2xf64>
  vector.store %y, %c[%i] : memref<4xf64>, vector<2xf64>
  return
}

// -----

// ROW: arith.uitofp | i32x4
// CHECK-LABEL: @uitofp_i32x4
// CHECK: lvx.floatuwq
func.func @uitofp_i32x4(%a: memref<8xi32>, %c: memref<8xf32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xi32>, vector<4xi32>
  // ROW-OP
  %y = arith.uitofp %x : vector<4xi32> to vector<4xf32>
  vector.store %y, %c[%i] : memref<8xf32>, vector<4xf32>
  return
}

// -----

// ROW: arith.fptosi | f32x4
// CHECK-LABEL: @fptosi_f32x4
// CHECK: lvx.fixedwq
func.func @fptosi_f32x4(%a: memref<8xf32>, %c: memref<8xi32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xf32>, vector<4xf32>
  // ROW-OP
  %y = arith.fptosi %x : vector<4xf32> to vector<4xi32>
  vector.store %y, %c[%i] : memref<8xi32>, vector<4xi32>
  return
}

// -----

// ROW: arith.fptosi | f64x2
// CHECK-LABEL: @fptosi_f64x2
// CHECK: lvx.fixeddp
func.func @fptosi_f64x2(%a: memref<4xf64>, %c: memref<4xi64>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<4xf64>, vector<2xf64>
  // ROW-OP
  %y = arith.fptosi %x : vector<2xf64> to vector<2xi64>
  vector.store %y, %c[%i] : memref<4xi64>, vector<2xi64>
  return
}

// -----

// ROW: arith.fptoui | f32x4
// CHECK-LABEL: @fptoui_f32x4
// CHECK: lvx.fixeduwq
func.func @fptoui_f32x4(%a: memref<8xf32>, %c: memref<8xi32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xf32>, vector<4xf32>
  // ROW-OP
  %y = arith.fptoui %x : vector<4xf32> to vector<4xi32>
  vector.store %y, %c[%i] : memref<8xi32>, vector<4xi32>
  return
}

// -----

// Narrowing: one instruction reads the quad and writes the pair.
// ROW: arith.trunci | i64x4
// CHECK-LABEL: @trunci_i64x4
// CHECK: lvx.truncdwq
func.func @trunci_i64x4(%a: memref<8xi64>, %c: memref<8xi32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xi64>, vector<4xi64>
  // ROW-OP
  %y = arith.trunci %x : vector<4xi64> to vector<4xi32>
  vector.store %y, %c[%i] : memref<8xi32>, vector<4xi32>
  return
}

// -----

// ROW: arith.trunci | i32x8
// CHECK-LABEL: @trunci_i32x8
// CHECK: lvx.truncwho
func.func @trunci_i32x8(%a: memref<16xi32>, %c: memref<16xi16>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<16xi32>, vector<8xi32>
  // ROW-OP
  %y = arith.trunci %x : vector<8xi32> to vector<8xi16>
  vector.store %y, %c[%i] : memref<16xi16>, vector<8xi16>
  return
}

// -----

// ROW: arith.trunci | i16x16
// CHECK-LABEL: @trunci_i16x16
// CHECK: lvx.trunchbx
func.func @trunci_i16x16(%a: memref<32xi16>, %c: memref<32xi8>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<32xi16>, vector<16xi16>
  // ROW-OP
  %y = arith.trunci %x : vector<16xi16> to vector<16xi8>
  vector.store %y, %c[%i] : memref<32xi8>, vector<16xi8>
  return
}

// -----

// ROW: arith.truncf | f64x4
// CHECK-LABEL: @truncf_f64x4
// CHECK: lvx.fnarrowdwq
func.func @truncf_f64x4(%a: memref<8xf64>, %c: memref<8xf32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xf64>, vector<4xf64>
  // ROW-OP
  %y = arith.truncf %x : vector<4xf64> to vector<4xf32>
  vector.store %y, %c[%i] : memref<8xf32>, vector<4xf32>
  return
}

// -----

// Widening: one instruction per half of the source pair. The second carries
// `m` (mostsig), and the `lvx.concat` that makes the quad emits nothing.
// ROW: arith.extsi | i32x4
// CHECK-LABEL: @extsi_i32x4
// CHECK: lvx.widenswdp
// CHECK: lvx.widenswdp
// CHECK: lvx.concat
func.func @extsi_i32x4(%a: memref<8xi32>, %c: memref<8xi64>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xi32>, vector<4xi32>
  // ROW-OP
  %y = arith.extsi %x : vector<4xi32> to vector<4xi64>
  vector.store %y, %c[%i] : memref<8xi64>, vector<4xi64>
  return
}

// -----

// ROW: arith.extsi | i16x8
// CHECK-LABEL: @extsi_i16x8
// CHECK: lvx.widenshwq
func.func @extsi_i16x8(%a: memref<16xi16>, %c: memref<16xi32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<16xi16>, vector<8xi16>
  // ROW-OP
  %y = arith.extsi %x : vector<8xi16> to vector<8xi32>
  vector.store %y, %c[%i] : memref<16xi32>, vector<8xi32>
  return
}

// -----

// ROW: arith.extsi | i8x16
// CHECK-LABEL: @extsi_i8x16
// CHECK: lvx.widensbho
func.func @extsi_i8x16(%a: memref<32xi8>, %c: memref<32xi16>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<32xi8>, vector<16xi8>
  // ROW-OP
  %y = arith.extsi %x : vector<16xi8> to vector<16xi16>
  vector.store %y, %c[%i] : memref<32xi16>, vector<16xi16>
  return
}

// -----

// ROW: arith.extui | i32x4
// CHECK-LABEL: @extui_i32x4
// CHECK: lvx.widenzwdp
func.func @extui_i32x4(%a: memref<8xi32>, %c: memref<8xi64>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xi32>, vector<4xi32>
  // ROW-OP
  %y = arith.extui %x : vector<4xi32> to vector<4xi64>
  vector.store %y, %c[%i] : memref<8xi64>, vector<4xi64>
  return
}

// -----

// ROW: arith.extf | f32x4
// CHECK-LABEL: @extf_f32x4
// CHECK: lvx.fwidenwdp
// CHECK: lvx.fwidenwdp
func.func @extf_f32x4(%a: memref<8xf32>, %c: memref<8xf64>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xf32>, vector<4xf32>
  // ROW-OP
  %y = arith.extf %x : vector<4xf32> to vector<4xf64>
  vector.store %y, %c[%i] : memref<8xf64>, vector<4xf64>
  return
}
