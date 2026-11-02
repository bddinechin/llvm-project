// RUN: mlir-opt %s --pass-pipeline='builtin.module(any(lvx-allocate-registers))' | FileCheck %s

// Ties: an operand read through the destination shares the result's register,
// so the op overwrites it, and every other reader must read before that or
// read a copy. Which side gets the copy depends on whether the op's result
// comes back into that operand through the loop.

// The accumulator recurs (`acc = ffma(x, y, acc)` yielded back) and is also
// read after the ffma. A private copy *into* the ffma cannot work here: the
// tie joins the copy to the result and the loop channel joins the result to
// the accumulator, so all three share a register and the fmulw reads the new
// accumulator. The fmulw reads a copy made before the ffma instead, in a
// register of its own, while the ffma keeps the channel's register.
// CHECK-LABEL: lvx_func.func @recurrent_accumulator_read_after
// CHECK:       ^bb0(%{{.*}}: !lvx.reg<r{{[0-9]+}}>, %[[ACC:.*]]: !lvx.reg<[[R:r[0-9]+]]>):
// CHECK:         %[[KEEP:.*]] = lvx.mv %[[ACC]] : (!lvx.reg<[[R]]>) -> !lvx.reg<[[K:r[0-9]+]]>
// CHECK:         lvx.ffmaw %{{.*}}, %{{.*}}, %[[ACC]] : ({{.*}}, !lvx.reg<[[R]]>) -> !lvx.reg<[[R]]>
// CHECK:         lvx.fmulw %[[KEEP]], %{{.*}} : (!lvx.reg<[[K]]>,
// CHECK-NOT:     lvx.fmulw %[[ACC]]
lvx_func.func @recurrent_accumulator_read_after(%arg0: !lvx.reg<r0>, %arg1: !lvx.reg<r1>, %arg2: !lvx.reg<r2>) -> !lvx.reg<r0> {
  %0 = lvx.mv %arg0 : (!lvx.reg<r0>) -> !lvx.reg
  %1 = lvx.mv %arg1 : (!lvx.reg<r1>) -> !lvx.reg
  %2 = lvx.mv %arg2 : (!lvx.reg<r2>) -> !lvx.reg
  %3 = lvx.li 0 : index : !lvx.reg
  %4 = lvx.li 1 : index : !lvx.reg
  %5 = lvx.li 64 : index : !lvx.reg
  %6 = lvx.li 0.000000e+00 : f32 : !lvx.reg
  %7 = lvx_scf.for %3 : !lvx.reg to %5 : !lvx.reg step %4 : !lvx.reg iter_args(%6) : (!lvx.reg) -> (!lvx.reg) {
  ^bb0(%arg3: !lvx.reg, %arg4: !lvx.reg):
    %9 = lvx.addx4d %arg3, %0 : (!lvx.reg, !lvx.reg) -> !lvx.reg
    %10 = lvx.lwz %9, 0 : i64 : (!lvx.reg) -> !lvx.reg
    %11 = lvx.addx4d %arg3, %1 : (!lvx.reg, !lvx.reg) -> !lvx.reg
    %12 = lvx.lwz %11, 0 : i64 : (!lvx.reg) -> !lvx.reg
    %13 = lvx.ffmaw %10, %12, %arg4 : (!lvx.reg, !lvx.reg, !lvx.reg) -> !lvx.reg
    %14 = lvx.fmulw %arg4, %10 : (!lvx.reg, !lvx.reg) -> !lvx.reg
    %15 = lvx.addx4d %arg3, %2 : (!lvx.reg, !lvx.reg) -> !lvx.reg
    lvx.sw %14, %15, 0 : i64 : (!lvx.reg, !lvx.reg)
    lvx_scf.yield %13 : !lvx.reg
  }
  %8 = lvx.mv %7 : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %8 : !lvx.reg<r0>
}

