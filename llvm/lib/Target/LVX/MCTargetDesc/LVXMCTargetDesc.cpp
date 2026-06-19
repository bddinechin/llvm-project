#include "LVXMCTargetDesc.h"
#include "TargetInfo/LVXTargetInfo.h"
#include "llvm/MC/MCAsmInfoELF.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/MC/TargetRegistry.h"
#include "llvm/TargetParser/Triple.h"

#define GET_INSTRINFO_MC_DESC
#include "LVXGenInstrInfo.inc"
#define GET_REGINFO_MC_DESC
#include "LVXGenRegisterInfo.inc"
#define GET_SUBTARGETINFO_MC_DESC
#include "LVXGenSubtargetInfo.inc"

using namespace llvm;

// Minimal MCAsmInfo for LVX. Subclasses MCAsmInfoELF (per the data
// layout's m:e ELF mangling flag). Settings:
//   - 64-bit pointer/callee-save slot size
//   - little-endian (per the 'e' prefix in the data layout string)
//   - CommentString: "//" -- PLACEHOLDER, update once the LVX assembler
//     syntax spec confirms the actual line-comment character
//   - PrivateGlobalPrefix ".L" (standard ELF convention for local labels
//     that must not appear in the .o file's symbol table)
// All other fields inherit MCAsmInfoELF defaults (WeakRefDirective,
// HasIdentDirective, UsesELFSectionDirectiveForBSS, etc.).
namespace {
class LVXMCAsmInfo : public MCAsmInfoELF {
public:
  explicit LVXMCAsmInfo(const Triple &TT, const MCTargetOptions &Options)
      : MCAsmInfoELF(Options) {
    CodePointerSize = 8;
    CalleeSaveStackSlotSize = 8;
    IsLittleEndian = true;
    CommentString = "#";
    PrivateLabelPrefix = ".L";
    SupportsDebugInformation = true;
  }
};
} // end anonymous namespace

static MCInstrInfo *createLVXMCInstrInfo() {
  MCInstrInfo *X = new MCInstrInfo();
  InitLVXMCInstrInfo(X);
  return X;
}

static MCRegisterInfo *createLVXMCRegisterInfo(const Triple &TT) {
  MCRegisterInfo *X = new MCRegisterInfo();
  InitLVXMCRegisterInfo(X, LVX::RA);
  return X;
}

static MCSubtargetInfo *
createLVXMCSubtargetInfo(const Triple &TT, StringRef CPU, StringRef FS) {
  return createLVXMCSubtargetInfoImpl(TT, CPU, /*TuneCPU=*/CPU, FS);
}

static MCAsmInfo *createLVXMCAsmInfo(const MCRegisterInfo &MRI,
                                     const Triple &TT,
                                     const MCTargetOptions &Options) {
  return new LVXMCAsmInfo(TT, Options);
}

extern "C" LLVM_EXTERNAL_VISIBILITY void LLVMInitializeLVXTargetMC() {
  TargetRegistry::RegisterMCAsmInfo(getTheLVXTarget(), createLVXMCAsmInfo);
  TargetRegistry::RegisterMCInstrInfo(getTheLVXTarget(),
                                      createLVXMCInstrInfo);
  TargetRegistry::RegisterMCRegInfo(getTheLVXTarget(),
                                    createLVXMCRegisterInfo);
  TargetRegistry::RegisterMCSubtargetInfo(getTheLVXTarget(),
                                          createLVXMCSubtargetInfo);
}
