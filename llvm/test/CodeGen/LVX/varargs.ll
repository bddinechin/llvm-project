; RUN: llc -mtriple=lvx-mbr -verify-machineinstrs < %s | FileCheck %s

; Variadic functions. The ABI passes twelve 8-byte slots in R0-R11 before going
; to the stack, so a variadic callee spills whichever argument registers its
; named parameters did not take, into an area placed so that it ENDS exactly
; where the incoming stack arguments begin -- making va_list one pointer that
; walks upward across both. lvx-gcc builds the same layout from the other
; direction (lvx_expand_builtin_saveregs), and the paired value check is
; validation/tests/micro/varargs.c, where gcc and clang produce the same
; checksum.
;
; Until 2026-10-06 all three of LowerCall, LowerFormalArguments and LowerReturn
; raised report_fatal_error here, so `printf("%d\n", 42)` killed the compiler.

declare void @llvm.va_start(ptr)
declare void @llvm.va_end(ptr)

; One named parameter in R0, so R1-R11 are spilled: eleven slots.
;
; The checks name $r11 rather than the whole run. Which REGISTER each store
; mentions is not stable -- the allocator is free to rename a value it also
; uses, so a function returning its first vararg stores that one through
; whatever register holds it -- but $r11 is never otherwise live, so its spill
; is the save area's reliable signature. The area's SIZE and PLACEMENT are
; pinned by execution instead, in validation/tests/micro/varargs.c, where the
; thirteenth argument makes a misplaced area read the wrong address.
define i64 @one_named(i64 %n, ...) {
; CHECK-LABEL: one_named:
; CHECK:      addd $r12 = $r12, -{{[0-9]+}}
; CHECK-DAG:  sd {{[0-9]+}}[$r12] = $r11
; CHECK-DAG:  sd {{[0-9]+}}[$r12] = $r10
; CHECK:      ret
  %ap = alloca ptr
  call void @llvm.va_start(ptr %ap)
  %p = load ptr, ptr %ap
  %v = load i64, ptr %p
  call void @llvm.va_end(ptr %ap)
  ret i64 %v
}

; Three named parameters, so the area starts at R3 and is two slots shorter.
; The frame is correspondingly smaller, which is the visible consequence here;
; that the START moves with the named count is what varargs.c checks by value,
; its sum3 cases reading arguments the named parameters do not cover.
define i64 @three_named(i64 %a, i64 %b, i64 %c, ...) {
; CHECK-LABEL: three_named:
; CHECK:      addd $r12 = $r12, -{{[0-9]+}}
; CHECK-DAG:  sd {{[0-9]+}}[$r12] = $r11
; CHECK-DAG:  sd {{[0-9]+}}[$r12] = $r4
; CHECK:      ret
  %ap = alloca ptr
  call void @llvm.va_start(ptr %ap)
  %p = load ptr, ptr %ap
  %v = load i64, ptr %p
  call void @llvm.va_end(ptr %ap)
  ret i64 %v
}

; A CALL to a variadic function needs nothing special: the anonymous arguments
; are placed by the same rule as the named ones, so the first twelve go in
; registers and the rest on the stack.
declare i64 @sink(i64, ...)
define i64 @call_variadic() {
; CHECK-LABEL: call_variadic:
; CHECK:      call sink
; CHECK:      ret
  %r = call i64 (i64, ...) @sink(i64 1, i64 2, i64 3)
  ret i64 %r
}

; Thirteen arguments: the thirteenth has no register left and goes to the stack,
; which is the seam the save area has to meet.
define i64 @call_thirteen() {
; CHECK-LABEL: call_thirteen:
; CHECK:      sd {{[0-9]+}}[$r12] = $r{{[0-9]+}}
; CHECK:      call sink
; CHECK:      ret
  %r = call i64 (i64, ...) @sink(i64 1, i64 2, i64 3, i64 4, i64 5, i64 6,
                                 i64 7, i64 8, i64 9, i64 10, i64 11, i64 12,
                                 i64 13)
  ret i64 %r
}

; A variadic function that returns: varargs change nothing about the return
; convention, which is what the third report_fatal_error used to deny.
define i64 @variadic_returns(i64 %n, ...) {
; CHECK-LABEL: variadic_returns:
; CHECK:      ret
  ret i64 %n
}
