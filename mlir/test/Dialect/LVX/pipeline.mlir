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
// trip `t` the multiply works on iteration `t-1`, so it needs `i(t-1)`. That is
// recomputed from the kernel's own induction value rather than carried, so it
// takes no iter_arg. The peeled sections get it as a constant, the bounds
// being constant. Nothing lives longer than a trip, so the kernel is not
// unrolled.
// CHECK-LABEL: lvx_func.func @three
// CHECK: %[[LB:.*]] = lvx.li 2
// CHECK: lvx_scf.for %[[LB]]
// CHECK-NEXT: ^bb0(%[[IV:.*]]: !lvx.reg, %[[V:.*]]: !lvx.reg, %[[A:.*]]: !lvx.reg, %[[W:.*]]: !lvx.reg)
// Oldest iteration first: the add (stage 2), then the multiply (stage 1),
// then the load (stage 0).
// CHECK-NEXT: %[[S:.*]] = lvx.addd %[[A]], %[[W]]
// CHECK-NEXT: %[[I1:.*]] = lvx.addd_i %[[IV]], -1
// CHECK-NEXT: %[[MUL:.*]] = lvx.muld %[[V]], %[[I1]]
// CHECK-NEXT: %[[LD:.*]] = lvx.ld
// CHECK-NEXT: lvx_scf.yield %[[LD]], %[[S]], %[[MUL]]
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

// -----

// A value read three stages after it is loaded needs four names, so the kernel
// is unrolled four times and copy `c` reads the load of copy `c - 3` -- the
// previous kernel trip's, through an iter_arg, for the first three copies, and
// its own trip's for the last. Every iter_arg is yielded a fresh load, never
// another iter_arg: that is what lets allocation coalesce each with what is
// yielded into it. Ten iterations less the three the ramp covers leave seven,
// one whole kernel trip and three peeled ahead of the prologue.
// The kernel ends at the loop's own upper bound; only the step is new.
// CHECK-LABEL: lvx_func.func @deep
// CHECK: %[[UB:.*]] = lvx.li 10
// Peeled, unpipelined:
// CHECK-COUNT-3: lvx.sd
// CHECK: %[[LB:.*]] = lvx.li 6
// CHECK-NEXT: %[[STEP:.*]] = lvx.li 4
// CHECK-NEXT: lvx_scf.for %[[LB]] : !lvx.reg to %[[UB]] : !lvx.reg step %[[STEP]]
// CHECK-NEXT: ^bb0(%{{.*}}: !lvx.reg, %[[S1:.*]]: !lvx.reg, %[[S2:.*]]: !lvx.reg, %[[S3:.*]]: !lvx.reg)
// CHECK-NEXT: lvx.sd %[[S3]]
// CHECK-NEXT: %[[L0:.*]] = lvx.ld
// CHECK-NEXT: lvx.sd %[[S2]]
// CHECK-NEXT: %[[L1:.*]] = lvx.ld
// CHECK-NEXT: lvx.sd %[[S1]]
// CHECK-NEXT: %[[L2:.*]] = lvx.ld
// CHECK-NEXT: lvx.sd %[[L0]]
// CHECK-NEXT: %[[L3:.*]] = lvx.ld
// CHECK-NEXT: lvx_scf.yield %[[L3]], %[[L2]], %[[L1]]
// Drained oldest first:
// CHECK: lvx.sd %{{.*}}#2
// CHECK-NEXT: lvx.sd %{{.*}}#1
// CHECK-NEXT: lvx.sd %{{.*}}#0
lvx_func.func @deep(%base: !lvx.reg<r0>) {
  %lo = lvx.li 0 : i64 : !lvx.reg
  %hi = lvx.li 10 : i64 : !lvx.reg
  %st = lvx.li 1 : i64 : !lvx.reg
  lvx_scf.for %lo : !lvx.reg to %hi : !lvx.reg step %st : !lvx.reg {
  ^bb0(%i: !lvx.reg):
    %v = lvx.ld %base, 0 : i64 {lvx.stage = 0 : i64} : (!lvx.reg<r0>) -> !lvx.reg
    lvx.sd %v, %base, 8 : i64 {lvx.stage = 3 : i64} : (!lvx.reg, !lvx.reg<r0>)
    lvx_scf.yield
  }
  lvx_func.return
}

// -----

// A tie stretches a lifetime. The ffma overwrites the loaded value in place,
// so the load's register is busy until the ffma's result is stored, three
// stages after the load and not the two SSA shows. Two copies would put the
// next load in a register whose ffma result is still waiting for its store;
// the kernel is unrolled four times instead (three, rounded up).
// CHECK-LABEL: lvx_func.func @tied
// CHECK: lvx_scf.for
// CHECK-SAME: step %[[STEP:[^ ]*]]
// CHECK-COUNT-4: lvx.ffmaw
// CHECK: lvx_scf.yield
lvx_func.func @tied(%base: !lvx.reg<r0>, %y: !lvx.reg<r1>) {
  %lo = lvx.li 0 : i64 : !lvx.reg
  %hi = lvx.li 8 : i64 : !lvx.reg
  %st = lvx.li 1 : i64 : !lvx.reg
  lvx_scf.for %lo : !lvx.reg to %hi : !lvx.reg step %st : !lvx.reg {
  ^bb0(%i: !lvx.reg):
    %x = lvx.lwz %base, 0 : i64 {lvx.stage = 0 : i64} : (!lvx.reg<r0>) -> !lvx.reg
    %r = lvx.ffmaw %y, %y, %x {lvx.stage = 2 : i64} : (!lvx.reg<r1>, !lvx.reg<r1>, !lvx.reg) -> !lvx.reg
    lvx.sw %r, %base, 8 : i64 {lvx.stage = 3 : i64} : (!lvx.reg, !lvx.reg<r0>)
    lvx_scf.yield
  }
  lvx_func.return
}
