//===-- LVXInstrInfo.td - LVX Instruction Definitions -----*- tablegen -*-===//
//
// Encoding spaces:
//   simple  = 32-bit instruction  (P always 0 for single-issue)
//   double  = 64-bit instruction  (.X suffix formats)
//   triple  = 96-bit instruction  (.Y suffix formats)
//
// Register naming convention in the table:
//   registerW/Y/Z  = 6-bit GPR  (GPR,  $r0..$r63)
//   registerT      = 6-bit GPR  store data source
//   registerM/O/P  = 5-bit pair (GPR128, $r0r1..$r62r63)
//   registerN/V    = 4-bit quad (GPR256, $r0r1r2r3..$r60r61r62r63)
//   registerU      = 5-bit pair (store of a pair)
//   registerR      = 4-bit quad (COPYO destination)
//   registerWe/Ye/Ze = 5-bit even GPR (COMPND even variant)
//   registerWo/Yo/Zo = 5-bit odd  GPR (COMPND odd  variant)
//
// The P bit (bit 31, always 0) is a parallel-issue bit reserved for the VLIW
// backend and is hardcoded to 0 for single-issue compilation.
//
// Modifier operand types are defined in LVXInstrFormats.td and correspond
// to entries in lvx_Modifier.yml. Assembly suffixes are dot-appended to the
// mnemonic, e.g. "addd", "addw.sx", "faddd.rn", "compd.lt", "muld.h".
//
// Naming convention for scalar integer widths:
//   D-suffix instructions (ALU_DW*, ALU_DB*, ALU_DD*) operate on 64-bit
//   (Double) values and produce a 64-bit result.
//   W-suffix instructions (ALU_WW*, ALU_WD*, ALU_BW*, ALU_WM*) operate on
//   the lower 32-bit (Word) halves of GPRs. The signextw modifier controls
//   how the 32-bit result is extended to 64-bit in the destination register:
//   sig=0 (default, no suffix) zero-extends; sig=1 (.sx) sign-extends.
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
// Scheduling classes (itinerary stubs — filled in during Phase 5)
//===----------------------------------------------------------------------===//

def GenericItineraries : ProcessorItineraries<[], [], []>;

//===----------------------------------------------------------------------===//
// Subtarget features and processor model
//
// LVXGenSubtargetInfo.inc generation requires at least one ProcessorModel
// def to have something to parse. ProcessorModel's second template
// argument is a SchedMachineModel, not a ProcessorItineraries (a
// real TableGen type distinction caught at build time) -- GenericModel
// below is a placeholder with no real scheduling information yet,
// matching the pattern used by minimal targets before a real scheduler
// model is written (Phase 5).
//===----------------------------------------------------------------------===//

def GenericModel : SchedMachineModel {
  let NoModel = 1;
  let CompleteModel = 0;
}

def : ProcessorModel<"generic", GenericModel, []>;

def ALU_TINY      : InstrItinClass;
def ALU_LITE      : InstrItinClass;
def ALU_FULL      : InstrItinClass;
def BCU_XFER      : InstrItinClass;
def BCU_BRRP      : InstrItinClass;
def BCU_BRRP2     : InstrItinClass;
def BCU_XFER_BRRP : InstrItinClass;
def BCU2          : InstrItinClass;
def BCU2_TINY_LSU : InstrItinClass;
def LSU           : InstrItinClass;
def LSU2_MEMW     : InstrItinClass;
def LSU_AUXW      : InstrItinClass;
def LSU_MEMW_AUXR : InstrItinClass;
def LSU_AUXR_AUXW : InstrItinClass;
def ALL           : InstrItinClass;

//===----------------------------------------------------------------------===//
// Non-modifier immediate operands
//===----------------------------------------------------------------------===//

// Immediate operands usable inside SelectionDAG patterns need a companion
// ImmLeaf predicate (not just an encoder/decoder) so -gen-dag-isel knows
// what kind of immediate node to match and how to range-check it. The
// Operand<i64> def is used for instruction encoding/asm printing; the
// ImmLeaf def below (suffix "imm") is what actually appears inside
// (set ...) patterns in place of a bare immediate.
def simm10 : Operand<i64> {
  let DecoderMethod = "decodeSImmOperand<10>";
}
def simm10imm : ImmLeaf<i64, [{ return isInt<10>(Imm); }]>;

def simm16 : Operand<i64> {
  let DecoderMethod = "decodeSImmOperand<16>";
}
def simm16imm : ImmLeaf<i64, [{ return isInt<16>(Imm); }]>;

def uimm6 : Operand<i64> {
  let DecoderMethod = "decodeUImmOperand<6>";
}
def uimm6imm : ImmLeaf<i64, [{ return isUInt<6>(Imm); }]>;

def uimm11 : Operand<i64>;   // sysnumber (SCALL) — not yet used in a pattern
def uimm2  : Operand<i64>;   // brknumb, misc 2-bit fields — not yet used in a pattern

// Bitfield operands — stopbit is a 6-bit logical field split across two
// physical locations in the encoding (2 low bits at [25:24], 4 high bits
// at [15:12]).  The encoder/decoder reconstruct the full value.
def stopbit_op : Operand<i64> {
  let EncoderMethod = "getStopBitOpValue";
  let DecoderMethod = "decodeStopBit";
}
def startbit_op : Operand<i64> {
  let DecoderMethod = "decodeUImmOperand<6>";
}

// PC-relative branch targets (instruction word offset, shifted left 2)
def brtarget11s2 : Operand<OtherVT> {
  let EncoderMethod = "encodePCRelTarget<11>";
  let DecoderMethod = "decodePCRelTarget<11>";
  let OperandType   = "OPERAND_PCREL";
}
def brtarget17s2 : Operand<OtherVT> {
  let EncoderMethod = "encodePCRelTarget<17>";
  let DecoderMethod = "decodePCRelTarget<17>";
  let OperandType   = "OPERAND_PCREL";
}
def brtarget27s2 : Operand<OtherVT> {
  let EncoderMethod = "encodePCRelTarget<27>";
  let DecoderMethod = "decodePCRelTarget<27>";
  let OperandType   = "OPERAND_PCREL";
}

//===----------------------------------------------------------------------===//
// Instruction format base class
//===----------------------------------------------------------------------===//

class LVXInst<dag outs, dag ins, string asmstr, list<dag> pattern,
              InstrItinClass itin>
    : Instruction {
  field bits<32> Inst;
  field bits<32> SoftFail = 0;
  let Namespace      = "LVX";
  let Size           = 4;
  let OutOperandList = outs;
  let InOperandList  = ins;
  let AsmString      = asmstr;
  let Pattern        = pattern;
  let Itinerary      = itin;
  let Inst{31}       = 0;   // P bit: always 0 for single-issue
}

//===----------------------------------------------------------------------===//
// Format classes
//
// Assembly string convention for modifier suffixes:
//   Modifiers with a "no-suffix" default (sig, fne, imu, con, mos, highmult,
//   widemult, floatmode, accesses, variant) are printed only when non-default,
//   so the mnemonic is written as e.g. "addd${sig}" and the PrintMethod emits
//   nothing for encoding 0.
//
//   Modifiers that always require a suffix (intcomp, floatcomp, ccbcomp,
//   bcucond, cachelev) use e.g. "compd${intcomp}".
//===----------------------------------------------------------------------===//

// ---------- ALU_DWI: rW = imm16 --------------------------------------------
// | 0 | 1 1 | 0 | opc4 | rW(6) | 0 0 | signed16 |
class ALU_DWI_Inst<bits<4> opc, string mnemonic, list<dag> pattern>
    : LVXInst<(outs GPR:$rW), (ins simm16:$imm),
              !strconcat(mnemonic, " $rW = $imm"),
              pattern, ALU_TINY> {
  bits<6>  rW;
  bits<16> imm;
  let Inst{30-29} = 0b11;
  let Inst{28}    = 0b0;
  let Inst{27-24} = opc;
  let Inst{23-18} = rW;
  let Inst{17-16} = 0b00;
  let Inst{15-0}  = imm;
}

// ---------- ALU_DWRI: rW = imm10, rZ ---------------------------------------
// | 0 | 1 1 | 0 | opc4 | rW(6) | 0 0 | signed10 | rZ(6) |
class ALU_DWRI_Inst<bits<4> opc, string mnemonic, list<dag> pattern>
    : LVXInst<(outs GPR:$rW), (ins simm10:$imm, GPR:$rZ),
              !strconcat(mnemonic, " $rW = $imm, $rZ"),
              pattern, ALU_TINY> {
  bits<6>  rW;
  bits<10> imm;
  bits<6>  rZ;
  let Inst{30-29} = 0b11;
  let Inst{28}    = 0b0;
  let Inst{27-24} = opc;
  let Inst{23-18} = rW;
  let Inst{17-16} = 0b00;
  let Inst{15-6}  = imm;
  let Inst{5-0}   = rZ;
}

// ---------- ALU_BFWR: rW = stop, start, rZ (bitfield) ----------------------
// | 0 | 1 1 | 0 | opc2 | stop[1:0] | rW(6) | 0 1 | stop[5:2] | start(6) | rZ(6) |
class ALU_BFWR_Inst<bits<2> opc, string mnemonic, list<dag> pattern>
    : LVXInst<(outs GPR:$rW), (ins stopbit_op:$stop, startbit_op:$start, GPR:$rZ),
              !strconcat(mnemonic, " $rW, $stop, $start, $rZ"),
              pattern, ALU_TINY> {
  bits<6> rW;
  bits<6> stop;
  bits<6> start;
  bits<6> rZ;
  let Inst{30-29} = 0b11;
  let Inst{28}    = 0b0;
  let Inst{27-26} = opc;
  let Inst{25-24} = stop{1-0};
  let Inst{23-18} = rW;
  let Inst{17-16} = 0b01;
  let Inst{15-12} = stop{5-2};
  let Inst{11-6}  = start;
  let Inst{5-0}   = rZ;
}

// ---------- ALU_DBMWRI: byte matrix immediate ------------------------------
class ALU_DBMWRI_Inst<bits<4> opc, string mnemonic, list<dag> pattern>
    : LVXInst<(outs GPR:$rW), (ins simm10:$imm, GPR:$rZ),
              !strconcat(mnemonic, " $rW = $imm, $rZ"),
              pattern, ALU_TINY> {
  bits<6>  rW;
  bits<10> imm;
  bits<6>  rZ;
  let Inst{30-29} = 0b11;
  let Inst{28}    = 0b0;
  let Inst{27-24} = opc;
  let Inst{23-18} = rW;
  let Inst{17-16} = 0b01;
  let Inst{15-6}  = imm;
  let Inst{5-0}   = rZ;
}

// ---------- ALU_DWRR0: rW = rY op rZ, subop=000, bit12=0 -------------------
// | 0 | 1 1 | 0 | opc4 | rW(6) | 1 0 | 0 0 0 | 0 | rY(6) | rZ(6) |
class ALU_DWRR0_Inst<bits<4> opc, string mnemonic, list<dag> pattern,
                     InstrItinClass itin = ALU_TINY>
    : LVXInst<(outs GPR:$rW), (ins GPR:$rY, GPR:$rZ),
              !strconcat(mnemonic, " $rW = $rY, $rZ"),
              pattern, itin> {
  bits<6> rW;
  bits<6> rY;
  bits<6> rZ;
  let Inst{30-29} = 0b11;
  let Inst{28}    = 0b0;
  let Inst{27-24} = opc;
  let Inst{23-18} = rW;
  let Inst{17-16} = 0b10;
  let Inst{15-13} = 0b000;
  let Inst{12}    = 0b0;
  let Inst{11-6}  = rY;
  let Inst{5-0}   = rZ;
}

// ---------- ALU_DCWRR: integer compare rW = intcomp(rY, rZ) ----------------
// | 0 | 1 1 | 0 | intcomp(4) | rW(6) | 1 0 | 0 0 1 | 0 | rY(6) | rZ(6) |
class ALU_DCWRR_Inst<string mnemonic, list<dag> pattern>
    : LVXInst<(outs GPR:$rW), (ins intcomp:$cmp, GPR:$rY, GPR:$rZ),
              !strconcat(mnemonic, "${cmp} $rW = $rY, $rZ"),
              pattern, ALU_TINY> {
  bits<4> cmp;
  bits<6> rW;
  bits<6> rY;
  bits<6> rZ;
  let Inst{30-29} = 0b11;
  let Inst{28}    = 0b0;
  let Inst{27-24} = cmp;
  let Inst{23-18} = rW;
  let Inst{17-16} = 0b10;
  let Inst{15-13} = 0b001;
  let Inst{12}    = 0b0;
  let Inst{11-6}  = rY;
  let Inst{5-0}   = rZ;
}

// ---------- ALU_DWRR2: logical double, subop=010, bit12=0 ------------------
class ALU_DWRR2_Inst<bits<4> opc, string mnemonic, list<dag> pattern>
    : LVXInst<(outs GPR:$rW), (ins GPR:$rY, GPR:$rZ),
              !strconcat(mnemonic, " $rW = $rY, $rZ"),
              pattern, ALU_TINY> {
  bits<6> rW;
  bits<6> rY;
  bits<6> rZ;
  let Inst{30-29} = 0b11;
  let Inst{28}    = 0b0;
  let Inst{27-24} = opc;
  let Inst{23-18} = rW;
  let Inst{17-16} = 0b10;
  let Inst{15-13} = 0b010;
  let Inst{12}    = 0b0;
  let Inst{11-6}  = rY;
  let Inst{5-0}   = rZ;
}

// ---------- ALU_DWRRS: saturating/abs double, subop=010, bit12=0 -----------
class ALU_DWRRS_Inst<bits<4> opc, string mnemonic, list<dag> pattern>
    : LVXInst<(outs GPR:$rW), (ins GPR:$rY, GPR:$rZ),
              !strconcat(mnemonic, " $rW = $rY, $rZ"),
              pattern, ALU_TINY> {
  bits<6> rW;
  bits<6> rY;
  bits<6> rZ;
  let Inst{30-29} = 0b11;
  let Inst{28}    = 0b0;
  let Inst{27-24} = opc;
  let Inst{23-18} = rW;
  let Inst{17-16} = 0b10;
  let Inst{15-13} = 0b010;
  let Inst{12}    = 0b0;
  let Inst{11-6}  = rY;
  let Inst{5-0}   = rZ;
}

