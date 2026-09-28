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
