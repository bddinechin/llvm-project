// RUN: mlir-opt %s --pass-pipeline='builtin.module(any(lvx-allocate-registers),any(lvx-scf-to-cf))' | FileCheck %s

// Must run after -lvx-allocate-registers (lvx-mlir/docs/AssemblyEmission.md,
// "lvx-scf-to-cf: lowering after allocation").

// A constant-step-1, non-nested loop is eligible for the hardware-loop
// path (lvx-mlir/docs/HardwareLoops.md): `lvx_cf.loopdo` replaces the
// compare+cond_br header entirely, and the induction variable's entry
// value is still copied in via an explicit `lvx.mv` (%6) for the same
// reason the branch-based path needs it -- the lower bound and the body's
// own induction-variable argument are independently allocated by Steps
// 1-3, with no guarantee they share a register.
// CHECK-LABEL: lvx_func.func @loop
// CHECK: %5 = lvx.sbfd %2, %1 : (!lvx.reg<r2>, !lvx.reg<r0>) -> !lvx.reg<r61>
// CHECK-NEXT: %6 = lvx.mv %1 : (!lvx.reg<r0>) -> !lvx.reg<r0>
// CHECK-NEXT: lvx_cf.loopdo %5 : !lvx.reg<r61>, ^bb1(%6, %4 : !lvx.reg<r0>, !lvx.reg<r4>), ^bb2(%4 : !lvx.reg<r4>)
// CHECK-NEXT: ^bb1(%7: !lvx.reg<r0>, %8: !lvx.reg<r4>):
// CHECK-NEXT: %9 = lvx.addd %8, %0 : (!lvx.reg<r4>, !lvx.reg<r1>) -> !lvx.reg<r4>
// CHECK-NEXT: %10 = lvx.addd %7, %3 : (!lvx.reg<r0>, !lvx.reg<r3>) -> !lvx.reg<r0>
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
// explicit compare (`lvx.compd lt`, pinned to r61 like the hardware
// loop's own trip-count value) and cond_br header, with the same
// induction-variable copy-in (%5) for the same reason.
// CHECK-LABEL: lvx_func.func @loop_step2
// CHECK: %5 = lvx.mv %1 : (!lvx.reg<r0>) -> !lvx.reg<r0>
// CHECK-NEXT: lvx_cf.br ^bb1(%5, %4 : !lvx.reg<r0>, !lvx.reg<r4>)
// CHECK-NEXT: ^bb1(%6: !lvx.reg<r0>, %7: !lvx.reg<r4>):
// CHECK-NEXT: %8 = lvx.compd lt %6, %2 : (!lvx.reg<r0>, !lvx.reg<r2>) -> !lvx.reg<r61>
// CHECK-NEXT: lvx_cf.cond_br wnez %8 : !lvx.reg<r61>, ^bb2(%6, %7 : !lvx.reg<r0>, !lvx.reg<r4>), ^bb3(%7 : !lvx.reg<r4>)
// CHECK-NEXT: ^bb2(%9: !lvx.reg<r0>, %10: !lvx.reg<r4>):
// CHECK-NEXT: %11 = lvx.addd %10, %0 : (!lvx.reg<r4>, !lvx.reg<r1>) -> !lvx.reg<r4>
// CHECK-NEXT: %12 = lvx.addd %6, %3 : (!lvx.reg<r0>, !lvx.reg<r3>) -> !lvx.reg<r0>
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
// lvx-mlir/docs/HardwareLoops.md, "No nesting") and uses the branch-based
// lowering (compd/cond_br, %7), while the inner loop -- itself a leaf,
// step 1 -- independently takes the hardware-loop path on its own turn
// (lvx_cf.loopdo, %10/^bb3). The accumulator channel (%3 init / %6+%9
// outer iterArg / %13 inner iterArg / %14 inner yield+result / %16 outer
// yield / %18 outer result) all share register r3 across *both* nesting
// levels -- the fix for lvx-mlir/docs/RegisterAllocation.md's "coalescing
// across nesting levels": the inner loop's own result (%14, via the
// group ^bb4 feeds from) is the outer loop's directly-yielded operand,
// which used to make this either fail verification or crash this pass.
//
// This test also, incidentally, reuses the outer loop's own bounds/step
// (%lb/%ub/%step) verbatim as the inner loop's -- exactly the shape that
// exposed the hardware-loop clobber bug (lvx-mlir/docs/HardwareLoops.md): `%0`
// (the shared lower bound, r0) used to get reused for the inner loop's
// own induction-variable copy too (`%11 = lvx.mv %0 : (!lvx.reg<r0>) ->
// !lvx.reg<r0>` -- a same-register self-copy, only "safe" because this
// test never checked what happens on the outer loop's *second* iteration,
// where the first iteration's inner-loop IV increments would have already
// overwritten r0's original bound value). Now fixed
// (`getUsedValuesDefinedAbove`-based capture extension in
// `LiveIntervals.cpp`): `%0` correctly stays live for the whole outer
// loop, and the inner IV's copy (`%11`) lands in a fresh register (`r5`)
// instead.
// CHECK-LABEL: lvx_func.func @nested
// CHECK: %3 = lvx.li 0 : i64 : !lvx.reg<r3>
// CHECK: lvx_cf.br ^bb1(%4, %3 : !lvx.reg<r4>, !lvx.reg<r3>)
// CHECK-NEXT: ^bb1(%5: !lvx.reg<r4>, %6: !lvx.reg<r3>):
// CHECK-NEXT: %7 = lvx.compd lt %5, %1 : (!lvx.reg<r4>, !lvx.reg<r1>) -> !lvx.reg<r61>
// CHECK-NEXT: lvx_cf.cond_br wnez %7 : !lvx.reg<r61>, ^bb2(%5, %6 : !lvx.reg<r4>, !lvx.reg<r3>), ^bb5(%6 : !lvx.reg<r3>)
// CHECK-NEXT: ^bb2(%8: !lvx.reg<r4>, %9: !lvx.reg<r3>):
// CHECK-NEXT: %10 = lvx.sbfd %1, %0 : (!lvx.reg<r1>, !lvx.reg<r0>) -> !lvx.reg<r61>
// CHECK-NEXT: %11 = lvx.mv %0 : (!lvx.reg<r0>) -> !lvx.reg<r5>
// CHECK-NEXT: lvx_cf.loopdo %10 : !lvx.reg<r61>, ^bb3(%11, %9 : !lvx.reg<r5>, !lvx.reg<r3>), ^bb4(%9 : !lvx.reg<r3>)
// CHECK-NEXT: ^bb3(%12: !lvx.reg<r5>, %13: !lvx.reg<r3>):
// CHECK-NEXT: %14 = lvx.addd %13, %12 : (!lvx.reg<r3>, !lvx.reg<r5>) -> !lvx.reg<r3>
// CHECK-NEXT: %15 = lvx.addd %12, %2 : (!lvx.reg<r5>, !lvx.reg<r2>) -> !lvx.reg<r5>
// CHECK-NEXT: lvx_cf.br ^bb4(%14 : !lvx.reg<r3>)
// CHECK-NEXT: ^bb4(%16: !lvx.reg<r3>):
// CHECK-NEXT: %17 = lvx.addd %5, %2 : (!lvx.reg<r4>, !lvx.reg<r2>) -> !lvx.reg<r4>
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