// ---------- ALU_DCMWRR: conditional move ------------------------------------
// Per lvx_Format.yml: operands = [registerW(dest), registerZ(tested),
// registerY(source), cmovecond], syntax "%0%4 %2? %1 = %3" i.e.
// "<mnemonic><cond> rZ ? rW = rY" — rZ is tested against cmovecond,
// and if true, rY is moved into rW.
class ALU_DCMWRR_Inst<string mnemonic, list<dag> pattern>
    : LVXInst<(outs GPR:$rW), (ins cmovecond:$cond, GPR:$rZ, GPR:$rY),
              !strconcat(mnemonic, "${cond} $rZ? $rW = $rY"),
              pattern, ALU_LITE> {
  bits<4> cond;
  bits<6> rW;
  bits<6> rZ;
  bits<6> rY;
  let Inst{30-29} = 0b11;
  let Inst{28}    = 0b0;
  let Inst{27-24} = cond;
  let Inst{23-18} = rW;
  let Inst{17-16} = 0b10;
  let Inst{15-13} = 0b011;
  let Inst{12}    = 0b0;
  let Inst{11-6}  = rY;
  let Inst{5-0}   = rZ;
}

// ---------- ALU_DSWRR: shift/rotate double, reg amount ---------------------
// | 0 | 1 1 | 0 | dir(1) | opc3 | rW(6) | 1 0 | 1 0 0 | 0 | rY(6) | rZ(6) |
class ALU_DSWRR_Inst<bit dir, bits<3> opc, string mnemonic, list<dag> pattern,
                     InstrItinClass itin = ALU_TINY>
    : LVXInst<(outs GPR:$rW), (ins GPR:$rY, GPR:$rZ),
              !strconcat(mnemonic, " $rW = $rY, $rZ"),
              pattern, itin> {
  bits<6> rW;
  bits<6> rY;
  bits<6> rZ;
  let Inst{30-29} = 0b11;
  let Inst{28}    = 0b0;
  let Inst{27}    = dir;
  let Inst{26-24} = opc;
  let Inst{23-18} = rW;
  let Inst{17-16} = 0b10;
  let Inst{15-13} = 0b100;
  let Inst{12}    = 0b0;
  let Inst{11-6}  = rY;
  let Inst{5-0}   = rZ;
}

// ---------- ALU_DSWRI: shift/rotate double, imm amount ---------------------
class ALU_DSWRI_Inst<bit dir, bits<3> opc, string mnemonic, list<dag> pattern,
                     InstrItinClass itin = ALU_TINY>
    : LVXInst<(outs GPR:$rW), (ins uimm6:$shamt, GPR:$rZ),
              !strconcat(mnemonic, " $rW = $shamt, $rZ"),
              pattern, itin> {
  bits<6> rW;
  bits<6> shamt;
  bits<6> rZ;
  let Inst{30-29} = 0b11;
  let Inst{28}    = 0b1;
  let Inst{27}    = dir;
  let Inst{26-24} = opc;
  let Inst{23-18} = rW;
  let Inst{17-16} = 0b10;
  let Inst{15-13} = 0b100;
  let Inst{12}    = 0b0;
  let Inst{11-6}  = shamt;
  let Inst{5-0}   = rZ;
}

// ---------- ALU_DWRR1: scaled-add / saturating add double ------------------
class ALU_DWRR1_Inst<bits<4> opc, string mnemonic, list<dag> pattern>
    : LVXInst<(outs GPR:$rW), (ins GPR:$rY, GPR:$rZ),
              !strconcat(mnemonic, " $rW = $rY, $rZ"),
              pattern, ALU_TINY> {
  bits<6> rW;
  bits<6> rY;
  bits<6> rZ;
  let Inst{30-29} = 0b11;
  let Inst{28}    = 0b0;
  let Inst{27-24} = opc;
  let Inst{23-18} = rW;
  let Inst{17-16} = 0b10;
  let Inst{15-13} = 0b101;
  let Inst{12}    = 0b0;
  let Inst{11-6}  = rY;
  let Inst{5-0}   = rZ;
}

// ---------- ALU_DDMWRR: divmod double, pair dest ---------------------------
class ALU_DDMWRR_Inst<bits<4> opc, string mnemonic, list<dag> pattern>
    : LVXInst<(outs GPR128:$rM), (ins GPR:$rY, GPR:$rZ),
              !strconcat(mnemonic, " $rM = $rY, $rZ"),
              pattern, ALU_FULL> {
  bits<5> rM;
  bits<6> rY;
  bits<6> rZ;
  let Inst{30-29} = 0b11;
  let Inst{28}    = 0b0;
  let Inst{27-24} = opc;
  let Inst{23-19} = rM;
  let Inst{18}    = 0b0;
  let Inst{17-16} = 0b10;
  let Inst{15-13} = 0b101;
  let Inst{12}    = 0b0;
  let Inst{11-6}  = rY;
  let Inst{5-0}   = rZ;
}

// ---------- ALU_DBWR: unary double -----------------------------------------
// | 0 | 1 1 | 0 | 1 1 1 1 | rW(6) | 1 0 | 1 0 1 | 0 | subop(4) | 0 0 | rZ(6) |
class ALU_DBWR_Inst<bits<4> subop, string mnemonic, list<dag> pattern>
    : LVXInst<(outs GPR:$rW), (ins GPR:$rZ),
              !strconcat(mnemonic, " $rW = $rZ"),
              pattern, ALU_TINY> {
  bits<6> rW;
  bits<6> rZ;
  let Inst{30-29} = 0b11;
  let Inst{28}    = 0b0;
  let Inst{27-24} = 0b1111;
  let Inst{23-18} = rW;
  let Inst{17-16} = 0b10;
  let Inst{15-13} = 0b101;
  let Inst{12}    = 0b0;
  let Inst{11-8}  = subop;
  let Inst{7}     = 0b0;
  let Inst{6}     = 0b0;
  let Inst{5-0}   = rZ;
}

// ---------- ALU_DMWRR/DMWRRR: multiply double, highmult modifier -----------
// | 0 | 1 1 | 0 | mulop(2) | highmult(2) | rW(6) | 1 0 | 1 1 0 | 0 | rY | rZ |
class ALU_DMWRR_Inst<bits<2> mulop, string mnemonic, list<dag> pattern>
    : LVXInst<(outs GPR:$rW), (ins highmult:$hm, GPR:$rY, GPR:$rZ),
              !strconcat(mnemonic, "${hm} $rW = $rY, $rZ"),
              pattern, ALU_LITE> {
  bits<2> hm;
  bits<6> rW;
  bits<6> rY;
  bits<6> rZ;
  let Inst{30-29} = 0b11;
  let Inst{28}    = 0b0;
  let Inst{27-26} = mulop;
  let Inst{25-24} = hm;
  let Inst{23-18} = rW;
  let Inst{17-16} = 0b10;
  let Inst{15-13} = 0b110;
  let Inst{12}    = 0b0;
  let Inst{11-6}  = rY;
  let Inst{5-0}   = rZ;
}

// ---------- ALU_DMEWRR/DMEWRRR: widening multiply, widemult modifier --------
class ALU_DMEWRR_Inst<bits<2> mulop, string mnemonic, list<dag> pattern>
    : LVXInst<(outs GPR:$rW), (ins widemult:$wm, GPR:$rY, GPR:$rZ),
              !strconcat(mnemonic, "${wm} $rW = $rY, $rZ"),
              pattern, ALU_LITE> {
  bits<2> wm;
  bits<6> rW;
  bits<6> rY;
  bits<6> rZ;
  let Inst{30-29} = 0b11;
  let Inst{28}    = 0b0;
  let Inst{27-26} = mulop;
  let Inst{25-24} = wm;
  let Inst{23-18} = rW;
  let Inst{17-16} = 0b10;
  let Inst{15-13} = 0b111;
  let Inst{12}    = 0b0;
  let Inst{11-6}  = rY;
  let Inst{5-0}   = rZ;
}

// ---------- ALU_QWRR0: 128-bit quad binary, bit12=1 ------------------------
// | 0 | 1 1 | 0 | opc4 | rM(5) | _ | 1 0 | 0 0 0 | 1 | rO(5) | _ | rP(5) | _ |
class ALU_QWRR0_Inst<bits<4> opc, string mnemonic, list<dag> pattern>
    : LVXInst<(outs GPR128:$rM), (ins GPR128:$rO, GPR128:$rP),
              !strconcat(mnemonic, " $rM = $rO, $rP"),
              pattern, ALU_LITE> {
  bits<5> rM;
  bits<5> rO;
  bits<5> rP;
  let Inst{30-29} = 0b11;
  let Inst{28}    = 0b0;
  let Inst{27-24} = opc;
  let Inst{23-19} = rM;
  let Inst{18}    = 0b0;
  let Inst{17-16} = 0b10;
  let Inst{15-13} = 0b000;
  let Inst{12}    = 0b1;
  let Inst{11-7}  = rO;
  let Inst{6}     = 0b0;
  let Inst{5-1}   = rP;
  let Inst{0}     = 0b0;
}

// ---------- ALU_QCWRR: quad compare ----------------------------------------
class ALU_QCWRR_Inst<string mnemonic, list<dag> pattern>
    : LVXInst<(outs GPR128:$rM), (ins intcomp:$cmp, GPR128:$rO, GPR128:$rP),
              !strconcat(mnemonic, "${cmp} $rM = $rO, $rP"),
              pattern, ALU_LITE> {
  bits<4> cmp;
  bits<5> rM;
  bits<5> rO;
  bits<5> rP;
  let Inst{30-29} = 0b11;
  let Inst{28}    = 0b0;
  let Inst{27-24} = cmp;
  let Inst{23-19} = rM;
  let Inst{18}    = 0b0;
  let Inst{17-16} = 0b10;
  let Inst{15-13} = 0b001;
  let Inst{12}    = 0b1;
  let Inst{11-7}  = rO;
  let Inst{6}     = 0b0;
  let Inst{5-1}   = rP;
  let Inst{0}     = 0b0;
}

// ---------- ALU_QCMWRR: quad conditional move -------------------------------
// Per lvx_Format.yml: operands = [registerM(dest), registerZ(tested),
// registerO(source), cmovecond], syntax "%0%4 %2? %1 = %3" i.e.
// "<mnemonic><cond> rZ ? rM = rO" — rZ is tested against cmovecond,
// and if true, the 128-bit rO is moved into rM.
class ALU_QCMWRR_Inst<string mnemonic, list<dag> pattern>
    : LVXInst<(outs GPR128:$rM), (ins cmovecond:$cond, GPR:$rZ, GPR128:$rO),
              !strconcat(mnemonic, "${cond} $rZ? $rM = $rO"),
              pattern, ALU_LITE> {
  bits<4> cond;
  bits<5> rM;
  bits<5> rO;
  bits<6> rZ;
  let Inst{30-29} = 0b11;
  let Inst{28}    = 0b0;
  let Inst{27-24} = cond;
  let Inst{23-19} = rM;
  let Inst{18}    = 0b0;
  let Inst{17-16} = 0b10;
  let Inst{15-13} = 0b011;
  let Inst{12}    = 0b1;
  let Inst{11-7}  = rO;
  let Inst{6}     = 0b0;
  let Inst{5-0}   = rZ;
}

// ---------- ALU_QBWR: unary quad -------------------------------------------
class ALU_QBWR_Inst<bits<4> subop, string mnemonic, list<dag> pattern>
    : LVXInst<(outs GPR128:$rM), (ins GPR128:$rP),
              !strconcat(mnemonic, " $rM = $rP"),
              pattern, ALU_LITE> {
  bits<5> rM;
  bits<5> rP;
  let Inst{30-29} = 0b11;
  let Inst{28}    = 0b0;
  let Inst{27-24} = 0b1111;
  let Inst{23-19} = rM;
  let Inst{18}    = 0b0;
  let Inst{17-16} = 0b10;
  let Inst{15-13} = 0b101;
  let Inst{12}    = 0b1;
  let Inst{11-8}  = subop;
  let Inst{7}     = 0b0;
  let Inst{6}     = 0b0;
  let Inst{5-1}   = rP;
  let Inst{0}     = 0b0;
}

// ---------- ALU_WWRR0: 32-bit word binary, signextw controls result extension
// | 0 | 1 1 | 0 | opc4 | rW(6) | 1 1 | 0 0 0 | sig(1) | rY(6) | rZ(6) |
// sig=0: result zero-extended to 64-bit; sig=1: sign-extended to 64-bit.
class ALU_WWRR0_Inst<bits<4> opc, string mnemonic, list<dag> pattern,
                     InstrItinClass itin = ALU_TINY>
    : LVXInst<(outs GPR:$rW), (ins signextw:$sig, GPR:$rY, GPR:$rZ),
              !strconcat(mnemonic, "${sig} $rW = $rY, $rZ"),
              pattern, itin> {
  bits<1> sig;
  bits<6> rW;
  bits<6> rY;
  bits<6> rZ;
  let Inst{30-29} = 0b11;
  let Inst{28}    = 0b0;
  let Inst{27-24} = opc;
  let Inst{23-18} = rW;
  let Inst{17-16} = 0b11;
  let Inst{15-13} = 0b000;
  let Inst{12}    = sig;
  let Inst{11-6}  = rY;
  let Inst{5-0}   = rZ;
}

// ---------- ALU_WCWRR: 32-bit word compare, intcomp + signextw -------------
class ALU_WCWRR_Inst<string mnemonic, list<dag> pattern>
    : LVXInst<(outs GPR:$rW), (ins intcomp:$cmp, signextw:$sig,
                                   GPR:$rY, GPR:$rZ),
              !strconcat(mnemonic, "${cmp}${sig} $rW = $rY, $rZ"),
              pattern, ALU_TINY> {
  bits<4> cmp;
  bits<1> sig;
  bits<6> rW;
  bits<6> rY;
  bits<6> rZ;
  let Inst{30-29} = 0b11;
  let Inst{28}    = 0b0;
  let Inst{27-24} = cmp;
  let Inst{23-18} = rW;
  let Inst{17-16} = 0b11;
  let Inst{15-13} = 0b001;
  let Inst{12}    = sig;
  let Inst{11-6}  = rY;
  let Inst{5-0}   = rZ;
}

