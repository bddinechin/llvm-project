; RUN: llc -mtriple=lvx-mbr < %s | FileCheck %s

; The five complemented bitwise operations, at both widths. LVX has all of them
; and nothing reached any of them until 2026-10-13: `a & ~b' was notd + andd.
;
;     andnd/andnq $rW = $rZ, $rY      ~rZ & rY
;     iornd/iornq $rW = $rZ, $rY      ~rZ | rY
;     nandd/nandq $rW = $rZ, $rY      ~(rZ & rY)
;     niord/niorq $rW = $rZ, $rY      ~(rZ | rY)
;     neord/neorq $rW = $rZ, $rY      ~(rZ ^ rY)
;
; ANDN and IORN are the asymmetric ones -- the complement is on the FIRST
; printed source -- so the register order in those checks is the test, not
; decoration: binding them the other way round computes `~a & b' for `a & ~b',
; which agrees whenever a == b and which the three negated forms cannot catch.

define i64 @d_andn(i64 %a, i64 %b) {
; CHECK-LABEL: d_andn:
; CHECK-NOT:     notd
; CHECK:         andnd $r0 = $r1, $r0
  %n = xor i64 %b, -1
  %r = and i64 %a, %n
  ret i64 %r
}

define i64 @d_iorn(i64 %a, i64 %b) {
; CHECK-LABEL: d_iorn:
; CHECK-NOT:     notd
; CHECK:         iornd $r0 = $r1, $r0
  %n = xor i64 %b, -1
  %r = or i64 %a, %n
  ret i64 %r
}

define i64 @d_nand(i64 %a, i64 %b) {
; CHECK-LABEL: d_nand:
; CHECK-NOT:     notd
; CHECK:         nandd $r0 = $r{{[01]}}, $r{{[01]}}
  %t = and i64 %a, %b
  %r = xor i64 %t, -1
  ret i64 %r
}

define i64 @d_nior(i64 %a, i64 %b) {
; CHECK-LABEL: d_nior:
; CHECK-NOT:     notd
; CHECK:         niord $r0 = $r{{[01]}}, $r{{[01]}}
  %t = or i64 %a, %b
  %r = xor i64 %t, -1
  ret i64 %r
}

define i64 @d_neor(i64 %a, i64 %b) {
; CHECK-LABEL: d_neor:
; CHECK-NOT:     notd
; CHECK:         neord $r0 = $r{{[01]}}, $r{{[01]}}
  %t = xor i64 %a, %b
  %r = xor i64 %t, -1
  ret i64 %r
}

; `and' and `or' are commutative nodes, so the commuted operand order needs no
; pattern of its own -- this is the check that TableGen really does try it.
define i64 @d_andn_commuted(i64 %a, i64 %b) {
; CHECK-LABEL: d_andn_commuted:
; CHECK-NOT:     notd
; CHECK:         andnd $r0 = $r1, $r0
  %n = xor i64 %b, -1
  %r = and i64 %n, %a
  ret i64 %r
}

; ~(a ^ b) and a ^ ~b are the same function, and the optimizer reassociates
; between them freely -- a loop-invariant ~b arrives as the second form -- so
; both spellings have to reach NEORD.
define i64 @d_neor_reassociated(i64 %a, i64 %b) {
; CHECK-LABEL: d_neor_reassociated:
; CHECK-NOT:     notd
; CHECK:         neord $r0 = $r{{[01]}}, $r{{[01]}}
  %n = xor i64 %b, -1
  %r = xor i64 %a, %n
  ret i64 %r
}

; 128 bits: the same five, where the halves come from different registers, so a
; pattern that pairs the right operand at 64 bits can still mis-pair here.
define i128 @q_andn(i128 %a, i128 %b) {
; CHECK-LABEL: q_andn:
; CHECK-NOT:     notq
; CHECK:         andnq $r0r1 = $r2r3, $r0r1
  %n = xor i128 %b, -1
  %r = and i128 %a, %n
  ret i128 %r
}

define i128 @q_iorn(i128 %a, i128 %b) {
; CHECK-LABEL: q_iorn:
; CHECK-NOT:     notq
; CHECK:         iornq $r0r1 = $r2r3, $r0r1
  %n = xor i128 %b, -1
  %r = or i128 %a, %n
  ret i128 %r
}

define i128 @q_nand(i128 %a, i128 %b) {
; CHECK-LABEL: q_nand:
; CHECK-NOT:     notq
; CHECK:         nandq $r0r1 = $r{{[02]}}r{{[13]}}, $r{{[02]}}r{{[13]}}
  %t = and i128 %a, %b
  %r = xor i128 %t, -1
  ret i128 %r
}

define i128 @q_nior(i128 %a, i128 %b) {
; CHECK-LABEL: q_nior:
; CHECK-NOT:     notq
; CHECK:         niorq $r0r1 = $r{{[02]}}r{{[13]}}, $r{{[02]}}r{{[13]}}
  %t = or i128 %a, %b
  %r = xor i128 %t, -1
  ret i128 %r
}

define i128 @q_neor(i128 %a, i128 %b) {
; CHECK-LABEL: q_neor:
; CHECK-NOT:     notq
; CHECK:         neorq $r0r1 = $r{{[02]}}r{{[13]}}, $r{{[02]}}r{{[13]}}
  %t = xor i128 %a, %b
  %r = xor i128 %t, -1
  ret i128 %r
}

; And the plain complement still has to reach NOTQ rather than one of the
; two-operand forms -- the generic pattern is the lower-priority one, so this
; is a check that adding the five above did not shadow it.
define i128 @q_not(i128 %a) {
; CHECK-LABEL: q_not:
; CHECK:         notq $r0r1 = $r0r1
  %r = xor i128 %a, -1
  ret i128 %r
}
