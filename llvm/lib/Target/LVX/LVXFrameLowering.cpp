//===-- LVXFrameLowering.cpp - LVX Frame Information ---------*- C++ -*-===//
//
// This file contains the LVX implementation of TargetFrameLowering class.
//
//===----------------------------------------------------------------------===//

#include "LVXFrameLowering.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/Support/ErrorHandling.h"

using namespace llvm;

bool LVXFrameLowering::hasFPImpl(const MachineFunction &MF) const {
  const MachineFrameInfo &MFI = MF.getFrameInfo();
  // Standard criteria: a frame pointer is needed if the frame cannot be
  // addressed reliably from SP alone — variable-sized objects (alloca) or
  // a request for stack realignment. This intentionally differs from
  // Lanai's hardcoded `return true`, per the user's explicit instruction:
  // make R14 (FP) allocatable when the function doesn't need a frame
  // pointer.
  return MFI.hasVarSizedObjects() || MF.getFrameInfo().isFrameAddressTaken();
}

void LVXFrameLowering::emitPrologue(MachineFunction & /*MF*/,
                                    MachineBasicBlock & /*MBB*/) const {
  // TODO(Phase 5): real prologue emission (stack allocation, callee-saved
  // register spills, $ra save for non-leaf functions per the ABI doc,
  // frame pointer setup when hasFP(MF) is true). Left empty for now so
  // that functions with no stack frame requirements (the common case
  // while bringing up basic codegen) still produce valid, if minimal,
  // output; this must be filled in before any function using locals,
  // calls, or callee-saved registers can be compiled correctly.
}

void LVXFrameLowering::emitEpilogue(MachineFunction & /*MF*/,
                                    MachineBasicBlock & /*MBB*/) const {
  // TODO(Phase 5): mirror of emitPrologue — restore callee-saved
  // registers, restore $ra, deallocate the stack frame.
}

MachineBasicBlock::iterator LVXFrameLowering::eliminateCallFramePseudoInstr(
    MachineFunction & /*MF*/, MachineBasicBlock &MBB,
    MachineBasicBlock::iterator I) const {
  // TODO(Phase 5): LVX has no ADJCALLSTACKDOWN/UP pseudo-instructions
  // defined yet (see the comment in LVXInstrInfo.cpp), so there is
  // nothing target-specific to lower here yet; simply erase the pseudo
  // as the generic default behavior would.
  return MBB.erase(I);
}

void LVXFrameLowering::determineCalleeSaves(MachineFunction &MF,
                                            BitVector &SavedRegs,
                                            RegScavenger *RS) const {
  TargetFrameLowering::determineCalleeSaves(MF, SavedRegs, RS);
  // TODO(Phase 5): reserve a scavenging spill slot here if/when
  // LVXRegisterInfo::eliminateFrameIndex needs one (Lanai does this for
  // its MOVHI/OR_I_LO large-offset sequence); LVX's equivalent large-
  // offset handling isn't implemented yet either, so there's nothing
  // target-specific to add beyond the generic CSR set for now.
}
