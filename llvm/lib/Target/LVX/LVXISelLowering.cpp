//===-- LVXISelLowering.cpp - LVX DAG Lowering Implementation -*- C++ -*-===//
//
// This file implements the LVXTargetLowering class.
//
//===----------------------------------------------------------------------===//

#include "LVXISelLowering.h"
#include "LVXSubtarget.h"
#include "llvm/CodeGen/CallingConvLower.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/IR/DiagnosticInfo.h"
#include "llvm/Support/ErrorHandling.h"

using namespace llvm;

namespace {
// The 12 argument-slot registers, per lvx_Convention.yml "argument" and
// the ABI doc's "first 12 arguments slots ... allocated into the
// general-purpose registers R0-R11". Shared by every slot allocated
// below, regardless of which original argument type (i64/f64/i128/
// v4i64) the slot belongs to -- this is the single shared counter the
// declarative CC_LVX rules couldn't provide.
static const MCPhysReg LVXArgGPRs[] = {
    LVX::R0, LVX::R1, LVX::R2,  LVX::R3,  LVX::R4,  LVX::R5,
    LVX::R6, LVX::R7, LVX::R8,  LVX::R9,  LVX::R10, LVX::R11,
};
} // end anonymous namespace

// CC_LVX_Custom implements the ABI's argument-slot model precisely
// (lvx_ApplicationBinaryInterface.tex, "Function Arguments and Result"):
// every argument occupies one or more 8-byte slots; the first 12 slots
// are R0-R11; slot 12 onward is the Outgoing Arguments stack region; and
// "if an argument straddles the boundary between slot 11 and slot 12,
// the part that lies within the first twelve slots is passed in general
// registers, and the remainder is passed in the Outgoing Arguments
// region" (quoted from the ABI doc, confirmed verbatim against the
// .tex source).
//
// This single callback handles i64/f64 (1 slot), i128 (2 slots), and
// v4i64 (4 slots) uniformly: it is registered for all three via
// CCIfType<...,  CCCustom<"CC_LVX_Custom">> in LVXCallingConv.td, and
// loops over however many 8-byte slots ValVT requires, attempting
// AllocateReg for each one (falling through to AllocateStack once the
// register list is exhausted -- which is exactly the straddle case).
//
// Each individual slot is recorded as its own CCValAssign with LocVT
// forced to i64 (even for the high slots of an i128/v4i64 argument),
// following the same "split a wide value into same-ValNo, narrower-LocVT
// pieces" pattern used by CC_Sparc_Assign_Split_64 and
// CC_PPC32_SPE_CustomSplitFP64 for their analogous 64-bit splits. The
// caller (LowerFormalArguments/LowerReturn/LowerCall in
// LVXISelLowering.cpp) is responsible for walking same-ValNo runs of
// CCValAssign entries and reassembling the original i128/v4i64 value
// from its i64 pieces (or splitting it into pieces, for outgoing args).
static bool CC_LVX_Custom(unsigned &ValNo, MVT &ValVT, MVT &LocVT,
                          CCValAssign::LocInfo &LocInfo,
                          ISD::ArgFlagsTy &ArgFlags, CCState &State) {
  unsigned NumSlots;
  switch (LocVT.SimpleTy) {
  case MVT::i64:
  case MVT::f64:
    NumSlots = 1;
    break;
  case MVT::i128:
    NumSlots = 2;
    break;
  case MVT::v4i64:
    NumSlots = 4;
    break;
  default:
    // Not a type this callback handles: return false (= "I didn't handle
    // this") so TableGen's generated CC_LVX falls through to the next rule.
    // Note: CCCustomFn uses the OPPOSITE convention from CCAssignFn --
    // return TRUE means success (handled), FALSE means failure (not handled).
    return false;
  }

  for (unsigned Slot = 0; Slot != NumSlots; ++Slot) {
    if (MCRegister Reg = State.AllocateReg(LVXArgGPRs)) {
      State.addLoc(CCValAssign::getCustomReg(ValNo, ValVT, Reg, MVT::i64,
                                             LocInfo));
      continue;
    }
    // No more argument-slot registers free: per the ABI's straddle rule,
    // this slot (and every subsequent slot of this same argument) goes
    // to the Outgoing Arguments stack region.
    int64_t Offset = State.AllocateStack(8, Align(8));
    State.addLoc(
        CCValAssign::getCustomMem(ValNo, ValVT, Offset, MVT::i64, LocInfo));
  }

  return true; // Successfully handled (CCCustomFn convention: true = success).
}

#include "LVXGenCallingConv.inc"

