//===- IntrinsicsLVX.td - Defines LVX intrinsics -----------*- tablegen -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// The LVX-specific intrinsics.
//
// This file exists because most LVX builtins do NOT need it: clang lowers them
// to generic IR -- llvm.copysign, llvm.minnum, a shift, a multiply -- which is
// what keeps them optimisable and is why there was no IntrinsicsLVX.td until
// 2026-10-08. A target intrinsic is for the instructions generic IR cannot
// spell, and it should stay that way: reach for generic IR first.
//
//===----------------------------------------------------------------------===//

let TargetPrefix = "lvx" in {

// TAILD -- a lane mask from a loop's own bounds. Bit i of the result is set
// iff i < lanes and base + i <u bound, bits at and above `lanes' cleared; the
// third operand is the lanecount ENCODING, 0..7 for .v1 .. .v128, which is
// log2 of the lane count and must be a constant because it is an instruction
// modifier rather than an operand.
//
// The encoding is i64, not the i32 an ImmArg would normally be, and it has to
// be: LVX is LP64 with no i32 among its legal types (LVXISelLowering adds
// register classes for i64, i128, v4i64 and the FP types, and nothing else).
// An i32 intrinsic operand therefore has no type set to infer from, and
// TableGen rejects any pattern matching this intrinsic with "Type set is empty
// for each HW mode" -- reported against TargetSelectionDAG.td's `vtInt', which
// is a cascade and says nothing about the real cause.
//
// NOTE, for whoever wires masking properly: these are exactly the semantics of
// the generic @llvm.get.active.lane.mask(base, n), which the loop vectorizer
// already emits for a tail-folded loop. Going through that intrinsic instead of
// this one is what would make TAILD reachable from the vectorizer rather than
// only from a builtin -- but it returns <N x i1>, and LVX wants the mask packed
// one bit per lane in a GPR, so it needs the mask-type work first. This
// intrinsic is the builtin's path, not the vectorizer's.
def int_lvx_taild
    : DefaultAttrsIntrinsic<[llvm_i64_ty],
                            [llvm_i64_ty, llvm_i64_ty, llvm_i64_ty],
                            [IntrNoMem, IntrSpeculatable,
                             ImmArg<ArgIndex<2>>]>;

} // let TargetPrefix = "lvx"
