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

  // 256-bit register-quad values. Without this, the type legalizer would
  // treat v4i64 as illegal and split/scalarize it before
  // LowerFormalArguments/LowerCall/LowerReturn ever see it, which would
  // conflict with the slot-splitting CC_LVX_Custom already performs at
  // the calling-convention level -- v4i64 must reach those functions
  // intact as a single legal type.
  addRegisterClass(MVT::v4i64, &LVX::GPR256RegClass);

  // Floating point lives in the SAME general-purpose registers as integers --
  // LVX has no separate FP register file, and every FPU instruction in the
  // generated encodings takes GPR operands. f32 values occupy the low 32 bits
  // of their GPR (the ISA's f32 operations zero-extend their result).
  addRegisterClass(MVT::f64, &LVX::GPRRegClass);
  addRegisterClass(MVT::f32, &LVX::GPRRegClass);

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

  // COMPD writes the comparison result zero-extended to a full double word
  // ("The boolean result extended to double word is stored into the %1"), so
  // a boolean really is 0 or 1 here. Saying so lets the generic combines use
  // a comparison result as an arithmetic value without re-masking it.
  setBooleanContents(ZeroOrOneBooleanContent);

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

  // There is no extending FP load and no truncating FP store: widening and
  // narrowing are separate instructions (FWIDENWD / FNARROWDW). Without these,
  // DAGCombiner folds "fpextend (load f32)" into a single f32->f64 EXTLOAD and
  // "store (fpround f64)" into an f64->f32 TRUNCSTORE, and the conversion is
  // then silently dropped -- the bits get moved but never converted.
  setLoadExtAction(ISD::EXTLOAD, MVT::f64, MVT::f32, Expand);
  setTruncStoreAction(MVT::f64, MVT::f32, Expand);

  // A ConstantFP has no immediate form -- LVXISelDAGToDAG materializes it as
  // an integer MAKE of the value's bit pattern, like any other constant.
  setOperationAction(ISD::ConstantFP, MVT::f64, Legal);
  setOperationAction(ISD::ConstantFP, MVT::f32, Legal);

  // FP and integer share the GPR file, so a same-width bitcast is at worst a
  // register move.
  setOperationAction(ISD::BITCAST, MVT::f64, Legal);
  setOperationAction(ISD::BITCAST, MVT::f32, Legal);
  setOperationAction(ISD::BITCAST, MVT::i64, Legal);

  setMinFunctionAlignment(Align(4));
  setPrefFunctionAlignment(Align(4));
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
  // Nothing routed here yet -- every IR construct currently reaching
  // LowerOperation should already be legal or handled by a TableGen
  // pattern. If this is hit, a new case needs to be added once a real
  // test program identifies what's missing.
  llvm_unreachable(
      "Unimplemented operation in LVXTargetLowering::LowerOperation");
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
  // TODO(Phase 5): real inline-asm register-class constraint parsing
  // (e.g. "r" -> GPR). Fall back to the generic implementation for now.
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
      InVals.push_back(RetVal);
    }
  }

  return Chain;
}
