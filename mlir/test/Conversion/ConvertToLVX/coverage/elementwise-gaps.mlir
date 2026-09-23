// RUN: mlir-opt %s -split-input-file -verify-diagnostics -convert-to-lvx -o /dev/null

// Elementwise rows with no lowering: class D. Each `expected-error` pins the
// gap, so when the ISA or a pattern fills it this test fails until the row
// moves to elementwise.mlir. See README.md.

// -----

// ROW: arith.muli | i8x16
func.func @arith_muli_i8x16(%a: memref<64xi8>, %b: memref<64xi8>, %c: memref<64xi8>, %s: i8) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xi8>, vector<16xi8>
  %y = vector.load %b[%i] : memref<64xi8>, vector<16xi8>
  // expected-error @below {{failed to legalize operation 'arith.muli'}}
  %z = arith.muli %x, %y : vector<16xi8>
  vector.store %z, %c[%i] : memref<64xi8>, vector<16xi8>
  return
}

// -----

// ROW: arith.muli | i8x32
func.func @arith_muli_i8x32(%a: memref<64xi8>, %b: memref<64xi8>, %c: memref<64xi8>, %s: i8) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xi8>, vector<32xi8>
  %y = vector.load %b[%i] : memref<64xi8>, vector<32xi8>
  // expected-error @below {{failed to legalize operation 'arith.muli'}}
  %z = arith.muli %x, %y : vector<32xi8>
  vector.store %z, %c[%i] : memref<64xi8>, vector<32xi8>
  return
}

// -----

// ROW: arith.divf | f32x4
func.func @arith_divf_f32x4(%a: memref<64xf32>, %b: memref<64xf32>, %c: memref<64xf32>, %s: f32) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xf32>, vector<4xf32>
  %y = vector.load %b[%i] : memref<64xf32>, vector<4xf32>
  // expected-error @below {{failed to legalize operation 'arith.divf'}}
  %z = arith.divf %x, %y : vector<4xf32>
  vector.store %z, %c[%i] : memref<64xf32>, vector<4xf32>
  return
}

// -----

// ROW: arith.divf | f64x2
func.func @arith_divf_f64x2(%a: memref<64xf64>, %b: memref<64xf64>, %c: memref<64xf64>, %s: f64) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xf64>, vector<2xf64>
  %y = vector.load %b[%i] : memref<64xf64>, vector<2xf64>
  // expected-error @below {{failed to legalize operation 'arith.divf'}}
  %z = arith.divf %x, %y : vector<2xf64>
  vector.store %z, %c[%i] : memref<64xf64>, vector<2xf64>
  return
}

// -----

// ROW: math.ctlz | i8x16
func.func @math_ctlz_i8x16(%a: memref<64xi8>, %b: memref<64xi8>, %c: memref<64xi8>, %s: i8) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xi8>, vector<16xi8>
  // expected-error @below {{failed to legalize operation 'math.ctlz'}}
  %z = math.ctlz %x : vector<16xi8>
  vector.store %z, %c[%i] : memref<64xi8>, vector<16xi8>
  return
}

// -----

// ROW: math.cttz | i8x16
func.func @math_cttz_i8x16(%a: memref<64xi8>, %b: memref<64xi8>, %c: memref<64xi8>, %s: i8) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xi8>, vector<16xi8>
  // expected-error @below {{failed to legalize operation 'math.cttz'}}
  %z = math.cttz %x : vector<16xi8>
  vector.store %z, %c[%i] : memref<64xi8>, vector<16xi8>
  return
}

// -----

// ROW: math.ctpop | i8x16
func.func @math_ctpop_i8x16(%a: memref<64xi8>, %b: memref<64xi8>, %c: memref<64xi8>, %s: i8) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xi8>, vector<16xi8>
  // expected-error @below {{failed to legalize operation 'math.ctpop'}}
  %z = math.ctpop %x : vector<16xi8>
  vector.store %z, %c[%i] : memref<64xi8>, vector<16xi8>
  return
}

// -----

// ROW: math.sqrt | f32x4
func.func @math_sqrt_f32x4(%a: memref<64xf32>, %b: memref<64xf32>, %c: memref<64xf32>, %s: f32) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xf32>, vector<4xf32>
  // expected-error @below {{failed to legalize operation 'math.sqrt'}}
  %z = math.sqrt %x : vector<4xf32>
  vector.store %z, %c[%i] : memref<64xf32>, vector<4xf32>
  return
}

// -----

// ROW: math.sqrt | f64x2
func.func @math_sqrt_f64x2(%a: memref<64xf64>, %b: memref<64xf64>, %c: memref<64xf64>, %s: f64) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xf64>, vector<2xf64>
  // expected-error @below {{failed to legalize operation 'math.sqrt'}}
  %z = math.sqrt %x : vector<2xf64>
  vector.store %z, %c[%i] : memref<64xf64>, vector<2xf64>
  return
}

// -----

// ROW: math.rsqrt | f32x4
func.func @math_rsqrt_f32x4(%a: memref<64xf32>, %b: memref<64xf32>, %c: memref<64xf32>, %s: f32) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xf32>, vector<4xf32>
  // expected-error @below {{failed to legalize operation 'math.rsqrt'}}
  %z = math.rsqrt %x : vector<4xf32>
  vector.store %z, %c[%i] : memref<64xf32>, vector<4xf32>
  return
}

