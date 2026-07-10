//===-- LVXFrameLowering.cpp - LVX Frame Information ---------*- C++ -*-===//
//
// This file contains the LVX implementation of TargetFrameLowering class.
//
// ABI reference: lvx_ApplicationBinaryInterface.tex §Stack Frame Regions
//
// Stack layout (high → low address):
//
//   [Incoming Arguments]       ← incoming SP (caller's frame)
//   [Anonymous Arguments]
//   [padding1]
//   [Local Variables / Static Chain]   ← virtual FP
//   [padding2]
//   [Register Save]
//   [$ra]                      (if frame marker needed)
//   [caller FP]                ← $fp (R14) points HERE if hasFP
//   [Dynamic Area]             (alloca)
//   [padding3]
//   [Outgoing Arguments]       ← SP (R12), 32-byte aligned
//
// Frame Marker = {caller FP (8 bytes), $ra (8 bytes)} at the bottom of
// the Register Save region.  Required when hasFP || has dynamic area.
//
//===----------------------------------------------------------------------===//

#include "LVXFrameLowering.h"
#include "LVXInstrInfo.h"
#include "LVXRegisterInfo.h"
#include "LVXSubtarget.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/CodeGen/RegisterScavenging.h"
#include "llvm/Support/ErrorHandling.h"

using namespace llvm;

// Every Frame Marker access below (caller-FP save/restore, $ra
// save/restore) and the FP-set add share the same "large offset" problem as
// the stack (de)allocation in emitPrologue/emitEpilogue: the immediate is
// bounded by simm10 ([-512,511]), but with big outgoing-call-argument areas
// OutgoingArgSize (and therefore FPOffset/RAOffset) can exceed that. This
// materializes Base+Offset into scratch register R16 via MAKE+ADDD when
// needed (same MAKE simm16 limit noted in emitPrologue's stack-allocation
// step), returning the register/immediate pair callers should use in place
// of (Base, Offset).
static std::pair<Register, int64_t>
materializeOffset(MachineBasicBlock &MBB, MachineBasicBlock::iterator MBBI,
                  const DebugLoc &DL, const LVXInstrInfo *TII, Register Base,
                  int64_t Offset) {
  if (isInt<10>(Offset))
    return {Base, Offset};
  assert(isInt<16>(Offset) &&
        "Offset exceeds MAKE's simm16 range -- needs a wider "
        "immediate-materialization sequence, not yet modeled");
  BuildMI(MBB, MBBI, DL, TII->get(LVX::MAKE), LVX::R16).addImm(Offset);
  BuildMI(MBB, MBBI, DL, TII->get(LVX::ADDD), LVX::R16)
      .addReg(LVX::R16)
      .addReg(Base);
  return {Register(LVX::R16), 0};
}

bool LVXFrameLowering::hasFPImpl(const MachineFunction &MF) const {
  const MachineFrameInfo &MFI = MF.getFrameInfo();
  // A frame pointer is needed when the frame cannot be addressed reliably
  // from SP alone: variable-sized objects (alloca) or when the frame address
  // is taken. This intentionally differs from Lanai's hardcoded `return true`;
  // when FP is not needed, R14 is allocatable as a normal callee-saved GPR.
  return MFI.hasVarSizedObjects() || MF.getFrameInfo().isFrameAddressTaken();
}

