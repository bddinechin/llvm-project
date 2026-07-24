target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n32:64-S128"

; Exercises Phase 5.4: BR_CC -> CCB (fused compare-and-branch). Covers
; all 10 integer condition codes, including the LE/GT/ULE/UGT ones that
; require LowerBR_CC's operand-swap canonicalization (CCB only has
; native LT/GE forms).

define i64 @lt(i64 %a, i64 %b) {
entry:
  %c = icmp slt i64 %a, %b
  br i1 %c, label %t, label %f
t:
  ret i64 1
f:
  ret i64 0
}

define i64 @le(i64 %a, i64 %b) {
entry:
  %c = icmp sle i64 %a, %b
  br i1 %c, label %t, label %f
t:
  ret i64 1
f:
  ret i64 0
}

define i64 @gt(i64 %a, i64 %b) {
entry:
  %c = icmp sgt i64 %a, %b
  br i1 %c, label %t, label %f
t:
  ret i64 1
f:
  ret i64 0
}

define i64 @ge(i64 %a, i64 %b) {
entry:
  %c = icmp sge i64 %a, %b
  br i1 %c, label %t, label %f
t:
  ret i64 1
f:
  ret i64 0
}

define i64 @eq(i64 %a, i64 %b) {
entry:
  %c = icmp eq i64 %a, %b
  br i1 %c, label %t, label %f
t:
  ret i64 1
f:
  ret i64 0
}

define i64 @ne(i64 %a, i64 %b) {
entry:
  %c = icmp ne i64 %a, %b
  br i1 %c, label %t, label %f
t:
  ret i64 1
f:
  ret i64 0
}

define i64 @ult(i64 %a, i64 %b) {
entry:
  %c = icmp ult i64 %a, %b
  br i1 %c, label %t, label %f
t:
  ret i64 1
f:
  ret i64 0
}

define i64 @ule(i64 %a, i64 %b) {
entry:
  %c = icmp ule i64 %a, %b
  br i1 %c, label %t, label %f
t:
  ret i64 1
f:
  ret i64 0
}

define i64 @ugt(i64 %a, i64 %b) {
entry:
  %c = icmp ugt i64 %a, %b
  br i1 %c, label %t, label %f
t:
  ret i64 1
f:
  ret i64 0
}

define i64 @uge(i64 %a, i64 %b) {
entry:
  %c = icmp uge i64 %a, %b
  br i1 %c, label %t, label %f
t:
  ret i64 1
f:
  ret i64 0
}

; A loop (br_cc used for the back-edge test), matching sample.c's
; sum_to_n shape.
define i64 @sum_to_n(i64 %n) {
entry:
  br label %loop
loop:
  %i = phi i64 [1, %entry], [%i.next, %loop]
  %total = phi i64 [0, %entry], [%total.next, %loop]
  %total.next = add i64 %total, %i
  %i.next = add i64 %i, 1
  %c = icmp sle i64 %i.next, %n
  br i1 %c, label %loop, label %exit
exit:
  ret i64 %total.next
}
