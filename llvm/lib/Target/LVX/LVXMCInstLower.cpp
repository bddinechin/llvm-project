//===-- LVXMCInstLower.cpp - Convert LVX MachineInstr to an MCInst ------===//
//
// This file contains code to lower LVX MachineInstrs to their corresponding
// MCInst records. Modeled on LanaiMCInstLower.cpp (confirmed current in
// this checkout).
//
//===----------------------------------------------------------------------===//

#include "LVXMCInstLower.h"

#include "llvm/CodeGen/AsmPrinter.h"
#include "llvm/CodeGen/MachineBasicBlock.h"
#include "llvm/CodeGen/MachineInstr.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCInst.h"
#include "llvm/Support/ErrorHandling.h"

using namespace llvm;

MCSymbol *
LVXMCInstLower::GetGlobalAddressSymbol(const MachineOperand &MO) const {
  return Printer.getSymbol(MO.getGlobal());
}

MCSymbol *
LVXMCInstLower::GetExternalSymbolSymbol(const MachineOperand &MO) const {
  return Printer.GetExternalSymbolSymbol(MO.getSymbolName());
}

// LVX's direct CALL/GOTO targets are a single PC-relative field (no
// hi/lo relocation split the way Lanai needs) -- so unlike Lanai's
// LowerSymbolOperand, there is no target-flag/Specifier switch here, just
// a plain symbol reference plus optional constant offset.
MCOperand LVXMCInstLower::LowerSymbolOperand(const MachineOperand &MO,
                                             MCSymbol *Sym) const {
  const MCExpr *Expr = MCSymbolRefExpr::create(Sym, Ctx);
  if (MO.getOffset())
    Expr = MCBinaryExpr::createAdd(
        Expr, MCConstantExpr::create(MO.getOffset(), Ctx), Ctx);
  return MCOperand::createExpr(Expr);
}

void LVXMCInstLower::Lower(const MachineInstr *MI, MCInst &OutMI) const {
  OutMI.setOpcode(MI->getOpcode());

  for (const MachineOperand &MO : MI->operands()) {
    MCOperand MCOp;
    switch (MO.getType()) {
    case MachineOperand::MO_Register:
      // Ignore all implicit register operands.
      if (MO.isImplicit())
        continue;
      MCOp = MCOperand::createReg(MO.getReg());
      break;
    case MachineOperand::MO_Immediate:
      MCOp = MCOperand::createImm(MO.getImm());
      break;
    case MachineOperand::MO_MachineBasicBlock:
      MCOp = MCOperand::createExpr(
          MCSymbolRefExpr::create(MO.getMBB()->getSymbol(), Ctx));
      break;
    case MachineOperand::MO_RegisterMask:
      continue;
    case MachineOperand::MO_GlobalAddress:
      MCOp = LowerSymbolOperand(MO, GetGlobalAddressSymbol(MO));
      break;
    case MachineOperand::MO_ExternalSymbol:
      MCOp = LowerSymbolOperand(MO, GetExternalSymbolSymbol(MO));
      break;
    default:
      // BlockAddress/JumpTableIndex/ConstantPoolIndex/FrameIndex: none of
      // these are produced by LVXISelLowering/LVXISelDAGToDAG yet (no
      // blockaddress, switch, or FP-constant lowering implemented, and
      // FrameIndex operands are always eliminated by PEI before this
      // runs) -- deferred until something actually generates one.
      MI->print(errs());
      llvm_unreachable("unknown or not-yet-supported operand type in "
                       "LVXMCInstLower::Lower");
    }

    OutMI.addOperand(MCOp);
  }
}
