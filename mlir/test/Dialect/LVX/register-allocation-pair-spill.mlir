// RUN: mlir-opt %s --pass-pipeline='builtin.module(any(lvx-allocate-registers{max-registers=4}))' | FileCheck %s

// Spilling with tuples (lvx-mlir/docs/RegisterAllocation.md, "Step 4",
// "The scan" and "Spilling a tuple"), with the pool shrunk to four units,
// r0..r3 (`max-registers` bounds units at every width). r0 and r1 hold the
// arguments throughout, so the pool has one aligned pair, r2r3, and it is
// contended by every pair and by the singles r2 and r3.

// A pair evicting two singles: with the pool r0..r3 and r0/r1 holding the
// arguments, `%a` and `%b` take r2 and r3; the pair then needs r2r3 -- the
// only aligned pair in the pool -- and both singles outlive it, so both are
// evicted (each to its own 8-byte slot) and the pair takes the block.
// CHECK-LABEL: lvx_func.func @pair_evicts
// CHECK-NEXT: %0 = lvx.sp : !lvx.reg<r12>
// CHECK-NEXT: %1 = lvx.li 16 : i64 : !lvx.reg<r61>
// CHECK-NEXT: %2 = lvx.sbfd %0, %1 : (!lvx.reg<r12>, !lvx.reg<r61>) -> !lvx.reg<r12>
// CHECK-NEXT: %3 = lvx.addd %arg1, %arg1 : (!lvx.reg<r1>, !lvx.reg<r1>) -> !lvx.reg<r61>
// CHECK-NEXT: lvx.sd %3, %2, 0 : i64 : (!lvx.reg<r61>, !lvx.reg<r12>)
// CHECK-NEXT: %4 = lvx.ld %2, 0 : i64 : (!lvx.reg<r12>) -> !lvx.reg<r61>
// CHECK-NEXT: %5 = lvx.addd %arg1, %4 : (!lvx.reg<r1>, !lvx.reg<r61>) -> !lvx.reg<r61>
// CHECK-NEXT: lvx.sd %5, %2, 8 : i64 : (!lvx.reg<r61>, !lvx.reg<r12>)
// CHECK-NEXT: %6 = lvx.splatwq %arg1 : (!lvx.reg<r1>) -> !lvx.pair<r2r3>
// CHECK-NEXT: lvx.sq %6, %arg0, 0 : i64 : (!lvx.pair<r2r3>, !lvx.reg<r0>)
// CHECK-NEXT: %7 = lvx.ld %2, 0 : i64 : (!lvx.reg<r12>) -> !lvx.reg<r61>
// CHECK-NEXT: lvx.sd %7, %arg0, 16 : i64 : (!lvx.reg<r61>, !lvx.reg<r0>)
// CHECK-NEXT: %8 = lvx.ld %2, 8 : i64 : (!lvx.reg<r12>) -> !lvx.reg<r61>
// CHECK-NEXT: lvx.sd %8, %arg0, 24 : i64 : (!lvx.reg<r61>, !lvx.reg<r0>)
// CHECK-NEXT: %9 = lvx.li 16 : i64 : !lvx.reg<r61>
// CHECK-NEXT: %10 = lvx.addd %2, %9 : (!lvx.reg<r12>, !lvx.reg<r61>) -> !lvx.reg<r12>
// CHECK-NEXT: lvx_func.return
lvx_func.func @pair_evicts(%base: !lvx.reg<r0>, %x: !lvx.reg<r1>) {
  %a = lvx.addd %x, %x : (!lvx.reg<r1>, !lvx.reg<r1>) -> !lvx.reg
  %b = lvx.addd %x, %a : (!lvx.reg<r1>, !lvx.reg) -> !lvx.reg
  %p = lvx.splatwq %x : (!lvx.reg<r1>) -> !lvx.pair
  lvx.sq %p, %base, 0 : i64 : (!lvx.pair, !lvx.reg<r0>)
  lvx.sd %a, %base, 16 : i64 : (!lvx.reg, !lvx.reg<r0>)
  lvx.sd %b, %base, 24 : i64 : (!lvx.reg, !lvx.reg<r0>)
  lvx_func.return
}

// A single evicting a pair: the pair holds r2r3 and outlives `%a`, so `%a`
// takes r2 and the pair is spilled -- stored whole with `sq` from the
// scratch pair r62r63 right after its def (16-byte slot, 16-byte aligned)
// and reloaded with `lq` into the same scratch at its use.
// CHECK-LABEL: lvx_func.func @single_evicts_pair
// CHECK-NEXT: %0 = lvx.sp : !lvx.reg<r12>
// CHECK-NEXT: %1 = lvx.li 16 : i64 : !lvx.reg<r61>
// CHECK-NEXT: %2 = lvx.sbfd %0, %1 : (!lvx.reg<r12>, !lvx.reg<r61>) -> !lvx.reg<r12>
// CHECK-NEXT: %3 = lvx.splatwq %arg1 : (!lvx.reg<r1>) -> !lvx.pair<r62r63>
// CHECK-NEXT: lvx.sq %3, %2, 0 : i64 : (!lvx.pair<r62r63>, !lvx.reg<r12>)
// CHECK-NEXT: %4 = lvx.addd %arg1, %arg1 : (!lvx.reg<r1>, !lvx.reg<r1>) -> !lvx.reg<r2>
// CHECK-NEXT: lvx.sd %4, %arg0, 16 : i64 : (!lvx.reg<r2>, !lvx.reg<r0>)
// CHECK-NEXT: %5 = lvx.lq %2, 0 : i64 : (!lvx.reg<r12>) -> !lvx.pair<r62r63>
// CHECK-NEXT: lvx.sq %5, %arg0, 0 : i64 : (!lvx.pair<r62r63>, !lvx.reg<r0>)
// CHECK-NEXT: %6 = lvx.li 16 : i64 : !lvx.reg<r61>
// CHECK-NEXT: %7 = lvx.addd %2, %6 : (!lvx.reg<r12>, !lvx.reg<r61>) -> !lvx.reg<r12>
// CHECK-NEXT: lvx_func.return
lvx_func.func @single_evicts_pair(%base: !lvx.reg<r0>, %x: !lvx.reg<r1>) {
  %p = lvx.splatwq %x : (!lvx.reg<r1>) -> !lvx.pair
  %a = lvx.addd %x, %x : (!lvx.reg<r1>, !lvx.reg<r1>) -> !lvx.reg
  lvx.sd %a, %base, 16 : i64 : (!lvx.reg, !lvx.reg<r0>)
  lvx.sq %p, %base, 0 : i64 : (!lvx.pair, !lvx.reg<r0>)
  lvx_func.return
}

