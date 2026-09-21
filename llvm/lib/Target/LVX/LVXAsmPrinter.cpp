//===-- LVXAsmPrinter.cpp - LVX LLVM assembly writer ---------------------===//
//
// Real MachineInstr -> MCInst -> OutStreamer lowering via LVXMCInstLower and
// LVXInstPrinter (Phase 4.1). -filetype=asm now produces real text. Still
// missing for -filetype=obj: an MCCodeEmitter and MCAsmBackend (no real
// bit-encoding exists yet -- see LVXInstrInfo.td's ALU_DWI_X_Inst/
// ALU_DWI_Y_Inst "TODO(Phase 4)" comments for the one known gap even in
// the instructions that do have Inst bits populated).
//
//===----------------------------------------------------------------------===//

#include "LVXMCInstLower.h"
#include "MCTargetDesc/LVXInstPrinter.h"
#include "LVXTargetMachine.h"
#include "TargetInfo/LVXTargetInfo.h"
#include "llvm/CodeGen/AsmPrinter.h"
#include "llvm/CodeGen/MachineInstr.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/MC/TargetRegistry.h"

using namespace llvm;

namespace {

class LVXAsmPrinter : public AsmPrinter {
public:
  explicit LVXAsmPrinter(TargetMachine &TM,
                         std::unique_ptr<MCStreamer> Streamer)
      : AsmPrinter(TM, std::move(Streamer)) {}

  StringRef getPassName() const override { return "LVX Assembly Printer"; }

  void emitInstruction(const MachineInstr *MI) override;

  bool PrintAsmOperand(const MachineInstr *MI, unsigned OpNo,
                       const char *ExtraCode, raw_ostream &OS) override;
  void emitInlineAsmEnd(const MCSubtargetInfo &StartInfo,
                        const MCSubtargetInfo *EndInfo,
                        const MachineInstr *MI) override;
};

} // end anonymous namespace

void LVXAsmPrinter::emitInstruction(const MachineInstr *MI) {
  LVXMCInstLower MCInstLowering(OutContext, *this);
  MCInst TmpInst;
  MCInstLowering.Lower(MI, TmpInst);
  OutStreamer->emitInstruction(TmpInst, getSubtargetInfo());

  // LVX assembly syntax requires an explicit ";;" bundle terminator after
  // every bundle (confirmed against the real GNU Binutils port and
  // lvx-mds/refs's regression-test corpus, which places ";;" on its own
  // line after every single instruction). Since this backend has no VLIW
  // bundling (every instruction is its own one-instruction bundle -- see
  // LVXInst's Inst{31}=0 "always 0 for single-issue" convention), every
  // real instruction gets its own terminator here.
  OutStreamer->emitRawText("\t;;");
}

// An inline asm operand. A register prints under its own name -- $r3,
// $r2r3, $r0r1r2r3 -- which is also how the width of an "r" operand reaches
// the assembler, so there is nothing for a modifier to say; the generic
// ones (%c, %n, ...) are left to the base class.
bool LVXAsmPrinter::PrintAsmOperand(const MachineInstr *MI, unsigned OpNo,
                                    const char *ExtraCode, raw_ostream &OS) {
  if (ExtraCode && ExtraCode[0])
    return AsmPrinter::PrintAsmOperand(MI, OpNo, ExtraCode, OS);

  const MachineOperand &MO = MI->getOperand(OpNo);
  switch (MO.getType()) {
  case MachineOperand::MO_Register:
    OS << LVXInstPrinter::getRegisterName(MO.getReg());
    return false;
  case MachineOperand::MO_Immediate:
    OS << MO.getImm();
    return false;
  case MachineOperand::MO_GlobalAddress:
    PrintSymbolOperand(MO, OS);
    return false;
  default:
    return true;
  }
}

// Inline asm is passed through as text, and gets the same ";;" every other
// instruction gets: the assembler only closes a bundle on ";;", never on a
// newline, so without it the asm's last instruction would be bundled with
// whatever follows. Text that already ends in ";;" costs nothing more -- an
// empty bundle assembles to no syllable at all.
void LVXAsmPrinter::emitInlineAsmEnd(const MCSubtargetInfo &,
                                     const MCSubtargetInfo *,
                                     const MachineInstr *) {
  OutStreamer->emitRawText("\t;;");
}

extern "C" LLVM_EXTERNAL_VISIBILITY void LLVMInitializeLVXAsmPrinter() {
  RegisterAsmPrinter<LVXAsmPrinter> X(getTheLVXTarget());
}
