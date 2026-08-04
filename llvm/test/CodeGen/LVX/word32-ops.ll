; RUN: llc -mtriple=lvx < %s | FileCheck %s

; 32-bit arithmetic in 64-bit registers: one instruction, not two.
;
; i64 is the only legal integer width here, so LLVM promotes 32-bit arithmetic
; and puts the result back to 32 bits afterwards. That trailing narrowing has
; two canonical spellings, neither of which is a node of its own --
;
;   sign:  (sext_inreg (add a, b), i32)
;   zero:  (and (add a, b), 0xffffffff)
;
; -- and LVX has a single instruction for each, selected by the `signextw`
; modifier: "addw.sx" and plain "addw". Without these patterns the pair
; compiled to an addd followed by an extfs or an andd, which is correct but
; costs an extra instruction on every 32-bit operation.
;
; That is why this test exists alongside validation/tests/micro/word32.c: the
; runtime test catches a WRONG extension, but losing the patterns entirely
; still produces right answers, so only a check on the emitted instructions
; notices it.
;
; Shifts are deliberately absent. "sllw" masks its shift amount to 5 bits and
; slices its operand, so it is NOT (sext_inreg (shl a, b), i32) once the
; amount reaches 32 -- the generator rejects it for that reason, and the two
; shift cases below confirm it still goes the long way round.

; CHECK-LABEL: add_sext:
; CHECK: addw.sx $r0 = $r{{[0-9]+}}, $r{{[0-9]+}}
; CHECK-NOT: extfs
define i64 @add_sext(i64 %a, i64 %b) {
  %s = add i64 %a, %b
  %t = trunc i64 %s to i32
  %e = sext i32 %t to i64
  ret i64 %e
}

; CHECK-LABEL: add_zext:
; CHECK: addw $r0 = $r{{[0-9]+}}, $r{{[0-9]+}}
; CHECK-NOT: andd
define i64 @add_zext(i64 %a, i64 %b) {
  %s = add i64 %a, %b
  %t = trunc i64 %s to i32
  %e = zext i32 %t to i64
  ret i64 %e
}

; SBFW subtracts FROM, so the operand order is significant and the generator
; derives it from the Behavior rather than from the assembly syntax.
; CHECK-LABEL: sub_sext:
; CHECK: sbfw.sx $r0 = $r{{[0-9]+}}, $r{{[0-9]+}}
define i64 @sub_sext(i64 %a, i64 %b) {
  %s = sub i64 %a, %b
  %t = trunc i64 %s to i32
  %e = sext i32 %t to i64
  ret i64 %e
}

; CHECK-LABEL: and_zext:
; CHECK: andw $r0 = $r{{[0-9]+}}, $r{{[0-9]+}}
define i64 @and_zext(i64 %a, i64 %b) {
  %s = and i64 %a, %b
  %t = trunc i64 %s to i32
  %e = zext i32 %t to i64
  ret i64 %e
}

; CHECK-LABEL: or_sext:
; CHECK: iorw.sx $r0 = $r{{[0-9]+}}, $r{{[0-9]+}}
define i64 @or_sext(i64 %a, i64 %b) {
  %s = or i64 %a, %b
  %t = trunc i64 %s to i32
  %e = sext i32 %t to i64
  ret i64 %e
}

; CHECK-LABEL: xor_zext:
; CHECK: eorw $r0 = $r{{[0-9]+}}, $r{{[0-9]+}}
define i64 @xor_zext(i64 %a, i64 %b) {
  %s = xor i64 %a, %b
  %t = trunc i64 %s to i32
  %e = zext i32 %t to i64
  ret i64 %e
}

; A shift by a variable amount must NOT become sllw: the 32-bit shift takes
; its amount modulo 32 where the 64-bit one takes it modulo 64, so they differ
; for any amount of 32 or more.
; CHECK-LABEL: shl_sext:
; CHECK: slld
; CHECK: extfs
; CHECK-NOT: sllw
define i64 @shl_sext(i64 %a, i64 %b) {
  %s = shl i64 %a, %b
  %t = trunc i64 %s to i32
  %e = sext i32 %t to i64
  ret i64 %e
}
