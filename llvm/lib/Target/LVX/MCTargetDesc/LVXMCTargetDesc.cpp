#include "LVXMCTargetDesc.h"
#include "TargetInfo/LVXTargetInfo.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/MC/TargetRegistry.h"

#define GET_INSTRINFO_MC_DESC
#include "LVXGenInstrInfo.inc"

#define GET_REGINFO_MC_DESC
#include "LVXGenRegisterInfo.inc"

#define GET_SUBTARGETINFO_MC_DESC
#include "LVXGenSubtargetInfo.inc"

using namespace llvm;

static MCInstrInfo *createLVXMCInstrInfo() {
  MCInstrInfo *X = new MCInstrInfo();
  InitLVXMCInstrInfo(X);
  return X;
}

static MCRegisterInfo *createLVXMCRegisterInfo(const Triple &TT) {
  MCRegisterInfo *X = new MCRegisterInfo();
  // InitLVXMCRegisterInfo(X, LVX::R0); // uncomment once regs defined
  return X;
}

static MCSubtargetInfo *
createLVXMCSubtargetInfo(const Triple &TT, StringRef CPU, StringRef FS) {
  return createLVXMCSubtargetInfoImpl(TT, CPU, /*TuneCPU=*/CPU, FS);
}

extern "C" LLVM_EXTERNAL_VISIBILITY void LLVMInitializeLVXTargetMC() {
  TargetRegistry::RegisterMCInstrInfo(getTheLVXTarget(),
                                      createLVXMCInstrInfo);
  TargetRegistry::RegisterMCRegInfo(getTheLVXTarget(),
                                    createLVXMCRegisterInfo);
  TargetRegistry::RegisterMCSubtargetInfo(getTheLVXTarget(),
                                          createLVXMCSubtargetInfo);
}