// -----

// ROW: math.rsqrt | f64x2
func.func @math_rsqrt_f64x2(%a: memref<64xf64>, %b: memref<64xf64>, %c: memref<64xf64>, %s: f64) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xf64>, vector<2xf64>
  // expected-error @below {{failed to legalize operation 'math.rsqrt'}}
  %z = math.rsqrt %x : vector<2xf64>
  vector.store %z, %c[%i] : memref<64xf64>, vector<2xf64>
  return
}

// -----

// ROW: math.floor | f32x4
func.func @math_floor_f32x4(%a: memref<64xf32>, %b: memref<64xf32>, %c: memref<64xf32>, %s: f32) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xf32>, vector<4xf32>
  // expected-error @below {{failed to legalize operation 'math.floor'}}
  %z = math.floor %x : vector<4xf32>
  vector.store %z, %c[%i] : memref<64xf32>, vector<4xf32>
  return
}

// -----

// ROW: math.floor | f64x2
func.func @math_floor_f64x2(%a: memref<64xf64>, %b: memref<64xf64>, %c: memref<64xf64>, %s: f64) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xf64>, vector<2xf64>
  // expected-error @below {{failed to legalize operation 'math.floor'}}
  %z = math.floor %x : vector<2xf64>
  vector.store %z, %c[%i] : memref<64xf64>, vector<2xf64>
  return
}

// -----

// ROW: math.ceil | f32x4
func.func @math_ceil_f32x4(%a: memref<64xf32>, %b: memref<64xf32>, %c: memref<64xf32>, %s: f32) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xf32>, vector<4xf32>
  // expected-error @below {{failed to legalize operation 'math.ceil'}}
  %z = math.ceil %x : vector<4xf32>
  vector.store %z, %c[%i] : memref<64xf32>, vector<4xf32>
  return
}

// -----

// ROW: math.ceil | f64x2
func.func @math_ceil_f64x2(%a: memref<64xf64>, %b: memref<64xf64>, %c: memref<64xf64>, %s: f64) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xf64>, vector<2xf64>
  // expected-error @below {{failed to legalize operation 'math.ceil'}}
  %z = math.ceil %x : vector<2xf64>
  vector.store %z, %c[%i] : memref<64xf64>, vector<2xf64>
  return
}

// -----

// ROW: math.roundeven | f32x4
func.func @math_roundeven_f32x4(%a: memref<64xf32>, %b: memref<64xf32>, %c: memref<64xf32>, %s: f32) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xf32>, vector<4xf32>
  // expected-error @below {{failed to legalize operation 'math.roundeven'}}
  %z = math.roundeven %x : vector<4xf32>
  vector.store %z, %c[%i] : memref<64xf32>, vector<4xf32>
  return
}

// -----

// ROW: math.roundeven | f64x2
func.func @math_roundeven_f64x2(%a: memref<64xf64>, %b: memref<64xf64>, %c: memref<64xf64>, %s: f64) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xf64>, vector<2xf64>
  // expected-error @below {{failed to legalize operation 'math.roundeven'}}
  %z = math.roundeven %x : vector<2xf64>
  vector.store %z, %c[%i] : memref<64xf64>, vector<2xf64>
  return
}

// -----

// ROW: math.trunc | f32x4
func.func @math_trunc_f32x4(%a: memref<64xf32>, %b: memref<64xf32>, %c: memref<64xf32>, %s: f32) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xf32>, vector<4xf32>
  // expected-error @below {{failed to legalize operation 'math.trunc'}}
  %z = math.trunc %x : vector<4xf32>
  vector.store %z, %c[%i] : memref<64xf32>, vector<4xf32>
  return
}

// -----

// ROW: math.trunc | f64x2
func.func @math_trunc_f64x2(%a: memref<64xf64>, %b: memref<64xf64>, %c: memref<64xf64>, %s: f64) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xf64>, vector<2xf64>
  // expected-error @below {{failed to legalize operation 'math.trunc'}}
  %z = math.trunc %x : vector<2xf64>
  vector.store %z, %c[%i] : memref<64xf64>, vector<2xf64>
  return
}

// -----

// ROW: math.exp | f32x4
func.func @math_exp_f32x4(%a: memref<64xf32>, %b: memref<64xf32>, %c: memref<64xf32>, %s: f32) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xf32>, vector<4xf32>
  // expected-error @below {{failed to legalize operation 'math.exp'}}
  %z = math.exp %x : vector<4xf32>
  vector.store %z, %c[%i] : memref<64xf32>, vector<4xf32>
  return
}

// -----

// ROW: math.exp | f64x2
func.func @math_exp_f64x2(%a: memref<64xf64>, %b: memref<64xf64>, %c: memref<64xf64>, %s: f64) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xf64>, vector<2xf64>
  // expected-error @below {{failed to legalize operation 'math.exp'}}
  %z = math.exp %x : vector<2xf64>
  vector.store %z, %c[%i] : memref<64xf64>, vector<2xf64>
  return
}
