//===-- LVXRegisterInfo.td - LVX Register Definitions -----*- tablegen -*-===//
//
// Register layout, per lvx_Convention.yml (Convention: regular):
//
//   $r0  - $r11   argument / result registers (caller-saved)
//   $r12          stack pointer (SP)           — reserved
//   $r13          thread-local / local pointer — reserved
//   $r14          frame pointer (FP)            — callee-saved,
//                  allocatable when the function does not need a
//                  frame pointer (handled dynamically in
//                  LVXRegisterInfo::getReservedRegs(), Phase 5)
//   $r15          struct-return pointer (caller-saved scratch otherwise)
//   $r16, $r17    veneer / long-branch temporaries (caller-saved)
//   $r18 - $r31   callee-saved (preserved)
//   $r31          also used as the static-chain register for nested
//                  functions (callee-saved scratch)
//   $r32 - $r63   caller-saved (scratch)
//
//===----------------------------------------------------------------------===//

class LVXReg<bits<6> Enc, string Name, list<string> AltNames = []>
    : Register<Name, AltNames> {
  let HWEncoding{5-0} = Enc;
  let Namespace = "LVX";
}

class LVXReg64<bits<6> Enc, string Name, list<string> AltNames = []>
    : LVXReg<Enc, Name, AltNames>;

//===----------------------------------------------------------------------===//
// General-purpose registers: $r0 - $r63
//===----------------------------------------------------------------------===//

def R0  : LVXReg64<0,  "$r0">;
def R1  : LVXReg64<1,  "$r1">;
def R2  : LVXReg64<2,  "$r2">;
def R3  : LVXReg64<3,  "$r3">;
def R4  : LVXReg64<4,  "$r4">;
def R5  : LVXReg64<5,  "$r5">;
def R6  : LVXReg64<6,  "$r6">;
def R7  : LVXReg64<7,  "$r7">;
def R8  : LVXReg64<8,  "$r8">;
def R9  : LVXReg64<9,  "$r9">;
def R10 : LVXReg64<10, "$r10">;
def R11 : LVXReg64<11, "$r11">;
def R12 : LVXReg64<12, "$r12", ["sp"]>;
def R13 : LVXReg64<13, "$r13", ["tp"]>;
def R14 : LVXReg64<14, "$r14", ["fp"]>;
def R15 : LVXReg64<15, "$r15">;
def R16 : LVXReg64<16, "$r16">;
def R17 : LVXReg64<17, "$r17">;
def R18 : LVXReg64<18, "$r18">;
def R19 : LVXReg64<19, "$r19">;
def R20 : LVXReg64<20, "$r20">;
def R21 : LVXReg64<21, "$r21">;
def R22 : LVXReg64<22, "$r22">;
def R23 : LVXReg64<23, "$r23">;
def R24 : LVXReg64<24, "$r24">;
def R25 : LVXReg64<25, "$r25">;
def R26 : LVXReg64<26, "$r26">;
def R27 : LVXReg64<27, "$r27">;
def R28 : LVXReg64<28, "$r28">;
def R29 : LVXReg64<29, "$r29">;
def R30 : LVXReg64<30, "$r30">;
def R31 : LVXReg64<31, "$r31">;
def R32 : LVXReg64<32, "$r32">;
def R33 : LVXReg64<33, "$r33">;
def R34 : LVXReg64<34, "$r34">;
def R35 : LVXReg64<35, "$r35">;
def R36 : LVXReg64<36, "$r36">;
def R37 : LVXReg64<37, "$r37">;
def R38 : LVXReg64<38, "$r38">;
def R39 : LVXReg64<39, "$r39">;
def R40 : LVXReg64<40, "$r40">;
def R41 : LVXReg64<41, "$r41">;
def R42 : LVXReg64<42, "$r42">;
def R43 : LVXReg64<43, "$r43">;
def R44 : LVXReg64<44, "$r44">;
def R45 : LVXReg64<45, "$r45">;
def R46 : LVXReg64<46, "$r46">;
def R47 : LVXReg64<47, "$r47">;
def R48 : LVXReg64<48, "$r48">;
def R49 : LVXReg64<49, "$r49">;
def R50 : LVXReg64<50, "$r50">;
def R51 : LVXReg64<51, "$r51">;
def R52 : LVXReg64<52, "$r52">;
def R53 : LVXReg64<53, "$r53">;
def R54 : LVXReg64<54, "$r54">;
def R55 : LVXReg64<55, "$r55">;
def R56 : LVXReg64<56, "$r56">;
def R57 : LVXReg64<57, "$r57">;
def R58 : LVXReg64<58, "$r58">;
def R59 : LVXReg64<59, "$r59">;
def R60 : LVXReg64<60, "$r60">;
def R61 : LVXReg64<61, "$r61">;
def R62 : LVXReg64<62, "$r62">;
def R63 : LVXReg64<63, "$r63">;

