add_llvm_component_library(LLVMLVXInfo
  LVXTargetInfo.cpp
  LINK_COMPONENTS
    MC
    Support
  ADD_TO_COMPONENT
    LVX
)
