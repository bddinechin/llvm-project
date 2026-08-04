//===-- LVXAddressSpaces.h - LVX address spaces ---------------*- C++ -*-===//
//
// The LVX address spaces, and how they select a load's `variant` modifier.
//
// These numbers are ABI, not a private choice: lvx-gcc registers the same
// address spaces by name in gcc/config/lvx/lvx.h
//
//     c_register_addr_space ("__bypass",    LVX_ADDR_SPACE_BYPASS    = 1)
//     c_register_addr_space ("__preload",   LVX_ADDR_SPACE_PRELOAD   = 2)
//     c_register_addr_space ("__speculate", LVX_ADDR_SPACE_SPECULATE = 3)
//     c_register_addr_space ("__convert",   LVX_ADDR_SPACE_CONVERT   = 4)
//
// so a "__bypass int *" must mean the same thing to both compilers or the two
// disagree on the same source.
//
// The variant values themselves come from the machine description: lvx-refs
// Modifier.table gives variant members ". .S .U .US" over values "0 1 2 3"
// with properties
//
//     %0.S:  Dismissible
//     %0.U:  MemoryLevel=2
//     %0.US: MemoryLevel=2;Dismissible
//
// -- "Dismissible" being the no-fault speculative load and "MemoryLevel=2"
// the one that bypasses the L1.  GCC prints the matching suffix straight from
// MEM_ADDR_SPACE (its 'V' operand code); nothing about this is heuristic on
// either side, which is why it belongs in a table rather than in codegen
// policy.
//
// Note the pairing is not the obvious one: __preload is .us (uncached AND
// dismissible), not .u.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_LVX_LVXADDRESSSPACES_H
#define LLVM_LIB_TARGET_LVX_LVXADDRESSSPACES_H

namespace llvm {
namespace LVXAS {

enum : unsigned {
  Generic   = 0,
  Bypass    = 1,   // __bypass    -- bypass the cache
  Preload   = 2,   // __preload   -- bypass the cache, and dismissible
  Speculate = 3,   // __speculate -- dismissible (no-fault) load
  Convert   = 4,   // __convert   -- pointer conversion only, never a load
  Syscall   = 5,   // __syscall
};

// The `variant` modifier value a load in this address space must carry, or
// ~0u when the address space is not one a load may be issued in.
// constexpr so LVXISelDAGToDAG.cpp can static_assert this mapping against the
// generated LVXLoadTable.inc: the numbering here cannot be derived from the
// machine description (it is ABI, shared with lvx-gcc), but what each variant
// MEANS can be, and the two must agree.
constexpr unsigned variantForAddressSpace(unsigned AS) {
  switch (AS) {
  case Generic:   return 0;   // no suffix
  case Speculate: return 1;   // .s
  case Bypass:    return 2;   // .u
  case Preload:   return 3;   // .us
  default:        return ~0u; // __convert/__syscall and anything unknown
  }
}

} // end namespace LVXAS
} // end namespace llvm

#endif // LLVM_LIB_TARGET_LVX_LVXADDRESSSPACES_H
