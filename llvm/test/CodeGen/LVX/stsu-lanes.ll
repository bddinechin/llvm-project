; RUN: llc -mtriple=lvx-mbr -verify-machineinstrs < %s | FileCheck %s

; The lane STSU forms, one instruction per 128 bits, with stsud's operand
; order: the first source is the divisor, the second the running remainder.
; lvx-2 only -- their patterns exist only where the instructions do (see
; LVXInstrInfo.td) -- so this test needs the lvx_2 description installed.

define <8 x i16> @ho(<8 x i16> %z, <8 x i16> %y) {
; CHECK-LABEL: ho:
; CHECK:       stsuho $r0r1 = $r0r1, $r2r3
  %r = call <8 x i16> @llvm.lvx.stsuho(<8 x i16> %z, <8 x i16> %y)
  ret <8 x i16> %r
}

define <4 x i32> @wq(<4 x i32> %z, <4 x i32> %y) {
; CHECK-LABEL: wq:
; CHECK:       stsuwq $r0r1 = $r0r1, $r2r3
  %r = call <4 x i32> @llvm.lvx.stsuwq(<4 x i32> %z, <4 x i32> %y)
  ret <4 x i32> %r
}

; Operand order pinned by swapping the arguments.
define <2 x i64> @dp_swapped(<2 x i64> %y, <2 x i64> %z) {
; CHECK-LABEL: dp_swapped:
; CHECK:       stsudp $r0r1 = $r2r3, $r0r1
  %r = call <2 x i64> @llvm.lvx.stsudp(<2 x i64> %z, <2 x i64> %y)
  ret <2 x i64> %r
}
