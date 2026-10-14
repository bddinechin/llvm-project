//===- ParametricLabelCorrecting.cpp - RecMII and modulo potentials -------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/LVX/Analysis/ParametricLabelCorrecting.h"

#include <cassert>

using namespace mlir;
using namespace mlir::lvx;

/// Smallest integer not below `a / b`, for `b > 0`.
static int64_t ceilDiv(int64_t a, int64_t b) {
  assert(b > 0 && "ceilDiv wants a positive divisor");
  return a >= 0 ? (a + b - 1) / b : -((-a) / b);
}

unsigned ParametricLabelCorrecting::addNode() {
  nodes.push_back(Node{});
  outArcs.push_back({});
  return nodes.size() - 1;
}

unsigned ParametricLabelCorrecting::addArc(unsigned tail, unsigned head,
                                           int64_t theta, int64_t omega) {
  assert(tail < nodes.size() && head < nodes.size() && "arc on unknown node");
  assert(omega >= 0 && "a negative iteration distance is not a dependence");
  arcs.push_back(Arc{tail, head, theta, omega});
  outArcs[tail].push_back(arcs.size() - 1);
  return arcs.size() - 1;
}

void ParametricLabelCorrecting::enqueueOutArcs(unsigned node) {
  for (unsigned a : outArcs[node])
    if (!queued[a]) {
      queued[a] = true;
      worklist.push_back(a);
    }
}

/// Grows the initial spanning tree over the zero-distance arcs, breadth first
/// from the root, taking each node's potential from its parent.
///
/// It would be tempting to relax in topological order instead, so that label
/// correcting starts from the longest path as LAO's `doFLP` does. That is wrong
/// here: when the zero-distance subgraph has a circuit there is no topological
/// order, relaxation can pick tree edges that form a cycle, and the result is
/// not a tree at all. Growing can only ever produce a tree, and the circuit is
/// then found where it belongs, by `checkCircuit` -- with `beta == 0`, so it is
/// correctly reported as feasible at no period rather than silently mis-solved.
/// The warm start is not worth a special case; label correcting recovers it.
///
/// Returns false when some node has no tree edge, which means the root does not
/// reach it along zero-distance arcs.
bool ParametricLabelCorrecting::buildInitialTree() {
  unsigned n = nodes.size();
  for (Node &nd : nodes) {
    nd.edge = -1;
    nd.depth = -1;
    nd.pi = AffinePeriod{};
  }
  nodes[0].depth = 0;

  llvm::SmallVector<unsigned> order{0};
  llvm::SmallVector<llvm::SmallVector<unsigned, 4>> children(n);
  for (unsigned i = 0; i != order.size(); ++i) {
    unsigned v = order[i];
    for (unsigned ai : outArcs[v]) {
      const Arc &a = arcs[ai];
      if (a.omega != 0 || a.head == 0 || nodes[a.head].depth >= 0)
        continue;
      Node &h = nodes[a.head];
      h.edge = ai;
      h.pi = nodes[v].pi + a.length();
      h.depth = nodes[v].depth + 1;
      children[v].push_back(a.head);
      order.push_back(a.head);
    }
  }
  if (order.size() != n)
    return false;

  // Thread the tree in preorder; `order` is breadth first, which is not one.
  llvm::SmallVector<unsigned> preorder;
  llvm::SmallVector<unsigned> dfs{0};
  while (!dfs.empty()) {
    unsigned v = dfs.pop_back_val();
    preorder.push_back(v);
    for (unsigned c : llvm::reverse(children[v]))
      dfs.push_back(c);
  }
  assert(preorder.size() == n && "the grown tree does not span the graph");
  for (unsigned i = 0; i != n; ++i) {
    unsigned v = preorder[i], w = preorder[(i + 1) % n];
    nodes[v].next = w;
    nodes[w].prev = v;
  }
  return true;
}

