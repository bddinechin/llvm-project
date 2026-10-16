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

// STSUD -- one step of a restoring unsigned division:
//
//   rW = (rY >=u rZ) ? ((rY - rZ) << 1) | 1 : rY << 1
//
// so a divide loop is one instruction per quotient bit: the new remainder is
// rW >> 1 and the quotient bit is rW & 1. Note the operand order, which the
// mnemonic prints and this intrinsic keeps: `stsud $rW = $rZ, $rY' subtracts
// the FIRST source from the SECOND -- the second is the running remainder, the
// first the divisor. A swap agrees on every input where rY >=u rZ and differs
// only below that line.
//
// This one is a judgement call against the rule above, and worth stating:
// generic IR CAN spell the value (icmp, sub, two shls, or, select), but not the
// cost -- six IR operations where the ISA has one instruction, in the inner
// loop of a divider, which is the only reason the builtin exists. lvx-gcc has
// had `__builtin_lvx_stsud' on both cores since the instruction was restored
// (lvx-mds 270d0b5, 2026-10-09). The alternative that would honour both -- emit
// the generic shape and teach isel to recognise it, so hand-written C divisions
// benefit too -- is a DAGCombine-shape match, and a fragile one: the `or' with 1
// and the select both move under combining. If that ever lands, this intrinsic
// is what it replaces.
def int_lvx_stsud
    : DefaultAttrsIntrinsic<[llvm_i64_ty], [llvm_i64_ty, llvm_i64_ty],
                            [IntrNoMem, IntrSpeculatable]>;

// COMP{BX,HO,WQ,DP} -- the lane compare to a PACKED MASK: one bit per lane
// into a GPR, bit i set iff lane i of the first source stands in the named
// relation to lane i of the second. On BOTH cores since 2026-10-01, unlike the
// lane-wise arithmetic, because the result needs no lanes to consume it.
//
// This is the one member of SIMDe's LVX surface that generic IR cannot spell.
// The value is `bitcast (icmp a, b) to iN', and the bitcast of a <16 x i1> is
// precisely what has no lowering here: it is what `getNumberOfRegisters'
// returning nonzero on an lvx-1 build used to crash the legalizer on. The
// other fifteen builtins SIMDe needs ARE plain IR (vector add/sub, the
// saturating intrinsics, smin/umin/smax/umax) and are emitted as such.
//
// The third operand is the intcomp ENCODING, 0..11 for
// .lt .ge .ltu .geu .eq .ne .any .none .le .gt .leu .gtu -- an instruction
// modifier, so a constant. It is i64 for the reason spelled out under
// int_lvx_taild: there is no i32 among LVX's legal types, so an i32 intrinsic
// operand leaves TableGen with no type set to infer from.
//
// .any and .none are NOT relations: they test the bitwise AND of the two lanes
// for any/no bits set. They are in the encoding and so reachable here, which is
// why these are 12 relations and CompQPat's SETCC-driven list is 10.
class LVXLaneComp<LLVMType vt>
    : DefaultAttrsIntrinsic<[llvm_i64_ty], [vt, vt, llvm_i64_ty],
                            [IntrNoMem, IntrSpeculatable,
                             ImmArg<ArgIndex<2>>]>;

def int_lvx_compbx : LVXLaneComp<llvm_v16i8_ty>;
def int_lvx_compho : LVXLaneComp<llvm_v8i16_ty>;
def int_lvx_compwq : LVXLaneComp<llvm_v4i32_ty>;
def int_lvx_compdp : LVXLaneComp<llvm_v2i64_ty>;

} // let TargetPrefix = "lvx"
