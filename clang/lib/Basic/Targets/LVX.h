//===--- LVX.h - Declare LVX target feature support -------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file declares LVX TargetInfo objects.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_CLANG_LIB_BASIC_TARGETS_LVX_H
#define LLVM_CLANG_LIB_BASIC_TARGETS_LVX_H

#include "clang/Basic/TargetInfo.h"
#include "clang/Basic/TargetOptions.h"
#include "llvm/Support/Compiler.h"
#include "llvm/TargetParser/Triple.h"

namespace clang {
namespace targets {

// LVX: a 64-bit little-endian VLIW, LP64 only -- there is no 32-bit mode and
// no -m32. Two variants, lvx-1 and lvx-2, which differ only in that lvx-2
// adds 256-bit SIMD; everything the front end cares about is common to both,
// so the variant reaches here as a CPU name and leaves as a predefined macro.
class LLVM_LIBRARY_VISIBILITY LVXTargetInfo : public TargetInfo {
  // lvx-1 unless the driver says otherwise, matching lvx-gcc's default and
  // the core whose description the back end is built against.
  enum CPUKind { CK_LVX1, CK_LVX2 } CPU = CK_LVX1;

  static const char *const GCCRegNames[];
  static const TargetInfo::GCCRegAlias GCCRegAliases[];

public:
  LVXTargetInfo(const llvm::Triple &Triple, const TargetOptions &)
      : TargetInfo(Triple) {
    // The same string LVXTargetMachine gives the back end, and it has to stay
    // the same: a module carrying a different layout is silently re-laid-out
    // by llc rather than rejected.
    resetDataLayout("e-m:e-p:64:64-i64:64-i128:128-n32:64-S128");

    // LP64. long and pointers are 64 bits, int is 32.
    LongWidth = LongAlign = PointerWidth = PointerAlign = 64;
    IntMaxType = SignedLong;
    Int64Type = SignedLong;
    IntPtrType = SignedLong;
    PtrDiffType = SignedLong;
    SizeType = UnsignedLong;
    WCharType = SignedInt;
    WIntType = UnsignedInt;

    // f16 is a storage and arithmetic type in the ISA -- the FP surface has a
    // half-word width throughout -- so _Float16 is a real type here rather
    // than one promoted through float.
    HasFloat16 = true;

    // Alignments, from lvx.h: BIGGEST_ALIGNMENT is 256 bits, which is also
    // the stack boundary. A local declared with that alignment is placed at a
    // fixed offset from $r12 and its address computed with a bitwise or, so
    // the runtime owes the program a 32-byte-aligned stack -- see
    // lvx-gem5's process.cc, where getting it wrong corrupted 256-bit values
    // silently.
    SuitableAlign = 256;
    DefaultAlignForAttributeAligned = 256;
    LongDoubleWidth = LongDoubleAlign = 64;
    LongDoubleFormat = &llvm::APFloat::IEEEdouble();
    MaxAtomicPromoteWidth = MaxAtomicInlineWidth = 64;
  }

  void getTargetDefines(const LangOptions &Opts,
                        MacroBuilder &Builder) const override;

  llvm::SmallVector<Builtin::InfosShard> getTargetBuiltins() const override;

  bool isValidCPUName(StringRef Name) const override;
  void fillValidCPUList(SmallVectorImpl<StringRef> &Values) const override;
  bool setCPU(const std::string &Name) override;

  bool hasFeature(StringRef Feature) const override;

  ArrayRef<const char *> getGCCRegNames() const override;
  ArrayRef<TargetInfo::GCCRegAlias> getGCCRegAliases() const override;

  bool validateAsmConstraint(const char *&Name,
                             TargetInfo::ConstraintInfo &Info) const override;

  std::string_view getClobbers() const override { return ""; }

  BuiltinVaListKind getBuiltinVaListKind() const override {
    return TargetInfo::VoidPtrBuiltinVaList;
  }

  bool hasBitIntType() const override { return true; }

  // __fp16 is a real arithmetic type here, not a storage format converted
  // through float: the ISA has an f16 instruction wherever it has an f32 or
  // f64 one (fadd/fmul/fmin/fsign/...), so a half value is computed on
  // directly. Saying otherwise makes clang convert every __fp16 through an
  // i16 bitcast, which is how __builtin_copysignf16 came out as the
  // nonexistent llvm.copysign.i16 and broke the module outright.
  bool useFP16ConversionIntrinsics() const override { return false; }

  // __int128 is a register pair (GPR128), not a libcall.
  bool hasInt128Type() const override { return true; }
};

} // namespace targets
} // namespace clang

#endif // LLVM_CLANG_LIB_BASIC_TARGETS_LVX_H
