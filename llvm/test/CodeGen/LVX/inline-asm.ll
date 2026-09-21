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
