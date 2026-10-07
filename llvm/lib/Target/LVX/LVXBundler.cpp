//===-- LVXBundler.cpp - Form LVX VLIW bundles ----------------------------===//
//
// Part of the LVX project, under the Apache License v2.0 with LLVM Exceptions.
// See LICENSE.TXT in the root of this repository for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Groups consecutive independent instructions into VLIW bundles, so that the
// assembler's ";;" terminator falls once per bundle instead of once per
// instruction.
//
// WHY THIS IS SO SHORT.  On LVX, any resource-feasible parallel group of
// instructions can be encoded as a valid bundle: there is no slot assignment
// to solve, no ordering rule among the syllables, no pairing constraint. So
// the whole decision is
//
//   (1) do the instructions fit the bundle's units,          and
//   (2) are they independent?
//
// (1) comes out of the itinerary in LVXSchedule.td and needs no target
// knowledge here at all -- see haveRoomFor below. (2) is a register and memory
// test over physical registers, which is all that is left this late.
//
// That also means a mistake here cannot produce a silently wrong encoding: the
// assembler validates every bundle it is handed and rejects an infeasible one,
// so over-packing is a build failure rather than wrong code. What a mistake
// CAN produce is wrong code through a missed dependence, which is why the
// dependence test below is conservative in every direction it is unsure of.
//
// HOW THIS RELATES TO lvx-gcc.  GCC forms the same bundles out of the sched2
// post-pass schedule: the automaton in scheduling-isa.md enforces
// feasibility, TARGET_SCHED_DFA_NEW_CYCLE caps the bundle at
// LVX_SCHED2_BUNDLE_SIZE (32 bytes = eight syllables), and instructions landing
// in one clock become one bundle. Two differences, both deliberate:
//
//   - There is no post-RA SCHEDULING here yet, only bundling, so this packs
//     instructions in the order the register allocator left them. Independent
//     work that a scheduler would have brought together stays apart. Turning
//     on post-RA scheduling is the next step and wants the latencies BE/GCC's
//     scheduling.md already has; see the MDS handoff.
//   - lvx-gcc also accounts for the GUARD/MASKS/MASKM prefix syllable, which
//     two ops of one bundle can share. The LLVM back end emits no predicated
//     or masked instruction (it uses none of the mask predication family), so
//     there is nothing here to share; an instruction whose itinerary claims a
//     BRRP unit is treated as solo below so that this stays true by
//     construction rather than by assumption.
//
//===----------------------------------------------------------------------===//

#include "LVXISelDAGToDAG.h"   // createLVXBundlerPass
#include "LVXInstrInfo.h"
#include "LVXSubtarget.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineInstrBundle.h"
#include "llvm/CodeGen/TargetRegisterInfo.h"
#include "llvm/MC/MCInstrItineraries.h"
#include "llvm/InitializePasses.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

#define DEBUG_TYPE "lvx-bundler"

STATISTIC(NumBundles, "Number of bundles formed (of two or more instructions)");
STATISTIC(NumBundled, "Number of instructions placed in such a bundle");
STATISTIC(NumSolo, "Number of instructions left alone in their bundle");

static cl::opt<bool> EnableBundling(
    "lvx-bundling", cl::Hidden, cl::init(true),
    cl::desc("Form LVX VLIW bundles (off: one instruction per bundle)"));

// An LVX bundle reads all its operands before it writes any of them, so an
// instruction may share a bundle with a LATER one that overwrites a register it
// reads: it sees the old value, which is what program order says it should see.
//
// This is worth 9% of the remaining bundles on the corpus, and it is safe under
// either reading of what a bundle does, which is why it is on. Take the pair
// (J, I) with J first, J reading X and I writing X. Issued in parallel with
// reads before writes, J gets the old X. Executed one after the other, J still
// gets the old X, because J comes first. The two agree.
//
// The case where they would NOT agree is a swap -- J: X = Y alongside I: Y = X,
// where parallel issue exchanges the two and sequential execution does not --
// and that pair is rejected anyway, by the true dependence that comes with it:
// I reads X, which J writes. isIndependentOfBundle tests both directions of
// every pair, so it never has to decide which semantics the hardware has.
//
// Turning this off leaves a bundler that respects all four dependence kinds.
static cl::opt<bool> AllowAntiDeps(
    "lvx-bundle-anti-deps", cl::Hidden, cl::init(true),
    cl::desc("Let an instruction share a bundle with a later one that "
             "overwrites a register it reads (a bundle reads all its operands "
             "before writing any of them)"));

// Eight 4-byte syllables. The same constant is LVX_SCHED2_BUNDLE_SIZE in
// lvx-gcc, and it is also why LVXSchedule.td need not model issue slots: the
// syllable count of an instruction is its encoded size.
static constexpr unsigned BundleSizeLimit = 32;

