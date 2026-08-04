//===-- LVXCallingConv.td - LVX Calling Convention --------*- tablegen -*-===//
//
// Implements the "regular" calling convention from
// lvx_ApplicationBinaryInterface.tex and lvx_Convention.yml.
//
// Argument slot model (Section "Function Arguments and Result"):
//   - Each argument slot is 8 bytes (64 bits), naturally aligned.
//   - Integral scalars < 64 bits are placed in the low bits of a slot
//     (CCAssignToReg / CCAssignToStack pick whole 64-bit slots; the
//     sub-64-bit placement within the slot is handled by the type
//     legalizer, not by this file).
//   - The first 12 slots (slot 0-11) go in GPR R0-R11.
//   - Slot 12 onward go to the Outgoing Arguments stack region, 8 bytes
//     each, starting at the incoming SP.
//   - An argument that straddles slot 11/12 has its low part in R11 and
//     its high part on the stack.
//
// IMPORTANT — implemented via CCCustom (see CC_LVX_Custom in
// LVXISelLowering.cpp): TableGen's declarative CC rules alone cannot
// share a single slot counter across different value types (i64 vs
// i128 vs v4i64) or implement the slot-11/12 straddle rule, so this file
// only handles type promotion/bitconversion declaratively and defers
// all register/stack slot assignment to one C++ callback that tracks a
// shared slot index across every CC_LVX rule and splits an argument
// across registers and the stack at exactly the slot-11/12 boundary, as
// the ABI doc requires.
//
// Return values (up to 32 bytes / 4 slots) use the same register list as
// arguments: R0-R3 ("result" in lvx_Convention.yml). Larger or
// dynamically-sized returns are passed via a caller-allocated buffer
// whose pointer arrives in R15 ("struct" in lvx_Convention.yml) — that
// pointer itself is passed as slot 0 in R0 per the "as if it were the
// first parameter" rule, so no special CC rule is needed for it; the
// frontend lowers sret accordingly.
//
// 128-bit and 256-bit aggregates (GPR128 / GPR256) follow the same slot
// rules: a 128-bit value occupies two consecutive slots (two GPRs or two
// stack words), a 256-bit value occupies four.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Argument registers: slots 0-11 -> R0-R11
//===----------------------------------------------------------------------===//

def CC_LVX : CallingConv<[
  // f16/f32 travel in the low bits of a 64-bit slot, sharing the same
  // GPR/stack slot sequence as integers. Reinterpret them as the SAME-SIZED
  // integer here, then let the promotion rule below widen that to the slot.
  // Converting straight to i64 is not a reinterpretation at all -- f32 is 32
  // bits -- and asserts "Cannot BITCAST between types of different sizes" on
  // the first float argument compiled.
  CCIfType<[f16], CCBitConvertToType<i16>>,
  CCIfType<[f32], CCBitConvertToType<i32>>,

  // Promote small integer types to i64 — every argument slot is 64 bits
  // wide and integral scalars are placed in the low bits of the slot.
  CCIfType<[i1, i8, i16, i32], CCPromoteToType<i64>>,

  // f16/f32 are passed in the low bits of a 64-bit slot without promotion
  // (per "Half-precision floating-point arguments ... are passed directly
  // with 48-bit of padding" and the analogous rule for single precision).
  // They share the same GPR/stack slot sequence as integers, so they are
  // bitcast to i64-sized container types by the frontend; CC just assigns
  // the slot.
  // ---- 64/128/256-bit arguments: shared slot counter via CCCustom -----
  // CC_LVX_Custom (LVXISelLowering.cpp) handles i64, f64, i128, and
  // v4i64 uniformly, allocating 1/1/2/4 8-byte slots respectively from
  // a single counter shared across all of them, splitting across
  // R0-R11 and the Outgoing Arguments stack region at exactly the
  // slot-11/12 boundary per the ABI doc's straddle rule. This replaces
  // separate CCAssignToReg/CCAssignToStack rules per type, since those
  // cannot share state across CCIfType branches.
  CCIfType<[i64, f64, i128, v4i64], CCCustom<"CC_LVX_Custom">>
]>;

//===----------------------------------------------------------------------===//
// Return values: slots 0-3 -> R0-R3 ("result" in lvx_Convention.yml)
//
// Return values up to 32 bytes (4 x 8 bytes) are returned directly in
// R0-R3, following the same slot-assignment rules as arguments. Larger
// or dynamically-sized returns are written through the buffer pointer
// passed in R15 by the caller (sret lowering in LVXISelLowering,
// Phase 3) and produce no CC_LVXRet entries themselves.
//===----------------------------------------------------------------------===//

def CC_LVXRet : CallingConv<[
  CCIfType<[f16], CCBitConvertToType<i16>>,
  CCIfType<[f32], CCBitConvertToType<i32>>,
  CCIfType<[i1, i8, i16, i32], CCPromoteToType<i64>>,

  CCIfType<[i64, f64],  CCAssignToReg<[R0, R1, R2, R3]>>,
  CCIfType<[i128],      CCAssignToReg<[R0R1, R2R3]>>,
  CCIfType<[v4i64],     CCAssignToReg<[R0R1R2R3]>>
]>;

//===----------------------------------------------------------------------===//
// Callee-saved registers (preserved across calls)
//
// From lvx_Convention.yml "callee": R14 (FP), R18-R31.
// R14 doubles as the frame pointer; it is included here unconditionally —
// LVXFrameLowering (Phase 5) decides at runtime whether it must actually
// be saved (i.e. when the function needs a frame pointer it is saved like
// any other callee-saved register via the Frame Marker region; when it
// does not need one, R14 behaves as an ordinary callee-saved GPR and is
// only saved/restored if the function clobbers it).
//
// $ra is saved separately by the prologue/epilogue inserter for non-leaf
// functions (per "it must save the RA register in the stack frame"); it
// is not part of the GPR callee-saved list because it is a control
// register (CR_RW), not a GPR.
//===----------------------------------------------------------------------===//

def CSR_LVX : CalleeSavedRegs<(add
  R14,
  R18, R19, R20, R21, R22, R23,
  R24, R25, R26, R27, R28, R29, R30, R31
)>;

// 128-bit view of the callee-saved set, for spilling GPR128 values that
// happen to be live across a call (e.g. a 128-bit local promoted to a
// register pair entirely within the callee-saved range).
def CSR_LVX128 : CalleeSavedRegs<(add
  R18R19, R20R21, R22R23, R24R25, R26R27, R28R29, R30R31
)>;
