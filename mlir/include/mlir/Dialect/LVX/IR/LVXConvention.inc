//===-- LVXConvention.inc - -*- C++ -*- ===//
//
// The 'regular' calling convention's register sets.
//
// Generated from the LVX Machine Description System by MDS/BE/MLIR, for core
// lvx_v2.  DO NOT EDIT -- your changes will be overwritten by the next
// `make -C BE/MLIR install`.  Change lvx-mds/lvx-family's YAML description,
// or the generator in MDS/BE/MLIR/BIN, instead.
//
//===----------------------------------------------------------------===//

#ifndef LVX_CONVENTION_INC
#define LVX_CONVENTION_INC

namespace mlir {
namespace lvx {

/// The 12 registers passed to a call, in order.
inline constexpr Register kAbiArgRegs[] = {
    Register::r0, Register::r1, Register::r2, Register::r3, Register::r4,
    Register::r5, Register::r6, Register::r7, Register::r8, Register::r9,
    Register::r10, Register::r11
};
inline constexpr unsigned kNumAbiArgRegs = 12;

/// The 4 registers returned from a call, in order.
inline constexpr Register kAbiResultRegs[] = {
    Register::r0, Register::r1, Register::r2, Register::r3
};
inline constexpr unsigned kNumAbiResultRegs = 4;

/// The 47 registers a caller must save across a call.
inline constexpr Register kCallerSavedRegs[] = {
    Register::r0, Register::r1, Register::r2, Register::r3, Register::r4,
    Register::r5, Register::r6, Register::r7, Register::r8, Register::r9,
    Register::r10, Register::r11, Register::r15, Register::r16, Register::r17,
    Register::r32, Register::r33, Register::r34, Register::r35, Register::r36,
    Register::r37, Register::r38, Register::r39, Register::r40, Register::r41,
    Register::r42, Register::r43, Register::r44, Register::r45, Register::r46,
    Register::r47, Register::r48, Register::r49, Register::r50, Register::r51,
    Register::r52, Register::r53, Register::r54, Register::r55, Register::r56,
    Register::r57, Register::r58, Register::r59, Register::r60, Register::r61,
    Register::r62, Register::r63
};
inline constexpr unsigned kNumCallerSavedRegs = 47;

/// The 15 registers a callee must preserve across a call.
inline constexpr Register kCalleeSavedRegs[] = {
    Register::r14, Register::r18, Register::r19, Register::r20, Register::r21,
    Register::r22, Register::r23, Register::r24, Register::r25, Register::r26,
    Register::r27, Register::r28, Register::r29, Register::r30, Register::r31
};
inline constexpr unsigned kNumCalleeSavedRegs = 15;

/// The 2 registers that are never allocatable.
inline constexpr Register kReservedRegs[] = {
    Register::r12, Register::r13
};
inline constexpr unsigned kNumReservedRegs = 2;

/// The 2 registers held as scratch for a long-branch veneer.
inline constexpr Register kVeneerRegs[] = {
    Register::r16, Register::r17
};
inline constexpr unsigned kNumVeneerRegs = 2;

/// $r12 -- stack pointer.
inline constexpr Register kStackReg = Register::r12;

/// $r13 -- thread-local/local data pointer.
inline constexpr Register kLocalReg = Register::r13;

/// $r14 -- frame pointer.
inline constexpr Register kFrameReg = Register::r14;

/// $r15 -- hidden struct-return pointer.
inline constexpr Register kStructReg = Register::r15;

/// $ra -- return address.
inline constexpr Register kReturnReg = Register::ra;

/// True if `r` belongs to `set`.  constexpr so the sets above can be used in
/// a static_assert, which is how a pass states an ABI invariant it depends on
/// -- see ScratchRegisters.h.
template <unsigned N>
inline constexpr bool isIn(Register r, const Register (&set)[N]) {
  for (unsigned i = 0; i < N; ++i)
    if (set[i] == r)
      return true;
  return false;
}

} // namespace lvx
} // namespace mlir

#endif // LVX_CONVENTION_INC
