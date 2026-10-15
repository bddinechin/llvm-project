//===- CrossStageValues.cpp - What a stage assignment leaves in flight ---===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/LVX/Analysis/CrossStageValues.h"

#include "llvm/ADT/DenseMap.h"

using namespace mlir;
using namespace mlir::lvx;

void CrossStageValues::note(Value value, unsigned defStage, unsigned useStage,
                            bool loopCarried) {
  // A use before the definition is not a late use, it is a broken schedule.
  // Within an iteration that means any earlier stage; across the back edge the
  // use gets one trip of slack, since it happens in the next iteration -- so a
  // value yielded at stage 2 cannot be read at stage 0, its consumer running a
  // trip before its producer. That is the recurrence constraint at stage
  // granularity, and a schedule violating it is not a pipeline.
  if (loopCarried ? useStage + 1 < defStage : useStage < defStage) {
    valid = false;
    return;
  }
  for (Crossing &c : crossings)
    if (c.value == value && c.loopCarried == loopCarried) {
      c.lastUseStage = std::max(c.lastUseStage, useStage);
      maxNames = std::max(maxNames, c.names());
      return;
    }
  crossings.push_back({value, defStage, useStage, loopCarried});
  maxNames = std::max(maxNames, crossings.back().names());
}

CrossStageValues::CrossStageValues(lvx_scf::ForOp loop,
                                   llvm::ArrayRef<unsigned> stages)
    : stages(stages) {
  Block &body = *loop.getBody();

  // Number the body operations the way the stage vector is indexed: in order,
  // terminator excluded.
  llvm::DenseMap<Operation *, unsigned> index;
  unsigned n = 0;
  for (Operation &op : body.without_terminator()) {
    if (n >= stages.size()) {
      valid = false;
      return;
    }
    index[&op] = n;
    numStages = std::max(numStages, stages[n] + 1);
    ++n;
  }
  if (n != stages.size()) {
    valid = false;
    return;
  }

  auto stageOf = [&](Operation *op) -> unsigned {
    auto it = index.find(op);
    // The terminator belongs to the last stage: it is what hands a value to
    // the next iteration, and it issues once every stage has.
    return it == index.end() ? numStages - 1 : stages[it->second];
  };

  // Intra-iteration: a result computed in one stage and read in a later one.
  for (Operation &op : body.without_terminator()) {
    unsigned defStage = stages[index[&op]];
    for (Value result : op.getResults())
      for (Operation *user : result.getUsers()) {
        if (user->getBlock() != &body)
          continue; // nested regions are not pipelined
        if (isa<lvx_scf::YieldOp>(user))
          continue; // handled with the loop-carried values below
        note(result, defStage, stageOf(user), /*loopCarried=*/false);
      }
  }

  // Loop-carried: the yield's operand reaches the matching `iter_arg` of the
  // next iteration, so its definition and its use are a trip apart on top of
  // whatever stages separate them. This is the distance modulo variable
  // expansion is really for -- an accumulator written late and read early is
  // alive across the back edge whatever the stage assignment does.
  auto yield = cast<lvx_scf::YieldOp>(body.getTerminator());
  ValueRange iterArgs = loop.getRegionIterArgs();
  for (auto [i, yielded] : llvm::enumerate(yield.getOperands())) {
    if (i >= iterArgs.size())
      break;
    Operation *def = yielded.getDefiningOp();
    unsigned defStage = def ? stageOf(def) : 0;
    for (Operation *user : iterArgs[i].getUsers()) {
      if (user->getBlock() != &body)
        continue;
      unsigned useStage =
          isa<lvx_scf::YieldOp>(user) ? defStage : stageOf(user);
      note(yielded, defStage, useStage, /*loopCarried=*/true);
    }
  }
}
