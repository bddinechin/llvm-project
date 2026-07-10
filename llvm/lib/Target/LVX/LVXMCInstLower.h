//===-- LVXMCInstLower.h - Lower MachineInstr to MCInst ---------*- C++ -*-===//
//
// This file declares LVXMCInstLower, which lowers a MachineInstr (with
// FrameIndex operands already eliminated by PEI) into an MCInst that
// LVXInstPrinter/a future MCCodeEmitter can consume. Modeled on
// LanaiMCInstLower.h (confirmed current in this checkout), trimmed to what
// LVX's current instruction set actually produces: no jump tables,
// constant pools, or block addresses are lowered by this backend yet.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_LVX_LVXMCINSTLOWER_H
#define LLVM_LIB_TARGET_LVX_LVXMCINSTLOWER_H

#include "llvm/Support/Compiler.h"

namespace llvm {
class AsmPrinter;
class MCContext;
class MCInst;
class MCOperand;
class MCSymbol;
class MachineInstr;
class MachineOperand;

class LLVM_LIBRARY_VISIBILITY LVXMCInstLower {
  MCContext &Ctx;
  AsmPrinter &Printer;

public:
  LVXMCInstLower(MCContext &CTX, AsmPrinter &AP) : Ctx(CTX), Printer(AP) {}
  void Lower(const MachineInstr *MI, MCInst &OutMI) const;

  MCOperand LowerSymbolOperand(const MachineOperand &MO, MCSymbol *Sym) const;

  MCSymbol *GetGlobalAddressSymbol(const MachineOperand &MO) const;
  MCSymbol *GetExternalSymbolSymbol(const MachineOperand &MO) const;
};

} // end namespace llvm

#endif // LLVM_LIB_TARGET_LVX_LVXMCINSTLOWER_H