void LVXFrameLowering::emitPrologue(MachineFunction &MF,
                                    MachineBasicBlock &MBB) const {
  const LVXSubtarget &STI  = MF.getSubtarget<LVXSubtarget>();
  const LVXInstrInfo *TII  = STI.getInstrInfo();
  const LVXRegisterInfo *TRI = STI.getRegisterInfo();

  MachineBasicBlock::iterator MBBI = MBB.begin();
  MachineFrameInfo &MFI = MF.getFrameInfo();
  const TargetRegisterInfo *RegInfo = MF.getSubtarget().getRegisterInfo();
  DebugLoc DL;

  // Compute the total frame size (already rounded to StackAlignment = 32
  // by TargetFrameLowering::adjustsStack; MFI.getStackSize() returns the
  // already-aligned value after register allocation).
  uint64_t StackSize = MFI.getStackSize();

  // Leaf functions with no local variables, no callee-saved register spills,
  // and no outgoing arguments need no stack frame at all.
  if (StackSize == 0 && !MFI.adjustsStack() && !hasFP(MF))
    return;

  // Step 1: Allocate the stack frame.
  // "addd $r12 = -FrameSize, $r12" when it fits ADDD_i's simm10 immediate
  // ([-512,511]); otherwise materialize -FrameSize into a scratch register
  // via MAKE (simm16, [-32768,32767] -- the only immediate-load
  // instruction modeled so far, see LVXInstrInfo.td's ALU_DWI_Inst) and add
  // it with the register-register ADDD. R16 ($r16, one of the "veneer /
  // long-branch temporary" scratch registers per LVXRegisterInfo.td) is
  // free here since nothing is live yet at function entry.
  if (StackSize > 0) {
    if (isInt<10>(-(int64_t)StackSize)) {
      BuildMI(MBB, MBBI, DL, TII->get(LVX::ADDD_i), LVX::R12)
          .addImm(-(int64_t)StackSize)
          .addReg(LVX::R12);
    } else {
      assert(isInt<16>(-(int64_t)StackSize) &&
             "Frame size exceeds MAKE's simm16 range -- needs a wider "
             "immediate-materialization sequence, not yet modeled");
      BuildMI(MBB, MBBI, DL, TII->get(LVX::MAKE), LVX::R16)
          .addImm(-(int64_t)StackSize);
      BuildMI(MBB, MBBI, DL, TII->get(LVX::ADDD), LVX::R12)
          .addReg(LVX::R12)
          .addReg(LVX::R16);
    }
  }

  // Step 2: Save the Frame Marker ($ra, caller FP) when a frame pointer
  // is needed or when the function calls other functions (adjustsStack).
  // The Frame Marker sits just above the Outgoing Arguments region:
  //   SP+0 .. SP+(OutgoingArgSize-1) = Outgoing Arguments
  //   SP+OutgoingArgSize+0  = caller FP  (8 bytes)
  //   SP+OutgoingArgSize+8  = $ra        (8 bytes)
  // Per ABI: FP points to the caller-FP slot (= SP+OutgoingArgSize).
  if (hasFP(MF) || MFI.adjustsStack()) {
    unsigned OutgoingArgSize = MFI.getMaxCallFrameSize();
    // Align to 8 bytes.
    OutgoingArgSize = alignTo(OutgoingArgSize, 8);

    int64_t FPOffset = (int64_t)OutgoingArgSize;     // caller FP slot
    int64_t RAOffset = (int64_t)OutgoingArgSize + 8; // $ra slot

    // Save caller FP.
    {
      auto [Base, Off] = materializeOffset(MBB, MBBI, DL, TII, LVX::R12, FPOffset);
      BuildMI(MBB, MBBI, DL, TII->get(LVX::SD))
          .addReg(LVX::R14) // rT = caller FP
          .addImm(Off)
          .addReg(Base);
    }

    // Save return address.
    {
      auto [Base, Off] = materializeOffset(MBB, MBBI, DL, TII, LVX::R12, RAOffset);
      BuildMI(MBB, MBBI, DL, TII->get(LVX::SD))
          .addReg(LVX::RA) // rT = $ra
          .addImm(Off)
          .addReg(Base);
    }

    // Set frame pointer: FP = SP + FrameSize (points to Frame Marker).
    // "addd $r14 = FrameSize, $r12"
    if (isInt<10>((int64_t)StackSize)) {
      BuildMI(MBB, MBBI, DL, TII->get(LVX::ADDD_i), LVX::R14)
          .addImm((int64_t)StackSize)
          .addReg(LVX::R12);
    } else {
      assert(isInt<16>((int64_t)StackSize) &&
             "Frame size exceeds MAKE's simm16 range -- needs a wider "
             "immediate-materialization sequence, not yet modeled");
      BuildMI(MBB, MBBI, DL, TII->get(LVX::MAKE), LVX::R14)
          .addImm((int64_t)StackSize);
      BuildMI(MBB, MBBI, DL, TII->get(LVX::ADDD), LVX::R14)
          .addReg(LVX::R14)
          .addReg(LVX::R12);
    }
  }

  // Step 3: Emit callee-saved register spills (generated by
  // spillCalleeSavedRegisters / the generic framework).
  // The generic framework handles this via storeRegToStackSlot; the
  // actual SD instructions are inserted by the register scavenger between
  // MBBI and end. Nothing target-specific needed here beyond the stack
  // allocation above.
}

