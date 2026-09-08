//===-- LVXModifiers.td - -*- tablegen -*- ===//
//
// Enumerated attributes for the LVX instruction modifiers.
//
// Generated from the LVX Machine Description System by MDS/BE/MLIR, for core
// lvx_v1.  DO NOT EDIT -- your changes will be overwritten by the next
// `make -C BE/MLIR install`.  Change lvx-mds/lvx-family's YAML description,
// or the generator in MDS/BE/MLIR/BIN, instead.
//
//===----------------------------------------------------------------===//

#ifndef LVX_MODIFIERS
#define LVX_MODIFIERS

include "mlir/IR/EnumAttr.td"

// `exunum` -- Execution Unit Number in Immediate Extensions.  2 bits.
def LVX_ExuNumAttr : I64EnumAttr<
    "ExuNum", "LVX Execution Unit Number in Immediate Extensions modifier",
    [
      I64EnumAttrCase<"alu0", 0,   "alu0">,  // ALU 0
      I64EnumAttrCase<"alu1", 1,   "alu1">,  // ALU 1
      I64EnumAttrCase<"lsu0", 2,   "lsu0">,  // LSU 0
      I64EnumAttrCase<"lsu1", 3,   "lsu1">,  // LSU 1
    ]> {
  let cppNamespace = "::mlir::lvx";
}

// `ccbcomp` -- CCB Double Word Compare.  4 bits.
def LVX_CcbCompAttr : I64EnumAttr<
    "CcbComp", "LVX CCB Double Word Compare modifier",
    [
      I64EnumAttrCase<"dlt",   0,   "dlt"  >,  // Double Word Less Than
      I64EnumAttrCase<"dge",   1,   "dge"  >,  // Double Word Greater Than or Equal
      I64EnumAttrCase<"dltu",  2,   "dltu" >,  // Double Word Less Than Unsigned
      I64EnumAttrCase<"dgeu",  3,   "dgeu" >,  // Double Word Greater Than or Equal Unsigned
      I64EnumAttrCase<"deq",   4,   "deq"  >,  // Double Word Equal
      I64EnumAttrCase<"dne",   5,   "dne"  >,  // Double Word Not Equal
      I64EnumAttrCase<"dany",  6,   "dany" >,  // Double Any bit set after AND-ing
      I64EnumAttrCase<"dnone", 7,   "dnone">,  // Double No bits set after AND-ing
      I64EnumAttrCase<"wlt",   8,   "wlt"  >,  // Word Less Than
      I64EnumAttrCase<"wge",   9,   "wge"  >,  // Word Greater Than or Equal
      I64EnumAttrCase<"wltu",  10,  "wltu" >,  // Word Less Than Unsigned
      I64EnumAttrCase<"wgeu",  11,  "wgeu" >,  // Word Greater Than or Equal Unsigned
      I64EnumAttrCase<"weq",   12,  "weq"  >,  // Word Equal
      I64EnumAttrCase<"wne",   13,  "wne"  >,  // Word Not Equal
      I64EnumAttrCase<"wany",  14,  "wany" >,  // Word Any bit set after AND-ing
      I64EnumAttrCase<"wnone", 15,  "wnone">,  // Word No bits set after AND-ing
    ]> {
  let cppNamespace = "::mlir::lvx";
}

// `bcucond` -- CB Condition.  4 bits.
def LVX_BcuCondAttr : I64EnumAttr<
    "BcuCond", "LVX CB Condition modifier",
    [
      I64EnumAttrCase<"dltz", 0,   "dltz">,  // Double Less Than Zero
      I64EnumAttrCase<"dgez", 1,   "dgez">,  // Double Greater Than or Equal to Zero
      I64EnumAttrCase<"dlez", 2,   "dlez">,  // Double Less Than or Equal to Zero
      I64EnumAttrCase<"dgtz", 3,   "dgtz">,  // Double Greater Than Zero
      I64EnumAttrCase<"deqz", 4,   "deqz">,  // Double Equal to Zero
      I64EnumAttrCase<"dnez", 5,   "dnez">,  // Double Not Equal to Zero
      I64EnumAttrCase<"odd",  6,   "odd" >,  // Odd (LSB Set)
      I64EnumAttrCase<"even", 7,   "even">,  // Even (LSB Clear)
      I64EnumAttrCase<"wltz", 8,   "wltz">,  // Word Less Than Zero
      I64EnumAttrCase<"wgez", 9,   "wgez">,  // Word Greater Than or Equal to Zero
      I64EnumAttrCase<"wlez", 10,  "wlez">,  // Word Less Than or Equal to Zero
      I64EnumAttrCase<"wgtz", 11,  "wgtz">,  // Word Greater Than Zero
      I64EnumAttrCase<"weqz", 12,  "weqz">,  // Word Equal to Zero
      I64EnumAttrCase<"wnez", 13,  "wnez">,  // Word Not Equal to Zero
    ]> {
  let cppNamespace = "::mlir::lvx";
}

