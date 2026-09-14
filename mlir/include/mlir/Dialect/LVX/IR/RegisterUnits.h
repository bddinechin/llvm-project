//===- RegisterUnits.h - One unit space for reg, pair and quad ------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// The register allocator's view of the three register-parameterized types
// (lvx-mlir/docs/RegisterAllocation.md, "Step 4 -- Register tuples"): a
// value occupies a block of `width` consecutive *units* starting at `base`,
// where a unit is one general-purpose register. A `!lvx.reg<r5>` is the
// block {5}, a `!lvx.pair<r4r5>` is {4, 5}, a `!lvx.quad<r4r5r6r7>` is
// {4, 5, 6, 7}. The three enums make this arithmetic rather than a lookup:
// a GPR's value is its number (its dwarfId equals its address, which the
// generator checks) and a tuple's value is its first component's number.
//
// Everything else the allocator does with a type -- reading a pinned
// location, sizing an item, retyping a value -- goes through the three
// functions here, so that they are the whole of its contact with the type
// system.
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_DIALECT_LVX_IR_REGISTERUNITS_H
#define MLIR_DIALECT_LVX_IR_REGISTERUNITS_H

#include "mlir/Dialect/LVX/IR/LVX.h"
#include "llvm/Support/raw_ostream.h"

#include <optional>

namespace mlir {
namespace lvx {

// The unit-space invariant, asserted against the generated enums rather than
// assumed: a renumbering in the description would fail here, not misallocate.
static_assert(static_cast<unsigned>(Register::r0) == 0 &&
                  static_cast<unsigned>(Register::r63) == 63,
              "a GPR's enumerator must be its number");
static_assert(static_cast<unsigned>(PairRegister::r0r1) == 0 &&
                  static_cast<unsigned>(PairRegister::r62r63) == 62,
              "a pair's enumerator must be its first component's number");
static_assert(static_cast<unsigned>(QuadRegister::r0r1r2r3) == 0 &&
                  static_cast<unsigned>(QuadRegister::r60r61r62r63) == 60,
              "a quad's enumerator must be its first component's number");

/// The number of general-purpose registers, i.e. of units a block wider than
/// one may start in. The system registers (values 64 and up) are units too,
/// but only ever as width-1 fixed locations.
inline constexpr unsigned kNumGPRUnits = 64;

/// A physical location: `width` consecutive units starting at `base`.
///   width 1: a GPR or a system register (base < getMaxEnumValForRegister()+1)
///   width 2: an aligned pair (base < 64, base % 2 == 0)
///   width 4: an aligned quad (base < 64, base % 4 == 0)
struct PhysLoc {
  unsigned base;
  unsigned width;

  bool operator==(const PhysLoc &o) const {
    return base == o.base && width == o.width;
  }
  bool operator!=(const PhysLoc &o) const { return !(*this == o); }
  /// One past the last unit.
  unsigned end() const { return base + width; }
  /// Whether the two blocks share a unit.
  bool overlaps(const PhysLoc &o) const {
    return base < o.end() && o.base < end();
  }
};

/// The width in units of a register-parameterized type: 1 for `!lvx.reg`,
/// 2 for `!lvx.pair`, 4 for `!lvx.quad`; 0 for any other type.
inline unsigned widthOf(Type t) {
  if (isa<RegisterType>(t))
    return 1;
  if (isa<PairType>(t))
    return 2;
  if (isa<QuadType>(t))
    return 4;
  return 0;
}

/// The location a register-parameterized type is pinned to, if it is.
inline std::optional<PhysLoc> pinnedLoc(Type t) {
  if (auto ty = dyn_cast<RegisterType>(t)) {
    if (auto r = ty.getReg())
      return PhysLoc{static_cast<unsigned>(*r), 1};
    return std::nullopt;
  }
  if (auto ty = dyn_cast<PairType>(t)) {
    if (auto r = ty.getReg())
      return PhysLoc{static_cast<unsigned>(*r), 2};
    return std::nullopt;
  }
  if (auto ty = dyn_cast<QuadType>(t)) {
    if (auto r = ty.getReg())
      return PhysLoc{static_cast<unsigned>(*r), 4};
    return std::nullopt;
  }
  return std::nullopt;
}

/// The pinned type for a location -- the inverse of `pinnedLoc`, and the one
/// place the three type constructors are named together.
inline Type typeFor(MLIRContext *ctx, PhysLoc loc) {
  switch (loc.width) {
  case 1:
    return RegisterType::get(ctx, static_cast<Register>(loc.base));
  case 2:
    assert(loc.base % 2 == 0 && loc.base < kNumGPRUnits && "misaligned pair");
    return PairType::get(ctx, static_cast<PairRegister>(loc.base));
  case 4:
    assert(loc.base % 4 == 0 && loc.base < kNumGPRUnits && "misaligned quad");
    return QuadType::get(ctx, static_cast<QuadRegister>(loc.base));
  }
  llvm_unreachable("a PhysLoc is 1, 2 or 4 units wide");
}

/// The ISA's spelling of a location: `r5`, `r4r5`, `r4r5r6r7`, `ra`.
inline StringRef spellingOf(PhysLoc loc) {
  switch (loc.width) {
  case 1:
    return stringifyRegister(static_cast<Register>(loc.base));
  case 2:
    return stringifyPairRegister(static_cast<PairRegister>(loc.base));
  case 4:
    return stringifyQuadRegister(static_cast<QuadRegister>(loc.base));
  }
  llvm_unreachable("a PhysLoc is 1, 2 or 4 units wide");
}

inline raw_ostream &operator<<(raw_ostream &os, PhysLoc loc) {
  return os << spellingOf(loc);
}

} // namespace lvx
} // namespace mlir

#endif // MLIR_DIALECT_LVX_IR_REGISTERUNITS_H
