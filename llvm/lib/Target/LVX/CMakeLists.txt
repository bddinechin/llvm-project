add_llvm_component_group(LVX)

set(LLVM_TARGET_DEFINITIONS LVX.td)

tablegen(LLVM LVXGenAsmWriter.inc       -gen-asm-writer)
tablegen(LLVM LVXGenCallingConv.inc     -gen-callingconv)
tablegen(LLVM LVXGenDAGISel.inc         -gen-dag-isel)
tablegen(LLVM LVXGenInstrInfo.inc       -gen-instr-info)
tablegen(LLVM LVXGenRegisterInfo.inc    -gen-register-info)
tablegen(LLVM LVXGenSDNodeInfo.inc      -gen-sd-node-info)
tablegen(LLVM LVXGenSubtargetInfo.inc   -gen-subtarget)

add_public_tablegen_target(LVXCommonTableGen)

# NOTE: matches the current LanaiCodeGen shape (confirmed against this
# checkout's Lanai/CMakeLists.txt) trimmed to what's needed so far. Not yet
# added: an AsmParser/Disassembler subdirectory, and an MCCodeEmitter/
# MCAsmBackend (needed for -filetype=obj -- still Phase 4 work beyond this
# InstPrinter/MCInstLower piece).
add_llvm_target(LVXCodeGen
  LVXAsmPrinter.cpp
  LVXBranchRelaxation.cpp
  LVXFrameLowering.cpp
  LVXInstrInfo.cpp
  LVXISelDAGToDAG.cpp
  LVXISelLowering.cpp
  LVXMachineFunctionInfo.cpp
  LVXMCInstLower.cpp
  LVXRegisterInfo.cpp
  LVXSelectionDAGInfo.cpp
  LVXSubtarget.cpp
  LVXTargetMachine.cpp
  LINK_COMPONENTS
    Analysis
    AsmPrinter
    CodeGen
    CodeGenTypes
    Core
    LVXDesc
    LVXInfo
    MC
    SelectionDAG
    Support
    Target
    TargetParser
    TransformUtils
  ADD_TO_COMPONENT
    LVX
)

add_subdirectory(MCTargetDesc)
add_subdirectory(TargetInfo)
