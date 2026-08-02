//===-- LVXInstrFormats.td - -*- tablegen -*- ===//
//
// Operand types for the LVX instruction operands.
//
// Generated from the LVX Machine Description System by MDS/BE/LLVM,
// for core lvx_v1.  DO NOT EDIT -- your changes will be overwritten by
// the next `make -C BE/LLVM install`.  Change lvx-mds/lvx-family's YAML
// description, or the generator in MDS/BE/LLVM/BIN, instead.
//
//===----------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Modifier operands
//
// Each corresponds to a Modifier of the machine description; the suffix
// tables and the parse/print helpers live in LVXModifiers.h.
//===----------------------------------------------------------------------===//

// exunum — 2 bits  (Execution Unit Number in Immediate Extensions)
def LVXExunumAsmOperand : AsmOperandClass {
  let Name           = "Exunum";
  let ParserMethod   = "parseModifier";
  let DiagnosticType = "InvalidExunum";
}
def exunum : Operand<i32> {
  let PrintMethod      = "printExunum";
  let EncoderMethod    = "getExunumOpValue";
  let DecoderMethod    = "decodeExunum";
  let ParserMatchClass = LVXExunumAsmOperand;
  let OperandType      = "OPERAND_IMMEDIATE";
}

// ccbcomp — 4 bits  (CCB Double Word Compare)
def LVXCcbcompAsmOperand : AsmOperandClass {
  let Name           = "Ccbcomp";
  let ParserMethod   = "parseModifier";
  let DiagnosticType = "InvalidCcbcomp";
}
def ccbcomp : Operand<i32> {
  let PrintMethod      = "printCcbcomp";
  let EncoderMethod    = "getCcbcompOpValue";
  let DecoderMethod    = "decodeCcbcomp";
  let ParserMatchClass = LVXCcbcompAsmOperand;
  let OperandType      = "OPERAND_IMMEDIATE";
}

// bcucond — 4 bits  (CB Condition)
def LVXBcucondAsmOperand : AsmOperandClass {
  let Name           = "Bcucond";
  let ParserMethod   = "parseModifier";
  let DiagnosticType = "InvalidBcucond";
}
def bcucond : Operand<i32> {
  let PrintMethod      = "printBcucond";
  let EncoderMethod    = "getBcucondOpValue";
  let DecoderMethod    = "decodeBcucond";
  let ParserMatchClass = LVXBcucondAsmOperand;
  let OperandType      = "OPERAND_IMMEDIATE";
}

// intcomp — 4 bits  (Integer Comparison)
def LVXIntcompAsmOperand : AsmOperandClass {
  let Name           = "Intcomp";
  let ParserMethod   = "parseModifier";
  let DiagnosticType = "InvalidIntcomp";
}
def intcomp : Operand<i32> {
  let PrintMethod      = "printIntcomp";
  let EncoderMethod    = "getIntcompOpValue";
  let DecoderMethod    = "decodeIntcomp";
  let ParserMatchClass = LVXIntcompAsmOperand;
  let OperandType      = "OPERAND_IMMEDIATE";
}

// lanecond — 3 bits  (Lane Condition)
def LVXLanecondAsmOperand : AsmOperandClass {
  let Name           = "Lanecond";
  let ParserMethod   = "parseModifier";
  let DiagnosticType = "InvalidLanecond";
}
def lanecond : Operand<i32> {
  let PrintMethod      = "printLanecond";
  let EncoderMethod    = "getLanecondOpValue";
  let DecoderMethod    = "decodeLanecond";
  let ParserMatchClass = LVXLanecondAsmOperand;
  let OperandType      = "OPERAND_IMMEDIATE";
}

// lanetodo — 2 bits  (BLEND Lane To Do)
def LVXLanetodoAsmOperand : AsmOperandClass {
  let Name           = "Lanetodo";
  let ParserMethod   = "parseModifier";
  let DiagnosticType = "InvalidLanetodo";
}
def lanetodo : Operand<i32> {
  let PrintMethod      = "printLanetodo";
  let EncoderMethod    = "getLanetodoOpValue";
  let DecoderMethod    = "decodeLanetodo";
  let ParserMatchClass = LVXLanetodoAsmOperand;
  let OperandType      = "OPERAND_IMMEDIATE";
}

