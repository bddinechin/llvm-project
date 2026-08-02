//===-- LVXInstrInfo.td - LVX Instruction Selection -------*- tablegen -*-===//
//
// The hand-written half of the LVX target description: the SelectionDAG
// nodes, the call-frame pseudos, the processor model, and the instruction
// selection patterns.
//
// Everything that the machine description already states -- every
// instruction format, every opcode, every operand type, every bit of every
// encoding -- is GENERATED from lvx-mds by MDS/BE/LLVM and included below as
// LVXInstrFormats.td (operand types) and LVXInstrEncodings.td (format classes
// and instruction defs).  Do not add instruction defs here: add them to the
// ISA description in lvx-mds/lvx-family and regenerate.
//
// Generated instruction names are <INSTRUCTION>_<format>, with the execution
// unit stripped from the format -- ADDD_DWRR0 is "addd $rW = $rZ, $rY"
// (ALU_DWRR0), ADDD_DWRI is the 10-bit-immediate form, and ADDD_DWRI_X /
// ADDD_DWRI_Y are its 37-bit and 64-bit widened forms.  The same mnemonic
// has up to five encodings, so the format is part of the name.
//
// Immediate extensions.  A widened instruction prefixes one or two extension
// syllables to the base one and spends them on immediate bits:
//
//   addd $rW = $rZ, imm10     ADDD_DWRI      32 bits, simm10
//   addd $rW = $rZ, imm37     ADDD_DWRI_X    64 bits, simm37 (upper27+lower10)
//   addd $rW = $rZ, imm64     ADDD_DWRI_Y    96 bits, wimm64 (+extend27)
//   addd $rW = $rZ, imm32     ADDD_DWRR0_M   64 bits, wimm32 in place of $rY,
//                                            plus the ".@" splat modifier
//
// The assembler spells all of them "addd" and picks by immediate magnitude,
// so the widened forms need no new mnemonic -- only a wider operand class.
//
//===----------------------------------------------------------------------===//

include "LVXRegisterInfo.td"
include "LVXInstrFormats.td"

//===----------------------------------------------------------------------===//
// LVX-specific SelectionDAG nodes
//
// Every target needs at least these custom nodes to implement call/return
// lowering: a CALL node (the actual call instruction, gluing the callee
// address and argument registers together) and a glued return node (so
// LowerReturn can tie the return values to the RET instruction).
// CALLSEQ_START/CALLSEQ_END are generic ISD nodes already declared in
// TargetSelectionDAG.td and need no LVX-specific wrapper. Modeled directly
// on Lanai's Call/RetGlue (confirmed current via LanaiInstrInfo.td in this
// checkout).
//===----------------------------------------------------------------------===//

def SDT_LVXCall : SDTypeProfile<0, -1, [SDTCisVT<0, i64>]>;
def LVXcall : SDNode<"LVXISD::CALL", SDT_LVXCall,
                     [SDNPHasChain, SDNPOptInGlue, SDNPOutGlue,
                      SDNPVariadic]>;

// RET_GLUE: return with glue. SDTNone with SDNPHasChain|SDNPOptInGlue|
// SDNPVariadic is the correct pattern (per RISC-V's riscv_ret_glue,
// MSP430's retflag, etc.) -- SDTNone means no additional type constraints
// on the variadic operands (the outgoing return-value register copies),
// not that the node takes zero operands. Our earlier attempt to use
// SDTypeProfile<0,-1,[]> instead was wrong: it generates an out-of-bounds
// type constraint table index in LVXGenSDNodeInfo.inc, causing a segfault
// in verifyTargetNode. The original SDTNone was always the right choice.
def LVXretglue : SDNode<"LVXISD::RET_GLUE", SDTNone,
                        [SDNPHasChain, SDNPOptInGlue, SDNPVariadic]>;

//===----------------------------------------------------------------------===//
// Call-frame pseudo instructions
//
// Select targets for the generic ISD::CALLSEQ_START/CALLSEQ_END nodes
// LowerCall emits around every call. Unlike targets that adjust SP per
// call site, LVX's Outgoing Arguments region is sized once for the whole
// function (MFI.getMaxCallFrameSize(), baked into the frame by
// LVXFrameLowering's prologue/epilogue) — so these pseudos carry no real
// codegen effect; LVXFrameLowering::eliminateCallFramePseudoInstr just
// erases them post-selection. They still need to exist as real,
// selectable instructions, though: without them SelectionDAGISel has
// nothing to select CALLSEQ_START/END to at all and aborts.
//===----------------------------------------------------------------------===//

class LVXPseudo<dag outs, dag ins, string asmstr, list<dag> pattern>
    : Instruction {
  let Namespace = "LVX";
  let OutOperandList = outs;
  let InOperandList = ins;
  let AsmString = asmstr;
  let Pattern = pattern;
  let isPseudo = 1;
  let isCodeGenOnly = 1;
}

