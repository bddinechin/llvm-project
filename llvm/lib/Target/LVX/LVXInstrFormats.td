//===-- LVXInstrFormats.td - LVX Modifier Operands ---------*- tablegen -*-===//
// Auto-generated from lvx_Modifier.yml — do not edit by hand.

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

// cmovecond — alias for intcomp, reused for conditional-move instructions
// cmovecond — per lvx_Format.yml, ALU_DCMWRR/ALU_QCMWRR type this as
// "bcucond" (zero/sign test on the tested register), not intcomp.
def cmovecond : Operand<i32> {
  let PrintMethod      = "printBcucond";
  let EncoderMethod    = "getBcucondOpValue";
  let DecoderMethod    = "decodeBcucond";
  let ParserMatchClass = LVXBcucondAsmOperand;
  let OperandType      = "OPERAND_IMMEDIATE";
}
