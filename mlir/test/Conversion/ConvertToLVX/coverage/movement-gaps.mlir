// RUN: mlir-opt %s -split-input-file -verify-diagnostics -convert-to-lvx -o /dev/null

// Class-D data-movement rows: no lowering today. Each `expected-error`
// pins the gap -- when a pattern or an instruction arrives, this test fails
// and the row moves to movement.mlir. See README.md.

// A 64-bit lane of a pinned pair *is* a register (lvx-mds/docs/
// MLIR-backend-design.md §8.1), and `lvx.lane` is the pseudo that names it,
// so this should cost nothing -- but no pattern maps `vector.extract` to it
// yet. Phase 3.
// ROW: vector.extract | i64x2
func.func @extract_i64x2(%a: memref<4xi64>) -> i64 {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<4xi64>, vector<2xi64>
  // expected-error @below {{failed to legalize operation 'vector.extract'}}
  %s = vector.extract %x[1] : i64 from vector<2xi64>
  return %s : i64
}

// -----

// A narrower lane is not a register: it is a field of one, so this is
// `extfzd`/`extfsd` on the single that holds it (Phase 3).
// ROW: vector.extract | f32x4
func.func @extract_f32x4(%a: memref<8xf32>) -> f32 {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xf32>, vector<4xf32>
  // expected-error @below {{failed to legalize operation 'vector.extract'}}
  %s = vector.extract %x[2] : f32 from vector<4xf32>
  return %s : f32
}

// -----

// ROW: vector.insert | i64x2
func.func @insert_i64x2(%a: memref<4xi64>, %c: memref<4xi64>, %s: i64) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<4xi64>, vector<2xi64>
  // expected-error @below {{failed to legalize operation 'vector.insert'}}
  %y = vector.insert %s, %x[1] : i64 into vector<2xi64>
  vector.store %y, %c[%i] : memref<4xi64>, vector<2xi64>
  return
}

// -----

// ROW: vector.shuffle | f32x4
func.func @shuffle_f32x4(%a: memref<8xf32>, %b: memref<8xf32>, %c: memref<8xf32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xf32>, vector<4xf32>
  %y = vector.load %b[%i] : memref<8xf32>, vector<4xf32>
  // expected-error @below {{failed to legalize operation 'vector.shuffle'}}
  %z = vector.shuffle %x, %y [3, 2, 1, 0] : vector<4xf32>, vector<4xf32>
  vector.store %z, %c[%i] : memref<8xf32>, vector<4xf32>
  return
}

// `vector.transpose` and the other rank-2 ops have no row here: a rank-2
// vector has no register type at all (the converter takes rank 1 only), so
// they must be flattened upstream -- `-convert-vector-to-scf`, the vector
// transpose lowering patterns -- and what reaches `-convert-to-lvx` is the
// 1-D shuffles they become. Phase 3 measures those, not the rank-2 op.