LVXTargetLowering::LVXTargetLowering(const TargetMachine &TM,
                                     const LVXSubtarget &STI)
    : TargetLowering(TM, STI), TRI(STI.getRegisterInfo()) {
  // LVX's native scalar integer type is i64 -- every GPR is 64 bits wide
  // per LVXRegisterInfo.td.
  addRegisterClass(MVT::i64, &LVX::GPRRegClass);

  // 128-bit register-pair values.
  addRegisterClass(MVT::i128, &LVX::GPR128RegClass);

  // There is no load that extends INTO a register pair, and no store that
  // truncates out of one: lq and sq move 128 bits as they are. Expand
  // splits each into an access of the width the ISA has plus an explicit
  // extension, which the zext/sext patterns in LVXInstrInfo.td then build
  // the pair for.
  for (MVT VT : {MVT::i8, MVT::i16, MVT::i32, MVT::i64}) {
    setTruncStoreAction(MVT::i128, VT, Expand);
    for (unsigned Ext : {ISD::EXTLOAD, ISD::SEXTLOAD, ISD::ZEXTLOAD})
      setLoadExtAction(Ext, MVT::i128, VT, Expand);
  }

  // 256-bit register-quad values. Without this, the type legalizer would
  // treat v4i64 as illegal and split/scalarize it before
  // LowerFormalArguments/LowerCall/LowerReturn ever see it, which would
  // conflict with the slot-splitting CC_LVX_Custom already performs at
  // the calling-convention level -- v4i64 must reach those functions
  // intact as a single legal type.
  addRegisterClass(MVT::v4i64, &LVX::GPR256RegClass);

  // v4i64 being the only legal vector type, the type legalizer promotes a
  // v4i8/v4i16/v4i32 to it -- and then asks for an extending vector load or
  // a truncating vector store, which the ISA has not got: lo and so move
  // 256 bits as they are, and the narrower ld/lw/lh/lb move one element.
  // Left Legal (the default for a legal type), those select nothing at all.
  // Expand turns each into per-element accesses, which is slow but is what
  // the hardware can do until there is real vector lowering.
  for (MVT VT : {MVT::v4i8, MVT::v4i16, MVT::v4i32}) {
    setTruncStoreAction(MVT::v4i64, VT, Expand);
    for (unsigned Ext : {ISD::EXTLOAD, ISD::SEXTLOAD, ISD::ZEXTLOAD})
      setLoadExtAction(Ext, MVT::v4i64, VT, Expand);
  }

  // v4i64 is a legal TYPE with no legal OPERATIONS: it exists so that a
  // 256-bit argument reaches LowerFormalArguments in one piece, and nothing
  // in the back end computes with one. Left at the default action for a
  // legal type -- Legal -- each of these selects nothing and isel dies on
  // the first vector program. Expand unrolls them into the scalar
  // operations the ISA does have, through the EXTRACT_VECTOR_ELT and
  // BUILD_VECTOR selected by hand in LVXISelDAGToDAG (which is why those
  // two stay Legal here).
  //
  // This is correct, not fast: a v4i64 add becomes four addd. Real vector
  // lowering is the lvx-2 SIMD work, and it replaces these one at a time --
  // every operation that becomes Legal simply stops being unrolled.
  // Only the operations that actually arise are listed. The set is not
  // closed under "looks like it belongs": the conversions between vector
  // widths (TRUNCATE, *_EXTEND) and the subvector operations expand into
  // forms that legalize back into themselves on a type that is both legal
  // and computationally empty, and isel then spins -- ten minutes on one
  // function, not a crash, which is the sort of thing a timeout finds and a
  // test suite does not. They are left Legal; nothing has asked for them.
  for (unsigned Op :
       {ISD::ADD, ISD::SUB, ISD::MUL, ISD::SDIV, ISD::UDIV, ISD::SREM,
        ISD::UREM, ISD::AND, ISD::OR, ISD::XOR, ISD::SHL, ISD::SRA,
        ISD::SRL, ISD::MULHS, ISD::MULHU, ISD::ABS, ISD::SMIN, ISD::SMAX,
        ISD::UMIN, ISD::UMAX, ISD::SETCC, ISD::VSELECT,
        ISD::INSERT_VECTOR_ELT, ISD::VECTOR_SHUFFLE, ISD::SCALAR_TO_VECTOR,
        ISD::CONCAT_VECTORS, ISD::EXTRACT_SUBVECTOR, ISD::INSERT_SUBVECTOR})
    setOperationAction(Op, MVT::v4i64, Expand);

  // Floating point lives in the SAME general-purpose registers as integers --
  // LVX has no separate FP register file, and every FPU instruction in the
  // generated encodings takes GPR operands. f32 values occupy the low 32 bits
  // of their GPR (the ISA's f32 operations zero-extend their result).
  addRegisterClass(MVT::f64, &LVX::GPRRegClass);
  addRegisterClass(MVT::f32, &LVX::GPRRegClass);
  // f16 lives in a GPR too, in the low half word: the ISA has a half-word
  // instruction wherever it has a word one (faddh, fmulh, fminh, fsignh,
  // ffmah ...), and fwidenhw/fnarrowwh convert to and from f32. It was in no
  // register class until now, which made MVT::f16 exist throughout the
  // machine description and be selectable nowhere -- so clang, which types
  // _Float16 natively, produced half values the back end could not place.
  addRegisterClass(MVT::f16, &LVX::GPRRegClass);

  // Compute derived properties from the register classes we just declared
  // (mirrors the standard boilerplate every target's constructor performs
  // right after addRegisterClass calls).
  computeRegisterProperties(STI.getRegisterInfo());

  setStackPointerRegisterToSaveRestore(LVX::R12);

  // Divide and modulus. DIVMODD/DIVMODUD compute BOTH results in one
  // instruction, packed into a 128-bit register pair, which maps exactly onto
  // ISD::SDIVREM/UDIVREM -- so those are the nodes made Legal, and they are
  // selected by hand in LVXISelDAGToDAG (one instruction feeding two
  // independent 64-bit values is a shape TableGen patterns express poorly).
  //
  // SDIV/UDIV/SREM/UREM stay Expand on purpose: the generic expansion turns
  // an Expand-ed one into the corresponding SDIVREM/UDIVREM whenever that is
  // legal-or-custom, so each still becomes a single divmod, and an adjacent
  // "a / b" and "a % b" on the same operands collapse to one instruction
  // rather than two. Making them Legal instead would lose that sharing.
  setOperationAction(ISD::SDIV, MVT::i64, Expand);
  setOperationAction(ISD::UDIV, MVT::i64, Expand);
  setOperationAction(ISD::SREM, MVT::i64, Expand);
  setOperationAction(ISD::UREM, MVT::i64, Expand);
  setOperationAction(ISD::SDIVREM, MVT::i64, Legal);
  setOperationAction(ISD::UDIVREM, MVT::i64, Legal);

  // 128-bit shifts. SLLQ/SRLQ/SRAQ take the amount in a register or in a
  // 6-bit immediate, so a constant amount of 64 or more has no encoding --
  // and does not want one: such a shift only moves one half of the pair
  // into the other, which lowerShift128 spells as subregister reads and a
  // 64-bit shift, so that "(trunc (srl x, 64))", the high half of an
  // __int128, folds down to a register. Everything else returns from the
  // hook untouched and meets the patterns in LVXInstrInfo.td.
  for (unsigned Op : {ISD::SHL, ISD::SRL, ISD::SRA})
    setOperationAction(Op, MVT::i128, Custom);

  // COMPD writes the comparison result zero-extended to a full double word
  // ("The boolean result extended to double word is stored into the %1"), so
  // a boolean really is 0 or 1 here. Saying so lets the generic combines use
  // a comparison result as an arithmetic value without re-masking it.
  setBooleanContents(ZeroOrOneBooleanContent);

  // Per LANE, a vector comparison yields all-ones rather than 1. Nothing in
  // the ISA settles this -- there are no vector compares here yet -- so it
  // is a choice, and it is the one every expansion of a vector select or
  // mask assumes: those rewrite "select(c, a, b)" into "(c & a) | (~c & b)",
  // which needs a full-width mask and is silently wrong with 0/1 lanes.
  // Left at the default, UndefinedBooleanContent, the expansions cannot
  // proceed and the vector legalizer spins on the resulting and/or instead
  // of failing.
  setBooleanVectorContents(ZeroOrNegativeOneBooleanContent);

  // SELECT_CC stays expanded into SETCC + SELECT: CMOVED is a conditional
  // move on a bcucond test of one register, so the two-step form is what it
  // actually matches. BR_CC and BRCOND are left Legal and selected directly
  // in LVXISelDAGToDAG -- LVX branches on the comparison itself (cb/ccb), so
  // routing them through SETCC would cost an extra instruction on every
  // conditional branch.
  setOperationAction(ISD::SELECT_CC, MVT::i64, Expand);

  // A switch's jump table. LVX has no dedicated table-branch instruction, so
  // BR_JT is expanded into the generic sequence -- scale the index, add the
  // table base, load the entry, and branch indirectly through it -- and only
  // the resulting ISD::BRIND needs a pattern (-> IGOTO_IBC). Leaving BR_JT at
  // its default Legal action means isel fails with "Cannot select: br_jt" on
  // any switch dense enough for a table, which at -O0 is most of them: at
  // higher -O levels the optimizer often rewrites the switch into a compare
  // chain, which bypasses the table path entirely.
  setOperationAction(ISD::BR_JT, MVT::Other, Expand);

  //===--------------------------------------------------------------------===//
  // Floating point
  //
  // Rounding: the arithmetic patterns in LVXInstrInfo.td pass floatmode=7,
  // the "no suffix" member, which per the generated LVXModifiers.h means "Use
  // CS rounding" -- i.e. dynamic, from $cs.RM. That matches RISC-V, whose
  // rm=111 is DYN and is what its assembler defaults to for "fadd.d"; the
  // floatmode table lines up member-for-member with RISC-V's. Conversions to
  // integer instead pin floatmode=1 (.rz), because C truncates toward zero
  // regardless of $cs.
  //===--------------------------------------------------------------------===//
  for (MVT VT : {MVT::f32, MVT::f64}) {
    // No hardware for these; they are libm calls in C anyway.
    for (unsigned Op : {ISD::FREM, ISD::FSIN, ISD::FCOS, ISD::FSINCOS,
                        ISD::FPOW, ISD::FEXP, ISD::FEXP2, ISD::FLOG,
                        ISD::FLOG2, ISD::FLOG10, ISD::FCEIL, ISD::FFLOOR,
                        ISD::FTRUNC, ISD::FROUND, ISD::FNEARBYINT})
      setOperationAction(Op, VT, Expand);

    // There IS hardware for these, and until now nothing said so. LVX has both
    // IEEE min/max families, which is why the description has two helpers per
    // direction and why they must not be conflated:
    //
    //   f*_minNum  (FMINN)  754-2008 minNum  -- returns the non-NaN operand
    //   f*_min     (FMIN)   754-2019 minimum -- propagates the NaN
    //
    // the same split RISC-V spells FMIN/FMAX against Zfa's FMINM/FMAXM. Left
    // to Expand, FMINIMUM turned into a setcc/select chain that then failed to
    // select outright, so llvm.minimum.f64 did not compile at all; FMINNUM
    // asked for a libcall that does not exist. The patterns for all four are
    // generated from those helper names, so declaring them Legal is what
    // connects the two.
    //
    // FRINT rounds by the current mode, which is exactly what FRINTD does with
    // floatmode=7. FNEARBYINT stays Expand above: it differs precisely in not
    // raising inexact, and nothing here suppresses that flag.
    for (unsigned Op : {ISD::FMINNUM, ISD::FMAXNUM, ISD::FMINIMUM,
                        ISD::FMAXIMUM, ISD::FRINT})
      setOperationAction(Op, VT, Legal);

    // FMA is Legal: FFMAD/FFMAW accumulate INTO their destination register
    // ("f64_mulAdd(RM, argument3, argument2^fsign, argument1^fsign)", where
    // argument1 is registerW), and the generated encodings already model that
    // -- ALU_FDFMA_Inst carries a $rWsrc input tied to $rW via
    // "let Constraints". So the accumulator simply binds to that tied
    // operand and no pseudo or custom inserter is needed.

    // No FP compare-and-branch and no FP conditional move: go through an
    // explicit FCOMPD/FCOMPW producing a 0/1 GPR, then an integer branch.
    setOperationAction(ISD::BR_CC, VT, Expand);
    setOperationAction(ISD::SELECT_CC, VT, Expand);

    // floatcomp has eight members covering four complementary pairs --
    // ONE/UEQ, OEQ/UNE, OLT/UGE, OGE/ULT. GT/LE forms are reached by swapping
    // the compared operands, which the patterns do. Ordered/unordered as a
    // standalone predicate has no single encoding, so let the legalizer
    // synthesize those two.
    setCondCodeAction(ISD::SETO, VT, Expand);
    setCondCodeAction(ISD::SETUO, VT, Expand);
  }

  //===--------------------------------------------------------------------===//
  // f16
  //
  // The f16 arithmetic is NATIVE, not promoted: faddh, fmulh, fminh and the
  // rest are real instructions, and their patterns are generated from the
  // f16_* helpers each one's Behavior calls (lvx-mds a132720 -- the generator
  // had skipped them while MVT::f16 was in no register class, which it no
  // longer is). Left at Promote they would sit unused behind an fwidenhw /
  // fnarrowwh pair that also rounds twice where the instruction rounds once.
  //
  // The comparison is native too: fcomph, through the same FCmpPat
  // multiclass f32 and f64 use. What is left is what f32 and f64 also leave
  // alone -- there is no FP compare-and-branch and no FP conditional move,
  // so a comparison produces a 0/1 GPR and an integer branch or cmove reads
  // it, and the two "is it ordered" predicates have no single encoding.
  setOperationAction(ISD::BR_CC, MVT::f16, Expand);
  setOperationAction(ISD::SELECT_CC, MVT::f16, Expand);
  setCondCodeAction(ISD::SETO, MVT::f16, Expand);
  setCondCodeAction(ISD::SETUO, MVT::f16, Expand);

  // The same four min/max and FRINT the f32/f64 loop above declares Legal,
  // for the same reason: both IEEE families have a half-word instruction
  // (fminh propagates a NaN, fminnh returns the numeric operand) and their
  // patterns are generated. Saying so explicitly is not redundant -- that
  // loop runs over f32 and f64 only, and these do not default to Legal.
  for (unsigned Op : {ISD::FMINNUM, ISD::FMAXNUM, ISD::FMINIMUM,
                      ISD::FMAXIMUM, ISD::FRINT})
    setOperationAction(Op, MVT::f16, Legal);

  // NOT promoted, and the exceptions are the interesting part:
  //
  //  - fneg/fabs/fcopysign have half-word instructions of their own and are
  //    selected by pattern in LVXInstrInfo.td. They are pure sign-bit work,
  //    so promoting would cost three instructions for one -- and promoting
  //    FCOPYSIGN sends the legalizer round in a circle, because its two
  //    operands need not share a type. That is a hang, not a diagnostic.
  //
  //  - the integer conversions are keyed on the RESULT type, which for
  //    fp_to_sint is i64 and already Legal, so "Promote for f16" would
  //    silently do nothing and isel would fail. They too are patterns.

  // No hardware, as for f32/f64: these are libm calls in C.
  for (unsigned Op : {ISD::FREM, ISD::FSIN, ISD::FCOS, ISD::FSINCOS,
                      ISD::FPOW, ISD::FEXP, ISD::FEXP2, ISD::FLOG,
                      ISD::FLOG2, ISD::FLOG10, ISD::FCEIL, ISD::FFLOOR,
                      ISD::FTRUNC, ISD::FROUND, ISD::FNEARBYINT})
    setOperationAction(Op, MVT::f16, Promote);

  // A half constant is its bit pattern in a GPR, like every other FP
  // constant here (LVXISelDAGToDAG materializes it with a maked).
  setOperationAction(ISD::ConstantFP, MVT::f16, Legal);

  // f16 <-> f64 is two instructions, and the patterns in LVXInstrInfo.td
  // spell it as such; fpextend/fpround themselves stay Legal.
  setOperationAction(ISD::BITCAST, MVT::f16, Legal);

  // There is no extending FP load and no truncating FP store: widening and
  // narrowing are separate instructions (FWIDENWD / FNARROWDW). Without these,
  // DAGCombiner folds "fpextend (load f32)" into a single f32->f64 EXTLOAD and
  // "store (fpround f64)" into an f64->f32 TRUNCSTORE, and the conversion is
  // then silently dropped -- the bits get moved but never converted.
  setLoadExtAction(ISD::EXTLOAD, MVT::f64, MVT::f32, Expand);
  setTruncStoreAction(MVT::f64, MVT::f32, Expand);
  // Same for the half word: a load of an f16 is a 16-bit load and then a
  // fwidenhw, never one instruction, and a store of one narrows first.
  for (MVT VT : {MVT::f32, MVT::f64}) {
    setLoadExtAction(ISD::EXTLOAD, VT, MVT::f16, Expand);
    setTruncStoreAction(VT, MVT::f16, Expand);
  }

  // A ConstantFP has no immediate form -- LVXISelDAGToDAG materializes it as
  // an integer MAKE of the value's bit pattern, like any other constant.
  setOperationAction(ISD::ConstantFP, MVT::f64, Legal);
  setOperationAction(ISD::ConstantFP, MVT::f32, Legal);

  // FP and integer share the GPR file, so a same-width bitcast is at worst a
  // register move.
  setOperationAction(ISD::BITCAST, MVT::f64, Legal);
  setOperationAction(ISD::BITCAST, MVT::f32, Legal);
  setOperationAction(ISD::BITCAST, MVT::i64, Legal);

  // A vector lane read at a VARIABLE index. The constant case is a
  // subregister read, selected in LVXISelDAGToDAG; there is no instruction
  // for a computed one, so it goes through memory -- which is what the
  // generic expansion does, and what returning a null SDValue from a Custom
  // hook asks for. Left Legal, isel simply failed on it at -O0 and -O1,
  // where the index has not been folded to a constant yet.
  setOperationAction(ISD::EXTRACT_VECTOR_ELT, MVT::v4i64, Custom);

  // fcopysign whose operands are different types -- see lowerCopySign.
  for (MVT VT : {MVT::f16, MVT::f32, MVT::f64})
    setOperationAction(ISD::FCOPYSIGN, VT, Custom);

  setMinFunctionAlignment(Align(4));
  setPrefFunctionAlignment(Align(4));
}

