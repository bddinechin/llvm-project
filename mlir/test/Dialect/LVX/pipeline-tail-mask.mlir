// RUN: mlir-opt %s -lvx-pipeline -split-input-file | FileCheck %s

// The kernel drops the loop-tail mask (docs/SoftwarePipelining.md §8). Only
// the last iteration can be partial, and the kernel holds no instance of it:
// with a run-time count the remainder copy runs 1..K iterations, never 0 --
// at kunroll 1 one is peeled for it -- and with a constant count the
// kernel's trips stop short of a partial last iteration. So in the kernel a mask that is the
// loop tail's -- `taild(iv, ub)`, or `taild(0, max(ub - iv, 0))` before
// `-lvx-combine` can fold it -- is all ones, and the access is the plain
// `lq`/`sq`. The prologue, the remainder copy and the drains keep the mask,
// except where an access reads a mask the kernel made: that instance is of
// an iteration the kernel began, a full one.

// A run-time count, the unfolded mask, kunroll 2: the kernel is two plain
// loads and two plain stores, and neither computes nor carries a mask. The
// remainder stores what the kernel loaded unmasked and masks its own.
// CHECK-LABEL: lvx_func.func @runtime
// CHECK: lvx.masked_load
// CHECK: lvx_scf.for {{.*}} iter_args({{[^)]*}}) : (!lvx.pair, !lvx.pair)
// CHECK-NEXT: ^bb0
// CHECK-NEXT: lvx.sq
// CHECK-NEXT: lvx.lq
// CHECK-NEXT: lvx.sq
// CHECK-NEXT: lvx.lq
// CHECK-NEXT: lvx_scf.yield
// CHECK-NEXT: } {lvx.kernel_period = 2 : i64}
// CHECK-NEXT: lvx.sq %[[K:.*]]#0,
// CHECK: lvx.taild
// CHECK: lvx.masked_load
// CHECK: lvx_scf.if deqz
// CHECK-NEXT: lvx.sq %[[K]]#1,
// CHECK-NEXT: lvx.masked_store
lvx_func.func @runtime(%base: !lvx.reg<r0>, %n: !lvx.reg<r1>) {
  %lo = lvx.li 0 : i64 : !lvx.reg
  %st = lvx.li 4 : i64 : !lvx.reg
  %z = lvx.li 0 : i64 : !lvx.reg
  lvx_scf.for %lo : !lvx.reg to %n : !lvx.reg<r1> step %st : !lvx.reg {
  ^bb0(%i: !lvx.reg):
    %d = lvx.sbfd %n, %i {lvx.stage = 0 : i64} : (!lvx.reg<r1>, !lvx.reg) -> !lvx.reg
    %c = lvx.maxd_i %d, 0 : i64 {lvx.stage = 0 : i64} : (!lvx.reg) -> !lvx.reg
    %t = lvx.taild v4 %z, %c {lvx.stage = 0 : i64} : (!lvx.reg, !lvx.reg) -> !lvx.reg
    %m = lvx.extb4d %t {lvx.stage = 0 : i64} : (!lvx.reg) -> !lvx.reg
    %v = lvx.masked_load %m, %base, 0 : i64 {lvx.stage = 0 : i64} : (!lvx.reg, !lvx.reg<r0>) -> !lvx.pair
    lvx.masked_store %v, %m, %base, 16 : i64 {lvx.stage = 2 : i64} : (!lvx.pair, !lvx.reg, !lvx.reg<r0>)
    lvx_scf.yield
  }
  lvx_func.return
}

// -----

