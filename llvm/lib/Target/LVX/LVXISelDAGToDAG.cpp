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
                       SDValue &Base, SDValue &Offset, bool &IsFrameIndex) {
  IsFrameIndex = false;

  if (auto *FIN = dyn_cast<FrameIndexSDNode>(Addr)) {
    Base = CurDAG->getTargetFrameIndex(FIN->getIndex(), Addr.getValueType());
    Offset = CurDAG->getTargetConstant(0, DL, MVT::i64);
    IsFrameIndex = true;
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
      IsFrameIndex = true;
      return true;
    }

    // A genuine runtime register base gets no later fixup, so the encoding
    // has to hold this displacement as it stands -- but "as it stands" is not
    // limited to simm10: the widened forms of the same load or store take 37
    // and 64 bits of offset, and selectLoadStoreOpcode below picks whichever
    // is narrowest for Off. Only a displacement no encoding can hold is
    // rejected here, which for a 64-bit form means none.
    Base = Lhs;
    Offset = CurDAG->getTargetConstant(Off, DL, MVT::i64);
    return true;
  }

  Base = Addr;
  Offset = CurDAG->getTargetConstant(0, DL, MVT::i64);
  return true;
}

// The encoding of a base+offset load or store to use for displacement Off.
//
// A FrameIndex keeps the narrow form: its real displacement is not known
// until PEI runs, and LVXRegisterInfo::eliminateFrameIndex widens the
// instruction then, against the final value. Widening here on the residual
// constant would be guesswork, and would leave PEI a widened opcode to
// re-widen.
//
// A runtime base is final now, so this picks the narrowest form that holds
// Off -- the same widened encodings the frame code uses, reached from the
// other direction.
static unsigned selectLoadStoreOpcode(unsigned NarrowOpc, SDValue Offset,
                                      bool IsFrameIndex) {
  if (IsFrameIndex)
    return NarrowOpc;
  int64_t Off = cast<ConstantSDNode>(Offset)->getSExtValue();
  if (isInt<10>(Off))
    return NarrowOpc;
  return LVXInstrInfo::getFormForImmediate(NarrowOpc, Off);
}

// ---- Conditional branches --------------------------------------------------
//
// LVX branches on a comparison directly, so a BR_CC becomes ONE instruction:
//
//   cb.<bcucond>  $rZ ? target          BCU_CB,  a test of one register
//                                       against zero, 17-bit displacement
//   ccb.<ccbcomp> $rZ, $rY ? target     BCU_CCB, a comparison of two
//                                       registers, 11-bit displacement
//
// Both compare in printed order -- "ccb.dlt $rZ, $rY" branches when
// rZ < rY -- confirmed against the machine description's ccbcomp/bcucond
// helper semantics.

// The bcucond code for "$rZ <CC> 0", or -1 when CB cannot express it.
static int getBcucondForZero(ISD::CondCode CC) {
  switch (CC) {
  case ISD::SETLT:  return 0;  // .dltz
  case ISD::SETGE:  return 1;  // .dgez
  case ISD::SETLE:  return 2;  // .dlez
  case ISD::SETGT:  return 3;  // .dgtz
  case ISD::SETEQ:  return 4;  // .deqz
  case ISD::SETNE:  return 5;  // .dnez
  // Unsigned against zero degenerates: x >u 0 is x != 0, x <=u 0 is x == 0.
  // (x <u 0 and x >=u 0 are constants and never reach here.)
  case ISD::SETUGT: return 5;  // .dnez
  case ISD::SETULE: return 4;  // .deqz
  default:          return -1;
  }
}

// The ccbcomp code for "$rZ <CC> $rY", or -1. ccbcomp's 64-bit half has only
// lt/ge/ltu/geu/eq/ne (codes 0-7 also cover the bitwise any/none tests), so
// the four remaining relations are reached by swapping the operands -- which
// is what Swap reports.
static int getCcbcompCode(ISD::CondCode CC, bool &Swap) {
  Swap = false;
  switch (CC) {
  case ISD::SETLT:  return 0;  // .dlt
  case ISD::SETGE:  return 1;  // .dge
  case ISD::SETULT: return 2;  // .dltu
  case ISD::SETUGE: return 3;  // .dgeu
  case ISD::SETEQ:  return 4;  // .deq
  case ISD::SETNE:  return 5;  // .dne
  // a > b is b < a, a <= b is b >= a, and likewise unsigned.
  case ISD::SETGT:  Swap = true; return 0;
  case ISD::SETLE:  Swap = true; return 1;
  case ISD::SETUGT: Swap = true; return 2;
  case ISD::SETULE: Swap = true; return 3;
  default:          return -1;
  }
}