// lanesize — 2 bits  (BLEND Lane Size)
def LVXLanesizeAsmOperand : AsmOperandClass {
  let Name           = "Lanesize";
  let ParserMethod   = "parseModifier";
  let DiagnosticType = "InvalidLanesize";
}
def lanesize : Operand<i32> {
  let PrintMethod      = "printLanesize";
  let EncoderMethod    = "getLanesizeOpValue";
  let DecoderMethod    = "decodeLanesize";
  let ParserMatchClass = LVXLanesizeAsmOperand;
  let OperandType      = "OPERAND_IMMEDIATE";
}

// floatcomp — 3 bits  (Floating-Point Comparison)
def LVXFloatcompAsmOperand : AsmOperandClass {
  let Name           = "Floatcomp";
  let ParserMethod   = "parseModifier";
  let DiagnosticType = "InvalidFloatcomp";
}
def floatcomp : Operand<i32> {
  let PrintMethod      = "printFloatcomp";
  let EncoderMethod    = "getFloatcompOpValue";
  let DecoderMethod    = "decodeFloatcomp";
  let ParserMatchClass = LVXFloatcompAsmOperand;
  let OperandType      = "OPERAND_IMMEDIATE";
}

// floatmode — 3 bits  (Floating-Point Rounding Mode)
def LVXFloatmodeAsmOperand : AsmOperandClass {
  let Name           = "Floatmode";
  let ParserMethod   = "parseModifier";
  let DiagnosticType = "InvalidFloatmode";
}
def floatmode : Operand<i32> {
  let PrintMethod      = "printFloatmode";
  let EncoderMethod    = "getFloatmodeOpValue";
  let DecoderMethod    = "decodeFloatmode";
  let ParserMatchClass = LVXFloatmodeAsmOperand;
  let OperandType      = "OPERAND_IMMEDIATE";
}

// signextw — 1 bit  (Sign Extend Word)
def LVXSignextwAsmOperand : AsmOperandClass {
  let Name           = "Signextw";
  let ParserMethod   = "parseModifier";
  let DiagnosticType = "InvalidSignextw";
}
def signextw : Operand<i32> {
  let PrintMethod      = "printSignextw";
  let EncoderMethod    = "getSignextwOpValue";
  let DecoderMethod    = "decodeSignextw";
  let ParserMatchClass = LVXSignextwAsmOperand;
  let OperandType      = "OPERAND_IMMEDIATE";
}

// highmult — 2 bits  (High Multiply)
def LVXHighmultAsmOperand : AsmOperandClass {
  let Name           = "Highmult";
  let ParserMethod   = "parseModifier";
  let DiagnosticType = "InvalidHighmult";
}
def highmult : Operand<i32> {
  let PrintMethod      = "printHighmult";
  let EncoderMethod    = "getHighmultOpValue";
  let DecoderMethod    = "decodeHighmult";
  let ParserMatchClass = LVXHighmultAsmOperand;
  let OperandType      = "OPERAND_IMMEDIATE";
}

// widemult — 2 bits  (Wide Multiply)
def LVXWidemultAsmOperand : AsmOperandClass {
  let Name           = "Widemult";
  let ParserMethod   = "parseModifier";
  let DiagnosticType = "InvalidWidemult";
}
def widemult : Operand<i32> {
  let PrintMethod      = "printWidemult";
  let EncoderMethod    = "getWidemultOpValue";
  let DecoderMethod    = "decodeWidemult";
  let ParserMatchClass = LVXWidemultAsmOperand;
  let OperandType      = "OPERAND_IMMEDIATE";
}

// mostsig — 1 bit  (Least or Most Significant Bits)
def LVXMostsigAsmOperand : AsmOperandClass {
  let Name           = "Mostsig";
  let ParserMethod   = "parseModifier";
  let DiagnosticType = "InvalidMostsig";
}
def mostsig : Operand<i32> {
  let PrintMethod      = "printMostsig";
  let EncoderMethod    = "getMostsigOpValue";
  let DecoderMethod    = "decodeMostsig";
  let ParserMatchClass = LVXMostsigAsmOperand;
  let OperandType      = "OPERAND_IMMEDIATE";
}

