// RUN: mlir-opt %s -lvx-pipeline -split-input-file -verify-diagnostics

// A use before its definition is not a schedule.
lvx_func.func @use_before_def(%base: !lvx.reg<r0>) {
  %lo = lvx.li 0 : i64 : !lvx.reg
  %hi = lvx.li 4 : i64 : !lvx.reg
  %st = lvx.li 1 : i64 : !lvx.reg
  // expected-error @below {{not a feasible stage assignment}}
  lvx_scf.for %lo : !lvx.reg to %hi : !lvx.reg step %st : !lvx.reg {
  ^bb0(%i: !lvx.reg):
    %v = lvx.ld %base, 0 : i64 {lvx.stage = 1 : i64} : (!lvx.reg<r0>) -> !lvx.reg
    lvx.sd %v, %base, 8 : i64 {lvx.stage = 0 : i64} : (!lvx.reg, !lvx.reg<r0>)
    lvx_scf.yield
  }
  lvx_func.return
}

// -----

// Dynamic bounds need the guard and the remainder loop, which are not emitted.
lvx_func.func @dynamic(%base: !lvx.reg<r0>, %n: !lvx.reg<r1>) {
  %lo = lvx.li 0 : i64 : !lvx.reg
  %st = lvx.li 1 : i64 : !lvx.reg
  // expected-error @below {{needs constant loop bounds}}
  lvx_scf.for %lo : !lvx.reg to %n : !lvx.reg<r1> step %st : !lvx.reg {
  ^bb0(%i: !lvx.reg):
    %v = lvx.ld %base, 0 : i64 {lvx.stage = 0 : i64} : (!lvx.reg<r0>) -> !lvx.reg
    lvx.sd %v, %base, 8 : i64 {lvx.stage = 1 : i64} : (!lvx.reg, !lvx.reg<r0>)
    lvx_scf.yield
  }
  lvx_func.return
}

// -----

// Fewer iterations than stages: the guard around an unpipelined copy is not
// emitted yet, so this is rejected rather than miscompiled.
lvx_func.func @too_short(%base: !lvx.reg<r0>) {
  %lo = lvx.li 0 : i64 : !lvx.reg
  %hi = lvx.li 1 : i64 : !lvx.reg
  %st = lvx.li 1 : i64 : !lvx.reg
  // expected-error @below {{fewer iterations than the pipeline has stages}}
  lvx_scf.for %lo : !lvx.reg to %hi : !lvx.reg step %st : !lvx.reg {
  ^bb0(%i: !lvx.reg):
    %v = lvx.ld %base, 0 : i64 {lvx.stage = 0 : i64} : (!lvx.reg<r0>) -> !lvx.reg
    %w = lvx.muld %v, %v {lvx.stage = 1 : i64} : (!lvx.reg, !lvx.reg) -> !lvx.reg
    lvx.sd %w, %base, 8 : i64 {lvx.stage = 2 : i64} : (!lvx.reg, !lvx.reg<r0>)
    lvx_scf.yield
  }
  lvx_func.return
}
