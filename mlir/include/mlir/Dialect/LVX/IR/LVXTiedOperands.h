//===- LVXTiedOperands.h - Operands tied to a result ------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Which operands an instruction reads *through* its destination, generated
// from the machine description by lvx-mds' `MDS/BE/MLIR` into
// `LVXTiedOperands.inc`. This header exists only to pull `ArrayRef` and
// `StringSwitch` into scope first and to say why the file it includes is not
// hand-written.
//
// It was, twice, and both copies said the same wrong thing:
// `RegisterAllocation.cpp` and `EmitAsm.cpp` each carried
// `isa<FfmadOp, FfmawOp, FfmsdOp, FfmswOp, CmovedOp>` with the tie hardcoded
// at operand index 2. The description's `analysis` attribute contradicts that
// in two directions -- 129 generated ops have a tie, not 5, and it is not
// always operand 2 (`aladdd` ties operand 1; `rswap` ties two operands to two
// results). The five were the ones a lowering happened to reach; the rest
// would have been allocated without coalescing and printed with an operand
// real hardware has no field for, both silently.
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_DIALECT_LVX_IR_LVXTIEDOPERANDS_H
#define MLIR_DIALECT_LVX_IR_LVXTIEDOPERANDS_H

#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/ADT/StringSwitch.h"

#include "mlir/Dialect/LVX/IR/LVXTiedOperands.inc"

#endif // MLIR_DIALECT_LVX_IR_LVXTIEDOPERANDS_H
