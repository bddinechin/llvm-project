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

// f32 <-> raw GPR bits. LVX keeps f32 in the low 32 bits of a 64-bit GPR, so
// moving between an f32 value and the i64 argument/return slot that carries
// it is a pure reinterpretation -- the same register, no instruction.
//
// ISD::BITCAST cannot express it: bitcasting f32 to i64 is a size mismatch,
// and going via i32 does not work either because i32 is not a legal type here
// (only i64 is), so the legalizer lowers the i32 bitcast through MEMORY. That
// is not merely slow -- it silently dropped the conversion entirely, turning
// "fpext float to double" into a store/reload of the raw f32 bits with no
// FWIDENWD at all. These two nodes keep the reinterpretation in registers.
def SDT_LVXF32ToBits : SDTypeProfile<1, 1, [SDTCisVT<0, i64>, SDTCisVT<1, f32>]>;
def SDT_LVXBitsToF32 : SDTypeProfile<1, 1, [SDTCisVT<0, f32>, SDTCisVT<1, i64>]>;
def LVXf32tobits : SDNode<"LVXISD::F32_TO_BITS", SDT_LVXF32ToBits>;
def LVXbitstof32 : SDNode<"LVXISD::BITS_TO_F32", SDT_LVXBitsToF32>;

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

// Defs/Uses of the stack pointer are load-bearing even though these pseudos
// emit nothing. Without them the instructions define no register, so
// DeadMachineInstructionElim removes them between isel and PEI -- and PEI
// derives MFI.getMaxCallFrameSize() by walking for exactly these opcodes, so
// the outgoing-argument area silently ends up sized 0 and is never reserved
// in the frame. That stayed hidden while nothing else claimed the space (the
// outgoing stores just wrote below the locals into stack no one was using),
// and turned into corruption the moment the Frame Marker became a real
// frame object: the marker and the outgoing arguments were handed the same
// bytes, so storing argument 14 overwrote the saved caller FP.
let Defs = [R12], Uses = [R12] in {
def ADJCALLSTACKDOWN : LVXPseudo<(outs), (ins i64imm:$amt1, i64imm:$amt2),
                                 "# ADJCALLSTACKDOWN $amt1, $amt2",
                                 [(callseq_start timm:$amt1, timm:$amt2)]>;
def ADJCALLSTACKUP : LVXPseudo<(outs), (ins i64imm:$amt1, i64imm:$amt2),
                               "# ADJCALLSTACKUP $amt1, $amt2",
                               [(callseq_end timm:$amt1, timm:$amt2)]>;
}

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

// add/sub and the bitwise register-register forms are GENERATED from the
// machine description now -- see LVXInstrPatterns.td.  They were the ones
// whose operand placement is invisible in the assembly syntax, and the
// hand-written "sub" here had it backwards (100 - 7 evaluated to -93).
def : Pat<(smin GPR:$rY, GPR:$rZ), (MIND_DWRR0  GPR:$rZ, GPR:$rY)>;
def : Pat<(smax GPR:$rY, GPR:$rZ), (MAXD_DWRR0  GPR:$rZ, GPR:$rY)>;
def : Pat<(umin GPR:$rY, GPR:$rZ), (MINUD_DWRR0 GPR:$rZ, GPR:$rY)>;
def : Pat<(umax GPR:$rY, GPR:$rZ), (MAXUD_DWRR0 GPR:$rZ, GPR:$rY)>;

// ---- Multiply -------------------------------------------------------------
//
// One instruction, MULD, covers the low and all three high multiplies; which
// one you get is the `highmult` modifier. Its encoding is NOT the KVX one and
// is the opposite of the obvious guess -- lvx-refs Modifier.table gives
//
//   members = ".H .HU .HSU ."   over   values = "0 1 2 3"
//
// so **3 is the plain low multiply** (printing bare "muld") and 0/1/2 are the
// high forms. Instruction.yml's MULD execution is explicit:
//
//   if (highmult == 3) result1 = product.64[0];   // low half
//   else               result1 = product.64[1];   // high half
//
// with the operand extension chosen alongside it: case 1 is ZX*ZX, case 2 is
// SX*ZX, and the default (0, and 3) is SX*SX.
//
// Getting this backwards is silent wrong code, not a build failure: under the
// KVX convention ISD::MUL would select highmult=0 and every plain "a * b"
// would compile to a signed HIGH multiply.
//
// The low half is bit-identical for signed and unsigned operands, so one
// pattern covers signed and unsigned MUL alike. MULD is commutative, so the
// $rZ/$rY order carries no meaning here (unlike SBFD).
def : Pat<(mul   GPR:$rZ, GPR:$rY), (MULD_DMWRR GPR:$rZ, GPR:$rY, 3 /* low   */)>;
def : Pat<(mulhs GPR:$rZ, GPR:$rY), (MULD_DMWRR GPR:$rZ, GPR:$rY, 0 /* .h    */)>;
def : Pat<(mulhu GPR:$rZ, GPR:$rY), (MULD_DMWRR GPR:$rZ, GPR:$rY, 1 /* .hu   */)>;
// highmult=2 (".hsu", signed x unsigned) has no two-operand ISD node, so it
// gets no pattern.

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
// Types pinned to i64 rather than left as bare GPR: GPR now carries f64/f32
// as well, and ISD::SELECT is type-agnostic, so TableGen cannot infer which
// was meant. An FP select reaches the same instruction after a bitcast.
def : Pat<(select i64:$rZ, i64:$rY, i64:$rW),
          (CMOVED_DCMWRR i64:$rW, i64:$rZ, i64:$rY, 5 /* .dnez */)>;

