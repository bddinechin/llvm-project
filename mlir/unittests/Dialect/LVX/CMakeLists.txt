add_mlir_unittest(MLIRLVXAnalysisTests
  ParametricLabelCorrectingTest.cpp
  PipelineConstructionTest.cpp
)
mlir_target_link_libraries(MLIRLVXAnalysisTests
  PRIVATE
  MLIRLVXAnalysis
)
