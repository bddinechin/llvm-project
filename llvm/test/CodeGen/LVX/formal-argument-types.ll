; RUN: llc -mtriple=lvx-mbr -debug-only=isel -o /dev/null %s
; REQUIRES: asserts

; LowerFormalArguments must hand SelectionDAGBuilder values of the type the
; CONVENTION assigned -- Ins[i].VT, the legalized type -- and not of the IR's
; own ArgVT. For a narrow integer the two differ: i1/i8/i16/i32 are illegal
; here, so the convention promotes them to i64 and the BUILDER is what puts the
; value back to its IR type.
;
; This back end truncated to the IR type as well and handed that back, which
; came out right because the builder then truncated an already-truncated value.
; SelectionDAGBuilder::LowerArguments verifies the contract -- "LowerFormalArguments
; emitted a value with the wrong type!" -- but inside an LLVM_DEBUG block, so the
; check only RUNS under -debug-only=isel and the violation went unnoticed until
; a DAG dump was wanted for something else.
;
; Hence the RUN line: there is nothing to FileCheck, the test is that the
; verification passes. It needs an assertions build to mean anything, which is
; what REQUIRES states.

define i32 @narrow_int(i32 %a, i32 %b) {
  %r = lshr i32 %a, %b
  ret i32 %r
}

define i64 @every_narrow_width(i1 %p, i8 %b, i16 %h, i32 %w) {
  %pz = zext i1 %p to i64
  %bz = zext i8 %b to i64
  %hz = zext i16 %h to i64
  %wz = zext i32 %w to i64
  %s1 = add i64 %pz, %bz
  %s2 = add i64 %s1, %hz
  %s3 = add i64 %s2, %wz
  ret i64 %s3
}

; The types where ArgVT and the convention's VT agree, which must keep working:
; f32 and f16 are legal and reinterpreted out of their slot in place, f64 is a
; bitcast, i128 is two slots paired and v4i64 is four slots built into a vector.
define double @wide_and_fp(float %f, half %h, double %d, i128 %q, <4 x i64> %v) {
  %fd = fpext float %f to double
  %hd = fpext half %h to double
  %s = fadd double %fd, %hd
  %t = fadd double %s, %d
  ret double %t
}

; And a narrow argument passed on the STACK rather than in a register, which
; takes the same path through a load.
define i32 @narrow_on_the_stack(i64 %a0, i64 %a1, i64 %a2, i64 %a3, i64 %a4,
                                i64 %a5, i64 %a6, i64 %a7, i64 %a8, i64 %a9,
                                i64 %a10, i64 %a11, i32 %spilled) {
  ret i32 %spilled
}