// ---- Control flow ---------------------------------------------------------
//
// CALL has no declarative pattern: binding the LVXcall pseudo-node's callee
// operand to the PC-relative brtarget27s2 (direct call to a global symbol)
// versus ICALL_IBC's register operand (indirect call) depends on the
// callee's DAG node kind, which is selection logic and lives in
// LVXISelDAGToDAG::Select.
def : Pat<(br bb:$target), (GOTO_UB brtarget27s2:$target)>;
def : Pat<(LVXretglue), (RET_RTS)>;

// Indirect branch, which is what an expanded jump table lands on: the target
// address has already been loaded out of the table into a register. This is
// the only pattern BR_JT's expansion needs -- see the ISD::BR_JT Expand in
// LVXTargetLowering and the ISD::JumpTable case in LVXISelDAGToDAG::Select.
def : Pat<(brind i64:$addr), (IGOTO_IBC i64:$addr)>;

// ---- Stores ---------------------------------------------------------------
//
// The generated store formats order their operands offset-then-base-then-
// data, matching the assembly syntax "sd off[$rZ] = $rT".
// Pinned to i64 for the same type-inference reason as the select above.
// (These two are identical apart from the opcode, so only the first can ever
// match; they are dead in practice because LVXISelDAGToDAG::Select handles
// every store -- including the FP and narrower ones -- before the generated
// matcher runs.)
def : Pat<(store i64:$rT, (add i64:$rZ, simm10imm:$off)),
          (SW_SSBO simm10imm:$off, i64:$rZ, i64:$rT)>;
def : Pat<(store i64:$rT, (add i64:$rZ, simm10imm:$off)),
          (SD_SSBO simm10imm:$off, i64:$rZ, i64:$rT)>;

// ---- Floating point -------------------------------------------------------
//
// The generated FP formats take their operands in ISA order,
// "(ins GPR:$rZ, GPR:$rY, <modifiers>)" printed as "$rW = $rZ, $rY", so a
// pattern's first register operand is $rZ. floatmode=7 is the "no suffix"
// member: dynamic rounding from $cs.RM, matching RISC-V's DYN default.
// Conversions to integer pin floatmode=1 (.rz) because C truncates toward
// zero. fnegate=0 on the multiply/divide formats leaves the operand unnegated.
//
// FADDD/FMULD are commutative so operand order is free. The other two are
// not: FSBFD is "subtract FROM" -- f64_sub(RM, argument3, argument2) = rY - rZ
// -- so "a - b" needs rY=a and rZ=b, i.e. the operands swapped relative to
// the source. FDIVD is f64_div(RM, argument2, argument3) = rZ / rY, so "a / b"
// keeps them in source order. Getting either backwards is invisible in the
// assembly and only shows up as a wrong value.
def : Pat<(fadd f64:$a, f64:$b), (FADDD_FDADD f64:$a, f64:$b, 7)>;
def : Pat<(fsub f64:$a, f64:$b), (FSBFD_FDADD f64:$b, f64:$a, 7)>;
def : Pat<(fmul f64:$a, f64:$b), (FMULD_FDMUL f64:$a, f64:$b, 7, 0)>;
def : Pat<(fdiv f64:$a, f64:$b), (FDIVD_FDMUL f64:$a, f64:$b, 7, 0)>;
def : Pat<(fsqrt f64:$a),        (FSQRTD_FDMO0 f64:$a, 7)>;
def : Pat<(fneg f64:$a),         (FNEGD_FDMO1 f64:$a)>;
def : Pat<(fabs f64:$a),         (FABSD_FDMO1 f64:$a)>;