//===----------------------------------------------------------------------===//
// 64-bit scalar register class
//
// Allocation order follows lvx_Convention.yml:
//   1. Argument/result registers R0-R11 (caller-saved) — preferred first
//      so the allocator naturally keeps values where calls expect them.
//   2. Other caller-saved scratch: R15-R17, R32-R63.
//   3. Callee-saved (preserved): R14 (FP), R18-R31 — used last since
//      spilling to them costs a save/restore in the prologue/epilogue.
//
// R12 (SP) and R13 (local/TLS pointer) are excluded entirely; they are
// marked non-allocatable via getReservedRegs() in LVXRegisterInfo.cpp
// (Phase 5), not removed from this class, so that DWARF/debug info and
// inline asm can still name them.
//===----------------------------------------------------------------------===//

// The value-type list carries f64 and f32 as well as i64: LVX has no separate
// floating-point register file, and every FPU instruction in the generated
// LVXInstrEncodings.td takes GPR operands. Without them an FP pattern cannot
// bind its f64/f32 operand to a GPR-typed instruction operand and TableGen
// rejects it with "Type set is empty for each HW mode". f32 occupies the low
// 32 bits of its register (the ISA's f32 results are zero-extended to 64).
def GPR : RegisterClass<"LVX", [i64, f64, f32], 64, (add
  // argument / result (R0-R11)
  R0,  R1,  R2,  R3,  R4,  R5,  R6,  R7,  R8,  R9,  R10, R11,
  // other caller-saved scratch
  R15, R16, R17,
  R32, R33, R34, R35, R36, R37, R38, R39,
  R40, R41, R42, R43, R44, R45, R46, R47,
  R48, R49, R50, R51, R52, R53, R54, R55,
  R56, R57, R58, R59, R60, R61, R62, R63,
  // callee-saved (R14 = FP, allocatable when no frame pointer is needed)
  R14, R18, R19, R20, R21, R22, R23,
  R24, R25, R26, R27, R28, R29, R30, R31,
  // R12 (SP) and R13 (TLS/local) are MEMBERS of this class but are never
  // allocated -- getReservedRegs marks them reserved and the allocator
  // filters reserved registers out of the allocation order, so listing them
  // last costs nothing. They have to belong to SOME i64 register class:
  // SelectionDAG's CopyFromReg/CopyToReg on a physical register calls
  // getMinimalPhysRegClass(), which asserts "Couldn't find the register
  // class" for a register in none. LowerCall does exactly that --
  // getCopyFromReg(..., LVX::R12, ...) to form the base address for outgoing
  // stack arguments -- so any call with more than twelve 64-bit argument
  // slots crashed llc outright. (The block comment above already described
  // them as kept-in-class; the class body just did not match it.)
  R12, R13
)>;

//===----------------------------------------------------------------------===//
// Sub-register indices
//===----------------------------------------------------------------------===//

def sub_hi : SubRegIndex<64, 0>;
def sub_lo : SubRegIndex<64, 64>;

//===----------------------------------------------------------------------===//
// 128-bit aligned register pairs: $r0r1, $r2r3 ... $r62r63
// Encoded on 5 bits: $r0r1 = 0, $r2r3 = 1, ..., $r62r63 = 31
//===----------------------------------------------------------------------===//

class LVXRegPair<bits<5> Enc, string Name, list<Register> Subregs>
    : RegisterWithSubRegs<Name, Subregs> {
  let HWEncoding{4-0} = Enc;
  let Namespace = "LVX";
  let SubRegIndices = [sub_hi, sub_lo];
  let CoveredBySubRegs = 1;
}

