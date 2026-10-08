// RUN: mlir-opt %s -convert-to-lvx -split-input-file -verify-diagnostics | FileCheck %s

// `vector.create_mask` is one `taild` (lvx-mds f0bf233): lane *i* iff
// `base + i <u bound`, bits above the `lanecount` cleared. The base is a
// materialised zero, and the `maxd_i` is the lower clamp `create_mask`
// requires and `taild`'s unsigned compare does not give -- see the pattern's
// comment in ConvertToLVX.cpp and examples/vmask_harness.c, which executes
// the negative case on the ISS.

// CHECK-LABEL: @mask4
// CHECK: lvx.maxd_i %{{.*}}, 0
// CHECK: lvx.li 0
// CHECK: lvx.taild v4
// CHECK-NOT: lvx.slld
func.func @mask4(%a: memref<8xf32>, %c: memref<8xf32>, %n: index) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xf32>, vector<4xf32>
  %y = vector.load %c[%i] : memref<8xf32>, vector<4xf32>
  %m = vector.create_mask %n : vector<4xi1>
  %z = arith.select %m, %x, %y : vector<4xi1>, vector<4xf32>
  vector.store %z, %c[%i] : memref<8xf32>, vector<4xf32>
  return
}

// -----

// The widest mask a register holds is 32 lanes -- `i8x32` in a quad -- and
// the modifier goes with it.
// CHECK-LABEL: @mask32
// CHECK: lvx.taild v32
func.func @mask32(%a: memref<32xi8>, %c: memref<32xi8>, %n: index) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<32xi8>, vector<32xi8>
  %y = vector.load %c[%i] : memref<32xi8>, vector<32xi8>
  %m = vector.create_mask %n : vector<32xi1>
  %z = arith.select %m, %x, %y : vector<32xi1>, vector<32xi8>
  vector.store %z, %c[%i] : memref<32xi8>, vector<32xi8>
  return
}

// -----

// A lane count the converter will not place must be refused, not built on.
// This is the case that caught a real crash: `convertType`'s first rule is an
// identity fallback, so it answers with the *vector* type for a shape it
// cannot place rather than with null, and a `!regTy` test passes. The ops
// then get a vector type where the generated builder casts to
// `TypedValue<RegisterType>`, and that asserts. Asking `dyn_cast` for the
// register type is the fix, and it subsumes any lane-count guard: 64 lanes is
// refused here because the converter caps a mask at 32, not because a shift
// by 64 would be undefined.
// expected-error @+2 {{failed to legalize operation 'vector.create_mask'}}
func.func @mask64(%n: index, %o: memref<8xi64>) {
  %m = vector.create_mask %n : vector<64xi1>
  %b = vector.bitcast %m : vector<64xi1> to vector<1xi64>
  %e = vector.extract %b[0] : i64 from vector<1xi64>
  %i = arith.constant 0 : index
  memref.store %e, %o[%i] : memref<8xi64>
  return
}
