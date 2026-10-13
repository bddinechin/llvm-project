; RUN: llc -mtriple=lvx-mbr < %s | FileCheck %s

; ABSQ, MINQ/MAXQ and MINUQ/MAXUQ -- the 128-bit absolute value and both IEEE-
; style integer min/max pairs, added to the ISA on 2026-10-13. Each is one
; ALU_LITE syllable where the expansion was four instructions for abs (a SRAD of
; the sign bit, a COPYD to spread it over the pair, an EORQ and an SBFQ) and
; three for a min (COMPQ, CMOVEQ and a CATDQ to rebuild the pair).
;
; The signedness is the thing to check: a min done with the wrong extension
; agrees with the right answer on every pair of small positive values, which is
; most of them, so the mnemonic is checked by name.

define i128 @q_abs(i128 %a) {
; CHECK-LABEL: q_abs:
; CHECK-NOT:     srad
; CHECK:         absq $r0r1 = $r0r1
  %c = icmp slt i128 %a, 0
  %n = sub i128 0, %a
  %r = select i1 %c, i128 %n, i128 %a
  ret i128 %r
}

define i128 @q_smin(i128 %a, i128 %b) {
; CHECK-LABEL: q_smin:
; CHECK-NOT:     compq
; CHECK:         minq $r0r1 = $r0r1, $r2r3
  %c = icmp slt i128 %a, %b
  %r = select i1 %c, i128 %a, i128 %b
  ret i128 %r
}

define i128 @q_smax(i128 %a, i128 %b) {
; CHECK-LABEL: q_smax:
; CHECK:         maxq $r0r1 = $r0r1, $r2r3
  %c = icmp sgt i128 %a, %b
  %r = select i1 %c, i128 %a, i128 %b
  ret i128 %r
}

define i128 @q_umin(i128 %a, i128 %b) {
; CHECK-LABEL: q_umin:
; CHECK:         minuq $r0r1 = $r0r1, $r2r3
  %c = icmp ult i128 %a, %b
  %r = select i1 %c, i128 %a, i128 %b
  ret i128 %r
}

define i128 @q_umax(i128 %a, i128 %b) {
; CHECK-LABEL: q_umax:
; CHECK:         maxuq $r0r1 = $r0r1, $r2r3
  %c = icmp ugt i128 %a, %b
  %r = select i1 %c, i128 %a, i128 %b
  ret i128 %r
}

; The intrinsics, which is how a vectorized or idiom-recognized min arrives.
declare i128 @llvm.smin.i128(i128, i128)
declare i128 @llvm.abs.i128(i128, i1)
define i128 @q_smin_intrinsic(i128 %a, i128 %b) {
; CHECK-LABEL: q_smin_intrinsic:
; CHECK:         minq $r0r1 = $r0r1, $r2r3
  %r = call i128 @llvm.smin.i128(i128 %a, i128 %b)
  ret i128 %r
}
define i128 @q_abs_intrinsic(i128 %a) {
; CHECK-LABEL: q_abs_intrinsic:
; CHECK:         absq $r0r1 = $r0r1
  %r = call i128 @llvm.abs.i128(i128 %a, i1 true)
  ret i128 %r
}

; Still no 128-bit bit count: CLZQ does not exist, so this stays expanded. The
; line between "has an instruction" and "does not" is the list in
; LVXISelLowering, and this is the half that must not drift into it.
declare i128 @llvm.ctlz.i128(i128, i1)
define i64 @q_clz(i128 %a) {
; CHECK-LABEL: q_clz:
; CHECK-NOT:     clzq
; CHECK:         srlq
  %r = call i128 @llvm.ctlz.i128(i128 %a, i1 false)
  %t = trunc i128 %r to i64
  ret i64 %t
}
