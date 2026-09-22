//===- LVX.cpp ------------------------------------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "ABIInfoImpl.h"
#include "TargetInfo.h"

using namespace clang;
using namespace clang::CodeGen;

//===----------------------------------------------------------------------===//
// LVX ABI Implementation
//===----------------------------------------------------------------------===//

namespace {

class LVXABIInfo : public DefaultABIInfo {
public:
  LVXABIInfo(CodeGenTypes &CGT) : DefaultABIInfo(CGT) {}

  ABIArgInfo classifyType(QualType Ty, bool IsReturn) const;

  void computeInfo(CGFunctionInfo &FI) const override {
    if (!getCXXABI().classifyReturnType(FI))
      FI.getReturnInfo() = classifyType(FI.getReturnType(), /*IsReturn=*/true);
    for (auto &I : FI.arguments())
      I.info = classifyType(I.type, /*IsReturn=*/false);
  }
};

// A vector is passed in general registers, as the integer of its width: one
// aligned pair for 128 bits, one quad for 256. That is what lvx-gcc does --
// "lq $r0r1 = ...", "lo $r0r1r2r3 = ..." -- and what the back end's
// calling convention knows how to take apart, which is the practical
// constraint: LVXISelLowering splits a multi-slot argument as an i128 or a
// v4i64 and asserts on anything else. Passing a <2 x i64> or a <16 x i16>
// through as itself reached exactly that assertion.
//
// Coercing rather than indirecting keeps the value in registers; the back
// end bitcasts it to the vector type on arrival, which costs nothing because
// both live in the same registers.
ABIArgInfo LVXABIInfo::classifyType(QualType Ty, bool IsReturn) const {
  if (const VectorType *VT = Ty->getAs<VectorType>()) {
    uint64_t Size = getContext().getTypeSize(VT);
    llvm::LLVMContext &LLVMCtx = getVMContext();
    if (Size == 128)
      return ABIArgInfo::getDirect(llvm::Type::getInt128Ty(LLVMCtx));
    if (Size == 256)
      return ABIArgInfo::getDirect(llvm::FixedVectorType::get(
          llvm::Type::getInt64Ty(LLVMCtx), 4));
    // Anything else has no register form here: 64 bits and under would be
    // the departed 64-bit SIMD family, and above 256 there is no register
    // to hold it. Memory is the honest answer rather than a coercion that
    // changes the value's size.
    return getNaturalAlignIndirect(Ty, getDataLayout().getAllocaAddrSpace());
  }

  return IsReturn ? DefaultABIInfo::classifyReturnType(Ty)
                  : DefaultABIInfo::classifyArgumentType(Ty);
}

class LVXTargetCodeGenInfo : public TargetCodeGenInfo {
public:
  LVXTargetCodeGenInfo(CodeGenTypes &CGT)
      : TargetCodeGenInfo(std::make_unique<LVXABIInfo>(CGT)) {}
};

} // namespace

std::unique_ptr<TargetCodeGenInfo>
CodeGen::createLVXTargetCodeGenInfo(CodeGenModule &CGM) {
  return std::make_unique<LVXTargetCodeGenInfo>(CGM.getTypes());
}
