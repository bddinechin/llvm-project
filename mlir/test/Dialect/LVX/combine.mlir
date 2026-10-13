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

// 128 is in the family since the ISA upgrade of 2026-10-13, which added
// ADDX128 and ADDX256 -- the scales a byte stride actually has. This case
// has expected three different things as the ISA and the patterns moved: the
// multiply surviving, then a shift, now the fused add.
// CHECK-LABEL: lvx_func.func @fold_scale128
// CHECK-NOT: lvx.muld
// CHECK-NOT: lvx.slld_i
// CHECK: lvx.addx128d %arg0, %arg1
lvx_func.func @fold_scale128(%i: !lvx.reg<r0>, %base: !lvx.reg<r1>) -> !lvx.reg<r0> {
  %c = lvx.li 128 : i64 : !lvx.reg
  %m = lvx.muld %i, %c : (!lvx.reg<r0>, !lvx.reg) -> !lvx.reg
  %a = lvx.addd %m, %base : (!lvx.reg, !lvx.reg<r1>) -> !lvx.reg<r0>
  lvx_func.return %a : !lvx.reg<r0>
}

// The multiply feeds two adds, so folding it into either would leave the
// muld live for the other -- one instruction more, not fewer, and no ADDX.
// The shift pattern has no such problem: one shift serves both uses.
// CHECK-LABEL: lvx_func.func @no_fold_multi_use
// CHECK: lvx.slld_i %arg0, 2
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

// The real `signextw` modifier decides how a 32-bit result lands in the
// 64-bit register: bare = zero-extend, `.sx` = sign-extend
// (Description.yml, signextw members `[ ., .SX ]`).
//
// So `sxwd` folds into the producer as a modifier, and `zxwd` is not folded
// but *deleted* -- the bare form already zero-extends, making it redundant.
// CHECK-LABEL: lvx_func.func @fold_sxwd
// CHECK: lvx.addw sx
// CHECK-NOT: lvx.sxwd
lvx_func.func @fold_sxwd(%a: !lvx.reg<r0>, %b: !lvx.reg<r1>) -> !lvx.reg<r0> {
  %0 = lvx.addw %a, %b : (!lvx.reg<r0>, !lvx.reg<r1>) -> !lvx.reg
  %1 = lvx.sxwd %0 : (!lvx.reg) -> !lvx.reg
  %2 = lvx.mv %1 : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %2 : !lvx.reg<r0>
}

// CHECK-LABEL: lvx_func.func @drop_zxwd
// CHECK: lvx.mulw %arg0, %arg1
// CHECK-NOT: lvx.zxwd
// CHECK-NOT: lvx.mulw sx
lvx_func.func @drop_zxwd(%a: !lvx.reg<r0>, %b: !lvx.reg<r1>) -> !lvx.reg<r0> {
  %0 = lvx.mulw %a, %b : (!lvx.reg<r0>, !lvx.reg<r1>) -> !lvx.reg
  %1 = lvx.zxwd %0 : (!lvx.reg) -> !lvx.reg
  %2 = lvx.mv %1 : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %2 : !lvx.reg<r0>
}

