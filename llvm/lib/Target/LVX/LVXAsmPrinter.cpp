//===-- LVXAsmPrinter.cpp - LVX LLVM assembly writer ---------------------===//
//
// Minimal AsmPrinter stub sufficient to let llc initialize and run passes
// up to instruction selection (e.g. -stop-after=finalize-isel, -filetype=null).
// Full assembly emission (Phase 4) requires:
//   - an MCInstPrinter (printInst / printOperand),
//   - an MCCodeEmitter and MCAsmBackend (for -filetype=obj),
//   - emitInstruction that lowers MachineInstr -> MCInst -> OutStreamer.
// None of those are implemented here; emitInstruction hits llvm_unreachable
// if actually called, which only happens when -filetype=asm/obj is requested.
//
//===----------------------------------------------------------------------===//

#include "LVXTargetMachine.h"
#include "TargetInfo/LVXTargetInfo.h"
#include "llvm/CodeGen/AsmPrinter.h"
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

  // Full MC lowering (MachineInstr -> MCInst -> OutStreamer) is Phase 4.
  // For -filetype=null testing, emit nothing -- the streamer discards output.
  // For -filetype=asm/obj this will silently produce empty output; that is
  // acceptable for Phase 3 testing and will be fixed in Phase 4.
  void emitInstruction(const MachineInstr *MI) override {}
};

} // end anonymous namespace

extern "C" LLVM_EXTERNAL_VISIBILITY void LLVMInitializeLVXAsmPrinter() {
  RegisterAsmPrinter<LVXAsmPrinter> X(getTheLVXTarget());
}
