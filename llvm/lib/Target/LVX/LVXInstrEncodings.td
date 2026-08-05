//===-- LVXInstrEncodings.td - -*- tablegen -*- ===//
//
// Instruction formats and encodings for the LVX instruction set.
//
// Generated from the LVX Machine Description System by MDS/BE/LLVM,
// for core lvx_v1.  DO NOT EDIT -- your changes will be overwritten by
// the next `make -C BE/LLVM install`.  Change lvx-mds/lvx-family's YAML
// description, or the generator in MDS/BE/LLVM/BIN, instead.
//
//===----------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Base classes, one per instruction encoding
//
// LVX is a VLIW: a bundle holds up to three 32-bit syllables, and a widened
// instruction spends two or three of them on one operation.  Each syllable's
// most significant bit is the parallel bit, set on every syllable except the
// last of its bundle.  The fixed bits below come from the machine
// description; only the final syllable's parallel bit is forced here, to 0,
// because this back end does not bundle yet and so every bundle holds exactly
// one instruction.
//
// Inst is numbered over the whole instruction, syllable 0 (first in memory) in
// the low bits, so a .X form's extension syllable is Inst{63-32}.
//===----------------------------------------------------------------------===//

// simple — 1 syllable, 32 bits
class LVXInst32<dag outs, dag ins, string asmstr, list<dag> pattern,
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
  let Inst{31}    = 0b0;   // parallel bit of the last syllable
}

// double — 2 syllables, 64 bits
class LVXInst64<dag outs, dag ins, string asmstr, list<dag> pattern,
                InstrItinClass itin>
    : Instruction {
  field bits<64> Inst;
  field bits<64> SoftFail = 0;
  let Namespace      = "LVX";
  let Size           = 8;
  let OutOperandList = outs;
  let InOperandList  = ins;
  let AsmString      = asmstr;
  let Pattern        = pattern;
  let Itinerary      = itin;
  let Inst{63}    = 0b0;   // parallel bit of the last syllable
}

// triple — 3 syllables, 96 bits
class LVXInst96<dag outs, dag ins, string asmstr, list<dag> pattern,
                InstrItinClass itin>
    : Instruction {
  field bits<96> Inst;
  field bits<96> SoftFail = 0;
  let Namespace      = "LVX";
  let Size           = 12;
  let OutOperandList = outs;
  let InOperandList  = ins;
  let AsmString      = asmstr;
  let Pattern        = pattern;
  let Itinerary      = itin;
  let Inst{95}    = 0b0;   // parallel bit of the last syllable
}

//===----------------------------------------------------------------------===//
// Itinerary classes, one per Scheduling entry of the machine description
//===----------------------------------------------------------------------===//

def ALL                      : InstrItinClass;
def BCU                      : InstrItinClass;
def BCU_XFER                 : InstrItinClass;
def BCU_XFER_BRRP            : InstrItinClass;
def BCU_BRRP                 : InstrItinClass;
def BCU_BRRP2                : InstrItinClass;
def BCU2                     : InstrItinClass;
def BCU2_X                   : InstrItinClass;
def BCU2_TINY_LSU            : InstrItinClass;
def ALU_TINY                 : InstrItinClass;
def ALU_TINY_X               : InstrItinClass;
def ALU_TINY_Y               : InstrItinClass;
def ALU_TINY_AUXR            : InstrItinClass;
def ALU_LITE                 : InstrItinClass;
def ALU_LITE_X               : InstrItinClass;
def ALU_LITE_Y               : InstrItinClass;
def ALU_LITE_MISC            : InstrItinClass;
def ALU_FULL                 : InstrItinClass;
def ALU_FULL_X               : InstrItinClass;
def ALU_FULL_Y               : InstrItinClass;
def ALU_FULL2                : InstrItinClass;
def LSU                      : InstrItinClass;
def LSU_X                    : InstrItinClass;
def LSU_Y                    : InstrItinClass;
def LSU_MEMW_ACCR            : InstrItinClass;
def LSU_MEMW_ACCR_X          : InstrItinClass;
def LSU_MEMW_ACCR_Y          : InstrItinClass;
def LSU2_MEMW                : InstrItinClass;
def LSU2_MEMW_X              : InstrItinClass;
def LSU2_MEMW_Y              : InstrItinClass;
def LSU_AUXR                 : InstrItinClass;
def LSU_AUXR_X               : InstrItinClass;
def LSU_AUXR_Y               : InstrItinClass;
def LSU_MEMW_AUXR            : InstrItinClass;
def LSU_MEMW_AUXR_X          : InstrItinClass;
def LSU_MEMW_AUXR_Y          : InstrItinClass;
def LSU2_MEMW_AUXR           : InstrItinClass;
def LSU2_MEMW_AUXR_X         : InstrItinClass;
def LSU2_MEMW_AUXR_Y         : InstrItinClass;
def LSU_MEMW_AUXW            : InstrItinClass;
def LSU_MEMW_AUXW_X          : InstrItinClass;
def LSU_MEMW_AUXW_Y          : InstrItinClass;
def LSU2_MEMW_AUXW           : InstrItinClass;
def LSU2_MEMW_AUXW_X         : InstrItinClass;
def LSU2_MEMW_AUXW_Y         : InstrItinClass;
def LSU_AUXW                 : InstrItinClass;
def LSU_AUXW_X               : InstrItinClass;
def LSU_AUXW_Y               : InstrItinClass;
def LSU_AUXR_AUXW            : InstrItinClass;
def LSU_AUXR_AUXW_X          : InstrItinClass;
def LSU_AUXR_AUXW_Y          : InstrItinClass;
def LSU2_MEMW_AUXR_AUXW      : InstrItinClass;
def LSU2_MEMW_AUXR_AUXW_X    : InstrItinClass;
def LSU2_MEMW_AUXR_AUXW_Y    : InstrItinClass;
def EXT                      : InstrItinClass;
def EXT_COMP                 : InstrItinClass;
def EXT_MISC                 : InstrItinClass;
def EXT_MISC_AUXW            : InstrItinClass;

//===----------------------------------------------------------------------===//
// BCU_IPC — BCU Instruction Pipeline Control
// simple (32 bits), syntax: %0
//===----------------------------------------------------------------------===//
class BCU_IPC_Inst<string mnemonic, list<dag> pattern,
                   InstrItinClass itin = ALL>
    : LVXInst32<(outs), (ins),
                !strconcat(mnemonic, ""),
                pattern, itin> {

  let Inst{30-20}  = 0b00011111010;
}

def AWAIT_IPC              : BCU_IPC_Inst<"await", []> {
  let Inst{19-18}  = 0b00;
}
def SLEEP_IPC              : BCU_IPC_Inst<"sleep", []> {
  let Inst{19-18}  = 0b01;
}
def STOP_IPC               : BCU_IPC_Inst<"stop", []> {
  let Inst{19-18}  = 0b10;
}
def BARRIER_IPC            : BCU_IPC_Inst<"barrier", []> {
  let Inst{19-18}  = 0b11;
}

//===----------------------------------------------------------------------===//
// BCU_TLB — BCU TLB Management
// simple (32 bits), syntax: %0
//===----------------------------------------------------------------------===//
class BCU_TLB_Inst<string mnemonic, list<dag> pattern,
                   InstrItinClass itin = ALL>
    : LVXInst32<(outs), (ins),
                !strconcat(mnemonic, ""),
                pattern, itin> {

  let Inst{30-21}  = 0b0001111100;
}

def TLBREAD_TLB            : BCU_TLB_Inst<"tlbread", []> {
  let Inst{20-18}  = 0b010;
}
def TLBPROBE_TLB           : BCU_TLB_Inst<"tlbprobe", []> {
  let Inst{20-18}  = 0b011;
}
def TLBWRITE_TLB           : BCU_TLB_Inst<"tlbwrite", []> {
  let Inst{20-18}  = 0b100;
}
def TLBDINVAL_TLB          : BCU_TLB_Inst<"tlbdinval", []> {
  let Inst{20-18}  = 0b110;
}
def TLBIINVAL_TLB          : BCU_TLB_Inst<"tlbiinval", []> {
  let Inst{20-18}  = 0b111;
}

//===----------------------------------------------------------------------===//
// BCU_BREAK — BCU Software Break
// simple (32 bits), syntax: %0 %1
//===----------------------------------------------------------------------===//
class BCU_BREAK_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin = ALL>
    : LVXInst32<(outs), (ins uimm2:$brknumber),
                !strconcat(mnemonic, " $brknumber"),
                pattern, itin> {
  bits<2>  brknumber;
  let Inst{1-0}    = brknumber;
  let Inst{30-18}  = 0b0001111111101;
}

def BREAK_BREAK            : BCU_BREAK_Inst<"break", []>;

//===----------------------------------------------------------------------===//
// BCU_RTS — BCU Return from Call and System Calls
// simple (32 bits), syntax: %0
//===----------------------------------------------------------------------===//
class BCU_RTS_Inst<string mnemonic, list<dag> pattern,
                   InstrItinClass itin>
    : LVXInst32<(outs), (ins),
                !strconcat(mnemonic, ""),
                pattern, itin> {

  let Inst{30-22}  = 0b000111111;
}

def RET_RTS                : BCU_RTS_Inst<"ret", [], BCU_XFER> {
  let Inst{21-18}  = 0b0111;
  let isReturn = 1;
  let isTerminator = 1;
  let isBarrier = 1;
  let Uses = [RA];
}
def RFE_RTS                : BCU_RTS_Inst<"rfe", [], ALL> {
  let Inst{21-18}  = 0b1000;
  let isReturn = 1;
  let isTerminator = 1;
  let isBarrier = 1;
}

//===----------------------------------------------------------------------===//
// BCU_IBC — BCU Indirect Branch and Call from Register
// simple (32 bits), syntax: %0 %1
//===----------------------------------------------------------------------===//
class BCU_IBC_Inst<string mnemonic, list<dag> pattern,
                   InstrItinClass itin = BCU_XFER_BRRP>
    : LVXInst32<(outs), (ins GPR:$rZ),
                !strconcat(mnemonic, " $rZ"),
                pattern, itin> {
  bits<6>  rZ;
  let Inst{5-0}    = rZ;
  let Inst{30-20}  = 0b00011111110;
}

def IGOTO_IBC              : BCU_IBC_Inst<"igoto", []> {
  let Inst{19-18}  = 0b01;
  let isBranch = 1;
  let isIndirectBranch = 1;
  let isTerminator = 1;
  let isBarrier = 1;
}
def ICALL_IBC              : BCU_IBC_Inst<"icall", []> {
  let Inst{19-18}  = 0b10;
  let isCall = 1;
  let Defs = [RA];
}

//===----------------------------------------------------------------------===//
// BCU_SCR — BCU Supervisor Call Register
// simple (32 bits), syntax: %0 %1
//===----------------------------------------------------------------------===//
class BCU_SCR_Inst<string mnemonic, list<dag> pattern,
                   InstrItinClass itin = ALL>
    : LVXInst32<(outs), (ins GPR:$rZ),
                !strconcat(mnemonic, " $rZ"),
                pattern, itin> {
  bits<6>  rZ;
  let Inst{5-0}    = rZ;
  let Inst{30-18}  = 0b0001111111100;
}

def SCALL_SCR              : BCU_SCR_Inst<"scall", []>;

//===----------------------------------------------------------------------===//
// BCU_SCI — BCU Supervisor Call Immediate
// simple (32 bits), syntax: %0 %1
//===----------------------------------------------------------------------===//
class BCU_SCI_Inst<string mnemonic, list<dag> pattern,
                   InstrItinClass itin = ALL>
    : LVXInst32<(outs), (ins uimm12:$sysnumber),
                !strconcat(mnemonic, " $sysnumber"),
                pattern, itin> {
  bits<12> sysnumber;
  let Inst{11-0}   = sysnumber;
  let Inst{30-18}  = 0b0001111111011;
}

def SCALL_SCI              : BCU_SCI_Inst<"scall", []>;

//===----------------------------------------------------------------------===//
// BCU_HLS — BCU Hardware Loop Setup
// simple (32 bits), syntax: %0 %1, %2
//===----------------------------------------------------------------------===//
class BCU_HLS_Inst<string mnemonic, list<dag> pattern,
                   InstrItinClass itin = ALL>
    : LVXInst32<(outs), (ins GPR:$rZ, brtarget17s2:$target),
                !strconcat(mnemonic, " $rZ, $target"),
                pattern, itin> {
  bits<6>  rZ;
  bits<17> target;
  let Inst{5-0}    = rZ;
  let Inst{22-6}   = target;
  let Inst{30-23}  = 0b00011110;
}

def LOOPDO_HLS             : BCU_HLS_Inst<"loopdo", []>;

//===----------------------------------------------------------------------===//
// BCU_WFX — BCU Half-Word Effects
// simple (32 bits), syntax: %0 %1, %2
//===----------------------------------------------------------------------===//
class BCU_WFX_Inst<string mnemonic, list<dag> pattern,
                   InstrItinClass itin = BCU2>
    : LVXInst32<(outs CR:$systemT2), (ins CR:$systemT2src, GPR:$rZ),
                !strconcat(mnemonic, " $systemT2, $rZ"),
                pattern, itin> {
  bits<9>  systemT2;
  bits<6>  rZ;
  let Constraints = "$systemT2src = $systemT2";
  let Inst{14-6}   = systemT2;
  let Inst{5-0}    = rZ;
  let Inst{30-19}  = 0b000111110111;
}

def WFXL_WFX               : BCU_WFX_Inst<"wfxl", []> {
  let Inst{18}     = 0b0;
}
def WFXM_WFX               : BCU_WFX_Inst<"wfxm", []> {
  let Inst{18}     = 0b1;
}

//===----------------------------------------------------------------------===//
// BCU_WFXA — BCU Half-Word Effects Alone
// simple (32 bits), syntax: %0 %1, %2
//===----------------------------------------------------------------------===//
class BCU_WFXA_Inst<string mnemonic, list<dag> pattern,
                    InstrItinClass itin = ALL>
    : LVXInst32<(outs CR:$systemAlone), (ins CR:$systemAlonesrc, GPR:$rZ),
                !strconcat(mnemonic, " $systemAlone, $rZ"),
                pattern, itin> {
  bits<9>  systemAlone;
  bits<6>  rZ;
  let Constraints = "$systemAlonesrc = $systemAlone";
  let Inst{14-6}   = systemAlone;
  let Inst{5-0}    = rZ;
  let Inst{30-19}  = 0b000111110111;
}

def WFXL_WFXA              : BCU_WFXA_Inst<"wfxl", []> {
  let Inst{18}     = 0b0;
}
def WFXM_WFXA              : BCU_WFXA_Inst<"wfxm", []> {
  let Inst{18}     = 0b1;
}

//===----------------------------------------------------------------------===//
// BCU_WFXHW — BCU Half-Word Effects [ONLY_FOR_HW]
// simple (32 bits), syntax: %0 %1, %2
//===----------------------------------------------------------------------===//
class BCU_WFXHW_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin = BCU2>
    : LVXInst32<(outs CR:$systemT4), (ins CR:$systemT4src, GPR:$rZ),
                !strconcat(mnemonic, " $systemT4, $rZ"),
                pattern, itin> {
  bits<9>  systemT4;
  bits<6>  rZ;
  let Constraints = "$systemT4src = $systemT4";
  let Inst{14-6}   = systemT4;
  let Inst{5-0}    = rZ;
  let Inst{30-19}  = 0b000111110111;
}

def WFXL_WFXHW             : BCU_WFXHW_Inst<"wfxl", []> {
  let Inst{18}     = 0b0;
}
def WFXM_WFXHW             : BCU_WFXHW_Inst<"wfxm", []> {
  let Inst{18}     = 0b1;
}

//===----------------------------------------------------------------------===//
// BCU_GSR — BCU Get System Registers
// simple (32 bits), syntax: %0 %1 = %2
//===----------------------------------------------------------------------===//
class BCU_GSR_Inst<string mnemonic, list<dag> pattern,
                   InstrItinClass itin = BCU2_TINY_LSU>
    : LVXInst32<(outs GPR:$rZ), (ins CR:$systemS2),
                !strconcat(mnemonic, " $rZ = $systemS2"),
                pattern, itin> {
  bits<6>  rZ;
  bits<9>  systemS2;
  let Inst{5-0}    = rZ;
  let Inst{14-6}   = systemS2;
  let Inst{30-18}  = 0b0001111110001;
}

def GET_GSR                : BCU_GSR_Inst<"get", []>;

//===----------------------------------------------------------------------===//
// BCU_GSRHW — BCU Get System Registers [ONLY_FOR_HW]
// simple (32 bits), syntax: %0 %1 = %2
//===----------------------------------------------------------------------===//
class BCU_GSRHW_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin = BCU2_TINY_LSU>
    : LVXInst32<(outs GPR:$rZ), (ins CR:$systemS3),
                !strconcat(mnemonic, " $rZ = $systemS3"),
                pattern, itin> {
  bits<6>  rZ;
  bits<9>  systemS3;
  let Inst{5-0}    = rZ;
  let Inst{14-6}   = systemS3;
  let Inst{30-18}  = 0b0001111110001;
}

def GET_GSRHW              : BCU_GSRHW_Inst<"get", []>;

//===----------------------------------------------------------------------===//
// BCU_IGSR — BCU Indirect Get System Registers
// simple (32 bits), syntax: %0 %1
//===----------------------------------------------------------------------===//
class BCU_IGSR_Inst<string mnemonic, list<dag> pattern,
                    InstrItinClass itin = BCU2_TINY_LSU>
    : LVXInst32<(outs GPR:$rZ), (ins GPR:$rZsrc),
                !strconcat(mnemonic, " $rZ"),
                pattern, itin> {
  bits<6>  rZ;
  let Constraints = "$rZsrc = $rZ";
  let Inst{5-0}    = rZ;
  let Inst{30-18}  = 0b0001111110110;
}

def IGET_IGSR              : BCU_IGSR_Inst<"iget", []>;

//===----------------------------------------------------------------------===//
// BCU_SET — BCU Set System Registers
// simple (32 bits), syntax: %0 %1 = %2
//===----------------------------------------------------------------------===//
class BCU_SET_Inst<string mnemonic, list<dag> pattern,
                   InstrItinClass itin = BCU2>
    : LVXInst32<(outs CR_SET:$systemT3), (ins CR_SET:$systemT3src, GPR:$rZ),
                !strconcat(mnemonic, " $systemT3 = $rZ"),
                pattern, itin> {
  bits<9>  systemT3;
  bits<6>  rZ;
  let Constraints = "$systemT3src = $systemT3";
  let Inst{14-6}   = systemT3;
  let Inst{5-0}    = rZ;
  let Inst{30-18}  = 0b0001111110000;
}

def SET_SET                : BCU_SET_Inst<"set", []>;

//===----------------------------------------------------------------------===//
// BCU_SETA — BCU Set System Register Alone
// simple (32 bits), syntax: %0 %1 = %2
//===----------------------------------------------------------------------===//
class BCU_SETA_Inst<string mnemonic, list<dag> pattern,
                    InstrItinClass itin = ALL>
    : LVXInst32<(outs CR:$systemAlone), (ins CR:$systemAlonesrc, GPR:$rZ),
                !strconcat(mnemonic, " $systemAlone = $rZ"),
                pattern, itin> {
  bits<9>  systemAlone;
  bits<6>  rZ;
  let Constraints = "$systemAlonesrc = $systemAlone";
  let Inst{14-6}   = systemAlone;
  let Inst{5-0}    = rZ;
  let Inst{30-18}  = 0b0001111110000;
}

def SET_SETA               : BCU_SETA_Inst<"set", []>;

//===----------------------------------------------------------------------===//
// BCU_SETRA — BCU Set System Register RA
// simple (32 bits), syntax: %0 %1 = %2
//===----------------------------------------------------------------------===//
class BCU_SETRA_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin = BCU2>
    : LVXInst32<(outs CR_RA:$systemRA), (ins CR_RA:$systemRAsrc, GPR:$rZ),
                !strconcat(mnemonic, " $systemRA = $rZ"),
                pattern, itin> {
  bits<9>  systemRA;
  bits<6>  rZ;
  let Constraints = "$systemRAsrc = $systemRA";
  let Inst{14-6}   = systemRA;
  let Inst{5-0}    = rZ;
  let Inst{30-18}  = 0b0001111110000;
}

def SET_SETRA              : BCU_SETRA_Inst<"set", []>;

//===----------------------------------------------------------------------===//
// BCU_SETHW — BCU Set System Registers [ONLY_FOR_HW]
// simple (32 bits), syntax: %0 %1 = %2
//===----------------------------------------------------------------------===//
class BCU_SETHW_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin = BCU2>
    : LVXInst32<(outs CR:$systemT4), (ins CR:$systemT4src, GPR:$rZ),
                !strconcat(mnemonic, " $systemT4 = $rZ"),
                pattern, itin> {
  bits<9>  systemT4;
  bits<6>  rZ;
  let Constraints = "$systemT4src = $systemT4";
  let Inst{14-6}   = systemT4;
  let Inst{5-0}    = rZ;
  let Inst{30-18}  = 0b0001111110000;
}

def SET_SETHW              : BCU_SETHW_Inst<"set", []>;

//===----------------------------------------------------------------------===//
// BCU_RSWAP — BCU General and System Register Swap
// simple (32 bits), syntax: %0 %1 = %2
//===----------------------------------------------------------------------===//
class BCU_RSWAP_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin = BCU2_TINY_LSU>
    : LVXInst32<(outs GPR:$rZ, CR:$systemS4), (ins GPR:$rZsrc, CR:$systemS4src),
                !strconcat(mnemonic, " $rZ = $systemS4"),
                pattern, itin> {
  bits<6>  rZ;
  bits<9>  systemS4;
  let Constraints = "$rZsrc = $rZ, $systemS4src = $systemS4";
  let Inst{5-0}    = rZ;
  let Inst{14-6}   = systemS4;
  let Inst{30-18}  = 0b0001111110010;
}

def RSWAP_RSWAP            : BCU_RSWAP_Inst<"rswap", []>;

//===----------------------------------------------------------------------===//
// BCU_RSWAPA — BCU General and System Register Swap Alone
// simple (32 bits), syntax: %0 %1 = %2
//===----------------------------------------------------------------------===//
class BCU_RSWAPA_Inst<string mnemonic, list<dag> pattern,
                      InstrItinClass itin = ALL>
    : LVXInst32<(outs GPR:$rZ, CR:$systemAlone), (ins GPR:$rZsrc, CR:$systemAlonesrc),
                !strconcat(mnemonic, " $rZ = $systemAlone"),
                pattern, itin> {
  bits<6>  rZ;
  bits<9>  systemAlone;
  let Constraints = "$rZsrc = $rZ, $systemAlonesrc = $systemAlone";
  let Inst{5-0}    = rZ;
  let Inst{14-6}   = systemAlone;
  let Inst{30-18}  = 0b0001111110010;
}

def RSWAP_RSWAPA           : BCU_RSWAPA_Inst<"rswap", []>;

//===----------------------------------------------------------------------===//
// BCU_RSWAPHW — BCU General and System Register Swap [ONLY_FOR_HW]
// simple (32 bits), syntax: %0 %1 = %2
//===----------------------------------------------------------------------===//
class BCU_RSWAPHW_Inst<string mnemonic, list<dag> pattern,
                       InstrItinClass itin = BCU2_TINY_LSU>
    : LVXInst32<(outs GPR:$rZ, CR:$systemS3), (ins GPR:$rZsrc, CR:$systemS3src),
                !strconcat(mnemonic, " $rZ = $systemS3"),
                pattern, itin> {
  bits<6>  rZ;
  bits<9>  systemS3;
  let Constraints = "$rZsrc = $rZ, $systemS3src = $systemS3";
  let Inst{5-0}    = rZ;
  let Inst{14-6}   = systemS3;
  let Inst{30-18}  = 0b0001111110010;
}

def RSWAP_RSWAPHW          : BCU_RSWAPHW_Inst<"rswap", []>;

//===----------------------------------------------------------------------===//
// BCU_CSR — BCU RISC-V CSR access (read/write, read/set, read/clear)
// simple (32 bits), syntax: %0 %1 = %2
//===----------------------------------------------------------------------===//
class BCU_CSR_Inst<string mnemonic, list<dag> pattern,
                   InstrItinClass itin = BCU2_TINY_LSU>
    : LVXInst32<(outs GPR:$rZ), (ins GPR:$rZsrc, uimm12:$csrnumber),
                !strconcat(mnemonic, " $rZ = $csrnumber"),
                pattern, itin> {
  bits<6>  rZ;
  bits<12> csrnumber;
  let Constraints = "$rZsrc = $rZ";
  let Inst{5-0}    = rZ;
  let Inst{17-6}   = csrnumber;
  let Inst{30-21}  = 0b0001111110;
}

def CSRRW_CSR              : BCU_CSR_Inst<"csrrw", []> {
  let Inst{20-18}  = 0b011;
}
def CSRRS_CSR              : BCU_CSR_Inst<"csrrs", []> {
  let Inst{20-18}  = 0b100;
}
def CSRRC_CSR              : BCU_CSR_Inst<"csrrc", []> {
  let Inst{20-18}  = 0b101;
}
def FRCSR_CSR              : BCU_CSR_Inst<"frcsr", []> {
  let Inst{20-6}   = 0b100000000000011;
}
def FSCSR_CSR              : BCU_CSR_Inst<"fscsr", []> {
  let Inst{20-6}   = 0b011000000000011;
}
def FRFLAGS_CSR            : BCU_CSR_Inst<"frflags", []> {
  let Inst{20-6}   = 0b100000000000001;
}
def FSFLAGS_CSR            : BCU_CSR_Inst<"fsflags", []> {
  let Inst{20-6}   = 0b011000000000001;
}
def FRRM_CSR               : BCU_CSR_Inst<"frrm", []> {
  let Inst{20-6}   = 0b100000000000010;
}
def FSRM_CSR               : BCU_CSR_Inst<"fsrm", []> {
  let Inst{20-6}   = 0b011000000000010;
}

//===----------------------------------------------------------------------===//
// BCU_PGI — BCU Processing Group Instructions
// simple (32 bits), syntax: %0 %1
// One of 2 classes for this format: its instructions do not all
// read and write the same operands, so they cannot share an operand list.
// This one covers WAITIT_PGI.
//===----------------------------------------------------------------------===//
class BCU_PGI_Inst<string mnemonic, list<dag> pattern,
                   InstrItinClass itin = BCU2_TINY_LSU>
    : LVXInst32<(outs GPR:$rZ), (ins GPR:$rZsrc),
                !strconcat(mnemonic, " $rZ"),
                pattern, itin> {
  bits<6>  rZ;
  let Constraints = "$rZsrc = $rZ";
  let Inst{5-0}    = rZ;
  let Inst{30-18}  = 0b0001111101100;
}

def WAITIT_PGI             : BCU_PGI_Inst<"waitit", []>;

//===----------------------------------------------------------------------===//
// BCU_PGI — BCU Processing Group Instructions
// simple (32 bits), syntax: %0 %1
// One of 2 classes for this format: its instructions do not all
// read and write the same operands, so they cannot share an operand list.
// This one covers SYNCGROUP_PGI.
//===----------------------------------------------------------------------===//
class BCU_PGI_2_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin = BCU2>
    : LVXInst32<(outs), (ins GPR:$rZ),
                !strconcat(mnemonic, " $rZ"),
                pattern, itin> {
  bits<6>  rZ;
  let Inst{5-0}    = rZ;
  let Inst{30-18}  = 0b0001111101101;
}

def SYNCGROUP_PGI          : BCU_PGI_2_Inst<"syncgroup", []>;

//===----------------------------------------------------------------------===//
// BCU_UB — BCU Unconditional Branches
// simple (32 bits), syntax: %0 %1
//===----------------------------------------------------------------------===//
class BCU_UB_Inst<string mnemonic, list<dag> pattern,
                  InstrItinClass itin = BCU_XFER>
    : LVXInst32<(outs), (ins brtarget27s2:$target),
                !strconcat(mnemonic, " $target"),
                pattern, itin> {
  bits<27> target;
  let Inst{26-0}   = target;
  let Inst{30-28}  = 0b001;
}

def GOTO_UB                : BCU_UB_Inst<"goto", []> {
  let Inst{27}     = 0b0;
  let isBranch = 1;
  let isTerminator = 1;
  let isBarrier = 1;
}
def CALL_UB                : BCU_UB_Inst<"call", []> {
  let Inst{27}     = 0b1;
  let isCall = 1;
  let Defs = [RA];
}

//===----------------------------------------------------------------------===//
// BCU_UB.X — BCU Unconditional Branches Extended
// double (64 bits), syntax: %0 %1
//===----------------------------------------------------------------------===//
class BCU_UB_X_Inst<string mnemonic, list<dag> pattern,
                    InstrItinClass itin = BCU2_X>
    : LVXInst64<(outs), (ins brtarget54s2:$target),
                !strconcat(mnemonic, " $target"),
                pattern, itin> {
  bits<54> target;
  let Inst{58-32}  = target{53-27};
  let Inst{26-0}   = target{26-0};
  let Inst{62-59}  = 0b0000;
  let Inst{31-28}  = 0b1001;
}

def GOTOX_UB_X             : BCU_UB_X_Inst<"gotox", []> {
  let Inst{27}     = 0b0;
  let isBranch = 1;
  let isTerminator = 1;
  let isBarrier = 1;
}
def CALLX_UB_X             : BCU_UB_X_Inst<"callx", []> {
  let Inst{27}     = 0b1;
  let isCall = 1;
  let Defs = [RA];
}

//===----------------------------------------------------------------------===//
// BCU_CB — BCU Conditional Branches
// simple (32 bits), syntax: %0%1 %2? %3
//===----------------------------------------------------------------------===//
class BCU_CB_Inst<string mnemonic, list<dag> pattern,
                  InstrItinClass itin = BCU_BRRP>
    : LVXInst32<(outs), (ins bcucond:$bcucond, GPR:$rZ, brtarget17s2:$target),
                !strconcat(mnemonic, "${bcucond} $rZ? $target"),
                pattern, itin> {
  bits<4>  bcucond;
  bits<6>  rZ;
  bits<17> target;
  let Inst{26-23}  = bcucond;
  let Inst{5-0}    = rZ;
  let Inst{22-6}   = target;
  let Inst{30-27}  = 0b0001;
}

def CB_CB                  : BCU_CB_Inst<"cb", []> {
  let isBranch = 1;
  let isTerminator = 1;
}

//===----------------------------------------------------------------------===//
// BCU_CB.X — BCU Conditional Branches Extended
// double (64 bits), syntax: %0%1 %2? %3
//===----------------------------------------------------------------------===//
class BCU_CB_X_Inst<string mnemonic, list<dag> pattern,
                    InstrItinClass itin = BCU2_X>
    : LVXInst64<(outs), (ins bcucond:$bcucond, GPR:$rZ, brtarget44s2:$target),
                !strconcat(mnemonic, "${bcucond} $rZ? $target"),
                pattern, itin> {
  bits<4>  bcucond;
  bits<6>  rZ;
  bits<44> target;
  let Inst{26-23}  = bcucond;
  let Inst{5-0}    = rZ;
  let Inst{58-32}  = target{43-17};
  let Inst{22-6}   = target{16-0};
  let Inst{62-59}  = 0b0000;
  let Inst{31-27}  = 0b10001;
}

def CBX_CB_X               : BCU_CB_X_Inst<"cbx", []> {
  let isBranch = 1;
  let isTerminator = 1;
}

//===----------------------------------------------------------------------===//
// BCU_CCB — BCU Compare Conditional Branches
// simple (32 bits), syntax: %0%1 %2, %3 ? %4
//===----------------------------------------------------------------------===//
class BCU_CCB_Inst<string mnemonic, list<dag> pattern,
                   InstrItinClass itin = BCU_BRRP2>
    : LVXInst32<(outs), (ins ccbcomp:$ccbcomp, GPR:$rZ, GPR:$rY, brtarget11s2:$target),
                !strconcat(mnemonic, "${ccbcomp} $rZ, $rY ? $target"),
                pattern, itin> {
  bits<4>  ccbcomp;
  bits<6>  rZ;
  bits<6>  rY;
  bits<11> target;
  let Inst{26-23}  = ccbcomp;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = rY;
  let Inst{22-12}  = target;
  let Inst{30-27}  = 0b0000;
}

def CCB_CCB                : BCU_CCB_Inst<"ccb", []> {
  let isBranch = 1;
  let isTerminator = 1;
}
def ERROP_CCB              : BCU_CCB_Inst<"errop", []> {
  let Inst{26-0}   = 0b000000000000000000000000000;
}

//===----------------------------------------------------------------------===//
// BCU_CCB.X — BCU Compare Conditional Branches Extended
// double (64 bits), syntax: %0%1 %2, %3 ? %4
//===----------------------------------------------------------------------===//
class BCU_CCB_X_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin = BCU2_X>
    : LVXInst64<(outs), (ins ccbcomp:$ccbcomp, GPR:$rZ, GPR:$rY, brtarget38s2:$target),
                !strconcat(mnemonic, "${ccbcomp} $rZ, $rY ? $target"),
                pattern, itin> {
  bits<4>  ccbcomp;
  bits<6>  rZ;
  bits<6>  rY;
  bits<38> target;
  let Inst{26-23}  = ccbcomp;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = rY;
  let Inst{58-32}  = target{37-11};
  let Inst{22-12}  = target{10-0};
  let Inst{62-59}  = 0b0000;
  let Inst{31-27}  = 0b10000;
}

def CCBX_CCB_X             : BCU_CCB_X_Inst<"ccbx", []> {
  let isBranch = 1;
  let isTerminator = 1;
}

//===----------------------------------------------------------------------===//
// BCU_GUARD — BCU Guarded Execution
// simple (32 bits), syntax: %0%1 %2? %3
//===----------------------------------------------------------------------===//
class BCU_GUARD_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin = BCU_BRRP>
    : LVXInst32<(outs), (ins bcucond:$bcucond, GPR:$rZ, uimm6:$activate),
                !strconcat(mnemonic, "${bcucond} $rZ? $activate"),
                pattern, itin> {
  bits<4>  bcucond;
  bits<6>  rZ;
  bits<8>  activate;
  let Inst{17-14}  = bcucond;
  let Inst{5-0}    = rZ;
  let Inst{13-6}   = activate;
  let Inst{30-18}  = 0b0001111100000;
}

def GUARD_GUARD            : BCU_GUARD_Inst<"guard", []>;

//===----------------------------------------------------------------------===//
// BCU_BLEND — BCU Blended Execution
// simple (32 bits), syntax: %0%1%2 %3? %4
//===----------------------------------------------------------------------===//
class BCU_BLEND_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin = BCU_BRRP>
    : LVXInst32<(outs), (ins lanetodo:$lanetodo, lanesize:$lanesize, GPR:$rZ, uimm6:$activate),
                !strconcat(mnemonic, "${lanetodo}${lanesize} $rZ? $activate"),
                pattern, itin> {
  bits<2>  lanetodo;
  bits<2>  lanesize;
  bits<6>  rZ;
  bits<8>  activate;
  let Inst{17-16}  = lanetodo;
  let Inst{15-14}  = lanesize;
  let Inst{5-0}    = rZ;
  let Inst{13-6}   = activate;
  let Inst{30-18}  = 0b0001111100001;
}

def BLEND_BLEND            : BCU_BLEND_Inst<"blend", []>;

//===----------------------------------------------------------------------===//
// LSU_LSBO — LSU Load Scalar Base Offset
// simple (32 bits), syntax: %0%4 %1 = %2[%3]
//===----------------------------------------------------------------------===//
class LSU_LSBO_Inst<string mnemonic, list<dag> pattern,
                    InstrItinClass itin = LSU_AUXW>
    : LVXInst32<(outs GPR:$rW), (ins simm10:$off, GPR:$rZ, variant:$variant),
                !strconcat(mnemonic, "${variant} $rW = $off[$rZ]"),
                pattern, itin> {
  bits<6>  rW;
  bits<10> off;
  bits<6>  rZ;
  bits<2>  variant;
  let Inst{23-18}  = rW;
  let Inst{15-6}   = off;
  let Inst{5-0}    = rZ;
  let Inst{25-24}  = variant;
  let Inst{30-29}  = 0b01;
  let Inst{17-16}  = 0b00;
  let mayLoad  = 1;
}

def LBZ_LSBO               : LSU_LSBO_Inst<"lbz", []> {
  let Inst{28-26}  = 0b000;
}
def LBS_LSBO               : LSU_LSBO_Inst<"lbs", []> {
  let Inst{28-26}  = 0b001;
}
def LHZ_LSBO               : LSU_LSBO_Inst<"lhz", []> {
  let Inst{28-26}  = 0b010;
}
def LHS_LSBO               : LSU_LSBO_Inst<"lhs", []> {
  let Inst{28-26}  = 0b011;
}
def LWZ_LSBO               : LSU_LSBO_Inst<"lwz", []> {
  let Inst{28-26}  = 0b100;
}
def LWS_LSBO               : LSU_LSBO_Inst<"lws", []> {
  let Inst{28-26}  = 0b101;
}
def LD_LSBO                : LSU_LSBO_Inst<"ld", []> {
  let Inst{28-26}  = 0b110;
}

//===----------------------------------------------------------------------===//
// LSU_LSBO.X — LSU Load Scalar Base Offset Extended
// double (64 bits), syntax: %0%4 %1 = %2[%3]
//===----------------------------------------------------------------------===//
class LSU_LSBO_X_Inst<string mnemonic, list<dag> pattern,
                      InstrItinClass itin = LSU_AUXW_X>
    : LVXInst64<(outs GPR:$rW), (ins simm37:$off, GPR:$rZ, variant:$variant),
                !strconcat(mnemonic, "${variant} $rW = $off[$rZ]"),
                pattern, itin> {
  bits<6>  rW;
  bits<37> off;
  bits<6>  rZ;
  bits<2>  variant;
  let Inst{23-18}  = rW;
  let Inst{58-32}  = off{36-10};
  let Inst{15-6}   = off{9-0};
  let Inst{5-0}    = rZ;
  let Inst{25-24}  = variant;
  let Inst{62-61}  = 0b00;
  let Inst{31-29}  = 0b101;
  let Inst{17-16}  = 0b00;
  let mayLoad  = 1;
}

