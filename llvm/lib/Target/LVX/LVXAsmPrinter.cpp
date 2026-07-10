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

extern "C" LLVM_EXTERNAL_VISIBILITY void LLVMInitializeLVXAsmPrinter() {
  RegisterAsmPrinter<LVXAsmPrinter> X(getTheLVXTarget());
}
