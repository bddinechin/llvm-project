// RUN: mlir-opt %s --pass-pipeline='builtin.module(any(lvx-allocate-registers))' | FileCheck %s

// Straight-line code. `%3`'s last use is as the operand of the very `mv`
// that defines the pinned return value `%4` (fixed r0) -- this exercises
// the fixed-interval boundary fix (see lvx-mlir/docs/RegisterAllocation.md,
// "Bail-out semantics"): %3 must not spuriously conflict with %4's r0 just
// because it's still nominally "active" at that exact instruction.
// CHECK-LABEL: lvx_func.func @straight
// CHECK-NEXT: %0 = lvx.mv %arg0 : (!lvx.reg<r0>) -> !lvx.reg<r2>
// CHECK-NEXT: %1 = lvx.mv %arg1 : (!lvx.reg<r1>) -> !lvx.reg<r0>
// CHECK-NEXT: %2 = lvx.addd %0, %1 : (<r2>, <r0>) -> <r1>
// CHECK-NEXT: %3 = lvx.muld %2, %0 : (<r1>, <r2>) -> <r0>
// CHECK-NEXT: %4 = lvx.mv %3 : (!lvx.reg<r0>) -> !lvx.reg<r0>
// CHECK-NEXT: lvx_func.return %4 : !lvx.reg<r0>
lvx_func.func @straight(%a: !lvx.reg<r0>, %b: !lvx.reg<r1>) -> !lvx.reg<r0> {
  %0 = lvx.mv %a : (!lvx.reg<r0>) -> !lvx.reg
  %1 = lvx.mv %b : (!lvx.reg<r1>) -> !lvx.reg
  %2 = lvx.addd %0, %1 : (!lvx.reg, !lvx.reg) -> !lvx.reg
  %3 = lvx.muld %2, %0 : (!lvx.reg, !lvx.reg) -> !lvx.reg
  %4 = lvx.mv %3 : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %4 : !lvx.reg<r0>
}

// A branch diamond: `%ov`/`%0` passes through `^bb1` with no direct
// reference in it and must keep one register the whole way through.
// CHECK-LABEL: lvx_func.func @branches
// CHECK-NEXT: %0 = lvx.mv %arg0 : (!lvx.reg<r0>) -> !lvx.reg<r2>
// CHECK-NEXT: %1 = lvx.mv %arg1 : (!lvx.reg<r1>) -> !lvx.reg<r0>
// CHECK-NEXT: lvx_cf.cond_br wnez %1 : <r0>, ^bb1, ^bb2
// CHECK: ^bb2:
// CHECK-NEXT: %2 = lvx.addd %0, %0 : (<r2>, <r2>) -> <r0>
// CHECK-NEXT: %3 = lvx.mv %2 : (!lvx.reg<r0>) -> !lvx.reg<r0>
// CHECK-NEXT: lvx_func.return %3 : !lvx.reg<r0>
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

// A `lvx_cf.br` carrying a block argument -- mirrors the shape
// `-convert-to-lvx`'s `FuncFuncToLVX` pattern always produces for a
// function's entry block (copy ABI args in, then branch into the real
// body block). The branch operand (`%0`) and the destination block
// argument (`^bb1`'s own `%1`) are two distinct SSA values with no
// explicit use connecting them beyond the branch edge itself -- they must
// still be coalesced into the same register, or the branch becomes
// unrepresentable in real assembly (no move mechanism exists for a plain
// `goto`). This is not hypothetical: this exact shape produced a
// type-mismatch verifier error the first time a real
// `-convert-to-lvx`-produced kernel was ever run through this pass end to
// end (lvx-mlir/docs/EndToEndValidation.md) -- every prior hand-written test
// happened to only use argument-less blocks for `lvx_cf.br`.
// CHECK-LABEL: lvx_func.func @branch_args
// CHECK-NEXT: %0 = lvx.mv %arg0 : (!lvx.reg<r0>) -> !lvx.reg<r1>
// CHECK-NEXT: lvx_cf.br ^bb1(%0 : !lvx.reg<r1>)
// CHECK-NEXT: ^bb1(%1: !lvx.reg<r1>):
// CHECK-NEXT: %2 = lvx.mv %1 : (!lvx.reg<r1>) -> !lvx.reg<r0>
// CHECK-NEXT: lvx_func.return %2 : !lvx.reg<r0>
lvx_func.func @branch_args(%a: !lvx.reg<r0>) -> !lvx.reg<r0> {
  %0 = lvx.mv %a : (!lvx.reg<r0>) -> !lvx.reg
  lvx_cf.br ^bb1(%0 : !lvx.reg)
^bb1(%1: !lvx.reg):
  %2 = lvx.mv %1 : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %2 : !lvx.reg<r0>
}

