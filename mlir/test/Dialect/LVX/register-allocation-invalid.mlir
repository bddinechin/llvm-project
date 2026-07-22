// RUN: mlir-opt %s --pass-pipeline='builtin.module(any(lvx-allocate-registers{max-registers=2}))' -verify-diagnostics

// With the allocatable pool artificially shrunk to 2 registers (test-only
// `max-registers` option -- see docs/lvx/RegisterAllocation.md), this
// function's four simultaneously-live virtual values can't all get a
// register, and Step 2 has no spilling: it must bail out with a hard
// error rather than silently miscompiling.
lvx_func.func @out_of_registers(%a: !lvx.reg<r0>, %b: !lvx.reg<r1>) -> !lvx.reg<r0> {
  // expected-error@+1 {{linear scan register allocation failed}}
  %0 = lvx.mv %a : (!lvx.reg<r0>) -> !lvx.reg
  %1 = lvx.mv %b : (!lvx.reg<r1>) -> !lvx.reg
  %2 = lvx.addd %0, %1 : (!lvx.reg, !lvx.reg) -> !lvx.reg
  %3 = lvx.muld %2, %0 : (!lvx.reg, !lvx.reg) -> !lvx.reg
  %4 = lvx.mv %3 : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %4 : !lvx.reg<r0>
}