namespace llvm {
// INITIALIZE_PASS below defines llvm::initializeLVXBundlerPass, so it has to be
// declared in that namespace first.
void initializeLVXBundlerPass(PassRegistry &);
} // end namespace llvm

namespace {

class LVXBundler : public MachineFunctionPass {
public:
  static char ID;
  LVXBundler() : MachineFunctionPass(ID) {}

  bool runOnMachineFunction(MachineFunction &MF) override;

  StringRef getPassName() const override { return "LVX VLIW bundler"; }

  void getAnalysisUsage(AnalysisUsage &AU) const override {
    AU.setPreservesCFG();
    MachineFunctionPass::getAnalysisUsage(AU);
  }

private:
  const LVXInstrInfo *TII = nullptr;
  const TargetRegisterInfo *TRI = nullptr;
  const InstrItineraryData *Itin = nullptr;

  // The resources the open bundle has claimed, as a count per unit group. A
  // group is identified by the bitmask of its interchangeable units, which is
  // exactly what an InstrStage carries, so this needs to know nothing about
  // what the groups ARE: the capacity of a group is the number of units in it,
  // i.e. the population count of its mask. Add a group to LVXSchedule.td and
  // this code already handles it.
  SmallVector<std::pair<unsigned, unsigned>, 16> Claimed;
  unsigned ClaimedBytes = 0;
  SmallVector<MachineInstr *, 8> Members;

  void openBundle() {
    Claimed.clear();
    ClaimedBytes = 0;
    Members.clear();
  }

  bool isSolo(const MachineInstr &MI) const;
  bool haveRoomFor(const MachineInstr &MI) const;
  bool isIndependentOfBundle(const MachineInstr &MI) const;
  void claim(MachineInstr &MI);
  bool closeBundle(MachineBasicBlock &MBB);
};

char LVXBundler::ID = 0;

} // end anonymous namespace

// Whether MI must be alone in its bundle. Everything this cannot reason about
// lands here: the resource demand is unknown, or the dependence test above
// would not see all of its effects.
bool LVXBundler::isSolo(const MachineInstr &MI) const {
  // Inline asm is an opaque string: neither its resources nor its full effects
  // are visible, and it may itself be several instructions.
  if (MI.isInlineAsm())
    return true;

  // A side effect this description does not spell out could be ordered against
  // anything, including another instruction's side effect.
  if (MI.hasUnmodeledSideEffects())
    return true;

  // A register mask (a call's clobber set) is not something the operand walk
  // in isIndependentOfBundle inspects, so do not pack across one.
  for (const MachineOperand &MO : MI.operands())
    if (MO.isRegMask())
      return true;

  // No itinerary means no resource demand to check against the bundle. Real
  // instructions all have one -- every format class in LVXInstrEncodings.td
  // names an itinerary class, defaulting to ALL -- so this is a pseudo that
  // outlived expansion, and the honest answer is to leave it alone.
  unsigned Cls = MI.getDesc().getSchedClass();
  if (Itin->beginStage(Cls) == Itin->endStage(Cls))
    return true;

  return false;
}

// Whether MI's resource demand still fits what the open bundle has left. This
// is the whole of the ISA knowledge in this pass, and it is all read out of
// the itinerary.
bool LVXBundler::haveRoomFor(const MachineInstr &MI) const {
  if (ClaimedBytes + TII->getInstSizeInBytes(MI) > BundleSizeLimit)
    return false;

  unsigned Cls = MI.getDesc().getSchedClass();
  for (const InstrStage *S = Itin->beginStage(Cls), *E = Itin->endStage(Cls);
       S != E; ++S) {
    unsigned Mask = S->getUnits();
    unsigned Capacity = llvm::popcount(Mask);
    unsigned Used = 0;
    for (auto &C : Claimed)
      if (C.first == Mask)
        Used = C.second;
    // Count this stage and every later stage of the same group: an
    // instruction needing two units of a group carries the stage twice.
    unsigned Need = 0;
    for (const InstrStage *T = Itin->beginStage(Cls); T != E; ++T)
      if (T->getUnits() == Mask)
        ++Need;
    if (Used + Need > Capacity)
      return false;
  }
  return true;
}