// The type a SETCC produces. The base class has no answer for a vector --
// it asserts -- and v4i64 reaches here whenever a vector comparison is
// unrolled, so say the obvious thing: one lane of result per lane of input,
// as wide as the lane compared.
EVT LVXTargetLowering::getSetCCResultType(const DataLayout &DL,
                                          LLVMContext &Ctx, EVT VT) const {
  if (VT.isVector())
    return VT.changeVectorElementTypeToInteger();
  return TargetLowering::getSetCCResultType(DL, Ctx, VT);
}

bool LVXTargetLowering::isFMAFasterThanFMulAndFAdd(const MachineFunction &MF,
                                                   EVT VT) const {
  if (!VT.isSimple())
    return false;
  // One instruction instead of two, and more accurate: the ISA fuses with a
  // single rounding ("f64_mulAdd").
  switch (VT.getSimpleVT().SimpleTy) {
  case MVT::f32:
  case MVT::f64:
    return true;
  default:
    return false;
  }
}

SDValue LVXTargetLowering::LowerOperation(SDValue Op,
                                          SelectionDAG &DAG) const {
  switch (Op.getOpcode()) {
  case ISD::SHL:
  case ISD::SRL:
  case ISD::SRA:
    return lowerShift128(Op, DAG);
  case ISD::FCOPYSIGN:
    return lowerCopySign(Op, DAG);
  case ISD::EXTRACT_VECTOR_ELT:
    // A constant index is a subregister read and isel takes it from here; a
    // computed one has no instruction, and a null SDValue is how a Custom
    // hook asks for the generic expansion (through memory).
    return isa<ConstantSDNode>(Op.getOperand(1)) ? Op : SDValue();
  default:
    llvm_unreachable(
        "Unimplemented operation in LVXTargetLowering::LowerOperation");
  }
}

