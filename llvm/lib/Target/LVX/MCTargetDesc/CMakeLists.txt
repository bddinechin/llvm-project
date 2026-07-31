# Named LLVMLVXDesc for the same reason as LLVMLVXInfo next door -- see the
# comment in TargetInfo/CMakeLists.txt. LVXInfo moves from LINK_LIBS to
# LINK_COMPONENTS as well: it is a registered LLVM component, and naming it as
# one is what lets the component graph (AllTargetsDescs -> LVXDesc -> LVXInfo)
# resolve for tools that never link the CodeGen half. This matches Lanai/X86.
add_llvm_component_library(LLVMLVXDesc
  LVXInstPrinter.cpp
  LVXMCTargetDesc.cpp

  LINK_COMPONENTS
  LVXInfo
  MC
  Support

  ADD_TO_COMPONENT
  LVX
)