// `intcomp` -- Integer Comparison.  4 bits.
def LVX_IntCompAttr : I64EnumAttr<
    "IntComp", "LVX Integer Comparison modifier",
    [
      I64EnumAttrCase<"lt",   0,   "lt"  >,  // Less Than
      I64EnumAttrCase<"ge",   1,   "ge"  >,  // Greater Than or Equal
      I64EnumAttrCase<"ltu",  2,   "ltu" >,  // Less Than Unsigned
      I64EnumAttrCase<"geu",  3,   "geu" >,  // Greater Than or Equal Unsigned
      I64EnumAttrCase<"eq",   4,   "eq"  >,  // Equal
      I64EnumAttrCase<"ne",   5,   "ne"  >,  // Not Equal
      I64EnumAttrCase<"any",  6,   "any" >,  // Any bits set in after AND-ing
      I64EnumAttrCase<"none", 7,   "none">,  // No bits set after AND-ing
      I64EnumAttrCase<"le",   8,   "le"  >,  // Less Than or Equal
      I64EnumAttrCase<"gt",   9,   "gt"  >,  // Greater Than
      I64EnumAttrCase<"leu",  10,  "leu" >,  // Less Than or Equal Unsigned
      I64EnumAttrCase<"gtu",  11,  "gtu" >,  // Greater Than Unsigned
    ]> {
  let cppNamespace = "::mlir::lvx";
}

// `lanecond` -- Lane Condition.  3 bits.
def LVX_LaneCondAttr : I64EnumAttr<
    "LaneCond", "LVX Lane Condition modifier",
    [
      I64EnumAttrCase<"ltz",  0,   "ltz" >,  // Less Than Zero
      I64EnumAttrCase<"gez",  1,   "gez" >,  // Greater Than or Equal to Zero
      I64EnumAttrCase<"lez",  2,   "lez" >,  // Less Than or Equal to Zero
      I64EnumAttrCase<"gtz",  3,   "gtz" >,  // Greater Than Zero
      I64EnumAttrCase<"eqz",  4,   "eqz" >,  // Equal to Zero
      I64EnumAttrCase<"nez",  5,   "nez" >,  // Not Equal to Zero
      I64EnumAttrCase<"odd",  6,   "odd" >,  // Odd (LSB Set)
      I64EnumAttrCase<"even", 7,   "even">,  // Even (LSB Clear)
    ]> {
  let cppNamespace = "::mlir::lvx";
}

// `lanetodo` -- BLEND Lane To Do.  2 bits.
def LVX_LaneTodoAttr : I64EnumAttr<
    "LaneTodo", "LVX BLEND Lane To Do modifier",
    [
      I64EnumAttrCase<"mt",  0,   "mt" >,  // Mask True
      I64EnumAttrCase<"mf",  1,   "mf" >,  // Mask False
      I64EnumAttrCase<"mtc", 2,   "mtc">,  // Mask True or Clear
      I64EnumAttrCase<"mfc", 3,   "mfc">,  // Mask False or Clear
    ]> {
  let cppNamespace = "::mlir::lvx";
}

