// RUN: mlir-opt %s -convert-to-lvx | FileCheck %s

// CHECK-LABEL: lvx_func.func @loop
func.func @loop(%n: index, %m: memref<10xf64>) {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  // CHECK: lvx_scf.for
  // CHECK-NOT: lvx_cf.br
  scf.for %i = %c0 to %n step %c1 {
    %v = memref.load %m[%i] : memref<10xf64>
    // CHECK: lvx.faddd
    %v2 = arith.addf %v, %v : f64
    memref.store %v2, %m[%i] : memref<10xf64>
  }
  // CHECK: lvx_func.return
  return
}

// CHECK-LABEL: lvx_func.func @branches
func.func @branches(%cond: i1, %a: i64, %b: i64) -> i64 {
  // CHECK: lvx_cf.cond_br wnez
  cf.cond_br %cond, ^bb1(%a : i64), ^bb2(%b : i64)
^bb1(%x: i64):
  // CHECK: lvx_cf.br
  cf.br ^bb2(%x : i64)
^bb2(%y: i64):
  return %y : i64
}
