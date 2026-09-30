; RUN: llc -mtriple=lvx-mbr -verify-machineinstrs < %s | FileCheck %s

; BSELD and BSELQ, the bitwise select, new in the ISA on 2026-09-29 and present
; on BOTH cores:
;
;     bseld $rW = $rZ, $rY      rW = (rZ & rY) | (rW & ~rY)
;
; The destination is read as well as written, which is what makes it a select
; rather than a mask-and-or, and on lvx-1 it is the only single-instruction
; select there is -- BLEND* is lvx-2 only.
;
; The pattern matches `b ^ ((a ^ b) & m)`, NOT `(a & m) | (b & ~m)`: the second
; shape survives InstCombine intact, but DAGCombiner folds it to the first
; before isel sees it, so a pattern written over or/not never fires and the
; three-instruction sequence keeps coming out. This test is written in the
; source shape a user writes, so it fails if that fold ever changes.

define i64 @bsel_d(i64 %a, i64 %b, i64 %m) {
; CHECK-LABEL: bsel_d:
; CHECK:      bseld $r{{[0-9]+}} = $r{{[0-9]+}}, $r{{[0-9]+}}
; CHECK-NOT:  iord
; CHECK:      ret
  %am = and i64 %a, %m
  %nm = xor i64 %m, -1
  %bn = and i64 %b, %nm
  %r = or i64 %am, %bn
  ret i64 %r
}

; The already-canonical shape must select the same instruction.
define i64 @bsel_d_canonical(i64 %a, i64 %b, i64 %m) {
; CHECK-LABEL: bsel_d_canonical:
; CHECK:      bseld $r{{[0-9]+}} = $r{{[0-9]+}}, $r{{[0-9]+}}
; CHECK:      ret
  %x = xor i64 %a, %b
  %xm = and i64 %x, %m
  %r = xor i64 %xm, %b
  ret i64 %r
}

; 128 bits in a register pair. The i128 case is also why PreprocessISelDAG
; splits only constants needing more than 64 bits: `not m` is `xor m, -1`, and
; an i128 -1 has to still be a constant when the matcher looks at it.
define i128 @bsel_q(i128 %a, i128 %b, i128 %m) {
; CHECK-LABEL: bsel_q:
; CHECK:      bselq ${{r[0-9]+r[0-9]+}} = ${{r[0-9]+r[0-9]+}}, ${{r[0-9]+r[0-9]+}}
; CHECK-NOT:  iorq
; CHECK:      ret
  %am = and i128 %a, %m
  %nm = xor i128 %m, -1
  %bn = and i128 %b, %nm
  %r = or i128 %am, %bn
  ret i128 %r
}

; A CONSTANT mask is a missed opportunity, recorded here rather than asserted
; away. DAGCombiner does not fold to the xor shape when the mask is constant --
; `and x, C` is already cheap -- so the BSELD pattern never sees it, and this
; stays three instructions. It is exactly what INSFD does in ONE, for a mask
; that is a contiguous run of ones (255 is bits 0..7): insert a's field into b,
; the field given as a pair of immediates. Implementing that needs a predicate
; for "contiguous mask" plus the stop/start encoding; until then this pins the
; current output so the improvement is visible when it lands.
define i64 @bsel_d_constant_mask(i64 %a, i64 %b) {
; CHECK-LABEL: bsel_d_constant_mask:
; CHECK-DAG:  andd $r{{[0-9]+}} = $r{{[0-9]+}}, -256
; CHECK-DAG:  andd $r{{[0-9]+}} = $r{{[0-9]+}}, 255
; CHECK:      iord
; CHECK:      ret
  %am = and i64 %a, 255
  %bn = and i64 %b, -256
  %r = or i64 %am, %bn
  ret i64 %r
}
