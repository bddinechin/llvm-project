//===-- LVXTargetMachine.cpp - Define TargetMachine for LVX -------------===//
//
// Phase 3: now constructs a real LVXSubtarget member, mirroring
// LanaiTargetMachine.cpp's initializer-list pattern (confirmed against
// this checkout).
//
//===----------------------------------------------------------------------===//

#include "LVXTargetMachine.h"
#include "LVXMachineFunctionInfo.h"
#include "llvm/InitializePasses.h"
#include "LVXISelDAGToDAG.h"
#include "TargetInfo/LVXTargetInfo.h"
#include "llvm/CodeGen/TargetLoweringObjectFileImpl.h"
#include "llvm/CodeGen/TargetPassConfig.h"
#include "llvm/MC/TargetRegistry.h"

using namespace llvm;

// getEffectiveRelocModel is a per-target local helper in current LLVM (not
// a shared utility -- confirmed against LanaiTargetMachine.cpp in this
// checkout, which defines its own static copy). LVX defaults to
// Reloc::Static absent an explicit choice; revisit once the ABI's
// position-independence requirements are settled (Lanai defaults to
// Reloc::PIC_ instead).
static Reloc::Model getEffectiveRelocModel(std::optional<Reloc::Model> RM) {
  return RM.value_or(Reloc::Static);
}

extern "C" LLVM_EXTERNAL_VISIBILITY void LLVMInitializeLVXTarget() {
  // So the pass can be named on llc's command line (-run-pass, -stop-after).
  initializeLVXBranchRelaxationPass(*PassRegistry::getPassRegistry());
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
          getEffectiveCodeModel(CM, CodeModel::Small), OL),
      Subtarget(TT, CPU, FS, *this, Options, getCodeModel(), OL),
      TLOF(std::make_unique<TargetLoweringObjectFileELF>()) {
  initAsmInfo();
}

namespace {
class LVXPassConfig : public TargetPassConfig {
public:
  LVXPassConfig(LVXTargetMachine &TM, PassManagerBase &PM)
      : TargetPassConfig(TM, PM) {}

  LVXTargetMachine &getLVXTargetMachine() const {
    return getTM<LVXTargetMachine>();
  }

  bool addInstSelector() override {
    addPass(createLVXISelDag(getLVXTargetMachine(), getOptLevel()));
    return false;
  }

  // Branch relaxation has to see the final instruction widths, which are only
  // settled once the frame code is in and every out-of-range frame access has
  // been widened -- so it runs at the very end of the machine passes, after
  // prologue/epilogue insertion and block placement.
  void addPreEmitPass() override {
    addPass(createLVXBranchRelaxationPass());
  }
};
} // end anonymous namespace

MachineFunctionInfo *LVXTargetMachine::createMachineFunctionInfo(
    BumpPtrAllocator &Allocator, const Function &F,
    const TargetSubtargetInfo *STI) const {
  return LVXMachineFunctionInfo::create<LVXMachineFunctionInfo>(Allocator, F,
                                                                STI);
}

TargetPassConfig *LVXTargetMachine::createPassConfig(PassManagerBase &PM) {
  return new LVXPassConfig(*this, PM);
}
