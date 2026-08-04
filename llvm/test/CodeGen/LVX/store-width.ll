; RUN: llc -mtriple=lvx < %s | FileCheck %s

; Which store instruction writes an access of a given width.
;
; The companion of load-width-extension.ll, and the more dangerous half. A
; load picked at the wrong width produces a wrong VALUE, which stays inside
; the program; a store picked at the wrong width produces a wrong-SIZED
; WRITE, which does not. sh where sw was meant leaves two bytes of whatever
; was in memory before; sw where sh was meant destroys two bytes belonging to
; something else entirely, and the symptom surfaces in an unrelated variable.
;
; There is no extension dimension here -- a store truncates its value to the
; width it writes, so there is nothing to say about the bits above it. That is
; why the generated table's store rows have no extension column.
;
; The widths come from the byte mask each store's Behavior hands MEM_store:
;
;   sb:  (EFFECT.4.MEM_store (READ.address) (CONST.1)   ...)   1 byte
;   sh:  (EFFECT.4.MEM_store (READ.address) (CONST.3)   ...)   2 bytes
;   sw:  (EFFECT.4.MEM_store (READ.address) (CONST.15)  ...)   4 bytes
;   sd:  (EFFECT.4.MEM_store (READ.address) (CONST.255) ...)   8 bytes

; CHECK-LABEL: store_i8:
; CHECK: sb 0[$r0] = $r1
define void @store_i8(ptr %p, i8 %v) {
  store i8 %v, ptr %p
  ret void
}

; CHECK-LABEL: store_i16:
; CHECK: sh 0[$r0] = $r1
define void @store_i16(ptr %p, i16 %v) {
  store i16 %v, ptr %p
  ret void
}

; CHECK-LABEL: store_i32:
; CHECK: sw 0[$r0] = $r1
define void @store_i32(ptr %p, i32 %v) {
  store i32 %v, ptr %p
  ret void
}

; CHECK-LABEL: store_i64:
; CHECK: sd 0[$r0] = $r1
define void @store_i64(ptr %p, i64 %v) {
  store i64 %v, ptr %p
  ret void
}

; A truncating store must write the NARROW width, not the register's. This is
; the case where a width slip is pure memory corruption: the value is already
; correct in the register, and only the number of bytes committed is wrong.
; CHECK-LABEL: store_trunc_i64_to_i8:
; CHECK: sb 0[$r0] = $r1
define void @store_trunc_i64_to_i8(ptr %p, i64 %v) {
  %t = trunc i64 %v to i8
  store i8 %t, ptr %p
  ret void
}

; CHECK-LABEL: store_trunc_i64_to_i16:
; CHECK: sh 0[$r0] = $r1
define void @store_trunc_i64_to_i16(ptr %p, i64 %v) {
  %t = trunc i64 %v to i16
  store i16 %t, ptr %p
  ret void
}

; CHECK-LABEL: store_trunc_i64_to_i32:
; CHECK: sw 0[$r0] = $r1
define void @store_trunc_i64_to_i32(ptr %p, i64 %v) {
  %t = trunc i64 %v to i32
  store i32 %t, ptr %p
  ret void
}

; f64/f32 live in GPRs, so they take the integer stores of the same width.
; CHECK-LABEL: store_f64:
; CHECK: sd 0[$r0] = $r1
define void @store_f64(ptr %p, double %v) {
  store double %v, ptr %p
  ret void
}

; CHECK-LABEL: store_f32:
; CHECK: sw 0[$r0] = $r1
define void @store_f32(ptr %p, float %v) {
  store float %v, ptr %p
  ret void
}