// `lanesize` -- BLEND Lane Size.  2 bits.
//
// Absent attribute means the default encoding, which has no member
// here by design -- see the BE/MLIR design document, O4.
def LVX_LaneSizeAttr : I64EnumAttr<
    "LaneSize", "LVX BLEND Lane Size modifier",
    [
      I64EnumAttrCase<"h", 1,   "h">,  // Half Word Size
      I64EnumAttrCase<"w", 2,   "w">,  // Word Size
      I64EnumAttrCase<"d", 3,   "d">,  // Double Word Size
    ]> {
  let cppNamespace = "::mlir::lvx";
}

// `floatcomp` -- Floating-Point Comparison.  3 bits.
def LVX_FloatCompAttr : I64EnumAttr<
    "FloatComp", "LVX Floating-Point Comparison modifier",
    [
      I64EnumAttrCase<"one", 0,   "one">,  // Ordered and Not Equal
      I64EnumAttrCase<"ueq", 1,   "ueq">,  // Unordered or Equal
      I64EnumAttrCase<"oeq", 2,   "oeq">,  // Ordered and Equal
      I64EnumAttrCase<"une", 3,   "une">,  // Unordered or Not Equal
      I64EnumAttrCase<"olt", 4,   "olt">,  // Ordered and Less Than
      I64EnumAttrCase<"uge", 5,   "uge">,  // Unordered or Greater Than or Equal
      I64EnumAttrCase<"oge", 6,   "oge">,  // Ordered and Greater Than or Equal
      I64EnumAttrCase<"ult", 7,   "ult">,  // Unordered or Less Than
    ]> {
  let cppNamespace = "::mlir::lvx";
}

// `floatmode` -- Floating-Point Rounding Mode.  3 bits.
//
// Absent attribute means the default encoding, which has no member
// here by design -- see the BE/MLIR design document, O4.
def LVX_FloatModeAttr : I64EnumAttr<
    "FloatMode", "LVX Floating-Point Rounding Mode modifier",
    [
      I64EnumAttrCase<"rn", 0,   "rn">,  // Round to Nearest, ties to Even
      I64EnumAttrCase<"rz", 1,   "rz">,  // Round toward Zero
      I64EnumAttrCase<"rd", 2,   "rd">,  // Round Downward
      I64EnumAttrCase<"ru", 3,   "ru">,  // Round Upward
      I64EnumAttrCase<"rm", 4,   "rm">,  // Round to Nearest, ties to Max Magnitude
      I64EnumAttrCase<"ro", 6,   "ro">,  // Round to Odd
    ]> {
  let cppNamespace = "::mlir::lvx";
}

// `highmult` -- High Multiply.  2 bits.
//
// Absent attribute means the default encoding, which has no member
// here by design -- see the BE/MLIR design document, O4.
def LVX_HighMultAttr : I64EnumAttr<
    "HighMult", "LVX High Multiply modifier",
    [
      I64EnumAttrCase<"h",   0,   "h"  >,  // High
      I64EnumAttrCase<"hu",  1,   "hu" >,  // High Unsigned
      I64EnumAttrCase<"hsu", 2,   "hsu">,  // High Signed Unsigned
    ]> {
  let cppNamespace = "::mlir::lvx";
}

// `widemult` -- Wide Multiply.  2 bits.
//
// Absent attribute means the default encoding, which has no member
// here by design -- see the BE/MLIR design document, O4.
def LVX_WideMultAttr : I64EnumAttr<
    "WideMult", "LVX Wide Multiply modifier",
    [
      I64EnumAttrCase<"u",  1,   "u" >,  // Unsigned
      I64EnumAttrCase<"su", 2,   "su">,  // Signed by Unsigned
    ]> {
  let cppNamespace = "::mlir::lvx";
}

// `variant` -- Load Variants.  2 bits.
//
// Absent attribute means the default encoding, which has no member
// here by design -- see the BE/MLIR design document, O4.
def LVX_VariantAttr : I64EnumAttr<
    "Variant", "LVX Load Variants modifier",
    [
      I64EnumAttrCase<"s",  1,   "s" >,  // Speculative
      I64EnumAttrCase<"u",  2,   "u" >,  // Uncached
      I64EnumAttrCase<"us", 3,   "us">,  // Uncached Speculative
    ]> {
  let cppNamespace = "::mlir::lvx";
}

