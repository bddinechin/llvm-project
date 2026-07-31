; RUN: llc -mtriple=lvx < %s | FileCheck %s

; Assembly-syntax conformance against the LVX ISA description in
; lvx-mds/lvx-refs. Everything the back-end prints is consumed by GNU as
; (there is no MCCodeEmitter for LVX yet), so a mnemonic or operand order
; that disagrees with the ISA is not a cosmetic defect -- it either fails to
; assemble or, worse, assembles into a *different* instruction.
;
; The two-source ALU formats all have ISA syntax "%1 = %2, %3" over operands
; [registerW, registerZ, registerY] -- registerZ is printed FIRST. Confirmed
; against BE/GBU/lvx/lvx_v1/LVX_OPCODE_FLAG_MODE64.s, the generated reference
; assembly, e.g.
;   sbfd $r16r17.hi = $r16r17r18r19.z, $r18
; tagged ..._registerW_registerZ_registerY_simple.

; SBFD is "Subtract From": Description.yml marks '%2': Right, '%3': Left and
; computes "new result1 = argument3 - argument2", i.e. rY - rZ. So for
; "a - b" the subtrahend a... is the one that must land in rY. Printing the
; sources in the wrong order here turns every subtraction into its negation.
; CHECK-LABEL: sub_order:
; CHECK: sbfd $r{{[0-9]+}} = $r{{[0-9]+}}, $r{{[0-9]+}}
define i64 @sub_order(i64 %a, i64 %b) {
  %r = sub i64 %a, %b
  ret i64 %r
}

; COMPD's intcomp encodings are ".LT .GE .LTU .GEU .EQ .NE .ANY .NONE .LE
; .GT .LEU .GTU" over 0..11 (Modifier.table). These check the suffix the
; back-end picks per condition, which is where an off-by-one in the modifier
; table shows up as a silently inverted comparison.
; CHECK-LABEL: cmp_slt:
; CHECK: compd.lt $r{{[0-9]+}} = $r{{[0-9]+}}, $r{{[0-9]+}}
define i64 @cmp_slt(i64 %a, i64 %b) {
  %c = icmp slt i64 %a, %b
  %r = zext i1 %c to i64
  ret i64 %r
}

; CHECK-LABEL: cmp_ugt:
; CHECK: compd.gtu $r{{[0-9]+}} = $r{{[0-9]+}}, $r{{[0-9]+}}
define i64 @cmp_ugt(i64 %a, i64 %b) {
  %c = icmp ugt i64 %a, %b
  %r = zext i1 %c to i64
  ret i64 %r
}

; CHECK-LABEL: cmp_eq:
; CHECK: compd.eq $r{{[0-9]+}} = $r{{[0-9]+}}, $r{{[0-9]+}}
define i64 @cmp_eq(i64 %a, i64 %b) {
  %c = icmp eq i64 %a, %b
  %r = zext i1 %c to i64
  ret i64 %r
}
