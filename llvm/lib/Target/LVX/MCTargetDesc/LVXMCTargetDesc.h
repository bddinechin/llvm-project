#ifndef LLVM_LIB_TARGET_LVX_MCTARGETDESC_LVXMCTARGETDESC_H
#define LLVM_LIB_TARGET_LVX_MCTARGETDESC_LVXMCTARGETDESC_H

#include <cstdint>

namespace llvm {
class Target;
} // end namespace llvm

// Defines symbolic names for LVX registers and instructions.
#define GET_REGINFO_ENUM
#include "LVXGenRegisterInfo.inc"

#define GET_INSTRINFO_ENUM
#include "LVXGenInstrInfo.inc"

#define GET_SUBTARGETINFO_ENUM
#include "LVXGenSubtargetInfo.inc"

#endif

