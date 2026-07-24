// RUN: mlir-opt %s --pass-pipeline='builtin.module(any(lvx-allocate-registers),any(lvx-scf-to-cf))' | FileCheck %s

// Must run after -lvx-allocate-registers (docs/lvx/AssemblyEmission.md,
// "lvx-scf-to-cf: lowering after allocation").

// A constant-step-1, non-nested loop is eligible for the hardware-loop
// path (docs/lvx/HardwareLoops.md): `lvx_cf.loopdo` replaces the
// compare+cond_br header entirely, and the induction variable's entry
// value is still copied in via an explicit `lvx.mv` (%6) for the same
// reason the branch-based path needs it -- the lower bound and the body's
// own induction-variable argument are independently allocated by Steps
// 1-3, with no guarantee they share a register.
// CHECK-LABEL: lvx_func.func @loop
// CHECK: %5 = lvx.sbfd %2, %1 : (<r2>, <r0>) -> <r29>
// CHECK-NEXT: %6 = lvx.mv %1 : (!lvx.reg<r0>) -> !lvx.reg<r0>
// CHECK-NEXT: lvx_cf.loopdo %5 : <r29>, ^bb1(%6, %4 : !lvx.reg<r0>, !lvx.reg<r4>), ^bb2(%4 : !lvx.reg<r4>)
// CHECK-NEXT: ^bb1(%7: !lvx.reg<r0>, %8: !lvx.reg<r4>):
// CHECK-NEXT: %9 = lvx.addd %8, %0 : (<r4>, <r1>) -> <r4>
// CHECK-NEXT: %10 = lvx.addd %7, %3 : (<r0>, <r3>) -> <r0>
// CHECK-NEXT: lvx_cf.br ^bb2(%9 : !lvx.reg<r4>)
// CHECK-NEXT: ^bb2(%11: !lvx.reg<r4>):
// CHECK-NEXT: %12 = lvx.mv %11 : (!lvx.reg<r4>) -> !lvx.reg<r0>
// CHECK-NEXT: lvx_func.return %12 : !lvx.reg<r0>
lvx_func.func @loop(%a: !lvx.reg<r0>) -> !lvx.reg<r0> {
  %ov = lvx.mv %a : (!lvx.reg<r0>) -> !lvx.reg
  %lb = lvx.li 0 : i64 : !lvx.reg
  %ub = lvx.li 10 : i64 : !lvx.reg
  %step = lvx.li 1 : i64 : !lvx.reg
  %init = lvx.li 0 : i64 : !lvx.reg
  %r = lvx_scf.for %lb : !lvx.reg to %ub : !lvx.reg step %step : !lvx.reg iter_args(%init) : (!lvx.reg) -> (!lvx.reg) {
  ^bb0(%iv: !lvx.reg, %acc: !lvx.reg):
    %use = lvx.addd %acc, %ov : (!lvx.reg, !lvx.reg) -> !lvx.reg
    lvx_scf.yield %use : !lvx.reg
  }
  %p = lvx.mv %r : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %p : !lvx.reg<r0>
}

// Non-constant-step-1 loops (here, step 2) are not eligible for the
// hardware-loop path and keep using the branch-based lowering: an
// explicit compare (`lvx.compd lt`, pinned to r29 like the hardware
// loop's own trip-count value) and cond_br header, with the same
// induction-variable copy-in (%5) for the same reason.
// CHECK-LABEL: lvx_func.func @loop_step2
// CHECK: %5 = lvx.mv %1 : (!lvx.reg<r0>) -> !lvx.reg<r0>
// CHECK-NEXT: lvx_cf.br ^bb1(%5, %4 : !lvx.reg<r0>, !lvx.reg<r4>)
// CHECK-NEXT: ^bb1(%6: !lvx.reg<r0>, %7: !lvx.reg<r4>):
// CHECK-NEXT: %8 = lvx.compd lt %6, %2 : (<r0>, <r2>) -> <r29>
// CHECK-NEXT: lvx_cf.cond_br wnez %8 : <r29>, ^bb2(%6, %7 : !lvx.reg<r0>, !lvx.reg<r4>), ^bb3(%7 : !lvx.reg<r4>)
// CHECK-NEXT: ^bb2(%9: !lvx.reg<r0>, %10: !lvx.reg<r4>):
// CHECK-NEXT: %11 = lvx.addd %10, %0 : (<r4>, <r1>) -> <r4>
// CHECK-NEXT: %12 = lvx.addd %6, %3 : (<r0>, <r3>) -> <r0>
// CHECK-NEXT: lvx_cf.br ^bb1(%12, %11 : !lvx.reg<r0>, !lvx.reg<r4>)
// CHECK-NEXT: ^bb3(%13: !lvx.reg<r4>):
// CHECK-NEXT: %14 = lvx.mv %13 : (!lvx.reg<r4>) -> !lvx.reg<r0>
// CHECK-NEXT: lvx_func.return %14 : !lvx.reg<r0>
lvx_func.func @loop_step2(%a: !lvx.reg<r0>) -> !lvx.reg<r0> {
  %ov = lvx.mv %a : (!lvx.reg<r0>) -> !lvx.reg
  %lb = lvx.li 0 : i64 : !lvx.reg
  %ub = lvx.li 10 : i64 : !lvx.reg
  %step = lvx.li 2 : i64 : !lvx.reg
  %init = lvx.li 0 : i64 : !lvx.reg
  %r = lvx_scf.for %lb : !lvx.reg to %ub : !lvx.reg step %step : !lvx.reg iter_args(%init) : (!lvx.reg) -> (!lvx.reg) {
  ^bb0(%iv: !lvx.reg, %acc: !lvx.reg):
    %use = lvx.addd %acc, %ov : (!lvx.reg, !lvx.reg) -> !lvx.reg
    lvx_scf.yield %use : !lvx.reg
  }
  %p = lvx.mv %r : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %p : !lvx.reg<r0>
}

