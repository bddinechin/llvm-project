add_mlir_dialect(LVXSCFOps lvx_scf)
# -dialect is required: these .td files include LVXBase.td, so more than one
# dialect is in scope and mlir-tblgen refuses to guess. Without it the
# mlir-doc target fails outright -- it never produced a page until this.
add_mlir_doc(LVXSCFOps LVXSCFOps Dialects/ -gen-dialect-doc -dialect=lvx_scf)
