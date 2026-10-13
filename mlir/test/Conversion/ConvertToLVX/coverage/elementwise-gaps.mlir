// RUN: mlir-opt %s -split-input-file -verify-diagnostics \
// RUN:   --pass-pipeline='builtin.module(func.func(lvx-lower-vector-transfers),convert-to-lvx,any(lvx-combine),cse)' -o /dev/null

// Elementwise rows with no lowering: class D. Each `expected-error` pins the
// gap, so when the ISA or a pattern fills it this test fails until the row
// moves to elementwise.mlir. See README.md.

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

// -----

// Integer vector division and remainder, and the transcendentals. All class D,
// and all **by decision rather than omission** (§5, "What is *not* a gap"):
// LVX has no integer vector divider, and `round`/`tanh` have no opcode at any
// width, scalar included. They are in the table because an absent row reads as
// "not looked at", and these were -- the yardstick ISAs have no integer vector
// divide either.

// ROW: arith.divsi | i32x4
func.func @arith_divsi_i32x4(%a: memref<64xi32>, %b: memref<64xi32>, %c: memref<64xi32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xi32>, vector<4xi32>
  %y = vector.load %b[%i] : memref<64xi32>, vector<4xi32>
  // expected-error @below {{failed to legalize operation 'arith.divsi'}}
  %z = arith.divsi %x, %y : vector<4xi32>
  vector.store %z, %c[%i] : memref<64xi32>, vector<4xi32>
  return
}
// -----

// ROW: arith.divsi | i64x2
func.func @arith_divsi_i64x2(%a: memref<64xi64>, %b: memref<64xi64>, %c: memref<64xi64>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xi64>, vector<2xi64>
  %y = vector.load %b[%i] : memref<64xi64>, vector<2xi64>
  // expected-error @below {{failed to legalize operation 'arith.divsi'}}
  %z = arith.divsi %x, %y : vector<2xi64>
  vector.store %z, %c[%i] : memref<64xi64>, vector<2xi64>
  return
}
// -----

// ROW: arith.divui | i32x4
func.func @arith_divui_i32x4(%a: memref<64xi32>, %b: memref<64xi32>, %c: memref<64xi32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xi32>, vector<4xi32>
  %y = vector.load %b[%i] : memref<64xi32>, vector<4xi32>
  // expected-error @below {{failed to legalize operation 'arith.divui'}}
  %z = arith.divui %x, %y : vector<4xi32>
  vector.store %z, %c[%i] : memref<64xi32>, vector<4xi32>
  return
}
// -----

// ROW: arith.divui | i64x2
func.func @arith_divui_i64x2(%a: memref<64xi64>, %b: memref<64xi64>, %c: memref<64xi64>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xi64>, vector<2xi64>
  %y = vector.load %b[%i] : memref<64xi64>, vector<2xi64>
  // expected-error @below {{failed to legalize operation 'arith.divui'}}
  %z = arith.divui %x, %y : vector<2xi64>
  vector.store %z, %c[%i] : memref<64xi64>, vector<2xi64>
  return
}
// -----

// ROW: arith.remsi | i32x4
func.func @arith_remsi_i32x4(%a: memref<64xi32>, %b: memref<64xi32>, %c: memref<64xi32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xi32>, vector<4xi32>
  %y = vector.load %b[%i] : memref<64xi32>, vector<4xi32>
  // expected-error @below {{failed to legalize operation 'arith.remsi'}}
  %z = arith.remsi %x, %y : vector<4xi32>
  vector.store %z, %c[%i] : memref<64xi32>, vector<4xi32>
  return
}
// -----

// ROW: arith.remsi | i64x2
func.func @arith_remsi_i64x2(%a: memref<64xi64>, %b: memref<64xi64>, %c: memref<64xi64>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xi64>, vector<2xi64>
  %y = vector.load %b[%i] : memref<64xi64>, vector<2xi64>
  // expected-error @below {{failed to legalize operation 'arith.remsi'}}
  %z = arith.remsi %x, %y : vector<2xi64>
  vector.store %z, %c[%i] : memref<64xi64>, vector<2xi64>
  return
}
// -----

// ROW: arith.remui | i32x4
func.func @arith_remui_i32x4(%a: memref<64xi32>, %b: memref<64xi32>, %c: memref<64xi32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xi32>, vector<4xi32>
  %y = vector.load %b[%i] : memref<64xi32>, vector<4xi32>
  // expected-error @below {{failed to legalize operation 'arith.remui'}}
  %z = arith.remui %x, %y : vector<4xi32>
  vector.store %z, %c[%i] : memref<64xi32>, vector<4xi32>
  return
}
// -----

// ROW: arith.remui | i64x2
func.func @arith_remui_i64x2(%a: memref<64xi64>, %b: memref<64xi64>, %c: memref<64xi64>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xi64>, vector<2xi64>
  %y = vector.load %b[%i] : memref<64xi64>, vector<2xi64>
  // expected-error @below {{failed to legalize operation 'arith.remui'}}
  %z = arith.remui %x, %y : vector<2xi64>
  vector.store %z, %c[%i] : memref<64xi64>, vector<2xi64>
  return
}
// -----

// ROW: math.tanh | f32x4
func.func @math_tanh_f32x4(%a: memref<64xf32>, %c: memref<64xf32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xf32>, vector<4xf32>
  // expected-error @below {{failed to legalize operation 'math.tanh'}}
  %z = math.tanh %x : vector<4xf32>
  vector.store %z, %c[%i] : memref<64xf32>, vector<4xf32>
  return
}
// -----

// ROW: math.tanh | f64x2
func.func @math_tanh_f64x2(%a: memref<64xf64>, %c: memref<64xf64>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xf64>, vector<2xf64>
  // expected-error @below {{failed to legalize operation 'math.tanh'}}
  %z = math.tanh %x : vector<2xf64>
  vector.store %z, %c[%i] : memref<64xf64>, vector<2xf64>
  return
}
