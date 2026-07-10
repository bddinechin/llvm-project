add_mlir_dialect_library(MLIRLVXFuncDialect
  LVXFuncDialect.cpp
  LVXFuncOps.cpp

  ADDITIONAL_HEADER_DIRS
  ${MLIR_MAIN_INCLUDE_DIR}/mlir/Dialect/LVXFunc

  DEPENDS
  MLIRLVXFuncOpsIncGen

  LINK_LIBS PUBLIC
  MLIRCallInterfaces
  MLIRDialect
  MLIRFunctionInterfaces
  MLIRIR
  MLIRLVXDialect
)
