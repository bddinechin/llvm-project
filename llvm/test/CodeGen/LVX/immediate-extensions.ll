; RUN: llc -mtriple=lvx-mbr < %s | FileCheck %s
; RUN: llc -mtriple=lvx-mbr -stop-after=finalize-isel < %s | FileCheck %s --check-prefix=MIR

; An LVX instruction carrying an immediate has widened encodings that spend
; one or two extra 32-bit syllables on immediate bits: "addd $rW = $rZ, imm"
; holds 10 bits in 4 bytes (ALU_DWRI), 37 in 8 (ALU_DWRI.X) and 64 in 12
; (ALU_DWRI.Y). All three assemble to the same mnemonic -- the assembler picks
; by magnitude -- so the only thing selection has to get right is choosing the
; narrowest form that holds the constant, instead of materialising it into a
; scratch register with maked first.

define i64 @add_imm10(i64 %a) {
; CHECK-LABEL: add_imm10:
; CHECK: addd $r0 = $r0, 100
; CHECK-NOT: maked
; MIR: ADDD_DWRI %0, 100
  %r = add i64 %a, 100
  ret i64 %r
}

define i64 @add_imm37(i64 %a) {
; CHECK-LABEL: add_imm37:
; CHECK: addd $r0 = $r0, 100000
; CHECK-NOT: maked
; MIR: ADDD_DWRI_X %0, 100000
  %r = add i64 %a, 100000
  ret i64 %r
}

define i64 @add_imm64(i64 %a) {
; CHECK-LABEL: add_imm64:
; CHECK: addd $r0 = $r0, 1234605616436508552
; CHECK-NOT: maked
; MIR: ADDD_DWRI_Y %0, 1234605616436508552
  %r = add i64 %a, 1234605616436508552
  ret i64 %r
}

; The boundary: 2^36-1 is the largest value the 37-bit signed form holds, 2^36
; is the first that needs the 64-bit one.

define i64 @add_imm37_max(i64 %a) {
; MIR: ADDD_DWRI_X %0, 68719476735
  %r = add i64 %a, 68719476735
  ret i64 %r
}

define i64 @add_imm37_overflow(i64 %a) {
; MIR: ADDD_DWRI_Y %0, 68719476736
  %r = add i64 %a, 68719476736
  ret i64 %r
}

; The same widening applies to every logical operation that has an immediate
; form, not just add.

define i64 @and_imm37(i64 %a) {
; CHECK-LABEL: and_imm37:
; CHECK: andd $r0 = $r0, 305419896
; MIR: ANDD_DWRI_X %0, 305419896
  %r = and i64 %a, 305419896
  ret i64 %r
}

define i64 @or_imm64(i64 %a) {
; CHECK-LABEL: or_imm64:
; CHECK: iord $r0 = $r0, 1234605616436508552
; MIR: IORD_DWRI_Y %0, 1234605616436508552
  %r = or i64 %a, 1234605616436508552
  ret i64 %r
}

define i64 @xor_imm64(i64 %a) {
; CHECK-LABEL: xor_imm64:
; CHECK: eord $r0 = $r0, 1099511627776
; MIR: EORD_DWRI_Y %0, 1099511627776
  %r = xor i64 %a, 1099511627776
  ret i64 %r
}
