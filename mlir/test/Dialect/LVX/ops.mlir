// RUN: mlir-opt %s | mlir-opt | FileCheck %s

// CHECK-LABEL: func @scalar_ops
lvx_func.func @scalar_ops(%a: !lvx.reg, %b: !lvx.reg) -> !lvx.reg {
  // CHECK: lvx.li 41 : i64 : !lvx.reg
  %c = lvx.li 41 : i64 : !lvx.reg
  // CHECK: lvx.mv %{{.*}} : (!lvx.reg) -> !lvx.reg
  %m = lvx.mv %c : (!lvx.reg) -> !lvx.reg
  // CHECK: lvx.sp : !lvx.reg<r12>
  %sp = lvx.sp : !lvx.reg<r12>
  // CHECK: lvx.addd %{{.*}}, %{{.*}} : (!lvx.reg, !lvx.reg) -> !lvx.reg
  %0 = lvx.addd %a, %b : (!lvx.reg, !lvx.reg) -> !lvx.reg
  // CHECK: lvx.sbfw %{{.*}}, %{{.*}} : (!lvx.reg, !lvx.reg) -> !lvx.reg
  %1 = lvx.sbfw %a, %b : (!lvx.reg, !lvx.reg) -> !lvx.reg
  // CHECK: lvx.muld %{{.*}}, %{{.*}} : (!lvx.reg, !lvx.reg) -> !lvx.reg
  %2 = lvx.muld %a, %b : (!lvx.reg, !lvx.reg) -> !lvx.reg
  // CHECK: lvx.andd %{{.*}}, %{{.*}} : (!lvx.reg, !lvx.reg) -> !lvx.reg
  %3 = lvx.andd %a, %b : (!lvx.reg, !lvx.reg) -> !lvx.reg
  // CHECK: lvx.slld %{{.*}}, %{{.*}} : (!lvx.reg, !lvx.reg) -> !lvx.reg
  %4 = lvx.slld %a, %b : (!lvx.reg, !lvx.reg) -> !lvx.reg
  // CHECK: %{{.*}}, %{{.*}} = lvx.divmodd %{{.*}}, %{{.*}} : (!lvx.reg, !lvx.reg) -> (!lvx.reg, !lvx.reg)
  %q, %r = lvx.divmodd %a, %b : (!lvx.reg, !lvx.reg) -> (!lvx.reg, !lvx.reg)
  // CHECK: lvx.compd lt %{{.*}}, %{{.*}} : (!lvx.reg, !lvx.reg) -> !lvx.reg
  %5 = lvx.compd lt %a, %b : (!lvx.reg, !lvx.reg) -> !lvx.reg
  // CHECK: lvx.cmoved wnez %{{.*}}, %{{.*}}, %{{.*}} : (!lvx.reg, !lvx.reg, !lvx.reg) -> !lvx.reg
  %6 = lvx.cmoved wnez %5, %a, %b : (!lvx.reg, !lvx.reg, !lvx.reg) -> !lvx.reg
  lvx_func.return %0 : !lvx.reg
}

// CHECK-LABEL: func @float_ops
lvx_func.func @float_ops(%a: !lvx.reg, %b: !lvx.reg, %c: !lvx.reg) -> !lvx.reg {
  // CHECK: lvx.faddd %{{.*}}, %{{.*}} : (!lvx.reg, !lvx.reg) -> !lvx.reg
  %0 = lvx.faddd %a, %b : (!lvx.reg, !lvx.reg) -> !lvx.reg
  // CHECK: lvx.ffmad %{{.*}}, %{{.*}}, %{{.*}} : (!lvx.reg, !lvx.reg, !lvx.reg) -> !lvx.reg
  %1 = lvx.ffmad %a, %b, %c : (!lvx.reg, !lvx.reg, !lvx.reg) -> !lvx.reg
  // CHECK: lvx.fcompd olt %{{.*}}, %{{.*}} : (!lvx.reg, !lvx.reg) -> !lvx.reg
  %2 = lvx.fcompd olt %a, %b : (!lvx.reg, !lvx.reg) -> !lvx.reg
  lvx_func.return %0 : !lvx.reg
}

// CHECK-LABEL: func @memory_ops
lvx_func.func @memory_ops(%base: !lvx.reg, %val: !lvx.reg) -> !lvx.reg {
  // CHECK: lvx.ld %{{.*}}, 8 : (!lvx.reg) -> !lvx.reg
  %0 = lvx.ld %base, 8 : (!lvx.reg) -> !lvx.reg
  // CHECK: lvx.sd %{{.*}}, %{{.*}}, 16 : (!lvx.reg, !lvx.reg)
  lvx.sd %val, %base, 16 : (!lvx.reg, !lvx.reg)
  lvx_func.return %0 : !lvx.reg
}

// CHECK-LABEL: func @casts
lvx_func.func @casts(%a: !lvx.reg) -> !lvx.reg {
  // CHECK: lvx.sxbd %{{.*}} : (!lvx.reg) -> !lvx.reg
  %0 = lvx.sxbd %a : (!lvx.reg) -> !lvx.reg
  // CHECK: lvx.zxwd %{{.*}} : (!lvx.reg) -> !lvx.reg
  %1 = lvx.zxwd %a : (!lvx.reg) -> !lvx.reg
  // CHECK: lvx.fdtofw %{{.*}} : (!lvx.reg) -> !lvx.reg
  %2 = lvx.fdtofw %a : (!lvx.reg) -> !lvx.reg
  // CHECK: lvx.bitcast %{{.*}} : (!lvx.reg) -> !lvx.reg
  %3 = lvx.bitcast %a : (!lvx.reg) -> !lvx.reg
  lvx_func.return %0 : !lvx.reg
}

// CHECK-LABEL: func @registers
lvx_func.func @registers(%a: !lvx.reg<r0>) -> !lvx.reg<r0> {
  // CHECK: !lvx.reg<r5>
  %pinned = lvx.mv %a : (!lvx.reg<r0>) -> !lvx.reg<r5>
  lvx_func.return %a : !lvx.reg<r0>
}