// ---------- ALU_WAVG: 32-bit word average, signextw modifier ---------------
class ALU_WAVG_Inst<bits<4> opc, string mnemonic, list<dag> pattern>
    : LVXInst<(outs GPR:$rW), (ins signextw:$sig, GPR:$rY, GPR:$rZ),
              !strconcat(mnemonic, "${sig} $rW = $rY, $rZ"),
              pattern, ALU_TINY> {
  bits<1> sig;
  bits<6> rW;
  bits<6> rY;
  bits<6> rZ;
  let Inst{30-29} = 0b11;
  let Inst{28}    = 0b0;
  let Inst{27-24} = opc;
  let Inst{23-18} = rW;
  let Inst{17-16} = 0b11;
  let Inst{15-13} = 0b001;
  let Inst{12}    = sig;
  let Inst{11-6}  = rY;
  let Inst{5-0}   = rZ;
}

// ---------- ALU_WWRR2: 32-bit word logical (no signextw — result is logical) 
class ALU_WWRR2_Inst<bits<4> opc, string mnemonic, list<dag> pattern>
    : LVXInst<(outs GPR:$rW), (ins GPR:$rY, GPR:$rZ),
              !strconcat(mnemonic, " $rW = $rY, $rZ"),
              pattern, ALU_TINY> {
  bits<6> rW;
  bits<6> rY;
  bits<6> rZ;
  let Inst{30-29} = 0b11;
  let Inst{28}    = 0b0;
  let Inst{27-24} = opc;
  let Inst{23-18} = rW;
  let Inst{17-16} = 0b11;
  let Inst{15-13} = 0b010;
  let Inst{12}    = 0b0;
  let Inst{11-6}  = rY;
  let Inst{5-0}   = rZ;
}

// ---------- ALU_WCWRRR: CRC word ops, subop=010, bit12=1 -------------------
class ALU_WCWRRR_Inst<bits<4> opc, string mnemonic, list<dag> pattern>
    : LVXInst<(outs GPR:$rW), (ins GPR:$rY, GPR:$rZ),
              !strconcat(mnemonic, " $rW = $rY, $rZ"),
              pattern, ALU_LITE> {
  bits<6> rW;
  bits<6> rY;
  bits<6> rZ;
  let Inst{30-29} = 0b11;
  let Inst{28}    = 0b0;
  let Inst{27-24} = opc;
  let Inst{23-18} = rW;
  let Inst{17-16} = 0b11;
  let Inst{15-13} = 0b010;
  let Inst{12}    = 0b1;
  let Inst{11-6}  = rY;
  let Inst{5-0}   = rZ;
}

// ---------- ALU_WWRRS: 32-bit word saturating/abs, signextw modifier -------
class ALU_WWRRS_Inst<bits<4> opc, string mnemonic, list<dag> pattern>
    : LVXInst<(outs GPR:$rW), (ins signextw:$sig, GPR:$rY, GPR:$rZ),
              !strconcat(mnemonic, "${sig} $rW = $rY, $rZ"),
              pattern, ALU_TINY> {
  bits<1> sig;
  bits<6> rW;
  bits<6> rY;
  bits<6> rZ;
  let Inst{30-29} = 0b11;
  let Inst{28}    = 0b0;
  let Inst{27-24} = opc;
  let Inst{23-18} = rW;
  let Inst{17-16} = 0b11;
  let Inst{15-13} = 0b010;
  let Inst{12}    = sig;
  let Inst{11-6}  = rY;
  let Inst{5-0}   = rZ;
}

// ---------- ALU_WSWRR: 32-bit word shift/rotate reg, signextw modifier -----
class ALU_WSWRR_Inst<bit dir, bits<3> opc, string mnemonic, list<dag> pattern,
                     InstrItinClass itin = ALU_TINY>
    : LVXInst<(outs GPR:$rW), (ins signextw:$sig, GPR:$rY, GPR:$rZ),
              !strconcat(mnemonic, "${sig} $rW = $rY, $rZ"),
              pattern, itin> {
  bits<1> sig;
  bits<6> rW;
  bits<6> rY;
  bits<6> rZ;
  let Inst{30-29} = 0b11;
  let Inst{28}    = 0b0;
  let Inst{27}    = dir;
  let Inst{26-24} = opc;
  let Inst{23-18} = rW;
  let Inst{17-16} = 0b11;
  let Inst{15-13} = 0b100;
  let Inst{12}    = sig;
  let Inst{11-6}  = rY;
  let Inst{5-0}   = rZ;
}

// ---------- ALU_WSWRI: 32-bit word shift/rotate imm, signextw modifier -----
class ALU_WSWRI_Inst<bit dir, bits<3> opc, string mnemonic, list<dag> pattern,
                     InstrItinClass itin = ALU_TINY>
    : LVXInst<(outs GPR:$rW), (ins signextw:$sig, uimm6:$shamt, GPR:$rZ),
              !strconcat(mnemonic, "${sig} $rW = $shamt, $rZ"),
              pattern, itin> {
  bits<1> sig;
  bits<6> rW;
  bits<6> shamt;
  bits<6> rZ;
  let Inst{30-29} = 0b11;
  let Inst{28}    = 0b1;
  let Inst{27}    = dir;
  let Inst{26-24} = opc;
  let Inst{23-18} = rW;
  let Inst{17-16} = 0b11;
  let Inst{15-13} = 0b100;
  let Inst{12}    = sig;
  let Inst{11-6}  = shamt;
  let Inst{5-0}   = rZ;
}

// ---------- ALU_WWRR1: 32-bit word scaled-add / saturating add, signextw ---
class ALU_WWRR1_Inst<bits<4> opc, string mnemonic, list<dag> pattern>
    : LVXInst<(outs GPR:$rW), (ins signextw:$sig, GPR:$rY, GPR:$rZ),
              !strconcat(mnemonic, "${sig} $rW = $rY, $rZ"),
              pattern, ALU_TINY> {
  bits<1> sig;
  bits<6> rW;
  bits<6> rY;
  bits<6> rZ;
  let Inst{30-29} = 0b11;
  let Inst{28}    = 0b0;
  let Inst{27-24} = opc;
  let Inst{23-18} = rW;
  let Inst{17-16} = 0b11;
  let Inst{15-13} = 0b101;
  let Inst{12}    = sig;
  let Inst{11-6}  = rY;
  let Inst{5-0}   = rZ;
}

// ---------- ALU_WDMWRR: 32-bit word divmod, pair dest, signextw modifier ---
class ALU_WDMWRR_Inst<bits<4> opc, string mnemonic, list<dag> pattern>
    : LVXInst<(outs GPR128:$rM), (ins signextw:$sig, GPR:$rY, GPR:$rZ),
              !strconcat(mnemonic, "${sig} $rM = $rY, $rZ"),
              pattern, ALU_FULL> {
  bits<1> sig;
  bits<5> rM;
  bits<6> rY;
  bits<6> rZ;
  let Inst{30-29} = 0b11;
  let Inst{28}    = 0b0;
  let Inst{27-24} = opc;
  let Inst{23-19} = rM;
  let Inst{18}    = 0b0;
  let Inst{17-16} = 0b11;
  let Inst{15-13} = 0b101;
  let Inst{12}    = sig;
  let Inst{11-6}  = rY;
  let Inst{5-0}   = rZ;
}

// ---------- ALU_BWRW: 32-bit word unary, signextw modifier -----------------
class ALU_BWRW_Inst<bits<4> subop, string mnemonic, list<dag> pattern>
    : LVXInst<(outs GPR:$rW), (ins signextw:$sig, GPR:$rZ),
              !strconcat(mnemonic, "${sig} $rW = $rZ"),
              pattern, ALU_TINY> {
  bits<1> sig;
  bits<6> rW;
  bits<6> rZ;
  let Inst{30-29} = 0b11;
  let Inst{28}    = 0b0;
  let Inst{27-24} = 0b1111;
  let Inst{23-18} = rW;
  let Inst{17-16} = 0b11;
  let Inst{15-13} = 0b101;
  let Inst{12}    = sig;
  let Inst{11-8}  = subop;
  let Inst{7}     = 0b0;
  let Inst{6}     = 0b0;
  let Inst{5-0}   = rZ;
}

// ---------- ALU_WMWRR/WMWRRR: 32-bit word multiply, highmult + signextw ----
class ALU_WMWRR_Inst<bits<2> mulop, string mnemonic, list<dag> pattern>
    : LVXInst<(outs GPR:$rW), (ins highmult:$hm, signextw:$sig,
                                   GPR:$rY, GPR:$rZ),
              !strconcat(mnemonic, "${hm}${sig} $rW = $rY, $rZ"),
              pattern, ALU_LITE> {
  bits<2> hm;
  bits<1> sig;
  bits<6> rW;
  bits<6> rY;
  bits<6> rZ;
  let Inst{30-29} = 0b11;
  let Inst{28}    = 0b0;
  let Inst{27-26} = mulop;
  let Inst{25-24} = hm;
  let Inst{23-18} = rW;
  let Inst{17-16} = 0b11;
  let Inst{15-13} = 0b110;
  let Inst{12}    = sig;
  let Inst{11-6}  = rY;
  let Inst{5-0}   = rZ;
}

//===----------------------------------------------------------------------===//
// Float format classes
//===----------------------------------------------------------------------===//

// ---------- ALU_FDADD / ALU_FWADD / ALU_FHADD: FP add/sub/compare ---------
// | 0 | 1 1 | 1 | 0 | floatmode(3) | rW(6) | fp_sub(2) | subop3 | 0 | rY | rZ |
// fp_sub: 00=double, 01=single, for half: 01 with bit12=1
class ALU_FDADD_Inst<bits<3> subop, bits<2> fp_sub, bit half,
                     string mnemonic, list<dag> pattern>
    : LVXInst<(outs GPR:$rW), (ins floatmode:$fm, GPR:$rY, GPR:$rZ),
              !strconcat(mnemonic, "${fm} $rW = $rY, $rZ"),
              pattern, ALU_LITE> {
  bits<3> fm;
  bits<6> rW;
  bits<6> rY;
  bits<6> rZ;
  let Inst{30-29} = 0b11;
  let Inst{28}    = 0b1;
  let Inst{27}    = 0b0;
  let Inst{26-24} = fm;
  let Inst{23-18} = rW;
  let Inst{17-16} = fp_sub;
  let Inst{15-13} = subop;
  let Inst{12}    = half;
  let Inst{11-6}  = rY;
  let Inst{5-0}   = rZ;
}

// ---------- ALU_FDCWRR / FWCWRR / FHCWRR: FP compare, floatcomp -----------
class ALU_FDCWRR_Inst<bits<2> fp_sub, bit half, string mnemonic,
                      list<dag> pattern>
    : LVXInst<(outs GPR:$rW), (ins floatcomp:$fc, GPR:$rY, GPR:$rZ),
              !strconcat(mnemonic, "${fc} $rW = $rY, $rZ"),
              pattern, ALU_LITE> {
  bits<3> fc;
  bits<6> rW;
  bits<6> rY;
  bits<6> rZ;
  let Inst{30-29} = 0b11;
  let Inst{28}    = 0b1;
  let Inst{27}    = 0b0;
  let Inst{26-24} = fc;
  let Inst{23-18} = rW;
  let Inst{17-16} = fp_sub;
  let Inst{15-13} = 0b010;
  let Inst{12}    = half;
  let Inst{11-6}  = rY;
  let Inst{5-0}   = rZ;
}

// ---------- ALU_FDMMWR / FWMMWR / FHMMWR: FP min/max -----------------------
// | 0 | 1 1 | 1 | 1 | opc3 | rW(6) | fp_sub(2) | 0 0 0 | half | rY | rZ |
class ALU_FDMMWR_Inst<bits<3> opc, bits<2> fp_sub, bit half,
                      string mnemonic, list<dag> pattern>
    : LVXInst<(outs GPR:$rW), (ins GPR:$rY, GPR:$rZ),
              !strconcat(mnemonic, " $rW = $rY, $rZ"),
              pattern, ALU_LITE> {
  bits<6> rW;
  bits<6> rY;
  bits<6> rZ;
  let Inst{30-29} = 0b11;
  let Inst{28}    = 0b1;
  let Inst{27}    = 0b1;
  let Inst{26-24} = opc;
  let Inst{23-18} = rW;
  let Inst{17-16} = fp_sub;
  let Inst{15-13} = 0b000;
  let Inst{12}    = half;
  let Inst{11-6}  = rY;
  let Inst{5-0}   = rZ;
}

// ---------- ALU_FDMO1 / FWMO1 / FHMO1: FP unary, no rounding mode ----------
// (fneg/fabs/fsrec/fsrsr/fclass — operations with a single defined result,
// no rounding ambiguity, hence no floatmode operand)
// | 0 | 1 1 | 1 | 1 | 1 1 1 | rW(6) | fp_sub(2) | 0 0 0 | half | subop(4) | _ | 0 | rZ |
class ALU_FDMO1_Inst<bits<4> subop, bits<2> fp_sub, bit half,
                     string mnemonic, list<dag> pattern,
                     InstrItinClass itin = ALU_LITE>
    : LVXInst<(outs GPR:$rW), (ins GPR:$rZ),
              !strconcat(mnemonic, " $rW = $rZ"),
              pattern, itin> {
  bits<6> rW;
  bits<6> rZ;
  let Inst{30-29} = 0b11;
  let Inst{28}    = 0b1;
  let Inst{27-24} = 0b1111;
  let Inst{23-18} = rW;
  let Inst{17-16} = fp_sub;
  let Inst{15-13} = 0b000;
  let Inst{12}    = half;
  let Inst{11-8}  = subop;
  let Inst{7}     = 0b0;
  let Inst{6}     = 0b0;
  let Inst{5-0}   = rZ;
}

