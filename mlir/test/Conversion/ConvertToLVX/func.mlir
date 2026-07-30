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

// A call's operands/results are pinned to the ABI's argument/result
// registers (r0-r11/r0-r3), same as a function's own entry/exit -- see
// `CallToLVX` in ConvertToLVX.cpp. Without this, register allocation is
// free to assign a call's operands/results to whatever's convenient, not
// necessarily what the callee actually expects/produces.
// CHECK-LABEL: lvx_func.func @caller
func.func @caller(%x: i64, %y: i64) -> i64 {
  // CHECK: %[[X:.*]] = lvx.mv %{{.*}} : (!lvx.reg) -> !lvx.reg<r0>
  // CHECK: %[[Y:.*]] = lvx.mv %{{.*}} : (!lvx.reg) -> !lvx.reg<r1>
  // CHECK: %[[R:.*]] = lvx_func.call @callee(%[[X]], %[[Y]]) : (!lvx.reg<r0>, !lvx.reg<r1>) -> !lvx.reg<r0>
  // CHECK: lvx.mv %[[R]] : (!lvx.reg<r0>) -> !lvx.reg
  %0 = func.call @callee(%x, %y) : (i64, i64) -> i64
  return %0 : i64
}
