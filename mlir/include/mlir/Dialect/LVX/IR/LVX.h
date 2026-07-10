//===- LVX.h - LVX Dialect Operations ---------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_DIALECT_LVX_IR_LVX_H
#define MLIR_DIALECT_LVX_IR_LVX_H

#include <optional>

#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinTypes.h"
#include "mlir/IR/Dialect.h"
#include "mlir/IR/OpImplementation.h"
#include "mlir/IR/SymbolTable.h"
#include "mlir/Interfaces/CallInterfaces.h"
#include "mlir/Interfaces/ControlFlowInterfaces.h"
#include "mlir/Interfaces/FunctionInterfaces.h"
#include "mlir/Interfaces/SideEffectInterfaces.h"

#include "mlir/Dialect/LVX/IR/LVXOpsDialect.h.inc"
#include "mlir/Dialect/LVX/IR/LVXOpsEnums.h.inc"

#define GET_TYPEDEF_CLASSES
#include "mlir/Dialect/LVX/IR/LVXOpsTypes.h.inc"

#define GET_OP_CLASSES
#include "mlir/Dialect/LVX/IR/LVXOps.h.inc"

#endif // MLIR_DIALECT_LVX_IR_LVX_H
