//===-- LVXSelectionDAGInfo.h - LVX SelectionDAG Info -----------*- C++ -*-===//
//
// This file defines the LVX subclass for SelectionDAGGenTargetInfo.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_LVX_LVXSELECTIONDAGINFO_H
#define LLVM_LIB_TARGET_LVX_LVXSELECTIONDAGINFO_H

#include "llvm/CodeGen/SelectionDAGTargetInfo.h"

#define GET_SDNODE_ENUM
#include "LVXGenSDNodeInfo.inc"

namespace llvm {

class LVXSelectionDAGInfo : public SelectionDAGGenTargetInfo {
public:
  LVXSelectionDAGInfo();
  // Out-of-line destructor = key function = vtable anchor for this TU.
  // Without this, the vtable remains a weak zero-address symbol even
  // though all virtual overrides are strong -- because the compiler needs
  // a non-inline virtual to anchor the vtable to a specific TU.
  ~LVXSelectionDAGInfo() override;

  // All four of SelectionDAGGenTargetInfo's virtual method overrides are
  // defined inline in SelectionDAGTargetInfo.h. Inline virtuals generate only
  // weak zero-address symbols (confirmed via nm: all show as 'W 0x0'), so the
  // vtable for any class inheriting from SelectionDAGGenTargetInfo has null
  // entries for all four slots. This causes segfaults when SelectionDAG calls
  // them (verifyNode at +175, mayRaiseFPException at +47 via isTargetStrictFPOpcode).
  //
  // Fix: provide out-of-line definitions here. This TU becomes the vtable
  // anchor for LVXSelectionDAGInfo, replacing the weak nulls with strong
  // non-null function pointers. Each implementation just calls the base
  // inline version -- the optimizer will inline them anyway.
  const char *getTargetNodeName(unsigned Opcode) const override;
  bool isTargetMemoryOpcode(unsigned Opcode) const override;
  bool isTargetStrictFPOpcode(unsigned Opcode) const override;
  void verifyTargetNode(const SelectionDAG &DAG,
                        const SDNode *N) const override;
};

} // end namespace llvm

#endif // LLVM_LIB_TARGET_LVX_LVXSELECTIONDAGINFO_H