def : Pat<(fadd f32:$a, f32:$b), (FADDW_FWADD f32:$a, f32:$b, 7)>;
def : Pat<(fsub f32:$a, f32:$b), (FSBFW_FWADD f32:$b, f32:$a, 7)>;
def : Pat<(fmul f32:$a, f32:$b), (FMULW_FWMUL f32:$a, f32:$b, 7, 0)>;
def : Pat<(fdiv f32:$a, f32:$b), (FDIVW_FWMUL f32:$a, f32:$b, 7, 0)>;
def : Pat<(fsqrt f32:$a),        (FSQRTW_FWMO0 f32:$a, 7)>;
def : Pat<(fneg f32:$a),         (FNEGW_FWMO1 f32:$a)>;
def : Pat<(fabs f32:$a),         (FABSW_FWMO1 f32:$a)>;

// Fused multiply-add. FFMAD computes
//   result1 = f64_mulAdd(RM, argument3, argument2^fsign, argument1^fsign)
// i.e. rY * rZ + rW, accumulating into its own destination -- which the
// generated ALU_FDFMA_Inst models with a $rWsrc input tied to $rW. So
// ISD::FMA's third operand (the addend) binds to $rWsrc and the two
// multiplicands to $rZ/$rY; the product is commutative so their order is
// free. fnegate=0 leaves both negatable operands alone.
def : Pat<(fma f64:$a, f64:$b, f64:$c),
          (FFMAD_FDFMA f64:$c, f64:$a, f64:$b, 7, 0)>;
def : Pat<(fma f32:$a, f32:$b, f32:$c),
          (FFMAW_FWFMA f32:$c, f32:$a, f32:$b, 7, 0)>;

// FFMSD subtracts the product from the accumulator ("the product is
// subtracted from the %1"), which is c - a*b -- exactly fma(-a, b, c). Worth
// a pattern of its own: without it that shape costs a separate negate.
def : Pat<(fma (fneg f64:$a), f64:$b, f64:$c),
          (FFMSD_FDFMA f64:$c, f64:$a, f64:$b, 7, 0)>;
def : Pat<(fma (fneg f32:$a), f32:$b, f32:$c),
          (FFMSW_FWFMA f32:$c, f32:$a, f32:$b, 7, 0)>;

// Sign transfer. FSIGND is "(argument2 & 0x7FFF…) | (argument3 & 0x8000…)"
// -- magnitude from $rZ, sign from $rY -- which is exactly ISD::FCOPYSIGN's
// (magnitude, sign) operand order, so this maps directly.
//
// Historical note: these masks used to read 0x3FFF…, clearing exponent bit 62
// along with the sign, so copysign of any magnitude >= 2.0 returned +/-0.
// FCOPYSIGN was Expand until the ISA was corrected (verified on the ISS,
// 2026-08-04). If a copysign test ever regresses, check that mask first --
// and test with a magnitude that has bit 62 SET, because 1.0 and 0.5 give the
// right answer even with the broken mask.
def : Pat<(fcopysign f64:$mag, f64:$sgn), (FSIGND_FDMMWR f64:$mag, f64:$sgn)>;
def : Pat<(fcopysign f32:$mag, f32:$sgn), (FSIGNW_FWMMWR f32:$mag, f32:$sgn)>;

