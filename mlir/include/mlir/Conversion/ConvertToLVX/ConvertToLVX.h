//===- ConvertToLVX.h - Conversion to LVX dialect ---------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_CONVERSION_CONVERTTOLVX_CONVERTTOLVX_H
#define MLIR_CONVERSION_CONVERTTOLVX_CONVERTTOLVX_H

#include <memory>

namespace mlir {
class Pass;
class RewritePatternSet;
class TypeConverter;

#define GEN_PASS_DECL_CONVERTTOLVXPASS
#include "mlir/Conversion/Passes.h.inc"

/// Populate patterns to lower Arith, ControlFlow, SCF, MemRef, and Func ops
/// to LVX/lvx_cf/lvx_scf/lvx_func, using `typeConverter` to map scalar and
/// memref types to `!lvx.reg`.
void populateConvertToLVXPatterns(TypeConverter &typeConverter,
                                  RewritePatternSet &patterns);

} // namespace mlir

#endif // MLIR_CONVERSION_CONVERTTOLVX_CONVERTTOLVX_H
