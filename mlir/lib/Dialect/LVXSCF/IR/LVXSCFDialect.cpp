//===- LVXSCFDialect.cpp - LVX_scf dialect implementation ------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/LVXSCF/IR/LVXSCF.h"
#include "mlir/IR/DialectImplementation.h"
#include "llvm/ADT/TypeSwitch.h"

using namespace mlir;
using namespace mlir::lvx_scf;

#include "mlir/Dialect/LVXSCF/IR/LVXSCFOpsDialect.cpp.inc"

#define GET_TYPEDEF_CLASSES
#include "mlir/Dialect/LVXSCF/IR/LVXSCFOpsTypes.cpp.inc"

void LVXSCFDialect::initialize() {
  addTypes<
#define GET_TYPEDEF_LIST
#include "mlir/Dialect/LVXSCF/IR/LVXSCFOpsTypes.cpp.inc"
      >();
  addOperations<
#define GET_OP_LIST
#include "mlir/Dialect/LVXSCF/IR/LVXSCFOps.cpp.inc"
      >();
}
