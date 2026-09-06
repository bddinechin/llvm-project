//===-- LVXModifiers.h - -*- C++ -*- ===//
//
// Assembly-suffix tables for the LVX instruction modifiers.
//
// Generated from the LVX Machine Description System by MDS/BE/LLVM,
// for core lvx_v1.  DO NOT EDIT -- your changes will be overwritten by
// the next `make -C BE/LLVM install`.  Change lvx-mds/lvx-family's YAML
// description, or the generator in MDS/BE/LLVM/BIN, instead.
//
//===----------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_LVX_LVXMODIFIERS_H
#define LLVM_LIB_TARGET_LVX_LVXMODIFIERS_H

#include "llvm/ADT/StringRef.h"
#include <cstdint>

namespace llvm {
namespace LVXModifier {

// ────────────────────────────────────────────────────────────────
// exunum — 2 bits  (Execution Unit Number in Immediate Extensions)
static const char *ExunumSuffixes[4] = {
  "alu0",   // 0: ALU 0
  "alu1",   // 1: ALU 1
  "lsu0",   // 2: LSU 0
  "lsu1",   // 3: LSU 1
};

inline const char *getExunumSuffix(uint8_t enc) {
  if (enc >= 4) return nullptr;
  return ExunumSuffixes[enc];
}

inline int parseExunum(StringRef s) {
  if (s == "alu0"      ) return 0;
  if (s == "alu1"      ) return 1;
  if (s == "lsu0"      ) return 2;
  if (s == "lsu1"      ) return 3;
  return -1;
}

// ────────────────────────────────────────────────────────────────
// ccbcomp — 4 bits  (CCB Double Word Compare)
static const char *CcbcompSuffixes[16] = {
  ".dlt",   // 0: Double Word Less Than
  ".dge",   // 1: Double Word Greater Than or Equal
  ".dltu",  // 2: Double Word Less Than Unsigned
  ".dgeu",  // 3: Double Word Greater Than or Equal Unsigned
  ".deq",   // 4: Double Word Equal
  ".dne",   // 5: Double Word Not Equal
  ".dany",  // 6: Double Any bit set after AND-ing
  ".dnone", // 7: Double No bits set after AND-ing
  ".wlt",   // 8: Word Less Than
  ".wge",   // 9: Word Greater Than or Equal
  ".wltu",  // 10: Word Less Than Unsigned
  ".wgeu",  // 11: Word Greater Than or Equal Unsigned
  ".weq",   // 12: Word Equal
  ".wne",   // 13: Word Not Equal
  ".wany",  // 14: Word Any bit set after AND-ing
  ".wnone", // 15: Word No bits set after AND-ing
};

inline const char *getCcbcompSuffix(uint8_t enc) {
  if (enc >= 16) return nullptr;
  return CcbcompSuffixes[enc];
}

inline int parseCcbcomp(StringRef s) {
  if (s == ".dlt"      ) return 0;
  if (s == ".dge"      ) return 1;
  if (s == ".dltu"     ) return 2;
  if (s == ".dgeu"     ) return 3;
  if (s == ".deq"      ) return 4;
  if (s == ".dne"      ) return 5;
  if (s == ".dany"     ) return 6;
  if (s == ".dnone"    ) return 7;
  if (s == ".wlt"      ) return 8;
  if (s == ".wge"      ) return 9;
  if (s == ".wltu"     ) return 10;
  if (s == ".wgeu"     ) return 11;
  if (s == ".weq"      ) return 12;
  if (s == ".wne"      ) return 13;
  if (s == ".wany"     ) return 14;
  if (s == ".wnone"    ) return 15;
  return -1;
}

// ────────────────────────────────────────────────────────────────
// bcucond — 4 bits  (CB Condition)
static const char *BcucondSuffixes[16] = {
  ".dltz",  // 0: Double Less Than Zero
  ".dgez",  // 1: Double Greater Than or Equal to Zero
  ".dlez",  // 2: Double Less Than or Equal to Zero
  ".dgtz",  // 3: Double Greater Than Zero
  ".deqz",  // 4: Double Equal to Zero
  ".dnez",  // 5: Double Not Equal to Zero
  ".odd",   // 6: Odd (LSB Set)
  ".even",  // 7: Even (LSB Clear)
  ".wltz",  // 8: Word Less Than Zero
  ".wgez",  // 9: Word Greater Than or Equal to Zero
  ".wlez",  // 10: Word Less Than or Equal to Zero
  ".wgtz",  // 11: Word Greater Than Zero
  ".weqz",  // 12: Word Equal to Zero
  ".wnez",  // 13: Word Not Equal to Zero
  nullptr,  // 14: undefined
  nullptr,  // 15: undefined
};

inline const char *getBcucondSuffix(uint8_t enc) {
  if (enc >= 16) return nullptr;
  return BcucondSuffixes[enc];
}

inline int parseBcucond(StringRef s) {
  if (s == ".dltz"     ) return 0;
  if (s == ".dgez"     ) return 1;
  if (s == ".dlez"     ) return 2;
  if (s == ".dgtz"     ) return 3;
  if (s == ".deqz"     ) return 4;
  if (s == ".dnez"     ) return 5;
  if (s == ".odd"      ) return 6;
  if (s == ".even"     ) return 7;
  if (s == ".wltz"     ) return 8;
  if (s == ".wgez"     ) return 9;
  if (s == ".wlez"     ) return 10;
  if (s == ".wgtz"     ) return 11;
  if (s == ".weqz"     ) return 12;
  if (s == ".wnez"     ) return 13;
  return -1;
}

// ────────────────────────────────────────────────────────────────
// intcomp — 4 bits  (Integer Comparison)
static const char *IntcompSuffixes[16] = {
  ".lt",    // 0: Less Than
  ".ge",    // 1: Greater Than or Equal
  ".ltu",   // 2: Less Than Unsigned
  ".geu",   // 3: Greater Than or Equal Unsigned
  ".eq",    // 4: Equal
  ".ne",    // 5: Not Equal
  ".any",   // 6: Any bits set in after AND-ing
  ".none",  // 7: No bits set after AND-ing
  ".le",    // 8: Less Than or Equal
  ".gt",    // 9: Greater Than
  ".leu",   // 10: Less Than or Equal Unsigned
  ".gtu",   // 11: Greater Than Unsigned
  nullptr,  // 12: undefined
  nullptr,  // 13: undefined
  nullptr,  // 14: undefined
  nullptr,  // 15: undefined
};

inline const char *getIntcompSuffix(uint8_t enc) {
  if (enc >= 16) return nullptr;
  return IntcompSuffixes[enc];
}

inline int parseIntcomp(StringRef s) {
  if (s == ".lt"       ) return 0;
  if (s == ".ge"       ) return 1;
  if (s == ".ltu"      ) return 2;
  if (s == ".geu"      ) return 3;
  if (s == ".eq"       ) return 4;
  if (s == ".ne"       ) return 5;
  if (s == ".any"      ) return 6;
  if (s == ".none"     ) return 7;
  if (s == ".le"       ) return 8;
  if (s == ".gt"       ) return 9;
  if (s == ".leu"      ) return 10;
  if (s == ".gtu"      ) return 11;
  return -1;
}

// ────────────────────────────────────────────────────────────────
// lanecond — 3 bits  (Lane Condition)
static const char *LanecondSuffixes[8] = {
  ".ltz",   // 0: Less Than Zero
  ".gez",   // 1: Greater Than or Equal to Zero
  ".lez",   // 2: Less Than or Equal to Zero
  ".gtz",   // 3: Greater Than Zero
  ".eqz",   // 4: Equal to Zero
  ".nez",   // 5: Not Equal to Zero
  ".odd",   // 6: Odd (LSB Set)
  ".even",  // 7: Even (LSB Clear)
};

inline const char *getLanecondSuffix(uint8_t enc) {
  if (enc >= 8) return nullptr;
  return LanecondSuffixes[enc];
}

inline int parseLanecond(StringRef s) {
  if (s == ".ltz"      ) return 0;
  if (s == ".gez"      ) return 1;
  if (s == ".lez"      ) return 2;
  if (s == ".gtz"      ) return 3;
  if (s == ".eqz"      ) return 4;
  if (s == ".nez"      ) return 5;
  if (s == ".odd"      ) return 6;
  if (s == ".even"     ) return 7;
  return -1;
}

// ────────────────────────────────────────────────────────────────
// lanetodo — 2 bits  (BLEND Lane To Do)
static const char *LanetodoSuffixes[4] = {
  ".mt",    // 0: Mask True
  ".mf",    // 1: Mask False
  ".mtc",   // 2: Mask True or Clear
  ".mfc",   // 3: Mask False or Clear
};

inline const char *getLanetodoSuffix(uint8_t enc) {
  if (enc >= 4) return nullptr;
  return LanetodoSuffixes[enc];
}

inline int parseLanetodo(StringRef s) {
  if (s == ".mt"       ) return 0;
  if (s == ".mf"       ) return 1;
  if (s == ".mtc"      ) return 2;
  if (s == ".mfc"      ) return 3;
  return -1;
}

// ────────────────────────────────────────────────────────────────
// lanesize — 2 bits  (BLEND Lane Size)
static const char *LanesizeSuffixes[4] = {
  "",       // 0: Byte Size
  ".h",     // 1: Half Word Size
  ".w",     // 2: Word Size
  ".d",     // 3: Double Word Size
};

inline const char *getLanesizeSuffix(uint8_t enc) {
  if (enc >= 4) return nullptr;
  return LanesizeSuffixes[enc];
}

inline int parseLanesize(StringRef s) {
  if (s == ""          ) return 0;
  if (s == ".h"        ) return 1;
  if (s == ".w"        ) return 2;
  if (s == ".d"        ) return 3;
  return -1;
}

// ────────────────────────────────────────────────────────────────
// floatcomp — 3 bits  (Floating-Point Comparison)
static const char *FloatcompSuffixes[8] = {
  ".one",   // 0: Ordered and Not Equal
  ".ueq",   // 1: Unordered or Equal
  ".oeq",   // 2: Ordered and Equal
  ".une",   // 3: Unordered or Not Equal
  ".olt",   // 4: Ordered and Less Than
  ".uge",   // 5: Unordered or Greater Than or Equal
  ".oge",   // 6: Ordered and Greater Than or Equal
  ".ult",   // 7: Unordered or Less Than
};

inline const char *getFloatcompSuffix(uint8_t enc) {
  if (enc >= 8) return nullptr;
  return FloatcompSuffixes[enc];
}

inline int parseFloatcomp(StringRef s) {
  if (s == ".one"      ) return 0;
  if (s == ".ueq"      ) return 1;
  if (s == ".oeq"      ) return 2;
  if (s == ".une"      ) return 3;
  if (s == ".olt"      ) return 4;
  if (s == ".uge"      ) return 5;
  if (s == ".oge"      ) return 6;
  if (s == ".ult"      ) return 7;
  return -1;
}

// ────────────────────────────────────────────────────────────────
// floatmode — 3 bits  (Floating-Point Rounding Mode)
static const char *FloatmodeSuffixes[8] = {
  ".rn",    // 0: Round to Nearest, ties to Even
  ".rz",    // 1: Round toward Zero
  ".rd",    // 2: Round Downward
  ".ru",    // 3: Round Upward
  ".rm",    // 4: Round to Nearest, ties to Max Magnitude
  ".r5",    // 5: Reserved 5
  ".ro",    // 6: Round to Odd
  "",       // 7: Use CS rounding
};

inline const char *getFloatmodeSuffix(uint8_t enc) {
  if (enc >= 8) return nullptr;
  return FloatmodeSuffixes[enc];
}

inline int parseFloatmode(StringRef s) {
  if (s == ".rn"       ) return 0;
  if (s == ".rz"       ) return 1;
  if (s == ".rd"       ) return 2;
  if (s == ".ru"       ) return 3;
  if (s == ".rm"       ) return 4;
  if (s == ".r5"       ) return 5;
  if (s == ".ro"       ) return 6;
  if (s == ""          ) return 7;
  return -1;
}

// ────────────────────────────────────────────────────────────────
// signextw — 1 bit  (Sign Extend Word)
static const char *SignextwSuffixes[2] = {
  "",       // 0: Zero Extend
  ".sx",    // 1: Sign Extend
};

inline const char *getSignextwSuffix(uint8_t enc) {
  if (enc >= 2) return nullptr;
  return SignextwSuffixes[enc];
}

inline int parseSignextw(StringRef s) {
  if (s == ""          ) return 0;
  if (s == ".sx"       ) return 1;
  return -1;
}

// ────────────────────────────────────────────────────────────────
// highmult — 2 bits  (High Multiply)
static const char *HighmultSuffixes[4] = {
  ".h",     // 0: High
  ".hu",    // 1: High Unsigned
  ".hsu",   // 2: High Signed Unsigned
  "",       // 3: Low
};

inline const char *getHighmultSuffix(uint8_t enc) {
  if (enc >= 4) return nullptr;
  return HighmultSuffixes[enc];
}

inline int parseHighmult(StringRef s) {
  if (s == ".h"        ) return 0;
  if (s == ".hu"       ) return 1;
  if (s == ".hsu"      ) return 2;
  if (s == ""          ) return 3;
  return -1;
}

// ────────────────────────────────────────────────────────────────
// widemult — 2 bits  (Wide Multiply)
static const char *WidemultSuffixes[4] = {
  "",       // 0: Signed
  ".u",     // 1: Unsigned
  ".su",    // 2: Signed by Unsigned
  nullptr,  // 3: undefined
};

inline const char *getWidemultSuffix(uint8_t enc) {
  if (enc >= 4) return nullptr;
  return WidemultSuffixes[enc];
}

inline int parseWidemult(StringRef s) {
  if (s == ""          ) return 0;
  if (s == ".u"        ) return 1;
  if (s == ".su"       ) return 2;
  return -1;
}

// ────────────────────────────────────────────────────────────────
// mostsig — 1 bit  (Least or Most Significant Bits)
static const char *MostsigSuffixes[2] = {
  "",       // 0: Least Significant Bits
  ".m",     // 1: Most Significant Bits
};

inline const char *getMostsigSuffix(uint8_t enc) {
  if (enc >= 2) return nullptr;
  return MostsigSuffixes[enc];
}

inline int parseMostsig(StringRef s) {
  if (s == ""          ) return 0;
  if (s == ".m"        ) return 1;
  return -1;
}

// ────────────────────────────────────────────────────────────────
// oddlanes — 1 bit  (Even or Odd SIMD Lanes)
static const char *OddlanesSuffixes[2] = {
  "",       // 0: Even Lanes
  ".o",     // 1: Odd Lanes
};

inline const char *getOddlanesSuffix(uint8_t enc) {
  if (enc >= 2) return nullptr;
  return OddlanesSuffixes[enc];
}

inline int parseOddlanes(StringRef s) {
  if (s == ""          ) return 0;
  if (s == ".o"        ) return 1;
  return -1;
}

// ────────────────────────────────────────────────────────────────
// ziplanes — 1 bit  (Zip SIMD Lanes)
static const char *ZiplanesSuffixes[2] = {
  "",       // 0: No zip
  ".z",     // 1: Zip lanes
};

inline const char *getZiplanesSuffix(uint8_t enc) {
  if (enc >= 2) return nullptr;
  return ZiplanesSuffixes[enc];
}

inline int parseZiplanes(StringRef s) {
  if (s == ""          ) return 0;
  if (s == ".z"        ) return 1;
  return -1;
}

// ────────────────────────────────────────────────────────────────
// fnegate — 1 bit  (Floating-Point Negate)
static const char *FnegateSuffixes[2] = {
  "",       // 0: Default Result
  ".n",     // 1: Negate Result
};

inline const char *getFnegateSuffix(uint8_t enc) {
  if (enc >= 2) return nullptr;
  return FnegateSuffixes[enc];
}

inline int parseFnegate(StringRef s) {
  if (s == ""          ) return 0;
  if (s == ".n"        ) return 1;
  return -1;
}

// ────────────────────────────────────────────────────────────────
// variant — 2 bits  (Load Variants)
static const char *VariantSuffixes[4] = {
  "",       // 0: Cached
  ".s",     // 1: Speculative
  ".u",     // 2: Uncached
  ".us",    // 3: Uncached Speculative
};

inline const char *getVariantSuffix(uint8_t enc) {
  if (enc >= 4) return nullptr;
  return VariantSuffixes[enc];
}

inline int parseVariant(StringRef s) {
  if (s == ""          ) return 0;
  if (s == ".s"        ) return 1;
  if (s == ".u"        ) return 2;
  if (s == ".us"       ) return 3;
  return -1;
}

// ────────────────────────────────────────────────────────────────
// speculate — 1 bit  (Speculative Load)
static const char *SpeculateSuffixes[2] = {
  ".u",     // 0: Uncached
  ".us",    // 1: Uncached Speculative
};

inline const char *getSpeculateSuffix(uint8_t enc) {
  if (enc >= 2) return nullptr;
  return SpeculateSuffixes[enc];
}

inline int parseSpeculate(StringRef s) {
  if (s == ".u"        ) return 0;
  if (s == ".us"       ) return 1;
  return -1;
}

// ────────────────────────────────────────────────────────────────
// doscale — 1 bit  (Enable Scaling for Indexed Addressing)
static const char *DoscaleSuffixes[2] = {
  "",       // 0: Scale by 1
  ".xs",    // 1: Scale by sizeof
};

inline const char *getDoscaleSuffix(uint8_t enc) {
  if (enc >= 2) return nullptr;
  return DoscaleSuffixes[enc];
}

inline int parseDoscale(StringRef s) {
  if (s == ""          ) return 0;
  if (s == ".xs"       ) return 1;
  return -1;
}

// ────────────────────────────────────────────────────────────────
// qindex — 2 bits  (Quarter Index)
static const char *QindexSuffixes[4] = {
  ".q0",    // 0: Quarter 0
  ".q1",    // 1: Quarter 1
  ".q2",    // 2: Quarter 2
  ".q3",    // 3: Quarter 3
};

inline const char *getQindexSuffix(uint8_t enc) {
  if (enc >= 4) return nullptr;
  return QindexSuffixes[enc];
}

inline int parseQindex(StringRef s) {
  if (s == ".q0"       ) return 0;
  if (s == ".q1"       ) return 1;
  if (s == ".q2"       ) return 2;
  if (s == ".q3"       ) return 3;
  return -1;
}

// ────────────────────────────────────────────────────────────────
// hindex — 1 bit  (Half Index)
static const char *HindexSuffixes[2] = {
  ".h0",    // 0: Half 0
  ".h1",    // 1: Half 1
};

inline const char *getHindexSuffix(uint8_t enc) {
  if (enc >= 2) return nullptr;
  return HindexSuffixes[enc];
}

inline int parseHindex(StringRef s) {
  if (s == ".h0"       ) return 0;
  if (s == ".h1"       ) return 1;
  return -1;
}

// ────────────────────────────────────────────────────────────────
// cachelev — 2 bits  (Cache Level for Set/Way maintenance)
static const char *CachelevSuffixes[4] = {
  ".l1",    // 0: L1 Cache
  ".l2",    // 1: L2 Cache
  nullptr,  // 2: undefined
  nullptr,  // 3: undefined
};

inline const char *getCachelevSuffix(uint8_t enc) {
  if (enc >= 4) return nullptr;
  return CachelevSuffixes[enc];
}

inline int parseCachelev(StringRef s) {
  if (s == ".l1"       ) return 0;
  if (s == ".l2"       ) return 1;
  return -1;
}

// ────────────────────────────────────────────────────────────────
// coherency — 2 bits  (Coherency Domain for atomics)
static const char *CoherencySuffixes[4] = {
  "",       // 0: Local
  ".g",     // 1: Global
  ".s",     // 2: Reserved
  nullptr,  // 3: undefined
};

inline const char *getCoherencySuffix(uint8_t enc) {
  if (enc >= 4) return nullptr;
  return CoherencySuffixes[enc];
}

inline int parseCoherency(StringRef s) {
  if (s == ""          ) return 0;
  if (s == ".g"        ) return 1;
  if (s == ".s"        ) return 2;
  return -1;
}

// ────────────────────────────────────────────────────────────────
// boolcas — 1 bit  (Boolean Compare-and-Swap)
static const char *BoolcasSuffixes[2] = {
  ".v",     // 0: Valued CAS
  "",       // 1: Boolean CAS
};

inline const char *getBoolcasSuffix(uint8_t enc) {
  if (enc >= 2) return nullptr;
  return BoolcasSuffixes[enc];
}

inline int parseBoolcas(StringRef s) {
  if (s == ".v"        ) return 0;
  if (s == ""          ) return 1;
  return -1;
}

// ────────────────────────────────────────────────────────────────
// accesses — 2 bits  (Fence Access)
static const char *AccessesSuffixes[4] = {
  "",       // 0: All Accesses
  ".w",     // 1: Write Accesses
  ".r",     // 2: Read Accesses
  ".wa",    // 3: Write Accesses (asynchronous)
};

inline const char *getAccessesSuffix(uint8_t enc) {
  if (enc >= 4) return nullptr;
  return AccessesSuffixes[enc];
}

inline int parseAccesses(StringRef s) {
  if (s == ""          ) return 0;
  if (s == ".w"        ) return 1;
  if (s == ".r"        ) return 2;
  if (s == ".wa"       ) return 3;
  return -1;
}

// ────────────────────────────────────────────────────────────────
// conjugate — 1 bit  (Complex Conjugate)
static const char *ConjugateSuffixes[2] = {
  "",       // 0: Default
  ".c",     // 1: Conjugate
};

inline const char *getConjugateSuffix(uint8_t enc) {
  if (enc >= 2) return nullptr;
  return ConjugateSuffixes[enc];
}

inline int parseConjugate(StringRef s) {
  if (s == ""          ) return 0;
  if (s == ".c"        ) return 1;
  return -1;
}

// ────────────────────────────────────────────────────────────────
// imultiply — 1 bit  (Multiply by Imaginary Unit)
static const char *ImultiplySuffixes[2] = {
  "",       // 0: Default
  ".mi",    // 1: Multiply by I
};

inline const char *getImultiplySuffix(uint8_t enc) {
  if (enc >= 2) return nullptr;
  return ImultiplySuffixes[enc];
}

inline int parseImultiply(StringRef s) {
  if (s == ""          ) return 0;
  if (s == ".mi"       ) return 1;
  return -1;
}

// ────────────────────────────────────────────────────────────────
// splat32 — 1 bit  (Splat 32-bit Immediate)
static const char *Splat32Suffixes[2] = {
  "",       // 0: No splat
  ".@",     // 1: Splat x2
};

inline const char *getSplat32Suffix(uint8_t enc) {
  if (enc >= 2) return nullptr;
  return Splat32Suffixes[enc];
}

inline int parseSplat32(StringRef s) {
  if (s == ""          ) return 0;
  if (s == ".@"        ) return 1;
  return -1;
}

// Every modifier, as (CamelName, tablegen_name, width).  LVXInstPrinter
// expands this to declare and define one print method per modifier.
#define LVX_FOR_EACH_MODIFIER(X) \
  X(Exunum, exunum, 2) \
  X(Ccbcomp, ccbcomp, 4) \
  X(Bcucond, bcucond, 4) \
  X(Intcomp, intcomp, 4) \
  X(Lanecond, lanecond, 3) \
  X(Lanetodo, lanetodo, 2) \
  X(Lanesize, lanesize, 2) \
  X(Floatcomp, floatcomp, 3) \
  X(Floatmode, floatmode, 3) \
  X(Signextw, signextw, 1) \
  X(Highmult, highmult, 2) \
  X(Widemult, widemult, 2) \
  X(Mostsig, mostsig, 1) \
  X(Oddlanes, oddlanes, 1) \
  X(Ziplanes, ziplanes, 1) \
  X(Fnegate, fnegate, 1) \
  X(Variant, variant, 2) \
  X(Speculate, speculate, 1) \
  X(Doscale, doscale, 1) \
  X(Qindex, qindex, 2) \
  X(Hindex, hindex, 1) \
  X(Cachelev, cachelev, 2) \
  X(Coherency, coherency, 2) \
  X(Boolcas, boolcas, 1) \
  X(Accesses, accesses, 2) \
  X(Conjugate, conjugate, 1) \
  X(Imultiply, imultiply, 1) \
  X(Splat32, splat32, 1)

} // end namespace LVXModifier
} // end namespace llvm

#endif // LLVM_LIB_TARGET_LVX_LVXMODIFIERS_H