// A constant count, 29 by 4: eight iterations, the last with one lane. At
// kunroll 2 the exit falls on the kernel's last loopback, which would put
// the partial iteration in the kernel; the last trip is peeled instead, so
// the kernel runs iterations 2..5 unmasked and 6..7 keep their masks.
// CHECK-LABEL: lvx_func.func @constant
// CHECK: lvx_scf.for {{.*}} iter_args({{[^)]*}}) : (!lvx.pair, !lvx.pair)
// CHECK-NOT: masked
// CHECK-NOT: taild
// CHECK: lvx.kernel_period = 2
// CHECK: lvx.taild
// CHECK: lvx.masked_load
// CHECK: lvx.taild
// CHECK: lvx.masked_load
// CHECK: lvx.masked_store
// CHECK: lvx.masked_store
lvx_func.func @constant(%base: !lvx.reg<r0>) {
  %lo = lvx.li 0 : i64 : !lvx.reg
  %hi = lvx.li 29 : i64 : !lvx.reg
  %st = lvx.li 4 : i64 : !lvx.reg
  lvx_scf.for %lo : !lvx.reg to %hi : !lvx.reg step %st : !lvx.reg {
  ^bb0(%i: !lvx.reg):
    %t = lvx.taild v4 %i, %hi {lvx.stage = 0 : i64} : (!lvx.reg, !lvx.reg) -> !lvx.reg
    %m = lvx.extb4d %t {lvx.stage = 0 : i64} : (!lvx.reg) -> !lvx.reg
    %v = lvx.masked_load %m, %base, 0 : i64 {lvx.stage = 0 : i64} : (!lvx.reg, !lvx.reg<r0>) -> !lvx.pair
    lvx.masked_store %v, %m, %base, 16 : i64 {lvx.stage = 2 : i64} : (!lvx.pair, !lvx.reg, !lvx.reg<r0>)
    lvx_scf.yield
  }
  lvx_func.return
}

// -----

// kunroll 1 with a run-time count: without a remainder copy the kernel's
// last trip would be the last iteration, so the K >= 2 arrangement is taken
// at K = 1 -- M - 1 - L0 kernel trips, then the last iteration in a one-
// iteration remainder copy, masked, before the drain.
// CHECK-LABEL: lvx_func.func @kunroll1
// CHECK: lvx_scf.for {{.*}} iter_args({{[^)]*}}) : (!lvx.pair)
// CHECK-NEXT: ^bb0
// CHECK-NEXT: lvx.sq
// CHECK-NEXT: lvx.lq
// CHECK-NEXT: lvx_scf.yield
// CHECK-NEXT: } {lvx.kernel_period = 1 : i64}
// CHECK-NEXT: lvx.sq
// CHECK: lvx.taild
// CHECK: lvx.masked_load
// CHECK-NEXT: lvx.masked_store
// CHECK-NEXT: lvx_scf.break
lvx_func.func @kunroll1(%base: !lvx.reg<r0>, %n: !lvx.reg<r1>) {
  %lo = lvx.li 0 : i64 : !lvx.reg
  %st = lvx.li 4 : i64 : !lvx.reg
  lvx_scf.for %lo : !lvx.reg to %n : !lvx.reg<r1> step %st : !lvx.reg {
  ^bb0(%i: !lvx.reg):
    %t = lvx.taild v4 %i, %n {lvx.stage = 0 : i64} : (!lvx.reg, !lvx.reg<r1>) -> !lvx.reg
    %m = lvx.extb4d %t {lvx.stage = 0 : i64} : (!lvx.reg) -> !lvx.reg
    %v = lvx.masked_load %m, %base, 0 : i64 {lvx.stage = 0 : i64} : (!lvx.reg, !lvx.reg<r0>) -> !lvx.pair
    lvx.masked_store %v, %m, %base, 16 : i64 {lvx.stage = 1 : i64} : (!lvx.pair, !lvx.reg, !lvx.reg<r0>)
    lvx_scf.yield
  }
  lvx_func.return
}

// -----