// Combined accumulator (fixed): `%acc` (the outer loop's own iterArg) is
// fed into the inner loop as its `iter_args` init *and* read again
// independently after that loop finishes, combined with its result
// (`%sum = lvx.addd %acc, %r2`) rather than simply replaced by it. This
// used to compile to a self-add (`addd $r3 = $r3, $r3`) -- both operands
// pinned to the same register by buildAllocItems's forced coalescing,
// silently observing whatever the inner loop's own iterations last left
// there instead of %acc's actual pre-loop value
// (lvx-mlir/docs/RegisterAllocation.md, "Nested lvx_scf.for": the paragraph
// after the fix). Fixed by `insertLoopCarriedPreservingCopies`
// (`RegisterAllocation.cpp`), which runs before Step 1 and inserts an
// explicit `lvx.mv` copy of any loop init-arg that has a use beyond that
// one operand: `%13 = lvx.mv %9` below (in `^bb2`, right before the
// inner loop's own `loopdo`) snapshots `%acc` (r3) into a fresh register
// (r6) *before* the inner loop runs, and the combining `addd` (`%21`)
// reads that snapshot, not the shared channel register -- no more
// self-add. The inner loop's own channel is untouched (still r3
// throughout, unaffected by the fix, since its only use of the
// pre-snapshot value is as its own init operand). Verified against the
// real toolchain end to end, not just structurally: assembled with the
// real `lvx-mbr-as` and executed on real `lvx-gem5` (10 outer iterations
// each combining a fresh 10-iteration inner sum-of-0..9, recurrence
// acc' = 2*acc + 45 from acc=0) exits with code 46035, matching the
// hand-derived expected result (`lvx-mlir/docs/EndToEndValidation.md`-style
// verification, not run separately as its own kernel here).
//
// The inner loop's own bounds (`%lb2`/`%ub2`/`%step2`) were originally
// kept deliberately *different* from the outer loop's (`%lb`/`%ub`/
// `%step`, contrast the `@nested` case above) to sidestep a second,
// separate bug found while first verifying this fix: the inner hardware
// loop's induction variable could land in the very register a reused
// outer-scope value (e.g. a shared lower bound) still occupied -- an
// ordinary, uncoalesced allocation coincidence, not a coalescing decision
// -- so the first outer iteration's inner loop would permanently
// overwrite that register before the second outer iteration re-entered
// the inner loop needing the original value again. **Now fixed** (same
// `getUsedValuesDefinedAbove`-based capture extension in
// `LiveIntervals.cpp` documented on `@nested` above, and exercised there
// directly with genuinely shared bounds) -- this test's own inner bounds
// remain independent `lvx.li`s regardless, since that's not what it's
// isolating.
// CHECK-LABEL: lvx_func.func @nested_combined_accumulator
// CHECK: lvx_cf.br ^bb1(%4, %3 : !lvx.reg<r0>, !lvx.reg<r3>)
// CHECK-NEXT: ^bb1(%5: !lvx.reg<r0>, %6: !lvx.reg<r3>):
// CHECK-NEXT: %7 = lvx.compd lt %5, %1 : (!lvx.reg<r0>, !lvx.reg<r1>) -> !lvx.reg<r61>
// CHECK-NEXT: lvx_cf.cond_br wnez %7 : !lvx.reg<r61>, ^bb2(%5, %6 : !lvx.reg<r0>, !lvx.reg<r3>), ^bb5(%6 : !lvx.reg<r3>)
// CHECK-NEXT: ^bb2(%8: !lvx.reg<r0>, %9: !lvx.reg<r3>):
// CHECK-NEXT: %10 = lvx.li 0 : i64 : !lvx.reg<r1>
// CHECK-NEXT: %11 = lvx.li 10 : i64 : !lvx.reg<r4>
// CHECK-NEXT: %12 = lvx.li 1 : i64 : !lvx.reg<r5>
// CHECK-NEXT: %13 = lvx.mv %9 : (!lvx.reg<r3>) -> !lvx.reg<r6>
// CHECK-NEXT: %14 = lvx.sbfd %11, %10 : (!lvx.reg<r4>, !lvx.reg<r1>) -> !lvx.reg<r61>
// CHECK-NEXT: %15 = lvx.mv %10 : (!lvx.reg<r1>) -> !lvx.reg<r1>
// CHECK-NEXT: lvx_cf.loopdo %14 : !lvx.reg<r61>, ^bb3(%15, %9 : !lvx.reg<r1>, !lvx.reg<r3>), ^bb4(%9 : !lvx.reg<r3>)
// CHECK-NEXT: ^bb3(%16: !lvx.reg<r1>, %17: !lvx.reg<r3>):
// CHECK-NEXT: %18 = lvx.addd %17, %16 : (!lvx.reg<r3>, !lvx.reg<r1>) -> !lvx.reg<r3>
// CHECK-NEXT: %19 = lvx.addd %16, %12 : (!lvx.reg<r1>, !lvx.reg<r5>) -> !lvx.reg<r1>
// CHECK-NEXT: lvx_cf.br ^bb4(%18 : !lvx.reg<r3>)
// CHECK-NEXT: ^bb4(%20: !lvx.reg<r3>):
// CHECK-NEXT: %21 = lvx.addd %13, %20 : (!lvx.reg<r6>, !lvx.reg<r3>) -> !lvx.reg<r3>
// CHECK-NEXT: %22 = lvx.addd %5, %2 : (!lvx.reg<r0>, !lvx.reg<r2>) -> !lvx.reg<r0>
// CHECK-NEXT: lvx_cf.br ^bb1(%22, %21 : !lvx.reg<r0>, !lvx.reg<r3>)
// CHECK-NEXT: ^bb5(%23: !lvx.reg<r3>):
// CHECK-NEXT: %24 = lvx.mv %23 : (!lvx.reg<r3>) -> !lvx.reg<r0>
// CHECK-NEXT: lvx_func.return %24 : !lvx.reg<r0>
lvx_func.func @nested_combined_accumulator(%a: !lvx.reg<r0>) -> !lvx.reg<r0> {
  %lb = lvx.li 0 : i64 : !lvx.reg
  %ub = lvx.li 10 : i64 : !lvx.reg
  %step = lvx.li 1 : i64 : !lvx.reg
  %init = lvx.li 0 : i64 : !lvx.reg
  %r = lvx_scf.for %lb : !lvx.reg to %ub : !lvx.reg step %step : !lvx.reg iter_args(%init) : (!lvx.reg) -> (!lvx.reg) {
  ^bb0(%iv: !lvx.reg, %acc: !lvx.reg):
    %lb2 = lvx.li 0 : i64 : !lvx.reg
    %ub2 = lvx.li 10 : i64 : !lvx.reg
    %step2 = lvx.li 1 : i64 : !lvx.reg
    %r2 = lvx_scf.for %lb2 : !lvx.reg to %ub2 : !lvx.reg step %step2 : !lvx.reg iter_args(%acc) : (!lvx.reg) -> (!lvx.reg) {
    ^bb1(%iv2: !lvx.reg, %acc2: !lvx.reg):
      %use = lvx.addd %acc2, %iv2 : (!lvx.reg, !lvx.reg) -> !lvx.reg
      lvx_scf.yield %use : !lvx.reg
    }
    %sum = lvx.addd %acc, %r2 : (!lvx.reg, !lvx.reg) -> !lvx.reg
    lvx_scf.yield %sum : !lvx.reg
  }
  %p = lvx.mv %r : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %p : !lvx.reg<r0>
}

