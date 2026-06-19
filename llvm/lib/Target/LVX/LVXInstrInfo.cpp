//===-- LVXInstrInfo.cpp - LVX Instruction Information -----------*- C++ -*-===//
//
// This file contains the LVX implementation of the TargetInstrInfo class.
//
//===----------------------------------------------------------------------===//

#include "LVXInstrInfo.h"
#include "LVXSubtarget.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"

#define GET_INSTRINFO_CTOR_DTOR
#include "LVXGenInstrInfo.inc"

using namespace llvm;

// LVXGenInstrInfo's real constructor (confirmed via build error against
// the generated .inc, not guessed) is:
//   LVXGenInstrInfo(const TargetSubtargetInfo &STI,
//                   const TargetRegisterInfo &TRI,
//                   unsigned CFSetupOpcode, unsigned CFDestroyOpcode,
//                   unsigned CatchRetOpcode, unsigned ReturnOpcode)
// LVX has no call-frame setup/destroy pseudo-instructions and no
// catch-return instruction (no exception handling defined yet), so those
// three use ~0u, the standard LLVM sentinel for "no such opcode" used
// throughout TargetInstrInfo. RET is a real opcode (LVX::RET), so that one
// is passed through properly.
//
// RegisterInfo (our own member, not the subtarget's) is passed as the
// TargetRegisterInfo& argument: going through STI.getRegisterInfo() here
// would be circular, since that accessor returns
// &InstrInfo.getRegisterInfo() -- i.e. it depends on this very
// LVXInstrInfo object being fully constructed already.
//
// Note on initialization order: base classes always construct before
// derived-class members, so RegisterInfo (a member declared below) is
// technically not yet constructed when its address is passed into
// LVXGenInstrInfo's initializer here. This is safe in practice because
// (a) member sub-object storage is reserved as part of the object's
// layout before any constructor runs, so the address itself is valid;
// (b) TargetInstrInfo's constructor (per the upstream change that added
// this TRI-reference-storing behavior) only stores the reference for
// later use, it does not dereference it during construction; and
// (c) RegisterInfo is fully constructed immediately afterward, strictly
// before LVXInstrInfo is considered constructed or usable by any caller.
LVXInstrInfo::LVXInstrInfo(const LVXSubtarget &STI)
    : LVXGenInstrInfo(STI, RegisterInfo, /*CFSetupOpcode=*/~0u,
                      /*CFDestroyOpcode=*/~0u, /*CatchRetOpcode=*/~0u,
                      /*ReturnOpcode=*/LVX::RET),
      RegisterInfo() {}

// Emits one COPYD ("iord $rW = 0, $rZ", per lvx_Synthetic.yml) for a
// single 64-bit GPR-to-GPR move.
static void emitCopyD(MachineBasicBlock &MBB, MachineBasicBlock::iterator MI,
                      const DebugLoc &DL, const TargetInstrInfo &TII,
                      MCRegister DestReg, MCRegister SrcReg, bool KillSrc) {
  BuildMI(MBB, MI, DL, TII.get(LVX::COPYD), DestReg)
      .addReg(SrcReg, getKillRegState(KillSrc));
}

// Emits one CATDQ to assemble an aligned 128-bit register pair directly
// from two arbitrary 64-bit source registers in a single instruction.
// Confirmed semantics: for "catdq $rM = $rY, $rZ", $rY becomes the
// pair's low 64 bits and $rZ the high 64 bits.
static void emitCatDQ(MachineBasicBlock &MBB, MachineBasicBlock::iterator MI,
                      const DebugLoc &DL, const TargetInstrInfo &TII,
                      MCRegister DestPair, MCRegister SrcLo, MCRegister SrcHi,
                      bool KillSrc) {
  BuildMI(MBB, MI, DL, TII.get(LVX::CATDQ), DestPair)
      .addReg(SrcLo, getKillRegState(KillSrc))
      .addReg(SrcHi, getKillRegState(KillSrc));
}

