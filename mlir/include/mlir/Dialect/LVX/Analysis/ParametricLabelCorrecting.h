//===- ParametricLabelCorrecting.h - RecMII and modulo potentials -*- C++ -*-=//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// Parametric label correcting over a bi-valued dependence graph, after Dupont
// de Dinechin, "Parametric Computation of Margins and of Minimum Cumulative
// Register Lifetime Dates", LCPC 1996, whose PLC is a parametric form of the
// Simplex variant of Goldfarb, Hao and Kai's dynamic breadth-first search.
//
// The graph has one arc (i, j) per dependence, carrying a latency `theta` and
// an iteration distance `omega`, constraining a 1-periodic schedule of period
// lambda as
//
//     date(i) + theta - lambda * omega <= date(j).
//
// Solving it yields two things the modulo scheduler needs: the smallest period
// for which no circuit is positive (RecMII, with the circuit that bounds it),
// and the earliest potentials at that period -- the resource-free schedule a
// decomposed software pipeliner starts from.
//
// "Parametric" means lambda is carried symbolically: arc lengths are
// `theta - lambda * omega` and potentials `mu + lambda * nu`, so raising the
// period leaves every potential valid as a function and costs no recomputation
// of the spanning tree. See lvx-mlir/docs/SoftwarePipelining.md §3.
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_DIALECT_LVX_ANALYSIS_PARAMETRICLABELCORRECTING_H
#define MLIR_DIALECT_LVX_ANALYSIS_PARAMETRICLABELCORRECTING_H

#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/SmallVector.h"

#include <cstdint>

namespace mlir {
namespace lvx {

/// An arc length or node potential as an affine function of the period:
/// `mu + lambda * nu`. Arc lengths have `nu = -omega`; a potential's `nu` is
/// the negated sum of the distances along its spanning-tree path.
struct AffinePeriod {
  int64_t mu = 0;
  int64_t nu = 0;

  int64_t at(int64_t lambda) const { return mu + lambda * nu; }

  AffinePeriod operator+(const AffinePeriod &o) const {
    return {mu + o.mu, nu + o.nu};
  }
  AffinePeriod operator-(const AffinePeriod &o) const {
    return {mu - o.mu, nu - o.nu};
  }
  bool operator==(const AffinePeriod &o) const {
    return mu == o.mu && nu == o.nu;
  }
};

/// Parametric label correcting over a bi-valued dependence graph.
///
/// Node 0 is the root: its potential is pinned to zero and every other node
/// must be reachable from it along zero-distance arcs, which is what the
/// source node of a dependence graph provides.
class ParametricLabelCorrecting {
public:
  enum class Result {
    /// A period and potentials were found.
    Solved,
    /// A positive circuit of zero total distance: no period makes it feasible.
    InfeasibleCircuit,
    /// Some node is not reachable from the root along zero-distance arcs.
    Unreachable,
    /// The iteration bound was hit; report rather than loop.
    IterationLimit,
  };

  /// Adds a node and returns its index. The first node added is the root.
  unsigned addNode();

  /// Adds an arc and returns its index.
  unsigned addArc(unsigned tail, unsigned head, int64_t theta, int64_t omega);

  /// Raises the period until no circuit is positive, maintaining the earliest
  /// potentials throughout. `lambdaLowerBound` seeds the period, and should be
  /// ResMII when one is known: the result is then max(RecMII, ResMII), which is
  /// the bound a modulo scheduler actually wants.
  Result solve(int64_t lambdaLowerBound = 1);

  /// The period the last `solve` settled on.
  int64_t getPeriod() const { return lambda; }

  /// The potential of `node`, as a function of the period. Valid at
  /// `getPeriod()` and immediately above it.
  AffinePeriod getPotential(unsigned node) const { return nodes[node].pi; }

  /// The potential of `node` evaluated at the period.
  int64_t getDate(unsigned node) const { return nodes[node].pi.at(lambda); }

  /// The arcs of the circuit that last forced the period up -- the most
  /// constraining recurrence, in the order the upward walk found them, which
  /// is the entering arc followed by the tree path from its tail. Empty when
  /// the period was never raised.
  llvm::ArrayRef<unsigned> getCriticalCircuit() const { return circuit; }

  unsigned getNumNodes() const { return nodes.size(); }
  unsigned getNumArcs() const { return arcs.size(); }

private:
  struct Arc {
    unsigned tail, head;
    int64_t theta, omega;
    AffinePeriod length() const { return {theta, -omega}; }
  };

  /// A node of the spanning tree. `edge` is the arc it hangs from, oriented
  /// away from the root; `next`/`prev` thread the tree in preorder and are
  /// circular, which is what terminates the subtree walks.
  struct Node {
    int edge = -1;
    AffinePeriod pi;
    unsigned next = 0, prev = 0;
    int32_t depth = -1;
  };

  /// The reduced length of `a`: positive means the constraint is violated.
  AffinePeriod reduced(const Arc &a) const {
    return a.length() + nodes[a.tail].pi - nodes[a.head].pi;
  }

  /// Whether `r` must be corrected: positive at the period, or zero there and
  /// rising, which keeps the potentials lexicographically maximal and so valid
  /// just above the period. A circuit can never satisfy the second disjunct,
  /// its `nu` being the negated sum of non-negative distances, so this cannot
  /// cycle.
  bool violated(const AffinePeriod &r) const {
    int64_t v = r.at(lambda);
    return v > 0 || (v == 0 && r.nu > 0);
  }

  /// What the upward walk from an entering arc's tail found.
  enum class Circuit { None, PeriodRaised, NoDistance };

  bool buildInitialTree();
  Circuit checkCircuit(unsigned arcId);
  void reparent(unsigned arcId);
  void enqueueOutArcs(unsigned node);

  llvm::SmallVector<Node> nodes;
  llvm::SmallVector<Arc> arcs;
  llvm::SmallVector<llvm::SmallVector<unsigned, 4>> outArcs;

  llvm::SmallVector<unsigned> worklist;
  llvm::SmallVector<bool> queued;
  llvm::SmallVector<unsigned> circuit;

  int64_t lambda = 1;
};

} // namespace lvx
} // namespace mlir

#endif // MLIR_DIALECT_LVX_ANALYSIS_PARAMETRICLABELCORRECTING_H
