; RUN: llc -mtriple=lvx-mbr -O0 < %s | FileCheck %s
; RUN: llc -mtriple=lvx-mbr -O2 < %s | FileCheck %s

; An FP comparison that feeds a BRANCH must use the FP compare, and this test
; exists because for a long time it did not.
;
; ISD::CondCode shares one enum between the unsigned integer relations and the
; unordered floating-point ones: ISD::SETULT is both "unsigned <" and
; "unordered or <", ISD::SETUGE both "unsigned >=" and "unordered or >=". So
; the integer table in LVXISelDAGToDAG answers for an FP condition code
; without noticing, and `x < 0.0` selected
;
;     compd.geu $r0 = $r0, $r1      ; an UNSIGNED INTEGER compare of the bits
;     cb.dnez $r0? .LBB0_2
;
; against zero -- which is a tautology, so the branch was never taken and
; every negative double took the other arm. It hid because an FP comparison
; reaches that code only as the condition of a branch: used as a value it goes
; through LVXInstrInfo.td's FCmpPat, which is typed and correct, and that is
; the form an optimized `?:` takes. Found by running the differential corpus
; at -O0, where clang emits the branch rather than a select.
;
; The comparison is emitted NEGATED here (olt -> uge) because the branch goes
; to the else-block; floatcomp has all four unordered members, so no swap or
; inversion is needed.

declare double @llvm.sqrt.f64(double)
declare void @sink(i64)

define double @d_lt_zero(double %x) {
; CHECK-LABEL: d_lt_zero:
; CHECK-NOT:     compd
; CHECK:         fcompd.uge $r{{[0-9]+}} = $r{{[0-9]+}}, $r{{[0-9]+}}
entry:
  %c = fcmp olt double %x, 0.0
  br i1 %c, label %zero, label %root
zero:
  ret double 0.0
root:
  %s = call double @llvm.sqrt.f64(double %x)
  ret double %s
}

; Two registers rather than a comparison against zero, and f32: the f32 and
; f16 compares are separate instructions and the same enum sharing applies to
; each.
define void @w_gt(float %a, float %b) {
; CHECK-LABEL: w_gt:
; CHECK-NOT:     compw
; CHECK:         fcompw.{{[a-z]+}} $r{{[0-9]+}} = $r{{[0-9]+}}, $r{{[0-9]+}}
entry:
  %c = fcmp ogt float %a, %b
  br i1 %c, label %yes, label %no
yes:
  call void @sink(i64 1)
  ret void
no:
  call void @sink(i64 2)
  ret void
}

define void @h_le(half %a, half %b) {
; CHECK-LABEL: h_le:
; CHECK-NOT:     compd
; CHECK:         fcomph.{{[a-z]+}} $r{{[0-9]+}} = $r{{[0-9]+}}, $r{{[0-9]+}}
entry:
  %c = fcmp ole half %a, %b
  br i1 %c, label %yes, label %no
yes:
  call void @sink(i64 1)
  ret void
no:
  call void @sink(i64 2)
  ret void
}

; The integer branch is what the guard must NOT break: a genuine unsigned
; integer relation still reaches the one-instruction compare-and-branch.
define void @i_ult(i64 %a, i64 %b) {
; CHECK-LABEL: i_ult:
; CHECK:         ccb.{{dltu|dgeu}} $r{{[0-9]+}}, $r{{[0-9]+}} ?
entry:
  %c = icmp ult i64 %a, %b
  br i1 %c, label %yes, label %no
yes:
  call void @sink(i64 1)
  ret void
no:
  call void @sink(i64 2)
  ret void
}
