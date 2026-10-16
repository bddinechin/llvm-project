//===- UncachedLoads.cpp - Mark loop-variant loads uncached ---------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// A load whose address varies with the loop should not go through L1. Its line
// is read once and not read again -- a streaming access -- so the cache buys
// nothing and the traffic evicts what other code does reuse. The ISA says so
// with the `variant` modifier: `.u` and `.us` carry `MemoryLevel=2` in the
// description, bypassing L1, and commit at SR ("stream return") rather than at
// the L1-hit stage.
//
// What that costs is the point. An uncached load's latency is fifteen cycles
// against a cached one's three, and fifteen cycles of memory in a loop body is
// what software pipelining is for: there is no schedule of one iteration that
// hides it, and overlapping iterations is the only thing that does. Modelling
// every load as an L1 hit made the kernels look like they had nothing to gain.
//
// `.u` and not `.us`: the speculative forms are *dismissible*, which drops a
// fault the access should have taken. That is what a speculated load wants and
// this is not one -- these loads run in iterations that were going to run.
//
// See lvx-mlir/docs/SoftwarePipelining.md §11.
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/LVX/Transforms/Passes.h"

#include "mlir/Dialect/LVX/IR/LVX.h"
#include "mlir/Dialect/LVXFunc/IR/LVXFunc.h"
#include "mlir/Dialect/LVXSCF/IR/LVXSCF.h"
#include "mlir/IR/Builders.h"
#include "mlir/Interfaces/SideEffectInterfaces.h"

namespace mlir {
namespace lvx {
#define GEN_PASS_DEF_LVXUNCACHEDLOADSPASS
#include "mlir/Dialect/LVX/Transforms/Passes.h.inc"
} // namespace lvx
} // namespace mlir

using namespace mlir;
using namespace mlir::lvx;

namespace {

/// Whether `op` is a load: it reads memory and writes none. A store, an
/// atomic and a prefetch are all excluded, and only a load has a `variant`
/// to set.
static bool isLoad(Operation *op) {
  auto iface = dyn_cast<MemoryEffectOpInterface>(op);
  return iface && iface.hasEffect<MemoryEffects::Read>() &&
         !iface.hasEffect<MemoryEffects::Write>();
}

/// Whether the op's ODS declares a `variant` attribute, which is how the
/// description says an opcode has the modifier. Asking the registered
/// operation rather than keeping a list here: the loads are generated, and a
/// list would be a second copy of the description going stale.
static bool acceptsVariant(Operation *op) {
  if (auto info = op->getName().getRegisteredInfo())
    return llvm::is_contained(info->getAttributeNames(), "variant");
  return false;
}

/// Whether `v` is produced inside `body` -- so it takes a different value on
/// each trip. A body block argument is the induction variable or an
/// `iter_arg`, both of which do.
static bool variesIn(Value v, Block *body) {
  if (auto arg = dyn_cast<BlockArgument>(v))
    return arg.getOwner() == body;
  Operation *def = v.getDefiningOp();
  return def && body->getParent()->isAncestor(def->getParentRegion());
}

/// Whether `load`'s address varies with the loop. A load has no data operand,
/// so every register operand of it is part of the address -- except a masked
/// access's mask, which selects lanes and says nothing about where. The
/// address arithmetic that does not vary has already been hoisted by then
/// (`-loop-invariant-code-motion`, which this pass must follow), so "defined
/// inside the body" is exactly "loop-variant".
static bool hasLoopVariantAddress(Operation *load, Block *body) {
  unsigned first = isa<MaskedLoadOp>(load) ? 1 : 0;
  for (unsigned i = first, e = load->getNumOperands(); i != e; ++i)
    if (variesIn(load->getOperand(i), body))
      return true;
  return false;
}

struct LVXUncachedLoadsPass
    : public lvx::impl::LVXUncachedLoadsPassBase<LVXUncachedLoadsPass> {
  using LVXUncachedLoadsPassBase::LVXUncachedLoadsPassBase;

  void runOnOperation() override {
    OpBuilder builder(&getContext());
    auto uncached = VariantAttr::get(&getContext(), Variant::u);
    getOperation().walk([&](lvx_scf::ForOp loop) {
      Block *body = loop.getBody();
      body->walk([&](Operation *op) {
        if (!isLoad(op) || !acceptsVariant(op))
          return;
        if (op->getAttrOfType<VariantAttr>("variant"))
          return; // already said; leave a deliberate choice alone
        if (hasLoopVariantAddress(op, body))
          op->setAttr("variant", uncached);
      });
    });
  }
};

} // namespace
