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
# checkout's Lanai/CMakeLists.txt) trimmed to what Phase 3 needs. Not yet
# added, pending later phases: LVXAsmPrinter.cpp, LVXMCInstLower.cpp
# (Phase 4 -- MC layer / asm printing), and an AsmParser/Disassembler
# subdirectory (Phase 4).
add_llvm_target(LVXCodeGen
  LVXAsmPrinter.cpp
  LVXFrameLowering.cpp
  LVXInstrInfo.cpp
  LVXISelDAGToDAG.cpp
  LVXISelLowering.cpp
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
    MC
    SelectionDAG
    Support
    Target
    TargetParser
    TransformUtils
  LINK_LIBS
    LVXDesc
    LVXInfo
  ADD_TO_COMPONENT
    LVX
)

add_subdirectory(MCTargetDesc)
add_subdirectory(TargetInfo)
