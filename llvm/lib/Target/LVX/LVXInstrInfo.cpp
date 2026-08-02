//===-- LVXInstrInfo.cpp - LVX Instruction Information -----------*- C++ -*-===//
//
// This file contains the LVX implementation of the TargetInstrInfo class.
//
//===----------------------------------------------------------------------===//

#include "LVXInstrInfo.h"
#include "LVXSubtarget.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/Support/MathExtras.h"

#define GET_INSTRINFO_CTOR_DTOR
#include "LVXGenInstrInfo.inc"

using namespace llvm;

// LVXGenInstrInfo's real constructor (confirmed via build error against
// the generated .inc, not guessed) is:
//   LVXGenInstrInfo(const TargetSubtargetInfo &STI,
//                   const TargetRegisterInfo &TRI,
//                   unsigned CFSetupOpcode, unsigned CFDestroyOpcode,
//                   unsigned CatchRetOpcode, unsigned ReturnOpcode)
// CFSetupOpcode/CFDestroyOpcode are LVX::ADJCALLSTACKDOWN/UP (Phase 5,
// LVXInstrInfo.td) -- SelectionDAGISel needs real, selectable targets for
// the generic ISD::CALLSEQ_START/END nodes LowerCall emits around every
// call, even though LVXFrameLowering::eliminateCallFramePseudoInstr just
// erases them afterward (LVX's Outgoing Arguments region is sized once
// for the whole function, not adjusted per call site). LVX still has no
// catch-return instruction (no exception handling defined yet), so that
// one uses ~0u, the standard LLVM sentinel for "no such opcode". RET is a
// real opcode (LVX::RET_RTS), so that one is passed through properly.
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
    : LVXGenInstrInfo(STI, RegisterInfo,
                      /*CFSetupOpcode=*/LVX::ADJCALLSTACKDOWN,
                      /*CFDestroyOpcode=*/LVX::ADJCALLSTACKUP,
                      /*CatchRetOpcode=*/~0u,
                      /*ReturnOpcode=*/LVX::RET_RTS),
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
// Semantics, per the machine description ("result = ZX64(argument2) |
// (argument3 << 64)") and confirmed against opcodes/lvx-opc.c: the
// instruction is "catdq $rM = $rZ, $rY" and $rZ -- the FIRST source operand
// -- is the pair's low 64 bits, $rY the high.  The hand-written description
// this replaced had the two sources in the opposite order while assigning
// them the same encoding fields, so it built every pair with its halves
// swapped; generating the format from the machine description fixed it.
static void emitCatDQ(MachineBasicBlock &MBB, MachineBasicBlock::iterator MI,
                      const DebugLoc &DL, const TargetInstrInfo &TII,
                      MCRegister DestPair, MCRegister SrcLo, MCRegister SrcHi,
                      bool KillSrc) {
  BuildMI(MBB, MI, DL, TII.get(LVX::CATDQ_CATDQ), DestPair)
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

// Store/load operand shapes (LVXInstrInfo.td):
// Store/load operand shapes, generated from the machine description into
// LVXInstrEncodings.td, in the order the assembly syntax writes them:
//   SD_SSBO: (outs),           (ins simm10:$off, GPR:$rZ, GPR:$rT)
//   SQ_SQBO: (outs),           (ins simm10:$off, GPR:$rZ, GPR128:$rU)
//   SO_SOBO: (outs),           (ins simm10:$off, GPR:$rZ, GPR256:$rV)
//   LD_LSBO: (outs GPR:$rW),   (ins simm10:$off, GPR:$rZ, variant:$variant)
//   LQ_LQBO: (outs GPR128:$rM),(ins simm10:$off, GPR:$rZ, variant:$variant)
//   LO_LOBO: (outs GPR256:$rN),(ins simm10:$off, GPR:$rZ, variant:$variant)
// The offset operand always immediately precedes the base-register operand --
// opposite of Lanai's ADD_I_LO-derived layout -- which matters in
// LVXRegisterInfo::eliminateFrameIndex, where the offset is located relative
// to the frame-index operand it replaces.
void LVXInstrInfo::storeRegToStackSlot(MachineBasicBlock &MBB,
                                       MachineBasicBlock::iterator MI,
                                       Register SrcReg, bool isKill,
                                       int FrameIndex,
                                       const TargetRegisterClass *RC,
                                       Register /*VReg*/,
                                       MachineInstr::MIFlag Flags) const {
  DebugLoc DL;
  if (MI != MBB.end())
    DL = MI->getDebugLoc();

  unsigned Opc;
  if (RC == &LVX::GPRRegClass)
    Opc = LVX::SD_SSBO;
  else if (RC == &LVX::GPR128RegClass)
    Opc = LVX::SQ_SQBO;
  else if (RC == &LVX::GPR256RegClass)
    Opc = LVX::SO_SOBO;
  else
    llvm_unreachable("Unsupported register class in LVX storeRegToStackSlot");

  BuildMI(MBB, MI, DL, get(Opc))
      .addImm(0) // off
      .addFrameIndex(FrameIndex)
      .addReg(SrcReg, getKillRegState(isKill))
      .setMIFlags(Flags);
}

void LVXInstrInfo::loadRegFromStackSlot(MachineBasicBlock &MBB,
                                        MachineBasicBlock::iterator MI,
                                        Register DestReg, int FrameIndex,
                                        const TargetRegisterClass *RC,
                                        Register /*VReg*/, unsigned /*SubReg*/,
                                        MachineInstr::MIFlag Flags) const {
  DebugLoc DL;
  if (MI != MBB.end())
    DL = MI->getDebugLoc();

  unsigned Opc;
  if (RC == &LVX::GPRRegClass)
    Opc = LVX::LD_LSBO;
  else if (RC == &LVX::GPR128RegClass)
    Opc = LVX::LQ_LQBO;
  else if (RC == &LVX::GPR256RegClass)
    Opc = LVX::LO_LOBO;
  else
    llvm_unreachable("Unsupported register class in LVX loadRegFromStackSlot");

  BuildMI(MBB, MI, DL, get(Opc), DestReg)
      .addImm(0) // off
      .addFrameIndex(FrameIndex)
      .addImm(0) // variant = 0 (cached, non-speculative)
      .setMIFlags(Flags);
}

//===----------------------------------------------------------------------===//
// Branch analysis
//===----------------------------------------------------------------------===//

// Is this one of the conditional branches, in any width?
static bool isCondBranchOpcode(unsigned Opc) {
  switch (Opc) {
  case LVX::CB_CB:
  case LVX::CBX_CB_X:
  case LVX::CCB_CCB:
  case LVX::CCBX_CCB_X:
    return true;
  default:
    return false;
  }
}

// ... and one of the unconditional ones?
static bool isUncondBranchOpcode(unsigned Opc) {
  return Opc == LVX::GOTO_UB || Opc == LVX::GOTOX_UB_X;
}

// Is this a two-register compare-and-branch (ccb) rather than a test of one
// register against zero (cb)? They differ in operand count, so the condition
// vector's length depends on it.
static bool isCompareBranchOpcode(unsigned Opc) {
  return Opc == LVX::CCB_CCB || Opc == LVX::CCBX_CCB_X;
}

MachineBasicBlock *
LVXInstrInfo::getBranchDestBlock(const MachineInstr &MI) const {
  // The target is always the last operand of an LVX branch: "goto T",
  // "cb.<cond> $rZ ? T", "ccb.<cmp> $rZ, $rY ? T".
  assert(MI.getDesc().isBranch() && "not a branch");
  return MI.getOperand(MI.getNumExplicitOperands() - 1).getMBB();
}

bool LVXInstrInfo::analyzeBranch(MachineBasicBlock &MBB,
                                 MachineBasicBlock *&TBB,
                                 MachineBasicBlock *&FBB,
                                 SmallVectorImpl<MachineOperand> &Cond,
                                 bool AllowModify) const {
  TBB = FBB = nullptr;
  Cond.clear();

  MachineBasicBlock::iterator I = MBB.getLastNonDebugInstr();
  if (I == MBB.end() || !isUnpredicatedTerminator(*I))
    return false;

  // Walk back over the block's terminators, newest first.
  MachineBasicBlock::iterator FirstTerm = I;
  while (FirstTerm != MBB.begin()) {
    auto Prev = std::prev(FirstTerm);
    if (!isUnpredicatedTerminator(*Prev))
      break;
    FirstTerm = Prev;
  }

  SmallVector<MachineInstr *, 4> Terminators;
  for (auto T = FirstTerm; T != MBB.end(); ++T)
    if (!T->isDebugInstr())
      Terminators.push_back(&*T);

  // Anything that is not a plain branch (a return, an indirect branch) means
  // this block's control flow cannot be rewritten.
  for (MachineInstr *T : Terminators)
    if (!isCondBranchOpcode(T->getOpcode()) &&
        !isUncondBranchOpcode(T->getOpcode()))
      return true;

  // Delete anything after the first unconditional branch: it is unreachable,
  // and leaving it would make the terminator sequence unanalyzable.
  if (AllowModify) {
    while (Terminators.size() > 1 &&
           isUncondBranchOpcode(Terminators[Terminators.size() - 2]
                                    ->getOpcode())) {
      Terminators.back()->eraseFromParent();
      Terminators.pop_back();
    }
  }

  if (Terminators.size() > 2)
    return true;

  auto setCondition = [&Cond](MachineInstr *Branch) {
    Cond.push_back(MachineOperand::CreateImm(Branch->getOpcode()));
    Cond.push_back(Branch->getOperand(0));   // the bcucond/ccbcomp code
    Cond.push_back(Branch->getOperand(1));   // $rZ
    if (isCompareBranchOpcode(Branch->getOpcode()))
      Cond.push_back(Branch->getOperand(2)); // $rY
  };

  if (Terminators.size() == 1) {
    MachineInstr *Only = Terminators[0];
    if (isUncondBranchOpcode(Only->getOpcode())) {
      TBB = getBranchDestBlock(*Only);       // fall-through is unreachable
      return false;
    }
    TBB = getBranchDestBlock(*Only);         // conditional, falls through
    setCondition(Only);
    return false;
  }

  // Conditional followed by unconditional.
  MachineInstr *Conditional = Terminators[0];
  MachineInstr *Unconditional = Terminators[1];
  if (!isCondBranchOpcode(Conditional->getOpcode()) ||
      !isUncondBranchOpcode(Unconditional->getOpcode()))
    return true;

  TBB = getBranchDestBlock(*Conditional);
  FBB = getBranchDestBlock(*Unconditional);
  setCondition(Conditional);
  return false;
}

unsigned LVXInstrInfo::removeBranch(MachineBasicBlock &MBB,
                                    int *BytesRemoved) const {
  if (BytesRemoved)
    *BytesRemoved = 0;

  unsigned Removed = 0;
  MachineBasicBlock::iterator I = MBB.end();
  while (I != MBB.begin()) {
    --I;
    if (I->isDebugInstr())
      continue;
    if (!isCondBranchOpcode(I->getOpcode()) &&
        !isUncondBranchOpcode(I->getOpcode()))
      break;
    if (BytesRemoved)
      *BytesRemoved += getInstSizeInBytes(*I);
    I = MBB.erase(I);
    ++Removed;
  }
  return Removed;
}

unsigned LVXInstrInfo::insertBranch(MachineBasicBlock &MBB,
                                    MachineBasicBlock *TBB,
                                    MachineBasicBlock *FBB,
                                    ArrayRef<MachineOperand> Cond,
                                    const DebugLoc &DL, int *BytesAdded) const {
  assert(TBB && "insertBranch needs at least one destination");
  assert((Cond.size() == 0 || Cond.size() == 3 || Cond.size() == 4) &&
         "LVX branch conditions are (opcode, code, rZ[, rY])");
  if (BytesAdded)
    *BytesAdded = 0;

  auto add = [&](MachineInstr *MI) {
    if (BytesAdded)
      *BytesAdded += getInstSizeInBytes(*MI);
  };

  if (Cond.empty()) {
    assert(!FBB && "an unconditional branch cannot have two destinations");
    add(BuildMI(&MBB, DL, get(LVX::GOTO_UB)).addMBB(TBB));
    return 1;
  }

  // Conditional branch; the target is always last, matching the generated
  // formats' operand order.
  MachineInstrBuilder MIB = BuildMI(&MBB, DL, get(Cond[0].getImm()));
  for (unsigned i = 1, e = Cond.size(); i != e; ++i)
    MIB.add(Cond[i]);
  MIB.addMBB(TBB);
  add(MIB);

  if (!FBB)
    return 1;

  add(BuildMI(&MBB, DL, get(LVX::GOTO_UB)).addMBB(FBB));
  return 2;
}

bool LVXInstrInfo::reverseBranchCondition(
    SmallVectorImpl<MachineOperand> &Cond) const {
  assert((Cond.size() == 3 || Cond.size() == 4) && "malformed LVX condition");
  // Both condition encodings pair each relation with its negation in adjacent
  // codes -- bcucond has dltz/dgez, dlez/dgtz, deqz/dnez, odd/even and the
  // same four again for the word-width tests; ccbcomp has dlt/dge, dltu/dgeu,
  // deq/dne, dany/dnone and likewise. So negating a condition is flipping its
  // low bit, for either kind. (Checked against every member of both modifiers
  // in LVXModifiers.h.)
  Cond[1].setImm(Cond[1].getImm() ^ 1);
  return false;
}

unsigned LVXInstrInfo::getInstSizeInBytes(const MachineInstr &MI) const {
  if (MI.isPseudo() || MI.isMetaInstruction())
    return 0;
  // Every real LVX instruction carries its width: 4 bytes for a single
  // syllable, 8 and 12 for the widened forms.
  return MI.getDesc().getSize();
}

bool LVXInstrInfo::isBranchOffsetInRange(unsigned BranchOpc,
                                         int64_t BrOffset) const {
  // Every branch displacement is a signed field counting instruction words,
  // so the reach in bytes is two bits wider than the field.
  unsigned Bits;
  switch (BranchOpc) {
  case LVX::CCB_CCB:     Bits = 11; break;  // pcrel11s2
  case LVX::CB_CB:       Bits = 17; break;  // pcrel17s2
  case LVX::GOTO_UB:
  case LVX::CALL_UB:     Bits = 27; break;  // pcrel27s2
  case LVX::CCBX_CCB_X:  Bits = 38; break;  // pcrel38s2
  case LVX::CBX_CB_X:    Bits = 44; break;  // pcrel44s2
  case LVX::GOTOX_UB_X:
  case LVX::CALLX_UB_X:  Bits = 54; break;  // pcrel54s2
  default:
    llvm_unreachable("not a PC-relative LVX branch");
  }
  return isIntN(Bits + 2, BrOffset);
}

// The widened-immediate chains, generated from the machine description: one
// row per encoding of an instruction that has more than one, narrowest first,
// as (narrow opcode, this form's opcode, immediate bits).
namespace {
struct ImmediateForm {
  unsigned Narrow;
  unsigned Form;
  unsigned Bits;
};
} // namespace

static const ImmediateForm ImmediateForms[] = {
#define LVX_IMMEDIATE_FORM(Narrow, Form, Bits) {LVX::Narrow, LVX::Form, Bits},
#include "LVXImmediateExtensions.inc"
#undef LVX_IMMEDIATE_FORM
};

unsigned LVXInstrInfo::getFormForImmediate(unsigned Opc, int64_t Imm) {
  // Accept any form of an instruction, not just the narrow one: a caller that
  // is re-deciding the width of an instruction it did not select itself -- as
  // eliminateFrameIndex does -- should not have to know which form it is
  // looking at. Every row names its chain's narrow opcode, so one pass over
  // the table canonicalizes.
  unsigned NarrowOpc = Opc;
  for (const ImmediateForm &F : ImmediateForms)
    if (F.Form == Opc) {
      NarrowOpc = F.Narrow;
      break;
    }

  // The rows of one chain are contiguous and ordered narrowest-first, so the
  // first match is the shortest encoding that holds Imm.
  bool HasChain = false;
  for (const ImmediateForm &F : ImmediateForms) {
    if (F.Narrow != NarrowOpc)
      continue;
    HasChain = true;
    if (isIntN(F.Bits, Imm))
      return F.Form;
  }
  // Either nothing in the chain was wide enough, or the instruction has no
  // widened forms at all. Both mean the same thing to a caller: this
  // instruction cannot hold Imm, so materialize it some other way. Returning
  // Opc for the second case would be a trap -- it reads as success and would
  // leave an out-of-range immediate in the instruction.
  (void)HasChain;
  return 0;
}

void LVXInstrInfo::loadImmediate(MachineBasicBlock &MBB,
                                 MachineBasicBlock::iterator MI,
                                 const DebugLoc &DL, Register DestReg,
                                 int64_t Imm) const {
  unsigned Opc = getFormForImmediate(LVX::MAKED_DWI, Imm);
  BuildMI(MBB, MI, DL, get(Opc), DestReg).addImm(Imm);
}
