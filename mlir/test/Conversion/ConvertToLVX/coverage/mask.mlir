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

// -----

// Making a mask. A lane count is the loop-tail idiom: lanes 0..n-1 active is
// `(1 << n) - 1`. A constant count folds to `vector.constant_mask` upstream
// and is one `maked`; a dynamic one is four ops, the clamp included -- a
// count outside the vector is defined for `create_mask` (negative masks
// nothing, large masks everything) where a shift by it is not.

// ROW: vector.constant_mask | i1x4
// CHECK-LABEL: @constant_mask_i1x4
// CHECK: lvx.li 7
// CHECK-NOT: lvx.slld
func.func @constant_mask_i1x4(%a: memref<8xf32>, %b: memref<8xf32>, %c: memref<8xf32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xf32>, vector<4xf32>
  %y = vector.load %b[%i] : memref<8xf32>, vector<4xf32>
  // ROW-OP
  %m = vector.constant_mask [3] : vector<4xi1>
  %z = arith.select %m, %x, %y : vector<4xi1>, vector<4xf32>
  vector.store %z, %c[%i] : memref<8xf32>, vector<4xf32>
  return
}

// -----

// ROW: vector.create_mask | i1x4
// CHECK-LABEL: @create_mask_i1x4
// CHECK: lvx.maxd_i
// CHECK: lvx.mind_i
// CHECK: lvx.slld
// CHECK: lvx.addd_i
func.func @create_mask_i1x4(%a: memref<8xf32>, %b: memref<8xf32>, %c: memref<8xf32>, %n: index) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xf32>, vector<4xf32>
  %y = vector.load %b[%i] : memref<8xf32>, vector<4xf32>
  // ROW-OP
  %m = vector.create_mask %n : vector<4xi1>
  %z = arith.select %m, %x, %y : vector<4xi1>, vector<4xf32>
  vector.store %z, %c[%i] : memref<8xf32>, vector<4xf32>
  return
}

// -----

// `arith.select` is two operations sharing one spelling, and the condition's
// type is what separates them: a `vector<Nxi1>` condition picks per lane
// (`blend*`, above), a scalar `i1` picks the whole vector. The scalar-condition
// form had no lowering until CMOVEQ arrived (lvx-mds 409a2c3) -- the vector
// pattern wanted a vector condition, the scalar pattern rejects vector
// operands, so it fell between them.

// ROW: arith.select(scalar) | f32x4
// CHECK-LABEL: @select_scalar_f32x4
// CHECK: lvx.cmoveq wnez
// CHECK-NOT: lvx.blend
func.func @select_scalar_f32x4(%c: i1, %a: memref<8xf32>, %b: memref<8xf32>,
                               %o: memref<8xf32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xf32>, vector<4xf32>
  %y = vector.load %b[%i] : memref<8xf32>, vector<4xf32>
  // ROW-OP
  %z = arith.select %c, %x, %y : vector<4xf32>
  vector.store %z, %o[%i] : memref<8xf32>, vector<4xf32>
  return
}

// -----

// CMOVEQ is pair-only, with no quad form and no composite, so a quad is two of
// them on the halves.
// ROW: arith.select(scalar) | f32x8
// CHECK-LABEL: @select_scalar_f32x8
// CHECK: lvx.cmoveq wnez
// CHECK: lvx.cmoveq wnez
func.func @select_scalar_f32x8(%c: i1, %a: memref<16xf32>, %b: memref<16xf32>,
                               %o: memref<16xf32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<16xf32>, vector<8xf32>
  %y = vector.load %b[%i] : memref<16xf32>, vector<8xf32>
  // ROW-OP
  %z = arith.select %c, %x, %y : vector<8xf32>
  vector.store %z, %o[%i] : memref<16xf32>, vector<8xf32>
  return
}

// -----

// A quad compare. `COMP*` writes its lane bits from bit 0 and clears the rest,
// so both halves land in the same bits and must be brought together: `insfd`
// shifts the high half up by the half lane count and merges it, one
// instruction where a shift and an or would be two. Low half first, which is
// the order `masks.mtd` distributes in.
//
// Combined rather than kept apart because a masked quad *access* cannot take
// two masks: `lo`/`so` are single instructions, not composites, and `MASKM`
// has no `.mtd`. The row below pairs it with a masked store for that reason.
// ROW: arith.cmpi | i32x8
// CHECK-LABEL: @cmpi_i32x8
// CHECK: lvx.compwq
// CHECK: lvx.compwq
// CHECK: lvx.insfd
// CHECK: lvx.extb4d
func.func @cmpi_i32x8(%a: memref<16xi32>, %b: memref<16xi32>, %o: memref<16xi32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<16xi32>, vector<8xi32>
  %y = vector.load %b[%i] : memref<16xi32>, vector<8xi32>
  // ROW-OP
  %m = arith.cmpi slt, %x, %y : vector<8xi32>
  vector.maskedstore %o[%i], %m, %x : memref<16xi32>, vector<8xi1>, vector<8xi32>
  return
}

// -----

// ROW: arith.cmpf | f32x8
// CHECK-LABEL: @cmpf_f32x8
// CHECK: lvx.fcompwq
// CHECK: lvx.fcompwq
// CHECK: lvx.insfd
func.func @cmpf_f32x8(%a: memref<16xf32>, %b: memref<16xf32>, %o: memref<16xf32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<16xf32>, vector<8xf32>
  %y = vector.load %b[%i] : memref<16xf32>, vector<8xf32>
  // ROW-OP
  %m = arith.cmpf olt, %x, %y : vector<8xf32>
  vector.maskedstore %o[%i], %m, %x : memref<16xf32>, vector<8xi1>, vector<8xf32>
  return
}

// -----

// A quad vector-condition select. `blend*` has no quad form and no composite
// (§7 group B), so it is one per half -- and since the mask arrives combined
// low-first, the high half reads it shifted down by the half lane count.
// `blend*` looks at only as many bits as it has lanes, so the shift is the
// whole adjustment; nothing has to mask above it.
// ROW: arith.select | i32x8
// CHECK-LABEL: @select_i32x8
// CHECK: lvx.blendwq
// CHECK: lvx.srld_i %{{.*}}, 4
// CHECK: lvx.blendwq
func.func @select_i32x8(%m: vector<8xi1>, %a: memref<16xi32>,
                        %b: memref<16xi32>, %o: memref<16xi32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<16xi32>, vector<8xi32>
  %y = vector.load %b[%i] : memref<16xi32>, vector<8xi32>
  // ROW-OP
  %z = arith.select %m, %x, %y : vector<8xi1>, vector<8xi32>
  vector.store %z, %o[%i] : memref<16xi32>, vector<8xi32>
  return
}
