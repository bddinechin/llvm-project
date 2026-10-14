; RUN: llc -mtriple=lvx < %s | FileCheck %s
; selection + subregister reads). Ported from the pre-MDS backend as the spec
; for that work; drop this XFAIL when it lands.

; Integer division/remainder selects the hardware DIVMODD/DIVMODUD, which
; produce quotient and remainder together in a 128-bit register pair
; (quotient in the architecturally low half, remainder in the high half).
;
; ISD::SDIVREM/UDIVREM are Legal and hand-selected in LVXISelDAGToDAG; the
; single-result SDIV/UDIV/SREM/UREM are Expand, so the legalizer rewrites them
; into the same node and keeps result 0 or result 1. The value-level checks --
; that the halves are not swapped and the operands are not reversed -- live in
; validation/tests/ir/divmod.ll, which runs on the ISS. This file pins the
; instruction selection.

; CHECK-LABEL: sdiv64:
; CHECK: divmodd $r{{[0-9]+}}r{{[0-9]+}} = $r{{[0-9]+}}, $r{{[0-9]+}}
; CHECK-NOT: divmodud
define i64 @sdiv64(i64 %a, i64 %b) {
  %r = sdiv i64 %a, %b
  ret i64 %r
}

; CHECK-LABEL: udiv64:
; CHECK: divmodud $r{{[0-9]+}}r{{[0-9]+}} = $r{{[0-9]+}}, $r{{[0-9]+}}
define i64 @udiv64(i64 %a, i64 %b) {
  %r = udiv i64 %a, %b
  ret i64 %r
}

; CHECK-LABEL: srem64:
; CHECK: divmodd $r{{[0-9]+}}r{{[0-9]+}} = $r{{[0-9]+}}, $r{{[0-9]+}}
define i64 @srem64(i64 %a, i64 %b) {
  %r = srem i64 %a, %b
  ret i64 %r
}

; CHECK-LABEL: urem64:
; CHECK: divmodud $r{{[0-9]+}}r{{[0-9]+}} = $r{{[0-9]+}}, $r{{[0-9]+}}
define i64 @urem64(i64 %a, i64 %b) {
  %r = urem i64 %a, %b
  ret i64 %r
}

; The point of using DIVMODD rather than separate divide and remainder
; instructions: "a / b" and "a % b" on the same operands must collapse to ONE
; instruction, with the two halves read out separately. Exactly one divmodd
; and no libcall.
; CHECK-LABEL: divmod_shared:
; CHECK:     divmodd $r{{[0-9]+}}r{{[0-9]+}} = $r{{[0-9]+}}, $r{{[0-9]+}}
; CHECK-NOT: divmodd
; CHECK-NOT: call
define i64 @divmod_shared(i64 %a, i64 %b) {
  %q = sdiv i64 %a, %b
  %m = srem i64 %a, %b
  %r = add i64 %q, %m
  ret i64 %r
}

; i32 division has no legal type of its own here, and until 2026-10-14 that meant
; promotion to i64 -- sign- or zero-extending both operands and using the 64-bit
; divide, three instructions, the extension being what made the wider divide give
; the right 32-bit answer. It has its own instruction now, built as a target node
; during type legalization (divide32.ll says why it cannot be a pattern over the
; promoted form), so what follows is one instruction and no extension at all.
; CHECK-LABEL: sdiv32:
; CHECK-NOT: extfsd
; CHECK: divmodw.sx $r{{[0-9]+}}r{{[0-9]+}} = $r{{[0-9]+}}, $r{{[0-9]+}}
define i32 @sdiv32(i32 %a, i32 %b) {
  %r = sdiv i32 %a, %b
  ret i32 %r
}

; CHECK-LABEL: udiv32:
; CHECK-NOT: andd
; CHECK: divmoduw $r{{[0-9]+}}r{{[0-9]+}} = $r{{[0-9]+}}, $r{{[0-9]+}}
define i32 @udiv32(i32 %a, i32 %b) {
  %r = udiv i32 %a, %b
  ret i32 %r
}