// Comparisons. floatcomp members: 0 .one, 1 .ueq, 2 .oeq, 3 .une, 4 .olt,
// 5 .uge, 6 .oge, 7 .ult. There is no GT/LE member, so those come from
// swapping the compared registers -- note the swapped patterns pass ($b, $a).
multiclass FCmpPat<ValueType vt, Instruction cmp> {
  def : Pat<(i64 (setcc vt:$a, vt:$b, SETOEQ)), (cmp vt:$a, vt:$b, 2)>;
  def : Pat<(i64 (setcc vt:$a, vt:$b, SETONE)), (cmp vt:$a, vt:$b, 0)>;
  def : Pat<(i64 (setcc vt:$a, vt:$b, SETOLT)), (cmp vt:$a, vt:$b, 4)>;
  def : Pat<(i64 (setcc vt:$a, vt:$b, SETOGE)), (cmp vt:$a, vt:$b, 6)>;
  def : Pat<(i64 (setcc vt:$a, vt:$b, SETUEQ)), (cmp vt:$a, vt:$b, 1)>;
  def : Pat<(i64 (setcc vt:$a, vt:$b, SETUNE)), (cmp vt:$a, vt:$b, 3)>;
  def : Pat<(i64 (setcc vt:$a, vt:$b, SETUGE)), (cmp vt:$a, vt:$b, 5)>;
  def : Pat<(i64 (setcc vt:$a, vt:$b, SETULT)), (cmp vt:$a, vt:$b, 7)>;
  def : Pat<(i64 (setcc vt:$a, vt:$b, SETOGT)), (cmp vt:$b, vt:$a, 4)>;
  def : Pat<(i64 (setcc vt:$a, vt:$b, SETOLE)), (cmp vt:$b, vt:$a, 6)>;
  def : Pat<(i64 (setcc vt:$a, vt:$b, SETUGT)), (cmp vt:$b, vt:$a, 7)>;
  def : Pat<(i64 (setcc vt:$a, vt:$b, SETULE)), (cmp vt:$b, vt:$a, 5)>;
  // The "don't care" condition codes, which ISDOpcodes.h defines as undefined
  // when an operand is NaN -- either member of each pair answers them. clang
  // emits a bare setne against a ConstantFP at -O0.
  def : Pat<(i64 (setcc vt:$a, vt:$b, SETEQ)), (cmp vt:$a, vt:$b, 2)>;
  def : Pat<(i64 (setcc vt:$a, vt:$b, SETNE)), (cmp vt:$a, vt:$b, 3)>;
  def : Pat<(i64 (setcc vt:$a, vt:$b, SETLT)), (cmp vt:$a, vt:$b, 4)>;
  def : Pat<(i64 (setcc vt:$a, vt:$b, SETGE)), (cmp vt:$a, vt:$b, 6)>;
  def : Pat<(i64 (setcc vt:$a, vt:$b, SETGT)), (cmp vt:$b, vt:$a, 4)>;
  def : Pat<(i64 (setcc vt:$a, vt:$b, SETLE)), (cmp vt:$b, vt:$a, 6)>;
}
defm : FCmpPat<f64, FCOMPD_FDCWRR>;
defm : FCmpPat<f32, FCOMPW_FWCWRR>;

// Conversions. i64 is the only legal integer type, so the narrower FIXED*/
// FLOAT* forms are never selected directly -- the type legalizer promotes i32
// conversions to these and truncates/extends around them.
def : Pat<(i64 (fp_to_sint f64:$a)), (FIXEDD_FDFIXED   f64:$a, 1)>;
def : Pat<(i64 (fp_to_uint f64:$a)), (FIXEDUD_FDFIXED  f64:$a, 1)>;
def : Pat<(i64 (fp_to_sint f32:$a)), (FIXEDWD_FDFIXED  f32:$a, 1)>;
def : Pat<(i64 (fp_to_uint f32:$a)), (FIXEDUWD_FDFIXED f32:$a, 1)>;
def : Pat<(f64 (sint_to_fp i64:$a)), (FLOATD_FDFLOAT   i64:$a, 7)>;
def : Pat<(f64 (uint_to_fp i64:$a)), (FLOATUD_FDFLOAT  i64:$a, 7)>;
def : Pat<(f32 (sint_to_fp i64:$a)), (FLOATDW_FWFLOAT  i64:$a, 7)>;
def : Pat<(f32 (uint_to_fp i64:$a)), (FLOATUDW_FWFLOAT i64:$a, 7)>;

// f32 <-> f64. FWIDENWD reads the f32 from the low half of its source when
// mostsig=0, which is where f32 values live here.
def : Pat<(f64 (fpextend f32:$a)), (FWIDENWD_FDWIDEN f32:$a, 0)>;
def : Pat<(f32 (fpround f64:$a)),  (FNARROWDW_FWWR   f64:$a, 7)>;

// Reinterpretations: FP and integer share the GPR file, so all of these are
// register-to-register.
def : Pat<(f64 (bitconvert i64:$a)), (COPY_TO_REGCLASS GPR:$a, GPR)>;
def : Pat<(i64 (bitconvert f64:$a)), (COPY_TO_REGCLASS GPR:$a, GPR)>;
def : Pat<(i64 (LVXf32tobits f32:$a)), (COPY_TO_REGCLASS GPR:$a, GPR)>;
def : Pat<(f32 (LVXbitstof32 i64:$a)), (COPY_TO_REGCLASS GPR:$a, GPR)>;

// Patterns generated from the machine description (BE/LLVM llvm-patterns.pl).
include "LVXInstrPatterns.td"

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
