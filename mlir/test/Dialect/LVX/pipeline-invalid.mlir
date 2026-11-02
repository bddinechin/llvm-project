// RUN: mlir-opt %s -lvx-pipeline -split-input-file -verify-diagnostics

// A use before its definition, in the master schedule's walk order, is not a
// schedule.
lvx_func.func @use_before_def(%base: !lvx.reg<r0>) {
  %lo = lvx.li 0 : i64 : !lvx.reg
  %hi = lvx.li 4 : i64 : !lvx.reg
  %st = lvx.li 1 : i64 : !lvx.reg
  // expected-error @below {{the schedule is not one}}
  lvx_scf.for %lo : !lvx.reg to %hi : !lvx.reg step %st : !lvx.reg {
  ^bb0(%i: !lvx.reg):
    %v = lvx.ld %base, 0 : i64 {lvx.stage = 1 : i64} : (!lvx.reg<r0>) -> !lvx.reg
    lvx.sd %v, %base, 8 : i64 {lvx.stage = 0 : i64} : (!lvx.reg, !lvx.reg<r0>)
    lvx_scf.yield
  }
  lvx_func.return
}

// -----

// A run-time trip count is a shift of the bound difference, which needs a
// constant power-of-two step.
lvx_func.func @step3(%base: !lvx.reg<r0>, %n: !lvx.reg<r1>) {
  %lo = lvx.li 0 : i64 : !lvx.reg
  %st = lvx.li 3 : i64 : !lvx.reg
  // expected-error @below {{constant power-of-two step}}
  lvx_scf.for %lo : !lvx.reg to %n : !lvx.reg<r1> step %st : !lvx.reg {
  ^bb0(%i: !lvx.reg):
    %v = lvx.ld %base, 0 : i64 {lvx.stage = 0 : i64} : (!lvx.reg<r0>) -> !lvx.reg
    lvx.sd %v, %base, 8 : i64 {lvx.stage = 1 : i64} : (!lvx.reg, !lvx.reg<r0>)
    lvx_scf.yield
  }
  lvx_func.return
}
