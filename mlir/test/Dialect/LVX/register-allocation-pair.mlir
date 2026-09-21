// RUN: mlir-opt %s --pass-pipeline='builtin.module(any(lvx-allocate-registers))' | FileCheck %s

// Pairs and quads under no pressure (lvx-mlir/docs/RegisterAllocation.md,
// "Step 4 -- Register tuples"). A tuple is a block of 2 or 4 units in the
// same space as the singles, and the preference order at each width is
// derived from the ABI by containment: wholly caller-saved blocks first.

// The `mymma` inner step: broadcast a scalar, load a pair, fused
// multiply-add into an accumulator pair, store it. r0/r1 hold the
// arguments, so the first free aligned pair is r2r3; the accumulator `%acc`
// is tied to `ffmawq`'s result and shares its block; the `lq` result gets
// the next pair. Note `%s` (the splat) lands in r2r3, so `%acc` (defined
// later, while `%s` is live) takes r4r5 and `%v` r6r7.
// CHECK-LABEL: lvx_func.func @fma_step
// CHECK-NEXT: %[[S:.*]] = lvx.splatwq %arg1 : (!lvx.reg<r1>) -> !lvx.pair<r2r3>
// CHECK-NEXT: %[[ACC:.*]] = lvx.lq %arg0, 0 : i64 : (!lvx.reg<r0>) -> !lvx.pair<r4r5>
// CHECK-NEXT: %[[V:.*]] = lvx.lq %arg0, 16 : i64 : (!lvx.reg<r0>) -> !lvx.pair<r6r7>
// CHECK-NEXT: %[[F:.*]] = lvx.ffmawq %[[S]], %[[V]], %[[ACC]] : (!lvx.pair<r2r3>, !lvx.pair<r6r7>, !lvx.pair<r4r5>) -> !lvx.pair<r4r5>
// CHECK-NEXT: lvx.sq %[[F]], %arg0, 0 : i64 : (!lvx.pair<r4r5>, !lvx.reg<r0>)
lvx_func.func @fma_step(%base: !lvx.reg<r0>, %x: !lvx.reg<r1>) {
  %s = lvx.splatwq %x : (!lvx.reg<r1>) -> !lvx.pair
  %acc = lvx.lq %base, 0 : i64 : (!lvx.reg<r0>) -> !lvx.pair
  %v = lvx.lq %base, 16 : i64 : (!lvx.reg<r0>) -> !lvx.pair
  %f = lvx.ffmawq %s, %v, %acc : (!lvx.pair, !lvx.pair, !lvx.pair) -> !lvx.pair
  lvx.sq %f, %base, 0 : i64 : (!lvx.pair, !lvx.reg<r0>)
  lvx_func.return
}

// Interference is by unit: a live single in r2 blocks the pair r2r3, so
// the pair goes to r4r5 -- and a pair in r4r5 blocks the singles r4 and
// r5, so with r0, r1 and r2 still live the next single is r3, the hole the
// pair left.
// CHECK-LABEL: lvx_func.func @units
// CHECK-NEXT: %[[A:.*]] = lvx.addd %arg0, %arg1 : (!lvx.reg<r0>, !lvx.reg<r1>) -> !lvx.reg<r2>
// CHECK-NEXT: %[[P:.*]] = lvx.splatwq %[[A]] : (!lvx.reg<r2>) -> !lvx.pair<r4r5>
// CHECK-NEXT: %[[B:.*]] = lvx.addd %[[A]], %arg0 : (!lvx.reg<r2>, !lvx.reg<r0>) -> !lvx.reg<r3>
// CHECK-NEXT: lvx.sq %[[P]], %[[B]], 0 : i64 : (!lvx.pair<r4r5>, !lvx.reg<r3>)
// CHECK-NEXT: lvx.sq %[[P]], %arg1, 0 : i64 : (!lvx.pair<r4r5>, !lvx.reg<r1>)
lvx_func.func @units(%a: !lvx.reg<r0>, %b: !lvx.reg<r1>) {
  %s = lvx.addd %a, %b : (!lvx.reg<r0>, !lvx.reg<r1>) -> !lvx.reg
  %p = lvx.splatwq %s : (!lvx.reg) -> !lvx.pair
  %t = lvx.addd %s, %a : (!lvx.reg, !lvx.reg<r0>) -> !lvx.reg
  lvx.sq %p, %t, 0 : i64 : (!lvx.pair, !lvx.reg)
  lvx.sq %p, %b, 0 : i64 : (!lvx.pair, !lvx.reg<r1>)
  lvx_func.return
}

