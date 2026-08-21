//===-- LVXRegisters.td - -*- tablegen -*- ===//
//
// Physical register enum for the LVX dialect's register type.
//
// Generated from the LVX Machine Description System by MDS/BE/MLIR, for core
// lvx_v1.  DO NOT EDIT -- your changes will be overwritten by the next
// `make -C BE/MLIR install`.  Change lvx-mds/lvx-family's YAML description,
// or the generator in MDS/BE/MLIR/BIN, instead.
//
//===----------------------------------------------------------------===//

#ifndef LVX_REGISTERS
#define LVX_REGISTERS

include "mlir/IR/EnumAttr.td"

// The 65 registers a value can be pinned to: the 64-register unified
// general-purpose file, which holds scalar integer and floating-point alike,
// plus $ra.
//
// Values are dwarfId, so they are the ISA's own numbering rather than a
// position in this list.  Do not assume they are dense.
def LVX_RegisterAttr : I64EnumAttr<
    "Register", "an lvx physical register",
    [
      I64EnumAttrCase<"r0",   0,   "r0"   >,  // r0r1.lo r0r1r2r3.x
      I64EnumAttrCase<"r1",   1,   "r1"   >,  // r0r1.hi r0r1r2r3.y
      I64EnumAttrCase<"r2",   2,   "r2"   >,  // r2r3.lo r0r1r2r3.z
      I64EnumAttrCase<"r3",   3,   "r3"   >,  // r2r3.hi r0r1r2r3.t
      I64EnumAttrCase<"r4",   4,   "r4"   >,  // r4r5.lo r4r5r6r7.x
      I64EnumAttrCase<"r5",   5,   "r5"   >,  // r4r5.hi r4r5r6r7.y
      I64EnumAttrCase<"r6",   6,   "r6"   >,  // r6r7.lo r4r5r6r7.z
      I64EnumAttrCase<"r7",   7,   "r7"   >,  // r6r7.hi r4r5r6r7.t
      I64EnumAttrCase<"r8",   8,   "r8"   >,  // r8r9.lo r8r9r10r11.x
      I64EnumAttrCase<"r9",   9,   "r9"   >,  // r8r9.hi r8r9r10r11.y
      I64EnumAttrCase<"r10",  10,  "r10"  >,  // r10r11.lo r8r9r10r11.z
      I64EnumAttrCase<"r11",  11,  "r11"  >,  // r10r11.hi r8r9r10r11.t
      I64EnumAttrCase<"r12",  12,  "r12"  >,  // sp
      I64EnumAttrCase<"r13",  13,  "r13"  >,  // tp
      I64EnumAttrCase<"r14",  14,  "r14"  >,  // fp r14r15.lo
      I64EnumAttrCase<"r15",  15,  "r15"  >,  // rp r14r15.hi
      I64EnumAttrCase<"r16",  16,  "r16"  >,  // r16r17.lo r16r17r18r19.x
      I64EnumAttrCase<"r17",  17,  "r17"  >,  // r16r17.hi r16r17r18r19.y
      I64EnumAttrCase<"r18",  18,  "r18"  >,  // r18r19.lo r16r17r18r19.z
      I64EnumAttrCase<"r19",  19,  "r19"  >,  // r18r19.hi r16r17r18r19.t
      I64EnumAttrCase<"r20",  20,  "r20"  >,  // r20r21.lo r20r21r22r23.x
      I64EnumAttrCase<"r21",  21,  "r21"  >,  // r20r21.hi r20r21r22r23.y
      I64EnumAttrCase<"r22",  22,  "r22"  >,  // r22r23.lo r20r21r22r23.z
      I64EnumAttrCase<"r23",  23,  "r23"  >,  // r22r23.hi r20r21r22r23.t
      I64EnumAttrCase<"r24",  24,  "r24"  >,  // r24r25.lo r24r25r26r27.x
      I64EnumAttrCase<"r25",  25,  "r25"  >,  // r24r25.hi r24r25r26r27.y
      I64EnumAttrCase<"r26",  26,  "r26"  >,  // r26r27.lo r24r25r26r27.z
      I64EnumAttrCase<"r27",  27,  "r27"  >,  // r26r27.hi r24r25r26r27.t
      I64EnumAttrCase<"r28",  28,  "r28"  >,  // r28r29.lo r28r29r30r31.x
      I64EnumAttrCase<"r29",  29,  "r29"  >,  // r28r29.hi r28r29r30r31.y
      I64EnumAttrCase<"r30",  30,  "r30"  >,  // r30r31.lo r28r29r30r31.z
      I64EnumAttrCase<"r31",  31,  "r31"  >,  // r30r31.hi r28r29r30r31.t
      I64EnumAttrCase<"r32",  32,  "r32"  >,  // r32r33.lo r32r33r34r35.x
      I64EnumAttrCase<"r33",  33,  "r33"  >,  // r32r33.hi r32r33r34r35.y
      I64EnumAttrCase<"r34",  34,  "r34"  >,  // r34r35.lo r32r33r34r35.z
      I64EnumAttrCase<"r35",  35,  "r35"  >,  // r34r35.hi r32r33r34r35.t
      I64EnumAttrCase<"r36",  36,  "r36"  >,  // r36r37.lo r36r37r38r39.x
      I64EnumAttrCase<"r37",  37,  "r37"  >,  // r36r37.hi r36r37r38r39.y
      I64EnumAttrCase<"r38",  38,  "r38"  >,  // r38r39.lo r36r37r38r39.z
      I64EnumAttrCase<"r39",  39,  "r39"  >,  // r38r39.hi r36r37r38r39.t
      I64EnumAttrCase<"r40",  40,  "r40"  >,  // r40r41.lo r40r41r42r43.x
      I64EnumAttrCase<"r41",  41,  "r41"  >,  // r40r41.hi r40r41r42r43.y
      I64EnumAttrCase<"r42",  42,  "r42"  >,  // r42r43.lo r40r41r42r43.z
      I64EnumAttrCase<"r43",  43,  "r43"  >,  // r42r43.hi r40r41r42r43.t
      I64EnumAttrCase<"r44",  44,  "r44"  >,  // r44r45.lo r44r45r46r47.x
      I64EnumAttrCase<"r45",  45,  "r45"  >,  // r44r45.hi r44r45r46r47.y
      I64EnumAttrCase<"r46",  46,  "r46"  >,  // r46r47.lo r44r45r46r47.z
      I64EnumAttrCase<"r47",  47,  "r47"  >,  // r46r47.hi r44r45r46r47.t
      I64EnumAttrCase<"r48",  48,  "r48"  >,  // r48r49.lo r48r49r50r51.x
      I64EnumAttrCase<"r49",  49,  "r49"  >,  // r48r49.hi r48r49r50r51.y
      I64EnumAttrCase<"r50",  50,  "r50"  >,  // r50r51.lo r48r49r50r51.z
      I64EnumAttrCase<"r51",  51,  "r51"  >,  // r50r51.hi r48r49r50r51.t
      I64EnumAttrCase<"r52",  52,  "r52"  >,  // r52r53.lo r52r53r54r55.x
      I64EnumAttrCase<"r53",  53,  "r53"  >,  // r52r53.hi r52r53r54r55.y
      I64EnumAttrCase<"r54",  54,  "r54"  >,  // r54r55.lo r52r53r54r55.z
      I64EnumAttrCase<"r55",  55,  "r55"  >,  // r54r55.hi r52r53r54r55.t
      I64EnumAttrCase<"r56",  56,  "r56"  >,  // r56r57.lo r56r57r58r59.x
      I64EnumAttrCase<"r57",  57,  "r57"  >,  // r56r57.hi r56r57r58r59.y
      I64EnumAttrCase<"r58",  58,  "r58"  >,  // r58r59.lo r56r57r58r59.z
      I64EnumAttrCase<"r59",  59,  "r59"  >,  // r58r59.hi r56r57r58r59.t
      I64EnumAttrCase<"r60",  60,  "r60"  >,  // r60r61.lo r60r61r62r63.x
      I64EnumAttrCase<"r61",  61,  "r61"  >,  // r60r61.hi r60r61r62r63.y
      I64EnumAttrCase<"r62",  62,  "r62"  >,  // r62r63.lo r60r61r62r63.z
      I64EnumAttrCase<"r63",  63,  "r63"  >,  // r62r63.hi r60r61r62r63.t
      I64EnumAttrCase<"ra",   67,  "ra"   >,  // s3
    ]> {
  let cppNamespace = "::mlir::lvx";
  // The enum parameterizes a type (`!lvx.reg<r5>`), it is never itself an
  // attribute on an op, so the specialized attribute class is not wanted.
  let genSpecializedAttr = 0;
}

#endif // LVX_REGISTERS