// fcopysign whose two operands are different types. ISD::FCOPYSIGN allows
// that -- only the sign bit of the second is read -- and DAGCombiner makes it
// happen, folding "fcopysign x, (fpextend y)" into "fcopysign x, y". Every
// fsign pattern takes one type, so such a node selected nothing at all:
// copysign(double, (double)float) failed to compile at any -O level, and had
// since copysign arrived.
//
// Two wrong ways to fix it, both tried:
//
//  - Convert the sign operand to the magnitude's type and let the ordinary
//    pattern match. WRONG ON A NaN: fnarrowdw of a negative NaN returns a
//    CANONICAL one, positive -- RISC-V-conformant, and it drops exactly the
//    bit being copied. Verified on the ISS; validation's signs.c catches it
//    and nothing else does.
//  - Convert and rebuild the FCOPYSIGN node from a Custom hook. The combine
//    above undoes it on the next round and the two spin forever -- a hang,
//    not a diagnostic, and the same shape as the i128 constant that had to
//    be materialized at isel.
//
// So move the BIT. The reinterpretations are free (FP and integer share the
// GPR file) and no conversion instruction is involved, so a NaN keeps its
// sign because nothing has looked at what the value means.
SDValue LVXTargetLowering::lowerCopySign(SDValue Op, SelectionDAG &DAG) const {
  EVT VT = Op.getValueType();
  SDValue Mag = Op.getOperand(0), Sgn = Op.getOperand(1);
  EVT SgnVT = Sgn.getValueType();
  if (SgnVT == VT)
    return Op; // one type: fsignd/fsignw/fsignh takes it directly

  SDLoc DL(Op);
  auto ToBits = [&](SDValue V, EVT T) -> SDValue {
    if (T == MVT::f64)
      return DAG.getNode(ISD::BITCAST, DL, MVT::i64, V);
    return DAG.getNode(T == MVT::f32 ? LVXISD::F32_TO_BITS
                                     : LVXISD::F16_TO_BITS,
                       DL, MVT::i64, V);
  };
  auto FromBits = [&](SDValue V) -> SDValue {
    if (VT == MVT::f64)
      return DAG.getNode(ISD::BITCAST, DL, VT, V);
    return DAG.getNode(VT == MVT::f32 ? LVXISD::BITS_TO_F32
                                      : LVXISD::BITS_TO_F16,
                       DL, VT, V);
  };

  unsigned MagBits = VT.getSizeInBits(), SgnBits = SgnVT.getSizeInBits();
  SDValue M = ToBits(Mag, VT), S = ToBits(Sgn, SgnVT);

  // The sign bit alone, moved from its place in the source to its place in
  // the destination.
  SDValue Bit = DAG.getNode(
      ISD::AND, DL, MVT::i64,
      DAG.getNode(ISD::SRL, DL, MVT::i64, S,
                  DAG.getConstant(SgnBits - 1, DL, MVT::i64)),
      DAG.getConstant(1, DL, MVT::i64));
  SDValue Placed = DAG.getNode(ISD::SHL, DL, MVT::i64, Bit,
                               DAG.getConstant(MagBits - 1, DL, MVT::i64));
  SDValue Cleared =
      DAG.getNode(ISD::AND, DL, MVT::i64, M,
                  DAG.getConstant(~(uint64_t(1) << (MagBits - 1)), DL,
                                  MVT::i64));
  return FromBits(DAG.getNode(ISD::OR, DL, MVT::i64, Cleared, Placed));
}

