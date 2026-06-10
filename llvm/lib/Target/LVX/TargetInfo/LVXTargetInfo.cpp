#include "LVXTargetInfo.h"
#include "llvm/MC/TargetRegistry.h"

using namespace llvm;

Target &llvm::getTheLVXTarget() {
  static Target TheLVXTarget;
  return TheLVXTarget;
}

extern "C" LLVM_EXTERNAL_VISIBILITY void LLVMInitializeLVXTargetInfo() {
  RegisterTarget<Triple::UnknownArch> X(getTheLVXTarget(), "lvx",
                                        "LVX (32-bit)", "LVX");
}

