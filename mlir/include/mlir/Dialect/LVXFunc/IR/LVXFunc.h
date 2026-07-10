//===- LVXFunc.h - LVX_func Dialect Operations --------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_DIALECT_LVXFUNC_IR_LVXFUNC_H
#define MLIR_DIALECT_LVXFUNC_IR_LVXFUNC_H

#include "mlir/Dialect/LVX/IR/LVX.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/Dialect.h"
#include "mlir/IR/OpImplementation.h"
#include "mlir/IR/SymbolTable.h"
#include "mlir/Interfaces/CallInterfaces.h"
#include "mlir/Interfaces/FunctionInterfaces.h"

#include "mlir/Dialect/LVXFunc/IR/LVXFuncOpsDialect.h.inc"

#define GET_OP_CLASSES
#include "mlir/Dialect/LVXFunc/IR/LVXFuncOps.h.inc"

#endif // MLIR_DIALECT_LVXFUNC_IR_LVXFUNC_H
