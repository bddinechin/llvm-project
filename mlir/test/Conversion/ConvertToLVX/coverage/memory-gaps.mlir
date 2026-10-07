// RUN: mlir-opt %s -split-input-file -verify-diagnostics \
// RUN:   --pass-pipeline='builtin.module(func.func(lvx-lower-vector-transfers),convert-to-lvx,any(lvx-combine),cse)' -o /dev/null

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

// -----

// Phase 6's memory family, all class D, and all for the same reason: LVX has
// no gather, scatter, expanding load or compressing store at any width. KVX
// has none either; SVE does, which is what makes them worth recording rather
// than dismissing -- §7 ranks them against the kernels that would use them.
//
// These rows are only honest now that a constant mask vector lowers. Before
// that the chunk failed on its own `arith.constant` -- the i1 mask -- and the
// row would have been attributed to the wrong op entirely.

// ROW: vector.gather | i32x4
func.func @vector_gather_i32x4(%a: memref<64xi32>, %c: memref<64xi32>) {
  %i = arith.constant 0 : index
  %m = arith.constant dense<[true, false, true, true]> : vector<4xi1>
  %p = arith.constant dense<0> : vector<4xi32>
  %idx = arith.constant dense<[0, 3, 7, 11]> : vector<4xi32>
  // expected-error @below {{failed to legalize operation 'vector.gather'}}
  %g = vector.gather %a[%i] [%idx], %m, %p
       : memref<64xi32>, vector<4xi32>, vector<4xi1>, vector<4xi32> into vector<4xi32>
  vector.store %g, %c[%i] : memref<64xi32>, vector<4xi32>
  return
}

// -----

// ROW: vector.scatter | i32x4
func.func @vector_scatter_i32x4(%a: memref<64xi32>, %c: memref<64xi32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xi32>, vector<4xi32>
  %m = arith.constant dense<[true, false, true, true]> : vector<4xi1>
  %idx = arith.constant dense<[0, 3, 7, 11]> : vector<4xi32>
  // expected-error @below {{failed to legalize operation 'vector.scatter'}}
  vector.scatter %c[%i] [%idx], %m, %x
      : memref<64xi32>, vector<4xi32>, vector<4xi1>, vector<4xi32>
  return
}

// -----

// ROW: vector.scatter | f32x4
func.func @vector_scatter_f32x4(%a: memref<64xf32>, %c: memref<64xf32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xf32>, vector<4xf32>
  %m = arith.constant dense<[true, false, true, true]> : vector<4xi1>
  %idx = arith.constant dense<[0, 3, 7, 11]> : vector<4xi32>
  // expected-error @below {{failed to legalize operation 'vector.scatter'}}
  vector.scatter %c[%i] [%idx], %m, %x
      : memref<64xf32>, vector<4xi32>, vector<4xi1>, vector<4xf32>
  return
}

// -----

// ROW: vector.expandload | f32x4
func.func @vector_expandload_f32x4(%a: memref<64xf32>, %c: memref<64xf32>) {
  %i = arith.constant 0 : index
  %m = arith.constant dense<[true, false, true, true]> : vector<4xi1>
  %p = arith.constant dense<0.0> : vector<4xf32>
  // expected-error @below {{failed to legalize operation 'vector.expandload'}}
  %g = vector.expandload %a[%i], %m, %p
       : memref<64xf32>, vector<4xi1>, vector<4xf32> into vector<4xf32>
  vector.store %g, %c[%i] : memref<64xf32>, vector<4xf32>
  return
}

// -----

// ROW: vector.compressstore | f32x4
func.func @vector_compressstore_f32x4(%a: memref<64xf32>, %c: memref<64xf32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<64xf32>, vector<4xf32>
  %m = arith.constant dense<[true, false, true, true]> : vector<4xi1>
  // expected-error @below {{failed to legalize operation 'vector.compressstore'}}
  vector.compressstore %c[%i], %m, %x
      : memref<64xf32>, vector<4xi1>, vector<4xf32>
  return
}
