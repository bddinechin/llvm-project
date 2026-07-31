# The library MUST be named LLVMLVXInfo, not LVXInfo: add_llvm_component_library
# derives a component's name by stripping a leading "LLVM", and the generated
# AllTargetsInfos component -- what llvm-mc and other MC-level tools link
# against -- is assembled from those component names. Without the prefix the
# library still built (as libLVXInfo.a), but nothing outside this directory
# could resolve it, so llvm-mc failed to link with "undefined reference to
# LLVMInitializeLVXTargetInfo". llc happened to work anyway only because
# LVXCodeGen named this library in LINK_LIBS, dragging it in through plain
# CMake linkage. Every other in-tree target uses the prefix (LLVMLanaiInfo,
# LLVMX86Info, ...).
add_llvm_component_library(LLVMLVXInfo
  LVXTargetInfo.cpp

  LINK_COMPONENTS
  MC
  Support

  ADD_TO_COMPONENT
  LVX
)
