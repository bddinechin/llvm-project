target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n32:64-S128"

; Forces real register-allocator spills: 80 simultaneously-live i64
; arguments (LVX's GPR class has 62 allocatable registers -- see
; LVXRegisterInfo.td), all materialized at function entry by
; LowerFormalArguments before any of them are consumed by the chain
; below, so every one is live from entry until its use point.
; Exercises: LVXInstrInfo::storeRegToStackSlot/loadRegFromStackSlot,
; frame-index addressing in LVXISelDAGToDAG::Select, and
; LVXRegisterInfo::eliminateFrameIndex.
define i64 @spill_test(i64 %a0, i64 %a1, i64 %a2, i64 %a3, i64 %a4, i64 %a5, i64 %a6, i64 %a7, i64 %a8, i64 %a9, i64 %a10, i64 %a11, i64 %a12, i64 %a13, i64 %a14, i64 %a15, i64 %a16, i64 %a17, i64 %a18, i64 %a19, i64 %a20, i64 %a21, i64 %a22, i64 %a23, i64 %a24, i64 %a25, i64 %a26, i64 %a27, i64 %a28, i64 %a29, i64 %a30, i64 %a31, i64 %a32, i64 %a33, i64 %a34, i64 %a35, i64 %a36, i64 %a37, i64 %a38, i64 %a39, i64 %a40, i64 %a41, i64 %a42, i64 %a43, i64 %a44, i64 %a45, i64 %a46, i64 %a47, i64 %a48, i64 %a49, i64 %a50, i64 %a51, i64 %a52, i64 %a53, i64 %a54, i64 %a55, i64 %a56, i64 %a57, i64 %a58, i64 %a59, i64 %a60, i64 %a61, i64 %a62, i64 %a63, i64 %a64, i64 %a65, i64 %a66, i64 %a67, i64 %a68, i64 %a69, i64 %a70, i64 %a71, i64 %a72, i64 %a73, i64 %a74, i64 %a75, i64 %a76, i64 %a77, i64 %a78, i64 %a79) {
entry:
  %t0 = add i64 %a0, %a1
  %t1 = add i64 %t0, %a2
  %t2 = add i64 %t1, %a3
  %t3 = add i64 %t2, %a4
  %t4 = add i64 %t3, %a5
  %t5 = add i64 %t4, %a6
  %t6 = add i64 %t5, %a7
  %t7 = add i64 %t6, %a8
  %t8 = add i64 %t7, %a9
  %t9 = add i64 %t8, %a10
  %t10 = add i64 %t9, %a11
  %t11 = add i64 %t10, %a12
  %t12 = add i64 %t11, %a13
  %t13 = add i64 %t12, %a14
  %t14 = add i64 %t13, %a15
  %t15 = add i64 %t14, %a16
  %t16 = add i64 %t15, %a17
  %t17 = add i64 %t16, %a18
  %t18 = add i64 %t17, %a19
  %t19 = add i64 %t18, %a20
  %t20 = add i64 %t19, %a21
  %t21 = add i64 %t20, %a22
  %t22 = add i64 %t21, %a23
  %t23 = add i64 %t22, %a24
  %t24 = add i64 %t23, %a25
  %t25 = add i64 %t24, %a26
  %t26 = add i64 %t25, %a27
  %t27 = add i64 %t26, %a28
  %t28 = add i64 %t27, %a29
  %t29 = add i64 %t28, %a30
  %t30 = add i64 %t29, %a31
  %t31 = add i64 %t30, %a32
  %t32 = add i64 %t31, %a33
  %t33 = add i64 %t32, %a34
  %t34 = add i64 %t33, %a35
  %t35 = add i64 %t34, %a36
  %t36 = add i64 %t35, %a37
  %t37 = add i64 %t36, %a38
  %t38 = add i64 %t37, %a39
  %t39 = add i64 %t38, %a40
  %t40 = add i64 %t39, %a41
  %t41 = add i64 %t40, %a42
  %t42 = add i64 %t41, %a43
  %t43 = add i64 %t42, %a44
  %t44 = add i64 %t43, %a45
  %t45 = add i64 %t44, %a46
  %t46 = add i64 %t45, %a47
  %t47 = add i64 %t46, %a48
  %t48 = add i64 %t47, %a49
  %t49 = add i64 %t48, %a50
  %t50 = add i64 %t49, %a51
  %t51 = add i64 %t50, %a52
  %t52 = add i64 %t51, %a53
  %t53 = add i64 %t52, %a54
  %t54 = add i64 %t53, %a55
  %t55 = add i64 %t54, %a56
  %t56 = add i64 %t55, %a57
  %t57 = add i64 %t56, %a58
  %t58 = add i64 %t57, %a59
  %t59 = add i64 %t58, %a60
  %t60 = add i64 %t59, %a61
  %t61 = add i64 %t60, %a62
  %t62 = add i64 %t61, %a63
  %t63 = add i64 %t62, %a64
  %t64 = add i64 %t63, %a65
  %t65 = add i64 %t64, %a66
  %t66 = add i64 %t65, %a67
  %t67 = add i64 %t66, %a68
  %t68 = add i64 %t67, %a69
  %t69 = add i64 %t68, %a70
  %t70 = add i64 %t69, %a71
  %t71 = add i64 %t70, %a72
  %t72 = add i64 %t71, %a73
  %t73 = add i64 %t72, %a74
  %t74 = add i64 %t73, %a75
  %t75 = add i64 %t74, %a76
  %t76 = add i64 %t75, %a77
  %t77 = add i64 %t76, %a78
  %t78 = add i64 %t77, %a79
  ret i64 %t78
}
