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

  switch (BuiltinID) {
  default:
    return nullptr;

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

  case LVX::BI__builtin_lvx_copysignh:
  case LVX::BI__builtin_lvx_copysignw:
  case LVX::BI__builtin_lvx_copysignd:
    return Binary(Intrinsic::copysign);

  // copysignn takes the sign NEGATED: lvx-gcc's lvx_fsignn<suffix> is
  // (copysign a (neg b)), so the negation is part of what the instruction
  // means rather than something the caller wrote.
  case LVX::BI__builtin_lvx_copysignnh:
  case LVX::BI__builtin_lvx_copysignnw:
  case LVX::BI__builtin_lvx_copysignnd:
  case LVX::BI__builtin_lvx_copysignnwq:
  case LVX::BI__builtin_lvx_copysignndq: {
    auto [A, B] = Args();
    return Builder.CreateBinaryIntrinsic(Intrinsic::copysign, A,
                                         Builder.CreateFNeg(B));
  }

  // The vector sign family needs no separate code: llvm.copysign is
  // overloaded, so the same intrinsic applied to a vector type is the
  // lane-wise operation, and the back end selects FSIGN<lane> for it.
  case LVX::BI__builtin_lvx_copysignwq:
  case LVX::BI__builtin_lvx_copysignho:
  case LVX::BI__builtin_lvx_copysigndp:
  case LVX::BI__builtin_lvx_copysignwo:
  case LVX::BI__builtin_lvx_copysigndq:
    return Binary(Intrinsic::copysign);

  // xorsign: `a` with its sign bit XORed with b's. Done on the bits rather
  // than as copysign(a, a*b), which agrees on every finite value but not on a
  // NaN -- a multiply does not carry a NaN's sign -- and not as
  // copysign(a, b) either, which REPLACES the sign instead of flipping it.
  case LVX::BI__builtin_lvx_xorsignwq:
  case LVX::BI__builtin_lvx_xorsignho:
  case LVX::BI__builtin_lvx_xorsigndp:
  case LVX::BI__builtin_lvx_xorsignwo: {
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
