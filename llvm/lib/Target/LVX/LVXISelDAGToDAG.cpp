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

  // ISD::Constant (Phase 5.3) → MAKE/MAKE_X/MAKE_Y, picking the narrowest
  // that fits, same width tiers as LVXInstrInfo::loadImmediate's BuildMI
  // version of this logic. This is the fallback for any i64 constant that
  // isn't consumed directly by an immediate-embedding pattern (e.g.
  // ADDD_i's simm10imm) -- a bare constant used standalone (returned,
  // compared, multiplied, etc.) has to be materialized into a real
  // register somehow, and this is the only place that happens.
  if (N->getOpcode() == ISD::Constant && N->getValueType(0) == MVT::i64) {
    int64_t Val = cast<ConstantSDNode>(N)->getSExtValue();
    unsigned Opc = isInt<16>(Val) ? LVX::MAKE
                 : isInt<43>(Val) ? LVX::MAKE_X
                                   : LVX::MAKE_Y;
    SDValue Imm = CurDAG->getTargetConstant(Val, DL, MVT::i64);
    SDNode *Res = CurDAG->getMachineNode(Opc, DL, MVT::i64, Imm);
    ReplaceNode(N, Res);
    return;
  }

  // ISD::ConstantFP → the same MAKE/MAKE_X/MAKE_Y ladder as an integer
  // constant, over the value's raw bit pattern. There is no FP immediate form
  // and no constant pool in use here; since FP shares the GPR file, loading
  // the bits IS loading the value. f32 is materialized as its 32-bit encoding
  // zero-extended, which is where f32 values live in a GPR.
  if (N->getOpcode() == ISD::ConstantFP) {
    auto *CFP = cast<ConstantFPSDNode>(N);
    EVT VT = N->getValueType(0);
    APInt Bits = CFP->getValueAPF().bitcastToAPInt();
    int64_t Val = VT == MVT::f32 ? (int64_t)Bits.getZExtValue()
                                 : (int64_t)Bits.getSExtValue();
    unsigned Opc = isInt<16>(Val) ? LVX::MAKE
                 : isInt<43>(Val) ? LVX::MAKE_X
                                  : LVX::MAKE_Y;
    SDValue Imm = CurDAG->getTargetConstant(Val, DL, MVT::i64);
    SDNode *Res = CurDAG->getMachineNode(Opc, DL, VT, Imm);
    ReplaceNode(N, Res);
    return;
  }

  // ISD::FrameIndex (Phase 5.6) → ADDD_i $rW = FI, 0, i.e. materialize the
  // local's address into a register. This is for a FrameIndex used as a
  // plain VALUE (e.g. taking a local's address, or passing an array to a
  // function) rather than as a load/store base (that case is handled
  // inside selectAddr/the LOAD/STORE cases below and never reaches here).
  // ADDD_i's ins order (simm10:$imm, GPR:$rZ) places the offset
  // immediately before the base-register operand -- the FrameIndex here
  // fills that $rZ slot with offset 0 -- which is exactly the "offset
  // precedes base" layout LVXRegisterInfo::eliminateFrameIndex already
  // assumes for every load/store format; PEI later rewrites this FI
  // operand to the real frame register and the 0 to the true offset
  // (falling back to MAKE_X/Y + scavenging via the usual mechanism if it
  // doesn't fit simm10), turning this into a real address computation.
  if (N->getOpcode() == ISD::FrameIndex) {
    int FI = cast<FrameIndexSDNode>(N)->getIndex();
    SDValue TFI = CurDAG->getTargetFrameIndex(FI, N->getValueType(0));
    SDValue Zero = CurDAG->getTargetConstant(0, DL, MVT::i64);
    SDNode *Res = CurDAG->getMachineNode(LVX::ADDD_i, DL, MVT::i64, Zero, TFI);
    ReplaceNode(N, Res);
    return;
  }

  // ISD::GlobalAddress used as a plain VALUE (e.g. the base of a switch
  // lookup table SimplifyCFG materialized, or any other &global reference
  // that isn't a direct CALL callee -- that case is handled separately
  // above). This backend has no MCCodeEmitter, so the real encoding of
  // MAKE_Y's wide immediate is moot (LVXInstrInfo.td's Inst{...}=? bits are
  // explicitly deferred); what matters is that LVXMCInstLower's generic
  // MO_GlobalAddress handling prints this as a real symbol reference, and
  // MAKE_Y is used unconditionally (not the narrower MAKE/MAKE_X) since a
  // link-time symbol address isn't known at compile time and can't be
  // range-checked into those forms the way ISD::Constant's literal value is.
  if (N->getOpcode() == ISD::GlobalAddress) {
    auto *GA = cast<GlobalAddressSDNode>(N);
    SDValue Sym = CurDAG->getTargetGlobalAddress(
        GA->getGlobal(), DL, MVT::i64, GA->getOffset());
    SDNode *Res = CurDAG->getMachineNode(LVX::MAKE_Y, DL, MVT::i64, Sym);
    ReplaceNode(N, Res);
    return;
  }

  // ISD::JumpTable -> MAKE_Y of the table's base address, exactly like
  // ISD::GlobalAddress above: a link-time symbol whose value is unknown at
  // compile time, so the widest MAKE form is used unconditionally. The
  // BR_JT that referenced it has already been expanded (it is declared
  // Expand in LVXTargetLowering) into this base, a scaled index, a load and
  // an ISD::BRIND -- so all that survives here is an ordinary address.
  if (N->getOpcode() == ISD::JumpTable) {
    auto *JT = cast<JumpTableSDNode>(N);
    SDValue TJT = CurDAG->getTargetJumpTable(JT->getIndex(), MVT::i64);
    SDNode *Res = CurDAG->getMachineNode(LVX::MAKE_Y, DL, MVT::i64, TJT);
    ReplaceNode(N, Res);
    return;
  }

  // ISD::SDIVREM / UDIVREM → DIVMODD / DIVMODUD plus two subregister reads.
  //
  // These are declared Legal in LVXTargetLowering (not Custom/Expand) and
  // selected here by hand, because the machine instruction has a shape
  // TableGen patterns express poorly: one instruction, one 128-bit paired
  // result, feeding two independent 64-bit values.
  //
  // Result layout, per Description.yml's DIVMODD/DIVMODUD:
  //   result1.64[0] = quotient    result1.64[1] = remainder
  // and .64[0] is the architecturally LOW half of the pair, which in this
  // target's (confusingly named) subregister indices is sub_hi -- the one
  // at bit offset 0, i.e. the even/lower-numbered GPR of the pair. See the
  // matching note in LVXInstrInfo.cpp's copyPhysReg. So quotient = sub_hi,
  // remainder = sub_lo. Swapping them silently exchanges "/" and "%".
  //
  // Operand order needs the same care. ALU_DDMWRR_Inst is
  // "(ins GPR:$rY, GPR:$rZ)" printed as "$rM = $rZ, $rY", and the ISA makes
  // $rZ the dividend (argument2) and $rY the divisor (argument3). The
  // machine node therefore takes (divisor, dividend) in that order, which
  // is the reverse of how the assembly reads.
  if (N->getOpcode() == ISD::SDIVREM || N->getOpcode() == ISD::UDIVREM) {
    bool IsSigned = N->getOpcode() == ISD::SDIVREM;
    unsigned Opc = IsSigned ? LVX::DIVMODD : LVX::DIVMODUD;
    SDValue Dividend = N->getOperand(0);
    SDValue Divisor = N->getOperand(1);

    SDNode *Pair =
        CurDAG->getMachineNode(Opc, DL, MVT::i128, Divisor, Dividend);
    SDValue PairVal(Pair, 0);

    SDValue Quo =
        CurDAG->getTargetExtractSubreg(sub_hi, DL, MVT::i64, PairVal);
    SDValue Rem =
        CurDAG->getTargetExtractSubreg(sub_lo, DL, MVT::i64, PairVal);

    ReplaceUses(SDValue(N, 0), Quo);
    ReplaceUses(SDValue(N, 1), Rem);
    CurDAG->RemoveDeadNode(N);
    return;
  }

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
      // f64/f32 live in GPRs, so an FP load is the same LD/LWZ as the
      // integer one of the same width -- only the value type differs.
      // FP loads must be non-extending: an f32->f64 EXTLOAD needs a real
      // FWIDENWD after the load, so it is declared Expand in
      // LVXTargetLowering and must never be matched here as a bare LWZ.
      if      (MemVT == MVT::i64 || MemVT == MVT::f64)        Opc = LVX::LD;
      else if (MemVT == MVT::f32 && Ext == ISD::NON_EXTLOAD)  Opc = LVX::LWZ;
      else if (MemVT == MVT::i32 && Ext != ISD::SEXTLOAD)    Opc = LVX::LWZ;
      else if (MemVT == MVT::i32 && Ext == ISD::SEXTLOAD)    Opc = LVX::LWS;
      else if (MemVT == MVT::i16 && Ext != ISD::SEXTLOAD)    Opc = LVX::LHZ;
      else if (MemVT == MVT::i16 && Ext == ISD::SEXTLOAD)    Opc = LVX::LHS;
      else if (MemVT == MVT::i8  && Ext != ISD::SEXTLOAD)    Opc = LVX::LBZ;
      else if (MemVT == MVT::i8  && Ext == ISD::SEXTLOAD)    Opc = LVX::LBS;

      if (Opc) {
        SDValue Var  = CurDAG->getTargetConstant(0, DL, MVT::i32); // variant=0
        SDValue Ops[] = {Var, Offset, Base, LD->getChain()};
        // Result type comes from the node, not a hardcoded i64: an f32/f64
        // load produces an f32/f64 value (the loaded bits land in a GPR
        // either way), and replacing it with an i64-typed machine node trips
        // ReplaceAllUsesWith's "Cannot use this version" assertion. For the
        // extending integer loads the node type is already i64, so this is
        // unchanged for them.
        SDNode *Res = CurDAG->getMachineNode(Opc, DL, N->getValueType(0),
                                             MVT::Other, Ops);
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
      if      (MemVT == MVT::i64 || MemVT == MVT::f64) Opc = LVX::SD;
      else if (MemVT == MVT::f32) Opc = LVX::SW;
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
