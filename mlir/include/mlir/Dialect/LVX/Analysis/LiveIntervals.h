//===- LiveIntervals.h - Live interval analysis for LVX register alloc --===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Step 1 of the linear-scan register allocator described in
// lvx-mlir/docs/RegisterAllocation.md (Poletto & Sarkar, TOPLAS 1999): computes
// a conservative [start, end] live interval for every `!lvx.reg`-typed SSA
// value in an `lvx_func::FuncOp`, using a linear instruction numbering
// derived from a reverse-postorder walk of the function's block graph.
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_DIALECT_LVX_ANALYSIS_LIVEINTERVALS_H
#define MLIR_DIALECT_LVX_ANALYSIS_LIVEINTERVALS_H

#include "mlir/Dialect/LVX/IR/LVX.h"
#include "mlir/Dialect/LVXFunc/IR/LVXFunc.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallVector.h"

#include <optional>

namespace mlir {
namespace lvx {

/// A conservative live range for a single SSA value, expressed in terms of
/// the linear instruction numbering `LVXLiveIntervals` assigns. Per
/// Poletto & Sarkar, `[start, end]` is the tightest bracket such that the
/// value is not live at any point before `start` or after `end`; there may
/// be "holes" within the bracket where the value isn't actually live, and
/// this is deliberately ignored (matches the paper's base algorithm, which
/// performs no live-range splitting).
///
/// `fixedReg` is set when `value`'s type is already an allocated
/// `!lvx.reg<rN>` (e.g. an ABI-pinned function argument or a pinned
/// return value). Such intervals are not allocation candidates -- they are
/// hard constraints a later register-assignment pass must not conflict
/// with.
struct LiveInterval {
  Value value;
  unsigned start = 0;
  unsigned end = 0;
  std::optional<Register> fixedReg;

  bool isFixed() const { return fixedReg.has_value(); }
};

/// Computes live intervals for every `!lvx.reg`-typed value defined in an
/// `lvx_func::FuncOp` body.
///
/// Instruction numbering: a reverse-postorder walk of the function's outer
/// block graph (blocks connected via `lvx_cf.br`/`lvx_cf.cond_br`
/// successors), numbering every operation in sequence; an `lvx_scf.for`
/// op's single-block body is numbered inline, immediately following the
/// `lvx_scf.for` op itself and before the next operation in its parent
/// block. This keeps the whole function on one flat, monotonically
/// increasing number line, which is sufficient to correctly bracket values
/// captured from an enclosing scope and used inside a loop body: since the
/// use is numbered at a position after the loop op itself, the value's
/// computed interval naturally extends to cover it, with no special-cased
/// "loop extension" step required. (Verified empirically against
/// `mlir::Liveness`'s treatment of `lvx_scf.for`'s nested region -- see
/// lvx-mlir/docs/RegisterAllocation.md.)
///
/// Raw liveness (needed to correctly extend a value's interval through a
/// block it passes through untouched, without any direct use in that
/// block) comes from `mlir::Liveness`'s per-block live-in/live-out sets,
/// per the paper's assumption that live intervals are built from
/// already-computed dataflow liveness information.
class LVXLiveIntervals {
public:
  explicit LVXLiveIntervals(lvx_func::FuncOp func);

  /// All computed intervals, sorted by increasing `start`.
  ArrayRef<LiveInterval> getIntervals() const { return intervals; }

  /// The live interval for `value`. `value` must be a `!lvx.reg`-typed
  /// value defined within the analyzed function.
  const LiveInterval &getInterval(Value value) const;

  /// The linear instruction number assigned to `op`.
  unsigned getNumber(Operation *op) const { return opNumber.lookup(op); }

  /// The linear instruction number at which `block`'s arguments are
  /// considered defined (the block's reserved entry slot, strictly before
  /// its first operation's number).
  unsigned getNumber(Block *block) const { return blockNumber.lookup(block); }

private:
  /// Numbers `block` and, recursively, the body of any `lvx_scf.for` op
  /// found within it, advancing `counter` as it goes. Does not follow
  /// `lvx_cf` successor edges -- those are handled by the reverse
  /// postorder traversal driving the top-level calls to this function.
  void numberBlock(Block *block, unsigned &counter);

  void buildIntervals(lvx_func::FuncOp func);

  DenseMap<Operation *, unsigned> opNumber;
  DenseMap<Block *, unsigned> blockNumber;
  DenseMap<Value, unsigned> valueToIntervalIndex;
  SmallVector<LiveInterval> intervals;
};

} // namespace lvx
} // namespace mlir

#endif // MLIR_DIALECT_LVX_ANALYSIS_LIVEINTERVALS_H
