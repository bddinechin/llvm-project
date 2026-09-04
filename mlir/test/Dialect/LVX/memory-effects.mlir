// RUN: mlir-opt %s -canonicalize | FileCheck %s --check-prefix=DEAD
// RUN: mlir-opt %s -lvx-allocate-registers -canonicalize | FileCheck %s --check-prefix=LIVE

// `lvx.ld` and `lvx.sd` carry real memory effects, generated from the machine
// description's `analysis` (`%0: ReadsMemory` / `WritesMemory`). Before that
// they declared none at all, which MLIR reads as "unknown effects" -- safe,
// but opaque to every pass.
//
// The declaration has a consequence worth a test of its own: by MLIR's own
// rule (`wouldOpBeTriviallyDead`) an op whose only effect is a read and whose
// results are unused is dead. That is right for an ordinary load...
func.func @dead_load(%base: !lvx.reg) {
  %unused = lvx.ld %base, 0 : i64 : (!lvx.reg) -> !lvx.reg
  return
}
// DEAD-LABEL: func.func @dead_load
// DEAD-NOT:     lvx.ld
// DEAD:       return

// ...and a store is never dead, whatever is or is not done with it.
func.func @live_store(%value: !lvx.reg, %base: !lvx.reg) {
  lvx.sd %value, %base, 0 : i64 : (!lvx.reg, !lvx.reg)
  return
}
// DEAD-LABEL: func.func @live_store
// DEAD:         lvx.sd

// ...but it is WRONG for a callee-saved restore, which is an `lvx.ld` whose
// result is a pinned physical register that nothing in the IR reads -- the
// value it produces is the register's contents, not an SSA value. Deleting it
// leaves the caller's r14 clobbered, an ABI violation against any
// lvx-gcc-compiled caller, arrived at silently.
//
// `lvx.reg_live_out` is what stops it: it emits no assembly and only says the
// register must hold that value on exit. This is the regression guard --
// without it, one of the two restores below disappears here.
lvx_func.func private @callee(!lvx.reg<r0>) -> !lvx.reg<r0>
lvx_func.func @caller(%a: !lvx.reg<r0>) -> !lvx.reg<r0> {
  %live = lvx.mv %a : (!lvx.reg<r0>) -> !lvx.reg
  %r = lvx_func.call @callee(%a) : (!lvx.reg<r0>) -> !lvx.reg<r0>
  %sum = lvx.addd %live, %r : (!lvx.reg, !lvx.reg<r0>) -> !lvx.reg
  %out = lvx.mv %sum : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %out : !lvx.reg<r0>
}
// The callee-saved restore and the $ra restore both survive.
// LIVE-LABEL: lvx_func.func @caller
// LIVE:         lvx.ld
// LIVE-NEXT:    lvx.reg_live_out
// LIVE:         lvx.ld
// LIVE:         lvx.set
