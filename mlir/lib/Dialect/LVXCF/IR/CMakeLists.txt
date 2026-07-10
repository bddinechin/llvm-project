add_mlir_dialect_library(MLIRLVXCFDialect
  LVXCFDialect.cpp
  LVXCFOps.cpp

  ADDITIONAL_HEADER_DIRS
  ${MLIR_MAIN_INCLUDE_DIR}/mlir/Dialect/LVXCF

  DEPENDS
  MLIRLVXCFOpsIncGen

  LINK_LIBS PUBLIC
  MLIRControlFlowInterfaces
  MLIRDialect
  MLIRIR
  MLIRLVXDialect
  MLIRSideEffectInterfaces
)
