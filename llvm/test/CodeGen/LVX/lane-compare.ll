; RUN: llc -mtriple=lvx-mbr -O2 < %s | FileCheck %s

; COMP{BX,HO,WQ,DP}: the lane compare to a mask PACKED one bit per lane into a
; GPR. On both cores, unlike the lane-wise arithmetic, because the result needs
; no lanes to consume it -- which is why these are patterns here and not rows
; of the generated LVXLaneSIMD.inc, and why this test runs whichever
; description is installed.
;
; It is the one member of SIMDe's LVX surface that generic IR cannot spell: the
; value is a bitcast of a <16 x i1>, and that bitcast has no lowering here.

; CHECK-LABEL: lt16x8:
; CHECK: compbx.lt $r0 = $r0r1, $r2r3
define i64 @lt16x8(<16 x i8> %a, <16 x i8> %b) {
  %m = call i64 @llvm.lvx.compbx(<16 x i8> %a, <16 x i8> %b, i64 0)
  ret i64 %m
}

; CHECK-LABEL: ge8x16:
; CHECK: compho.ge $r0 = $r0r1, $r2r3
define i64 @ge8x16(<8 x i16> %a, <8 x i16> %b) {
  %m = call i64 @llvm.lvx.compho(<8 x i16> %a, <8 x i16> %b, i64 1)
  ret i64 %m
}

; CHECK-LABEL: eq4x32:
; CHECK: compwq.eq $r0 = $r0r1, $r2r3
define i64 @eq4x32(<4 x i32> %a, <4 x i32> %b) {
  %m = call i64 @llvm.lvx.compwq(<4 x i32> %a, <4 x i32> %b, i64 4)
  ret i64 %m
}

; The unsigned relations are their own encodings, not a swap of the signed ones.
; CHECK-LABEL: gtu2x64:
; CHECK: compdp.gtu $r0 = $r0r1, $r2r3
define i64 @gtu2x64(<2 x i64> %a, <2 x i64> %b) {
  %m = call i64 @llvm.lvx.compdp(<2 x i64> %a, <2 x i64> %b, i64 11)
  ret i64 %m
}

; .any and .none are NOT relations -- they test the bitwise AND of the two
; lanes for any/no bits set -- so they have no ISD::CondCode and are reachable
; only through the intrinsic. Encodings 6 and 7.
; CHECK-LABEL: anybits:
; CHECK: compbx.any $r0 = $r0r1, $r2r3
define i64 @anybits(<16 x i8> %a, <16 x i8> %b) {
  %m = call i64 @llvm.lvx.compbx(<16 x i8> %a, <16 x i8> %b, i64 6)
  ret i64 %m
}

; CHECK-LABEL: nobits:
; CHECK: compbx.none $r0 = $r0r1, $r2r3
define i64 @nobits(<16 x i8> %a, <16 x i8> %b) {
  %m = call i64 @llvm.lvx.compbx(<16 x i8> %a, <16 x i8> %b, i64 7)
  ret i64 %m
}

declare i64 @llvm.lvx.compbx(<16 x i8>, <16 x i8>, i64 immarg)
declare i64 @llvm.lvx.compho(<8 x i16>, <8 x i16>, i64 immarg)
declare i64 @llvm.lvx.compwq(<4 x i32>, <4 x i32>, i64 immarg)
declare i64 @llvm.lvx.compdp(<2 x i64>, <2 x i64>, i64 immarg)