// ---------- ALU_FDMO0 / FWMO0 / FHMO0: FP unary, explicit rounding mode ----
// (fsqrt/frint — operations whose result depends on the rounding mode)
// | 0 | 1 1 | 1 | 1 | floatmode(3) | rW(6) | fp_sub(2) | 0 0 1 | half | subop(4) | _ | 0 | rZ |
class ALU_FDMO0_Inst<bits<4> subop, bits<2> fp_sub, bit half,
                     string mnemonic, list<dag> pattern,
                     InstrItinClass itin = ALU_LITE>
    : LVXInst<(outs GPR:$rW), (ins floatmode:$fm, GPR:$rZ),
              !strconcat(mnemonic, "${fm} $rW = $rZ"),
              pattern, itin> {
  bits<3> fm;
  bits<6> rW;
  bits<6> rZ;
  let Inst{30-29} = 0b11;
  let Inst{28}    = 0b1;
  let Inst{27}    = 0b1;
  let Inst{26-24} = fm;
  let Inst{23-18} = rW;
  let Inst{17-16} = fp_sub;
  let Inst{15-13} = 0b001;
  let Inst{12}    = half;
  let Inst{11-8}  = subop;
  let Inst{7}     = 0b0;
  let Inst{6}     = 0b0;
  let Inst{5-0}   = rZ;
}

// ---------- ALU_FDFLOAT/FDFIXED/FWFLOAT etc.: FP convert, floatmode --------
class ALU_FDCVT_Inst<bits<4> subop, bits<2> fp_sub, bit half,
                     string mnemonic, list<dag> pattern>
    : LVXInst<(outs GPR:$rW), (ins floatmode:$fm, GPR:$rZ),
              !strconcat(mnemonic, "${fm} $rW = $rZ"),
              pattern, ALU_LITE> {
  bits<3> fm;
  bits<6> rW;
  bits<6> rZ;
  let Inst{30-29} = 0b11;
  let Inst{28}    = 0b1;
  let Inst{27}    = 0b1;
  let Inst{26-24} = fm;
  let Inst{23-18} = rW;
  let Inst{17-16} = fp_sub;
  let Inst{15-13} = 0b001;
  let Inst{12}    = half;
  let Inst{11-8}  = subop;
  let Inst{7}     = 0b0;
  let Inst{6}     = 0b0;
  let Inst{5-0}   = rZ;
}

// ---------- ALU_FDFMA / FWFMA / FHFMA: FP FMA, fnegate + floatmode ---------
// | 0 | 1 1 | 1 | fne(1) | floatmode(3) | rW(6) | fp_sub(2) | subop3 | half | rY | rZ |
class ALU_FDFMA_Inst<bits<3> subop, bits<2> fp_sub, bit half,
                     string mnemonic, list<dag> pattern,
                     InstrItinClass itin = ALU_LITE>
    : LVXInst<(outs GPR:$rW), (ins fnegate:$fne, floatmode:$fm,
                                   GPR:$rY, GPR:$rZ),
              !strconcat(mnemonic, "${fne}${fm} $rW = $rY, $rZ"),
              pattern, itin> {
  bits<1> fne;
  bits<3> fm;
  bits<6> rW;
  bits<6> rY;
  bits<6> rZ;
  let Inst{30-29} = 0b11;
  let Inst{28}    = 0b1;
  let Inst{27}    = fne;
  let Inst{26-24} = fm;
  let Inst{23-18} = rW;
  let Inst{17-16} = fp_sub;
  let Inst{15-13} = subop;
  let Inst{12}    = half;
  let Inst{11-6}  = rY;
  let Inst{5-0}   = rZ;
}

// ---------- ALU_FWCOP: complex FP ops, imultiply + conjugate + floatmode ---
// | 0 | 1 1 | 1 | imu(1) | floatmode(3) | rW(6) | 0 0 | subop2 | con(1) | 1 | rY | rZ |
class ALU_FWCOP_Inst<bits<2> subop, string mnemonic, list<dag> pattern>
    : LVXInst<(outs GPR:$rW), (ins imultiply:$imu, floatmode:$fm,
                                   conjugate:$con, GPR:$rY, GPR:$rZ),
              !strconcat(mnemonic, "${imu}${fm}${con} $rW = $rY, $rZ"),
              pattern, ALU_LITE> {
  bits<1> imu;
  bits<3> fm;
  bits<1> con;
  bits<6> rW;
  bits<6> rY;
  bits<6> rZ;
  let Inst{30-29} = 0b11;
  let Inst{28}    = 0b1;
  let Inst{27}    = imu;
  let Inst{26-24} = fm;
  let Inst{23-18} = rW;
  let Inst{17-16} = 0b00;
  let Inst{15-14} = subop;
  let Inst{13}    = con;
  let Inst{12}    = 0b1;
  let Inst{11-6}  = rY;
  let Inst{5-0}   = rZ;
}

// ---------- ALU_FDWIDEN / ALU_FWWIDEN: FP widen, mostsig modifier ----------
// | 0 | 1 1 | 1 | 1 | 1 1 1 | rW(6) | fp_sub(2) | 0 0 0 | half | 1 0 0 0 | mos(1) | 0 | rZ |
class ALU_FDWIDEN_Inst<bits<2> fp_sub, bit half, string mnemonic,
                       list<dag> pattern>
    : LVXInst<(outs GPR:$rW), (ins mostsig:$mos, GPR:$rZ),
              !strconcat(mnemonic, "${mos} $rW = $rZ"),
              pattern, ALU_LITE> {
  bits<1> mos;
  bits<6> rW;
  bits<6> rZ;
  let Inst{30-29} = 0b11;
  let Inst{28}    = 0b1;
  let Inst{27-24} = 0b1111;
  let Inst{23-18} = rW;
  let Inst{17-16} = fp_sub;
  let Inst{15-13} = 0b000;
  let Inst{12}    = half;
  let Inst{11-8}  = 0b1000;
  let Inst{7}     = mos;
  let Inst{6}     = 0b0;
  let Inst{5-0}   = rZ;
}

//===----------------------------------------------------------------------===//
// BCU format classes
//===----------------------------------------------------------------------===//

class BCU_UB_Inst<bits<2> opc, string mnemonic, list<dag> pattern,
                  InstrItinClass itin>
    : LVXInst<(outs), (ins brtarget27s2:$target),
              !strconcat(mnemonic, " $target"),
              pattern, itin> {
  bits<27> target;
  let Inst{30-29} = 0b00;
  let Inst{28-27} = opc;
  let Inst{26-0}  = target;
}

class BCU_CB_Inst<string mnemonic, list<dag> pattern>
    : LVXInst<(outs), (ins bcucond:$cond, brtarget17s2:$target, GPR:$rZ),
              !strconcat(mnemonic, "${cond} $target, $rZ"),
              pattern, BCU_BRRP> {
  bits<4>  cond;
  bits<17> target;
  bits<6>  rZ;
  let Inst{30-29} = 0b00;
  let Inst{28-27} = 0b01;
  let Inst{26-23} = cond;
  let Inst{22-6}  = target;
  let Inst{5-0}   = rZ;
}

class BCU_CCB_Inst<string mnemonic, list<dag> pattern>
    : LVXInst<(outs), (ins ccbcomp:$cmp, brtarget11s2:$target,
                           GPR:$rY, GPR:$rZ),
              !strconcat(mnemonic, "${cmp} $target, $rY, $rZ"),
              pattern, BCU_BRRP2> {
  bits<4>  cmp;
  bits<11> target;
  bits<6>  rY;
  bits<6>  rZ;
  let Inst{30-29} = 0b00;
  let Inst{28-27} = 0b00;
  let Inst{26-23} = cmp;
  let Inst{22-12} = target;
  let Inst{11-6}  = rY;
  let Inst{5-0}   = rZ;
}

class BCU_IBC_Inst<bits<5> opc5, string mnemonic, list<dag> pattern,
                   InstrItinClass itin>
    : LVXInst<(outs), (ins GPR:$rZ),
              !strconcat(mnemonic, " $rZ"),
              pattern, itin> {
  bits<6> rZ;
  let Inst{30-29} = 0b00;
  let Inst{28-27} = 0b01;
  let Inst{26-23} = 0b1111;
  let Inst{22-18} = opc5;
  let Inst{17-6}  = 0;
  let Inst{5-0}   = rZ;
}

class BCU_RTS_Inst<bits<5> opc5, string mnemonic, list<dag> pattern,
                   InstrItinClass itin>
    : LVXInst<(outs), (ins), mnemonic, pattern, itin> {
  let Inst{30-29} = 0b00;
  let Inst{28-27} = 0b01;
  let Inst{26-23} = 0b1111;
  let Inst{22-18} = opc5;
  let Inst{17-0}  = 0;
}

class BCU_IPC_Inst<bits<5> opc5, string mnemonic, list<dag> pattern>
    : LVXInst<(outs), (ins), mnemonic, pattern, ALL> {
  let Inst{30-29} = 0b00;
  let Inst{28-27} = 0b01;
  let Inst{26-23} = 0b1111;
  let Inst{22-18} = opc5;
  let Inst{17-0}  = 0;
}

// ---------- BCU_SET: set a writeable control register (excl. $ra, $ps) ----
// Per lvx_Opcode.txt: P(1) 00(2) 01(2) 1111(4) 10000(5) ___(3) system(9) rZ(6)
// Total: 1+2+2+4+5+3+9+6 = 32 bits.
// All BCU_SET/SETRA/SETA/SETHW variants share this exact fixed-bit shape;
// they differ only in which control registers the 9-bit system-selector
// field is permitted to name. $ra and $ps are excluded from this format —
// they have their own dedicated formats below — so TableGen rejects e.g.
// "set $ra = $rZ" through this opcode at the operand-type level.
//
// The system field is 9 bits wide but every currently-defined control
// register's HWEncoding fits in the low 4 bits (LVXCtrlReg<4, ...>, values
// 0-6); the upper 5 bits of the field are fixed at 0 here. If LVX ever
// defines more than 16 control registers, or assigns one a HWEncoding
// using the upper bits, this class's `let Inst{9-6} = 0` line must be
// revisited.
class BCU_SET_Inst<string mnemonic, list<dag> pattern>
    : LVXInst<(outs), (ins CR_SET:$ctrl, GPR:$rZ),
              !strconcat(mnemonic, " $ctrl = $rZ"),
              pattern, BCU2> {
  bits<4> ctrl;   // CR_SET register's HWEncoding (4 bits)
  bits<6> rZ;
  let Inst{30-29} = 0b00;
  let Inst{28-27} = 0b01;
  let Inst{26-23} = 0b1111;
  let Inst{22-18} = 0b10000;
  let Inst{17-15} = 0b000;  // reserved / don't-care
  let Inst{14-10} = 0b00000; // upper 5 bits of the 9-bit system field
  let Inst{9-6}   = ctrl;    // low 4 bits of the system field
  let Inst{5-0}   = rZ;
}

// ---------- BCU_SETRA: set $ra only ----------------------------------------
class BCU_SETRA_Inst<string mnemonic, list<dag> pattern>
    : LVXInst<(outs), (ins CR_RA:$ctrl, GPR:$rZ),
              !strconcat(mnemonic, " $ctrl = $rZ"),
              pattern, BCU2> {
  bits<6> rZ;
  let Inst{30-29} = 0b00;
  let Inst{28-27} = 0b01;
  let Inst{26-23} = 0b1111;
  let Inst{22-18} = 0b10000;
  let Inst{17-15} = 0b000;
  let Inst{14-6}  = 0b000000000; // system field fixed: $ra, HWEncoding 0
  let Inst{5-0}   = rZ;
}

// ---------- BCU_SETPS: set $ps only ----------------------------------------
class BCU_SETPS_Inst<string mnemonic, list<dag> pattern>
    : LVXInst<(outs), (ins CR_PS:$ctrl, GPR:$rZ),
              !strconcat(mnemonic, " $ctrl = $rZ"),
              pattern, BCU2> {
  bits<6> rZ;
  let Inst{30-29} = 0b00;
  let Inst{28-27} = 0b01;
  let Inst{26-23} = 0b1111;
  let Inst{22-18} = 0b10000;
  let Inst{17-15} = 0b000;
  let Inst{14-10} = 0b00000;
  let Inst{9-6}   = 0b0010;  // system field fixed: $ps, HWEncoding 2
  let Inst{5-0}   = rZ;
}

//===----------------------------------------------------------------------===//
// LSU format classes
//===----------------------------------------------------------------------===//

// ---------- LSU_LSBO: load scalar, base+offset, variant modifier -----------
class LSU_LSBO_Inst<bits<3> opc, string mnemonic, list<dag> pattern>
    : LVXInst<(outs GPR:$rW), (ins variant:$var, simm10:$off, GPR:$rZ),
              !strconcat(mnemonic, "${var} $rW = [$rZ + $off]"),
              pattern, LSU_AUXW> {
  bits<2>  var;
  bits<6>  rW;
  bits<10> off;
  bits<6>  rZ;
  let Inst{30-29} = 0b01;
  let Inst{28-26} = opc;
  let Inst{25-24} = var;
  let Inst{23-18} = rW;
  let Inst{17-16} = 0b00;
  let Inst{15-6}  = off;
  let Inst{5-0}   = rZ;
}

// ---------- LSU_LSBI: load scalar, base+index, variant modifier ------------
class LSU_LSBI_Inst<bits<3> opc, string mnemonic, list<dag> pattern>
    : LVXInst<(outs GPR:$rW), (ins variant:$var, GPR:$rY, GPR:$rZ),
              !strconcat(mnemonic, "${var} $rW = [$rZ + $rY]"),
              pattern, LSU_AUXW> {
  bits<2> var;
  bits<6> rW;
  bits<6> rY;
  bits<6> rZ;
  let Inst{30-29} = 0b01;
  let Inst{28-26} = opc;
  let Inst{25-24} = var;
  let Inst{23-18} = rW;
  let Inst{17-16} = 0b10;
  let Inst{15-13} = 0b111;
  let Inst{12}    = 0b0;
  let Inst{11-6}  = rY;
  let Inst{5-0}   = rZ;
}

// ---------- LSU_LQBI: load pair, base+index, variant modifier --------------
// | 0 | 01 | 111 | variant(2) | rM(5) | 0 | 10 | 111 | _ | rY(6) | rZ(6) |
class LSU_LQBI_Inst<string mnemonic, list<dag> pattern>
    : LVXInst<(outs GPR128:$rM), (ins variant:$var, GPR:$rY, GPR:$rZ),
              !strconcat(mnemonic, "${var} $rM = [$rZ + $rY]"),
              pattern, LSU_AUXW> {
  bits<2> var;
  bits<5> rM;
  bits<6> rY;
  bits<6> rZ;
  let Inst{30-29} = 0b01;
  let Inst{28-26} = 0b111;
  let Inst{25-24} = var;
  let Inst{23-19} = rM;
  let Inst{18}    = 0b0;
  let Inst{17-16} = 0b10;
  let Inst{15-13} = 0b111;
  let Inst{12}    = 0b0;
  let Inst{11-6}  = rY;
  let Inst{5-0}   = rZ;
}

