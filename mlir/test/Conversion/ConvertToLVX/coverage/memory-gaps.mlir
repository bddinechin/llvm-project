// RUN: mlir-opt %s -split-input-file -verify-diagnostics -convert-to-lvx -o /dev/null

// Class-D memory rows: no lowering with today's ISA. Each row's
// `expected-error` is what pins the gap -- when the instruction arrives,
// this test fails and the row moves to memory.mlir. See README.md.

// The broadcast of a loaded element to a *pair* has no load-and-splat
// (there is no `lwsq`), so it stays a load plus a `splatwq` -- which does
// lower. What has no lowering is a broadcast of a loaded element whose
// scalar is also used: the fold requires the load to have no other use.
// (Not a gap, a deliberate choice -- see ConvertToLVX.cpp.)

// ROW: vector.gather | f32x4
func.func @gather_f32x4(%a: memref<8xf32>, %c: memref<8xf32>, %idx: vector<4xi32>, %m: vector<4xi1>, %p: vector<4xf32>) {
  %i = arith.constant 0 : index
  // expected-error @below {{failed to legalize operation 'vector.gather'}}
  %x = vector.gather %a[%i] [%idx], %m, %p : memref<8xf32>, vector<4xi32>, vector<4xi1>, vector<4xf32> into vector<4xf32>
  vector.store %x, %c[%i] : memref<8xf32>, vector<4xf32>
  return
}