// An i128 shift by a constant of 64 or more. The result's halves are the
// source's other half shifted by amount-64, and a zero -- or, for sra, the
// sign spread over a word. Built from the halves rather than sent to the
// shifter, so the combiner can fold the truncate that nearly always follows
// into a subregister read: "(trunc (srl x, 64))" is how the high half of an
// __int128 is spelled, and it should cost nothing.
//
// The subregister indices are named for the register NUMBER, not the value:
// sub_hi is SubRegIndex<64, 0>, the lower-numbered GPR of the pair, which
// holds the LOW 64 bits (catdq $rM = $rZ, $rY puts $rZ there). See the
// DIVMODD comment in LVXISelDAGToDAG.cpp, which trips on the same thing.
SDValue LVXTargetLowering::lowerShift128(SDValue Op, SelectionDAG &DAG) const {
  auto *C = dyn_cast<ConstantSDNode>(Op.getOperand(1));
  if (!C || C->getZExtValue() < 64)
    return Op; // the patterns take it: sllq/srlq/sraq, immediate or register
  uint64_t Amt = C->getZExtValue();
  if (Amt >= 128)
    return DAG.getUNDEF(MVT::i128); // poison in the IR

  SDLoc DL(Op);
  SDValue X = Op.getOperand(0);
  SDValue Lo = DAG.getTargetExtractSubreg(sub_hi, DL, MVT::i64, X);
  SDValue Hi = DAG.getTargetExtractSubreg(sub_lo, DL, MVT::i64, X);
  SDValue Zero = DAG.getConstant(0, DL, MVT::i64);
  SDValue Sh = DAG.getConstant(Amt - 64, DL, MVT::i64);
  SDValue NewLo, NewHi;
  switch (Op.getOpcode()) {
  case ISD::SHL:
    NewLo = Zero;
    NewHi = DAG.getNode(ISD::SHL, DL, MVT::i64, Lo, Sh);
    break;
  case ISD::SRL:
    NewLo = DAG.getNode(ISD::SRL, DL, MVT::i64, Hi, Sh);
    NewHi = Zero;
    break;
  case ISD::SRA:
    NewLo = DAG.getNode(ISD::SRA, DL, MVT::i64, Hi, Sh);
    NewHi = DAG.getNode(ISD::SRA, DL, MVT::i64, Hi,
                        DAG.getConstant(63, DL, MVT::i64));
    break;
  default:
    llvm_unreachable("not a shift");
  }
  // (low, high), the order LVXISelDAGToDAG turns into catdq.
  return DAG.getNode(ISD::BUILD_PAIR, DL, MVT::i128, NewLo, NewHi);
}

bool LVXTargetLowering::CanLowerReturn(
    CallingConv::ID CallConv, MachineFunction &MF, bool IsVarArg,
    const SmallVectorImpl<ISD::OutputArg> &Outs, LLVMContext &Context,
    const Type * /*RetTy*/) const {
  SmallVector<CCValAssign, 16> RVLocs;
  CCState CCInfo(CallConv, IsVarArg, MF, RVLocs, Context);
  return CCInfo.CheckReturn(Outs, CC_LVXRet);
}

Register
LVXTargetLowering::getRegisterByName(const char * /*RegName*/, LLT /*VT*/,
                                     const MachineFunction & /*MF*/) const {
  // TODO(Phase 5): support llvm.read_register / write_register intrinsics
  // by mapping assembly register names (e.g. "r0", "ra") to LVX:: enum
  // values, as Lanai does. Not needed for basic call/return lowering.
  report_fatal_error(
      "Invalid register name for llvm.read/write_register on LVX");
}

