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
  //
  // markSuperRegs, NOT a plain Reserved.set: reserving a register does not
  // implicitly reserve the register TUPLES that contain it. RegisterClassInfo
  // builds each class's allocation order by testing the candidate register
  // itself against this bitvector, so setting only R12/R13 left the GPR128
  // pair R12R13 (and the GPR256 quad R12R13R14R15) perfectly allocatable --
  // LVXRegisterInfo.td's comment on the GPR128 order asserted the opposite,
  // that such pairs "will be excluded by getReservedRegs() when their halves
  // are reserved", which was never true.
  //
  // The consequence is as bad as it sounds: the allocator handed out $r12r13
  // as a DIVMODD/DIVMODUD destination, so an ordinary 64-bit division wrote
  // its quotient and remainder straight over the stack pointer and TLS
  // pointer. It stayed latent only because nothing allocated a GPR128 until
  // the divide instructions were wired up.
  markSuperRegs(Reserved, LVX::R12);
  markSuperRegs(Reserved, LVX::R13);

  // R14 = frame pointer. Per the user's explicit instruction earlier in
  // this conversation ("do what LLVM normally does: if the function
  // doesn't need a frame pointer, make FP allocatable"), R14 is only
  // reserved when this function actually needs a frame pointer -- and when
  // it is, the tuples containing it must go with it, same as above.
  const TargetFrameLowering *TFI = MF.getSubtarget().getFrameLowering();
  if (TFI->hasFP(MF))
    markSuperRegs(Reserved, LVX::R14);

  // Control registers ($ra, $pc, $ps, $cs, $ls, $le, $lc) are not members
  // of the GPR class at all, so they don't need reserving here — they're
  // already excluded from GPR's allocation order in LVXRegisterInfo.td.

  assert(checkAllSuperRegsMarked(Reserved) &&
         "super-registers of a reserved register must also be reserved");
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

  // Every LVX base+offset load/store format places the simm10 offset
  // immediately BEFORE the base-register operand (LD: rW, var, off, rZ;
  // SD/SQ/SO: rT/rU/rV, off, rZ; LQ/LO: rM/rN, var, off, rZ) -- opposite of
  // Lanai's ADD_I_LO-derived layout where the immediate follows the
  // register. FIOperandNum is the base-register (rZ) operand here, so the
  // offset is at FIOperandNum - 1.
  MachineOperand &OffsetOp = MI.getOperand(FIOperandNum - 1);
  int64_t Offset = MFI.getObjectOffset(FrameIndex) + OffsetOp.getImm();

  // MFI.getObjectOffset() returns an offset relative to R14 (FP): per
  // LVXFrameLowering::emitPrologue, FP = (SP after the prologue's stack
  // decrement) + AllocSize = the function's INCOMING SP, and both local
  // objects (negative PEI-assigned offsets below FP) and fixed/incoming-
  // argument objects (positive SPOffset above FP, per
  // LowerFormalArguments' CreateFixedObject(..., VA.getLocMemOffset()))
  // are expressed relative to that same point.
  //
  // The Frame Marker ($ra + caller FP, 16 bytes) is carved out of the MIDDLE
  // of that picture, and it has to be stepped over here. emitPrologue lowers
  // SP by AllocSize = StackSize + MarkerSize, so the extra 16 bytes are
  // added at the BOTTOM of the frame, but it writes the marker at the TOP --
  // at SP+StackSize and SP+StackSize+8, directly beneath the incoming SP.
  // PEI, meanwhile, hands out local offsets counting straight down from that
  // same incoming SP, so the two locals nearest the top (offsets -8 and -16)
  // land on exactly the caller-FP and $ra slots. That is not a near miss: a
  // frame with two spill slots had "sd 32[$r12] = $r1" store a local over the
  // saved $ra, and the epilogue's "ld $r16 = 32[$r12]; set $ra = $r16" then
  // reloaded that local as the return address, so `ret` jumped to it.
  //
  // Shifting locals down by MarkerSize makes the locals region [SP,
  // SP+StackSize) end exactly where the marker begins. It also keeps the
  // outgoing-argument area correct: PEI folds it into the bottom of the
  // local frame, and after the shift it sits at SP+0, which is where a
  // callee reads its incoming stack arguments from.
  //
  // Fixed objects are deliberately NOT shifted -- those are the incoming
  // stack arguments (CreateFixedObject with SPOffset >= 0), which live in
  // the CALLER's outgoing-argument area above the incoming SP, on the far
  // side of the marker from the locals.
  //
  // MarkerSize must be computed with the same predicate emitPrologue and
  // emitEpilogue use, or the three disagree about where the frame is.
  uint64_t MarkerSize = (HasFP || MFI.adjustsStack()) ? 16 : 0;
  if (!MFI.isFixedObjectIndex(FrameIndex))
    Offset -= MarkerSize;

  // With no FP the same address must be expressed relative to SP:
  // address = FP + Offset = (SP + AllocSize) + Offset.
  if (!HasFP)
    Offset += MFI.getStackSize() + MarkerSize;

  Register FrameReg = HasFP ? getFrameRegister(MF) : Register(LVX::R12);

  if (isInt<10>(Offset)) {
    MI.getOperand(FIOperandNum).ChangeToRegister(FrameReg, /*isDef=*/false);
    OffsetOp.ChangeToImmediate(Offset);
    return false;
  }

  // Offset out of simm10 range: scavenge a scratch register, materialize
  // FrameReg + Offset into it via LVXInstrInfo::loadImmediate
  // (MAKE/MAKE_X/MAKE_Y, Phase 5.1 -- any int64_t offset fits) + ADDD
  // (register-register form), then rewrite the instruction to address
  // through that scratch register at offset 0.
  assert(RS && "Register scavenging must be enabled for large frame offsets");
  Register Scratch = RS->scavengeRegisterBackwards(
      LVX::GPRRegClass, II, /*RestoreAfter=*/false, SPAdj);

  TII->loadImmediate(*MI.getParent(), II, DL, Scratch, Offset);
  BuildMI(*MI.getParent(), II, DL, TII->get(LVX::ADDD), Scratch)
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
