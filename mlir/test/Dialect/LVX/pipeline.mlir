// RUN: mlir-opt %s -lvx-pipeline -split-input-file | FileCheck %s
// RUN: mlir-opt %s -lvx-pipeline -split-input-file -verify-diagnostics -o /dev/null

// Software pipeline construction from a modulo schedule, after [PaCT97] as
// LVX GCC implements it: instances walked in (date, iteration, position)
// order, the kernel the window of `kunroll * II` cycles ending at ITER_SLOT,
// and the drain of the one exit a constant trip count takes. A bare
// `lvx.stage` is a date at II = 1. See lvx-mlir/docs/SoftwarePipelining.md.

// Two stages: the load runs an iteration ahead of the add that consumes it.
// The kernel runs whole trips over iterations 1..3 of the load, the add of
// iteration 3 drains -- four loads and four adds for four iterations.
//
// The two values in flight become iter_args: the load's result, and the
// accumulator, which crosses the back edge with one name: the add reads its
// previous value as it writes the next.
// CHECK-LABEL: lvx_func.func @acc
// CHECK: %[[PRO:.*]] = lvx.ld
// CHECK: %[[LB:.*]] = lvx.li 0
// CHECK-NEXT: %[[UB:.*]] = lvx.li 3
// CHECK: %[[K:.*]]:2 = lvx_scf.for %[[LB]] : !lvx.reg to %[[UB]]
// CHECK-SAME: iter_args(%{{.*}}, %[[PRO]])
// CHECK-NEXT: ^bb0(%{{.*}}: !lvx.reg, %[[A:.*]]: !lvx.reg, %[[V:.*]]: !lvx.reg)
// The add issues first: it is the *older* iteration's, at the same date.
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

// Three stages, and the induction variable is read a stage late: the multiply
// works on the iteration after the add's. The kernel's induction variable
// counts from that iteration -- its bounds shifted a step, 1 to 4 rather than
// 0 to 3 -- so the multiply reads it directly, with no add in the kernel. The
// peeled sections get it as a constant, the bounds being constant. Nothing
// lives longer than a trip, so the kernel is not unrolled.
// CHECK-LABEL: lvx_func.func @three
// CHECK: %[[KUB:.*]] = lvx.li 4
// CHECK-NEXT: lvx_scf.for %{{.*}} : !lvx.reg to %[[KUB]]
// CHECK-NEXT: ^bb0(%[[IV:.*]]: !lvx.reg, %[[A:.*]]: !lvx.reg, %[[W:.*]]: !lvx.reg, %[[V:.*]]: !lvx.reg)
// Oldest iteration first: the add (stage 2), then the multiply (stage 1),
// then the load (stage 0).
// CHECK-NEXT: %[[S:.*]] = lvx.addd %[[A]], %[[W]]
// CHECK-NEXT: %[[MUL:.*]] = lvx.muld %[[V]], %[[IV]]
// CHECK-NEXT: %[[LD:.*]] = lvx.ld
// CHECK-NEXT: lvx_scf.yield %[[S]], %[[MUL]], %[[LD]]
// The drain finishes iterations 3 and 4, the last multiply on a constant.
// CHECK: %[[C4:.*]] = lvx.li 4
// CHECK-NEXT: lvx.muld %{{.*}}, %[[C4]]
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
// previous trip's, through an iter_arg, for the first three copies, and its
// own trip's for the last. Every iter_arg is yielded a fresh load, never
// another iter_arg: that is what lets allocation coalesce each with what is
// yielded into it. Ten iterations: three loads ramp up, one whole trip, then
// three more copies up to the last iteration's exit, and three stores drain.
// CHECK-LABEL: lvx_func.func @deep
// CHECK-COUNT-3: lvx.ld
// One whole trip of four: from 0 to 4, by 4.
// CHECK: %[[LB:.*]] = lvx.li 0
// CHECK-NEXT: %[[UB:.*]] = lvx.li 4
// CHECK-NEXT: %[[STEP:.*]] = lvx.li 4
// CHECK-NEXT: lvx_scf.for %[[LB]] : !lvx.reg to %[[UB]] : !lvx.reg step %[[STEP]]
// CHECK-NEXT: ^bb0(%{{.*}}: !lvx.reg, %[[S1:.*]]: !lvx.reg, %[[S2:.*]]: !lvx.reg, %[[S3:.*]]: !lvx.reg)
// CHECK-NEXT: lvx.sd %[[S1]]
// CHECK-NEXT: %[[L0:.*]] = lvx.ld
// CHECK-NEXT: lvx.sd %[[S2]]
// CHECK-NEXT: %[[L1:.*]] = lvx.ld
// CHECK-NEXT: lvx.sd %[[S3]]
// CHECK-NEXT: %[[L2:.*]] = lvx.ld
// CHECK-NEXT: lvx.sd %[[L0]]
// CHECK-NEXT: %[[L3:.*]] = lvx.ld
// CHECK-NEXT: lvx_scf.yield %[[L1]], %[[L2]], %[[L3]]
// The leading three copies of one more trip, then the drain.
// CHECK: lvx.sd %{{.*}}#0
// CHECK-NEXT: %[[R0:.*]] = lvx.ld
// CHECK-NEXT: lvx.sd %{{.*}}#1
// CHECK-NEXT: %[[R1:.*]] = lvx.ld
// CHECK-NEXT: lvx.sd %{{.*}}#2
// CHECK-NEXT: %[[R2:.*]] = lvx.ld
// CHECK-NEXT: lvx.sd %[[R0]]
// CHECK-NEXT: lvx.sd %[[R1]]
// CHECK-NEXT: lvx.sd %[[R2]]
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

