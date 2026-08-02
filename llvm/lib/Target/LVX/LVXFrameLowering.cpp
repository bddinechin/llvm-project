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

// "Dest = Src + Offset" for an arbitrary int64_t Offset, in ONE instruction.
//
// The immediate of "addd $rW = $rZ, imm" is only simm10 ([-512,511]), which a
// frame of any size overruns, but the instruction has widened forms that hold
// 37 and 64 immediate bits in two and three syllables (ALU_DWRI.X/.Y) -- the
// same instruction, just longer. LVXInstrInfo::getFormForImmediate picks the
// narrowest that holds Offset, from the chains the machine description
// generates into LVXImmediateExtensions.inc. Every int64_t fits the 64-bit
// form, so this never needs a scratch register or a second instruction.
static void emitAddImm(MachineBasicBlock &MBB, MachineBasicBlock::iterator MBBI,
                       const DebugLoc &DL, const LVXInstrInfo *TII,
                       Register Dest, Register Src, int64_t Offset) {
  unsigned Opc = LVXInstrInfo::getFormForImmediate(LVX::ADDD_DWRI, Offset);
  assert(Opc && "every int64_t fits addd's 64-bit widened form");
  BuildMI(MBB, MBBI, DL, TII->get(Opc), Dest).addReg(Src).addImm(Offset);
}

// The opcode to use for a Frame Marker access at Offset from Base.
//
// Same story as emitAddImm: with a big outgoing-call-argument area the frame
// marker sits further from SP than the simm10 offset field of "sd off[$rZ]"
// reaches, and the instruction's widened forms (LSU_SSBO.X/.Y, LSU_LSBO.X/.Y)
// hold 37 and 64 bits of offset in the same operand. Widening in place keeps
// each save and restore a single instruction, where materializing the address
// into a scratch register first would cost two more -- and would need a
// scratch register free at a point in the prologue where that is awkward to
// guarantee.
static unsigned frameAccessOpcode(unsigned NarrowOpc, int64_t Offset) {
  unsigned Opc = LVXInstrInfo::getFormForImmediate(NarrowOpc, Offset);
  assert(Opc && "every int64_t fits the 64-bit widened load/store offset");
  return Opc;
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

  // Step 1: Allocate the stack frame -- "addd $r12 = $r12, -FrameSize", in
  // whichever width of that instruction holds -FrameSize (see emitAddImm).
  if (StackSize > 0)
    emitAddImm(MBB, MBBI, DL, TII, LVX::R12, LVX::R12, -(int64_t)StackSize);

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
      BuildMI(MBB, MBBI, DL,
              TII->get(frameAccessOpcode(LVX::SD_SSBO, FPOffset)))
          .addImm(FPOffset)
          .addReg(LVX::R12)
          .addReg(LVX::R14); // rT = caller FP
    }

    // Save return address. $ra is a control register, not a GPR -- SD's
    // rT operand is GPR-typed, so it can't be stored directly (confirmed
    // by the real assembler rejecting "sd off[$rZ] = $ra" outright).
    // GETRA (Phase 5.2) moves it into scratch GPR R16 first, matching
    // the real ISA's GET/SET register-transfer convention.
    {
      BuildMI(MBB, MBBI, DL, TII->get(LVX::GET_GSR), LVX::R16).addReg(LVX::RA);
      BuildMI(MBB, MBBI, DL,
              TII->get(frameAccessOpcode(LVX::SD_SSBO, RAOffset)))
          .addImm(RAOffset)
          .addReg(LVX::R12)
          .addReg(LVX::R16); // rT = $ra (via GET)
    }

    // Set frame pointer: FP = SP + FrameSize (points to Frame Marker).
    // "addd $r14 = $r12, FrameSize"
    emitAddImm(MBB, MBBI, DL, TII, LVX::R14, LVX::R12, (int64_t)StackSize);
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

    // Restore $ra. LD's destination is GPR-typed (same reason as the
    // GETRA save above), so load into scratch R16 first, then SETRA it
    // back into the actual $ra control register.
    {
      BuildMI(MBB, MBBI, DL,
              TII->get(frameAccessOpcode(LVX::LD_LSBO, RAOffset)), LVX::R16)
          .addImm(RAOffset)
          .addReg(LVX::R12)
          .addImm(0); // variant = 0 (cached, non-speculative)
      // "set $ra = $r16". The machine description makes $ra a tied
      // read-modify-write destination here -- the write is conditional on
      // privilege -- so $ra appears as both the def and the tied use.
      BuildMI(MBB, MBBI, DL, TII->get(LVX::SET_SETRA), LVX::RA)
          .addReg(LVX::RA)
          .addReg(LVX::R16);
    }

    // Restore caller FP.
    {
      BuildMI(MBB, MBBI, DL,
              TII->get(frameAccessOpcode(LVX::LD_LSBO, FPOffset)), LVX::R14)
          .addImm(FPOffset)
          .addReg(LVX::R12)
          .addImm(0); // variant = 0 (cached, non-speculative)
    }
  }

  // Step 2: Deallocate the stack frame -- "addd $r12 = $r12, FrameSize", in
  // whichever width of that instruction holds FrameSize, mirroring the
  // allocation in emitPrologue.
  if (StackSize > 0)
    emitAddImm(MBB, MBBI, DL, TII, LVX::R12, LVX::R12, (int64_t)StackSize);
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
