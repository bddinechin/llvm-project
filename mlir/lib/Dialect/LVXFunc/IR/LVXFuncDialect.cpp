//===- LVXFuncDialect.cpp - LVX_func dialect implementation ----------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/LVXFunc/IR/LVXFunc.h"

using namespace mlir;
using namespace mlir::lvx_func;

#include "mlir/Dialect/LVXFunc/IR/LVXFuncOpsDialect.cpp.inc"

void LVXFuncDialect::initialize() {
  addOperations<
#define GET_OP_LIST
#include "mlir/Dialect/LVXFunc/IR/LVXFuncOps.cpp.inc"
      >();
}