// ISD::CALLSEQ_START/END are target-independent nodes, but (per every
// target in this tree, e.g. ARC/Lanai's own callseq_start/callseq_end)
// have no globally predefined TableGen fragment name -- each target
// declares its own local SDNode wrapper with its pointer-sized type.
def SDT_LVXCallSeqStart : SDCallSeqStart<[SDTCisVT<0, i64>, SDTCisVT<1, i64>]>;
def SDT_LVXCallSeqEnd   : SDCallSeqEnd<[SDTCisVT<0, i64>, SDTCisVT<1, i64>]>;
def callseq_start : SDNode<"ISD::CALLSEQ_START", SDT_LVXCallSeqStart,
                           [SDNPHasChain, SDNPOutGlue]>;
def callseq_end   : SDNode<"ISD::CALLSEQ_END", SDT_LVXCallSeqEnd,
                           [SDNPHasChain, SDNPOptInGlue, SDNPOutGlue]>;

def ADJCALLSTACKDOWN : LVXPseudo<(outs), (ins i64imm:$amt1, i64imm:$amt2),
                                 "# ADJCALLSTACKDOWN $amt1, $amt2",
                                 [(callseq_start timm:$amt1, timm:$amt2)]>;
def ADJCALLSTACKUP : LVXPseudo<(outs), (ins i64imm:$amt1, i64imm:$amt2),
                               "# ADJCALLSTACKUP $amt1, $amt2",
                               [(callseq_end timm:$amt1, timm:$amt2)]>;

//===----------------------------------------------------------------------===//
// Subtarget features and processor model
//
// LVXGenSubtargetInfo.inc generation requires at least one ProcessorModel
// def to have something to parse. ProcessorModel's second template
// argument is a SchedMachineModel, not a ProcessorItineraries (a
// real TableGen type distinction caught at build time) -- GenericModel
// below is a placeholder with no real scheduling information yet. The
// itinerary classes themselves are generated from the machine
// description's Scheduling table, in LVXInstrEncodings.td.
//===----------------------------------------------------------------------===//

def GenericItineraries : ProcessorItineraries<[], [], []>;

def GenericModel : SchedMachineModel {
  let NoModel = 1;
  let CompleteModel = 0;
}

def : ProcessorModel<"generic", GenericModel, []>;

//===----------------------------------------------------------------------===//
// The generated instruction description
//===----------------------------------------------------------------------===//

include "LVXInstrEncodings.td"

//===----------------------------------------------------------------------===//
// COPYD: synthetic register-to-register copy, per lvx_Synthetic.yml
//
// "COPYD %0 %1 = %2" specializes IORD_DWRI (rW = imm | rZ) with imm fixed
// to 0, i.e. COPYD $rW, $rZ  ==>  iord $rW = 0, $rZ  ==>  rW = 0 | rZ = rZ.
// It shares IORD_DWRI's exact encoding but exposes only $rW/$rZ as
// operands -- the immediate is hardcoded rather than user-supplied, and the
// assembly string omits it entirely, matching the synthetic instruction's
// own two-operand syntax.
//
// It stays hand-written because it is a Synthetic, not an Opcode: MDS keeps
// it in Synthetic.yml, which BE/LLVM does not emit from.
//
// This is the instruction LVXISelLowering (LowerFormalArguments/LowerCall)
// emits to realign mis-aligned i128/v4i64 argument pieces into a true
// GPR128/GPR256 register tuple: per the ABI doc, "some multi-register
// arguments may end up in mis-aligned register tuples. It is the callee's
// responsibility to move such arguments into well-aligned register tuples
// before using them as operands of wide load-store and SIMD instructions"
// (and the caller's responsibility on the outgoing side) -- moving one
// 64-bit register at a time via COPYD is exactly that mechanism.
//===----------------------------------------------------------------------===//

def COPYD : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ),
                      "copyd $rW = $rZ", [], ALU_TINY> {
  bits<6> rW;
  bits<6> rZ;
  let Inst{30-29} = 0b11;
  let Inst{28}    = 0b0;
  let Inst{27-24} = 0b1010; // IORD_DWRI's opcode
  let Inst{23-18} = rW;
  let Inst{17-16} = 0b00;
  let Inst{15-6}  = 0;      // imm, hardcoded to 0
  let Inst{5-0}   = rZ;
}

//===----------------------------------------------------------------------===//
// Instruction selection patterns
//
// The generated defs carry no patterns -- MDS describes what an instruction
// encodes and computes, not which DAG shape should select it -- so every
// pattern lives here.
//===----------------------------------------------------------------------===//

// ---- Materializing a constant ---------------------------------------------
//
// "maked $rW = imm" in the width that holds it: 16 bits in one syllable, 43
// in two, 64 in three. Same narrowest-first ordering as the binary-operation
// immediates below, for the same reason.