def LBZ_LSBO_X             : LSU_LSBO_X_Inst<"lbz", []> {
  let Inst{28-26}  = 0b000;
}
def LBS_LSBO_X             : LSU_LSBO_X_Inst<"lbs", []> {
  let Inst{28-26}  = 0b001;
}
def LHZ_LSBO_X             : LSU_LSBO_X_Inst<"lhz", []> {
  let Inst{28-26}  = 0b010;
}
def LHS_LSBO_X             : LSU_LSBO_X_Inst<"lhs", []> {
  let Inst{28-26}  = 0b011;
}
def LWZ_LSBO_X             : LSU_LSBO_X_Inst<"lwz", []> {
  let Inst{28-26}  = 0b100;
}
def LWS_LSBO_X             : LSU_LSBO_X_Inst<"lws", []> {
  let Inst{28-26}  = 0b101;
}
def LD_LSBO_X              : LSU_LSBO_X_Inst<"ld", []> {
  let Inst{28-26}  = 0b110;
}

//===----------------------------------------------------------------------===//
// LSU_LSBO.Y — LSU Load Scalar Base Offset Extended Extended
// triple (96 bits), syntax: %0%4 %1 = %2[%3]
//===----------------------------------------------------------------------===//
class LSU_LSBO_Y_Inst<string mnemonic, list<dag> pattern,
                      InstrItinClass itin = LSU_AUXW_Y>
    : LVXInst96<(outs GPR:$rW), (ins wimm64:$off, GPR:$rZ, variant:$variant),
                !strconcat(mnemonic, "${variant} $rW = $off[$rZ]"),
                pattern, itin> {
  bits<6>  rW;
  bits<64> off;
  bits<6>  rZ;
  bits<2>  variant;
  let Inst{23-18}  = rW;
  let Inst{90-64}  = off{63-37};
  let Inst{58-32}  = off{36-10};
  let Inst{15-6}   = off{9-0};
  let Inst{5-0}    = rZ;
  let Inst{25-24}  = variant;
  let Inst{94-93}  = 0b00;
  let Inst{63-61}  = 0b100;
  let Inst{31-29}  = 0b101;
  let Inst{17-16}  = 0b00;
  let mayLoad  = 1;
}

def LBZ_LSBO_Y             : LSU_LSBO_Y_Inst<"lbz", []> {
  let Inst{28-26}  = 0b000;
}
def LBS_LSBO_Y             : LSU_LSBO_Y_Inst<"lbs", []> {
  let Inst{28-26}  = 0b001;
}
def LHZ_LSBO_Y             : LSU_LSBO_Y_Inst<"lhz", []> {
  let Inst{28-26}  = 0b010;
}
def LHS_LSBO_Y             : LSU_LSBO_Y_Inst<"lhs", []> {
  let Inst{28-26}  = 0b011;
}
def LWZ_LSBO_Y             : LSU_LSBO_Y_Inst<"lwz", []> {
  let Inst{28-26}  = 0b100;
}
def LWS_LSBO_Y             : LSU_LSBO_Y_Inst<"lws", []> {
  let Inst{28-26}  = 0b101;
}
def LD_LSBO_Y              : LSU_LSBO_Y_Inst<"ld", []> {
  let Inst{28-26}  = 0b110;
}

//===----------------------------------------------------------------------===//
// LSU_LSBI — LSU Load Scalar Base + Index
// simple (32 bits), syntax: %0%4 %1 = %2[%3]
//===----------------------------------------------------------------------===//
class LSU_LSBI_Inst<string mnemonic, list<dag> pattern,
                    InstrItinClass itin = LSU_AUXW>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rY, GPR:$rZ, variant:$variant),
                !strconcat(mnemonic, "${variant} $rW = $rY[$rZ]"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rY;
  bits<6>  rZ;
  bits<2>  variant;
  let Inst{23-18}  = rW;
  let Inst{11-6}   = rY;
  let Inst{5-0}    = rZ;
  let Inst{25-24}  = variant;
  let Inst{30-29}  = 0b01;
  let Inst{17-13}  = 0b10111;
  let mayLoad  = 1;
}

def LBZ_LSBI               : LSU_LSBI_Inst<"lbz", []> {
  let Inst{28-26}  = 0b000;
}
def LBS_LSBI               : LSU_LSBI_Inst<"lbs", []> {
  let Inst{28-26}  = 0b001;
}
def LHZ_LSBI               : LSU_LSBI_Inst<"lhz", []> {
  let Inst{28-26}  = 0b010;
}
def LHS_LSBI               : LSU_LSBI_Inst<"lhs", []> {
  let Inst{28-26}  = 0b011;
}
def LWZ_LSBI               : LSU_LSBI_Inst<"lwz", []> {
  let Inst{28-26}  = 0b100;
}
def LWS_LSBI               : LSU_LSBI_Inst<"lws", []> {
  let Inst{28-26}  = 0b101;
}
def LD_LSBI                : LSU_LSBI_Inst<"ld", []> {
  let Inst{28-26}  = 0b110;
}

//===----------------------------------------------------------------------===//
// LSU_LQBO — LSU Load Quadruple Base Offset
// simple (32 bits), syntax: %0%4 %1 = %2[%3]
//===----------------------------------------------------------------------===//
class LSU_LQBO_Inst<string mnemonic, list<dag> pattern,
                    InstrItinClass itin = LSU_AUXW>
    : LVXInst32<(outs GPR128:$rM), (ins simm10:$off, GPR:$rZ, variant:$variant),
                !strconcat(mnemonic, "${variant} $rM = $off[$rZ]"),
                pattern, itin> {
  bits<5>  rM;
  bits<10> off;
  bits<6>  rZ;
  bits<2>  variant;
  let Inst{23-19}  = rM;
  let Inst{15-6}   = off;
  let Inst{5-0}    = rZ;
  let Inst{25-24}  = variant;
  let Inst{30-26}  = 0b01111;
  let Inst{18-16}  = 0b000;
  let mayLoad  = 1;
}

def LQ_LQBO                : LSU_LQBO_Inst<"lq", []>;

//===----------------------------------------------------------------------===//
// LSU_LQBO.X — LSU Load Quadruple Base Offset Extended
// double (64 bits), syntax: %0%4 %1 = %2[%3]
//===----------------------------------------------------------------------===//
class LSU_LQBO_X_Inst<string mnemonic, list<dag> pattern,
                      InstrItinClass itin = LSU_AUXW_X>
    : LVXInst64<(outs GPR128:$rM), (ins simm37:$off, GPR:$rZ, variant:$variant),
                !strconcat(mnemonic, "${variant} $rM = $off[$rZ]"),
                pattern, itin> {
  bits<5>  rM;
  bits<37> off;
  bits<6>  rZ;
  bits<2>  variant;
  let Inst{23-19}  = rM;
  let Inst{58-32}  = off{36-10};
  let Inst{15-6}   = off{9-0};
  let Inst{5-0}    = rZ;
  let Inst{25-24}  = variant;
  let Inst{62-61}  = 0b00;
  let Inst{31-26}  = 0b101111;
  let Inst{18-16}  = 0b000;
  let mayLoad  = 1;
}

def LQ_LQBO_X              : LSU_LQBO_X_Inst<"lq", []>;

//===----------------------------------------------------------------------===//
// LSU_LQBO.Y — LSU Load Quadruple Base Offset Extended Extended
// triple (96 bits), syntax: %0%4 %1 = %2[%3]
//===----------------------------------------------------------------------===//
class LSU_LQBO_Y_Inst<string mnemonic, list<dag> pattern,
                      InstrItinClass itin = LSU_AUXW_Y>
    : LVXInst96<(outs GPR128:$rM), (ins wimm64:$off, GPR:$rZ, variant:$variant),
                !strconcat(mnemonic, "${variant} $rM = $off[$rZ]"),
                pattern, itin> {
  bits<5>  rM;
  bits<64> off;
  bits<6>  rZ;
  bits<2>  variant;
  let Inst{23-19}  = rM;
  let Inst{90-64}  = off{63-37};
  let Inst{58-32}  = off{36-10};
  let Inst{15-6}   = off{9-0};
  let Inst{5-0}    = rZ;
  let Inst{25-24}  = variant;
  let Inst{94-93}  = 0b00;
  let Inst{63-61}  = 0b100;
  let Inst{31-26}  = 0b101111;
  let Inst{18-16}  = 0b000;
  let mayLoad  = 1;
}

def LQ_LQBO_Y              : LSU_LQBO_Y_Inst<"lq", []>;

//===----------------------------------------------------------------------===//
// LSU_LQBI — LSU Load Quadruple Base + Index
// simple (32 bits), syntax: %0%4 %1 = %2[%3]
//===----------------------------------------------------------------------===//
class LSU_LQBI_Inst<string mnemonic, list<dag> pattern,
                    InstrItinClass itin = LSU_AUXW>
    : LVXInst32<(outs GPR128:$rM), (ins GPR:$rY, GPR:$rZ, variant:$variant),
                !strconcat(mnemonic, "${variant} $rM = $rY[$rZ]"),
                pattern, itin> {
  bits<5>  rM;
  bits<6>  rY;
  bits<6>  rZ;
  bits<2>  variant;
  let Inst{23-19}  = rM;
  let Inst{11-6}   = rY;
  let Inst{5-0}    = rZ;
  let Inst{25-24}  = variant;
  let Inst{30-26}  = 0b01111;
  let Inst{18-13}  = 0b010111;
  let mayLoad  = 1;
}

def LQ_LQBI                : LSU_LQBI_Inst<"lq", []>;

//===----------------------------------------------------------------------===//
// LSU_LOBO — LSU Load Octuple Base Offset
// simple (32 bits), syntax: %0%4 %1 = %2[%3]
//===----------------------------------------------------------------------===//
class LSU_LOBO_Inst<string mnemonic, list<dag> pattern,
                    InstrItinClass itin = LSU_AUXW>
    : LVXInst32<(outs GPR256:$rN), (ins simm10:$off, GPR:$rZ, variant:$variant),
                !strconcat(mnemonic, "${variant} $rN = $off[$rZ]"),
                pattern, itin> {
  bits<4>  rN;
  bits<10> off;
  bits<6>  rZ;
  bits<2>  variant;
  let Inst{23-20}  = rN;
  let Inst{15-6}   = off;
  let Inst{5-0}    = rZ;
  let Inst{25-24}  = variant;
  let Inst{30-26}  = 0b01111;
  let Inst{19-16}  = 0b0100;
  let mayLoad  = 1;
}

def LO_LOBO                : LSU_LOBO_Inst<"lo", []>;

//===----------------------------------------------------------------------===//
// LSU_LOBO.X — LSU Load Octuple Base Offset Extended
// double (64 bits), syntax: %0%4 %1 = %2[%3]
//===----------------------------------------------------------------------===//
class LSU_LOBO_X_Inst<string mnemonic, list<dag> pattern,
                      InstrItinClass itin = LSU_AUXW_X>
    : LVXInst64<(outs GPR256:$rN), (ins simm37:$off, GPR:$rZ, variant:$variant),
                !strconcat(mnemonic, "${variant} $rN = $off[$rZ]"),
                pattern, itin> {
  bits<4>  rN;
  bits<37> off;
  bits<6>  rZ;
  bits<2>  variant;
  let Inst{23-20}  = rN;
  let Inst{58-32}  = off{36-10};
  let Inst{15-6}   = off{9-0};
  let Inst{5-0}    = rZ;
  let Inst{25-24}  = variant;
  let Inst{62-61}  = 0b00;
  let Inst{31-26}  = 0b101111;
  let Inst{19-16}  = 0b0100;
  let mayLoad  = 1;
}

def LO_LOBO_X              : LSU_LOBO_X_Inst<"lo", []>;

//===----------------------------------------------------------------------===//
// LSU_LOBO.Y — LSU Load Octuple Base Offset Extended Extended
// triple (96 bits), syntax: %0%4 %1 = %2[%3]
//===----------------------------------------------------------------------===//
class LSU_LOBO_Y_Inst<string mnemonic, list<dag> pattern,
                      InstrItinClass itin = LSU_AUXW_Y>
    : LVXInst96<(outs GPR256:$rN), (ins wimm64:$off, GPR:$rZ, variant:$variant),
                !strconcat(mnemonic, "${variant} $rN = $off[$rZ]"),
                pattern, itin> {
  bits<4>  rN;
  bits<64> off;
  bits<6>  rZ;
  bits<2>  variant;
  let Inst{23-20}  = rN;
  let Inst{90-64}  = off{63-37};
  let Inst{58-32}  = off{36-10};
  let Inst{15-6}   = off{9-0};
  let Inst{5-0}    = rZ;
  let Inst{25-24}  = variant;
  let Inst{94-93}  = 0b00;
  let Inst{63-61}  = 0b100;
  let Inst{31-26}  = 0b101111;
  let Inst{19-16}  = 0b0100;
  let mayLoad  = 1;
}

def LO_LOBO_Y              : LSU_LOBO_Y_Inst<"lo", []>;

//===----------------------------------------------------------------------===//
// LSU_LOBI — LSU Load Octuple Base + Index
// simple (32 bits), syntax: %0%4 %1 = %2[%3]
//===----------------------------------------------------------------------===//
class LSU_LOBI_Inst<string mnemonic, list<dag> pattern,
                    InstrItinClass itin = LSU_AUXW>
    : LVXInst32<(outs GPR256:$rN), (ins GPR:$rY, GPR:$rZ, variant:$variant),
                !strconcat(mnemonic, "${variant} $rN = $rY[$rZ]"),
                pattern, itin> {
  bits<4>  rN;
  bits<6>  rY;
  bits<6>  rZ;
  bits<2>  variant;
  let Inst{23-20}  = rN;
  let Inst{11-6}   = rY;
  let Inst{5-0}    = rZ;
  let Inst{25-24}  = variant;
  let Inst{30-26}  = 0b01111;
  let Inst{19-13}  = 0b0110111;
  let mayLoad  = 1;
}

def LO_LOBI                : LSU_LOBI_Inst<"lo", []>;

//===----------------------------------------------------------------------===//
// LSU_SSBO — LSU Store Scalar Base Offset
// simple (32 bits), syntax: %0 %1[%2] = %3
//===----------------------------------------------------------------------===//
class LSU_SSBO_Inst<string mnemonic, list<dag> pattern,
                    InstrItinClass itin = LSU_MEMW_AUXR>
    : LVXInst32<(outs), (ins simm10:$off, GPR:$rZ, GPR:$rT),
                !strconcat(mnemonic, " $off[$rZ] = $rT"),
                pattern, itin> {
  bits<10> off;
  bits<6>  rZ;
  bits<6>  rT;
  let Inst{15-6}   = off;
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{30-26}  = 0b01100;
  let Inst{17-16}  = 0b01;
  let mayStore = 1;
}

