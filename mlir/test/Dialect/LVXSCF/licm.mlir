// RUN: mlir-opt %s --pass-pipeline='builtin.module(any(loop-invariant-code-motion))' | FileCheck %s

// `lvx_scf.for` implements LoopLikeOpInterface so that upstream's LICM can
// hoist what `-convert-to-lvx` leaves inside a loop: the conversion
// materializes an address computation at every access, and the part of it
// that does not depend on the induction variable is loop-invariant work
// created *after* every upstream pass that could have moved it. Without the
// interface this pass is a byte-for-byte no-op -- it does not recognize the
// op as a loop at all -- which is what this test exists to keep from
// regressing silently (lvx-mlir/docs/Vectorization.md §4).

// The row stride, the multiply by the outer index and the add onto the base
// are invariant and must end up before the loop; the two adds that involve
// the induction variable and the accumulator must stay in it.

// CHECK-LABEL: func @hoist_invariant_address
// CHECK:         lvx.li 512
// CHECK:         lvx.muld
// CHECK:         lvx.addd
// CHECK:         lvx_scf.for
// CHECK:           lvx.addd
// CHECK:           lvx.addd
// CHECK:           lvx_scf.yield
lvx_func.func @hoist_invariant_address(%lb: !lvx.reg, %ub: !lvx.reg,
                                       %step: !lvx.reg, %base: !lvx.reg,
                                       %row: !lvx.reg, %init: !lvx.reg)
    -> !lvx.reg {
  %r = lvx_scf.for %lb : !lvx.reg to %ub : !lvx.reg step %step : !lvx.reg
       iter_args(%init) : (!lvx.reg) -> (!lvx.reg) {
  ^bb0(%iv: !lvx.reg, %acc: !lvx.reg):
    %stride = lvx.li 512 : index : !lvx.reg
    %off = lvx.muld %row, %stride : (!lvx.reg, !lvx.reg) -> !lvx.reg
    %addr = lvx.addd %base, %off : (!lvx.reg, !lvx.reg) -> !lvx.reg
    %elem = lvx.addd %addr, %iv : (!lvx.reg, !lvx.reg) -> !lvx.reg
    %next = lvx.addd %acc, %elem : (!lvx.reg, !lvx.reg) -> !lvx.reg
    lvx_scf.yield %next : !lvx.reg
  }
  lvx_func.return %r : !lvx.reg
}

// -----

// The boundary: a load reads memory, so it is not pure and stays put however
// invariant its address looks. Only `isPure` ops move.

// CHECK-LABEL: func @load_stays
// CHECK:         lvx_scf.for
// CHECK:           lvx.ld
// CHECK:           lvx_scf.yield
lvx_func.func @load_stays(%lb: !lvx.reg, %ub: !lvx.reg, %step: !lvx.reg,
                          %base: !lvx.reg, %init: !lvx.reg) -> !lvx.reg {
  %r = lvx_scf.for %lb : !lvx.reg to %ub : !lvx.reg step %step : !lvx.reg
       iter_args(%init) : (!lvx.reg) -> (!lvx.reg) {
  ^bb0(%iv: !lvx.reg, %acc: !lvx.reg):
    %v = lvx.ld %base, 0 : i64 : (!lvx.reg) -> !lvx.reg
    %next = lvx.addd %acc, %v : (!lvx.reg, !lvx.reg) -> !lvx.reg
    lvx_scf.yield %next : !lvx.reg
  }
  lvx_func.return %r : !lvx.reg
}
