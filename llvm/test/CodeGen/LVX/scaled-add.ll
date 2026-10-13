; RUN: llc -mtriple=lvx-mbr < %s | FileCheck %s

; ADDX<n>D -- `rY + (rZ << log2 n)' in one ALU_TINY syllable. The family runs
; x2 x4 x8 x16 x32 x64 and, since the 2026-10-13 ISA change, x128 and x256.
;
; Nothing in the back end used any of them before, so an indexed address paid a
; SLLD and an ADDD. The scale is part of the mnemonic rather than an operand,
; so there is one pattern per member and an off-by-one in the table is a wrong
; VALUE -- which is why each scale is checked by name.

define i64 @x2(i64 %a, i64 %b) {
; CHECK-LABEL: x2:
; CHECK-NOT:     slld
; CHECK:         addx2d $r0 = $r0, $r1
  %s = shl i64 %a, 1
  %r = add i64 %s, %b
  ret i64 %r
}

define i64 @x8(i64 %a, i64 %b) {
; CHECK-LABEL: x8:
; CHECK:         addx8d $r0 = $r0, $r1
  %s = shl i64 %a, 3
  %r = add i64 %s, %b
  ret i64 %r
}

define i64 @x64(i64 %a, i64 %b) {
; CHECK-LABEL: x64:
; CHECK:         addx64d $r0 = $r0, $r1
  %s = shl i64 %a, 6
  %r = add i64 %s, %b
  ret i64 %r
}

; The two new members.
define i64 @x128(i64 %a, i64 %b) {
; CHECK-LABEL: x128:
; CHECK:         addx128d $r0 = $r0, $r1
  %s = shl i64 %a, 7
  %r = add i64 %s, %b
  ret i64 %r
}

define i64 @x256(i64 %a, i64 %b) {
; CHECK-LABEL: x256:
; CHECK:         addx256d $r0 = $r0, $r1
  %s = shl i64 %a, 8
  %r = add i64 %s, %b
  ret i64 %r
}

; x512 does not exist, so this one has to stay two instructions -- the check
; that the table stops where the ISA does.
define i64 @x512(i64 %a, i64 %b) {
; CHECK-LABEL: x512:
; CHECK:         slld
; CHECK:         addd
  %s = shl i64 %a, 9
  %r = add i64 %s, %b
  ret i64 %r
}

; `add' is commutative, so the shifted operand on either side is the same
; instruction and needs no second pattern.
define i64 @x8_commuted(i64 %a, i64 %b) {
; CHECK-LABEL: x8_commuted:
; CHECK:         addx8d $r0 = $r0, $r1
  %s = shl i64 %a, 3
  %r = add i64 %b, %s
  ret i64 %r
}

; An indexed address is where this lands in real code: a doubleword array index
; is a shift by three and an add, which is one instruction.
define i64 @indexed(ptr %p, i64 %i) {
; CHECK-LABEL: indexed:
; CHECK-NOT:     slld
; CHECK:         addx8d
; CHECK:         ld $r0 = 0[$r0]
  %q = getelementptr i64, ptr %p, i64 %i
  %v = load i64, ptr %q
  ret i64 %v
}

; A multiply by a power of two reaches it too, through DAGCombine's shift.
define i64 @mul128(i64 %a, i64 %b) {
; CHECK-LABEL: mul128:
; CHECK-NOT:     muld
; CHECK:         addx128d $r0 = $r0, $r1
  %m = mul i64 %a, 128
  %r = add i64 %m, %b
  ret i64 %r
}
