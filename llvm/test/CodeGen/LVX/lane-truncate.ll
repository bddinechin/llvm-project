; RUN: llc -mtriple=lvx-mbr -verify-machineinstrs < %s | FileCheck %s

; v4i64 -> v4i32 is one truncdwq, a quad into a pair. It failed to select
; before ("Cannot select: v4i32 = truncate"): TRUNCATE is Legal on the vector
; types and nothing matched it. lvx-2 only, like the instruction.

define <4 x i32> @dwq(<4 x i64> %a) {
; CHECK-LABEL: dwq:
; CHECK-NOT:   ld
; CHECK:       truncdwq $r0r1 = $r{{[0-9]+}}r{{[0-9]+}}r{{[0-9]+}}r{{[0-9]+}}
; CHECK-NOT:   sd
; CHECK:       ret
  %r = trunc <4 x i64> %a to <4 x i32>
  ret <4 x i32> %r
}

; The high words: a shift by 32 and the same truncation, as libgcc's divider
; takes its remainders.
define <4 x i32> @dwq_high(<4 x i64> %a) {
; CHECK-LABEL: dwq_high:
; CHECK:       truncdwq
  %s = lshr <4 x i64> %a, <i64 32, i64 32, i64 32, i64 32>
  %r = trunc <4 x i64> %s to <4 x i32>
  ret <4 x i32> %r
}
