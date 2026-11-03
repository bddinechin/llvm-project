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

namespace mlir {
namespace lvx {

/// The opposite sense of the same test. Every `BcuCond` has a complement, and
/// the ISA pairs them adjacently in the encoding -- dltz/dgez, dlez/dgtz,
/// deqz/dnez, odd/even, and the word four -- so negating a test is free: the
/// other arm tests the same register with the other condition code, needing no
/// compare and no `not`. Spelled out rather than XOR-ing bit 0, so that a
/// future member without a complement is a compile error and not a wrong
/// branch sense.
inline std::optional<BcuCond> negateBcuCond(BcuCond c) {
  switch (c) {
  case BcuCond::dltz: return BcuCond::dgez;
  case BcuCond::dgez: return BcuCond::dltz;
  case BcuCond::dlez: return BcuCond::dgtz;
  case BcuCond::dgtz: return BcuCond::dlez;
  case BcuCond::deqz: return BcuCond::dnez;
  case BcuCond::dnez: return BcuCond::deqz;
  case BcuCond::odd:  return BcuCond::even;
  case BcuCond::even: return BcuCond::odd;
  case BcuCond::wltz: return BcuCond::wgez;
  case BcuCond::wgez: return BcuCond::wltz;
  case BcuCond::wlez: return BcuCond::wgtz;
  case BcuCond::wgtz: return BcuCond::wlez;
  case BcuCond::weqz: return BcuCond::wnez;
  case BcuCond::wnez: return BcuCond::weqz;
  }
  return std::nullopt;
}

} // namespace lvx
} // namespace mlir

#define GET_TYPEDEF_CLASSES
#include "mlir/Dialect/LVX/IR/LVXOpsTypes.h.inc"

#define GET_OP_CLASSES
#include "mlir/Dialect/LVX/IR/LVXOps.h.inc"

#endif // MLIR_DIALECT_LVX_IR_LVX_H