// A pair live across a call needs every unit callee-saved: the first such
// pair is r18r19 (r14r15 is mixed -- r15 is caller-saved -- and is skipped
// for a crossing item), and both units are saved in the prologue.
// CHECK-LABEL: lvx_func.func @across_call
// CHECK: lvx.reg_live_in : !lvx.reg<r18>
// CHECK: lvx.reg_live_in : !lvx.reg<r19>
// CHECK: %[[P:.*]] = lvx.splatwq %arg0 : (!lvx.reg<r0>) -> !lvx.pair<r18r19>
// CHECK-NEXT: %[[R:.*]] = lvx_func.call @callee(%arg0)
// CHECK-NEXT: lvx.sq %[[P]], %[[R]], 0 : i64 : (!lvx.pair<r18r19>, !lvx.reg<r0>)
lvx_func.func private @callee(!lvx.reg<r0>) -> !lvx.reg<r0>
lvx_func.func @across_call(%a: !lvx.reg<r0>) -> !lvx.reg<r0> {
  %p = lvx.splatwq %a : (!lvx.reg<r0>) -> !lvx.pair
  %r = lvx_func.call @callee(%a) : (!lvx.reg<r0>) -> !lvx.reg<r0>
  lvx.sq %p, %r, 0 : i64 : (!lvx.pair, !lvx.reg<r0>)
  lvx_func.return %r : !lvx.reg<r0>
}

