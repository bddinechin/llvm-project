; RUN: llc -mtriple=lvx-mbr -verify-machineinstrs < %s | FileCheck %s

; i128 multiplication. The ISA has no MULQ: the widest multiply is MULXDQ,
; 64x64 into a pair, whose `widemult` modifier carries the signedness. Because
; i128 is a LEGAL type here the legalizer never splits a multiply into 64-bit
; pieces the way it does where i128 is illegal, so everything below arrived at
; isel whole -- and until 2026-09-28 every one of them failed with
; "Cannot select: i128 = mul", which is a crash rather than a diagnostic.
;
; What a wrong version looks like: the widening forms are one instruction, so
; a mistake there shows up as the wrong modifier (a signed product where an
; unsigned one was asked for) rather than as extra code. The full 128x128 is
; three multiplies, and the halves are addressed by subregister indices whose
; names say which REGISTER they are, not which end of the value -- sub_hi is
; the LOW half -- so a swapped pair multiplies the right values in the wrong
; places and still verifies. The paired value checks are in
; validation/tests/micro/i128mul.c.

; A widening signed multiply is exactly MULXDQ, unsuffixed.
define i128 @wide_s(i64 %a, i64 %b) {
; CHECK-LABEL: wide_s:
; CHECK:      mulxdq ${{r[0-9]+r[0-9]+}} = $r0, $r1
; CHECK-NOT:  muld
; CHECK:      ret
  %x = sext i64 %a to i128
  %y = sext i64 %b to i128
  %p = mul i128 %x, %y
  ret i128 %p
}

; Both operands zero-extended: the .u modifier.
define i128 @wide_u(i64 %a, i64 %b) {
; CHECK-LABEL: wide_u:
; CHECK:      mulxdq.u ${{r[0-9]+r[0-9]+}} = $r0, $r1
; CHECK:      ret
  %x = zext i64 %a to i128
  %y = zext i64 %b to i128
  %p = mul i128 %x, %y
  ret i128 %p
}

; Mixed: .su, and the SIGN-extended source is the one printed first.
define i128 @wide_su(i64 %a, i64 %b) {
; CHECK-LABEL: wide_su:
; CHECK:      mulxdq.su ${{r[0-9]+r[0-9]+}} = $r0, $r1
; CHECK:      ret
  %x = sext i64 %a to i128
  %y = zext i64 %b to i128
  %p = mul i128 %x, %y
  ret i128 %p
}

; A genuine 128x128 product: the full product of the low halves, plus the two
; cross terms, summed and added in at bit 64. ahi*bhi lands entirely above bit
; 127 and is not computed at all -- three multiplies, not four. CHECK-DAG
; because the order is the scheduler's: the two MULDs are independent of the
; MULXDQ and it places them first today.
define i128 @full(i128 %a, i128 %b) {
; CHECK-LABEL: full:
; CHECK-DAG:  mulxdq.u ${{r[0-9]+r[0-9]+}} = $r{{[0-9]+}}, $r{{[0-9]+}}
; CHECK-DAG:  muld $
; CHECK-DAG:  muld $
; CHECK-DAG:  addd $
; CHECK-DAG:  addq $
; CHECK:      ret
  %p = mul i128 %a, %b
  ret i128 %p
}

; An i128 constant wider than 64 bits. Both halves are materialized and paired;
; nothing hands the constant to an immediate field. This one is a regression
; test for a crash rather than for code quality: the generated immediate
; predicates read a constant with getSExtValue(), which asserts above 64 bits,
; and the matcher reaches them before it has checked the operand's type -- so
; PreprocessISelDAG splits every i128 constant before matching starts.
define i128 @wide_constant(i128 %a) {
; CHECK-LABEL: wide_constant:
; CHECK-DAG:  maked $r{{[0-9]+}} = -1
; CHECK-DAG:  maked $r{{[0-9]+}} = 0
; CHECK:      andq ${{r[0-9]+r[0-9]+}} = ${{r[0-9]+r[0-9]+}}, ${{r[0-9]+r[0-9]+}}
; CHECK:      ret
  %r = and i128 %a, -18446744073709551616   ; ~0xffffffffffffffff
  ret i128 %r
}

; The high half of a widening product is MULD with the high-multiply modifier,
; not a 128-bit multiply at all -- pinned here because the modifier encoding is
; inverted relative to KVX (see mul-highmult.ll).
define i64 @high_s(i64 %a, i64 %b) {
; CHECK-LABEL: high_s:
; CHECK:      muld.h $r0 = $r{{[01]}}, $r{{[01]}}
; CHECK-NOT:  mulxdq
; CHECK:      ret
  %x = sext i64 %a to i128
  %y = sext i64 %b to i128
  %p = mul i128 %x, %y
  %s = lshr i128 %p, 64
  %h = trunc i128 %s to i64
  ret i64 %h
}
