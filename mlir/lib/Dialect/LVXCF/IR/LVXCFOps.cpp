//===- LVXCFOps.cpp - LVX_cf dialect op implementations -------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/LVXCF/IR/LVXCF.h"

#define GET_OP_CLASSES
#include "mlir/Dialect/LVXCF/IR/LVXCFOps.cpp.inc"

using namespace mlir;
using namespace mlir::lvx_cf;

//===----------------------------------------------------------------------===//
// BranchOp
//===----------------------------------------------------------------------===//

SuccessorOperands BranchOp::getSuccessorOperands(unsigned index) {
  assert(index == 0 && "invalid successor index");
  return SuccessorOperands(getDestOperandsMutable());
}

Block *BranchOp::getSuccessorForOperands(ArrayRef<Attribute>) {
  return getDest();
}

//===----------------------------------------------------------------------===//
// CondBranchOp
//===----------------------------------------------------------------------===//

SuccessorOperands CondBranchOp::getSuccessorOperands(unsigned index) {
  assert(index < getNumSuccessors() && "invalid successor index");
  return SuccessorOperands(index == 0 ? getTrueDestOperandsMutable()
                                      : getFalseDestOperandsMutable());
}

Block *CondBranchOp::getSuccessorForOperands(ArrayRef<Attribute>) {
  // Folding a `bcucond` test against a constant register value is not
  // implemented yet; conservatively report "not statically determined".
  return nullptr;
}

//===----------------------------------------------------------------------===//
// LoopdoOp
//===----------------------------------------------------------------------===//

SuccessorOperands LoopdoOp::getSuccessorOperands(unsigned index) {
  assert(index < getNumSuccessors() && "invalid successor index");
  return SuccessorOperands(index == 0 ? getBodyOperandsMutable()
                                      : getExitOperandsMutable());
}

Block *LoopdoOp::getSuccessorForOperands(ArrayRef<Attribute> operands) {
  // Statically known only when the trip count folds to the constant 0
  // (real hardware skips straight to `exit`); not implemented -- see
  // CondBranchOp's own note above for the same "not implemented yet"
  // shape.
  return nullptr;
}