std::pair<unsigned, const TargetRegisterClass *>
LVXTargetLowering::getRegForInlineAsmConstraint(const TargetRegisterInfo *TRI_,
                                                StringRef Constraint,
                                                MVT VT) const {
  // "r" is a general register of whatever width the operand has: one GPR
  // for a word (integer or floating point -- they share the file), an
  // aligned pair for an __int128, a quad for a 256-bit vector. Which one
  // the assembler then wants is spelled by the register name itself
  // ($r0, $r0r1, $r0r1r2r3), so the same "%0" works for all three.
  if (Constraint.size() == 1 && Constraint[0] == 'r') {
    switch (VT.SimpleTy) {
    case MVT::i128:
      return std::make_pair(0U, &LVX::GPR128RegClass);
    case MVT::v4i64:
      return std::make_pair(0U, &LVX::GPR256RegClass);
    default:
      return std::make_pair(0U, &LVX::GPRRegClass);
    }
  }
  return TargetLowering::getRegForInlineAsmConstraint(TRI_, Constraint, VT);
}

TargetLowering::ConstraintWeight
LVXTargetLowering::getSingleConstraintMatchWeight(
    AsmOperandInfo &Info, const char *Constraint) const {
  // TODO(Phase 5): real constraint-weight logic, as Lanai implements.
  return TargetLowering::getSingleConstraintMatchWeight(Info, Constraint);
}

//===----------------------------------------------------------------------===//
// Calling Convention Implementation
//===----------------------------------------------------------------------===//

// The calling convention promotes every integer narrower than a slot to i64
// (CCPromoteToType in LVXCallingConv.td), so a value's type on the wire is
// not always the type the IR gave it. These two put a value into, and take it
// back out of, its 64-bit slot.
//
// Which way an integer was widened matters to the callee only when it reads
// the high bits, which the sext/zext argument flags are exactly there to
// promise; without a flag, any-extend is what the convention allows.
static SDValue extendToSlot(SelectionDAG &DAG, const SDLoc &DL, SDValue Val,
                            MVT LocVT, ISD::ArgFlagsTy Flags) {
  EVT VT = Val.getValueType();
  if (VT == LocVT)
    return Val;

  // A narrower floating-point value cannot be extended directly. f32 gets a
  // dedicated node rather than a bitcast-to-i32-then-extend: i32 is not a
  // legal type here (only i64 is), so that route makes the legalizer lower
  // the bitcast through MEMORY, which does not merely cost a spill -- it
  // silently drops the value, turning "fpext float to double" into a
  // store/reload of the raw f32 bits with no FWIDENWD at all. See the
  // LVXISD::F32_TO_BITS comment in LVXInstrInfo.td.
  if (VT == MVT::f32 && LocVT == MVT::i64)
    return DAG.getNode(LVXISD::F32_TO_BITS, DL, MVT::i64, Val);
  // And the same for f16, for the same reason one step further down: i16 is
  // no more a legal type than i32 is.
  if (VT == MVT::f16 && LocVT == MVT::i64)
    return DAG.getNode(LVXISD::F16_TO_BITS, DL, MVT::i64, Val);

  if (VT.isFloatingPoint() && VT.getSizeInBits() < LocVT.getSizeInBits()) {
    Val = DAG.getNode(ISD::BITCAST, DL,
                      MVT::getIntegerVT(VT.getSizeInBits()), Val);
    VT = Val.getValueType();
  }

  if (VT.isInteger() && LocVT.isInteger() && VT.bitsLT(LocVT)) {
    unsigned Opc = Flags.isSExt()   ? ISD::SIGN_EXTEND
                   : Flags.isZExt() ? ISD::ZERO_EXTEND
                                    : ISD::ANY_EXTEND;
    return DAG.getNode(Opc, DL, LocVT, Val);
  }

  // Same width, different type (f64 in an i64 slot): a reinterpretation.
  return DAG.getNode(ISD::BITCAST, DL, LocVT, Val);
}

static SDValue truncateFromSlot(SelectionDAG &DAG, const SDLoc &DL,
                                SDValue Val, EVT VT) {
  if (VT == MVT::i64)
    return Val;
  // Mirror of extendToSlot's f32 case: reinterpret the low 32 bits of the
  // slot in place. ISD::TRUNCATE below is integer-only and would be invalid
  // for f32 anyway.
  if (VT == MVT::f32)
    return DAG.getNode(LVXISD::BITS_TO_F32, DL, MVT::f32, Val);
  if (VT == MVT::f16)
    return DAG.getNode(LVXISD::BITS_TO_F16, DL, MVT::f16, Val);
  if (VT.bitsLT(MVT::i64))
    return DAG.getNode(ISD::TRUNCATE, DL, VT, Val);
  return DAG.getNode(ISD::BITCAST, DL, VT, Val);
}

