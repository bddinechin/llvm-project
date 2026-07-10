//===-- LVXInstPrinter.cpp - Convert LVX MCInst to asm syntax -----------===//
//
// This class prints an LVX MCInst to a .s file. Modeled on
// LanaiInstPrinter.cpp (confirmed current in this checkout).
//
//===----------------------------------------------------------------------===//

#include "LVXInstPrinter.h"
#include "../LVXModifiers.h"
#include "llvm/MC/MCAsmInfo.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCInst.h"
#include "llvm/Support/ErrorHandling.h"

using namespace llvm;

#define DEBUG_TYPE "asm-printer"

// Include the auto-generated portion of the assembly writer.
#define PRINT_ALIAS_INSTR
#include "LVXGenAsmWriter.inc"

// LVX register names already embed the assembler's "$" sigil (e.g.
// "$r0", "$ra" -- see the Name string on every def in LVXRegisterInfo.td),
// so this needs no extra prefix, unlike Lanai's "%"-prepending printRegName.
void LVXInstPrinter::printRegName(raw_ostream &OS, MCRegister Reg) {
  OS << getRegisterName(Reg);
}

void LVXInstPrinter::printInst(const MCInst *MI, uint64_t Address,
                               StringRef Annotation,
                               const MCSubtargetInfo & /*STI*/,
                               raw_ostream &OS) {
  if (!printAliasInstr(MI, Address, OS))
    printInstruction(MI, Address, OS);
  printAnnotation(OS, Annotation);
}

void LVXInstPrinter::printOperand(const MCInst *MI, unsigned OpNo,
                                  raw_ostream &OS) {
  const MCOperand &Op = MI->getOperand(OpNo);
  if (Op.isReg()) {
    printRegName(OS, Op.getReg());
    return;
  }
  if (Op.isImm()) {
    OS << Op.getImm();
    return;
  }
  assert(Op.isExpr() && "Expected an expression");
  MAI.printExpr(OS, *Op.getExpr());
}

void LVXInstPrinter::printOperand(const MCInst *MI, uint64_t /*Address*/,
                                  unsigned OpNo, raw_ostream &OS) {
  printOperand(MI, OpNo, OS);
}

// ---- Modifier-operand printers (LVXModifiers.h suffix tables) -------------
// Each modifier's encoded value maps directly to an assembly suffix
// (e.g. ".sx", ".lt", or "" for the default/no-suffix encoding); the
// AsmString in LVXInstrInfo.td/LVXInstrFormats.td already places the
// mnemonic text immediately before these, e.g. "addd${sig}", so nothing
// else (no extra '.' or separator) belongs in these print methods.

void LVXInstPrinter::printCcbcomp(const MCInst *MI, unsigned OpNo,
                                  raw_ostream &OS) {
  if (const char *S =
          LVXModifier::getCcbcompSuffix(MI->getOperand(OpNo).getImm()))
    OS << S;
}

void LVXInstPrinter::printBcucond(const MCInst *MI, unsigned OpNo,
                                  raw_ostream &OS) {
  if (const char *S =
          LVXModifier::getBcucondSuffix(MI->getOperand(OpNo).getImm()))
    OS << S;
}

void LVXInstPrinter::printIntcomp(const MCInst *MI, unsigned OpNo,
                                  raw_ostream &OS) {
  if (const char *S =
          LVXModifier::getIntcompSuffix(MI->getOperand(OpNo).getImm()))
    OS << S;
}

void LVXInstPrinter::printFloatcomp(const MCInst *MI, unsigned OpNo,
                                    raw_ostream &OS) {
  if (const char *S =
          LVXModifier::getFloatcompSuffix(MI->getOperand(OpNo).getImm()))
    OS << S;
}

void LVXInstPrinter::printFloatmode(const MCInst *MI, unsigned OpNo,
                                    raw_ostream &OS) {
  if (const char *S =
          LVXModifier::getFloatmodeSuffix(MI->getOperand(OpNo).getImm()))
    OS << S;
}

void LVXInstPrinter::printSignextw(const MCInst *MI, unsigned OpNo,
                                   raw_ostream &OS) {
  if (const char *S =
          LVXModifier::getSignextwSuffix(MI->getOperand(OpNo).getImm()))
    OS << S;
}

void LVXInstPrinter::printHighmult(const MCInst *MI, unsigned OpNo,
                                   raw_ostream &OS) {
  if (const char *S =
          LVXModifier::getHighmultSuffix(MI->getOperand(OpNo).getImm()))
    OS << S;
}

void LVXInstPrinter::printWidemult(const MCInst *MI, unsigned OpNo,
                                   raw_ostream &OS) {
  if (const char *S =
          LVXModifier::getWidemultSuffix(MI->getOperand(OpNo).getImm()))
    OS << S;
}

void LVXInstPrinter::printMostsig(const MCInst *MI, unsigned OpNo,
                                  raw_ostream &OS) {
  if (const char *S =
          LVXModifier::getMostsigSuffix(MI->getOperand(OpNo).getImm()))
    OS << S;
}

void LVXInstPrinter::printFnegate(const MCInst *MI, unsigned OpNo,
                                  raw_ostream &OS) {
  if (const char *S =
          LVXModifier::getFnegateSuffix(MI->getOperand(OpNo).getImm()))
    OS << S;
}

void LVXInstPrinter::printVariant(const MCInst *MI, unsigned OpNo,
                                  raw_ostream &OS) {
  if (const char *S =
          LVXModifier::getVariantSuffix(MI->getOperand(OpNo).getImm()))
    OS << S;
}

void LVXInstPrinter::printCachelev(const MCInst *MI, unsigned OpNo,
                                   raw_ostream &OS) {
  if (const char *S =
          LVXModifier::getCachelevSuffix(MI->getOperand(OpNo).getImm()))
    OS << S;
}

void LVXInstPrinter::printAccesses(const MCInst *MI, unsigned OpNo,
                                   raw_ostream &OS) {
  if (const char *S =
          LVXModifier::getAccessesSuffix(MI->getOperand(OpNo).getImm()))
    OS << S;
}

void LVXInstPrinter::printConjugate(const MCInst *MI, unsigned OpNo,
                                    raw_ostream &OS) {
  if (const char *S =
          LVXModifier::getConjugateSuffix(MI->getOperand(OpNo).getImm()))
    OS << S;
}

void LVXInstPrinter::printImultiply(const MCInst *MI, unsigned OpNo,
                                    raw_ostream &OS) {
  if (const char *S =
          LVXModifier::getImultiplySuffix(MI->getOperand(OpNo).getImm()))
    OS << S;
}
