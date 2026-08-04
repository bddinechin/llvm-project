//===-- LVXMachineFunctionInfo.h - LVX per-function state -----*- C++ -*-===//
//
// Per-MachineFunction state for the LVX back-end.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_LVX_LVXMACHINEFUNCTIONINFO_H
#define LLVM_LIB_TARGET_LVX_LVXMACHINEFUNCTIONINFO_H

#include "llvm/CodeGen/MachineFunction.h"

namespace llvm {

class LVXMachineFunctionInfo : public MachineFunctionInfo {
  virtual void anchor();

  // Frame index of the 16-byte Frame Marker slot ({caller FP, $ra}), or -1
  // in a function that needs no marker.
  //
  // The marker has to be a real MachineFrameInfo object rather than a fixed
  // offset picked by the prologue. PEI is what decides where local objects
  // land and what MFI.getStackSize() ends up being, so anything the prologue
  // writes outside that accounting either overlaps a local or is not
  // allocated at all. Both happened: writing the marker at a hand-computed
  // offset put it on top of the two locals nearest the frame base, and in a
  // non-leaf function with no locals StackSize was 0, so the prologue
  // performed no stack decrement and stored the marker *below* SP, where the
  // callee promptly overwrote it and `ret` jumped to whatever was there.
  //
  // Owning a frame index instead means PEI reserves the space, includes it in
  // the stack size, and keeps every other object clear of it.
  int FrameMarkerFI = -1;

public:
  LVXMachineFunctionInfo(const Function &F, const TargetSubtargetInfo *STI) {}

  MachineFunctionInfo *
  clone(BumpPtrAllocator &Allocator, MachineFunction &DestMF,
        const DenseMap<MachineBasicBlock *, MachineBasicBlock *> &Src2DstMBB)
      const override {
    return DestMF.cloneInfo<LVXMachineFunctionInfo>(*this);
  }

  bool hasFrameMarker() const { return FrameMarkerFI != -1; }
  int getFrameMarkerFI() const { return FrameMarkerFI; }
  void setFrameMarkerFI(int FI) { FrameMarkerFI = FI; }
};

} // end namespace llvm

#endif // LLVM_LIB_TARGET_LVX_LVXMACHINEFUNCTIONINFO_H
