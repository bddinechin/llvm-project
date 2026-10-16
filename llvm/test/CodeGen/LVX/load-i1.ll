; RUN: llc -mtriple=lvx-mbr -O2 < %s | FileCheck %s

; i1 is a memory width with no instruction behind it -- the narrow loads start
; at the byte -- and every load extension is LEGAL by default, the table being
; zeroed. Left that way, a "load zext from i1" reached isel whole and failed to
; select outright; MiBench's rijndael is enough to produce one. Promoting the
; load to the byte LLVM already guarantees holds 0 or 1 is what every other
; target does, and the x86 output for this file is instruction-for-instruction
; the same choice.

; A zero-extending i1 load needs no mask at all: the byte is the value.
; CHECK-LABEL: zl:
; CHECK:      lbz $r0 = 0[$r0]
; CHECK-NOT:  andd
; CHECK:      ret
define i64 @zl(ptr %p) {
  %b = load i1, ptr %p
  %z = zext i1 %b to i64
  ret i64 %z
}

; The sign-extending one is the byte plus a 1-bit signed field extract, not a
; byte sign-extension: bit 0 is the value and bits 1-7 are not its sign.
; CHECK-LABEL: sl:
; CHECK:      lbz $r0 = 0[$r0]
; CHECK:      extfsd $r0 = $r0, 1, 0
define i64 @sl(ptr %p) {
  %b = load i1, ptr %p
  %z = sext i1 %b to i64
  ret i64 %z
}

; Storing one masks to the single bit, which is what keeps the load above able
; to skip the mask.
; CHECK-LABEL: st:
; CHECK:      andd $r1 = $r1, 1
; CHECK:      sb 0[$r0] = $r1
define void @st(ptr %p, i1 %v) {
  store i1 %v, ptr %p
  ret void
}
