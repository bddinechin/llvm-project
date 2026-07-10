//===-- LVXFrameLowering.h - Define frame lowering for LVX -----*- C++-*-===//
//
// This class implements LVX-specific bits of the TargetFrameLowering
// class. Modeled on LanaiFrameLowering.h (confirmed current in this
// checkout).
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_LVX_LVXFRAMELOWERING_H
#define LLVM_LIB_TARGET_LVX_LVXFRAMELOWERING_H

#include "llvm/CodeGen/TargetFrameLowering.h"

namespace llvm {

class BitVector;
class LVXSubtarget;

class LVXFrameLowering : public TargetFrameLowering {
protected:
  const LVXSubtarget &STI;

public:
  // ABI doc §Stack Frame Addressing: "The stack pointer must always be
  // aligned on a 32-byte boundary. This implies that all stack frames
  // must be a multiple of 32 bytes in size."
  explicit LVXFrameLowering(const LVXSubtarget &Subtarget)
      : TargetFrameLowering(StackGrowsDown,
                            /*StackAlignment=*/Align(32),
                            /*LocalAreaOffset=*/0),
        STI(Subtarget) {}

  void emitPrologue(MachineFunction &MF,
                    MachineBasicBlock &MBB) const override;
  void emitEpilogue(MachineFunction &MF,
                    MachineBasicBlock &MBB) const override;

  MachineBasicBlock::iterator
  eliminateCallFramePseudoInstr(MachineFunction &MF, MachineBasicBlock &MBB,
                                MachineBasicBlock::iterator I) const override;

  void determineCalleeSaves(MachineFunction &MF, BitVector &SavedRegs,
                            RegScavenger *RS = nullptr) const override;

protected:
  // Unlike Lanai (which hardcodes true), LVX determines FP need normally:
  // a frame pointer is required when the function has variable-sized
  // objects (alloca) or requests stack realignment — i.e. the standard
  // TargetFrameLowering::hasFP default behavior. Returning false here
  // when not needed is what makes R14 allocatable, per the user's
  // explicit instruction earlier in this conversation.
  bool hasFPImpl(const MachineFunction &MF) const override;
};

} // end namespace llvm

#endif // LLVM_LIB_TARGET_LVX_LVXFRAMELOWERING_H
