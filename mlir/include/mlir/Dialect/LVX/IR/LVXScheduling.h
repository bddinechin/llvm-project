//===- LVXScheduling.h - What each op reserves ------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// The processor resources each op occupies, generated from the machine
// description by lvx-mds' `MDS/BE/MLIR` into `LVXScheduling.inc`. This header
// pulls the pieces it needs into scope and states the two things the table
// does not say itself.
//
// **It is occupancy, not latency.** The description states a reservation
// table -- which units an instruction takes and how many -- and states no
// latency anywhere: no element carries one, `Reservation@stalls` is empty for
// every lvx_v1 class, and `Execution`'s pipeline stages are where effects
// land rather than when a result is readable (LSU reaches stage 24). A
// software pipeliner needs both, so it needs latency to reach the description
// before it can reach here. The generator deliberately invents none.
//
// **The reservation depends on the `format` attribute**, which is what that
// attribute has been for since O1/O2 with nothing to consume it: `ALU_TINY`
// takes one issue slot, `ALU_TINY.X` two, `ALU_TINY.Y` three, because a
// widened immediate costs extra syllables. The mapping cannot be composed
// from the format suffix -- that names an encoding family while the
// scheduling suffix counts syllables, and they disagree on 286 of 859
// lvx_v1 opcodes (`LSU_ACSWAPSB.O` schedules as `LSU2_MEMW_AUXR_AUXW.X`) --
// so the generator records it per (op, format) pair.
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_DIALECT_LVX_IR_LVXSCHEDULING_H
#define MLIR_DIALECT_LVX_IR_LVXSCHEDULING_H

#include "mlir/Dialect/LVX/IR/LVX.h"

#include "llvm/ADT/StringRef.h"
#include "llvm/ADT/StringSwitch.h"

#include <optional>

#include "mlir/Dialect/LVX/IR/LVXScheduling.inc"

namespace mlir {
namespace lvx {

/// No scheduling class may ask for more of a resource than one bundle has.
/// Checking it here is the point of generating `kAllReservations`: a
/// description that oversubscribed a unit would otherwise produce a model in
/// which no legal bundle exists for that instruction, and nothing would say
/// so until a bundler failed to place it.
constexpr bool reservationsFitTheMachine() {
  for (const Reservation &r : kAllReservations)
    for (unsigned i = 0; i < r.numUses; ++i)
      if (r.uses[i].count >
          kResourceAvailability[static_cast<unsigned>(r.uses[i].resource)])
        return false;
  return true;
}
static_assert(reservationsFitTheMachine(),
              "a scheduling class reserves more of a resource than a bundle "
              "provides -- no legal bundle could contain that instruction");

} // namespace lvx
} // namespace mlir

#endif // MLIR_DIALECT_LVX_IR_LVXSCHEDULING_H
