// RUN: mlir-opt %s --pass-pipeline='builtin.module(func.func(lvx-lower-vector-transfers))' \
// RUN:   | mlir-opt -convert-to-lvx | FileCheck %s

// `vector.contract` and `vector.multi_reduction`: the reduced shapes, which
// upstream emits for a dot product or a matmul vectorised along k, and which
// nothing here lowered until -lvx-lower-vector-transfers learned upstream's
// decompositions (docs/VectorCoverage.md, Phase 4).
//
// The `Dot` strategy is the one that fits: it rewrites a contraction into
// vector.extract + vector.reduction + vector.insert, every one of which this
// back end already lowers. What comes out below is the reduction tree of
// Phase 4 -- even/odd to bring the lanes alongside each other, then the op.

// CHECK-LABEL: @dot_i32
// CHECK: lvx.mulwq
// CHECK: lvx.evenwq
// CHECK: lvx.oddwq
// CHECK-NOT: vector.contract
#dot_a = affine_map<(k) -> (k)>
#dot_s = affine_map<(k) -> ()>
func.func @dot_i32(%p: memref<8xi32>, %q: memref<8xi32>, %o: memref<8xi32>) {
  %c0 = arith.constant 0 : index
  %z = arith.constant 0 : i32
  %x = vector.load %p[%c0] : memref<8xi32>, vector<4xi32>
  %y = vector.load %q[%c0] : memref<8xi32>, vector<4xi32>
  %r = vector.contract {indexing_maps = [#dot_a, #dot_a, #dot_s],
                        iterator_types = ["reduction"]}
       %x, %y, %z : vector<4xi32>, vector<4xi32> into i32
  memref.store %r, %o[%c0] : memref<8xi32>
  return
}

// -----

// A 1-D `vector.multi_reduction` reaches `vector.reduction` through the
// Unrolling stage's [OneDimMultiReductionToReduction].
// CHECK-LABEL: @multi_reduction_i32
// CHECK: lvx.evenwq
// CHECK-NOT: vector.multi_reduction
func.func @multi_reduction_i32(%p: memref<8xi32>, %o: memref<8xi32>) {
  %c0 = arith.constant 0 : index
  %z = arith.constant 0 : i32
  %x = vector.load %p[%c0] : memref<8xi32>, vector<4xi32>
  %r = vector.multi_reduction <add>, %x, %z [0] : vector<4xi32> to i32
  memref.store %r, %o[%c0] : memref<8xi32>
  return
}

// -----

// A 2-D operand. `Dot` extracts rows from it, and a 2-D vector has no register
// tuple -- so this needed native-shape unrolling, which cuts every vector to a
// shape a tuple holds (at most 256 bits, one dimension) and lets the rows be
// read as separate vectors in the first place.
// CHECK-LABEL: @matvec_i32
// CHECK-NOT: vector.contract
// CHECK-NOT: vector.extract
// CHECK: lvx.addwq
#mv0 = affine_map<(i,k) -> (i,k)>
#mv1 = affine_map<(i,k) -> (k)>
#mv2 = affine_map<(i,k) -> (i)>
func.func @matvec_i32(%A: memref<4x4xi32>, %b: memref<4xi32>, %o: memref<4xi32>) {
  %c0 = arith.constant 0 : index
  %z = arith.constant 0 : i32
  %a = vector.transfer_read %A[%c0,%c0], %z : memref<4x4xi32>, vector<4x4xi32>
  %v = vector.transfer_read %b[%c0], %z : memref<4xi32>, vector<4xi32>
  %acc = vector.transfer_read %o[%c0], %z : memref<4xi32>, vector<4xi32>
  %r = vector.contract {indexing_maps = [#mv0, #mv1, #mv2],
                        iterator_types = ["parallel", "reduction"]}
       %a, %v, %acc : vector<4x4xi32>, vector<4xi32> into vector<4xi32>
  vector.transfer_write %r, %o[%c0] : vector<4xi32>, memref<4xi32>
  return
}

// -----

// An oversized 1-D vector: 512 bits, which no register tuple holds, so every
// op on it failed to legalize starting at the load. Unrolling cuts it to two
// quads -- `lo` twice a side, `faddwo` twice, `so` twice.
// CHECK-LABEL: @wide_f32
// CHECK: lvx.faddwo
// CHECK-NOT: vector.load
func.func @wide_f32(%a: memref<64xf32>, %b: memref<64xf32>, %c: memref<64xf32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xf32>, vector<16xf32>
  %y = vector.load %b[%i] : memref<64xf32>, vector<16xf32>
  %z = arith.addf %x, %y : vector<16xf32>
  vector.store %z, %c[%i] : memref<64xf32>, vector<16xf32>
  return
}
