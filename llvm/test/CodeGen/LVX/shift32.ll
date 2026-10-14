; RUN: llc -mtriple=lvx-mbr < %s | FileCheck %s

; The 32-bit shifts, which are one instruction and were three.
;
; i32 is not a legal type here, so a 32-bit shift reaches the type legalizer to
; be promoted -- and promotion alone cannot express it. SLLW/SRLW/SRAW take
; their count modulo 32 (the Behavior masks it with _ZX_5) where the promoted
; 64-bit shift takes it modulo 64, so a selection pattern over the promoted
; form -- (srl (and X, 0xffffffff), c) -> srlw -- is a miscompile: it matches a
; genuine 64-bit shift of a masked value just as happily, and there the count is
; in range and the answer defined. `wide' at the bottom is that shape and must
; keep its srld.
;
; So LVXTargetLowering::ReplaceNodeResults builds a target node while the width
; is still known, exactly as RV64 does with RISCVISD::SLLW/SRLW/SRAW.
;
; Two things have to hold for the node to be worth anything, and each was an
; instruction when it did not:
;   - the COUNT arrives masked to 32 bits (an i32 promoted back), and the
;     instruction masks to five itself, so the ANDD is dead -- matched away by
;     the second set of patterns;
;   - the RESULT is sign-extended by the instruction for free, which
;     ComputeNumSignBitsForTargetNode has to state (33 bits) or the extension is
;     emitted again as an EXTFS.

define signext i32 @sra32(i32 signext %a, i32 signext %b) {
; CHECK-LABEL: sra32:
; CHECK-NOT:     andd
; CHECK-NOT:     extfsd
; CHECK:         sraw.sx $r0 = $r0, $r1
; CHECK-NEXT:    ;;
; CHECK-NEXT:    ret
  %r = ashr i32 %a, %b
  ret i32 %r
}

define zeroext i32 @srl32(i32 zeroext %a, i32 zeroext %b) {
; CHECK-LABEL: srl32:
; CHECK:         srlw.sx $r0 = $r0, $r1
  %r = lshr i32 %a, %b
  ret i32 %r
}

define signext i32 @shl32(i32 signext %a, i32 signext %b) {
; CHECK-LABEL: shl32:
; CHECK-NOT:     andd
; CHECK:         sllw.sx $r0 = $r0, $r1
  %r = shl i32 %a, %b
  ret i32 %r
}

; Widened afterwards: the instruction's own sign extension is the answer, so
; there is nothing left to do.
define i64 @sra32_widened(i32 signext %a, i32 signext %b) {
; CHECK-LABEL: sra32_widened:
; CHECK-NOT:     extfsd
; CHECK:         sraw.sx $r0 = $r0, $r1
  %r = ashr i32 %a, %b
  %s = sext i32 %r to i64
  ret i64 %s
}

; A CONSTANT count is left to generic promotion on purpose: it is known below
; 32, so the promoted 64-bit shift of a correctly extended value is exact, and
; the generated SRLD immediate pattern takes it.
define zeroext i32 @srl32_const(i32 zeroext %a) {
; CHECK-LABEL: srl32_const:
; CHECK:         srld
  %r = lshr i32 %a, 5
  ret i32 %r
}

; And the shape a pattern would have swallowed: 64-bit, masked, shifted by a
; count a 32-bit instruction could not take. This one must NOT be narrow.
define i64 @wide(i64 %x, i64 %c) {
; CHECK-LABEL: wide:
; CHECK-NOT:     srlw
; CHECK:         srld
  %m = and i64 %x, 4294967295
  %r = lshr i64 %m, %c
  ret i64 %r
}