// A loop whose body reads the induction variable for its own purposes
// (here: squaring it into the accumulator), not just to feed the implicit
// per-iteration increment `-lvx-scf-to-cf` synthesizes. This is the exact
// shape that exposed a real Step 1 live-interval gap
// (lvx-mlir/docs/EndToEndValidation.md, "Induction variable's live range didn't
// account for the lowering-synthesized increment"): `-lvx-allocate-
// registers` runs *before* this pass ever creates the synthesized
// increment, so without explicitly extending `%iv`'s (and `%step`'s) live
// interval to the body's last op, the intermediate `%sq` value below could
// legally get allocated the very register `%iv` or `%step` still needs at
// the body's end, silently corrupting every iteration after the first.
// `%0`/r0 (iv) and `%2`/r2 (step) both stay live across `%9`'s
// computation, confirming the fix: `%9` (the square) lands in a fresh
// register (r4), never reusing r0 or r2, and the synthesized increment at
// the end (`addd $r0 = $r0, $r2`, via `lowerForHardware`'s in-place
// `%next_iv`) reads back exactly the values that were live going in.
// CHECK-LABEL: lvx_func.func @loop_reads_iv
// CHECK: %4 = lvx.sbfd %1, %0 : (!lvx.reg<r1>, !lvx.reg<r0>) -> !lvx.reg<r61>
// CHECK-NEXT: %5 = lvx.mv %0 : (!lvx.reg<r0>) -> !lvx.reg<r0>
// CHECK-NEXT: lvx_cf.loopdo %4 : !lvx.reg<r61>, ^bb1(%5, %3 : !lvx.reg<r0>, !lvx.reg<r3>), ^bb2(%3 : !lvx.reg<r3>)
// CHECK-NEXT: ^bb1(%6: !lvx.reg<r0>, %7: !lvx.reg<r3>):
// CHECK-NEXT: %8 = lvx.mv %6 : (!lvx.reg<r0>) -> !lvx.reg<r1>
// CHECK-NEXT: %9 = lvx.muld %8, %8 : (!lvx.reg<r1>, !lvx.reg<r1>) -> !lvx.reg<r4>
// CHECK-NEXT: %10 = lvx.addd %7, %9 : (!lvx.reg<r3>, !lvx.reg<r4>) -> !lvx.reg<r3>
// CHECK-NEXT: %11 = lvx.addd %6, %2 : (!lvx.reg<r0>, !lvx.reg<r2>) -> !lvx.reg<r0>
// CHECK-NEXT: lvx_cf.br ^bb2(%10 : !lvx.reg<r3>)
// CHECK-NEXT: ^bb2(%12: !lvx.reg<r3>):
// CHECK-NEXT: %13 = lvx.mv %12 : (!lvx.reg<r3>) -> !lvx.reg<r0>
// CHECK-NEXT: lvx_func.return %13 : !lvx.reg<r0>
lvx_func.func @loop_reads_iv(%a: !lvx.reg<r0>) -> !lvx.reg<r0> {
  %lb = lvx.li 0 : i64 : !lvx.reg
  %ub = lvx.li 10 : i64 : !lvx.reg
  %step = lvx.li 1 : i64 : !lvx.reg
  %init = lvx.li 0 : i64 : !lvx.reg
  %r = lvx_scf.for %lb : !lvx.reg to %ub : !lvx.reg step %step : !lvx.reg iter_args(%init) : (!lvx.reg) -> (!lvx.reg) {
  ^bb0(%iv: !lvx.reg, %acc: !lvx.reg):
    %ivcopy = lvx.mv %iv : (!lvx.reg) -> !lvx.reg
    %sq = lvx.muld %ivcopy, %ivcopy : (!lvx.reg, !lvx.reg) -> !lvx.reg
    %use = lvx.addd %acc, %sq : (!lvx.reg, !lvx.reg) -> !lvx.reg
    lvx_scf.yield %use : !lvx.reg
  }
  %p = lvx.mv %r : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %p : !lvx.reg<r0>
}
