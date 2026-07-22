add_mlir_dialect_library(MLIRLVXAnalysis
  LiveIntervals.cpp

  ADDITIONAL_HEADER_DIRS
  ${MLIR_MAIN_INCLUDE_DIR}/mlir/Dialect/LVX

  LINK_LIBS PUBLIC
  MLIRAnalysis
  MLIRIR
  MLIRLVXDialect
  MLIRLVXFuncDialect
  MLIRLVXSCFDialect
)
