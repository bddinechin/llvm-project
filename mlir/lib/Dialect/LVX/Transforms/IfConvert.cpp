//===- IfConvert.cpp - branch diamond -> guard-predicated instructions ---===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// If-conversion for the GUARD BCU prefix. See lvx-mlir/docs/IfConversion.md,
// and `lvx_ifcvt_ctor` with the comment above it in lvx-gcc's `lvx.cc` for the
// transformation this mirrors: the two decisions are the same two -- is this
// arm convertible, and which of its insns are free to run unconditionally.
//
// Runs on the *branch* form, after -convert-to-lvx, which is where lvx-gcc's
// CE3 runs too. It was written first on `scf.if`, where the arms are explicit
// regions and no diamond has to be recognized, and that was wrong for a
// concrete reason worth recording: a `vector.store`'s address arithmetic does
// not exist yet before the conversion. -convert-to-lvx's `computeAddress`
// materializes `lvx.li`/`muld`/`addd` where the store is -- which would be
// inside the guard -- so an arm holding one store became a region of four ops,
// three of them pure and needlessly predicated. Converting after the lowering
// sees the real instructions, and those three are hoisted by the ordinary
// speculation rule below.
//
// One thing is easier here than in GCC and worth saying why. CE2 has to append
// a USE of the tested register to each arm, because once the jump is gone
// nothing keeps that register live to where the guards read it. In SSA there
// is nothing to do: each `lvx.guarded` *uses* the condition value, so the use
// is the liveness.
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/LVX/Transforms/Passes.h"

#include "mlir/Dialect/LVX/IR/LVX.h"
#include "mlir/Dialect/LVXCF/IR/LVXCF.h"
#include "mlir/Dialect/LVXFunc/IR/LVXFunc.h"
#include "mlir/IR/Builders.h"
#include "mlir/Interfaces/CallInterfaces.h"
#include "mlir/Interfaces/SideEffectInterfaces.h"

namespace mlir {
namespace lvx {
#define GEN_PASS_DEF_LVXIFCONVERTPASS
#include "mlir/Dialect/LVX/Transforms/Passes.h.inc"
} // namespace lvx
} // namespace mlir

using namespace mlir;
using namespace mlir::lvx;