void LVXInstrInfo::copyPhysReg(MachineBasicBlock &MBB,
                               MachineBasicBlock::iterator MI,
                               const DebugLoc &DL, Register DestReg,
                               Register SrcReg, bool KillSrc,
                               bool /*RenamableDest*/,
                               bool /*RenamableSrc*/) const {
  if (LVX::GPRRegClass.contains(DestReg, SrcReg)) {
    emitCopyD(MBB, MI, DL, *this, DestReg, SrcReg, KillSrc);
    return;
  }

  if (LVX::GPR128RegClass.contains(DestReg, SrcReg)) {
    // CATDQ assembles the whole pair from the source's two halves in
    // one instruction -- strictly better than two separate COPYDs, and
    // the same mechanism this move would need anyway if SrcReg's two
    // halves did not start out adjacent (the mis-aligned-argument case
    // the ABI doc describes), so it is used unconditionally here rather
    // than only as a special case.
    //
    // IMPORTANT, confirmed directly rather than inferred from naming:
    // sub_hi (SubRegIndex<64, 0>) is the architectural LOW 64 bits of
    // a pair (e.g. R0 in R0R1), and sub_lo (SubRegIndex<64, 64>) is the
    // architectural HIGH 64 bits (e.g. R1 in R0R1) -- the index names
    // reflect list position in each LVXRegPair's Subregs, not bit
    // significance. Naming local variables by their true architectural
    // role (SrcLowHalf/SrcHighHalf) rather than reusing the
    // sub_hi/sub_lo names avoids re-introducing this inversion here.
    MCRegister SrcLowHalf = RegisterInfo.getSubReg(SrcReg, sub_hi);
    MCRegister SrcHighHalf = RegisterInfo.getSubReg(SrcReg, sub_lo);
    emitCatDQ(MBB, MI, DL, *this, DestReg, SrcLowHalf, SrcHighHalf, KillSrc);
    return;
  }

  if (LVX::GPR256RegClass.contains(DestReg, SrcReg)) {
    // No single instruction catenates two 128-bit pairs into a 256-bit
    // quad (confirmed absent from lvx_Format.yml/lvx_Opcode.txt/
    // lvx_Synthetic.yml), so this decomposes one level further than
    // GPR128's case: walk the two 128-bit halves, and use one CATDQ
    // per half to assemble each one's two GPR quarters.
    //
    // Confirmed mapping (same backwards-from-naming pattern as
    // sub_hi/sub_lo above): sub_pair_hi (SubRegIndex<128, 0>) is the
    // architectural LOW 128 bits (e.g. R0R1 in R0R1R2R3), sub_pair_lo
    // (SubRegIndex<128, 128>) is the architectural HIGH 128 bits (e.g.
    // R2R3). Local variables are named by true architectural role
    // throughout, not by reusing the index names, to avoid
    // re-introducing the same inversion bug fixed above.
    MCRegister SrcLowPair = RegisterInfo.getSubReg(SrcReg, sub_pair_hi);
    MCRegister SrcHighPair = RegisterInfo.getSubReg(SrcReg, sub_pair_lo);
    MCRegister DestLowPair = RegisterInfo.getSubReg(DestReg, sub_pair_hi);
    MCRegister DestHighPair = RegisterInfo.getSubReg(DestReg, sub_pair_lo);

    MCRegister SrcLowPairLow = RegisterInfo.getSubReg(SrcLowPair, sub_hi);
    MCRegister SrcLowPairHigh = RegisterInfo.getSubReg(SrcLowPair, sub_lo);
    emitCatDQ(MBB, MI, DL, *this, DestLowPair, SrcLowPairLow, SrcLowPairHigh,
             KillSrc);

    MCRegister SrcHighPairLow =
        RegisterInfo.getSubReg(SrcHighPair, sub_hi);
    MCRegister SrcHighPairHigh =
        RegisterInfo.getSubReg(SrcHighPair, sub_lo);
    emitCatDQ(MBB, MI, DL, *this, DestHighPair, SrcHighPairLow,
             SrcHighPairHigh, KillSrc);
    return;
  }

  llvm_unreachable("Unsupported register class pair in LVX copyPhysReg");
}
