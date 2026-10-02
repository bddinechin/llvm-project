// RUN: mlir-opt %s -convert-to-lvx -verify-diagnostics -split-input-file

// The two shapes of `scf.if` that `IfToLVX` does not lower, each pinned as a
// *diagnostic* test because the natural failure is useless on its own: the
// framework would say only "failed to legalize operation 'scf.if'", sending
// the reader to look for a pattern that is in fact present and deliberate.

// An `scf.if` inside a loop has no lowering yet, and the reason is structural
// rather than a missing pattern: `lvx_scf.for` is a single-block region by
// construction -- that is what lets the allocator coalesce the loop-carried
// values, and it survives until `-lvx-scf-to-cf` lowers it after allocation --
// so the branch diamond `IfToLVX` would build cannot live in its body.
//
// Pinned as a *diagnostic* test because the natural failure is useless: the
// framework would say only "failed to legalize operation 'scf.if'", sending
// the reader to look for a pattern that is in fact present and deliberate.
// The structured `lvx_scf.if` that would carry this is the documented next
// step (lvx-mlir/docs/IfConversion.md, "Reachability").
func.func @if_in_loop(%a: memref<64xi32>, %b: memref<64xi32>,
                      %f: memref<16xi32>, %n: index) {
  %c0 = arith.constant 0 : index
  %c4 = arith.constant 4 : index
  %z = arith.constant 0 : i32
  scf.for %i = %c0 to %n step %c4 {
    %x = vector.load %a[%i] : memref<64xi32>, vector<4xi32>
    %g = memref.load %f[%i] : memref<16xi32>
    %c = arith.cmpi ne, %g, %z : i32
    // Two diagnostics: the explanation, then the framework's own failure --
    // the pattern declines after saying why, and `scf.if` has no other
    // pattern to try.
    // expected-error @+2 {{an scf.if inside a loop is not lowered yet}}
    // expected-error @+1 {{failed to legalize operation 'scf.if'}}
    scf.if %c {
      vector.store %x, %b[%i] : memref<64xi32>, vector<4xi32>
    }
  }
  return
}

// -----

// A result is a phi at the join, which on LVX is a select and not a branch:
// `arith.select` is one `cmoved`/`blend*`, and `-canonicalize` turns a
// result-carrying `scf.if` with pure arms into exactly that. Lowering it to a
// diamond here would also hit a conversion-framework limit -- a pattern
// cannot get the *converted* operands of a yield in a region it is inlining,
// so the originals leave an unresolved `!lvx.reg`-to-`i32` materialization
// alive past the conversion.
func.func @if_with_result(%a: memref<4xi32>, %c: i1) -> i32 {
  %i = arith.constant 0 : index
  %x = memref.load %a[%i] : memref<4xi32>
  // expected-error @+2 {{an scf.if with results is not lowered}}
  // expected-error @+1 {{failed to legalize operation 'scf.if'}}
  %r = scf.if %c -> i32 {
    scf.yield %x : i32
  } else {
    %z = arith.constant 0 : i32
    scf.yield %z : i32
  }
  return %r : i32
}
