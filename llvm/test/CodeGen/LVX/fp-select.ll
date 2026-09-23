; RUN: llc -mtriple=lvx-mbr -verify-machineinstrs < %s | FileCheck %s

; An FP select. There is no FP conditional move: the comparison produces a
; 0/1 GPR and the integer cmoved reads it.
;
; This failed to select outright for every FP type until 2026-09-23 -- the
; select pattern was pinned to i64 and a comment claimed an FP one "reaches
; the same instruction after a bitcast", which it does not. Nothing in the
; suite performed an FP select, so "a < b ? x : y" on a float had never been
; compiled; adding f16 to the same pattern is what surfaced it.

define double @sel64(double %a, double %b, double %x, double %y) {
; CHECK-LABEL: sel64:
; CHECK:      fcompd.olt
; CHECK:      cmoved.dnez
; CHECK:      ret
  %c = fcmp olt double %a, %b
  %r = select i1 %c, double %x, double %y
  ret double %r
}

define float @sel32(float %a, float %b, float %x, float %y) {
; CHECK-LABEL: sel32:
; CHECK:      fcompw.olt
; CHECK:      cmoved.dnez
; CHECK:      ret
  %c = fcmp olt float %a, %b
  %r = select i1 %c, float %x, float %y
  ret float %r
}

define i64 @sel_int(i64 %a, i64 %b, i64 %x, i64 %y) {
; CHECK-LABEL: sel_int:
; CHECK:      cmoved.dnez
; CHECK:      ret
  %c = icmp slt i64 %a, %b
  %r = select i1 %c, i64 %x, i64 %y
  ret i64 %r
}