SDValue LVXTargetLowering::LowerFormalArguments(
    SDValue Chain, CallingConv::ID CallConv, bool IsVarArg,
    const SmallVectorImpl<ISD::InputArg> &Ins, const SDLoc &DL,
    SelectionDAG &DAG, SmallVectorImpl<SDValue> &InVals) const {
  if (IsVarArg)
    report_fatal_error("Variadic functions not yet supported on LVX");

  MachineFunction &MF = DAG.getMachineFunction();
  MachineRegisterInfo &RegInfo = MF.getRegInfo();

  SmallVector<CCValAssign, 16> ArgLocs;
  CCState CCInfo(CallConv, IsVarArg, MF, ArgLocs, *DAG.getContext());
  CCInfo.AnalyzeFormalArguments(Ins, CC_LVX);

  // CC_LVX_Custom (LVXCallingConv.td / the callback above) assigns every
  // argument as one or more i64-typed slots sharing the same ValNo: 1
  // slot for i64/f64, 2 for i128, 4 for v4i64. Walk ArgLocs grouping
  // consecutive entries by ValNo, materialize each slot individually
  // (CopyFromReg for a register slot, a load for a stack slot), then
  // reassemble multi-slot arguments into their true type.
  unsigned Idx = 0;
  while (Idx < ArgLocs.size()) {
    unsigned ValNo = ArgLocs[Idx].getValNo();
    SmallVector<SDValue, 4> Pieces;

    while (Idx < ArgLocs.size() && ArgLocs[Idx].getValNo() == ValNo) {
      const CCValAssign &VA = ArgLocs[Idx];
      SDValue Piece;
      if (VA.isRegLoc()) {
        // A slot passed in one of R0-R11: create a vreg, copy the
        // incoming physical register into it. Every slot's LocVT is
        // forced to i64 by CC_LVX_Custom, regardless of the original
        // argument's true type.
        Register VReg = RegInfo.createVirtualRegister(&LVX::GPRRegClass);
        RegInfo.addLiveIn(VA.getLocReg(), VReg);
        Piece = DAG.getCopyFromReg(Chain, DL, VReg, MVT::i64);
      } else {
        // A slot in the Outgoing Arguments stack region (the straddle
        // case, or an argument entirely past the first 12 slots): load
        // it from the incoming argument area of the caller's frame.
        assert(VA.isMemLoc() &&
               "CCValAssign must be either RegLoc or MemLoc");
        int FI = MF.getFrameInfo().CreateFixedObject(
            8, VA.getLocMemOffset(), /*IsImmutable=*/true);
        SDValue FIN = DAG.getFrameIndex(FI, getPointerTy(DAG.getDataLayout()));
        Piece = DAG.getLoad(MVT::i64, DL, Chain, FIN,
                            MachinePointerInfo::getFixedStack(MF, FI));
      }
      Pieces.push_back(Piece);
      ++Idx;
    }

    // Reassemble the pieces into the argument's true value type. The
    // true type comes from Ins[ValNo].ArgVT (the pre-CC_LVX_Custom type:
    // i64/f64 for a single piece, i128 for two, v4i64 for four).
    EVT ArgVT = Ins[ValNo].ArgVT;
    SDValue ArgValue;
    if (Pieces.size() == 1) {
      // Narrower than a slot means the convention promoted it on the way in,
      // so getting it back is a truncation; a same-width type (f64) is a
      // bitcast. Doing this unconditionally as a bitcast asserts on any
      // i1/i8/i16/i32 argument.
      ArgValue = truncateFromSlot(DAG, DL, Pieces[0], ArgVT);
    } else if (Pieces.size() == 2) {
      // i128: a genuine wide integer split across two i64 halves.
      // BUILD_PAIR is the standard node for this (low half first, per
      // the ABI's increasing-address slot ordering -- slot N holds the
      // low 64 bits, slot N+1 the high 64 bits).
      ArgValue =
          DAG.getNode(ISD::BUILD_PAIR, DL, MVT::i128, Pieces[0], Pieces[1]);
      if (ArgVT != MVT::i128)
        ArgValue = DAG.getNode(ISD::BITCAST, DL, ArgVT, ArgValue);
    } else {
      // v4i64: a VECTOR of four i64 elements, not a wide integer --
      // BUILD_VECTOR is the correct node here (BUILD_PAIR is only for
      // forming wider integers from narrower integer halves, e.g.
      // i64+i64->i128, and has no defined meaning for assembling a
      // vector). No BITCAST is needed since the element type already
      // matches ArgVT's element type.
      assert(Pieces.size() == 4 && ArgVT == MVT::v4i64 &&
             "Unexpected piece count for a non-i128 multi-slot argument");
      ArgValue = DAG.getBuildVector(MVT::v4i64, DL, Pieces);
    }

    InVals.push_back(ArgValue);
  }

  return Chain;
}

SDValue LVXTargetLowering::LowerReturn(
    SDValue Chain, CallingConv::ID CallConv, bool IsVarArg,
    const SmallVectorImpl<ISD::OutputArg> &Outs,
    const SmallVectorImpl<SDValue> &OutVals, const SDLoc &DL,
    SelectionDAG &DAG) const {
  if (IsVarArg)
    report_fatal_error("Variadic functions not yet supported on LVX");

  MachineFunction &MF = DAG.getMachineFunction();

  SmallVector<CCValAssign, 16> RVLocs;
  CCState CCInfo(CallConv, IsVarArg, MF, RVLocs, *DAG.getContext());
  CCInfo.AnalyzeReturn(Outs, CC_LVXRet);

  SDValue Glue;
  SmallVector<SDValue, 4> RetOps(1, Chain);

  for (unsigned i = 0, e = RVLocs.size(); i != e; ++i) {
    CCValAssign &VA = RVLocs[i];
    assert(VA.isRegLoc() &&
           "Return values must be in registers per CC_LVXRet");
    // Same promotion as an outgoing argument: a return value narrower than
    // its assigned location is extended into it. The location is not always a
    // single 64-bit slot -- an i128 return goes in a GPR128 pair, where
    // LocVT is i128 and nothing needs doing -- so this asks the CCValAssign
    // rather than assuming.
    SDValue RetVal =
        extendToSlot(DAG, DL, OutVals[i], VA.getLocVT(), Outs[i].Flags);
    Chain = DAG.getCopyToReg(Chain, DL, VA.getLocReg(), RetVal, Glue);
    Glue = Chain.getValue(1);
    RetOps.push_back(DAG.getRegister(VA.getLocReg(), VA.getLocVT()));
  }

  RetOps[0] = Chain;
  if (Glue.getNode())
    RetOps.push_back(Glue);

  SDValue Ret = DAG.getNode(LVXISD::RET_GLUE, DL, MVT::Other, RetOps);
  return Ret;
}