// -----

// A trip count shorter than the pipeline exits from the prologue: one
// iteration of a three-stage schedule is its three operations in order, with
// no kernel and no guard.
// CHECK-LABEL: lvx_func.func @short
// CHECK: lvx.ld
// CHECK-NEXT: lvx.muld
// CHECK-NEXT: lvx.sd
// CHECK-NOT: lvx_scf.for
lvx_func.func @short(%base: !lvx.reg<r0>) {
  %lo = lvx.li 0 : i64 : !lvx.reg
  %hi = lvx.li 1 : i64 : !lvx.reg
  %st = lvx.li 1 : i64 : !lvx.reg
  lvx_scf.for %lo : !lvx.reg to %hi : !lvx.reg step %st : !lvx.reg {
  ^bb0(%i: !lvx.reg):
    %v = lvx.ld %base, 0 : i64 {lvx.stage = 0 : i64} : (!lvx.reg<r0>) -> !lvx.reg
    %w = lvx.muld %v, %v {lvx.stage = 1 : i64} : (!lvx.reg, !lvx.reg) -> !lvx.reg
    lvx.sd %w, %base, 8 : i64 {lvx.stage = 2 : i64} : (!lvx.reg, !lvx.reg<r0>)
    lvx_scf.yield
  }
  lvx_func.return
}

// -----

// Dates, not stages, order a section. At II = 2 the store (date 3) and the
// second load (date 2) are both stage 1, and the body lists the store first;
// the walk issues the load first, because its date is earlier, and an
// instance of an older iteration first when dates tie. Stage-then-body order
// would put every store ahead of the loads of its stage, which is a reordering
// of memory the schedule never made.
// CHECK-LABEL: lvx_func.func @dates
// CHECK: lvx.ld %{{.*}}, 0
// CHECK-NEXT: lvx.ld %{{.*}}, 16
// CHECK-NEXT: lvx.ld %{{.*}}, 0
// CHECK: lvx_scf.for
// CHECK-NEXT: ^bb0
// CHECK-NEXT: lvx.sd
// CHECK-NEXT: lvx.ld %{{.*}}, 16
// CHECK-NEXT: lvx.ld %{{.*}}, 0
// CHECK-NEXT: lvx.sd
// CHECK-NEXT: lvx.ld %{{.*}}, 16
// CHECK-NEXT: lvx.ld %{{.*}}, 0
// CHECK-NEXT: lvx_scf.yield
// CHECK-NEXT: }
// CHECK-NEXT: lvx.sd
// CHECK-NEXT: lvx.ld %{{.*}}, 16
// CHECK-NEXT: lvx.sd
// CHECK-NOT: lvx.ld
lvx_func.func @dates(%base: !lvx.reg<r0>) {
  %lo = lvx.li 0 : i64 : !lvx.reg
  %hi = lvx.li 6 : i64 : !lvx.reg
  %st = lvx.li 1 : i64 : !lvx.reg
  lvx_scf.for %lo : !lvx.reg to %hi : !lvx.reg step %st : !lvx.reg {
  ^bb0(%i: !lvx.reg):
    %x = lvx.ld %base, 0 : i64 {lvx.date = 0 : i64} : (!lvx.reg<r0>) -> !lvx.reg
    lvx.sd %x, %base, 8 : i64 {lvx.date = 3 : i64} : (!lvx.reg, !lvx.reg<r0>)
    %z = lvx.ld %base, 16 : i64 {lvx.date = 2 : i64} : (!lvx.reg<r0>) -> !lvx.reg
    lvx_scf.yield
  } {lvx.ii = 2 : i64}
  lvx_func.return
}

