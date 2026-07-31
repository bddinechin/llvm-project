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
  LVXFrameLowering.cpp
  LVXInstrInfo.cpp
  LVXISelDAGToDAG.cpp
  LVXISelLowering.cpp
  LVXMCInstLower.cpp
  LVXRegisterInfo.cpp
  LVXSelectionDAGInfo.cpp
  LVXSubtarget.cpp
  LVXTargetMachine.cpp
  # LVXDesc/LVXInfo belong in LINK_COMPONENTS, not LINK_LIBS: they are
  # registered LLVM components (see the subdirectory CMakeLists), and listing
  # them as components is what records the dependency in the component graph
  # rather than only as a raw CMake library edge. Every other target does it
  # this way.
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
