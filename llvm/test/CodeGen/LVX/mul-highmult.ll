; RUN: llc -mtriple=lvx < %s | FileCheck %s
; Ported from the pre-MDS backend as the spec for that work; drop this XFAIL
; when it lands.

; LVX's MULD picks the low or high half of the widened product with the
; `highmult` modifier, and the encoding is NOT the KVX one: lvx-refs
; Modifier.table gives highmult members ".H .HU .HSU ." over values
; "0 1 2 3", so encoding 3 is the plain low multiply that prints with no
; suffix, and 0/1/2 are the three high forms. Description.yml's MULD agrees:
;   "if (highmult == 3) result1 = product.64[0]; else result1 = product.64[1]"
;
; This test pins all three forms down, because they can fail independently.
; The bug this was written for was a pair of compensating errors: a suffix
; table rotated into the KVX layout (0 -> "", 1 -> ".h", ...) together with
; KVX-convention constants in the patterns. Since the back-end emits text and
; GNU as does the encoding, those cancelled for plain "mul" -- constant 0
; printed a bare "muld", which as encodes as highmult=3, the correct low
; multiply -- while leaving both high forms wrong: mulhu printed "muld.h"
; (signed high) and mulhs printed "muld.hsu". A test that only checked plain
; multiplication would have passed throughout. Hence all three CHECKs.

; CHECK-LABEL: mul_low:
; The plain 64-bit multiply must be bare "muld", with no .h/.hu/.hsu suffix.
; CHECK: muld $r{{[0-9]+}} = $r{{[0-9]+}}, $r{{[0-9]+}}
; CHECK-NOT: muld.
define i64 @mul_low(i64 %a, i64 %b) {
  %r = mul i64 %a, %b
  ret i64 %r
}

; CHECK-LABEL: mul_high_signed:
; CHECK: muld.h $r{{[0-9]+}} = $r{{[0-9]+}}, $r{{[0-9]+}}
define i64 @mul_high_signed(i64 %a, i64 %b) {
  %ae = sext i64 %a to i128
  %be = sext i64 %b to i128
  %p  = mul i128 %ae, %be
  %s  = lshr i128 %p, 64
  %r  = trunc i128 %s to i64
  ret i64 %r
}

; CHECK-LABEL: mul_high_unsigned:
; CHECK: muld.hu $r{{[0-9]+}} = $r{{[0-9]+}}, $r{{[0-9]+}}
define i64 @mul_high_unsigned(i64 %a, i64 %b) {
  %ae = zext i64 %a to i128
  %be = zext i64 %b to i128
  %p  = mul i128 %ae, %be
  %s  = lshr i128 %p, 64
  %r  = trunc i128 %s to i64
  ret i64 %r
}
