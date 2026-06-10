add_llvm_component_library(LVXDesc
  LVXMCTargetDesc.cpp
  LINK_COMPONENTS
    MC
    Support
    LVXInfo
  ADD_TO_COMPONENT
    LVX
)

