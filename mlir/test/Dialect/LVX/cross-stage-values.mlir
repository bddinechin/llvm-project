// RUN: mlir-opt %s -split-input-file -lvx-print-cross-stage -o /dev/null 2>&1 \
// RUN:   | FileCheck %s

// What a stage assignment leaves in flight, which is what the kernel has to
// carry and what modulo variable expansion names. See
// lvx-mlir/docs/SoftwarePipelining.md §5.

// A load at stage 0 whose result is used by an add at stage 1: one value in
// flight across one trip, so two names.
// CHECK-LABEL: loop: stages=2 valid=yes names=2
// CHECK-NEXT: def=0 use=1 distance=1 names=2
lvx_func.func @one_crossing(%base: !lvx.reg<r0>, %n: !lvx.reg<r1>) {
  %lo = lvx.li 0 : i64 : !lvx.reg
  %st = lvx.li 1 : i64 : !lvx.reg
  %acc = lvx.li 0 : i64 : !lvx.reg
  %r = lvx_scf.for %lo : !lvx.reg to %n : !lvx.reg<r1> step %st : !lvx.reg
       iter_args(%acc) : (!lvx.reg) -> (!lvx.reg) {
  ^bb0(%i: !lvx.reg, %a: !lvx.reg):
    %v = lvx.ld %base, 0 : i64 {lvx.stage = 0 : i64} : (!lvx.reg<r0>) -> !lvx.reg
    %s = lvx.addd %a, %v {lvx.stage = 1 : i64} : (!lvx.reg, !lvx.reg) -> !lvx.reg
    lvx_scf.yield %s : !lvx.reg
  }
  lvx_func.return
}

// -----

// Everything in one stage is not a pipeline: nothing crosses, one name.
// CHECK-LABEL: loop: stages=1 valid=yes names=1
lvx_func.func @no_crossing(%base: !lvx.reg<r0>, %n: !lvx.reg<r1>) {
  %lo = lvx.li 0 : i64 : !lvx.reg
  %st = lvx.li 1 : i64 : !lvx.reg
  lvx_scf.for %lo : !lvx.reg to %n : !lvx.reg<r1> step %st : !lvx.reg {
  ^bb0(%i: !lvx.reg):
    %v = lvx.ld %base, 0 : i64 {lvx.stage = 0 : i64} : (!lvx.reg<r0>) -> !lvx.reg
    lvx.sd %v, %base, 8 : i64 {lvx.stage = 0 : i64} : (!lvx.reg, !lvx.reg<r0>)
    lvx_scf.yield
  }
  lvx_func.return
}

// -----

// A value loaded at stage 0 and consumed at stage 2 is alive for two trips, so
// the kernel needs three names for it -- and the accumulator, defined and read
// at the same stage a trip apart, needs two.
// CHECK-LABEL: loop: stages=3 valid=yes names=3
// CHECK: def=0 use=2 distance=2 names=3
// CHECK: carried distance=1 names=2
lvx_func.func @two_trips_in_flight(%base: !lvx.reg<r0>,
                                                 %n: !lvx.reg<r1>) {
  %lo = lvx.li 0 : i64 : !lvx.reg
  %st = lvx.li 1 : i64 : !lvx.reg
  %acc = lvx.li 0 : i64 : !lvx.reg
  %r = lvx_scf.for %lo : !lvx.reg to %n : !lvx.reg<r1> step %st : !lvx.reg
       iter_args(%acc) : (!lvx.reg) -> (!lvx.reg) {
  ^bb0(%i: !lvx.reg, %a: !lvx.reg):
    %v = lvx.ld %base, 0 : i64 {lvx.stage = 0 : i64} : (!lvx.reg<r0>) -> !lvx.reg
    %w = lvx.muld %base, %base {lvx.stage = 1 : i64} : (!lvx.reg<r0>, !lvx.reg<r0>) -> !lvx.reg
    %s = lvx.addd %a, %v {lvx.stage = 2 : i64} : (!lvx.reg, !lvx.reg) -> !lvx.reg
    lvx_scf.yield %s : !lvx.reg
  }
  lvx_func.return
}

// -----

// A schedule that reads a value in an earlier stage than the one computing it
// is not a pipeline at all, and must be rejected rather than emitted.
// CHECK-LABEL: loop: stages=2 valid=no
lvx_func.func @use_before_def(%base: !lvx.reg<r0>, %n: !lvx.reg<r1>) {
  %lo = lvx.li 0 : i64 : !lvx.reg
  %st = lvx.li 1 : i64 : !lvx.reg
  lvx_scf.for %lo : !lvx.reg to %n : !lvx.reg<r1> step %st : !lvx.reg {
  ^bb0(%i: !lvx.reg):
    %v = lvx.ld %base, 0 : i64 {lvx.stage = 1 : i64} : (!lvx.reg<r0>) -> !lvx.reg
    lvx.sd %v, %base, 8 : i64 {lvx.stage = 0 : i64} : (!lvx.reg, !lvx.reg<r0>)
    lvx_scf.yield
  }
  lvx_func.return
}

// -----

// The back edge gives a use one trip of slack, but no more: a value yielded at
// stage 2 cannot be read at stage 0 by the next iteration, whose stage 0 runs
// a trip before the stage 2 that produces it.
// CHECK-LABEL: loop: stages=3 valid=no
lvx_func.func @carried_use_before_def(%base: !lvx.reg<r0>, %n: !lvx.reg<r1>) {
  %lo = lvx.li 0 : i64 : !lvx.reg
  %st = lvx.li 1 : i64 : !lvx.reg
  %acc = lvx.li 0 : i64 : !lvx.reg
  %r = lvx_scf.for %lo : !lvx.reg to %n : !lvx.reg<r1> step %st : !lvx.reg
       iter_args(%acc) : (!lvx.reg) -> (!lvx.reg) {
  ^bb0(%i: !lvx.reg, %a: !lvx.reg):
    %x = lvx.muld %a, %a {lvx.stage = 0 : i64} : (!lvx.reg, !lvx.reg) -> !lvx.reg
    %v = lvx.ld %base, 0 : i64 {lvx.stage = 1 : i64} : (!lvx.reg<r0>) -> !lvx.reg
    %s = lvx.addd %x, %v {lvx.stage = 2 : i64} : (!lvx.reg, !lvx.reg) -> !lvx.reg
    lvx_scf.yield %s : !lvx.reg
  }
  lvx_func.return
}
