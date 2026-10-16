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
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
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

  bool doInitialization(Module &M) override;

  void emitInstruction(const MachineInstr *MI) override;

  bool PrintAsmOperand(const MachineInstr *MI, unsigned OpNo,
                       const char *ExtraCode, raw_ostream &OS) override;
  void emitInlineAsmEnd(const MCSubtargetInfo &StartInfo,
                        const MCSubtargetInfo *EndInfo,
                        const MachineInstr *MI) override;

private:
  void emitOne(const MachineInstr *MI);
};

} // end anonymous namespace

// Say so when -mcpu/-march names a core this build cannot compile for.
//
// lib/Target/LVX holds ONE core's generated description at a time, so the
// instructions that exist were decided at install (LLVM_CORE=), not by -mcpu.
// Both mismatches are quiet and neither is a selection failure:
//
//   lvx-2 asked of an lvx-1 build -- every lane-wise operation is unrolled to
//   scalars and the vectorizer is told there are no vector registers, so the
//   output is correct lvx-1 code with lvx-2 macros over it and an lvx-2 ELF
//   flag on the object. "No vectorization at all on lvx-2" is what this looks
//   like from the outside, and it was reported as a back-end bug.
//
//   lvx-1 asked of an lvx-2 build -- the reverse, and worse: the back end
//   emits packed instructions and `lvx-mbr-as --march lvx-1` rejects them, so
//   the compile appears to succeed and the assembly step fails.
//
// Only an EXPLICIT core is diagnosed. An empty or "generic" CPU is the
// ordinary case and means "whatever this build holds".
bool LVXAsmPrinter::doInitialization(Module &M) {
  StringRef CPU = TM.getTargetCPU();
  bool WantsLaneSIMD = CPU == "lvx-2";
  if ((WantsLaneSIMD || CPU == "lvx-1") &&
      WantsLaneSIMD != LVX::DescriptionHasLaneSIMD) {
    StringRef Held = LVX::DescriptionHasLaneSIMD ? "lvx_v2" : "lvx_v1";
    StringRef Want = WantsLaneSIMD ? "lvx_v2" : "lvx_v1";
    M.getContext().diagnose(DiagnosticInfoGeneric(
        "requested core " + CPU + ", but this compiler holds the " + Held +
            " machine description: no " + CPU +
            "-only instruction can be selected; install the " + Want +
            " description and rebuild (make -C lvx-mds/build_lvx/BE/LLVM "
            "install LLVM_CORE=" +
            Want + ")",
        DS_Warning));
  }
  return AsmPrinter::doInitialization(M);
}

// Print one instruction, with no bundle terminator of its own.
void LVXAsmPrinter::emitOne(const MachineInstr *MI) {
  LVXMCInstLower MCInstLowering(OutContext, *this);
  MCInst TmpInst;
  MCInstLowering.Lower(MI, TmpInst);
  OutStreamer->emitInstruction(TmpInst, getSubtargetInfo());
}

void LVXAsmPrinter::emitInstruction(const MachineInstr *MI) {
  // LVX assembly marks the END of a bundle: the assembler reads ";;" as the
  // boundary and sets the parallel bit on every syllable before it, so the
  // terminator goes once per bundle and the instructions in between are what
  // issue together.
  //
  // LVXBundler wraps a group of two or more into a BUNDLE instruction, and the
  // generic AsmPrinter hands us that BUNDLE rather than its members -- so this
  // is where the members get printed. Anything not in a bundle is a bundle of
  // one, which is what every instruction was before bundling existed.
  if (MI->isBundle()) {
    const MachineBasicBlock *MBB = MI->getParent();
    MachineBasicBlock::const_instr_iterator I = std::next(MI->getIterator());
    for (; I != MBB->instr_end() && I->isInsideBundle(); ++I)
      if (!I->isDebugInstr() && !I->isImplicitDef())
        emitOne(&*I);
  } else {
    emitOne(MI);
  }
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
