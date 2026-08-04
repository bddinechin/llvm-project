set(LLVM_TARGET_DEFINITIONS LVXOps.td)
mlir_tablegen(LVXOpsEnums.h.inc   -gen-enum-decls)
mlir_tablegen(LVXOpsEnums.cpp.inc -gen-enum-defs)
add_mlir_dialect(LVXOps lvx)
# -dialect is required: these .td files include LVXBase.td, so more than one
# dialect is in scope and mlir-tblgen refuses to guess. Without it the
# mlir-doc target fails outright -- it never produced a page until this.
add_mlir_doc(LVXOps LVXOps Dialects/ -gen-dialect-doc -dialect=lvx)
