#include "LVXTargetInfo.h"
#include "llvm/MC/TargetRegistry.h"

using namespace llvm;

Target &llvm::getTheLVXTarget() {
  static Target TheLVXTarget;
  return TheLVXTarget;
}

extern "C" LLVM_EXTERNAL_VISIBILITY void LLVMInitializeLVXTargetInfo() {
  // Triple::lvx, not UnknownArch: the arch is a real one now (it parses,
  // names itself, and answers 64-bit and little-endian), which is what lets
  // a driver and a front end find this target from a triple rather than
  // only from an -march string. And LP64, not "32-bit" -- the description
  // that string came from was wrong from the start.
  RegisterTarget<Triple::lvx> X(getTheLVXTarget(), "lvx",
                                "LVX (64-bit VLIW)", "LVX");
}