// `lvx_scf.for`: the loop-carried channel (`%init` -> `%acc` -> `%use` ->
// the op's own result `%r`) must all end up pinned to the *same* physical
// register, per `ForOp`'s own verifier -- this is the coalescing rule from
// lvx-mlir/docs/RegisterAllocation.md ("Loop-carried register coalescing").
// CHECK-LABEL: lvx_func.func @loop
// CHECK: %4 = lvx.li 0 : i64 : <r4>
// CHECK-NEXT: %5 = lvx_scf.for %1 : <r0> to %2 : <r2> step %3 : <r3> iter_args(%4) : (!lvx.reg<r4>) -> (!lvx.reg<r4>)
// CHECK-NEXT: ^bb0(%arg1: !lvx.reg<r0>, %arg2: !lvx.reg<r4>):
// CHECK-NEXT: %7 = lvx.addd %arg2, %0 : (<r4>, <r1>) -> <r4>
// CHECK-NEXT: lvx_scf.yield %7 : !lvx.reg<r4>
// CHECK: %6 = lvx.mv %5 : (!lvx.reg<r4>) -> !lvx.reg<r0>
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

// `%live` is defined before the call and used after it, so it must not
// land in a caller-saved register -- it should be forced into the first
// callee-saved candidate (r14), per the "Call clobbering" mechanism.
//
// `@caller` itself executes a call, so it's non-leaf and gets a
// prologue/epilogue purely for $ra even though nothing is spilled here
// (lvx-mlir/docs/RegisterAllocation.md, "Return-address save/restore"): $ra is
// snapshotted (`lvx.getra` + `lvx.sd`, both r61) right after the frame is
// established, and restored (`lvx.ld` + `lvx.setra`) right before the
// epilogue's stack-pointer restore -- otherwise `@callee`'s own `call`
// would silently overwrite `@caller`'s $ra before its own `ret` uses it.
//
// This also exercises the callee-saved save/restore: `%live` above is
// forced into r14, which is callee-saved, so the caller's own r14 has to
// be preserved. The frame is therefore 16 bytes, not 8 -- slot 0 for $ra,
// slot 8 for r14 -- and the prologue names the incoming register with
// `lvx.reg_live_in` (which emits nothing) so an ordinary `lvx.sd` can
// store it. The restore needs no such pseudo: an `lvx.ld` whose *result*
// is typed <r14> already is `ld $r14 = 8[$r12]`. Until this was added,
// `@caller` clobbered its caller's r14 outright -- an ABI violation
// against any lvx-gcc-compiled caller.
// CHECK-LABEL: lvx_func.func @caller
// CHECK-NEXT: %0 = lvx.sp : <r12>
// CHECK-NEXT: %1 = lvx.li 16 : i64 : <r61>
// CHECK-NEXT: %2 = lvx.sbfd %0, %1 : (<r12>, <r61>) -> <r12>
// CHECK-NEXT: %3 = lvx.getra : <r61>
// CHECK-NEXT: lvx.sd %3, %2, 0 : (<r61>, <r12>)
// CHECK-NEXT: %4 = lvx.reg_live_in : <r14>
// CHECK-NEXT: lvx.sd %4, %2, 8 : (<r14>, <r12>)
// CHECK-NEXT: %5 = lvx.mv %arg0 : (!lvx.reg<r0>) -> !lvx.reg<r14>
// CHECK-NEXT: %6 = lvx_func.call @callee(%arg0) : (!lvx.reg<r0>) -> !lvx.reg<r0>
// CHECK-NEXT: %7 = lvx.addd %5, %6 : (<r14>, <r0>) -> <r1>
// CHECK-NEXT: %8 = lvx.mv %7 : (!lvx.reg<r1>) -> !lvx.reg<r0>
// CHECK-NEXT: %9 = lvx.ld %2, 8 : (!lvx.reg<r12>) -> !lvx.reg<r14>
// CHECK-NEXT: %10 = lvx.ld %2, 0 : (!lvx.reg<r12>) -> !lvx.reg<r61>
// CHECK-NEXT: lvx.setra %10 : <r61>
// CHECK-NEXT: %11 = lvx.li 16 : i64 : <r61>
// CHECK-NEXT: %12 = lvx.addd %2, %11 : (<r12>, <r61>) -> <r12>
// CHECK-NEXT: lvx_func.return %8 : !lvx.reg<r0>
lvx_func.func private @callee(!lvx.reg<r0>) -> !lvx.reg<r0>
lvx_func.func @caller(%a: !lvx.reg<r0>) -> !lvx.reg<r0> {
  %live = lvx.mv %a : (!lvx.reg<r0>) -> !lvx.reg
  %r = lvx_func.call @callee(%a) : (!lvx.reg<r0>) -> !lvx.reg<r0>
  %use = lvx.addd %live, %r : (!lvx.reg, !lvx.reg<r0>) -> !lvx.reg
  %p = lvx.mv %use : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %p : !lvx.reg<r0>
}

