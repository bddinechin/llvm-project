add_mlir_dialect_library(MLIRLVXTransforms
  Combine.cpp
  RegisterAllocation.cpp
  RewriteDivmod.cpp
  SCFToCF.cpp
  EmitAsm.cpp

  ADDITIONAL_HEADER_DIRS
  ${MLIR_MAIN_INCLUDE_DIR}/mlir/Dialect/LVX/Transforms

  DEPENDS
  MLIRLVXTransformsIncGen

  LINK_LIBS PUBLIC
  MLIRIR
  MLIRPass
  MLIRTransforms
  MLIRLVXAnalysis
  MLIRLVXDialect
  MLIRLVXCFDialect
  MLIRLVXFuncDialect
  MLIRLVXSCFDialect
  )
