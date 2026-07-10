// RUN: mlir-opt %s | mlir-opt | FileCheck %s

// CHECK-LABEL: func @loop
lvx_func.func @loop(%lb: !lvx.reg, %ub: !lvx.reg, %step: !lvx.reg, %init: !lvx.reg) -> !lvx.reg {
  // CHECK: lvx_scf.for %{{.*}} : !lvx.reg to %{{.*}} : !lvx.reg step %{{.*}} : !lvx.reg iter_args(%{{.*}}) : (!lvx.reg) -> (!lvx.reg)
  %r = lvx_scf.for %lb : !lvx.reg to %ub : !lvx.reg step %step : !lvx.reg iter_args(%init) : (!lvx.reg) -> (!lvx.reg) {
  ^bb0(%iv: !lvx.reg, %acc: !lvx.reg):
    %next = lvx.addd %acc, %iv : (!lvx.reg, !lvx.reg) -> !lvx.reg
    // CHECK: lvx_scf.yield %{{.*}} : !lvx.reg
    lvx_scf.yield %next : !lvx.reg
  }
  lvx_func.return %r : !lvx.reg
}