// A reader BEFORE the ffma needs nothing: it reads before the write. No copy.
// CHECK-LABEL: lvx_func.func @recurrent_accumulator_read_before
// CHECK:       ^bb0(%{{.*}}: !lvx.reg<r{{[0-9]+}}>, %[[ACC2:.*]]: !lvx.reg<[[R2:r[0-9]+]]>):
// CHECK-NOT:     lvx.mv
// CHECK:         lvx.fmulw %[[ACC2]]
// CHECK:         lvx.ffmaw %{{.*}}, %{{.*}}, %[[ACC2]] : ({{.*}}, !lvx.reg<[[R2]]>) -> !lvx.reg<[[R2]]>
lvx_func.func @recurrent_accumulator_read_before(%arg0: !lvx.reg<r0>, %arg1: !lvx.reg<r1>, %arg2: !lvx.reg<r2>) -> !lvx.reg<r0> {
  %0 = lvx.mv %arg0 : (!lvx.reg<r0>) -> !lvx.reg
  %1 = lvx.mv %arg1 : (!lvx.reg<r1>) -> !lvx.reg
  %2 = lvx.mv %arg2 : (!lvx.reg<r2>) -> !lvx.reg
  %3 = lvx.li 0 : index : !lvx.reg
  %4 = lvx.li 1 : index : !lvx.reg
  %5 = lvx.li 64 : index : !lvx.reg
  %6 = lvx.li 0.000000e+00 : f32 : !lvx.reg
  %7 = lvx_scf.for %3 : !lvx.reg to %5 : !lvx.reg step %4 : !lvx.reg iter_args(%6) : (!lvx.reg) -> (!lvx.reg) {
  ^bb0(%arg3: !lvx.reg, %arg4: !lvx.reg):
    %9 = lvx.addx4d %arg3, %0 : (!lvx.reg, !lvx.reg) -> !lvx.reg
    %10 = lvx.lwz %9, 0 : i64 : (!lvx.reg) -> !lvx.reg
    %11 = lvx.addx4d %arg3, %1 : (!lvx.reg, !lvx.reg) -> !lvx.reg
    %12 = lvx.lwz %11, 0 : i64 : (!lvx.reg) -> !lvx.reg
    %14 = lvx.fmulw %arg4, %10 : (!lvx.reg, !lvx.reg) -> !lvx.reg
    %13 = lvx.ffmaw %10, %12, %arg4 : (!lvx.reg, !lvx.reg, !lvx.reg) -> !lvx.reg
    %15 = lvx.addx4d %arg3, %2 : (!lvx.reg, !lvx.reg) -> !lvx.reg
    lvx.sw %14, %15, 0 : i64 : (!lvx.reg, !lvx.reg)
    lvx_scf.yield %13 : !lvx.reg
  }
  %8 = lvx.mv %7 : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %8 : !lvx.reg<r0>
}

// Not a recurrence: the accumulator's start is captured from outside the loop
// and read again on every trip, so the ffma overwriting it in place would
// corrupt the next trip. The ffma reads a private copy, and the captured value
// keeps a register the ffma never writes.
// CHECK-LABEL: lvx_func.func @captured_accumulator
// CHECK:         %[[INIT:.*]] = lvx.li 0.000000e+00 : f32 : !lvx.reg<[[I:r[0-9]+]]>
// CHECK:         %[[PRIV:.*]] = lvx.mv %[[INIT]] : (!lvx.reg<[[I]]>) -> !lvx.reg<[[P:r[0-9]+]]>
// CHECK:         lvx.ffmaw %{{.*}}, %{{.*}}, %[[PRIV]] : ({{.*}}, !lvx.reg<[[P]]>) -> !lvx.reg<[[P]]>
lvx_func.func @captured_accumulator(%arg0: !lvx.reg<r0>, %arg1: !lvx.reg<r1>, %arg2: !lvx.reg<r2>) {
  %0 = lvx.mv %arg0 : (!lvx.reg<r0>) -> !lvx.reg
  %1 = lvx.mv %arg1 : (!lvx.reg<r1>) -> !lvx.reg
  %2 = lvx.mv %arg2 : (!lvx.reg<r2>) -> !lvx.reg
  %3 = lvx.li 0 : index : !lvx.reg
  %4 = lvx.li 1 : index : !lvx.reg
  %5 = lvx.li 64 : index : !lvx.reg
  %6 = lvx.li 0.000000e+00 : f32 : !lvx.reg
  lvx_scf.for %3 : !lvx.reg to %5 : !lvx.reg step %4 : !lvx.reg {
  ^bb0(%arg3: !lvx.reg):
    %9 = lvx.addx4d %arg3, %0 : (!lvx.reg, !lvx.reg) -> !lvx.reg
    %10 = lvx.lwz %9, 0 : i64 : (!lvx.reg) -> !lvx.reg
    %11 = lvx.addx4d %arg3, %1 : (!lvx.reg, !lvx.reg) -> !lvx.reg
    %12 = lvx.lwz %11, 0 : i64 : (!lvx.reg) -> !lvx.reg
    %13 = lvx.ffmaw %10, %12, %6 : (!lvx.reg, !lvx.reg, !lvx.reg) -> !lvx.reg
    %15 = lvx.addx4d %arg3, %2 : (!lvx.reg, !lvx.reg) -> !lvx.reg
    lvx.sw %13, %15, 0 : i64 : (!lvx.reg, !lvx.reg)
    lvx_scf.yield
  }
  lvx_func.return
}
