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
#include "LVXAddressSpaces.h"
#include "LVXInstrInfo.h"
#include "LVXRegisterInfo.h"
#include "LVXSubtarget.h"
#include "llvm/CodeGen/SelectionDAGISel.h"
#include "llvm/CodeGen/SelectionDAGNodes.h"
#include "llvm/Support/MathExtras.h"
#include <iterator>

using namespace llvm;

char LVXDAGToDAGISel::ID = 0;

#define GET_DAGISEL_BODY LVXDAGToDAGISel
#include "LVXGenDAGISel.inc"

// ---- The load table -------------------------------------------------------
//
// Which load instruction implements a given access is ISA, not policy, and it
// comes from lvx-mds BE/LLVM, which reads it out of each opcode's Behavior:
// the access width is the width of the MEM_load helper call and the extension
// is whichever of SX/ZX wraps it.
//
//   lbs:  (SX.8  (APPLY.8.MEM_load  (READ.address) ...))
//   lwz:  (ZX.32 (APPLY.32.MEM_load (READ.address) ...))
//
// This used to be eight hand-written lines here. They were right, but nothing
// checked them: LWS and LWZ both exist, both assemble, and they differ only in
// the top 32 bits of a value that is usually small, so a swap is silent.
//
// What is NOT in the table is which addressing form to use for a given
// displacement, and the rule that a FrameIndex keeps the narrow form for PEI
// to widen later. That is LLVM plumbing, the same on any target with widened
// encodings, and it stays in selectLoadStoreOpcode below.
namespace {
enum LoadExtension { EXT_SEXT, EXT_ZEXT, EXT_NONE };

// The register class a row loads into or stores from. The width alone does
// not identify a row: lvx-2 has 8/16/32/64-bit loads that SPLAT into a
// GPR256 (lbso, lhso, lwso, ldso) beside the ordinary ones, so ldso and ld
// are both "64, NONE" and differ only here. Keying on the width alone, as
// this did, left the right answer to the order the generator happened to
// emit the rows in.
enum LoadClass { CLASS_GPR, CLASS_GPR128, CLASS_GPR256 };
#define CLASS_GPR_GPR    CLASS_GPR
#define CLASS_GPR_GPR128 CLASS_GPR128
#define CLASS_GPR_GPR256 CLASS_GPR256

struct LoadRow {
  unsigned Bits;
  LoadExtension Ext;
  LoadClass Class;
  unsigned Narrow;      // base+offset, the narrowest displacement
  unsigned Indexed;     // base+index register
};

constexpr LoadRow LoadRows[] = {
#define LVX_LOAD(BITS, EXT, CLASS, BO, BOX, BOY, BI)                           \
  {BITS, EXT_##EXT, CLASS_GPR_##CLASS, LVX::BO, LVX::BI},
#include "LVXMemoryTable.inc"
};

// The widened forms (BOX/BOY above) are deliberately not carried here:
// selectLoadStoreOpcode reaches them through
// LVXInstrInfo::getFormForImmediate, which walks the same generated widening
// chain the frame code uses, so there is one route to them rather than two.

// The narrow base+offset load for an access of Bits bits into register class
// Class, or 0 if the ISA has none. Extension is only meaningful below the
// register width; at 64 bits and above the value fills the register and the
// table says NONE.
unsigned narrowLoadOpcode(unsigned Bits, bool IsSigned, LoadClass Class) {
  LoadExtension Want = Bits >= 64 ? EXT_NONE : IsSigned ? EXT_SEXT : EXT_ZEXT;
  for (const LoadRow &Row : LoadRows)
    if (Row.Bits == Bits && Row.Ext == Want && Row.Class == Class)
      return Row.Narrow;
  return 0;
}

// Stores have no extension column: a store truncates to the width it writes.
struct StoreRow {
  unsigned Bits;
  LoadClass Class;
  unsigned Narrow;
  unsigned Indexed;
};

constexpr StoreRow StoreRows[] = {
#define LVX_STORE(BITS, CLASS, BO, BOX, BOY, BI)                               \
  {BITS, CLASS_GPR_##CLASS, LVX::BO, LVX::BI},
#include "LVXMemoryTable.inc"
};

unsigned narrowStoreOpcode(unsigned Bits, LoadClass Class) {
  for (const StoreRow &Row : StoreRows)
    if (Row.Bits == Bits && Row.Class == Class)
      return Row.Narrow;
  return 0;
}

// The widths this back end SELECTS, as opposed to the ones the table happens
// to carry. Checked at build time because the table is generated and can lose
// a row without anyone noticing until the code is worse or gone: a missing
// 8/16/32/64 row silently costs the ordinary loads and stores, and a missing
// 128/256 row costs lq/sq/lo/so, which is every i128 and v4i64 access.
//
// That is not hypothetical. lq/sq/lo/so are becoming maskable -- their
// bytemask comes from APPLY.maskbytes, fed by a MASKM BCU prefix -- and the
// generator drops any opcode it sees as masked. A prefix is a separate
// instruction, so these keep their operands and, with no MASKM in the bundle,
// maskbytes() yields all-ones and the access is full width: exactly what a
// row promises, and this back end emits no prefixes. If they disappear
// anyway, the build stops here rather than the tests failing later with a
// CHECK line that does not say why.
constexpr bool hasLoad(unsigned Bits, LoadClass Class) {
  for (const LoadRow &Row : LoadRows)
    if (Row.Bits == Bits && Row.Class == Class)
      return true;
  return false;
}
constexpr bool hasStore(unsigned Bits, LoadClass Class) {
  for (const StoreRow &Row : StoreRows)
    if (Row.Bits == Bits && Row.Class == Class)
      return true;
  return false;
}
static_assert(hasLoad(128, CLASS_GPR128) && hasStore(128, CLASS_GPR128),
              "lq/sq went missing: every i128 access selects through them");
static_assert(hasLoad(256, CLASS_GPR256) && hasStore(256, CLASS_GPR256),
              "lo/so went missing: every v4i64 access selects through them");
static_assert(hasLoad(64, CLASS_GPR) && hasStore(64, CLASS_GPR),
              "ld/sd went missing");

// Whether a load or store of MemVT bits can hold a value of type VT in one
// register, which is what lets the width alone pick the instruction. Two
// shapes qualify: the value is exactly what memory holds (an f32 load, a
// 128-bit pair), or it is a whole GPR holding a narrower access extended or
// truncated (the ordinary lbz/lhs/lwz/sb/sh/sw case). Anything else -- a
// 64-bit load whose result is an i128, say -- names a register class the
// instruction does not write, and must go back to the legalizer instead of
// being matched to an instruction of the wrong width.
bool widthAgrees(EVT VT, EVT MemVT) {
  if (VT == MemVT)
    return true;
  return MemVT.getSizeInBits() < 64 && VT == MVT::i64;
}

// A 128- or 256-bit access, whatever type the value has: i128, v2i64 and
// v2f64 all live in one pair and v4i64 in one quad, and the instruction cares
// only which class it writes. Listing the types by name instead meant a new
// legal vector type silently had no load at all.
bool isWideMemVT(EVT VT) {
  unsigned Bits = VT.getSizeInBits();
  return (Bits == 128 || Bits == 256) && (VT.isVector() || VT == MVT::i128);
}

// The register class a value of this type lives in, for the two lookups
// above. Everything 64 bits and under is a GPR: an i32 is loaded into a
// whole register, zero- or sign-extended.
LoadClass classForType(EVT VT) {
  unsigned Bits = VT.getSizeInBits();
  if (Bits <= 64)
    return CLASS_GPR;
  return Bits == 128 ? CLASS_GPR128 : CLASS_GPR256;
}

// The `variant` values, with the properties the description gives them.
//
// The address-space NUMBERING in LVXAddressSpaces.h cannot be derived from the
// machine description -- it is ABI, chosen to match lvx-gcc's
// c_register_addr_space calls -- but what each variant MEANS can be, and the
// assertions below tie the two together. If the description ever renumbers the
// variants or moves Dismissible/MemoryLevel between them, this stops compiling
// instead of silently emitting a cached load where an uncached one was asked
// for, which is the exact bug LVXAddressSpaces.h was written to fix.
struct VariantRow {
  unsigned Value;
  bool Dismissible;   // a no-fault speculative load
  unsigned Level;     // 2 bypasses the L1
};

constexpr VariantRow VariantRows[] = {
#define LVX_LOAD_VARIANT(VALUE, SUFFIX, DISMISSIBLE, LEVEL)                    \
  {VALUE, DISMISSIBLE != 0, LEVEL},
#include "LVXMemoryTable.inc"
};

constexpr const VariantRow *variantRow(unsigned Value) {
  for (const VariantRow &Row : VariantRows)
    if (Row.Value == Value)
      return &Row;
  return nullptr;
}
constexpr bool dismissible(unsigned AS) {
  return variantRow(LVXAS::variantForAddressSpace(AS))->Dismissible;
}
constexpr unsigned level(unsigned AS) {
  return variantRow(LVXAS::variantForAddressSpace(AS))->Level;
}

static_assert(std::size(VariantRows) == 4, "the variant modifier has 4 values");
static_assert(!dismissible(LVXAS::Generic) && level(LVXAS::Generic) == 1,
              "a generic load is cached and may fault");
static_assert(dismissible(LVXAS::Speculate) && level(LVXAS::Speculate) == 1,
              "__speculate is the dismissible load");
static_assert(!dismissible(LVXAS::Bypass) && level(LVXAS::Bypass) == 2,
              "__bypass bypasses the cache");
static_assert(dismissible(LVXAS::Preload) && level(LVXAS::Preload) == 2,
              "__preload is both -- .us, not .u");
} // end anonymous namespace

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

  // Already a machine node: lowerShift128 builds EXTRACT_SUBREGs straight
  // into the DAG, and there is nothing to select on one.
  if (N->isMachineOpcode()) {
    N->setNodeId(-1);
    return;
  }

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
    int64_t Val = (VT == MVT::f32 || VT == MVT::f16)
                      ? (int64_t)Bits.getZExtValue()
                      : (int64_t)Bits.getSExtValue();
    unsigned Opc = isInt<16>(Val) ? LVX::MAKED_DWI
                 : isInt<43>(Val) ? LVX::MAKED_DWI_X
                                  : LVX::MAKED_DWI_Y;
    SDValue Imm = CurDAG->getTargetConstant(Val, DL, MVT::i64);
    SDNode *Res = CurDAG->getMachineNode(Opc, DL, VT, Imm);
    ReplaceNode(N, Res);
    return;
  }

