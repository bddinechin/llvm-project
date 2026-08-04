; RUN: llc -mtriple=lvx < %s | FileCheck %s
; XFAIL: *
; NOT YET PORTED: scalar floating point is not lowered yet ("unsupported library call
; operation"). Ported from the pre-MDS backend as the spec for that work; drop
; this XFAIL when it lands.

; Scalar floating point. LVX has no separate FP register file -- f64 and f32
; live in GPRs -- so these checks are as much about the right *instruction*
; being chosen as about registers.
;
; Rounding: the arithmetic patterns pass floatmode=7, the "no suffix" member,
; which means dynamic rounding from $cs.RM. That matches RISC-V, whose rm=111
; is DYN and is what its assembler defaults to. Conversions to integer instead
; pin .rz, because C truncates toward zero.
;
; Value-level checking (that a-b is not b-a, that conversions actually
; convert) lives in validation/tests/micro/floats.c, which runs the same
; source natively on x86 and on the ISS and diffs the results.

; CHECK-LABEL: fadd64:
; CHECK: faddd $r{{[0-9]+}} = $r{{[0-9]+}}, $r{{[0-9]+}}
define double @fadd64(double %a, double %b) {
  %r = fadd double %a, %b
  ret double %r
}

; FSBFD is "subtract from": f64_sub(RM, argument3, argument2) = rY - rZ, and
; the printed order is "$rW = $rZ, $rY". So for "a - b" the operands must come
; out reversed relative to the source; printing them in source order would
; negate every subtraction.
; CHECK-LABEL: fsub64:
; CHECK: fsbfd $r{{[0-9]+}} = $r{{[0-9]+}}, $r{{[0-9]+}}
define double @fsub64(double %a, double %b) {
  %r = fsub double %a, %b
  ret double %r
}

; CHECK-LABEL: fmul64:
; CHECK: fmuld $r{{[0-9]+}} = $r{{[0-9]+}}, $r{{[0-9]+}}
define double @fmul64(double %a, double %b) {
  %r = fmul double %a, %b
  ret double %r
}

; CHECK-LABEL: fdiv64:
; CHECK: fdivd $r{{[0-9]+}} = $r{{[0-9]+}}, $r{{[0-9]+}}
define double @fdiv64(double %a, double %b) {
  %r = fdiv double %a, %b
  ret double %r
}

; CHECK-LABEL: fsqrt64:
; CHECK: fsqrtd $r{{[0-9]+}} = $r{{[0-9]+}}
define double @fsqrt64(double %a) {
  %r = call double @llvm.sqrt.f64(double %a)
  ret double %r
}

; floatcomp members: 0 .ONE, 1 .UEQ, 2 .OEQ, 3 .UNE, 4 .OLT, 5 .UGE, 6 .OGE,
; 7 .ULT. There is no GT/LE member, so "a > b" must come out as "b < a" -- an
; olt with the operands swapped, not an invented mnemonic.
; CHECK-LABEL: fcmp_olt:
; CHECK: fcompd.olt $r{{[0-9]+}} = $r{{[0-9]+}}, $r{{[0-9]+}}
define i64 @fcmp_olt(double %a, double %b) {
  %c = fcmp olt double %a, %b
  %r = zext i1 %c to i64
  ret i64 %r
}

; CHECK-LABEL: fcmp_ogt:
; CHECK: fcompd.olt $r{{[0-9]+}} = $r{{[0-9]+}}, $r{{[0-9]+}}
define i64 @fcmp_ogt(double %a, double %b) {
  %c = fcmp ogt double %a, %b
  %r = zext i1 %c to i64
  ret i64 %r
}

; Conversions to integer truncate toward zero, so they must carry .rz and not
; inherit the dynamic mode.
; CHECK-LABEL: to_int:
; CHECK: fixedd.rz $r{{[0-9]+}} = $r{{[0-9]+}}
define i64 @to_int(double %a) {
  %r = fptosi double %a to i64
  ret i64 %r
}

; CHECK-LABEL: to_uint:
; CHECK: fixedud.rz $r{{[0-9]+}} = $r{{[0-9]+}}
define i64 @to_uint(double %a) {
  %r = fptoui double %a to i64
  ret i64 %r
}

; CHECK-LABEL: from_int:
; CHECK: floatd $r{{[0-9]+}} = $r{{[0-9]+}}
define double @from_int(i64 %a) {
  %r = sitofp i64 %a to double
  ret double %r
}

; f32 <-> f64 must be real conversions. These previously compiled to a bare
; load/store pair with no conversion instruction at all: DAGCombiner had folded
; the fpextend into an f32->f64 extending load, which the ISA does not have.
; CHECK-LABEL: widen:
; CHECK: fwidenwd $r{{[0-9]+}} = $r{{[0-9]+}}
define double @widen(float %a) {
  %r = fpext float %a to double
  ret double %r
}

; CHECK-LABEL: narrow:
; CHECK: fnarrowdw $r{{[0-9]+}} = $r{{[0-9]+}}
define float @narrow(double %a) {
  %r = fptrunc double %a to float
  ret float %r
}

; CHECK-LABEL: fadd32:
; CHECK: faddw $r{{[0-9]+}} = $r{{[0-9]+}}, $r{{[0-9]+}}
define float @fadd32(float %a, float %b) {
  %r = fadd float %a, %b
  ret float %r
}

; An FP constant has no immediate form; it is materialized as its raw bit
; pattern through the same MAKE ladder as any integer constant.
; 3.5 == 0x400C000000000000 == 4614838538166547251-ish; just check for a MAKE.
; CHECK-LABEL: fconst:
; CHECK: make $r{{[0-9]+}} = {{-?[0-9]+}}
define double @fconst() {
  ret double 3.5
}

declare double @llvm.sqrt.f64(double)
