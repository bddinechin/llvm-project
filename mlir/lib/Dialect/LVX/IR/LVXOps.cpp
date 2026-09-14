//===- LVXOps.cpp - LVX dialect op implementations ------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/LVX/IR/LVX.h"
#include "mlir/Dialect/LVX/IR/RegisterUnits.h"
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

//===----------------------------------------------------------------------===//
// MvOp
//===----------------------------------------------------------------------===//

LogicalResult MvOp::verify() {
  if (widthOf(getSource().getType()) != widthOf(getResult().getType()))
    return emitOpError("source and result must be the same width: a copy "
                       "does not change register file");
  return success();
}

//===----------------------------------------------------------------------===//
// LaneOp
//===----------------------------------------------------------------------===//

LogicalResult LaneOp::verify() {
  unsigned sourceWidth = widthOf(getSource().getType());
  unsigned resultWidth = widthOf(getResult().getType());
  int64_t index = getIndex();
  if (resultWidth >= sourceWidth)
    return emitOpError("result must be narrower than the source");
  if (index < 0 || index % resultWidth != 0 ||
      static_cast<uint64_t>(index) + resultWidth > sourceWidth)
    return emitOpError("index ")
           << index << " is not a lane of the source: it must be a multiple "
           << "of the result's width (" << resultWidth << ") and leave the "
           << "lane within the source's " << sourceWidth << " units";
  // Once both are pinned, the lane is a register and the types must agree.
  std::optional<PhysLoc> src = pinnedLoc(getSource().getType());
  std::optional<PhysLoc> res = pinnedLoc(getResult().getType());
  if (src && res && res->base != src->base + index)
    return emitOpError("result is pinned to ")
           << spellingOf(*res) << " but lane " << index << " of "
           << spellingOf(*src) << " is " << spellingOf({src->base + static_cast<unsigned>(index), resultWidth});
  return success();
}

//===----------------------------------------------------------------------===//
// RegLiveInOp
//===----------------------------------------------------------------------===//

LogicalResult RegLiveOutOp::verify() {
  // Symmetric to RegLiveInOp below: "some register is live out" is not a
  // statement about anything.
  if (!cast<RegisterType>(getValue().getType()).isAllocated())
    return emitOpError("operand must be a pinned physical register");
  return success();
}

LogicalResult RegLiveInOp::verify() {
  // An unpinned result would denote "some register", which is meaningless
  // for an op whose only purpose is to name one specific physical register
  // that is already live on entry.
  if (!cast<RegisterType>(getResult().getType()).isAllocated())
    return emitOpError("result must be a pinned physical register");
  return success();
}