  // An i128 constant: a MAKE of each half, paired. Like the ConstantFP
  // above this is done here rather than by custom-lowering it to a
  // BUILD_PAIR of two i64 constants, and for a sharper reason than the
  // pattern being unwritable: DAGCombiner folds a BUILD_PAIR of two
  // constants straight back into one i128 Constant, which lowers to a
  // BUILD_PAIR again. That is not a loop the combiner detects -- each turn
  // builds new nodes -- so the DAG grows without bound and compilation
  // simply never ends. At isel there is no combiner left to undo it.
  if (N->getOpcode() == ISD::Constant && N->getValueType(0) == MVT::i128) {
    const APInt &V = cast<ConstantSDNode>(N)->getAPIntValue();
    auto Make = [&](int64_t Val) {
      unsigned Opc = isInt<16>(Val) ? LVX::MAKED_DWI
                   : isInt<43>(Val) ? LVX::MAKED_DWI_X
                                    : LVX::MAKED_DWI_Y;
      return SDValue(CurDAG->getMachineNode(
                         Opc, DL, MVT::i64,
                         CurDAG->getTargetConstant(Val, DL, MVT::i64)),
                     0);
    };
    SDValue Ops[] = {CurDAG->getTargetConstant(LVX::GPR128RegClassID, DL,
                                               MVT::i32),
                     Make(V.trunc(64).getSExtValue()), // low half
                     CurDAG->getTargetConstant(sub_hi, DL, MVT::i32),
                     Make(V.lshr(64).trunc(64).getSExtValue()), // high half
                     CurDAG->getTargetConstant(sub_lo, DL, MVT::i32)};
    ReplaceNode(N, CurDAG->getMachineNode(TargetOpcode::REG_SEQUENCE, DL,
                                          MVT::i128, Ops));
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
      //
      // getAPIntValue, not getSExtValue: the constant can be wider than 64
      // bits (an i128 comparison reaches here), and getSExtValue asserts on
      // one rather than returning something wrong -- which is a mercy, but
      // it is still a crash on valid input.
      if (CC == ISD::SETLT && C->getAPIntValue().isOne()) {
        Tested = LHS;
        ZeroCC = ISD::SETLE;                     // x < 1  is  x <= 0
      } else if (CC == ISD::SETGT && C->getAPIntValue().isAllOnes()) {
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
          C && C->getAPIntValue().getSignificantBits() <= 32) {
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

  // ISD::BUILD_PAIR (i128 from two i64 halves) → REG_SEQUENCE.
  // LowerFormalArguments produces BUILD_PAIR when reassembling an i128
  // argument from its two i64 CC slots, lowerShift128 when it builds a
  // shifted pair from one half and a zero. A REG_SEQUENCE asks the allocator
  // to put the halves in an aligned pair, which for an argument or a return
  // value they already are, so it usually costs nothing; where they are not,
  // it costs a copyd per half. This used to be a CATDQ -- one real
  // instruction, always, even to re-pair $r0 with $r1 -- so every i128
  // argument paid for its own reassembly.
  //
  // The indices are named for the register number, not the value: sub_hi
  // is SubRegIndex<64, 0>, the lower-numbered GPR of the pair, and holds
  // the LOW 64 bits.
  if (N->getOpcode() == ISD::BUILD_PAIR &&
      N->getValueType(0) == MVT::i128) {
    SDValue RegClass =
        CurDAG->getTargetConstant(LVX::GPR128RegClassID, DL, MVT::i32);
    SDValue Ops[] = {RegClass,
                     N->getOperand(0), // low 64 bits
                     CurDAG->getTargetConstant(sub_hi, DL, MVT::i32),
                     N->getOperand(1), // high 64 bits
                     CurDAG->getTargetConstant(sub_lo, DL, MVT::i32)};
    ReplaceNode(N, CurDAG->getMachineNode(TargetOpcode::REG_SEQUENCE, DL,
                                          MVT::i128, Ops));
    return;
  }

  // ISD::BUILD_VECTOR for a 128-bit pair: the two lanes are the pair's two
  // registers, so this is the same REG_SEQUENCE that BUILD_PAIR gets -- the
  // allocator puts them in an aligned pair and nothing is executed.
  if (N->getOpcode() == ISD::BUILD_VECTOR &&
      (N->getValueType(0) == MVT::v2i64 || N->getValueType(0) == MVT::v2f64)) {
    SDValue RegClass =
        CurDAG->getTargetConstant(LVX::GPR128VRegClassID, DL, MVT::i32);
    SDValue Ops[] = {RegClass,
                     N->getOperand(0),
                     CurDAG->getTargetConstant(sub_hi, DL, MVT::i32),
                     N->getOperand(1),
                     CurDAG->getTargetConstant(sub_lo, DL, MVT::i32)};
    ReplaceNode(N, CurDAG->getMachineNode(TargetOpcode::REG_SEQUENCE, DL,
                                          N->getValueType(0), Ops));
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

    SDNode *LoPair = CurDAG->getMachineNode(LVX::CATDQ_QZWRR, DL, MVT::i128, E0, E1);
    SDNode *HiPair = CurDAG->getMachineNode(LVX::CATDQ_QZWRR, DL, MVT::i128, E2, E3);

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

  // ISD::EXTRACT_VECTOR_ELT of a v4i64 at a constant index -- a register,
  // not an instruction. A GPR256 is two GPR128s (sub_pair_hi/lo), each two
  // GPRs (sub_hi/lo), and every index names one of the four; the composition
  // of the two reads is what InstrEmitter turns into a single subregister
  // reference. A variable index would have to go through memory and is left
  // to the legalizer.
  //
  // The naming trap once more: sub_pair_hi and sub_hi are the indices at
  // bit offset 0 -- the LOW halves -- so element 0 is (sub_pair_hi,
  // sub_hi). This matches the BUILD_VECTOR below, which must agree with it.
  // A lane NARROWER than a register: the containing register is still a
  // subregister read, and the lane is a shift within it. No mask: the node's
  // result type is i64 (the element type is not legal on its own), so the
  // bits above the lane are don't-care -- any-extend is what the legalizer
  // asked for.
  if (N->getOpcode() == ISD::EXTRACT_VECTOR_ELT) {
    EVT VecVT = N->getOperand(0).getValueType();
    unsigned LaneBits = VecVT.getScalarSizeInBits();
    auto *CIdx = dyn_cast<ConstantSDNode>(N->getOperand(1));
    if (CIdx && VecVT.isVector() && LaneBits < 64 &&
        VecVT.getSizeInBits() == 128) {
      unsigned I = CIdx->getZExtValue();
      unsigned PerHalf = 64 / LaneBits;
      SDValue Half = CurDAG->getTargetExtractSubreg(
          (I / PerHalf) ? sub_lo : sub_hi, DL, MVT::i64, N->getOperand(0));
      unsigned Shift = (I % PerHalf) * LaneBits;
      if (!Shift) {
        ReplaceNode(N, Half.getNode());
        return;
      }
      ReplaceNode(N, CurDAG->getMachineNode(
                         LVX::SRLD_DSWRI, DL, MVT::i64, Half,
                         CurDAG->getTargetConstant(Shift, DL, MVT::i64)));
      return;
    }
  }

  if (N->getOpcode() == ISD::EXTRACT_VECTOR_ELT) {
    EVT VecVT = N->getOperand(0).getValueType();
    auto *Idx = dyn_cast<ConstantSDNode>(N->getOperand(1));
    if (Idx && (VecVT == MVT::v4i64 || VecVT == MVT::v2i64 ||
                VecVT == MVT::v2f64)) {
      uint64_t I = Idx->getZExtValue();
      EVT EltVT = VecVT.getVectorElementType();
      SDValue Vec = N->getOperand(0);
      if (VecVT == MVT::v4i64) {
        assert(I < 4 && "index out of range for v4i64");
        Vec = CurDAG->getTargetExtractSubreg(
            I < 2 ? sub_pair_hi : sub_pair_lo, DL, MVT::i128, Vec);
      } else {
        assert(I < 2 && "index out of range for a 128-bit pair");
      }
      SDValue Elt = CurDAG->getTargetExtractSubreg((I & 1) ? sub_lo : sub_hi,
                                                   DL, EltVT, Vec);
      ReplaceNode(N, Elt.getNode());
      return;
    }
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
      //
      // The wide widths are here too: lq at 128 bits and lo at 256, for
      // whichever type of that width the value has -- an i128, a v2i64 or a
      // v2f64 all live in the same pair, and only the class matters to the
      // instruction. They are non-extending by nature; there is nothing above
      // them to extend to. classForType is what keeps them apart from the
      // lvx-2 splatting loads of the same width, which target a GPR256.
      //
      // The node's own type has to be checked, not just the memory width: a
      // load of 64 bits whose RESULT is an i128 is an extending load into a
      // register pair, and picking "ld" for it drops the extension and hands
      // a GPR result to a GPR128 node -- wrong code, no diagnostic. Such
      // loads are Expand (see LVXTargetLowering) and must not be matched
      // here; below 64 bits an extending load into a GPR is the ordinary
      // case and its result is i64 by construction.
      EVT VT = N->getValueType(0);
      bool WidthAgrees = widthAgrees(VT, MemVT);
      if (WidthAgrees &&
          (MemVT == MVT::i64 || MemVT == MVT::f64 || MemVT == MVT::i32 ||
           MemVT == MVT::i16 || MemVT == MVT::i8 ||
           ((MemVT == MVT::f32 || MemVT == MVT::f16) &&
            Ext == ISD::NON_EXTLOAD) ||
           (isWideMemVT(MemVT) && Ext == ISD::NON_EXTLOAD)))
        Opc = narrowLoadOpcode(MemVT.getSizeInBits(), Ext == ISD::SEXTLOAD,
                               classForType(MemVT));

      Opc = Opc ? selectLoadStoreOpcode(Opc, Offset, IsFrameIndex) : 0;

      if (Opc) {
        // The `variant` modifier is NOT a codegen choice -- it is read off the
        // pointer's address space, which the user declared ("__bypass int *p").
        // Hardcoding 0 here silently compiled a __bypass load as an ordinary
        // CACHED load, which is wrong in exactly the case address spaces exist
        // for (MMIO, coherency), and made LVX disagree with lvx-gcc on the
        // same source. See LVXAddressSpaces.h for the mapping and why the
        // numbering is ABI rather than a private choice.
        unsigned Variant =
            LVXAS::variantForAddressSpace(LD->getAddressSpace());
        if (Variant == ~0u) {
          // __convert/__syscall are pointer-qualifier machinery, not load
          // variants, and there is no encoding for a load in them. Diagnose
          // rather than fall back to 0, which would be the silent
          // wrong-cacheing bug again.
          // GenCrashDiag=false: this is a user error (they wrote a load
          // through a __convert-qualified pointer), not an internal failure,
          // so it should not print "PLEASE submit a bug report" or abort.
          report_fatal_error("LVX: load from unsupported address space " +
                                 Twine(LD->getAddressSpace()),
                             /*GenCrashDiag=*/false);
        }
        // Generated LSU_LSBO_Inst operand order: off, base, variant.
        SDValue Var  = CurDAG->getTargetConstant(Variant, DL, MVT::i32);
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
      // Same table, same reasoning as the load above, minus the extension: a
      // store truncates to the width it writes, so the width and the class
      // pick it. A truncating store of a wide value is not one of these --
      // those are Expand (see LVXTargetLowering), which splits them into
      // stores of what the ISA does have.
      // The same check on the other side: a truncating store OUT of a pair
      // writes 64 bits of a 128-bit value, and "sd" cannot take a GPR128
      // operand. Those are Expand too.
      EVT VT = ST->getValue().getValueType();
      bool WidthAgrees = widthAgrees(VT, MemVT);
      if (WidthAgrees &&
          (MemVT == MVT::i64 || MemVT == MVT::f64 || MemVT == MVT::f32 ||
           MemVT == MVT::f16 || MemVT == MVT::i32 || MemVT == MVT::i16 ||
           MemVT == MVT::i8 ||
           (isWideMemVT(MemVT) && !ST->isTruncatingStore())))
        Opc = narrowStoreOpcode(MemVT.getSizeInBits(), classForType(MemVT));

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