def SB_SSBO                : LSU_SSBO_Inst<"sb", []> {
  let Inst{25-24}  = 0b00;
}
def SH_SSBO                : LSU_SSBO_Inst<"sh", []> {
  let Inst{25-24}  = 0b01;
}
def SW_SSBO                : LSU_SSBO_Inst<"sw", []> {
  let Inst{25-24}  = 0b10;
}
def SD_SSBO                : LSU_SSBO_Inst<"sd", []> {
  let Inst{25-24}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_SSBO.X — LSU Store Scalar Base Offset Extended
// double (64 bits), syntax: %0 %1[%2] = %3
//===----------------------------------------------------------------------===//
class LSU_SSBO_X_Inst<string mnemonic, list<dag> pattern,
                      InstrItinClass itin = LSU_MEMW_AUXR_X>
    : LVXInst64<(outs), (ins simm37:$off, GPR:$rZ, GPR:$rT),
                !strconcat(mnemonic, " $off[$rZ] = $rT"),
                pattern, itin> {
  bits<37> off;
  bits<6>  rZ;
  bits<6>  rT;
  let Inst{58-32}  = off{36-10};
  let Inst{15-6}   = off{9-0};
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{62-61}  = 0b00;
  let Inst{31-26}  = 0b101100;
  let Inst{17-16}  = 0b01;
  let mayStore = 1;
}

def SB_SSBO_X              : LSU_SSBO_X_Inst<"sb", []> {
  let Inst{25-24}  = 0b00;
}
def SH_SSBO_X              : LSU_SSBO_X_Inst<"sh", []> {
  let Inst{25-24}  = 0b01;
}
def SW_SSBO_X              : LSU_SSBO_X_Inst<"sw", []> {
  let Inst{25-24}  = 0b10;
}
def SD_SSBO_X              : LSU_SSBO_X_Inst<"sd", []> {
  let Inst{25-24}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_SSBO.Y — LSU Store Scalar Base Offset Extended Extended
// triple (96 bits), syntax: %0 %1[%2] = %3
//===----------------------------------------------------------------------===//
class LSU_SSBO_Y_Inst<string mnemonic, list<dag> pattern,
                      InstrItinClass itin = LSU_MEMW_AUXR_Y>
    : LVXInst96<(outs), (ins wimm64:$off, GPR:$rZ, GPR:$rT),
                !strconcat(mnemonic, " $off[$rZ] = $rT"),
                pattern, itin> {
  bits<64> off;
  bits<6>  rZ;
  bits<6>  rT;
  let Inst{90-64}  = off{63-37};
  let Inst{58-32}  = off{36-10};
  let Inst{15-6}   = off{9-0};
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{94-93}  = 0b00;
  let Inst{63-61}  = 0b100;
  let Inst{31-26}  = 0b101100;
  let Inst{17-16}  = 0b01;
  let mayStore = 1;
}

def SB_SSBO_Y              : LSU_SSBO_Y_Inst<"sb", []> {
  let Inst{25-24}  = 0b00;
}
def SH_SSBO_Y              : LSU_SSBO_Y_Inst<"sh", []> {
  let Inst{25-24}  = 0b01;
}
def SW_SSBO_Y              : LSU_SSBO_Y_Inst<"sw", []> {
  let Inst{25-24}  = 0b10;
}
def SD_SSBO_Y              : LSU_SSBO_Y_Inst<"sd", []> {
  let Inst{25-24}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_SSBI — LSU Store Scalar Base + Index
// simple (32 bits), syntax: %0 %1[%2] = %3
//===----------------------------------------------------------------------===//
class LSU_SSBI_Inst<string mnemonic, list<dag> pattern,
                    InstrItinClass itin = LSU_MEMW_AUXR>
    : LVXInst32<(outs), (ins GPR:$rY, GPR:$rZ, GPR:$rT),
                !strconcat(mnemonic, " $rY[$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rY;
  bits<6>  rZ;
  bits<6>  rT;
  let Inst{11-6}   = rY;
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{30-26}  = 0b01100;
  let Inst{17-13}  = 0b11111;
  let mayStore = 1;
}

def SB_SSBI                : LSU_SSBI_Inst<"sb", []> {
  let Inst{25-24}  = 0b00;
}
def SH_SSBI                : LSU_SSBI_Inst<"sh", []> {
  let Inst{25-24}  = 0b01;
}
def SW_SSBI                : LSU_SSBI_Inst<"sw", []> {
  let Inst{25-24}  = 0b10;
}
def SD_SSBI                : LSU_SSBI_Inst<"sd", []> {
  let Inst{25-24}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_SQBO — LSU Store Quadruple Base Offset
// simple (32 bits), syntax: %0 %1[%2] = %3
//===----------------------------------------------------------------------===//
class LSU_SQBO_Inst<string mnemonic, list<dag> pattern,
                    InstrItinClass itin = LSU_MEMW_AUXR>
    : LVXInst32<(outs), (ins simm10:$off, GPR:$rZ, GPR128:$rU),
                !strconcat(mnemonic, " $off[$rZ] = $rU"),
                pattern, itin> {
  bits<10> off;
  bits<6>  rZ;
  bits<5>  rU;
  let Inst{15-6}   = off;
  let Inst{5-0}    = rZ;
  let Inst{23-19}  = rU;
  let Inst{30-24}  = 0b0110100;
  let Inst{18-16}  = 0b001;
  let mayStore = 1;
}

def SQ_SQBO                : LSU_SQBO_Inst<"sq", []>;

//===----------------------------------------------------------------------===//
// LSU_SQBO.X — LSU Store Quadruple Base Offset Extended
// double (64 bits), syntax: %0 %1[%2] = %3
//===----------------------------------------------------------------------===//
class LSU_SQBO_X_Inst<string mnemonic, list<dag> pattern,
                      InstrItinClass itin = LSU_MEMW_AUXR_X>
    : LVXInst64<(outs), (ins simm37:$off, GPR:$rZ, GPR128:$rU),
                !strconcat(mnemonic, " $off[$rZ] = $rU"),
                pattern, itin> {
  bits<37> off;
  bits<6>  rZ;
  bits<5>  rU;
  let Inst{58-32}  = off{36-10};
  let Inst{15-6}   = off{9-0};
  let Inst{5-0}    = rZ;
  let Inst{23-19}  = rU;
  let Inst{62-61}  = 0b00;
  let Inst{31-24}  = 0b10110100;
  let Inst{18-16}  = 0b001;
  let mayStore = 1;
}

def SQ_SQBO_X              : LSU_SQBO_X_Inst<"sq", []>;

//===----------------------------------------------------------------------===//
// LSU_SQBO.Y — LSU Store Quadruple Base Offset Extended Extended
// triple (96 bits), syntax: %0 %1[%2] = %3
//===----------------------------------------------------------------------===//
class LSU_SQBO_Y_Inst<string mnemonic, list<dag> pattern,
                      InstrItinClass itin = LSU_MEMW_AUXR_Y>
    : LVXInst96<(outs), (ins wimm64:$off, GPR:$rZ, GPR128:$rU),
                !strconcat(mnemonic, " $off[$rZ] = $rU"),
                pattern, itin> {
  bits<64> off;
  bits<6>  rZ;
  bits<5>  rU;
  let Inst{90-64}  = off{63-37};
  let Inst{58-32}  = off{36-10};
  let Inst{15-6}   = off{9-0};
  let Inst{5-0}    = rZ;
  let Inst{23-19}  = rU;
  let Inst{94-93}  = 0b00;
  let Inst{63-61}  = 0b100;
  let Inst{31-24}  = 0b10110100;
  let Inst{18-16}  = 0b001;
  let mayStore = 1;
}

def SQ_SQBO_Y              : LSU_SQBO_Y_Inst<"sq", []>;

//===----------------------------------------------------------------------===//
// LSU_SQBI — LSU Store Quadruple Base + Index
// simple (32 bits), syntax: %0 %1[%2] = %3
//===----------------------------------------------------------------------===//
class LSU_SQBI_Inst<string mnemonic, list<dag> pattern,
                    InstrItinClass itin = LSU_MEMW_AUXR>
    : LVXInst32<(outs), (ins GPR:$rY, GPR:$rZ, GPR128:$rU),
                !strconcat(mnemonic, " $rY[$rZ] = $rU"),
                pattern, itin> {
  bits<6>  rY;
  bits<6>  rZ;
  bits<5>  rU;
  let Inst{11-6}   = rY;
  let Inst{5-0}    = rZ;
  let Inst{23-19}  = rU;
  let Inst{30-24}  = 0b0110100;
  let Inst{18-13}  = 0b011111;
  let mayStore = 1;
}

def SQ_SQBI                : LSU_SQBI_Inst<"sq", []>;

//===----------------------------------------------------------------------===//
// LSU_SOBO — LSU Store Octuple Base Offset
// simple (32 bits), syntax: %0 %1[%2] = %3
//===----------------------------------------------------------------------===//
class LSU_SOBO_Inst<string mnemonic, list<dag> pattern,
                    InstrItinClass itin = LSU_MEMW_AUXR>
    : LVXInst32<(outs), (ins simm10:$off, GPR:$rZ, GPR256:$rV),
                !strconcat(mnemonic, " $off[$rZ] = $rV"),
                pattern, itin> {
  bits<10> off;
  bits<6>  rZ;
  bits<4>  rV;
  let Inst{15-6}   = off;
  let Inst{5-0}    = rZ;
  let Inst{23-20}  = rV;
  let Inst{30-24}  = 0b0110100;
  let Inst{19-16}  = 0b0101;
  let mayStore = 1;
}

def SO_SOBO                : LSU_SOBO_Inst<"so", []>;

//===----------------------------------------------------------------------===//
// LSU_SOBO.X — LSU Store Octuple Base Offset Extended
// double (64 bits), syntax: %0 %1[%2] = %3
//===----------------------------------------------------------------------===//
class LSU_SOBO_X_Inst<string mnemonic, list<dag> pattern,
                      InstrItinClass itin = LSU_MEMW_AUXR_X>
    : LVXInst64<(outs), (ins simm37:$off, GPR:$rZ, GPR256:$rV),
                !strconcat(mnemonic, " $off[$rZ] = $rV"),
                pattern, itin> {
  bits<37> off;
  bits<6>  rZ;
  bits<4>  rV;
  let Inst{58-32}  = off{36-10};
  let Inst{15-6}   = off{9-0};
  let Inst{5-0}    = rZ;
  let Inst{23-20}  = rV;
  let Inst{62-61}  = 0b00;
  let Inst{31-24}  = 0b10110100;
  let Inst{19-16}  = 0b0101;
  let mayStore = 1;
}

def SO_SOBO_X              : LSU_SOBO_X_Inst<"so", []>;

//===----------------------------------------------------------------------===//
// LSU_SOBO.Y — LSU Store Octuple Base Offset Extended Extended
// triple (96 bits), syntax: %0 %1[%2] = %3
//===----------------------------------------------------------------------===//
class LSU_SOBO_Y_Inst<string mnemonic, list<dag> pattern,
                      InstrItinClass itin = LSU_MEMW_AUXR_Y>
    : LVXInst96<(outs), (ins wimm64:$off, GPR:$rZ, GPR256:$rV),
                !strconcat(mnemonic, " $off[$rZ] = $rV"),
                pattern, itin> {
  bits<64> off;
  bits<6>  rZ;
  bits<4>  rV;
  let Inst{90-64}  = off{63-37};
  let Inst{58-32}  = off{36-10};
  let Inst{15-6}   = off{9-0};
  let Inst{5-0}    = rZ;
  let Inst{23-20}  = rV;
  let Inst{94-93}  = 0b00;
  let Inst{63-61}  = 0b100;
  let Inst{31-24}  = 0b10110100;
  let Inst{19-16}  = 0b0101;
  let mayStore = 1;
}

def SO_SOBO_Y              : LSU_SOBO_Y_Inst<"so", []>;

//===----------------------------------------------------------------------===//
// LSU_SOBI — LSU Store Octuple Base + Index
// simple (32 bits), syntax: %0 %1[%2] = %3
//===----------------------------------------------------------------------===//
class LSU_SOBI_Inst<string mnemonic, list<dag> pattern,
                    InstrItinClass itin = LSU_MEMW_AUXR>
    : LVXInst32<(outs), (ins GPR:$rY, GPR:$rZ, GPR256:$rV),
                !strconcat(mnemonic, " $rY[$rZ] = $rV"),
                pattern, itin> {
  bits<6>  rY;
  bits<6>  rZ;
  bits<4>  rV;
  let Inst{11-6}   = rY;
  let Inst{5-0}    = rZ;
  let Inst{23-20}  = rV;
  let Inst{30-24}  = 0b0110100;
  let Inst{19-13}  = 0b0111111;
  let mayStore = 1;
}

def SO_SOBI                : LSU_SOBI_Inst<"so", []>;

//===----------------------------------------------------------------------===//
// LSU_ACSWAPSB — LSU Atomic Compare and Swap Scalar Base
// simple (32 bits), syntax: %0%5%4 %1, [%2] = %3
//===----------------------------------------------------------------------===//
class LSU_ACSWAPSB_Inst<string mnemonic, list<dag> pattern,
                        InstrItinClass itin = LSU2_MEMW_AUXR_AUXW>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, GPR128:$rO, coherency:$coherency, boolcas:$boolcas),
                !strconcat(mnemonic, "${boolcas}${coherency} $rW, [$rZ] = $rO"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<5>  rO;
  bits<2>  coherency;
  bits<1>  boolcas;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{11-7}   = rO;
  let Inst{25-24}  = coherency;
  let Inst{12}     = boolcas;
  let Inst{30-26}  = 0b01111;
  let Inst{17-15}  = 0b110;
  let Inst{6}      = 0b1;
}

def ACSWAPB_ACSWAPSB       : LSU_ACSWAPSB_Inst<"acswapb", []> {
  let Inst{14-13}  = 0b00;
}
def ACSWAPH_ACSWAPSB       : LSU_ACSWAPSB_Inst<"acswaph", []> {
  let Inst{14-13}  = 0b01;
}
def ACSWAPW_ACSWAPSB       : LSU_ACSWAPSB_Inst<"acswapw", []> {
  let Inst{14-13}  = 0b10;
}
def ACSWAPD_ACSWAPSB       : LSU_ACSWAPSB_Inst<"acswapd", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ACSWAPSB.O — LSU Atomic Compare and Swap Scalar Base Offset
// double (64 bits), syntax: %0%5%4 %1, %6[%2] = %3
//===----------------------------------------------------------------------===//
class LSU_ACSWAPSB_O_Inst<string mnemonic, list<dag> pattern,
                          InstrItinClass itin = LSU2_MEMW_AUXR_AUXW_X>
    : LVXInst64<(outs GPR:$rW), (ins GPR:$rZ, GPR128:$rO, coherency:$coherency, boolcas:$boolcas, simm27:$off),
                !strconcat(mnemonic, "${boolcas}${coherency} $rW, $off[$rZ] = $rO"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<5>  rO;
  bits<2>  coherency;
  bits<1>  boolcas;
  bits<27> off;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{11-7}   = rO;
  let Inst{25-24}  = coherency;
  let Inst{12}     = boolcas;
  let Inst{58-32}  = off;
  let Inst{62-61}  = 0b00;
  let Inst{31-26}  = 0b101111;
  let Inst{17-15}  = 0b110;
  let Inst{6}      = 0b1;
}

def ACSWAPB_ACSWAPSB_O     : LSU_ACSWAPSB_O_Inst<"acswapb", []> {
  let Inst{14-13}  = 0b00;
}
def ACSWAPH_ACSWAPSB_O     : LSU_ACSWAPSB_O_Inst<"acswaph", []> {
  let Inst{14-13}  = 0b01;
}
def ACSWAPW_ACSWAPSB_O     : LSU_ACSWAPSB_O_Inst<"acswapw", []> {
  let Inst{14-13}  = 0b10;
}
def ACSWAPD_ACSWAPSB_O     : LSU_ACSWAPSB_O_Inst<"acswapd", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ACSWAPSB.D — LSU Atomic Compare and Swap Scalar Base Double Offset
// triple (96 bits), syntax: %0%5%4 %1, %6[%2] = %3
//===----------------------------------------------------------------------===//
class LSU_ACSWAPSB_D_Inst<string mnemonic, list<dag> pattern,
                          InstrItinClass itin = LSU2_MEMW_AUXR_AUXW_Y>
    : LVXInst96<(outs GPR:$rW), (ins GPR:$rZ, GPR128:$rO, coherency:$coherency, boolcas:$boolcas, simm54:$off),
                !strconcat(mnemonic, "${boolcas}${coherency} $rW, $off[$rZ] = $rO"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<5>  rO;
  bits<2>  coherency;
  bits<1>  boolcas;
  bits<54> off;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{11-7}   = rO;
  let Inst{25-24}  = coherency;
  let Inst{12}     = boolcas;
  let Inst{90-64}  = off{53-27};
  let Inst{58-32}  = off{26-0};
  let Inst{94-93}  = 0b00;
  let Inst{63-61}  = 0b100;
  let Inst{31-26}  = 0b101111;
  let Inst{17-15}  = 0b110;
  let Inst{6}      = 0b1;
}

def ACSWAPB_ACSWAPSB_D     : LSU_ACSWAPSB_D_Inst<"acswapb", []> {
  let Inst{14-13}  = 0b00;
}
def ACSWAPH_ACSWAPSB_D     : LSU_ACSWAPSB_D_Inst<"acswaph", []> {
  let Inst{14-13}  = 0b01;
}
def ACSWAPW_ACSWAPSB_D     : LSU_ACSWAPSB_D_Inst<"acswapw", []> {
  let Inst{14-13}  = 0b10;
}
def ACSWAPD_ACSWAPSB_D     : LSU_ACSWAPSB_D_Inst<"acswapd", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ACSWAPQB — LSU Atomic Compare and Swap Quadruple Base
// simple (32 bits), syntax: %0%5%4 %1, [%2] = %3
//===----------------------------------------------------------------------===//
class LSU_ACSWAPQB_Inst<string mnemonic, list<dag> pattern,
                        InstrItinClass itin = LSU2_MEMW_AUXR_AUXW>
    : LVXInst32<(outs GPR128:$rM), (ins GPR:$rZ, GPR256:$rQ, coherency:$coherency, boolcas:$boolcas),
                !strconcat(mnemonic, "${boolcas}${coherency} $rM, [$rZ] = $rQ"),
                pattern, itin> {
  bits<5>  rM;
  bits<6>  rZ;
  bits<4>  rQ;
  bits<2>  coherency;
  bits<1>  boolcas;
  let Inst{23-19}  = rM;
  let Inst{5-0}    = rZ;
  let Inst{11-8}   = rQ;
  let Inst{25-24}  = coherency;
  let Inst{12}     = boolcas;
  let Inst{30-26}  = 0b01111;
  let Inst{18-13}  = 0b011100;
  let Inst{6}      = 0b1;
}

def ACSWAPQ_ACSWAPQB       : LSU_ACSWAPQB_Inst<"acswapq", []>;

//===----------------------------------------------------------------------===//
// LSU_ACSWAPQB.O — LSU Atomic Compare and Swap Quadruple Base Offset
// double (64 bits), syntax: %0%5%4 %1, %6[%2] = %3
//===----------------------------------------------------------------------===//
class LSU_ACSWAPQB_O_Inst<string mnemonic, list<dag> pattern,
                          InstrItinClass itin = LSU2_MEMW_AUXR_AUXW_X>
    : LVXInst64<(outs GPR128:$rM), (ins GPR:$rZ, GPR256:$rQ, coherency:$coherency, boolcas:$boolcas, simm27:$off),
                !strconcat(mnemonic, "${boolcas}${coherency} $rM, $off[$rZ] = $rQ"),
                pattern, itin> {
  bits<5>  rM;
  bits<6>  rZ;
  bits<4>  rQ;
  bits<2>  coherency;
  bits<1>  boolcas;
  bits<27> off;
  let Inst{23-19}  = rM;
  let Inst{5-0}    = rZ;
  let Inst{11-8}   = rQ;
  let Inst{25-24}  = coherency;
  let Inst{12}     = boolcas;
  let Inst{58-32}  = off;
  let Inst{62-61}  = 0b00;
  let Inst{31-26}  = 0b101111;
  let Inst{18-13}  = 0b011100;
  let Inst{6}      = 0b1;
}

def ACSWAPQ_ACSWAPQB_O     : LSU_ACSWAPQB_O_Inst<"acswapq", []>;

//===----------------------------------------------------------------------===//
// LSU_ACSWAPQB.D — LSU Atomic Compare and Swap Quadruple Base Double Offset
// triple (96 bits), syntax: %0%5%4 %1, %6[%2] = %3
//===----------------------------------------------------------------------===//
class LSU_ACSWAPQB_D_Inst<string mnemonic, list<dag> pattern,
                          InstrItinClass itin = LSU2_MEMW_AUXR_AUXW_Y>
    : LVXInst96<(outs GPR128:$rM), (ins GPR:$rZ, GPR256:$rQ, coherency:$coherency, boolcas:$boolcas, simm54:$off),
                !strconcat(mnemonic, "${boolcas}${coherency} $rM, $off[$rZ] = $rQ"),
                pattern, itin> {
  bits<5>  rM;
  bits<6>  rZ;
  bits<4>  rQ;
  bits<2>  coherency;
  bits<1>  boolcas;
  bits<54> off;
  let Inst{23-19}  = rM;
  let Inst{5-0}    = rZ;
  let Inst{11-8}   = rQ;
  let Inst{25-24}  = coherency;
  let Inst{12}     = boolcas;
  let Inst{90-64}  = off{53-27};
  let Inst{58-32}  = off{26-0};
  let Inst{94-93}  = 0b00;
  let Inst{63-61}  = 0b100;
  let Inst{31-26}  = 0b101111;
  let Inst{18-13}  = 0b011100;
  let Inst{6}      = 0b1;
}

def ACSWAPQ_ACSWAPQB_D     : LSU_ACSWAPQB_D_Inst<"acswapq", []>;

//===----------------------------------------------------------------------===//
// LSU_ALSB — LSU Atomic Load Scalar Base
// simple (32 bits), syntax: %0%3 %1 = [%2]
//===----------------------------------------------------------------------===//
class LSU_ALSB_Inst<string mnemonic, list<dag> pattern,
                    InstrItinClass itin = LSU_MEMW_AUXW>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, coherency:$coherency),
                !strconcat(mnemonic, "${coherency} $rW = [$rZ]"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<2>  coherency;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{25-24}  = coherency;
  let Inst{30-26}  = 0b01111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b000000;
  let mayLoad  = 1;
}

def ALB_ALSB               : LSU_ALSB_Inst<"alb", []> {
  let Inst{14-13}  = 0b00;
}
def ALH_ALSB               : LSU_ALSB_Inst<"alh", []> {
  let Inst{14-13}  = 0b01;
}
def ALW_ALSB               : LSU_ALSB_Inst<"alw", []> {
  let Inst{14-13}  = 0b10;
}
def ALD_ALSB               : LSU_ALSB_Inst<"ald", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ALSB.O — LSU Atomic Load Scalar Base Offset
// double (64 bits), syntax: %0%3 %1 = %4[%2]
//===----------------------------------------------------------------------===//
class LSU_ALSB_O_Inst<string mnemonic, list<dag> pattern,
                      InstrItinClass itin = LSU_MEMW_AUXW_X>
    : LVXInst64<(outs GPR:$rW), (ins GPR:$rZ, coherency:$coherency, simm27:$off),
                !strconcat(mnemonic, "${coherency} $rW = $off[$rZ]"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<2>  coherency;
  bits<27> off;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{25-24}  = coherency;
  let Inst{58-32}  = off;
  let Inst{62-61}  = 0b00;
  let Inst{31-26}  = 0b101111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b000000;
  let mayLoad  = 1;
}

def ALB_ALSB_O             : LSU_ALSB_O_Inst<"alb", []> {
  let Inst{14-13}  = 0b00;
}
def ALH_ALSB_O             : LSU_ALSB_O_Inst<"alh", []> {
  let Inst{14-13}  = 0b01;
}
def ALW_ALSB_O             : LSU_ALSB_O_Inst<"alw", []> {
  let Inst{14-13}  = 0b10;
}
def ALD_ALSB_O             : LSU_ALSB_O_Inst<"ald", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ALSB.D — LSU Atomic Load Scalar Base Double Offset
// triple (96 bits), syntax: %0%3 %1 = %4[%2]
//===----------------------------------------------------------------------===//
class LSU_ALSB_D_Inst<string mnemonic, list<dag> pattern,
                      InstrItinClass itin = LSU_MEMW_AUXW_Y>
    : LVXInst96<(outs GPR:$rW), (ins GPR:$rZ, coherency:$coherency, simm54:$off),
                !strconcat(mnemonic, "${coherency} $rW = $off[$rZ]"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<2>  coherency;
  bits<54> off;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{25-24}  = coherency;
  let Inst{90-64}  = off{53-27};
  let Inst{58-32}  = off{26-0};
  let Inst{94-93}  = 0b00;
  let Inst{63-61}  = 0b100;
  let Inst{31-26}  = 0b101111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b000000;
  let mayLoad  = 1;
}

def ALB_ALSB_D             : LSU_ALSB_D_Inst<"alb", []> {
  let Inst{14-13}  = 0b00;
}
def ALH_ALSB_D             : LSU_ALSB_D_Inst<"alh", []> {
  let Inst{14-13}  = 0b01;
}
def ALW_ALSB_D             : LSU_ALSB_D_Inst<"alw", []> {
  let Inst{14-13}  = 0b10;
}
def ALD_ALSB_D             : LSU_ALSB_D_Inst<"ald", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ALCLRSB — LSU Atomic Load and Clear Scalar Base
// simple (32 bits), syntax: %0%3 %1 = [%2]
//===----------------------------------------------------------------------===//
class LSU_ALCLRSB_Inst<string mnemonic, list<dag> pattern,
                       InstrItinClass itin = LSU2_MEMW_AUXW>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, coherency:$coherency),
                !strconcat(mnemonic, "${coherency} $rW = [$rZ]"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<2>  coherency;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{25-24}  = coherency;
  let Inst{30-26}  = 0b01111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b000010;
}

def ALCLRB_ALCLRSB         : LSU_ALCLRSB_Inst<"alclrb", []> {
  let Inst{14-13}  = 0b00;
}
def ALCLRH_ALCLRSB         : LSU_ALCLRSB_Inst<"alclrh", []> {
  let Inst{14-13}  = 0b01;
}
def ALCLRW_ALCLRSB         : LSU_ALCLRSB_Inst<"alclrw", []> {
  let Inst{14-13}  = 0b10;
}
def ALCLRD_ALCLRSB         : LSU_ALCLRSB_Inst<"alclrd", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ALCLRSB.O — LSU Atomic Load and Clear Scalar Base Offset
// double (64 bits), syntax: %0%3 %1 = %4[%2]
//===----------------------------------------------------------------------===//
class LSU_ALCLRSB_O_Inst<string mnemonic, list<dag> pattern,
                         InstrItinClass itin = LSU2_MEMW_AUXW_X>
    : LVXInst64<(outs GPR:$rW), (ins GPR:$rZ, coherency:$coherency, simm27:$off),
                !strconcat(mnemonic, "${coherency} $rW = $off[$rZ]"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<2>  coherency;
  bits<27> off;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{25-24}  = coherency;
  let Inst{58-32}  = off;
  let Inst{62-61}  = 0b00;
  let Inst{31-26}  = 0b101111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b000010;
}

def ALCLRB_ALCLRSB_O       : LSU_ALCLRSB_O_Inst<"alclrb", []> {
  let Inst{14-13}  = 0b00;
}
def ALCLRH_ALCLRSB_O       : LSU_ALCLRSB_O_Inst<"alclrh", []> {
  let Inst{14-13}  = 0b01;
}
def ALCLRW_ALCLRSB_O       : LSU_ALCLRSB_O_Inst<"alclrw", []> {
  let Inst{14-13}  = 0b10;
}
def ALCLRD_ALCLRSB_O       : LSU_ALCLRSB_O_Inst<"alclrd", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ALCLRSB.D — LSU Atomic Load and Clear Scalar Base Double Offset
// triple (96 bits), syntax: %0%3 %1 = %4[%2]
//===----------------------------------------------------------------------===//
class LSU_ALCLRSB_D_Inst<string mnemonic, list<dag> pattern,
                         InstrItinClass itin = LSU2_MEMW_AUXW_Y>
    : LVXInst96<(outs GPR:$rW), (ins GPR:$rZ, coherency:$coherency, simm54:$off),
                !strconcat(mnemonic, "${coherency} $rW = $off[$rZ]"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<2>  coherency;
  bits<54> off;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{25-24}  = coherency;
  let Inst{90-64}  = off{53-27};
  let Inst{58-32}  = off{26-0};
  let Inst{94-93}  = 0b00;
  let Inst{63-61}  = 0b100;
  let Inst{31-26}  = 0b101111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b000010;
}

def ALCLRB_ALCLRSB_D       : LSU_ALCLRSB_D_Inst<"alclrb", []> {
  let Inst{14-13}  = 0b00;
}
def ALCLRH_ALCLRSB_D       : LSU_ALCLRSB_D_Inst<"alclrh", []> {
  let Inst{14-13}  = 0b01;
}
def ALCLRW_ALCLRSB_D       : LSU_ALCLRSB_D_Inst<"alclrw", []> {
  let Inst{14-13}  = 0b10;
}
def ALCLRD_ALCLRSB_D       : LSU_ALCLRSB_D_Inst<"alclrd", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ASWAPSB — LSU Atomic Swap Scalar Base
// simple (32 bits), syntax: %0%3 [%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ASWAPSB_Inst<string mnemonic, list<dag> pattern,
                       InstrItinClass itin = LSU2_MEMW_AUXR_AUXW>
    : LVXInst32<(outs GPR:$rT), (ins GPR:$rZ, GPR:$rTsrc, coherency:$coherency),
                !strconcat(mnemonic, "${coherency} [$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  let Constraints = "$rTsrc = $rT";
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{30-26}  = 0b01111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b000100;
}

def ASWAPB_ASWAPSB         : LSU_ASWAPSB_Inst<"aswapb", []> {
  let Inst{14-13}  = 0b00;
}
def ASWAPH_ASWAPSB         : LSU_ASWAPSB_Inst<"aswaph", []> {
  let Inst{14-13}  = 0b01;
}
def ASWAPW_ASWAPSB         : LSU_ASWAPSB_Inst<"aswapw", []> {
  let Inst{14-13}  = 0b10;
}
def ASWAPD_ASWAPSB         : LSU_ASWAPSB_Inst<"aswapd", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ASWAPSB.O — LSU Atomic Swap Scalar Base Offset
// double (64 bits), syntax: %0%3 %4[%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ASWAPSB_O_Inst<string mnemonic, list<dag> pattern,
                         InstrItinClass itin = LSU2_MEMW_AUXR_AUXW_X>
    : LVXInst64<(outs GPR:$rT), (ins GPR:$rZ, GPR:$rTsrc, coherency:$coherency, simm27:$off),
                !strconcat(mnemonic, "${coherency} $off[$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  bits<27> off;
  let Constraints = "$rTsrc = $rT";
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{58-32}  = off;
  let Inst{62-61}  = 0b00;
  let Inst{31-26}  = 0b101111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b000100;
}

def ASWAPB_ASWAPSB_O       : LSU_ASWAPSB_O_Inst<"aswapb", []> {
  let Inst{14-13}  = 0b00;
}
def ASWAPH_ASWAPSB_O       : LSU_ASWAPSB_O_Inst<"aswaph", []> {
  let Inst{14-13}  = 0b01;
}
def ASWAPW_ASWAPSB_O       : LSU_ASWAPSB_O_Inst<"aswapw", []> {
  let Inst{14-13}  = 0b10;
}
def ASWAPD_ASWAPSB_O       : LSU_ASWAPSB_O_Inst<"aswapd", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ASWAPSB.D — LSU Atomic Swap Scalar Base Double Offset
// triple (96 bits), syntax: %0%3 %4[%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ASWAPSB_D_Inst<string mnemonic, list<dag> pattern,
                         InstrItinClass itin = LSU2_MEMW_AUXR_AUXW_Y>
    : LVXInst96<(outs GPR:$rT), (ins GPR:$rZ, GPR:$rTsrc, coherency:$coherency, simm54:$off),
                !strconcat(mnemonic, "${coherency} $off[$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  bits<54> off;
  let Constraints = "$rTsrc = $rT";
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{90-64}  = off{53-27};
  let Inst{58-32}  = off{26-0};
  let Inst{94-93}  = 0b00;
  let Inst{63-61}  = 0b100;
  let Inst{31-26}  = 0b101111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b000100;
}

def ASWAPB_ASWAPSB_D       : LSU_ASWAPSB_D_Inst<"aswapb", []> {
  let Inst{14-13}  = 0b00;
}
def ASWAPH_ASWAPSB_D       : LSU_ASWAPSB_D_Inst<"aswaph", []> {
  let Inst{14-13}  = 0b01;
}
def ASWAPW_ASWAPSB_D       : LSU_ASWAPSB_D_Inst<"aswapw", []> {
  let Inst{14-13}  = 0b10;
}
def ASWAPD_ASWAPSB_D       : LSU_ASWAPSB_D_Inst<"aswapd", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ASSB — LSU Atomic Store Scalar Base
// simple (32 bits), syntax: %0%3 [%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ASSB_Inst<string mnemonic, list<dag> pattern,
                    InstrItinClass itin = LSU_MEMW_AUXR>
    : LVXInst32<(outs), (ins GPR:$rZ, GPR:$rT, coherency:$coherency),
                !strconcat(mnemonic, "${coherency} [$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{30-26}  = 0b01111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b100000;
  let mayStore = 1;
}

def ASB_ASSB               : LSU_ASSB_Inst<"asb", []> {
  let Inst{14-13}  = 0b00;
}
def ASH_ASSB               : LSU_ASSB_Inst<"ash", []> {
  let Inst{14-13}  = 0b01;
}
def ASW_ASSB               : LSU_ASSB_Inst<"asw", []> {
  let Inst{14-13}  = 0b10;
}
def ASD_ASSB               : LSU_ASSB_Inst<"asd", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ASSB.O — LSU Atomic Store Scalar Base Offset
// double (64 bits), syntax: %0%3 %4[%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ASSB_O_Inst<string mnemonic, list<dag> pattern,
                      InstrItinClass itin = LSU_MEMW_AUXR_X>
    : LVXInst64<(outs), (ins GPR:$rZ, GPR:$rT, coherency:$coherency, simm27:$off),
                !strconcat(mnemonic, "${coherency} $off[$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  bits<27> off;
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{58-32}  = off;
  let Inst{62-61}  = 0b00;
  let Inst{31-26}  = 0b101111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b100000;
  let mayStore = 1;
}

def ASB_ASSB_O             : LSU_ASSB_O_Inst<"asb", []> {
  let Inst{14-13}  = 0b00;
}
def ASH_ASSB_O             : LSU_ASSB_O_Inst<"ash", []> {
  let Inst{14-13}  = 0b01;
}
def ASW_ASSB_O             : LSU_ASSB_O_Inst<"asw", []> {
  let Inst{14-13}  = 0b10;
}
def ASD_ASSB_O             : LSU_ASSB_O_Inst<"asd", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ASSB.D — LSU Atomic Store Scalar Base Double Offset
// triple (96 bits), syntax: %0%3 %4[%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ASSB_D_Inst<string mnemonic, list<dag> pattern,
                      InstrItinClass itin = LSU_MEMW_AUXR_Y>
    : LVXInst96<(outs), (ins GPR:$rZ, GPR:$rT, coherency:$coherency, simm54:$off),
                !strconcat(mnemonic, "${coherency} $off[$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  bits<54> off;
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{90-64}  = off{53-27};
  let Inst{58-32}  = off{26-0};
  let Inst{94-93}  = 0b00;
  let Inst{63-61}  = 0b100;
  let Inst{31-26}  = 0b101111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b100000;
  let mayStore = 1;
}

def ASB_ASSB_D             : LSU_ASSB_D_Inst<"asb", []> {
  let Inst{14-13}  = 0b00;
}
def ASH_ASSB_D             : LSU_ASSB_D_Inst<"ash", []> {
  let Inst{14-13}  = 0b01;
}
def ASW_ASSB_D             : LSU_ASSB_D_Inst<"asw", []> {
  let Inst{14-13}  = 0b10;
}
def ASD_ASSB_D             : LSU_ASSB_D_Inst<"asd", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ALADDSB — LSU Atomic Load and Add Scalar Base
// simple (32 bits), syntax: %0%3 [%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ALADDSB_Inst<string mnemonic, list<dag> pattern,
                       InstrItinClass itin = LSU2_MEMW_AUXR_AUXW>
    : LVXInst32<(outs GPR:$rT), (ins GPR:$rZ, GPR:$rTsrc, coherency:$coherency),
                !strconcat(mnemonic, "${coherency} [$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  let Constraints = "$rTsrc = $rT";
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{30-26}  = 0b01111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b001000;
}

def ALADDB_ALADDSB         : LSU_ALADDSB_Inst<"aladdb", []> {
  let Inst{14-13}  = 0b00;
}
def ALADDH_ALADDSB         : LSU_ALADDSB_Inst<"aladdh", []> {
  let Inst{14-13}  = 0b01;
}
def ALADDW_ALADDSB         : LSU_ALADDSB_Inst<"aladdw", []> {
  let Inst{14-13}  = 0b10;
}
def ALADDD_ALADDSB         : LSU_ALADDSB_Inst<"aladdd", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ALADDSB.O — LSU Atomic Load and Add Scalar Base Offset
// double (64 bits), syntax: %0%3 %4[%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ALADDSB_O_Inst<string mnemonic, list<dag> pattern,
                         InstrItinClass itin = LSU2_MEMW_AUXR_AUXW_X>
    : LVXInst64<(outs GPR:$rT), (ins GPR:$rZ, GPR:$rTsrc, coherency:$coherency, simm27:$off),
                !strconcat(mnemonic, "${coherency} $off[$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  bits<27> off;
  let Constraints = "$rTsrc = $rT";
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{58-32}  = off;
  let Inst{62-61}  = 0b00;
  let Inst{31-26}  = 0b101111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b001000;
}

def ALADDB_ALADDSB_O       : LSU_ALADDSB_O_Inst<"aladdb", []> {
  let Inst{14-13}  = 0b00;
}
def ALADDH_ALADDSB_O       : LSU_ALADDSB_O_Inst<"aladdh", []> {
  let Inst{14-13}  = 0b01;
}
def ALADDW_ALADDSB_O       : LSU_ALADDSB_O_Inst<"aladdw", []> {
  let Inst{14-13}  = 0b10;
}
def ALADDD_ALADDSB_O       : LSU_ALADDSB_O_Inst<"aladdd", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ALADDSB.D — LSU Atomic Load and Add Scalar Base Double Offset
// triple (96 bits), syntax: %0%3 %4[%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ALADDSB_D_Inst<string mnemonic, list<dag> pattern,
                         InstrItinClass itin = LSU2_MEMW_AUXR_AUXW_Y>
    : LVXInst96<(outs GPR:$rT), (ins GPR:$rZ, GPR:$rTsrc, coherency:$coherency, simm54:$off),
                !strconcat(mnemonic, "${coherency} $off[$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  bits<54> off;
  let Constraints = "$rTsrc = $rT";
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{90-64}  = off{53-27};
  let Inst{58-32}  = off{26-0};
  let Inst{94-93}  = 0b00;
  let Inst{63-61}  = 0b100;
  let Inst{31-26}  = 0b101111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b001000;
}

def ALADDB_ALADDSB_D       : LSU_ALADDSB_D_Inst<"aladdb", []> {
  let Inst{14-13}  = 0b00;
}
def ALADDH_ALADDSB_D       : LSU_ALADDSB_D_Inst<"aladdh", []> {
  let Inst{14-13}  = 0b01;
}
def ALADDW_ALADDSB_D       : LSU_ALADDSB_D_Inst<"aladdw", []> {
  let Inst{14-13}  = 0b10;
}
def ALADDD_ALADDSB_D       : LSU_ALADDSB_D_Inst<"aladdd", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ALANDSB — LSU Atomic Load and AND Scalar Base
// simple (32 bits), syntax: %0%3 [%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ALANDSB_Inst<string mnemonic, list<dag> pattern,
                       InstrItinClass itin = LSU2_MEMW_AUXR_AUXW>
    : LVXInst32<(outs GPR:$rT), (ins GPR:$rZ, GPR:$rTsrc, coherency:$coherency),
                !strconcat(mnemonic, "${coherency} [$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  let Constraints = "$rTsrc = $rT";
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{30-26}  = 0b01111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b001010;
}

def ALANDB_ALANDSB         : LSU_ALANDSB_Inst<"alandb", []> {
  let Inst{14-13}  = 0b00;
}
def ALANDH_ALANDSB         : LSU_ALANDSB_Inst<"alandh", []> {
  let Inst{14-13}  = 0b01;
}
def ALANDW_ALANDSB         : LSU_ALANDSB_Inst<"alandw", []> {
  let Inst{14-13}  = 0b10;
}
def ALANDD_ALANDSB         : LSU_ALANDSB_Inst<"alandd", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ALANDSB.O — LSU Atomic Load and AND Scalar Base Offset
// double (64 bits), syntax: %0%3 %4[%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ALANDSB_O_Inst<string mnemonic, list<dag> pattern,
                         InstrItinClass itin = LSU2_MEMW_AUXR_AUXW_X>
    : LVXInst64<(outs GPR:$rT), (ins GPR:$rZ, GPR:$rTsrc, coherency:$coherency, simm27:$off),
                !strconcat(mnemonic, "${coherency} $off[$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  bits<27> off;
  let Constraints = "$rTsrc = $rT";
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{58-32}  = off;
  let Inst{62-61}  = 0b00;
  let Inst{31-26}  = 0b101111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b001010;
}

def ALANDB_ALANDSB_O       : LSU_ALANDSB_O_Inst<"alandb", []> {
  let Inst{14-13}  = 0b00;
}
def ALANDH_ALANDSB_O       : LSU_ALANDSB_O_Inst<"alandh", []> {
  let Inst{14-13}  = 0b01;
}
def ALANDW_ALANDSB_O       : LSU_ALANDSB_O_Inst<"alandw", []> {
  let Inst{14-13}  = 0b10;
}
def ALANDD_ALANDSB_O       : LSU_ALANDSB_O_Inst<"alandd", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ALANDSB.D — LSU Atomic Load and AND Scalar Base Double Offset
// triple (96 bits), syntax: %0%3 %4[%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ALANDSB_D_Inst<string mnemonic, list<dag> pattern,
                         InstrItinClass itin = LSU2_MEMW_AUXR_AUXW_Y>
    : LVXInst96<(outs GPR:$rT), (ins GPR:$rZ, GPR:$rTsrc, coherency:$coherency, simm54:$off),
                !strconcat(mnemonic, "${coherency} $off[$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  bits<54> off;
  let Constraints = "$rTsrc = $rT";
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{90-64}  = off{53-27};
  let Inst{58-32}  = off{26-0};
  let Inst{94-93}  = 0b00;
  let Inst{63-61}  = 0b100;
  let Inst{31-26}  = 0b101111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b001010;
}

def ALANDB_ALANDSB_D       : LSU_ALANDSB_D_Inst<"alandb", []> {
  let Inst{14-13}  = 0b00;
}
def ALANDH_ALANDSB_D       : LSU_ALANDSB_D_Inst<"alandh", []> {
  let Inst{14-13}  = 0b01;
}
def ALANDW_ALANDSB_D       : LSU_ALANDSB_D_Inst<"alandw", []> {
  let Inst{14-13}  = 0b10;
}
def ALANDD_ALANDSB_D       : LSU_ALANDSB_D_Inst<"alandd", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ALIORSB — LSU Atomic Load and IOR Scalar Base
// simple (32 bits), syntax: %0%3 [%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ALIORSB_Inst<string mnemonic, list<dag> pattern,
                       InstrItinClass itin = LSU2_MEMW_AUXR_AUXW>
    : LVXInst32<(outs GPR:$rT), (ins GPR:$rZ, GPR:$rTsrc, coherency:$coherency),
                !strconcat(mnemonic, "${coherency} [$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  let Constraints = "$rTsrc = $rT";
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{30-26}  = 0b01111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b001100;
}

def ALIORB_ALIORSB         : LSU_ALIORSB_Inst<"aliorb", []> {
  let Inst{14-13}  = 0b00;
}
def ALIORH_ALIORSB         : LSU_ALIORSB_Inst<"aliorh", []> {
  let Inst{14-13}  = 0b01;
}
def ALIORW_ALIORSB         : LSU_ALIORSB_Inst<"aliorw", []> {
  let Inst{14-13}  = 0b10;
}
def ALIORD_ALIORSB         : LSU_ALIORSB_Inst<"aliord", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ALIORSB.O — LSU Atomic Load and IOR Scalar Base Offset
// double (64 bits), syntax: %0%3 %4[%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ALIORSB_O_Inst<string mnemonic, list<dag> pattern,
                         InstrItinClass itin = LSU2_MEMW_AUXR_AUXW_X>
    : LVXInst64<(outs GPR:$rT), (ins GPR:$rZ, GPR:$rTsrc, coherency:$coherency, simm27:$off),
                !strconcat(mnemonic, "${coherency} $off[$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  bits<27> off;
  let Constraints = "$rTsrc = $rT";
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{58-32}  = off;
  let Inst{62-61}  = 0b00;
  let Inst{31-26}  = 0b101111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b001100;
}

def ALIORB_ALIORSB_O       : LSU_ALIORSB_O_Inst<"aliorb", []> {
  let Inst{14-13}  = 0b00;
}
def ALIORH_ALIORSB_O       : LSU_ALIORSB_O_Inst<"aliorh", []> {
  let Inst{14-13}  = 0b01;
}
def ALIORW_ALIORSB_O       : LSU_ALIORSB_O_Inst<"aliorw", []> {
  let Inst{14-13}  = 0b10;
}
def ALIORD_ALIORSB_O       : LSU_ALIORSB_O_Inst<"aliord", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ALIORSB.D — LSU Atomic Load and IOR Scalar Base Double Offset
// triple (96 bits), syntax: %0%3 %4[%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ALIORSB_D_Inst<string mnemonic, list<dag> pattern,
                         InstrItinClass itin = LSU2_MEMW_AUXR_AUXW_Y>
    : LVXInst96<(outs GPR:$rT), (ins GPR:$rZ, GPR:$rTsrc, coherency:$coherency, simm54:$off),
                !strconcat(mnemonic, "${coherency} $off[$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  bits<54> off;
  let Constraints = "$rTsrc = $rT";
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{90-64}  = off{53-27};
  let Inst{58-32}  = off{26-0};
  let Inst{94-93}  = 0b00;
  let Inst{63-61}  = 0b100;
  let Inst{31-26}  = 0b101111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b001100;
}

def ALIORB_ALIORSB_D       : LSU_ALIORSB_D_Inst<"aliorb", []> {
  let Inst{14-13}  = 0b00;
}
def ALIORH_ALIORSB_D       : LSU_ALIORSB_D_Inst<"aliorh", []> {
  let Inst{14-13}  = 0b01;
}
def ALIORW_ALIORSB_D       : LSU_ALIORSB_D_Inst<"aliorw", []> {
  let Inst{14-13}  = 0b10;
}
def ALIORD_ALIORSB_D       : LSU_ALIORSB_D_Inst<"aliord", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ALEORSB — LSU Atomic Load and EOR Scalar Base
// simple (32 bits), syntax: %0%3 [%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ALEORSB_Inst<string mnemonic, list<dag> pattern,
                       InstrItinClass itin = LSU2_MEMW_AUXR_AUXW>
    : LVXInst32<(outs GPR:$rT), (ins GPR:$rZ, GPR:$rTsrc, coherency:$coherency),
                !strconcat(mnemonic, "${coherency} [$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  let Constraints = "$rTsrc = $rT";
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{30-26}  = 0b01111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b001110;
}

def ALEORB_ALEORSB         : LSU_ALEORSB_Inst<"aleorb", []> {
  let Inst{14-13}  = 0b00;
}
def ALEORH_ALEORSB         : LSU_ALEORSB_Inst<"aleorh", []> {
  let Inst{14-13}  = 0b01;
}
def ALEORW_ALEORSB         : LSU_ALEORSB_Inst<"aleorw", []> {
  let Inst{14-13}  = 0b10;
}
def ALEORD_ALEORSB         : LSU_ALEORSB_Inst<"aleord", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ALEORSB.O — LSU Atomic Load and EOR Scalar Base Offset
// double (64 bits), syntax: %0%3 %4[%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ALEORSB_O_Inst<string mnemonic, list<dag> pattern,
                         InstrItinClass itin = LSU2_MEMW_AUXR_AUXW_X>
    : LVXInst64<(outs GPR:$rT), (ins GPR:$rZ, GPR:$rTsrc, coherency:$coherency, simm27:$off),
                !strconcat(mnemonic, "${coherency} $off[$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  bits<27> off;
  let Constraints = "$rTsrc = $rT";
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{58-32}  = off;
  let Inst{62-61}  = 0b00;
  let Inst{31-26}  = 0b101111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b001110;
}

def ALEORB_ALEORSB_O       : LSU_ALEORSB_O_Inst<"aleorb", []> {
  let Inst{14-13}  = 0b00;
}
def ALEORH_ALEORSB_O       : LSU_ALEORSB_O_Inst<"aleorh", []> {
  let Inst{14-13}  = 0b01;
}
def ALEORW_ALEORSB_O       : LSU_ALEORSB_O_Inst<"aleorw", []> {
  let Inst{14-13}  = 0b10;
}
def ALEORD_ALEORSB_O       : LSU_ALEORSB_O_Inst<"aleord", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ALEORSB.D — LSU Atomic Load and EOR Scalar Base Double Offset
// triple (96 bits), syntax: %0%3 %4[%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ALEORSB_D_Inst<string mnemonic, list<dag> pattern,
                         InstrItinClass itin = LSU2_MEMW_AUXR_AUXW_Y>
    : LVXInst96<(outs GPR:$rT), (ins GPR:$rZ, GPR:$rTsrc, coherency:$coherency, simm54:$off),
                !strconcat(mnemonic, "${coherency} $off[$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  bits<54> off;
  let Constraints = "$rTsrc = $rT";
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{90-64}  = off{53-27};
  let Inst{58-32}  = off{26-0};
  let Inst{94-93}  = 0b00;
  let Inst{63-61}  = 0b100;
  let Inst{31-26}  = 0b101111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b001110;
}

def ALEORB_ALEORSB_D       : LSU_ALEORSB_D_Inst<"aleorb", []> {
  let Inst{14-13}  = 0b00;
}
def ALEORH_ALEORSB_D       : LSU_ALEORSB_D_Inst<"aleorh", []> {
  let Inst{14-13}  = 0b01;
}
def ALEORW_ALEORSB_D       : LSU_ALEORSB_D_Inst<"aleorw", []> {
  let Inst{14-13}  = 0b10;
}
def ALEORD_ALEORSB_D       : LSU_ALEORSB_D_Inst<"aleord", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ALMINSB — LSU Atomic Load and MIN Scalar Base
// simple (32 bits), syntax: %0%3 [%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ALMINSB_Inst<string mnemonic, list<dag> pattern,
                       InstrItinClass itin = LSU2_MEMW_AUXR_AUXW>
    : LVXInst32<(outs GPR:$rT), (ins GPR:$rZ, GPR:$rTsrc, coherency:$coherency),
                !strconcat(mnemonic, "${coherency} [$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  let Constraints = "$rTsrc = $rT";
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{30-26}  = 0b01111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b010000;
}

def ALMINB_ALMINSB         : LSU_ALMINSB_Inst<"alminb", []> {
  let Inst{14-13}  = 0b00;
}
def ALMINH_ALMINSB         : LSU_ALMINSB_Inst<"alminh", []> {
  let Inst{14-13}  = 0b01;
}
def ALMINW_ALMINSB         : LSU_ALMINSB_Inst<"alminw", []> {
  let Inst{14-13}  = 0b10;
}
def ALMIND_ALMINSB         : LSU_ALMINSB_Inst<"almind", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ALMINSB.O — LSU Atomic Load and MIN Scalar Base Offset
// double (64 bits), syntax: %0%3 %4[%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ALMINSB_O_Inst<string mnemonic, list<dag> pattern,
                         InstrItinClass itin = LSU2_MEMW_AUXR_AUXW_X>
    : LVXInst64<(outs GPR:$rT), (ins GPR:$rZ, GPR:$rTsrc, coherency:$coherency, simm27:$off),
                !strconcat(mnemonic, "${coherency} $off[$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  bits<27> off;
  let Constraints = "$rTsrc = $rT";
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{58-32}  = off;
  let Inst{62-61}  = 0b00;
  let Inst{31-26}  = 0b101111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b010000;
}

def ALMINB_ALMINSB_O       : LSU_ALMINSB_O_Inst<"alminb", []> {
  let Inst{14-13}  = 0b00;
}
def ALMINH_ALMINSB_O       : LSU_ALMINSB_O_Inst<"alminh", []> {
  let Inst{14-13}  = 0b01;
}
def ALMINW_ALMINSB_O       : LSU_ALMINSB_O_Inst<"alminw", []> {
  let Inst{14-13}  = 0b10;
}
def ALMIND_ALMINSB_O       : LSU_ALMINSB_O_Inst<"almind", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ALMINSB.D — LSU Atomic Load and MIN Scalar Base Double Offset
// triple (96 bits), syntax: %0%3 %4[%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ALMINSB_D_Inst<string mnemonic, list<dag> pattern,
                         InstrItinClass itin = LSU2_MEMW_AUXR_AUXW_Y>
    : LVXInst96<(outs GPR:$rT), (ins GPR:$rZ, GPR:$rTsrc, coherency:$coherency, simm54:$off),
                !strconcat(mnemonic, "${coherency} $off[$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  bits<54> off;
  let Constraints = "$rTsrc = $rT";
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{90-64}  = off{53-27};
  let Inst{58-32}  = off{26-0};
  let Inst{94-93}  = 0b00;
  let Inst{63-61}  = 0b100;
  let Inst{31-26}  = 0b101111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b010000;
}

def ALMINB_ALMINSB_D       : LSU_ALMINSB_D_Inst<"alminb", []> {
  let Inst{14-13}  = 0b00;
}
def ALMINH_ALMINSB_D       : LSU_ALMINSB_D_Inst<"alminh", []> {
  let Inst{14-13}  = 0b01;
}
def ALMINW_ALMINSB_D       : LSU_ALMINSB_D_Inst<"alminw", []> {
  let Inst{14-13}  = 0b10;
}
def ALMIND_ALMINSB_D       : LSU_ALMINSB_D_Inst<"almind", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ALMAXSB — LSU Atomic Load and MAX Scalar Base
// simple (32 bits), syntax: %0%3 [%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ALMAXSB_Inst<string mnemonic, list<dag> pattern,
                       InstrItinClass itin = LSU2_MEMW_AUXR_AUXW>
    : LVXInst32<(outs GPR:$rT), (ins GPR:$rZ, GPR:$rTsrc, coherency:$coherency),
                !strconcat(mnemonic, "${coherency} [$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  let Constraints = "$rTsrc = $rT";
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{30-26}  = 0b01111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b010010;
}

def ALMAXB_ALMAXSB         : LSU_ALMAXSB_Inst<"almaxb", []> {
  let Inst{14-13}  = 0b00;
}
def ALMAXH_ALMAXSB         : LSU_ALMAXSB_Inst<"almaxh", []> {
  let Inst{14-13}  = 0b01;
}
def ALMAXW_ALMAXSB         : LSU_ALMAXSB_Inst<"almaxw", []> {
  let Inst{14-13}  = 0b10;
}
def ALMAXD_ALMAXSB         : LSU_ALMAXSB_Inst<"almaxd", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ALMAXSB.O — LSU Atomic Load and MAX Scalar Base Offset
// double (64 bits), syntax: %0%3 %4[%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ALMAXSB_O_Inst<string mnemonic, list<dag> pattern,
                         InstrItinClass itin = LSU2_MEMW_AUXR_AUXW_X>
    : LVXInst64<(outs GPR:$rT), (ins GPR:$rZ, GPR:$rTsrc, coherency:$coherency, simm27:$off),
                !strconcat(mnemonic, "${coherency} $off[$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  bits<27> off;
  let Constraints = "$rTsrc = $rT";
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{58-32}  = off;
  let Inst{62-61}  = 0b00;
  let Inst{31-26}  = 0b101111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b010010;
}

def ALMAXB_ALMAXSB_O       : LSU_ALMAXSB_O_Inst<"almaxb", []> {
  let Inst{14-13}  = 0b00;
}
def ALMAXH_ALMAXSB_O       : LSU_ALMAXSB_O_Inst<"almaxh", []> {
  let Inst{14-13}  = 0b01;
}
def ALMAXW_ALMAXSB_O       : LSU_ALMAXSB_O_Inst<"almaxw", []> {
  let Inst{14-13}  = 0b10;
}
def ALMAXD_ALMAXSB_O       : LSU_ALMAXSB_O_Inst<"almaxd", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ALMAXSB.D — LSU Atomic Load and MAX Scalar Base Double Offset
// triple (96 bits), syntax: %0%3 %4[%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ALMAXSB_D_Inst<string mnemonic, list<dag> pattern,
                         InstrItinClass itin = LSU2_MEMW_AUXR_AUXW_Y>
    : LVXInst96<(outs GPR:$rT), (ins GPR:$rZ, GPR:$rTsrc, coherency:$coherency, simm54:$off),
                !strconcat(mnemonic, "${coherency} $off[$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  bits<54> off;
  let Constraints = "$rTsrc = $rT";
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{90-64}  = off{53-27};
  let Inst{58-32}  = off{26-0};
  let Inst{94-93}  = 0b00;
  let Inst{63-61}  = 0b100;
  let Inst{31-26}  = 0b101111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b010010;
}

def ALMAXB_ALMAXSB_D       : LSU_ALMAXSB_D_Inst<"almaxb", []> {
  let Inst{14-13}  = 0b00;
}
def ALMAXH_ALMAXSB_D       : LSU_ALMAXSB_D_Inst<"almaxh", []> {
  let Inst{14-13}  = 0b01;
}
def ALMAXW_ALMAXSB_D       : LSU_ALMAXSB_D_Inst<"almaxw", []> {
  let Inst{14-13}  = 0b10;
}
def ALMAXD_ALMAXSB_D       : LSU_ALMAXSB_D_Inst<"almaxd", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ALMINUSB — LSU Atomic Load and MIN Unsigned Scalar Base
// simple (32 bits), syntax: %0%3 [%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ALMINUSB_Inst<string mnemonic, list<dag> pattern,
                        InstrItinClass itin = LSU2_MEMW_AUXR_AUXW>
    : LVXInst32<(outs GPR:$rT), (ins GPR:$rZ, GPR:$rTsrc, coherency:$coherency),
                !strconcat(mnemonic, "${coherency} [$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  let Constraints = "$rTsrc = $rT";
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{30-26}  = 0b01111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b010100;
}

def ALMINUB_ALMINUSB       : LSU_ALMINUSB_Inst<"alminub", []> {
  let Inst{14-13}  = 0b00;
}
def ALMINUH_ALMINUSB       : LSU_ALMINUSB_Inst<"alminuh", []> {
  let Inst{14-13}  = 0b01;
}
def ALMINUW_ALMINUSB       : LSU_ALMINUSB_Inst<"alminuw", []> {
  let Inst{14-13}  = 0b10;
}
def ALMINUD_ALMINUSB       : LSU_ALMINUSB_Inst<"alminud", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ALMINUSB.O — LSU Atomic Load and MIN Unsigned Scalar Base Offset
// double (64 bits), syntax: %0%3 %4[%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ALMINUSB_O_Inst<string mnemonic, list<dag> pattern,
                          InstrItinClass itin = LSU2_MEMW_AUXR_AUXW_X>
    : LVXInst64<(outs GPR:$rT), (ins GPR:$rZ, GPR:$rTsrc, coherency:$coherency, simm27:$off),
                !strconcat(mnemonic, "${coherency} $off[$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  bits<27> off;
  let Constraints = "$rTsrc = $rT";
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{58-32}  = off;
  let Inst{62-61}  = 0b00;
  let Inst{31-26}  = 0b101111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b010100;
}

def ALMINUB_ALMINUSB_O     : LSU_ALMINUSB_O_Inst<"alminub", []> {
  let Inst{14-13}  = 0b00;
}
def ALMINUH_ALMINUSB_O     : LSU_ALMINUSB_O_Inst<"alminuh", []> {
  let Inst{14-13}  = 0b01;
}
def ALMINUW_ALMINUSB_O     : LSU_ALMINUSB_O_Inst<"alminuw", []> {
  let Inst{14-13}  = 0b10;
}
def ALMINUD_ALMINUSB_O     : LSU_ALMINUSB_O_Inst<"alminud", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ALMINUSB.D — LSU Atomic Load and MIN Unsigned Scalar Base Double Offset
// triple (96 bits), syntax: %0%3 %4[%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ALMINUSB_D_Inst<string mnemonic, list<dag> pattern,
                          InstrItinClass itin = LSU2_MEMW_AUXR_AUXW_Y>
    : LVXInst96<(outs GPR:$rT), (ins GPR:$rZ, GPR:$rTsrc, coherency:$coherency, simm54:$off),
                !strconcat(mnemonic, "${coherency} $off[$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  bits<54> off;
  let Constraints = "$rTsrc = $rT";
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{90-64}  = off{53-27};
  let Inst{58-32}  = off{26-0};
  let Inst{94-93}  = 0b00;
  let Inst{63-61}  = 0b100;
  let Inst{31-26}  = 0b101111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b010100;
}

def ALMINUB_ALMINUSB_D     : LSU_ALMINUSB_D_Inst<"alminub", []> {
  let Inst{14-13}  = 0b00;
}
def ALMINUH_ALMINUSB_D     : LSU_ALMINUSB_D_Inst<"alminuh", []> {
  let Inst{14-13}  = 0b01;
}
def ALMINUW_ALMINUSB_D     : LSU_ALMINUSB_D_Inst<"alminuw", []> {
  let Inst{14-13}  = 0b10;
}
def ALMINUD_ALMINUSB_D     : LSU_ALMINUSB_D_Inst<"alminud", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ALMAXUSB — LSU Atomic Load and MAX Unsigned Scalar Base
// simple (32 bits), syntax: %0%3 [%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ALMAXUSB_Inst<string mnemonic, list<dag> pattern,
                        InstrItinClass itin = LSU2_MEMW_AUXR_AUXW>
    : LVXInst32<(outs GPR:$rT), (ins GPR:$rZ, GPR:$rTsrc, coherency:$coherency),
                !strconcat(mnemonic, "${coherency} [$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  let Constraints = "$rTsrc = $rT";
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{30-26}  = 0b01111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b010110;
}

def ALMAXUB_ALMAXUSB       : LSU_ALMAXUSB_Inst<"almaxub", []> {
  let Inst{14-13}  = 0b00;
}
def ALMAXUH_ALMAXUSB       : LSU_ALMAXUSB_Inst<"almaxuh", []> {
  let Inst{14-13}  = 0b01;
}
def ALMAXUW_ALMAXUSB       : LSU_ALMAXUSB_Inst<"almaxuw", []> {
  let Inst{14-13}  = 0b10;
}
def ALMAXUD_ALMAXUSB       : LSU_ALMAXUSB_Inst<"almaxud", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ALMAXUSB.O — LSU Atomic Load and MAX Unsigned Scalar Base Offset
// double (64 bits), syntax: %0%3 %4[%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ALMAXUSB_O_Inst<string mnemonic, list<dag> pattern,
                          InstrItinClass itin = LSU2_MEMW_AUXR_AUXW_X>
    : LVXInst64<(outs GPR:$rT), (ins GPR:$rZ, GPR:$rTsrc, coherency:$coherency, simm27:$off),
                !strconcat(mnemonic, "${coherency} $off[$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  bits<27> off;
  let Constraints = "$rTsrc = $rT";
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{58-32}  = off;
  let Inst{62-61}  = 0b00;
  let Inst{31-26}  = 0b101111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b010110;
}

def ALMAXUB_ALMAXUSB_O     : LSU_ALMAXUSB_O_Inst<"almaxub", []> {
  let Inst{14-13}  = 0b00;
}
def ALMAXUH_ALMAXUSB_O     : LSU_ALMAXUSB_O_Inst<"almaxuh", []> {
  let Inst{14-13}  = 0b01;
}
def ALMAXUW_ALMAXUSB_O     : LSU_ALMAXUSB_O_Inst<"almaxuw", []> {
  let Inst{14-13}  = 0b10;
}
def ALMAXUD_ALMAXUSB_O     : LSU_ALMAXUSB_O_Inst<"almaxud", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ALMAXUSB.D — LSU Atomic Load and MAX Unsigned Scalar Base Double Offset
// triple (96 bits), syntax: %0%3 %4[%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ALMAXUSB_D_Inst<string mnemonic, list<dag> pattern,
                          InstrItinClass itin = LSU2_MEMW_AUXR_AUXW_Y>
    : LVXInst96<(outs GPR:$rT), (ins GPR:$rZ, GPR:$rTsrc, coherency:$coherency, simm54:$off),
                !strconcat(mnemonic, "${coherency} $off[$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  bits<54> off;
  let Constraints = "$rTsrc = $rT";
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{90-64}  = off{53-27};
  let Inst{58-32}  = off{26-0};
  let Inst{94-93}  = 0b00;
  let Inst{63-61}  = 0b100;
  let Inst{31-26}  = 0b101111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b010110;
}

def ALMAXUB_ALMAXUSB_D     : LSU_ALMAXUSB_D_Inst<"almaxub", []> {
  let Inst{14-13}  = 0b00;
}
def ALMAXUH_ALMAXUSB_D     : LSU_ALMAXUSB_D_Inst<"almaxuh", []> {
  let Inst{14-13}  = 0b01;
}
def ALMAXUW_ALMAXUSB_D     : LSU_ALMAXUSB_D_Inst<"almaxuw", []> {
  let Inst{14-13}  = 0b10;
}
def ALMAXUD_ALMAXUSB_D     : LSU_ALMAXUSB_D_Inst<"almaxud", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ALDUSSB — LSU Atomic Load and Decrement Unsigned Saturating Scalar Base
// simple (32 bits), syntax: %0%3 [%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ALDUSSB_Inst<string mnemonic, list<dag> pattern,
                       InstrItinClass itin = LSU2_MEMW_AUXR_AUXW>
    : LVXInst32<(outs GPR:$rT), (ins GPR:$rZ, GPR:$rTsrc, coherency:$coherency),
                !strconcat(mnemonic, "${coherency} [$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  let Constraints = "$rTsrc = $rT";
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{30-26}  = 0b01111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b011100;
}

def ALDUSB_ALDUSSB         : LSU_ALDUSSB_Inst<"aldusb", []> {
  let Inst{14-13}  = 0b00;
}
def ALDUSH_ALDUSSB         : LSU_ALDUSSB_Inst<"aldush", []> {
  let Inst{14-13}  = 0b01;
}
def ALDUSW_ALDUSSB         : LSU_ALDUSSB_Inst<"aldusw", []> {
  let Inst{14-13}  = 0b10;
}
def ALDUSD_ALDUSSB         : LSU_ALDUSSB_Inst<"aldusd", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ALDUSSB.O — LSU Atomic Load and Decrement Unsigned Saturating Scalar Base Offset
// double (64 bits), syntax: %0%3 %4[%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ALDUSSB_O_Inst<string mnemonic, list<dag> pattern,
                         InstrItinClass itin = LSU2_MEMW_AUXR_AUXW_X>
    : LVXInst64<(outs GPR:$rT), (ins GPR:$rZ, GPR:$rTsrc, coherency:$coherency, simm27:$off),
                !strconcat(mnemonic, "${coherency} $off[$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  bits<27> off;
  let Constraints = "$rTsrc = $rT";
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{58-32}  = off;
  let Inst{62-61}  = 0b00;
  let Inst{31-26}  = 0b101111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b011100;
}

def ALDUSB_ALDUSSB_O       : LSU_ALDUSSB_O_Inst<"aldusb", []> {
  let Inst{14-13}  = 0b00;
}
def ALDUSH_ALDUSSB_O       : LSU_ALDUSSB_O_Inst<"aldush", []> {
  let Inst{14-13}  = 0b01;
}
def ALDUSW_ALDUSSB_O       : LSU_ALDUSSB_O_Inst<"aldusw", []> {
  let Inst{14-13}  = 0b10;
}
def ALDUSD_ALDUSSB_O       : LSU_ALDUSSB_O_Inst<"aldusd", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ALDUSSB.D — LSU Atomic Load and Decrement Unsigned Saturating Scalar Base Double Offset
// triple (96 bits), syntax: %0%3 %4[%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ALDUSSB_D_Inst<string mnemonic, list<dag> pattern,
                         InstrItinClass itin = LSU2_MEMW_AUXR_AUXW_Y>
    : LVXInst96<(outs GPR:$rT), (ins GPR:$rZ, GPR:$rTsrc, coherency:$coherency, simm54:$off),
                !strconcat(mnemonic, "${coherency} $off[$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  bits<54> off;
  let Constraints = "$rTsrc = $rT";
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{90-64}  = off{53-27};
  let Inst{58-32}  = off{26-0};
  let Inst{94-93}  = 0b00;
  let Inst{63-61}  = 0b100;
  let Inst{31-26}  = 0b101111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b011100;
}

def ALDUSB_ALDUSSB_D       : LSU_ALDUSSB_D_Inst<"aldusb", []> {
  let Inst{14-13}  = 0b00;
}
def ALDUSH_ALDUSSB_D       : LSU_ALDUSSB_D_Inst<"aldush", []> {
  let Inst{14-13}  = 0b01;
}
def ALDUSW_ALDUSSB_D       : LSU_ALDUSSB_D_Inst<"aldusw", []> {
  let Inst{14-13}  = 0b10;
}
def ALDUSD_ALDUSSB_D       : LSU_ALDUSSB_D_Inst<"aldusd", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ASADDSB — LSU Atomic Store and Add Scalar Base
// simple (32 bits), syntax: %0%3 [%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ASADDSB_Inst<string mnemonic, list<dag> pattern,
                       InstrItinClass itin = LSU2_MEMW_AUXR>
    : LVXInst32<(outs), (ins GPR:$rZ, GPR:$rT, coherency:$coherency),
                !strconcat(mnemonic, "${coherency} [$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{30-26}  = 0b01111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b101000;
}

def ASADDB_ASADDSB         : LSU_ASADDSB_Inst<"asaddb", []> {
  let Inst{14-13}  = 0b00;
}
def ASADDH_ASADDSB         : LSU_ASADDSB_Inst<"asaddh", []> {
  let Inst{14-13}  = 0b01;
}
def ASADDW_ASADDSB         : LSU_ASADDSB_Inst<"asaddw", []> {
  let Inst{14-13}  = 0b10;
}
def ASADDD_ASADDSB         : LSU_ASADDSB_Inst<"asaddd", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ASADDSB.O — LSU Atomic Store and Add Scalar Base Offset
// double (64 bits), syntax: %0%3 %4[%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ASADDSB_O_Inst<string mnemonic, list<dag> pattern,
                         InstrItinClass itin = LSU2_MEMW_AUXR_X>
    : LVXInst64<(outs), (ins GPR:$rZ, GPR:$rT, coherency:$coherency, simm27:$off),
                !strconcat(mnemonic, "${coherency} $off[$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  bits<27> off;
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{58-32}  = off;
  let Inst{62-61}  = 0b00;
  let Inst{31-26}  = 0b101111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b101000;
}

def ASADDB_ASADDSB_O       : LSU_ASADDSB_O_Inst<"asaddb", []> {
  let Inst{14-13}  = 0b00;
}
def ASADDH_ASADDSB_O       : LSU_ASADDSB_O_Inst<"asaddh", []> {
  let Inst{14-13}  = 0b01;
}
def ASADDW_ASADDSB_O       : LSU_ASADDSB_O_Inst<"asaddw", []> {
  let Inst{14-13}  = 0b10;
}
def ASADDD_ASADDSB_O       : LSU_ASADDSB_O_Inst<"asaddd", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ASADDSB.D — LSU Atomic Store and Add Scalar Base Double Offset
// triple (96 bits), syntax: %0%3 %4[%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ASADDSB_D_Inst<string mnemonic, list<dag> pattern,
                         InstrItinClass itin = LSU2_MEMW_AUXR_Y>
    : LVXInst96<(outs), (ins GPR:$rZ, GPR:$rT, coherency:$coherency, simm54:$off),
                !strconcat(mnemonic, "${coherency} $off[$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  bits<54> off;
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{90-64}  = off{53-27};
  let Inst{58-32}  = off{26-0};
  let Inst{94-93}  = 0b00;
  let Inst{63-61}  = 0b100;
  let Inst{31-26}  = 0b101111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b101000;
}

def ASADDB_ASADDSB_D       : LSU_ASADDSB_D_Inst<"asaddb", []> {
  let Inst{14-13}  = 0b00;
}
def ASADDH_ASADDSB_D       : LSU_ASADDSB_D_Inst<"asaddh", []> {
  let Inst{14-13}  = 0b01;
}
def ASADDW_ASADDSB_D       : LSU_ASADDSB_D_Inst<"asaddw", []> {
  let Inst{14-13}  = 0b10;
}
def ASADDD_ASADDSB_D       : LSU_ASADDSB_D_Inst<"asaddd", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ASANDSB — LSU Atomic Store and AND Scalar Base
// simple (32 bits), syntax: %0%3 [%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ASANDSB_Inst<string mnemonic, list<dag> pattern,
                       InstrItinClass itin = LSU2_MEMW_AUXR>
    : LVXInst32<(outs), (ins GPR:$rZ, GPR:$rT, coherency:$coherency),
                !strconcat(mnemonic, "${coherency} [$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{30-26}  = 0b01111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b101010;
}

def ASANDB_ASANDSB         : LSU_ASANDSB_Inst<"asandb", []> {
  let Inst{14-13}  = 0b00;
}
def ASANDH_ASANDSB         : LSU_ASANDSB_Inst<"asandh", []> {
  let Inst{14-13}  = 0b01;
}
def ASANDW_ASANDSB         : LSU_ASANDSB_Inst<"asandw", []> {
  let Inst{14-13}  = 0b10;
}
def ASANDD_ASANDSB         : LSU_ASANDSB_Inst<"asandd", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ASANDSB.O — LSU Atomic Store and AND Scalar Base Offset
// double (64 bits), syntax: %0%3 %4[%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ASANDSB_O_Inst<string mnemonic, list<dag> pattern,
                         InstrItinClass itin = LSU2_MEMW_AUXR_X>
    : LVXInst64<(outs), (ins GPR:$rZ, GPR:$rT, coherency:$coherency, simm27:$off),
                !strconcat(mnemonic, "${coherency} $off[$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  bits<27> off;
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{58-32}  = off;
  let Inst{62-61}  = 0b00;
  let Inst{31-26}  = 0b101111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b101010;
}

def ASANDB_ASANDSB_O       : LSU_ASANDSB_O_Inst<"asandb", []> {
  let Inst{14-13}  = 0b00;
}
def ASANDH_ASANDSB_O       : LSU_ASANDSB_O_Inst<"asandh", []> {
  let Inst{14-13}  = 0b01;
}
def ASANDW_ASANDSB_O       : LSU_ASANDSB_O_Inst<"asandw", []> {
  let Inst{14-13}  = 0b10;
}
def ASANDD_ASANDSB_O       : LSU_ASANDSB_O_Inst<"asandd", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ASANDSB.D — LSU Atomic Store and AND Scalar Base Double Offset
// triple (96 bits), syntax: %0%3 %4[%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ASANDSB_D_Inst<string mnemonic, list<dag> pattern,
                         InstrItinClass itin = LSU2_MEMW_AUXR_Y>
    : LVXInst96<(outs), (ins GPR:$rZ, GPR:$rT, coherency:$coherency, simm54:$off),
                !strconcat(mnemonic, "${coherency} $off[$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  bits<54> off;
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{90-64}  = off{53-27};
  let Inst{58-32}  = off{26-0};
  let Inst{94-93}  = 0b00;
  let Inst{63-61}  = 0b100;
  let Inst{31-26}  = 0b101111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b101010;
}

def ASANDB_ASANDSB_D       : LSU_ASANDSB_D_Inst<"asandb", []> {
  let Inst{14-13}  = 0b00;
}
def ASANDH_ASANDSB_D       : LSU_ASANDSB_D_Inst<"asandh", []> {
  let Inst{14-13}  = 0b01;
}
def ASANDW_ASANDSB_D       : LSU_ASANDSB_D_Inst<"asandw", []> {
  let Inst{14-13}  = 0b10;
}
def ASANDD_ASANDSB_D       : LSU_ASANDSB_D_Inst<"asandd", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ASIORSB — LSU Atomic Store and IOR Scalar Base
// simple (32 bits), syntax: %0%3 [%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ASIORSB_Inst<string mnemonic, list<dag> pattern,
                       InstrItinClass itin = LSU2_MEMW_AUXR>
    : LVXInst32<(outs), (ins GPR:$rZ, GPR:$rT, coherency:$coherency),
                !strconcat(mnemonic, "${coherency} [$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{30-26}  = 0b01111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b101100;
}

def ASIORB_ASIORSB         : LSU_ASIORSB_Inst<"asiorb", []> {
  let Inst{14-13}  = 0b00;
}
def ASIORH_ASIORSB         : LSU_ASIORSB_Inst<"asiorh", []> {
  let Inst{14-13}  = 0b01;
}
def ASIORW_ASIORSB         : LSU_ASIORSB_Inst<"asiorw", []> {
  let Inst{14-13}  = 0b10;
}
def ASIORD_ASIORSB         : LSU_ASIORSB_Inst<"asiord", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ASIORSB.O — LSU Atomic Store and IOR Scalar Base Offset
// double (64 bits), syntax: %0%3 %4[%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ASIORSB_O_Inst<string mnemonic, list<dag> pattern,
                         InstrItinClass itin = LSU2_MEMW_AUXR_X>
    : LVXInst64<(outs), (ins GPR:$rZ, GPR:$rT, coherency:$coherency, simm27:$off),
                !strconcat(mnemonic, "${coherency} $off[$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  bits<27> off;
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{58-32}  = off;
  let Inst{62-61}  = 0b00;
  let Inst{31-26}  = 0b101111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b101100;
}

def ASIORB_ASIORSB_O       : LSU_ASIORSB_O_Inst<"asiorb", []> {
  let Inst{14-13}  = 0b00;
}
def ASIORH_ASIORSB_O       : LSU_ASIORSB_O_Inst<"asiorh", []> {
  let Inst{14-13}  = 0b01;
}
def ASIORW_ASIORSB_O       : LSU_ASIORSB_O_Inst<"asiorw", []> {
  let Inst{14-13}  = 0b10;
}
def ASIORD_ASIORSB_O       : LSU_ASIORSB_O_Inst<"asiord", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ASIORSB.D — LSU Atomic Store and IOR Scalar Base Double Offset
// triple (96 bits), syntax: %0%3 %4[%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ASIORSB_D_Inst<string mnemonic, list<dag> pattern,
                         InstrItinClass itin = LSU2_MEMW_AUXR_Y>
    : LVXInst96<(outs), (ins GPR:$rZ, GPR:$rT, coherency:$coherency, simm54:$off),
                !strconcat(mnemonic, "${coherency} $off[$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  bits<54> off;
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{90-64}  = off{53-27};
  let Inst{58-32}  = off{26-0};
  let Inst{94-93}  = 0b00;
  let Inst{63-61}  = 0b100;
  let Inst{31-26}  = 0b101111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b101100;
}

def ASIORB_ASIORSB_D       : LSU_ASIORSB_D_Inst<"asiorb", []> {
  let Inst{14-13}  = 0b00;
}
def ASIORH_ASIORSB_D       : LSU_ASIORSB_D_Inst<"asiorh", []> {
  let Inst{14-13}  = 0b01;
}
def ASIORW_ASIORSB_D       : LSU_ASIORSB_D_Inst<"asiorw", []> {
  let Inst{14-13}  = 0b10;
}
def ASIORD_ASIORSB_D       : LSU_ASIORSB_D_Inst<"asiord", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ASEORSB — LSU Atomic Store and EOR Scalar Base
// simple (32 bits), syntax: %0%3 [%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ASEORSB_Inst<string mnemonic, list<dag> pattern,
                       InstrItinClass itin = LSU2_MEMW_AUXR>
    : LVXInst32<(outs), (ins GPR:$rZ, GPR:$rT, coherency:$coherency),
                !strconcat(mnemonic, "${coherency} [$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{30-26}  = 0b01111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b101110;
}

def ASEORB_ASEORSB         : LSU_ASEORSB_Inst<"aseorb", []> {
  let Inst{14-13}  = 0b00;
}
def ASEORH_ASEORSB         : LSU_ASEORSB_Inst<"aseorh", []> {
  let Inst{14-13}  = 0b01;
}
def ASEORW_ASEORSB         : LSU_ASEORSB_Inst<"aseorw", []> {
  let Inst{14-13}  = 0b10;
}
def ASEORD_ASEORSB         : LSU_ASEORSB_Inst<"aseord", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ASEORSB.O — LSU Atomic Store and EOR Scalar Base Offset
// double (64 bits), syntax: %0%3 %4[%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ASEORSB_O_Inst<string mnemonic, list<dag> pattern,
                         InstrItinClass itin = LSU2_MEMW_AUXR_X>
    : LVXInst64<(outs), (ins GPR:$rZ, GPR:$rT, coherency:$coherency, simm27:$off),
                !strconcat(mnemonic, "${coherency} $off[$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  bits<27> off;
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{58-32}  = off;
  let Inst{62-61}  = 0b00;
  let Inst{31-26}  = 0b101111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b101110;
}

def ASEORB_ASEORSB_O       : LSU_ASEORSB_O_Inst<"aseorb", []> {
  let Inst{14-13}  = 0b00;
}
def ASEORH_ASEORSB_O       : LSU_ASEORSB_O_Inst<"aseorh", []> {
  let Inst{14-13}  = 0b01;
}
def ASEORW_ASEORSB_O       : LSU_ASEORSB_O_Inst<"aseorw", []> {
  let Inst{14-13}  = 0b10;
}
def ASEORD_ASEORSB_O       : LSU_ASEORSB_O_Inst<"aseord", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ASEORSB.D — LSU Atomic Store and EOR Scalar Base Double Offset
// triple (96 bits), syntax: %0%3 %4[%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ASEORSB_D_Inst<string mnemonic, list<dag> pattern,
                         InstrItinClass itin = LSU2_MEMW_AUXR_Y>
    : LVXInst96<(outs), (ins GPR:$rZ, GPR:$rT, coherency:$coherency, simm54:$off),
                !strconcat(mnemonic, "${coherency} $off[$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  bits<54> off;
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{90-64}  = off{53-27};
  let Inst{58-32}  = off{26-0};
  let Inst{94-93}  = 0b00;
  let Inst{63-61}  = 0b100;
  let Inst{31-26}  = 0b101111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b101110;
}

def ASEORB_ASEORSB_D       : LSU_ASEORSB_D_Inst<"aseorb", []> {
  let Inst{14-13}  = 0b00;
}
def ASEORH_ASEORSB_D       : LSU_ASEORSB_D_Inst<"aseorh", []> {
  let Inst{14-13}  = 0b01;
}
def ASEORW_ASEORSB_D       : LSU_ASEORSB_D_Inst<"aseorw", []> {
  let Inst{14-13}  = 0b10;
}
def ASEORD_ASEORSB_D       : LSU_ASEORSB_D_Inst<"aseord", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ASMINSB — LSU Atomic Store and MIN Scalar Base
// simple (32 bits), syntax: %0%3 [%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ASMINSB_Inst<string mnemonic, list<dag> pattern,
                       InstrItinClass itin = LSU2_MEMW_AUXR>
    : LVXInst32<(outs), (ins GPR:$rZ, GPR:$rT, coherency:$coherency),
                !strconcat(mnemonic, "${coherency} [$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{30-26}  = 0b01111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b110000;
}

def ASMINB_ASMINSB         : LSU_ASMINSB_Inst<"asminb", []> {
  let Inst{14-13}  = 0b00;
}
def ASMINH_ASMINSB         : LSU_ASMINSB_Inst<"asminh", []> {
  let Inst{14-13}  = 0b01;
}
def ASMINW_ASMINSB         : LSU_ASMINSB_Inst<"asminw", []> {
  let Inst{14-13}  = 0b10;
}
def ASMIND_ASMINSB         : LSU_ASMINSB_Inst<"asmind", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ASMINSB.O — LSU Atomic Store and MIN Scalar Base Offset
// double (64 bits), syntax: %0%3 %4[%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ASMINSB_O_Inst<string mnemonic, list<dag> pattern,
                         InstrItinClass itin = LSU2_MEMW_AUXR_X>
    : LVXInst64<(outs), (ins GPR:$rZ, GPR:$rT, coherency:$coherency, simm27:$off),
                !strconcat(mnemonic, "${coherency} $off[$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  bits<27> off;
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{58-32}  = off;
  let Inst{62-61}  = 0b00;
  let Inst{31-26}  = 0b101111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b110000;
}

def ASMINB_ASMINSB_O       : LSU_ASMINSB_O_Inst<"asminb", []> {
  let Inst{14-13}  = 0b00;
}
def ASMINH_ASMINSB_O       : LSU_ASMINSB_O_Inst<"asminh", []> {
  let Inst{14-13}  = 0b01;
}
def ASMINW_ASMINSB_O       : LSU_ASMINSB_O_Inst<"asminw", []> {
  let Inst{14-13}  = 0b10;
}
def ASMIND_ASMINSB_O       : LSU_ASMINSB_O_Inst<"asmind", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ASMINSB.D — LSU Atomic Store and MIN Scalar Base Double Offset
// triple (96 bits), syntax: %0%3 %4[%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ASMINSB_D_Inst<string mnemonic, list<dag> pattern,
                         InstrItinClass itin = LSU2_MEMW_AUXR_Y>
    : LVXInst96<(outs), (ins GPR:$rZ, GPR:$rT, coherency:$coherency, simm54:$off),
                !strconcat(mnemonic, "${coherency} $off[$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  bits<54> off;
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{90-64}  = off{53-27};
  let Inst{58-32}  = off{26-0};
  let Inst{94-93}  = 0b00;
  let Inst{63-61}  = 0b100;
  let Inst{31-26}  = 0b101111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b110000;
}

def ASMINB_ASMINSB_D       : LSU_ASMINSB_D_Inst<"asminb", []> {
  let Inst{14-13}  = 0b00;
}
def ASMINH_ASMINSB_D       : LSU_ASMINSB_D_Inst<"asminh", []> {
  let Inst{14-13}  = 0b01;
}
def ASMINW_ASMINSB_D       : LSU_ASMINSB_D_Inst<"asminw", []> {
  let Inst{14-13}  = 0b10;
}
def ASMIND_ASMINSB_D       : LSU_ASMINSB_D_Inst<"asmind", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ASMAXSB — LSU Atomic Store and MAX Scalar Base
// simple (32 bits), syntax: %0%3 [%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ASMAXSB_Inst<string mnemonic, list<dag> pattern,
                       InstrItinClass itin = LSU2_MEMW_AUXR>
    : LVXInst32<(outs), (ins GPR:$rZ, GPR:$rT, coherency:$coherency),
                !strconcat(mnemonic, "${coherency} [$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{30-26}  = 0b01111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b110010;
}

def ASMAXB_ASMAXSB         : LSU_ASMAXSB_Inst<"asmaxb", []> {
  let Inst{14-13}  = 0b00;
}
def ASMAXH_ASMAXSB         : LSU_ASMAXSB_Inst<"asmaxh", []> {
  let Inst{14-13}  = 0b01;
}
def ASMAXW_ASMAXSB         : LSU_ASMAXSB_Inst<"asmaxw", []> {
  let Inst{14-13}  = 0b10;
}
def ASMAXD_ASMAXSB         : LSU_ASMAXSB_Inst<"asmaxd", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ASMAXSB.O — LSU Atomic Store and MAX Scalar Base Offset
// double (64 bits), syntax: %0%3 %4[%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ASMAXSB_O_Inst<string mnemonic, list<dag> pattern,
                         InstrItinClass itin = LSU2_MEMW_AUXR_X>
    : LVXInst64<(outs), (ins GPR:$rZ, GPR:$rT, coherency:$coherency, simm27:$off),
                !strconcat(mnemonic, "${coherency} $off[$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  bits<27> off;
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{58-32}  = off;
  let Inst{62-61}  = 0b00;
  let Inst{31-26}  = 0b101111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b110010;
}

def ASMAXB_ASMAXSB_O       : LSU_ASMAXSB_O_Inst<"asmaxb", []> {
  let Inst{14-13}  = 0b00;
}
def ASMAXH_ASMAXSB_O       : LSU_ASMAXSB_O_Inst<"asmaxh", []> {
  let Inst{14-13}  = 0b01;
}
def ASMAXW_ASMAXSB_O       : LSU_ASMAXSB_O_Inst<"asmaxw", []> {
  let Inst{14-13}  = 0b10;
}
def ASMAXD_ASMAXSB_O       : LSU_ASMAXSB_O_Inst<"asmaxd", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ASMAXSB.D — LSU Atomic Store and MAX Scalar Base Double Offset
// triple (96 bits), syntax: %0%3 %4[%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ASMAXSB_D_Inst<string mnemonic, list<dag> pattern,
                         InstrItinClass itin = LSU2_MEMW_AUXR_Y>
    : LVXInst96<(outs), (ins GPR:$rZ, GPR:$rT, coherency:$coherency, simm54:$off),
                !strconcat(mnemonic, "${coherency} $off[$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  bits<54> off;
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{90-64}  = off{53-27};
  let Inst{58-32}  = off{26-0};
  let Inst{94-93}  = 0b00;
  let Inst{63-61}  = 0b100;
  let Inst{31-26}  = 0b101111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b110010;
}

def ASMAXB_ASMAXSB_D       : LSU_ASMAXSB_D_Inst<"asmaxb", []> {
  let Inst{14-13}  = 0b00;
}
def ASMAXH_ASMAXSB_D       : LSU_ASMAXSB_D_Inst<"asmaxh", []> {
  let Inst{14-13}  = 0b01;
}
def ASMAXW_ASMAXSB_D       : LSU_ASMAXSB_D_Inst<"asmaxw", []> {
  let Inst{14-13}  = 0b10;
}
def ASMAXD_ASMAXSB_D       : LSU_ASMAXSB_D_Inst<"asmaxd", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ASMINUSB — LSU Atomic Store and MIN Unsigned Scalar Base
// simple (32 bits), syntax: %0%3 [%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ASMINUSB_Inst<string mnemonic, list<dag> pattern,
                        InstrItinClass itin = LSU2_MEMW_AUXR>
    : LVXInst32<(outs), (ins GPR:$rZ, GPR:$rT, coherency:$coherency),
                !strconcat(mnemonic, "${coherency} [$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{30-26}  = 0b01111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b110100;
}

def ASMINUB_ASMINUSB       : LSU_ASMINUSB_Inst<"asminub", []> {
  let Inst{14-13}  = 0b00;
}
def ASMINUH_ASMINUSB       : LSU_ASMINUSB_Inst<"asminuh", []> {
  let Inst{14-13}  = 0b01;
}
def ASMINUW_ASMINUSB       : LSU_ASMINUSB_Inst<"asminuw", []> {
  let Inst{14-13}  = 0b10;
}
def ASMINUD_ASMINUSB       : LSU_ASMINUSB_Inst<"asminud", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ASMINUSB.O — LSU Atomic Store and MIN Unsigned Scalar Base Offset
// double (64 bits), syntax: %0%3 %4[%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ASMINUSB_O_Inst<string mnemonic, list<dag> pattern,
                          InstrItinClass itin = LSU2_MEMW_AUXR_X>
    : LVXInst64<(outs), (ins GPR:$rZ, GPR:$rT, coherency:$coherency, simm27:$off),
                !strconcat(mnemonic, "${coherency} $off[$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  bits<27> off;
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{58-32}  = off;
  let Inst{62-61}  = 0b00;
  let Inst{31-26}  = 0b101111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b110100;
}

def ASMINUB_ASMINUSB_O     : LSU_ASMINUSB_O_Inst<"asminub", []> {
  let Inst{14-13}  = 0b00;
}
def ASMINUH_ASMINUSB_O     : LSU_ASMINUSB_O_Inst<"asminuh", []> {
  let Inst{14-13}  = 0b01;
}
def ASMINUW_ASMINUSB_O     : LSU_ASMINUSB_O_Inst<"asminuw", []> {
  let Inst{14-13}  = 0b10;
}
def ASMINUD_ASMINUSB_O     : LSU_ASMINUSB_O_Inst<"asminud", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ASMINUSB.D — LSU Atomic Store and MIN Unsigned Scalar Base Double Offset
// triple (96 bits), syntax: %0%3 %4[%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ASMINUSB_D_Inst<string mnemonic, list<dag> pattern,
                          InstrItinClass itin = LSU2_MEMW_AUXR_Y>
    : LVXInst96<(outs), (ins GPR:$rZ, GPR:$rT, coherency:$coherency, simm54:$off),
                !strconcat(mnemonic, "${coherency} $off[$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  bits<54> off;
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{90-64}  = off{53-27};
  let Inst{58-32}  = off{26-0};
  let Inst{94-93}  = 0b00;
  let Inst{63-61}  = 0b100;
  let Inst{31-26}  = 0b101111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b110100;
}

def ASMINUB_ASMINUSB_D     : LSU_ASMINUSB_D_Inst<"asminub", []> {
  let Inst{14-13}  = 0b00;
}
def ASMINUH_ASMINUSB_D     : LSU_ASMINUSB_D_Inst<"asminuh", []> {
  let Inst{14-13}  = 0b01;
}
def ASMINUW_ASMINUSB_D     : LSU_ASMINUSB_D_Inst<"asminuw", []> {
  let Inst{14-13}  = 0b10;
}
def ASMINUD_ASMINUSB_D     : LSU_ASMINUSB_D_Inst<"asminud", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ASMAXUSB — LSU Atomic Store and MAX Unsigned Scalar Base
// simple (32 bits), syntax: %0%3 [%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ASMAXUSB_Inst<string mnemonic, list<dag> pattern,
                        InstrItinClass itin = LSU2_MEMW_AUXR>
    : LVXInst32<(outs), (ins GPR:$rZ, GPR:$rT, coherency:$coherency),
                !strconcat(mnemonic, "${coherency} [$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{30-26}  = 0b01111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b110110;
}

def ASMAXUB_ASMAXUSB       : LSU_ASMAXUSB_Inst<"asmaxub", []> {
  let Inst{14-13}  = 0b00;
}
def ASMAXUH_ASMAXUSB       : LSU_ASMAXUSB_Inst<"asmaxuh", []> {
  let Inst{14-13}  = 0b01;
}
def ASMAXUW_ASMAXUSB       : LSU_ASMAXUSB_Inst<"asmaxuw", []> {
  let Inst{14-13}  = 0b10;
}
def ASMAXUD_ASMAXUSB       : LSU_ASMAXUSB_Inst<"asmaxud", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ASMAXUSB.O — LSU Atomic Store and MAX Unsigned Scalar Base Offset
// double (64 bits), syntax: %0%3 %4[%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ASMAXUSB_O_Inst<string mnemonic, list<dag> pattern,
                          InstrItinClass itin = LSU2_MEMW_AUXR_X>
    : LVXInst64<(outs), (ins GPR:$rZ, GPR:$rT, coherency:$coherency, simm27:$off),
                !strconcat(mnemonic, "${coherency} $off[$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  bits<27> off;
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{58-32}  = off;
  let Inst{62-61}  = 0b00;
  let Inst{31-26}  = 0b101111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b110110;
}

def ASMAXUB_ASMAXUSB_O     : LSU_ASMAXUSB_O_Inst<"asmaxub", []> {
  let Inst{14-13}  = 0b00;
}
def ASMAXUH_ASMAXUSB_O     : LSU_ASMAXUSB_O_Inst<"asmaxuh", []> {
  let Inst{14-13}  = 0b01;
}
def ASMAXUW_ASMAXUSB_O     : LSU_ASMAXUSB_O_Inst<"asmaxuw", []> {
  let Inst{14-13}  = 0b10;
}
def ASMAXUD_ASMAXUSB_O     : LSU_ASMAXUSB_O_Inst<"asmaxud", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ASMAXUSB.D — LSU Atomic Store and MAX Unsigned Scalar Base Double Offset
// triple (96 bits), syntax: %0%3 %4[%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ASMAXUSB_D_Inst<string mnemonic, list<dag> pattern,
                          InstrItinClass itin = LSU2_MEMW_AUXR_Y>
    : LVXInst96<(outs), (ins GPR:$rZ, GPR:$rT, coherency:$coherency, simm54:$off),
                !strconcat(mnemonic, "${coherency} $off[$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  bits<54> off;
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{90-64}  = off{53-27};
  let Inst{58-32}  = off{26-0};
  let Inst{94-93}  = 0b00;
  let Inst{63-61}  = 0b100;
  let Inst{31-26}  = 0b101111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b110110;
}

def ASMAXUB_ASMAXUSB_D     : LSU_ASMAXUSB_D_Inst<"asmaxub", []> {
  let Inst{14-13}  = 0b00;
}
def ASMAXUH_ASMAXUSB_D     : LSU_ASMAXUSB_D_Inst<"asmaxuh", []> {
  let Inst{14-13}  = 0b01;
}
def ASMAXUW_ASMAXUSB_D     : LSU_ASMAXUSB_D_Inst<"asmaxuw", []> {
  let Inst{14-13}  = 0b10;
}
def ASMAXUD_ASMAXUSB_D     : LSU_ASMAXUSB_D_Inst<"asmaxud", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ASDUSSB — LSU Atomic Store and Decrement Unsigned Saturating Scalar Base
// simple (32 bits), syntax: %0%3 [%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ASDUSSB_Inst<string mnemonic, list<dag> pattern,
                       InstrItinClass itin = LSU2_MEMW_AUXR>
    : LVXInst32<(outs), (ins GPR:$rZ, GPR:$rT, coherency:$coherency),
                !strconcat(mnemonic, "${coherency} [$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{30-26}  = 0b01111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b111100;
}

def ASDUSB_ASDUSSB         : LSU_ASDUSSB_Inst<"asdusb", []> {
  let Inst{14-13}  = 0b00;
}
def ASDUSH_ASDUSSB         : LSU_ASDUSSB_Inst<"asdush", []> {
  let Inst{14-13}  = 0b01;
}
def ASDUSW_ASDUSSB         : LSU_ASDUSSB_Inst<"asdusw", []> {
  let Inst{14-13}  = 0b10;
}
def ASDUSD_ASDUSSB         : LSU_ASDUSSB_Inst<"asdusd", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ASDUSSB.O — LSU Atomic Store and Decrement Unsigned Saturating Scalar Base Offset
// double (64 bits), syntax: %0%3 %4[%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ASDUSSB_O_Inst<string mnemonic, list<dag> pattern,
                         InstrItinClass itin = LSU2_MEMW_AUXR_X>
    : LVXInst64<(outs), (ins GPR:$rZ, GPR:$rT, coherency:$coherency, simm27:$off),
                !strconcat(mnemonic, "${coherency} $off[$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  bits<27> off;
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{58-32}  = off;
  let Inst{62-61}  = 0b00;
  let Inst{31-26}  = 0b101111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b111100;
}

def ASDUSB_ASDUSSB_O       : LSU_ASDUSSB_O_Inst<"asdusb", []> {
  let Inst{14-13}  = 0b00;
}
def ASDUSH_ASDUSSB_O       : LSU_ASDUSSB_O_Inst<"asdush", []> {
  let Inst{14-13}  = 0b01;
}
def ASDUSW_ASDUSSB_O       : LSU_ASDUSSB_O_Inst<"asdusw", []> {
  let Inst{14-13}  = 0b10;
}
def ASDUSD_ASDUSSB_O       : LSU_ASDUSSB_O_Inst<"asdusd", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_ASDUSSB.D — LSU Atomic Store and Decrement Unsigned Saturating Scalar Base Double Offset
// triple (96 bits), syntax: %0%3 %4[%1] = %2
//===----------------------------------------------------------------------===//
class LSU_ASDUSSB_D_Inst<string mnemonic, list<dag> pattern,
                         InstrItinClass itin = LSU2_MEMW_AUXR_Y>
    : LVXInst96<(outs), (ins GPR:$rZ, GPR:$rT, coherency:$coherency, simm54:$off),
                !strconcat(mnemonic, "${coherency} $off[$rZ] = $rT"),
                pattern, itin> {
  bits<6>  rZ;
  bits<6>  rT;
  bits<2>  coherency;
  bits<54> off;
  let Inst{5-0}    = rZ;
  let Inst{23-18}  = rT;
  let Inst{25-24}  = coherency;
  let Inst{90-64}  = off{53-27};
  let Inst{58-32}  = off{26-0};
  let Inst{94-93}  = 0b00;
  let Inst{63-61}  = 0b100;
  let Inst{31-26}  = 0b101111;
  let Inst{17-15}  = 0b110;
  let Inst{11-6}   = 0b111100;
}

def ASDUSB_ASDUSSB_D       : LSU_ASDUSSB_D_Inst<"asdusb", []> {
  let Inst{14-13}  = 0b00;
}
def ASDUSH_ASDUSSB_D       : LSU_ASDUSSB_D_Inst<"asdush", []> {
  let Inst{14-13}  = 0b01;
}
def ASDUSW_ASDUSSB_D       : LSU_ASDUSSB_D_Inst<"asdusw", []> {
  let Inst{14-13}  = 0b10;
}
def ASDUSD_ASDUSSB_D       : LSU_ASDUSSB_D_Inst<"asdusd", []> {
  let Inst{14-13}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_FXBO — LSU Memory Effects Base Offset
// simple (32 bits), syntax: %0 %2[%1]
//===----------------------------------------------------------------------===//
class LSU_FXBO_Inst<string mnemonic, list<dag> pattern,
                    InstrItinClass itin>
    : LVXInst32<(outs), (ins GPR:$rZ, simm10:$off),
                !strconcat(mnemonic, " $off[$rZ]"),
                pattern, itin> {
  bits<6>  rZ;
  bits<10> off;
  let Inst{5-0}    = rZ;
  let Inst{15-6}   = off;
  let Inst{30-23}  = 0b01111000;
  let Inst{19-16}  = 0b1100;
}

def DTOUCHL_FXBO           : LSU_FXBO_Inst<"dtouchl", [], LSU> {
  let Inst{22-20}  = 0b000;
}
def DINVALL_FXBO           : LSU_FXBO_Inst<"dinvall", [], LSU> {
  let Inst{22-20}  = 0b001;
}
def DPURGEL_FXBO           : LSU_FXBO_Inst<"dpurgel", [], LSU> {
  let Inst{22-20}  = 0b010;
}
def DFLUSHL_FXBO           : LSU_FXBO_Inst<"dflushl", [], LSU> {
  let Inst{22-20}  = 0b011;
}
def I1INVALS_FXBO          : LSU_FXBO_Inst<"i1invals", [], LSU2_MEMW> {
  let Inst{22-20}  = 0b101;
}

//===----------------------------------------------------------------------===//
// LSU_FXBO.X — LSU Memory Effects Base Offset Extended
// double (64 bits), syntax: %0 %2[%1]
//===----------------------------------------------------------------------===//
class LSU_FXBO_X_Inst<string mnemonic, list<dag> pattern,
                      InstrItinClass itin>
    : LVXInst64<(outs), (ins GPR:$rZ, simm37:$off),
                !strconcat(mnemonic, " $off[$rZ]"),
                pattern, itin> {
  bits<6>  rZ;
  bits<37> off;
  let Inst{5-0}    = rZ;
  let Inst{58-32}  = off{36-10};
  let Inst{15-6}   = off{9-0};
  let Inst{62-61}  = 0b00;
  let Inst{31-23}  = 0b101111000;
  let Inst{19-16}  = 0b1100;
}

def DTOUCHL_FXBO_X         : LSU_FXBO_X_Inst<"dtouchl", [], LSU_X> {
  let Inst{22-20}  = 0b000;
}
def DINVALL_FXBO_X         : LSU_FXBO_X_Inst<"dinvall", [], LSU_X> {
  let Inst{22-20}  = 0b001;
}
def DPURGEL_FXBO_X         : LSU_FXBO_X_Inst<"dpurgel", [], LSU_X> {
  let Inst{22-20}  = 0b010;
}
def DFLUSHL_FXBO_X         : LSU_FXBO_X_Inst<"dflushl", [], LSU_X> {
  let Inst{22-20}  = 0b011;
}
def I1INVALS_FXBO_X        : LSU_FXBO_X_Inst<"i1invals", [], LSU2_MEMW_X> {
  let Inst{22-20}  = 0b101;
}

//===----------------------------------------------------------------------===//
// LSU_FXBO.Y — LSU Memory Effects Base Offset Extended Extended
// triple (96 bits), syntax: %0 %2[%1]
//===----------------------------------------------------------------------===//
class LSU_FXBO_Y_Inst<string mnemonic, list<dag> pattern,
                      InstrItinClass itin>
    : LVXInst96<(outs), (ins GPR:$rZ, wimm64:$off),
                !strconcat(mnemonic, " $off[$rZ]"),
                pattern, itin> {
  bits<6>  rZ;
  bits<64> off;
  let Inst{5-0}    = rZ;
  let Inst{90-64}  = off{63-37};
  let Inst{58-32}  = off{36-10};
  let Inst{15-6}   = off{9-0};
  let Inst{94-93}  = 0b00;
  let Inst{63-61}  = 0b100;
  let Inst{31-23}  = 0b101111000;
  let Inst{19-16}  = 0b1100;
}

def DTOUCHL_FXBO_Y         : LSU_FXBO_Y_Inst<"dtouchl", [], LSU_Y> {
  let Inst{22-20}  = 0b000;
}
def DINVALL_FXBO_Y         : LSU_FXBO_Y_Inst<"dinvall", [], LSU_Y> {
  let Inst{22-20}  = 0b001;
}
def DPURGEL_FXBO_Y         : LSU_FXBO_Y_Inst<"dpurgel", [], LSU_Y> {
  let Inst{22-20}  = 0b010;
}
def DFLUSHL_FXBO_Y         : LSU_FXBO_Y_Inst<"dflushl", [], LSU_Y> {
  let Inst{22-20}  = 0b011;
}
def I1INVALS_FXBO_Y        : LSU_FXBO_Y_Inst<"i1invals", [], LSU2_MEMW_Y> {
  let Inst{22-20}  = 0b101;
}

//===----------------------------------------------------------------------===//
// LSU_FXBI — LSU Memory Effects Base + Index
// simple (32 bits), syntax: %0 %1[%2]
//===----------------------------------------------------------------------===//
class LSU_FXBI_Inst<string mnemonic, list<dag> pattern,
                    InstrItinClass itin>
    : LVXInst32<(outs), (ins GPR:$rY, GPR:$rZ),
                !strconcat(mnemonic, " $rY[$rZ]"),
                pattern, itin> {
  bits<6>  rY;
  bits<6>  rZ;
  let Inst{11-6}   = rY;
  let Inst{5-0}    = rZ;
  let Inst{30-23}  = 0b01111000;
  let Inst{19-13}  = 0b1110111;
}

def DTOUCHL_FXBI           : LSU_FXBI_Inst<"dtouchl", [], LSU> {
  let Inst{22-20}  = 0b000;
}
def DINVALL_FXBI           : LSU_FXBI_Inst<"dinvall", [], LSU> {
  let Inst{22-20}  = 0b001;
}
def DPURGEL_FXBI           : LSU_FXBI_Inst<"dpurgel", [], LSU> {
  let Inst{22-20}  = 0b010;
}
def DFLUSHL_FXBI           : LSU_FXBI_Inst<"dflushl", [], LSU> {
  let Inst{22-20}  = 0b011;
}
def I1INVALS_FXBI          : LSU_FXBI_Inst<"i1invals", [], LSU2_MEMW> {
  let Inst{22-20}  = 0b101;
}

//===----------------------------------------------------------------------===//
// LSU_FXSW — LSU Memory Effects by Set / Way
// simple (32 bits), syntax: %0%3 %1, %2
//===----------------------------------------------------------------------===//
class LSU_FXSW_Inst<string mnemonic, list<dag> pattern,
                    InstrItinClass itin = LSU2_MEMW>
    : LVXInst32<(outs), (ins GPR:$rY, GPR:$rZ, cachelev:$cachelev),
                !strconcat(mnemonic, "${cachelev} $rY, $rZ"),
                pattern, itin> {
  bits<6>  rY;
  bits<6>  rZ;
  bits<2>  cachelev;
  let Inst{11-6}   = rY;
  let Inst{5-0}    = rZ;
  let Inst{25-24}  = cachelev;
  let Inst{30-26}  = 0b01111;
  let Inst{23-22}  = 0b10;
  let Inst{19-13}  = 0b1110111;
}

def DINVALSW_FXSW          : LSU_FXSW_Inst<"dinvalsw", []> {
  let Inst{21-20}  = 0b01;
}
def DPURGESW_FXSW          : LSU_FXSW_Inst<"dpurgesw", []> {
  let Inst{21-20}  = 0b10;
}
def DFLUSHSW_FXSW          : LSU_FXSW_Inst<"dflushsw", []> {
  let Inst{21-20}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_MCC — LSU Memory and Cache Control
// simple (32 bits), syntax: %0
//===----------------------------------------------------------------------===//
class LSU_MCC_Inst<string mnemonic, list<dag> pattern,
                   InstrItinClass itin = LSU2_MEMW>
    : LVXInst32<(outs), (ins),
                !strconcat(mnemonic, ""),
                pattern, itin> {

  let Inst{30-23}  = 0b01111001;
  let Inst{21-16}  = 0b001100;
}

def D1INVAL_MCC            : LSU_MCC_Inst<"d1inval", []> {
  let Inst{22}     = 0b0;
}
def I1INVAL_MCC            : LSU_MCC_Inst<"i1inval", []> {
  let Inst{22}     = 0b1;
}

//===----------------------------------------------------------------------===//
// LSU_FENCE — LSU Memory Fence
// simple (32 bits), syntax: %0%1
//===----------------------------------------------------------------------===//
class LSU_FENCE_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin = LSU2_MEMW>
    : LVXInst32<(outs), (ins accesses:$accesses),
                !strconcat(mnemonic, "${accesses}"),
                pattern, itin> {
  bits<2>  accesses;
  let Inst{25-24}  = accesses;
  let Inst{30-26}  = 0b01111;
  let Inst{23-16}  = 0b11111100;
}

def FENCE_FENCE            : LSU_FENCE_Inst<"fence", []>;

//===----------------------------------------------------------------------===//
// ALU_NOP — ALU No Operation
// simple (32 bits), syntax: %0
//===----------------------------------------------------------------------===//
class ALU_NOP_Inst<string mnemonic, list<dag> pattern,
                   InstrItinClass itin = ALU_TINY>
    : LVXInst32<(outs), (ins),
                !strconcat(mnemonic, ""),
                pattern, itin> {

  let Inst{30-24}  = 0b1111111;
  let Inst{18-6}   = 0b1111111111111;
  let Inst{0}      = 0b1;
}

def NOP_NOP                : ALU_NOP_Inst<"nop", []> {
  let hasSideEffects = 0;
}

//===----------------------------------------------------------------------===//
// ALU_DWRRS — ALU Double Word Write Read Read Special
// simple (32 bits), syntax: %0 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_DWRRS_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin = ALU_TINY>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, GPR:$rY),
                !strconcat(mnemonic, " $rW = $rZ, $rY"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<6>  rY;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = rY;
  let Inst{30-26}  = 0b11011;
  let Inst{17-12}  = 0b100100;
}

def STSUD_DWRRS            : ALU_DWRRS_Inst<"stsud", []> {
  let Inst{25-24}  = 0b11;
}
def ABDD_DWRRS             : ALU_DWRRS_Inst<"abdd", []> {
  let Inst{25-24}  = 0b00;
}
def ABDSD_DWRRS            : ALU_DWRRS_Inst<"abdsd", []> {
  let Inst{25-24}  = 0b10;
}
def ABDUD_DWRRS            : ALU_DWRRS_Inst<"abdud", []> {
  let Inst{25-24}  = 0b01;
}

//===----------------------------------------------------------------------===//
// ALU_WWRRS — ALU Word Write Read Read Special
// simple (32 bits), syntax: %0%4 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_WWRRS_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin = ALU_TINY>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, GPR:$rY, signextw:$signextw),
                !strconcat(mnemonic, "${signextw} $rW = $rZ, $rY"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<6>  rY;
  bits<1>  signextw;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = rY;
  let Inst{12}     = signextw;
  let Inst{30-26}  = 0b11011;
  let Inst{17-13}  = 0b11010;
}

def STSUW_WWRRS            : ALU_WWRRS_Inst<"stsuw", []> {
  let Inst{25-24}  = 0b11;
}
def ABDW_WWRRS             : ALU_WWRRS_Inst<"abdw", []> {
  let Inst{25-24}  = 0b00;
}
def ABDSW_WWRRS            : ALU_WWRRS_Inst<"abdsw", []> {
  let Inst{25-24}  = 0b10;
}
def ABDUW_WWRRS            : ALU_WWRRS_Inst<"abduw", []> {
  let Inst{25-24}  = 0b01;
}

//===----------------------------------------------------------------------===//
// ALU_DWRRS.M — ALU Double Word Write Read Read Special Magic
// double (64 bits), syntax: %0 %1 = %2, %3%4
//===----------------------------------------------------------------------===//
class ALU_DWRRS_M_Inst<string mnemonic, list<dag> pattern,
                       InstrItinClass itin = ALU_TINY_X>
    : LVXInst64<(outs GPR:$rW), (ins GPR:$rZ, wimm32:$imm, splat32:$splat32),
                !strconcat(mnemonic, " $rW = $rZ, $imm${splat32}"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<32> imm;
  bits<1>  splat32;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{58-32}  = imm{31-5};
  let Inst{10-6}   = imm{4-0};
  let Inst{11}     = splat32;
  let Inst{62-61}  = 0b00;
  let Inst{31-26}  = 0b111011;
  let Inst{17-12}  = 0b100100;
}

def ABDD_DWRRS_M           : ALU_DWRRS_M_Inst<"abdd", []> {
  let Inst{25-24}  = 0b00;
}
def ABDSD_DWRRS_M          : ALU_DWRRS_M_Inst<"abdsd", []> {
  let Inst{25-24}  = 0b10;
}
def ABDUD_DWRRS_M          : ALU_DWRRS_M_Inst<"abdud", []> {
  let Inst{25-24}  = 0b01;
}

//===----------------------------------------------------------------------===//
// ALU_WWRRS.M — ALU Word Write Read Read Special Magic
// double (64 bits), syntax: %0%4 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_WWRRS_M_Inst<string mnemonic, list<dag> pattern,
                       InstrItinClass itin = ALU_TINY_X>
    : LVXInst64<(outs GPR:$rW), (ins GPR:$rZ, wimm32:$imm, signextw:$signextw),
                !strconcat(mnemonic, "${signextw} $rW = $rZ, $imm"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<32> imm;
  bits<1>  signextw;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{58-32}  = imm{31-5};
  let Inst{10-6}   = imm{4-0};
  let Inst{12}     = signextw;
  let Inst{62-61}  = 0b00;
  let Inst{31-26}  = 0b111011;
  let Inst{17-13}  = 0b11010;
}

def ABDW_WWRRS_M           : ALU_WWRRS_M_Inst<"abdw", []> {
  let Inst{25-24}  = 0b00;
}
def ABDSW_WWRRS_M          : ALU_WWRRS_M_Inst<"abdsw", []> {
  let Inst{25-24}  = 0b10;
}
def ABDUW_WWRRS_M          : ALU_WWRRS_M_Inst<"abduw", []> {
  let Inst{25-24}  = 0b01;
}

//===----------------------------------------------------------------------===//
// ALU_QWRR0 — ALU Word Quadruple Write Read Read 0
// simple (32 bits), syntax: %0 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_QWRR0_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin = ALU_LITE>
    : LVXInst32<(outs GPR128:$rM), (ins GPR128:$rP, GPR128:$rO),
                !strconcat(mnemonic, " $rM = $rP, $rO"),
                pattern, itin> {
  bits<5>  rM;
  bits<5>  rP;
  bits<5>  rO;
  let Inst{23-19}  = rM;
  let Inst{5-1}    = rP;
  let Inst{11-7}   = rO;
  let Inst{30-28}  = 0b110;
  let Inst{17-12}  = 0b100001;
}

def ADDQ_QWRR0             : ALU_QWRR0_Inst<"addq", []> {
  let Inst{27-24}  = 0b0010;
}
def SBFQ_QWRR0             : ALU_QWRR0_Inst<"sbfq", []> {
  let Inst{27-24}  = 0b0011;
}
def ANDQ_QWRR0             : ALU_QWRR0_Inst<"andq", []> {
  let Inst{27-24}  = 0b1000;
}
def NANDQ_QWRR0            : ALU_QWRR0_Inst<"nandq", []> {
  let Inst{27-24}  = 0b1001;
}
def IORQ_QWRR0             : ALU_QWRR0_Inst<"iorq", []> {
  let Inst{27-24}  = 0b1010;
}
def NIORQ_QWRR0            : ALU_QWRR0_Inst<"niorq", []> {
  let Inst{27-24}  = 0b1011;
}
def EORQ_QWRR0             : ALU_QWRR0_Inst<"eorq", []> {
  let Inst{27-24}  = 0b1100;
}
def NEORQ_QWRR0            : ALU_QWRR0_Inst<"neorq", []> {
  let Inst{27-24}  = 0b1101;
}
def ANDNQ_QWRR0            : ALU_QWRR0_Inst<"andnq", []> {
  let Inst{27-24}  = 0b1110;
}
def IORNQ_QWRR0            : ALU_QWRR0_Inst<"iornq", []> {
  let Inst{27-24}  = 0b1111;
}

//===----------------------------------------------------------------------===//
// ALU_QWRR0.M — ALU Word Quadruple Write Read Read 0 Magic
// double (64 bits), syntax: %0 %1 = %2, %3%4
//===----------------------------------------------------------------------===//
class ALU_QWRR0_M_Inst<string mnemonic, list<dag> pattern,
                       InstrItinClass itin = ALU_LITE_X>
    : LVXInst64<(outs GPR128:$rM), (ins GPR128:$rP, wimm32:$imm, splat32:$splat32),
                !strconcat(mnemonic, " $rM = $rP, $imm${splat32}"),
                pattern, itin> {
  bits<5>  rM;
  bits<5>  rP;
  bits<32> imm;
  bits<1>  splat32;
  let Inst{23-19}  = rM;
  let Inst{5-1}    = rP;
  let Inst{58-32}  = imm{31-5};
  let Inst{10-6}   = imm{4-0};
  let Inst{11}     = splat32;
  let Inst{62-61}  = 0b00;
  let Inst{31-28}  = 0b1110;
  let Inst{17-12}  = 0b100001;
  let Inst{0}      = 0b1;
}

def ADDQ_QWRR0_M           : ALU_QWRR0_M_Inst<"addq", []> {
  let Inst{27-24}  = 0b0010;
}
def SBFQ_QWRR0_M           : ALU_QWRR0_M_Inst<"sbfq", []> {
  let Inst{27-24}  = 0b0011;
}
def ANDQ_QWRR0_M           : ALU_QWRR0_M_Inst<"andq", []> {
  let Inst{27-24}  = 0b1000;
}
def NANDQ_QWRR0_M          : ALU_QWRR0_M_Inst<"nandq", []> {
  let Inst{27-24}  = 0b1001;
}
def IORQ_QWRR0_M           : ALU_QWRR0_M_Inst<"iorq", []> {
  let Inst{27-24}  = 0b1010;
}
def NIORQ_QWRR0_M          : ALU_QWRR0_M_Inst<"niorq", []> {
  let Inst{27-24}  = 0b1011;
}
def EORQ_QWRR0_M           : ALU_QWRR0_M_Inst<"eorq", []> {
  let Inst{27-24}  = 0b1100;
}
def NEORQ_QWRR0_M          : ALU_QWRR0_M_Inst<"neorq", []> {
  let Inst{27-24}  = 0b1101;
}
def ANDNQ_QWRR0_M          : ALU_QWRR0_M_Inst<"andnq", []> {
  let Inst{27-24}  = 0b1110;
}
def IORNQ_QWRR0_M          : ALU_QWRR0_M_Inst<"iornq", []> {
  let Inst{27-24}  = 0b1111;
}

//===----------------------------------------------------------------------===//
// ALU_DWRR0 — ALU Double Write Read Read 0
// simple (32 bits), syntax: %0 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_DWRR0_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin = ALU_TINY>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, GPR:$rY),
                !strconcat(mnemonic, " $rW = $rZ, $rY"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<6>  rY;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = rY;
  let Inst{30-28}  = 0b110;
  let Inst{17-12}  = 0b100000;
}

def ADDD_DWRR0             : ALU_DWRR0_Inst<"addd", []> {
  let Inst{27-24}  = 0b0010;
}
def SBFD_DWRR0             : ALU_DWRR0_Inst<"sbfd", []> {
  let Inst{27-24}  = 0b0011;
}
def MIND_DWRR0             : ALU_DWRR0_Inst<"mind", []> {
  let Inst{27-24}  = 0b0100;
}
def MAXD_DWRR0             : ALU_DWRR0_Inst<"maxd", []> {
  let Inst{27-24}  = 0b0101;
}
def MINUD_DWRR0            : ALU_DWRR0_Inst<"minud", []> {
  let Inst{27-24}  = 0b0110;
}
def MAXUD_DWRR0            : ALU_DWRR0_Inst<"maxud", []> {
  let Inst{27-24}  = 0b0111;
}
def ANDD_DWRR0             : ALU_DWRR0_Inst<"andd", []> {
  let Inst{27-24}  = 0b1000;
}
def NANDD_DWRR0            : ALU_DWRR0_Inst<"nandd", []> {
  let Inst{27-24}  = 0b1001;
}
def IORD_DWRR0             : ALU_DWRR0_Inst<"iord", []> {
  let Inst{27-24}  = 0b1010;
}
def NIORD_DWRR0            : ALU_DWRR0_Inst<"niord", []> {
  let Inst{27-24}  = 0b1011;
}
def EORD_DWRR0             : ALU_DWRR0_Inst<"eord", []> {
  let Inst{27-24}  = 0b1100;
}
def NEORD_DWRR0            : ALU_DWRR0_Inst<"neord", []> {
  let Inst{27-24}  = 0b1101;
}
def ANDND_DWRR0            : ALU_DWRR0_Inst<"andnd", []> {
  let Inst{27-24}  = 0b1110;
}
def IORND_DWRR0            : ALU_DWRR0_Inst<"iornd", []> {
  let Inst{27-24}  = 0b1111;
}
def SIGND_DWRR0            : ALU_DWRR0_Inst<"signd", []> {
  let Inst{27-24}  = 0b0000;
}
def SIGNSD_DWRR0           : ALU_DWRR0_Inst<"signsd", []> {
  let Inst{27-24}  = 0b0001;
}

//===----------------------------------------------------------------------===//
// ALU_DWRR0.M — ALU Double Write Read Read 0 Magic
// double (64 bits), syntax: %0 %1 = %2, %3%4
//===----------------------------------------------------------------------===//
class ALU_DWRR0_M_Inst<string mnemonic, list<dag> pattern,
                       InstrItinClass itin = ALU_TINY_X>
    : LVXInst64<(outs GPR:$rW), (ins GPR:$rZ, wimm32:$imm, splat32:$splat32),
                !strconcat(mnemonic, " $rW = $rZ, $imm${splat32}"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<32> imm;
  bits<1>  splat32;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{58-32}  = imm{31-5};
  let Inst{10-6}   = imm{4-0};
  let Inst{11}     = splat32;
  let Inst{62-61}  = 0b00;
  let Inst{31-28}  = 0b1110;
  let Inst{17-12}  = 0b100000;
}

def ADDD_DWRR0_M           : ALU_DWRR0_M_Inst<"addd", []> {
  let Inst{27-24}  = 0b0010;
}
def SBFD_DWRR0_M           : ALU_DWRR0_M_Inst<"sbfd", []> {
  let Inst{27-24}  = 0b0011;
}
def MIND_DWRR0_M           : ALU_DWRR0_M_Inst<"mind", []> {
  let Inst{27-24}  = 0b0100;
}
def MAXD_DWRR0_M           : ALU_DWRR0_M_Inst<"maxd", []> {
  let Inst{27-24}  = 0b0101;
}
def MINUD_DWRR0_M          : ALU_DWRR0_M_Inst<"minud", []> {
  let Inst{27-24}  = 0b0110;
}
def MAXUD_DWRR0_M          : ALU_DWRR0_M_Inst<"maxud", []> {
  let Inst{27-24}  = 0b0111;
}
def ANDD_DWRR0_M           : ALU_DWRR0_M_Inst<"andd", []> {
  let Inst{27-24}  = 0b1000;
}
def NANDD_DWRR0_M          : ALU_DWRR0_M_Inst<"nandd", []> {
  let Inst{27-24}  = 0b1001;
}
def IORD_DWRR0_M           : ALU_DWRR0_M_Inst<"iord", []> {
  let Inst{27-24}  = 0b1010;
}
def NIORD_DWRR0_M          : ALU_DWRR0_M_Inst<"niord", []> {
  let Inst{27-24}  = 0b1011;
}
def EORD_DWRR0_M           : ALU_DWRR0_M_Inst<"eord", []> {
  let Inst{27-24}  = 0b1100;
}
def NEORD_DWRR0_M          : ALU_DWRR0_M_Inst<"neord", []> {
  let Inst{27-24}  = 0b1101;
}
def ANDND_DWRR0_M          : ALU_DWRR0_M_Inst<"andnd", []> {
  let Inst{27-24}  = 0b1110;
}
def IORND_DWRR0_M          : ALU_DWRR0_M_Inst<"iornd", []> {
  let Inst{27-24}  = 0b1111;
}
def SIGND_DWRR0_M          : ALU_DWRR0_M_Inst<"signd", []> {
  let Inst{27-24}  = 0b0000;
}
def SIGNSD_DWRR0_M         : ALU_DWRR0_M_Inst<"signsd", []> {
  let Inst{27-24}  = 0b0001;
}

//===----------------------------------------------------------------------===//
// ALU_DWRI — ALU Double Word Write Read Immediate
// simple (32 bits), syntax: %0 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_DWRI_Inst<string mnemonic, list<dag> pattern,
                    InstrItinClass itin = ALU_TINY>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, simm10:$imm),
                !strconcat(mnemonic, " $rW = $rZ, $imm"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<10> imm;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{15-6}   = imm;
  let Inst{30-28}  = 0b110;
  let Inst{17-16}  = 0b00;
}

def ADDD_DWRI              : ALU_DWRI_Inst<"addd", []> {
  let Inst{27-24}  = 0b0010;
}
def SBFD_DWRI              : ALU_DWRI_Inst<"sbfd", []> {
  let Inst{27-24}  = 0b0011;
}
def MIND_DWRI              : ALU_DWRI_Inst<"mind", []> {
  let Inst{27-24}  = 0b0100;
}
def MAXD_DWRI              : ALU_DWRI_Inst<"maxd", []> {
  let Inst{27-24}  = 0b0101;
}
def MINUD_DWRI             : ALU_DWRI_Inst<"minud", []> {
  let Inst{27-24}  = 0b0110;
}
def MAXUD_DWRI             : ALU_DWRI_Inst<"maxud", []> {
  let Inst{27-24}  = 0b0111;
}
def ANDD_DWRI              : ALU_DWRI_Inst<"andd", []> {
  let Inst{27-24}  = 0b1000;
}
def NANDD_DWRI             : ALU_DWRI_Inst<"nandd", []> {
  let Inst{27-24}  = 0b1001;
}
def IORD_DWRI              : ALU_DWRI_Inst<"iord", []> {
  let Inst{27-24}  = 0b1010;
}
def NIORD_DWRI             : ALU_DWRI_Inst<"niord", []> {
  let Inst{27-24}  = 0b1011;
}
def EORD_DWRI              : ALU_DWRI_Inst<"eord", []> {
  let Inst{27-24}  = 0b1100;
}
def NEORD_DWRI             : ALU_DWRI_Inst<"neord", []> {
  let Inst{27-24}  = 0b1101;
}
def ANDND_DWRI             : ALU_DWRI_Inst<"andnd", []> {
  let Inst{27-24}  = 0b1110;
}
def IORND_DWRI             : ALU_DWRI_Inst<"iornd", []> {
  let Inst{27-24}  = 0b1111;
}
def COPYD_DWRI             : ALU_DWRI_Inst<"copyd", []> {
  let Inst{27-24}  = 0b1010;
  let Inst{15-6}   = 0b0000000000;
}

//===----------------------------------------------------------------------===//
// ALU_DWRI.X — ALU Double Word Write Read Immediate Extended
// double (64 bits), syntax: %0 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_DWRI_X_Inst<string mnemonic, list<dag> pattern,
                      InstrItinClass itin = ALU_TINY_X>
    : LVXInst64<(outs GPR:$rW), (ins GPR:$rZ, simm37:$imm),
                !strconcat(mnemonic, " $rW = $rZ, $imm"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<37> imm;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{58-32}  = imm{36-10};
  let Inst{15-6}   = imm{9-0};
  let Inst{62-61}  = 0b00;
  let Inst{31-28}  = 0b1110;
  let Inst{17-16}  = 0b00;
}

def ADDD_DWRI_X            : ALU_DWRI_X_Inst<"addd", []> {
  let Inst{27-24}  = 0b0010;
}
def SBFD_DWRI_X            : ALU_DWRI_X_Inst<"sbfd", []> {
  let Inst{27-24}  = 0b0011;
}
def MIND_DWRI_X            : ALU_DWRI_X_Inst<"mind", []> {
  let Inst{27-24}  = 0b0100;
}
def MAXD_DWRI_X            : ALU_DWRI_X_Inst<"maxd", []> {
  let Inst{27-24}  = 0b0101;
}
def MINUD_DWRI_X           : ALU_DWRI_X_Inst<"minud", []> {
  let Inst{27-24}  = 0b0110;
}
def MAXUD_DWRI_X           : ALU_DWRI_X_Inst<"maxud", []> {
  let Inst{27-24}  = 0b0111;
}
def ANDD_DWRI_X            : ALU_DWRI_X_Inst<"andd", []> {
  let Inst{27-24}  = 0b1000;
}
def NANDD_DWRI_X           : ALU_DWRI_X_Inst<"nandd", []> {
  let Inst{27-24}  = 0b1001;
}
def IORD_DWRI_X            : ALU_DWRI_X_Inst<"iord", []> {
  let Inst{27-24}  = 0b1010;
}
def NIORD_DWRI_X           : ALU_DWRI_X_Inst<"niord", []> {
  let Inst{27-24}  = 0b1011;
}
def EORD_DWRI_X            : ALU_DWRI_X_Inst<"eord", []> {
  let Inst{27-24}  = 0b1100;
}
def NEORD_DWRI_X           : ALU_DWRI_X_Inst<"neord", []> {
  let Inst{27-24}  = 0b1101;
}
def ANDND_DWRI_X           : ALU_DWRI_X_Inst<"andnd", []> {
  let Inst{27-24}  = 0b1110;
}
def IORND_DWRI_X           : ALU_DWRI_X_Inst<"iornd", []> {
  let Inst{27-24}  = 0b1111;
}

//===----------------------------------------------------------------------===//
// ALU_DWRI.Y — ALU Double Word Write Read Immediate Extended Extended
// triple (96 bits), syntax: %0 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_DWRI_Y_Inst<string mnemonic, list<dag> pattern,
                      InstrItinClass itin = ALU_TINY_Y>
    : LVXInst96<(outs GPR:$rW), (ins GPR:$rZ, wimm64:$imm),
                !strconcat(mnemonic, " $rW = $rZ, $imm"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<64> imm;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{90-64}  = imm{63-37};
  let Inst{58-32}  = imm{36-10};
  let Inst{15-6}   = imm{9-0};
  let Inst{94-93}  = 0b00;
  let Inst{63-61}  = 0b100;
  let Inst{31-28}  = 0b1110;
  let Inst{17-16}  = 0b00;
}

def ADDD_DWRI_Y            : ALU_DWRI_Y_Inst<"addd", []> {
  let Inst{27-24}  = 0b0010;
}
def SBFD_DWRI_Y            : ALU_DWRI_Y_Inst<"sbfd", []> {
  let Inst{27-24}  = 0b0011;
}
def MIND_DWRI_Y            : ALU_DWRI_Y_Inst<"mind", []> {
  let Inst{27-24}  = 0b0100;
}
def MAXD_DWRI_Y            : ALU_DWRI_Y_Inst<"maxd", []> {
  let Inst{27-24}  = 0b0101;
}
def MINUD_DWRI_Y           : ALU_DWRI_Y_Inst<"minud", []> {
  let Inst{27-24}  = 0b0110;
}
def MAXUD_DWRI_Y           : ALU_DWRI_Y_Inst<"maxud", []> {
  let Inst{27-24}  = 0b0111;
}
def ANDD_DWRI_Y            : ALU_DWRI_Y_Inst<"andd", []> {
  let Inst{27-24}  = 0b1000;
}
def NANDD_DWRI_Y           : ALU_DWRI_Y_Inst<"nandd", []> {
  let Inst{27-24}  = 0b1001;
}
def IORD_DWRI_Y            : ALU_DWRI_Y_Inst<"iord", []> {
  let Inst{27-24}  = 0b1010;
}
def NIORD_DWRI_Y           : ALU_DWRI_Y_Inst<"niord", []> {
  let Inst{27-24}  = 0b1011;
}
def EORD_DWRI_Y            : ALU_DWRI_Y_Inst<"eord", []> {
  let Inst{27-24}  = 0b1100;
}
def NEORD_DWRI_Y           : ALU_DWRI_Y_Inst<"neord", []> {
  let Inst{27-24}  = 0b1101;
}
def ANDND_DWRI_Y           : ALU_DWRI_Y_Inst<"andnd", []> {
  let Inst{27-24}  = 0b1110;
}
def IORND_DWRI_Y           : ALU_DWRI_Y_Inst<"iornd", []> {
  let Inst{27-24}  = 0b1111;
}

//===----------------------------------------------------------------------===//
// ALU_WWRR0 — ALU Word Write Read Read 0
// simple (32 bits), syntax: %0%4 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_WWRR0_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin = ALU_TINY>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, GPR:$rY, signextw:$signextw),
                !strconcat(mnemonic, "${signextw} $rW = $rZ, $rY"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<6>  rY;
  bits<1>  signextw;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = rY;
  let Inst{12}     = signextw;
  let Inst{30-28}  = 0b110;
  let Inst{17-13}  = 0b11000;
}

def ADDW_WWRR0             : ALU_WWRR0_Inst<"addw", []> {
  let Inst{27-24}  = 0b0010;
}
def SBFW_WWRR0             : ALU_WWRR0_Inst<"sbfw", []> {
  let Inst{27-24}  = 0b0011;
}
def MINW_WWRR0             : ALU_WWRR0_Inst<"minw", []> {
  let Inst{27-24}  = 0b0100;
}
def MAXW_WWRR0             : ALU_WWRR0_Inst<"maxw", []> {
  let Inst{27-24}  = 0b0101;
}
def MINUW_WWRR0            : ALU_WWRR0_Inst<"minuw", []> {
  let Inst{27-24}  = 0b0110;
}
def MAXUW_WWRR0            : ALU_WWRR0_Inst<"maxuw", []> {
  let Inst{27-24}  = 0b0111;
}
def ANDW_WWRR0             : ALU_WWRR0_Inst<"andw", []> {
  let Inst{27-24}  = 0b1000;
}
def NANDW_WWRR0            : ALU_WWRR0_Inst<"nandw", []> {
  let Inst{27-24}  = 0b1001;
}
def IORW_WWRR0             : ALU_WWRR0_Inst<"iorw", []> {
  let Inst{27-24}  = 0b1010;
}
def NIORW_WWRR0            : ALU_WWRR0_Inst<"niorw", []> {
  let Inst{27-24}  = 0b1011;
}
def EORW_WWRR0             : ALU_WWRR0_Inst<"eorw", []> {
  let Inst{27-24}  = 0b1100;
}
def NEORW_WWRR0            : ALU_WWRR0_Inst<"neorw", []> {
  let Inst{27-24}  = 0b1101;
}
def ANDNW_WWRR0            : ALU_WWRR0_Inst<"andnw", []> {
  let Inst{27-24}  = 0b1110;
}
def IORNW_WWRR0            : ALU_WWRR0_Inst<"iornw", []> {
  let Inst{27-24}  = 0b1111;
}
def SIGNW_WWRR0            : ALU_WWRR0_Inst<"signw", []> {
  let Inst{27-24}  = 0b0000;
}
def SIGNSW_WWRR0           : ALU_WWRR0_Inst<"signsw", []> {
  let Inst{27-24}  = 0b0001;
}

//===----------------------------------------------------------------------===//
// ALU_WWRR0.W — ALU Word Write Read Read 0 Wrapped
// double (64 bits), syntax: %0%4 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_WWRR0_W_Inst<string mnemonic, list<dag> pattern,
                       InstrItinClass itin = ALU_TINY_X>
    : LVXInst64<(outs GPR:$rW), (ins GPR:$rZ, wimm32:$imm, signextw:$signextw),
                !strconcat(mnemonic, "${signextw} $rW = $rZ, $imm"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<32> imm;
  bits<1>  signextw;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{58-32}  = imm{31-5};
  let Inst{10-6}   = imm{4-0};
  let Inst{12}     = signextw;
  let Inst{62-61}  = 0b00;
  let Inst{31-28}  = 0b1110;
  let Inst{17-13}  = 0b11000;
  let Inst{11}     = 0b0;
}

def ADDW_WWRR0_W           : ALU_WWRR0_W_Inst<"addw", []> {
  let Inst{27-24}  = 0b0010;
}
def SBFW_WWRR0_W           : ALU_WWRR0_W_Inst<"sbfw", []> {
  let Inst{27-24}  = 0b0011;
}
def MINW_WWRR0_W           : ALU_WWRR0_W_Inst<"minw", []> {
  let Inst{27-24}  = 0b0100;
}
def MAXW_WWRR0_W           : ALU_WWRR0_W_Inst<"maxw", []> {
  let Inst{27-24}  = 0b0101;
}
def MINUW_WWRR0_W          : ALU_WWRR0_W_Inst<"minuw", []> {
  let Inst{27-24}  = 0b0110;
}
def MAXUW_WWRR0_W          : ALU_WWRR0_W_Inst<"maxuw", []> {
  let Inst{27-24}  = 0b0111;
}
def ANDW_WWRR0_W           : ALU_WWRR0_W_Inst<"andw", []> {
  let Inst{27-24}  = 0b1000;
}
def NANDW_WWRR0_W          : ALU_WWRR0_W_Inst<"nandw", []> {
  let Inst{27-24}  = 0b1001;
}
def IORW_WWRR0_W           : ALU_WWRR0_W_Inst<"iorw", []> {
  let Inst{27-24}  = 0b1010;
}
def NIORW_WWRR0_W          : ALU_WWRR0_W_Inst<"niorw", []> {
  let Inst{27-24}  = 0b1011;
}
def EORW_WWRR0_W           : ALU_WWRR0_W_Inst<"eorw", []> {
  let Inst{27-24}  = 0b1100;
}
def NEORW_WWRR0_W          : ALU_WWRR0_W_Inst<"neorw", []> {
  let Inst{27-24}  = 0b1101;
}
def ANDNW_WWRR0_W          : ALU_WWRR0_W_Inst<"andnw", []> {
  let Inst{27-24}  = 0b1110;
}
def IORNW_WWRR0_W          : ALU_WWRR0_W_Inst<"iornw", []> {
  let Inst{27-24}  = 0b1111;
}
def SIGNW_WWRR0_W          : ALU_WWRR0_W_Inst<"signw", []> {
  let Inst{27-24}  = 0b0000;
}
def SIGNSW_WWRR0_W         : ALU_WWRR0_W_Inst<"signsw", []> {
  let Inst{27-24}  = 0b0001;
}

//===----------------------------------------------------------------------===//
// ALU_DWRR1 — ALU Double Write Read Read 1
// simple (32 bits), syntax: %0 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_DWRR1_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin = ALU_TINY>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, GPR:$rY),
                !strconcat(mnemonic, " $rW = $rZ, $rY"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<6>  rY;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = rY;
  let Inst{30-28}  = 0b110;
  let Inst{17-12}  = 0b101010;
}

def ADDSD_DWRR1            : ALU_DWRR1_Inst<"addsd", []> {
  let Inst{27-24}  = 0b1000;
}
def ADDUSD_DWRR1           : ALU_DWRR1_Inst<"addusd", []> {
  let Inst{27-24}  = 0b1010;
}
def SBFSD_DWRR1            : ALU_DWRR1_Inst<"sbfsd", []> {
  let Inst{27-24}  = 0b1001;
}
def SBFUSD_DWRR1           : ALU_DWRR1_Inst<"sbfusd", []> {
  let Inst{27-24}  = 0b1011;
}
def ADDX2D_DWRR1           : ALU_DWRR1_Inst<"addx2d", []> {
  let Inst{27-24}  = 0b0000;
}
def ADDX4D_DWRR1           : ALU_DWRR1_Inst<"addx4d", []> {
  let Inst{27-24}  = 0b0001;
}
def ADDX8D_DWRR1           : ALU_DWRR1_Inst<"addx8d", []> {
  let Inst{27-24}  = 0b0010;
}
def ADDX16D_DWRR1          : ALU_DWRR1_Inst<"addx16d", []> {
  let Inst{27-24}  = 0b0011;
}
def ADDX32D_DWRR1          : ALU_DWRR1_Inst<"addx32d", []> {
  let Inst{27-24}  = 0b0100;
}
def ADDX64D_DWRR1          : ALU_DWRR1_Inst<"addx64d", []> {
  let Inst{27-24}  = 0b0101;
}

//===----------------------------------------------------------------------===//
// ALU_DWRR1.M — ALU Double Write Read Read 1 Magic
// double (64 bits), syntax: %0 %1 = %2, %3%4
//===----------------------------------------------------------------------===//
class ALU_DWRR1_M_Inst<string mnemonic, list<dag> pattern,
                       InstrItinClass itin = ALU_TINY_X>
    : LVXInst64<(outs GPR:$rW), (ins GPR:$rZ, wimm32:$imm, splat32:$splat32),
                !strconcat(mnemonic, " $rW = $rZ, $imm${splat32}"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<32> imm;
  bits<1>  splat32;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{58-32}  = imm{31-5};
  let Inst{10-6}   = imm{4-0};
  let Inst{11}     = splat32;
  let Inst{62-61}  = 0b00;
  let Inst{31-28}  = 0b1110;
  let Inst{17-12}  = 0b101010;
}

def ADDSD_DWRR1_M          : ALU_DWRR1_M_Inst<"addsd", []> {
  let Inst{27-24}  = 0b1000;
}
def ADDUSD_DWRR1_M         : ALU_DWRR1_M_Inst<"addusd", []> {
  let Inst{27-24}  = 0b1010;
}
def SBFSD_DWRR1_M          : ALU_DWRR1_M_Inst<"sbfsd", []> {
  let Inst{27-24}  = 0b1001;
}
def SBFUSD_DWRR1_M         : ALU_DWRR1_M_Inst<"sbfusd", []> {
  let Inst{27-24}  = 0b1011;
}
def ADDX2D_DWRR1_M         : ALU_DWRR1_M_Inst<"addx2d", []> {
  let Inst{27-24}  = 0b0000;
}
def ADDX4D_DWRR1_M         : ALU_DWRR1_M_Inst<"addx4d", []> {
  let Inst{27-24}  = 0b0001;
}
def ADDX8D_DWRR1_M         : ALU_DWRR1_M_Inst<"addx8d", []> {
  let Inst{27-24}  = 0b0010;
}
def ADDX16D_DWRR1_M        : ALU_DWRR1_M_Inst<"addx16d", []> {
  let Inst{27-24}  = 0b0011;
}
def ADDX32D_DWRR1_M        : ALU_DWRR1_M_Inst<"addx32d", []> {
  let Inst{27-24}  = 0b0100;
}
def ADDX64D_DWRR1_M        : ALU_DWRR1_M_Inst<"addx64d", []> {
  let Inst{27-24}  = 0b0101;
}

//===----------------------------------------------------------------------===//
// ALU_WWRR1 — ALU Word Write Read Read 1
// simple (32 bits), syntax: %0%4 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_WWRR1_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin = ALU_TINY>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, GPR:$rY, signextw:$signextw),
                !strconcat(mnemonic, "${signextw} $rW = $rZ, $rY"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<6>  rY;
  bits<1>  signextw;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = rY;
  let Inst{12}     = signextw;
  let Inst{30-28}  = 0b110;
  let Inst{17-13}  = 0b11101;
}

def ADDSW_WWRR1            : ALU_WWRR1_Inst<"addsw", []> {
  let Inst{27-24}  = 0b1000;
}
def ADDUSW_WWRR1           : ALU_WWRR1_Inst<"addusw", []> {
  let Inst{27-24}  = 0b1010;
}
def SBFSW_WWRR1            : ALU_WWRR1_Inst<"sbfsw", []> {
  let Inst{27-24}  = 0b1001;
}
def SBFUSW_WWRR1           : ALU_WWRR1_Inst<"sbfusw", []> {
  let Inst{27-24}  = 0b1011;
}
def ADDX2W_WWRR1           : ALU_WWRR1_Inst<"addx2w", []> {
  let Inst{27-24}  = 0b0000;
}
def ADDX4W_WWRR1           : ALU_WWRR1_Inst<"addx4w", []> {
  let Inst{27-24}  = 0b0001;
}
def ADDX8W_WWRR1           : ALU_WWRR1_Inst<"addx8w", []> {
  let Inst{27-24}  = 0b0010;
}
def ADDX16W_WWRR1          : ALU_WWRR1_Inst<"addx16w", []> {
  let Inst{27-24}  = 0b0011;
}
def ADDX32W_WWRR1          : ALU_WWRR1_Inst<"addx32w", []> {
  let Inst{27-24}  = 0b0100;
}
def ADDX64W_WWRR1          : ALU_WWRR1_Inst<"addx64w", []> {
  let Inst{27-24}  = 0b0101;
}

//===----------------------------------------------------------------------===//
// ALU_WWRR1.W — ALU Word Write Read Read 1 Wrapped
// double (64 bits), syntax: %0%4 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_WWRR1_W_Inst<string mnemonic, list<dag> pattern,
                       InstrItinClass itin = ALU_TINY_X>
    : LVXInst64<(outs GPR:$rW), (ins GPR:$rZ, wimm32:$imm, signextw:$signextw),
                !strconcat(mnemonic, "${signextw} $rW = $rZ, $imm"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<32> imm;
  bits<1>  signextw;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{58-32}  = imm{31-5};
  let Inst{10-6}   = imm{4-0};
  let Inst{12}     = signextw;
  let Inst{62-61}  = 0b00;
  let Inst{31-28}  = 0b1110;
  let Inst{17-13}  = 0b11101;
  let Inst{11}     = 0b0;
}

def ADDSW_WWRR1_W          : ALU_WWRR1_W_Inst<"addsw", []> {
  let Inst{27-24}  = 0b1000;
}
def ADDUSW_WWRR1_W         : ALU_WWRR1_W_Inst<"addusw", []> {
  let Inst{27-24}  = 0b1010;
}
def SBFSW_WWRR1_W          : ALU_WWRR1_W_Inst<"sbfsw", []> {
  let Inst{27-24}  = 0b1001;
}
def SBFUSW_WWRR1_W         : ALU_WWRR1_W_Inst<"sbfusw", []> {
  let Inst{27-24}  = 0b1011;
}
def ADDX2W_WWRR1_W         : ALU_WWRR1_W_Inst<"addx2w", []> {
  let Inst{27-24}  = 0b0000;
}
def ADDX4W_WWRR1_W         : ALU_WWRR1_W_Inst<"addx4w", []> {
  let Inst{27-24}  = 0b0001;
}
def ADDX8W_WWRR1_W         : ALU_WWRR1_W_Inst<"addx8w", []> {
  let Inst{27-24}  = 0b0010;
}
def ADDX16W_WWRR1_W        : ALU_WWRR1_W_Inst<"addx16w", []> {
  let Inst{27-24}  = 0b0011;
}
def ADDX32W_WWRR1_W        : ALU_WWRR1_W_Inst<"addx32w", []> {
  let Inst{27-24}  = 0b0100;
}
def ADDX64W_WWRR1_W        : ALU_WWRR1_W_Inst<"addx64w", []> {
  let Inst{27-24}  = 0b0101;
}

//===----------------------------------------------------------------------===//
// ALU_DSWRI — ALU Double Shift Rotate Write Read Immediate
// simple (32 bits), syntax: %0 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_DSWRI_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, uimm6:$imm),
                !strconcat(mnemonic, " $rW = $rZ, $imm"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<6>  imm;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = imm;
  let Inst{30-27}  = 0b1101;
  let Inst{17-12}  = 0b101000;
}

def SRLD_DSWRI             : ALU_DSWRI_Inst<"srld", [], ALU_TINY> {
  let Inst{26-24}  = 0b011;
}
def SRAD_DSWRI             : ALU_DSWRI_Inst<"srad", [], ALU_TINY> {
  let Inst{26-24}  = 0b010;
}
def SRSD_DSWRI             : ALU_DSWRI_Inst<"srsd", [], ALU_LITE> {
  let Inst{26-24}  = 0b000;
}
def SLLD_DSWRI             : ALU_DSWRI_Inst<"slld", [], ALU_TINY> {
  let Inst{26-24}  = 0b001;
}
def SLSD_DSWRI             : ALU_DSWRI_Inst<"slsd", [], ALU_LITE> {
  let Inst{26-24}  = 0b100;
}
def SLUSD_DSWRI            : ALU_DSWRI_Inst<"slusd", [], ALU_LITE> {
  let Inst{26-24}  = 0b101;
}
def ROLD_DSWRI             : ALU_DSWRI_Inst<"rold", [], ALU_TINY> {
  let Inst{26-24}  = 0b110;
}
def RORD_DSWRI             : ALU_DSWRI_Inst<"rord", [], ALU_TINY> {
  let Inst{26-24}  = 0b111;
}

//===----------------------------------------------------------------------===//
// ALU_DSWRR — ALU Double Shift Rotate Write Read Read
// simple (32 bits), syntax: %0 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_DSWRR_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, GPR:$rY),
                !strconcat(mnemonic, " $rW = $rZ, $rY"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<6>  rY;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = rY;
  let Inst{30-27}  = 0b1100;
  let Inst{17-12}  = 0b101000;
}

def SRLD_DSWRR             : ALU_DSWRR_Inst<"srld", [], ALU_TINY> {
  let Inst{26-24}  = 0b011;
}
def SRAD_DSWRR             : ALU_DSWRR_Inst<"srad", [], ALU_TINY> {
  let Inst{26-24}  = 0b010;
}
def SRSD_DSWRR             : ALU_DSWRR_Inst<"srsd", [], ALU_LITE> {
  let Inst{26-24}  = 0b000;
}
def SLLD_DSWRR             : ALU_DSWRR_Inst<"slld", [], ALU_TINY> {
  let Inst{26-24}  = 0b001;
}
def SLSD_DSWRR             : ALU_DSWRR_Inst<"slsd", [], ALU_LITE> {
  let Inst{26-24}  = 0b100;
}
def SLUSD_DSWRR            : ALU_DSWRR_Inst<"slusd", [], ALU_LITE> {
  let Inst{26-24}  = 0b101;
}
def ROLD_DSWRR             : ALU_DSWRR_Inst<"rold", [], ALU_TINY> {
  let Inst{26-24}  = 0b110;
}
def RORD_DSWRR             : ALU_DSWRR_Inst<"rord", [], ALU_TINY> {
  let Inst{26-24}  = 0b111;
}

//===----------------------------------------------------------------------===//
// ALU_WSWRR — ALU Word Shift Rotate Write Read Read
// simple (32 bits), syntax: %0%4 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_WSWRR_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, GPR:$rY, signextw:$signextw),
                !strconcat(mnemonic, "${signextw} $rW = $rZ, $rY"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<6>  rY;
  bits<1>  signextw;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = rY;
  let Inst{12}     = signextw;
  let Inst{30-27}  = 0b1100;
  let Inst{17-13}  = 0b11100;
}

def SRLW_WSWRR             : ALU_WSWRR_Inst<"srlw", [], ALU_TINY> {
  let Inst{26-24}  = 0b011;
}
def SRAW_WSWRR             : ALU_WSWRR_Inst<"sraw", [], ALU_TINY> {
  let Inst{26-24}  = 0b010;
}
def SRSW_WSWRR             : ALU_WSWRR_Inst<"srsw", [], ALU_LITE> {
  let Inst{26-24}  = 0b000;
}
def SLLW_WSWRR             : ALU_WSWRR_Inst<"sllw", [], ALU_TINY> {
  let Inst{26-24}  = 0b001;
}
def SLSW_WSWRR             : ALU_WSWRR_Inst<"slsw", [], ALU_LITE> {
  let Inst{26-24}  = 0b100;
}
def SLUSW_WSWRR            : ALU_WSWRR_Inst<"slusw", [], ALU_LITE> {
  let Inst{26-24}  = 0b101;
}
def ROLW_WSWRR             : ALU_WSWRR_Inst<"rolw", [], ALU_TINY> {
  let Inst{26-24}  = 0b110;
}
def RORW_WSWRR             : ALU_WSWRR_Inst<"rorw", [], ALU_TINY> {
  let Inst{26-24}  = 0b111;
}

//===----------------------------------------------------------------------===//
// ALU_WSWRI — ALU Word Shift Rotate Write Read Immediate
// simple (32 bits), syntax: %0%4 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_WSWRI_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, uimm6:$imm, signextw:$signextw),
                !strconcat(mnemonic, "${signextw} $rW = $rZ, $imm"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<6>  imm;
  bits<1>  signextw;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = imm;
  let Inst{12}     = signextw;
  let Inst{30-27}  = 0b1101;
  let Inst{17-13}  = 0b11100;
}

def SRLW_WSWRI             : ALU_WSWRI_Inst<"srlw", [], ALU_TINY> {
  let Inst{26-24}  = 0b011;
}
def SRAW_WSWRI             : ALU_WSWRI_Inst<"sraw", [], ALU_TINY> {
  let Inst{26-24}  = 0b010;
}
def SRSW_WSWRI             : ALU_WSWRI_Inst<"srsw", [], ALU_LITE> {
  let Inst{26-24}  = 0b000;
}
def SLLW_WSWRI             : ALU_WSWRI_Inst<"sllw", [], ALU_TINY> {
  let Inst{26-24}  = 0b001;
}
def SLSW_WSWRI             : ALU_WSWRI_Inst<"slsw", [], ALU_LITE> {
  let Inst{26-24}  = 0b100;
}
def SLUSW_WSWRI            : ALU_WSWRI_Inst<"slusw", [], ALU_LITE> {
  let Inst{26-24}  = 0b101;
}
def ROLW_WSWRI             : ALU_WSWRI_Inst<"rolw", [], ALU_TINY> {
  let Inst{26-24}  = 0b110;
}
def RORW_WSWRI             : ALU_WSWRI_Inst<"rorw", [], ALU_TINY> {
  let Inst{26-24}  = 0b111;
}
def COPYW_WSWRI            : ALU_WSWRI_Inst<"copyw", [], ALU_TINY> {
  let Inst{26-24}  = 0b001;
  let Inst{11-6}   = 0b000000;
}

//===----------------------------------------------------------------------===//
// ALU_DBMWRR — ALU Bit Matrix Multiply Write Read Read
// simple (32 bits), syntax: %0 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_DBMWRR_Inst<string mnemonic, list<dag> pattern,
                      InstrItinClass itin = ALU_TINY>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, GPR:$rY),
                !strconcat(mnemonic, " $rW = $rZ, $rY"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<6>  rY;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = rY;
  let Inst{30-25}  = 0b110111;
  let Inst{17-12}  = 0b100010;
}

def SBMM8D_DBMWRR          : ALU_DBMWRR_Inst<"sbmm8d", []> {
  let Inst{24}     = 0b0;
}
def SBMMT8D_DBMWRR         : ALU_DBMWRR_Inst<"sbmmt8d", []> {
  let Inst{24}     = 0b1;
}
def SBMM8_DBMWRR           : ALU_DBMWRR_Inst<"sbmm8", []> {
  let Inst{24}     = 0b0;
}
def SBMMT8_DBMWRR          : ALU_DBMWRR_Inst<"sbmmt8", []> {
  let Inst{24}     = 0b1;
}

//===----------------------------------------------------------------------===//
// ALU_DBMWRR.M — ALU Bit Matrix Multiply Write Read Read Magic
// double (64 bits), syntax: %0 %1 = %2, %3%4
//===----------------------------------------------------------------------===//
class ALU_DBMWRR_M_Inst<string mnemonic, list<dag> pattern,
                        InstrItinClass itin = ALU_TINY_X>
    : LVXInst64<(outs GPR:$rW), (ins GPR:$rZ, wimm32:$imm, splat32:$splat32),
                !strconcat(mnemonic, " $rW = $rZ, $imm${splat32}"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<32> imm;
  bits<1>  splat32;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{58-32}  = imm{31-5};
  let Inst{10-6}   = imm{4-0};
  let Inst{11}     = splat32;
  let Inst{62-61}  = 0b00;
  let Inst{31-25}  = 0b1110111;
  let Inst{17-12}  = 0b100010;
}

def SBMM8D_DBMWRR_M        : ALU_DBMWRR_M_Inst<"sbmm8d", []> {
  let Inst{24}     = 0b0;
}
def SBMMT8D_DBMWRR_M       : ALU_DBMWRR_M_Inst<"sbmmt8d", []> {
  let Inst{24}     = 0b1;
}
def SBMM8_DBMWRR_M         : ALU_DBMWRR_M_Inst<"sbmm8", []> {
  let Inst{24}     = 0b0;
}
def SBMMT8_DBMWRR_M        : ALU_DBMWRR_M_Inst<"sbmmt8", []> {
  let Inst{24}     = 0b1;
}

//===----------------------------------------------------------------------===//
// ALU_DBMWRI — ALU Double Word Bit Matrix Multiply Immediate
// simple (32 bits), syntax: %0 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_DBMWRI_Inst<string mnemonic, list<dag> pattern,
                      InstrItinClass itin = ALU_TINY>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, simm10:$imm),
                !strconcat(mnemonic, " $rW = $rZ, $imm"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<10> imm;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{15-6}   = imm;
  let Inst{30-25}  = 0b110111;
  let Inst{17-16}  = 0b01;
}

