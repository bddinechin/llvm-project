; RUN: llc -mtriple=lvx-mbr < %s | FileCheck %s

; The 32-bit divides, one instruction where the promoted 64-bit divide needed
; three (two operand normalisations and the divide).
;
; Like the shifts, these are target nodes built during type legalization rather
; than patterns over the promoted form -- and here the ISA's own text is the
; argument. Instruction.yml gives DIVMODW the 32-bit wrap for the overflowing
; pair: 0x80000000 / 0xFFFFFFFF has quotient 0x80000000, where
; `sdiv i64 -2147483648, -1' is +2147483648. Undefined in C, defined in IR, so a
; pattern matching the promoted shape would miscompile valid input. `wide64' at
; the bottom is the shape that must keep the 64-bit instruction.
;
; The node carries BOTH results, because the instruction does: the DAG CSEs two
; identical nodes, so an adjacent / and % are one divide -- which is the sharing
; the i64 path gets from ISD::SDIVREM and which separate nodes would have lost.

define signext i32 @sdiv32(i32 signext %a, i32 signext %b) {
; CHECK-LABEL: sdiv32:
; CHECK-NOT:     extfsd
; CHECK:         divmodw.sx $r0r1 = $r0, $r1
  %r = sdiv i32 %a, %b
  ret i32 %r
}

; Zero-extended results, so signextw is 0 and the mnemonic prints bare.
define zeroext i32 @udiv32(i32 zeroext %a, i32 zeroext %b) {
; CHECK-LABEL: udiv32:
; CHECK-NOT:     andd
; CHECK:         divmoduw $r0r1 = $r0, $r1
  %r = udiv i32 %a, %b
  ret i32 %r
}

; The remainder is the pair's other half.
define signext i32 @srem32(i32 signext %a, i32 signext %b) {
; CHECK-LABEL: srem32:
; CHECK:         divmodw.sx $r0r1 = $r0, $r1
  %r = srem i32 %a, %b
  ret i32 %r
}

; One divide for both, by CSE on the node.
define signext i32 @divrem32(i32 signext %a, i32 signext %b) {
; CHECK-LABEL: divrem32:
; CHECK:         divmodw.sx $r0r1 = $r0, $r1
; CHECK-NOT:     divmodw
  %q = sdiv i32 %a, %b
  %r = srem i32 %a, %b
  %s = add i32 %q, %r
  ret i32 %s
}

; Widened afterwards: the instruction sign-extends its results already, which
; ComputeNumSignBitsForTargetNode reports, so nothing extends them again.
define i64 @widened(i32 signext %a, i32 signext %b) {
; CHECK-LABEL: widened:
; CHECK-NOT:     extfsd
; CHECK:         divmodw.sx $r0r1 = $r0, $r1
  %r = sdiv i32 %a, %b
  %s = sext i32 %r to i64
  ret i64 %s
}

; And the unsigned mirror, which computeKnownBitsForTargetNode reports as zero
; in the upper half.
define i64 @widened_u(i32 zeroext %a, i32 zeroext %b) {
; CHECK-LABEL: widened_u:
; CHECK-NOT:     andd
; CHECK:         divmoduw $r0r1 = $r0, $r1
  %r = udiv i32 %a, %b
  %z = zext i32 %r to i64
  ret i64 %z
}

; A genuine 64-bit divide keeps the 64-bit instruction.
define i64 @wide64(i64 %a, i64 %b) {
; CHECK-LABEL: wide64:
; CHECK-NOT:     divmodw
; CHECK:         divmodd $r0r1 = $r0, $r1
  %r = sdiv i64 %a, %b
  ret i64 %r
}
