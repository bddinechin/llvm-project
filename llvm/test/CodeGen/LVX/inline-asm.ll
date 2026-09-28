; RUN: llc -mtriple=lvx-mbr -verify-machineinstrs < %s | FileCheck %s

; The "r" constraint is a general register of the operand's width, and the
; register's own name -- $r0, $r0r1 -- carries that width to the assembler.
; The text is passed through as it is, and closed with the same ";;" every
; instruction gets: the assembler ends a bundle on ";;", never on a newline,
; so without it the asm's last syllable would be bundled with what follows.

define i128 @pair(i64 %x) {
; CHECK-LABEL: pair:
; CHECK:      #APP
; CHECK-NEXT: splatbq $r0r1 = $r0
; CHECK-NEXT: ;;
; CHECK-NEXT: #NO_APP
; CHECK:      ret
  %q = call i128 asm "splatbq $0 = $1", "=r,r"(i64 %x)
  ret i128 %q
}

; A tied operand ("0") reads and writes one register, and the asm keeps its
; own ";;" -- an empty bundle assembles to nothing, so the extra one is free.
define i64 @tied(i64 %c, i64 %a) {
; CHECK-LABEL: tied:
; CHECK:      #APP
; CHECK-NEXT: guard.dnez $r0? addd $r1 = $r1, 1
; CHECK-NEXT: ;;
; CHECK-NEXT: ;;
; CHECK-NEXT: #NO_APP
; CHECK:      copyd $r0 = $r1
  %r = call i64 asm "guard.dnez $2? addd $0 = $1, 1\0A\09;;", "=r,0,r"(i64 %a, i64 %c)
  ret i64 %r
}

; A 128-bit VECTOR operand must get a register pair, like an i128 does. The
; constraint handler decided by an enumerated list of types until 2026-09-28,
; so only i128 and v4i64 got a wide class and every 128-bit vector silently
; received one 64-bit GPR -- SelectionDAGBuilder then asserted "lossy
; conversion of vector to scalar type" while copying 128 bits into it. Reached
; by ordinary asm: a packed compare with a v4i32 operand.
define i64 @vector_operand(<4 x i32> %v) {
; CHECK-LABEL: vector_operand:
; CHECK:      compwq.eq $r{{[0-9]+}} = $r{{[0-9]+r[0-9]+}}, 7
; CHECK:      ret
  %m = call i64 asm "compwq.eq $0 = $1, 7", "=r,r"(<4 x i32> %v)
  ret i64 %m
}

; ... and a vector RESULT likewise, in both directions of the same statement.
define <8 x i16> @vector_result(<16 x i8> %b) {
; CHECK-LABEL: vector_result:
; CHECK:      extlzbho $r{{[0-9]+r[0-9]+}} = $r{{[0-9]+r[0-9]+}}
; CHECK:      ret
  %h = call <8 x i16> asm "extlzbho $0 = $1", "=r,r"(<16 x i8> %b)
  ret <8 x i16> %h
}
