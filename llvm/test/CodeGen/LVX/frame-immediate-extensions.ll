; RUN: llc -mtriple=lvx-mbr < %s | FileCheck %s
; RUN: llc -mtriple=lvx-mbr -stop-after=prologepilog < %s | FileCheck %s --check-prefix=MIR

; A frame bigger than the simm10 offset field ([-512,511]) used to cost a
; scratch register plus a maked/addd pair on every out-of-range access. The
; widened encodings hold the offset directly -- LSU_SSBO.X takes 37 bits, .Y
; takes 64 -- so both the stack adjustment and each access stay one
; instruction, just a syllable or two longer.

; A ~800-byte frame: the offsets need more than 10 bits but fit 37.
define void @large_frame(i64 %v) {
; CHECK-LABEL: large_frame:
; CHECK:      addd $r12 = $r12, -808
; CHECK-NOT:  maked
; CHECK:      sd 808[$r12] = $r0
; CHECK-NOT:  maked
; CHECK:      addd $r12 = $r12, 808
; MIR: $r12 = ADDD_DWRI_X $r12, -808
; MIR: SD_SSBO 8, $r12, $r0
; MIR: SD_SSBO_X 808, $r12, killed $r0
entry:
  %buf = alloca [100 x i64], align 8
  %p_last = getelementptr inbounds [100 x i64], ptr %buf, i64 0, i64 100
  store i64 %v, ptr %p_last, align 8
  %p0 = getelementptr inbounds [100 x i64], ptr %buf, i64 0, i64 0
  store i64 %v, ptr %p0, align 8
  ret void
}

; A 64KB frame: still one instruction each, since 37 bits is plenty.
define void @huge_frame(i64 %v) {
; CHECK-LABEL: huge_frame:
; CHECK:      addd $r12 = $r12, -65544
; CHECK-NOT:  maked
; CHECK:      sd 65544[$r12] = $r0
; MIR: $r12 = ADDD_DWRI_X $r12, -65544
; MIR: SD_SSBO 8, $r12, $r0
; MIR: SD_SSBO_X 65544, $r12, killed $r0
entry:
  %buf = alloca [8192 x i64], align 8
  %p_last = getelementptr inbounds [8192 x i64], ptr %buf, i64 0, i64 8192
  store i64 %v, ptr %p_last, align 8
  %p0 = getelementptr inbounds [8192 x i64], ptr %buf, i64 0, i64 0
  store i64 %v, ptr %p0, align 8
  ret void
}

; An in-range frame must still use the narrow forms -- widening is only for
; what does not fit.
define void @small_frame(i64 %v) {
; MIR: $r12 = ADDD_DWRI $r12, -24
; MIR: SD_SSBO 16, $r12, killed $r0
entry:
  %buf = alloca [2 x i64], align 8
  %p1 = getelementptr inbounds [2 x i64], ptr %buf, i64 0, i64 1
  store i64 %v, ptr %p1, align 8
  ret void
}