def SBMM8D_DBMWRI          : ALU_DBMWRI_Inst<"sbmm8d", []> {
  let Inst{24}     = 0b0;
}
def SBMMT8D_DBMWRI         : ALU_DBMWRI_Inst<"sbmmt8d", []> {
  let Inst{24}     = 0b1;
}
def SBMM8_DBMWRI           : ALU_DBMWRI_Inst<"sbmm8", []> {
  let Inst{24}     = 0b0;
}
def SBMMT8_DBMWRI          : ALU_DBMWRI_Inst<"sbmmt8", []> {
  let Inst{24}     = 0b1;
}

//===----------------------------------------------------------------------===//
// ALU_DBMWRI.X — ALU Double Word Bit Matrix Multiply Immediate Extended
// double (64 bits), syntax: %0 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_DBMWRI_X_Inst<string mnemonic, list<dag> pattern,
                        InstrItinClass itin = ALU_TINY_X>
    : LVXInst64<(outs GPR:$rW), (ins GPR:$rZ, simm37:$imm),
                !strconcat(mnemonic, " $rW = $rZ, $imm"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<37> imm;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{58-32}  = imm{36-10};
  let Inst{15-6}   = imm{9-0};
  let Inst{62-61}  = 0b00;
  let Inst{31-25}  = 0b1110111;
  let Inst{17-16}  = 0b01;
}

