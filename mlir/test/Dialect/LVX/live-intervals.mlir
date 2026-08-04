// RUN: mlir-opt %s --pass-pipeline='builtin.module(any(lvx-print-live-intervals))' -mlir-disable-threading -o /dev/null 2>&1 | FileCheck %s

// Straight-line code: a simple sequential chain of defs/uses, plus
// ABI-pinned fixed intervals for the entry arguments and the pinned
// return value.
// CHECK-LABEL: Testing : straight
// CHECK-NEXT: %arg0 : [0, 1] fixed=r0
// CHECK-NEXT: %arg1 : [0, 2] fixed=r1
// CHECK-NEXT: %0 : [1, 4]
// CHECK-NEXT: %1 : [2, 3]
// CHECK-NEXT: %2 : [3, 4]
// CHECK-NEXT: %3 : [4, 5]
// CHECK-NEXT: %4 : [5, 6] fixed=r0
lvx_func.func @straight(%a: !lvx.reg<r0>, %b: !lvx.reg<r1>) -> !lvx.reg<r0> {
  %0 = lvx.mv %a : (!lvx.reg<r0>) -> !lvx.reg
  %1 = lvx.mv %b : (!lvx.reg<r1>) -> !lvx.reg
  %2 = lvx.addd %0, %1 : (!lvx.reg, !lvx.reg) -> !lvx.reg
  %3 = lvx.muld %2, %0 : (!lvx.reg, !lvx.reg) -> !lvx.reg
  %4 = lvx.mv %3 : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %4 : !lvx.reg<r0>
}

// A branch diamond: `%ov` is defined in the entry block, passes through
// `^bb1` untouched, and is only used in `^bb2`. Its computed interval
// spans the whole way through, covering the block it passes through with
// no direct reference in it.
// CHECK-LABEL: Testing : branches
// CHECK-NEXT: %arg0 : [0, 1] fixed=r0
// CHECK-NEXT: %arg1 : [0, 2] fixed=r1
// CHECK-NEXT: %0 : [1, 7]
// CHECK-NEXT: %1 : [2, 3]
// CHECK-NEXT: %2 : [7, 8]
// CHECK-NEXT: %3 : [8, 9] fixed=r0
lvx_func.func @branches(%a: !lvx.reg<r0>, %cond: !lvx.reg<r1>) -> !lvx.reg<r0> {
  %ov = lvx.mv %a : (!lvx.reg<r0>) -> !lvx.reg
  %c = lvx.mv %cond : (!lvx.reg<r1>) -> !lvx.reg
  lvx_cf.cond_br wnez %c : !lvx.reg, ^bb1, ^bb2
^bb1:
  lvx_cf.br ^bb2
^bb2:
  %r = lvx.addd %ov, %ov : (!lvx.reg, !lvx.reg) -> !lvx.reg
  %p = lvx.mv %r : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %p : !lvx.reg<r0>
}

// `lvx_scf.for`: `%ov` is captured from the enclosing scope and used
// inside the loop body -- its interval is force-extended to the body's
// last op (`%7`, the terminator), not just its own last-explicit-use
// point (`%1`, the addd inside the body), the same "captured value must
// span the whole loop" reasoning applied to every value
// `getUsedValuesDefinedAbove` finds referenced inside a `lvx_scf.for`'s
// body but defined outside it (lvx-mlir/docs/HardwareLoops.md, "hardware-loop
// clobber bug"): if this loop were itself nested inside another one, its
// whole body -- including whatever register `%ov` shares once its own
// last use has passed -- re-executes on the next outer iteration, and
// `%ov`'s original value is needed again at that point. `%arg1` (the
// induction variable) has no explicit use in this body, and `%3` (the
// `step` operand) has no use anywhere in the original IR but as the `for`
// op's own operand -- both intervals are also force-extended to the
// body's last op, because `-lvx-scf-to-cf` always synthesizes an
// implicit "iv = iv + step" increment there for *both* lowering paths,
// reading both values, invisible to this pass's own SSA-use walk. A
// kernel whose body actually reads iv (unlike this hand-written test)
// would otherwise let some other value's live range overlap and clobber
// iv's (or step's) register before that synthesized increment ever runs.
// `%arg2` (the loop-carried accumulator) and the yielded value each get
// their own honest, separate interval, since they are distinct SSA
// values.
// CHECK-LABEL: Testing : loop
// CHECK-NEXT: %arg0 : [0, 1] fixed=r0
// CHECK-NEXT: %0 : [1, 9]
// CHECK-NEXT: %1 : [2, 6]
// CHECK-NEXT: %2 : [3, 6]
// CHECK-NEXT: %3 : [4, 9]
// CHECK-NEXT: %4 : [5, 6]
// CHECK-NEXT: %5 : [6, 10]
// CHECK-NEXT: %arg1 : [7, 9]
// CHECK-NEXT: %arg2 : [7, 8]
// CHECK-NEXT: %7 : [8, 9]
// CHECK-NEXT: %6 : [10, 11] fixed=r0
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

// A nested `lvx_scf.for` whose inner loop reuses the outer loop's own
// bounds/step (`%lb`/`%ub`/`%step`, `%0`/`%1`/`%2` below) verbatim as its
// own bound operands -- the exact shape that exposed the hardware-loop
// clobber bug (lvx-mlir/docs/HardwareLoops.md, lvx-mlir/docs/RegisterAllocation.md
// "Captured values across a re-entered loop"). Without the fix, `%0`'s
// interval (its "own" recorded last use is the *inner* for-op's operand
// list) would end at instruction 3 -- one less than `%arg3` (the inner
// loop's own induction variable, a block argument starting at 4) -- so
// the two would look non-overlapping and free to share a register, even
// though the entire inner loop re-executes on every outer iteration.
// With the fix, `%0`/`%1`/`%2` are each extended all the way to 11 (the
// *outer* body's own last instruction), covering not just the inner
// for-op's own operand-list use but the loop's entire re-executable span.
// CHECK-LABEL: Testing : nested_captured_bound
// CHECK-NEXT: %arg0 : [0, 0] fixed=r0
// CHECK-NEXT: %0 : [1, 11]
// CHECK-NEXT: %1 : [2, 11]
// CHECK-NEXT: %2 : [3, 11]
// CHECK-NEXT: %3 : [4, 5]
// CHECK-NEXT: %4 : [5, 12]
// CHECK-NEXT: %arg1 : [6, 11]
// CHECK-NEXT: %arg2 : [6, 7]
// CHECK-NEXT: %6 : [7, 11]
// CHECK-NEXT: %arg3 : [8, 10]
// CHECK-NEXT: %arg4 : [8, 9]
// CHECK-NEXT: %7 : [9, 10]
// CHECK-NEXT: %5 : [12, 13] fixed=r0
lvx_func.func @nested_captured_bound(%a: !lvx.reg<r0>) -> !lvx.reg<r0> {
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