// A lane group spills as one block (lvx-mlir/docs/RegisterAllocation.md,
// "Lane groups are spillable"): the divmod pair outlives `%a`/`%b`, so it
// is evicted for them. The pair is stored once at its slot; the `lvx.lane`
// views are erased, and each use of the quotient reloads a single at the
// slot (`ld ... 0`), of the remainder at slot + 8 (`ld ... 8`); the pair's
// own use reloads it whole (`lq ... 0`). One op reading both lanes gets
// two singles of scratch, r61 and r62.
// CHECK-LABEL: lvx_func.func @lane_group_spills
// CHECK-NEXT: %0 = lvx.sp : !lvx.reg<r12>
// CHECK-NEXT: %1 = lvx.li 16 : i64 : !lvx.reg<r61>
// CHECK-NEXT: %2 = lvx.sbfd %0, %1 : (!lvx.reg<r12>, !lvx.reg<r61>) -> !lvx.reg<r12>
// CHECK-NEXT: %3 = lvx.divmodd %arg1, %arg1 : (!lvx.reg<r1>, !lvx.reg<r1>) -> !lvx.pair<r62r63>
// CHECK-NEXT: lvx.sq %3, %2, 0 : i64 : (!lvx.pair<r62r63>, !lvx.reg<r12>)
// CHECK-NEXT: %4 = lvx.addd %arg1, %arg1 : (!lvx.reg<r1>, !lvx.reg<r1>) -> !lvx.reg<r2>
// CHECK-NEXT: %5 = lvx.addd %arg1, %4 : (!lvx.reg<r1>, !lvx.reg<r2>) -> !lvx.reg<r3>
// CHECK-NEXT: lvx.sd %4, %arg0, 32 : i64 : (!lvx.reg<r2>, !lvx.reg<r0>)
// CHECK-NEXT: lvx.sd %5, %arg0, 40 : i64 : (!lvx.reg<r3>, !lvx.reg<r0>)
// CHECK-NEXT: %6 = lvx.ld %2, 0 : i64 : (!lvx.reg<r12>) -> !lvx.reg<r61>
// CHECK-NEXT: lvx.sd %6, %arg0, 16 : i64 : (!lvx.reg<r61>, !lvx.reg<r0>)
// CHECK-NEXT: %7 = lvx.ld %2, 0 : i64 : (!lvx.reg<r12>) -> !lvx.reg<r61>
// CHECK-NEXT: %8 = lvx.ld %2, 8 : i64 : (!lvx.reg<r12>) -> !lvx.reg<r62>
// CHECK-NEXT: %9 = lvx.addd %7, %8 : (!lvx.reg<r61>, !lvx.reg<r62>) -> !lvx.reg<r1>
// CHECK-NEXT: lvx.sd %9, %arg0, 24 : i64 : (!lvx.reg<r1>, !lvx.reg<r0>)
// CHECK-NEXT: %10 = lvx.lq %2, 0 : i64 : (!lvx.reg<r12>) -> !lvx.pair<r62r63>
// CHECK-NEXT: lvx.sq %10, %arg0, 0 : i64 : (!lvx.pair<r62r63>, !lvx.reg<r0>)
// CHECK-NEXT: %11 = lvx.li 16 : i64 : !lvx.reg<r61>
// CHECK-NEXT: %12 = lvx.addd %2, %11 : (!lvx.reg<r12>, !lvx.reg<r61>) -> !lvx.reg<r12>
// CHECK-NEXT: lvx_func.return
lvx_func.func @lane_group_spills(%base: !lvx.reg<r0>, %x: !lvx.reg<r1>) {
  %qr = lvx.divmodd %x, %x : (!lvx.reg<r1>, !lvx.reg<r1>) -> !lvx.pair
  %q = lvx.lane %qr[0] : (!lvx.pair) -> !lvx.reg
  %r = lvx.lane %qr[1] : (!lvx.pair) -> !lvx.reg
  %a = lvx.addd %x, %x : (!lvx.reg<r1>, !lvx.reg<r1>) -> !lvx.reg
  %b = lvx.addd %x, %a : (!lvx.reg<r1>, !lvx.reg) -> !lvx.reg
  lvx.sd %a, %base, 32 : i64 : (!lvx.reg, !lvx.reg<r0>)
  lvx.sd %b, %base, 40 : i64 : (!lvx.reg, !lvx.reg<r0>)
  lvx.sd %q, %base, 16 : i64 : (!lvx.reg, !lvx.reg<r0>)
  %sum = lvx.addd %q, %r : (!lvx.reg, !lvx.reg) -> !lvx.reg
  lvx.sd %sum, %base, 24 : i64 : (!lvx.reg, !lvx.reg<r0>)
  lvx.sq %qr, %base, 0 : i64 : (!lvx.pair, !lvx.reg<r0>)
  lvx_func.return
}
