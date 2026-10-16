; RUN: llc -mtriple=lvx-mbr -O2 < %s | FileCheck %s

; LVX had no entry in RuntimeLibcalls.td, which left every libcall NAME null --
; and a null name is not a diagnostic. A memcpy too big to inline reached
; instruction selection as an ExternalSymbol holding a null string and killed
; the compiler inside std::string's constructor ("basic_string::_M_construct
; null not valid", a std::logic_error, so not even a useful stack trace).
; PolyBench's doitgen at MINI/float found it. See LVXSystemLibrary.

; Small enough to inline: no call, and the copy is in registers.
; CHECK-LABEL: small:
; CHECK-NOT:  call memcpy
; CHECK:      ret
define void @small(ptr align 4 %d, ptr align 4 %s) {
  call void @llvm.memcpy.p0.p0.i64(ptr align 4 %d, ptr align 4 %s, i64 16, i1 false)
  ret void
}

; Too big to inline: this is the size that used to crash.
; CHECK-LABEL: medium:
; CHECK:      call memcpy
define void @medium(ptr align 4 %d, ptr align 4 %s) {
  call void @llvm.memcpy.p0.p0.i64(ptr align 4 %d, ptr align 4 %s, i64 48, i1 false)
  ret void
}

; A large one did not crash and was wrong in a quieter way: with no memcpy to
; call it came out as a byte-at-a-time LOOP, so the check here is that a call
; is made and no such loop is left behind.
; CHECK-LABEL: large:
; CHECK:      call memcpy
; CHECK-NOT:  lbz
define void @large(ptr align 4 %d, ptr align 4 %s) {
  call void @llvm.memcpy.p0.p0.i64(ptr align 4 %d, ptr align 4 %s, i64 4096, i1 false)
  ret void
}

; memset takes the same path.
; CHECK-LABEL: setter:
; CHECK:      call memset
define void @setter(ptr align 4 %d, i8 %v) {
  call void @llvm.memset.p0.i64(ptr align 4 %d, i8 %v, i64 4096, i1 false)
  ret void
}

declare void @llvm.memcpy.p0.p0.i64(ptr, ptr, i64, i1)
declare void @llvm.memset.p0.i64(ptr, i8, i64, i1)
