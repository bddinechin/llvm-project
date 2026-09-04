//===- LVXDialect.cpp - LVX dialect implementation ------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/LVX/IR/LVX.h"
// The machine model. Nothing consumes it yet -- a bundler and a software
// pipeliner are the consumers it is for -- but it is included here, in the
// dialect's own translation unit, so that it is COMPILED: the table is
// constexpr and carries a static_assert that no scheduling class reserves
// more of a resource than a bundle provides, and a generated header nobody
// includes is a generated header nobody checks.
#include "mlir/Dialect/LVX/IR/LVXScheduling.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/DialectImplementation.h"
#include "mlir/Transforms/InliningUtils.h"

using namespace mlir;
using namespace mlir::lvx;

#include "mlir/Dialect/LVX/IR/LVXOpsDialect.cpp.inc"
#include "mlir/Dialect/LVX/IR/LVXOpsEnums.cpp.inc"

#define GET_TYPEDEF_CLASSES
#include "mlir/Dialect/LVX/IR/LVXOpsTypes.cpp.inc"

namespace {
struct LVXInlinerInterface : public DialectInlinerInterface {
  using DialectInlinerInterface::DialectInlinerInterface;
  bool isLegalToInline(Operation *, Region *, bool, IRMapping &) const final {
    return true;
  }
};
} // namespace

void LVXDialect::initialize() {
  addOperations<
#define GET_OP_LIST
#include "mlir/Dialect/LVX/IR/LVXOps.cpp.inc"
      >();
  addTypes<
#define GET_TYPEDEF_LIST
#include "mlir/Dialect/LVX/IR/LVXOpsTypes.cpp.inc"
      >();
  addInterfaces<LVXInlinerInterface>();
}

Operation *LVXDialect::materializeConstant(OpBuilder &builder, Attribute value,
                                           Type type, Location loc) {
  if (!isa<RegisterType>(type))
    return nullptr;
  auto typedAttr = dyn_cast<TypedAttr>(value);
  if (!typedAttr)
    return nullptr;
  return builder.create<LiOp>(loc, type, typedAttr);
}

//===----------------------------------------------------------------------===//
// RegisterType: `!lvx.reg` (unallocated) or `!lvx.reg<r5>` (allocated).
//===----------------------------------------------------------------------===//

Type RegisterType::parse(AsmParser &parser) {
  if (parser.parseOptionalLess())
    return RegisterType::get(parser.getContext(), std::nullopt);

  StringRef keyword;
  if (parser.parseKeyword(&keyword))
    return {};
  std::optional<Register> reg = symbolizeRegister(keyword);
  if (!reg) {
    parser.emitError(parser.getCurrentLocation())
        << "invalid LVX register name '" << keyword << "'";
    return {};
  }
  if (parser.parseGreater())
    return {};
  return RegisterType::get(parser.getContext(), reg);
}

void RegisterType::print(AsmPrinter &printer) const {
  if (std::optional<Register> reg = getReg())
    printer << "<" << stringifyRegister(*reg) << ">";
}
