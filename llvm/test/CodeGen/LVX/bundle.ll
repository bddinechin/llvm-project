; RUN: llc -mtriple=lvx-mbr < %s | FileCheck %s
; RUN: llc -mtriple=lvx-mbr -lvx-bundling=0 < %s | FileCheck %s --check-prefix=OFF
; RUN: llc -mtriple=lvx-mbr -lvx-bundle-anti-deps=0 < %s | FileCheck %s --check-prefix=NOANTI

; VLIW bundle formation. ";;" ends a bundle, so what these tests assert is
; which instructions fall between two of them.
;
; An LVX bundle holds up to eight syllables and any resource-feasible group of
; instructions is a valid bundle, so the only two questions are resources
; (LVXSchedule.td) and dependence (LVXBundler) -- which is what the three RUN
; lines take apart: all dependences respected, no bundling at all, and
; anti-dependences treated as a reason to split.

; Two independent operations issue together. The third reads both results, so a
; true dependence keeps it out: inside the bundle it would read stale values.
define i64 @independent(i64 %a, i64 %b, i64 %c, i64 %d) {
; CHECK-LABEL:   independent:
; CHECK:           muld $r2 = $r2, $r3
; CHECK-NEXT:      addd $r0 = $r1, $r0
; CHECK-NEXT:      ;;
; CHECK-NEXT:      eord $r0 = $r0, $r2
; CHECK-NEXT:      ;;
;
; With bundling off every instruction is its own bundle, which is what this
; back end emitted before LVXBundler existed.
; OFF-LABEL:     independent:
; OFF:             muld $r2 = $r2, $r3
; OFF-NEXT:        ;;
; OFF-NEXT:        addd $r0 = $r1, $r0
; OFF-NEXT:        ;;
; OFF-NEXT:        eord $r0 = $r0, $r2
; OFF-NEXT:        ;;
  %x = add i64 %a, %b
  %y = mul i64 %c, %d
  %z = xor i64 %x, %y
  ret i64 %z
}

; A serial chain bundles into nothing, whatever the flags: each multiply reads
; what the one before it wrote.
define i64 @chain(i64 %a, i64 %b) {
; CHECK-LABEL:   chain:
; CHECK:           muld $r0 = $r0, $r1
; CHECK-NEXT:      ;;
; CHECK-NEXT:      muld $r0 = $r0, $r0
; CHECK-NEXT:      ;;
;
; NOANTI-LABEL:  chain:
; NOANTI:          muld $r0 = $r0, $r1
; NOANTI-NEXT:     ;;
; NOANTI-NEXT:     muld $r0 = $r0, $r0
; NOANTI-NEXT:     ;;
  %1 = mul i64 %a, %b
  %2 = mul i64 %1, %1
  ret i64 %2
}

; Anti-dependences, twice over: the addd reads $r1 that the maked overwrites,
; and the store reads $r0 that the next maked overwrites. Both pack, because
; the reader comes first and a bundle reads everything before it writes
; anything -- so the reader sees the old value either way. Four bundles become
; two.
define i64 @antidep(i64 %a, i64 %b) {
; CHECK-LABEL:   antidep:
; CHECK:           addd $r0 = $r1, $r0
; CHECK-NEXT:      maked $r1 = 48
; CHECK-NEXT:      ;;
; CHECK-NEXT:      sd 0[$r1] = $r0
; CHECK-NEXT:      maked $r0 = 7
; CHECK-NEXT:      ;;
;
; NOANTI-LABEL:  antidep:
; NOANTI:          addd $r0 = $r1, $r0
; NOANTI-NEXT:     ;;
; NOANTI-NEXT:     maked $r1 = 48
; NOANTI-NEXT:     ;;
; NOANTI-NEXT:     sd 0[$r1] = $r0
; NOANTI-NEXT:     ;;
; NOANTI-NEXT:     maked $r0 = 7
; NOANTI-NEXT:     ;;
  %s = add i64 %a, %b
  store i64 %s, ptr inttoptr (i64 48 to ptr)
  ret i64 7
}