// oddlanes — 1 bit  (Even or Odd SIMD Lanes)
def LVXOddlanesAsmOperand : AsmOperandClass {
  let Name           = "Oddlanes";
  let ParserMethod   = "parseModifier";
  let DiagnosticType = "InvalidOddlanes";
}
def oddlanes : Operand<i32> {
  let PrintMethod      = "printOddlanes";
  let EncoderMethod    = "getOddlanesOpValue";
  let DecoderMethod    = "decodeOddlanes";
  let ParserMatchClass = LVXOddlanesAsmOperand;
  let OperandType      = "OPERAND_IMMEDIATE";
}

// ziplanes — 1 bit  (Zip SIMD Lanes)
def LVXZiplanesAsmOperand : AsmOperandClass {
  let Name           = "Ziplanes";
  let ParserMethod   = "parseModifier";
  let DiagnosticType = "InvalidZiplanes";
}
def ziplanes : Operand<i32> {
  let PrintMethod      = "printZiplanes";
  let EncoderMethod    = "getZiplanesOpValue";
  let DecoderMethod    = "decodeZiplanes";
  let ParserMatchClass = LVXZiplanesAsmOperand;
  let OperandType      = "OPERAND_IMMEDIATE";
}

// fnegate — 1 bit  (Floating-Point Negate)
def LVXFnegateAsmOperand : AsmOperandClass {
  let Name           = "Fnegate";
  let ParserMethod   = "parseModifier";
  let DiagnosticType = "InvalidFnegate";
}
def fnegate : Operand<i32> {
  let PrintMethod      = "printFnegate";
  let EncoderMethod    = "getFnegateOpValue";
  let DecoderMethod    = "decodeFnegate";
  let ParserMatchClass = LVXFnegateAsmOperand;
  let OperandType      = "OPERAND_IMMEDIATE";
}

// variant — 2 bits  (Load Variants)
def LVXVariantAsmOperand : AsmOperandClass {
  let Name           = "Variant";
  let ParserMethod   = "parseModifier";
  let DiagnosticType = "InvalidVariant";
}
def variant : Operand<i32> {
  let PrintMethod      = "printVariant";
  let EncoderMethod    = "getVariantOpValue";
  let DecoderMethod    = "decodeVariant";
  let ParserMatchClass = LVXVariantAsmOperand;
  let OperandType      = "OPERAND_IMMEDIATE";
}

// speculate — 1 bit  (Speculative Load)
def LVXSpeculateAsmOperand : AsmOperandClass {
  let Name           = "Speculate";
  let ParserMethod   = "parseModifier";
  let DiagnosticType = "InvalidSpeculate";
}
def speculate : Operand<i32> {
  let PrintMethod      = "printSpeculate";
  let EncoderMethod    = "getSpeculateOpValue";
  let DecoderMethod    = "decodeSpeculate";
  let ParserMatchClass = LVXSpeculateAsmOperand;
  let OperandType      = "OPERAND_IMMEDIATE";
}

// doscale — 1 bit  (Enable Scaling for Indexed Addressing)
def LVXDoscaleAsmOperand : AsmOperandClass {
  let Name           = "Doscale";
  let ParserMethod   = "parseModifier";
  let DiagnosticType = "InvalidDoscale";
}
def doscale : Operand<i32> {
  let PrintMethod      = "printDoscale";
  let EncoderMethod    = "getDoscaleOpValue";
  let DecoderMethod    = "decodeDoscale";
  let ParserMatchClass = LVXDoscaleAsmOperand;
  let OperandType      = "OPERAND_IMMEDIATE";
}

// qindex — 2 bits  (Quarter Index)
def LVXQindexAsmOperand : AsmOperandClass {
  let Name           = "Qindex";
  let ParserMethod   = "parseModifier";
  let DiagnosticType = "InvalidQindex";
}
def qindex : Operand<i32> {
  let PrintMethod      = "printQindex";
  let EncoderMethod    = "getQindexOpValue";
  let DecoderMethod    = "decodeQindex";
  let ParserMatchClass = LVXQindexAsmOperand;
  let OperandType      = "OPERAND_IMMEDIATE";
}

