; RUN: llc -mtriple=lvx-mbr < %s | FileCheck %s

; LVX branches on the comparison itself, so a conditional branch is one
; instruction: "cb.<cond> $rZ ? T" tests one register against zero, and
; "ccb.<cmp> $rZ, $rY ? T" compares two. Both compare in printed order, so
; "ccb.dlt $rZ, $rY" branches when rZ < rY.

; A two-register comparison uses ccb. The branch is inverted so the taken edge
; is the one that does not fall through, which is why this is .dge and not
; .dlt -- and there is no trailing goto, because analyzeBranch lets
; BranchFolding see that the other edge is the fall-through.
define i64 @cmp_two_registers(i64 %a, i64 %b) {
; CHECK-LABEL: cmp_two_registers:
; CHECK:      %bb.0:
; CHECK-NEXT: ccb.dge $r0, $r1 ?
; CHECK-NOT:  goto
entry:
  %c = icmp slt i64 %a, %b
  br i1 %c, label %t, label %e
t:
  ret i64 1
e:
  ret i64 2
}

; A comparison against zero needs no second register: cb tests one directly.
define i64 @cmp_against_zero(i64 %a) {
; CHECK-LABEL: cmp_against_zero:
; CHECK:      %bb.0:
; CHECK-NEXT: cb.deqz $r0?
entry:
  %c = icmp ne i64 %a, 0
  br i1 %c, label %t, label %e
t:
  ret i64 1
e:
  ret i64 2
}

; DAGCombine rewrites "x > 0" into "x < 1"; recognising that keeps it on cb
; rather than materializing the 1 into a register for a ccb.
define i64 @cmp_positive(i64 %a) {
; CHECK-LABEL: cmp_positive:
; CHECK:      %bb.0:
; CHECK-NEXT: cb.dlez $r0?
entry:
  %c = icmp sgt i64 %a, 0
  br i1 %c, label %t, label %e
t:
  ret i64 1
e:
  ret i64 2
}

; ...and "x < 0" arrives as "x > -1" -- here block placement leaves the taken
; edge first, so it is the uninverted .dltz rather than its negation.
define i64 @cmp_negative(i64 %a) {
; CHECK-LABEL: cmp_negative:
; CHECK:      %bb.0:
; CHECK-NEXT: cb.dltz $r0?
entry:
  %c = icmp slt i64 %a, 0
  br i1 %c, label %t, label %e
t:
  ret i64 1
e:
  ret i64 2
}

; A loop back-edge: one compare-and-branch, nothing else.
define void @loop(ptr %p, i64 %n) {
; CHECK-LABEL: loop:
; CHECK:      ccb.dlt $r2, $r1 ?
; CHECK-NOT:  goto
; CHECK:      ret
entry:
  br label %body
body:
  %i = phi i64 [ 0, %entry ], [ %i1, %body ]
  %q = getelementptr i64, ptr %p, i64 %i
  store i64 %i, ptr %q
  %i1 = add i64 %i, 1
  %d = icmp slt i64 %i1, %n
  br i1 %d, label %body, label %out
out:
  ret void
}