def : Pat<(simm16imm:$imm), (MAKED_DWI   simm16imm:$imm)>;
def : Pat<(simm43imm:$imm), (MAKED_DWI_X simm43imm:$imm)>;
def : Pat<(wimm64imm:$imm), (MAKED_DWI_Y wimm64imm:$imm)>;

// ---- Integer arithmetic and logic, register-register ----------------------

def : Pat<(add  GPR:$rY, GPR:$rZ), (ADDD_DWRR0  GPR:$rZ, GPR:$rY)>;
def : Pat<(sub  GPR:$rY, GPR:$rZ), (SBFD_DWRR0  GPR:$rY, GPR:$rZ)>;
def : Pat<(smin GPR:$rY, GPR:$rZ), (MIND_DWRR0  GPR:$rZ, GPR:$rY)>;
def : Pat<(smax GPR:$rY, GPR:$rZ), (MAXD_DWRR0  GPR:$rZ, GPR:$rY)>;
def : Pat<(umin GPR:$rY, GPR:$rZ), (MINUD_DWRR0 GPR:$rZ, GPR:$rY)>;
def : Pat<(umax GPR:$rY, GPR:$rZ), (MAXUD_DWRR0 GPR:$rZ, GPR:$rY)>;
def : Pat<(and  GPR:$rY, GPR:$rZ), (ANDD_DWRR0  GPR:$rZ, GPR:$rY)>;
def : Pat<(or   GPR:$rY, GPR:$rZ), (IORD_DWRR0  GPR:$rZ, GPR:$rY)>;
def : Pat<(xor  GPR:$rY, GPR:$rZ), (EORD_DWRR0  GPR:$rZ, GPR:$rY)>;

// ---- Integer arithmetic and logic, register-immediate ---------------------
//
// Three widths per operation, tried widest-last: the 10-bit form fits in one
// syllable, the 37-bit form costs a second, the 64-bit form a third.  LLVM
// picks the first whose ImmLeaf predicate accepts the constant, and the
// predicates are nested ranges, so listing them narrowest-first selects the
// shortest encoding that can hold the value.  Without the widened forms
// every constant above 10 bits would need a separate MAKE into a scratch
// register first.
multiclass BinOpImm<SDPatternOperator node, Instruction i10, Instruction i37,
                    Instruction i64> {
  def : Pat<(node GPR:$rZ, simm10imm:$imm), (i10 GPR:$rZ, simm10imm:$imm)>;
  def : Pat<(node GPR:$rZ, simm37imm:$imm), (i37 GPR:$rZ, simm37imm:$imm)>;
  def : Pat<(node GPR:$rZ, wimm64imm:$imm), (i64 GPR:$rZ, wimm64imm:$imm)>;
}

defm : BinOpImm<add,  ADDD_DWRI,  ADDD_DWRI_X,  ADDD_DWRI_Y>;
defm : BinOpImm<smin, MIND_DWRI,  MIND_DWRI_X,  MIND_DWRI_Y>;
defm : BinOpImm<smax, MAXD_DWRI,  MAXD_DWRI_X,  MAXD_DWRI_Y>;
defm : BinOpImm<umin, MINUD_DWRI, MINUD_DWRI_X, MINUD_DWRI_Y>;
defm : BinOpImm<umax, MAXUD_DWRI, MAXUD_DWRI_X, MAXUD_DWRI_Y>;
defm : BinOpImm<and,  ANDD_DWRI,  ANDD_DWRI_X,  ANDD_DWRI_Y>;
defm : BinOpImm<or,   IORD_DWRI,  IORD_DWRI_X,  IORD_DWRI_Y>;
defm : BinOpImm<xor,  EORD_DWRI,  EORD_DWRI_X,  EORD_DWRI_Y>;

// ---- Shifts and rotates ---------------------------------------------------

def : Pat<(shl  GPR:$rY, GPR:$rZ), (SLLD_DSWRR GPR:$rY, GPR:$rZ)>;
def : Pat<(sra  GPR:$rY, GPR:$rZ), (SRAD_DSWRR GPR:$rY, GPR:$rZ)>;
def : Pat<(srl  GPR:$rY, GPR:$rZ), (SRLD_DSWRR GPR:$rY, GPR:$rZ)>;
def : Pat<(rotl GPR:$rY, GPR:$rZ), (ROLD_DSWRR GPR:$rY, GPR:$rZ)>;
def : Pat<(rotr GPR:$rY, GPR:$rZ), (RORD_DSWRR GPR:$rY, GPR:$rZ)>;