namespace {

/// What one arm decomposes into: the ops that can run unconditionally and the
/// ops that have to be guarded, in program order. The terminator is neither --
/// it is the branch being removed.
struct Arm {
  Block *block = nullptr; // null for an absent else-arm
  SmallVector<Operation *> speculate;
  SmallVector<Operation *> guard;
};

/// The opposite sense of the same test. Every `BcuCond` has a complement, and
/// the ISA pairs them adjacently in the encoding -- dltz/dgez, dlez/dgtz,
/// deqz/dnez, odd/even, and the word four -- so negating a guard is free: the
/// else-arm tests the same register with the other condition code, needing no
/// compare and no `not`. Spelled out rather than XOR-ing bit 0, so that a
/// future member without a complement is a compile error and not a wrong
/// branch sense.
static std::optional<BcuCond> negateBcuCond(BcuCond c) {
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

/// Can `op` run whether or not the branch was taken? lvx-gcc's CE3 rule is
/// "non-memory, non-trapping": `isMemoryEffectFree` is the first half and
/// `isSpeculatable` the second. Address arithmetic (`lvx.li`, `muld`, `addd`,
/// `addx*d`) and the register pseudos all pass, which is what makes guarding a
/// store cost one prefix and not four.
static bool isFreeToSpeculate(Operation *op) {
  return isMemoryEffectFree(op) && isSpeculatable(op);
}

/// Classify one arm, or fail if it holds something this pass will not touch.
/// An op is speculated only when every value it reads is already available
/// outside the arm -- defined in another block, or produced by an op already
/// hoisted out of this one. An op reading a *guarded* value could not be
/// hoisted above it.
static FailureOr<Arm> classifyArm(Block *block) {
  Arm arm;
  arm.block = block;
  if (!block)
    return arm;
  DenseSet<Operation *> hoisted;

  for (Operation &op : block->without_terminator()) {
    if (op.getNumRegions() != 0)
      return failure(); // already guarded, or control flow we have not read
    bool operandsAvailable = llvm::all_of(op.getOperands(), [&](Value v) {
      Operation *def = v.getDefiningOp();
      return !def || def->getBlock() != block || hoisted.contains(def);
    });
    if (operandsAvailable && isFreeToSpeculate(&op)) {
      arm.speculate.push_back(&op);
      hoisted.insert(&op);
      continue;
    }
    // Not hoisted, so it must be guardable. Two reasons it might not be:
    //
    // - `lvx.guarded` yields nothing, so a result cannot cross it. A result
    //   that is *worth* having belongs to a speculatable op anyway, which the
    //   branch above already took.
    // - A **BCU instruction cannot be guarded at all**: the prefix is itself
    //   a BCU syllable, so there is no slot for both. lvx-gcc says the same
    //   ("only the BCU and singleton-bundle instructions cannot be guarded"),
    //   and a call is the case that reaches here looking guardable.
    if (op.getNumResults() != 0)
      return failure();
    if (isa<CallOpInterface>(&op))
      return failure();
    arm.guard.push_back(&op);
  }
  return arm;
}

/// Where `block`, reached from `from`, rejoins -- if it is an arm at all: it
/// must be entered only from `from`, take no block arguments, and leave by an
/// unconditional branch that passes none. A block with another predecessor is
/// not an arm; removing the branch would change what reaches it.
static Block *armJoin(Block *from, Block *block) {
  if (!llvm::hasSingleElement(block->getPredecessors()))
    return nullptr;
  if (*block->getPredecessors().begin() != from)
    return nullptr;
  if (block->getNumArguments() != 0)
    return nullptr;
  auto br = dyn_cast<lvx_cf::BranchOp>(block->getTerminator());
  if (!br || !br.getDestOperands().empty())
    return nullptr;
  return br.getDest();
}

/// Try to if-convert the diamond whose head is `block`. Returns whether it did.
static bool convertDiamond(Block *block, unsigned maxGuarded) {
  auto condBr = dyn_cast<lvx_cf::CondBranchOp>(block->getTerminator());
  if (!condBr)
    return false;
  Block *trueDest = condBr.getTrueDest();
  Block *falseDest = condBr.getFalseDest();
  if (trueDest == falseDest)
    return false; // not a diamond; a fold, which canonicalization owns
  // Values passed along either edge would have to be selected, not guarded.
  if (!condBr.getTrueDestOperands().empty() ||
      !condBr.getFalseDestOperands().empty())
    return false;

  // Three shapes, by which edges are arms:
  //   then-only:  the true edge is an arm rejoining at falseDest
  //   else-only:  the false edge is an arm rejoining at trueDest
  //   both arms:  each is an arm and the two rejoin at the same block
  Block *trueJoin = armJoin(block, trueDest);
  Block *falseJoin = armJoin(block, falseDest);
  Block *thenArm = nullptr, *elseArm = nullptr, *join = nullptr;
  if (trueJoin == falseDest) {
    thenArm = trueDest;
    join = falseDest;
  } else if (falseJoin == trueDest) {
    elseArm = falseDest;
    join = trueDest;
  } else if (trueJoin && falseJoin && trueJoin == falseJoin) {
    thenArm = trueDest;
    elseArm = falseDest;
    join = trueJoin;
  } else {
    return false;
  }
  // A join taking arguments is a phi: that is a select, not a guard.
  if (join->getNumArguments() != 0)
    return false;

  FailureOr<Arm> thenPart = classifyArm(thenArm);
  FailureOr<Arm> elsePart = classifyArm(elseArm);
  if (failed(thenPart) || failed(elsePart))
    return false;

  // Past this many guarded instructions the branch is cheaper: each one
  // occupies its slot in every bundle the arm spans whether the condition
  // holds or not. lvx-gcc spells the same bound MAX_CONDITIONAL_EXECUTE.
  if (thenPart->guard.size() + elsePart->guard.size() > maxGuarded)
    return false;
  if (thenPart->guard.empty() && elsePart->guard.empty())
    return false; // nothing to predicate; an empty arm is a fold, not this

  // The sense the branch tested is the then-arm's; the else-arm is the
  // complement, on the same register.
  BcuCond thenCond = condBr.getCondition();
  std::optional<BcuCond> elseCond = negateBcuCond(thenCond);
  if (elseArm && !elseCond)
    return false;

  OpBuilder builder(condBr);
  Value cond = condBr.getTest();
  auto emitArm = [&](const Arm &arm, BcuCond sense) {
    for (Operation *op : arm.speculate)
      op->moveBefore(condBr);
    for (Operation *op : arm.guard) {
      builder.setInsertionPoint(condBr);
      auto guarded = builder.create<GuardedOp>(op->getLoc(), sense, cond);
      Block *body = builder.createBlock(&guarded.getBody());
      op->moveBefore(body, body->end());
    }
  };
  emitArm(*thenPart, thenCond);
  if (elseArm)
    emitArm(*elsePart, *elseCond);

  // The branch is gone: fall straight through to the join.
  builder.setInsertionPoint(condBr);
  builder.create<lvx_cf::BranchOp>(condBr.getLoc(), join, ValueRange{});
  condBr.erase();
  if (thenArm)
    thenArm->erase();
  if (elseArm)
    elseArm->erase();
  return true;
}

struct LVXIfConvertPass
    : public lvx::impl::LVXIfConvertPassBase<LVXIfConvertPass> {
  using Base::Base;

  void runOnOperation() override {
    // Collect first: a conversion erases the arms it absorbed, so iterating
    // the block list live would walk freed memory.
    SmallVector<Block *> blocks;
    for (Block &b : getOperation().getBody())
      blocks.push_back(&b);
    for (Block *b : blocks) {
      // An arm absorbed by an earlier conversion must not be revisited. A
      // block still in the region has a parent; an erased one does not.
      if (!b->getParent())
        continue;
      convertDiamond(b, maxGuarded);
    }
  }
};

} // namespace
