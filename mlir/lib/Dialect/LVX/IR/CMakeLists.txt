add_mlir_dialect_library(MLIRLVXDialect
  LVXDialect.cpp
  LVXOps.cpp

  ADDITIONAL_HEADER_DIRS
  ${MLIR_MAIN_INCLUDE_DIR}/mlir/Dialect/LVX

  DEPENDS
  MLIRLVXOpsIncGen

  LINK_LIBS PUBLIC
  MLIRCallInterfaces
  MLIRControlFlowInterfaces
  MLIRDialect
  MLIRFunctionInterfaces
  MLIRIR
  MLIRSideEffectInterfaces
  MLIRTransforms
)
