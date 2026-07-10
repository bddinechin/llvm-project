//===-- LVXISelDAGToDAG.cpp - LVX DAG-to-DAG Instruction Selector -------===//
//
// Phase 3 stub. SelectCode (the auto-generated table matcher from
// LVXGenDAGISel.inc) handles every pattern currently defined in
// LVXInstrInfo.td. None of the deferred custom-selection cases (CALL vs
// ICALL dispatch, LWZ/LWS/LD variant-modifier defaulting, CLSD) are
// implemented yet -- IR that would need them simply won't select
// correctly until this is filled in.
//
//===----------------------------------------------------------------------===//

#include "LVXISelDAGToDAG.h"
#include "LVXInstrInfo.h"
#include "LVXRegisterInfo.h"
#include "LVXSubtarget.h"
#include "llvm/CodeGen/SelectionDAGISel.h"
#include "llvm/CodeGen/SelectionDAGNodes.h"
#include "llvm/Support/MathExtras.h"

using namespace llvm;

char LVXDAGToDAGISel::ID = 0;

#define GET_DAGISEL_BODY LVXDAGToDAGISel
#include "LVXGenDAGISel.inc"

// Recognizes the addressing modes every LSU_*BO_Inst base+offset operand
// pair accepts: a bare FrameIndex (treated as FrameIndex+0), a FrameIndex
// plus an in-range constant offset, a register plus an in-range constant
// offset, or a bare register (offset 0). Modeled on Lanai's
// selectAddrRi/selectFrameIndex (LanaiISelDAGToDAG.cpp) -- the frame-index
// case is what lets PrologEpilogInserter later find and call
// eliminateFrameIndex on the resulting MachineInstr, since the target frame
// index becomes a real operand rather than falling through unselected.
static bool selectAddr(SelectionDAG *CurDAG, const SDLoc &DL, SDValue Addr,
                       SDValue &Base, SDValue &Offset) {
  if (auto *FIN = dyn_cast<FrameIndexSDNode>(Addr)) {
    Base = CurDAG->getTargetFrameIndex(FIN->getIndex(), Addr.getValueType());
    Offset = CurDAG->getTargetConstant(0, DL, MVT::i64);
    return true;
  }

  if (Addr.getOpcode() == ISD::ADD &&
      isa<ConstantSDNode>(Addr.getOperand(1))) {
    int64_t Off = cast<ConstantSDNode>(Addr.getOperand(1))->getSExtValue();
    SDValue Lhs = Addr.getOperand(0);

    if (auto *FIN = dyn_cast<FrameIndexSDNode>(Lhs)) {
      // A FrameIndex's true address isn't known until PEI runs --
      // eliminateFrameIndex combines MFI.getObjectOffset(FI) with this
      // residual constant and range-checks/scavenges on the FINAL
      // offset (LVXRegisterInfo::eliminateFrameIndex). Rejecting a
      // large residual here would be premature: e.g. indexing near the
      // end of a large local array produces exactly this shape (a
      // FrameIndex + an offset that alone may already exceed simm10).
      Base = CurDAG->getTargetFrameIndex(FIN->getIndex(), Lhs.getValueType());
      Offset = CurDAG->getTargetConstant(Off, DL, MVT::i64);
      return true;
    }

    // A genuine runtime register base has no later fixup pass, so the
    // offset must already fit simm10.
    if (!isInt<10>(Off))
      return false;
    Base = Lhs;
    Offset = CurDAG->getTargetConstant(Off, DL, MVT::i64);
    return true;
  }

  Base = Addr;
  Offset = CurDAG->getTargetConstant(0, DL, MVT::i64);
  return true;
}

