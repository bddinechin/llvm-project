//===- IdentityCopies.h - drop `copyd $rX = $rX` -----------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// An `lvx.mv` whose source and destination ended up in the same register is
// `copyd $r2 = $r2`. These are not a mistake upstream -- the ABI copy-in and
// copy-out, the loop-carried channel moves and the tied-accumulator
// preserving copies are all emitted before anyone knows which registers they
// will join, and most do join two different ones. The identity cases are
// where coalescing *succeeded*, and nothing else deletes them.
//
// Shared by the two passes that can create them, for the reason
// `ScratchRegisters.h` gives for its own sharing: the first version of this
// lived inside -lvx-allocate-registers alone, and -lvx-scf-to-cf, which runs
// *after* it, went on emitting one per hardware-loop-ineligible loop -- the
// induction variable's channel move, `copyd $r2 = $r2`, straight into the
// bundler. Found by comparing a vectorized loop against lvx-gcc's output for
// the same source, which is the only reason it was noticed at all.
//
// It must run before -lvx-schedule: left in place the op still reserves a
// TINY slot, the resource that actually binds a bundle on this machine, so
// having the emitter skip the line would not recover it.
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_DIALECT_LVX_TRANSFORMS_IDENTITYCOPIES_H
#define MLIR_DIALECT_LVX_TRANSFORMS_IDENTITYCOPIES_H

#include "mlir/Dialect/LVXFunc/IR/LVXFunc.h"

namespace mlir {
namespace lvx {

/// Erase every `lvx.mv` in `func` whose source and result are the same
/// physical register, forwarding its uses to the source. Types must already
/// be pinned, so this is only meaningful after register allocation.
void eraseIdentityCopies(lvx_func::FuncOp func);

} // namespace lvx
} // namespace mlir

#endif // MLIR_DIALECT_LVX_TRANSFORMS_IDENTITYCOPIES_H
