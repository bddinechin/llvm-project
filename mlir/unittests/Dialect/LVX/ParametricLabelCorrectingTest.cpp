//===- ParametricLabelCorrectingTest.cpp ----------------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// The cases here are the ones a differential run against the reference
// implementation (lvx-mlir/docs/SoftwarePipelining.md, "Building it as an
// oracle") cannot pin: the published example, and the shapes whose answer is
// known by hand.
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/LVX/Analysis/ParametricLabelCorrecting.h"
#include "gtest/gtest.h"

using namespace mlir::lvx;
using Result = ParametricLabelCorrecting::Result;

namespace {

/// The dependence graph of Ning & Gao as used by Figure 1 of Dupont de
/// Dinechin, LCPC 1996: three operations, a multiply of latency 2, and one
/// recurrence of distance 2 closing the loop.
///
///   root -> +1          (0, 0)
///   +1   -> *2          (1, 0)
///   +1   -> +3          (1, 0)
///   *2   -> +3          (2, 0)
///   +3   -> +1          (1, 2)
///
/// Two circuits: 1->2->3->1 of length 4 over distance 2, and 1->3->1 of
/// length 2 over distance 2. RecMII is the larger ceiling, 2.
TEST(ParametricLabelCorrecting, LCPC96Figure1) {
  ParametricLabelCorrecting g;
  for (unsigned i = 0; i != 4; ++i)
    g.addNode();
  g.addArc(0, 1, 0, 0);
  g.addArc(1, 2, 1, 0);
  g.addArc(1, 3, 1, 0);
  g.addArc(2, 3, 2, 0);
  unsigned rec = g.addArc(3, 1, 1, 2);

  ASSERT_EQ(g.solve(), Result::Solved);
  EXPECT_EQ(g.getPeriod(), 2);
  EXPECT_EQ(g.getDate(0), 0);
  EXPECT_EQ(g.getDate(1), 0);
  EXPECT_EQ(g.getDate(2), 1);
  EXPECT_EQ(g.getDate(3), 3);

  // The recurrence is tight: date(1) >= date(3) + 1 - 2*lambda, 0 == 3 - 3.
  EXPECT_EQ(g.getDate(1), g.getDate(3) + 1 - 2 * g.getPeriod());

  // And the circuit that bound the period is reported, entering arc first.
  auto circuit = g.getCriticalCircuit();
  EXPECT_FALSE(circuit.empty());
  EXPECT_EQ(circuit.front(), rec);
}

/// With no recurrence the period is whatever lower bound it was given --
/// ResMII in practice -- and the potentials are the plain longest path.
TEST(ParametricLabelCorrecting, NoRecurrence) {
  ParametricLabelCorrecting g;
  for (unsigned i = 0; i != 4; ++i)
    g.addNode();
  g.addArc(0, 1, 1, 0);
  g.addArc(1, 2, 2, 0);
  g.addArc(1, 3, 1, 0);
  g.addArc(2, 3, 3, 0);

  ASSERT_EQ(g.solve(7), Result::Solved);
  EXPECT_EQ(g.getPeriod(), 7);
  EXPECT_EQ(g.getDate(3), 6); // 1 + 2 + 3, not the shorter 1 + 1
  EXPECT_TRUE(g.getCriticalCircuit().empty());
}

/// A self-loop is a recurrence like any other: an accumulator read and written
/// by one operation, at distance one, sets the period to its own latency.
TEST(ParametricLabelCorrecting, SelfLoopSetsThePeriod) {
  ParametricLabelCorrecting g;
  for (unsigned i = 0; i != 2; ++i)
    g.addNode();
  g.addArc(0, 1, 0, 0);
  g.addArc(1, 1, 5, 1);

  ASSERT_EQ(g.solve(), Result::Solved);
  EXPECT_EQ(g.getPeriod(), 5);
}

/// The period is the maximum over circuits, not the first one found.
TEST(ParametricLabelCorrecting, MaximumOverCircuits) {
  ParametricLabelCorrecting g;
  for (unsigned i = 0; i != 5; ++i)
    g.addNode();
  g.addArc(0, 1, 0, 0);
  g.addArc(1, 2, 1, 0);
  g.addArc(2, 1, 1, 1); // ceil(2/1) = 2
  g.addArc(0, 3, 0, 0);
  g.addArc(3, 4, 7, 0);
  g.addArc(4, 3, 2, 2); // ceil(9/2) = 5

  ASSERT_EQ(g.solve(), Result::Solved);
  EXPECT_EQ(g.getPeriod(), 5);
}

/// Raising the period never lowers it below a resource bound handed in.
TEST(ParametricLabelCorrecting, RespectsTheLowerBound) {
  ParametricLabelCorrecting g;
  for (unsigned i = 0; i != 2; ++i)
    g.addNode();
  g.addArc(0, 1, 0, 0);
  g.addArc(1, 1, 3, 1);

  ASSERT_EQ(g.solve(11), Result::Solved);
  EXPECT_EQ(g.getPeriod(), 11); // max(RecMII 3, ResMII 11)
}

/// A positive circuit carrying no distance cannot be made feasible by any
/// period -- it is a dependence cycle within one iteration.
TEST(ParametricLabelCorrecting, PositiveCircuitWithoutDistance) {
  ParametricLabelCorrecting g;
  for (unsigned i = 0; i != 3; ++i)
    g.addNode();
  g.addArc(0, 1, 0, 0);
  g.addArc(1, 2, 1, 0);
  g.addArc(2, 1, 1, 0);

  EXPECT_EQ(g.solve(), Result::InfeasibleCircuit);
}

/// The root must reach every node along zero-distance arcs, which a dependence
/// graph's source node provides; say so rather than producing a potential that
/// means nothing.
TEST(ParametricLabelCorrecting, UnreachableNode) {
  ParametricLabelCorrecting g;
  for (unsigned i = 0; i != 3; ++i)
    g.addNode();
  g.addArc(0, 1, 1, 0);
  // node 2 is reachable only across an iteration boundary
  g.addArc(1, 2, 1, 1);

  EXPECT_EQ(g.solve(), Result::Unreachable);
}

/// The potentials are affine in the period, and the `nu` component is the
/// negated distance along the tree path -- which is what lets a dichotomy
/// raise the period without re-solving.
TEST(ParametricLabelCorrecting, PotentialsAreAffine) {
  ParametricLabelCorrecting g;
  for (unsigned i = 0; i != 3; ++i)
    g.addNode();
  g.addArc(0, 1, 0, 0);
  g.addArc(1, 2, 4, 0);
  g.addArc(2, 1, 0, 1); // forces lambda >= 4

  ASSERT_EQ(g.solve(), Result::Solved);
  EXPECT_EQ(g.getPeriod(), 4);
  AffinePeriod p2 = g.getPotential(2);
  EXPECT_EQ(p2.at(g.getPeriod()), g.getDate(2));
}

} // namespace
