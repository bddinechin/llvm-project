//===- LVXSCF.h - LVX_scf Dialect Operations ----------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_DIALECT_LVXSCF_IR_LVXSCF_H
#define MLIR_DIALECT_LVXSCF_IR_LVXSCF_H

#include "mlir/Dialect/LVX/IR/LVX.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/Dialect.h"
#include "mlir/IR/OpImplementation.h"
#include "mlir/Interfaces/SideEffectInterfaces.h"

#include "mlir/Dialect/LVXSCF/IR/LVXSCFOpsDialect.h.inc"

#define GET_OP_CLASSES
#include "mlir/Dialect/LVXSCF/IR/LVXSCFOps.h.inc"

#endif // MLIR_DIALECT_LVXSCF_IR_LVXSCF_H