// ---------- LSU_LOBI: load quad (octuple), base+index, variant modifier ----
// | 0 | 01 | 111 | variant(2) | rN(4) | 0 | 1 | 10 | 111 | _ | rY(6) | rZ(6) |
class LSU_LOBI_Inst<string mnemonic, list<dag> pattern>
    : LVXInst<(outs GPR256:$rN), (ins variant:$var, GPR:$rY, GPR:$rZ),
              !strconcat(mnemonic, "${var} $rN = [$rZ + $rY]"),
              pattern, LSU_AUXW> {
  bits<2> var;
  bits<4> rN;
  bits<6> rY;
  bits<6> rZ;
  let Inst{30-29} = 0b01;
  let Inst{28-26} = 0b111;
  let Inst{25-24} = var;
  let Inst{23-20} = rN;
  let Inst{19}    = 0b0;
  let Inst{18}    = 0b1;
  let Inst{17-16} = 0b10;
  let Inst{15-13} = 0b111;
  let Inst{12}    = 0b0;
  let Inst{11-6}  = rY;
  let Inst{5-0}   = rZ;
}


class LSU_LQBO_Inst<string mnemonic, list<dag> pattern>
    : LVXInst<(outs GPR128:$rM), (ins variant:$var, simm10:$off, GPR:$rZ),
              !strconcat(mnemonic, "${var} $rM = [$rZ + $off]"),
              pattern, LSU_AUXW> {
  bits<2>  var;
  bits<5>  rM;
  bits<10> off;
  bits<6>  rZ;
  let Inst{30-29} = 0b01;
  let Inst{28-26} = 0b111;
  let Inst{25-24} = var;
  let Inst{23-19} = rM;
  let Inst{18}    = 0b0;
  let Inst{17-16} = 0b00;
  let Inst{15-6}  = off;
  let Inst{5-0}   = rZ;
}

// ---------- LSU_LOBO: load quad, base+offset, variant modifier -------------
class LSU_LOBO_Inst<string mnemonic, list<dag> pattern>
    : LVXInst<(outs GPR256:$rN), (ins variant:$var, simm10:$off, GPR:$rZ),
              !strconcat(mnemonic, "${var} $rN = [$rZ + $off]"),
              pattern, LSU_AUXW> {
  bits<2>  var;
  bits<4>  rN;
  bits<10> off;
  bits<6>  rZ;
  let Inst{30-29} = 0b01;
  let Inst{28-26} = 0b111;
  let Inst{25-24} = var;
  let Inst{23-20} = rN;
  let Inst{19}    = 0b0;
  let Inst{18}    = 0b1;
  let Inst{17-16} = 0b00;
  let Inst{15-6}  = off;
  let Inst{5-0}   = rZ;
}

// ---------- LSU_SSBO: store scalar -----------------------------------------
class LSU_SSBO_Inst<bits<5> opc, string mnemonic, list<dag> pattern>
    : LVXInst<(outs), (ins GPR:$rT, simm10:$off, GPR:$rZ),
              !strconcat(mnemonic, " [$rZ + $off] = $rT"),
              pattern, LSU_MEMW_AUXR> {
  bits<6>  rT;
  bits<10> off;
  bits<6>  rZ;
  let Inst{30-29} = 0b01;
  let Inst{28-24} = opc;
  let Inst{23-18} = rT;
  let Inst{17-16} = 0b01;
  let Inst{15-6}  = off;
  let Inst{5-0}   = rZ;
}

// ---------- LSU_SSBI: store scalar, base+index -----------------------------
// | 0 | 01 | opc5(5) | rT(6) | 11 | 111 | _ | rY(6) | rZ(6) |
class LSU_SSBI_Inst<bits<5> opc, string mnemonic, list<dag> pattern>
    : LVXInst<(outs), (ins GPR:$rT, GPR:$rY, GPR:$rZ),
              !strconcat(mnemonic, " [$rZ + $rY] = $rT"),
              pattern, LSU_MEMW_AUXR> {
  bits<6> rT;
  bits<6> rY;
  bits<6> rZ;
  let Inst{30-29} = 0b01;
  let Inst{28-24} = opc;
  let Inst{23-18} = rT;
  let Inst{17-16} = 0b11;
  let Inst{15-13} = 0b111;
  let Inst{12}    = 0b0;
  let Inst{11-6}  = rY;
  let Inst{5-0}   = rZ;
}


class LSU_SQBO_Inst<string mnemonic, list<dag> pattern>
    : LVXInst<(outs), (ins GPR128:$rU, simm10:$off, GPR:$rZ),
              !strconcat(mnemonic, " [$rZ + $off] = $rU"),
              pattern, LSU_MEMW_AUXR> {
  bits<5>  rU;
  bits<10> off;
  bits<6>  rZ;
  let Inst{30-29} = 0b01;
  let Inst{28-24} = 0b10100;
  let Inst{23-19} = rU;
  let Inst{18}    = 0b0;
  let Inst{17-16} = 0b01;
  let Inst{15-6}  = off;
  let Inst{5-0}   = rZ;
}

// ---------- LSU_SQBI: store pair, base+index --------------------------------
// | 0 | 01 | 10100 | rU(5) | 0 | 11 | 111 | _ | rY(6) | rZ(6) |
class LSU_SQBI_Inst<string mnemonic, list<dag> pattern>
    : LVXInst<(outs), (ins GPR128:$rU, GPR:$rY, GPR:$rZ),
              !strconcat(mnemonic, " [$rZ + $rY] = $rU"),
              pattern, LSU_MEMW_AUXR> {
  bits<5> rU;
  bits<6> rY;
  bits<6> rZ;
  let Inst{30-29} = 0b01;
  let Inst{28-24} = 0b10100;
  let Inst{23-19} = rU;
  let Inst{18}    = 0b0;
  let Inst{17-16} = 0b11;
  let Inst{15-13} = 0b111;
  let Inst{12}    = 0b0;
  let Inst{11-6}  = rY;
  let Inst{5-0}   = rZ;
}


class LSU_SOBO_Inst<string mnemonic, list<dag> pattern>
    : LVXInst<(outs), (ins GPR256:$rV, simm10:$off, GPR:$rZ),
              !strconcat(mnemonic, " [$rZ + $off] = $rV"),
              pattern, LSU_MEMW_AUXR> {
  bits<4>  rV;
  bits<10> off;
  bits<6>  rZ;
  let Inst{30-29} = 0b01;
  let Inst{28-24} = 0b10100;
  let Inst{23-20} = rV;
  let Inst{19}    = 0b0;
  let Inst{18}    = 0b1;
  let Inst{17-16} = 0b01;
  let Inst{15-6}  = off;
  let Inst{5-0}   = rZ;
}

// ---------- LSU_SOBI: store quad (octuple), base+index ---------------------
// | 0 | 01 | 10100 | rV(4) | 0 | 1 | 11 | 111 | _ | rY(6) | rZ(6) |
class LSU_SOBI_Inst<string mnemonic, list<dag> pattern>
    : LVXInst<(outs), (ins GPR256:$rV, GPR:$rY, GPR:$rZ),
              !strconcat(mnemonic, " [$rZ + $rY] = $rV"),
              pattern, LSU_MEMW_AUXR> {
  bits<4> rV;
  bits<6> rY;
  bits<6> rZ;
  let Inst{30-29} = 0b01;
  let Inst{28-24} = 0b10100;
  let Inst{23-20} = rV;
  let Inst{19}    = 0b0;
  let Inst{18}    = 0b1;
  let Inst{17-16} = 0b11;
  let Inst{15-13} = 0b111;
  let Inst{12}    = 0b0;
  let Inst{11-6}  = rY;
  let Inst{5-0}   = rZ;
}

// ---------- LSU_FENCE: memory fence, accesses modifier ---------------------
class LSU_FENCE_Inst<string mnemonic, list<dag> pattern>
    : LVXInst<(outs), (ins accesses:$acc),
              !strconcat(mnemonic, "${acc}"),
              pattern, LSU2_MEMW> {
  bits<2> acc;
  let Inst{30-29} = 0b01;
  let Inst{28-26} = 0b111;
  let Inst{25-24} = acc;
  let Inst{23-20} = 0b1111;
  let Inst{19}    = 0b1;
  let Inst{18}    = 0b1;
  let Inst{17-16} = 0b00;
  let Inst{15-0}  = 0;
}

// ---------- LSU_FXBO: memory effects (prefetch/cache hint), base+offset ----
// | 0 | 01 | 111 | 00 | opc4(4) | 1 | 1 | 00 | signed10 | rZ(6) |
// DTOUCHL/DINVALL/DPURGEL/DFLUSHL/I1INVALS — cache-line hint instructions
// that take an address (base + signed offset) but produce no result.
class LSU_FXBO_Inst<bits<4> opc, string mnemonic, list<dag> pattern,
                    InstrItinClass itin = LSU>
    : LVXInst<(outs), (ins simm10:$off, GPR:$rZ),
              !strconcat(mnemonic, " [$rZ + $off]"),
              pattern, itin> {
  bits<10> off;
  bits<6>  rZ;
  let Inst{30-29} = 0b01;
  let Inst{28-26} = 0b111;
  let Inst{25-24} = 0b00;
  let Inst{23-20} = opc;
  let Inst{19}    = 0b1;
  let Inst{18}    = 0b1;
  let Inst{17-16} = 0b00;
  let Inst{15-6}  = off;
  let Inst{5-0}   = rZ;
}

// ---------- LSU_FXBI: memory effects (prefetch/cache hint), base+index -----
// | 0 | 01 | 111 | 00 | opc4(4) | 1 | 1 | 10 | 111 | _ | rY(6) | rZ(6) |
class LSU_FXBI_Inst<bits<4> opc, string mnemonic, list<dag> pattern,
                    InstrItinClass itin = LSU>
    : LVXInst<(outs), (ins GPR:$rY, GPR:$rZ),
              !strconcat(mnemonic, " [$rZ + $rY]"),
              pattern, itin> {
  bits<6> rY;
  bits<6> rZ;
  let Inst{30-29} = 0b01;
  let Inst{28-26} = 0b111;
  let Inst{25-24} = 0b00;
  let Inst{23-20} = opc;
  let Inst{19}    = 0b1;
  let Inst{18}    = 0b1;
  let Inst{17-16} = 0b10;
  let Inst{15-13} = 0b111;
  let Inst{12}    = 0b0;
  let Inst{11-6}  = rY;
  let Inst{5-0}   = rZ;
}

// ---------- LSU_FXSW: memory effects by set/way, cachelev modifier ---------
// | 0 | 01 | 111 | cachelev(2) | opc4(4) | 1 | 1 | 10 | 111 | _ | rY(6) | rZ(6) |
// DINVALSW/DPURGESW/DFLUSHSW — cache maintenance by set/way; rY/rZ here
// encode the set and way indices rather than a base+index address.
class LSU_FXSW_Inst<bits<4> opc, string mnemonic, list<dag> pattern>
    : LVXInst<(outs), (ins cachelev:$lev, GPR:$rY, GPR:$rZ),
              !strconcat(mnemonic, "${lev} $rY, $rZ"),
              pattern, LSU2_MEMW> {
  bits<2> lev;
  bits<6> rY;
  bits<6> rZ;
  let Inst{30-29} = 0b01;
  let Inst{28-26} = 0b111;
  let Inst{25-24} = lev;
  let Inst{23-20} = opc;
  let Inst{19}    = 0b1;
  let Inst{18}    = 0b1;
  let Inst{17-16} = 0b10;
  let Inst{15-13} = 0b111;
  let Inst{12}    = 0b0;
  let Inst{11-6}  = rY;
  let Inst{5-0}   = rZ;
}

// ---------- LSU_MCC: memory and cache control, no operands -----------------
// | 0 | 01 | 111 | 00 | opc4(4) | 1 | 1 | 00 | ignored(16) |
// D1INVAL/I1INVAL — whole-cache invalidate, no address or register operand.
class LSU_MCC_Inst<bits<4> opc, string mnemonic, list<dag> pattern>
    : LVXInst<(outs), (ins), mnemonic, pattern, LSU2_MEMW> {
  let Inst{30-29} = 0b01;
  let Inst{28-26} = 0b111;
  let Inst{25-24} = 0b00;
  let Inst{23-20} = opc;
  let Inst{19}    = 0b1;
  let Inst{18}    = 0b1;
  let Inst{17-16} = 0b00;
  let Inst{15-0}  = 0;   // ignored / don't-care
}



//===----------------------------------------------------------------------===//
// Instruction definitions
//===----------------------------------------------------------------------===//

// ---- BCU: Control flow ----------------------------------------------------

def GOTO  : BCU_UB_Inst<0b10, "goto",  [(br bb:$target)], BCU_XFER> {
  let isBranch     = 1;
  let isTerminator = 1;
  let isBarrier    = 1;
}
// CALL has no declarative SelectionDAG pattern: binding the LVXcall
// pseudo-node's callee operand to this instruction's PC-relative
// brtarget27s2 (direct call, global symbol) vs ICALL's register operand
// (indirect call, register) depends on the callee's DAG node kind, which
// is exactly the kind of selection logic that belongs in
// LVXISelDAGToDAG::Select (Phase 3) rather than a TableGen pattern.
def CALL  : BCU_UB_Inst<0b11, "call",  [], BCU_XFER> {
  let isCall = 1;
  let Defs   = [RA];
}
def CCB   : BCU_CCB_Inst<"ccb", []> {
  let isBranch     = 1;
  let isTerminator = 1;
}
def CB    : BCU_CB_Inst<"cb", []> {
  let isBranch     = 1;
  let isTerminator = 1;
}
// RET is selected via the LVXretglue pseudo-node, which LowerReturn emits
// to tie the return value registers to this instruction (Phase 3). The
// pattern says "any LVXretglue node selects to RET"; the actual outgoing
// register assignment is performed by CopyToReg nodes inserted by
// LowerReturn before this point, not by this pattern itself.
def RET   : BCU_RTS_Inst<0b10100, "ret", [(LVXretglue)], BCU_XFER> {
  let isReturn     = 1;
  let isTerminator = 1;
  let isBarrier    = 1;
  let Uses         = [RA];
}
def RFE   : BCU_RTS_Inst<0b10101, "rfe", [], ALL> {
  let isReturn     = 1;
  let isTerminator = 1;
  let isBarrier    = 1;
}
def IGOTO : BCU_IBC_Inst<0b10110, "igoto", [], BCU_XFER_BRRP> {
  let isBranch         = 1;
  let isIndirectBranch = 1;
  let isTerminator     = 1;
  let isBarrier        = 1;
}
def ICALL : BCU_IBC_Inst<0b10111, "icall", [], BCU_XFER_BRRP> {
  let isCall = 1;
  let Defs   = [RA];
}

