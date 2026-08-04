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

const uint32_t *
LVXRegisterInfo::getCallPreservedMask(const MachineFunction & /*MF*/,
                                      CallingConv::ID /*CC*/) const {
  // CSR_LVX_RegMask is generated from CSR_LVX in LVXCallingConv.td, so this
  // stays in step with getCalleeSavedRegs above by construction: everything
  // not listed there is caller-saved and is reported clobbered.
  return CSR_LVX_RegMask;
}

BitVector LVXRegisterInfo::getReservedRegs(const MachineFunction &MF) const {
  BitVector Reserved(getNumRegs());

  // R12 = stack pointer, R13 = thread-local/local pointer — always
  // reserved, per lvx_Convention.yml "stack"/"local".
  //
  // markSuperRegs, NOT a plain Reserved.set: reserving a register does not
  // implicitly reserve the register TUPLES that contain it. RegisterClassInfo
  // builds each class's allocation order by testing the candidate register
  // itself against this bitvector, so setting only R12/R13 leaves the GPR128
  // pair R12R13 (and the GPR256 quad R12R13R14R15) fully allocatable. The
  // allocator can then hand out $r12r13 as a DIVMODD/DIVMODUD destination and
  // write a quotient and remainder straight over the stack pointer and TLS
  // pointer. GPR128 had no real consumer until the divide instructions were
  // wired up, which is what makes this reachable now.
  markSuperRegs(Reserved, LVX::R12);
  markSuperRegs(Reserved, LVX::R13);

  // R14 = frame pointer. Per the user's explicit instruction earlier in
  // this conversation ("do what LLVM normally does: if the function
  // doesn't need a frame pointer, make FP allocatable"), R14 is only
  // reserved when this function actually needs a frame pointer.
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

  // The offset operand sits next to the base-register operand, but on which
  // side depends on the format. Every base+offset load/store places it
  // BEFORE (SD/SQ/SO: off, rZ, rT/rU/rV; LD/LQ/LO: rW/rM/rN, off, rZ,
  // variant), whereas the register-immediate ALU formats place it AFTER
  // (ALU_DWRI: rW, rZ, imm) -- and the latter is what a FrameIndex used as a
  // plain VALUE selects to, via ADDD_DWRI. Assuming FIOperandNum - 1
  // unconditionally would read the destination register as if it were the
  // offset. Look on both sides instead and take whichever is the immediate.
  unsigned OffsetOpNum = FIOperandNum - 1;
  if (!MI.getOperand(OffsetOpNum).isImm()) {
    assert(FIOperandNum + 1 < MI.getNumOperands() &&
           MI.getOperand(FIOperandNum + 1).isImm() &&
           "frame-index operand has no adjacent immediate offset");
    OffsetOpNum = FIOperandNum + 1;
  }
  MachineOperand &OffsetOp = MI.getOperand(OffsetOpNum);
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
