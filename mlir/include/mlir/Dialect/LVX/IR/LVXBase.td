//===- LVXBase.td - Base defs for LVX dialect ---------------*- tablegen -*-==//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LVX_BASE
#define LVX_BASE

include "mlir/IR/AttrTypeBase.td"
include "mlir/IR/EnumAttr.td"
include "mlir/IR/OpBase.td"

def LVX_Dialect : Dialect {
  let name = "lvx";
  let cppNamespace = "::mlir::lvx";
  let description = [{
    The LVX dialect represents LVX_v1 machine instructions in SSA form,
    before register allocation and instruction scheduling. Operations
    correspond one-to-one to real assembly instructions (as described by
    the LVX_v1 machine description in the sibling `lvx-mds` repo, under
    `lvx-mds/lvx-refs/`),
    using real mnemonics and modifier suffixes. Every live machine value is
    represented as an `!lvx.reg`: an unallocated virtual register until a
    later register-allocation pass assigns it a physical register (encoded
    in the type itself, following the "physical registers as types"
    approach). LVX has a single unified 64-bit general-purpose register
    file (R0-R63) used for both scalar integer and floating-point values;
    instruction width (32- vs. 64-bit) is a property of the mnemonic, not
    of the register.
  }];

  let useDefaultTypePrinterParser = 1;
  let hasConstantMaterializer = 1;
}

//===----------------------------------------------------------------------===//
// Physical register enum (R0-R63, plus the RA control register), used to
// parameterize the LVX_RegType once a value has been allocated.
//===----------------------------------------------------------------------===//

def LVX_RegisterAttr : I64EnumAttr<
    "Register", "an LVX physical register",
    [
      I64EnumAttrCase<"r0", 0, "r0">,
      I64EnumAttrCase<"r1", 1, "r1">,
      I64EnumAttrCase<"r2", 2, "r2">,
      I64EnumAttrCase<"r3", 3, "r3">,
      I64EnumAttrCase<"r4", 4, "r4">,
      I64EnumAttrCase<"r5", 5, "r5">,
      I64EnumAttrCase<"r6", 6, "r6">,
      I64EnumAttrCase<"r7", 7, "r7">,
      I64EnumAttrCase<"r8", 8, "r8">,
      I64EnumAttrCase<"r9", 9, "r9">,
      I64EnumAttrCase<"r10", 10, "r10">,
      I64EnumAttrCase<"r11", 11, "r11">,
      I64EnumAttrCase<"r12", 12, "r12">,
      I64EnumAttrCase<"r13", 13, "r13">,
      I64EnumAttrCase<"r14", 14, "r14">,
      I64EnumAttrCase<"r15", 15, "r15">,
      I64EnumAttrCase<"r16", 16, "r16">,
      I64EnumAttrCase<"r17", 17, "r17">,
      I64EnumAttrCase<"r18", 18, "r18">,
      I64EnumAttrCase<"r19", 19, "r19">,
      I64EnumAttrCase<"r20", 20, "r20">,
      I64EnumAttrCase<"r21", 21, "r21">,
      I64EnumAttrCase<"r22", 22, "r22">,
      I64EnumAttrCase<"r23", 23, "r23">,
      I64EnumAttrCase<"r24", 24, "r24">,
      I64EnumAttrCase<"r25", 25, "r25">,
      I64EnumAttrCase<"r26", 26, "r26">,
      I64EnumAttrCase<"r27", 27, "r27">,
      I64EnumAttrCase<"r28", 28, "r28">,
      I64EnumAttrCase<"r29", 29, "r29">,
      I64EnumAttrCase<"r30", 30, "r30">,
      I64EnumAttrCase<"r31", 31, "r31">,
      I64EnumAttrCase<"r32", 32, "r32">,
      I64EnumAttrCase<"r33", 33, "r33">,
      I64EnumAttrCase<"r34", 34, "r34">,
      I64EnumAttrCase<"r35", 35, "r35">,
      I64EnumAttrCase<"r36", 36, "r36">,
      I64EnumAttrCase<"r37", 37, "r37">,
      I64EnumAttrCase<"r38", 38, "r38">,
      I64EnumAttrCase<"r39", 39, "r39">,
      I64EnumAttrCase<"r40", 40, "r40">,
      I64EnumAttrCase<"r41", 41, "r41">,
      I64EnumAttrCase<"r42", 42, "r42">,
      I64EnumAttrCase<"r43", 43, "r43">,
      I64EnumAttrCase<"r44", 44, "r44">,
      I64EnumAttrCase<"r45", 45, "r45">,
      I64EnumAttrCase<"r46", 46, "r46">,
      I64EnumAttrCase<"r47", 47, "r47">,
      I64EnumAttrCase<"r48", 48, "r48">,
      I64EnumAttrCase<"r49", 49, "r49">,
      I64EnumAttrCase<"r50", 50, "r50">,
      I64EnumAttrCase<"r51", 51, "r51">,
      I64EnumAttrCase<"r52", 52, "r52">,
      I64EnumAttrCase<"r53", 53, "r53">,
      I64EnumAttrCase<"r54", 54, "r54">,
      I64EnumAttrCase<"r55", 55, "r55">,
      I64EnumAttrCase<"r56", 56, "r56">,
      I64EnumAttrCase<"r57", 57, "r57">,
      I64EnumAttrCase<"r58", 58, "r58">,
      I64EnumAttrCase<"r59", 59, "r59">,
      I64EnumAttrCase<"r60", 60, "r60">,
      I64EnumAttrCase<"r61", 61, "r61">,
      I64EnumAttrCase<"r62", 62, "r62">,
      I64EnumAttrCase<"r63", 63, "r63">,
      I64EnumAttrCase<"ra", 64, "ra">,
    ]> {
  let cppNamespace = "::mlir::lvx";
  let genSpecializedAttr = 0;
}

