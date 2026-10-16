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
#include "mlir/Dialect/LVX/IR/RegisterUnits.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/ADT/StringSwitch.h"

#include <cstdint>
#include <optional>

#include "mlir/Dialect/LVX/IR/LVXLatency.inc"

namespace mlir {
namespace lvx {

/// The instruction an `lvx` op prints, which is the key into the generated
/// timing and reservation tables -- `std::nullopt` for an op that prints
/// nothing, and for anything outside the `lvx` dialect.
///
/// It is not the operation name. A pseudo prints a real instruction whose
/// timing is the one that applies: `lvx.li` prints `maked`, `lvx.mv` a copy at
/// its width, and `lvx.masked_load`/`masked_store` print the bare access that
/// the `maskm` prefix governs. Looking the op's own name up instead finds
/// nothing in the table and silently falls back to the defaults, which is
/// wrong by a cycle wherever a real instruction disagrees with them -- `sq`
/// reads its data operand in cycle 2 and the default is 1, so a pipeliner that
/// did this computed a recurrence bound one cycle too long on every loop with
/// a masked store, and reported a minimum period its own emitted kernel then
/// beat.
///
/// Here, beside the timings it is the key to, because the bundler and the
/// pipeliner both need it and must agree. The control ops are not handled:
/// `lvx_cf` and `lvx_func` depend on this dialect, so naming them here would
/// invert that. A consumer that cares adds them on top.
inline std::optional<llvm::StringRef> lvxPrintedMnemonic(Operation *op) {
  if (auto guarded = dyn_cast<GuardedOp>(op))
    return lvxPrintedMnemonic(guarded.guardedOp());
  if (isa<LiOp>(op))
    return llvm::StringRef("maked");
  if (auto mv = dyn_cast<MvOp>(op)) {
    switch (widthOf(mv.getResult().getType())) {
    case 1:
      return llvm::StringRef("copyd");
    case 2:
      return llvm::StringRef("catdq");
    default:
      return llvm::StringRef("copyo");
    }
  }
  // A masked access reserves and times as the bare access does; the BCU
  // syllable its `maskm` prefix takes is accounted separately.
  if (auto ml = dyn_cast<MaskedLoadOp>(op))
    return widthOf(ml.getResult().getType()) == 4 ? llvm::StringRef("lo")
                                                  : llvm::StringRef("lq");
  if (auto ms = dyn_cast<MaskedStoreOp>(op))
    return widthOf(ms.getValue().getType()) == 4 ? llvm::StringRef("so")
                                                 : llvm::StringRef("sq");
  if (isa<LaneOp, ConcatOp, SpOp, RegLiveInOp, RegLiveOutOp>(op))
    return std::nullopt;
  if (op->getDialect() && op->getDialect()->getNamespace() == "lvx")
    return op->getName().stripDialect();
  return std::nullopt;
}

/// Whether `op` is an uncached load: it carries the `variant` modifier's `.u`
/// or `.us`, which bypass L1 (`MemoryLevel=2` in the description).
inline bool isUncachedLoad(Operation *op) {
  auto variant = op->getAttrOfType<VariantAttr>("variant");
  return variant && (variant.getValue() == Variant::u ||
                     variant.getValue() == Variant::us);
}

/// The cycle `op` reads operand `i` in, and writes result `i` in. RR = 1 and
/// E1 = 2 where the generated table has nothing to say -- a pseudo, or a
/// control op whose operands are registers read at issue.
///
/// `writeCycleOf` makes the one correction the per-opcode table cannot. An
/// uncached load commits at SR, "stream return", but `Opcode@timing` is
/// derived from the Behavior's `stage` annotations and a `.u` load shares its
/// Opcode record with its cached self -- `variant` is a modifier, not a
/// separate opcode -- so the table gives every load the L1-hit figure. It is
/// the difference between modelling a load at three cycles and at fifteen,
/// which is the difference between a loop with nothing to hide the memory
/// behind and one software pipelining has work to do on. `Stage::SR` is the
/// description's own number (`Processor.yml`'s pipeline), not one written
/// here.
///
/// Here rather than in a pass because two of them must agree: the bundler
/// schedules against these latencies and the pipeliner assigns stages from
/// them, and a pipeline staged for a three-cycle load does not cover a
/// fifteen-cycle one.
inline unsigned readCycleOf(const OpTiming *t, unsigned i) {
  return t && i < t->numOperands ? t->operandRead[i] : 1;
}
inline unsigned writeCycleOf(Operation *op, const OpTiming *t, unsigned i) {
  if (isUncachedLoad(op))
    return static_cast<unsigned>(Stage::SR);
  return t && i < t->numResults ? t->resultWrite[i] : 2;
}

} // namespace lvx
} // namespace mlir

#endif // MLIR_DIALECT_LVX_IR_LVXLATENCY_H