def SBMM8D_DBMWRI_X        : ALU_DBMWRI_X_Inst<"sbmm8d", []> {
  let Inst{24}     = 0b0;
}
def SBMMT8D_DBMWRI_X       : ALU_DBMWRI_X_Inst<"sbmmt8d", []> {
  let Inst{24}     = 0b1;
}
def SBMM8_DBMWRI_X         : ALU_DBMWRI_X_Inst<"sbmm8", []> {
  let Inst{24}     = 0b0;
}
def SBMMT8_DBMWRI_X        : ALU_DBMWRI_X_Inst<"sbmmt8", []> {
  let Inst{24}     = 0b1;
}

//===----------------------------------------------------------------------===//
// ALU_DBMWRI.Y — ALU Double Word Bit Matrix Multiply Immediate Extended Extended
// triple (96 bits), syntax: %0 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_DBMWRI_Y_Inst<string mnemonic, list<dag> pattern,
                        InstrItinClass itin = ALU_TINY_Y>
    : LVXInst96<(outs GPR:$rW), (ins GPR:$rZ, wimm64:$imm),
                !strconcat(mnemonic, " $rW = $rZ, $imm"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<64> imm;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{90-64}  = imm{63-37};
  let Inst{58-32}  = imm{36-10};
  let Inst{15-6}   = imm{9-0};
  let Inst{94-93}  = 0b00;
  let Inst{63-61}  = 0b100;
  let Inst{31-25}  = 0b1110111;
  let Inst{17-16}  = 0b01;
}

