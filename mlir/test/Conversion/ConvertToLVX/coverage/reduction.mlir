// RUN: mlir-opt %s -split-input-file \
// RUN:   --pass-pipeline='builtin.module(func.func(lvx-lower-vector-transfers),convert-to-lvx,any(lvx-combine),cse)' \
// RUN:   | FileCheck %s

// Reduction rows of docs/VectorCoverage.md (Phase 4). The ISA has no
// horizontal instruction, so each row is the tree described in
// ConvertToLVX.cpp: a quad folds to a pair in one op, 64-bit lanes finish in
// one scalar op because the pair's units are its lanes, and narrower lanes
// spend even/odd + the op per level. See README.md for the row format.

// 64-bit lanes: the two units are the two lanes, so this is one `addd` and
// the lane views cost nothing.
// ROW: vector.reduction<add> | i64x2
// CHECK-LABEL: @reduction_add_i64x2
// CHECK: lvx.addd
// CHECK-NOT: lvx.evendq
func.func @reduction_add_i64x2(%a: memref<4xi64>, %c: memref<4xi64>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<4xi64>, vector<2xi64>
  // ROW-OP
  %s = vector.reduction <add>, %x : vector<2xi64> into i64
  memref.store %s, %c[%i] : memref<4xi64>
  return
}

// -----

// ROW: vector.reduction<add> | i32x4
// CHECK-LABEL: @reduction_add_i32x4
// CHECK: lvx.evenwq
// CHECK: lvx.oddwq
// CHECK: lvx.addwq
func.func @reduction_add_i32x4(%a: memref<8xi32>, %c: memref<8xi32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xi32>, vector<4xi32>
  // ROW-OP
  %s = vector.reduction <add>, %x : vector<4xi32> into i32
  memref.store %s, %c[%i] : memref<8xi32>
  return
}

// -----

// ROW: vector.reduction<add> | i16x8
// CHECK-LABEL: @reduction_add_i16x8
// CHECK: lvx.evenhq
func.func @reduction_add_i16x8(%a: memref<16xi16>, %c: memref<16xi16>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<16xi16>, vector<8xi16>
  // ROW-OP
  %s = vector.reduction <add>, %x : vector<8xi16> into i16
  memref.store %s, %c[%i] : memref<16xi16>
  return
}

// -----

// ROW: vector.reduction<add> | i8x16
// CHECK-LABEL: @reduction_add_i8x16
// CHECK: lvx.evenbq
func.func @reduction_add_i8x16(%a: memref<32xi8>, %c: memref<32xi8>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<32xi8>, vector<16xi8>
  // ROW-OP
  %s = vector.reduction <add>, %x : vector<16xi8> into i8
  memref.store %s, %c[%i] : memref<32xi8>
  return
}

// -----

// A quad folds to a pair with one lane-parallel op on its halves first.
// ROW: vector.reduction<add> | i32x8
// CHECK-LABEL: @reduction_add_i32x8
// CHECK: lvx.addwq
// CHECK: lvx.evenwq
func.func @reduction_add_i32x8(%a: memref<16xi32>, %c: memref<16xi32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<16xi32>, vector<8xi32>
  // ROW-OP
  %s = vector.reduction <add>, %x : vector<8xi32> into i32
  memref.store %s, %c[%i] : memref<16xi32>
  return
}

// -----

// A float reduction reassociates, so it needs `reassoc` to be lowered as a
// tree at all; the row carries it.
// ROW: vector.reduction<add> | f32x4
// CHECK-LABEL: @reduction_add_f32x4
// CHECK: lvx.evenwq
// CHECK: lvx.faddwq
func.func @reduction_add_f32x4(%a: memref<8xf32>, %c: memref<8xf32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xf32>, vector<4xf32>
  // ROW-OP
  %s = vector.reduction <add>, %x fastmath<reassoc> : vector<4xf32> into f32
  memref.store %s, %c[%i] : memref<8xf32>
  return
}

// -----

// ROW: vector.reduction<add> | f64x2
// CHECK-LABEL: @reduction_add_f64x2
// CHECK: lvx.faddd
func.func @reduction_add_f64x2(%a: memref<4xf64>, %c: memref<4xf64>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<4xf64>, vector<2xf64>
  // ROW-OP
  %s = vector.reduction <add>, %x fastmath<reassoc> : vector<2xf64> into f64
  memref.store %s, %c[%i] : memref<4xf64>
  return
}

