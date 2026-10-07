//===-- LVXSchedule.td - LVX scheduling and bundling ------*- tablegen -*-===//
//
// Part of the LVX project, under the Apache License v2.0 with LLVM Exceptions.
// See LICENSE.TXT in the root of this repository for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// What a bundle can hold.  LVX is a VLIW: a bundle is up to eight 4-byte
// syllables, and -- this is the property the bundler leans on -- ANY
// resource-feasible parallel group of instructions can be encoded as a valid
// bundle.  So forming bundles needs no encoding knowledge at all, only the
// per-unit capacity of a bundle and the count each instruction occupies.
//
// This file is the LLVM counterpart of BE/GCC's scheduling-isa.md and
// lvx-issue-table.inc, and it is INTERIM AND HAND-DERIVED: it is generated
// from the itinerary class NAMES (which BE/LLVM does emit, in
// LVXInstrEncodings.td) by a rule proved against every plain reservation
// BE/GCC describes.  BE/LLVM should generate it from the Reservation
// description instead -- see lvx-csw/docs/handoff-mds-llvm-scheduling.md.
//
// REGENERATE IT, DO NOT EDIT IT:
//   validation/check-lvx-schedule.py --emit > LVXSchedule.td
// and run the same script with no argument to check it has not drifted.
//
// Two things to know before editing.
//
// THE SLOT GROUPS ARE NESTED, NOT DISJOINT.  A LITE op occupies a TINY slot as
// well; a FULL op occupies both; and so does every LSU op.  The class name
// states the deepest group the instruction reaches, so the groups in a name
// are unioned, never summed.  BCU2_TINY_LSU is what pins this: it names TINY
// and LSU and occupies ONE tiny slot.
//
// ISSUE SLOTS ARE NOT MODELLED HERE.  BE/GCC spends one `issue' unit per
// syllable (eight per bundle, the 32-byte LVX_SCHED2_BUNDLE_SIZE), and a _X or
// _Y class costs two or three because the immediate extension is one or two
// extra syllables.  In LLVM that count is already in the instruction: it is
// getInstSizeInBytes()/4, since the _X and _Y formats are LVXInst64 and
// LVXInst96.  The generator checks that identity on every format class rather
// than restating it, and LVXBundler caps a bundle at 32 bytes.  Leaving the
// eight issue units out also keeps the unit count at 26, inside the 32 a
// FuncUnit bitmask holds.
//
// The itinerary carries no LATENCY yet -- every stage is one cycle -- because
// nothing reads it: the only consumer is LVXBundler's resource counting, which
// looks at the units and ignores the cycles.  BE/GCC's scheduling.md keeps the
// real latencies and bypasses, and they belong here when post-RA scheduling
// gets turned on.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// The functional units, one def per physical unit of each group.
//===----------------------------------------------------------------------===//

def LVX_Tiny0 : FuncUnit; def LVX_Tiny1 : FuncUnit; def LVX_Tiny2 : FuncUnit; def LVX_Tiny3 : FuncUnit;
def LVX_Lite0 : FuncUnit; def LVX_Lite1 : FuncUnit;
def LVX_Full : FuncUnit;
def LVX_Lsu0 : FuncUnit; def LVX_Lsu1 : FuncUnit;
def LVX_Bcu0 : FuncUnit; def LVX_Bcu1 : FuncUnit;
def LVX_Ext0 : FuncUnit; def LVX_Ext1 : FuncUnit; def LVX_Ext2 : FuncUnit; def LVX_Ext3 : FuncUnit;
def LVX_Brrp0 : FuncUnit; def LVX_Brrp1 : FuncUnit;
def LVX_AuxR0 : FuncUnit; def LVX_AuxR1 : FuncUnit;
def LVX_AuxW0 : FuncUnit; def LVX_AuxW1 : FuncUnit;
def LVX_Xfer : FuncUnit;
def LVX_MemW : FuncUnit;
def LVX_Misc0 : FuncUnit; def LVX_Misc1 : FuncUnit;
def LVX_AccR : FuncUnit;

