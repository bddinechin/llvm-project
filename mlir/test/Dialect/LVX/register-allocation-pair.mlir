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
// CHECK-NEXT: %0 = lvx.splatwq %arg1 : (!lvx.reg<r1>) -> !lvx.pair<r2r3>
// CHECK-NEXT: %1 = lvx.lq %arg0, 0 : i64 : (!lvx.reg<r0>) -> !lvx.pair<r4r5>
// CHECK-NEXT: %2 = lvx.lq %arg0, 16 : i64 : (!lvx.reg<r0>) -> !lvx.pair<r6r7>
// CHECK-NEXT: %3 = lvx.ffmawq %0, %2, %1 : (!lvx.pair<r2r3>, !lvx.pair<r6r7>, !lvx.pair<r4r5>) -> !lvx.pair<r4r5>
// CHECK-NEXT: lvx.sq %3, %arg0, 0 : i64 : (!lvx.pair<r4r5>, !lvx.reg<r0>)
// CHECK-NEXT: lvx_func.return
// CHECK-NEXT: }
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
// CHECK-NEXT: %0 = lvx.addd %arg0, %arg1 : (!lvx.reg<r0>, !lvx.reg<r1>) -> !lvx.reg<r2>
// CHECK-NEXT: %1 = lvx.splatwq %0 : (!lvx.reg<r2>) -> !lvx.pair<r4r5>
// CHECK-NEXT: %2 = lvx.addd %0, %arg0 : (!lvx.reg<r2>, !lvx.reg<r0>) -> !lvx.reg<r0>
// CHECK-NEXT: lvx.sq %1, %2, 0 : i64 : (!lvx.pair<r4r5>, !lvx.reg<r0>)
// CHECK-NEXT: lvx.sq %1, %arg1, 0 : i64 : (!lvx.pair<r4r5>, !lvx.reg<r1>)
// CHECK-NEXT: lvx_func.return
// CHECK-NEXT: }
// CHECK-NEXT: lvx_func.func private @callee(!lvx.reg<r0>) -> !lvx.reg<r0>
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
// CHECK-NEXT: %0 = lvx.sp : !lvx.reg<r12>
// CHECK-NEXT: %1 = lvx.li 24 : i64 : !lvx.reg<r61>
// CHECK-NEXT: %2 = lvx.sbfd %0, %1 : (!lvx.reg<r12>, !lvx.reg<r61>) -> !lvx.reg<r12>
// CHECK-NEXT: %3 = lvx.reg_live_in : !lvx.reg<ra>
// CHECK-NEXT: %4 = lvx.get %3 : (!lvx.reg<ra>) -> !lvx.reg<r61>
// CHECK-NEXT: lvx.sd %4, %2, 0 : i64 : (!lvx.reg<r61>, !lvx.reg<r12>)
// CHECK-NEXT: %5 = lvx.reg_live_in : !lvx.reg<r18>
// CHECK-NEXT: lvx.sd %5, %2, 8 : i64 : (!lvx.reg<r18>, !lvx.reg<r12>)
// CHECK-NEXT: %6 = lvx.reg_live_in : !lvx.reg<r19>
// CHECK-NEXT: lvx.sd %6, %2, 16 : i64 : (!lvx.reg<r19>, !lvx.reg<r12>)
// CHECK-NEXT: %7 = lvx.splatwq %arg0 : (!lvx.reg<r0>) -> !lvx.pair<r18r19>
// CHECK-NEXT: %8 = lvx_func.call @callee(%arg0) : (!lvx.reg<r0>) -> !lvx.reg<r0>
// CHECK-NEXT: lvx.sq %7, %8, 0 : i64 : (!lvx.pair<r18r19>, !lvx.reg<r0>)
// CHECK-NEXT: %9 = lvx.ld %2, 8 : i64 : (!lvx.reg<r12>) -> !lvx.reg<r18>
// CHECK-NEXT: lvx.reg_live_out %9 : !lvx.reg<r18>
// CHECK-NEXT: %10 = lvx.ld %2, 16 : i64 : (!lvx.reg<r12>) -> !lvx.reg<r19>
// CHECK-NEXT: lvx.reg_live_out %10 : !lvx.reg<r19>
// CHECK-NEXT: %11 = lvx.ld %2, 0 : i64 : (!lvx.reg<r12>) -> !lvx.reg<r61>
// CHECK-NEXT: %12 = lvx.set %11 : (!lvx.reg<r61>) -> !lvx.reg<ra>
// CHECK-NEXT: %13 = lvx.li 24 : i64 : !lvx.reg<r61>
// CHECK-NEXT: %14 = lvx.addd %2, %13 : (!lvx.reg<r12>, !lvx.reg<r61>) -> !lvx.reg<r12>
// CHECK-NEXT: lvx_func.return %8 : !lvx.reg<r0>
// CHECK-NEXT: }
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
// CHECK-NEXT: %0 = lvx.sp : !lvx.reg<r12>
// CHECK-NEXT: %1 = lvx.li 24 : i64 : !lvx.reg<r61>
// CHECK-NEXT: %2 = lvx.sbfd %0, %1 : (!lvx.reg<r12>, !lvx.reg<r61>) -> !lvx.reg<r12>
// CHECK-NEXT: %3 = lvx.reg_live_in : !lvx.reg<r14>
// CHECK-NEXT: lvx.sd %3, %2, 0 : i64 : (!lvx.reg<r14>, !lvx.reg<r12>)
// CHECK-NEXT: %4 = lvx.reg_live_in : !lvx.reg<r18>
// CHECK-NEXT: lvx.sd %4, %2, 8 : i64 : (!lvx.reg<r18>, !lvx.reg<r12>)
// CHECK-NEXT: %5 = lvx.reg_live_in : !lvx.reg<r19>
// CHECK-NEXT: lvx.sd %5, %2, 16 : i64 : (!lvx.reg<r19>, !lvx.reg<r12>)
// CHECK-NEXT: %6 = lvx.splatwq %arg0 : (!lvx.reg<r0>) -> !lvx.pair<r2r3>
// CHECK-NEXT: %7 = lvx.splatwq %arg0 : (!lvx.reg<r0>) -> !lvx.pair<r4r5>
// CHECK-NEXT: %8 = lvx.splatwq %arg0 : (!lvx.reg<r0>) -> !lvx.pair<r6r7>
// CHECK-NEXT: %9 = lvx.splatwq %arg0 : (!lvx.reg<r0>) -> !lvx.pair<r8r9>
// CHECK-NEXT: %10 = lvx.splatwq %arg0 : (!lvx.reg<r0>) -> !lvx.pair<r10r11>
// CHECK-NEXT: %11 = lvx.splatwq %arg0 : (!lvx.reg<r0>) -> !lvx.pair<r16r17>
// CHECK-NEXT: %12 = lvx.splatwq %arg0 : (!lvx.reg<r0>) -> !lvx.pair<r32r33>
// CHECK-NEXT: %13 = lvx.splatwq %arg0 : (!lvx.reg<r0>) -> !lvx.pair<r34r35>
// CHECK-NEXT: %14 = lvx.splatwq %arg0 : (!lvx.reg<r0>) -> !lvx.pair<r36r37>
// CHECK-NEXT: %15 = lvx.splatwq %arg0 : (!lvx.reg<r0>) -> !lvx.pair<r38r39>
// CHECK-NEXT: %16 = lvx.splatwq %arg0 : (!lvx.reg<r0>) -> !lvx.pair<r40r41>
// CHECK-NEXT: %17 = lvx.splatwq %arg0 : (!lvx.reg<r0>) -> !lvx.pair<r42r43>
// CHECK-NEXT: %18 = lvx.splatwq %arg0 : (!lvx.reg<r0>) -> !lvx.pair<r44r45>
// CHECK-NEXT: %19 = lvx.splatwq %arg0 : (!lvx.reg<r0>) -> !lvx.pair<r46r47>
// CHECK-NEXT: %20 = lvx.splatwq %arg0 : (!lvx.reg<r0>) -> !lvx.pair<r48r49>
// CHECK-NEXT: %21 = lvx.splatwq %arg0 : (!lvx.reg<r0>) -> !lvx.pair<r50r51>
// CHECK-NEXT: %22 = lvx.splatwq %arg0 : (!lvx.reg<r0>) -> !lvx.pair<r52r53>
// CHECK-NEXT: %23 = lvx.splatwq %arg0 : (!lvx.reg<r0>) -> !lvx.pair<r54r55>
// CHECK-NEXT: %24 = lvx.splatwq %arg0 : (!lvx.reg<r0>) -> !lvx.pair<r56r57>
// CHECK-NEXT: %25 = lvx.splatwq %arg0 : (!lvx.reg<r0>) -> !lvx.pair<r58r59>
// CHECK-NEXT: %26 = lvx.splatwq %arg0 : (!lvx.reg<r0>) -> !lvx.pair<r14r15>
// CHECK-NEXT: %27 = lvx.splatwq %arg0 : (!lvx.reg<r0>) -> !lvx.pair<r18r19>
// CHECK-NEXT: lvx.sq %6, %arg0, 0 : i64 : (!lvx.pair<r2r3>, !lvx.reg<r0>)
// CHECK-NEXT: lvx.sq %7, %arg0, 0 : i64 : (!lvx.pair<r4r5>, !lvx.reg<r0>)
// CHECK-NEXT: lvx.sq %8, %arg0, 0 : i64 : (!lvx.pair<r6r7>, !lvx.reg<r0>)
// CHECK-NEXT: lvx.sq %9, %arg0, 0 : i64 : (!lvx.pair<r8r9>, !lvx.reg<r0>)
// CHECK-NEXT: lvx.sq %10, %arg0, 0 : i64 : (!lvx.pair<r10r11>, !lvx.reg<r0>)
// CHECK-NEXT: lvx.sq %11, %arg0, 0 : i64 : (!lvx.pair<r16r17>, !lvx.reg<r0>)
// CHECK-NEXT: lvx.sq %12, %arg0, 0 : i64 : (!lvx.pair<r32r33>, !lvx.reg<r0>)
// CHECK-NEXT: lvx.sq %13, %arg0, 0 : i64 : (!lvx.pair<r34r35>, !lvx.reg<r0>)
// CHECK-NEXT: lvx.sq %14, %arg0, 0 : i64 : (!lvx.pair<r36r37>, !lvx.reg<r0>)
// CHECK-NEXT: lvx.sq %15, %arg0, 0 : i64 : (!lvx.pair<r38r39>, !lvx.reg<r0>)
// CHECK-NEXT: lvx.sq %16, %arg0, 0 : i64 : (!lvx.pair<r40r41>, !lvx.reg<r0>)
// CHECK-NEXT: lvx.sq %17, %arg0, 0 : i64 : (!lvx.pair<r42r43>, !lvx.reg<r0>)
// CHECK-NEXT: lvx.sq %18, %arg0, 0 : i64 : (!lvx.pair<r44r45>, !lvx.reg<r0>)
// CHECK-NEXT: lvx.sq %19, %arg0, 0 : i64 : (!lvx.pair<r46r47>, !lvx.reg<r0>)
// CHECK-NEXT: lvx.sq %20, %arg0, 0 : i64 : (!lvx.pair<r48r49>, !lvx.reg<r0>)
// CHECK-NEXT: lvx.sq %21, %arg0, 0 : i64 : (!lvx.pair<r50r51>, !lvx.reg<r0>)
// CHECK-NEXT: lvx.sq %22, %arg0, 0 : i64 : (!lvx.pair<r52r53>, !lvx.reg<r0>)
// CHECK-NEXT: lvx.sq %23, %arg0, 0 : i64 : (!lvx.pair<r54r55>, !lvx.reg<r0>)
// CHECK-NEXT: lvx.sq %24, %arg0, 0 : i64 : (!lvx.pair<r56r57>, !lvx.reg<r0>)
// CHECK-NEXT: lvx.sq %25, %arg0, 0 : i64 : (!lvx.pair<r58r59>, !lvx.reg<r0>)
// CHECK-NEXT: lvx.sq %26, %arg0, 0 : i64 : (!lvx.pair<r14r15>, !lvx.reg<r0>)
// CHECK-NEXT: lvx.sq %27, %arg0, 0 : i64 : (!lvx.pair<r18r19>, !lvx.reg<r0>)
// CHECK-NEXT: %28 = lvx.ld %2, 0 : i64 : (!lvx.reg<r12>) -> !lvx.reg<r14>
// CHECK-NEXT: lvx.reg_live_out %28 : !lvx.reg<r14>
// CHECK-NEXT: %29 = lvx.ld %2, 8 : i64 : (!lvx.reg<r12>) -> !lvx.reg<r18>
// CHECK-NEXT: lvx.reg_live_out %29 : !lvx.reg<r18>
// CHECK-NEXT: %30 = lvx.ld %2, 16 : i64 : (!lvx.reg<r12>) -> !lvx.reg<r19>
// CHECK-NEXT: lvx.reg_live_out %30 : !lvx.reg<r19>
// CHECK-NEXT: %31 = lvx.li 24 : i64 : !lvx.reg<r61>
// CHECK-NEXT: %32 = lvx.addd %2, %31 : (!lvx.reg<r12>, !lvx.reg<r61>) -> !lvx.reg<r12>
// CHECK-NEXT: lvx_func.return
// CHECK-NEXT: }
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
// CHECK-NEXT: %0 = lvx.lo %arg0, 0 : i64 : (!lvx.reg<r0>) -> !lvx.quad<r4r5r6r7>
// CHECK-NEXT: %1 = lvx.lq %arg0, 32 : i64 : (!lvx.reg<r0>) -> !lvx.pair<r2r3>
// CHECK-NEXT: lvx.so %0, %arg0, 0 : i64 : (!lvx.quad<r4r5r6r7>, !lvx.reg<r0>)
// CHECK-NEXT: lvx.sq %1, %arg0, 32 : i64 : (!lvx.pair<r2r3>, !lvx.reg<r0>)
// CHECK-NEXT: lvx_func.return
// CHECK-NEXT: }
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
// CHECK-NEXT: %0 = lvx.lq %arg0, 0 : i64 : (!lvx.reg<r0>) -> !lvx.pair<r2r3>
// CHECK-NEXT: %1 = lvx.lq %arg0, 16 : i64 : (!lvx.reg<r0>) -> !lvx.pair<r4r5>
// CHECK-NEXT: %2 = lvx.lane %0[0] : (!lvx.pair<r2r3>) -> !lvx.reg<r2>
// CHECK-NEXT: %3 = lvx.lane %1[0] : (!lvx.pair<r4r5>) -> !lvx.reg<r4>
// CHECK-NEXT: %4 = lvx.zipwdq %2, %3 : (!lvx.reg<r2>, !lvx.reg<r4>) -> !lvx.pair<r8r9>
// CHECK-NEXT: %5 = lvx.lane %0[1] : (!lvx.pair<r2r3>) -> !lvx.reg<r3>
// CHECK-NEXT: %6 = lvx.lane %1[1] : (!lvx.pair<r4r5>) -> !lvx.reg<r5>
// CHECK-NEXT: %7 = lvx.zipwdq %5, %6 : (!lvx.reg<r3>, !lvx.reg<r5>) -> !lvx.pair<r10r11>
// CHECK-NEXT: %8 = lvx.concat %4, %7 : (!lvx.pair<r8r9>, !lvx.pair<r10r11>) -> !lvx.quad<r8r9r10r11>
// CHECK-NEXT: lvx.so %8, %arg0, 32 : i64 : (!lvx.quad<r8r9r10r11>, !lvx.reg<r0>)
// CHECK-NEXT: lvx_func.return
// CHECK-NEXT: }
// CHECK-NEXT: }
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
