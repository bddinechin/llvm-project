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

  // The complement of getCalleeSavedRegs, as a register mask attached to
  // every call. This is what tells the register allocator which registers a
  // call destroys; without it the only clobber a call declares is the
  // generated "Defs = [RA]", which states what the ISA writes but says
  // nothing about the ABI's caller-saved set, and values get parked in
  // R0-R11 across calls and silently destroyed.
  const uint32_t *getCallPreservedMask(const MachineFunction &MF,
                                       CallingConv::ID CC) const override;

  BitVector getReservedRegs(const MachineFunction &MF) const override;

  // requiresFrameIndexScavenging is deliberately NOT overridden: that flag
  // tells PEI to defer frame-index elimination to a second post-pass and
  // run the *main* replaceFrameIndices walk with RS forced to null (see
  // PrologEpilogInserter.cpp's FrameIndexEliminationScavenging), which is
  // wrong for LVX's single-pass eliminateFrameIndex below (it scavenges
  // inline, immediately, exactly like Lanai's).
  bool requiresRegisterScavenging(const MachineFunction &MF) const override {
    return true;
  }

  bool eliminateFrameIndex(MachineBasicBlock::iterator II, int SPAdj,
                           unsigned FIOperandNum,
                           RegScavenger *RS = nullptr) const override;

  Register getFrameRegister(const MachineFunction &MF) const override;
};

} // end namespace llvm

#endif // LLVM_LIB_TARGET_LVX_LVXREGISTERINFO_H