// `lvx.ffmad`/`lvx.ffmsd`/`lvx.ffmaw`/`lvx.ffmsw` have no separate
// destination register on real hardware -- the `c` operand and the op's
// own result must be coalesced into one physical register
// (lvx-mlir/docs/RegisterAllocation.md, "`ffma`/`ffms` accumulator
// coalescing"): `%2`/`%4` below both land in `r1`. `%2` (the accumulator)
// is *also* read again after the ffma (`%5`'s second operand), so
// `insertFmaAccumulatorPreservingCopies` must insert a defensive copy
// (`%3`, independently allocated to `r2`) before the ffma clobbers `r1` in
// place -- `%5` reads `%3`, not `%2`, getting the correct pre-ffma value.
// CHECK-LABEL: lvx_func.func @ffma_preserve
// CHECK-NEXT: %0 = lvx.mv %arg0 : (!lvx.reg<r0>) -> !lvx.reg<r3>
// CHECK-NEXT: %1 = lvx.mv %arg1 : (!lvx.reg<r1>) -> !lvx.reg<r0>
// CHECK-NEXT: %2 = lvx.mv %arg2 : (!lvx.reg<r2>) -> !lvx.reg<r1>
// CHECK-NEXT: %3 = lvx.mv %2 : (!lvx.reg<r1>) -> !lvx.reg<r2>
// CHECK-NEXT: %4 = lvx.ffmad cs %0, %1, %2 : (<r3>, <r0>, <r1>) -> <r1>
// CHECK-NEXT: %5 = lvx.addd %4, %3 : (<r1>, <r2>) -> <r0>
// CHECK-NEXT: %6 = lvx.mv %5 : (!lvx.reg<r0>) -> !lvx.reg<r0>
// CHECK-NEXT: lvx_func.return %6 : !lvx.reg<r0>
lvx_func.func @ffma_preserve(%a: !lvx.reg<r0>, %b: !lvx.reg<r1>, %acc: !lvx.reg<r2>) -> !lvx.reg<r0> {
  %0 = lvx.mv %a : (!lvx.reg<r0>) -> !lvx.reg
  %1 = lvx.mv %b : (!lvx.reg<r1>) -> !lvx.reg
  %2 = lvx.mv %acc : (!lvx.reg<r2>) -> !lvx.reg
  %3 = lvx.ffmad cs %0, %1, %2 : (!lvx.reg, !lvx.reg, !lvx.reg) -> !lvx.reg
  %4 = lvx.addd %3, %2 : (!lvx.reg, !lvx.reg) -> !lvx.reg
  %p = lvx.mv %4 : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %p : !lvx.reg<r0>
}