// Whether MI can execute in parallel with everything already in the bundle.
//
// All registers are physical by now, so this is an overlap test over the
// operand lists -- and it must use regsOverlap rather than equality, because
// an LVX 128- or 256-bit value lives in a GPR pair or quad ($r2r3, $r0r1r2r3)
// that overlaps its own halves.
bool LVXBundler::isIndependentOfBundle(const MachineInstr &MI) const {
  for (const MachineInstr *MJ : Members) {
    // Memory: two loads commute, anything else that may touch memory does not.
    // Addresses are not compared -- no alias analysis is available here and
    // the ordering of two accesses within one bundle is not something the ISA
    // defines -- so this is deliberately coarse.
    if ((MI.mayStore() && MJ->mayLoadOrStore()) ||
        (MJ->mayStore() && MI.mayLoadOrStore()))
      return false;

    for (const MachineOperand &JO : MJ->operands()) {
      if (!JO.isReg() || !JO.getReg())
        continue;
      for (const MachineOperand &IO : MI.operands()) {
        if (!IO.isReg() || !IO.getReg())
          continue;
        if (!TRI->regsOverlap(JO.getReg(), IO.getReg()))
          continue;
        // Two reads of the same register are always fine.
        if (!JO.isDef() && !IO.isDef())
          continue;
        // Two writes to the same register in one bundle: which one lands is
        // not defined. Never.
        if (JO.isDef() && IO.isDef())
          return false;
        // A read in MI of something MJ writes: MI would read the old value,
        // which is not what the instruction order says. Never.
        if (JO.isDef())
          return false;
        // MI writes what MJ reads. MJ reads the old value, which IS what the
        // instruction order says, because the bundle reads everything before
        // it writes anything.
        if (!AllowAntiDeps)
          return false;
      }
    }
  }
  return true;
}

void LVXBundler::claim(MachineInstr &MI) {
  ClaimedBytes += TII->getInstSizeInBytes(MI);
  unsigned Cls = MI.getDesc().getSchedClass();
  for (const InstrStage *S = Itin->beginStage(Cls), *E = Itin->endStage(Cls);
       S != E; ++S) {
    unsigned Mask = S->getUnits();
    bool Found = false;
    for (auto &C : Claimed)
      if (C.first == Mask) {
        ++C.second;
        Found = true;
        break;
      }
    if (!Found)
      Claimed.emplace_back(Mask, 1u);
  }
  Members.push_back(&MI);
}

// Wrap the open bundle in a BUNDLE instruction, if it is worth one.
bool LVXBundler::closeBundle(MachineBasicBlock &MBB) {
  if (Members.size() < 2) {
    NumSolo += Members.size();
    openBundle();
    return false;
  }
  // finalizeBundle wants a half-open range, and the members are consecutive by
  // construction.
  finalizeBundle(MBB, Members.front()->getIterator(),
                 std::next(Members.back()->getIterator()));
  ++NumBundles;
  NumBundled += Members.size();
  openBundle();
  return true;
}

bool LVXBundler::runOnMachineFunction(MachineFunction &MF) {
  if (!EnableBundling)
    return false;

  const LVXSubtarget &ST = MF.getSubtarget<LVXSubtarget>();
  TII = ST.getInstrInfo();
  TRI = ST.getRegisterInfo();
  Itin = ST.getInstrItineraryData();
  if (!Itin || Itin->isEmpty())
    return false;

  bool Changed = false;
  for (MachineBasicBlock &MBB : MF) {
    openBundle();
    // Collected first: closeBundle inserts a BUNDLE instruction, which
    // invalidates an iteration in progress.
    SmallVector<MachineInstr *, 32> Candidates;
    for (MachineInstr &MI : MBB)
      Candidates.push_back(&MI);

    bool Sealed = false; // a terminator has joined; nothing more may
    for (MachineInstr *MI : Candidates) {
      // A meta instruction emits nothing, but some of them (CFI, labels) are
      // handled by the generic AsmPrinter path that a bundle bypasses, so
      // keep them out of bundles entirely rather than reason about which.
      if (MI->isMetaInstruction()) {
        Changed |= closeBundle(MBB);
        continue;
      }

      bool Solo = isSolo(*MI);
      if (Sealed || Solo || !haveRoomFor(*MI) || !isIndependentOfBundle(*MI)) {
        Changed |= closeBundle(MBB);
        Sealed = false;
      }

      if (Solo) {
        ++NumSolo;
        LLVM_DEBUG(dbgs() << "lvx-bundler: solo " << *MI);
        continue;
      }

      claim(*MI);
      // A branch is the last thing in its bundle: it may share the bundle with
      // the work before it, but nothing may follow it, and two branches in one
      // bundle are not something this pass takes on.
      if (MI->isTerminator())
        Sealed = true;
    }
    Changed |= closeBundle(MBB);
  }
  return Changed;
}

INITIALIZE_PASS(LVXBundler, DEBUG_TYPE, "LVX VLIW bundler", false, false)

FunctionPass *llvm::createLVXBundlerPass() { return new LVXBundler(); }
