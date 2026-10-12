; RUN: llc -mtriple=lvx < %s | FileCheck %s

; The seven round-to-integral functions, one instruction each.
;
; LVX has two of them, differing in nothing but the inexact flag:
;
;   FRINT  -- roundToIntegralExact, RAISES inexact when it changed the value
;   FROUND -- roundToIntegral, quiet
;
; and both take the direction from the same floatmode modifier. So FRINT is
; rint() and only rint(), which is defined to raise inexact; floor, ceil,
; trunc, round, roundeven and nearbyint are all exact operations that must
; not, and every one of them is FROUND with a different modifier.
;
; The pairing that no non-tie input can distinguish, and the one to get wrong:
; llvm.round is ties AWAY FROM ZERO, which is .rm ("to nearest, ties to max
; magnitude"), while llvm.roundeven is ties to even, which is .rn. Swap them
; and 2.5 rounds to 2.0 instead of 3.0, with every other value agreeing.
;
; Until 2026-10-12 these six were Expand, and LVX has no libcall table: each
; one produced "error: no libcall available for ffloor" and then an `icall
; $r0' in the output -- a diagnostic the compiler kept going past, so the
; failure reached the assembler as a call through an argument register.

define double @d_floor(double %x) {
; CHECK-LABEL: d_floor:
; CHECK: froundd.rd $r0 = $r0
  %r = call double @llvm.floor.f64(double %x)
  ret double %r
}

define double @d_ceil(double %x) {
; CHECK-LABEL: d_ceil:
; CHECK: froundd.ru $r0 = $r0
  %r = call double @llvm.ceil.f64(double %x)
  ret double %r
}

define double @d_trunc(double %x) {
; CHECK-LABEL: d_trunc:
; CHECK: froundd.rz $r0 = $r0
  %r = call double @llvm.trunc.f64(double %x)
  ret double %r
}

define double @d_round(double %x) {
; CHECK-LABEL: d_round:
; CHECK: froundd.rm $r0 = $r0
  %r = call double @llvm.round.f64(double %x)
  ret double %r
}

define double @d_roundeven(double %x) {
; CHECK-LABEL: d_roundeven:
; CHECK: froundd.rn $r0 = $r0
  %r = call double @llvm.roundeven.f64(double %x)
  ret double %r
}

; The empty modifier is "use the rounding mode in $cs.RM", which is what
; nearbyint is; the only thing separating it from rint is the flag.
define double @d_nearbyint(double %x) {
; CHECK-LABEL: d_nearbyint:
; CHECK: froundd $r0 = $r0
  %r = call double @llvm.nearbyint.f64(double %x)
  ret double %r
}

define double @d_rint(double %x) {
; CHECK-LABEL: d_rint:
; CHECK: frintd $r0 = $r0
  %r = call double @llvm.rint.f64(double %x)
  ret double %r
}

; f32 and f16 have their own instructions -- in particular f16 is native here
; rather than promoted, since widening and narrowing around an exact rounding
; would be three instructions for one, and the narrowing rounds again.

define float @w_floor(float %x) {
; CHECK-LABEL: w_floor:
; CHECK: froundw.rd $r0 = $r0
  %r = call float @llvm.floor.f32(float %x)
  ret float %r
}

define float @w_round(float %x) {
; CHECK-LABEL: w_round:
; CHECK: froundw.rm $r0 = $r0
  %r = call float @llvm.round.f32(float %x)
  ret float %r
}

define half @h_floor(half %x) {
; CHECK-LABEL: h_floor:
; CHECK-NOT: fwiden
; CHECK: froundh.rd $r0 = $r0
  %r = call half @llvm.floor.f16(half %x)
  ret half %r
}

define half @h_trunc(half %x) {
; CHECK-LABEL: h_trunc:
; CHECK-NOT: fwiden
; CHECK: froundh.rz $r0 = $r0
  %r = call half @llvm.trunc.f16(half %x)
  ret half %r
}

; A vector has no packed form on lvx-1 and none is generated on lvx-2 yet
; (FROUNDDP exists; the modifier keeps it out of the generated per-core list),
; so it unrolls to the scalar instruction -- which is the point: before this it
; unrolled to a libcall that does not exist. Lane order is not pinned.
define <2 x double> @v2_floor(<2 x double> %x) {
; CHECK-LABEL: v2_floor:
; CHECK-DAG: froundd.rd $r{{[0-9]+}} = $r{{[0-9]+}}
; CHECK-DAG: froundd.rd $r{{[0-9]+}} = $r{{[0-9]+}}
  %r = call <2 x double> @llvm.floor.v2f64(<2 x double> %x)
  ret <2 x double> %r
}

declare double @llvm.floor.f64(double)
declare double @llvm.ceil.f64(double)
declare double @llvm.trunc.f64(double)
declare double @llvm.round.f64(double)
declare double @llvm.roundeven.f64(double)
declare double @llvm.nearbyint.f64(double)
declare double @llvm.rint.f64(double)
declare float @llvm.floor.f32(float)
declare float @llvm.round.f32(float)
declare half @llvm.floor.f16(half)
declare half @llvm.trunc.f16(half)
declare <2 x double> @llvm.floor.v2f64(<2 x double>)