def : Pat<(shl  GPR:$rZ, uimm6imm:$imm), (SLLD_DSWRI GPR:$rZ, uimm6imm:$imm)>;
def : Pat<(sra  GPR:$rZ, uimm6imm:$imm), (SRAD_DSWRI GPR:$rZ, uimm6imm:$imm)>;
def : Pat<(srl  GPR:$rZ, uimm6imm:$imm), (SRLD_DSWRI GPR:$rZ, uimm6imm:$imm)>;
def : Pat<(rotl GPR:$rZ, uimm6imm:$imm), (ROLD_DSWRI GPR:$rZ, uimm6imm:$imm)>;
def : Pat<(rotr GPR:$rZ, uimm6imm:$imm), (RORD_DSWRI GPR:$rZ, uimm6imm:$imm)>;

// ---- Sign extension from a narrower width ---------------------------------
//
// "extfs $rW = $rZ, stop, start" extracts bits [stop:start] of $rZ, sign
// extending from the stop bit -- so sign-extending a value that is really n
// bits wide is the field [n-1:0]. This is what a signext parameter or return
// value needs, and what the type legalizer asks for as sext_inreg.
def : Pat<(sext_inreg GPR:$rZ, i8),  (EXTFS_BFWR GPR:$rZ,  7, 0)>;
def : Pat<(sext_inreg GPR:$rZ, i16), (EXTFS_BFWR GPR:$rZ, 15, 0)>;
def : Pat<(sext_inreg GPR:$rZ, i32), (EXTFS_BFWR GPR:$rZ, 31, 0)>;

// ---- Unary integer --------------------------------------------------------

def : Pat<(ineg  GPR:$rZ), (NEGD_DBWR GPR:$rZ)>;
def : Pat<(abs   GPR:$rZ), (ABSD_DBWR GPR:$rZ)>;
def : Pat<(ctlz  GPR:$rZ), (CLZD_DBWR GPR:$rZ)>;
def : Pat<(cttz  GPR:$rZ), (CTZD_DBWR GPR:$rZ)>;
def : Pat<(ctpop GPR:$rZ), (CBSD_DBWR GPR:$rZ)>;
def : Pat<(not   GPR:$rZ), (NOTD_DBWR GPR:$rZ)>;

// ---- Conditional move -----------------------------------------------------
//
// "cmoved.dnez $rZ? $rW = $rY" overwrites $rW with $rY when $rZ is non-zero
// and leaves it alone otherwise, so a select is: start with the false value
// in $rW, then conditionally take the true one. $rWsrc is the tied input
// carrying that starting value.
//
// The write being conditional is exactly why $rW is tied -- see the
// CMOVED entry in LVXInstrEncodings.td, whose Constraints the machine
// description's "(IF ... (COMMIT %1) (SKIP))" is what produces.
def : Pat<(select GPR:$rZ, GPR:$rY, GPR:$rW),
          (CMOVED_DCMWRR GPR:$rW, GPR:$rZ, GPR:$rY, 5 /* .dnez */)>;

// ---- Control flow ---------------------------------------------------------
//
// CALL has no declarative pattern: binding the LVXcall pseudo-node's callee
// operand to the PC-relative brtarget27s2 (direct call to a global symbol)
// versus ICALL_IBC's register operand (indirect call) depends on the
// callee's DAG node kind, which is selection logic and lives in
// LVXISelDAGToDAG::Select.
def : Pat<(br bb:$target), (GOTO_UB brtarget27s2:$target)>;
def : Pat<(LVXretglue), (RET_RTS)>;

// ---- Stores ---------------------------------------------------------------
//
// The generated store formats order their operands offset-then-base-then-
// data, matching the assembly syntax "sd off[$rZ] = $rT".
def : Pat<(store GPR:$rT, (add GPR:$rZ, simm10imm:$off)),
          (SW_SSBO simm10imm:$off, GPR:$rZ, GPR:$rT)>;
def : Pat<(store GPR:$rT, (add GPR:$rZ, simm10imm:$off)),
          (SD_SSBO simm10imm:$off, GPR:$rZ, GPR:$rT)>;

//===----------------------------------------------------------------------===//
// Mandatory pointer-register-class override (LLVM requires every target to
// supply this since the PointerLikeRegClass overrides became mandatory;
// see PR #159882 "CodeGen: Make target overrides of PointerLikeRegClass
// mandatory"). This tells the standard pseudo-instructions defined in
// Target.td (LOAD_STACK_GUARD, PREALLOCATED_ARG, PATCHABLE_EVENT_CALL,
// etc.) which concrete register class to use in place of the generic
// ptr_rc placeholder — for LVX, pointers live in GPR.
//===----------------------------------------------------------------------===//

defm : RemapAllTargetPseudoPointerOperands<GPR>;

//===----------------------------------------------------------------------===//
// Instruction info class (required by LLVM)
//===----------------------------------------------------------------------===//

def LVXInstrInfo : InstrInfo;
