//===-- LVXTargetMachine.h - Define TargetMachine for LVX -----*- C++ -*-===//
//
// This file declares the LVX specific subclass of TargetMachine.
//
// NOTE: as of a recent LLVM change, the base class formerly named
// LLVMTargetMachine was renamed/restructured to CodeGenTargetMachineImpl,
// declared in llvm/CodeGen/CodeGenTargetMachineImpl.h (confirmed against
// LanaiTargetMachine.h in this checkout). LVXTargetMachine derives from
// CodeGenTargetMachineImpl directly, matching current in-tree targets.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_LVX_LVXTARGETMACHINE_H
#define LLVM_LIB_TARGET_LVX_LVXTARGETMACHINE_H

#include "llvm/CodeGen/CodeGenTargetMachineImpl.h"
#include "llvm/Target/TargetMachine.h"

namespace llvm {

// Phase 1 stub: no LVXSubtarget, TargetLoweringObjectFile, or
// MachineFunctionInfo override yet — those are added in later phases
// (Subtarget work, LVXISelLowering, frame lowering respectively). This
// class exists at this stage only to prove the target registers and
// builds against the current TargetMachine API.
class LVXTargetMachine : public CodeGenTargetMachineImpl {
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
