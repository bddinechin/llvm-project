; RUN: llc -mtriple=lvx-mbr -verify-machineinstrs < %s | FileCheck %s

; The lane-wise .S forms take a 32-bit immediate in place of their second
; register: since lvx-mds c389303 the Behavior states it as
; (SPLAT.L (SX.32 imm)), L the lane width, and BE/LLVM's llvm-patterns.pl turns
; that into a (splat_vector constant) operand. One instruction where the
; register form needed a maked and a splat first.
;
; lvx-2 only, and lit cannot see the installed description: on an lvx_1 build
; these forms do not exist and this test fails. lvx_2 has been the installed
; description since 2026-10-16.

; 64-bit lanes: the immediate is sign-extended to 64 bits, so the lane must be
; an int32.
define <2 x i64> @add_dp(<2 x i64> %a) {
; CHECK-LABEL: add_dp:
; CHECK-NOT:   splat
; CHECK:       adddp $r0r1 = $r0r1, 70000
; CHECK-NEXT:  ;;
; CHECK-NEXT:  ret
  %r = add <2 x i64> %a, <i64 70000, i64 70000>
  ret <2 x i64> %r
}

; 2^32 is not an int32: the register form, with the splat materialised.
define <2 x i64> @add_dp_wide(<2 x i64> %a) {
; CHECK-LABEL: add_dp_wide:
; CHECK:       splatdq
; CHECK:       adddp $r0r1 = $r2r3, $r0r1
  %r = add <2 x i64> %a, <i64 4294967296, i64 4294967296>
  ret <2 x i64> %r
}

; Narrower lanes: any constant, and the immediate is the lane sign-extended
; from the lane width -- the ISA replicates its low bits back.
define <4 x i32> @add_wq(<4 x i32> %a) {
; CHECK-LABEL: add_wq:
; CHECK-NOT:   splat
; CHECK:       addwq $r0r1 = $r0r1, 5
; CHECK-NEXT:  ;;
; CHECK-NEXT:  ret
  %r = add <4 x i32> %a, <i32 5, i32 5, i32 5, i32 5>
  ret <4 x i32> %r
}

define <4 x i32> @add_wq_ffff(<4 x i32> %a) {
; CHECK-LABEL: add_wq_ffff:
; CHECK-NOT:   splat
; CHECK:       addwq $r0r1 = $r0r1, -1
; CHECK-NEXT:  ;;
; CHECK-NEXT:  ret
  %r = add <4 x i32> %a, <i32 -1, i32 -1, i32 -1, i32 -1>
  ret <4 x i32> %r
}

; 3000000000 does not fit a signed 32-bit field, but its low 32 bits are the
; lane, and -1294967296 has the same ones.
define <4 x i32> @add_wq_big(<4 x i32> %a) {
; CHECK-LABEL: add_wq_big:
; CHECK-NOT:   splat
; CHECK:       addwq $r0r1 = $r0r1, -1294967296
; CHECK-NEXT:  ;;
; CHECK-NEXT:  ret
  %r = add <4 x i32> %a, <i32 3000000000, i32 3000000000, i32 3000000000, i32 3000000000>
  ret <4 x i32> %r
}

; 40000 = 0x9c40 in a 16-bit lane is -25536.
define <8 x i16> @add_ho(<8 x i16> %a) {
; CHECK-LABEL: add_ho:
; CHECK-NOT:   splat
; CHECK:       addho $r0r1 = $r0r1, -25536
; CHECK-NEXT:  ;;
; CHECK-NEXT:  ret
  %r = add <8 x i16> %a, <i16 40000, i16 40000, i16 40000, i16 40000, i16 40000, i16 40000, i16 40000, i16 40000>
  ret <8 x i16> %r
}

; 200 in an 8-bit lane is -56.
define <16 x i8> @add_bx(<16 x i8> %a) {
; CHECK-LABEL: add_bx:
; CHECK-NOT:   splat
; CHECK:       addbx $r0r1 = $r0r1, -56
; CHECK-NEXT:  ;;
; CHECK-NEXT:  ret
  %r = add <16 x i8> %a, <i8 200, i8 200, i8 200, i8 200, i8 200, i8 200, i8 200, i8 200, i8 200, i8 200, i8 200, i8 200, i8 200, i8 200, i8 200, i8 200>
  ret <16 x i8> %r
}

; sbf* subtracts the register FROM the immediate: C - x.
define <4 x i32> @sub_from_wq(<4 x i32> %a) {
; CHECK-LABEL: sub_from_wq:
; CHECK-NOT:   splat
; CHECK:       sbfwq $r0r1 = $r0r1, 7
; CHECK-NEXT:  ;;
; CHECK-NEXT:  ret
  %r = sub <4 x i32> <i32 7, i32 7, i32 7, i32 7>, %a
  ret <4 x i32> %r
}

; x - C is not covered: the DAG does not turn a vector sub of a splat into
; an add of its negation, so this keeps the register form for now.
define <4 x i32> @sub_wq(<4 x i32> %a) {
; CHECK-LABEL: sub_wq:
; CHECK:       splatwq
; CHECK:       sbfwq $r0r1 = $r2r3, $r0r1
  %r = sub <4 x i32> %a, <i32 7, i32 7, i32 7, i32 7>
  ret <4 x i32> %r
}

; min/max: the Behavior states the immediate first, and the patterns keep that
; order; the operations are commutative, so TableGen's commuted variant is the
; one that matches the canonical (x, splat) DAG.
define <8 x i16> @smin_ho(<8 x i16> %a) {
; CHECK-LABEL: smin_ho:
; CHECK-NOT:   splat
; CHECK:       minho $r0r1 = $r0r1, 100
; CHECK-NEXT:  ;;
; CHECK-NEXT:  ret
  %r = call <8 x i16> @llvm.smin.v8i16(<8 x i16> %a, <8 x i16> <i16 100, i16 100, i16 100, i16 100, i16 100, i16 100, i16 100, i16 100>)
  ret <8 x i16> %r
}

define <2 x i64> @umax_dp(<2 x i64> %a) {
; CHECK-LABEL: umax_dp:
; CHECK-NOT:   splat
; CHECK:       maxudp $r0r1 = $r0r1, -5
; CHECK-NEXT:  ;;
; CHECK-NEXT:  ret
  %r = call <2 x i64> @llvm.umax.v2i64(<2 x i64> %a, <2 x i64> <i64 -5, i64 -5>)
  ret <2 x i64> %r
}

define <16 x i8> @umin_bx(<16 x i8> %a) {
; CHECK-LABEL: umin_bx:
; CHECK-NOT:   splat
; CHECK:       minubx $r0r1 = $r0r1, -6
; CHECK-NEXT:  ;;
; CHECK-NEXT:  ret
  %r = call <16 x i8> @llvm.umin.v16i8(<16 x i8> %a, <16 x i8> <i8 250, i8 250, i8 250, i8 250, i8 250, i8 250, i8 250, i8 250, i8 250, i8 250, i8 250, i8 250, i8 250, i8 250, i8 250, i8 250>)
  ret <16 x i8> %r
}

