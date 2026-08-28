# The three .td files lvx-mds' BE/MLIR generates are included by LVXOps.td,
# and TableGen's include tracking does not see them: this build's tablegen
# edge lists only LVXBase.td and LVXOps.td, because TableGen.cmake globs
# *.td at CONFIGURE time and these did not exist when the tree was first
# configured. `make -C BE/MLIR install` therefore delivered a new
# description that ninja considered up to date -- a rebuild-and-test cycle
# that silently tested the previous ISA. LLVM_TARGET_DEPENDS is the macro's
# supported hook for exactly this; list every generated file, and add the
# next one here too.
set(LLVM_TARGET_DEPENDS
  ${CMAKE_CURRENT_SOURCE_DIR}/LVXRegisters.td
  ${CMAKE_CURRENT_SOURCE_DIR}/LVXModifiers.td
  ${CMAKE_CURRENT_SOURCE_DIR}/LVXInstrOps.td
  )
set(LLVM_TARGET_DEFINITIONS LVXOps.td)
mlir_tablegen(LVXOpsEnums.h.inc   -gen-enum-decls)
mlir_tablegen(LVXOpsEnums.cpp.inc -gen-enum-defs)
add_mlir_dialect(LVXOps lvx)
# -dialect is required: these .td files include LVXBase.td, so more than one
# dialect is in scope and mlir-tblgen refuses to guess. Without it the
# mlir-doc target fails outright -- it never produced a page until this.
add_mlir_doc(LVXOps LVXOps Dialects/ -gen-dialect-doc -dialect=lvx)