// r14r15 is a pair for an item that does NOT cross a call, ordered after
// the 21 wholly caller-saved pairs and before the 7 wholly callee-saved
// ones (it costs one save, r14, where those cost two). With 21 pairs held
// live the 22nd lands there, and the prologue saves r14 alone.
// CHECK-LABEL: lvx_func.func @mixed_pair
// CHECK: lvx.reg_live_in : !lvx.reg<r14>
// CHECK: lvx.splatwq %arg0 : (!lvx.reg<r0>) -> !lvx.pair<r14r15>
lvx_func.func @mixed_pair(%a: !lvx.reg<r0>) {
  %p0 = lvx.splatwq %a : (!lvx.reg<r0>) -> !lvx.pair
  %p1 = lvx.splatwq %a : (!lvx.reg<r0>) -> !lvx.pair
  %p2 = lvx.splatwq %a : (!lvx.reg<r0>) -> !lvx.pair
  %p3 = lvx.splatwq %a : (!lvx.reg<r0>) -> !lvx.pair
  %p4 = lvx.splatwq %a : (!lvx.reg<r0>) -> !lvx.pair
  %p5 = lvx.splatwq %a : (!lvx.reg<r0>) -> !lvx.pair
  %p6 = lvx.splatwq %a : (!lvx.reg<r0>) -> !lvx.pair
  %p7 = lvx.splatwq %a : (!lvx.reg<r0>) -> !lvx.pair
  %p8 = lvx.splatwq %a : (!lvx.reg<r0>) -> !lvx.pair
  %p9 = lvx.splatwq %a : (!lvx.reg<r0>) -> !lvx.pair
  %p10 = lvx.splatwq %a : (!lvx.reg<r0>) -> !lvx.pair
  %p11 = lvx.splatwq %a : (!lvx.reg<r0>) -> !lvx.pair
  %p12 = lvx.splatwq %a : (!lvx.reg<r0>) -> !lvx.pair
  %p13 = lvx.splatwq %a : (!lvx.reg<r0>) -> !lvx.pair
  %p14 = lvx.splatwq %a : (!lvx.reg<r0>) -> !lvx.pair
  %p15 = lvx.splatwq %a : (!lvx.reg<r0>) -> !lvx.pair
  %p16 = lvx.splatwq %a : (!lvx.reg<r0>) -> !lvx.pair
  %p17 = lvx.splatwq %a : (!lvx.reg<r0>) -> !lvx.pair
  %p18 = lvx.splatwq %a : (!lvx.reg<r0>) -> !lvx.pair
  %p19 = lvx.splatwq %a : (!lvx.reg<r0>) -> !lvx.pair
  %p20 = lvx.splatwq %a : (!lvx.reg<r0>) -> !lvx.pair
  %p21 = lvx.splatwq %a : (!lvx.reg<r0>) -> !lvx.pair
  lvx.sq %p0, %a, 0 : i64 : (!lvx.pair, !lvx.reg<r0>)
  lvx.sq %p1, %a, 0 : i64 : (!lvx.pair, !lvx.reg<r0>)
  lvx.sq %p2, %a, 0 : i64 : (!lvx.pair, !lvx.reg<r0>)
  lvx.sq %p3, %a, 0 : i64 : (!lvx.pair, !lvx.reg<r0>)
  lvx.sq %p4, %a, 0 : i64 : (!lvx.pair, !lvx.reg<r0>)
  lvx.sq %p5, %a, 0 : i64 : (!lvx.pair, !lvx.reg<r0>)
  lvx.sq %p6, %a, 0 : i64 : (!lvx.pair, !lvx.reg<r0>)
  lvx.sq %p7, %a, 0 : i64 : (!lvx.pair, !lvx.reg<r0>)
  lvx.sq %p8, %a, 0 : i64 : (!lvx.pair, !lvx.reg<r0>)
  lvx.sq %p9, %a, 0 : i64 : (!lvx.pair, !lvx.reg<r0>)
  lvx.sq %p10, %a, 0 : i64 : (!lvx.pair, !lvx.reg<r0>)
  lvx.sq %p11, %a, 0 : i64 : (!lvx.pair, !lvx.reg<r0>)
  lvx.sq %p12, %a, 0 : i64 : (!lvx.pair, !lvx.reg<r0>)
  lvx.sq %p13, %a, 0 : i64 : (!lvx.pair, !lvx.reg<r0>)
  lvx.sq %p14, %a, 0 : i64 : (!lvx.pair, !lvx.reg<r0>)
  lvx.sq %p15, %a, 0 : i64 : (!lvx.pair, !lvx.reg<r0>)
  lvx.sq %p16, %a, 0 : i64 : (!lvx.pair, !lvx.reg<r0>)
  lvx.sq %p17, %a, 0 : i64 : (!lvx.pair, !lvx.reg<r0>)
  lvx.sq %p18, %a, 0 : i64 : (!lvx.pair, !lvx.reg<r0>)
  lvx.sq %p19, %a, 0 : i64 : (!lvx.pair, !lvx.reg<r0>)
  lvx.sq %p20, %a, 0 : i64 : (!lvx.pair, !lvx.reg<r0>)
  lvx.sq %p21, %a, 0 : i64 : (!lvx.pair, !lvx.reg<r0>)
  lvx_func.return
}

// A quad: four units, aligned to four. r0 is live (the argument), so the
// first free quad is r4r5r6r7, and a pair allocated while it is live goes
// to r2r3 -- the two units below the quad that the argument left free.
// CHECK-LABEL: lvx_func.func @quad
// CHECK-NEXT: %[[Q:.*]] = lvx.lo %arg0, 0 : i64 : (!lvx.reg<r0>) -> !lvx.quad<r4r5r6r7>
// CHECK-NEXT: %[[P:.*]] = lvx.lq %arg0, 32 : i64 : (!lvx.reg<r0>) -> !lvx.pair<r2r3>
// CHECK-NEXT: lvx.so %[[Q]], %arg0, 0 : i64 : (!lvx.quad<r4r5r6r7>, !lvx.reg<r0>)
// CHECK-NEXT: lvx.sq %[[P]], %arg0, 32 : i64 : (!lvx.pair<r2r3>, !lvx.reg<r0>)
lvx_func.func @quad(%base: !lvx.reg<r0>) {
  %q = lvx.lo %base, 0 : i64 : (!lvx.reg<r0>) -> !lvx.quad
  %p = lvx.lq %base, 32 : i64 : (!lvx.reg<r0>) -> !lvx.pair
  lvx.so %q, %base, 0 : i64 : (!lvx.quad, !lvx.reg<r0>)
  lvx.sq %p, %base, 32 : i64 : (!lvx.pair, !lvx.reg<r0>)
  lvx_func.return
}

