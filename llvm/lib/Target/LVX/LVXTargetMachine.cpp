//===-- LVXTargetMachine.cpp - Define TargetMachine for LVX -------------===//
//
// Phase 1 stub implementation. Mirrors the current LanaiTargetMachine.cpp
// shape (confirmed against this checkout) but trimmed to what's needed to
// register the target and compile: no Subtarget, no real instruction
// selector, no TargetTransformInfo override yet.
//
//===----------------------------------------------------------------------===//

#include "LVXTargetMachine.h"
#include "TargetInfo/LVXTargetInfo.h"
#include "llvm/CodeGen/TargetPassConfig.h"
#include "llvm/MC/TargetRegistry.h"

using namespace llvm;

// getEffectiveRelocModel is a per-target local helper in current LLVM (not
// a shared utility — confirmed against LanaiTargetMachine.cpp in this
// checkout, which defines its own static copy). LVX defaults to
// Reloc::Static absent an explicit choice; revisit once the ABI's
// position-independence requirements are settled (Lanai defaults to
// Reloc::PIC_ instead).
static Reloc::Model getEffectiveRelocModel(std::optional<Reloc::Model> RM) {
  return RM.value_or(Reloc::Static);
}

extern "C" LLVM_EXTERNAL_VISIBILITY void LLVMInitializeLVXTarget() {
  RegisterTargetMachine<LVXTargetMachine> X(getTheLVXTarget());
}

LVXTargetMachine::LVXTargetMachine(
    const Target &T, const Triple &TT, StringRef CPU, StringRef FS,
    const TargetOptions &Options, std::optional<Reloc::Model> RM,
    std::optional<CodeModel::Model> CM, CodeGenOptLevel OL, bool JIT)
    : CodeGenTargetMachineImpl(
          T,
          "e-m:e-p:64:64-i64:64-i128:128-n32:64-S128", // LVX data layout
                                                        // (RV64G-derived,
                                                        // see Phase 1 chat)
          TT, CPU, FS, Options, getEffectiveRelocModel(RM),
          getEffectiveCodeModel(CM, CodeModel::Small), OL) {
  initAsmInfo();
}

namespace {
// Minimal pass config: no addInstSelector/addPreSched2/addPreEmitPass
// overrides yet — those land in Phase 3/5 once LVXISelLowering and the
// frame lowering exist. Until then this behaves like the generic
// TargetPassConfig base.
class LVXPassConfig : public TargetPassConfig {
public:
  LVXPassConfig(LVXTargetMachine &TM, PassManagerBase &PM)
      : TargetPassConfig(TM, PM) {}
};
} // end anonymous namespace

TargetPassConfig *LVXTargetMachine::createPassConfig(PassManagerBase &PM) {
  return new LVXPassConfig(*this, PM);
}