// -----

// ROW: vector.reduction<mul> | i32x4
// CHECK-LABEL: @reduction_mul_i32x4
// CHECK: lvx.mulwq
func.func @reduction_mul_i32x4(%a: memref<8xi32>, %c: memref<8xi32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xi32>, vector<4xi32>
  // ROW-OP
  %s = vector.reduction <mul>, %x : vector<4xi32> into i32
  memref.store %s, %c[%i] : memref<8xi32>
  return
}

// -----

// ROW: vector.reduction<minsi> | i32x4
// CHECK-LABEL: @reduction_minsi_i32x4
// CHECK: lvx.minwq
func.func @reduction_minsi_i32x4(%a: memref<8xi32>, %c: memref<8xi32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xi32>, vector<4xi32>
  // ROW-OP
  %s = vector.reduction <minsi>, %x : vector<4xi32> into i32
  memref.store %s, %c[%i] : memref<8xi32>
  return
}

// -----

// ROW: vector.reduction<maxsi> | i8x16
// CHECK-LABEL: @reduction_maxsi_i8x16
// CHECK: lvx.maxbx
func.func @reduction_maxsi_i8x16(%a: memref<32xi8>, %c: memref<32xi8>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<32xi8>, vector<16xi8>
  // ROW-OP
  %s = vector.reduction <maxsi>, %x : vector<16xi8> into i8
  memref.store %s, %c[%i] : memref<32xi8>
  return
}

// -----

// `minimumf` propagates a NaN -- `fmin`, not `fminn` (the min/max NaN split).
// ROW: vector.reduction<minimumf> | f32x4
// CHECK-LABEL: @reduction_minimumf_f32x4
// CHECK: lvx.fminwq
func.func @reduction_minimumf_f32x4(%a: memref<8xf32>, %c: memref<8xf32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xf32>, vector<4xf32>
  // ROW-OP
  %s = vector.reduction <minimumf>, %x fastmath<reassoc> : vector<4xf32> into f32
  memref.store %s, %c[%i] : memref<8xf32>
  return
}

// -----

// `minnumf` returns the numeric operand -- `fminn`. The two differ only on a
// NaN input, which is why the pairing has to be pinned by a test.
// ROW: vector.reduction<minnumf> | f32x4
// CHECK-LABEL: @reduction_minnumf_f32x4
// CHECK: lvx.fminnwq
func.func @reduction_minnumf_f32x4(%a: memref<8xf32>, %c: memref<8xf32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xf32>, vector<4xf32>
  // ROW-OP
  %s = vector.reduction <minnumf>, %x fastmath<reassoc> : vector<4xf32> into f32
  memref.store %s, %c[%i] : memref<8xf32>
  return
}

// -----

// and/or/xor are bitwise and lane-independent, so they skip the even/odd tree
// entirely: fold the units with the 64-bit scalar op, then halve within the
// unit by shifting it down over itself. Three ops at i32x4 where the tree
// would be six.
// ROW: vector.reduction<and> | i32x4
// CHECK-LABEL: @reduction_and_i32x4
// CHECK: lvx.andd
func.func @reduction_and_i32x4(%a: memref<8xi32>, %c: memref<8xi32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xi32>, vector<4xi32>
  // ROW-OP
  %s = vector.reduction <and>, %x : vector<4xi32> into i32
  memref.store %s, %c[%i] : memref<8xi32>
  return
}

// -----

// ROW: vector.reduction<xor> | i32x4
// CHECK-LABEL: @reduction_xor_i32x4
// CHECK: lvx.eord
func.func @reduction_xor_i32x4(%a: memref<8xi32>, %c: memref<8xi32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xi32>, vector<4xi32>
  // ROW-OP
  %s = vector.reduction <xor>, %x : vector<4xi32> into i32
  memref.store %s, %c[%i] : memref<8xi32>
  return
}

// -----

// ROW: vector.reduction<or> | i32x4
// CHECK-LABEL: @reduction_or_i32x4
// CHECK: lvx.iord
func.func @reduction_or_i32x4(%a: memref<8xi32>, %c: memref<8xi32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xi32>, vector<4xi32>
  // ROW-OP
  %s = vector.reduction <or>, %x : vector<4xi32> into i32
  memref.store %s, %c[%i] : memref<8xi32>
  return
}

