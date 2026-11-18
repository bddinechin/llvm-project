//===-- LVX.cpp - Emit LLVM Code for builtins -----------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This contains code to emit Builtin calls as LLVM code for the LVX target.
//
//===----------------------------------------------------------------------===//

#include "CodeGenFunction.h"
#include "clang/Basic/TargetBuiltins.h"
#include "llvm/IR/IntrinsicInst.h"
// Intrinsic::lvx_* lives in this generated header, not in Intrinsics.h: the
// per-target enums are split out by -intrinsic-prefix. Every other target's
// builtin file includes its own the same way.
#include "llvm/IR/IntrinsicsLVX.h"

using namespace clang;
using namespace CodeGen;
using namespace llvm;

Value *CodeGenFunction::EmitLVXBuiltinExpr(unsigned BuiltinID,
                                           const CallExpr *E) {
  // Most LVX builtins are two-operand FP instructions, scalar or one lane at
  // a time, so the operands are read once here. The wider families below read
  // their own arguments.
  auto Args = [&]() -> std::pair<Value *, Value *> {
    return {EmitScalarExpr(E->getArg(0)), EmitScalarExpr(E->getArg(1))};
  };

  // The intrinsic named by an instruction, applied to the operands' type.
  auto Binary = [&](Intrinsic::ID ID) -> Value * {
    auto [A, B] = Args();
    return Builder.CreateBinaryIntrinsic(ID, A, B);
  };

  // TAILD's lane count. It is an instruction modifier, so it has to be a
  // literal, and lvx-gcc spells it as the assembly suffix does -- ".v16" --
  // which is what this accepts, mapping it to the 0..7 encoding (log2 of the
  // lane count). A count that is not a power of two in range is a diagnostic,
  // not a round-down: lvx-gcc rejects ".v3" and so does this.
  if (BuiltinID == LVX::BI__builtin_lvx_taild) {
    const auto *SL = dyn_cast<StringLiteral>(E->getArg(2)->IgnoreParenCasts());
    if (!SL) {
      CGM.ErrorUnsupported(E, "taild whose lane count is not a string literal "
                              "(\".v1\" ... \".v128\")");
      return llvm::PoisonValue::get(ConvertType(E->getType()));
    }
    static constexpr const char *Suffixes[8] = {".v1",  ".v2",  ".v4",  ".v8",
                                                ".v16", ".v32", ".v64", ".v128"};
    StringRef Want = SL->getString();
    int Enc = -1;
    for (int I = 0; I != 8; ++I)
      if (Want == Suffixes[I]) {
        Enc = I;
        break;
      }
    if (Enc < 0) {
      CGM.ErrorUnsupported(E, "taild lane count that is not one of \".v1\", "
                              "\".v2\", \".v4\", \".v8\", \".v16\", "
                              "\".v32\", \".v64\", \".v128\"");
      return llvm::PoisonValue::get(ConvertType(E->getType()));
    }
    auto [Index, Bound] = Args();
    Function *F = CGM.getIntrinsic(Intrinsic::lvx_taild);
    return Builder.CreateCall(F, {Index, Bound, Builder.getInt64(Enc)});
  }

  // STSUD is a target intrinsic rather than generic IR, which the rest of this
  // file avoids: generic IR can spell the value but needs six operations where
  // the ISA has one instruction, and a divide loop is where that matters. See
  // IntrinsicsLVX.td.
  if (BuiltinID == LVX::BI__builtin_lvx_stsud) {
    auto [Z, Y] = Args();
    Function *F = CGM.getIntrinsic(Intrinsic::lvx_stsud);
    return Builder.CreateCall(F, {Z, Y});
  }

  // A modifier spelled as lvx-gcc spells it, mapped to its encoding. Returns
  // -1 after diagnosing, so a caller can bail; the table is written out here
  // rather than taken from the generated LVXModifiers.h, which belongs to the
  // back end and is not clang's to include.
  auto Modifier = [&](unsigned ArgNo, ArrayRef<const char *> Suffixes,
                      const char *What) -> int {
    const auto *SL =
        dyn_cast<StringLiteral>(E->getArg(ArgNo)->IgnoreParenCasts());
    if (!SL) {
      CGM.ErrorUnsupported(E, "LVX builtin whose modifier is not a string "
                              "literal");
      return -1;
    }
    StringRef Want = SL->getString();
    for (unsigned I = 0, N = Suffixes.size(); I != N; ++I)
      if (Want == Suffixes[I])
        return int(I);
    CGM.ErrorUnsupported(E, What);
    return -1;
  };

  // ADD/SBF at a lane shape, with the SATURATE flavour as a string: "" wraps,
  // ".s" saturates signed, ".us" unsigned. Plain IR in every case -- which is
  // what makes them right on both cores, an lvx_1 description scalarising
  // what an lvx_2 one selects as one instruction.
  //
  // SBF is "subtract FROM": sbf(a, b) is b - a. The operands are swapped here
  // and nowhere else, so this is the single place to get it wrong.
  if (BuiltinID == LVX::BI__builtin_lvx_addbx ||
      BuiltinID == LVX::BI__builtin_lvx_addho ||
      BuiltinID == LVX::BI__builtin_lvx_sbfbx ||
      BuiltinID == LVX::BI__builtin_lvx_sbfho) {
    static const char *Saturate[] = {"", ".s", ".us"};
    int Sat = Modifier(2, Saturate, "LVX saturation flavour that is not one of "
                                    "\"\", \".s\" or \".us\"");
    if (Sat < 0)
      return llvm::PoisonValue::get(ConvertType(E->getType()));
    bool IsSub = BuiltinID == LVX::BI__builtin_lvx_sbfbx ||
                 BuiltinID == LVX::BI__builtin_lvx_sbfho;
    auto [A, B] = Args();
    if (IsSub)
      std::swap(A, B);
    switch (Sat) {
    case 1:
      return Builder.CreateBinaryIntrinsic(
          IsSub ? Intrinsic::ssub_sat : Intrinsic::sadd_sat, A, B);
    case 2:
      return Builder.CreateBinaryIntrinsic(
          IsSub ? Intrinsic::usub_sat : Intrinsic::uadd_sat, A, B);
    default:
      return IsSub ? Builder.CreateSub(A, B) : Builder.CreateAdd(A, B);
    }
  }

  // COMP* -- the lane compare to a packed mask, the one member of this family
  // generic IR cannot spell (the result is a bitcast of a <16 x i1>). The
  // builtin's type is lvx-gcc's, uint32, while the instruction writes a GPR,
  // so the i64 the intrinsic returns is truncated here.
  if (BuiltinID == LVX::BI__builtin_lvx_compbx ||
      BuiltinID == LVX::BI__builtin_lvx_compho ||
      BuiltinID == LVX::BI__builtin_lvx_compwq ||
      BuiltinID == LVX::BI__builtin_lvx_compdp) {
    static const char *Intcomp[] = {".lt", ".ge",   ".ltu",  ".geu",
                                    ".eq", ".ne",   ".any",  ".none",
                                    ".le", ".gt",   ".leu",  ".gtu"};
    int Cmp = Modifier(2, Intcomp,
                       "LVX lane comparison that is not one of \".lt\", "
                       "\".ge\", \".ltu\", \".geu\", \".eq\", \".ne\", "
                       "\".any\", \".none\", \".le\", \".gt\", \".leu\" "
                       "or \".gtu\"");
    if (Cmp < 0)
      return llvm::PoisonValue::get(ConvertType(E->getType()));
    Intrinsic::ID ID = BuiltinID == LVX::BI__builtin_lvx_compbx
                           ? Intrinsic::lvx_compbx
                       : BuiltinID == LVX::BI__builtin_lvx_compho
                           ? Intrinsic::lvx_compho
                       : BuiltinID == LVX::BI__builtin_lvx_compwq
                           ? Intrinsic::lvx_compwq
                           : Intrinsic::lvx_compdp;
    auto [A, B] = Args();
    Function *F = CGM.getIntrinsic(ID);
    Value *Mask = Builder.CreateCall(F, {A, B, Builder.getInt64(Cmp)});
    return Builder.CreateTrunc(Mask, ConvertType(E->getType()));
  }

  auto Poison = [&]() -> Value * {
    return llvm::PoisonValue::get(ConvertType(E->getType()));
  };

  // The lanes 0 .. N-1 of a shuffle: a concatenation when both operands are
  // given and N is twice their lane count, or a half when N is half of it.
  auto Lanes = [](unsigned First, unsigned N) {
    SmallVector<int, 64> Mask;
    for (unsigned I = 0; I != N; ++I)
      Mask.push_back(int(First + I));
    return Mask;
  };
  auto LaneCount = [](Value *V) {
    return cast<FixedVectorType>(V->getType())->getNumElements();
  };

  switch (BuiltinID) {
  // ABS<shape>: "" wraps (abs of the minimum is the minimum, as the
  // instruction leaves it), ".s" saturates it to the maximum. The saturating
  // one is max(a, 0 -sat a): -MIN saturates to MAX, every other lane is |a|.
  case LVX::BI__builtin_lvx_absbx:
  case LVX::BI__builtin_lvx_absbv:
  case LVX::BI__builtin_lvx_absho:
  case LVX::BI__builtin_lvx_abshx:
  case LVX::BI__builtin_lvx_abswq:
  case LVX::BI__builtin_lvx_abswo:
  case LVX::BI__builtin_lvx_absdp:
  case LVX::BI__builtin_lvx_absdq: {
    static const char *SignedSat[] = {"", ".s"};
    int Sat = Modifier(1, SignedSat, "LVX abs flavour that is not one of \"\" "
                                     "or \".s\"");
    if (Sat < 0)
      return Poison();
    Value *A = EmitScalarExpr(E->getArg(0));
    if (Sat == 0)
      return Builder.CreateBinaryIntrinsic(Intrinsic::abs, A,
                                           Builder.getFalse());
    Value *Neg = Builder.CreateBinaryIntrinsic(
        Intrinsic::ssub_sat, Constant::getNullValue(A->getType()), A);
    return Builder.CreateBinaryIntrinsic(Intrinsic::smax, A, Neg);
  }

  // WIDEN<from><to>: each lane to twice its width. "" sign-extends, ".z"
  // zero-extends, ".q" is the Q-format widening (Q31 -> Q63 at word lanes):
  // the lane moves to the top half and the bottom half is zero.
  case LVX::BI__builtin_lvx_widenbhx:
  case LVX::BI__builtin_lvx_widenbhv:
  case LVX::BI__builtin_lvx_widenhwo:
  case LVX::BI__builtin_lvx_widenhwx:
  case LVX::BI__builtin_lvx_widenwdq:
  case LVX::BI__builtin_lvx_widenwdo: {
    static const char *WidenInt[] = {"", ".z", ".q"};
    int Ext = Modifier(1, WidenInt, "LVX widening that is not one of \"\", "
                                    "\".z\" or \".q\"");
    if (Ext < 0)
      return Poison();
    Value *A = EmitScalarExpr(E->getArg(0));
    llvm::Type *Wide = ConvertType(E->getType());
    if (Ext == 0)
      return Builder.CreateSExt(A, Wide);
    Value *Z = Builder.CreateZExt(A, Wide);
    if (Ext == 1)
      return Z;
    unsigned Bits = A->getType()->getScalarSizeInBits();
    return Builder.CreateShl(Z, Bits);
  }

  // TRUNC<from><to>: each lane's low half.
  case LVX::BI__builtin_lvx_trunchbx:
  case LVX::BI__builtin_lvx_truncwho:
  case LVX::BI__builtin_lvx_truncdwq:
    return Builder.CreateTrunc(EmitScalarExpr(E->getArg(0)),
                               ConvertType(E->getType()));

  // SELECT<shape>(t, f, c, cond): per lane, cond(c) ? t : f -- the condition
  // tests the third operand against zero, or its low bit.
  case LVX::BI__builtin_lvx_selectbx:
  case LVX::BI__builtin_lvx_selectbv:
  case LVX::BI__builtin_lvx_selectbt:
  case LVX::BI__builtin_lvx_selectho:
  case LVX::BI__builtin_lvx_selecthx:
  case LVX::BI__builtin_lvx_selecthv:
  case LVX::BI__builtin_lvx_selectwq:
  case LVX::BI__builtin_lvx_selectwo:
  case LVX::BI__builtin_lvx_selectwx:
  case LVX::BI__builtin_lvx_selectdp:
  case LVX::BI__builtin_lvx_selectdq:
  case LVX::BI__builtin_lvx_selectdo: {
    static const char *SimdCond[] = {".nez", ".eqz", ".ltz", ".gez",
                                     ".lez", ".gtz", ".odd", ".even"};
    int Cond = Modifier(3, SimdCond,
                        "LVX select condition that is not one of \".nez\", "
                        "\".eqz\", \".ltz\", \".gez\", \".lez\", \".gtz\", "
                        "\".odd\" or \".even\"");
    if (Cond < 0)
      return Poison();
    Value *T = EmitScalarExpr(E->getArg(0));
    Value *F = EmitScalarExpr(E->getArg(1));
    Value *C = EmitScalarExpr(E->getArg(2));
    Value *Zero = Constant::getNullValue(C->getType());
    Value *Test;
    switch (Cond) {
    case 0: Test = Builder.CreateICmpNE(C, Zero); break;
    case 1: Test = Builder.CreateICmpEQ(C, Zero); break;
    case 2: Test = Builder.CreateICmpSLT(C, Zero); break;
    case 3: Test = Builder.CreateICmpSGE(C, Zero); break;
    case 4: Test = Builder.CreateICmpSLE(C, Zero); break;
    case 5: Test = Builder.CreateICmpSGT(C, Zero); break;
    default: {
      Value *Low = Builder.CreateAnd(C, ConstantInt::get(C->getType(), 1));
      Test = Cond == 6 ? Builder.CreateICmpNE(Low, Zero)
                       : Builder.CreateICmpEQ(Low, Zero);
    }
    }
    return Builder.CreateSelect(Test, T, F);
  }

  // CAT/LOW/HIGH: the opaque-vector concatenations and halves, as shuffles.
  case LVX::BI__builtin_lvx_cat256:
  case LVX::BI__builtin_lvx_cat512: {
    auto [Lo, Hi] = Args();
    return Builder.CreateShuffleVector(Lo, Hi, Lanes(0, 2 * LaneCount(Lo)));
  }
  case LVX::BI__builtin_lvx_low128:
  case LVX::BI__builtin_lvx_low256:
  case LVX::BI__builtin_lvx_high128:
  case LVX::BI__builtin_lvx_high256: {
    Value *A = EmitScalarExpr(E->getArg(0));
    unsigned Half = LaneCount(A) / 2;
    bool High = BuiltinID == LVX::BI__builtin_lvx_high128 ||
                BuiltinID == LVX::BI__builtin_lvx_high256;
    return Builder.CreateShuffleVector(A, Lanes(High ? Half : 0, Half));
  }

  // STSU at a lane shape: the intrinsic per 128 bits, as STSUD's is per
  // register. A 256-bit operand is two of them on the halves -- what lvx-gcc
  // emits, there being no 256-bit STSU.
  case LVX::BI__builtin_lvx_stsuho:
  case LVX::BI__builtin_lvx_stsuhx:
  case LVX::BI__builtin_lvx_stsuwq:
  case LVX::BI__builtin_lvx_stsuwo:
  case LVX::BI__builtin_lvx_stsudp:
  case LVX::BI__builtin_lvx_stsudq: {
    Intrinsic::ID ID = (BuiltinID == LVX::BI__builtin_lvx_stsuho ||
                        BuiltinID == LVX::BI__builtin_lvx_stsuhx)
                           ? Intrinsic::lvx_stsuho
                       : (BuiltinID == LVX::BI__builtin_lvx_stsuwq ||
                          BuiltinID == LVX::BI__builtin_lvx_stsuwo)
                           ? Intrinsic::lvx_stsuwq
                           : Intrinsic::lvx_stsudp;
    Function *Fn = CGM.getIntrinsic(ID);
    auto [Z, Y] = Args();
    unsigned N = LaneCount(Z);
    unsigned Lane128 =
        cast<FixedVectorType>(Fn->getReturnType())->getNumElements();
    if (N == Lane128)
      return Builder.CreateCall(Fn, {Z, Y});
    Value *Lo = Builder.CreateCall(
        Fn, {Builder.CreateShuffleVector(Z, Lanes(0, Lane128)),
             Builder.CreateShuffleVector(Y, Lanes(0, Lane128))});
    Value *Hi = Builder.CreateCall(
        Fn, {Builder.CreateShuffleVector(Z, Lanes(Lane128, Lane128)),
             Builder.CreateShuffleVector(Y, Lanes(Lane128, Lane128))});
    return Builder.CreateShuffleVector(Lo, Hi, Lanes(0, N));
  }

  default:
    return nullptr;

  // Lane-wise minimum and maximum. The signedness is in the OPERATION, not in
  // the type: lvx-gcc gives minubx the signed V16QI type too, and SIMDe hands
  // it an lvx_int8x16_t.
  case LVX::BI__builtin_lvx_minbx:
  case LVX::BI__builtin_lvx_minho:
    return Binary(Intrinsic::smin);
  case LVX::BI__builtin_lvx_maxbx:
  case LVX::BI__builtin_lvx_maxho:
    return Binary(Intrinsic::smax);
  case LVX::BI__builtin_lvx_minubx:
  case LVX::BI__builtin_lvx_minuho:
    return Binary(Intrinsic::umin);
  case LVX::BI__builtin_lvx_maxubx:
  case LVX::BI__builtin_lvx_maxuho:
    return Binary(Intrinsic::umax);

  // The two IEEE families. fmin/fmax are 754-2019 minimum/maximum and
  // PROPAGATE a NaN -- llvm.minimum/maximum; fminn/fmaxn are 754-2008
  // minNum/maxNum and return the NUMERIC operand -- llvm.minnum/maxnum,
  // which is what C's fmin and fmax mean. Every non-NaN input gives the
  // same answer from both, so a swap here is invisible until a NaN
  // arrives; see BuiltinsLVX.td and lvx-csw/CLAUDE.md.
  case LVX::BI__builtin_lvx_fminh:
  case LVX::BI__builtin_lvx_fminw:
  case LVX::BI__builtin_lvx_fmind:
    return Binary(Intrinsic::minimum);
  case LVX::BI__builtin_lvx_fmaxh:
  case LVX::BI__builtin_lvx_fmaxw:
  case LVX::BI__builtin_lvx_fmaxd:
    return Binary(Intrinsic::maximum);
  case LVX::BI__builtin_lvx_fminnh:
  case LVX::BI__builtin_lvx_fminnw:
  case LVX::BI__builtin_lvx_fminnd:
    return Binary(Intrinsic::minnum);
  case LVX::BI__builtin_lvx_fmaxnh:
  case LVX::BI__builtin_lvx_fmaxnw:
  case LVX::BI__builtin_lvx_fmaxnd:
    return Binary(Intrinsic::maxnum);

  case LVX::BI__builtin_lvx_fsignch:
  case LVX::BI__builtin_lvx_fsigncw:
  case LVX::BI__builtin_lvx_fsigncd:
    return Binary(Intrinsic::copysign);

  // copysignn takes the sign NEGATED: lvx-gcc's lvx_fsignn<suffix> is
  // (copysign a (neg b)), so the negation is part of what the instruction
  // means rather than something the caller wrote.
  case LVX::BI__builtin_lvx_fsignnh:
  case LVX::BI__builtin_lvx_fsignnw:
  case LVX::BI__builtin_lvx_fsignnd:
  case LVX::BI__builtin_lvx_fsignnwq:
  case LVX::BI__builtin_lvx_fsignndq: {
    auto [A, B] = Args();
    return Builder.CreateBinaryIntrinsic(Intrinsic::copysign, A,
                                         Builder.CreateFNeg(B));
  }

  // The vector sign family needs no separate code: llvm.copysign is
  // overloaded, so the same intrinsic applied to a vector type is the
  // lane-wise operation, and the back end selects FSIGN<lane> for it.
  case LVX::BI__builtin_lvx_fsigncwq:
  case LVX::BI__builtin_lvx_fsigncho:
  case LVX::BI__builtin_lvx_fsigncdp:
  case LVX::BI__builtin_lvx_fsigncwo:
  case LVX::BI__builtin_lvx_fsigncdq:
    return Binary(Intrinsic::copysign);

  // xorsign: `a` with its sign bit XORed with b's. Done on the bits rather
  // than as copysign(a, a*b), which agrees on every finite value but not on a
  // NaN -- a multiply does not carry a NaN's sign -- and not as
  // copysign(a, b) either, which REPLACES the sign instead of flipping it.
  case LVX::BI__builtin_lvx_fsignmwq:
  case LVX::BI__builtin_lvx_fsignmho:
  case LVX::BI__builtin_lvx_fsignmdp:
  case LVX::BI__builtin_lvx_fsignmwo: {
    auto [A, B] = Args();
    auto *VecTy = cast<llvm::FixedVectorType>(A->getType());
    unsigned Bits = VecTy->getScalarSizeInBits();
    llvm::Type *IntTy = llvm::FixedVectorType::get(
        Builder.getIntNTy(Bits), VecTy->getNumElements());
    Value *SignMask = llvm::ConstantVector::getSplat(
        VecTy->getElementCount(),
        llvm::ConstantInt::get(Builder.getIntNTy(Bits),
                               llvm::APInt::getSignMask(Bits)));
    Value *Sign = Builder.CreateAnd(Builder.CreateBitCast(B, IntTy), SignMask);
    Value *Res = Builder.CreateXor(Builder.CreateBitCast(A, IntTy), Sign);
    return Builder.CreateBitCast(Res, VecTy);
  }

  // Widening multiply: extend both operands to the destination's lane width
  // and multiply there. The trailing string literal is the EXTENDMUL flavour
  // ("" signed, ".u" unsigned, ".su" signed times unsigned), which decides
  // which extension each operand gets -- and for ".su" the FIRST operand is
  // the signed one, as lvx-gcc prints it.
  case LVX::BI__builtin_lvx_mulxhwo:
  case LVX::BI__builtin_lvx_mulxwdq:
  case LVX::BI__builtin_lvx_maddxhwo:
  case LVX::BI__builtin_lvx_maddxwdq:
  case LVX::BI__builtin_lvx_msbfxhwo:
  case LVX::BI__builtin_lvx_msbfxwdq: {
    bool IsMul = BuiltinID == LVX::BI__builtin_lvx_mulxhwo ||
                 BuiltinID == LVX::BI__builtin_lvx_mulxwdq;
    bool IsSub = BuiltinID == LVX::BI__builtin_lvx_msbfxhwo ||
                 BuiltinID == LVX::BI__builtin_lvx_msbfxwdq;
    unsigned FlavourArg = IsMul ? 2 : 3;

    const auto *SL =
        dyn_cast<StringLiteral>(E->getArg(FlavourArg)->IgnoreParenCasts());
    if (!SL) {
      CGM.ErrorUnsupported(E, "widening multiply whose flavour is not a "
                              "string literal (\"\", \".u\" or \".su\")");
      return llvm::PoisonValue::get(ConvertType(E->getType()));
    }
    StringRef Flavour = SL->getString();

    Value *A = EmitScalarExpr(E->getArg(0));
    Value *B = EmitScalarExpr(E->getArg(1));
    Value *Acc = IsMul ? nullptr : EmitScalarExpr(E->getArg(2));

    llvm::Type *WideTy = ConvertType(E->getType());
    // "" both signed; ".u" both unsigned; ".su" the first signed, the
    // second unsigned.
    bool FirstSigned = Flavour != ".u";
    bool SecondSigned = Flavour.empty();
    Value *WA = FirstSigned ? Builder.CreateSExt(A, WideTy)
                            : Builder.CreateZExt(A, WideTy);
    Value *WB = SecondSigned ? Builder.CreateSExt(B, WideTy)
                             : Builder.CreateZExt(B, WideTy);
    Value *P = Builder.CreateMul(WA, WB);
    if (IsMul)
      return P;
    return IsSub ? Builder.CreateSub(Acc, P) : Builder.CreateAdd(Acc, P);
  }

  // A splatting load: read one element and broadcast it across the 256-bit
  // quad. The trailing string is the load VARIANT, which selects caching and
  // changes no value, so nothing here depends on it -- a plain load carries
  // the same meaning. (Selecting the variant would mean going through an
  // address space, the way LVXAddressSpaces.h does for ordinary loads.)
  case LVX::BI__builtin_lvx_loadbso:
  case LVX::BI__builtin_lvx_loadhso:
  case LVX::BI__builtin_lvx_loadwso:
  case LVX::BI__builtin_lvx_loaddso: {
    Value *Ptr = EmitScalarExpr(E->getArg(0));
    auto *VecTy = cast<llvm::FixedVectorType>(ConvertType(E->getType()));
    llvm::Type *EltTy = VecTy->getElementType();
    // Naturally aligned for its width: these load one element, and the ISA's
    // sized loads require that alignment (MISALIGN otherwise).
    Value *Elt = Builder.CreateAlignedLoad(
        EltTy, Ptr,
        CharUnits::fromQuantity(EltTy->getScalarSizeInBits() / 8).getAsAlign());
    return Builder.CreateVectorSplat(VecTy->getElementCount(), Elt);
  }
  }
}
