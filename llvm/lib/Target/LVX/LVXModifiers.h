#ifndef LLVM_LIB_TARGET_LVX_LVXMODIFIERS_H
#define LLVM_LIB_TARGET_LVX_LVXMODIFIERS_H
// Auto-generated from lvx_Modifier.yml — do not edit by hand.

#include "llvm/ADT/StringRef.h"
#include <cstdint>

namespace llvm {
namespace LVXModifier {

// ────────────────────────────────────────────────────────────────
// ccbcomp — 4 bits  (CCB Double Word Compare)
static const char *CcbcompSuffixes[16] = {
  ".dlt",    // 0: Double Word Less Than
  ".dge",    // 1: Double Word Greater Than or Equal
  ".dltu",   // 2: Double Word Less Than Unsigned
  ".dgeu",   // 3: Double Word Greater Than or Equal Unsigned
  ".deq",    // 4: Double Word Equal
  ".dne",    // 5: Double Word Not Equal
  ".dany",   // 6: Double Any bit set after AND-ing
  ".dnone",  // 7: Double No bits set after AND-ing
  ".wlt",    // 8: Word Less Than
  ".wge",    // 9: Word Greater Than or Equal
  ".wltu",   // 10: Word Less Than Unsigned
  ".wgeu",   // 11: Word Greater Than or Equal Unsigned
  ".weq",    // 12: Word Equal
  ".wne",    // 13: Word Not Equal
  ".wany",   // 14: Word Any bit set after AND-ing
  ".wnone",  // 15: Word No bits set after AND-ing
};

inline const char *getCcbcompSuffix(uint8_t enc) {
  if (enc >= 16) return nullptr;
  return CcbcompSuffixes[enc];
}

inline int parseCcbcomp(StringRef s) {
  if (s == ".dlt")         return 0;
  if (s == ".dge")         return 1;
  if (s == ".dltu")        return 2;
  if (s == ".dgeu")        return 3;
  if (s == ".deq")         return 4;
  if (s == ".dne")         return 5;
  if (s == ".dany")        return 6;
  if (s == ".dnone")       return 7;
  if (s == ".wlt")         return 8;
  if (s == ".wge")         return 9;
  if (s == ".wltu")        return 10;
  if (s == ".wgeu")        return 11;
  if (s == ".weq")         return 12;
  if (s == ".wne")         return 13;
  if (s == ".wany")        return 14;
  if (s == ".wnone")       return 15;
  return -1;
}

// ────────────────────────────────────────────────────────────────
// bcucond — 4 bits  (CB Condition)
static const char *BcucondSuffixes[16] = {
  ".dltz",   // 0: Double Less Than Zero
  ".dgez",   // 1: Double Greater Than or Equal to Zero
  ".dlez",   // 2: Double Less Than or Equal to Zero
  ".dgtz",   // 3: Double Greater Than Zero
  ".deqz",   // 4: Double Equal to Zero
  ".dnez",   // 5: Double Not Equal to Zero
  ".odd",    // 6: Odd (LSB Set)
  ".even",   // 7: Even (LSB Clear)
  ".wltz",   // 8: Word Less Than Zero
  ".wgez",   // 9: Word Greater Than or Equal to Zero
  ".wlez",   // 10: Word Less Than or Equal to Zero
  ".wgtz",   // 11: Word Greater Than Zero
  ".weqz",   // 12: Word Equal to Zero
  ".wnez",   // 13: Word Not Equal to Zero
  nullptr,        // 14: undefined
  nullptr,        // 15: undefined
};

inline const char *getBcucondSuffix(uint8_t enc) {
  if (enc >= 16) return nullptr;
  return BcucondSuffixes[enc];
}

inline int parseBcucond(StringRef s) {
  if (s == ".dltz")        return 0;
  if (s == ".dgez")        return 1;
  if (s == ".dlez")        return 2;
  if (s == ".dgtz")        return 3;
  if (s == ".deqz")        return 4;
  if (s == ".dnez")        return 5;
  if (s == ".odd")         return 6;
  if (s == ".even")        return 7;
  if (s == ".wltz")        return 8;
  if (s == ".wgez")        return 9;
  if (s == ".wlez")        return 10;
  if (s == ".wgtz")        return 11;
  if (s == ".weqz")        return 12;
  if (s == ".wnez")        return 13;
  return -1;
}

// ────────────────────────────────────────────────────────────────
// intcomp — 4 bits  (Integer Comparison)
static const char *IntcompSuffixes[16] = {
  ".lt",     // 0: Less Than
  ".ge",     // 1: Greater Than or Equal
  ".ltu",    // 2: Less Than Unsigned
  ".geu",    // 3: Greater Than or Equal Unsigned
  ".eq",     // 4: Equal
  ".ne",     // 5: Not Equal
  ".any",    // 6: Any bits set in after AND-ing
  ".none",   // 7: No bits set after AND-ing
  ".le",     // 8: Less Than or Equal
  ".gt",     // 9: Greater Than
  ".leu",    // 10: Less Than or Equal Unsigned
  ".gtu",    // 11: Greater Than Unsigned
  nullptr,        // 12: undefined
  nullptr,        // 13: undefined
  nullptr,        // 14: undefined
  nullptr,        // 15: undefined
};

inline const char *getIntcompSuffix(uint8_t enc) {
  if (enc >= 16) return nullptr;
  return IntcompSuffixes[enc];
}

inline int parseIntcomp(StringRef s) {
  if (s == ".lt")          return 0;
  if (s == ".ge")          return 1;
  if (s == ".ltu")         return 2;
  if (s == ".geu")         return 3;
  if (s == ".eq")          return 4;
  if (s == ".ne")          return 5;
  if (s == ".any")         return 6;
  if (s == ".none")        return 7;
  if (s == ".le")          return 8;
  if (s == ".gt")          return 9;
  if (s == ".leu")         return 10;
  if (s == ".gtu")         return 11;
  return -1;
}

// ────────────────────────────────────────────────────────────────
// floatcomp — 3 bits  (Floating-Point Comparison)
static const char *FloatcompSuffixes[8] = {
  ".one",    // 0: Ordered and Not Equal
  ".ueq",    // 1: Unordered or Equal
  ".oeq",    // 2: Ordered and Equal
  ".une",    // 3: Unordered or Not Equal
  ".olt",    // 4: Ordered and Less Than
  ".uge",    // 5: Unordered or Greater Than or Equal
  ".oge",    // 6: Ordered and Greater Than or Equal
  ".ult",    // 7: Unordered or Less Than
};

inline const char *getFloatcompSuffix(uint8_t enc) {
  if (enc >= 8) return nullptr;
  return FloatcompSuffixes[enc];
}

inline int parseFloatcomp(StringRef s) {
  if (s == ".one")         return 0;
  if (s == ".ueq")         return 1;
  if (s == ".oeq")         return 2;
  if (s == ".une")         return 3;
  if (s == ".olt")         return 4;
  if (s == ".uge")         return 5;
  if (s == ".oge")         return 6;
  if (s == ".ult")         return 7;
  return -1;
}

// ────────────────────────────────────────────────────────────────
// floatmode — 3 bits  (Floating-Point Rounding Mode)
static const char *FloatmodeSuffixes[8] = {
  ".rn",     // 0: Round to Nearest, ties to Even
  ".rz",     // 1: Round toward Zero
  ".rd",     // 2: Round Downward
  ".ru",     // 3: Round Upward
  ".rm",     // 4: Round to Nearest, ties to Max Magnitude
  ".r5",     // 5: Reserved 5
  ".ro",     // 6: Round to Odd
  "",        // 7: Use CS rounding
};

inline const char *getFloatmodeSuffix(uint8_t enc) {
  if (enc >= 8) return nullptr;
  return FloatmodeSuffixes[enc];
}

inline int parseFloatmode(StringRef s) {
  if (s == ".rn")          return 0;
  if (s == ".rz")          return 1;
  if (s == ".rd")          return 2;
  if (s == ".ru")          return 3;
  if (s == ".rm")          return 4;
  if (s == ".r5")          return 5;
  if (s == ".ro")          return 6;
  if (s.empty())     return 7;
  return -1;
}

// ────────────────────────────────────────────────────────────────
// signextw — 1 bit  (Sign Extend Word)
static const char *SignextwSuffixes[2] = {
  "",        // 0: Zero Extend
  ".sx",     // 1: Sign Extend
};

inline const char *getSignextwSuffix(uint8_t enc) {
  if (enc >= 2) return nullptr;
  return SignextwSuffixes[enc];
}

inline int parseSignextw(StringRef s) {
  if (s.empty())     return 0;
  if (s == ".sx")          return 1;
  return -1;
}

// ────────────────────────────────────────────────────────────────
// highmult — 2 bits  (High Multiply)
static const char *HighmultSuffixes[4] = {
  "",        // 0: Low
  ".h",      // 1: High
  ".hu",     // 2: High Unsigned
  ".hsu",    // 3: High Signed Unsigned
};

inline const char *getHighmultSuffix(uint8_t enc) {
  if (enc >= 4) return nullptr;
  return HighmultSuffixes[enc];
}

inline int parseHighmult(StringRef s) {
  if (s.empty())     return 0;
  if (s == ".h")           return 1;
  if (s == ".hu")          return 2;
  if (s == ".hsu")         return 3;
  return -1;
}

// ────────────────────────────────────────────────────────────────
// widemult — 2 bits  (Wide Multiply)
static const char *WidemultSuffixes[4] = {
  "",        // 0: Signed
  ".u",      // 1: Unsigned
  ".su",     // 2: Signed by Unsigned
  nullptr,        // 3: undefined
};

inline const char *getWidemultSuffix(uint8_t enc) {
  if (enc >= 4) return nullptr;
  return WidemultSuffixes[enc];
}

inline int parseWidemult(StringRef s) {
  if (s.empty())     return 0;
  if (s == ".u")           return 1;
  if (s == ".su")          return 2;
  return -1;
}

// ────────────────────────────────────────────────────────────────
// mostsig — 1 bit  (Least or Most Significant Bits)
static const char *MostsigSuffixes[2] = {
  "",        // 0: Least Significant Bits
  ".m",      // 1: Most Significant Bits
};

inline const char *getMostsigSuffix(uint8_t enc) {
  if (enc >= 2) return nullptr;
  return MostsigSuffixes[enc];
}

inline int parseMostsig(StringRef s) {
  if (s.empty())     return 0;
  if (s == ".m")           return 1;
  return -1;
}

// ────────────────────────────────────────────────────────────────
// fnegate — 1 bit  (Floating-Point Negate)
static const char *FnegateSuffixes[2] = {
  "",        // 0: Default Result
  ".n",      // 1: Negate Result
};

inline const char *getFnegateSuffix(uint8_t enc) {
  if (enc >= 2) return nullptr;
  return FnegateSuffixes[enc];
}

inline int parseFnegate(StringRef s) {
  if (s.empty())     return 0;
  if (s == ".n")           return 1;
  return -1;
}

// ────────────────────────────────────────────────────────────────
// variant — 2 bits  (Load Variants)
static const char *VariantSuffixes[4] = {
  "",        // 0: Cached
  ".s",      // 1: Speculative
  ".u",      // 2: Uncached
  ".us",     // 3: Uncached Speculative
};

inline const char *getVariantSuffix(uint8_t enc) {
  if (enc >= 4) return nullptr;
  return VariantSuffixes[enc];
}

inline int parseVariant(StringRef s) {
  if (s.empty())     return 0;
  if (s == ".s")           return 1;
  if (s == ".u")           return 2;
  if (s == ".us")          return 3;
  return -1;
}

// ────────────────────────────────────────────────────────────────
// cachelev — 2 bits  (Cache Level for Set/Way maintenance)
static const char *CachelevSuffixes[4] = {
  ".l1",     // 0: L1 Cache
  ".l2",     // 1: L2 Cache
  nullptr,        // 2: undefined
  nullptr,        // 3: undefined
};

inline const char *getCachelevSuffix(uint8_t enc) {
  if (enc >= 4) return nullptr;
  return CachelevSuffixes[enc];
}

inline int parseCachelev(StringRef s) {
  if (s == ".l1")          return 0;
  if (s == ".l2")          return 1;
  return -1;
}

// ────────────────────────────────────────────────────────────────
// accesses — 2 bits  (Fence Access)
static const char *AccessesSuffixes[4] = {
  "",        // 0: All Accesses
  ".w",      // 1: Write Accesses
  ".r",      // 2: Read Accesses
  ".wa",     // 3: Write Accesses (asynchronous)
};

inline const char *getAccessesSuffix(uint8_t enc) {
  if (enc >= 4) return nullptr;
  return AccessesSuffixes[enc];
}

inline int parseAccesses(StringRef s) {
  if (s.empty())     return 0;
  if (s == ".w")           return 1;
  if (s == ".r")           return 2;
  if (s == ".wa")          return 3;
  return -1;
}

// ────────────────────────────────────────────────────────────────
// conjugate — 1 bit  (Complex Conjugate)
static const char *ConjugateSuffixes[2] = {
  "",        // 0: Default
  ".c",      // 1: Conjugate
};

inline const char *getConjugateSuffix(uint8_t enc) {
  if (enc >= 2) return nullptr;
  return ConjugateSuffixes[enc];
}

inline int parseConjugate(StringRef s) {
  if (s.empty())     return 0;
  if (s == ".c")           return 1;
  return -1;
}

// ────────────────────────────────────────────────────────────────
// imultiply — 1 bit  (Multiply by Imaginary Unit)
static const char *ImultiplySuffixes[2] = {
  "",        // 0: Default
  ".mi",     // 1: Multiply by I
};

inline const char *getImultiplySuffix(uint8_t enc) {
  if (enc >= 2) return nullptr;
  return ImultiplySuffixes[enc];
}

inline int parseImultiply(StringRef s) {
  if (s.empty())     return 0;
  if (s == ".mi")          return 1;
  return -1;
}

} // end namespace LVXModifier
} // end namespace llvm

#endif // LLVM_LIB_TARGET_LVX_LVXMODIFIERS_H
