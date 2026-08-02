; RUN: llc -mtriple=lvx-mbr < %s | FileCheck %s
; RUN: llc -mtriple=lvx-mbr -stop-after=finalize-isel < %s | FileCheck %s --check-prefix=MIR

; A base+offset load or store carries 10 bits of displacement in one syllable,
; 37 in two (LSU_LSBO.X / LSU_SSBO.X) and 64 in three. Selection picks the
; narrowest that holds the displacement, so a large offset folds into the
; access instead of needing a separate addd to compute the address.

define i64 @load_near(ptr %p) {
; CHECK-LABEL: load_near:
; CHECK: ld $r0 = 64[$r0]
; MIR: LD_LSBO 64, %0, 0
  %q = getelementptr i8, ptr %p, i64 64
  %v = load i64, ptr %q
  ret i64 %v
}

define i64 @load_far(ptr %p) {
; CHECK-LABEL: load_far:
; CHECK:     ld $r0 = 100000[$r0]
; CHECK-NOT: addd
; MIR: LD_LSBO_X 100000, %0, 0
  %q = getelementptr i8, ptr %p, i64 100000
  %v = load i64, ptr %q
  ret i64 %v
}

define i32 @load_very_far(ptr %p) {
; CHECK-LABEL: load_very_far:
; CHECK:     lwz $r0 = 1099511627776[$r0]
; CHECK-NOT: addd
; MIR: LWZ_LSBO_Y 1099511627776, %0, 0
  %q = getelementptr i8, ptr %p, i64 1099511627776
  %v = load i32, ptr %q
  ret i32 %v
}

define void @store_far(ptr %p, i64 %v) {
; CHECK-LABEL: store_far:
; CHECK:     sd 100000[$r0] = $r1
; CHECK-NOT: addd
; MIR: SD_SSBO_X 100000, %0, %1
  %q = getelementptr i8, ptr %p, i64 100000
  store i64 %v, ptr %q
  ret void
}
