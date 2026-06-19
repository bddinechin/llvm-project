//===-- LVXISelDAGToDAG.cpp - LVX DAG-to-DAG Instruction Selector -------===//
//
// Phase 3 stub. SelectCode (the auto-generated table matcher from
// LVXGenDAGISel.inc) handles every pattern currently defined in
// LVXInstrInfo.td. None of the deferred custom-selection cases (CALL vs
// ICALL dispatch, LWZ/LWS/LD variant-modifier defaulting, CLSD) are
// implemented yet -- IR that would need them simply won't select
// correctly until this is filled in.
//
//===----------------------------------------------------------------------===//

#include "LVXISelDAGToDAG.h"
#include "LVXInstrInfo.h"
#include "llvm/CodeGen/SelectionDAGISel.h"

using namespace llvm;

char LVXDAGToDAGISel::ID = 0;

#define GET_DAGISEL_BODY LVXDAGToDAGISel
#include "LVXGenDAGISel.inc"

void LVXDAGToDAGISel::Select(SDNode *N) {
  SDLoc DL(N);

  // ISD::BUILD_PAIR (i128 from two i64 halves) → CATDQ.
  // LowerFormalArguments produces BUILD_PAIR when reassembling an i128
  // argument from its two i64 CC slots. CATDQ is the single LVX instruction
  // that assembles an aligned GPR128 pair from two arbitrary GPR sources:
  // "catdq $rM = $rY, $rZ" where $rY is the low 64 bits and $rZ the high.
  if (N->getOpcode() == ISD::BUILD_PAIR &&
      N->getValueType(0) == MVT::i128) {
    SDValue Lo = N->getOperand(0); // low 64 bits
    SDValue Hi = N->getOperand(1); // high 64 bits
    SDNode *Res = CurDAG->getMachineNode(LVX::CATDQ, DL, MVT::i128, Lo, Hi);
    ReplaceNode(N, Res);
    return;
  }

  SelectCode(N);
}

FunctionPass *llvm::createLVXISelDag(LVXTargetMachine &TM,
                                     CodeGenOptLevel OptLevel) {
  return new SelectionDAGISelLegacy(
      LVXDAGToDAGISel::ID,
      std::make_unique<LVXDAGToDAGISel>(TM, OptLevel));
}
