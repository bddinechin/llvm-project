#include "LVXTargetMachine.h"
#include "TargetInfo/LVXTargetInfo.h"
#include "llvm/CodeGen/TargetPassConfig.h"
#include "llvm/MC/TargetRegistry.h"

using namespace llvm;

extern "C" LLVM_EXTERNAL_VISIBILITY void LLVMInitializeLVXTarget() {
  RegisterTargetMachine<LVXTargetMachine> X(getTheLVXTarget());
}

LVXTargetMachine::LVXTargetMachine(
    const Target &T, const Triple &TT, StringRef CPU, StringRef FS,
    const TargetOptions &Options, std::optional<Reloc::Model> RM,
    std::optional<CodeModel::Model> CM, CodeGenOptLevel OL, bool JIT)
    : LLVMTargetMachine(T,
                        "e-m:e-p:64:64-i64:64-i128:128-n32:64-S128", // Same as RV64G
                        TT, CPU, FS, Options,
                        RM.value_or(Reloc::Static),
                        CM.value_or(CodeModel::Small), OL) {}

TargetPassConfig *
LVXTargetMachine::createPassConfig(PassManagerBase &PM) {
  return new TargetPassConfig(*this, PM);
}

