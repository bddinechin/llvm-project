//===-- LVXRegisterInfo.h - LVX Register Information Impl -----*- C++ -*-===//
//
// This file contains the LVX implementation of the TargetRegisterInfo
// class. Mirrors LanaiRegisterInfo's shape (confirmed current via
// LanaiRegisterInfo.h/.cpp in this checkout), trimmed to what LVX needs
// right now: no base-pointer/stack-realignment support yet (Lanai's
// hasBasePointer/getBaseRegister), since LVX has no equivalent concept
// defined so far.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_LVX_LVXREGISTERINFO_H
#define LLVM_LIB_TARGET_LVX_LVXREGISTERINFO_H

#include "llvm/CodeGen/TargetRegisterInfo.h"

// GET_REGINFO_ENUM must be defined alongside GET_REGINFO_HEADER: the
// umbrella LVXGenRegisterInfo.inc treats these as independent guarded
// sections (confirmed by inspecting the generated file directly), and
// the TargetDesc section included later (in LVXRegisterInfo.cpp) assumes
// the RegClassID enum (LVX::CRRegClassID, etc.) is already visible. Build
// error without this: "'CRRegClassID' is not a member of 'llvm::LVX'".
#define GET_REGINFO_ENUM
#define GET_REGINFO_HEADER
#include "LVXGenRegisterInfo.inc"

namespace llvm {

class LVXRegisterInfo : public LVXGenRegisterInfo {
public:
  LVXRegisterInfo();

  const MCPhysReg *
  getCalleeSavedRegs(const MachineFunction *MF) const override;

  BitVector getReservedRegs(const MachineFunction &MF) const override;

  bool eliminateFrameIndex(MachineBasicBlock::iterator II, int SPAdj,
                           unsigned FIOperandNum,
                           RegScavenger *RS = nullptr) const override;

  Register getFrameRegister(const MachineFunction &MF) const override;
};

} // end namespace llvm

#endif // LLVM_LIB_TARGET_LVX_LVXREGISTERINFO_H