// ---- BCU: System ----------------------------------------------------------

def AWAIT   : BCU_IPC_Inst<0b01000, "await",   []>;
def SLEEP   : BCU_IPC_Inst<0b01001, "sleep",   []>;
def STOP    : BCU_IPC_Inst<0b01010, "stop",    []>;
def BARRIER : BCU_IPC_Inst<0b01011, "barrier", []>;

// ---- BCU: Set control register --------------------------------------------
// SET sets any writeable control register except $ra and $ps (CR_SET
// excludes both); SETRA sets only $ra; SETPS sets only $ps. All three
// share the identical fixed-bit shape (opc5=10000) and differ only in
// which register class constrains the $ctrl operand — see BCU_SET_Inst /
// BCU_SETRA_Inst / BCU_SETPS_Inst above for the encoding rationale.
def SET   : BCU_SET_Inst<"set", []>;
def SETRA : BCU_SETRA_Inst<"set", []>;
def SETPS : BCU_SETPS_Inst<"set", []>;

// ---- ALU_DWI: Load immediate / PC-relative --------------------------------

def MAKE  : ALU_DWI_Inst<0b0000, "make",  []>;
def PCREL : ALU_DWI_Inst<0b0001, "pcrel", []>;

// ---- ALU_DWRI: Integer immediate binary -----------------------------------

def ADDD_i  : ALU_DWRI_Inst<0b0010, "addd",  []>;
def SBFD_i  : ALU_DWRI_Inst<0b0011, "sbfd",  []>;
def MIND_i  : ALU_DWRI_Inst<0b0100, "mind",  []>;
def MAXD_i  : ALU_DWRI_Inst<0b0101, "maxd",  []>;
def MINUD_i : ALU_DWRI_Inst<0b0110, "minud", []>;
def MAXUD_i : ALU_DWRI_Inst<0b0111, "maxud", []>;
def ANDD_i  : ALU_DWRI_Inst<0b1000, "andd",  []>;
def NANDD_i : ALU_DWRI_Inst<0b1001, "nandd", []>;
def IORD_i  : ALU_DWRI_Inst<0b1010, "iord",  []>;
def NIORD_i : ALU_DWRI_Inst<0b1011, "niord", []>;
def EORD_i  : ALU_DWRI_Inst<0b1100, "eord",  []>;
def NEORD_i : ALU_DWRI_Inst<0b1101, "neord", []>;
def ANDND_i : ALU_DWRI_Inst<0b1110, "andnd", []>;
def IORND_i : ALU_DWRI_Inst<0b1111, "iornd", []>;

// ---- COPYD: synthetic register-to-register copy, per lvx_Synthetic.yml ---
// "COPYD %0 %1 = %2" specializes ALU_DWRI's IORD_i (rW = imm | rZ) with
// imm fixed to 0, i.e. COPYD $rW, $rZ  ==>  iord $rW = 0, $rZ  ==>
// rW = 0 | rZ = rZ. Shares IORD_i's exact encoding (opcode 0b1010,
// ALU_DWRI format) but exposes only $rW/$rZ as operands -- imm is
// hardcoded rather than user-supplied, and the assembly string omits
// the (always-zero) immediate entirely, matching the synthetic
// instruction's own two-operand syntax ("%0 %1 = %2", not IORD_i's
// three-token "$rW = $imm, $rZ").
//
// This is the instruction LVXISelLowering (LowerFormalArguments/
// LowerCall) emits to realign mis-aligned i128/v4i64 argument pieces
// into a true GPR128/GPR256 register tuple: per the ABI doc, "some
// multi-register arguments may end up in mis-aligned register tuples.
// It is the callee's responsibility to move such arguments into
// well-aligned register tuples before using them as operands of wide
// load-store and SIMD instructions" (and the caller's responsibility
// on the outgoing side) -- moving one 64-bit register at a time via
// COPYD is exactly the mechanism the ABI doc describes.
def COPYD : LVXInst<(outs GPR:$rW), (ins GPR:$rZ),
                    "copyd $rW = $rZ", [], ALU_TINY> {
  bits<6> rW;
  bits<6> rZ;
  let Inst{30-29} = 0b11;
  let Inst{28}    = 0b0;
  let Inst{27-24} = 0b1010; // IORD_i's opcode
  let Inst{23-18} = rW;
  let Inst{17-16} = 0b00;
  let Inst{15-6}  = 0;      // imm, hardcoded to 0
  let Inst{5-0}   = rZ;
}

// ---- ALU_BFWR: Bitfield ---------------------------------------------------

def INSF  : ALU_BFWR_Inst<0b00, "insf",  []>;
def EXTFZ : ALU_BFWR_Inst<0b01, "extfz", []>;
def EXTFS : ALU_BFWR_Inst<0b10, "extfs", []>;

// ---- ALU_DBMWRI: Byte matrix immediate ------------------------------------

def SBMM8D_i  : ALU_DBMWRI_Inst<0b1110, "sbmm8d",  []>;
def SBMMT8D_i : ALU_DBMWRI_Inst<0b1111, "sbmmt8d", []>;

// ---- ALU_DWRR0: Integer register binary -----------------------------------

def SIGND  : ALU_DWRR0_Inst<0b0000, "signd",  []>;
def SIGNSD : ALU_DWRR0_Inst<0b0001, "signsd", []>;
def ADDD   : ALU_DWRR0_Inst<0b0010, "addd",   [(set GPR:$rW, (add  GPR:$rY, GPR:$rZ))]>;
def SBFD   : ALU_DWRR0_Inst<0b0011, "sbfd",   [(set GPR:$rW, (sub  GPR:$rY, GPR:$rZ))]>;
def MIND   : ALU_DWRR0_Inst<0b0100, "mind",   [(set GPR:$rW, (smin GPR:$rY, GPR:$rZ))]>;
def MAXD   : ALU_DWRR0_Inst<0b0101, "maxd",   [(set GPR:$rW, (smax GPR:$rY, GPR:$rZ))]>;
def MINUD  : ALU_DWRR0_Inst<0b0110, "minud",  [(set GPR:$rW, (umin GPR:$rY, GPR:$rZ))]>;
def MAXUD  : ALU_DWRR0_Inst<0b0111, "maxud",  [(set GPR:$rW, (umax GPR:$rY, GPR:$rZ))]>;
def ANDD   : ALU_DWRR0_Inst<0b1000, "andd",   [(set GPR:$rW, (and  GPR:$rY, GPR:$rZ))]>;
def NANDD  : ALU_DWRR0_Inst<0b1001, "nandd",  []>;
def IORD   : ALU_DWRR0_Inst<0b1010, "iord",   [(set GPR:$rW, (or   GPR:$rY, GPR:$rZ))]>;
def NIORD  : ALU_DWRR0_Inst<0b1011, "niord",  []>;
def EORD   : ALU_DWRR0_Inst<0b1100, "eord",   [(set GPR:$rW, (xor  GPR:$rY, GPR:$rZ))]>;
def NEORD  : ALU_DWRR0_Inst<0b1101, "neord",  []>;
def ANDND  : ALU_DWRR0_Inst<0b1110, "andnd",  []>;
def IORND  : ALU_DWRR0_Inst<0b1111, "iornd",  []>;

// ---- ALU_DCWRR / ALU_DCMWRR: Compare / conditional move ------------------

def COMPD  : ALU_DCWRR_Inst<"compd",  []>;
def CMOVED : ALU_DCMWRR_Inst<"cmoved", []>;

// ---- ALU_DBMWRRR / ALU_DBMWRR: Byte matrix reg ---------------------------

def SBMM8EORD  : ALU_DWRR0_Inst<0b1100, "sbmm8eord",  []>;
def SBMMT8EORD : ALU_DWRR0_Inst<0b1101, "sbmmt8eord", []>;
def SBMM8D     : ALU_DWRR0_Inst<0b1110, "sbmm8d",     []>;
def SBMMT8D    : ALU_DWRR0_Inst<0b1111, "sbmmt8d",    []>;

// ---- ALU_DWRR2: Logical double --------------------------------------------

def LANDD  : ALU_DWRR2_Inst<0b0000, "landd",  []>;
def LNANDD : ALU_DWRR2_Inst<0b0001, "lnandd", []>;
def LIORD  : ALU_DWRR2_Inst<0b0010, "liord",  []>;
def LNIORD : ALU_DWRR2_Inst<0b0011, "lniord", []>;

// ---- ALU_DWRRS: Saturating/abs double -------------------------------------

def ABDD  : ALU_DWRRS_Inst<0b1100, "abdd",  []>;
def ABDUD : ALU_DWRRS_Inst<0b1101, "abdud", []>;
def ABDSD : ALU_DWRRS_Inst<0b1110, "abdsd", []>;
def STSUD : ALU_DWRRS_Inst<0b1111, "stsud", []>;

// ---- ALU_DSWRR / ALU_DSWRI: Shift/rotate double --------------------------

def SRSD_r  : ALU_DSWRR_Inst<0, 0b000, "srsd",  [], ALU_LITE>;
def SLLD_r  : ALU_DSWRR_Inst<0, 0b001, "slld",  [(set GPR:$rW, (shl  GPR:$rY, GPR:$rZ))]>;
def SRAD_r  : ALU_DSWRR_Inst<0, 0b010, "srad",  [(set GPR:$rW, (sra  GPR:$rY, GPR:$rZ))]>;
def SRLD_r  : ALU_DSWRR_Inst<0, 0b011, "srld",  [(set GPR:$rW, (srl  GPR:$rY, GPR:$rZ))]>;
def SLSD_r  : ALU_DSWRR_Inst<0, 0b100, "slsd",  [], ALU_LITE>;
def SLUSD_r : ALU_DSWRR_Inst<0, 0b101, "slusd", [], ALU_LITE>;
def ROLD_r  : ALU_DSWRR_Inst<0, 0b110, "rold",  [(set GPR:$rW, (rotl GPR:$rY, GPR:$rZ))]>;
def RORD_r  : ALU_DSWRR_Inst<0, 0b111, "rord",  [(set GPR:$rW, (rotr GPR:$rY, GPR:$rZ))]>;

def SRSD_i  : ALU_DSWRI_Inst<1, 0b000, "srsd",  [], ALU_LITE>;
def SLLD_i  : ALU_DSWRI_Inst<1, 0b001, "slld",  [(set GPR:$rW, (shl  GPR:$rZ, uimm6imm:$shamt))]>;
def SRAD_i  : ALU_DSWRI_Inst<1, 0b010, "srad",  [(set GPR:$rW, (sra  GPR:$rZ, uimm6imm:$shamt))]>;
def SRLD_i  : ALU_DSWRI_Inst<1, 0b011, "srld",  [(set GPR:$rW, (srl  GPR:$rZ, uimm6imm:$shamt))]>;
def SLSD_i  : ALU_DSWRI_Inst<1, 0b100, "slsd",  [], ALU_LITE>;
def SLUSD_i : ALU_DSWRI_Inst<1, 0b101, "slusd", [], ALU_LITE>;
def ROLD_i  : ALU_DSWRI_Inst<1, 0b110, "rold",  [(set GPR:$rW, (rotl GPR:$rZ, uimm6imm:$shamt))]>;
def RORD_i  : ALU_DSWRI_Inst<1, 0b111, "rord",  [(set GPR:$rW, (rotr GPR:$rZ, uimm6imm:$shamt))]>;

// ---- ALU_DWRR1: Scaled add / saturating add double ------------------------

def ADDX2D  : ALU_DWRR1_Inst<0b0000, "addx2d",  []>;
def ADDX4D  : ALU_DWRR1_Inst<0b0001, "addx4d",  []>;
def ADDX8D  : ALU_DWRR1_Inst<0b0010, "addx8d",  []>;
def ADDX16D : ALU_DWRR1_Inst<0b0011, "addx16d", []>;
def ADDX32D : ALU_DWRR1_Inst<0b0100, "addx32d", []>;
def ADDX64D : ALU_DWRR1_Inst<0b0101, "addx64d", []>;
def ADDSD   : ALU_DWRR1_Inst<0b1000, "addsd",   []>;
def SBFSD   : ALU_DWRR1_Inst<0b1001, "sbfsd",   []>;
def ADDUSD  : ALU_DWRR1_Inst<0b1010, "addusd",  []>;
def SBFUSD  : ALU_DWRR1_Inst<0b1011, "sbfusd",  []>;

// ---- ALU_DDMWRR: Divmod double (pair result) ------------------------------

def DIVMODD  : ALU_DDMWRR_Inst<0b1100, "divmodd",  []>;
def DIVMODUD : ALU_DDMWRR_Inst<0b1101, "divmodud", []>;

