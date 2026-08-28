//===- LVXConvention.h - The LVX calling convention -------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// The register sets of `Convention-lvx_v1-regular`, generated from the machine
// description by lvx-mds' `MDS/BE/MLIR` into `LVXConvention.inc`. This header
// exists only to pull the dialect's `Register` enum into scope first and to
// say why the file it includes is not hand-written.
//
// It was, in three places that had to agree with a table none of them read:
// `LVXFuncOps.cpp` and `ConvertToLVX.cpp` each carried their own
// `kMaxAbiArgRegs = 12` / `kMaxAbiResultRegs = 4`, `ConvertToLVX` additionally
// assumed argument register *i* IS `Register::rI`, and `RegisterAllocation.cpp`
// spelled out the callee-saved set and the entire allocation order as
// literals. That is the same class of duplication `BE/LIBC` was written to
// remove for newlib's `setjmp` and gdb's `longjmp` reader, and it is worth
// noting that the register file itself did not have to change for it to bite:
// swapping two entries of the `argument` set would have left every one of
// those files compiling and wrong.
//
// What stays hand-written is policy rather than fact -- which registers the
// allocator *prefers* (see `RegisterAllocation.cpp`'s `kFullOrder`, built from
// these sets) and which it holds back as scratch (`ScratchRegisters.h`). The
// ABI says what the sets are; it does not say what a compiler should do with
// them.
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_DIALECT_LVX_IR_LVXCONVENTION_H
#define MLIR_DIALECT_LVX_IR_LVXCONVENTION_H

#include "mlir/Dialect/LVX/IR/LVX.h"

#include "mlir/Dialect/LVX/IR/LVXConvention.inc"

#endif // MLIR_DIALECT_LVX_IR_LVXCONVENTION_H