//===----------------------------------------------------------------------===//
// One stage def per group: "needs one unit of this group".  An instruction needing
// two units of a group gets the stage twice.  TimeInc is 0 throughout, so
// every stage of an itinerary sits in the same cycle -- these are parallel
// resources of one bundle, not pipeline stages.
//===----------------------------------------------------------------------===//

def LVXTinyStage : InstrStage<1, [LVX_Tiny0, LVX_Tiny1, LVX_Tiny2, LVX_Tiny3], 0>;
def LVXLiteStage : InstrStage<1, [LVX_Lite0, LVX_Lite1], 0>;
def LVXFullStage : InstrStage<1, [LVX_Full], 0>;
def LVXLsuStage : InstrStage<1, [LVX_Lsu0, LVX_Lsu1], 0>;
def LVXBcuStage : InstrStage<1, [LVX_Bcu0, LVX_Bcu1], 0>;
def LVXExtStage : InstrStage<1, [LVX_Ext0, LVX_Ext1, LVX_Ext2, LVX_Ext3], 0>;
def LVXBrrpStage : InstrStage<1, [LVX_Brrp0, LVX_Brrp1], 0>;
def LVXAuxRStage : InstrStage<1, [LVX_AuxR0, LVX_AuxR1], 0>;
def LVXAuxWStage : InstrStage<1, [LVX_AuxW0, LVX_AuxW1], 0>;
def LVXXferStage : InstrStage<1, [LVX_Xfer], 0>;
def LVXMemWStage : InstrStage<1, [LVX_MemW], 0>;
def LVXMiscStage : InstrStage<1, [LVX_Misc0, LVX_Misc1], 0>;
def LVXAccRStage : InstrStage<1, [LVX_AccR], 0>;

//===----------------------------------------------------------------------===//
// The itineraries.  One entry per class LVXInstrEncodings.td declares; a class
// no instruction in the installed description uses simply goes unreferenced.
//===----------------------------------------------------------------------===//

