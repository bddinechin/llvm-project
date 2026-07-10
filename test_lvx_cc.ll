; Minimal LVX calling-convention test.
; Tests CC_LVX_Custom / LowerFormalArguments / LowerReturn for:
;   - i64  (1 slot, trivially in registers)
;   - i128 (2 slots, BUILD_PAIR reassembly, possible straddle at slot 11/12)
;   - v4i64 (4 slots, BUILD_VECTOR reassembly)
;
; All functions are leaf (no calls) and have no local variables, so
; eliminateFrameIndex (llvm_unreachable stub) and LowerCall
; (unmatched LVXISD::CALL pattern) are not exercised -- those need
; separate tests once prologue/epilogue and ISelDAGToDAG::Select
; are implemented.
;
; Run with:
;   llc -mtriple=lvx -o - test_lvx_cc.ll
;
; Expected: llc should not crash. Examine the output for:
;   - COPYD / CATDQ instructions for argument realignment (the i128/v4i64 cases)
;   - ret instruction at the end of each function
;   - correct register assignments consistent with CC_LVX_Custom's slot order

target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n32:64-S128"
; target triple will be set via -mtriple on the command line

; ---- Test 1: single i64 argument, pass straight back ----
; Expected: identity, argument arrives in R0, returned in R0.
; No realignment needed (1 slot, always aligned).
define i64 @identity_i64(i64 %a) {
  ret i64 %a
}

; ---- Test 2: two i64 arguments, return second ----
; Expected: %a in R0, %b in R1, return value in R0.
; Exercises the shared slot counter advancing across two arguments.
define i64 @return_second_i64(i64 %a, i64 %b) {
  ret i64 %b
}

; ---- Test 3: i128 argument, pass straight back ----
; Arguments: %a occupies slots 0-1 (R0R1), aligned pair, no straddle.
; Expected: CATDQ R0R1 = R0, R1 (or similar realignment to an aligned pair)
; then return via CC_LVXRet (R0R1 -> result).
define i128 @identity_i128(i128 %a) {
  ret i128 %a
}

; ---- Test 4: i64 then i128, exercises slot misalignment ----
; Arguments: %a in slot 0 (R0), %b in slots 1-2 (R1+R2).
; R1+R2 is NOT an aligned GPR128 pair (valid pairs are R0R1, R2R3, ...).
; This is the primary straddle/misalignment case the ABI doc describes:
; copyPhysReg should emit CATDQ to move R1+R2 into an aligned pair
; before %b is usable as an i128 operand.
; Return %b to force it through LowerReturn's CC_LVXRet.
define i128 @i64_then_i128(i64 %a, i128 %b) {
  ret i128 %b
}

; ---- Test 5: three i64s then i128, deeper misalignment ----
; Arguments: %a=R0, %b=R1, %c=R2, %d=slots 3-4 (R3+R4).
; R3+R4 is not a valid aligned pair either (pairs are even-based: R2R3,
; R4R5 -- R3R4 is not in GPR128). Tests the generic case where the
; misaligned pair starts at an odd slot.
define i128 @three_i64s_then_i128(i64 %a, i64 %b, i64 %c, i128 %d) {
  ret i128 %d
}

; ---- Test 6: i128 straddling the slot-11/12 boundary ----
; Arguments: five i64s (slots 0-4) + one i64 each (5,6,7,8,9,10) +
; an i128 starting at slot 11. Slot 11 is R11 (last register), slot 12
; is the first stack slot. The i128 gets R11 for its low half and
; stack[0] for its high half -- this is THE straddle case from the ABI doc.
; CC_LVX_Custom should produce one getCustomReg (R11) and one
; getCustomMem (SP+0) for the two pieces of %w.
define i128 @straddle_i128(i64 %a0, i64 %a1, i64 %a2, i64 %a3, i64 %a4,
                            i64 %a5, i64 %a6, i64 %a7, i64 %a8, i64 %a9,
                            i64 %a10, i128 %w) {
  ret i128 %w
}

; ---- Test 7: v4i64 argument, pass straight back ----
; Arguments: %a occupies slots 0-3 (R0-R3), an aligned quad (R0R1R2R3).
; Expected: BUILD_VECTOR from four i64 pieces, then CATDQ x2 for
; realignment into an aligned GPR256 if the slots happen to be
; non-quad-aligned (they aren't in this case, but the lowering code
; path is exercised regardless).
define <4 x i64> @identity_v4i64(<4 x i64> %a) {
  ret <4 x i64> %a
}

; ---- Test 8: i64 then v4i64, forces quad misalignment ----
; Arguments: %a=R0, %b=slots 1-4 (R1+R2+R3+R4).
; R1R2R3R4 is NOT a valid aligned quad (quads are R0R1R2R3, R4R5R6R7, ...).
; copyPhysReg for GPR256 should emit two CATDQs to realign into an
; aligned quad.
define <4 x i64> @i64_then_v4i64(i64 %a, <4 x i64> %b) {
  ret <4 x i64> %b
}
