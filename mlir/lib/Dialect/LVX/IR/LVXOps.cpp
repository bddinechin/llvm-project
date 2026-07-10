//===- LVXOps.cpp - LVX dialect op implementations ------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/LVX/IR/LVX.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinTypes.h"
#include "mlir/IR/OpImplementation.h"

#define GET_OP_CLASSES
#include "mlir/Dialect/LVX/IR/LVXOps.cpp.inc"

using namespace mlir;
using namespace mlir::lvx;

//===----------------------------------------------------------------------===//
// LiOp
//===----------------------------------------------------------------------===//

LogicalResult LiOp::verify() {
  if (!isa<IntegerAttr, FloatAttr>(getValue()))
    return emitOpError("value must be an integer or float attribute");
  return success();
}
