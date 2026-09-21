; RUN: llc -mtriple=lvx-mbr < %s | FileCheck %s
; RUN: llc -mtriple=lvx-mbr -stop-after=prologepilog < %s | FileCheck %s --check-prefix=MIR
; RUN: llc -mtriple=lvx-mbr -verify-machineinstrs -filetype=null < %s

; A function that makes a call saves and restores the frame marker: the
; caller's FP and $ra.  $ra is a control register, so it goes through a GPR
; with get/set rather than being stored directly.
;
; GET's and SET's writes are conditional on an access check, so the machine
; description makes their destinations tied read-modify-write operands, and
; the frame code has to supply the tied source.  The prologue's GET_GSR once
; did not, and the AsmPrinter asserted on every function containing a call
; while the other 17 tests -- none with a call in it -- stayed green.

declare i64 @g(i64)

define i64 @f(i64 %a) {
; CHECK-LABEL: f:
; CHECK:      sd 16[$r12] = $r14
; CHECK:      get $r16 = $ra
; CHECK:      sd 24[$r12] = $r16
; CHECK:      call g
; CHECK:      ld $r16 = 24[$r12]
; CHECK:      set $ra = $r16
; CHECK:      ld $r14 = 16[$r12]
; CHECK:      ret
; MIR: $r16 = GET_GSR undef $r16, $ra
; MIR: $ra = SET_SETRA $ra, $r16
entry:
  %r = call i64 @g(i64 %a)
  %s = add i64 %r, 1
  ret i64 %s
}
