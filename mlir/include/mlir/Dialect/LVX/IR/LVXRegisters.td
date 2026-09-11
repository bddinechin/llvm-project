//===-- LVXRegisters.td - -*- tablegen -*- ===//
//
// Physical register enum for the LVX dialect's register type.
//
// Generated from the LVX Machine Description System by MDS/BE/MLIR, for core
// lvx_v2.  DO NOT EDIT -- your changes will be overwritten by the next
// `make -C BE/MLIR install`.  Change lvx-mds/lvx-family's YAML description,
// or the generator in MDS/BE/MLIR/BIN, instead.
//
//===----------------------------------------------------------------===//

#ifndef LVX_REGISTERS
#define LVX_REGISTERS

include "mlir/IR/EnumAttr.td"

// The 256 registers a value can be pinned to: the 64-register unified
// general-purpose file, which holds scalar integer and floating-point alike,
// plus the 192-register system file (SFR).
//
// The system registers are here so that `get`, `set`, `rswap`, `wfxl` and
// `wfxm` can name their operand -- design document O5.  They are NOT
// allocatable: nothing puts them in the allocation pool, which is built from
// the calling convention's caller/callee sets (LVXConvention.inc), and both
// are subsets of the general-purpose file.
//
// Values are dwarfId, so they are the ISA's own numbering rather than a
// position in this list.  Do not assume they are dense.
def LVX_RegisterAttr : I64EnumAttr<
    "Register", "an lvx physical register",
    [
      I64EnumAttrCase<"r0",     0,   "r0"     >,  // r0r1.lo r0r1r2r3.x
      I64EnumAttrCase<"r1",     1,   "r1"     >,  // r0r1.hi r0r1r2r3.y
      I64EnumAttrCase<"r2",     2,   "r2"     >,  // r2r3.lo r0r1r2r3.z
      I64EnumAttrCase<"r3",     3,   "r3"     >,  // r2r3.hi r0r1r2r3.t
      I64EnumAttrCase<"r4",     4,   "r4"     >,  // r4r5.lo r4r5r6r7.x
      I64EnumAttrCase<"r5",     5,   "r5"     >,  // r4r5.hi r4r5r6r7.y
      I64EnumAttrCase<"r6",     6,   "r6"     >,  // r6r7.lo r4r5r6r7.z
      I64EnumAttrCase<"r7",     7,   "r7"     >,  // r6r7.hi r4r5r6r7.t
      I64EnumAttrCase<"r8",     8,   "r8"     >,  // r8r9.lo r8r9r10r11.x
      I64EnumAttrCase<"r9",     9,   "r9"     >,  // r8r9.hi r8r9r10r11.y
      I64EnumAttrCase<"r10",    10,  "r10"    >,  // r10r11.lo r8r9r10r11.z
      I64EnumAttrCase<"r11",    11,  "r11"    >,  // r10r11.hi r8r9r10r11.t
      I64EnumAttrCase<"r12",    12,  "r12"    >,  // sp
      I64EnumAttrCase<"r13",    13,  "r13"    >,  // tp
      I64EnumAttrCase<"r14",    14,  "r14"    >,  // fp r14r15.lo
      I64EnumAttrCase<"r15",    15,  "r15"    >,  // rp r14r15.hi
      I64EnumAttrCase<"r16",    16,  "r16"    >,  // r16r17.lo r16r17r18r19.x
      I64EnumAttrCase<"r17",    17,  "r17"    >,  // r16r17.hi r16r17r18r19.y
      I64EnumAttrCase<"r18",    18,  "r18"    >,  // r18r19.lo r16r17r18r19.z
      I64EnumAttrCase<"r19",    19,  "r19"    >,  // r18r19.hi r16r17r18r19.t
      I64EnumAttrCase<"r20",    20,  "r20"    >,  // r20r21.lo r20r21r22r23.x
      I64EnumAttrCase<"r21",    21,  "r21"    >,  // r20r21.hi r20r21r22r23.y
      I64EnumAttrCase<"r22",    22,  "r22"    >,  // r22r23.lo r20r21r22r23.z
      I64EnumAttrCase<"r23",    23,  "r23"    >,  // r22r23.hi r20r21r22r23.t
      I64EnumAttrCase<"r24",    24,  "r24"    >,  // r24r25.lo r24r25r26r27.x
      I64EnumAttrCase<"r25",    25,  "r25"    >,  // r24r25.hi r24r25r26r27.y
      I64EnumAttrCase<"r26",    26,  "r26"    >,  // r26r27.lo r24r25r26r27.z
      I64EnumAttrCase<"r27",    27,  "r27"    >,  // r26r27.hi r24r25r26r27.t
      I64EnumAttrCase<"r28",    28,  "r28"    >,  // r28r29.lo r28r29r30r31.x
      I64EnumAttrCase<"r29",    29,  "r29"    >,  // r28r29.hi r28r29r30r31.y
      I64EnumAttrCase<"r30",    30,  "r30"    >,  // r30r31.lo r28r29r30r31.z
      I64EnumAttrCase<"r31",    31,  "r31"    >,  // r30r31.hi r28r29r30r31.t
      I64EnumAttrCase<"r32",    32,  "r32"    >,  // r32r33.lo r32r33r34r35.x
      I64EnumAttrCase<"r33",    33,  "r33"    >,  // r32r33.hi r32r33r34r35.y
      I64EnumAttrCase<"r34",    34,  "r34"    >,  // r34r35.lo r32r33r34r35.z
      I64EnumAttrCase<"r35",    35,  "r35"    >,  // r34r35.hi r32r33r34r35.t
      I64EnumAttrCase<"r36",    36,  "r36"    >,  // r36r37.lo r36r37r38r39.x
      I64EnumAttrCase<"r37",    37,  "r37"    >,  // r36r37.hi r36r37r38r39.y
      I64EnumAttrCase<"r38",    38,  "r38"    >,  // r38r39.lo r36r37r38r39.z
      I64EnumAttrCase<"r39",    39,  "r39"    >,  // r38r39.hi r36r37r38r39.t
      I64EnumAttrCase<"r40",    40,  "r40"    >,  // r40r41.lo r40r41r42r43.x
      I64EnumAttrCase<"r41",    41,  "r41"    >,  // r40r41.hi r40r41r42r43.y
      I64EnumAttrCase<"r42",    42,  "r42"    >,  // r42r43.lo r40r41r42r43.z
      I64EnumAttrCase<"r43",    43,  "r43"    >,  // r42r43.hi r40r41r42r43.t
      I64EnumAttrCase<"r44",    44,  "r44"    >,  // r44r45.lo r44r45r46r47.x
      I64EnumAttrCase<"r45",    45,  "r45"    >,  // r44r45.hi r44r45r46r47.y
      I64EnumAttrCase<"r46",    46,  "r46"    >,  // r46r47.lo r44r45r46r47.z
      I64EnumAttrCase<"r47",    47,  "r47"    >,  // r46r47.hi r44r45r46r47.t
      I64EnumAttrCase<"r48",    48,  "r48"    >,  // r48r49.lo r48r49r50r51.x
      I64EnumAttrCase<"r49",    49,  "r49"    >,  // r48r49.hi r48r49r50r51.y
      I64EnumAttrCase<"r50",    50,  "r50"    >,  // r50r51.lo r48r49r50r51.z
      I64EnumAttrCase<"r51",    51,  "r51"    >,  // r50r51.hi r48r49r50r51.t
      I64EnumAttrCase<"r52",    52,  "r52"    >,  // r52r53.lo r52r53r54r55.x
      I64EnumAttrCase<"r53",    53,  "r53"    >,  // r52r53.hi r52r53r54r55.y
      I64EnumAttrCase<"r54",    54,  "r54"    >,  // r54r55.lo r52r53r54r55.z
      I64EnumAttrCase<"r55",    55,  "r55"    >,  // r54r55.hi r52r53r54r55.t
      I64EnumAttrCase<"r56",    56,  "r56"    >,  // r56r57.lo r56r57r58r59.x
      I64EnumAttrCase<"r57",    57,  "r57"    >,  // r56r57.hi r56r57r58r59.y
      I64EnumAttrCase<"r58",    58,  "r58"    >,  // r58r59.lo r56r57r58r59.z
      I64EnumAttrCase<"r59",    59,  "r59"    >,  // r58r59.hi r56r57r58r59.t
      I64EnumAttrCase<"r60",    60,  "r60"    >,  // r60r61.lo r60r61r62r63.x
      I64EnumAttrCase<"r61",    61,  "r61"    >,  // r60r61.hi r60r61r62r63.y
      I64EnumAttrCase<"r62",    62,  "r62"    >,  // r62r63.lo r60r61r62r63.z
      I64EnumAttrCase<"r63",    63,  "r63"    >,  // r62r63.hi r60r61r62r63.t
      I64EnumAttrCase<"pc",     64,  "pc"     >,  // s0
      I64EnumAttrCase<"ps",     65,  "ps"     >,  // s1
      I64EnumAttrCase<"pcr",    66,  "pcr"    >,  // s2
      I64EnumAttrCase<"ra",     67,  "ra"     >,  // s3
      I64EnumAttrCase<"cs",     68,  "cs"     >,  // s4
      I64EnumAttrCase<"csit",   69,  "csit"   >,  // s5
      I64EnumAttrCase<"aespc",  70,  "aespc"  >,  // s6
      I64EnumAttrCase<"ls",     71,  "ls"     >,  // s7
      I64EnumAttrCase<"le",     72,  "le"     >,  // s8
      I64EnumAttrCase<"lc",     73,  "lc"     >,  // s9
      I64EnumAttrCase<"ipe",    74,  "ipe"    >,  // s10
      I64EnumAttrCase<"men",    75,  "men"    >,  // s11
      I64EnumAttrCase<"pmc",    76,  "pmc"    >,  // s12
      I64EnumAttrCase<"pm0",    77,  "pm0"    >,  // s13
      I64EnumAttrCase<"pm1",    78,  "pm1"    >,  // s14
      I64EnumAttrCase<"pm2",    79,  "pm2"    >,  // s15
      I64EnumAttrCase<"pm3",    80,  "pm3"    >,  // s16
      I64EnumAttrCase<"pmsa",   81,  "pmsa"   >,  // s17
      I64EnumAttrCase<"tcr",    82,  "tcr"    >,  // s18
      I64EnumAttrCase<"t0v",    83,  "t0v"    >,  // s19
      I64EnumAttrCase<"t1v",    84,  "t1v"    >,  // s20
      I64EnumAttrCase<"t0r",    85,  "t0r"    >,  // s21
      I64EnumAttrCase<"t1r",    86,  "t1r"    >,  // s22
      I64EnumAttrCase<"wdv",    87,  "wdv"    >,  // s23
      I64EnumAttrCase<"wdr",    88,  "wdr"    >,  // s24
      I64EnumAttrCase<"ile",    89,  "ile"    >,  // s25
      I64EnumAttrCase<"ill",    90,  "ill"    >,  // s26
      I64EnumAttrCase<"ilr",    91,  "ilr"    >,  // s27
      I64EnumAttrCase<"mmc",    92,  "mmc"    >,  // s28
      I64EnumAttrCase<"tel",    93,  "tel"    >,  // s29
      I64EnumAttrCase<"teh",    94,  "teh"    >,  // s30
      I64EnumAttrCase<"ixc",    95,  "ixc"    >,  // s31
      I64EnumAttrCase<"syo",    96,  "syo"    >,  // s32
      I64EnumAttrCase<"hto",    97,  "hto"    >,  // s33
      I64EnumAttrCase<"ito",    98,  "ito"    >,  // s34
      I64EnumAttrCase<"do_",    99,  "do"     >,  // s35
      I64EnumAttrCase<"mo",     100, "mo"     >,  // s36
      I64EnumAttrCase<"pso",    101, "pso"    >,  // s37
      I64EnumAttrCase<"tpcm0",  102, "tpcm0"  >,  // s38
      I64EnumAttrCase<"tpcm1",  103, "tpcm1"  >,  // s39
      I64EnumAttrCase<"res40",  104, "res40"  >,  // s40
      I64EnumAttrCase<"dba0",   105, "dba0"   >,  // s41
      I64EnumAttrCase<"dba1",   106, "dba1"   >,  // s42
      I64EnumAttrCase<"dwa0",   107, "dwa0"   >,  // s43
      I64EnumAttrCase<"dwa1",   108, "dwa1"   >,  // s44
      I64EnumAttrCase<"mes",    109, "mes"    >,  // s45
      I64EnumAttrCase<"ws",     110, "ws"     >,  // s46
      I64EnumAttrCase<"dc0",    111, "dc0"    >,  // s47
      I64EnumAttrCase<"dc1",    112, "dc1"    >,  // s48
      I64EnumAttrCase<"dc2",    113, "dc2"    >,  // s49
      I64EnumAttrCase<"dc3",    114, "dc3"    >,  // s50
      I64EnumAttrCase<"dba2",   115, "dba2"   >,  // s51
      I64EnumAttrCase<"dba3",   116, "dba3"   >,  // s52
      I64EnumAttrCase<"dwa2",   117, "dwa2"   >,  // s53
      I64EnumAttrCase<"dwa3",   118, "dwa3"   >,  // s54
      I64EnumAttrCase<"tpcm2",  119, "tpcm2"  >,  // s55
      I64EnumAttrCase<"tpcmc",  120, "tpcmc"  >,  // s56
      I64EnumAttrCase<"pm4",    121, "pm4"    >,  // s57
      I64EnumAttrCase<"pm5",    122, "pm5"    >,  // s58
      I64EnumAttrCase<"pm6",    123, "pm6"    >,  // s59
      I64EnumAttrCase<"pm7",    124, "pm7"    >,  // s60
      I64EnumAttrCase<"pmc2",   125, "pmc2"   >,  // s61
      I64EnumAttrCase<"srhpc",  126, "srhpc"  >,  // s62
      I64EnumAttrCase<"frcc",   127, "frcc"   >,  // s63
      I64EnumAttrCase<"spc_pl0", 128, "spc_pl0">,  // s64
      I64EnumAttrCase<"spc_pl1", 129, "spc_pl1">,  // s65
      I64EnumAttrCase<"spc_pl2", 130, "spc_pl2">,  // s66
      I64EnumAttrCase<"spc_pl3", 131, "spc_pl3">,  // s67
      I64EnumAttrCase<"sps_pl0", 132, "sps_pl0">,  // s68
      I64EnumAttrCase<"sps_pl1", 133, "sps_pl1">,  // s69
      I64EnumAttrCase<"sps_pl2", 134, "sps_pl2">,  // s70
      I64EnumAttrCase<"sps_pl3", 135, "sps_pl3">,  // s71
      I64EnumAttrCase<"ea_pl0", 136, "ea_pl0" >,  // s72
      I64EnumAttrCase<"ea_pl1", 137, "ea_pl1" >,  // s73
      I64EnumAttrCase<"ea_pl2", 138, "ea_pl2" >,  // s74
      I64EnumAttrCase<"ea_pl3", 139, "ea_pl3" >,  // s75
      I64EnumAttrCase<"ev_pl0", 140, "ev_pl0" >,  // s76
      I64EnumAttrCase<"ev_pl1", 141, "ev_pl1" >,  // s77
      I64EnumAttrCase<"ev_pl2", 142, "ev_pl2" >,  // s78
      I64EnumAttrCase<"ev_pl3", 143, "ev_pl3" >,  // s79
      I64EnumAttrCase<"sr_pl0", 144, "sr_pl0" >,  // s80
      I64EnumAttrCase<"sr_pl1", 145, "sr_pl1" >,  // s81
      I64EnumAttrCase<"sr_pl2", 146, "sr_pl2" >,  // s82
      I64EnumAttrCase<"sr_pl3", 147, "sr_pl3" >,  // s83
      I64EnumAttrCase<"es_pl0", 148, "es_pl0" >,  // s84
      I64EnumAttrCase<"es_pl1", 149, "es_pl1" >,  // s85
      I64EnumAttrCase<"es_pl2", 150, "es_pl2" >,  // s86
      I64EnumAttrCase<"es_pl3", 151, "es_pl3" >,  // s87
      I64EnumAttrCase<"sid_pl0", 152, "sid_pl0">,  // s88
      I64EnumAttrCase<"sid_pl1", 153, "sid_pl1">,  // s89
      I64EnumAttrCase<"sid_pl2", 154, "sid_pl2">,  // s90
      I64EnumAttrCase<"sid_pl3", 155, "sid_pl3">,  // s91
      I64EnumAttrCase<"sr1_pl0", 156, "sr1_pl0">,  // s92
      I64EnumAttrCase<"sr1_pl1", 157, "sr1_pl1">,  // s93
      I64EnumAttrCase<"sr1_pl2", 158, "sr1_pl2">,  // s94
      I64EnumAttrCase<"sr1_pl3", 159, "sr1_pl3">,  // s95
      I64EnumAttrCase<"syow",   160, "syow"   >,  // s96
      I64EnumAttrCase<"htow",   161, "htow"   >,  // s97
      I64EnumAttrCase<"itow",   162, "itow"   >,  // s98
      I64EnumAttrCase<"dow",    163, "dow"    >,  // s99
      I64EnumAttrCase<"mow",    164, "mow"    >,  // s100
      I64EnumAttrCase<"psow",   165, "psow"   >,  // s101
      I64EnumAttrCase<"res102", 166, "res102" >,  // s102
      I64EnumAttrCase<"res103", 167, "res103" >,  // s103
      I64EnumAttrCase<"tpcc_pl0", 168, "tpcc_pl0">,  // s104
      I64EnumAttrCase<"tpcc_pl1", 169, "tpcc_pl1">,  // s105
      I64EnumAttrCase<"tpcc_pl2", 170, "tpcc_pl2">,  // s106
      I64EnumAttrCase<"tpcc_pl3", 171, "tpcc_pl3">,  // s107
      I64EnumAttrCase<"res108", 172, "res108" >,  // s108
      I64EnumAttrCase<"res109", 173, "res109" >,  // s109
      I64EnumAttrCase<"res110", 174, "res110" >,  // s110
      I64EnumAttrCase<"res111", 175, "res111" >,  // s111
      I64EnumAttrCase<"res112", 176, "res112" >,  // s112
      I64EnumAttrCase<"res113", 177, "res113" >,  // s113
      I64EnumAttrCase<"res114", 178, "res114" >,  // s114
      I64EnumAttrCase<"res115", 179, "res115" >,  // s115
      I64EnumAttrCase<"res116", 180, "res116" >,  // s116
      I64EnumAttrCase<"res117", 181, "res117" >,  // s117
      I64EnumAttrCase<"res118", 182, "res118" >,  // s118
      I64EnumAttrCase<"res119", 183, "res119" >,  // s119
      I64EnumAttrCase<"res120", 184, "res120" >,  // s120
      I64EnumAttrCase<"res121", 185, "res121" >,  // s121
      I64EnumAttrCase<"res122", 186, "res122" >,  // s122
      I64EnumAttrCase<"res123", 187, "res123" >,  // s123
      I64EnumAttrCase<"res124", 188, "res124" >,  // s124
      I64EnumAttrCase<"res125", 189, "res125" >,  // s125
      I64EnumAttrCase<"res126", 190, "res126" >,  // s126
      I64EnumAttrCase<"res127", 191, "res127" >,  // s127
      I64EnumAttrCase<"spc",    192, "spc"    >,  // s128
      I64EnumAttrCase<"res129", 193, "res129" >,  // s129
      I64EnumAttrCase<"res130", 194, "res130" >,  // s130
      I64EnumAttrCase<"res131", 195, "res131" >,  // s131
      I64EnumAttrCase<"sps",    196, "sps"    >,  // s132
      I64EnumAttrCase<"res133", 197, "res133" >,  // s133
      I64EnumAttrCase<"res134", 198, "res134" >,  // s134
      I64EnumAttrCase<"res135", 199, "res135" >,  // s135
      I64EnumAttrCase<"ea",     200, "ea"     >,  // s136
      I64EnumAttrCase<"res137", 201, "res137" >,  // s137
      I64EnumAttrCase<"res138", 202, "res138" >,  // s138
      I64EnumAttrCase<"res139", 203, "res139" >,  // s139
      I64EnumAttrCase<"ev",     204, "ev"     >,  // s140
      I64EnumAttrCase<"res141", 205, "res141" >,  // s141
      I64EnumAttrCase<"res142", 206, "res142" >,  // s142
      I64EnumAttrCase<"res143", 207, "res143" >,  // s143
      I64EnumAttrCase<"sr",     208, "sr"     >,  // s144
      I64EnumAttrCase<"res145", 209, "res145" >,  // s145
      I64EnumAttrCase<"res146", 210, "res146" >,  // s146
      I64EnumAttrCase<"res147", 211, "res147" >,  // s147
      I64EnumAttrCase<"es",     212, "es"     >,  // s148
      I64EnumAttrCase<"res149", 213, "res149" >,  // s149
      I64EnumAttrCase<"res150", 214, "res150" >,  // s150
      I64EnumAttrCase<"res151", 215, "res151" >,  // s151
      I64EnumAttrCase<"sid",    216, "sid"    >,  // s152
      I64EnumAttrCase<"res153", 217, "res153" >,  // s153
      I64EnumAttrCase<"res154", 218, "res154" >,  // s154
      I64EnumAttrCase<"res155", 219, "res155" >,  // s155
      I64EnumAttrCase<"sr1",    220, "sr1"    >,  // s156
      I64EnumAttrCase<"res157", 221, "res157" >,  // s157
      I64EnumAttrCase<"res158", 222, "res158" >,  // s158
      I64EnumAttrCase<"res159", 223, "res159" >,  // s159
      I64EnumAttrCase<"res160", 224, "res160" >,  // s160
      I64EnumAttrCase<"res161", 225, "res161" >,  // s161
      I64EnumAttrCase<"res162", 226, "res162" >,  // s162
      I64EnumAttrCase<"res163", 227, "res163" >,  // s163
      I64EnumAttrCase<"res164", 228, "res164" >,  // s164
      I64EnumAttrCase<"res165", 229, "res165" >,  // s165
      I64EnumAttrCase<"res166", 230, "res166" >,  // s166
      I64EnumAttrCase<"res167", 231, "res167" >,  // s167
      I64EnumAttrCase<"tpcc",   232, "tpcc"   >,  // s168
      I64EnumAttrCase<"res169", 233, "res169" >,  // s169
      I64EnumAttrCase<"res170", 234, "res170" >,  // s170
      I64EnumAttrCase<"res171", 235, "res171" >,  // s171
      I64EnumAttrCase<"res172", 236, "res172" >,  // s172
      I64EnumAttrCase<"res173", 237, "res173" >,  // s173
      I64EnumAttrCase<"res174", 238, "res174" >,  // s174
      I64EnumAttrCase<"res175", 239, "res175" >,  // s175
      I64EnumAttrCase<"res176", 240, "res176" >,  // s176
      I64EnumAttrCase<"res177", 241, "res177" >,  // s177
      I64EnumAttrCase<"res178", 242, "res178" >,  // s178
      I64EnumAttrCase<"res179", 243, "res179" >,  // s179
      I64EnumAttrCase<"res180", 244, "res180" >,  // s180
      I64EnumAttrCase<"res181", 245, "res181" >,  // s181
      I64EnumAttrCase<"res182", 246, "res182" >,  // s182
      I64EnumAttrCase<"res183", 247, "res183" >,  // s183
      I64EnumAttrCase<"res184", 248, "res184" >,  // s184
      I64EnumAttrCase<"res185", 249, "res185" >,  // s185
      I64EnumAttrCase<"res186", 250, "res186" >,  // s186
      I64EnumAttrCase<"res187", 251, "res187" >,  // s187
      I64EnumAttrCase<"res188", 252, "res188" >,  // s188
      I64EnumAttrCase<"res189", 253, "res189" >,  // s189
      I64EnumAttrCase<"res190", 254, "res190" >,  // s190
      I64EnumAttrCase<"res191", 255, "res191" >,  // s191
    ]> {
  let cppNamespace = "::mlir::lvx";
  // The enum parameterizes a type (`!lvx.reg<r5>`), it is never itself an
  // attribute on an op, so the specialized attribute class is not wanted.
  let genSpecializedAttr = 0;
}

#endif // LVX_REGISTERS
