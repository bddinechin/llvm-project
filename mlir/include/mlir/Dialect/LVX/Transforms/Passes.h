//===- Passes.h - LVX dialect transform pass entrypoints ---------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_DIALECT_LVX_TRANSFORMS_PASSES_H
#define MLIR_DIALECT_LVX_TRANSFORMS_PASSES_H

#include "mlir/Dialect/LVXCF/IR/LVXCF.h"
#include "mlir/Dialect/LVXFunc/IR/LVXFunc.h"
#include "mlir/Pass/Pass.h"

namespace mlir {
namespace lvx {

#define GEN_PASS_DECL
#include "mlir/Dialect/LVX/Transforms/Passes.h.inc"

//===----------------------------------------------------------------------===//
// Registration
//===----------------------------------------------------------------------===//

#define GEN_PASS_REGISTRATION
#include "mlir/Dialect/LVX/Transforms/Passes.h.inc"

} // namespace lvx
} // namespace mlir

#endif // MLIR_DIALECT_LVX_TRANSFORMS_PASSES_H
