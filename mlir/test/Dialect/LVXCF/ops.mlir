// RUN: mlir-opt %s | mlir-opt | FileCheck %s

// CHECK-LABEL: func @branches
lvx_func.func @branches(%a: !lvx.reg) -> !lvx.reg {
  // CHECK: lvx_cf.br ^{{.*}}(%{{.*}} : !lvx.reg)
  lvx_cf.br ^bb1(%a : !lvx.reg)
^bb1(%x: !lvx.reg):
  // CHECK: lvx_cf.cond_br wnez %{{.*}} : !lvx.reg, ^{{.*}}(%{{.*}} : !lvx.reg), ^{{.*}}(%{{.*}} : !lvx.reg)
  lvx_cf.cond_br wnez %x : !lvx.reg, ^bb2(%x : !lvx.reg), ^bb3(%x : !lvx.reg)
^bb2(%y: !lvx.reg):
  lvx_func.return %y : !lvx.reg
^bb3(%z: !lvx.reg):
  lvx_func.return %z : !lvx.reg
}
