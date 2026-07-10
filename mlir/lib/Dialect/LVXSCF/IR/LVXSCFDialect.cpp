//===- LVXSCFDialect.cpp - LVX_scf dialect implementation ------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/LVXSCF/IR/LVXSCF.h"

using namespace mlir;
using namespace mlir::lvx_scf;

#include "mlir/Dialect/LVXSCF/IR/LVXSCFOpsDialect.cpp.inc"

void LVXSCFDialect::initialize() {
  addOperations<
#define GET_OP_LIST
#include "mlir/Dialect/LVXSCF/IR/LVXSCFOps.cpp.inc"
      >();
}
