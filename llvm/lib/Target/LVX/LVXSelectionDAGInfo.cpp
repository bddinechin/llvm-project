//===-- LVXSelectionDAGInfo.cpp - LVX SelectionDAG Info ------------------===//
//===----------------------------------------------------------------------===//

#include "LVXSelectionDAGInfo.h"

#define GET_SDNODE_DESC
#include "LVXGenSDNodeInfo.inc"

using namespace llvm;

LVXSelectionDAGInfo::LVXSelectionDAGInfo()
    // Use LVXGenSDNodeInfo explicitly -- NOT 'GenNodeInfo', which in a
    // base-class initializer would resolve to the base's protected member
    // (SelectionDAGGenTargetInfo::GenNodeInfo) rather than the static
    // SDNodeInfo object defined by GET_SDNODE_DESC above. Using the member
    // name creates a circular self-reference, leaving GenNodeInfo as 0x0.
    : SelectionDAGGenTargetInfo(LVXGenSDNodeInfo) {}

LVXSelectionDAGInfo::~LVXSelectionDAGInfo() = default;

const char *LVXSelectionDAGInfo::getTargetNodeName(unsigned Opcode) const {
  return SelectionDAGGenTargetInfo::getTargetNodeName(Opcode);
}

bool LVXSelectionDAGInfo::isTargetMemoryOpcode(unsigned Opcode) const {
  return SelectionDAGGenTargetInfo::isTargetMemoryOpcode(Opcode);
}

bool LVXSelectionDAGInfo::isTargetStrictFPOpcode(unsigned Opcode) const {
  return SelectionDAGGenTargetInfo::isTargetStrictFPOpcode(Opcode);
}

void LVXSelectionDAGInfo::verifyTargetNode(const SelectionDAG &DAG,
                                           const SDNode *N) const {
  // TODO: re-enable once SDNodeInfo::verifyNode is stable for LVX nodes.
  (void)DAG;
  (void)N;
}
