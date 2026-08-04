; RUN: llc -mtriple=lvx -O0 < %s | FileCheck %s

; A dense switch lowers through a jump table. LVX has no table-branch
; instruction, so ISD::BR_JT is Expand and the generic sequence -- scale the
; index, add the table base, load the entry, branch indirectly -- is what
; reaches isel. Only the resulting ISD::BRIND needs a pattern (-> IGOTO).
;
; Run at -O0 deliberately: at higher optimization levels the switch may be
; turned into a compare chain instead, which would silently stop testing the
; table path. That asymmetry is why this gap only ever showed up in
; unoptimized builds.

; CHECK-LABEL: pick:

; The guard is an UNSIGNED compare, so a negative index is caught as a huge
; unsigned value rather than indexing off the front of the table.
; CHECK: ccb.dltu

; Index scaled by the 8-byte entry size, added to the table base, loaded, and
; branched through.
; CHECK: slld $r{{[0-9]+}} = $r{{[0-9]+}}, 3
; The table base is a link-time symbol, so the widest MAKE form (maked, via
; MAKED_DWI_Y) materializes it -- "make" was the pre-rename spelling.
; CHECK: maked $r{{[0-9]+}} = .LJTI
; CHECK: addd
; CHECK: ld $r{{[0-9]+}} = 0[$r{{[0-9]+}}]
; CHECK: igoto $r{{[0-9]+}}

define i32 @pick(i32 %n) {
entry:
  switch i32 %n, label %def [
    i32 0, label %c0
    i32 1, label %c1
    i32 2, label %c2
    i32 3, label %c3
    i32 4, label %c4
    i32 5, label %c5
    i32 6, label %c6
    i32 7, label %c7
  ]
c0:  ret i32 3
c1:  ret i32 5
c2:  ret i32 7
c3:  ret i32 11
c4:  ret i32 13
c5:  ret i32 17
c6:  ret i32 19
c7:  ret i32 23
def: ret i32 1
}

; The table itself: one 8-byte absolute address per case (EK_BlockAddress,
; the default encoding for a non-PIC target), emitted by the generic
; AsmPrinter into .rodata.
; CHECK: .LJTI
; CHECK-NEXT: .quad .LBB
