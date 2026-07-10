target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n32:64-S128"

; A local array of 8192 i64s (65536 bytes) pushes the frame size well past
; MAKE's simm16 range ([-32768,32767]), exercising the MAKE_X (43-bit)
; fallback added in LVXInstrInfo::loadImmediate (Phase 5.1) instead of the
; previous "not yet modeled" assert.
define i64 @huge_frame_test(i64 %n) {
entry:
  %buf = alloca [8192 x i64], align 8
  %p0 = getelementptr [8192 x i64], ptr %buf, i64 0, i64 0
  store i64 %n, ptr %p0
  %p_last = getelementptr [8192 x i64], ptr %buf, i64 0, i64 8191
  store i64 %n, ptr %p_last
  %v0 = load i64, ptr %p0
  %v_last = load i64, ptr %p_last
  %s = add i64 %v0, %v_last
  ret i64 %s
}