SDValue
LVXTargetLowering::LowerCall(TargetLowering::CallLoweringInfo &CLI,
                             SmallVectorImpl<SDValue> &InVals) const {
  SelectionDAG &DAG = CLI.DAG;
  SDLoc &DL = CLI.DL;
  SmallVectorImpl<ISD::OutputArg> &Outs = CLI.Outs;
  SmallVectorImpl<SDValue> &OutVals = CLI.OutVals;
  SmallVectorImpl<ISD::InputArg> &Ins = CLI.Ins;
  SDValue Chain = CLI.Chain;
  SDValue Callee = CLI.Callee;
  CallingConv::ID CallConv = CLI.CallConv;
  bool IsVarArg = CLI.IsVarArg;

  if (IsVarArg)
    report_fatal_error("Variadic functions not yet supported on LVX");
  if (CLI.IsTailCall)
    report_fatal_error("Tail calls not yet supported on LVX");

  MachineFunction &MF = DAG.getMachineFunction();

  // ---- Analyze outgoing arguments (mirrors LowerFormalArguments' use
  // of CC_LVX, but for the OUTGOING side: each i128/v4i64 OutputArg
  // still produces one or more i64-typed CCValAssign slots sharing a
  // ValNo, which must be SPLIT from the wide OutVals[ValNo] value rather
  // than reassembled). ----
  SmallVector<CCValAssign, 16> ArgLocs;
  CCState CCInfo(CallConv, IsVarArg, MF, ArgLocs, *DAG.getContext());
  CCInfo.AnalyzeCallOperands(Outs, CC_LVX);

  unsigned NumBytes = CCInfo.getAlignedCallFrameSize();
  Chain = DAG.getCALLSEQ_START(Chain, NumBytes, 0, DL);

  SmallVector<std::pair<unsigned, SDValue>, 12> RegsToPass;
  SmallVector<SDValue, 12> MemOpChains;

  unsigned Idx = 0;
  while (Idx < ArgLocs.size()) {
    unsigned ValNo = ArgLocs[Idx].getValNo();
    SDValue Val = OutVals[ValNo];
    // Widen a sub-slot integer before splitting, so the piece loop below only
    // ever deals in whole 64-bit slots.
    if (Val.getValueType() != MVT::i64 && !Val.getValueType().isVector() &&
        Val.getValueType().getSizeInBits() < 64)
      Val = extendToSlot(DAG, DL, Val, MVT::i64, Outs[ValNo].Flags);
    EVT ValVT = Val.getValueType();

    // Split the (possibly wide) outgoing value into the same number of
    // i64 pieces CC_LVX_Custom assigned it -- the inverse of the
    // BUILD_PAIR/BUILD_VECTOR reassembly LowerFormalArguments performs
    // on the incoming side.
    SmallVector<SDValue, 4> Pieces;
    if (ValVT == MVT::i64 || ValVT == MVT::f64) {
      Pieces.push_back(ValVT == MVT::i64
                            ? Val
                            : DAG.getNode(ISD::BITCAST, DL, MVT::i64, Val));
    } else if (ValVT == MVT::i128) {
      Pieces.push_back(DAG.getNode(ISD::EXTRACT_ELEMENT, DL, MVT::i64, Val,
                                   DAG.getIntPtrConstant(0, DL)));
      Pieces.push_back(DAG.getNode(ISD::EXTRACT_ELEMENT, DL, MVT::i64, Val,
                                   DAG.getIntPtrConstant(1, DL)));
    } else if (ValVT == MVT::v4i64) {
      for (unsigned El = 0; El != 4; ++El)
        Pieces.push_back(DAG.getNode(ISD::EXTRACT_VECTOR_ELT, DL, MVT::i64,
                                     Val, DAG.getVectorIdxConstant(El, DL)));
    } else {
      llvm_unreachable("Unexpected outgoing argument type for LVX CC_LVX");
    }

    for (SDValue Piece : Pieces) {
      const CCValAssign &VA = ArgLocs[Idx++];
      if (VA.isRegLoc()) {
        RegsToPass.push_back(std::make_pair(VA.getLocReg(), Piece));
      } else {
        assert(VA.isMemLoc() &&
               "CCValAssign must be either RegLoc or MemLoc");
        SDValue StackPtr =
            DAG.getCopyFromReg(Chain, DL, LVX::R12, getPointerTy(DAG.getDataLayout()));
        SDValue PtrOff = DAG.getNode(
            ISD::ADD, DL, getPointerTy(DAG.getDataLayout()), StackPtr,
            DAG.getIntPtrConstant(VA.getLocMemOffset(), DL));
        MemOpChains.push_back(
            DAG.getStore(Chain, DL, Piece, PtrOff, MachinePointerInfo()));
      }
    }
  }

  if (!MemOpChains.empty())
    Chain = DAG.getNode(ISD::TokenFactor, DL, MVT::Other, MemOpChains);

  // ---- Build the glued chain of CopyToReg nodes for every register
  // argument, then assemble the LVXcall node's operand list. ----
  SDValue Glue;
  for (auto &Reg : RegsToPass) {
    Chain = DAG.getCopyToReg(Chain, DL, Reg.first, Reg.second, Glue);
    Glue = Chain.getValue(1);
  }

  SmallVector<SDValue, 8> Ops;
  Ops.push_back(Chain);
  Ops.push_back(Callee);
  for (auto &Reg : RegsToPass)
    Ops.push_back(DAG.getRegister(Reg.first, MVT::i64));

  // The clobber mask. Without it the call declares only the generated
  // "Defs = [RA]" -- what the ISA writes -- and the allocator believes every
  // other register survives, so it happily keeps a value live across a call
  // in an argument register the callee then overwrites. That is silent: the
  // code assembles and runs, just with the wrong value.
  const uint32_t *Mask =
      TRI->getCallPreservedMask(DAG.getMachineFunction(), CallConv);
  assert(Mask && "missing call-preserved mask");
  Ops.push_back(DAG.getRegisterMask(Mask));

  if (Glue.getNode())
    Ops.push_back(Glue);

  // TODO(Phase 3 continuation): direct (GlobalAddress callee, -> CALL)
  // vs indirect (register callee, -> ICALL) opcode dispatch happens in
  // LVXISelDAGToDAG::Select when it pattern-matches this LVXISD::CALL
  // node -- see the TODO already there.
  Chain = DAG.getNode(LVXISD::CALL, DL, DAG.getVTList(MVT::Other, MVT::Glue),
                      Ops);
  Glue = Chain.getValue(1);

  Chain = DAG.getCALLSEQ_END(Chain, NumBytes, 0, Glue, DL);
  Glue = Chain.getValue(1);

  // ---- Analyze and reassemble the return value(s), mirroring
  // LowerFormalArguments' reassembly logic exactly (CC_LVXRet has no
  // CCCustom straddle splitting, so this side stays one CCValAssign per
  // Ins[i] -- no grouping/BUILD_PAIR/BUILD_VECTOR needed here, unlike
  // the CC_LVX argument side above). ----
  if (!Ins.empty()) {
    SmallVector<CCValAssign, 8> RVLocs;
    CCState RetCCInfo(CallConv, IsVarArg, MF, RVLocs, *DAG.getContext());
    RetCCInfo.AnalyzeCallResult(Ins, CC_LVXRet);

    for (const CCValAssign &VA : RVLocs) {
      assert(VA.isRegLoc() &&
             "Return values must be in registers per CC_LVXRet");
      SDValue RetVal =
          DAG.getCopyFromReg(Chain, DL, VA.getLocReg(), VA.getLocVT(), Glue);
      Chain = RetVal.getValue(1);
      Glue = RetVal.getValue(2);
      // Out of the slot and back into the value's own type, exactly as the
      // argument side does. CC_LVXRet promotes a narrow return the same way
      // CC_LVX promotes a narrow argument, so handing the caller the raw
      // 64-bit slot is a type mismatch -- "LowerCall emitted a value with
      // the wrong type" on the first _Float16-returning call.
      if (VA.getValVT() != VA.getLocVT())
        RetVal = truncateFromSlot(DAG, DL, RetVal, VA.getValVT());
      InVals.push_back(RetVal);
    }
  }

  return Chain;
}
