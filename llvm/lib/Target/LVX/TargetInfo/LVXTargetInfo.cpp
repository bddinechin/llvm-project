#include "LVXTargetInfo.h"
#include "llvm/MC/TargetRegistry.h"

using namespace llvm;

Target &llvm::getTheLVXTarget() {
  static Target TheLVXTarget;
  return TheLVXTarget;
}

extern "C" LLVM_EXTERNAL_VISIBILITY void LLVMInitializeLVXTargetInfo() {
  // "LVX (64-bit)": LVX is LP64 only -- there is no 32-bit mode, and the
  // data layout in LVXTargetMachine.cpp is the RV64 one (p:64:64). The
  // "(32-bit)" this used to print was a copy-paste leftover; it is the
  // string `llc --version` shows under Registered Targets.
  RegisterTarget<Triple::UnknownArch> X(getTheLVXTarget(), "lvx",
                                        "LVX (64-bit)", "LVX");
}

