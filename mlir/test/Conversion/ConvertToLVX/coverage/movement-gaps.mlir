// RUN: mlir-opt %s -split-input-file -verify-diagnostics -convert-to-lvx -o /dev/null

// Class-D data-movement rows: no lowering today. Each `expected-error`
// pins the gap -- when a pattern or an instruction arrives, this test fails
// and the row moves to movement.mlir. See README.md.

// A mask the ISA cannot read: it crosses register boundaries and is neither
// the even lanes, the odd lanes, nor the perfect shuffle. Reversing a vector
// is the canonical example -- the yardstick's answer is a general permute or
// a table lookup (NEON `TBL`, SVE `TBL`/`REV`), which LVX has not got.
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

// -----

// A dynamic lane index has no lowering: the unit it selects is a *register*,
// so it needs a select over the units plus a bit-field extract at a computed
// position -- and the ISA's `extfzd` takes its position as an immediate.
// See docs/VectorCoverage.md §7 (register forms of EXTFZD/INSFD).
// ROW: vector.extract(dynamic) | f32x4
func.func @extract_dynamic_f32x4(%a: memref<8xf32>, %k: index) -> f32 {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xf32>, vector<4xf32>
  // expected-error @below {{failed to legalize operation 'vector.extract'}}
  %s = vector.extract %x[%k] : f32 from vector<4xf32>
  return %s : f32
}

// `vector.transpose` and the other rank-2 ops have no row here: a rank-2
// vector has no register type at all (the converter takes rank 1 only), so
// they must be flattened upstream -- `-convert-vector-to-scf`, the vector
// transpose lowering patterns -- and what reaches `-convert-to-lvx` is the
// 1-D shuffles they become. Phase 3 measures those, not the rank-2 op.
