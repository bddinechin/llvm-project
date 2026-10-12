; RUN: llc -mtriple=lvx-mbr < %s | FileCheck %s

; A 128-bit comparison, which has no instruction: the ISA's widest compare is
; COMPD, so the relation is built from three 64-bit ones.
;
; This needs a target lowering precisely because i128 is a LEGAL type here --
; where it is illegal the legalizer splits the comparison for you. Left at the
; default action for a legal type, Legal, LVXISelDAGToDAG's hand-written
; SETCC/BR_CC cases selected ONE compd on the pair's low half and dropped the
; high one, so `(__int128)1 < (__int128)1 << 64` answered false. Silently: a
; wrong value, not a diagnostic.
;
; The shape is the lexicographic relation
;
;   a <op> b  ==  (ahi <strict op> bhi) | (ahi == bhi & alo <unsigned op> blo)
;
; with the high halves carrying the comparison's signedness and the low halves
; always unsigned. The non-strict relations are NOT the strict ones inverted --
; the ISA has le/leu/ge/geu, so asking for the relation directly costs the same
; and needs no assumption about what a boolean's bits are.

define i64 @slt(i128 %a, i128 %b) {
; CHECK-LABEL: slt:
; CHECK-DAG:     compd.ltu $r{{[0-9]+}} = $r0, $r2
; CHECK-DAG:     compd.eq $r{{[0-9]+}} = $r1, $r3
; CHECK-DAG:     compd.lt $r{{[0-9]+}} = $r1, $r3
; CHECK:         andd
; CHECK:         iord
  %c = icmp slt i128 %a, %b
  %z = zext i1 %c to i64
  ret i64 %z
}

; The signedness of the whole comparison shows up on the HIGH halves only.
define i64 @ult(i128 %a, i128 %b) {
; CHECK-LABEL: ult:
; CHECK-DAG:     compd.ltu $r{{[0-9]+}} = $r0, $r2
; CHECK-DAG:     compd.ltu $r{{[0-9]+}} = $r1, $r3
  %c = icmp ult i128 %a, %b
  %z = zext i1 %c to i64
  ret i64 %z
}

; A non-strict relation asks the hardware for itself: ge on the high halves,
; geu on the low ones, and no negation anywhere.
define i64 @uge(i128 %a, i128 %b) {
; CHECK-LABEL: uge:
; CHECK-NOT:     eord
; CHECK-DAG:     compd.geu $r{{[0-9]+}} = $r0, $r2
; CHECK-DAG:     compd.gtu $r{{[0-9]+}} = $r1, $r3
  %c = icmp uge i128 %a, %b
  %z = zext i1 %c to i64
  ret i64 %z
}

; Equality needs no ordering at all: the values are equal exactly when both
; halves are, so one OR of the two XORs against zero answers it.
define i64 @eq(i128 %a, i128 %b) {
; CHECK-LABEL: eq:
; CHECK-DAG:     eord $r{{[0-9]+}} = $r{{[0-9]+}}, $r{{[0-9]+}}
; CHECK-DAG:     eord $r{{[0-9]+}} = $r{{[0-9]+}}, $r{{[0-9]+}}
; CHECK:         iord
; CHECK:         compd.eq $r{{[0-9]+}} = $r{{[0-9]+}}, 0
  %c = icmp eq i128 %a, %b
  %z = zext i1 %c to i64
  ret i64 %z
}

; In branch form it is the same lowering: BR_CC on an i128 is Expand, so it
; becomes BRCOND of this SETCC and the branch tests the 0/1 it produces.
; What must NOT appear is a ccb on half the value.
declare void @sink()
define void @br_slt(i128 %a, i128 %b) {
; CHECK-LABEL: br_slt:
; CHECK-NOT:     ccb
; CHECK:         compd
; CHECK:         cb.{{deqz|dnez}} $r{{[0-9]+}}?
  %c = icmp slt i128 %a, %b
  br i1 %c, label %yes, label %no
yes:
  call void @sink()
  ret void
no:
  ret void
}
