; RUN: llc -mtriple=lvx-mbr -verify-machineinstrs < %s | FileCheck %s

; A 128-bit vector of 64-bit lanes is a legal type: the pair IS the vector,
; one lane per register. This description has no lane-wise instruction at all,
; so every operation still unrolls to scalars -- the point is that the lanes
; are reached by subregister, and nothing goes through memory.
;
; Before v2i64 was legal, v4i64 was the only legal vector type and every
; narrower 128-bit vector widened to 256 bits to get there: this add compiled
; to a 128-byte frame with sq/sq/lo/lo ... so/lq around the two adds it
; needed. Fifteen instructions for two.

define <2 x i64> @add(<2 x i64> %a, <2 x i64> %b) {
; CHECK-LABEL: add:
; CHECK-NOT:   addd $r12 = $r12
; CHECK-NOT:   sq
; CHECK-NOT:   lq
; CHECK-DAG:   addd
; CHECK-DAG:   addd
; CHECK:       ret
  %r = add <2 x i64> %a, %b
  ret <2 x i64> %r
}

; The bitwise ones are a single 128-bit instruction -- andq/iorq/eorq operate
; on the whole pair, so unrolling never happens.
define <2 x i64> @and(<2 x i64> %a, <2 x i64> %b) {
; CHECK-LABEL: and:
; CHECK-NOT:   sq
; CHECK:       andq
; CHECK:       ret
  %r = and <2 x i64> %a, %b
  ret <2 x i64> %r
}

; A lane is a subregister read.
define i64 @lane0(<2 x i64> %v) {
; CHECK-LABEL: lane0:
; CHECK-NOT:   sq
; CHECK-NOT:   srlq
; CHECK:       ret
  %e = extractelement <2 x i64> %v, i32 0
  ret i64 %e
}

define i64 @lane1(<2 x i64> %v) {
; CHECK-LABEL: lane1:
; CHECK-NOT:   sq
; CHECK:       copyd $r0 = $r1
; CHECK:       ret
  %e = extractelement <2 x i64> %v, i32 1
  ret i64 %e
}

; 128 bits move as a whole, whatever the type of the value: i128, v2i64 and
; v2f64 all live in one pair and the instruction cares only about the class.
define void @copy(ptr %p, ptr %q) {
; CHECK-LABEL: copy:
; CHECK:      lq $r{{[0-9r]+}} = 0[$r1]
; CHECK:      sq 0[$r0] = $r{{[0-9r]+}}
; CHECK:      ret
  %v = load <2 x i64>, ptr %q, align 16
  store <2 x i64> %v, ptr %p, align 16
  ret void
}

define void @copyf(ptr %p, ptr %q) {
; CHECK-LABEL: copyf:
; CHECK:      lq $r{{[0-9r]+}} = 0[$r1]
; CHECK:      sq 0[$r0] = $r{{[0-9r]+}}
; CHECK:      ret
  %v = load <2 x double>, ptr %q, align 16
  store <2 x double> %v, ptr %p, align 16
  ret void
}

; Reinterpreting between the views of one pair moves nothing.
define i128 @bits(<2 x i64> %v) {
; CHECK-LABEL: bits:
; CHECK-NOT:  sq
; CHECK-NOT:  catdq
; CHECK:      ret
  %r = bitcast <2 x i64> %v to i128
  ret i128 %r
}
