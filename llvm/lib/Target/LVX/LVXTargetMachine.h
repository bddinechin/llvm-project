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

#include "LVXSubtarget.h"
#include "llvm/CodeGen/CodeGenTargetMachineImpl.h"
#include "llvm/Target/TargetMachine.h"
#include "llvm/CodeGen/TargetLoweringObjectFileImpl.h"

namespace llvm {

class LVXTargetMachine : public CodeGenTargetMachineImpl {
  LVXSubtarget Subtarget;
  std::unique_ptr<TargetLoweringObjectFile> TLOF;

public:
  LVXTargetMachine(const Target &T, const Triple &TT, StringRef CPU,
                   StringRef FS, const TargetOptions &Options,
                   std::optional<Reloc::Model> RM,
                   std::optional<CodeModel::Model> CM,
                   CodeGenOptLevel OL, bool JIT);

  const LVXSubtarget *
  getSubtargetImpl(const Function & /*F*/) const override {
    return &Subtarget;
  }

  TargetLoweringObjectFile *getObjFileLowering() const override {
    return TLOF.get();
  }

  TargetPassConfig *createPassConfig(PassManagerBase &PM) override;

  // Every LVX address space is the same flat 64-bit address: the space does
  // not change what a pointer IS, only which `variant` of the load reads it
  // (see LVXAddressSpaces.h). So a cast between any two of them moves no
  // bits, and saying so lets the middle end fold them away instead of
  // leaving an addrspacecast for isel to fail on.
  bool isNoopAddrSpaceCast(unsigned SrcAS, unsigned DestAS) const override {
    return true;
  }

  MachineFunctionInfo *
  createMachineFunctionInfo(BumpPtrAllocator &Allocator, const Function &F,
                            const TargetSubtargetInfo *STI) const override;
};

} // end namespace llvm

#endif