// ---------- ALU_CATDQ: catenate two double words into a register pair -----
// Per lvx_Format.yml ("ALU Catenate Double to Quadruple Word") and
// lvx_Opcode.txt's confirmed bit layout:
//   | P | 11 | 0 | 1111 | registerM(5) | _ | 10 | 010 | 1 | registerY(6) | registerZ(6) |
// registerM is the GPR128 destination pair; registerY/registerZ are the
// two GPR sources. This is the real instruction behind the COPYD-based
// realignment scheme described in lvx_Synthetic.yml: CATDQ assembles an
// aligned 128-bit pair from two arbitrary (possibly non-adjacent) 64-bit
// source registers in a single instruction, which is exactly what's
// needed to move a mis-aligned i128 argument (per the ABI doc's
// "callee's responsibility to move such arguments into well-aligned
// register tuples") into place more efficiently than two separate
// COPYDs.
class ALU_CATDQ_Inst<string mnemonic, list<dag> pattern>
    : LVXInst<(outs GPR128:$rM), (ins GPR:$rY, GPR:$rZ),
              !strconcat(mnemonic, " $rM = $rY, $rZ"),
              pattern, ALU_LITE> {
  bits<5> rM;
  bits<6> rY;
  bits<6> rZ;
  let Inst{30-29} = 0b11;
  let Inst{28}    = 0b0;
  let Inst{27-24} = 0b1111;
  let Inst{23-19} = rM;
  let Inst{18}    = 0b0;
  let Inst{17-16} = 0b10;
  let Inst{15-13} = 0b010;
  let Inst{12}    = 0b1;
  let Inst{11-6}  = rY;
  let Inst{5-0}   = rZ;
}

def CATDQ : ALU_CATDQ_Inst<"catdq", []>;

// ---- ALU_DBWR: Unary double -----------------------------------------------

def NEGD  : ALU_DBWR_Inst<0b0000, "negd",  [(set GPR:$rW, (ineg  GPR:$rZ))]>;
def ABSD  : ALU_DBWR_Inst<0b0001, "absd",  [(set GPR:$rW, (abs   GPR:$rZ))]>;
def NEGSD : ALU_DBWR_Inst<0b0010, "negsd", []>;
def ABSSD : ALU_DBWR_Inst<0b0011, "abssd", []>;
def CLZD  : ALU_DBWR_Inst<0b0100, "clzd",  [(set GPR:$rW, (ctlz  GPR:$rZ))]>;
// CLSD (count leading sign bits) has no standard SelectionDAG node;
// it will be selected via a target intrinsic or custom combine in Phase 3.
def CLSD  : ALU_DBWR_Inst<0b0101, "clsd",  []>;
def CBSD  : ALU_DBWR_Inst<0b0110, "cbsd",  [(set GPR:$rW, (ctpop GPR:$rZ))]>;
def CTZD  : ALU_DBWR_Inst<0b0111, "ctzd",  [(set GPR:$rW, (cttz  GPR:$rZ))]>;
def NOTD  : ALU_DBWR_Inst<0b1000, "notd",  [(set GPR:$rW, (not   GPR:$rZ))]>;

// ---- ALU_DMWRR / ALU_DMWRRR: Multiply double, highmult modifier -----------

def MULD  : ALU_DMWRR_Inst<0b00, "muld",  []>;
def MULND : ALU_DMWRR_Inst<0b01, "mulnd", []>;
def MADDD : ALU_DMWRR_Inst<0b10, "maddd", []>;
def MSBFD : ALU_DMWRR_Inst<0b11, "msbfd", []>;

// ---- ALU_DMEWRR / ALU_DMEWRRR: Widening multiply, widemult modifier -------

def MULWD  : ALU_DMEWRR_Inst<0b00, "mulwd",  []>;
def MULNWD : ALU_DMEWRR_Inst<0b01, "mulnwd", []>;
def MADDWD : ALU_DMEWRR_Inst<0b10, "maddwd", []>;
def MSBFWD : ALU_DMEWRR_Inst<0b11, "msbfwd", []>;

// ---- ALU_QWRR0: 128-bit quad binary ---------------------------------------

def SBFQ  : ALU_QWRR0_Inst<0b0011, "sbfq",  []>;
def IORQ  : ALU_QWRR0_Inst<0b1010, "iorq",  []>;
def NIORQ : ALU_QWRR0_Inst<0b1011, "niorq", []>;
def EORQ  : ALU_QWRR0_Inst<0b1100, "eorq",  []>;
def NEORQ : ALU_QWRR0_Inst<0b1101, "neorq", []>;
def ANDNQ : ALU_QWRR0_Inst<0b1110, "andnq", []>;
def IORNQ : ALU_QWRR0_Inst<0b1111, "iornq", []>;

// ---- ALU_QCWRR / ALU_QCMWRR: Quad compare / conditional move -------------

def COMPQ  : ALU_QCWRR_Inst<"compq",  []>;
def CMOVEQ : ALU_QCMWRR_Inst<"cmoveq", []>;

// ---- ALU_QBWR: Unary quad -------------------------------------------------

def NEGQ : ALU_QBWR_Inst<0b0000, "negq", []>;
def NOTQ : ALU_QBWR_Inst<0b1000, "notq", []>;

// ---- ALU_WWRR0: 32-bit word binary, signextw modifier --------------------

def SIGNW  : ALU_WWRR0_Inst<0b0000, "signw",  []>;
def SIGNSW : ALU_WWRR0_Inst<0b0001, "signsw", []>;
def ADDW   : ALU_WWRR0_Inst<0b0010, "addw",   []>;
def SBFW   : ALU_WWRR0_Inst<0b0011, "sbfw",   []>;
def MINW   : ALU_WWRR0_Inst<0b0100, "minw",   []>;
def MAXW   : ALU_WWRR0_Inst<0b0101, "maxw",   []>;
def MINUW  : ALU_WWRR0_Inst<0b0110, "minuw",  []>;
def MAXUW  : ALU_WWRR0_Inst<0b0111, "maxuw",  []>;
def ANDW   : ALU_WWRR0_Inst<0b1000, "andw",   []>;
def NANDW  : ALU_WWRR0_Inst<0b1001, "nandw",  []>;
def IORW   : ALU_WWRR0_Inst<0b1010, "iorw",   []>;
def NIORW  : ALU_WWRR0_Inst<0b1011, "niorw",  []>;
def EORW   : ALU_WWRR0_Inst<0b1100, "eorw",   []>;
def NEORW  : ALU_WWRR0_Inst<0b1101, "neorw",  []>;
def ANDNW  : ALU_WWRR0_Inst<0b1110, "andnw",  []>;
def IORNW  : ALU_WWRR0_Inst<0b1111, "iornw",  []>;

// ---- ALU_WCWRR: 32-bit word compare, intcomp + signextw ------------------

def COMPW : ALU_WCWRR_Inst<"compw", []>;

// ---- ALU_WAVG: 32-bit word average, signextw modifier --------------------

def AVGW   : ALU_WAVG_Inst<0b1100, "avgw",   []>;
def AVGUW  : ALU_WAVG_Inst<0b1101, "avguw",  []>;
def AVGRW  : ALU_WAVG_Inst<0b1110, "avgrw",  []>;
def AVGRUW : ALU_WAVG_Inst<0b1111, "avgruw", []>;

// ---- ALU_WWRR2: 32-bit word logical --------------------------------------

def LANDW  : ALU_WWRR2_Inst<0b0000, "landw",  []>;
def LNANDW : ALU_WWRR2_Inst<0b0001, "lnandw", []>;
def LIORW  : ALU_WWRR2_Inst<0b0010, "liorw",  []>;
def LNIORW : ALU_WWRR2_Inst<0b0011, "lniorw", []>;

// ---- ALU_WCWRRR: 32-bit word CRC -----------------------------------------

def CRCBELMW : ALU_WCWRRR_Inst<0b0100, "crcbelmw", []>;
def CRCBELLW : ALU_WCWRRR_Inst<0b0101, "crcbellw", []>;
def CRCLELMW : ALU_WCWRRR_Inst<0b0110, "crclelmw", []>;
def CRCLELLW : ALU_WCWRRR_Inst<0b0111, "crclellw", []>;

// ---- ALU_WWRRS: 32-bit word saturating, signextw modifier ----------------

def ABDW  : ALU_WWRRS_Inst<0b1100, "abdw",  []>;
def ABDUW : ALU_WWRRS_Inst<0b1101, "abduw", []>;
def ABDSW : ALU_WWRRS_Inst<0b1110, "abdsw", []>;
def STSUW : ALU_WWRRS_Inst<0b1111, "stsuw", []>;

// ---- ALU_WSWRR / ALU_WSWRI: 32-bit word shift, signextw modifier ---------

def SRSW_r  : ALU_WSWRR_Inst<0, 0b000, "srsw",  [], ALU_LITE>;
def SLLW_r  : ALU_WSWRR_Inst<0, 0b001, "sllw",  []>;
def SRAW_r  : ALU_WSWRR_Inst<0, 0b010, "sraw",  []>;
def SRLW_r  : ALU_WSWRR_Inst<0, 0b011, "srlw",  []>;
def SLSW_r  : ALU_WSWRR_Inst<0, 0b100, "slsw",  [], ALU_LITE>;
def SLUSW_r : ALU_WSWRR_Inst<0, 0b101, "slusw", [], ALU_LITE>;
def ROLW_r  : ALU_WSWRR_Inst<0, 0b110, "rolw",  []>;
def RORW_r  : ALU_WSWRR_Inst<0, 0b111, "rorw",  []>;

def SRSW_i  : ALU_WSWRI_Inst<1, 0b000, "srsw",  [], ALU_LITE>;
def SLLW_i  : ALU_WSWRI_Inst<1, 0b001, "sllw",  []>;
def SRAW_i  : ALU_WSWRI_Inst<1, 0b010, "sraw",  []>;
def SRLW_i  : ALU_WSWRI_Inst<1, 0b011, "srlw",  []>;
def SLSW_i  : ALU_WSWRI_Inst<1, 0b100, "slsw",  [], ALU_LITE>;
def SLUSW_i : ALU_WSWRI_Inst<1, 0b101, "slusw", [], ALU_LITE>;
def ROLW_i  : ALU_WSWRI_Inst<1, 0b110, "rolw",  []>;
def RORW_i  : ALU_WSWRI_Inst<1, 0b111, "rorw",  []>;

// ---- ALU_WWRR1: 32-bit word scaled-add / saturating add, signextw --------

def ADDX2W  : ALU_WWRR1_Inst<0b0000, "addx2w",  []>;
def ADDX4W  : ALU_WWRR1_Inst<0b0001, "addx4w",  []>;
def ADDX8W  : ALU_WWRR1_Inst<0b0010, "addx8w",  []>;
def ADDX16W : ALU_WWRR1_Inst<0b0011, "addx16w", []>;
def ADDX32W : ALU_WWRR1_Inst<0b0100, "addx32w", []>;
def ADDX64W : ALU_WWRR1_Inst<0b0101, "addx64w", []>;
def ADDSW   : ALU_WWRR1_Inst<0b1000, "addsw",   []>;
def SBFSW   : ALU_WWRR1_Inst<0b1001, "sbfsw",   []>;
def ADDUSW  : ALU_WWRR1_Inst<0b1010, "addusw",  []>;
def SBFUSW  : ALU_WWRR1_Inst<0b1011, "sbfusw",  []>;

// ---- ALU_WDMWRR: 32-bit word divmod (pair result), signextw modifier -----

def DIVMODW  : ALU_WDMWRR_Inst<0b1100, "divmodw",  []>;
def DIVMODUW : ALU_WDMWRR_Inst<0b1101, "divmoduw", []>;

// ---- ALU_BWRW: 32-bit word unary, signextw modifier ----------------------

def NEGW  : ALU_BWRW_Inst<0b0000, "negw",  []>;
def ABSW  : ALU_BWRW_Inst<0b0001, "absw",  []>;
def NEGSW : ALU_BWRW_Inst<0b0010, "negsw", []>;
def ABSSW : ALU_BWRW_Inst<0b0011, "abssw", []>;
def CLZW  : ALU_BWRW_Inst<0b0100, "clzw",  []>;
def CLSW  : ALU_BWRW_Inst<0b0101, "clsw",  []>;
def CBSW  : ALU_BWRW_Inst<0b0110, "cbsw",  []>;
def CTZW  : ALU_BWRW_Inst<0b0111, "ctzw",  []>;
def NOTW  : ALU_BWRW_Inst<0b1000, "notw",  []>;

// ---- ALU_WMWRR / ALU_WMWRRR: 32-bit word multiply, highmult + signextw ---

def MULW  : ALU_WMWRR_Inst<0b00, "mulw",  []>;
def MULNW : ALU_WMWRR_Inst<0b01, "mulnw", []>;
def MADDW : ALU_WMWRR_Inst<0b10, "maddw", []>;
def MSBFW : ALU_WMWRR_Inst<0b11, "msbfw", []>;

// ---- Float double (D) ops -------------------------------------------------
// fp_sub=00, half=0

def FADDD    : ALU_FDADD_Inst<0b000, 0b00, 0, "faddd",    []>;
def FSBFD    : ALU_FDADD_Inst<0b001, 0b00, 0, "fsbfd",    []>;
def FCOMPD   : ALU_FDCWRR_Inst<0b00, 0, "fcompd",   []>;
def FMIND    : ALU_FDMMWR_Inst<0b000, 0b00, 0, "fmind",    []>;
def FMAXD    : ALU_FDMMWR_Inst<0b001, 0b00, 0, "fmaxd",    []>;
def FMINND   : ALU_FDMMWR_Inst<0b010, 0b00, 0, "fminnd",   []>;
def FMAXND   : ALU_FDMMWR_Inst<0b011, 0b00, 0, "fmaxnd",   []>;
def FSIGND   : ALU_FDMMWR_Inst<0b100, 0b00, 0, "fsignd",   []>;
def FSIGNND  : ALU_FDMMWR_Inst<0b101, 0b00, 0, "fsignnd",  []>;
def FSIGNMD  : ALU_FDMMWR_Inst<0b110, 0b00, 0, "fsignmd",  []>;
def FNEGD    : ALU_FDMO1_Inst<0b0010, 0b00, 0, "fnegd",    []>;
def FABSD    : ALU_FDMO1_Inst<0b0011, 0b00, 0, "fabsd",    []>;
def FSRECD   : ALU_FDMO1_Inst<0b0100, 0b00, 0, "fsrecd",   []>;
def FSRSRD   : ALU_FDMO1_Inst<0b0101, 0b00, 0, "fsrsrd",   []>;
def FCLASSD  : ALU_FDMO1_Inst<0b0110, 0b00, 0, "fclassd",  []>;
def FWIDENWDL: ALU_FDWIDEN_Inst<0b00, 0, "fwidenwdl", []>;  // mos=0
def FWIDENWDM: ALU_FDWIDEN_Inst<0b00, 0, "fwidenwdm", []>;  // mos=1 (alias)
def FLOATD   : ALU_FDCVT_Inst<0b0000, 0b00, 0, "floatd",   []>;
def FLOATUD  : ALU_FDCVT_Inst<0b0001, 0b00, 0, "floatud",  []>;
def FLOATWD  : ALU_FDCVT_Inst<0b0010, 0b00, 0, "floatwd",  []>;
def FLOATUWD : ALU_FDCVT_Inst<0b0011, 0b00, 0, "floatuwd", []>;
def FIXEDD   : ALU_FDCVT_Inst<0b0100, 0b00, 0, "fixedd",   []>;
def FIXEDUD  : ALU_FDCVT_Inst<0b0101, 0b00, 0, "fixedud",  []>;
def FIXEDWD  : ALU_FDCVT_Inst<0b0110, 0b00, 0, "fixedwd",  []>;
def FIXEDUWD : ALU_FDCVT_Inst<0b0111, 0b00, 0, "fixeduwd", []>;
def FSQRTD   : ALU_FDMO0_Inst<0b1000, 0b00, 0, "fsqrtd",   [], ALU_FULL>;
def FRINTD   : ALU_FDMO0_Inst<0b1001, 0b00, 0, "frintd",   []>;
def FFMAD    : ALU_FDFMA_Inst<0b100, 0b00, 0, "ffmad",    []>;
def FFMSD    : ALU_FDFMA_Inst<0b101, 0b00, 0, "ffmsd",    []>;
def FMULD    : ALU_FDFMA_Inst<0b110, 0b00, 0, "fmuld",    []>;
def FDIVD    : ALU_FDFMA_Inst<0b111, 0b00, 0, "fdivd",    [], ALU_FULL>;

