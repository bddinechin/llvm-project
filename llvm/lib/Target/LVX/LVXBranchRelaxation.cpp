//===-- LVXBranchRelaxation.cpp - Widen out-of-range LVX branches --------===//
//
// Replaces any branch whose target is too far away with the widened encoding
// of the same branch.
//
// LVX gives every branch a long form that differs only in how many bits of
// displacement it carries, and costs one more 32-bit syllable:
//
//   ccb  ->  ccbx    11 -> 38 bits    +-4 KiB   -> +-512 GiB
//   cb   ->  cbx     17 -> 44 bits    +-256 KiB -> +-32 TiB
//   goto ->  gotox   27 -> 54 bits    +-256 MiB -> +-32 PiB
//   call ->  callx   27 -> 54 bits
//
// (each field is a signed count of instruction words, so the reach in bytes
// is two bits wider than the field -- see isBranchOffsetInRange)
//
// so relaxing a branch here is a substitution in place, not the block
// splitting and trampoline the generic BranchRelaxation pass performs on
// targets with no long branch. The displacement field is the only difference:
// the operands are the same and in the same order, which is why swapping the
// opcode is enough.
//
// The pairs come from LVXImmediateExtensions.inc, generated from the machine
// description -- they are recovered from the encoding (an instruction and its
// widened form fix the same selector bits in the base syllable), not from the
// mnemonics, so adding a branch to the ISA needs no change here.
//
// Widening a branch grows its block, which can push another branch out of
// range, so this iterates to a fixed point. It only ever widens, and every
// branch has a widest form, so it terminates.
//
//===----------------------------------------------------------------------===//

#include "LVXISelDAGToDAG.h"
#include "LVXInstrInfo.h"
#include "LVXSubtarget.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/InitializePasses.h"
#include "llvm/Support/Debug.h"

using namespace llvm;

#define DEBUG_TYPE "lvx-branch-relaxation"

STATISTIC(NumRelaxed, "Number of LVX branches widened");

namespace llvm {
// INITIALIZE_PASS below defines llvm::initializeLVXBranchRelaxationPass, so it
// has to be declared in that namespace first.
void initializeLVXBranchRelaxationPass(PassRegistry &);
} // end namespace llvm

namespace {

class LVXBranchRelaxation : public MachineFunctionPass {
public:
  static char ID;
  LVXBranchRelaxation() : MachineFunctionPass(ID) {}

  bool runOnMachineFunction(MachineFunction &MF) override;

  StringRef getPassName() const override { return "LVX branch relaxation"; }

  MachineFunctionProperties getRequiredProperties() const override {
    return MachineFunctionProperties().setNoVRegs();
  }

private:
  const LVXInstrInfo *TII = nullptr;

  // Byte offset of each block from the start of the function.
  DenseMap<const MachineBasicBlock *, uint64_t> BlockOffset;

  void computeBlockOffsets(MachineFunction &MF);
  bool relaxOnce(MachineFunction &MF);
};

} // end anonymous namespace

char LVXBranchRelaxation::ID = 0;

INITIALIZE_PASS(LVXBranchRelaxation, DEBUG_TYPE, "LVX branch relaxation", false,
                false)

// The widened form of each relaxable branch, from the machine description.
static unsigned getWidenedBranch(unsigned Opc) {
  switch (Opc) {
#define LVX_IMMEDIATE_FORM(Narrow, Form, Bits)
#define LVX_BRANCH_FORM(Narrow, Wide)                                          \
  case LVX::Narrow:                                                            \
    return LVX::Wide;
#include "LVXImmediateExtensions.inc"
#undef LVX_BRANCH_FORM
#undef LVX_IMMEDIATE_FORM
  default:
    return 0;
  }
}

void LVXBranchRelaxation::computeBlockOffsets(MachineFunction &MF) {
  BlockOffset.clear();
  uint64_t Offset = 0;
  for (MachineBasicBlock &MBB : MF) {
    // A block's alignment can only push it further out, so rounding up here
    // keeps the offsets an upper bound rather than an underestimate -- which
    // is the safe direction for a range check.
    Offset = alignTo(Offset, MBB.getAlignment());
    BlockOffset[&MBB] = Offset;
    for (const MachineInstr &MI : MBB)
      Offset += TII->getInstSizeInBytes(MI);
  }
}

bool LVXBranchRelaxation::relaxOnce(MachineFunction &MF) {
  computeBlockOffsets(MF);

  bool Changed = false;
  for (MachineBasicBlock &MBB : MF) {
    uint64_t Offset = BlockOffset[&MBB];
    for (MachineInstr &MI : MBB) {
      unsigned Size = TII->getInstSizeInBytes(MI);
      unsigned Wide = MI.isBranch() ? getWidenedBranch(MI.getOpcode()) : 0;
      if (Wide) {
        // The displacement is measured from the branch itself, and the target
        // is always the last operand of an LVX branch.
        const MachineOperand &Target = MI.getOperand(MI.getNumExplicitOperands() - 1);
        if (Target.isMBB()) {
          int64_t Displacement =
              (int64_t)BlockOffset[Target.getMBB()] - (int64_t)Offset;
          if (!TII->isBranchOffsetInRange(MI.getOpcode(), Displacement)) {
            LLVM_DEBUG(dbgs() << "  widening " << MI << "    displacement "
                              << Displacement << " out of range\n");
            MI.setDesc(TII->get(Wide));
            ++NumRelaxed;
            Changed = true;
          }
        }
      }
      Offset += Size;
    }
  }
  return Changed;
}

bool LVXBranchRelaxation::runOnMachineFunction(MachineFunction &MF) {
  TII = MF.getSubtarget<LVXSubtarget>().getInstrInfo();

  // Widening a branch moves everything after it, so one pass is not enough:
  // iterate until nothing more goes out of range. Each iteration only ever
  // replaces a branch with a strictly wider one, and the widest form of every
  // branch reaches further than any function can be long, so the loop
  // converges -- the bound below is a backstop against a future ISA change
  // breaking that argument, not something the current one can reach.
  bool Changed = false;
  const unsigned MaxIterations = 10;
  for (unsigned I = 0; I != MaxIterations; ++I) {
    if (!relaxOnce(MF))
      return Changed;
    Changed = true;
  }
  report_fatal_error("LVX branch relaxation did not converge");
}

FunctionPass *llvm::createLVXBranchRelaxationPass() {
  return new LVXBranchRelaxation();
}
