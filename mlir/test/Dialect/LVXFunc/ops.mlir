// RUN: mlir-opt %s | mlir-opt | FileCheck %s

// CHECK-LABEL: lvx_func.func @callee
lvx_func.func @callee(%a: !lvx.reg<r0>, %b: !lvx.reg<r1>) -> !lvx.reg<r0> {
  %m = lvx.mv %a : (!lvx.reg<r0>) -> !lvx.reg
  %m2 = lvx.mv %m : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %m2 : !lvx.reg<r0>
}

// CHECK-LABEL: lvx_func.func @caller
lvx_func.func @caller(%x: !lvx.reg<r0>, %y: !lvx.reg<r1>) -> !lvx.reg<r0> {
  %x2 = lvx.mv %x : (!lvx.reg<r0>) -> !lvx.reg
  %y2 = lvx.mv %y : (!lvx.reg<r1>) -> !lvx.reg
  // CHECK: lvx_func.call @callee(%{{.*}}, %{{.*}}) : (!lvx.reg, !lvx.reg) -> !lvx.reg
  %r = lvx_func.call @callee(%x2, %y2) : (!lvx.reg, !lvx.reg) -> !lvx.reg
  %r2 = lvx.mv %r : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %r2 : !lvx.reg<r0>
}

// CHECK-LABEL: lvx_func.func private @declared
lvx_func.func private @declared(!lvx.reg<r0>) -> !lvx.reg<r0>
