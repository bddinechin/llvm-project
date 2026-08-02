; RUN: llc -mtriple=lvx-mbr < %s | FileCheck %s
; RUN: llc -mtriple=lvx-mbr -stop-after=finalize-isel < %s | FileCheck %s --check-prefix=MIR

; A comparison used as a value becomes "compd.<intcomp> $rW = $rZ, $rY", which
; writes 0 or 1. intcomp carries all twelve relations, so unlike ccb no
; operand swapping is ever needed.

define i64 @slt(i64 %a, i64 %b) {
; CHECK-LABEL: slt:
; CHECK: compd.lt $r0 = $r0, $r1
  %c = icmp slt i64 %a, %b
  %r = zext i1 %c to i64
  ret i64 %r
}

define i64 @ugt(i64 %a, i64 %b) {
; CHECK-LABEL: ugt:
; CHECK: compd.gtu $r0 = $r0, $r1
  %c = icmp ugt i64 %a, %b
  %r = zext i1 %c to i64
  ret i64 %r
}

; A constant right-hand side goes into compd's widened form (ALU_DCWRR.W,
; which replaces the register operand with a 32-bit immediate) rather than
; being materialized with a maked first: same total encoding size, one
; instruction instead of two.
define i64 @eq_zero(i64 %a) {
; CHECK-LABEL: eq_zero:
; CHECK:     compd.eq $r0 = $r0, 0
; CHECK-NOT: maked
; MIR: COMPD_DCWRR_W %0, 0, 4
  %c = icmp eq i64 %a, 0
  %r = zext i1 %c to i64
  ret i64 %r
}

define i64 @lt_constant(i64 %a) {
; CHECK-LABEL: lt_constant:
; CHECK:     compd.lt $r0 = $r0, 100000
; CHECK-NOT: maked
  %c = icmp slt i64 %a, 100000
  %r = zext i1 %c to i64
  ret i64 %r
}

; A select is a conditional move: start with the false value in the
; destination, then overwrite it when the condition holds. The destination is
; a tied operand precisely because the write is conditional -- see the
; Constraints on CMOVED in LVXInstrEncodings.td.
define i64 @select_lt(i64 %a, i64 %b, i64 %x, i64 %y) {
; CHECK-LABEL: select_lt:
; CHECK: compd.lt
; CHECK: cmoved.dnez
  %c = icmp slt i64 %a, %b
  %r = select i1 %c, i64 %x, i64 %y
  ret i64 %r
}
