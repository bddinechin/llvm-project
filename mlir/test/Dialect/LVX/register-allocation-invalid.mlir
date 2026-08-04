// RUN: mlir-opt %s --pass-pipeline='builtin.module(any(lvx-allocate-registers{max-registers=0}))' -split-input-file -verify-diagnostics

// With the allocatable pool shrunk to 0 (test-only `max-registers` option --
// see lvx-mlir/docs/RegisterAllocation.md), Step 3 spills ordinary values rather
// than erroring on pressure alone. But spilling a coalesced `lvx_scf.for`
// loop-carried channel isn't implemented yet, so that specific case must
// still be a hard error rather than silently producing wrong code.
lvx_func.func @loop_spill_not_implemented(%a: !lvx.reg<r0>) -> !lvx.reg<r0> {
  %ov = lvx.mv %a : (!lvx.reg<r0>) -> !lvx.reg
  %lb = lvx.li 0 : i64 : !lvx.reg
  %ub = lvx.li 10 : i64 : !lvx.reg
  %step = lvx.li 1 : i64 : !lvx.reg
  // expected-error@+1 {{spilling a coalesced register group (lvx_scf.for loop-carried channel, lvx_cf branch edge, or ffma/ffms accumulator) is not yet implemented}}
  %init = lvx.li 0 : i64 : !lvx.reg
  %r = lvx_scf.for %lb : !lvx.reg to %ub : !lvx.reg step %step : !lvx.reg iter_args(%init) : (!lvx.reg) -> (!lvx.reg) {
  ^bb0(%iv: !lvx.reg, %acc: !lvx.reg):
    %use = lvx.addd %acc, %ov : (!lvx.reg, !lvx.reg) -> !lvx.reg
    lvx_scf.yield %use : !lvx.reg
  }
  %p = lvx.mv %r : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %p : !lvx.reg<r0>
}

// -----

// A call with more spilled arguments than the reserved 3-register spill-
// scratch pool can reload simultaneously (see "Reserved scratch registers"
// in the design doc) is a documented scope limit, not a silent collision.
lvx_func.func private @callee(!lvx.reg<r0>, !lvx.reg<r1>, !lvx.reg<r2>, !lvx.reg<r3>) -> !lvx.reg<r0>
lvx_func.func @too_many_simultaneous_reloads(
    %a: !lvx.reg<r0>, %b: !lvx.reg<r1>, %c: !lvx.reg<r2>, %d: !lvx.reg<r3>) -> !lvx.reg<r0> {
  %0 = lvx.mv %a : (!lvx.reg<r0>) -> !lvx.reg
  %1 = lvx.mv %b : (!lvx.reg<r1>) -> !lvx.reg
  %2 = lvx.mv %c : (!lvx.reg<r2>) -> !lvx.reg
  %3 = lvx.mv %d : (!lvx.reg<r3>) -> !lvx.reg
  // expected-error@+1 {{instruction needs more than 3 simultaneously-reloaded spilled operands}}
  %r = lvx_func.call @callee(%0, %1, %2, %3) : (!lvx.reg, !lvx.reg, !lvx.reg, !lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %r : !lvx.reg<r0>
}