// hindex — 1 bit  (Half Index)
def LVXHindexAsmOperand : AsmOperandClass {
  let Name           = "Hindex";
  let ParserMethod   = "parseModifier";
  let DiagnosticType = "InvalidHindex";
}
def hindex : Operand<i32> {
  let PrintMethod      = "printHindex";
  let EncoderMethod    = "getHindexOpValue";
  let DecoderMethod    = "decodeHindex";
  let ParserMatchClass = LVXHindexAsmOperand;
  let OperandType      = "OPERAND_IMMEDIATE";
}

// cachelev — 2 bits  (Cache Level for Set/Way maintenance)
def LVXCachelevAsmOperand : AsmOperandClass {
  let Name           = "Cachelev";
  let ParserMethod   = "parseModifier";
  let DiagnosticType = "InvalidCachelev";
}
def cachelev : Operand<i32> {
  let PrintMethod      = "printCachelev";
  let EncoderMethod    = "getCachelevOpValue";
  let DecoderMethod    = "decodeCachelev";
  let ParserMatchClass = LVXCachelevAsmOperand;
  let OperandType      = "OPERAND_IMMEDIATE";
}

// coherency — 2 bits  (Coherency Domain for atomics)
def LVXCoherencyAsmOperand : AsmOperandClass {
  let Name           = "Coherency";
  let ParserMethod   = "parseModifier";
  let DiagnosticType = "InvalidCoherency";
}
def coherency : Operand<i32> {
  let PrintMethod      = "printCoherency";
  let EncoderMethod    = "getCoherencyOpValue";
  let DecoderMethod    = "decodeCoherency";
  let ParserMatchClass = LVXCoherencyAsmOperand;
  let OperandType      = "OPERAND_IMMEDIATE";
}

// boolcas — 1 bit  (Boolean Compare-and-Swap)
def LVXBoolcasAsmOperand : AsmOperandClass {
  let Name           = "Boolcas";
  let ParserMethod   = "parseModifier";
  let DiagnosticType = "InvalidBoolcas";
}
def boolcas : Operand<i32> {
  let PrintMethod      = "printBoolcas";
  let EncoderMethod    = "getBoolcasOpValue";
  let DecoderMethod    = "decodeBoolcas";
  let ParserMatchClass = LVXBoolcasAsmOperand;
  let OperandType      = "OPERAND_IMMEDIATE";
}

// accesses — 2 bits  (Fence Access)
def LVXAccessesAsmOperand : AsmOperandClass {
  let Name           = "Accesses";
  let ParserMethod   = "parseModifier";
  let DiagnosticType = "InvalidAccesses";
}
def accesses : Operand<i32> {
  let PrintMethod      = "printAccesses";
  let EncoderMethod    = "getAccessesOpValue";
  let DecoderMethod    = "decodeAccesses";
  let ParserMatchClass = LVXAccessesAsmOperand;
  let OperandType      = "OPERAND_IMMEDIATE";
}

// channel — 1 bit  (Extension Channel)
def LVXChannelAsmOperand : AsmOperandClass {
  let Name           = "Channel";
  let ParserMethod   = "parseModifier";
  let DiagnosticType = "InvalidChannel";
}
def channel : Operand<i32> {
  let PrintMethod      = "printChannel";
  let EncoderMethod    = "getChannelOpValue";
  let DecoderMethod    = "decodeChannel";
  let ParserMatchClass = LVXChannelAsmOperand;
  let OperandType      = "OPERAND_IMMEDIATE";
}

// conjugate — 1 bit  (Complex Conjugate)
def LVXConjugateAsmOperand : AsmOperandClass {
  let Name           = "Conjugate";
  let ParserMethod   = "parseModifier";
  let DiagnosticType = "InvalidConjugate";
}
def conjugate : Operand<i32> {
  let PrintMethod      = "printConjugate";
  let EncoderMethod    = "getConjugateOpValue";
  let DecoderMethod    = "decodeConjugate";
  let ParserMatchClass = LVXConjugateAsmOperand;
  let OperandType      = "OPERAND_IMMEDIATE";
}