def SBMM8D_DBMWRI_Y        : ALU_DBMWRI_Y_Inst<"sbmm8d", []> {
  let Inst{24}     = 0b0;
}
def SBMMT8D_DBMWRI_Y       : ALU_DBMWRI_Y_Inst<"sbmmt8d", []> {
  let Inst{24}     = 0b1;
}
def SBMM8_DBMWRI_Y         : ALU_DBMWRI_Y_Inst<"sbmm8", []> {
  let Inst{24}     = 0b0;
}
def SBMMT8_DBMWRI_Y        : ALU_DBMWRI_Y_Inst<"sbmmt8", []> {
  let Inst{24}     = 0b1;
}

//===----------------------------------------------------------------------===//
// ALU_DBMWRRR — ALU Bit Matrix Multiply EOR Write Read Read
// simple (32 bits), syntax: %0 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_DBMWRRR_Inst<string mnemonic, list<dag> pattern,
                       InstrItinClass itin = ALU_TINY>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rWsrc, GPR:$rZ, GPR:$rY),
                !strconcat(mnemonic, " $rW = $rZ, $rY"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<6>  rY;
  let Constraints = "$rWsrc = $rW";
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = rY;
  let Inst{30-25}  = 0b110110;
  let Inst{17-12}  = 0b100010;
}

def SBMM8EORD_DBMWRRR      : ALU_DBMWRRR_Inst<"sbmm8eord", []> {
  let Inst{24}     = 0b0;
}
def SBMMT8EORD_DBMWRRR     : ALU_DBMWRRR_Inst<"sbmmt8eord", []> {
  let Inst{24}     = 0b1;
}

//===----------------------------------------------------------------------===//
// ALU_DBMWRRR.M — ALU Bit Matrix Multiply EOR Write Read Read Magic
// double (64 bits), syntax: %0 %1 = %2, %3%4
//===----------------------------------------------------------------------===//
class ALU_DBMWRRR_M_Inst<string mnemonic, list<dag> pattern,
                         InstrItinClass itin = ALU_TINY_X>
    : LVXInst64<(outs GPR:$rW), (ins GPR:$rWsrc, GPR:$rZ, wimm32:$imm, splat32:$splat32),
                !strconcat(mnemonic, " $rW = $rZ, $imm${splat32}"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<32> imm;
  bits<1>  splat32;
  let Constraints = "$rWsrc = $rW";
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{58-32}  = imm{31-5};
  let Inst{10-6}   = imm{4-0};
  let Inst{11}     = splat32;
  let Inst{62-61}  = 0b00;
  let Inst{31-25}  = 0b1110110;
  let Inst{17-12}  = 0b100010;
}

def SBMM8EORD_DBMWRRR_M    : ALU_DBMWRRR_M_Inst<"sbmm8eord", []> {
  let Inst{24}     = 0b0;
}
def SBMMT8EORD_DBMWRRR_M   : ALU_DBMWRRR_M_Inst<"sbmmt8eord", []> {
  let Inst{24}     = 0b1;
}

//===----------------------------------------------------------------------===//
// ALU_WAVG — ALU Word Average
// simple (32 bits), syntax: %0%4 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_WAVG_Inst<string mnemonic, list<dag> pattern,
                    InstrItinClass itin = ALU_TINY>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, GPR:$rY, signextw:$signextw),
                !strconcat(mnemonic, "${signextw} $rW = $rZ, $rY"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<6>  rY;
  bits<1>  signextw;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = rY;
  let Inst{12}     = signextw;
  let Inst{30-26}  = 0b11011;
  let Inst{17-13}  = 0b11001;
}

def AVGW_WAVG              : ALU_WAVG_Inst<"avgw", []> {
  let Inst{25-24}  = 0b00;
}
def AVGUW_WAVG             : ALU_WAVG_Inst<"avguw", []> {
  let Inst{25-24}  = 0b01;
}
def AVGRW_WAVG             : ALU_WAVG_Inst<"avgrw", []> {
  let Inst{25-24}  = 0b10;
}
def AVGRUW_WAVG            : ALU_WAVG_Inst<"avgruw", []> {
  let Inst{25-24}  = 0b11;
}

//===----------------------------------------------------------------------===//
// ALU_WAVG.W — ALU Word Average Wrapped
// double (64 bits), syntax: %0%4 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_WAVG_W_Inst<string mnemonic, list<dag> pattern,
                      InstrItinClass itin = ALU_TINY_X>
    : LVXInst64<(outs GPR:$rW), (ins GPR:$rZ, wimm32:$imm, signextw:$signextw),
                !strconcat(mnemonic, "${signextw} $rW = $rZ, $imm"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<32> imm;
  bits<1>  signextw;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{58-32}  = imm{31-5};
  let Inst{10-6}   = imm{4-0};
  let Inst{12}     = signextw;
  let Inst{62-61}  = 0b00;
  let Inst{31-26}  = 0b111011;
  let Inst{17-13}  = 0b11001;
  let Inst{11}     = 0b0;
}

def AVGW_WAVG_W            : ALU_WAVG_W_Inst<"avgw", []> {
  let Inst{25-24}  = 0b00;
}
def AVGUW_WAVG_W           : ALU_WAVG_W_Inst<"avguw", []> {
  let Inst{25-24}  = 0b01;
}
def AVGRW_WAVG_W           : ALU_WAVG_W_Inst<"avgrw", []> {
  let Inst{25-24}  = 0b10;
}
def AVGRUW_WAVG_W          : ALU_WAVG_W_Inst<"avgruw", []> {
  let Inst{25-24}  = 0b11;
}

//===----------------------------------------------------------------------===//
// ALU_DWRR2 — ALU Double Word Write Read Read 2
// simple (32 bits), syntax: %0 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_DWRR2_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin = ALU_TINY>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, GPR:$rY),
                !strconcat(mnemonic, " $rW = $rZ, $rY"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<6>  rY;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = rY;
  let Inst{30-26}  = 0b11000;
  let Inst{17-12}  = 0b100100;
}

def LANDD_DWRR2            : ALU_DWRR2_Inst<"landd", []> {
  let Inst{25-24}  = 0b00;
}
def LNANDD_DWRR2           : ALU_DWRR2_Inst<"lnandd", []> {
  let Inst{25-24}  = 0b01;
}
def LIORD_DWRR2            : ALU_DWRR2_Inst<"liord", []> {
  let Inst{25-24}  = 0b10;
}
def LNIORD_DWRR2           : ALU_DWRR2_Inst<"lniord", []> {
  let Inst{25-24}  = 0b11;
}

//===----------------------------------------------------------------------===//
// ALU_WWRR2 — ALU Word Write Read Read 2
// simple (32 bits), syntax: %0 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_WWRR2_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin = ALU_TINY>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, GPR:$rY),
                !strconcat(mnemonic, " $rW = $rZ, $rY"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<6>  rY;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = rY;
  let Inst{30-26}  = 0b11000;
  let Inst{17-12}  = 0b110100;
}

def LANDW_WWRR2            : ALU_WWRR2_Inst<"landw", []> {
  let Inst{25-24}  = 0b00;
}
def LNANDW_WWRR2           : ALU_WWRR2_Inst<"lnandw", []> {
  let Inst{25-24}  = 0b01;
}
def LIORW_WWRR2            : ALU_WWRR2_Inst<"liorw", []> {
  let Inst{25-24}  = 0b10;
}
def LNIORW_WWRR2           : ALU_WWRR2_Inst<"lniorw", []> {
  let Inst{25-24}  = 0b11;
}

//===----------------------------------------------------------------------===//
// ALU_FDMO1 — ALU Floating-Point Double Word Operations 1
// simple (32 bits), syntax: %0 %1 = %2
//===----------------------------------------------------------------------===//
class ALU_FDMO1_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin = ALU_LITE>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ),
                !strconcat(mnemonic, " $rW = $rZ"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{30-24}  = 0b1111111;
  let Inst{17-11}  = 0b0000000;
  let Inst{6}      = 0b0;
}

def FNEGD_FDMO1            : ALU_FDMO1_Inst<"fnegd", []> {
  let Inst{10-8}   = 0b010;
}
def FABSD_FDMO1            : ALU_FDMO1_Inst<"fabsd", []> {
  let Inst{10-8}   = 0b011;
}
def FSRECD_FDMO1           : ALU_FDMO1_Inst<"fsrecd", []> {
  let Inst{10-8}   = 0b100;
}
def FSRSRD_FDMO1           : ALU_FDMO1_Inst<"fsrsrd", []> {
  let Inst{10-8}   = 0b101;
}
def FCLASSD_FDMO1          : ALU_FDMO1_Inst<"fclassd", []> {
  let Inst{10-8}   = 0b110;
}

//===----------------------------------------------------------------------===//
// ALU_FWMO1 — ALU Floating-Point Word Operations 1
// simple (32 bits), syntax: %0 %1 = %2
//===----------------------------------------------------------------------===//
class ALU_FWMO1_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin = ALU_LITE>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ),
                !strconcat(mnemonic, " $rW = $rZ"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{30-24}  = 0b1111111;
  let Inst{17-11}  = 0b0100000;
  let Inst{6}      = 0b0;
}

def FNEGW_FWMO1            : ALU_FWMO1_Inst<"fnegw", []> {
  let Inst{10-8}   = 0b010;
}
def FABSW_FWMO1            : ALU_FWMO1_Inst<"fabsw", []> {
  let Inst{10-8}   = 0b011;
}
def FSRECW_FWMO1           : ALU_FWMO1_Inst<"fsrecw", []> {
  let Inst{10-8}   = 0b100;
}
def FSRSRW_FWMO1           : ALU_FWMO1_Inst<"fsrsrw", []> {
  let Inst{10-8}   = 0b101;
}
def FCLASSW_FWMO1          : ALU_FWMO1_Inst<"fclassw", []> {
  let Inst{10-8}   = 0b110;
}

//===----------------------------------------------------------------------===//
// ALU_FWPMO1 — ALU Floating-Point Word Pair Operations 1
// simple (32 bits), syntax: %0 %1 = %2
//===----------------------------------------------------------------------===//
class ALU_FWPMO1_Inst<string mnemonic, list<dag> pattern,
                      InstrItinClass itin = ALU_LITE>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ),
                !strconcat(mnemonic, " $rW = $rZ"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{30-24}  = 0b1111111;
  let Inst{17-11}  = 0b0000010;
  let Inst{6}      = 0b0;
}

def FNEGWP_FWPMO1          : ALU_FWPMO1_Inst<"fnegwp", []> {
  let Inst{10-8}   = 0b010;
}
def FABSWP_FWPMO1          : ALU_FWPMO1_Inst<"fabswp", []> {
  let Inst{10-8}   = 0b011;
}
def FSRECWP_FWPMO1         : ALU_FWPMO1_Inst<"fsrecwp", []> {
  let Inst{10-8}   = 0b100;
}
def FSRSRWP_FWPMO1         : ALU_FWPMO1_Inst<"fsrsrwp", []> {
  let Inst{10-8}   = 0b101;
}
def FCLASSWP_FWPMO1        : ALU_FWPMO1_Inst<"fclasswp", []> {
  let Inst{10-8}   = 0b110;
}

