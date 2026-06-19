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
  // StackAlignment = 16 bytes (128 bits), per the ABI doc's "the only
  // alignment enforced is 8 bytes" note for argument slots — but the ABI
  // doc separately specifies stack alignment of 16 bytes elsewhere (see
  // LVXRegisterInfo.td's S128 data-layout token from Phase 1). Using 16
  // here; revisit if the ABI doc's stack-frame section says otherwise
  // once we read it again closely in Phase 5.
  explicit LVXFrameLowering(const LVXSubtarget &Subtarget)
      : TargetFrameLowering(StackGrowsDown,
                            /*StackAlignment=*/Align(16),
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
