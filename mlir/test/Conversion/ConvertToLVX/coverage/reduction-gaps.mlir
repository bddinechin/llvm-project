// RUN: mlir-opt %s -split-input-file -verify-diagnostics \
// RUN:   --pass-pipeline='builtin.module(func.func(lvx-lower-vector-transfers),convert-to-lvx,any(lvx-combine),cse)' -o /dev/null

// `vector.contract` at *float* lanes, which is class D for a reason that is
// not an ISA gap: a reduction tree reassociates, and a float reduction may
// only be reassociated when the op says so (§4). `vector.contract` carries no
// `fastmath`, so the `vector.reduction` it decomposes into has none either and
// the tree lowering declines -- leaving the sequential lane chain, which
// upstream has to unroll.
//
// The integer form lowers and is measured; this is the float half of the same
// row. Recorded rather than left open, because "no row" would read as "not
// looked at".

// ROW: vector.contract | f32x4
#d = affine_map<(d0) -> (d0)>
#s = affine_map<(d0) -> ()>
func.func @contract_f32x4(%a: memref<64xf32>, %b: memref<64xf32>,
                          %c: memref<64xf32>, %acc: f32) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xf32>, vector<4xf32>
  %y = vector.load %b[%i] : memref<64xf32>, vector<4xf32>
  // expected-error @below {{failed to legalize operation 'vector.reduction'}}
  %r = vector.contract {indexing_maps = [#d, #d, #s],
                        iterator_types = ["reduction"],
                        kind = #vector.kind<add>} %x, %y, %acc
       : vector<4xf32>, vector<4xf32> into f32
  memref.store %r, %c[%i] : memref<64xf32>
  return
}

// -----

// `vector.multi_reduction` at float lanes, class D for a sharper version of
// the same reason -- and this one is structural rather than incidental: the op
// **has no `fastmath` attribute at all** (its assembly format is
// `$kind , $source , $acc attr-dict $reduction_dims`), so it cannot carry
// `reassoc` even when the author wants to permit it. A float reduction tree
// therefore always declines here, and the only route is upstream's unrolling
// into a sequential lane chain.
//
// The integer form lowers and is measured. Worth recording because the fix is
// not in this repo: it needs the upstream op to gain the attribute, or the
// bridge to infer permission from somewhere else.

// Reducing 4x4 to 4 rather than 2x4 to 2: a `vector<2xf32>` is 64 bits, and
// 64-bit vectors are not a shape this back end has -- §5 records the retired
// family as deliberately not a gap -- so that accumulator would have failed
// on its own constant and attributed the row to the wrong op.
// ROW: vector.multi_reduction | f32x4
func.func @multi_reduction_f32x4(%a: memref<64xf32>, %c: memref<64xf32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xf32>, vector<16xf32>
  %s = vector.shape_cast %x : vector<16xf32> to vector<4x4xf32>
  %z = arith.constant dense<0.0> : vector<4xf32>
  // expected-error @below {{failed to legalize operation 'vector.reduction'}}
  %r = vector.multi_reduction <add>, %s, %z [1] : vector<4x4xf32> to vector<4xf32>
  vector.store %r, %c[%i] : memref<64xf32>, vector<4xf32>
  return
}