def R0R1   : LVXRegPair<0,  "$r0r1",   [R0,  R1]>;
def R2R3   : LVXRegPair<1,  "$r2r3",   [R2,  R3]>;
def R4R5   : LVXRegPair<2,  "$r4r5",   [R4,  R5]>;
def R6R7   : LVXRegPair<3,  "$r6r7",   [R6,  R7]>;
def R8R9   : LVXRegPair<4,  "$r8r9",   [R8,  R9]>;
def R10R11 : LVXRegPair<5,  "$r10r11", [R10, R11]>;
def R12R13 : LVXRegPair<6,  "$r12r13", [R12, R13]>;
def R14R15 : LVXRegPair<7,  "$r14r15", [R14, R15]>;
def R16R17 : LVXRegPair<8,  "$r16r17", [R16, R17]>;
def R18R19 : LVXRegPair<9,  "$r18r19", [R18, R19]>;
def R20R21 : LVXRegPair<10, "$r20r21", [R20, R21]>;
def R22R23 : LVXRegPair<11, "$r22r23", [R22, R23]>;
def R24R25 : LVXRegPair<12, "$r24r25", [R24, R25]>;
def R26R27 : LVXRegPair<13, "$r26r27", [R26, R27]>;
def R28R29 : LVXRegPair<14, "$r28r29", [R28, R29]>;
def R30R31 : LVXRegPair<15, "$r30r31", [R30, R31]>;
def R32R33 : LVXRegPair<16, "$r32r33", [R32, R33]>;
def R34R35 : LVXRegPair<17, "$r34r35", [R34, R35]>;
def R36R37 : LVXRegPair<18, "$r36r37", [R36, R37]>;
def R38R39 : LVXRegPair<19, "$r38r39", [R38, R39]>;
def R40R41 : LVXRegPair<20, "$r40r41", [R40, R41]>;
def R42R43 : LVXRegPair<21, "$r42r43", [R42, R43]>;
def R44R45 : LVXRegPair<22, "$r44r45", [R44, R45]>;
def R46R47 : LVXRegPair<23, "$r46r47", [R46, R47]>;
def R48R49 : LVXRegPair<24, "$r48r49", [R48, R49]>;
def R50R51 : LVXRegPair<25, "$r50r51", [R50, R51]>;
def R52R53 : LVXRegPair<26, "$r52r53", [R52, R53]>;
def R54R55 : LVXRegPair<27, "$r54r55", [R54, R55]>;
def R56R57 : LVXRegPair<28, "$r56r57", [R56, R57]>;
def R58R59 : LVXRegPair<29, "$r58r59", [R58, R59]>;
def R60R61 : LVXRegPair<30, "$r60r61", [R60, R61]>;
def R62R63 : LVXRegPair<31, "$r62r63", [R62, R63]>;

//===----------------------------------------------------------------------===//
// 128-bit register class
//
// Allocation order mirrors GPR: argument-derived pairs first (R0R1, R2R3,
// R4R5, R6R7, R8R9, R10R11 cover the R0-R11 argument range), then other
// caller-saved pairs, then callee-saved pairs last. R12R13 (SP/TLS) and
// R14R15 (FP/struct-return) are included for completeness but will be
// excluded by getReservedRegs() when their halves are reserved.
//===----------------------------------------------------------------------===//

def GPR128 : RegisterClass<"LVX", [i128], 128, (add
  R0R1,   R2R3,   R4R5,   R6R7,   R8R9,   R10R11,
  R32R33, R34R35, R36R37, R38R39, R40R41, R42R43,
  R44R45, R46R47, R48R49, R50R51, R52R53, R54R55,
  R56R57, R58R59, R60R61, R62R63,
  R16R17,
  R18R19, R20R21, R22R23, R24R25, R26R27, R28R29, R30R31,
  R12R13, R14R15
)>;

//===----------------------------------------------------------------------===//
// Sub-register indices for 256-bit quads
//===----------------------------------------------------------------------===//

def sub_pair_hi : SubRegIndex<128, 0>;
def sub_pair_lo : SubRegIndex<128, 128>;

//===----------------------------------------------------------------------===//
// 256-bit aligned register quads: $r0r1r2r3 .. $r60r61r62r63
// Encoded on 4 bits: $r0r1r2r3 = 0 .. $r60r61r62r63 = 15
//===----------------------------------------------------------------------===//

class LVXRegQuad<bits<4> Enc, string Name, list<Register> Subregs>
    : RegisterWithSubRegs<Name, Subregs> {
  let HWEncoding{3-0} = Enc;
  let Namespace = "LVX";
  let SubRegIndices = [sub_pair_hi, sub_pair_lo];
  let CoveredBySubRegs = 1;
}

def R0R1R2R3     : LVXRegQuad<0,  "$r0r1r2r3",     [R0R1,   R2R3]>;
def R4R5R6R7     : LVXRegQuad<1,  "$r4r5r6r7",     [R4R5,   R6R7]>;
def R8R9R10R11   : LVXRegQuad<2,  "$r8r9r10r11",   [R8R9,   R10R11]>;
def R12R13R14R15 : LVXRegQuad<3,  "$r12r13r14r15", [R12R13, R14R15]>;
def R16R17R18R19 : LVXRegQuad<4,  "$r16r17r18r19", [R16R17, R18R19]>;
def R20R21R22R23 : LVXRegQuad<5,  "$r20r21r22r23", [R20R21, R22R23]>;
def R24R25R26R27 : LVXRegQuad<6,  "$r24r25r26r27", [R24R25, R26R27]>;
def R28R29R30R31 : LVXRegQuad<7,  "$r28r29r30r31", [R28R29, R30R31]>;
def R32R33R34R35 : LVXRegQuad<8,  "$r32r33r34r35", [R32R33, R34R35]>;
def R36R37R38R39 : LVXRegQuad<9,  "$r36r37r38r39", [R36R37, R38R39]>;
def R40R41R42R43 : LVXRegQuad<10, "$r40r41r42r43", [R40R41, R42R43]>;
def R44R45R46R47 : LVXRegQuad<11, "$r44r45r46r47", [R44R45, R46R47]>;
def R48R49R50R51 : LVXRegQuad<12, "$r48r49r50r51", [R48R49, R50R51]>;
def R52R53R54R55 : LVXRegQuad<13, "$r52r53r54r55", [R52R53, R54R55]>;
def R56R57R58R59 : LVXRegQuad<14, "$r56r57r58r59", [R56R57, R58R59]>;
def R60R61R62R63 : LVXRegQuad<15, "$r60r61r62r63", [R60R61, R62R63]>;

