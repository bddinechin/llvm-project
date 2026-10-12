; RUN: llc -mtriple=lvx-mbr < %s | FileCheck %s

; STSUD -- one step of a restoring unsigned division:
;
;   $rW = ($rY >=u $rZ) ? (($rY - $rZ) << 1) | 1 : $rY << 1
;
; so a divider is one instruction per quotient bit: the new remainder is
; $rW >> 1 and the quotient bit is $rW & 1.
;
; The operand order is the printed one, and the arithmetic reads in the
; opposite direction: the SECOND source is the running remainder and the first
; the divisor. A swap agrees on every input where $rY >=u $rZ and differs only
; below that line, which is why the operands are pinned to distinct registers
; here rather than checked as $r{{[0-9]+}}.

declare i64 @llvm.lvx.stsud(i64, i64)

define i64 @step(i64 %divisor, i64 %rem) {
; CHECK-LABEL: step:
; CHECK:         stsud $r0 = $r0, $r1
  %r = call i64 @llvm.lvx.stsud(i64 %divisor, i64 %rem)
  ret i64 %r
}

; One instruction, so the recurrence is a chain of them -- and a dependent
; chain, which is what a divide loop unrolled by two looks like. Each step
; feeds the next, so they cannot bundle together.
define i64 @two_steps(i64 %divisor, i64 %rem) {
; CHECK-LABEL:   two_steps:
; CHECK:           stsud $r{{[0-9]+}} = $r0, $r1
; CHECK:           stsud $r{{[0-9]+}} = $r0, $r{{[0-9]+}}
  %a = call i64 @llvm.lvx.stsud(i64 %divisor, i64 %rem)
  %b = call i64 @llvm.lvx.stsud(i64 %divisor, i64 %a)
  ret i64 %b
}

; Pure ALU_TINY with no side effects: two independent steps bundle together,
; which also checks the itinerary reached it (a missing one makes LVXBundler
; treat an instruction as solo).
define i64 @bundles(i64 %z, i64 %y, i64 %z2, i64 %y2) {
; CHECK-LABEL:   bundles:
; CHECK:           stsud $r{{[0-9]+}} = $r{{[0-9]+}}, $r{{[0-9]+}}
; CHECK-NEXT:      stsud $r{{[0-9]+}} = $r{{[0-9]+}}, $r{{[0-9]+}}
; CHECK-NEXT:      ;;
  %a = call i64 @llvm.lvx.stsud(i64 %z, i64 %y)
  %b = call i64 @llvm.lvx.stsud(i64 %z2, i64 %y2)
  %r = xor i64 %a, %b
  ret i64 %r
}
