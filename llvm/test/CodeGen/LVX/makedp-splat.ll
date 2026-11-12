; RUN: llc -mtriple=lvx-mbr -verify-machineinstrs < %s | FileCheck %s

; makedp writes a 32-bit immediate, sign-extended to 64 bits, into both halves
; of a pair. That makes a v2i64 splat of any int32 one instruction where the
; generic route took two: a maked, then a splatdq (lvx-2's splat_vector) or a
; copy into the other half (the BUILD_VECTOR's REG_SEQUENCE). makedp is on
; both cores.
;
; The two routes depend on the installed description, which lit cannot see:
; on lvx_2 a constant v2i64 splat becomes a splat_vector, matched by the
; LVXInstrInfo.td patterns; on lvx_1 it stays a BUILD_VECTOR and Select()
; catches it. v2f64 and i128 take the Select() route on either core, so those
; cases pin it in an lvx_2 build too.

define <2 x i64> @splat_small() {
; CHECK-LABEL: splat_small:
; CHECK-NOT:   maked
; CHECK-NOT:   splatdq
; CHECK:       makedp $r0r1 = 7
; CHECK-NEXT:  ;;
; CHECK-NEXT:  ret
  ret <2 x i64> <i64 7, i64 7>
}

; Past the 16 bits of a one-syllable maked, still one makedp.
define <2 x i64> @splat_wide() {
; CHECK-LABEL: splat_wide:
; CHECK:       makedp $r0r1 = 100000
; CHECK-NEXT:  ;;
; CHECK-NEXT:  ret
  ret <2 x i64> <i64 100000, i64 100000>
}

define <2 x i64> @splat_neg() {
; CHECK-LABEL: splat_neg:
; CHECK:       makedp $r0r1 = -2147483648
; CHECK-NEXT:  ;;
; CHECK-NEXT:  ret
  ret <2 x i64> <i64 -2147483648, i64 -2147483648>
}

; 2^31 does not sign-extend from 32 bits: makedp would write -2^31.
define <2 x i64> @splat_too_wide() {
; CHECK-LABEL: splat_too_wide:
; CHECK-NOT:   makedp
; CHECK:       ret
  ret <2 x i64> <i64 2147483648, i64 2147483648>
}

; Nor does a zero-extended 32-bit all-ones: makedp would write -1.
define <2 x i64> @splat_zext32() {
; CHECK-LABEL: splat_zext32:
; CHECK-NOT:   makedp
; CHECK:       ret
  ret <2 x i64> <i64 4294967295, i64 4294967295>
}

define <2 x i64> @not_a_splat() {
; CHECK-LABEL: not_a_splat:
; CHECK-NOT:   makedp
; CHECK:       ret
  ret <2 x i64> <i64 1, i64 2>
}

; An undefined lane takes the other lane's value.
define <2 x i64> @splat_undef_lane() {
; CHECK-LABEL: splat_undef_lane:
; CHECK:       makedp $r0r1 = 9
; CHECK-NEXT:  ;;
; CHECK-NEXT:  ret
  ret <2 x i64> <i64 9, i64 undef>
}

; v2f64 counts by bit pattern: +0.0 is 0, 1.0 (0x3ff0000000000000) is not an
; int32, and -0.0 (0x8000000000000000) is not either.
define <2 x double> @splat_fzero() {
; CHECK-LABEL: splat_fzero:
; CHECK:       makedp $r0r1 = 0
; CHECK-NEXT:  ;;
; CHECK-NEXT:  ret
  ret <2 x double> zeroinitializer
}

define <2 x double> @splat_fone() {
; CHECK-LABEL: splat_fone:
; CHECK-NOT:   makedp
; CHECK:       ret
  ret <2 x double> <double 1.0, double 1.0>
}

define <2 x double> @splat_fnegzero() {
; CHECK-LABEL: splat_fnegzero:
; CHECK-NOT:   makedp
; CHECK:       ret
  ret <2 x double> <double -0.0, double -0.0>
}

; The packed lane shapes reach makedp at all-zeros and all-ones only.
define <4 x i32> @zero_v4i32() {
; CHECK-LABEL: zero_v4i32:
; CHECK:       makedp $r0r1 = 0
; CHECK-NEXT:  ;;
; CHECK-NEXT:  ret
  ret <4 x i32> zeroinitializer
}

define <4 x i32> @ones_v4i32() {
; CHECK-LABEL: ones_v4i32:
; CHECK:       makedp $r0r1 = -1
; CHECK-NEXT:  ;;
; CHECK-NEXT:  ret
  ret <4 x i32> <i32 -1, i32 -1, i32 -1, i32 -1>
}

define <8 x i16> @ones_v8i16() {
; CHECK-LABEL: ones_v8i16:
; CHECK:       makedp $r0r1 = -1
; CHECK-NEXT:  ;;
; CHECK-NEXT:  ret
  ret <8 x i16> <i16 -1, i16 -1, i16 -1, i16 -1, i16 -1, i16 -1, i16 -1, i16 -1>
}

define <16 x i8> @zero_v16i8() {
; CHECK-LABEL: zero_v16i8:
; CHECK:       makedp $r0r1 = 0
; CHECK-NEXT:  ;;
; CHECK-NEXT:  ret
  ret <16 x i8> zeroinitializer
}

; Any other packed splat replicates within the 64-bit half, which is not a
; sign-extended 32-bit value.
define <4 x i32> @splat5_v4i32() {
; CHECK-LABEL: splat5_v4i32:
; CHECK-NOT:   makedp
; CHECK:       ret
  ret <4 x i32> <i32 5, i32 5, i32 5, i32 5>
}

; An i128 whose halves are equal and sign-extend from 32 bits: 0 and -1.
define i128 @int128_ones() {
; CHECK-LABEL: int128_ones:
; CHECK:       makedp $r0r1 = -1
; CHECK-NEXT:  ;;
; CHECK-NEXT:  ret
  ret i128 -1
}

define i128 @int128_zero() {
; CHECK-LABEL: int128_zero:
; CHECK:       makedp $r0r1 = 0
; CHECK-NEXT:  ;;
; CHECK-NEXT:  ret
  ret i128 0
}

; Halves equal but the value needing more than 64 bits: PreprocessISelDAG
; splits it into a BUILD_PAIR, and that is where makedp has to catch it. This
; is also what clang hands over for `return (v2di){-7, -7}`, its ABI
; returning a 128-bit vector as an i128.
define i128 @int128_pair_neg7() {
; CHECK-LABEL: int128_pair_neg7:
; CHECK:       makedp $r0r1 = -7
; CHECK-NEXT:  ;;
; CHECK-NEXT:  ret
  ret i128 -110680464442257309703
}

; Halves (-7, 0): no makedp.
define i128 @int128_unequal_halves() {
; CHECK-LABEL: int128_unequal_halves:
; CHECK-NOT:   makedp
; CHECK:       ret
  ret i128 18446744073709551609
}

; 5 is (5, 0) as halves: not makedp.
define i128 @int128_five() {
; CHECK-LABEL: int128_five:
; CHECK-NOT:   makedp
; CHECK:       ret
  ret i128 5
}

; A splat used as an operand, not only returned: one makedp feeding the add.
define <2 x i64> @add_splat(<2 x i64> %a) {
; CHECK-LABEL: add_splat:
; CHECK-NOT:   splatdq
; CHECK:       {{makedp|adddp|addd}}
; CHECK:       ret
  %r = add <2 x i64> %a, <i64 70000, i64 70000>
  ret <2 x i64> %r
}
