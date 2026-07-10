//===- LVXSCFOps.cpp - LVX_scf dialect op implementations ------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/LVXSCF/IR/LVXSCF.h"
#include "mlir/Dialect/LVX/IR/LVX.h"

#define GET_OP_CLASSES
#include "mlir/Dialect/LVXSCF/IR/LVXSCFOps.cpp.inc"

using namespace mlir;
using namespace mlir::lvx_scf;
using mlir::lvx::RegisterType;

//===----------------------------------------------------------------------===//
// ForOp
//===----------------------------------------------------------------------===//

LogicalResult ForOp::verify() {
  if (getInitArgs().size() != getResults().size())
    return emitOpError("number of loop-carried init args (")
           << getInitArgs().size() << ") must match number of results ("
           << getResults().size() << ")";
  for (auto [idx, initTy, resTy] :
       llvm::enumerate(getInitArgs().getTypes(), getResultTypes())) {
    if (initTy != resTy)
      return emitOpError("type of init arg #")
             << idx << " (" << initTy << ") must match result type ("
             << resTy << ")";
  }
  return success();
}

LogicalResult ForOp::verifyRegions() {
  Block &body = *getBody();
  size_t expectedArgs = 1 + getInitArgs().size();
  if (body.getNumArguments() != expectedArgs)
    return emitOpError("expected body to take ")
           << expectedArgs << " arguments (induction variable + "
           << getInitArgs().size() << " iter args), got "
           << body.getNumArguments();
  for (BlockArgument arg : body.getArguments())
    if (!isa<RegisterType>(arg.getType()))
      return emitOpError("body arguments must have type !lvx.reg");

  auto yield = cast<YieldOp>(body.getTerminator());
  if (yield.getResults().size() != getInitArgs().size())
    return yield.emitOpError("number of yielded values (")
           << yield.getResults().size()
           << ") must match number of loop-carried init args ("
           << getInitArgs().size() << ")";
  for (auto [idx, yieldTy, initTy] : llvm::enumerate(
           yield.getResults().getTypes(), getInitArgs().getTypes())) {
    if (yieldTy != initTy)
      return yield.emitOpError("type of yielded value #")
             << idx << " (" << yieldTy
             << ") must match the corresponding init arg/result type ("
             << initTy << ")";
  }
  return success();
}
