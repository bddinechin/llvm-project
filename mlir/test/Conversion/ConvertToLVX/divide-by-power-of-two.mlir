// RUN: mlir-opt %s -split-input-file \
// RUN:   --pass-pipeline='builtin.module(func.func(lvx-lower-vector-transfers),convert-to-lvx,any(lvx-combine),cse)' \
// RUN:   | FileCheck %s

// Signed division by a constant power of two is **one `srs*`** -- "shift right
// symmetric", which biases a negative value by `2^k - 1` before shifting so
// the result rounds *toward zero*. A plain `sra*` rounds toward minus
// infinity and is the wrong answer; that difference is the instruction's whole
// reason for existing, and it shows only on negative dividends.
//
// Before this, a power-of-two divide went to the general divider -- and not
// only in vector code: scalar `arith.divsi x, 4` lowered to `lvx.divmodw`.
// The vector forms failed to legalize outright.
//
// The *general* vector divide stays class D, and is not a gap (§5): no
// yardstick has an integer vector divider either. This is the strength
// reduction the ISA already provides an instruction for.

// CHECK-LABEL: @div_i32x4
// CHECK: lvx.srswq
// CHECK-NOT: lvx.divmod
func.func @div_i32x4(%a: memref<64xi32>, %c: memref<64xi32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xi32>, vector<4xi32>
  %k = arith.constant dense<4> : vector<4xi32>
  %z = arith.divsi %x, %k : vector<4xi32>
  vector.store %z, %c[%i] : memref<64xi32>, vector<4xi32>
  return
}

// -----

// The narrowest lanes, where the bias is over a byte.
// CHECK-LABEL: @div_i8x16
// CHECK: lvx.srsbx
func.func @div_i8x16(%a: memref<64xi8>, %c: memref<64xi8>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xi8>, vector<16xi8>
  %k = arith.constant dense<8> : vector<16xi8>
  %z = arith.divsi %x, %k : vector<16xi8>
  vector.store %z, %c[%i] : memref<64xi8>, vector<16xi8>
  return
}

// -----

// And where the register *is* the lane.
// CHECK-LABEL: @div_i64x2
// CHECK: lvx.srsdp
func.func @div_i64x2(%a: memref<64xi64>, %c: memref<64xi64>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xi64>, vector<2xi64>
  %k = arith.constant dense<2> : vector<2xi64>
  %z = arith.divsi %x, %k : vector<2xi64>
  vector.store %z, %c[%i] : memref<64xi64>, vector<2xi64>
  return
}

// -----

// The scalar, which is where the divider was most surprising.
// CHECK-LABEL: @div_scalar_i32
// CHECK: lvx.srsw
// CHECK-NOT: lvx.divmod
func.func @div_scalar_i32(%a: i32) -> i32 {
  %k = arith.constant 16 : i32
  %z = arith.divsi %a, %k : i32
  return %z : i32
}

// -----

// A divisor that is *not* a power of two must still go to the divider at
// scalar width, and still fail to legalize at vector width -- the pattern
// must not quietly round something it cannot divide.
// CHECK-LABEL: @div_scalar_by_7
// CHECK: lvx.divmodw
// CHECK-NOT: lvx.srs
func.func @div_scalar_by_7(%a: i32) -> i32 {
  %k = arith.constant 7 : i32
  %z = arith.divsi %a, %k : i32
  return %z : i32
}