// `speculate` -- Speculative Load.  1 bit.
def LVX_SpeculateAttr : I64EnumAttr<
    "Speculate", "LVX Speculative Load modifier",
    [
      I64EnumAttrCase<"u",  0,   "u" >,  // Uncached
      I64EnumAttrCase<"us", 1,   "us">,  // Uncached Speculative
    ]> {
  let cppNamespace = "::mlir::lvx";
}

// `qindex` -- Quarter Index.  2 bits.
def LVX_QIndexAttr : I64EnumAttr<
    "QIndex", "LVX Quarter Index modifier",
    [
      I64EnumAttrCase<"q0", 0,   "q0">,  // Quarter 0
      I64EnumAttrCase<"q1", 1,   "q1">,  // Quarter 1
      I64EnumAttrCase<"q2", 2,   "q2">,  // Quarter 2
      I64EnumAttrCase<"q3", 3,   "q3">,  // Quarter 3
    ]> {
  let cppNamespace = "::mlir::lvx";
}

// `hindex` -- Half Index.  1 bit.
def LVX_HIndexAttr : I64EnumAttr<
    "HIndex", "LVX Half Index modifier",
    [
      I64EnumAttrCase<"h0", 0,   "h0">,  // Half 0
      I64EnumAttrCase<"h1", 1,   "h1">,  // Half 1
    ]> {
  let cppNamespace = "::mlir::lvx";
}

// `cachelev` -- Cache Level for Set/Way maintenance.  2 bits.
def LVX_CacheLevAttr : I64EnumAttr<
    "CacheLev", "LVX Cache Level for Set/Way maintenance modifier",
    [
      I64EnumAttrCase<"l1", 0,   "l1">,  // L1 Cache
      I64EnumAttrCase<"l2", 1,   "l2">,  // L2 Cache
    ]> {
  let cppNamespace = "::mlir::lvx";
}

// `accesses` -- Fence Access.  2 bits.
//
// Absent attribute means the default encoding, which has no member
// here by design -- see the BE/MLIR design document, O4.
def LVX_AccessesAttr : I64EnumAttr<
    "Accesses", "LVX Fence Access modifier",
    [
      I64EnumAttrCase<"w",  1,   "w" >,  // Write Accesses
      I64EnumAttrCase<"r",  2,   "r" >,  // Read Accesses
      I64EnumAttrCase<"wa", 3,   "wa">,  // Write Accesses (asynchronous)
    ]> {
  let cppNamespace = "::mlir::lvx";
}

// Two-state modifiers.  These carry no enum: the dialect spells them as a
// UnitAttr on each op that has them -- present or absent -- so their defs
// live with the ops rather than here.
//   modifier     suffix   meaning
//   signextw     .sx      Sign Extend Word
//   mostsig      .m       Least or Most Significant Bits
//   oddlanes     .o       Even or Odd SIMD Lanes
//   ziplanes     .z       Zip SIMD Lanes
//   fnegate      .n       Floating-Point Negate
//   doscale      .xs      Enable Scaling for Indexed Addressing
//   coherency    .g       Coherency Domain for atomics
//   boolcas      .v       Boolean Compare-and-Swap
//   conjugate    .c       Complex Conjugate
//   imultiply    .mi      Multiply by Imaginary Unit
//   splat32      .@       Splat 32-bit Immediate

// Format-extension suffix (O1). The bare format has NO member: absence
// means it, definitely, and never "not yet decided" -- O2. The assembler
// picks the encoding from the value, so this exists to account for size
// (bare/.x/.y are 1/2/3 syllables against a 3-syllable bundle), not to
// instruct the assembler.
def LVX_FormatAttr : I64EnumAttr<
    "Format", "LVX format-extension suffix",
    [
      I64EnumAttrCase<"d",  0, "d"  >,  // 93 formats
      I64EnumAttrCase<"m",  1, "m"  >,  // 57 formats
      I64EnumAttrCase<"o",  2, "o"  >,  // 93 formats
      I64EnumAttrCase<"w",  3, "w"  >,  // 43 formats
      I64EnumAttrCase<"x",  4, "x"  >,  // 44 formats
      I64EnumAttrCase<"y",  5, "y"  >,  // 40 formats
    ]> {
  let cppNamespace = "::mlir::lvx";
}

#endif // LVX_MODIFIERS