// A loop with a nested lvx_scf.for: the outer loop is excluded from the
// hardware-loop path (LC/LS/LE are a single register set, not a stack --
// docs/lvx/HardwareLoops.md, "No nesting") and uses the branch-based
// lowering (compd/cond_br, %7), while the inner loop -- itself a leaf,
// step 1 -- independently takes the hardware-loop path on its own turn
// (lvx_cf.loopdo, %10/^bb3). The accumulator channel (%3 init / %6+%9
// outer iterArg / %13 inner iterArg / %14 inner yield+result / %16 outer
// yield / %18 outer result) all share register r3 across *both* nesting
// levels -- the fix for docs/lvx/RegisterAllocation.md's "coalescing
// across nesting levels": the inner loop's own result (%14, via the
// group ^bb4 feeds from) is the outer loop's directly-yielded operand,
// which used to make this either fail verification or crash this pass.
// CHECK-LABEL: lvx_func.func @nested
// CHECK: %3 = lvx.li 0 : i64 : <r3>
// CHECK: lvx_cf.br ^bb1(%4, %3 : !lvx.reg<r4>, !lvx.reg<r3>)
// CHECK-NEXT: ^bb1(%5: !lvx.reg<r4>, %6: !lvx.reg<r3>):
// CHECK-NEXT: %7 = lvx.compd lt %5, %1 : (<r4>, <r1>) -> <r29>
// CHECK-NEXT: lvx_cf.cond_br wnez %7 : <r29>, ^bb2(%5, %6 : !lvx.reg<r4>, !lvx.reg<r3>), ^bb5(%6 : !lvx.reg<r3>)
// CHECK-NEXT: ^bb2(%8: !lvx.reg<r4>, %9: !lvx.reg<r3>):
// CHECK-NEXT: %10 = lvx.sbfd %1, %0 : (<r1>, <r0>) -> <r29>
// CHECK-NEXT: %11 = lvx.mv %0 : (!lvx.reg<r0>) -> !lvx.reg<r0>
// CHECK-NEXT: lvx_cf.loopdo %10 : <r29>, ^bb3(%11, %9 : !lvx.reg<r0>, !lvx.reg<r3>), ^bb4(%9 : !lvx.reg<r3>)
// CHECK-NEXT: ^bb3(%12: !lvx.reg<r0>, %13: !lvx.reg<r3>):
// CHECK-NEXT: %14 = lvx.addd %13, %12 : (<r3>, <r0>) -> <r3>
// CHECK-NEXT: %15 = lvx.addd %12, %2 : (<r0>, <r2>) -> <r0>
// CHECK-NEXT: lvx_cf.br ^bb4(%14 : !lvx.reg<r3>)
// CHECK-NEXT: ^bb4(%16: !lvx.reg<r3>):
// CHECK-NEXT: %17 = lvx.addd %5, %2 : (<r4>, <r2>) -> <r4>
// CHECK-NEXT: lvx_cf.br ^bb1(%17, %16 : !lvx.reg<r4>, !lvx.reg<r3>)
// CHECK-NEXT: ^bb5(%18: !lvx.reg<r3>):
// CHECK-NEXT: %19 = lvx.mv %18 : (!lvx.reg<r3>) -> !lvx.reg<r0>
// CHECK-NEXT: lvx_func.return %19 : !lvx.reg<r0>
lvx_func.func @nested(%a: !lvx.reg<r0>) -> !lvx.reg<r0> {
  %lb = lvx.li 0 : i64 : !lvx.reg
  %ub = lvx.li 10 : i64 : !lvx.reg
  %step = lvx.li 1 : i64 : !lvx.reg
  %init = lvx.li 0 : i64 : !lvx.reg
  %r = lvx_scf.for %lb : !lvx.reg to %ub : !lvx.reg step %step : !lvx.reg iter_args(%init) : (!lvx.reg) -> (!lvx.reg) {
  ^bb0(%iv: !lvx.reg, %acc: !lvx.reg):
    %r2 = lvx_scf.for %lb : !lvx.reg to %ub : !lvx.reg step %step : !lvx.reg iter_args(%acc) : (!lvx.reg) -> (!lvx.reg) {
    ^bb1(%iv2: !lvx.reg, %acc2: !lvx.reg):
      %use = lvx.addd %acc2, %iv2 : (!lvx.reg, !lvx.reg) -> !lvx.reg
      lvx_scf.yield %use : !lvx.reg
    }
    lvx_scf.yield %r2 : !lvx.reg
  }
  %p = lvx.mv %r : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %p : !lvx.reg<r0>
}

// Known, narrower remaining gap (docs/lvx/RegisterAllocation.md, "Nested
// lvx_scf.for": the paragraph after the fix): a value fed into a nested
// loop as its `iter_args` init *and* read again independently after that
// loop finishes gets coalesced into the same register the nested loop's
// own iterations physically overwrite, silently computing the wrong
// value. Not tested here (silent-wrong-code, not a clean failure, so
// there is no clean CHECK to write against it) -- flagged so it isn't
// rediscovered the hard way. Avoid combining an outer accumulator with a
// nested loop's result (`lvx.addd %acc, %innerResult` after the loop)
// until this is fixed; simply *replacing* the accumulator with the
// nested loop's result (yielding it directly, the case tested above) is
// unaffected.
