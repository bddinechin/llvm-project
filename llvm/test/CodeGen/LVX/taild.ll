; RUN: llc -mtriple=lvx-mbr < %s | FileCheck %s

; TAILD -- a lane mask from a loop's own bounds. Bit i of the result is set iff
; i < lanes and base + i <u bound, so the last iteration of a masked loop turns
; off exactly the lanes that would run past the end, in one ALU_TINY syllable
; and with no subtract: both operands are already live.
;
; The lane count is an instruction MODIFIER, which is why the intrinsic's third
; argument is an ImmArg carrying its 0..7 encoding (log2 of the count) rather
; than a value.

declare i64 @llvm.lvx.taild(i64, i64, i64 immarg)

define i64 @tail_v16(i64 %base, i64 %bound) {
; CHECK-LABEL: tail_v16:
; CHECK:         taild.v16 $r0 = $r0, $r1
  %m = call i64 @llvm.lvx.taild(i64 %base, i64 %bound, i64 4)
  ret i64 %m
}

; Every encoding reaches its own suffix, 0 and 7 included -- the two ends are
; where an off-by-one in the modifier mapping would show.
define i64 @tail_v1(i64 %base, i64 %bound) {
; CHECK-LABEL: tail_v1:
; CHECK:         taild.v1 $r0 = $r0, $r1
  %m = call i64 @llvm.lvx.taild(i64 %base, i64 %bound, i64 0)
  ret i64 %m
}

define i64 @tail_v128(i64 %base, i64 %bound) {
; CHECK-LABEL: tail_v128:
; CHECK:         taild.v128 $r0 = $r0, $r1
  %m = call i64 @llvm.lvx.taild(i64 %base, i64 %bound, i64 7)
  ret i64 %m
}

; It is a pure ALU_TINY op with no side effects, so it bundles with independent
; work like any other -- which is also a check that the itinerary reached it
; (a missing one would make LVXBundler treat it as solo).
define i64 @tail_bundles(i64 %base, i64 %bound, i64 %x, i64 %y) {
; CHECK-LABEL:   tail_bundles:
; CHECK:           addd $r2 = $r3, $r2
; CHECK-NEXT:      taild.v8 $r0 = $r0, $r1
; CHECK-NEXT:      ;;
  %m = call i64 @llvm.lvx.taild(i64 %base, i64 %bound, i64 3)
  %s = add i64 %x, %y
  %r = xor i64 %m, %s
  ret i64 %r
}
