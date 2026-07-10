// RUN: mlir-opt %s -convert-to-lvx | FileCheck %s

// CHECK-LABEL: lvx_func.func @load_store
func.func @load_store(%m: memref<10x20xf64>, %i: index, %j: index) {
  // CHECK-DAG: lvx.li {{.*}}160
  // CHECK-DAG: lvx.muld
  // CHECK-DAG: lvx.addd
  // CHECK: lvx.ld
  %0 = memref.load %m[%i, %j] : memref<10x20xf64>
  // CHECK: lvx.sd
  memref.store %0, %m[%i, %j] : memref<10x20xf64>
  return
}

// CHECK-LABEL: lvx_func.func @load_i32
func.func @load_i32(%m: memref<4xi32>, %i: index) -> i32 {
  // CHECK: lvx.lwz
  %0 = memref.load %m[%i] : memref<4xi32>
  return %0 : i32
}