// NEGATIVE: the producer has a second user, so setting `sx` would change
// the value that user sees. The zxwd case has no such restriction because
// it does not touch the producer -- but this one must not fire.
// CHECK-LABEL: lvx_func.func @no_fold_sxwd_multi_use
// CHECK: lvx.sxwd
// CHECK-NOT: lvx.addw sx
lvx_func.func @no_fold_sxwd_multi_use(%a: !lvx.reg<r0>, %b: !lvx.reg<r1>)
    -> !lvx.reg<r0> {
  %0 = lvx.addw %a, %b : (!lvx.reg<r0>, !lvx.reg<r1>) -> !lvx.reg
  %1 = lvx.sxwd %0 : (!lvx.reg) -> !lvx.reg
  %2 = lvx.addd %0, %1 : (!lvx.reg, !lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %2 : !lvx.reg<r0>
}

// `notw` folds too, as of 2026-08-05. Its format (ALU_BWRW) reserved the
// signextw encoding bit but never wired it into the operand list, so
// `notw.sx` was unencodable and the assembler rejected it; fixed in
// lvx-mds' Format.yml and confirmed against the rebuilt assembler. The
// whole ALU_BWRW family gained it: negw, absw, clzw, ctzw, clsw, cbsw too.
// CHECK-LABEL: lvx_func.func @fold_notw
// CHECK: lvx.notw sx
// CHECK-NOT: lvx.sxwd
lvx_func.func @fold_notw(%a: !lvx.reg<r0>) -> !lvx.reg<r0> {
  %0 = lvx.notw %a : (!lvx.reg<r0>) -> !lvx.reg
  %1 = lvx.sxwd %0 : (!lvx.reg) -> !lvx.reg
  %2 = lvx.mv %1 : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %2 : !lvx.reg<r0>
}

// NEGATIVE: a zxwd of an already-sign-extending op is doing real work.
// CHECK-LABEL: lvx_func.func @no_drop_zxwd_of_sx
// CHECK: lvx.addw sx
// CHECK: lvx.zxwd
lvx_func.func @no_drop_zxwd_of_sx(%a: !lvx.reg<r0>, %b: !lvx.reg<r1>)
    -> !lvx.reg<r0> {
  %0 = lvx.addw sx %a, %b : (!lvx.reg<r0>, !lvx.reg<r1>) -> !lvx.reg
  %1 = lvx.zxwd %0 : (!lvx.reg) -> !lvx.reg
  %2 = lvx.mv %1 : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %2 : !lvx.reg<r0>
}

// MLIR spells bitwise complement as `xor x, -1`, so without this fold
// `lvx.notw`/`notd` are unreachable from any input -- nothing else produces
// them. Two instructions become one, and the `lvx.li -1` dies with them.
// CHECK-LABEL: lvx_func.func @fold_eor_to_not
// CHECK: lvx.notd
// CHECK-NOT: lvx.eord
lvx_func.func @fold_eor_to_not(%a: !lvx.reg<r0>) -> !lvx.reg<r0> {
  %c = lvx.li -1 : i64 : !lvx.reg
  %0 = lvx.eord %a, %c : (!lvx.reg<r0>, !lvx.reg) -> !lvx.reg
  %1 = lvx.mv %0 : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %1 : !lvx.reg<r0>
}

// The fold must carry the signextw modifier across. FoldSxwdIntoW may have
// already set it on the eor, and building a fresh notw drops attributes --
// losing it turns a required sign-extension into a zero-extension, i.e. a
// wrong number rather than a failure. This case caught exactly that.
// CHECK-LABEL: lvx_func.func @fold_eor_to_not_keeps_sx
// CHECK: lvx.notw sx
// CHECK-NOT: lvx.sxwd
lvx_func.func @fold_eor_to_not_keeps_sx(%a: !lvx.reg<r0>) -> !lvx.reg<r0> {
  %c = lvx.li -1 : i32 : !lvx.reg
  %0 = lvx.eorw %a, %c : (!lvx.reg<r0>, !lvx.reg) -> !lvx.reg
  %1 = lvx.sxwd %0 : (!lvx.reg) -> !lvx.reg
  %2 = lvx.mv %1 : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %2 : !lvx.reg<r0>
}

// -----

// `taild(0, max(dim - offset, 0))` -> `taild(offset, dim)`: the loop-tail mask
// in one instruction instead of four.
//
// `taild` takes a base -- lane *i* active iff `base + i <u bound` -- so
// counting from a materialised zero over a subtracted, clamped bound is doing
// by hand what the instruction does. This is what every masked loop tail
// lowers to before the fold: `-lvx-lower-vector-transfers` masks an
// out-of-bounds transfer with `create_mask(dim - offset)` and
// `-convert-to-lvx` turns that into `sbfd` + `maxd_i` + `li 0` + `taild`.
//
// Sound only when `dim` and `offset` are both non-negative -- see the pattern
// for the case analysis; with a negative offset the two forms are exact
// inverses. Here `dim` is `lvx.li 13` and `offset` is the loop's induction
// variable over a lower bound of `lvx.li 0`.
// CHECK-LABEL: lvx_func.func @taild_tail
// CHECK: lvx_scf.for
// CHECK: lvx.taild v4 %arg{{[0-9]+}}, %{{[0-9]+}}
// CHECK-NOT: lvx.sbfd
// CHECK-NOT: lvx.maxd_i
lvx_func.func @taild_tail(%base: !lvx.reg<r0>) {
  %lb = lvx.li 0 : index : !lvx.reg
  %ub = lvx.li 13 : index : !lvx.reg
  %st = lvx.li 4 : index : !lvx.reg
  lvx_scf.for %lb : !lvx.reg to %ub : !lvx.reg step %st : !lvx.reg {
  ^bb0(%i: !lvx.reg):
    %n = lvx.sbfd %ub, %i : (!lvx.reg, !lvx.reg) -> !lvx.reg
    %c = lvx.maxd_i %n, 0 : i64 : (!lvx.reg) -> !lvx.reg
    %z = lvx.li 0 : i64 : !lvx.reg
    %m = lvx.taild v4 %z, %c : (!lvx.reg, !lvx.reg) -> !lvx.reg
    %e = lvx.extb4d %m : (!lvx.reg) -> !lvx.reg
    %v = lvx.masked_load %e, %base, 0 : i64 : (!lvx.reg, !lvx.reg<r0>) -> !lvx.pair
    lvx.masked_store %v, %e, %base, 0 : i64 : (!lvx.pair, !lvx.reg, !lvx.reg<r0>)
    lvx_scf.yield
  }
  lvx_func.return
}

// -----

// Not folded: the offset is a function argument, so nothing says it is
// non-negative, and with a negative offset `taild(offset, dim)` activates no
// lane where the clamped form activates every one. The four-op form stands.
// CHECK-LABEL: lvx_func.func @taild_unproven_offset
// CHECK: lvx.sbfd
// CHECK: lvx.maxd_i
// CHECK: lvx.taild v4 %{{[0-9]+}}, %{{[0-9]+}}
lvx_func.func @taild_unproven_offset(%base: !lvx.reg<r0>, %off: !lvx.reg<r1>) {
  %ub = lvx.li 13 : index : !lvx.reg
  %n = lvx.sbfd %ub, %off : (!lvx.reg, !lvx.reg<r1>) -> !lvx.reg
  %c = lvx.maxd_i %n, 0 : i64 : (!lvx.reg) -> !lvx.reg
  %z = lvx.li 0 : i64 : !lvx.reg
  %m = lvx.taild v4 %z, %c : (!lvx.reg, !lvx.reg) -> !lvx.reg
  %e = lvx.extb4d %m : (!lvx.reg) -> !lvx.reg
  %v = lvx.masked_load %e, %base, 0 : i64 : (!lvx.reg, !lvx.reg<r0>) -> !lvx.pair
  lvx.masked_store %v, %e, %base, 0 : i64 : (!lvx.pair, !lvx.reg, !lvx.reg<r0>)
  lvx_func.return
}

// A scale past the ADDX family -- which now reaches 256, so this is 512, the
// byte stride of a row of 128 floats -- becomes a shift. `slld` writes at
// stage 2 where `muld` writes at 3 and reserves an ALU_TINY where the
// multiply reserves an ALU_LITE, so it is a cycle off the dependence chain
// and the more plentiful unit (lvx-mlir/docs/Vectorization.md §4).
// CHECK-LABEL: lvx_func.func @fold_stride_to_shift
// CHECK-NOT: lvx.muld
// CHECK: lvx.slld_i %arg0, 9
lvx_func.func @fold_stride_to_shift(%i: !lvx.reg<r0>, %base: !lvx.reg<r1>)
    -> !lvx.reg<r0> {
  %c = lvx.li 512 : i64 : !lvx.reg
  %m = lvx.muld %i, %c : (!lvx.reg<r0>, !lvx.reg) -> !lvx.reg
  %a = lvx.addd %m, %base : (!lvx.reg, !lvx.reg<r1>) -> !lvx.reg<r0>
  lvx_func.return %a : !lvx.reg<r0>
}

// -----

// And 256 itself, the row of 64 floats that motivated the ISA addition: one
// `addx256d`, where before the upgrade it was a shift and an add.
// CHECK-LABEL: lvx_func.func @fold_scale256
// CHECK-NOT: lvx.slld_i
// CHECK: lvx.addx256d %arg0, %arg1
lvx_func.func @fold_scale256(%i: !lvx.reg<r0>, %base: !lvx.reg<r1>)
    -> !lvx.reg<r0> {
  %c = lvx.li 256 : i64 : !lvx.reg
  %m = lvx.muld %i, %c : (!lvx.reg<r0>, !lvx.reg) -> !lvx.reg
  %a = lvx.addd %m, %base : (!lvx.reg, !lvx.reg<r1>) -> !lvx.reg<r0>
  lvx_func.return %a : !lvx.reg<r0>
}

// -----

// A scale the ADDX family *does* encode stays with that fold, which is the
// better one: it removes the add as well. The shift pattern declines exactly
// where the ADDX pattern applies -- one use, that use being the add.
// CHECK-LABEL: lvx_func.func @addx_still_wins
// CHECK-NOT: lvx.slld_i
// CHECK: lvx.addx8d
lvx_func.func @addx_still_wins(%i: !lvx.reg<r0>, %base: !lvx.reg<r1>)
    -> !lvx.reg<r0> {
  %c = lvx.li 8 : i64 : !lvx.reg
  %m = lvx.muld %i, %c : (!lvx.reg<r0>, !lvx.reg) -> !lvx.reg
  %a = lvx.addd %m, %base : (!lvx.reg, !lvx.reg<r1>) -> !lvx.reg<r0>
  lvx_func.return %a : !lvx.reg<r0>
}

// -----

// ...but a scale in the family whose multiply has a second use cannot go to
// ADDX (folding would duplicate the multiply), and the shift takes it.
// CHECK-LABEL: lvx_func.func @two_uses_take_the_shift
// CHECK-NOT: lvx.muld
// CHECK: lvx.slld_i %arg0, 3
lvx_func.func @two_uses_take_the_shift(%i: !lvx.reg<r0>, %base: !lvx.reg<r1>)
    -> !lvx.reg<r0> {
  %c = lvx.li 8 : i64 : !lvx.reg
  %m = lvx.muld %i, %c : (!lvx.reg<r0>, !lvx.reg) -> !lvx.reg
  %a = lvx.addd %m, %base : (!lvx.reg, !lvx.reg<r1>) -> !lvx.reg<r0>
  %b = lvx.addd %m, %a : (!lvx.reg, !lvx.reg<r0>) -> !lvx.reg<r0>
  lvx_func.return %b : !lvx.reg<r0>
}

// -----

// A multiply by a non-power-of-two is left alone, and so is one by 1 (an
// identity fold, not this pattern's business).
// CHECK-LABEL: lvx_func.func @not_a_power_of_two
// CHECK: lvx.muld
// CHECK-NOT: lvx.slld_i
lvx_func.func @not_a_power_of_two(%i: !lvx.reg<r0>) -> !lvx.reg<r0> {
  %c = lvx.li 24 : i64 : !lvx.reg
  %m = lvx.muld %i, %c : (!lvx.reg<r0>, !lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %m : !lvx.reg<r0>
}