// Refused: the bound is not the loop's, so the mask may be partial on any
// iteration. The kernel keeps every mask.
// CHECK-LABEL: lvx_func.func @otherbound
// CHECK: lvx_scf.for
// CHECK-NEXT: ^bb0
// CHECK-NEXT: lvx.masked_store
// CHECK-NEXT: lvx.taild
// CHECK-NEXT: lvx.extb4d
// CHECK-NEXT: lvx.masked_load
// CHECK-NEXT: lvx.masked_store
lvx_func.func @otherbound(%base: !lvx.reg<r0>, %n: !lvx.reg<r1>, %b: !lvx.reg<r2>) {
  %lo = lvx.li 0 : i64 : !lvx.reg
  %st = lvx.li 4 : i64 : !lvx.reg
  lvx_scf.for %lo : !lvx.reg to %n : !lvx.reg<r1> step %st : !lvx.reg {
  ^bb0(%i: !lvx.reg):
    %t = lvx.taild v4 %i, %b {lvx.stage = 0 : i64} : (!lvx.reg, !lvx.reg<r2>) -> !lvx.reg
    %m = lvx.extb4d %t {lvx.stage = 0 : i64} : (!lvx.reg) -> !lvx.reg
    %v = lvx.masked_load %m, %base, 0 : i64 {lvx.stage = 0 : i64} : (!lvx.reg, !lvx.reg<r0>) -> !lvx.pair
    lvx.masked_store %v, %m, %base, 16 : i64 {lvx.stage = 2 : i64} : (!lvx.pair, !lvx.reg, !lvx.reg<r0>)
    lvx_scf.yield
  }
  lvx_func.return
}

// -----

// The mask chain split across stages: `n - iv` a stage before the rest.
// The chain is neither cloned into the kernel nor carried out of it; the
// remainder and the drain recompute each link from their iteration's
// induction value.
// CHECK-LABEL: lvx_func.func @split
// CHECK: lvx_scf.for {{.*}} iter_args({{[^)]*}}) : (!lvx.pair)
// CHECK-NEXT: ^bb0
// CHECK-NEXT: lvx.sq
// CHECK-NEXT: lvx.lq
// CHECK-NEXT: lvx_scf.yield
// CHECK-NEXT: } {lvx.kernel_period = 1 : i64}
// CHECK-NEXT: lvx.sq
// CHECK-NEXT: %[[IV:.*]] = lvx.addd_i
// CHECK-NEXT: lvx.sbfd %{{.*}}, %[[IV]]
// CHECK-NEXT: lvx.maxd_i
// CHECK-NEXT: lvx.taild
lvx_func.func @split(%base: !lvx.reg<r0>, %n: !lvx.reg<r1>) {
  %lo = lvx.li 0 : i64 : !lvx.reg
  %st = lvx.li 4 : i64 : !lvx.reg
  %z = lvx.li 0 : i64 : !lvx.reg
  lvx_scf.for %lo : !lvx.reg to %n : !lvx.reg<r1> step %st : !lvx.reg {
  ^bb0(%i: !lvx.reg):
    %d = lvx.sbfd %n, %i {lvx.stage = 0 : i64} : (!lvx.reg<r1>, !lvx.reg) -> !lvx.reg
    %c = lvx.maxd_i %d, 0 : i64 {lvx.stage = 1 : i64} : (!lvx.reg) -> !lvx.reg
    %t = lvx.taild v4 %z, %c {lvx.stage = 1 : i64} : (!lvx.reg, !lvx.reg) -> !lvx.reg
    %m = lvx.extb4d %t {lvx.stage = 1 : i64} : (!lvx.reg) -> !lvx.reg
    %v = lvx.masked_load %m, %base, 0 : i64 {lvx.stage = 1 : i64} : (!lvx.reg, !lvx.reg<r0>) -> !lvx.pair
    lvx.masked_store %v, %m, %base, 16 : i64 {lvx.stage = 2 : i64} : (!lvx.pair, !lvx.reg, !lvx.reg<r0>)
    lvx_scf.yield
  }
  lvx_func.return
}
