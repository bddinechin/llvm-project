; RUN: llc -mtriple=lvx-mbr < %s | FileCheck %s

; The 128-bit integer surface that is one instruction, and the two shapes that
; have to be written out before they are.
;
; COMPQ is the 128-bit compare -- `compq<intcomp> $rM = $rP, $rO', the same
; four-bit intcomp modifier COMPD takes, so all twelve relations with no
; operand swap and no inversion. Its destination is a PAIR whose whole 128 bits
; are 0 or 1, so the answer is the low half and reading it costs nothing.
;
; This test replaced one that pinned a five-instruction lexicographic expansion,
; written in the belief that COMPD was the widest compare in the ISA. It is not.
; What was a real bug underneath that -- and what the execution test
; validation/tests/micro/i128cmp.c still guards -- is that these were left at a
; legal type's default action, whereupon isel selected a single COMPD on the
; pair's LOW half and dropped the high one: `(__int128)1 < (__int128)1 << 64'
; answered false, silently.

define i64 @slt(i128 %a, i128 %b) {
; CHECK-LABEL: slt:
; CHECK:         compq.lt $r0r1 = $r0r1, $r2r3
; CHECK-NOT:     compd
  %c = icmp slt i128 %a, %b
  %z = zext i1 %c to i64
  ret i64 %z
}

; The signedness is in the modifier, not in a different expansion.
define i64 @ult(i128 %a, i128 %b) {
; CHECK-LABEL: ult:
; CHECK:         compq.ltu $r0r1 = $r0r1, $r2r3
  %c = icmp ult i128 %a, %b
  %z = zext i1 %c to i64
  ret i64 %z
}

; And a non-strict relation is its own intcomp member, not a negation.
define i64 @uge(i128 %a, i128 %b) {
; CHECK-LABEL: uge:
; CHECK:         compq.geu $r0r1 = $r0r1, $r2r3
; CHECK-NOT:     eord
  %c = icmp uge i128 %a, %b
  %z = zext i1 %c to i64
  ret i64 %z
}

define i64 @eq(i128 %a, i128 %b) {
; CHECK-LABEL: eq:
; CHECK:         compq.eq $r0r1 = $r0r1, $r2r3
  %c = icmp eq i128 %a, %b
  %z = zext i1 %c to i64
  ret i64 %z
}

; In branch form: BR_CC on an i128 is Expand, because there is no 128-bit
; compare-and-branch, so the branch tests the boolean COMPQ wrote -- and tests
; it in the pair's low register, which is where the subregister read lands.
declare void @sink()
define void @br_slt(i128 %a, i128 %b) {
; CHECK-LABEL: br_slt:
; CHECK-NOT:     ccb
; CHECK:         compq.ge $r0r1 = $r0r1, $r2r3
; CHECK:         cb.dnez $r0?
  %c = icmp slt i128 %a, %b
  br i1 %c, label %yes, label %no
yes:
  call void @sink()
  ret void
no:
  ret void
}

; Negation and complement: the DAG spells them as arithmetic against a constant
; (`sub 0, x', `xor x, -1'), which the generated SBFQ/EORQ patterns match
; happily, so each used to cost a MAKED and a COPYD to build the constant pair
; before the operation -- three instructions for one.
define i128 @neg(i128 %a) {
; CHECK-LABEL: neg:
; CHECK-NOT:     maked
; CHECK:         negq $r0r1 = $r0r1
  %r = sub i128 0, %a
  ret i128 %r
}

define i128 @nope(i128 %a) {
; CHECK-LABEL: nope:
; CHECK-NOT:     maked
; CHECK:         notq $r0r1 = $r0r1
  %r = xor i128 %a, -1
  ret i128 %r
}

; The bit-counting family has NO 128-bit instruction -- the quadword ALU is
; ADDQ/SBFQ/NEGQ, the logic ops, the shifts, CMOVEQ/BSELQ and COMPQ, and there
; is no CLZQ -- so this one is Expand, over operations the pair does have. It is
; here because on a legal type the default is Legal, and llvm.ctlz.i128 aborted
; isel with "Cannot select" until 2026-10-12.
declare i128 @llvm.ctlz.i128(i128, i1)
define i64 @clz(i128 %a) {
; CHECK-LABEL: clz:
; CHECK-NOT:     clzq
; CHECK:         srlq
  %r = call i128 @llvm.ctlz.i128(i128 %a, i1 false)
  %t = trunc i128 %r to i64
  ret i64 %t
}