// ---- Float single (W) ops -------------------------------------------------
// fp_sub=01, half=0

def FADDW    : ALU_FDADD_Inst<0b000, 0b01, 0, "faddw",    []>;
def FSBFW    : ALU_FDADD_Inst<0b001, 0b01, 0, "fsbfw",    []>;
def FCOMPW   : ALU_FDCWRR_Inst<0b01, 0, "fcompw",   []>;
def FMINW    : ALU_FDMMWR_Inst<0b000, 0b01, 0, "fminw",    []>;
def FMAXW    : ALU_FDMMWR_Inst<0b001, 0b01, 0, "fmaxw",    []>;
def FMINNW   : ALU_FDMMWR_Inst<0b010, 0b01, 0, "fminnw",   []>;
def FMAXNW   : ALU_FDMMWR_Inst<0b011, 0b01, 0, "fmaxnw",   []>;
def FSIGNW   : ALU_FDMMWR_Inst<0b100, 0b01, 0, "fsignw",   []>;
def FSIGNNW  : ALU_FDMMWR_Inst<0b101, 0b01, 0, "fsignnw",  []>;
def FSIGNMW  : ALU_FDMMWR_Inst<0b110, 0b01, 0, "fsignmw",  []>;
def FNEGW    : ALU_FDMO1_Inst<0b0010, 0b01, 0, "fnegw",    []>;
def FABSW    : ALU_FDMO1_Inst<0b0011, 0b01, 0, "fabsw",    []>;
def FSRECW   : ALU_FDMO1_Inst<0b0100, 0b01, 0, "fsrecw",   []>;
def FSRSRW   : ALU_FDMO1_Inst<0b0101, 0b01, 0, "fsrsrw",   []>;
def FCLASSW  : ALU_FDMO1_Inst<0b0110, 0b01, 0, "fclassw",  []>;
def FWIDENHW : ALU_FDWIDEN_Inst<0b01, 0, "fwidenhw", []>;
def FLOATW   : ALU_FDCVT_Inst<0b0000, 0b01, 0, "floatw",   []>;
def FLOATUW  : ALU_FDCVT_Inst<0b0001, 0b01, 0, "floatuw",  []>;
def FLOATDW  : ALU_FDCVT_Inst<0b0010, 0b01, 0, "floatdw",  []>;
def FLOATUDW : ALU_FDCVT_Inst<0b0011, 0b01, 0, "floatudw", []>;
def FIXEDW   : ALU_FDCVT_Inst<0b0100, 0b01, 0, "fixedw",   []>;
def FIXEDUW  : ALU_FDCVT_Inst<0b0101, 0b01, 0, "fixeduw",  []>;
def FIXEDDW  : ALU_FDCVT_Inst<0b0110, 0b01, 0, "fixeddw",  []>;
def FIXEDUDW : ALU_FDCVT_Inst<0b0111, 0b01, 0, "fixedudw", []>;
def FSQRTW   : ALU_FDMO0_Inst<0b1000, 0b01, 0, "fsqrtw",   [], ALU_FULL>;
def FRINTW   : ALU_FDMO0_Inst<0b1001, 0b01, 0, "frintw",   []>;
def FNARROWDW: ALU_FDMO0_Inst<0b1100, 0b01, 0, "fnarrowdw",[]>;
def FFMAW    : ALU_FDFMA_Inst<0b100, 0b01, 0, "ffmaw",    []>;
def FFMSW    : ALU_FDFMA_Inst<0b101, 0b01, 0, "ffmsw",    []>;
def FMULW    : ALU_FDFMA_Inst<0b110, 0b01, 0, "fmulw",    []>;
def FDIVW    : ALU_FDFMA_Inst<0b111, 0b01, 0, "fdivw",    [], ALU_FULL>;

// ---- Complex FP (W) ops ---------------------------------------------------
// fp_sub=00, bit12=1, imultiply + conjugate + floatmode

def FADDWC  : ALU_FWCOP_Inst<0b00, "faddwc",  []>;
def FSBFWC  : ALU_FWCOP_Inst<0b01, "fsbfwc",  []>;
def FMULWC  : ALU_FWCOP_Inst<0b10, "fmulwc",  []>;
def FFMAWC  : ALU_FWCOP_Inst<0b11, "ffmawc",  []>;

// ---- Float half (H) ops ---------------------------------------------------
// fp_sub=01, half=1

def FADDH    : ALU_FDADD_Inst<0b000, 0b01, 1, "faddh",    []>;
def FSBFH    : ALU_FDADD_Inst<0b001, 0b01, 1, "fsbfh",    []>;
def FCOMPH   : ALU_FDCWRR_Inst<0b01, 1, "fcomph",   []>;
def FMINH    : ALU_FDMMWR_Inst<0b000, 0b01, 1, "fminh",    []>;
def FMAXH    : ALU_FDMMWR_Inst<0b001, 0b01, 1, "fmaxh",    []>;
def FMINNH   : ALU_FDMMWR_Inst<0b010, 0b01, 1, "fminnh",   []>;
def FMAXNH   : ALU_FDMMWR_Inst<0b011, 0b01, 1, "fmaxnh",   []>;
def FSIGNH   : ALU_FDMMWR_Inst<0b100, 0b01, 1, "fsignh",   []>;
def FSIGNNH  : ALU_FDMMWR_Inst<0b101, 0b01, 1, "fsignnh",  []>;
def FSIGNMH  : ALU_FDMMWR_Inst<0b110, 0b01, 1, "fsignmh",  []>;
def FNEGH    : ALU_FDMO1_Inst<0b0010, 0b01, 1, "fnegh",    []>;
def FABSH    : ALU_FDMO1_Inst<0b0011, 0b01, 1, "fabsh",    []>;
def FCLASSH  : ALU_FDMO1_Inst<0b0110, 0b01, 1, "fclassh",  []>;
def FSQRTH   : ALU_FDMO0_Inst<0b1000, 0b01, 1, "fsqrth",   [], ALU_FULL>;
def FRINTH   : ALU_FDMO0_Inst<0b1001, 0b01, 1, "frinth",   []>;
def FNARROWWH: ALU_FDMO0_Inst<0b1100, 0b01, 1, "fnarrowwh",[]>;
def FFMAH    : ALU_FDFMA_Inst<0b100, 0b01, 1, "ffmah",    []>;
def FFMSH    : ALU_FDFMA_Inst<0b101, 0b01, 1, "ffmsh",    []>;
def FMULH    : ALU_FDFMA_Inst<0b110, 0b01, 1, "fmulh",    []>;
def FDIVH    : ALU_FDFMA_Inst<0b111, 0b01, 1, "fdivh",    [], ALU_FULL>;

// ---- NOP ------------------------------------------------------------------

def NOP : LVXInst<(outs), (ins), "nop", [], ALU_TINY> {
  let Inst{30-29} = 0b11;
  let Inst{28}    = 0b1;
  let Inst{27-24} = 0b1111;
  let Inst{23-19} = 0b00000;
  let Inst{18}    = 0b1;
  let Inst{17-16} = 0b11;
  let Inst{15-12} = 0b1111;
  let Inst{11-7}  = 0b11111;
  let Inst{6}     = 0b1;
  let Inst{5-1}   = 0b00000;
  let Inst{0}     = 0b1;
  let hasSideEffects = 0;
}

// ---- LSU: Loads -----------------------------------------------------------

def LBZ : LSU_LSBO_Inst<0b000, "lbz", []>;
def LBS : LSU_LSBO_Inst<0b001, "lbs", []>;
def LHZ : LSU_LSBO_Inst<0b010, "lhz", []>;
def LHS : LSU_LSBO_Inst<0b011, "lhs", []>;
// LWZ/LWS/LD have no SelectionDAG pattern here: LSU_LSBO_Inst's `variant`
// modifier operand has no fixed value a pattern could bind, so plain-load
// selection (variant=0, i.e. cached/non-speculative) is handled by a
// custom matcher in LVXISelDAGToDAG (Phase 3) that selects these opcodes
// with $var hardcoded to 0, rather than by a declarative pattern here.
def LWZ : LSU_LSBO_Inst<0b100, "lwz", []>;
def LWS : LSU_LSBO_Inst<0b101, "lws", []>;
def LD  : LSU_LSBO_Inst<0b110, "ld",  []>;
def LQ  : LSU_LQBO_Inst<"lq", []>;
def LO  : LSU_LOBO_Inst<"lo", []>;

// ---- LSU: Loads, base+index ------------------------------------------------
// Same mnemonics and opcode fields as the base+offset loads above; these
// are the register+register addressing-mode variants (LSU_LSBI/LQBI/LOBI).
// Distinct LLVM def names (_idx suffix) since LBZ etc. are already taken;
// the assembler/disassembler distinguish them by operand syntax ("[rZ+off]"
// vs "[rZ+rY]"), same as the base+offset/base+index split for ALU shifts.
def LBZ_idx : LSU_LSBI_Inst<0b000, "lbz", []>;
def LBS_idx : LSU_LSBI_Inst<0b001, "lbs", []>;
def LHZ_idx : LSU_LSBI_Inst<0b010, "lhz", []>;
def LHS_idx : LSU_LSBI_Inst<0b011, "lhs", []>;
def LWZ_idx : LSU_LSBI_Inst<0b100, "lwz", []>;
def LWS_idx : LSU_LSBI_Inst<0b101, "lws", []>;
def LD_idx  : LSU_LSBI_Inst<0b110, "ld",  []>;
def LQ_idx  : LSU_LQBI_Inst<"lq", []>;
def LO_idx  : LSU_LOBI_Inst<"lo", []>;

// ---- LSU: Stores ----------------------------------------------------------

def SB : LSU_SSBO_Inst<0b10000, "sb", []>;
def SH : LSU_SSBO_Inst<0b10001, "sh", []>;
def SW : LSU_SSBO_Inst<0b10010, "sw", [(store GPR:$rT, (add GPR:$rZ, simm10imm:$off))]>;
def SD : LSU_SSBO_Inst<0b10011, "sd", [(store GPR:$rT, (add GPR:$rZ, simm10imm:$off))]>;
def SQ : LSU_SQBO_Inst<"sq", []>;
def SO : LSU_SOBO_Inst<"so", []>;

// ---- LSU: Stores, base+index ------------------------------------------------

def SB_idx : LSU_SSBI_Inst<0b10000, "sb", []>;
def SH_idx : LSU_SSBI_Inst<0b10001, "sh", []>;
def SW_idx : LSU_SSBI_Inst<0b10010, "sw", []>;
def SD_idx : LSU_SSBI_Inst<0b10011, "sd", []>;
def SQ_idx : LSU_SQBI_Inst<"sq", []>;
def SO_idx : LSU_SOBI_Inst<"so", []>;

// ---- LSU: Fence -----------------------------------------------------------

def FENCE : LSU_FENCE_Inst<"fence", []>;

// ---- LSU: Memory effects (cache hints / prefetch), base+offset ------------

def DTOUCHL  : LSU_FXBO_Inst<0b0000, "dtouchl",  []>;
def DINVALL  : LSU_FXBO_Inst<0b0001, "dinvall",  []>;
def DPURGEL  : LSU_FXBO_Inst<0b0010, "dpurgel",  []>;
def DFLUSHL  : LSU_FXBO_Inst<0b0011, "dflushl",  []>;
def I1INVALS : LSU_FXBO_Inst<0b0101, "i1invals", [], LSU2_MEMW>;

// ---- LSU: Memory effects (cache hints / prefetch), base+index -------------

def DTOUCHL_idx  : LSU_FXBI_Inst<0b0000, "dtouchl",  []>;
def DINVALL_idx  : LSU_FXBI_Inst<0b0001, "dinvall",  []>;
def DPURGEL_idx  : LSU_FXBI_Inst<0b0010, "dpurgel",  []>;
def DFLUSHL_idx  : LSU_FXBI_Inst<0b0011, "dflushl",  []>;
def I1INVALS_idx : LSU_FXBI_Inst<0b0101, "i1invals", [], LSU2_MEMW>;

// ---- LSU: Memory effects by set/way ----------------------------------------

def DINVALSW : LSU_FXSW_Inst<0b1001, "dinvalsw", []>;
def DPURGESW : LSU_FXSW_Inst<0b1010, "dpurgesw", []>;
def DFLUSHSW : LSU_FXSW_Inst<0b1011, "dflushsw", []>;

// ---- LSU: Memory and cache control (whole-cache, no operands) -------------

def D1INVAL : LSU_MCC_Inst<0b1000, "d1inval", []>;
def I1INVAL : LSU_MCC_Inst<0b1100, "i1inval", []>;



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
