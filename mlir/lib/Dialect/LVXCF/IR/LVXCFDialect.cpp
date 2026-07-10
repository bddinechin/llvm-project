//===- LVXCFDialect.cpp - LVX_cf dialect implementation --------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/LVXCF/IR/LVXCF.h"

using namespace mlir;
using namespace mlir::lvx_cf;

#include "mlir/Dialect/LVXCF/IR/LVXCFOpsDialect.cpp.inc"

void LVXCFDialect::initialize() {
  addOperations<
#define GET_OP_LIST
#include "mlir/Dialect/LVXCF/IR/LVXCFOps.cpp.inc"
      >();
}
