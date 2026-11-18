; RUN: llc -mtriple=lvx-mbr -verify-machineinstrs < %s | FileCheck %s

; An inline asm memory operand ("m") prints as "off[base]", the addressing a
; load or store takes. Its absence used to abort selection with "Could not
; match memory address. Inline asm failure!".

@g = global i64 0

; A pointer in a register: offset 0.
define i64 @mem_reg(ptr %p) {
; CHECK-LABEL: mem_reg:
; CHECK:       ld $r0 = 0[$r0]
  %v = call i64 asm "ld $0 = $1", "=r,*m"(ptr elementtype(i64) %p)
  ret i64 %v
}

; A constant displacement folds into the operand.
define i64 @mem_offset(ptr %p) {
; CHECK-LABEL: mem_offset:
; CHECK:       ld $r0 = 24[$r0]
  %q = getelementptr inbounds i8, ptr %p, i64 24
  %v = call i64 asm "ld $0 = $1", "=r,*m"(ptr elementtype(i64) %q)
  ret i64 %v
}

; A store through an output memory operand.
define void @mem_store(ptr %p, i64 %x) {
; CHECK-LABEL: mem_store:
; CHECK:       sd 8[$r0] = $r1
  %q = getelementptr inbounds i8, ptr %p, i64 8
  call void asm sideeffect "sd $0 = $1", "=*m,r"(ptr elementtype(i64) %q, i64 %x)
  ret void
}

; A stack slot: the frame index becomes the frame or stack register plus the
; slot's final offset.
define i64 @mem_frame(i64 %x) {
; CHECK-LABEL: mem_frame:
; CHECK:       ld $r0 = {{-?[0-9]+}}[$r{{1[24]}}]
  %a = alloca i64
  store volatile i64 %x, ptr %a
  %v = call i64 asm "ld $0 = $1", "=r,*m"(ptr elementtype(i64) %a)
  ret i64 %v
}

; A global's address goes through a register.
define i64 @mem_global() {
; CHECK-LABEL: mem_global:
; CHECK:       make{{d?}} $r[[R:[0-9]+]] = g
; CHECK:       ld $r0 = 0[$r[[R]]]
  %v = call i64 asm "ld $0 = $1", "=r,*m"(ptr elementtype(i64) @g)
  ret i64 %v
}

; An "m" operand the template never names still has to be selected: this is
; the shape validation's baseindex.c uses, the operand only telling the
; compiler which memory the asm touches.
define i64 @mem_unnamed(ptr %b, i64 %i) {
; CHECK-LABEL: mem_unnamed:
; CHECK:       ld $r0 = $r1[$r0]
  %v = call i64 asm "ld $0 = $1[$2]", "=r,r,r,*m"(i64 %i, ptr %b, ptr elementtype(i8) %b)
  ret i64 %v
}
