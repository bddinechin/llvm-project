# Exclude tests from libMLIR.so
add_mlir_library(MLIRLVXTestPasses
  TestLiveIntervals.cpp

  EXCLUDE_FROM_LIBMLIR
  )
mlir_target_link_libraries(MLIRLVXTestPasses PUBLIC
  MLIRLVXAnalysis
  MLIRLVXFuncDialect
  MLIRPass
  )
