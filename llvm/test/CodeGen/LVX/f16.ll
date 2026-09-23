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

; Arithmetic is NATIVE, and this is the check that noticed when it became so:
; it used to demand the promoted form (two fwidenhw, a faddw and an fnarrowwh)
; and was written to fail the day the pattern was generated. Four instructions
; became one, and the one rounds once where the four rounded twice.
define half @add(half %a, half %b) {
; CHECK-LABEL: add:
; CHECK-NOT:  fwidenhw
; CHECK:      faddh $r0 = $r0, $r1
; CHECK-NOT:  fnarrowwh
; CHECK:      ret
  %r = fadd half %a, %b
  ret half %r
}

define half @mul(half %a, half %b) {
; CHECK-LABEL: mul:
; CHECK-NOT:  fwidenhw
; CHECK:      fmulh $r0 = $r0, $r1
; CHECK:      ret
  %r = fmul half %a, %b
  ret half %r
}

; Both IEEE families at the half word too, and nothing but a NaN separates
; them: fminh PROPAGATES it (fminimum), fminnh returns the numeric operand
; (fminnum, which is what C's fmin means). A swap here is invisible until a
; NaN arrives -- lvx-gcc emitted fmind for C's fmin until 2026-08-04.
define half @minimum(half %a, half %b) {
; CHECK-LABEL: minimum:
; CHECK: fminh $r0 = $r0, $r1
  %r = call half @llvm.minimum.f16(half %a, half %b)
  ret half %r
}

define half @minnum(half %a, half %b) {
; CHECK-LABEL: minnum:
; CHECK: fminnh $r0 = $r0, $r1
  %r = call half @llvm.minnum.f16(half %a, half %b)
  ret half %r
}

; One instruction, one rounding.
define half @fma(half %a, half %b, half %c) {
; CHECK-LABEL: fma:
; CHECK-NOT: fwidenhw
; CHECK:     ffmah
; CHECK:     ret
  %r = call half @llvm.fma.f16(half %a, half %b, half %c)
  ret half %r
}

; A comparison still widens: fcomph exists, but the compare multiclasses in
; LVXInstrInfo.td are hand-written and cover f32/f64 only, so SETCC is the
; one f16 operation left on Promote.
define i32 @cmp(half %a, half %b) {
; CHECK-LABEL: cmp:
; CHECK: fwidenhw
; CHECK: fcompw
  %c = fcmp olt half %a, %b
  %r = zext i1 %c to i32
  ret i32 %r
}

declare half @llvm.minimum.f16(half, half)
declare half @llvm.minnum.f16(half, half)
declare half @llvm.fma.f16(half, half, half)

declare half @llvm.copysign.f16(half, half)