void LVXFrameLowering::emitEpilogue(MachineFunction &MF,
                                    MachineBasicBlock &MBB) const {
  const LVXSubtarget &STI = MF.getSubtarget<LVXSubtarget>();
  const LVXInstrInfo *TII = STI.getInstrInfo();
  MachineBasicBlock::iterator MBBI = MBB.getLastNonDebugInstr();
  MachineFrameInfo &MFI = MF.getFrameInfo();
  DebugLoc DL = MBBI->getDebugLoc();

  uint64_t StackSize = MFI.getStackSize();
  if (StackSize == 0 && !MFI.adjustsStack() && !hasFP(MF))
    return;

  // Step 1: Restore Frame Marker ($ra, caller FP).
  if (hasFP(MF) || MFI.adjustsStack()) {
    unsigned OutgoingArgSize = MFI.getMaxCallFrameSize();
    OutgoingArgSize = alignTo(OutgoingArgSize, 8);

    int64_t FPOffset = (int64_t)OutgoingArgSize;
    int64_t RAOffset = (int64_t)OutgoingArgSize + 8;

    // Restore $ra.
    {
      auto [Base, Off] = materializeOffset(MBB, MBBI, DL, TII, LVX::R12, RAOffset);
      BuildMI(MBB, MBBI, DL, TII->get(LVX::LD), LVX::RA)
          .addImm(0) // variant = 0
          .addImm(Off)
          .addReg(Base);
    }

    // Restore caller FP.
    {
      auto [Base, Off] = materializeOffset(MBB, MBBI, DL, TII, LVX::R12, FPOffset);
      BuildMI(MBB, MBBI, DL, TII->get(LVX::LD), LVX::R14)
          .addImm(0) // variant = 0
          .addImm(Off)
          .addReg(Base);
    }
  }

  // Step 2: Deallocate the stack frame.
  // "addd $r12 = FrameSize, $r12" when it fits simm10; otherwise MAKE +
  // ADDD via scratch R16, same fallback as emitPrologue's allocation step.
  if (StackSize > 0) {
    if (isInt<10>((int64_t)StackSize)) {
      BuildMI(MBB, MBBI, DL, TII->get(LVX::ADDD_i), LVX::R12)
          .addImm((int64_t)StackSize)
          .addReg(LVX::R12);
    } else {
      assert(isInt<16>((int64_t)StackSize) &&
             "Frame size exceeds MAKE's simm16 range -- needs a wider "
             "immediate-materialization sequence, not yet modeled");
      BuildMI(MBB, MBBI, DL, TII->get(LVX::MAKE), LVX::R16)
          .addImm((int64_t)StackSize);
      BuildMI(MBB, MBBI, DL, TII->get(LVX::ADDD), LVX::R12)
          .addReg(LVX::R12)
          .addReg(LVX::R16);
    }
  }
}

MachineBasicBlock::iterator LVXFrameLowering::eliminateCallFramePseudoInstr(
    MachineFunction & /*MF*/, MachineBasicBlock &MBB,
    MachineBasicBlock::iterator I) const {
  // ADJCALLSTACKDOWN/UP (LVXInstrInfo.td) exist only so SelectionDAGISel
  // has something to select ISD::CALLSEQ_START/END to; LVX's Outgoing
  // Arguments region is sized once for the whole function
  // (MFI.getMaxCallFrameSize(), baked into the frame in emitPrologue), not
  // adjusted per call site, so there is no real per-call SP adjustment to
  // emit here -- simply erase the pseudo.
  return MBB.erase(I);
}

void LVXFrameLowering::determineCalleeSaves(MachineFunction &MF,
                                            BitVector &SavedRegs,
                                            RegScavenger *RS) const {
  TargetFrameLowering::determineCalleeSaves(MF, SavedRegs, RS);

  // Reserve a scavenging spill slot for LVXRegisterInfo::eliminateFrameIndex's
  // MAKE+ADDD fallback, which needs a scratch GPR whenever a frame-index
  // offset falls outside simm10 range. Unconditional (mirrors ARC's
  // "any function with stack objects gets one" policy) rather than trying
  // to predict which functions will actually need it.
  if (RS && MF.getFrameInfo().hasStackObjects()) {
    const LVXRegisterInfo *TRI = STI.getRegisterInfo();
    const TargetRegisterClass &RC = LVX::GPRRegClass;
    int FI = MF.getFrameInfo().CreateSpillStackObject(TRI->getSpillSize(RC),
                                                      TRI->getSpillAlign(RC));
    RS->addScavengingFrameIndex(FI);
  }
}
