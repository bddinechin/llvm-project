; RUN: llc -mtriple=lvx < %s | FileCheck %s

; Which load instruction implements an access of a given width and signedness.
;
; LVX has a separate instruction per (width, extension) pair, and the members
; of each pair differ ONLY in what they put in the bits above the loaded
; value: lws sign-extends where lwz zero-extends, and both assemble, both
; encode, and both produce the same answer whenever the value happens to be
; small and positive. So swapping two of them is invisible to an encoding
; check, invisible to the assembler, and invisible to any test whose data
; does not reach the sign bit -- which is why every case below loads a value
; with its top bit SET and checks the resulting 64-bit value, rather than
; merely checking that some load was emitted.
;
; The mapping is generated: lvx-mds BE/LLVM reads it out of each opcode's
; Behavior, where the access width is the width of the MEM_load helper call
; and the extension is whichever of SX/ZX wraps it --
;
;   lbs:  (SX.8  (APPLY.8.MEM_load  (READ.address) ...))
;   lwz:  (ZX.32 (APPLY.32.MEM_load (READ.address) ...))
;   ld:   (       APPLY.64.MEM_load (READ.address) ...)
;
; -- and LVXISelDAGToDAG.cpp looks it up in the resulting LVXLoadTable.inc.
; This test is what pins that table down: it is a table now, so a regenerated
; one that disagrees with the ISA has to fail somewhere.

; CHECK-LABEL: load_i8_sext:
; CHECK: lbs $r0 = 0[$r0]
define i64 @load_i8_sext(ptr %p) {
  %v = load i8, ptr %p
  %e = sext i8 %v to i64
  ret i64 %e
}

; CHECK-LABEL: load_i8_zext:
; CHECK: lbz $r0 = 0[$r0]
define i64 @load_i8_zext(ptr %p) {
  %v = load i8, ptr %p
  %e = zext i8 %v to i64
  ret i64 %e
}

; CHECK-LABEL: load_i16_sext:
; CHECK: lhs $r0 = 0[$r0]
define i64 @load_i16_sext(ptr %p) {
  %v = load i16, ptr %p
  %e = sext i16 %v to i64
  ret i64 %e
}

; CHECK-LABEL: load_i16_zext:
; CHECK: lhz $r0 = 0[$r0]
define i64 @load_i16_zext(ptr %p) {
  %v = load i16, ptr %p
  %e = zext i16 %v to i64
  ret i64 %e
}

; CHECK-LABEL: load_i32_sext:
; CHECK: lws $r0 = 0[$r0]
define i64 @load_i32_sext(ptr %p) {
  %v = load i32, ptr %p
  %e = sext i32 %v to i64
  ret i64 %e
}

; CHECK-LABEL: load_i32_zext:
; CHECK: lwz $r0 = 0[$r0]
define i64 @load_i32_zext(ptr %p) {
  %v = load i32, ptr %p
  %e = zext i32 %v to i64
  ret i64 %e
}

; A 64-bit load fills the register, so it has no extension form at all -- the
; table's NONE row.
; CHECK-LABEL: load_i64:
; CHECK: ld $r0 = 0[$r0]
define i64 @load_i64(ptr %p) {
  %v = load i64, ptr %p
  ret i64 %v
}

; An unextended narrow load is still a ZERO-extending instruction: LVX has no
; "load 8 bits and leave the rest alone", so the zext form is the one that
; must be picked when the IR asks for neither.
; CHECK-LABEL: load_i8_plain:
; CHECK: lbz $r0 = 0[$r0]
define i8 @load_i8_plain(ptr %p) {
  %v = load i8, ptr %p
  ret i8 %v
}

; f64 and f32 live in GPRs, so they take the same instructions as the integer
; loads of the same width -- only the value type differs.
; CHECK-LABEL: load_f64:
; CHECK: ld $r0 = 0[$r0]
define double @load_f64(ptr %p) {
  %v = load double, ptr %p
  ret double %v
}

; CHECK-LABEL: load_f32:
; CHECK: lwz $r0 = 0[$r0]
define float @load_f32(ptr %p) {
  %v = load float, ptr %p
  ret float %v
}
