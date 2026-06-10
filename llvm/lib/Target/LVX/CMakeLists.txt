add_llvm_component_group(LVX)

set(LLVM_TARGET_DEFINITIONS LVX.td)

tablegen(LLVM LVXGenRegisterInfo.inc    -gen-register-info)
tablegen(LLVM LVXGenInstrInfo.inc       -gen-instr-info)
tablegen(LLVM LVXGenAsmWriter.inc       -gen-asm-writer)
tablegen(LLVM LVXGenDAGISel.inc         -gen-dag-isel)
tablegen(LLVM LVXGenCallingConv.inc     -gen-callingconv)
tablegen(LLVM LVXGenSubtargetInfo.inc   -gen-subtarget)

add_public_tablegen_target(LVXCommonTableGen)

add_llvm_target(LVXCodeGen
  LVXTargetMachine.cpp
  LINK_COMPONENTS
    Analysis
    AsmPrinter
    CodeGen
    Core
    MC
    LVXDesc
    LVXInfo
    SelectionDAG
    Support
    Target
    TransformUtils
  ADD_TO_COMPONENT
    LVX
)

add_subdirectory(MCTargetDesc)
add_subdirectory(TargetInfo)