// -----

// Where the shift fold pays most: byte lanes are four halvings, seven ops
// against the tree's twelve.
// ROW: vector.reduction<and> | i8x16
// CHECK-LABEL: @reduction_and_i8x16
// CHECK: lvx.andd
// CHECK-NOT: lvx.evenbq
func.func @reduction_and_i8x16(%a: memref<32xi8>, %c: memref<32xi8>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<32xi8>, vector<16xi8>
  // ROW-OP
  %s = vector.reduction <and>, %x : vector<16xi8> into i8
  memref.store %s, %c[%i] : memref<32xi8>
  return
}

// -----

// The *accumulator* form, which used to legalize while silently dropping the
// accumulator. It is folded in the bridge into a scalar op over the tree's
// result -- `addw` at i32 lanes, the width-correct one.
// ROW: vector.reduction<add>(acc) | i32x4
// CHECK-LABEL: @reduction_add_acc_i32x4
// CHECK: lvx.addwq
// CHECK: lvx.addw
func.func @reduction_add_acc_i32x4(%a: memref<4xi32>, %c: memref<4xi32>,
                                   %acc: i32) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<4xi32>, vector<4xi32>
  // ROW-OP
  %s = vector.reduction <add>, %x, %acc : vector<4xi32> into i32
  memref.store %s, %c[%i] : memref<4xi32>
  return
}

// -----

