//===-- LVXRegisterInfo.cpp - LVX Register Information ----------*- C++ -*-===//
//
// This file contains the LVX implementation of the TargetRegisterInfo
// class. Modeled directly on LanaiRegisterInfo.cpp (confirmed current in
// this checkout).
//
//===----------------------------------------------------------------------===//

#include "LVXRegisterInfo.h"
#include "LVXFrameLowering.h"
#include "LVXInstrInfo.h"
#include "llvm/ADT/BitVector.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/TargetFrameLowering.h"
#include "llvm/CodeGen/TargetInstrInfo.h"
#include "llvm/Support/ErrorHandling.h"

#define GET_REGINFO_TARGET_DESC
#include "LVXGenRegisterInfo.inc"

using namespace llvm;

// The single argument is the return-address register, per lvx_Convention.yml
// ("return: [ RA ]") — mirrors LanaiRegisterInfo's LanaiGenRegisterInfo(Lanai::RCA).
LVXRegisterInfo::LVXRegisterInfo() : LVXGenRegisterInfo(LVX::RA) {}

const MCPhysReg *
LVXRegisterInfo::getCalleeSavedRegs(const MachineFunction * /*MF*/) const {
  // CSR_LVX_SaveList is generated from CSR_LVX in LVXCallingConv.td
  // (R14/FP + R18-R31, per lvx_Convention.yml "callee").
  return CSR_LVX_SaveList;
}

BitVector LVXRegisterInfo::getReservedRegs(const MachineFunction &MF) const {
  BitVector Reserved(getNumRegs());

  // R12 = stack pointer, R13 = thread-local/local pointer — always
  // reserved, per lvx_Convention.yml "stack"/"local".
  Reserved.set(LVX::R12);
  Reserved.set(LVX::R13);

  // R14 = frame pointer. Per the user's explicit instruction earlier in
  // this conversation ("do what LLVM normally does: if the function
  // doesn't need a frame pointer, make FP allocatable"), R14 is only
  // reserved when this function actually needs a frame pointer.
  const TargetFrameLowering *TFI = MF.getSubtarget().getFrameLowering();
  if (TFI->hasFP(MF))
    Reserved.set(LVX::R14);

  // Control registers ($ra, $pc, $ps, $cs, $ls, $le, $lc) are not members
  // of the GPR class at all, so they don't need reserving here — they're
  // already excluded from GPR's allocation order in LVXRegisterInfo.td.

  return Reserved;
}

bool LVXRegisterInfo::eliminateFrameIndex(MachineBasicBlock::iterator II,
                                          int SPAdj, unsigned FIOperandNum,
                                          RegScavenger * /*RS*/) const {
  // TODO(Phase 5): real frame-index elimination, modeled on
  // LanaiRegisterInfo::eliminateFrameIndex, once LVXFrameLowering's stack
  // layout (determineFrameLayout) is implemented. For now this is an
  // intentionally-unimplemented stub — it must not be reached until
  // LVXFrameLowering actually creates stack objects.
  llvm_unreachable("LVXRegisterInfo::eliminateFrameIndex not yet implemented "
                   "(Phase 5)");
}

Register LVXRegisterInfo::getFrameRegister(const MachineFunction & /*MF*/) const {
  return LVX::R14;
}
