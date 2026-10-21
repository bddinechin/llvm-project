// RUN: mlir-opt %s --pass-pipeline='builtin.module(any(lvx-uncached-loads))' | FileCheck %s

// A load is uncached when its address varies with its innermost loop, and only
// then: one whose address varies only with an enclosing loop reads the same
// line on every inner trip, which is the reuse L1 exists for.

// CHECK-LABEL: lvx_func.func @nest
lvx_func.func @nest(%arg0: !lvx.reg<r0>, %arg1: !lvx.reg<r1>) {
  %a = lvx.mv %arg0 : (!lvx.reg<r0>) -> !lvx.reg
  %b = lvx.mv %arg1 : (!lvx.reg<r1>) -> !lvx.reg
  %c0 = lvx.li 0 : index : !lvx.reg
  %c1 = lvx.li 1 : index : !lvx.reg
  %c8 = lvx.li 8 : index : !lvx.reg
  // Outside any loop: nothing to stream.
  // CHECK: lvx.lwz %{{[0-9]+}}, 0
  %x = lvx.lwz %a, 0 : i64 : (!lvx.reg) -> !lvx.reg
  lvx_scf.for %c0 : !lvx.reg to %c8 : !lvx.reg step %c1 : !lvx.reg {
  ^bb0(%j: !lvx.reg):
    %pj = lvx.addx4d %j, %a : (!lvx.reg, !lvx.reg) -> !lvx.reg
    // Varies with `j`, its innermost loop: uncached.
    // CHECK: lvx.lwz u %{{[0-9]+}}, 0
    %y = lvx.lwz %pj, 0 : i64 : (!lvx.reg) -> !lvx.reg
    lvx_scf.for %c0 : !lvx.reg to %c8 : !lvx.reg step %c1 : !lvx.reg {
    ^bb0(%k: !lvx.reg):
      // Varies with `j` but not with `k`, its innermost loop: cached, the
      // same line on every `k` trip.
      // CHECK: lvx.lwz %{{[0-9]+}}, 0
      %z = lvx.lwz %pj, 0 : i64 : (!lvx.reg) -> !lvx.reg
      // Varies with `k`: uncached.
      %pk = lvx.addx4d %k, %b : (!lvx.reg, !lvx.reg) -> !lvx.reg
      // CHECK: lvx.lwz u %{{[0-9]+}}, 0
      %w = lvx.lwz %pk, 0 : i64 : (!lvx.reg) -> !lvx.reg
      %s = lvx.addw %z, %w : (!lvx.reg, !lvx.reg) -> !lvx.reg
      lvx.sw %s, %pj, 0 : i64 : (!lvx.reg, !lvx.reg)
    }
  }
  lvx_func.return
}
