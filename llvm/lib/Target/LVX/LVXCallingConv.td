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
// IMPORTANT — Phase 5 TODO: TableGen's declarative CC rules cannot share a
// single slot counter across different value types (i64 vs i128 vs v4i64)
// or implement the slot-11/12 straddle rule. CC_LVX below uses simple
// independent CCAssignToReg lists per type as a Phase 1/2 placeholder that
// is correct only for argument lists containing a single value type with
// no more than 12 total slots. Before Phase 5 is complete, the i64/i128/
// v4i64 rules and the straddle rule must be replaced with a CCCustom C++
// callback (e.g. CC_LVX_Custom) that maintains one shared slot index across
// all argument types, as is done for similar register-pair ABIs in other
// targets (e.g. Mips o32, ARM AAPCS).
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
  // Promote small integer types to i64 — every argument slot is 64 bits
  // wide and integral scalars are placed in the low bits of the slot.
  CCIfType<[i1, i8, i16, i32], CCPromoteToType<i64>>,

  // f16/f32 are passed in the low bits of a 64-bit slot without promotion
  // (per "Half-precision floating-point arguments ... are passed directly
  // with 48-bit of padding" and the analogous rule for single precision).
  // They share the same GPR/stack slot sequence as integers, so they are
  // bitcast to i64-sized container types by the frontend; CC just assigns
  // the slot.
  CCIfType<[f16, f32], CCBitConvertToType<i64>>,

  // ---- 64-bit scalar arguments: slots 0-11 in R0-R11, else stack ------
  CCIfType<[i64, f64],
    CCAssignToReg<[R0, R1, R2, R3, R4, R5, R6, R7, R8, R9, R10, R11]>>,

  // ---- 128-bit arguments: register pairs within R0-R11 -----------------
  // NOTE: TableGen's CC infrastructure has no built-in way to share a
  // single slot counter between the GPR (R0-R11) and GPR128 (R0R1..R10R11)
  // assignment lists, nor to implement the slot-11/12 straddle rule (low
  // half in R11, high half on the stack). Both require a CCCustom C++
  // callback (e.g. CC_LVX_128) registered in LVXISelLowering (Phase 5),
  // which must track a shared slot index across all CC_LVX rules. The
  // rule below is a placeholder that is correct only when no i64/f64
  // arguments precede a i128 argument; it will be replaced by CCCustom.
  CCIfType<[i128],
    CCAssignToReg<[R0R1, R2R3, R4R5, R6R7, R8R9, R10R11]>>,

  // ---- 256-bit arguments: register quads within R0-R11 -----------------
  // Same caveat as above — placeholder pending CCCustom.
  CCIfType<[v4i64],
    CCAssignToReg<[R0R1R2R3, R4R5R6R7, R8R9R10R11]>>,

  // ---- Overflow: Outgoing Arguments region on the stack -----------------
  // Slot 12 is at SP+0, slot 13 at SP+8, etc. All stack slots are 8-byte
  // aligned regardless of the argument's natural alignment, per
  // "the only alignment enforced is 8 bytes."
  CCIfType<[i64, f64, f16, f32], CCAssignToStack<8, 8>>,
  CCIfType<[i128],               CCAssignToStack<16, 8>>,
  CCIfType<[v4i64],              CCAssignToStack<32, 8>>
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
  CCIfType<[i1, i8, i16, i32], CCPromoteToType<i64>>,
  CCIfType<[f16, f32], CCBitConvertToType<i64>>,

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
