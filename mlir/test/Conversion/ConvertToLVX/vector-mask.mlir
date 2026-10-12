// RUN: mlir-opt %s --pass-pipeline='builtin.module(func.func(lvx-lower-vector-transfers))' \
// RUN:   | mlir-opt -convert-to-lvx -lvx-combine -cse | FileCheck %s

// `vector.mask`, the region wrapper, is Phase 2's last item
// (docs/VectorCoverage.md). It needed no new lowering: `-lvx-if-convert`'s
// investigation established that `linalg` vectorization expresses a
// conditional as `vector.mask` and never as a branch, and this back end
// already takes a mask as an *operand* -- `lvx.masked_load`/`masked_store`
// do. So the bridge unwraps the region into that operand and the existing
// path takes it from there.
//
// The ordering inside the bridge is what matters and is pinned here by the
// pipeline: unroll first (those patterns understand masked ops and re-wrap
// each piece, so splitting an oversized masked transfer has to happen while
// the wrapper is still there), then unwrap, then lower the transfers (that
// stage reads the mask as an operand and has nothing to say about a region).

// A masked read and a masked write at the same mask -- what a loop whose trip
// count does not divide the vector length looks like after vectorization.
// `extb4d` widens the lane mask to the byte mask `maskm` wants, since the LSU
// block has no room to encode a lane size.
// CHECK-LABEL: @masked_copy
// CHECK-NOT: vector.mask
// CHECK: lvx.extb4d
// CHECK: lvx.masked_load
// CHECK: lvx.masked_store
func.func @masked_copy(%a: memref<8xf32>, %b: memref<8xf32>, %n: index) {
  %i = arith.constant 0 : index
  %p = arith.constant 0.0 : f32
  %m = vector.create_mask %n : vector<4xi1>
  %x = vector.mask %m {
    vector.transfer_read %a[%i], %p : memref<8xf32>, vector<4xf32>
  } : vector<4xi1> -> vector<4xf32>
  vector.mask %m {
    vector.transfer_write %x, %b[%i] : vector<4xf32>, memref<8xf32>
  } : vector<4xi1>
  return
}

// -----

// A masked write alone, at i32 lanes: one mask widening and one masked store.
// CHECK-LABEL: @masked_store_only
// CHECK-NOT: vector.mask
// CHECK: lvx.masked_store
func.func @masked_store_only(%b: memref<8xi32>, %v: vector<4xi32>, %n: index) {
  %i = arith.constant 0 : index
  %m = vector.create_mask %n : vector<4xi1>
  vector.mask %m {
    vector.transfer_write %v, %b[%i] : vector<4xi32>, memref<8xi32>
  } : vector<4xi1>
  return
}

// -----

// A masked reduction. `vector.reduction` is maskable, and the mask has to
// reach it as an operand or the inactive lanes would join the fold; upstream's
// lowering is what puts it there, and the reduction tree of Phase 4 follows.
//
// The bridge pads the inactive lanes with the fold's identity, which for
// `add` is zero -- so this is one `blendzwq`, the zeroing blend (lvx-mds
// e953588): no zero vector is built for it and it reads no destination, where
// a `blendwq` would need both. One instruction against three.
// CHECK-LABEL: @masked_reduce
// CHECK-NOT: vector.mask
// CHECK: lvx.blendzwq
// CHECK-NOT: lvx.blendwq
func.func @masked_reduce(%a: memref<8xi32>, %n: index) -> i32 {
  %i = arith.constant 0 : index
  %z = arith.constant 0 : i32
  %x = vector.load %a[%i] : memref<8xi32>, vector<4xi32>
  %m = vector.create_mask %n : vector<4xi1>
  %r = vector.mask %m {
    vector.reduction <add>, %x : vector<4xi32> into i32
  } : vector<4xi1> -> i32
  return %r : i32
}

// -----

// The contrast, and why `blendz*` is a choice rather than the lowering of
// every masked select: `min`'s identity is INT_MAX, not zero, so the padding
// is a real vector and the select stays a destination-reading `blendwq`.
// Only a zero (or poison) false value is a zeroing blend.
// CHECK-LABEL: @masked_reduce_min
// CHECK-NOT: vector.mask
// CHECK: lvx.blendwq
// CHECK-NOT: lvx.blendzwq
func.func @masked_reduce_min(%a: memref<8xi32>, %n: index) -> i32 {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xi32>, vector<4xi32>
  %m = vector.create_mask %n : vector<4xi1>
  %r = vector.mask %m {
    vector.reduction <minsi>, %x : vector<4xi32> into i32
  } : vector<4xi1> -> i32
  return %r : i32
}
