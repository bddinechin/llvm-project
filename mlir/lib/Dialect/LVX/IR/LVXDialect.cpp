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

// The three register-parameterized types share one syntax; only the enum
// and the wording of the error differ.
template <typename TypeT, typename EnumT>
static Type
parseRegisterParameterized(AsmParser &parser,
                           std::optional<EnumT> (*symbolize)(StringRef),
                           StringRef what) {
  if (parser.parseOptionalLess())
    return TypeT::get(parser.getContext(), std::nullopt);

  StringRef keyword;
  if (parser.parseKeyword(&keyword))
    return {};
  std::optional<EnumT> reg = symbolize(keyword);
  if (!reg) {
    parser.emitError(parser.getCurrentLocation())
        << "invalid LVX " << what << " name '" << keyword << "'";
    return {};
  }
  if (parser.parseGreater())
    return {};
  return TypeT::get(parser.getContext(), reg);
}

Type RegisterType::parse(AsmParser &parser) {
  return parseRegisterParameterized<RegisterType, Register>(
      parser, symbolizeRegister, "register");
}

void RegisterType::print(AsmPrinter &printer) const {
  if (std::optional<Register> reg = getReg())
    printer << "<" << stringifyRegister(*reg) << ">";
}

//===----------------------------------------------------------------------===//
// PairType / QuadType: `!lvx.pair<r0r1>`, `!lvx.quad<r0r1r2r3>` -- the same
// shape at width 2 and 4 (lvx-mds/docs/MLIR-backend-design.md §8.3).
//===----------------------------------------------------------------------===//

Type PairType::parse(AsmParser &parser) {
  return parseRegisterParameterized<PairType, PairRegister>(
      parser, symbolizePairRegister, "register pair");
}

void PairType::print(AsmPrinter &printer) const {
  if (std::optional<PairRegister> reg = getReg())
    printer << "<" << stringifyPairRegister(*reg) << ">";
}

Type QuadType::parse(AsmParser &parser) {
  return parseRegisterParameterized<QuadType, QuadRegister>(
      parser, symbolizeQuadRegister, "register quadruple");
}

void QuadType::print(AsmPrinter &printer) const {
  if (std::optional<QuadRegister> reg = getReg())
    printer << "<" << stringifyQuadRegister(*reg) << ">";
}
