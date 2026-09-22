//===--- LVX.cpp - Implement LVX target feature support -------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file implements LVX TargetInfo objects.
//
//===----------------------------------------------------------------------===//

#include "LVX.h"
#include "clang/Basic/MacroBuilder.h"
#include "clang/Basic/TargetBuiltins.h"
#include "llvm/ADT/StringSwitch.h"

namespace clang {
namespace targets {

static constexpr int NumBuiltins =
    clang::LVX::LastTSBuiltin - Builtin::FirstTSBuiltin;

#define GET_BUILTIN_STR_TABLE
#include "clang/Basic/BuiltinsLVX.inc"
#undef GET_BUILTIN_STR_TABLE

static constexpr Builtin::Info BuiltinInfos[] = {
#define GET_BUILTIN_INFOS
#include "clang/Basic/BuiltinsLVX.inc"
#undef GET_BUILTIN_INFOS
};

// The table and the enumerators come from one .td, so a mismatch means the
// two halves were generated from different things -- which is what an empty
// table looked like before this was here: every builtin simply "unknown".
static_assert(std::size(BuiltinInfos) == NumBuiltins);

// $r0-$r63 are the general registers; the assembler and lvx-gcc both spell
// them without the '$' in an asm register name, so "r0" is what a
// register asm("r0") or a clobber list says.
const char *const LVXTargetInfo::GCCRegNames[] = {
    "r0",  "r1",  "r2",  "r3",  "r4",  "r5",  "r6",  "r7",  "r8",  "r9",
    "r10", "r11", "r12", "r13", "r14", "r15", "r16", "r17", "r18", "r19",
    "r20", "r21", "r22", "r23", "r24", "r25", "r26", "r27", "r28", "r29",
    "r30", "r31", "r32", "r33", "r34", "r35", "r36", "r37", "r38", "r39",
    "r40", "r41", "r42", "r43", "r44", "r45", "r46", "r47", "r48", "r49",
    "r50", "r51", "r52", "r53", "r54", "r55", "r56", "r57", "r58", "r59",
    "r60", "r61", "r62", "r63",
};

// The ABI roles, spelled as lvx-gcc's ADDITIONAL_REGISTER_NAMES spells them,
// so the same asm source names the same register under either compiler.
const TargetInfo::GCCRegAlias LVXTargetInfo::GCCRegAliases[] = {
    {{"sp"}, "r12"},
    {{"tp"}, "r13"},
    {{"fp"}, "r14"},
};

ArrayRef<const char *> LVXTargetInfo::getGCCRegNames() const {
  return llvm::ArrayRef(GCCRegNames);
}

ArrayRef<TargetInfo::GCCRegAlias> LVXTargetInfo::getGCCRegAliases() const {
  return llvm::ArrayRef(GCCRegAliases);
}

bool LVXTargetInfo::validateAsmConstraint(
    const char *&Name, TargetInfo::ConstraintInfo &Info) const {
  switch (*Name) {
  case 'r': // A general register, of whatever width the operand has: one
            // GPR, an aligned pair for an __int128, a quad for a 256-bit
            // vector. The back end picks the class from the type and the
            // register's own name carries the width to the assembler.
    Info.setAllowsRegister();
    return true;
  default:
    return false;
  }
}

bool LVXTargetInfo::isValidCPUName(StringRef Name) const {
  return Name == "lvx-1" || Name == "lvx-2";
}

void LVXTargetInfo::fillValidCPUList(SmallVectorImpl<StringRef> &Values) const {
  Values.append({"lvx-1", "lvx-2"});
}

bool LVXTargetInfo::setCPU(const std::string &Name) {
  CPU = llvm::StringSwitch<CPUKind>(Name)
            .Case("lvx-1", CK_LVX1)
            .Case("lvx-2", CK_LVX2)
            .Default(CK_LVX1);
  return isValidCPUName(Name);
}

bool LVXTargetInfo::hasFeature(StringRef Feature) const {
  return llvm::StringSwitch<bool>(Feature)
      .Case("lvx", true)
      .Case("lvx-2", CPU == CK_LVX2)
      .Default(false);
}

void LVXTargetInfo::getTargetDefines(const LangOptions &Opts,
                                     MacroBuilder &Builder) const {
  // The same names lvx-gcc's TARGET_CPU_CPP_BUILTINS defines, spelled the
  // same way: source that switches on them has to see one target, not two.
  Builder.defineMacro("__LVX__");
  Builder.defineMacro("__lvx__");
  Builder.defineMacro("__LVX_64__");
  if (CPU == CK_LVX2) {
    Builder.defineMacro("__lvxarch_lvx_2");
    Builder.defineMacro("__lvx_2__");
  } else {
    Builder.defineMacro("__lvxarch_lvx_1");
    Builder.defineMacro("__lvx_1__");
  }

  // FLT_EVAL_METHOD 0: every operation is evaluated in its own type. The
  // ISA has an instruction at each width, so nothing is computed wider.
  Builder.defineMacro("__FLT_EVAL_METHOD__", "0");

  // The named address spaces, as macros rather than as keywords.
  //
  // lvx-gcc registers these with c_register_addr_space, which makes them
  // type qualifiers the parser knows; clang has no target hook for that, so
  // they are spelled here as the attribute that means the same thing to the
  // middle end. The NUMBERS are ABI -- LVXAddressSpaces.h in the back end
  // maps them onto the load's `variant` modifier, and a mismatch would
  // quietly compile a __bypass load as a cached one -- so they are written
  // out here rather than derived, and the back end static_asserts its half
  // against the generated encodings.
  //
  // A __convert pointer is a conversion step only: it never names a load, so
  // the back end diagnoses an access through one instead of inventing a
  // variant for it.
  if (!Opts.CPlusPlus) {
    Builder.defineMacro("__bypass", "__attribute__((address_space(1)))");
    Builder.defineMacro("__preload", "__attribute__((address_space(2)))");
    Builder.defineMacro("__speculate", "__attribute__((address_space(3)))");
    Builder.defineMacro("__convert", "__attribute__((address_space(4)))");
    Builder.defineMacro("__syscall", "__attribute__((address_space(5)))");
  }
}

llvm::SmallVector<Builtin::InfosShard>
LVXTargetInfo::getTargetBuiltins() const {
  return {{&BuiltinStrings, BuiltinInfos}};
}

} // namespace targets
} // namespace clang