// `lvx.concat`: the two pairs are placed as the halves of the quad they
// make -- with r0 and the two loaded pairs live, the first free quad is
// r8r9r10r11, and the zips write straight into r8r9 and r10r11; the concat
// is a type-level identity, like a lane view read the other way.
// CHECK-LABEL: lvx_func.func @concat
// CHECK-NEXT: %[[A:.*]] = lvx.lq %arg0, 0 : i64 : (!lvx.reg<r0>) -> !lvx.pair<r2r3>
// CHECK-NEXT: %[[B:.*]] = lvx.lq %arg0, 16 : i64 : (!lvx.reg<r0>) -> !lvx.pair<r4r5>
// CHECK-NEXT: %[[A0:.*]] = lvx.lane %[[A]][0] : (!lvx.pair<r2r3>) -> !lvx.reg<r2>
// CHECK-NEXT: %[[B0:.*]] = lvx.lane %[[B]][0] : (!lvx.pair<r4r5>) -> !lvx.reg<r4>
// CHECK-NEXT: %[[LO:.*]] = lvx.zipwdq %[[A0]], %[[B0]] : (!lvx.reg<r2>, !lvx.reg<r4>) -> !lvx.pair<r8r9>
// CHECK-NEXT: %[[A1:.*]] = lvx.lane %[[A]][1] : (!lvx.pair<r2r3>) -> !lvx.reg<r3>
// CHECK-NEXT: %[[B1:.*]] = lvx.lane %[[B]][1] : (!lvx.pair<r4r5>) -> !lvx.reg<r5>
// CHECK-NEXT: %[[HI:.*]] = lvx.zipwdq %[[A1]], %[[B1]] : (!lvx.reg<r3>, !lvx.reg<r5>) -> !lvx.pair<r10r11>
// CHECK-NEXT: %[[Q:.*]] = lvx.concat %[[LO]], %[[HI]] : (!lvx.pair<r8r9>, !lvx.pair<r10r11>) -> !lvx.quad<r8r9r10r11>
// CHECK-NEXT: lvx.so %[[Q]], %arg0, 32 : i64 : (!lvx.quad<r8r9r10r11>, !lvx.reg<r0>)
lvx_func.func @concat(%base: !lvx.reg<r0>) {
  %a = lvx.lq %base, 0 : i64 : (!lvx.reg<r0>) -> !lvx.pair
  %b = lvx.lq %base, 16 : i64 : (!lvx.reg<r0>) -> !lvx.pair
  %a0 = lvx.lane %a[0] : (!lvx.pair) -> !lvx.reg
  %b0 = lvx.lane %b[0] : (!lvx.pair) -> !lvx.reg
  %lo = lvx.zipwdq %a0, %b0 : (!lvx.reg, !lvx.reg) -> !lvx.pair
  %a1 = lvx.lane %a[1] : (!lvx.pair) -> !lvx.reg
  %b1 = lvx.lane %b[1] : (!lvx.pair) -> !lvx.reg
  %hi = lvx.zipwdq %a1, %b1 : (!lvx.reg, !lvx.reg) -> !lvx.pair
  %q = lvx.concat %lo, %hi : (!lvx.pair, !lvx.pair) -> !lvx.quad
  lvx.so %q, %base, 32 : i64 : (!lvx.quad, !lvx.reg<r0>)
  lvx_func.return
}
