// RUN: mlir-opt %s -convert-to-lvx | FileCheck %s

// CHECK-LABEL: lvx_func.func @callee
// CHECK-SAME: (%{{.*}}: !lvx.reg<r0>, %{{.*}}: !lvx.reg<r1>) -> !lvx.reg<r0>
func.func @callee(%a: i64, %b: i64) -> i64 {
  // CHECK: lvx.mv
  // CHECK: lvx.mv
  // CHECK: lvx.addd
  %0 = arith.addi %a, %b : i64
  // CHECK: lvx_func.return
  return %0 : i64
}

// CHECK-LABEL: lvx_func.func @caller
func.func @caller(%x: i64, %y: i64) -> i64 {
  // CHECK: lvx_func.call @callee(%{{.*}}, %{{.*}}) : (!lvx.reg, !lvx.reg) -> !lvx.reg
  %0 = func.call @callee(%x, %y) : (i64, i64) -> i64
  return %0 : i64
}
