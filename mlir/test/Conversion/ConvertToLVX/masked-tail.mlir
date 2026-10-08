// RUN: mlir-opt %s -lvx-lower-vector-transfers | FileCheck %s --check-prefix=BRIDGE
// RUN: mlir-opt %s -lvx-lower-vector-transfers -canonicalize -cse -convert-to-lvx | FileCheck %s

// The masked tail of a vectorised loop. `vector.transfer_read`/`write` are
// out-of-bounds *by default* -- absent an `in_bounds` attribute they are
// assumed to run off the end -- and `affine-super-vectorize` leaves them that
// way when it strip-mines a loop whose trip count does not divide the vector
// length. 13 elements by 4 lanes: the last iteration has one live lane.
//
// Until 2026-10-08 this did not lower at all. Upstream's
// `TransferReadToVectorLoadLowering` declines an out-of-bounds transfer
// ("out-of-bounds needs mask") and `-convert-to-lvx` had no pattern for what
// was left, so only exact multiples of the vector length vectorised.
//
// The mask is `create_mask(dim - offset)` and stays that way: we materialize
// it ourselves rather than through upstream's
// `populateVectorMaskMaterializationPatterns`, which bundles a pattern that
// rewrites every 1-D `create_mask` into `broadcast(n) sgt [0,1,2,...]` -- an
// index-vector comparison on `vector<4xi64>`, a *quad*, to produce a 4-lane
// mask. LVX has `taild`.

// BRIDGE-LABEL: @tail13
// BRIDGE: arith.subi
// BRIDGE: vector.create_mask
// BRIDGE: vector.maskedload
// BRIDGE: vector.maskedload
// BRIDGE: vector.maskedstore
// BRIDGE-NOT: vector.transfer_read
// BRIDGE-NOT: arith.cmpi

// One `taild` for the mask, one `extb4d` to byte enables, and the accesses.
// No `blendwq`: the `pass_thru` is the transfer's padding, which is
// `ub.poison` here, so the lanes `maskm` zeroes are unconstrained and need no
// restoring -- any value refines poison.
// CHECK-LABEL: @tail13
// CHECK: lvx.taild v4
// CHECK: lvx.extb4d
// CHECK: lvx.masked_load
// CHECK: lvx.masked_store
// CHECK-NOT: lvx.blendwq
func.func @tail13(%a: memref<13xf32>, %b: memref<13xf32>, %s: f32) {
  %c0 = arith.constant 0 : index
  %c4 = arith.constant 4 : index
  %c13 = arith.constant 13 : index
  %pad = ub.poison : f32
  %sv = vector.broadcast %s : f32 to vector<4xf32>
  scf.for %i = %c0 to %c13 step %c4 {
    %x = vector.transfer_read %a[%i], %pad : memref<13xf32>, vector<4xf32>
    %y = vector.transfer_read %b[%i], %pad : memref<13xf32>, vector<4xf32>
    %m = arith.mulf %x, %sv : vector<4xf32>
    %z = arith.addf %y, %m : vector<4xf32>
    vector.transfer_write %z, %b[%i] : vector<4xf32>, memref<13xf32>
  }
  return
}

// -----

// A transfer declared `in_bounds` keeps the plain access: nothing is paid for
// a tail that does not exist.
//
// Note what drives this. It is the attribute, not divisibility -- a transfer
// without `in_bounds` is out-of-bounds *by definition*, so a hand-written one
// gets masked even over a memref the trip count divides. What makes the
// divisible case cheap is that `affine-super-vectorize` proves in-boundedness
// and says so: measured, it emits `in_bounds = [true]` on all three transfers
// at 12 elements and omits it at 13. So the mask appears exactly where the
// vectorizer could not rule the tail out.
// CHECK-LABEL: @exact12
// CHECK: lvx.lq
// CHECK-NOT: lvx.taild
// CHECK-NOT: lvx.masked_load
func.func @exact12(%a: memref<12xf32>, %b: memref<12xf32>, %s: f32) {
  %c0 = arith.constant 0 : index
  %c4 = arith.constant 4 : index
  %c12 = arith.constant 12 : index
  %pad = ub.poison : f32
  %sv = vector.broadcast %s : f32 to vector<4xf32>
  scf.for %i = %c0 to %c12 step %c4 {
    %x = vector.transfer_read %a[%i], %pad {in_bounds = [true]}
        : memref<12xf32>, vector<4xf32>
    %m = arith.mulf %x, %sv : vector<4xf32>
    vector.transfer_write %m, %b[%i] {in_bounds = [true]}
        : vector<4xf32>, memref<12xf32>
  }
  return
}
