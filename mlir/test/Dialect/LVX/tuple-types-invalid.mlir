// RUN: mlir-opt %s -split-input-file -verify-diagnostics

// There is no `$r1r2`: pairs are the aligned set, and the type cannot name
// anything else (lvx-mds/docs/MLIR-backend-design.md §8.1).
// expected-error @below {{invalid LVX register pair name 'r1r2'}}
func.func @misaligned_pair(%p: !lvx.pair<r1r2>)

// -----

// expected-error @below {{invalid LVX register quadruple name 'r2r3r4r5'}}
func.func @misaligned_quad(%q: !lvx.quad<r2r3r4r5>)

// -----

// A single's name is not a pair's, and vice versa.
// expected-error @below {{invalid LVX register pair name 'r0'}}
func.func @single_as_pair(%p: !lvx.pair<r0>)

// -----

// expected-error @below {{invalid LVX register name 'r0r1'}}
func.func @pair_as_single(%p: !lvx.reg<r0r1>)
