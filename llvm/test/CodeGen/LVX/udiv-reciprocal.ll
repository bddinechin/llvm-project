; RUN: llc -mtriple=lvx < %s | FileCheck %s
; forms of MULD.
; forms of MULD. Ported from the pre-MDS backend as the spec for that work;
; drop this XFAIL when it lands.

; Division by a constant is strength-reduced into a reciprocal multiply: the
; high half of an unsigned product with a magic constant, then a shift. That
; makes it the most realistic consumer of ISD::mulhu in the whole back-end,
; and a good end-to-end pin for the `highmult` modifier encoding.
;
; It matters because the magic constant for /10 is 0xCCCCCCCCCCCCCCCD, whose
; top bit is set. Selecting the *signed* high multiply ("muld.h") instead of
; the unsigned one treats that constant as negative and yields a completely
; wrong quotient -- and it is not a theoretical concern: validation/lib/
; harness.h formats its result with exactly this "u % 10 / u /= 10" loop, so
; getting it wrong corrupts the test harness's own output rather than failing
; loudly.

; CHECK-LABEL: udiv_by_10:
; CHECK: muld.hu $r{{[0-9]+}} = $r{{[0-9]+}}, $r{{[0-9]+}}
; CHECK-NOT: muld.h $
define i64 @udiv_by_10(i64 %u) {
  %r = udiv i64 %u, 10
  ret i64 %r
}

; The remainder form needs both halves: the reciprocal multiply for the
; quotient, then a plain low multiply by 10 to subtract it back out. Both
; multiply flavours therefore appear in one function, which is precisely the
; case a rotated highmult table gets wrong in two different ways at once.
; CHECK-LABEL: urem_by_10:
; CHECK-DAG: muld.hu $r{{[0-9]+}} = $r{{[0-9]+}}, $r{{[0-9]+}}
; CHECK-DAG: muld $r{{[0-9]+}} = $r{{[0-9]+}}, $r{{[0-9]+}}
define i64 @urem_by_10(i64 %u) {
  %r = urem i64 %u, 10
  ret i64 %r
}

; Signed division by a constant uses the signed high multiply instead.
; CHECK-LABEL: sdiv_by_10:
; CHECK: muld.h $r{{[0-9]+}} = $r{{[0-9]+}}, $r{{[0-9]+}}
define i64 @sdiv_by_10(i64 %s) {
  %r = sdiv i64 %s, 10
  ret i64 %r
}