// The intcomp code for "$rZ <CC> $rY". Unlike ccbcomp, intcomp has all twelve
// relations, so COMPD never needs its operands swapped.
static int getIntcompCode(ISD::CondCode CC) {
  switch (CC) {
  case ISD::SETLT:  return 0;   // .lt
  case ISD::SETGE:  return 1;   // .ge
  case ISD::SETULT: return 2;   // .ltu
  case ISD::SETUGE: return 3;   // .geu
  case ISD::SETEQ:  return 4;   // .eq
  case ISD::SETNE:  return 5;   // .ne
  case ISD::SETLE:  return 8;   // .le
  case ISD::SETGT:  return 9;   // .gt
  case ISD::SETULE: return 10;  // .leu
  case ISD::SETUGT: return 11;  // .gtu
  default:          return -1;
  }
}

static bool isNullConstant(SDValue V) {
  auto *C = dyn_cast<ConstantSDNode>(V);
  return C && C->isZero();
}

void LVXDAGToDAGISel::Select(SDNode *N) {
  SDLoc DL(N);

  // ISD::BR_CC → cb (against zero) or ccb (register against register).
  // Operands are (Chain, CondCode, LHS, RHS, Dest).
  // ISD::ConstantFP -> a MAKE of the value's raw bit pattern. There is no FP
  // immediate form and no constant pool in use here; since FP shares the GPR
  // file, loading the bits IS loading the value. Integer constants are
  // handled declaratively in LVXInstrInfo.td, but an FP one cannot be: the
  // pattern would have to match an arbitrary 64-bit encoding.
  if (N->getOpcode() == ISD::ConstantFP) {
    auto *CFP = cast<ConstantFPSDNode>(N);
    EVT VT = N->getValueType(0);
    APInt Bits = CFP->getValueAPF().bitcastToAPInt();
    int64_t Val = VT == MVT::f32 ? (int64_t)Bits.getZExtValue()
                                 : (int64_t)Bits.getSExtValue();
    unsigned Opc = isInt<16>(Val) ? LVX::MAKED_DWI
                 : isInt<43>(Val) ? LVX::MAKED_DWI_X
                                  : LVX::MAKED_DWI_Y;
    SDValue Imm = CurDAG->getTargetConstant(Val, DL, MVT::i64);
    SDNode *Res = CurDAG->getMachineNode(Opc, DL, VT, Imm);
    ReplaceNode(N, Res);
    return;
  }

  if (N->getOpcode() == ISD::BR_CC) {
    ISD::CondCode CC = cast<CondCodeSDNode>(N->getOperand(1))->get();
    SDValue LHS = N->getOperand(2);
    SDValue RHS = N->getOperand(3);
    SDValue Dest = N->getOperand(4);
    SDValue Chain = N->getOperand(0);

    // Against a zero on either side, the one-register test is enough. When
    // the zero is on the left the relation has to be mirrored first, since
    // cb always tests its register: "0 < x" is "x > 0".
    SDValue Tested;
    ISD::CondCode ZeroCC = CC;
    if (isNullConstant(RHS)) {
      Tested = LHS;
    } else if (isNullConstant(LHS)) {
      Tested = RHS;
      ZeroCC = ISD::getSetCCSwappedOperands(CC);
    } else if (auto *C = dyn_cast<ConstantSDNode>(RHS)) {
      // DAGCombine canonicalizes a strict comparison against zero into a
      // non-strict one against the adjacent constant -- "x > 0" arrives as
      // "x < 1", "x < 0" as "x > -1". Undoing that is what keeps those, the
      // two most common loop and sign tests, on the one-register cb rather
      // than costing a maked to build the constant for a ccb.
      if (CC == ISD::SETLT && C->getSExtValue() == 1) {
        Tested = LHS;
        ZeroCC = ISD::SETLE;                     // x < 1  is  x <= 0
      } else if (CC == ISD::SETGT && C->getSExtValue() == -1) {
        Tested = LHS;
        ZeroCC = ISD::SETGE;                     // x > -1  is  x >= 0
      }
    }

    if (Tested) {
      if (int Cond = getBcucondForZero(ZeroCC), Ok = Cond >= 0; Ok) {
        SDValue Ops[] = {CurDAG->getTargetConstant(Cond, DL, MVT::i32), Tested,
                         Dest, Chain};
        ReplaceNode(N, CurDAG->getMachineNode(LVX::CB_CB, DL, MVT::Other, Ops));
        return;
      }
    }

    bool Swap;
    if (int Cmp = getCcbcompCode(CC, Swap); Cmp >= 0) {
      SDValue Ops[] = {CurDAG->getTargetConstant(Cmp, DL, MVT::i32),
                       Swap ? RHS : LHS, Swap ? LHS : RHS, Dest, Chain};
      ReplaceNode(N, CurDAG->getMachineNode(LVX::CCB_CCB, DL, MVT::Other, Ops));
      return;
    }
  }

  // ISD::BRCOND → "cb.dnez $cond ? target". This is the branch on a value
  // that is not itself a comparison (a loaded bool, a phi of i1); a BRCOND
  // whose condition IS a comparison is folded into BR_CC before selection.
  if (N->getOpcode() == ISD::BRCOND) {
    SDValue Ops[] = {CurDAG->getTargetConstant(5, DL, MVT::i32), // .dnez
                     N->getOperand(1), N->getOperand(2), N->getOperand(0)};
    ReplaceNode(N, CurDAG->getMachineNode(LVX::CB_CB, DL, MVT::Other, Ops));
    return;
  }

  // ISD::SETCC → "compd.<intcomp> $rW = $rZ, $rY", producing 0 or 1 in a
  // register. This is the comparison used as a value rather than branched on.
  if (N->getOpcode() == ISD::SETCC) {
    ISD::CondCode CC = cast<CondCodeSDNode>(N->getOperand(2))->get();
    if (int Cmp = getIntcompCode(CC); Cmp >= 0) {
      SDValue Cmp32 = CurDAG->getTargetConstant(Cmp, DL, MVT::i32);

      // A constant right-hand side goes straight into compd's widened form
      // (ALU_DCWRR.W, which replaces the register operand with a 32-bit
      // immediate) rather than being materialized with a maked first. Same
      // total size, one instruction instead of two.
      if (auto *C = dyn_cast<ConstantSDNode>(N->getOperand(1));
          C && isInt<32>(C->getSExtValue())) {
        SDValue Imm =
            CurDAG->getTargetConstant(C->getSExtValue(), DL, MVT::i64);
        SDValue Ops[] = {N->getOperand(0), Imm, Cmp32};
        ReplaceNode(N, CurDAG->getMachineNode(LVX::COMPD_DCWRR_W, DL,
                                              MVT::i64, Ops));
        return;
      }

      SDValue Ops[] = {N->getOperand(0), N->getOperand(1), Cmp32};
      ReplaceNode(N, CurDAG->getMachineNode(LVX::COMPD_DCWRR, DL, MVT::i64,
                                            Ops));
      return;
    }
  }

  // ISD::BUILD_PAIR (i128 from two i64 halves) → CATDQ.
  // LowerFormalArguments produces BUILD_PAIR when reassembling an i128
  // argument from its two i64 CC slots. CATDQ is the single LVX instruction
  // that assembles an aligned GPR128 pair from two arbitrary GPR sources:
  // "catdq $rM = $rZ, $rY", where the first source ($rZ) is the low 64 bits
  // and the second ($rY) the high -- see emitCatDQ in LVXInstrInfo.cpp.
  if (N->getOpcode() == ISD::BUILD_PAIR &&
      N->getValueType(0) == MVT::i128) {
    SDValue Lo = N->getOperand(0); // low 64 bits  (rZ)
    SDValue Hi = N->getOperand(1); // high 64 bits (rY)
    SDNode *Res = CurDAG->getMachineNode(LVX::CATDQ_CATDQ, DL, MVT::i128, Lo, Hi);
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
    SDValue E0 = N->getOperand(0); // sub_pair_hi low64  (rZ of first  CATDQ)
    SDValue E1 = N->getOperand(1); // sub_pair_hi high64 (rY of first  CATDQ)
    SDValue E2 = N->getOperand(2); // sub_pair_lo low64  (rZ of second CATDQ)
    SDValue E3 = N->getOperand(3); // sub_pair_lo high64 (rY of second CATDQ)

    SDNode *LoPair = CurDAG->getMachineNode(LVX::CATDQ_CATDQ, DL, MVT::i128, E0, E1);
    SDNode *HiPair = CurDAG->getMachineNode(LVX::CATDQ_CATDQ, DL, MVT::i128, E2, E3);

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

  // ISD::FrameIndex used as a plain VALUE -- taking a local's address, or
  // passing an array to a function -- rather than as a load/store base (that
  // case is folded into the addressing mode by selectAddr and never reaches
  // here). ADDD_DWRI computes "$rW = $rZ + imm", so the frame index fills the
  // $rZ slot with offset 0; PEI later rewrites that operand to the real frame
  // register and the 0 to the true offset (widening the encoding if it does
  // not fit simm10), turning this into a real address computation.
  if (N->getOpcode() == ISD::FrameIndex) {
    int FI = cast<FrameIndexSDNode>(N)->getIndex();
    SDValue TFI = CurDAG->getTargetFrameIndex(FI, N->getValueType(0));
    SDValue Zero = CurDAG->getTargetConstant(0, DL, MVT::i64);
    SDNode *Res =
        CurDAG->getMachineNode(LVX::ADDD_DWRI, DL, MVT::i64, TFI, Zero);
    ReplaceNode(N, Res);
    return;
  }

  // ISD::GlobalAddress used as a plain VALUE -- any &global reference that is
  // not a direct CALL callee (that case is handled in the LVXISD::CALL block
  // below). MAKED_DWI_Y unconditionally, not the narrower MAKED_DWI/_X: a
  // link-time symbol's address is not known at compile time and so cannot be
  // range-checked into the shorter forms the way a literal constant can.
  // LVXMCInstLower's MO_GlobalAddress case turns it into a real symbol
  // reference in the assembly.
  if (N->getOpcode() == ISD::GlobalAddress) {
    auto *GA = cast<GlobalAddressSDNode>(N);
    SDValue Sym = CurDAG->getTargetGlobalAddress(GA->getGlobal(), DL, MVT::i64,
                                                 GA->getOffset());
    SDNode *Res = CurDAG->getMachineNode(LVX::MAKED_DWI_Y, DL, MVT::i64, Sym);
    ReplaceNode(N, Res);
    return;
  }

  // ISD::SDIVREM / UDIVREM -> DIVMODD / DIVMODUD plus two subregister reads.
  //
  // Declared Legal in LVXTargetLowering rather than Custom/Expand, and
  // selected here by hand: one instruction produces a single 128-bit paired
  // result feeding two independent 64-bit values, a shape TableGen patterns
  // express poorly.
  //
  // Result layout, per Instruction.yml's DIVMODD/DIVMODUD execution:
  //   result1.64[0] = quotient    result1.64[1] = remainder
  // and .64[0] is the architecturally LOW half of the pair, which in this
  // target's (confusingly named) subregister indices is sub_hi -- the one
  // declared at bit offset 0, SubRegIndex<64, 0>, i.e. the even/lower-
  // numbered GPR of the pair. So quotient = sub_hi, remainder = sub_lo;
  // swapping them silently exchanges "/" and "%".
  //
  // Operand order needs equal care, and is NOT what the pre-MDS back end
  // used. The generated ALU_DDMWRR_Inst is
  //     (outs GPR128:$rM), (ins GPR:$rZ, GPR:$rY)    "$rM = $rZ, $rY"
  // and the ISA makes $rZ (%2, argument2) the dividend and $rY (%3,
  // argument3) the divisor -- so the machine node takes (dividend, divisor),
  // the order the assembly reads. The hand-written description this was
  // recovered from declared (ins GPR:$rY, GPR:$rZ), the reverse, and passed
  // (divisor, dividend) to match it; replaying that verbatim here would
  // silently compute b/a for every division.
  if (N->getOpcode() == ISD::SDIVREM || N->getOpcode() == ISD::UDIVREM) {
    bool IsSigned = N->getOpcode() == ISD::SDIVREM;
    unsigned Opc = IsSigned ? LVX::DIVMODD_DDMWRR : LVX::DIVMODUD_DDMWRR;
    SDValue Dividend = N->getOperand(0);
    SDValue Divisor = N->getOperand(1);

    SDNode *Pair =
        CurDAG->getMachineNode(Opc, DL, MVT::i128, Dividend, Divisor);
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

  // ISD::JumpTable -> MAKED_DWI_Y of the table's base address. The table
  // symbol is a link-time address whose value is unknown at compile time, so
  // the widest MAKE form is used unconditionally -- the same reasoning as the
  // wimm64imm pattern in LVXInstrInfo.td, just with a symbol in place of a
  // constant. The BR_JT that referenced it has already been expanded (it is
  // declared Expand in LVXTargetLowering) into this base, a scaled index, a
  // load and an ISD::BRIND -- so all that survives here is an ordinary
  // address materialization.
  if (N->getOpcode() == ISD::JumpTable) {
    auto *JT = cast<JumpTableSDNode>(N);
    SDValue TJT = CurDAG->getTargetJumpTable(JT->getIndex(), MVT::i64);
    SDNode *Res = CurDAG->getMachineNode(LVX::MAKED_DWI_Y, DL, MVT::i64, TJT);
    ReplaceNode(N, Res);
    return;
  }

  // Standard ISD::LOAD → LD (64-bit), LWZ/LWS (32-bit), LHZ/LHS (16-bit),
  // LBZ/LBS (8-bit). All with variant=0 (normal/non-speculative). Base+offset
  // addressing (register or FrameIndex, per selectAddr above) both handled.
  if (N->getOpcode() == ISD::LOAD) {
    auto *LD = cast<LoadSDNode>(N);
    SDValue Base, Offset;
    bool IsFrameIndex;

    if (selectAddr(CurDAG, DL, LD->getBasePtr(), Base, Offset, IsFrameIndex)) {
      ISD::LoadExtType Ext = LD->getExtensionType();
      EVT MemVT = LD->getMemoryVT();
      unsigned Opc = 0;
      // f64/f32 live in GPRs, so an FP load is the same LD/LWZ as the integer
      // one of the same width -- only the value type differs. The f32 case is
      // restricted to non-extending loads: an f32->f64 EXTLOAD needs a real
      // FWIDENWD after the load and is declared Expand in LVXTargetLowering,
      // so matching it here as a bare LWZ would silently drop the conversion.
      if      (MemVT == MVT::i64 || MemVT == MVT::f64)        Opc = LVX::LD_LSBO;
      else if (MemVT == MVT::f32 && Ext == ISD::NON_EXTLOAD)  Opc = LVX::LWZ_LSBO;
      else if (MemVT == MVT::i32 && Ext != ISD::SEXTLOAD)    Opc = LVX::LWZ_LSBO;
      else if (MemVT == MVT::i32 && Ext == ISD::SEXTLOAD)    Opc = LVX::LWS_LSBO;
      else if (MemVT == MVT::i16 && Ext != ISD::SEXTLOAD)    Opc = LVX::LHZ_LSBO;
      else if (MemVT == MVT::i16 && Ext == ISD::SEXTLOAD)    Opc = LVX::LHS_LSBO;
      else if (MemVT == MVT::i8  && Ext != ISD::SEXTLOAD)    Opc = LVX::LBZ_LSBO;
      else if (MemVT == MVT::i8  && Ext == ISD::SEXTLOAD)    Opc = LVX::LBS_LSBO;

      Opc = Opc ? selectLoadStoreOpcode(Opc, Offset, IsFrameIndex) : 0;

      if (Opc) {
        // Generated LSU_LSBO_Inst operand order: off, base, variant.
        SDValue Var  = CurDAG->getTargetConstant(0, DL, MVT::i32); // variant=0
        SDValue Ops[] = {Offset, Base, Var, LD->getChain()};
        // Result type from the node, not a hardcoded i64: an f32/f64 load
        // produces an f32/f64 value, and replacing it with an i64-typed
        // machine node trips ReplaceAllUsesWith's "Cannot use this version"
        // assertion. Extending integer loads already have node type i64.
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
    bool IsFrameIndex;

    if (selectAddr(CurDAG, DL, ST->getBasePtr(), Base, Offset, IsFrameIndex)) {
      EVT MemVT = ST->getMemoryVT();
      unsigned Opc = 0;
      if      (MemVT == MVT::i64 || MemVT == MVT::f64) Opc = LVX::SD_SSBO;
      else if (MemVT == MVT::f32) Opc = LVX::SW_SSBO;
      else if (MemVT == MVT::i32) Opc = LVX::SW_SSBO;
      else if (MemVT == MVT::i16) Opc = LVX::SH_SSBO;
      else if (MemVT == MVT::i8)  Opc = LVX::SB_SSBO;

      Opc = Opc ? selectLoadStoreOpcode(Opc, Offset, IsFrameIndex) : 0;

      if (Opc) {
        // Generated LSU_SSBO_Inst operand order: off, base, stored value.
        SDValue Ops[] = {Offset, Base, ST->getValue(), ST->getChain()};
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
      Opc = LVX::CALL_UB;
    } else if (auto *ES = dyn_cast<ExternalSymbolSDNode>(Callee)) {
      Ops.push_back(
          CurDAG->getTargetExternalSymbol(ES->getSymbol(), MVT::i64));
      Opc = LVX::CALL_UB;
    } else {
      Ops.push_back(Callee);
      Opc = LVX::ICALL_IBC;
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
