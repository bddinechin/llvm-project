; RUN: llc -mtriple=lvx < %s | FileCheck %s
; RUN: not llc -mtriple=lvx < %S/Inputs/addrspace-convert.ll 2>&1 \
; RUN:   | FileCheck %s --check-prefix=BADAS

; A load's `variant` modifier is read off the pointer's ADDRESS SPACE, which
; the user declared -- it is not a codegen choice. lvx-gcc registers the same
; spaces by name (gcc/config/lvx/lvx.h), so the numbering here is ABI: a
; "__bypass int *" has to mean the same thing to both compilers.
;
;   address space   GCC name        variant   suffix   meaning
;   1               __bypass        2         .u       bypass the cache
;   2               __preload       3         .us      bypass, and dismissible
;   3               __speculate     1         .s       dismissible (no-fault)
;
; Note __preload is .us, not .u -- the pairing is not the obvious one.
;
; This used to be hardcoded to variant 0, so every one of these compiled to an
; ordinary CACHED load: silently wrong in exactly the case address spaces
; exist for, and invisible to the execution harness, whose programs are all
; generic-address-space.

; CHECK-LABEL: generic:
; CHECK: ld $r{{[0-9]+}} = 0[$r{{[0-9]+}}]
; CHECK-NOT: ld.
define i64 @generic(ptr %p) {
  %v = load i64, ptr %p
  ret i64 %v
}

; CHECK-LABEL: bypass:
; CHECK: ld.u $r{{[0-9]+}} = 0[$r{{[0-9]+}}]
define i64 @bypass(ptr addrspace(1) %p) {
  %v = load i64, ptr addrspace(1) %p
  ret i64 %v
}

; CHECK-LABEL: preload:
; CHECK: ld.us $r{{[0-9]+}} = 0[$r{{[0-9]+}}]
define i64 @preload(ptr addrspace(2) %p) {
  %v = load i64, ptr addrspace(2) %p
  ret i64 %v
}

; CHECK-LABEL: speculate:
; CHECK: ld.s $r{{[0-9]+}} = 0[$r{{[0-9]+}}]
define i64 @speculate(ptr addrspace(3) %p) {
  %v = load i64, ptr addrspace(3) %p
  ret i64 %v
}

; The variant rides on the access width too, not just the 64-bit form.
; CHECK-LABEL: bypass32:
; CHECK: lwz.u $r{{[0-9]+}} = 0[$r{{[0-9]+}}]
define i32 @bypass32(ptr addrspace(1) %p) {
  %v = load i32, ptr addrspace(1) %p
  ret i32 %v
}

; CHECK-LABEL: bypass8:
; CHECK: lbz.u $r{{[0-9]+}} = 0[$r{{[0-9]+}}]
define i8 @bypass8(ptr addrspace(1) %p) {
  %v = load i8, ptr addrspace(1) %p
  ret i8 %v
}

; __convert (4) is pointer-qualifier machinery, not a load variant, and has no
; encoding. It must be diagnosed rather than quietly falling back to variant 0
; -- that fallback is the original bug.
; BADAS: LVX: load from unsupported address space 4
