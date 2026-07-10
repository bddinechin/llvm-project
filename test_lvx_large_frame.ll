target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n32:64-S128"

; Local array of 100 i64s (800 bytes) forces a stack frame well past the
; 511-byte simm10 limit ADDD_i's immediate can encode directly, exercising
; LVXFrameLowering::emitPrologue/emitEpilogue's MAKE+ADDD large-frame
; fallback. Accessing the last element (byte offset 792) also produces a
; FrameIndex + out-of-range-offset address, exercising
; LVXRegisterInfo::eliminateFrameIndex's own MAKE+ADDD scavenging fallback
; for the per-access residual offset once combined with the object's base
; offset within the frame.
define i64 @large_frame_test(i64 %n) {
entry:
  %buf = alloca [100 x i64], align 8
  %p0 = getelementptr [100 x i64], ptr %buf, i64 0, i64 0
  store i64 %n, ptr %p0
  %p50 = getelementptr [100 x i64], ptr %buf, i64 0, i64 50
  store i64 %n, ptr %p50
  %p99 = getelementptr [100 x i64], ptr %buf, i64 0, i64 99
  store i64 %n, ptr %p99
  %v0 = load i64, ptr %p0
  %v50 = load i64, ptr %p50
  %v99 = load i64, ptr %p99
  %s0 = add i64 %v0, %v50
  %s1 = add i64 %s0, %v99
  ret i64 %s1
}