/// Walks up the tree from the entering arc's tail. If it reaches the head, the
/// arc closes a circuit; the circuit's length is positive by construction --
/// the walk accumulates exactly the arc's reduced length -- so the period is
/// raised to make it non-positive.
///
/// Returns true when a circuit was found, in which case the caller must not
/// re-parent: the head is an ancestor of the tail, and moving its subtree under
/// the tail would thread the tree into itself.
ParametricLabelCorrecting::Circuit
ParametricLabelCorrecting::checkCircuit(unsigned arcId) {
  const Arc &q = arcs[arcId];
  int64_t alpha = q.theta, beta = q.omega;
  unsigned a = q.tail;
  while (nodes[a].depth > nodes[q.head].depth) {
    const Arc &e = arcs[nodes[a].edge];
    alpha += e.theta;
    beta += e.omega;
    a = e.tail;
  }
  if (a != q.head)
    return Circuit::None;

  circuit.clear();
  circuit.push_back(arcId);
  for (unsigned b = q.tail; nodes[b].depth > nodes[q.head].depth;) {
    circuit.push_back(nodes[b].edge);
    b = arcs[nodes[b].edge].tail;
  }

  // alpha - lambda * beta > 0 at the current period, so alpha > 0. With no
  // distance round the circuit no period can help.
  if (beta <= 0)
    return Circuit::NoDistance;
  int64_t raised = ceilDiv(alpha, beta);
  if (raised > lambda)
    lambda = raised;
  return Circuit::PeriodRaised;
}

/// Re-parents the entering arc's head under its tail, shifting the head's
/// subtree. The shift is uniform and equal to the arc's reduced length, because
/// re-rooting changes no arc's length; the depth delta is likewise uniform
/// because the path is not reversed -- this is the `j == l` case of LAO's
/// `doRST`, the only one a label-correcting pass needs.
void ParametricLabelCorrecting::reparent(unsigned arcId) {
  const Arc &q = arcs[arcId];
  unsigned k = q.tail, l = q.head;
  AffinePeriod shift = reduced(q);
  int32_t depthDelta = nodes[k].depth - nodes[l].depth + 1;

  unsigned x = nodes[l].next, r = nodes[l].prev, z = l;
  while (nodes[x].depth > nodes[l].depth) {
    nodes[x].depth += depthDelta;
    nodes[x].pi = nodes[x].pi + shift;
    enqueueOutArcs(x);
    z = x;
    x = nodes[x].next;
  }
  nodes[l].depth += depthDelta;
  nodes[l].pi = nodes[l].pi + shift;
  enqueueOutArcs(l);

  // At this point `next(z) == x` and `prev(x) == z` already hold: the walk
  // above reads links and never writes them. That is why skipping the splice
  // when the subtree is already in place is correct rather than merely cheap --
  // what it would assign is what is already there, and `next(z) = next(k)`
  // would point the tail of the subtree back inside it.
  if (nodes[k].next != l) {
    unsigned n = nodes[k].next;
    nodes[r].next = x;
    nodes[x].prev = r;
    nodes[z].next = n;
    nodes[n].prev = z;
  }
  nodes[k].next = l;
  nodes[l].prev = k;
  nodes[l].edge = arcId;
}

ParametricLabelCorrecting::Result
ParametricLabelCorrecting::solve(int64_t lambdaLowerBound) {
  lambda = lambdaLowerBound > 0 ? lambdaLowerBound : 1;
  circuit.clear();
  if (nodes.empty())
    return Result::Solved;
  if (!buildInitialTree())
    return Result::Unreachable;

  queued.assign(arcs.size(), false);
  worklist.clear();
  for (unsigned a = 0, e = arcs.size(); a != e; ++a) {
    queued[a] = true;
    worklist.push_back(a);
  }

  // Generous: every correction raises some potential, and the period only ever
  // rises. Hitting this means a bug, not a hard instance.
  const uint64_t limit = 64ull * (arcs.size() + 1) * (nodes.size() + 1) + 1024;
  uint64_t steps = 0;

  while (!worklist.empty()) {
    if (++steps > limit)
      return Result::IterationLimit;
    unsigned arcId = worklist.pop_back_val();
    queued[arcId] = false;
    if (!violated(reduced(arcs[arcId])))
      continue;

    switch (checkCircuit(arcId)) {
    case Circuit::NoDistance:
      return Result::InfeasibleCircuit;
    case Circuit::PeriodRaised:
      // The potentials stay valid as functions of the period -- they are tree
      // path sums -- so unlike the scalar implementation nothing is recomputed.
      // But an arc satisfied at the old period need not be at the new one, so
      // the worklist is refilled.
      for (unsigned a = 0, e = arcs.size(); a != e; ++a)
        if (!queued[a]) {
          queued[a] = true;
          worklist.push_back(a);
        }
      continue;
    case Circuit::None:
      break;
    }
    reparent(arcId);
  }
  return Result::Solved;
}