def LVXItineraries : ProcessorItineraries<[
  LVX_Tiny0, LVX_Tiny1, LVX_Tiny2, LVX_Tiny3, LVX_Lite0, LVX_Lite1,
  LVX_Full, LVX_Lsu0, LVX_Lsu1, LVX_Bcu0, LVX_Bcu1, LVX_Ext0,
  LVX_Ext1, LVX_Ext2, LVX_Ext3, LVX_Brrp0, LVX_Brrp1, LVX_AuxR0,
  LVX_AuxR1, LVX_AuxW0, LVX_AuxW1, LVX_Xfer, LVX_MemW, LVX_Misc0,
  LVX_Misc1, LVX_AccR
], [], [
  InstrItinData<ALL,                   [LVXTinyStage, LVXLiteStage, LVXFullStage, LVXLsuStage, LVXBcuStage, LVXExtStage, LVXBrrpStage, LVXAuxRStage, LVXAuxWStage, LVXXferStage, LVXMemWStage, LVXMiscStage, LVXAccRStage]>,
  InstrItinData<BCU,                   [LVXBcuStage]>,   // not in BE/GCC: derived from the name alone
  InstrItinData<BCU_XFER,              [LVXBcuStage, LVXXferStage]>,
  InstrItinData<BCU_XFER_BRRP,         [LVXBcuStage, LVXBrrpStage, LVXXferStage]>,
  InstrItinData<BCU_BRRP,              [LVXBcuStage, LVXBrrpStage]>,
  InstrItinData<BCU_BRRP2,             [LVXBcuStage, LVXBrrpStage, LVXBrrpStage]>,
  InstrItinData<BCU2,                  [LVXBcuStage, LVXBcuStage]>,
  InstrItinData<BCU2_X,                [LVXBcuStage, LVXBcuStage]>,
  InstrItinData<BCU2_TINY_LSU,         [LVXTinyStage, LVXLsuStage, LVXBcuStage, LVXBcuStage]>,
  InstrItinData<ALU_TINY,              [LVXTinyStage]>,
  InstrItinData<ALU_TINY_X,            [LVXTinyStage]>,
  InstrItinData<ALU_TINY_Y,            [LVXTinyStage]>,
  InstrItinData<ALU_TINY_AUXR,         [LVXTinyStage, LVXAuxRStage]>,   // not in BE/GCC: derived from the name alone
  InstrItinData<ALU_LITE,              [LVXTinyStage, LVXLiteStage]>,
  InstrItinData<ALU_LITE_X,            [LVXTinyStage, LVXLiteStage]>,
  InstrItinData<ALU_LITE_Y,            [LVXTinyStage, LVXLiteStage]>,
  InstrItinData<ALU_LITE_MISC,         [LVXTinyStage, LVXLiteStage, LVXMiscStage]>,
  InstrItinData<ALU_FULL,              [LVXTinyStage, LVXLiteStage, LVXFullStage]>,
  InstrItinData<ALU_FULL_X,            [LVXTinyStage, LVXLiteStage, LVXFullStage]>,
  InstrItinData<ALU_FULL_Y,            [LVXTinyStage, LVXLiteStage, LVXFullStage]>,   // not in BE/GCC: derived from the name alone
  InstrItinData<LSU,                   [LVXTinyStage, LVXLsuStage]>,
  InstrItinData<LSU_X,                 [LVXTinyStage, LVXLsuStage]>,
  InstrItinData<LSU_Y,                 [LVXTinyStage, LVXLsuStage]>,
  InstrItinData<LSU_MEMW_ACCR,         [LVXTinyStage, LVXLsuStage, LVXMemWStage, LVXAccRStage]>,
  InstrItinData<LSU_MEMW_ACCR_X,       [LVXTinyStage, LVXLsuStage, LVXMemWStage, LVXAccRStage]>,
  InstrItinData<LSU_MEMW_ACCR_Y,       [LVXTinyStage, LVXLsuStage, LVXMemWStage, LVXAccRStage]>,
  InstrItinData<LSU2_MEMW,             [LVXTinyStage, LVXLsuStage, LVXLsuStage, LVXMemWStage]>,
  InstrItinData<LSU2_MEMW_X,           [LVXTinyStage, LVXLsuStage, LVXLsuStage, LVXMemWStage]>,
  InstrItinData<LSU2_MEMW_Y,           [LVXTinyStage, LVXLsuStage, LVXLsuStage, LVXMemWStage]>,
  InstrItinData<LSU_AUXR,              [LVXTinyStage, LVXLsuStage, LVXAuxRStage]>,   // not in BE/GCC: derived from the name alone
  InstrItinData<LSU_AUXR_X,            [LVXTinyStage, LVXLsuStage, LVXAuxRStage]>,   // not in BE/GCC: derived from the name alone
  InstrItinData<LSU_AUXR_Y,            [LVXTinyStage, LVXLsuStage, LVXAuxRStage]>,   // not in BE/GCC: derived from the name alone
  InstrItinData<LSU_MEMW_AUXR,         [LVXTinyStage, LVXLsuStage, LVXAuxRStage, LVXMemWStage]>,
  InstrItinData<LSU_MEMW_AUXR_X,       [LVXTinyStage, LVXLsuStage, LVXAuxRStage, LVXMemWStage]>,
  InstrItinData<LSU_MEMW_AUXR_Y,       [LVXTinyStage, LVXLsuStage, LVXAuxRStage, LVXMemWStage]>,
  InstrItinData<LSU2_MEMW_AUXR,        [LVXTinyStage, LVXLsuStage, LVXLsuStage, LVXAuxRStage, LVXMemWStage]>,   // not in BE/GCC: derived from the name alone
  InstrItinData<LSU2_MEMW_AUXR_X,      [LVXTinyStage, LVXLsuStage, LVXLsuStage, LVXAuxRStage, LVXMemWStage]>,   // not in BE/GCC: derived from the name alone
  InstrItinData<LSU2_MEMW_AUXR_Y,      [LVXTinyStage, LVXLsuStage, LVXLsuStage, LVXAuxRStage, LVXMemWStage]>,   // not in BE/GCC: derived from the name alone
  InstrItinData<LSU_MEMW_AUXW,         [LVXTinyStage, LVXLsuStage, LVXAuxWStage, LVXMemWStage]>,
  InstrItinData<LSU_MEMW_AUXW_X,       [LVXTinyStage, LVXLsuStage, LVXAuxWStage, LVXMemWStage]>,
  InstrItinData<LSU_MEMW_AUXW_Y,       [LVXTinyStage, LVXLsuStage, LVXAuxWStage, LVXMemWStage]>,
  InstrItinData<LSU2_MEMW_AUXW,        [LVXTinyStage, LVXLsuStage, LVXLsuStage, LVXAuxWStage, LVXMemWStage]>,
  InstrItinData<LSU2_MEMW_AUXW_X,      [LVXTinyStage, LVXLsuStage, LVXLsuStage, LVXAuxWStage, LVXMemWStage]>,
  InstrItinData<LSU2_MEMW_AUXW_Y,      [LVXTinyStage, LVXLsuStage, LVXLsuStage, LVXAuxWStage, LVXMemWStage]>,
  InstrItinData<LSU_AUXW,              [LVXTinyStage, LVXLsuStage, LVXAuxWStage]>,
  InstrItinData<LSU_AUXW_X,            [LVXTinyStage, LVXLsuStage, LVXAuxWStage]>,
  InstrItinData<LSU_AUXW_Y,            [LVXTinyStage, LVXLsuStage, LVXAuxWStage]>,
  InstrItinData<LSU_AUXR_AUXW,         [LVXTinyStage, LVXLsuStage, LVXAuxRStage, LVXAuxWStage]>,
  InstrItinData<LSU_AUXR_AUXW_X,       [LVXTinyStage, LVXLsuStage, LVXAuxRStage, LVXAuxWStage]>,   // not in BE/GCC: derived from the name alone
  InstrItinData<LSU_AUXR_AUXW_Y,       [LVXTinyStage, LVXLsuStage, LVXAuxRStage, LVXAuxWStage]>,   // not in BE/GCC: derived from the name alone
  InstrItinData<LSU2_MEMW_AUXR_AUXW,   [LVXTinyStage, LVXLsuStage, LVXLsuStage, LVXAuxRStage, LVXAuxWStage, LVXMemWStage]>,
  InstrItinData<LSU2_MEMW_AUXR_AUXW_X, [LVXTinyStage, LVXLsuStage, LVXLsuStage, LVXAuxRStage, LVXAuxWStage, LVXMemWStage]>,
  InstrItinData<LSU2_MEMW_AUXR_AUXW_Y, [LVXTinyStage, LVXLsuStage, LVXLsuStage, LVXAuxRStage, LVXAuxWStage, LVXMemWStage]>,
  InstrItinData<EXT,                   [LVXExtStage]>,
  InstrItinData<EXT_COMP,              [LVXExtStage]>,   // not in BE/GCC: derived from the name alone
  InstrItinData<EXT_MISC,              [LVXExtStage, LVXMiscStage]>,   // not in BE/GCC: derived from the name alone
  InstrItinData<EXT_MISC_AUXW,         [LVXExtStage, LVXAuxWStage, LVXMiscStage]>,
]>;

//===----------------------------------------------------------------------===//
// The processor model.  The itinerary is attached so that
// LVXSubtarget::getInstrItineraryData() returns it and LVXBundler can read the
// unit counts out of it; nothing else consumes the model yet, so it stays
// incomplete and no scheduler is driven by it.
//===----------------------------------------------------------------------===//

def LVXModel : SchedMachineModel {
  let Itineraries = LVXItineraries;
  let CompleteModel = 0;
}

def : ProcessorModel<"generic", LVXModel, []>;

// The two ISA variants, named as lvx-gcc's -march names them and as the clang
// driver passes them through -mcpu. They carry no features: the description
// installed into this directory is one core's at a time (see lvx-mds's
// BE/LLVM), so which instructions exist is decided before the build, not by a
// SubtargetFeature. They exist so that -mcpu=lvx-1 names a processor this
// target knows rather than drawing "not a recognized processor"; when the two
// descriptions are merged into one build, this is where the feature that tells
// them apart goes.
def : ProcessorModel<"lvx-1", LVXModel, []>;
def : ProcessorModel<"lvx-2", LVXModel, []>;