// -----

// A run-time trip count M, in GCC's arrangement: one lvx_scf.loop whose
// breaks are the exits. Three loads ramp up (L0 = 3), each prologue loopback
// an exit to its own drain; then T = (M - 4) >> 2 exit-free kernel trips; then
// the remainder copy, whose first three loopbacks exit when
// J = (M - 4) & 3 is 0, 1 or 2, and whose closing one falls into the main
// drain. Every exit's drain stores exactly the iterations up to it.
// CHECK-LABEL: lvx_func.func @dyn_deep
// CHECK: %[[M:.*]] = lvx.sbfd %{{.*}}, %[[LO:[^ ]*]] :
// CHECK-NEXT: lvx_scf.loop token(%[[L:.*]]) {
// CHECK-NEXT:   lvx_scf.if dlez %[[M]]
// CHECK-NEXT:     lvx_scf.break [%[[L]]]
// The prologue's exits, one store per iteration started:
// CHECK:        lvx.ld
// CHECK-NEXT:   %[[M1:.*]] = lvx.addd_i %[[M]], -1
// CHECK-NEXT:   lvx_scf.if dlez %[[M1]]
// CHECK-COUNT-1: lvx.sd
// CHECK-NEXT:     lvx_scf.break [%[[L]]]
// CHECK:        lvx_scf.if dlez
// CHECK-COUNT-2: lvx.sd
// CHECK-NEXT:     lvx_scf.break [%[[L]]]
// CHECK:        lvx_scf.if dlez
// CHECK-COUNT-3: lvx.sd
// CHECK-NEXT:     lvx_scf.break [%[[L]]]
// SETUP, and the kernel from the lower bound:
// CHECK:        %[[X:.*]] = lvx.addd_i %[[M]], -4
// CHECK-NEXT:   %[[T:.*]] = lvx.srld_i %[[X]], 2
// CHECK-NEXT:   %[[J:.*]] = lvx.andd_i %[[X]], 3
// CHECK-NEXT:   %[[SPAN:.*]] = lvx.slld_i %[[T]], 2
// CHECK-NEXT:   %[[KUB:.*]] = lvx.addd %[[LO]], %[[SPAN]]
// CHECK-NEXT:   %[[KST:.*]] = lvx.li 4
// CHECK-NEXT:   %[[K:.*]]:3 = lvx_scf.for %[[LO]] : !lvx.reg to %[[KUB]] : !lvx.reg step %[[KST]]
// CHECK-NOT:      lvx_scf.if
// CHECK:        lvx_scf.yield
// The remainder copy's three exits, then the main drain:
// CHECK:        lvx.sd %[[K]]#0
// CHECK:        lvx_scf.if deqz %[[J]]
// CHECK-COUNT-3: lvx.sd
// CHECK-NEXT:     lvx_scf.break [%[[L]]]
// CHECK:        %[[J1:.*]] = lvx.addd_i %[[J]], -1
// CHECK-NEXT:   lvx_scf.if deqz %[[J1]]
// CHECK:        %[[J2:.*]] = lvx.addd_i %[[J]], -2
// CHECK-NEXT:   lvx_scf.if deqz %[[J2]]
// CHECK-COUNT-3: lvx.sd
// CHECK-NEXT:     lvx_scf.break [%[[L]]]
// CHECK-NEXT:   }
// CHECK-NEXT:   lvx.sd
// CHECK-NEXT:   lvx.ld
// CHECK-NEXT:   lvx.sd
// CHECK-NEXT:   lvx.sd
// CHECK-NEXT:   lvx.sd
// CHECK-NEXT:   lvx_scf.break [%[[L]]]
// CHECK-NEXT: }
// CHECK-NEXT: lvx_func.return
lvx_func.func @dyn_deep(%base: !lvx.reg<r0>, %n: !lvx.reg<r1>) {
  %lo = lvx.li 0 : i64 : !lvx.reg
  %st = lvx.li 1 : i64 : !lvx.reg
  lvx_scf.for %lo : !lvx.reg to %n : !lvx.reg<r1> step %st : !lvx.reg {
  ^bb0(%i: !lvx.reg):
    %v = lvx.ld %base, 0 : i64 {lvx.stage = 0 : i64} : (!lvx.reg<r0>) -> !lvx.reg
    lvx.sd %v, %base, 8 : i64 {lvx.stage = 3 : i64} : (!lvx.reg, !lvx.reg<r0>)
    lvx_scf.yield
  }
  lvx_func.return
}

