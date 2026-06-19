//===-- LVXInstrInfo.h - LVX Instruction Information -----------*- C++ -*-===//
//
// This file contains the LVX implementation of the TargetInstrInfo class.
// Modeled on LanaiInstrInfo.h (confirmed current in this checkout), trimmed
// to the constructor + getRegisterInfo for Phase 3; the optional overrides
// Lanai provides (analyzeBranch, optimizeCompareInstr, optimizeSelect,
// copyPhysReg, store/loadRegToStackSlot, expandPostRAPseudo, etc.) are not
// pure virtuals in TargetInstrInfo and are deferred to Phase 5 (frame
// lowering / register allocation support) since they aren't needed to get
// LVXISelLowering building and selecting basic patterns.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_LVX_LVXINSTRINFO_H
#define LLVM_LIB_TARGET_LVX_LVXINSTRINFO_H

#include "LVXRegisterInfo.h"
#include "llvm/CodeGen/TargetInstrInfo.h"

// GET_INSTRINFO_ENUM (the LVX::RET / LVX::ADDD / ... opcode enum) must be
// defined alongside GET_INSTRINFO_HEADER -- confirmed via the same
// independent-guarded-sections pattern found in LVXGenRegisterInfo.inc
// (see the comment in LVXRegisterInfo.h). LVXInstrInfo.cpp references
// LVX::RET directly, so this is needed for that translation unit too,
// since it includes this header first.
#define GET_INSTRINFO_ENUM
#define GET_INSTRINFO_HEADER
#include "LVXGenInstrInfo.inc"

namespace llvm {

class LVXSubtarget;

class LVXInstrInfo : public LVXGenInstrInfo {
  const LVXRegisterInfo RegisterInfo;

public:
  explicit LVXInstrInfo(const LVXSubtarget &STI);

  // TargetInstrInfo is a superset of MRegisterInfo; a client with an
  // instance of instruction info should always be able to get register
  // info too (through this method), per the same rationale as Lanai.
  const LVXRegisterInfo &getRegisterInfo() const { return RegisterInfo; }

  // Emits a single GPR-to-GPR move using COPYD (the synthetic
  // "iord $rW = 0, $rZ" instruction from lvx_Synthetic.yml). This is
  // invoked by standard LLVM machinery any time a physical-register
  // move needs lowering to a real instruction -- notably, by the
  // generic TargetOpcode::COPY produced when LowerFormalArguments'
  // RegInfo.addLiveIn() materializes an incoming argument register
  // into a virtual register, and by spilling/coalescing in general.
  // It is also the mechanism by which a GPR128/GPR256 argument value
  // assembled from a mis-aligned set of GPR pieces (per the ABI doc's
  // "some multi-register arguments may end up in mis-aligned register
  // tuples" rule) gets moved into a true aligned register tuple.
  void copyPhysReg(MachineBasicBlock &MBB, MachineBasicBlock::iterator MI,
                   const DebugLoc &DL, Register DestReg, Register SrcReg,
                   bool KillSrc, bool RenamableDest = false,
                   bool RenamableSrc = false) const override;
};

} // end namespace llvm

#endif // LLVM_LIB_TARGET_LVX_LVXINSTRINFO_H