// `vector.contract` at integer lanes: a dot product, whose init *is* the
// accumulator, which is why it did not lower until that was fixed. The bridge
// decomposes it with the `Dot` strategy into extract/reduction/insert, so what
// is measured is the reduction tree plus the accumulator fold.
//
// The float form is deliberately absent: a float reduction without `reassoc`
// is the sequential chain rather than a tree (§4), and `vector.contract` does
// not carry the flag.
// ROW: vector.contract | i32x4
// CHECK-LABEL: @contract_i32x4
// CHECK: lvx.mulwq
// CHECK: lvx.addwq
// CHECK: lvx.addw
#cd = affine_map<(d0) -> (d0)>
#cs = affine_map<(d0) -> ()>
func.func @contract_i32x4(%a: memref<4xi32>, %b: memref<4xi32>,
                          %c: memref<4xi32>, %acc: i32) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<4xi32>, vector<4xi32>
  %y = vector.load %b[%i] : memref<4xi32>, vector<4xi32>
  // ROW-OP
  %r = vector.contract {indexing_maps = [#cd, #cd, #cs],
                        iterator_types = ["reduction"],
                        kind = #vector.kind<add>} %x, %y, %acc
       : vector<4xi32>, vector<4xi32> into i32
  memref.store %r, %c[%i] : memref<4xi32>
  return
}

// -----

// The reduction kinds and widths the suite had not exercised, plus
// `vector.outerproduct` and the float `multi_reduction`. All lower; the rows
// exist so the table says so rather than leaving them open.

// ROW: vector.reduction<maxsi> | i16x8
// CHECK-LABEL: @reduction_maxsi_i16x8
// CHECK: lvx.
func.func @reduction_maxsi_i16x8(%a: memref<64xi16>, %c: memref<64xi16>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xi16>, vector<8xi16>
  // ROW-OP
  %r = vector.reduction <maxsi>, %x : vector<8xi16> into i16
  memref.store %r, %c[%i] : memref<64xi16>
  return
}
// -----

// ROW: vector.reduction<maxsi> | i32x4
// CHECK-LABEL: @reduction_maxsi_i32x4
// CHECK: lvx.
func.func @reduction_maxsi_i32x4(%a: memref<64xi32>, %c: memref<64xi32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xi32>, vector<4xi32>
  // ROW-OP
  %r = vector.reduction <maxsi>, %x : vector<4xi32> into i32
  memref.store %r, %c[%i] : memref<64xi32>
  return
}
// -----

// ROW: vector.reduction<maxsi> | i64x2
// CHECK-LABEL: @reduction_maxsi_i64x2
// CHECK: lvx.
func.func @reduction_maxsi_i64x2(%a: memref<64xi64>, %c: memref<64xi64>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xi64>, vector<2xi64>
  // ROW-OP
  %r = vector.reduction <maxsi>, %x : vector<2xi64> into i64
  memref.store %r, %c[%i] : memref<64xi64>
  return
}
// -----

// ROW: vector.reduction<minsi> | i8x16
// CHECK-LABEL: @reduction_minsi_i8x16
// CHECK: lvx.
func.func @reduction_minsi_i8x16(%a: memref<64xi8>, %c: memref<64xi8>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xi8>, vector<16xi8>
  // ROW-OP
  %r = vector.reduction <minsi>, %x : vector<16xi8> into i8
  memref.store %r, %c[%i] : memref<64xi8>
  return
}
// -----

// ROW: vector.reduction<minsi> | i16x8
// CHECK-LABEL: @reduction_minsi_i16x8
// CHECK: lvx.
func.func @reduction_minsi_i16x8(%a: memref<64xi16>, %c: memref<64xi16>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xi16>, vector<8xi16>
  // ROW-OP
  %r = vector.reduction <minsi>, %x : vector<8xi16> into i16
  memref.store %r, %c[%i] : memref<64xi16>
  return
}
// -----

// ROW: vector.reduction<minsi> | i64x2
// CHECK-LABEL: @reduction_minsi_i64x2
// CHECK: lvx.
func.func @reduction_minsi_i64x2(%a: memref<64xi64>, %c: memref<64xi64>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xi64>, vector<2xi64>
  // ROW-OP
  %r = vector.reduction <minsi>, %x : vector<2xi64> into i64
  memref.store %r, %c[%i] : memref<64xi64>
  return
}
// -----

// ROW: vector.reduction<maximumf> | f32x4
// CHECK-LABEL: @reduction_maximumf_f32x4
// CHECK: lvx.
func.func @reduction_maximumf_f32x4(%a: memref<64xf32>, %c: memref<64xf32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xf32>, vector<4xf32>
  // ROW-OP
  %r = vector.reduction <maximumf>, %x fastmath<reassoc> : vector<4xf32> into f32
  memref.store %r, %c[%i] : memref<64xf32>
  return
}
// -----

// ROW: vector.reduction<maximumf> | f64x2
// CHECK-LABEL: @reduction_maximumf_f64x2
// CHECK: lvx.
func.func @reduction_maximumf_f64x2(%a: memref<64xf64>, %c: memref<64xf64>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xf64>, vector<2xf64>
  // ROW-OP
  %r = vector.reduction <maximumf>, %x fastmath<reassoc> : vector<2xf64> into f64
  memref.store %r, %c[%i] : memref<64xf64>
  return
}
// -----

// ROW: vector.reduction<minimumf> | f64x2
// CHECK-LABEL: @reduction_minimumf_f64x2
// CHECK: lvx.
func.func @reduction_minimumf_f64x2(%a: memref<64xf64>, %c: memref<64xf64>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xf64>, vector<2xf64>
  // ROW-OP
  %r = vector.reduction <minimumf>, %x fastmath<reassoc> : vector<2xf64> into f64
  memref.store %r, %c[%i] : memref<64xf64>
  return
}
// -----

// ROW: vector.reduction<mul> | f32x4
// CHECK-LABEL: @reduction_mul_f32x4
// CHECK: lvx.
func.func @reduction_mul_f32x4(%a: memref<64xf32>, %c: memref<64xf32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xf32>, vector<4xf32>
  // ROW-OP
  %r = vector.reduction <mul>, %x fastmath<reassoc> : vector<4xf32> into f32
  memref.store %r, %c[%i] : memref<64xf32>
  return
}
// -----

// `vector.outerproduct`, never measured before. At a pair it is one broadcast
// and one `ffma` per row of the result.
// ROW: vector.outerproduct | f32x4
// CHECK-LABEL: @outerproduct_f32x4
// CHECK: lvx.
func.func @outerproduct_f32x4(%a: memref<64xf32>, %c: memref<64xf32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xf32>, vector<4xf32>
  %y = vector.load %a[%i] : memref<64xf32>, vector<4xf32>
  // ROW-OP
  %o = vector.outerproduct %x, %y : vector<4xf32>, vector<4xf32>
  %r = vector.extract %o[0] : vector<4xf32> from vector<4x4xf32>
  vector.store %r, %c[%i] : memref<64xf32>, vector<4xf32>
  return
}
