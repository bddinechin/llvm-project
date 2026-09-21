; RUN: llc -mtriple=lvx-mbr -verify-machineinstrs < %s | FileCheck %s

; An i128 is a legal type living in an aligned GPR pair, and the generated
; patterns give it its arithmetic (addq, eorq, ...). This pins the glue
; between the widths that is hand-written: the halves as subregisters, the
; widenings, the shifts, and the constants.
;
; Subregister naming trap: sub_hi is SubRegIndex<64, 0>, the LOWER-numbered
; GPR of the pair, and holds the LOW 64 bits (catdq $rM = $rZ, $rY puts $rZ
; there). A wrong choice here still compiles and still verifies; it swaps the
; halves of every __int128.

; The low half of an argument is $r0 already: nothing to do.
define i64 @lo(i128 %x) {
; CHECK-LABEL: lo:
; CHECK-NOT:   catdq
; CHECK-NOT:   copyd
; CHECK:       ret
  %t = trunc i128 %x to i64
  ret i64 %t
}

; The high half: a shift by 64 is a subregister read, not a shifter op.
define i64 @hi(i128 %x) {
; CHECK-LABEL: hi:
; CHECK-NOT:   srlq
; CHECK:       copyd $r0 = $r1
; CHECK:       ret
  %s = lshr i128 %x, 64
  %t = trunc i128 %s to i64
  ret i64 %t
}

; A shift by more than 64 is a 64-bit shift of the other half.
define i64 @hi32(i128 %x) {
; CHECK-LABEL: hi32:
; CHECK-NOT:   srlq
; CHECK:       srld $r0 = $r1, 32
; CHECK:       ret
  %s = lshr i128 %x, 96
  %t = trunc i128 %s to i64
  ret i64 %t
}

; Below 64 the shifter does it, with the 6-bit immediate.
define i64 @mid(i128 %x) {
; CHECK-LABEL: mid:
; CHECK:       srlq $r0r1 = $r0r1, 32
; CHECK:       ret
  %s = lshr i128 %x, 32
  %t = trunc i128 %s to i64
  ret i64 %t
}

define i128 @shl_big(i128 %x) {
; CHECK-LABEL: shl_big:
; CHECK-DAG:   slld $r1 = $r0, 6
; CHECK-DAG:   maked $r0 = 0
; CHECK:       ret
  %s = shl i128 %x, 70
  ret i128 %s
}

; Arithmetic right by 64 or more: the high half becomes the sign.
define i128 @sra_big(i128 %x) {
; CHECK-LABEL: sra_big:
; CHECK-DAG:   srad ${{r[0-9]+}} = $r1, 63
; CHECK-DAG:   srad ${{r[0-9]+}} = $r1, 36
; CHECK:       ret
  %s = ashr i128 %x, 100
  ret i128 %s
}

; A register amount goes to the register form; the amount is a word.
define i128 @shl_reg(i128 %x, i64 %n) {
; CHECK-LABEL: shl_reg:
; CHECK:       sllq $r0r1 = $r0r1, $r2
; CHECK:       ret
  %n128 = zext i64 %n to i128
  %s = shl i128 %x, %n128
  ret i128 %s
}

; Widening builds the pair in place: the word is in $r0 already, so only the
; high half costs anything.
define i128 @z(i64 %x) {
; CHECK-LABEL: z:
; CHECK-NOT:   catdq
; CHECK:       maked $r1 = 0
; CHECK:       ret
  %e = zext i64 %x to i128
  ret i128 %e
}

define i128 @sx(i64 %x) {
; CHECK-LABEL: sx:
; CHECK-NOT:   catdq
; CHECK:       srad $r1 = $r0, 63
; CHECK:       ret
  %e = sext i64 %x to i128
  ret i128 %e
}

; Generated arithmetic on the pair, and the argument pairs cost nothing.
define i128 @addq(i128 %a, i128 %b) {
; CHECK-LABEL: addq:
; CHECK-NOT:   catdq
; CHECK:       addq $r0r1 = $r2r3, $r0r1
; CHECK:       ret
  %r = add i128 %a, %b
  ret i128 %r
}

; A constant is a maked per half.
define i128 @const() {
; CHECK-LABEL: const:
; CHECK-DAG:   maked $r0 = 1
; CHECK-DAG:   maked $r1 = 2
; CHECK:       ret
  ret i128 36893488147419103233
}