//===----------------------------------------------------------------------===//
// LVX register type: `!lvx.reg` (unallocated) or `!lvx.reg<r5>` (allocated).
//===----------------------------------------------------------------------===//

class LVX_Type<string name, string typeMnemonic, list<Trait> traits = []>
    : TypeDef<LVX_Dialect, name, traits> {
  let mnemonic = typeMnemonic;
}

def LVX_RegType : LVX_Type<"Register", "reg"> {
  let summary = "an LVX general-purpose register value";
  let description = [{
    The type of every live machine value in the LVX dialect. `!lvx.reg`
    (no parameter) denotes a virtual register, not yet assigned to
    hardware; `!lvx.reg<r5>` denotes a value pinned to (or, after register
    allocation, assigned to) physical register `$r5`.
  }];
  let parameters = (ins "std::optional<Register>":$reg);
  let hasCustomAssemblyFormat = 1;
  let builders = [
    TypeBuilder<(ins), [{
      return $_get($_ctxt, std::optional<Register>{});
    }]>
  ];
  let extraClassDeclaration = [{
    /// Whether this register has been pinned/allocated to a physical
    /// register, as opposed to being a not-yet-allocated virtual register.
    bool isAllocated() const { return getReg().has_value(); }
  }];
}

//===----------------------------------------------------------------------===//
// Modifier enums, mirroring Description.yml's modifier suffixes.
//===----------------------------------------------------------------------===//

// `intcomp` -- integer comparison suffix (e.g. `compd.lt`).
def LVX_IntCompAttr : I64EnumAttr<
    "IntComp", "LVX integer comparison modifier",
    [
      I64EnumAttrCase<"lt",   0,  "lt">,
      I64EnumAttrCase<"ge",   1,  "ge">,
      I64EnumAttrCase<"ltu",  2,  "ltu">,
      I64EnumAttrCase<"geu",  3,  "geu">,
      I64EnumAttrCase<"eq",   4,  "eq">,
      I64EnumAttrCase<"ne",   5,  "ne">,
      I64EnumAttrCase<"any",  6,  "any">,
      I64EnumAttrCase<"none", 7,  "none">,
      I64EnumAttrCase<"le",   8,  "le">,
      I64EnumAttrCase<"gt",   9,  "gt">,
      I64EnumAttrCase<"leu",  10, "leu">,
      I64EnumAttrCase<"gtu",  11, "gtu">,
    ]> {
  let cppNamespace = "::mlir::lvx";
}

// `floatcomp` -- floating-point comparison suffix (e.g. `fcompd.olt`).
def LVX_FloatCompAttr : I64EnumAttr<
    "FloatComp", "LVX floating-point comparison modifier",
    [
      I64EnumAttrCase<"one", 0, "one">,
      I64EnumAttrCase<"ueq", 1, "ueq">,
      I64EnumAttrCase<"oeq", 2, "oeq">,
      I64EnumAttrCase<"une", 3, "une">,
      I64EnumAttrCase<"olt", 4, "olt">,
      I64EnumAttrCase<"uge", 5, "uge">,
      I64EnumAttrCase<"oge", 6, "oge">,
      I64EnumAttrCase<"ult", 7, "ult">,
    ]> {
  let cppNamespace = "::mlir::lvx";
}

// `floatmode` -- IEEE-754 rounding-mode suffix (e.g. `faddd.rn`).
def LVX_FloatModeAttr : I64EnumAttr<
    "FloatMode", "LVX floating-point rounding mode modifier",
    [
      I64EnumAttrCase<"rn", 0, "rn">,
      I64EnumAttrCase<"rz", 1, "rz">,
      I64EnumAttrCase<"rd", 2, "rd">,
      I64EnumAttrCase<"ru", 3, "ru">,
      I64EnumAttrCase<"rm", 4, "rm">,
      I64EnumAttrCase<"ro", 6, "ro">,
      // Empty suffix: use the rounding mode configured in $cs.
      I64EnumAttrCase<"cs", 7, "cs">,
    ]> {
  let cppNamespace = "::mlir::lvx";
}

// `bcucond` -- branch-condition suffix (e.g. `br.wnez`).
def LVX_BcuCondAttr : I64EnumAttr<
    "BcuCond", "LVX branch condition modifier",
    [
      I64EnumAttrCase<"dltz", 0,  "dltz">,
      I64EnumAttrCase<"dgez", 1,  "dgez">,
      I64EnumAttrCase<"dlez", 2,  "dlez">,
      I64EnumAttrCase<"dgtz", 3,  "dgtz">,
      I64EnumAttrCase<"deqz", 4,  "deqz">,
      I64EnumAttrCase<"dnez", 5,  "dnez">,
      I64EnumAttrCase<"odd",  6,  "odd">,
      I64EnumAttrCase<"even", 7,  "even">,
      I64EnumAttrCase<"wltz", 8,  "wltz">,
      I64EnumAttrCase<"wgez", 9,  "wgez">,
      I64EnumAttrCase<"wlez", 10, "wlez">,
      I64EnumAttrCase<"wgtz", 11, "wgtz">,
      I64EnumAttrCase<"weqz", 12, "weqz">,
      I64EnumAttrCase<"wnez", 13, "wnez">,
    ]> {
  let cppNamespace = "::mlir::lvx";
}

#endif // LVX_BASE
