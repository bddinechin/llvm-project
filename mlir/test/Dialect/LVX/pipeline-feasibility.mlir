// RUN: mlir-opt %s -split-input-file --pass-pipeline='builtin.module(any(lvx-decomposed-pipeline))' | FileCheck %s --check-prefix=POOL59
// RUN: mlir-opt %s -split-input-file --pass-pipeline='builtin.module(any(lvx-decomposed-pipeline{max-registers=16}))' | FileCheck %s --check-prefix=POOL16
// RUN: mlir-opt %s -split-input-file --pass-pipeline='builtin.module(any(lvx-decomposed-pipeline{max-registers=12}))' | FileCheck %s --check-prefix=POOL12
// RUN: mlir-opt %s -split-input-file --pass-pipeline='builtin.module(any(lvx-decomposed-pipeline{max-registers=8}))' 2>&1 | FileCheck %s --check-prefix=POOL8
// RUN: mlir-opt %s -split-input-file --pass-pipeline='builtin.module(any(lvx-pipeline{max-registers=16}))' 2>&1 | FileCheck %s --check-prefix=GIVEN16
// RUN: mlir-opt %s -split-input-file --pass-pipeline='builtin.module(any(lvx-pipeline))' | FileCheck %s --check-prefix=GIVEN59

// Allocation decides feasibility, and failure is an outcome
// (SoftwarePipelining.md §8, step 3). An uncached load takes fifteen cycles,
// so at II = 1 sixteen sums are in flight and the kernel needs a name for
// each. The scheduler raises the period until the pipeline allocates as well
// as the loop it replaces: each doubling of II halves `kunroll`, and with it
// the registers. With no such period up to eight past the first, the loop is
// left unpipelined.

// POOL59-LABEL: lvx_func.func @sum
// POOL59: lvx.ii = 1 : i64
// POOL16-LABEL: lvx_func.func @sum
// POOL16: lvx.ii = 2 : i64
// POOL12-LABEL: lvx_func.func @sum
// POOL12: lvx.ii = 4 : i64
// POOL8: remark: not software-pipelined: no period from 1 to 9
// POOL8-LABEL: lvx_func.func @sum
// POOL8-NOT: lvx.ii
// POOL8-NOT: lvx.date
// POOL8: lvx_func.return
lvx_func.func @sum(%base: !lvx.reg<r0>) -> !lvx.reg<r0> {
  %lo = lvx.li 0 : i64 : !lvx.reg
  %hi = lvx.li 64 : i64 : !lvx.reg
  %st = lvx.li 1 : i64 : !lvx.reg
  %z = lvx.li 0 : i64 : !lvx.reg
  %r = lvx_scf.for %lo : !lvx.reg to %hi : !lvx.reg step %st : !lvx.reg
       iter_args(%z) : (!lvx.reg) -> (!lvx.reg) {
  ^bb0(%i: !lvx.reg, %a: !lvx.reg):
    %p = lvx.addx8d %i, %base : (!lvx.reg, !lvx.reg<r0>) -> !lvx.reg
    %v = lvx.ld %p, 0 : i64 {variant = 2 : i64} : (!lvx.reg) -> !lvx.reg
    %s = lvx.addd %a, %v : (!lvx.reg, !lvx.reg) -> !lvx.reg
    lvx_scf.yield %s : !lvx.reg
  }
  %out = lvx.mv %r : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %out : !lvx.reg<r0>
}

// -----

// The same loop with its schedule given at II = 1: `-lvx-pipeline` tests it
// too, and in 16 registers the sixteen-copy kernel does not fit, so the loop
// is kept as it was -- schedule attributes removed, nothing else touched.
// In the full pool it pipelines.

// GIVEN16: remark: not software-pipelined: at II = 1
// GIVEN16-LABEL: lvx_func.func @given
// GIVEN16: lvx_scf.for
// GIVEN16-NEXT: ^bb0
// GIVEN16-NEXT: lvx.addx8d
// GIVEN16-NOT: lvx.date
// GIVEN16-NEXT: lvx.ld
// GIVEN16-NEXT: lvx.addd
// GIVEN16-NEXT: lvx_scf.yield
// GIVEN16-NEXT: }
// GIVEN16-NOT: lvx.ii
// GIVEN59-LABEL: lvx_func.func @given
// GIVEN59: lvx.kernel_period = 16
lvx_func.func @given(%base: !lvx.reg<r0>) -> !lvx.reg<r0> {
  %lo = lvx.li 0 : i64 : !lvx.reg
  %hi = lvx.li 64 : i64 : !lvx.reg
  %st = lvx.li 1 : i64 : !lvx.reg
  %z = lvx.li 0 : i64 : !lvx.reg
  %r = lvx_scf.for %lo : !lvx.reg to %hi : !lvx.reg step %st : !lvx.reg
       iter_args(%z) : (!lvx.reg) -> (!lvx.reg) {
  ^bb0(%i: !lvx.reg, %a: !lvx.reg):
    %p = lvx.addx8d %i, %base {lvx.date = 0 : i64} : (!lvx.reg, !lvx.reg<r0>) -> !lvx.reg
    %v = lvx.ld %p, 0 : i64 {lvx.date = 1 : i64, variant = 2 : i64} : (!lvx.reg) -> !lvx.reg
    %s = lvx.addd %a, %v {lvx.date = 16 : i64} : (!lvx.reg, !lvx.reg) -> !lvx.reg
    lvx_scf.yield %s : !lvx.reg
  } {lvx.ii = 1 : i64}
  %out = lvx.mv %r : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %out : !lvx.reg<r0>
}