// -----

// A run-time count with an accumulator, at kunroll 1: no remainder copy.
// Every break carries the sum: the inits when M is zero, the prologue's
// drain when M is one, and otherwise the kernel's M - 1 trips and the main
// drain. The last prologue exit's test, M - 1, is also the kernel's count.
// CHECK-LABEL: lvx_func.func @dyn_acc
// CHECK: lvx.li 1
// CHECK-NEXT: %[[Z:.*]] = lvx.li 0
// CHECK-NEXT: %[[M:.*]] = lvx.sbfd
// CHECK-NEXT: %[[R:.*]] = lvx_scf.loop token(%[[L:.*]]) -> (!lvx.reg) {
// CHECK-NEXT:   lvx_scf.if dlez %[[M]]
// CHECK-NEXT:     lvx_scf.break [%[[L]]] %[[Z]]
// CHECK:        %[[M1:.*]] = lvx.addd_i %[[M]], -1
// CHECK-NEXT:   lvx_scf.if dlez %[[M1]]
// CHECK-NEXT:     %[[S:.*]] = lvx.addd %[[Z]],
// CHECK-NEXT:     lvx_scf.break [%[[L]]] %[[S]]
// CHECK:        %[[KUB:.*]] = lvx.addd %{{.*}}, %[[M1]]
// CHECK:        %[[K:.*]]:2 = lvx_scf.for
// CHECK:        %[[F:.*]] = lvx.addd %[[K]]#0, %[[K]]#1
// CHECK-NEXT:   lvx_scf.break [%[[L]]] %[[F]]
// CHECK:      lvx.mv %[[R]]
lvx_func.func @dyn_acc(%base: !lvx.reg<r0>, %n: !lvx.reg<r1>) -> !lvx.reg<r0> {
  %lo = lvx.li 0 : i64 : !lvx.reg
  %st = lvx.li 1 : i64 : !lvx.reg
  %z = lvx.li 0 : i64 : !lvx.reg
  %r = lvx_scf.for %lo : !lvx.reg to %n : !lvx.reg<r1> step %st : !lvx.reg
       iter_args(%z) : (!lvx.reg) -> (!lvx.reg) {
  ^bb0(%i: !lvx.reg, %a: !lvx.reg):
    %v = lvx.ld %base, 0 : i64 {lvx.stage = 0 : i64} : (!lvx.reg<r0>) -> !lvx.reg
    %s = lvx.addd %a, %v {lvx.stage = 1 : i64} : (!lvx.reg, !lvx.reg) -> !lvx.reg
    lvx_scf.yield %s : !lvx.reg
  }
  %out = lvx.mv %r : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %out : !lvx.reg<r0>
}
