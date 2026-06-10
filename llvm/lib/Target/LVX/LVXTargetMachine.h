#ifndef LLVM_LIB_TARGET_LVX_LVXTARGETMACHINE_H
#define LLVM_LIB_TARGET_LVX_LVXTARGETMACHINE_H

#include "llvm/Target/TargetMachine.h"

namespace llvm {

class LVXTargetMachine : public LLVMTargetMachine {
public:
  LVXTargetMachine(const Target &T, const Triple &TT, StringRef CPU,
                   StringRef FS, const TargetOptions &Options,
                   std::optional<Reloc::Model> RM,
                   std::optional<CodeModel::Model> CM,
                   CodeGenOptLevel OL, bool JIT);

  TargetPassConfig *createPassConfig(PassManagerBase &PM) override;
};

} // end namespace llvm

#endif

