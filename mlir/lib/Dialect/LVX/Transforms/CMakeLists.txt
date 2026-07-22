add_mlir_dialect_library(MLIRLVXTransforms
  RegisterAllocation.cpp

  ADDITIONAL_HEADER_DIRS
  ${MLIR_MAIN_INCLUDE_DIR}/mlir/Dialect/LVX/Transforms

  DEPENDS
  MLIRLVXTransformsIncGen

  LINK_LIBS PUBLIC
  MLIRIR
  MLIRPass
  MLIRLVXAnalysis
  MLIRLVXDialect
  MLIRLVXFuncDialect
  MLIRLVXSCFDialect
  )
