//===- ScratchRegisters.h - LVX reserved scratch registers ------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// The registers held out of the general allocation pool for post-allocation
// passes to pin values to. Shared because three passes need the same answer
// and previously each spelled it out for itself: -lvx-allocate-registers
// (spill def-then-store / reload-then-use windows and the prologue's frame
// offset), -lvx-rewrite-divmod (the `registerM` result pair), and
// -lvx-scf-to-cf (the hardware-loop trip count and the branch-test compare).
//
// That duplication was a live bug, not a style problem: when the pool moved
// off R29-R31, SCFToCF kept pinning to R29 with a comment asserting R29 was
// "permanently excluded from the general allocation pool" -- by then false.
// Since SCFToCF runs *after* allocation, the allocator could hand R29 to a
// live value and the loop test would silently clobber it.
//
// Two invariants these must satisfy, both learned the hard way:
//
//  - **Caller-saved.** Per `Convention.table`, R61-R63 are; R29-R31 (the
//    original choice) are callee-saved. A scratch window is transient and
//    never crosses a call, so nothing needs preserving across it -- but a
//    callee-saved choice clobbers the caller's value in a register it is
//    entitled to get back, with no save to match, making every spilling
//    function ABI-illegal against lvx-gcc callers.
//  - **An even/odd aligned pair among them.** `lvx.divmodd` and friends
//    write an aligned register pair (the `registerM` operand class, a 5-bit
//    field naming one of 32 pairs). R62:R63 is pair index 31.
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_DIALECT_LVX_TRANSFORMS_SCRATCHREGISTERS_H
#define MLIR_DIALECT_LVX_TRANSFORMS_SCRATCHREGISTERS_H

#include "mlir/Dialect/LVX/IR/LVXConvention.h"

namespace mlir {
namespace lvx {

/// Registers reserved out of the general allocation pool. Sized for the
/// worst case among currently-defined ops needing several simultaneously:
/// `lvx.cmoved`/`lvx.cmovew`'s three register operands, and
/// `lvx.divmodd`/etc.'s two results.
inline constexpr Register kScratchRegs[] = {Register::r61, Register::r62,
                                            Register::r63};
inline constexpr unsigned kNumScratchRegs = 3;

/// The general-purpose scratch register, used where a single transient
/// value needs pinning (prologue frame offset, $ra snapshot, hardware-loop
/// trip count, branch-test compare result).
inline constexpr Register kScratchReg = kScratchRegs[0];

/// The aligned pair `lvx.divmodd` and friends write their two results to.
/// Must stay even/odd adjacent -- see the header comment.
inline constexpr Register kScratchPairLo = kScratchRegs[1];
inline constexpr Register kScratchPairHi = kScratchRegs[2];

// The two invariants from the header comment, now checked against the
// generated convention instead of being asserted in prose. The first one
// was violated once -- R29-R31 are callee-saved -- and the compiler had no
// way to notice; it does now.
static_assert(isIn(kScratchRegs[0], kCallerSavedRegs) &&
                  isIn(kScratchRegs[1], kCallerSavedRegs) &&
                  isIn(kScratchRegs[2], kCallerSavedRegs),
              "a scratch register is callee-saved: every spilling function "
              "would clobber a register its caller is entitled to get back");
static_assert(static_cast<unsigned>(kScratchPairLo) % 2 == 0 &&
                  static_cast<unsigned>(kScratchPairHi) ==
                      static_cast<unsigned>(kScratchPairLo) + 1,
              "the divmod scratch pair is not an even/odd aligned pair");

} // namespace lvx
} // namespace mlir

#endif // MLIR_DIALECT_LVX_TRANSFORMS_SCRATCHREGISTERS_H