//===----------------------------------------------------------------------===//
// 256-bit register class
//===----------------------------------------------------------------------===//

def GPR256 : RegisterClass<"LVX", [v4i64], 256, (add
  R0R1R2R3,     R4R5R6R7,     R8R9R10R11,
  R32R33R34R35, R36R37R38R39, R40R41R42R43, R44R45R46R47,
  R48R49R50R51, R52R53R54R55, R56R57R58R59, R60R61R62R63,
  R16R17R18R19, R20R21R22R23, R24R25R26R27, R28R29R30R31,
  R12R13R14R15
)>;

//===----------------------------------------------------------------------===//
// Control registers
//===----------------------------------------------------------------------===//

class LVXCtrlReg<bits<4> Enc, string Name>
    : Register<Name> {
  let HWEncoding{3-0} = Enc;
  let Namespace = "LVX";
}

// $ra — return address / link register.
def RA : LVXCtrlReg<0, "$ra">;

// $pc — program counter. Read-only (GET only, no SET).
def PC : LVXCtrlReg<1, "$pc">;

// $ps — processor status register. Holds the system call number (SN field)
// among other status bits.
def PS : LVXCtrlReg<2, "$ps">;

// $cs — compute status: IEEE 754 rounding mode + FP exception flags.
def CS : LVXCtrlReg<3, "$cs">;

// $ls, $le, $lc — hardware loop start/end/counter registers.
def LS : LVXCtrlReg<4, "$ls">;
def LE : LVXCtrlReg<5, "$le">;
def LC : LVXCtrlReg<6, "$lc">;

//===----------------------------------------------------------------------===//
// Control register classes
//===----------------------------------------------------------------------===//

// CR — full set, non-allocatable. Operand type for GET.
def CR : RegisterClass<"LVX", [i64], 64,
    (add RA, PC, PS, CS, LS, LE, LC)> {
  let isAllocatable = 0;
}

// CR_RO — read-only subset ($pc).
def CR_RO : RegisterClass<"LVX", [i64], 64, (add PC)> {
  let isAllocatable = 0;
}

// CR_RW — writeable subset. Operand type for the generic SET/GET pseudo
// (BCU_GSR_Inst).
def CR_RW : RegisterClass<"LVX", [i64], 64,
    (add RA, PS, CS, LS, LE, LC)> {
  let isAllocatable = 0;
}

// CR_LOOP — hardware loop registers as a group.
def CR_LOOP : RegisterClass<"LVX", [i64], 64, (add LS, LE, LC)> {
  let isAllocatable = 0;
}

//===----------------------------------------------------------------------===//
// Precise per-format SET register classes.
//
// The opcode table shows BCU_SET, BCU_SETRA, BCU_SETA, and BCU_SETHW all
// share the exact same fixed bit pattern (opc5=10000); they differ only in
// which control register encodings are valid in the 9-bit system-register
// selector field. These singleton/restricted classes let TableGen reject
// invalid combinations (e.g. "SETRA $cs") at the operand-type level rather
// than relying on a runtime check.
//===----------------------------------------------------------------------===//

// CR_SET — operand class for the base BCU_SET format: every writeable
// control register EXCEPT $ra and $ps (those have their own dedicated
// formats, BCU_SETRA and BCU_SETPS).
def CR_SET : RegisterClass<"LVX", [i64], 64, (add CS, LS, LE, LC)> {
  let isAllocatable = 0;
}

// CR_RA — singleton class containing only $ra. Operand class for
// BCU_SETRA, which can set $ra and nothing else.
def CR_RA : RegisterClass<"LVX", [i64], 64, (add RA)> {
  let isAllocatable = 0;
}

// CR_PS — singleton class containing only $ps. Operand class for
// BCU_SETPS, which can set $ps and nothing else.
def CR_PS : RegisterClass<"LVX", [i64], 64, (add PS)> {
  let isAllocatable = 0;
}
