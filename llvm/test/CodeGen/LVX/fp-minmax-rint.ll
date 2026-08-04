; RUN: llc -mtriple=lvx < %s | FileCheck %s

; LVX has BOTH IEEE minimum/maximum families, and which one you get is the
; whole point of this test.
;
;   f*_minNum  ->  fminn  ->  IEEE 754-2008 minNum   -- returns the non-NaN operand
;   f*_min     ->  fmin   ->  IEEE 754-2019 minimum  -- propagates the NaN
;
; the same split RISC-V spells FMIN/FMAX against Zfa's FMINM/FMAXM, and LLVM
; spells fminnum/fmaxnum against fminimum/fmaximum. The two agree on every
; input except NaN and, for minimum/maximum, signed zero -- which is to say
; they differ in exactly the cases the two forms exist to distinguish, so
; swapping them is invisible to any test that does not feed one a NaN.
;
; These patterns are generated from the SoftFloat helper names in each
; instruction's Behavior, which is what makes the pairing readable rather than
; a matter of guessing from the mnemonic: "fmind" is NOT the one that
; corresponds to llvm.minnum.
;
; Before this, all four were left to Expand: fminimum turned into a
; setcc/select chain that then failed to select outright ("Cannot select"), so
; llvm.minimum.f64 did not compile, and fminnum asked for a libcall that does
; not exist on this target.

declare double @llvm.minnum.f64(double, double)
declare double @llvm.maxnum.f64(double, double)
declare double @llvm.minimum.f64(double, double)
declare double @llvm.maximum.f64(double, double)
declare double @llvm.rint.f64(double)
declare float @llvm.minnum.f32(float, float)
declare float @llvm.minimum.f32(float, float)
declare float @llvm.rint.f32(float)

; CHECK-LABEL: minnum_f64:
; CHECK: fminnd $r0 = $r0, $r1
define double @minnum_f64(double %a, double %b) {
  %r = call double @llvm.minnum.f64(double %a, double %b)
  ret double %r
}

; CHECK-LABEL: maxnum_f64:
; CHECK: fmaxnd $r0 = $r0, $r1
define double @maxnum_f64(double %a, double %b) {
  %r = call double @llvm.maxnum.f64(double %a, double %b)
  ret double %r
}

; The NaN-propagating form, and NOT fminnd.
; CHECK-LABEL: minimum_f64:
; CHECK: fmind $r0 = $r0, $r1
; CHECK-NOT: fminnd
define double @minimum_f64(double %a, double %b) {
  %r = call double @llvm.minimum.f64(double %a, double %b)
  ret double %r
}

; CHECK-LABEL: maximum_f64:
; CHECK: fmaxd $r0 = $r0, $r1
; CHECK-NOT: fmaxnd
define double @maximum_f64(double %a, double %b) {
  %r = call double @llvm.maximum.f64(double %a, double %b)
  ret double %r
}

; CHECK-LABEL: minnum_f32:
; CHECK: fminnw $r0 = $r0, $r1
define float @minnum_f32(float %a, float %b) {
  %r = call float @llvm.minnum.f32(float %a, float %b)
  ret float %r
}

; CHECK-LABEL: minimum_f32:
; CHECK: fminw $r0 = $r0, $r1
define float @minimum_f32(float %a, float %b) {
  %r = call float @llvm.minimum.f32(float %a, float %b)
  ret float %r
}

; frint rounds by the CURRENT rounding mode, which is what floatmode=7 selects
; -- it reads $cs.RM rather than naming a mode. llvm.nearbyint stays expanded:
; it differs precisely in not raising inexact, and nothing here suppresses that.
; CHECK-LABEL: rint_f64:
; CHECK: frintd $r0 = $r0
define double @rint_f64(double %a) {
  %r = call double @llvm.rint.f64(double %a)
  ret double %r
}

; CHECK-LABEL: rint_f32:
; CHECK: frintw $r0 = $r0
define float @rint_f32(float %a) {
  %r = call float @llvm.rint.f32(float %a)
  ret float %r
}
