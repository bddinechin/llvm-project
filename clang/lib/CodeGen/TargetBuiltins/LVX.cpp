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
  // Every LVX builtin so far is a two-operand FP instruction, so the
  // operands are read once here.
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
  case LVX::BI__builtin_lvx_copysignnd: {
    auto [A, B] = Args();
    return Builder.CreateBinaryIntrinsic(Intrinsic::copysign, A,
                                         Builder.CreateFNeg(B));
  }
  }
}
