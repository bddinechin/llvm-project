; RUN: llc -mtriple=lvx-mbr -verify-machineinstrs < %s | FileCheck %s

; f16 lives in a GPR, in the low half word, like f32 lives in the low word:
; the ISA has a half-word instruction wherever it has a word one. MVT::f16 was
; in no register class until 2026-09-23, so half existed throughout the machine
; description and was selectable nowhere -- which clang, typing _Float16
; natively, walked straight into.

; The conversions are one instruction each. fwidenhw's `mostsig` says WHICH
; half word it widens; 0 is the least significant one, where a scalar f16 sits.
define float @widen(half %a) {
; CHECK-LABEL: widen:
; CHECK:      fwidenhw $r0 = $r0
; CHECK-NEXT: ;;
; CHECK-NEXT: ret
  %r = fpext half %a to float
  ret float %r
}

define half @narrow(float %a) {
; CHECK-LABEL: narrow:
; CHECK:      fnarrowwh $r0 = $r0
; CHECK:      ret
  %r = fptrunc float %a to half
  ret half %r
}

; There is no half-to-double instruction, so it is two -- via the word.
define double @widen64(half %a) {
; CHECK-LABEL: widen64:
; CHECK:      fwidenhw $r0 = $r0
; CHECK:      fwidenwd $r0 = $r0
; CHECK:      ret
  %r = fpext half %a to double
  ret double %r
}

define half @narrow64(double %a) {
; CHECK-LABEL: narrow64:
; CHECK:      fnarrowdw $r0 = $r0
; CHECK:      fnarrowwh $r0 = $r0
; CHECK:      ret
  %r = fptrunc double %a to half
  ret half %r
}

; A half is 16 bits in memory: an ordinary lhz/sh, no conversion.
define half @load(ptr %p) {
; CHECK-LABEL: load:
; CHECK:      lhz $r0 = 0[$r0]
; CHECK-NOT:  fwiden
; CHECK:      ret
  %r = load half, ptr %p
  ret half %r
}

define void @store(ptr %p, half %v) {
; CHECK-LABEL: store:
; CHECK:      sh 0[$r0] = $r1
; CHECK-NOT:  fnarrow
; CHECK:      ret
  store half %v, ptr %p
  ret void
}

; The sign operations have half-word instructions and must NOT be promoted:
; they are pure bit manipulation, so widening and narrowing around them would
; be three instructions for one. (Promoting FCOPYSIGN also hangs the
; legalizer, its two operands not having to share a type.)
define half @neg(half %a) {
; CHECK-LABEL: neg:
; CHECK-NOT:  fwiden
; CHECK:      fnegh $r0 = $r0
; CHECK:      ret
  %r = fneg half %a
  ret half %r
}

define half @copysign(half %m, half %s) {
; CHECK-LABEL: copysign:
; CHECK-NOT:  fwiden
; CHECK:      fsignh $r0 = $r0, $r1
; CHECK:      ret
  %r = call half @llvm.copysign.f16(half %m, half %s)
  ret half %r
}

; The integer conversions are two instructions, through the word. Their
; action is keyed on the RESULT type -- i64, already Legal -- so marking f16
; Promote does nothing for them; these are patterns.
define i64 @toint(half %a) {
; CHECK-LABEL: toint:
; CHECK:      fwidenhw $r0 = $r0
; CHECK:      fixedwd.rz $r0 = $r0
; CHECK:      ret
  %r = fptosi half %a to i64
  ret i64 %r
}

define half @fromint(i64 %a) {
; CHECK-LABEL: fromint:
; CHECK:      floatdw $r0 = $r0
; CHECK:      fnarrowwh $r0 = $r0
; CHECK:      ret
  %r = sitofp i64 %a to half
  ret half %r
}

; Arithmetic is promoted to f32 for now: correct, and one fwidenhw per operand
; plus one fnarrowwh, where faddh would be a single instruction. The ISA has
; faddh -- what is missing is the generated pattern, which MDS/BE/LLVM skips
; while saying why: "MVT::f16 is not added to any register class". That reason
; is gone; when the generator is told so, this becomes one instruction and this
; check is what will notice.
define half @add(half %a, half %b) {
; CHECK-LABEL: add:
; CHECK-DAG:  fwidenhw
; CHECK:      faddw
; CHECK:      fnarrowwh
; CHECK:      ret
  %r = fadd half %a, %b
  ret half %r
}

declare half @llvm.copysign.f16(half, half)
