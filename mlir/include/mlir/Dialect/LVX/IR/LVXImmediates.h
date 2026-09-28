//===- LVXImmediates.h - Generated Immediates table ---------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Pulls the generated LVXImmediates.inc (lvx-mds MDS/BE/MLIR) into scope with what
// it needs. See the .inc's own header comment for what it states.
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_DIALECT_LVX_IR_LVXIMMEDIATES_H
#define MLIR_DIALECT_LVX_IR_LVXIMMEDIATES_H

#include "mlir/Dialect/LVX/IR/LVX.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/APInt.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/ADT/StringSwitch.h"

#include <cstdint>
#include <optional>

#include "mlir/Dialect/LVX/IR/LVXImmediates.inc"

namespace mlir {
namespace lvx {

/// Does `value` fit `form`'s field, under that form's extension rule? A
/// property of the generated table rather than of any one pass: -lvx-schedule
/// asks it to choose a format, and -lvx-combine to decide whether a constant
/// can be folded into an immediate form at all.
inline bool valueFits(const ::llvm::APInt &value, const ImmediateForm &form) {
  unsigned w = form.width;
  if (w >= value.getBitWidth())
    return true;
  switch (form.extend) {
  case ImmediateExtend::Signed:
    return value.isSignedIntN(w);
  case ImmediateExtend::Unsigned:
    return value.isIntN(w);
  case ImmediateExtend::Wrap:
    return value.isSignedIntN(w) || value.isIntN(w);
  }
  return false;
}

} // namespace lvx
} // namespace mlir

#endif // MLIR_DIALECT_LVX_IR_LVXIMMEDIATES_H
