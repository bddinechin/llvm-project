add_llvm_component_library(LVXInfo
  LVXTargetInfo.cpp
  LINK_COMPONENTS
    Support
  ADD_TO_COMPONENT
    LVX
)
