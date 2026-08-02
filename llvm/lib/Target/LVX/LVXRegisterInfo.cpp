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
#include "LVXSubtarget.h"
#include "llvm/ADT/BitVector.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/RegisterScavenging.h"
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
                                          RegScavenger *RS) const {
  assert(SPAdj == 0 && "Unexpected SPAdj value -- LVX has no "
                       "ADJCALLSTACKDOWN/UP pseudo-instructions");

  MachineInstr &MI = *II;
  MachineFunction &MF = *MI.getParent()->getParent();
  MachineFrameInfo &MFI = MF.getFrameInfo();
  const LVXInstrInfo *TII = MF.getSubtarget<LVXSubtarget>().getInstrInfo();
  const TargetFrameLowering *TFI = MF.getSubtarget().getFrameLowering();
  bool HasFP = TFI->hasFP(MF);
  DebugLoc DL = MI.getDebugLoc();

  int FrameIndex = MI.getOperand(FIOperandNum).getIndex();

  // Every LVX base+offset load/store format places the offset immediately
  // BEFORE the base-register operand (SD/SQ/SO: off, rZ, rT/rU/rV; LD/LQ/LO:
  // rW/rM/rN, off, rZ, variant) -- opposite of Lanai's ADD_I_LO-derived
  // layout where the immediate follows the register. FIOperandNum is the
  // base-register (rZ) operand here, so the offset is at FIOperandNum - 1.
  MachineOperand &OffsetOp = MI.getOperand(FIOperandNum - 1);
  int64_t Offset = MFI.getObjectOffset(FrameIndex) + OffsetOp.getImm();

  // MFI.getObjectOffset() returns an offset relative to R14 (FP): per
  // LVXFrameLowering::emitPrologue, FP = (SP after the prologue's stack
  // decrement) + StackSize = the function's INCOMING SP, and both local
  // objects (negative PEI-assigned offsets below FP) and fixed/incoming-
  // argument objects (positive SPOffset above FP, per
  // LowerFormalArguments' CreateFixedObject(..., VA.getLocMemOffset()))
  // are already expressed relative to that same point. When there is no
  // FP, the same address must instead be expressed relative to SP:
  // address = FP + Offset = (SP + StackSize) + Offset, so the SP-relative
  // offset is (Offset + StackSize).
  if (!HasFP)
    Offset += MFI.getStackSize();

  Register FrameReg = HasFP ? getFrameRegister(MF) : Register(LVX::R12);

  // An offset too big for the instruction's current offset field does not
  // need a scratch register: the widened forms of the same load or store
  // (LSU_LSBO.X/.Y, LSU_SSBO.X/.Y and the pair/quad equivalents) hold 37 and
  // 64 bits of offset in the same operand position, so the fix is to swap the
  // opcode for a longer encoding of the same instruction and write the offset
  // straight in. LVXInstrInfo::getFormForImmediate picks the narrowest form
  // that holds Offset, from the chains the machine description generates into
  // LVXImmediateExtensions.inc.
  //
  // This is what the immediate extensions buy here: what used to be a
  // scavenged register plus maked + addd ahead of every out-of-range frame
  // access is now the access itself, four or eight bytes longer.
  if (unsigned Widened =
          LVXInstrInfo::getFormForImmediate(MI.getOpcode(), Offset)) {
    MI.setDesc(TII->get(Widened));
    MI.getOperand(FIOperandNum).ChangeToRegister(FrameReg, /*isDef=*/false);
    OffsetOp.ChangeToImmediate(Offset);
    return false;
  }

  // No encoding of this instruction reaches Offset (it has no widened form at
  // all): fall back to materializing FrameReg + Offset in a scratch register
  // and addressing through it at offset 0.
  assert(RS && "Register scavenging must be enabled for large frame offsets");
  Register Scratch = RS->scavengeRegisterBackwards(
      LVX::GPRRegClass, II, /*RestoreAfter=*/false, SPAdj);

  TII->loadImmediate(*MI.getParent(), II, DL, Scratch, Offset);
  BuildMI(*MI.getParent(), II, DL, TII->get(LVX::ADDD_DWRR0), Scratch)
      .addReg(Scratch)
      .addReg(FrameReg);

  MI.getOperand(FIOperandNum)
      .ChangeToRegister(Scratch, /*isDef=*/false, /*isImp=*/false,
                        /*isKill=*/true);
  OffsetOp.ChangeToImmediate(0);
  return false;
}

Register LVXRegisterInfo::getFrameRegister(const MachineFunction & /*MF*/) const {
  return LVX::R14;
}
