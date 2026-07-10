add_mlir_conversion_library(MLIRConvertToLVX
  ConvertToLVX.cpp

  ADDITIONAL_HEADER_DIRS
  ${MLIR_MAIN_INCLUDE_DIR}/mlir/Conversion/ConvertToLVX

  DEPENDS
  MLIRConversionPassIncGen

  LINK_LIBS PUBLIC
  MLIRArithDialect
  MLIRControlFlowDialect
  MLIRFuncDialect
  MLIRIndexDialect
  MLIRIR
  MLIRLVXCFDialect
  MLIRLVXDialect
  MLIRLVXFuncDialect
  MLIRLVXSCFDialect
  MLIRMemRefDialect
  MLIRSCFDialect
  MLIRTransformUtils
)