void LVXDAGToDAGISel::Select(SDNode *N) {
  SDLoc DL(N);

  // ISD::BUILD_PAIR (i128 from two i64 halves) → CATDQ.
  // LowerFormalArguments produces BUILD_PAIR when reassembling an i128
  // argument from its two i64 CC slots. CATDQ is the single LVX instruction
  // that assembles an aligned GPR128 pair from two arbitrary GPR sources:
  // "catdq $rM = $rY, $rZ" where $rY is the low 64 bits and $rZ the high.
  if (N->getOpcode() == ISD::BUILD_PAIR &&
      N->getValueType(0) == MVT::i128) {
    SDValue Lo = N->getOperand(0); // low 64 bits (rY)
    SDValue Hi = N->getOperand(1); // high 64 bits (rZ)
    SDNode *Res = CurDAG->getMachineNode(LVX::CATDQ, DL, MVT::i128, Lo, Hi);
    ReplaceNode(N, Res);
    return;
  }

  // ISD::BUILD_VECTOR for v4i64 → two CATDQs (forming two GPR128 halves)
  // then REG_SEQUENCE to place them into a GPR256.
  // Layout (confirmed ABI + sub_hi/sub_lo semantics):
  //   sub_pair_hi (offset 0, architectural low)  = elements [0] (low64), [1] (high64)
  //   sub_pair_lo (offset 128, architectural high) = elements [2] (low64), [3] (high64)
  if (N->getOpcode() == ISD::BUILD_VECTOR &&
      N->getValueType(0) == MVT::v4i64) {
    SDValue E0 = N->getOperand(0); // sub_pair_hi low64  (rY of first  CATDQ)
    SDValue E1 = N->getOperand(1); // sub_pair_hi high64 (rZ of first  CATDQ)
    SDValue E2 = N->getOperand(2); // sub_pair_lo low64  (rY of second CATDQ)
    SDValue E3 = N->getOperand(3); // sub_pair_lo high64 (rZ of second CATDQ)

    SDNode *LoPair = CurDAG->getMachineNode(LVX::CATDQ, DL, MVT::i128, E0, E1);
    SDNode *HiPair = CurDAG->getMachineNode(LVX::CATDQ, DL, MVT::i128, E2, E3);

    // Assemble the two GPR128 halves into a GPR256 via REG_SEQUENCE.
    // REG_SEQUENCE takes: RegClass, val0, subreg0, val1, subreg1, ...
    SDValue RegClass =
        CurDAG->getTargetConstant(LVX::GPR256RegClassID, DL, MVT::i32);
    SDValue SubLo = CurDAG->getTargetConstant(sub_pair_hi, DL, MVT::i32);
    SDValue SubHi = CurDAG->getTargetConstant(sub_pair_lo, DL, MVT::i32);
    SDValue Ops[] = {RegClass,
                     SDValue(LoPair, 0), SubLo,
                     SDValue(HiPair, 0), SubHi};
    SDNode *Res = CurDAG->getMachineNode(TargetOpcode::REG_SEQUENCE, DL,
                                         MVT::v4i64, Ops);
    ReplaceNode(N, Res);
    return;
  }

  // Standard ISD::LOAD → LD (64-bit), LWZ/LWS (32-bit), LHZ/LHS (16-bit),
  // LBZ/LBS (8-bit). All with variant=0 (normal/non-speculative). Base+offset
  // addressing (register or FrameIndex, per selectAddr above) both handled.
  if (N->getOpcode() == ISD::LOAD) {
    auto *LD = cast<LoadSDNode>(N);
    SDValue Base, Offset;

    if (selectAddr(CurDAG, DL, LD->getBasePtr(), Base, Offset)) {
      ISD::LoadExtType Ext = LD->getExtensionType();
      EVT MemVT = LD->getMemoryVT();
      unsigned Opc = 0;
      if      (MemVT == MVT::i64)                             Opc = LVX::LD;
      else if (MemVT == MVT::i32 && Ext != ISD::SEXTLOAD)    Opc = LVX::LWZ;
      else if (MemVT == MVT::i32 && Ext == ISD::SEXTLOAD)    Opc = LVX::LWS;
      else if (MemVT == MVT::i16 && Ext != ISD::SEXTLOAD)    Opc = LVX::LHZ;
      else if (MemVT == MVT::i16 && Ext == ISD::SEXTLOAD)    Opc = LVX::LHS;
      else if (MemVT == MVT::i8  && Ext != ISD::SEXTLOAD)    Opc = LVX::LBZ;
      else if (MemVT == MVT::i8  && Ext == ISD::SEXTLOAD)    Opc = LVX::LBS;

      if (Opc) {
        SDValue Var  = CurDAG->getTargetConstant(0, DL, MVT::i32); // variant=0
        SDValue Ops[] = {Var, Offset, Base, LD->getChain()};
        SDNode *Res = CurDAG->getMachineNode(Opc, DL, MVT::i64, MVT::Other, Ops);
        CurDAG->setNodeMemRefs(cast<MachineSDNode>(Res), {LD->getMemOperand()});
        ReplaceNode(N, Res);
        return;
      }
    }
  }

  // Standard ISD::STORE → SD (64-bit), SW (32-bit), SH (16-bit), SB (8-bit).
  // No variant field on stores (LSU_SSBO_Inst has none). Mirrors the LOAD
  // case above, including FrameIndex-based addressing -- this is what makes
  // spilling a local (an alloca'd or register-allocator-spilled i64/i32/
  // i16/i8) to the stack actually selectable instead of crashing.
  if (N->getOpcode() == ISD::STORE) {
    auto *ST = cast<StoreSDNode>(N);
    SDValue Base, Offset;

    if (selectAddr(CurDAG, DL, ST->getBasePtr(), Base, Offset)) {
      EVT MemVT = ST->getMemoryVT();
      unsigned Opc = 0;
      if      (MemVT == MVT::i64) Opc = LVX::SD;
      else if (MemVT == MVT::i32) Opc = LVX::SW;
      else if (MemVT == MVT::i16) Opc = LVX::SH;
      else if (MemVT == MVT::i8)  Opc = LVX::SB;

      if (Opc) {
        SDValue Ops[] = {ST->getValue(), Offset, Base, ST->getChain()};
        SDNode *Res = CurDAG->getMachineNode(Opc, DL, MVT::Other, Ops);
        CurDAG->setNodeMemRefs(cast<MachineSDNode>(Res), {ST->getMemOperand()});
        ReplaceNode(N, Res);
        return;
      }
    }
  }

  // LVXISD::CALL → CALL (direct, GlobalAddress/ExternalSymbol callee) or
  // ICALL (indirect, register callee). LVXTargetLowering::LowerCall builds
  // this node's operand list as [Chain, Callee, one DAG.getRegister(...)
  // per outgoing argument register, optional Glue] (SDNPHasChain puts
  // Chain first on the source node); the MachineSDNode built below must
  // reorder that into InstrEmitter's expected [explicit target operand,
  // implicit physreg uses..., Chain, Glue] shape (see countOperands() in
  // InstrEmitter.cpp) -- the physreg operands become implicit uses on the
  // selected CALL/ICALL MachineInstr purely from trailing in that slot,
  // not from anything declared in LVXInstrInfo.td.
  if (N->getOpcode() == LVXISD::CALL) {
    SDValue Chain = N->getOperand(0);
    SDValue Callee = N->getOperand(1);
    unsigned NumOps = N->getNumOperands();
    bool HasGlue = N->getOperand(NumOps - 1).getValueType() == MVT::Glue;

    SmallVector<SDValue, 8> Ops;
    unsigned Opc;
    if (auto *GA = dyn_cast<GlobalAddressSDNode>(Callee)) {
      Ops.push_back(CurDAG->getTargetGlobalAddress(
          GA->getGlobal(), DL, MVT::i64, GA->getOffset()));
      Opc = LVX::CALL;
    } else if (auto *ES = dyn_cast<ExternalSymbolSDNode>(Callee)) {
      Ops.push_back(
          CurDAG->getTargetExternalSymbol(ES->getSymbol(), MVT::i64));
      Opc = LVX::CALL;
    } else {
      Ops.push_back(Callee);
      Opc = LVX::ICALL;
    }

    for (unsigned i = 2, e = NumOps - (HasGlue ? 1 : 0); i != e; ++i)
      Ops.push_back(N->getOperand(i));
    Ops.push_back(Chain);
    if (HasGlue)
      Ops.push_back(N->getOperand(NumOps - 1));

    SDNode *Res = CurDAG->getMachineNode(Opc, DL, N->getVTList(), Ops);
    ReplaceNode(N, Res);
    return;
  }

  SelectCode(N);
}

FunctionPass *llvm::createLVXISelDag(LVXTargetMachine &TM,
                                     CodeGenOptLevel OptLevel) {
  return new SelectionDAGISelLegacy(
      LVXDAGToDAGISel::ID,
      std::make_unique<LVXDAGToDAGISel>(TM, OptLevel));
}
