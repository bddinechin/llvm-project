target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n32:64-S128"

; Exercises LVXISelDAGToDAG::Select's LVXcall dispatch: a direct call to a
; known global (-> CALL, brtarget27s2) and an indirect call through a
; function-pointer parameter (-> ICALL, GPR register operand).

define i64 @callee(i64 %a, i64 %b) {
  %s = add i64 %a, %b
  ret i64 %s
}

define i64 @direct_call_test(i64 %x, i64 %y) {
entry:
  %r = call i64 @callee(i64 %x, i64 %y)
  ret i64 %r
}

define i64 @indirect_call_test(ptr %fptr, i64 %x, i64 %y) {
entry:
  %r = call i64 %fptr(i64 %x, i64 %y)
  ret i64 %r
}

; A non-leaf function that both calls another function AND has a stack
; frame (local array), exercising the Frame Marker ($ra/caller-FP save)
; path in LVXFrameLowering together with CALL selection.
define i64 @call_with_locals_test(i64 %x, i64 %y) {
entry:
  %buf = alloca [4 x i64], align 8
  %p0 = getelementptr [4 x i64], ptr %buf, i64 0, i64 0
  store i64 %x, ptr %p0
  %r = call i64 @callee(i64 %x, i64 %y)
  %v0 = load i64, ptr %p0
  %s = add i64 %r, %v0
  ret i64 %s
}
