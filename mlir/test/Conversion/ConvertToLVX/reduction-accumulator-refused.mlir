// RUN: mlir-opt %s -convert-to-lvx -verify-diagnostics -o /dev/null

// Without the bridge the accumulator is *refused*, not dropped. This is the
// regression test for the wrong-code bug: the op used to legalize here and
// lose the accumulator silently, so the thing worth pinning is that it fails.
func.func @acc_unfolded(%a: memref<4xi32>, %c: memref<4xi32>, %acc: i32) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<4xi32>, vector<4xi32>
  // expected-error @+2 {{a vector.reduction accumulator is not lowered here}}
  // expected-error @+1 {{failed to legalize operation 'vector.reduction'}}
  %r = vector.reduction <add>, %x, %acc : vector<4xi32> into i32
  memref.store %r, %c[%i] : memref<4xi32>
  return
}
