//===- LVXCF.h - LVX_cf Dialect Operations -----------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_DIALECT_LVXCF_IR_LVXCF_H
#define MLIR_DIALECT_LVXCF_IR_LVXCF_H

#include "mlir/Dialect/LVX/IR/LVX.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/Dialect.h"
#include "mlir/IR/OpImplementation.h"
#include "mlir/Interfaces/ControlFlowInterfaces.h"
#include "mlir/Interfaces/SideEffectInterfaces.h"

#include "mlir/Dialect/LVXCF/IR/LVXCFOpsDialect.h.inc"

#define GET_OP_CLASSES
#include "mlir/Dialect/LVXCF/IR/LVXCFOps.h.inc"

#endif // MLIR_DIALECT_LVXCF_IR_LVXCF_H
