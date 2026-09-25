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

; Lanes NARROWER than a register are packed, several to a register, and the
; operations still unroll -- but in registers. With these types illegal the
; legalizer scalarized through MEMORY instead, storing the pair and loading
; each lane back: 67 instructions and 15 memory operations for a four-lane
; add, against 27 and none.
define <4 x i32> @add32(<4 x i32> %a, <4 x i32> %b) {
; CHECK-LABEL: add32:
; CHECK-NOT:   sq
; CHECK-NOT:   lwz
; CHECK-NOT:   sw
; CHECK:       ret
  %r = add <4 x i32> %a, %b
  ret <4 x i32> %r
}

; A packed lane is the containing register (a subregister read) and a shift
; within it -- no mask, because the element type is not legal on its own so
; the extract's result is an i64 and the bits above the lane are don't-care.
define i32 @lane32_0(<4 x i32> %v) {
; CHECK-LABEL: lane32_0:
; CHECK-NOT:   srld
; CHECK-NOT:   sq
; CHECK:       ret
  %e = extractelement <4 x i32> %v, i32 0
  ret i32 %e
}

define i32 @lane32_1(<4 x i32> %v) {
; CHECK-LABEL: lane32_1:
; CHECK-NOT:   sq
; CHECK:       srld $r0 = $r0, 32
; CHECK:       ret
  %e = extractelement <4 x i32> %v, i32 1
  ret i32 %e
}

; Lane 2 lives in the pair's other register, so it is the other subregister
; and no shift at all.
define i32 @lane32_2(<4 x i32> %v) {
; CHECK-LABEL: lane32_2:
; CHECK-NOT:   srld
; CHECK:       copyd $r0 = $r1
; CHECK:       ret
  %e = extractelement <4 x i32> %v, i32 2
  ret i32 %e
}

define <8 x i16> @add16(<8 x i16> %a, <8 x i16> %b) {
; CHECK-LABEL: add16:
; CHECK-NOT:   sq
; CHECK-NOT:   lhz
; CHECK:       ret
  %r = add <8 x i16> %a, %b
  ret <8 x i16> %r
}

define <16 x i8> @add8(<16 x i8> %a, <16 x i8> %b) {
; CHECK-LABEL: add8:
; CHECK-NOT:   sq
; CHECK-NOT:   lbz
; CHECK:       ret
  %r = add <16 x i8> %a, %b
  ret <16 x i8> %r
}

; A splat is one instruction on BOTH cores -- splatbq/hq/wq/dq are in lvx-1's
; description too, and they are the first lane-wise instructions this back end
; selects. The pattern is generated; what makes it reachable is the generated
; per-core list turning SPLAT_VECTOR Legal for the types that have one.
define <16 x i8> @splat8(i8 %x) {
; CHECK-LABEL: splat8:
; CHECK-NOT:   iord
; CHECK-NOT:   slld
; CHECK:       splatbq $r0r1 = $r0
; CHECK:       ret
  %v = insertelement <16 x i8> poison, i8 %x, i32 0
  %s = shufflevector <16 x i8> %v, <16 x i8> poison, <16 x i32> zeroinitializer
  ret <16 x i8> %s
}

define <4 x i32> @splat32(i32 %x) {
; CHECK-LABEL: splat32:
; CHECK:       splatwq $r0r1 = $r0
; CHECK:       ret
  %v = insertelement <4 x i32> poison, i32 %x, i32 0
  %s = shufflevector <4 x i32> %v, <4 x i32> poison, <4 x i32> zeroinitializer
  ret <4 x i32> %s
}

; Reading a packed lane stays a register read plus a shift, and lane 9 of a
; v16i8 is in the pair's other register so the read is free. This is the path
; that goes through the 64-bit-lane vector rather than a second subregister
; rule in isel -- a v16i8 EXTRACT_SUBREG reached InstrEmitter with a register
; class that had no such subregister and asserted.
define i8 @lane8_9(<16 x i8> %v) {
; CHECK-LABEL: lane8_9:
; CHECK-NOT:   sq
; CHECK:       srld $r0 = $r1, 8
; CHECK:       ret
  %e = extractelement <16 x i8> %v, i32 9
  ret i8 %e
}