// imultiply — 1 bit  (Multiply by Imaginary Unit)
def LVXImultiplyAsmOperand : AsmOperandClass {
  let Name           = "Imultiply";
  let ParserMethod   = "parseModifier";
  let DiagnosticType = "InvalidImultiply";
}
def imultiply : Operand<i32> {
  let PrintMethod      = "printImultiply";
  let EncoderMethod    = "getImultiplyOpValue";
  let DecoderMethod    = "decodeImultiply";
  let ParserMatchClass = LVXImultiplyAsmOperand;
  let OperandType      = "OPERAND_IMMEDIATE";
}

// realimag — 1 bit  (Complex Part)
def LVXRealimagAsmOperand : AsmOperandClass {
  let Name           = "Realimag";
  let ParserMethod   = "parseModifier";
  let DiagnosticType = "InvalidRealimag";
}
def realimag : Operand<i32> {
  let PrintMethod      = "printRealimag";
  let EncoderMethod    = "getRealimagOpValue";
  let DecoderMethod    = "decodeRealimag";
  let ParserMatchClass = LVXRealimagAsmOperand;
  let OperandType      = "OPERAND_IMMEDIATE";
}

// shuffleV — 1 bit  (Shuffle a Word Vector (1024 bits))
def LVXShufflevAsmOperand : AsmOperandClass {
  let Name           = "Shufflev";
  let ParserMethod   = "parseModifier";
  let DiagnosticType = "InvalidShufflev";
}
def shuffleV : Operand<i32> {
  let PrintMethod      = "printShufflev";
  let EncoderMethod    = "getShufflevOpValue";
  let DecoderMethod    = "decodeShufflev";
  let ParserMatchClass = LVXShufflevAsmOperand;
  let OperandType      = "OPERAND_IMMEDIATE";
}

// shuffleX — 3 bits  (Shuffle a Word Hexadecuple (512 bits))
def LVXShufflexAsmOperand : AsmOperandClass {
  let Name           = "Shufflex";
  let ParserMethod   = "parseModifier";
  let DiagnosticType = "InvalidShufflex";
}
def shuffleX : Operand<i32> {
  let PrintMethod      = "printShufflex";
  let EncoderMethod    = "getShufflexOpValue";
  let DecoderMethod    = "decodeShufflex";
  let ParserMatchClass = LVXShufflexAsmOperand;
  let OperandType      = "OPERAND_IMMEDIATE";
}

// splat32 — 1 bit  (Splat 32-bit Immediate)
def LVXSplat32AsmOperand : AsmOperandClass {
  let Name           = "Splat32";
  let ParserMethod   = "parseModifier";
  let DiagnosticType = "InvalidSplat32";
}
def splat32 : Operand<i32> {
  let PrintMethod      = "printSplat32";
  let EncoderMethod    = "getSplat32OpValue";
  let DecoderMethod    = "decodeSplat32";
  let ParserMatchClass = LVXSplat32AsmOperand;
  let OperandType      = "OPERAND_IMMEDIATE";
}

//===----------------------------------------------------------------------===//
// Immediate operands
//===----------------------------------------------------------------------===//

// uimm2 — 2 bits, unsigned-extended  (Break Number)
def uimm2 : Operand<i64> {
  let DecoderMethod = "decodeUImmOperand<2>";
}
def uimm2imm : ImmLeaf<i64, [{ return isUInt<2>(Imm); }]>;

// uimm6 — 6 bits, unsigned-extended  (Zero Extended Immediate 6 bits)
def uimm6 : Operand<i64> {
  let DecoderMethod = "decodeUImmOperand<6>";
}
def uimm6imm : ImmLeaf<i64, [{ return isUInt<6>(Imm); }]>;

// wimm8 — 8 bits, wrap-extended  (Wrapped Immediate 8 bits)
def wimm8 : Operand<i64> {
  let DecoderMethod = "decodeWImmOperand<8>";
}
def wimm8imm : ImmLeaf<i64, [{ return isInt<8>(Imm); }]>;

// simm10 — 10 bits, signed-extended  (Sign Extended Immediate 10 bits)
def simm10 : Operand<i64> {
  let DecoderMethod = "decodeSImmOperand<10>";
}
def simm10imm : ImmLeaf<i64, [{ return isInt<10>(Imm); }]>;

// brtarget11s2 — 11-bit displacement, scaled by 2  (CCB Offset)
def brtarget11s2 : Operand<OtherVT> {
  let EncoderMethod = "encodePCRelTarget<11, 2>";
  let DecoderMethod = "decodePCRelTarget<11, 2>";
  let OperandType   = "OPERAND_PCREL";
}