//===----------------------------------------------------------------------===//
// ALU_FHMO1 — ALU Floating-Point Half Word Monadic 1
// simple (32 bits), syntax: %0 %1 = %2
//===----------------------------------------------------------------------===//
class ALU_FHMO1_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin = ALU_LITE>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ),
                !strconcat(mnemonic, " $rW = $rZ"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{30-24}  = 0b1111111;
  let Inst{17-11}  = 0b0100010;
  let Inst{9}      = 0b1;
  let Inst{6}      = 0b0;
}

def FNEGH_FHMO1            : ALU_FHMO1_Inst<"fnegh", []> {
  let Inst{10}     = 0b0;
  let Inst{8}      = 0b0;
}
def FABSH_FHMO1            : ALU_FHMO1_Inst<"fabsh", []> {
  let Inst{10}     = 0b0;
  let Inst{8}      = 0b1;
}
def FCLASSH_FHMO1          : ALU_FHMO1_Inst<"fclassh", []> {
  let Inst{10}     = 0b1;
  let Inst{8}      = 0b0;
}

//===----------------------------------------------------------------------===//
// ALU_FDWIDEN — ALU Floating-Point Double Word Widen from Word
// simple (32 bits), syntax: %0%3 %1 = %2
//===----------------------------------------------------------------------===//
class ALU_FDWIDEN_Inst<string mnemonic, list<dag> pattern,
                       InstrItinClass itin = ALU_LITE>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, mostsig:$mostsig),
                !strconcat(mnemonic, "${mostsig} $rW = $rZ"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<1>  mostsig;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{7}      = mostsig;
  let Inst{30-24}  = 0b1111111;
  let Inst{17-8}   = 0b0000001000;
  let Inst{6}      = 0b0;
}

def FWIDENWD_FDWIDEN       : ALU_FDWIDEN_Inst<"fwidenwd", []>;

//===----------------------------------------------------------------------===//
// ALU_FWWIDEN — ALU Floating-Point Word Widen from Half Word
// simple (32 bits), syntax: %0%3 %1 = %2
//===----------------------------------------------------------------------===//
class ALU_FWWIDEN_Inst<string mnemonic, list<dag> pattern,
                       InstrItinClass itin = ALU_LITE>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, mostsig:$mostsig),
                !strconcat(mnemonic, "${mostsig} $rW = $rZ"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<1>  mostsig;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{7}      = mostsig;
  let Inst{30-24}  = 0b1111111;
  let Inst{17-8}   = 0b0100001000;
  let Inst{6}      = 0b0;
}

def FWIDENHW_FWWIDEN       : ALU_FWWIDEN_Inst<"fwidenhw", []>;

//===----------------------------------------------------------------------===//
// ALU_FWPWIDEN — ALU Floating-Point Double Word Widen from Word
// simple (32 bits), syntax: %0%3 %1 = %2
//===----------------------------------------------------------------------===//
class ALU_FWPWIDEN_Inst<string mnemonic, list<dag> pattern,
                        InstrItinClass itin = ALU_LITE>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, mostsig:$mostsig),
                !strconcat(mnemonic, "${mostsig} $rW = $rZ"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<1>  mostsig;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{7}      = mostsig;
  let Inst{30-24}  = 0b1111111;
  let Inst{17-8}   = 0b0000011000;
  let Inst{6}      = 0b0;
}

def FWIDENHWP_FWPWIDEN     : ALU_FWPWIDEN_Inst<"fwidenhwp", []>;

//===----------------------------------------------------------------------===//
// ALU_FWWR — ALU Floating-Point Word Write Read
// simple (32 bits), syntax: %0%3 %1 = %2
//===----------------------------------------------------------------------===//
class ALU_FWWR_Inst<string mnemonic, list<dag> pattern,
                    InstrItinClass itin = ALU_LITE>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, floatmode:$floatmode),
                !strconcat(mnemonic, "${floatmode} $rW = $rZ"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<3>  floatmode;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{26-24}  = floatmode;
  let Inst{30-27}  = 0b1111;
  let Inst{17-8}   = 0b0100101100;
  let Inst{6}      = 0b0;
}

def FNARROWDW_FWWR         : ALU_FWWR_Inst<"fnarrowdw", []>;

//===----------------------------------------------------------------------===//
// ALU_FHWR — ALU Floating-Point Half Word Write Read
// simple (32 bits), syntax: %0%3 %1 = %2
//===----------------------------------------------------------------------===//
class ALU_FHWR_Inst<string mnemonic, list<dag> pattern,
                    InstrItinClass itin = ALU_LITE>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, floatmode:$floatmode),
                !strconcat(mnemonic, "${floatmode} $rW = $rZ"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<3>  floatmode;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{26-24}  = floatmode;
  let Inst{30-27}  = 0b1111;
  let Inst{17-8}   = 0b0100111100;
  let Inst{6}      = 0b0;
}

def FNARROWWH_FHWR         : ALU_FHWR_Inst<"fnarrowwh", []>;

//===----------------------------------------------------------------------===//
// ALU_BFWR — ALU Bit Field Write Read
// simple (32 bits), syntax: %0 %1 = %2, %3, %4
// One of 2 classes for this format: its instructions do not all
// read and write the same operands, so they cannot share an operand list.
// This one covers INSF_BFWR.
//===----------------------------------------------------------------------===//
class ALU_BFWR_Inst<string mnemonic, list<dag> pattern,
                    InstrItinClass itin = ALU_TINY>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rWsrc, GPR:$rZ, uimm6:$stopbit, uimm6:$startbit),
                !strconcat(mnemonic, " $rW = $rZ, $stopbit, $startbit"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<6>  stopbit;
  bits<6>  startbit;
  let Constraints = "$rWsrc = $rW";
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{25-24}  = stopbit{5-4};
  let Inst{15-12}  = stopbit{3-0};
  let Inst{11-6}   = startbit;
  let Inst{30-26}  = 0b11000;
  let Inst{17-16}  = 0b01;
}

def INSF_BFWR              : ALU_BFWR_Inst<"insf", []>;

//===----------------------------------------------------------------------===//
// ALU_BFWR — ALU Bit Field Write Read
// simple (32 bits), syntax: %0 %1 = %2, %3, %4
// One of 2 classes for this format: its instructions do not all
// read and write the same operands, so they cannot share an operand list.
// This one covers EXTFZ_BFWR, EXTFS_BFWR, ZXBD_BFWR, SXBD_BFWR, ZXHD_BFWR, SXHD_BFWR, ZXWD_BFWR, SXWD_BFWR.
//===----------------------------------------------------------------------===//
class ALU_BFWR_2_Inst<string mnemonic, list<dag> pattern,
                      InstrItinClass itin = ALU_TINY>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, uimm6:$stopbit, uimm6:$startbit),
                !strconcat(mnemonic, " $rW = $rZ, $stopbit, $startbit"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<6>  stopbit;
  bits<6>  startbit;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{25-24}  = stopbit{5-4};
  let Inst{15-12}  = stopbit{3-0};
  let Inst{11-6}   = startbit;
  let Inst{30-28}  = 0b110;
  let Inst{17-16}  = 0b01;
}

def EXTFZ_BFWR             : ALU_BFWR_2_Inst<"extfz", []> {
  let Inst{27-26}  = 0b01;
}
def EXTFS_BFWR             : ALU_BFWR_2_Inst<"extfs", []> {
  let Inst{27-26}  = 0b10;
}
def ZXBD_BFWR              : ALU_BFWR_2_Inst<"zxbd", []> {
  let Inst{27-24}  = 0b0100;
  let Inst{15-6}   = 0b0111000000;
}
def SXBD_BFWR              : ALU_BFWR_2_Inst<"sxbd", []> {
  let Inst{27-24}  = 0b1000;
  let Inst{15-6}   = 0b0111000000;
}
def ZXHD_BFWR              : ALU_BFWR_2_Inst<"zxhd", []> {
  let Inst{27-24}  = 0b0100;
  let Inst{15-6}   = 0b1111000000;
}
def SXHD_BFWR              : ALU_BFWR_2_Inst<"sxhd", []> {
  let Inst{27-24}  = 0b1000;
  let Inst{15-6}   = 0b1111000000;
}
def ZXWD_BFWR              : ALU_BFWR_2_Inst<"zxwd", []> {
  let Inst{27-24}  = 0b0101;
  let Inst{15-6}   = 0b1111000000;
}
def SXWD_BFWR              : ALU_BFWR_2_Inst<"sxwd", []> {
  let Inst{27-24}  = 0b1001;
  let Inst{15-6}   = 0b1111000000;
}

//===----------------------------------------------------------------------===//
// ALU_QCWRR — ALU Double Word Comparison Write Read Read
// simple (32 bits), syntax: %0%4 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_QCWRR_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin = ALU_LITE>
    : LVXInst32<(outs GPR128:$rM), (ins GPR128:$rP, GPR128:$rO, intcomp:$intcomp),
                !strconcat(mnemonic, "${intcomp} $rM = $rP, $rO"),
                pattern, itin> {
  bits<5>  rM;
  bits<5>  rP;
  bits<5>  rO;
  bits<4>  intcomp;
  let Inst{23-19}  = rM;
  let Inst{5-1}    = rP;
  let Inst{11-7}   = rO;
  let Inst{27-24}  = intcomp;
  let Inst{30-28}  = 0b110;
  let Inst{17-12}  = 0b100011;
}

def COMPQ_QCWRR            : ALU_QCWRR_Inst<"compq", []>;

//===----------------------------------------------------------------------===//
// ALU_DCWRR — ALU Double Comparison Write Read Read
// simple (32 bits), syntax: %0%4 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_DCWRR_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin = ALU_TINY>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, GPR:$rY, intcomp:$intcomp),
                !strconcat(mnemonic, "${intcomp} $rW = $rZ, $rY"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<6>  rY;
  bits<4>  intcomp;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = rY;
  let Inst{27-24}  = intcomp;
  let Inst{30-28}  = 0b110;
  let Inst{17-12}  = 0b100010;
}

def COMPD_DCWRR            : ALU_DCWRR_Inst<"compd", []>;

//===----------------------------------------------------------------------===//
// ALU_DCWRR.W — ALU Double Comparison Write Read Read Wrapped
// double (64 bits), syntax: %0%4 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_DCWRR_W_Inst<string mnemonic, list<dag> pattern,
                       InstrItinClass itin = ALU_TINY_X>
    : LVXInst64<(outs GPR:$rW), (ins GPR:$rZ, wimm32:$imm, intcomp:$intcomp),
                !strconcat(mnemonic, "${intcomp} $rW = $rZ, $imm"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<32> imm;
  bits<4>  intcomp;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{58-32}  = imm{31-5};
  let Inst{10-6}   = imm{4-0};
  let Inst{27-24}  = intcomp;
  let Inst{62-61}  = 0b00;
  let Inst{31-28}  = 0b1110;
  let Inst{17-11}  = 0b1000100;
}

def COMPD_DCWRR_W          : ALU_DCWRR_W_Inst<"compd", []>;

//===----------------------------------------------------------------------===//
// ALU_WCWRR — ALU Word Comparison Write Read Read
// simple (32 bits), syntax: %0%4%5 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_WCWRR_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin = ALU_TINY>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, GPR:$rY, intcomp:$intcomp, signextw:$signextw),
                !strconcat(mnemonic, "${intcomp}${signextw} $rW = $rZ, $rY"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<6>  rY;
  bits<4>  intcomp;
  bits<1>  signextw;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = rY;
  let Inst{27-24}  = intcomp;
  let Inst{12}     = signextw;
  let Inst{30-28}  = 0b110;
  let Inst{17-13}  = 0b11001;
}

def COMPW_WCWRR            : ALU_WCWRR_Inst<"compw", []>;

//===----------------------------------------------------------------------===//
// ALU_WCWRR.W — ALU Word Comparison Write Read Read Wrapped
// double (64 bits), syntax: %0%4%5 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_WCWRR_W_Inst<string mnemonic, list<dag> pattern,
                       InstrItinClass itin = ALU_TINY_X>
    : LVXInst64<(outs GPR:$rW), (ins GPR:$rZ, wimm32:$imm, intcomp:$intcomp, signextw:$signextw),
                !strconcat(mnemonic, "${intcomp}${signextw} $rW = $rZ, $imm"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<32> imm;
  bits<4>  intcomp;
  bits<1>  signextw;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{58-32}  = imm{31-5};
  let Inst{10-6}   = imm{4-0};
  let Inst{27-24}  = intcomp;
  let Inst{12}     = signextw;
  let Inst{62-61}  = 0b00;
  let Inst{31-28}  = 0b1110;
  let Inst{17-13}  = 0b11001;
  let Inst{11}     = 0b0;
}

def COMPW_WCWRR_W          : ALU_WCWRR_W_Inst<"compw", []>;

//===----------------------------------------------------------------------===//
// ALU_QCMWRR — ALU Quadruple Word Conditional Move Write Read Read
// simple (32 bits), syntax: %0%4 %2? %1 = %3
//===----------------------------------------------------------------------===//
class ALU_QCMWRR_Inst<string mnemonic, list<dag> pattern,
                      InstrItinClass itin = ALU_LITE>
    : LVXInst32<(outs GPR128:$rM), (ins GPR128:$rMsrc, GPR:$rZ, GPR128:$rO, bcucond:$bcucond),
                !strconcat(mnemonic, "${bcucond} $rZ? $rM = $rO"),
                pattern, itin> {
  bits<5>  rM;
  bits<6>  rZ;
  bits<5>  rO;
  bits<4>  bcucond;
  let Constraints = "$rMsrc = $rM";
  let Inst{23-19}  = rM;
  let Inst{5-0}    = rZ;
  let Inst{11-7}   = rO;
  let Inst{27-24}  = bcucond;
  let Inst{30-28}  = 0b110;
  let Inst{17-12}  = 0b100111;
}

def CMOVEQ_QCMWRR          : ALU_QCMWRR_Inst<"cmoveq", []>;

//===----------------------------------------------------------------------===//
// ALU_DCMWRR — ALU Double Word Conditional Move Write Read Read
// simple (32 bits), syntax: %0%4 %2? %1 = %3
//===----------------------------------------------------------------------===//
class ALU_DCMWRR_Inst<string mnemonic, list<dag> pattern,
                      InstrItinClass itin = ALU_LITE>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rWsrc, GPR:$rZ, GPR:$rY, bcucond:$bcucond),
                !strconcat(mnemonic, "${bcucond} $rZ? $rW = $rY"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<6>  rY;
  bits<4>  bcucond;
  let Constraints = "$rWsrc = $rW";
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = rY;
  let Inst{27-24}  = bcucond;
  let Inst{30-28}  = 0b110;
  let Inst{17-12}  = 0b100110;
}

def CMOVED_DCMWRR          : ALU_DCMWRR_Inst<"cmoved", []>;

//===----------------------------------------------------------------------===//
// ALU_DCMWRR.M — ALU Double Word Conditional Move Write Read Read Magic
// double (64 bits), syntax: %0%4 %2? %1 = %3%5
//===----------------------------------------------------------------------===//
class ALU_DCMWRR_M_Inst<string mnemonic, list<dag> pattern,
                        InstrItinClass itin = ALU_LITE_X>
    : LVXInst64<(outs GPR:$rW), (ins GPR:$rWsrc, GPR:$rZ, wimm32:$imm, bcucond:$bcucond, splat32:$splat32),
                !strconcat(mnemonic, "${bcucond} $rZ? $rW = $imm${splat32}"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<32> imm;
  bits<4>  bcucond;
  bits<1>  splat32;
  let Constraints = "$rWsrc = $rW";
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{58-32}  = imm{31-5};
  let Inst{10-6}   = imm{4-0};
  let Inst{27-24}  = bcucond;
  let Inst{11}     = splat32;
  let Inst{62-61}  = 0b00;
  let Inst{31-28}  = 0b1110;
  let Inst{17-12}  = 0b100110;
}

def CMOVED_DCMWRR_M        : ALU_DCMWRR_M_Inst<"cmoved", []>;

//===----------------------------------------------------------------------===//
// ALU_DWI — ALU Double Word from Immediate
// simple (32 bits), syntax: %0 %1 = %2
//===----------------------------------------------------------------------===//
class ALU_DWI_Inst<string mnemonic, list<dag> pattern,
                   InstrItinClass itin = ALU_TINY>
    : LVXInst32<(outs GPR:$rW), (ins simm16:$imm),
                !strconcat(mnemonic, " $rW = $imm"),
                pattern, itin> {
  bits<6>  rW;
  bits<16> imm;
  let Inst{23-18}  = rW;
  let Inst{15-0}   = imm;
  let Inst{30-25}  = 0b110000;
  let Inst{17-16}  = 0b00;
}

def MAKED_DWI              : ALU_DWI_Inst<"maked", []> {
  let Inst{24}     = 0b0;
}
def PCREL_DWI              : ALU_DWI_Inst<"pcrel", []> {
  let Inst{24}     = 0b1;
}

//===----------------------------------------------------------------------===//
// ALU_DWI.X — ALU Double Word from Immediate Extended
// double (64 bits), syntax: %0 %1 = %2
//===----------------------------------------------------------------------===//
class ALU_DWI_X_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin = ALU_TINY_X>
    : LVXInst64<(outs GPR:$rW), (ins simm43:$imm),
                !strconcat(mnemonic, " $rW = $imm"),
                pattern, itin> {
  bits<6>  rW;
  bits<43> imm;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = imm{42-37};
  let Inst{58-32}  = imm{36-10};
  let Inst{15-6}   = imm{9-0};
  let Inst{62-61}  = 0b00;
  let Inst{31-25}  = 0b1110000;
  let Inst{17-16}  = 0b00;
}

def MAKED_DWI_X            : ALU_DWI_X_Inst<"maked", []> {
  let Inst{24}     = 0b0;
}
def PCREL_DWI_X            : ALU_DWI_X_Inst<"pcrel", []> {
  let Inst{24}     = 0b1;
}

//===----------------------------------------------------------------------===//
// ALU_DWI.Y — ALU Double Word from Immediate Extended Extended
// triple (96 bits), syntax: %0 %1 = %2
//===----------------------------------------------------------------------===//
class ALU_DWI_Y_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin = ALU_TINY_Y>
    : LVXInst96<(outs GPR:$rW), (ins wimm64:$imm),
                !strconcat(mnemonic, " $rW = $imm"),
                pattern, itin> {
  bits<6>  rW;
  bits<64> imm;
  let Inst{23-18}  = rW;
  let Inst{90-64}  = imm{63-37};
  let Inst{58-32}  = imm{36-10};
  let Inst{15-6}   = imm{9-0};
  let Inst{94-93}  = 0b00;
  let Inst{63-61}  = 0b100;
  let Inst{31-25}  = 0b1110000;
  let Inst{17-16}  = 0b00;
}

def MAKED_DWI_Y            : ALU_DWI_Y_Inst<"maked", []> {
  let Inst{24}     = 0b0;
}
def PCREL_DWI_Y            : ALU_DWI_Y_Inst<"pcrel", []> {
  let Inst{24}     = 0b1;
}

//===----------------------------------------------------------------------===//
// ALU_QBWR — ALU Quadruple Word Bit Write Read
// simple (32 bits), syntax: %0 %1 = %2
//===----------------------------------------------------------------------===//
class ALU_QBWR_Inst<string mnemonic, list<dag> pattern,
                    InstrItinClass itin = ALU_LITE>
    : LVXInst32<(outs GPR128:$rM), (ins GPR128:$rP),
                !strconcat(mnemonic, " $rM = $rP"),
                pattern, itin> {
  bits<5>  rM;
  bits<5>  rP;
  let Inst{23-19}  = rM;
  let Inst{5-1}    = rP;
  let Inst{30-24}  = 0b1101111;
  let Inst{17-12}  = 0b101011;
  let Inst{10-6}   = 0b00000;
}

def NOTQ_QBWR              : ALU_QBWR_Inst<"notq", []> {
  let Inst{11}     = 0b1;
}
def NEGQ_QBWR              : ALU_QBWR_Inst<"negq", []> {
  let Inst{11}     = 0b0;
}

//===----------------------------------------------------------------------===//
// ALU_DBWR — ALU Double Word Bit Write Read
// simple (32 bits), syntax: %0 %1 = %2
//===----------------------------------------------------------------------===//
class ALU_DBWR_Inst<string mnemonic, list<dag> pattern,
                    InstrItinClass itin = ALU_TINY>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ),
                !strconcat(mnemonic, " $rW = $rZ"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{30-24}  = 0b1101111;
  let Inst{17-12}  = 0b101010;
  let Inst{7-6}    = 0b00;
}

def NOTD_DBWR              : ALU_DBWR_Inst<"notd", []> {
  let Inst{11-8}   = 0b1000;
}
def NEGD_DBWR              : ALU_DBWR_Inst<"negd", []> {
  let Inst{11-8}   = 0b0000;
}
def NEGSD_DBWR             : ALU_DBWR_Inst<"negsd", []> {
  let Inst{11-8}   = 0b0010;
}
def ABSD_DBWR              : ALU_DBWR_Inst<"absd", []> {
  let Inst{11-8}   = 0b0001;
}
def ABSSD_DBWR             : ALU_DBWR_Inst<"abssd", []> {
  let Inst{11-8}   = 0b0011;
}
def CLZD_DBWR              : ALU_DBWR_Inst<"clzd", []> {
  let Inst{11-8}   = 0b0100;
}
def CLSD_DBWR              : ALU_DBWR_Inst<"clsd", []> {
  let Inst{11-8}   = 0b0101;
}
def CBSD_DBWR              : ALU_DBWR_Inst<"cbsd", []> {
  let Inst{11-8}   = 0b0110;
}
def CTZD_DBWR              : ALU_DBWR_Inst<"ctzd", []> {
  let Inst{11-8}   = 0b0111;
}

//===----------------------------------------------------------------------===//
// ALU_BWRW — ALU Word Bit Write Read
// simple (32 bits), syntax: %0%3 %1 = %2
//===----------------------------------------------------------------------===//
class ALU_BWRW_Inst<string mnemonic, list<dag> pattern,
                    InstrItinClass itin = ALU_TINY>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, signextw:$signextw),
                !strconcat(mnemonic, "${signextw} $rW = $rZ"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<1>  signextw;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{12}     = signextw;
  let Inst{30-24}  = 0b1101111;
  let Inst{17-13}  = 0b11101;
  let Inst{7-6}    = 0b00;
}

def NOTW_BWRW              : ALU_BWRW_Inst<"notw", []> {
  let Inst{11-8}   = 0b1000;
}
def NEGW_BWRW              : ALU_BWRW_Inst<"negw", []> {
  let Inst{11-8}   = 0b0000;
}
def NEGSW_BWRW             : ALU_BWRW_Inst<"negsw", []> {
  let Inst{11-8}   = 0b0010;
}
def ABSW_BWRW              : ALU_BWRW_Inst<"absw", []> {
  let Inst{11-8}   = 0b0001;
}
def ABSSW_BWRW             : ALU_BWRW_Inst<"abssw", []> {
  let Inst{11-8}   = 0b0011;
}
def CLZW_BWRW              : ALU_BWRW_Inst<"clzw", []> {
  let Inst{11-8}   = 0b0100;
}
def CLSW_BWRW              : ALU_BWRW_Inst<"clsw", []> {
  let Inst{11-8}   = 0b0101;
}
def CBSW_BWRW              : ALU_BWRW_Inst<"cbsw", []> {
  let Inst{11-8}   = 0b0110;
}
def CTZW_BWRW              : ALU_BWRW_Inst<"ctzw", []> {
  let Inst{11-8}   = 0b0111;
}

//===----------------------------------------------------------------------===//
// ALU_FDCWRR — ALU Floating-Point Double Word Comparison Write Read Read
// simple (32 bits), syntax: %0%4 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_FDCWRR_Inst<string mnemonic, list<dag> pattern,
                      InstrItinClass itin = ALU_LITE>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, GPR:$rY, floatcomp:$floatcomp),
                !strconcat(mnemonic, "${floatcomp} $rW = $rZ, $rY"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<6>  rY;
  bits<3>  floatcomp;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = rY;
  let Inst{26-24}  = floatcomp;
  let Inst{30-27}  = 0b1110;
  let Inst{17-12}  = 0b000100;
}

def FCOMPD_FDCWRR          : ALU_FDCWRR_Inst<"fcompd", []>;

//===----------------------------------------------------------------------===//
// ALU_FDCWRR.W — ALU Floating-Point Double Word Comparison Write Read Read Wrapped
// double (64 bits), syntax: %0%4 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_FDCWRR_W_Inst<string mnemonic, list<dag> pattern,
                        InstrItinClass itin = ALU_LITE_X>
    : LVXInst64<(outs GPR:$rW), (ins GPR:$rZ, wimm32:$imm, floatcomp:$floatcomp),
                !strconcat(mnemonic, "${floatcomp} $rW = $rZ, $imm"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<32> imm;
  bits<3>  floatcomp;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{58-32}  = imm{31-5};
  let Inst{10-6}   = imm{4-0};
  let Inst{26-24}  = floatcomp;
  let Inst{62-61}  = 0b00;
  let Inst{31-27}  = 0b11110;
  let Inst{17-11}  = 0b0001000;
}

def FCOMPD_FDCWRR_W        : ALU_FDCWRR_W_Inst<"fcompd", []>;

//===----------------------------------------------------------------------===//
// ALU_FWCWRR — ALU Floating-Point Word Comparison Write Read Read
// simple (32 bits), syntax: %0%4 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_FWCWRR_Inst<string mnemonic, list<dag> pattern,
                      InstrItinClass itin = ALU_LITE>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, GPR:$rY, floatcomp:$floatcomp),
                !strconcat(mnemonic, "${floatcomp} $rW = $rZ, $rY"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<6>  rY;
  bits<3>  floatcomp;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = rY;
  let Inst{26-24}  = floatcomp;
  let Inst{30-27}  = 0b1110;
  let Inst{17-12}  = 0b010100;
}

def FCOMPW_FWCWRR          : ALU_FWCWRR_Inst<"fcompw", []>;

//===----------------------------------------------------------------------===//
// ALU_FWCWRR.W — ALU Floating-Point Word Comparison Write Read Read Wrapped
// double (64 bits), syntax: %0%4 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_FWCWRR_W_Inst<string mnemonic, list<dag> pattern,
                        InstrItinClass itin = ALU_LITE_X>
    : LVXInst64<(outs GPR:$rW), (ins GPR:$rZ, wimm32:$imm, floatcomp:$floatcomp),
                !strconcat(mnemonic, "${floatcomp} $rW = $rZ, $imm"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<32> imm;
  bits<3>  floatcomp;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{58-32}  = imm{31-5};
  let Inst{10-6}   = imm{4-0};
  let Inst{26-24}  = floatcomp;
  let Inst{62-61}  = 0b00;
  let Inst{31-27}  = 0b11110;
  let Inst{17-11}  = 0b0101000;
}

def FCOMPW_FWCWRR_W        : ALU_FWCWRR_W_Inst<"fcompw", []>;

//===----------------------------------------------------------------------===//
// ALU_FHCWRR — ALU Floating-Point Half Word Comparison Write Read Read
// simple (32 bits), syntax: %0%4 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_FHCWRR_Inst<string mnemonic, list<dag> pattern,
                      InstrItinClass itin = ALU_LITE>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, GPR:$rY, floatcomp:$floatcomp),
                !strconcat(mnemonic, "${floatcomp} $rW = $rZ, $rY"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<6>  rY;
  bits<3>  floatcomp;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = rY;
  let Inst{26-24}  = floatcomp;
  let Inst{30-27}  = 0b1110;
  let Inst{17-12}  = 0b010101;
}

def FCOMPH_FHCWRR          : ALU_FHCWRR_Inst<"fcomph", []>;

//===----------------------------------------------------------------------===//
// ALU_FHCWRR.W — ALU Floating-Point Half Word Comparison Write Read Read Wrapped
// double (64 bits), syntax: %0%4 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_FHCWRR_W_Inst<string mnemonic, list<dag> pattern,
                        InstrItinClass itin = ALU_LITE_X>
    : LVXInst64<(outs GPR:$rW), (ins GPR:$rZ, wimm32:$imm, floatcomp:$floatcomp),
                !strconcat(mnemonic, "${floatcomp} $rW = $rZ, $imm"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<32> imm;
  bits<3>  floatcomp;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{58-32}  = imm{31-5};
  let Inst{10-6}   = imm{4-0};
  let Inst{26-24}  = floatcomp;
  let Inst{62-61}  = 0b00;
  let Inst{31-27}  = 0b11110;
  let Inst{17-11}  = 0b0101010;
}

def FCOMPH_FHCWRR_W        : ALU_FHCWRR_W_Inst<"fcomph", []>;

//===----------------------------------------------------------------------===//
// ALU_FDMMWR — ALU Floating-Point Double Word Min/Max Write Read
// simple (32 bits), syntax: %0 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_FDMMWR_Inst<string mnemonic, list<dag> pattern,
                      InstrItinClass itin = ALU_LITE>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, GPR:$rY),
                !strconcat(mnemonic, " $rW = $rZ, $rY"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<6>  rY;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = rY;
  let Inst{30-27}  = 0b1111;
  let Inst{17-12}  = 0b000000;
}

def FMIND_FDMMWR           : ALU_FDMMWR_Inst<"fmind", []> {
  let Inst{26-24}  = 0b000;
}
def FMINND_FDMMWR          : ALU_FDMMWR_Inst<"fminnd", []> {
  let Inst{26-24}  = 0b010;
}
def FMAXD_FDMMWR           : ALU_FDMMWR_Inst<"fmaxd", []> {
  let Inst{26-24}  = 0b001;
}
def FMAXND_FDMMWR          : ALU_FDMMWR_Inst<"fmaxnd", []> {
  let Inst{26-24}  = 0b011;
}
def FSIGND_FDMMWR          : ALU_FDMMWR_Inst<"fsignd", []> {
  let Inst{26-24}  = 0b100;
}
def FSIGNND_FDMMWR         : ALU_FDMMWR_Inst<"fsignnd", []> {
  let Inst{26-24}  = 0b101;
}
def FSIGNMD_FDMMWR         : ALU_FDMMWR_Inst<"fsignmd", []> {
  let Inst{26-24}  = 0b110;
}

//===----------------------------------------------------------------------===//
// ALU_FWMMWR — ALU Floating Point Word Min/Max Write Read
// simple (32 bits), syntax: %0 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_FWMMWR_Inst<string mnemonic, list<dag> pattern,
                      InstrItinClass itin = ALU_LITE>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, GPR:$rY),
                !strconcat(mnemonic, " $rW = $rZ, $rY"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<6>  rY;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = rY;
  let Inst{30-27}  = 0b1111;
  let Inst{17-12}  = 0b010000;
}

def FMINW_FWMMWR           : ALU_FWMMWR_Inst<"fminw", []> {
  let Inst{26-24}  = 0b000;
}
def FMINNW_FWMMWR          : ALU_FWMMWR_Inst<"fminnw", []> {
  let Inst{26-24}  = 0b010;
}
def FMAXW_FWMMWR           : ALU_FWMMWR_Inst<"fmaxw", []> {
  let Inst{26-24}  = 0b001;
}
def FMAXNW_FWMMWR          : ALU_FWMMWR_Inst<"fmaxnw", []> {
  let Inst{26-24}  = 0b011;
}
def FSIGNW_FWMMWR          : ALU_FWMMWR_Inst<"fsignw", []> {
  let Inst{26-24}  = 0b100;
}
def FSIGNNW_FWMMWR         : ALU_FWMMWR_Inst<"fsignnw", []> {
  let Inst{26-24}  = 0b101;
}
def FSIGNMW_FWMMWR         : ALU_FWMMWR_Inst<"fsignmw", []> {
  let Inst{26-24}  = 0b110;
}

//===----------------------------------------------------------------------===//
// ALU_FHMMWR — ALU Floating Point Half Word Min/Max Write Read
// simple (32 bits), syntax: %0 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_FHMMWR_Inst<string mnemonic, list<dag> pattern,
                      InstrItinClass itin = ALU_LITE>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, GPR:$rY),
                !strconcat(mnemonic, " $rW = $rZ, $rY"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<6>  rY;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = rY;
  let Inst{30-27}  = 0b1111;
  let Inst{17-12}  = 0b010111;
}

def FMINH_FHMMWR           : ALU_FHMMWR_Inst<"fminh", []> {
  let Inst{26-24}  = 0b000;
}
def FMINNH_FHMMWR          : ALU_FHMMWR_Inst<"fminnh", []> {
  let Inst{26-24}  = 0b010;
}
def FMAXH_FHMMWR           : ALU_FHMMWR_Inst<"fmaxh", []> {
  let Inst{26-24}  = 0b001;
}
def FMAXNH_FHMMWR          : ALU_FHMMWR_Inst<"fmaxnh", []> {
  let Inst{26-24}  = 0b011;
}
def FSIGNH_FHMMWR          : ALU_FHMMWR_Inst<"fsignh", []> {
  let Inst{26-24}  = 0b100;
}
def FSIGNNH_FHMMWR         : ALU_FHMMWR_Inst<"fsignnh", []> {
  let Inst{26-24}  = 0b101;
}
def FSIGNMH_FHMMWR         : ALU_FHMMWR_Inst<"fsignmh", []> {
  let Inst{26-24}  = 0b110;
}

//===----------------------------------------------------------------------===//
// ALU_FDFLOAT — ALU Floating-Point Double Word Convert to Floating-Point
// simple (32 bits), syntax: %0%3 %1 = %2
//===----------------------------------------------------------------------===//
class ALU_FDFLOAT_Inst<string mnemonic, list<dag> pattern,
                       InstrItinClass itin = ALU_LITE>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, floatmode:$floatmode),
                !strconcat(mnemonic, "${floatmode} $rW = $rZ"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<3>  floatmode;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{26-24}  = floatmode;
  let Inst{30-27}  = 0b1111;
  let Inst{17-10}  = 0b00001000;
  let Inst{6}      = 0b0;
}

def FLOATD_FDFLOAT         : ALU_FDFLOAT_Inst<"floatd", []> {
  let Inst{9-8}    = 0b00;
}
def FLOATUD_FDFLOAT        : ALU_FDFLOAT_Inst<"floatud", []> {
  let Inst{9-8}    = 0b01;
}
def FLOATWD_FDFLOAT        : ALU_FDFLOAT_Inst<"floatwd", []> {
  let Inst{9-8}    = 0b10;
}
def FLOATUWD_FDFLOAT       : ALU_FDFLOAT_Inst<"floatuwd", []> {
  let Inst{9-8}    = 0b11;
}

//===----------------------------------------------------------------------===//
// ALU_FWFLOAT — ALU Floating-Point Word Convert to Floating-Point
// simple (32 bits), syntax: %0%3 %1 = %2
//===----------------------------------------------------------------------===//
class ALU_FWFLOAT_Inst<string mnemonic, list<dag> pattern,
                       InstrItinClass itin = ALU_LITE>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, floatmode:$floatmode),
                !strconcat(mnemonic, "${floatmode} $rW = $rZ"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<3>  floatmode;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{26-24}  = floatmode;
  let Inst{30-27}  = 0b1111;
  let Inst{17-10}  = 0b01001000;
  let Inst{6}      = 0b0;
}

def FLOATW_FWFLOAT         : ALU_FWFLOAT_Inst<"floatw", []> {
  let Inst{9-8}    = 0b00;
}
def FLOATUW_FWFLOAT        : ALU_FWFLOAT_Inst<"floatuw", []> {
  let Inst{9-8}    = 0b01;
}
def FLOATDW_FWFLOAT        : ALU_FWFLOAT_Inst<"floatdw", []> {
  let Inst{9-8}    = 0b10;
}
def FLOATUDW_FWFLOAT       : ALU_FWFLOAT_Inst<"floatudw", []> {
  let Inst{9-8}    = 0b11;
}

//===----------------------------------------------------------------------===//
// ALU_FWPFLOAT — ALU Floating-Point Word Pair Convert to Floating-Point
// simple (32 bits), syntax: %0%3 %1 = %2
//===----------------------------------------------------------------------===//
class ALU_FWPFLOAT_Inst<string mnemonic, list<dag> pattern,
                        InstrItinClass itin = ALU_LITE>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, floatmode:$floatmode),
                !strconcat(mnemonic, "${floatmode} $rW = $rZ"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<3>  floatmode;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{26-24}  = floatmode;
  let Inst{30-27}  = 0b1111;
  let Inst{17-9}   = 0b000011000;
  let Inst{6}      = 0b0;
}

def FLOATWP_FWPFLOAT       : ALU_FWPFLOAT_Inst<"floatwp", []> {
  let Inst{8}      = 0b0;
}
def FLOATUWP_FWPFLOAT      : ALU_FWPFLOAT_Inst<"floatuwp", []> {
  let Inst{8}      = 0b1;
}

//===----------------------------------------------------------------------===//
// ALU_FDFIXED — ALU Floating-Point Double Word Convert to Fixed-Point
// simple (32 bits), syntax: %0%3 %1 = %2
//===----------------------------------------------------------------------===//
class ALU_FDFIXED_Inst<string mnemonic, list<dag> pattern,
                       InstrItinClass itin = ALU_LITE>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, floatmode:$floatmode),
                !strconcat(mnemonic, "${floatmode} $rW = $rZ"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<3>  floatmode;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{26-24}  = floatmode;
  let Inst{30-27}  = 0b1111;
  let Inst{17-10}  = 0b00001001;
  let Inst{6}      = 0b0;
}

def FIXEDD_FDFIXED         : ALU_FDFIXED_Inst<"fixedd", []> {
  let Inst{9-8}    = 0b00;
}
def FIXEDUD_FDFIXED        : ALU_FDFIXED_Inst<"fixedud", []> {
  let Inst{9-8}    = 0b01;
}
def FIXEDWD_FDFIXED        : ALU_FDFIXED_Inst<"fixedwd", []> {
  let Inst{9-8}    = 0b10;
}
def FIXEDUWD_FDFIXED       : ALU_FDFIXED_Inst<"fixeduwd", []> {
  let Inst{9-8}    = 0b11;
}

