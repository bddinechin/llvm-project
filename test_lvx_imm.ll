target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n32:64-S128"

; Exercises Phase 5.3: immediate ALU patterns (ADDD_i/SBFD_i/etc, simm10
; range) and generic constant materialization (ISD::Constant -> MAKE/
; MAKE_X/MAKE_Y) for values outside any immediate-embedding pattern.

define i64 @add_small_imm(i64 %x) {
  %r = add i64 %x, 5
  ret i64 %r
}

define i64 @sub_small_imm(i64 %x) {
  %r = sub i64 %x, 5
  ret i64 %r
}

define i64 @and_or_xor_imm(i64 %x) {
  %a = and i64 %x, 7
  %o = or i64 %a, 8
  %r = xor i64 %o, 9
  ret i64 %r
}

; Forces a genuinely large add-immediate: -512..511 is ADDD_i's simm10
; range, so 12345 must go through the ISD::Constant materialization path
; (MAKE, since it fits simm16) combined with register-register ADDD.
define i64 @add_large_imm(i64 %x) {
  %r = add i64 %x, 12345
  ret i64 %r
}

; A bare constant return exercises ISD::Constant materialization with no
; surrounding arithmetic pattern to embed it into at all.
define i64 @return_constant() {
  ret i64 999999999
}

; Forces SBFD_i specifically (not reducible to ADDD_i by negation): this
; is 5 - x, so the correct instruction must compute imm(5) - rZ(x).
define i64 @reverse_sub_imm(i64 %x) {
  %r = sub i64 5, %x
  ret i64 %r
}
