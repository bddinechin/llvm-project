//===- LVXLatency.h - Generated Latency table ---------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Pulls the generated LVXLatency.inc (lvx-mds MDS/BE/MLIR) into scope with what
// it needs. See the .inc's own header comment for what it states.
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_DIALECT_LVX_IR_LVXLATENCY_H
#define MLIR_DIALECT_LVX_IR_LVXLATENCY_H

#include "mlir/Dialect/LVX/IR/LVX.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/ADT/StringSwitch.h"

#include <cstdint>
#include <optional>

#include "mlir/Dialect/LVX/IR/LVXLatency.inc"

#endif // MLIR_DIALECT_LVX_IR_LVXLATENCY_H
