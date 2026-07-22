set(LLVM_TARGET_DEFINITIONS Passes.td)
mlir_tablegen(Passes.h.inc -gen-pass-decls -name LVX)
add_mlir_dialect_tablegen_target(MLIRLVXTransformsIncGen)

add_mlir_doc(Passes LVXPasses ./ -gen-pass-doc)
