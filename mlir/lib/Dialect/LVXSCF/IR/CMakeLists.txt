add_mlir_dialect_library(MLIRLVXSCFDialect
  LVXSCFDialect.cpp
  LVXSCFOps.cpp

  ADDITIONAL_HEADER_DIRS
  ${MLIR_MAIN_INCLUDE_DIR}/mlir/Dialect/LVXSCF

  DEPENDS
  MLIRLVXSCFOpsIncGen

  LINK_LIBS PUBLIC
  MLIRDialect
  MLIRIR
  MLIRLVXDialect
  MLIRSideEffectInterfaces
)
