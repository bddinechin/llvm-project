// RUN: mlir-opt %s --pass-pipeline='builtin.module(any(lvx-combine))' | FileCheck %s

// `addd(muld(x, 2^n), b)` becomes one `addx<2^n>d`. This is the shape every
// affine array index has, and it is what makes the address arithmetic in
// examples/mymma.mlir collapse -- see lvx-mlir/docs/InstructionSelection.md.
// CHECK-LABEL: lvx_func.func @fold_scale4
// CHECK-NOT: lvx.muld
// CHECK: lvx.addx4d %arg0, %arg1
lvx_func.func @fold_scale4(%i: !lvx.reg<r0>, %base: !lvx.reg<r1>) -> !lvx.reg<r0> {
  %c = lvx.li 4 : i64 : !lvx.reg
  %m = lvx.muld %i, %c : (!lvx.reg<r0>, !lvx.reg) -> !lvx.reg
  %a = lvx.addd %m, %base : (!lvx.reg, !lvx.reg<r1>) -> !lvx.reg<r0>
  lvx_func.return %a : !lvx.reg<r0>
}

// Every scale in the family, and the constant may sit on either side of the
// multiply.
// CHECK-LABEL: lvx_func.func @fold_scale64
// CHECK: lvx.addx64d
lvx_func.func @fold_scale64(%i: !lvx.reg<r0>, %base: !lvx.reg<r1>) -> !lvx.reg<r0> {
  %c = lvx.li 64 : i64 : !lvx.reg
  %m = lvx.muld %c, %i : (!lvx.reg, !lvx.reg<r0>) -> !lvx.reg
  %a = lvx.addd %base, %m : (!lvx.reg<r1>, !lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %a : !lvx.reg<r0>
}

// 32-bit forms go to the `w` instructions.
// CHECK-LABEL: lvx_func.func @fold_word
// CHECK: lvx.addx8w
lvx_func.func @fold_word(%i: !lvx.reg<r0>, %base: !lvx.reg<r1>) -> !lvx.reg<r0> {
  %c = lvx.li 8 : i32 : !lvx.reg
  %m = lvx.mulw %i, %c : (!lvx.reg<r0>, !lvx.reg) -> !lvx.reg
  %a = lvx.addw %m, %base : (!lvx.reg, !lvx.reg<r1>) -> !lvx.reg<r0>
  lvx_func.return %a : !lvx.reg<r0>
}

// NEGATIVE: 3 is not a power of two, so there is no addx3d and the multiply
// must survive. A pattern that folded this would emit an instruction the
// assembler does not have.
// CHECK-LABEL: lvx_func.func @no_fold_scale3
// CHECK: lvx.muld
// CHECK-NOT: lvx.addx
lvx_func.func @no_fold_scale3(%i: !lvx.reg<r0>, %base: !lvx.reg<r1>) -> !lvx.reg<r0> {
  %c = lvx.li 3 : i64 : !lvx.reg
  %m = lvx.muld %i, %c : (!lvx.reg<r0>, !lvx.reg) -> !lvx.reg
  %a = lvx.addd %m, %base : (!lvx.reg, !lvx.reg<r1>) -> !lvx.reg<r0>
  lvx_func.return %a : !lvx.reg<r0>
}

// NEGATIVE: 128 is a power of two but beyond the family (scales stop at 64).
// CHECK-LABEL: lvx_func.func @no_fold_scale128
// CHECK: lvx.muld
// CHECK-NOT: lvx.addx
lvx_func.func @no_fold_scale128(%i: !lvx.reg<r0>, %base: !lvx.reg<r1>) -> !lvx.reg<r0> {
  %c = lvx.li 128 : i64 : !lvx.reg
  %m = lvx.muld %i, %c : (!lvx.reg<r0>, !lvx.reg) -> !lvx.reg
  %a = lvx.addd %m, %base : (!lvx.reg, !lvx.reg<r1>) -> !lvx.reg<r0>
  lvx_func.return %a : !lvx.reg<r0>
}

// NEGATIVE: the multiply feeds two adds, so folding it into either would
// leave the muld live for the other -- one instruction more, not fewer.
// CHECK-LABEL: lvx_func.func @no_fold_multi_use
// CHECK: lvx.muld
// CHECK-NOT: lvx.addx
lvx_func.func @no_fold_multi_use(%i: !lvx.reg<r0>, %b1: !lvx.reg<r1>,
                                 %b2: !lvx.reg<r2>) -> !lvx.reg<r0> {
  %c = lvx.li 4 : i64 : !lvx.reg
  %m = lvx.muld %i, %c : (!lvx.reg<r0>, !lvx.reg) -> !lvx.reg
  %a1 = lvx.addd %m, %b1 : (!lvx.reg, !lvx.reg<r1>) -> !lvx.reg
  %a2 = lvx.addd %m, %b2 : (!lvx.reg, !lvx.reg<r2>) -> !lvx.reg
  %s = lvx.addd %a1, %a2 : (!lvx.reg, !lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %s : !lvx.reg<r0>
}