//===----------------------------------------------------------------------===//
// ALU_FWFIXED — ALU Floating-Point Word Convert to Fixed-Point
// simple (32 bits), syntax: %0%3 %1 = %2
//===----------------------------------------------------------------------===//
class ALU_FWFIXED_Inst<string mnemonic, list<dag> pattern,
                       InstrItinClass itin = ALU_LITE>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, floatmode:$floatmode),
                !strconcat(mnemonic, "${floatmode} $rW = $rZ"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<3>  floatmode;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{26-24}  = floatmode;
  let Inst{30-27}  = 0b1111;
  let Inst{17-10}  = 0b01001001;
  let Inst{6}      = 0b0;
}

def FIXEDW_FWFIXED         : ALU_FWFIXED_Inst<"fixedw", []> {
  let Inst{9-8}    = 0b00;
}
def FIXEDUW_FWFIXED        : ALU_FWFIXED_Inst<"fixeduw", []> {
  let Inst{9-8}    = 0b01;
}
def FIXEDDW_FWFIXED        : ALU_FWFIXED_Inst<"fixeddw", []> {
  let Inst{9-8}    = 0b10;
}
def FIXEDUDW_FWFIXED       : ALU_FWFIXED_Inst<"fixedudw", []> {
  let Inst{9-8}    = 0b11;
}

//===----------------------------------------------------------------------===//
// ALU_FWPFIXED — ALU Floating-Point Word Pair Convert to Fixed-Point
// simple (32 bits), syntax: %0%3 %1 = %2
//===----------------------------------------------------------------------===//
class ALU_FWPFIXED_Inst<string mnemonic, list<dag> pattern,
                        InstrItinClass itin = ALU_LITE>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, floatmode:$floatmode),
                !strconcat(mnemonic, "${floatmode} $rW = $rZ"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<3>  floatmode;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{26-24}  = floatmode;
  let Inst{30-27}  = 0b1111;
  let Inst{17-9}   = 0b000011010;
  let Inst{6}      = 0b0;
}

def FIXEDWP_FWPFIXED       : ALU_FWPFIXED_Inst<"fixedwp", []> {
  let Inst{8}      = 0b0;
}
def FIXEDUWP_FWPFIXED      : ALU_FWPFIXED_Inst<"fixeduwp", []> {
  let Inst{8}      = 0b1;
}

//===----------------------------------------------------------------------===//
// ALU_FDMO0 — ALU Floating-Point Double Word Monadic 0
// simple (32 bits), syntax: %0%3 %1 = %2
//===----------------------------------------------------------------------===//
class ALU_FDMO0_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, floatmode:$floatmode),
                !strconcat(mnemonic, "${floatmode} $rW = $rZ"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<3>  floatmode;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{26-24}  = floatmode;
  let Inst{30-27}  = 0b1111;
  let Inst{17-9}   = 0b000010100;
  let Inst{6}      = 0b0;
}

def FRINTD_FDMO0           : ALU_FDMO0_Inst<"frintd", [], ALU_LITE> {
  let Inst{8}      = 0b1;
}
def FSQRTD_FDMO0           : ALU_FDMO0_Inst<"fsqrtd", [], ALU_FULL> {
  let Inst{8}      = 0b0;
}

//===----------------------------------------------------------------------===//
// ALU_FWMO0 — ALU Floating-Point Word Monadic 0
// simple (32 bits), syntax: %0%3 %1 = %2
//===----------------------------------------------------------------------===//
class ALU_FWMO0_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, floatmode:$floatmode),
                !strconcat(mnemonic, "${floatmode} $rW = $rZ"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<3>  floatmode;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{26-24}  = floatmode;
  let Inst{30-27}  = 0b1111;
  let Inst{17-9}   = 0b010010100;
  let Inst{6}      = 0b0;
}

def FRINTW_FWMO0           : ALU_FWMO0_Inst<"frintw", [], ALU_LITE> {
  let Inst{8}      = 0b1;
}
def FSQRTW_FWMO0           : ALU_FWMO0_Inst<"fsqrtw", [], ALU_FULL> {
  let Inst{8}      = 0b0;
}

//===----------------------------------------------------------------------===//
// ALU_FHMO0 — ALU Floating-Point Half Word Monadic 0
// simple (32 bits), syntax: %0%3 %1 = %2
//===----------------------------------------------------------------------===//
class ALU_FHMO0_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, floatmode:$floatmode),
                !strconcat(mnemonic, "${floatmode} $rW = $rZ"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<3>  floatmode;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{26-24}  = floatmode;
  let Inst{30-27}  = 0b1111;
  let Inst{17-9}   = 0b010011100;
  let Inst{6}      = 0b0;
}

def FRINTH_FHMO0           : ALU_FHMO0_Inst<"frinth", [], ALU_LITE> {
  let Inst{8}      = 0b1;
}
def FSQRTH_FHMO0           : ALU_FHMO0_Inst<"fsqrth", [], ALU_FULL> {
  let Inst{8}      = 0b0;
}

//===----------------------------------------------------------------------===//
// ALU_DMWRR — ALU Double Word Multiply Write Read Read
// simple (32 bits), syntax: %0%4 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_DMWRR_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin = ALU_LITE>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, GPR:$rY, highmult:$highmult),
                !strconcat(mnemonic, "${highmult} $rW = $rZ, $rY"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<6>  rY;
  bits<2>  highmult;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = rY;
  let Inst{25-24}  = highmult;
  let Inst{30-27}  = 0b1100;
  let Inst{17-12}  = 0b101100;
}

def MULD_DMWRR             : ALU_DMWRR_Inst<"muld", []> {
  let Inst{26}     = 0b0;
}
def MULND_DMWRR            : ALU_DMWRR_Inst<"mulnd", []> {
  let Inst{26}     = 0b1;
}

//===----------------------------------------------------------------------===//
// ALU_DMWRR.M — ALU Double Word Multiply Write Read Read Magic
// double (64 bits), syntax: %0%4 %1 = %2, %3%5
//===----------------------------------------------------------------------===//
class ALU_DMWRR_M_Inst<string mnemonic, list<dag> pattern,
                       InstrItinClass itin = ALU_LITE_X>
    : LVXInst64<(outs GPR:$rW), (ins GPR:$rZ, wimm32:$imm, highmult:$highmult, splat32:$splat32),
                !strconcat(mnemonic, "${highmult} $rW = $rZ, $imm${splat32}"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<32> imm;
  bits<2>  highmult;
  bits<1>  splat32;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{58-32}  = imm{31-5};
  let Inst{10-6}   = imm{4-0};
  let Inst{25-24}  = highmult;
  let Inst{11}     = splat32;
  let Inst{62-61}  = 0b00;
  let Inst{31-27}  = 0b11100;
  let Inst{17-12}  = 0b101100;
}

def MULD_DMWRR_M           : ALU_DMWRR_M_Inst<"muld", []> {
  let Inst{26}     = 0b0;
}
def MULND_DMWRR_M          : ALU_DMWRR_M_Inst<"mulnd", []> {
  let Inst{26}     = 0b1;
}

//===----------------------------------------------------------------------===//
// ALU_WMWRR — ALU Word Multiply Write Read Read
// simple (32 bits), syntax: %0%4%5 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_WMWRR_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin = ALU_LITE>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, GPR:$rY, highmult:$highmult, signextw:$signextw),
                !strconcat(mnemonic, "${highmult}${signextw} $rW = $rZ, $rY"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<6>  rY;
  bits<2>  highmult;
  bits<1>  signextw;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = rY;
  let Inst{25-24}  = highmult;
  let Inst{12}     = signextw;
  let Inst{30-27}  = 0b1100;
  let Inst{17-13}  = 0b11110;
}

def MULW_WMWRR             : ALU_WMWRR_Inst<"mulw", []> {
  let Inst{26}     = 0b0;
}
def MULNW_WMWRR            : ALU_WMWRR_Inst<"mulnw", []> {
  let Inst{26}     = 0b1;
}

//===----------------------------------------------------------------------===//
// ALU_WMWRR.W — ALU Word Multiply Write Read Read Wrapped
// double (64 bits), syntax: %0%4%5 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_WMWRR_W_Inst<string mnemonic, list<dag> pattern,
                       InstrItinClass itin = ALU_LITE_X>
    : LVXInst64<(outs GPR:$rW), (ins GPR:$rZ, wimm32:$imm, highmult:$highmult, signextw:$signextw),
                !strconcat(mnemonic, "${highmult}${signextw} $rW = $rZ, $imm"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<32> imm;
  bits<2>  highmult;
  bits<1>  signextw;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{58-32}  = imm{31-5};
  let Inst{10-6}   = imm{4-0};
  let Inst{25-24}  = highmult;
  let Inst{12}     = signextw;
  let Inst{62-61}  = 0b00;
  let Inst{31-27}  = 0b11100;
  let Inst{17-13}  = 0b11110;
  let Inst{11}     = 0b0;
}

def MULW_WMWRR_W           : ALU_WMWRR_W_Inst<"mulw", []> {
  let Inst{26}     = 0b0;
}
def MULNW_WMWRR_W          : ALU_WMWRR_W_Inst<"mulnw", []> {
  let Inst{26}     = 0b1;
}

//===----------------------------------------------------------------------===//
// ALU_QMEWRR — ALU Word Quadruple Multiply Extend Write Read Read
// simple (32 bits), syntax: %0%4 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_QMEWRR_Inst<string mnemonic, list<dag> pattern,
                      InstrItinClass itin = ALU_LITE>
    : LVXInst32<(outs GPR128:$rM), (ins GPR:$rZ, GPR:$rY, widemult:$widemult),
                !strconcat(mnemonic, "${widemult} $rM = $rZ, $rY"),
                pattern, itin> {
  bits<5>  rM;
  bits<6>  rZ;
  bits<6>  rY;
  bits<2>  widemult;
  let Inst{23-19}  = rM;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = rY;
  let Inst{25-24}  = widemult;
  let Inst{30-27}  = 0b1100;
  let Inst{17-12}  = 0b101111;
}

def MULXDQ_QMEWRR          : ALU_QMEWRR_Inst<"mulxdq", []> {
  let Inst{26}     = 0b0;
}
def MULNXDQ_QMEWRR         : ALU_QMEWRR_Inst<"mulnxdq", []> {
  let Inst{26}     = 0b1;
}

//===----------------------------------------------------------------------===//
// ALU_DMEWRR — ALU Double Word Multiply Extend Write Read Read
// simple (32 bits), syntax: %0%4 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_DMEWRR_Inst<string mnemonic, list<dag> pattern,
                      InstrItinClass itin = ALU_LITE>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, GPR:$rY, widemult:$widemult),
                !strconcat(mnemonic, "${widemult} $rW = $rZ, $rY"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<6>  rY;
  bits<2>  widemult;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = rY;
  let Inst{25-24}  = widemult;
  let Inst{30-27}  = 0b1100;
  let Inst{17-12}  = 0b101110;
}

def MULXWD_DMEWRR          : ALU_DMEWRR_Inst<"mulxwd", []> {
  let Inst{26}     = 0b0;
}
def MULNXWD_DMEWRR         : ALU_DMEWRR_Inst<"mulnxwd", []> {
  let Inst{26}     = 0b1;
}

//===----------------------------------------------------------------------===//
// ALU_DMEWRR.M — ALU Double Word Multiply Extend Write Read Read Magic
// double (64 bits), syntax: %0%4 %1 = %2, %3%5
//===----------------------------------------------------------------------===//
class ALU_DMEWRR_M_Inst<string mnemonic, list<dag> pattern,
                        InstrItinClass itin = ALU_LITE_X>
    : LVXInst64<(outs GPR:$rW), (ins GPR:$rZ, wimm32:$imm, widemult:$widemult, splat32:$splat32),
                !strconcat(mnemonic, "${widemult} $rW = $rZ, $imm${splat32}"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<32> imm;
  bits<2>  widemult;
  bits<1>  splat32;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{58-32}  = imm{31-5};
  let Inst{10-6}   = imm{4-0};
  let Inst{25-24}  = widemult;
  let Inst{11}     = splat32;
  let Inst{62-61}  = 0b00;
  let Inst{31-27}  = 0b11100;
  let Inst{17-12}  = 0b101110;
}

def MULXWD_DMEWRR_M        : ALU_DMEWRR_M_Inst<"mulxwd", []> {
  let Inst{26}     = 0b0;
}
def MULNXWD_DMEWRR_M       : ALU_DMEWRR_M_Inst<"mulnxwd", []> {
  let Inst{26}     = 0b1;
}

//===----------------------------------------------------------------------===//
// ALU_DMWRRR — ALU Double Word Multiply Write Read Read Read
// simple (32 bits), syntax: %0%4 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_DMWRRR_Inst<string mnemonic, list<dag> pattern,
                      InstrItinClass itin = ALU_LITE>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rWsrc, GPR:$rZ, GPR:$rY, highmult:$highmult),
                !strconcat(mnemonic, "${highmult} $rW = $rZ, $rY"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<6>  rY;
  bits<2>  highmult;
  let Constraints = "$rWsrc = $rW";
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = rY;
  let Inst{25-24}  = highmult;
  let Inst{30-27}  = 0b1101;
  let Inst{17-12}  = 0b101100;
}

def MADDD_DMWRRR           : ALU_DMWRRR_Inst<"maddd", []> {
  let Inst{26}     = 0b0;
}
def MSBFD_DMWRRR           : ALU_DMWRRR_Inst<"msbfd", []> {
  let Inst{26}     = 0b1;
}

//===----------------------------------------------------------------------===//
// ALU_DMWRRR.M — ALU Double Word Multiply Write Read Read Read Magic
// double (64 bits), syntax: %0%4 %1 = %2, %3%5
//===----------------------------------------------------------------------===//
class ALU_DMWRRR_M_Inst<string mnemonic, list<dag> pattern,
                        InstrItinClass itin = ALU_LITE_X>
    : LVXInst64<(outs GPR:$rW), (ins GPR:$rWsrc, GPR:$rZ, wimm32:$imm, highmult:$highmult, splat32:$splat32),
                !strconcat(mnemonic, "${highmult} $rW = $rZ, $imm${splat32}"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<32> imm;
  bits<2>  highmult;
  bits<1>  splat32;
  let Constraints = "$rWsrc = $rW";
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{58-32}  = imm{31-5};
  let Inst{10-6}   = imm{4-0};
  let Inst{25-24}  = highmult;
  let Inst{11}     = splat32;
  let Inst{62-61}  = 0b00;
  let Inst{31-27}  = 0b11101;
  let Inst{17-12}  = 0b101100;
}

def MADDD_DMWRRR_M         : ALU_DMWRRR_M_Inst<"maddd", []> {
  let Inst{26}     = 0b0;
}
def MSBFD_DMWRRR_M         : ALU_DMWRRR_M_Inst<"msbfd", []> {
  let Inst{26}     = 0b1;
}

//===----------------------------------------------------------------------===//
// ALU_WMWRRR — ALU Word Multiply Write Read Read Read
// simple (32 bits), syntax: %0%4%5 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_WMWRRR_Inst<string mnemonic, list<dag> pattern,
                      InstrItinClass itin = ALU_LITE>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rWsrc, GPR:$rZ, GPR:$rY, highmult:$highmult, signextw:$signextw),
                !strconcat(mnemonic, "${highmult}${signextw} $rW = $rZ, $rY"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<6>  rY;
  bits<2>  highmult;
  bits<1>  signextw;
  let Constraints = "$rWsrc = $rW";
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = rY;
  let Inst{25-24}  = highmult;
  let Inst{12}     = signextw;
  let Inst{30-27}  = 0b1101;
  let Inst{17-13}  = 0b11110;
}

def MADDW_WMWRRR           : ALU_WMWRRR_Inst<"maddw", []> {
  let Inst{26}     = 0b0;
}
def MSBFW_WMWRRR           : ALU_WMWRRR_Inst<"msbfw", []> {
  let Inst{26}     = 0b1;
}

//===----------------------------------------------------------------------===//
// ALU_WMWRRR.W — ALU Word Multiply Write Read Read Read Wrapped
// double (64 bits), syntax: %0%4%5 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_WMWRRR_W_Inst<string mnemonic, list<dag> pattern,
                        InstrItinClass itin = ALU_LITE_X>
    : LVXInst64<(outs GPR:$rW), (ins GPR:$rWsrc, GPR:$rZ, wimm32:$imm, highmult:$highmult, signextw:$signextw),
                !strconcat(mnemonic, "${highmult}${signextw} $rW = $rZ, $imm"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<32> imm;
  bits<2>  highmult;
  bits<1>  signextw;
  let Constraints = "$rWsrc = $rW";
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{58-32}  = imm{31-5};
  let Inst{10-6}   = imm{4-0};
  let Inst{25-24}  = highmult;
  let Inst{12}     = signextw;
  let Inst{62-61}  = 0b00;
  let Inst{31-27}  = 0b11101;
  let Inst{17-13}  = 0b11110;
  let Inst{11}     = 0b0;
}

def MADDW_WMWRRR_W         : ALU_WMWRRR_W_Inst<"maddw", []> {
  let Inst{26}     = 0b0;
}
def MSBFW_WMWRRR_W         : ALU_WMWRRR_W_Inst<"msbfw", []> {
  let Inst{26}     = 0b1;
}

//===----------------------------------------------------------------------===//
// ALU_QMEWRRR — ALU Word Quadruple Multiply Extend Write Read Read Read
// simple (32 bits), syntax: %0%4 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_QMEWRRR_Inst<string mnemonic, list<dag> pattern,
                       InstrItinClass itin = ALU_LITE>
    : LVXInst32<(outs GPR128:$rM), (ins GPR128:$rMsrc, GPR:$rZ, GPR:$rY, widemult:$widemult),
                !strconcat(mnemonic, "${widemult} $rM = $rZ, $rY"),
                pattern, itin> {
  bits<5>  rM;
  bits<6>  rZ;
  bits<6>  rY;
  bits<2>  widemult;
  let Constraints = "$rMsrc = $rM";
  let Inst{23-19}  = rM;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = rY;
  let Inst{25-24}  = widemult;
  let Inst{30-27}  = 0b1101;
  let Inst{17-12}  = 0b101111;
}

def MADDXDQ_QMEWRRR        : ALU_QMEWRRR_Inst<"maddxdq", []> {
  let Inst{26}     = 0b0;
}
def MSBFXDQ_QMEWRRR        : ALU_QMEWRRR_Inst<"msbfxdq", []> {
  let Inst{26}     = 0b1;
}

//===----------------------------------------------------------------------===//
// ALU_DMEWRRR — ALU Double Word Multiply Extend Write Read Read Read
// simple (32 bits), syntax: %0%4 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_DMEWRRR_Inst<string mnemonic, list<dag> pattern,
                       InstrItinClass itin = ALU_LITE>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rWsrc, GPR:$rZ, GPR:$rY, widemult:$widemult),
                !strconcat(mnemonic, "${widemult} $rW = $rZ, $rY"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<6>  rY;
  bits<2>  widemult;
  let Constraints = "$rWsrc = $rW";
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = rY;
  let Inst{25-24}  = widemult;
  let Inst{30-27}  = 0b1101;
  let Inst{17-12}  = 0b101110;
}

def MADDXWD_DMEWRRR        : ALU_DMEWRRR_Inst<"maddxwd", []> {
  let Inst{26}     = 0b0;
}
def MSBFXWD_DMEWRRR        : ALU_DMEWRRR_Inst<"msbfxwd", []> {
  let Inst{26}     = 0b1;
}

//===----------------------------------------------------------------------===//
// ALU_DMEWRRR.M — ALU Double Word Multiply Extend Write Read Read Read Magic
// double (64 bits), syntax: %0%4 %1 = %2, %3%5
//===----------------------------------------------------------------------===//
class ALU_DMEWRRR_M_Inst<string mnemonic, list<dag> pattern,
                         InstrItinClass itin = ALU_LITE_X>
    : LVXInst64<(outs GPR:$rW), (ins GPR:$rWsrc, GPR:$rZ, wimm32:$imm, widemult:$widemult, splat32:$splat32),
                !strconcat(mnemonic, "${widemult} $rW = $rZ, $imm${splat32}"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<32> imm;
  bits<2>  widemult;
  bits<1>  splat32;
  let Constraints = "$rWsrc = $rW";
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{58-32}  = imm{31-5};
  let Inst{10-6}   = imm{4-0};
  let Inst{25-24}  = widemult;
  let Inst{11}     = splat32;
  let Inst{62-61}  = 0b00;
  let Inst{31-27}  = 0b11101;
  let Inst{17-12}  = 0b101110;
}

def MADDXWD_DMEWRRR_M      : ALU_DMEWRRR_M_Inst<"maddxwd", []> {
  let Inst{26}     = 0b0;
}
def MSBFXWD_DMEWRRR_M      : ALU_DMEWRRR_M_Inst<"msbfxwd", []> {
  let Inst{26}     = 0b1;
}

//===----------------------------------------------------------------------===//
// ALU_DDMWRR — ALU Double Word Division Modulus Write Read Read
// simple (32 bits), syntax: %0 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_DDMWRR_Inst<string mnemonic, list<dag> pattern,
                      InstrItinClass itin = ALU_FULL>
    : LVXInst32<(outs GPR128:$rM), (ins GPR:$rZ, GPR:$rY),
                !strconcat(mnemonic, " $rM = $rZ, $rY"),
                pattern, itin> {
  bits<5>  rM;
  bits<6>  rZ;
  bits<6>  rY;
  let Inst{23-19}  = rM;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = rY;
  let Inst{30-25}  = 0b110110;
  let Inst{17-12}  = 0b101010;
}

def DIVMODD_DDMWRR         : ALU_DDMWRR_Inst<"divmodd", []> {
  let Inst{24}     = 0b0;
}
def DIVMODUD_DDMWRR        : ALU_DDMWRR_Inst<"divmodud", []> {
  let Inst{24}     = 0b1;
}

//===----------------------------------------------------------------------===//
// ALU_WDMWRR — ALU Word Division Modulus Write Read Read
// simple (32 bits), syntax: %0%4 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_WDMWRR_Inst<string mnemonic, list<dag> pattern,
                      InstrItinClass itin = ALU_FULL>
    : LVXInst32<(outs GPR128:$rM), (ins GPR:$rZ, GPR:$rY, signextw:$signextw),
                !strconcat(mnemonic, "${signextw} $rM = $rZ, $rY"),
                pattern, itin> {
  bits<5>  rM;
  bits<6>  rZ;
  bits<6>  rY;
  bits<1>  signextw;
  let Inst{23-19}  = rM;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = rY;
  let Inst{12}     = signextw;
  let Inst{30-25}  = 0b110110;
  let Inst{17-13}  = 0b11101;
}

def DIVMODW_WDMWRR         : ALU_WDMWRR_Inst<"divmodw", []> {
  let Inst{24}     = 0b0;
}
def DIVMODUW_WDMWRR        : ALU_WDMWRR_Inst<"divmoduw", []> {
  let Inst{24}     = 0b1;
}

//===----------------------------------------------------------------------===//
// ALU_WCWRRR — ALU Word CRC Write Read Read Read
// simple (32 bits), syntax: %0 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_WCWRRR_Inst<string mnemonic, list<dag> pattern,
                      InstrItinClass itin = ALU_LITE>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rWsrc, GPR:$rZ, GPR:$rY),
                !strconcat(mnemonic, " $rW = $rZ, $rY"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<6>  rY;
  let Constraints = "$rWsrc = $rW";
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = rY;
  let Inst{30-26}  = 0b11001;
  let Inst{17-12}  = 0b110101;
}

def CRCBELMW_WCWRRR        : ALU_WCWRRR_Inst<"crcbelmw", []> {
  let Inst{25-24}  = 0b00;
}
def CRCBELLW_WCWRRR        : ALU_WCWRRR_Inst<"crcbellw", []> {
  let Inst{25-24}  = 0b01;
}
def CRCLELMW_WCWRRR        : ALU_WCWRRR_Inst<"crclelmw", []> {
  let Inst{25-24}  = 0b10;
}
def CRCLELLW_WCWRRR        : ALU_WCWRRR_Inst<"crclellw", []> {
  let Inst{25-24}  = 0b11;
}

//===----------------------------------------------------------------------===//
// ALU_WCWRRR.W — ALU Word CRC Write Read Read Read Wrapped
// double (64 bits), syntax: %0 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_WCWRRR_W_Inst<string mnemonic, list<dag> pattern,
                        InstrItinClass itin = ALU_LITE_X>
    : LVXInst64<(outs GPR:$rW), (ins GPR:$rWsrc, GPR:$rZ, wimm32:$imm),
                !strconcat(mnemonic, " $rW = $rZ, $imm"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<32> imm;
  let Constraints = "$rWsrc = $rW";
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{58-32}  = imm{31-5};
  let Inst{10-6}   = imm{4-0};
  let Inst{62-61}  = 0b00;
  let Inst{31-26}  = 0b111001;
  let Inst{17-11}  = 0b1101010;
}

def CRCBELMW_WCWRRR_W      : ALU_WCWRRR_W_Inst<"crcbelmw", []> {
  let Inst{25-24}  = 0b00;
}
def CRCBELLW_WCWRRR_W      : ALU_WCWRRR_W_Inst<"crcbellw", []> {
  let Inst{25-24}  = 0b01;
}
def CRCLELMW_WCWRRR_W      : ALU_WCWRRR_W_Inst<"crclelmw", []> {
  let Inst{25-24}  = 0b10;
}
def CRCLELLW_WCWRRR_W      : ALU_WCWRRR_W_Inst<"crclellw", []> {
  let Inst{25-24}  = 0b11;
}

//===----------------------------------------------------------------------===//
// ALU_FDADD — ALU Floating-Point Double Word Add Subtract
// simple (32 bits), syntax: %0%4 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_FDADD_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin = ALU_LITE>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, GPR:$rY, floatmode:$floatmode),
                !strconcat(mnemonic, "${floatmode} $rW = $rZ, $rY"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<6>  rY;
  bits<3>  floatmode;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = rY;
  let Inst{26-24}  = floatmode;
  let Inst{30-27}  = 0b1110;
  let Inst{17-14}  = 0b0000;
  let Inst{12}     = 0b0;
}

def FADDD_FDADD            : ALU_FDADD_Inst<"faddd", []> {
  let Inst{13}     = 0b0;
}
def FSBFD_FDADD            : ALU_FDADD_Inst<"fsbfd", []> {
  let Inst{13}     = 0b1;
}

//===----------------------------------------------------------------------===//
// ALU_FWADD — ALU Floating-Point Word Add Subtract
// simple (32 bits), syntax: %0%4 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_FWADD_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin = ALU_LITE>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, GPR:$rY, floatmode:$floatmode),
                !strconcat(mnemonic, "${floatmode} $rW = $rZ, $rY"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<6>  rY;
  bits<3>  floatmode;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = rY;
  let Inst{26-24}  = floatmode;
  let Inst{30-27}  = 0b1110;
  let Inst{17-14}  = 0b0100;
  let Inst{12}     = 0b0;
}

def FADDW_FWADD            : ALU_FWADD_Inst<"faddw", []> {
  let Inst{13}     = 0b0;
}
def FSBFW_FWADD            : ALU_FWADD_Inst<"fsbfw", []> {
  let Inst{13}     = 0b1;
}

//===----------------------------------------------------------------------===//
// ALU_FHADD — ALU Floating-Point Half Word Add Subtract
// simple (32 bits), syntax: %0%4 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_FHADD_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin = ALU_LITE>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, GPR:$rY, floatmode:$floatmode),
                !strconcat(mnemonic, "${floatmode} $rW = $rZ, $rY"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<6>  rY;
  bits<3>  floatmode;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = rY;
  let Inst{26-24}  = floatmode;
  let Inst{30-27}  = 0b1110;
  let Inst{17-14}  = 0b0100;
  let Inst{12}     = 0b1;
}

def FADDH_FHADD            : ALU_FHADD_Inst<"faddh", []> {
  let Inst{13}     = 0b0;
}
def FSBFH_FHADD            : ALU_FHADD_Inst<"fsbfh", []> {
  let Inst{13}     = 0b1;
}

//===----------------------------------------------------------------------===//
// ALU_FDMUL — ALU Floating-Point Double Word Multiply
// simple (32 bits), syntax: %0%5%4 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_FDMUL_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, GPR:$rY, floatmode:$floatmode, fnegate:$fnegate),
                !strconcat(mnemonic, "${fnegate}${floatmode} $rW = $rZ, $rY"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<6>  rY;
  bits<3>  floatmode;
  bits<1>  fnegate;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = rY;
  let Inst{26-24}  = floatmode;
  let Inst{27}     = fnegate;
  let Inst{30-28}  = 0b111;
  let Inst{17-14}  = 0b0011;
  let Inst{12}     = 0b0;
}

def FMULD_FDMUL            : ALU_FDMUL_Inst<"fmuld", [], ALU_LITE> {
  let Inst{13}     = 0b0;
}
def FDIVD_FDMUL            : ALU_FDMUL_Inst<"fdivd", [], ALU_FULL> {
  let Inst{13}     = 0b1;
}

//===----------------------------------------------------------------------===//
// ALU_FWMUL — ALU Floating-Point Word Multiply
// simple (32 bits), syntax: %0%5%4 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_FWMUL_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, GPR:$rY, floatmode:$floatmode, fnegate:$fnegate),
                !strconcat(mnemonic, "${fnegate}${floatmode} $rW = $rZ, $rY"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<6>  rY;
  bits<3>  floatmode;
  bits<1>  fnegate;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = rY;
  let Inst{26-24}  = floatmode;
  let Inst{27}     = fnegate;
  let Inst{30-28}  = 0b111;
  let Inst{17-14}  = 0b0111;
  let Inst{12}     = 0b0;
}

def FMULW_FWMUL            : ALU_FWMUL_Inst<"fmulw", [], ALU_LITE> {
  let Inst{13}     = 0b0;
}
def FDIVW_FWMUL            : ALU_FWMUL_Inst<"fdivw", [], ALU_FULL> {
  let Inst{13}     = 0b1;
}

//===----------------------------------------------------------------------===//
// ALU_FHMUL — ALU Floating-Point Half Word Multiply
// simple (32 bits), syntax: %0%5%4 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_FHMUL_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rZ, GPR:$rY, floatmode:$floatmode, fnegate:$fnegate),
                !strconcat(mnemonic, "${fnegate}${floatmode} $rW = $rZ, $rY"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<6>  rY;
  bits<3>  floatmode;
  bits<1>  fnegate;
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = rY;
  let Inst{26-24}  = floatmode;
  let Inst{27}     = fnegate;
  let Inst{30-28}  = 0b111;
  let Inst{17-14}  = 0b0111;
  let Inst{12}     = 0b1;
}

def FMULH_FHMUL            : ALU_FHMUL_Inst<"fmulh", [], ALU_LITE> {
  let Inst{13}     = 0b0;
}
def FDIVH_FHMUL            : ALU_FHMUL_Inst<"fdivh", [], ALU_FULL> {
  let Inst{13}     = 0b1;
}

//===----------------------------------------------------------------------===//
// ALU_FDFMA — ALU Floating-Point Double Word Fused Multiply Accumulate
// simple (32 bits), syntax: %0%5%4 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_FDFMA_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin = ALU_LITE>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rWsrc, GPR:$rZ, GPR:$rY, floatmode:$floatmode, fnegate:$fnegate),
                !strconcat(mnemonic, "${fnegate}${floatmode} $rW = $rZ, $rY"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<6>  rY;
  bits<3>  floatmode;
  bits<1>  fnegate;
  let Constraints = "$rWsrc = $rW";
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = rY;
  let Inst{26-24}  = floatmode;
  let Inst{27}     = fnegate;
  let Inst{30-28}  = 0b111;
  let Inst{17-14}  = 0b0010;
  let Inst{12}     = 0b0;
}

def FFMAD_FDFMA            : ALU_FDFMA_Inst<"ffmad", []> {
  let Inst{13}     = 0b0;
}
def FFMSD_FDFMA            : ALU_FDFMA_Inst<"ffmsd", []> {
  let Inst{13}     = 0b1;
}

//===----------------------------------------------------------------------===//
// ALU_FWFMA — ALU Floating-Point Word Fused Multiply Accumulate
// simple (32 bits), syntax: %0%5%4 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_FWFMA_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin = ALU_LITE>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rWsrc, GPR:$rZ, GPR:$rY, floatmode:$floatmode, fnegate:$fnegate),
                !strconcat(mnemonic, "${fnegate}${floatmode} $rW = $rZ, $rY"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<6>  rY;
  bits<3>  floatmode;
  bits<1>  fnegate;
  let Constraints = "$rWsrc = $rW";
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = rY;
  let Inst{26-24}  = floatmode;
  let Inst{27}     = fnegate;
  let Inst{30-28}  = 0b111;
  let Inst{17-14}  = 0b0110;
  let Inst{12}     = 0b0;
}

def FFMAW_FWFMA            : ALU_FWFMA_Inst<"ffmaw", []> {
  let Inst{13}     = 0b0;
}
def FFMSW_FWFMA            : ALU_FWFMA_Inst<"ffmsw", []> {
  let Inst{13}     = 0b1;
}

//===----------------------------------------------------------------------===//
// ALU_FHFMA — ALU Floating-Point Half Word Fused Multiply Accumulate
// simple (32 bits), syntax: %0%5%4 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_FHFMA_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin = ALU_LITE>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rWsrc, GPR:$rZ, GPR:$rY, floatmode:$floatmode, fnegate:$fnegate),
                !strconcat(mnemonic, "${fnegate}${floatmode} $rW = $rZ, $rY"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<6>  rY;
  bits<3>  floatmode;
  bits<1>  fnegate;
  let Constraints = "$rWsrc = $rW";
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = rY;
  let Inst{26-24}  = floatmode;
  let Inst{27}     = fnegate;
  let Inst{30-28}  = 0b111;
  let Inst{17-14}  = 0b0110;
  let Inst{12}     = 0b1;
}

def FFMAH_FHFMA            : ALU_FHFMA_Inst<"ffmah", []> {
  let Inst{13}     = 0b0;
}
def FFMSH_FHFMA            : ALU_FHFMA_Inst<"ffmsh", []> {
  let Inst{13}     = 0b1;
}

//===----------------------------------------------------------------------===//
// ALU_FWCOP — ALU Floating-Point Word Complex Operations
// simple (32 bits), syntax: %0%6%5%4 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_FWCOP_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin = ALU_LITE>
    : LVXInst32<(outs GPR:$rW), (ins GPR:$rWsrc, GPR:$rZ, GPR:$rY, floatmode:$floatmode, imultiply:$imultiply, conjugate:$conjugate),
                !strconcat(mnemonic, "${conjugate}${imultiply}${floatmode} $rW = $rZ, $rY"),
                pattern, itin> {
  bits<6>  rW;
  bits<6>  rZ;
  bits<6>  rY;
  bits<3>  floatmode;
  bits<1>  imultiply;
  bits<1>  conjugate;
  let Constraints = "$rWsrc = $rW";
  let Inst{23-18}  = rW;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = rY;
  let Inst{26-24}  = floatmode;
  let Inst{27}     = imultiply;
  let Inst{13}     = conjugate;
  let Inst{30-28}  = 0b111;
  let Inst{17-16}  = 0b00;
  let Inst{12}     = 0b1;
}

def FADDWC_FWCOP           : ALU_FWCOP_Inst<"faddwc", []> {
  let Inst{15-14}  = 0b00;
}
def FSBFWC_FWCOP           : ALU_FWCOP_Inst<"fsbfwc", []> {
  let Inst{15-14}  = 0b01;
}
def FMULWC_FWCOP           : ALU_FWCOP_Inst<"fmulwc", []> {
  let Inst{15-14}  = 0b10;
}
def FFMAWC_FWCOP           : ALU_FWCOP_Inst<"ffmawc", []> {
  let Inst{15-14}  = 0b11;
}

//===----------------------------------------------------------------------===//
// LSU_COPYO — LSU Copy Octuple Word
// simple (32 bits), syntax: %0 %1 = %2
//===----------------------------------------------------------------------===//
class LSU_COPYO_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin = LSU_AUXR_AUXW>
    : LVXInst32<(outs GPR256:$rN), (ins GPR256:$rR),
                !strconcat(mnemonic, " $rN = $rR"),
                pattern, itin> {
  bits<4>  rN;
  bits<4>  rR;
  let Inst{23-20}  = rN;
  let Inst{5-2}    = rR;
  let Inst{30-24}  = 0b0110100;
  let Inst{19-16}  = 0b1101;
}

def COPYO_COPYO            : LSU_COPYO_Inst<"copyo", []>;

//===----------------------------------------------------------------------===//
// ALU_CATDQ — ALU Catenate Double to Quadruple Word
// simple (32 bits), syntax: %0 %1 = %2, %3
//===----------------------------------------------------------------------===//
class ALU_CATDQ_Inst<string mnemonic, list<dag> pattern,
                     InstrItinClass itin = ALU_LITE>
    : LVXInst32<(outs GPR128:$rM), (ins GPR:$rZ, GPR:$rY),
                !strconcat(mnemonic, " $rM = $rZ, $rY"),
                pattern, itin> {
  bits<5>  rM;
  bits<6>  rZ;
  bits<6>  rY;
  let Inst{23-19}  = rM;
  let Inst{5-0}    = rZ;
  let Inst{11-6}   = rY;
  let Inst{30-24}  = 0b1101111;
  let Inst{17-12}  = 0b100101;
}

def CATDQ_CATDQ            : ALU_CATDQ_Inst<"catdq", []>;
def COPYQ_CATDQ            : ALU_CATDQ_Inst<"copyq", []>;

