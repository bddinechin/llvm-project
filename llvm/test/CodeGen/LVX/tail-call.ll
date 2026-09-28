; RUN: llc -mtriple=lvx-mbr -verify-machineinstrs < %s | FileCheck %s

; A tail call is a REQUEST the middle end makes of the target, not an
; obligation: it marks any call in tail position, and a target without
; tail-call lowering declines by clearing the flag and emitting an ordinary
; call. Until 2026-09-28 LowerCall raised report_fatal_error instead, so two
; lines of C at -O2 -- "int caller(int a, int b) { return callee(b, a); }" --
; killed clang outright. There is nothing target-specific to check beyond
; "this compiles into a normal call and returns", which is the point.

declare i32 @callee(i32, i32)

define i32 @plain_tail(i32 %a, i32 %b) {
; CHECK-LABEL: plain_tail:
; CHECK:      call callee
; CHECK:      ret
  %r = tail call i32 @callee(i32 %b, i32 %a)
  ret i32 %r
}

; `musttail` is a different contract -- the middle end is entitled to assume
; the call really is a tail call -- so it is NOT silently downgraded here; this
; only pins that the ordinary marker, which clang attaches on its own, is
; handled. A tail call whose arguments are wide takes the same path.
define i128 @wide_tail(i128 %a) {
; CHECK-LABEL: wide_tail:
; CHECK:      call widecallee
; CHECK:      ret
  %r = tail call i128 @widecallee(i128 %a)
  ret i128 %r
}

declare i128 @widecallee(i128)
