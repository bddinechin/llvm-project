; RUN: llc -mtriple=lvx-mbr -verify-machineinstrs < %s | FileCheck %s

; v4i64 is a legal TYPE with no legal OPERATIONS: it exists so a 256-bit
; argument reaches the calling-convention code in one piece, and nothing here
; computes with one. Every operation on it is Expand, which unrolls it into
; the scalar instructions the ISA has. Correct, not fast -- and each entry
; here stops being four instructions the day real SIMD lowering makes that
; operation Legal.

; A lane is a subregister read, not an instruction. Element 0 is the LOW
; half of the LOW pair, which in indices named for the register number is
; (sub_pair_hi, sub_hi).
define i64 @elt0(<4 x i64> %v) {
; CHECK-LABEL: elt0:
; CHECK-NOT:   ld
; CHECK-NOT:   so
; CHECK:       ret
  %e = extractelement <4 x i64> %v, i32 0
  ret i64 %e
}

define i64 @elt3(<4 x i64> %v) {
; CHECK-LABEL: elt3:
; CHECK-NOT:   ld
; CHECK:       copyd $r0 = $r3
; CHECK:       ret
  %e = extractelement <4 x i64> %v, i32 3
  ret i64 %e
}

; Arithmetic unrolls to four scalar operations, not a libcall and not a
; memory round trip.
define <4 x i64> @add(<4 x i64> %a, <4 x i64> %b) {
; CHECK-LABEL: add:
; CHECK-COUNT-4: addd
; CHECK-NOT:     call
; CHECK:         ret
  %r = add <4 x i64> %a, %b
  ret <4 x i64> %r
}

; 256 bits move as a whole: one so, one lo.
define void @copy(ptr %p, ptr %q) {
; CHECK-LABEL: copy:
; CHECK:      lo $r{{[0-9r]+}} = 0[$r1]
; CHECK:      so 0[$r0] = $r{{[0-9r]+}}
; CHECK:      ret
  %v = load <4 x i64>, ptr %q, align 32
  store <4 x i64> %v, ptr %p, align 32
  ret void
}

; And 128 bits, with lq/sq -- the widths the memory table has and nothing
; selected until now.
define void @copy128(ptr %p, ptr %q) {
; CHECK-LABEL: copy128:
; CHECK:      lq $r{{[0-9r]+}} = 0[$r1]
; CHECK:      sq 0[$r0] = $r{{[0-9r]+}}
; CHECK:      ret
  %v = load i128, ptr %q, align 16
  store i128 %v, ptr %p, align 16
  ret void
}

; An extending load into a pair is not "ld with a wider result": there is no
; such instruction, so it must become a 64-bit load and an explicit widening.
; Selecting ld for it dropped the extension and gave a GPR result to a
; GPR128 node -- wrong code with no diagnostic, and the reason the load table
; is keyed on the value's width as well as memory's.
define i128 @zextload(ptr %p) {
; CHECK-LABEL: zextload:
; CHECK-DAG:  ld $r{{[0-9]+}} = 0[$r0]
; CHECK-DAG:  maked $r1 = 0
; CHECK:      ret
  %v = load i64, ptr %p
  %e = zext i64 %v to i128
  ret i128 %e
}