// uimm12 — 12 bits, unsigned-extended  (RISC-V CSR Number)
def uimm12 : Operand<i64> {
  let DecoderMethod = "decodeUImmOperand<12>";
}
def uimm12imm : ImmLeaf<i64, [{ return isUInt<12>(Imm); }]>;

// simm16 — 16 bits, signed-extended  (Sign Extended Immediate 16 bits)
def simm16 : Operand<i64> {
  let DecoderMethod = "decodeSImmOperand<16>";
}
def simm16imm : ImmLeaf<i64, [{ return isInt<16>(Imm); }]>;

// brtarget17s2 — 17-bit displacement, scaled by 2  (CB Offset)
def brtarget17s2 : Operand<OtherVT> {
  let EncoderMethod = "encodePCRelTarget<17, 2>";
  let DecoderMethod = "decodePCRelTarget<17, 2>";
  let OperandType   = "OPERAND_PCREL";
}

// brtarget27s2 — 27-bit displacement, scaled by 2  (GOTO / CALL Offset)
def brtarget27s2 : Operand<OtherVT> {
  let EncoderMethod = "encodePCRelTarget<27, 2>";
  let DecoderMethod = "decodePCRelTarget<27, 2>";
  let OperandType   = "OPERAND_PCREL";
}

// simm27 — 27 bits, signed-extended  (Sign Extended Immediate 27 bits)
def simm27 : Operand<i64> {
  let DecoderMethod = "decodeSImmOperand<27>";
}
def simm27imm : ImmLeaf<i64, [{ return isInt<27>(Imm); }]>;

// wimm32 — 32 bits, wrap-extended  (Wrapped Immediate 32 bits)
def wimm32 : Operand<i64> {
  let DecoderMethod = "decodeWImmOperand<32>";
}
def wimm32imm : ImmLeaf<i64, [{ return isInt<32>(Imm); }]>;

// simm37 — 37 bits, signed-extended  (Sign Extended Immediate 37 bits)
def simm37 : Operand<i64> {
  let DecoderMethod = "decodeSImmOperand<37>";
}
def simm37imm : ImmLeaf<i64, [{ return isInt<37>(Imm); }]>;

// brtarget38s2 — 38-bit displacement, scaled by 2  (CCB Offset Extended)
def brtarget38s2 : Operand<OtherVT> {
  let EncoderMethod = "encodePCRelTarget<38, 2>";
  let DecoderMethod = "decodePCRelTarget<38, 2>";
  let OperandType   = "OPERAND_PCREL";
}

// simm43 — 43 bits, signed-extended  (Sign Extended Immediate 43 bits)
def simm43 : Operand<i64> {
  let DecoderMethod = "decodeSImmOperand<43>";
}
def simm43imm : ImmLeaf<i64, [{ return isInt<43>(Imm); }]>;

// brtarget44s2 — 44-bit displacement, scaled by 2  (CB Offset Extended)
def brtarget44s2 : Operand<OtherVT> {
  let EncoderMethod = "encodePCRelTarget<44, 2>";
  let DecoderMethod = "decodePCRelTarget<44, 2>";
  let OperandType   = "OPERAND_PCREL";
}

// brtarget54s2 — 54-bit displacement, scaled by 2  (GOTO Offset Extended)
def brtarget54s2 : Operand<OtherVT> {
  let EncoderMethod = "encodePCRelTarget<54, 2>";
  let DecoderMethod = "decodePCRelTarget<54, 2>";
  let OperandType   = "OPERAND_PCREL";
}

// simm54 — 54 bits, signed-extended  (Sign Extended Immediate 54 bits)
def simm54 : Operand<i64> {
  let DecoderMethod = "decodeSImmOperand<54>";
}
def simm54imm : ImmLeaf<i64, [{ return isInt<54>(Imm); }]>;

// wimm64 — 64 bits, wrap-extended  (Wrapped Immediate 64 bits)
def wimm64 : Operand<i64> {
  let DecoderMethod = "decodeWImmOperand<64>";
}
def wimm64imm : ImmLeaf<i64, [{ return true; }]>;

