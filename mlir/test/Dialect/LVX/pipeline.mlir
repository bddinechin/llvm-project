// RUN: mlir-opt %s -lvx-pipeline -split-input-file | FileCheck %s
// RUN: mlir-opt %s -lvx-pipeline -split-input-file -verify-diagnostics -o /dev/null

// Software pipelining from a stage assignment. See
// lvx-mlir/docs/SoftwarePipelining.md §§4-6.

// Two stages: the load runs an iteration ahead of the add that consumes it.
// One load is peeled into the prologue, the kernel loads iteration `t` while
// adding iteration `t-1`, and one add drains -- four loads and four adds for
// four iterations, as before.
//
// The two values in flight become iter_args: the load's result, and the
// accumulator (which crosses the back edge even though it is defined and read
// in the same stage).
// CHECK-LABEL: lvx_func.func @acc
// CHECK: %[[PRO:.*]] = lvx.ld
// CHECK: %[[LB:.*]] = lvx.li 1
// CHECK: %[[K:.*]]:2 = lvx_scf.for %[[LB]]
// CHECK-SAME: iter_args(%{{.*}}, %[[PRO]])
// CHECK-NEXT: ^bb0(%{{.*}}: !lvx.reg, %[[A:.*]]: !lvx.reg, %[[V:.*]]: !lvx.reg)
// The add issues first: it is the *older* iteration's, and a section holds
// several iterations at once. Body order would be wrong for anything whose
// dependence is not an SSA edge -- memory.
// CHECK-NEXT: %[[S:.*]] = lvx.addd %[[A]], %[[V]]
// CHECK-NEXT: %[[LD:.*]] = lvx.ld
// CHECK-NEXT: lvx_scf.yield %[[S]], %[[LD]]
// CHECK: lvx.addd %[[K]]#0, %[[K]]#1
lvx_func.func @acc(%base: !lvx.reg<r0>) -> !lvx.reg<r0> {
  %lo = lvx.li 0 : i64 : !lvx.reg
  %hi = lvx.li 4 : i64 : !lvx.reg
  %st = lvx.li 1 : i64 : !lvx.reg
  %z = lvx.li 0 : i64 : !lvx.reg
  %r = lvx_scf.for %lo : !lvx.reg to %hi : !lvx.reg step %st : !lvx.reg
       iter_args(%z) : (!lvx.reg) -> (!lvx.reg) {
  ^bb0(%i: !lvx.reg, %a: !lvx.reg):
    %v = lvx.ld %base, 0 : i64 {lvx.stage = 0 : i64} : (!lvx.reg<r0>) -> !lvx.reg
    %s = lvx.addd %a, %v {lvx.stage = 1 : i64} : (!lvx.reg, !lvx.reg) -> !lvx.reg
    lvx_scf.yield %s : !lvx.reg
  }
  %out = lvx.mv %r : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %out : !lvx.reg<r0>
}

// -----

// Three stages, and the induction variable is one of the values in flight: at
// trip `t` the multiply works on iteration `t-1`, so it needs `i(t-1)`, which
// is carried as an iter_arg like anything else rather than recomputed. The
// peeled sections get it as a constant, the bounds being constant.
// CHECK-LABEL: lvx_func.func @three
// CHECK: %[[LB:.*]] = lvx.li 2
// CHECK: lvx_scf.for %[[LB]]
// CHECK-NEXT: ^bb0(%[[IV:.*]]: !lvx.reg, %[[V:.*]]: !lvx.reg, %[[I1:.*]]: !lvx.reg, %[[A:.*]]: !lvx.reg, %[[W:.*]]: !lvx.reg)
// Oldest iteration first: the add (stage 2), then the multiply (stage 1),
// then the load (stage 0).
// CHECK-NEXT: %[[S:.*]] = lvx.addd %[[A]], %[[W]]
// CHECK-NEXT: %[[MUL:.*]] = lvx.muld %[[V]], %[[I1]]
// CHECK-NEXT: %[[LD:.*]] = lvx.ld
// CHECK-NEXT: lvx_scf.yield %[[LD]], %[[IV]], %[[S]], %[[MUL]]
lvx_func.func @three(%base: !lvx.reg<r0>) -> !lvx.reg<r0> {
  %lo = lvx.li 0 : i64 : !lvx.reg
  %hi = lvx.li 5 : i64 : !lvx.reg
  %st = lvx.li 1 : i64 : !lvx.reg
  %z = lvx.li 0 : i64 : !lvx.reg
  %r = lvx_scf.for %lo : !lvx.reg to %hi : !lvx.reg step %st : !lvx.reg
       iter_args(%z) : (!lvx.reg) -> (!lvx.reg) {
  ^bb0(%i: !lvx.reg, %a: !lvx.reg):
    %v = lvx.ld %base, 0 : i64 {lvx.stage = 0 : i64} : (!lvx.reg<r0>) -> !lvx.reg
    %w = lvx.muld %v, %i {lvx.stage = 1 : i64} : (!lvx.reg, !lvx.reg) -> !lvx.reg
    %s = lvx.addd %a, %w {lvx.stage = 2 : i64} : (!lvx.reg, !lvx.reg) -> !lvx.reg
    lvx_scf.yield %s : !lvx.reg
  }
  %out = lvx.mv %r : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %out : !lvx.reg<r0>
}

// -----

// One stage is not a pipeline: the loop is left alone.
// CHECK-LABEL: lvx_func.func @flat
// CHECK: lvx_scf.for
// CHECK-NOT: lvx_scf.for
lvx_func.func @flat(%base: !lvx.reg<r0>, %n: !lvx.reg<r1>) {
  %lo = lvx.li 0 : i64 : !lvx.reg
  %hi = lvx.li 4 : i64 : !lvx.reg
  %st = lvx.li 1 : i64 : !lvx.reg
  lvx_scf.for %lo : !lvx.reg to %hi : !lvx.reg step %st : !lvx.reg {
  ^bb0(%i: !lvx.reg):
    %v = lvx.ld %base, 0 : i64 {lvx.stage = 0 : i64} : (!lvx.reg<r0>) -> !lvx.reg
    lvx.sd %v, %base, 8 : i64 {lvx.stage = 0 : i64} : (!lvx.reg, !lvx.reg<r0>)
    lvx_scf.yield
  }
  lvx_func.return
}
