// RUN: mlir-opt %s --pass-pipeline='builtin.module(any(lvx-allocate-registers),any(lvx-scf-to-cf),lvx-emit-asm)' -o /dev/null | FileCheck %s

// This is also, deliberately, an integration test against the real
// sibling-project toolchain (lvx-mlir/docs/AssemblyEmission.md, "Testing"):
// every function emitted here was hand-assembled with the real
// `lvx-mbr-as` and round-tripped through `lvx-mbr-objdump` before these
// CHECK lines were written, and the RUN line below re-assembles the same
// output on every test run.
//
// `%lvx_mbr_as` and the `lvx-mbr-as` feature come from this directory's
// `lit.local.cfg`, which locates the installed toolchain (this checkout sits
// at a different absolute path on each machine, so never hardcode one here).
// The `%if` is what keeps the CHECK run above alive where the toolchain is
// absent; a file-scoped requires-directive would skip that run too.  (Don't
// spell that directive out here, even in prose -- lit scans every line of the
// file for it and would take the mention as the real thing.)
//
// RUN: %if lvx-mbr-as %{ mlir-opt %s --pass-pipeline='builtin.module(any(lvx-allocate-registers),any(lvx-scf-to-cf),lvx-emit-asm)' -o /dev/null 2>/dev/null | %lvx_mbr_as - -o %t.o %} %else %{ true %}

// Straight-line code: every op gets its own `;;`-terminated bundle. The two
// ABI copy-ins this function starts from are not here -- `%a` and `%b` die at
// the `addd` that reads them, so its result takes r1 and the copies became
// identities the allocation sweep removed (2026-10-14). `lvx.mv`/`lvx.li`
// still lower to real `copyd`/`maked` where a copy survives: see `loop:`.
// CHECK-LABEL: straight:
// CHECK-NEXT: addd $r1 = $r0, $r1
// CHECK-NEXT: ;;
// CHECK-NEXT: muld $r0 = $r1, $r0
// CHECK-NEXT: ;;
// CHECK-NEXT: ret
// CHECK-NEXT: ;;
// CHECK-NEXT: .global subtract
// The ABI copy-out into the pinned return register is *not* here: the value
// was placed in $r0 already, so it was `copyd $r0 = $r0` and the identity
// sweep at the end of allocation removed it. That matters for more than code
// size -- an identity copy left in place still occupies a TINY slot, the
// resource that binds a bundle on this machine.
lvx_func.func @straight(%a: !lvx.reg<r0>, %b: !lvx.reg<r1>) -> !lvx.reg<r0> {
  %0 = lvx.mv %a : (!lvx.reg<r0>) -> !lvx.reg
  %1 = lvx.mv %b : (!lvx.reg<r1>) -> !lvx.reg
  %2 = lvx.addd %0, %1 : (!lvx.reg, !lvx.reg) -> !lvx.reg
  %3 = lvx.muld %2, %0 : (!lvx.reg, !lvx.reg) -> !lvx.reg
  %4 = lvx.mv %3 : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %4 : !lvx.reg<r0>
}

// `sbfd` is a real "subtract FROM" opcode: `sbfd $rd = $rs1, $rs2` computes
// `$rs2 - $rs1`, not `$rs1 - $rs2` -- confirmed against
// lvx-mds/refs/FE/YAML/lvx/lvx_v1/Description.yml's own description ("The
// %2 is subtracted from the %3") and empirically on real gem5
// (lvx-mlir/docs/EndToEndValidation.md, where a naively-printed "subtract" of 5
// and 0 executed to -5). `lvx.sbfd %lhs, %rhs`'s own IR-level semantics
// still mean the natural "result = lhs - rhs" that `arith.subi` and every
// other caller assumes; only the *printed* operand order is swapped
// (`%1, %0` below, not `%0, %1`) to compensate at the assembly boundary --
// see `emitBinarySubtractFrom` in EmitAsm.cpp.
// CHECK-LABEL: subtract:
// CHECK-NEXT: sbfd $r0 = $r1, $r0
// CHECK-NEXT: ;;
// CHECK-NEXT: ret
// CHECK-NEXT: ;;
// CHECK-NEXT: .global branches
lvx_func.func @subtract(%a: !lvx.reg<r0>, %b: !lvx.reg<r1>) -> !lvx.reg<r0> {
  %0 = lvx.mv %a : (!lvx.reg<r0>) -> !lvx.reg
  %1 = lvx.mv %b : (!lvx.reg<r1>) -> !lvx.reg
  %2 = lvx.sbfd %0, %1 : (!lvx.reg, !lvx.reg) -> !lvx.reg
  %3 = lvx.mv %2 : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %3 : !lvx.reg<r0>
}

// A branch diamond: `lvx_cf.cond_br`'s bcucond modifier concatenates onto
// `cb` with a leading dot (`cb.wnez`, not `cb wnez`). The false edge
// (^bb1 -> ^bb2, i.e. .LBB0 -> .LBB1) and ^bb1's own unconditional branch
// to ^bb2 are both to the block immediately following in emission order,
// so both are elided entirely -- real assembly just falls through (the
// same rule that's required for correctness on a hardware loop's body
// exit, see the @loop case below, applied here purely as a cleanup).
// Block-label numbers are a single counter for the whole module, not
// reset per function (see scf-to-cf.mlir's neighbor doc comment /
// lvx-mlir/docs/AssemblyEmission.md's "Confirmed syntax" gotcha), so this
// matches them by capture rather than hardcoding which number lands here.
// CHECK-LABEL: branches:
// CHECK-NEXT: cb.wnez $r1? .LBB0
// CHECK-NEXT: ;;
// CHECK-NEXT: goto .LBB1
// CHECK-NEXT: ;;
// CHECK-NEXT: .LBB0:
// CHECK-NEXT: .LBB1:
// CHECK-NEXT: addd $r0 = $r0, $r0
// CHECK-NEXT: ;;
// CHECK-NEXT: ret
// CHECK-NEXT: ;;
// CHECK-NEXT: .global loop
// The ABI copy-out into the pinned return register is *not* here: the value
// was placed in $r0 already, so it was `copyd $r0 = $r0` and the identity
// sweep at the end of allocation removed it. That matters for more than code
// size -- an identity copy left in place still occupies a TINY slot, the
// resource that binds a bundle on this machine.
lvx_func.func @branches(%a: !lvx.reg<r0>, %cond: !lvx.reg<r1>) -> !lvx.reg<r0> {
  %ov = lvx.mv %a : (!lvx.reg<r0>) -> !lvx.reg
  %c = lvx.mv %cond : (!lvx.reg<r1>) -> !lvx.reg
  lvx_cf.cond_br wnez %c : !lvx.reg, ^bb1, ^bb2
^bb1:
  lvx_cf.br ^bb2
^bb2:
  %r = lvx.addd %ov, %ov : (!lvx.reg, !lvx.reg) -> !lvx.reg
  %p = lvx.mv %r : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %p : !lvx.reg<r0>
}

// A counted, constant-step-1 loop is eligible for the hardware-loop path
// (lvx-mlir/docs/HardwareLoops.md): a single `loopdo` replaces the
// compare+cond_br header entirely. `%trip` (r61) = ub - lb via `sbfd`;
// real `sbfd`/`sbfw`/`fsbfd`/`fsbfw` are "subtract FROM" opcodes --
// `sbfd $rd = $rs1, $rs2` computes `$rs2 - $rs1`, the reverse of every
// other binary op's `$rd = $rs1 op $rs2` reading (confirmed against
// lvx-mds's Description.yml and empirically on real gem5) -- so the
// *printed* operand order below is `lb, ub` even though the IR-level
// `lvx.sbfd` operands are `(ub, lb)`; see emitBinarySubtractFrom's comment
// in EmitAsm.cpp. The induction variable's explicit copy-in becomes a real (here,
// same-register, harmless) `copyd $r0 = $r0`. `loopdo`'s `body` successor
// is never printed as a jump target -- real hardware falls through to it
// -- and, critically, the body's own branch back to `exit` is *also*
// never printed: exit is the block immediately following body in emission
// order, so the fallthrough-elision rule applies, and here that's a
// correctness requirement, not just a cleanup -- an explicit `goto` there
// would override LOOPDO's implicit hardware back-edge and truncate the
// loop to one iteration regardless of trip count (see
// lvx-mlir/docs/HardwareLoops.md).
// CHECK-LABEL: loop:
// CHECK-NEXT: maked $r1 = 0
// CHECK-NEXT: ;;
// CHECK-NEXT: maked $r2 = 10
// CHECK-NEXT: ;;
// CHECK-NEXT: maked $r3 = 1
// CHECK-NEXT: ;;
// CHECK-NEXT: maked $r4 = 0
// CHECK-NEXT: ;;
// CHECK-NEXT: sbfd $r61 = $r1, $r2
// CHECK-NEXT: ;;
// The induction-variable copy-in is absent: both values landed in r0, so it
// was `copyd $r0 = $r0` and -lvx-scf-to-cf's identity sweep removed it --
// which also removes the bundle it was alone in.
// CHECK-NEXT: loopdo $r61, .LBB2
// CHECK-NEXT: ;;
// CHECK-NEXT: .LBB3:
// CHECK-NEXT: addd $r4 = $r4, $r0
// CHECK-NEXT: ;;
// CHECK-NEXT: addd $r1 = $r1, $r3
// CHECK-NEXT: ;;
// CHECK-NEXT: # end of hardware loop body -- LOOPDO back-edge is implicit
// CHECK-NEXT: .LBB2:
// The body's terminator is `lvx_cf.loopend`, which emits this comment and
// no instruction -- LOOPDO's back-edge is implicit, so a real `goto` here
// would override it and run the body exactly once.
// CHECK-NEXT: copyd $r0 = $r4
// CHECK-NEXT: ;;
// CHECK-NEXT: ret
// CHECK-NEXT: ;;
// CHECK-NEXT: .global divmod
lvx_func.func @loop(%a: !lvx.reg<r0>) -> !lvx.reg<r0> {
  %ov = lvx.mv %a : (!lvx.reg<r0>) -> !lvx.reg
  %lb = lvx.li 0 : i64 : !lvx.reg
  %ub = lvx.li 10 : i64 : !lvx.reg
  %step = lvx.li 1 : i64 : !lvx.reg
  %init = lvx.li 0 : i64 : !lvx.reg
  %r = lvx_scf.for %lb : !lvx.reg to %ub : !lvx.reg step %step : !lvx.reg iter_args(%init) : (!lvx.reg) -> (!lvx.reg) {
  ^bb0(%iv: !lvx.reg, %acc: !lvx.reg):
    %use = lvx.addd %acc, %ov : (!lvx.reg, !lvx.reg) -> !lvx.reg
    lvx_scf.yield %use : !lvx.reg
  }
  %p = lvx.mv %r : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %p : !lvx.reg<r0>
}

// `divmodd`'s destination is the real `registerM` pairedReg operand class,
// spelled `$r<even>r<odd>` with no separator (confirmed by hand-assembling
// with the real `lvx-mbr-as` and disassembling the result, and the
// low=quotient/high=remainder assignment confirmed by actually executing a
// `divmodd` on real gem5 -- lvx-mlir/docs/AssemblyEmission.md). The result
// is one `!lvx.pair`, allocated like any pair (r2r3 here: r0/r1 hold the
// copied-in arguments), and the quotient and remainder are `lvx.lane`
// views of it, which are the registers r2 and r3 and print nothing.
// CHECK-LABEL: divmod:
// CHECK-NEXT: divmodd $r0r1 = $r0, $r1
// CHECK-NEXT: ;;
// CHECK-NEXT: addd $r0 = $r0, $r1
// CHECK-NEXT: ;;
// CHECK-NEXT: ret
// CHECK-NEXT: ;;
// CHECK-NEXT: .global pairs
// The ABI copy-out into the pinned return register is *not* here: the value
// was placed in $r0 already, so it was `copyd $r0 = $r0` and the identity
// sweep at the end of allocation removed it. That matters for more than code
// size -- an identity copy left in place still occupies a TINY slot, the
// resource that binds a bundle on this machine.
lvx_func.func @divmod(%a: !lvx.reg<r0>, %b: !lvx.reg<r1>) -> !lvx.reg<r0> {
  %0 = lvx.mv %a : (!lvx.reg<r0>) -> !lvx.reg
  %1 = lvx.mv %b : (!lvx.reg<r1>) -> !lvx.reg
  %qr = lvx.divmodd %0, %1 : (!lvx.reg, !lvx.reg) -> !lvx.pair
  %q = lvx.lane %qr[0] : (!lvx.pair) -> !lvx.reg
  %r = lvx.lane %qr[1] : (!lvx.pair) -> !lvx.reg
  %sum = lvx.addd %q, %r : (!lvx.reg, !lvx.reg) -> !lvx.reg
  %p = lvx.mv %sum : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %p : !lvx.reg<r0>
}

// Pair ops print their tuple operands by primary name: `splatwq $r2r3 =
// $r1`, `lq`/`sq` with a pair, `ffmawq` with its tied accumulator dropped
// from the printed shape, and `lvx.mv` of a pair as `catdq` from the
// source's two lanes.
// CHECK-LABEL: pairs:
// CHECK-NEXT: splatwq $r2r3 = $r1
// CHECK-NEXT: ;;
// CHECK-NEXT: lq $r4r5 = 0[$r0]
// CHECK-NEXT: ;;
// CHECK-NEXT: lq $r6r7 = 16[$r0]
// CHECK-NEXT: ;;
// CHECK-NEXT: ffmawq $r4r5 = $r2r3, $r6r7
// CHECK-NEXT: ;;
// CHECK-NEXT: catdq $r2r3 = $r4, $r5
// CHECK-NEXT: ;;
// CHECK-NEXT: sq 0[$r0] = $r2r3
// CHECK-NEXT: ;;
// CHECK-NEXT: ret
// CHECK-NEXT: ;;
// CHECK-NEXT: .global composite
lvx_func.func @pairs(%base: !lvx.reg<r0>, %x: !lvx.reg<r1>) {
  %s = lvx.splatwq %x : (!lvx.reg<r1>) -> !lvx.pair
  %acc = lvx.lq %base, 0 : i64 : (!lvx.reg<r0>) -> !lvx.pair
  %v = lvx.lq %base, 16 : i64 : (!lvx.reg<r0>) -> !lvx.pair
  %f = lvx.ffmawq %s, %v, %acc : (!lvx.pair, !lvx.pair, !lvx.pair) -> !lvx.pair
  %c = lvx.mv %f : (!lvx.pair) -> !lvx.pair
  lvx.sq %c, %base, 0 : i64 : (!lvx.pair, !lvx.reg<r0>)
  lvx_func.return
}

// A composite (Builtin@split): `ffmawo` is `ffmawq` on each pair of its quad
// operands, printed as two instructions with one `;;` -- they issue together,
// which is what lets the result quad overlap the operands. The pair-typed
// splat is read whole by both parts; the accumulator is tied to the result,
// so it is not printed, and the allocator gave both the quad r4r5r6r7.
// CHECK-LABEL: composite:
// CHECK-NEXT: splatwq $r2r3 = $r1
// CHECK-NEXT: ;;
// CHECK-NEXT: lo $r4r5r6r7 = 0[$r0]
// CHECK-NEXT: ;;
// CHECK-NEXT: lo $r8r9r10r11 = 32[$r0]
// CHECK-NEXT: ;;
// CHECK-NEXT: ffmawq $r4r5 = $r2r3, $r8r9
// CHECK-NEXT: ffmawq $r6r7 = $r2r3, $r10r11
// CHECK-NEXT: ;;
// CHECK-NEXT: so 0[$r0] = $r4r5r6r7
// CHECK-NEXT: ;;
// CHECK-NEXT: ret
// CHECK-NEXT: ;;
// CHECK-NEXT: .global shuffles
lvx_func.func @composite(%base: !lvx.reg<r0>, %x: !lvx.reg<r1>) {
  %s = lvx.splatwq %x : (!lvx.reg<r1>) -> !lvx.pair
  %acc = lvx.lo %base, 0 : i64 : (!lvx.reg<r0>) -> !lvx.quad
  %v = lvx.lo %base, 32 : i64 : (!lvx.reg<r0>) -> !lvx.quad
  %f = lvx.ffmawo %s, %v, %acc : (!lvx.pair, !lvx.quad, !lvx.quad) -> !lvx.quad
  lvx.so %f, %base, 0 : i64 : (!lvx.quad, !lvx.reg<r0>)
  lvx_func.return
}

// The lane shuffles and the splat load: `lwso` fills a quad from one word
// in memory; `zipwdq` on the low singles and on the high singles of two
// pairs, placed by `lvx.concat` as the halves of one quad (no instruction);
// `evenwq`/`oddwq` on that quad's pairs (lane views, no instruction).
// CHECK-LABEL: shuffles:
// CHECK-NEXT: lwso $r4r5r6r7 = 0[$r0]
// CHECK-NEXT: ;;
// CHECK-NEXT: lq $r2r3 = 32[$r0]
// CHECK-NEXT: ;;
// CHECK-NEXT: zipwdq $r8r9 = $r4, $r2
// CHECK-NEXT: ;;
// CHECK-NEXT: zipwdq $r10r11 = $r5, $r3
// CHECK-NEXT: ;;
// CHECK-NEXT: so 64[$r0] = $r8r9r10r11
// CHECK-NEXT: ;;
// CHECK-NEXT: evenwq $r2r3 = $r8r9, $r10r11
// CHECK-NEXT: ;;
// CHECK-NEXT: oddwq $r4r5 = $r8r9, $r10r11
// CHECK-NEXT: ;;
// CHECK-NEXT: sq 96[$r0] = $r2r3
// CHECK-NEXT: ;;
// CHECK-NEXT: sq 112[$r0] = $r4r5
// CHECK-NEXT: ;;
// CHECK-NEXT: ret
// CHECK-NEXT: ;;
// CHECK-NEXT: .global ffma
lvx_func.func @shuffles(%base: !lvx.reg<r0>) {
  %s = lvx.lwso %base, 0 : i64 : (!lvx.reg<r0>) -> !lvx.quad
  %v = lvx.lq %base, 32 : i64 : (!lvx.reg<r0>) -> !lvx.pair
  %s0 = lvx.lane %s[0] : (!lvx.quad) -> !lvx.pair
  %a0 = lvx.lane %s0[0] : (!lvx.pair) -> !lvx.reg
  %b0 = lvx.lane %v[0] : (!lvx.pair) -> !lvx.reg
  %lo = lvx.zipwdq %a0, %b0 : (!lvx.reg, !lvx.reg) -> !lvx.pair
  %a1 = lvx.lane %s0[1] : (!lvx.pair) -> !lvx.reg
  %b1 = lvx.lane %v[1] : (!lvx.pair) -> !lvx.reg
  %hi = lvx.zipwdq %a1, %b1 : (!lvx.reg, !lvx.reg) -> !lvx.pair
  %q = lvx.concat %lo, %hi : (!lvx.pair, !lvx.pair) -> !lvx.quad
  lvx.so %q, %base, 64 : i64 : (!lvx.quad, !lvx.reg<r0>)
  %q0 = lvx.lane %q[0] : (!lvx.quad) -> !lvx.pair
  %q2 = lvx.lane %q[2] : (!lvx.quad) -> !lvx.pair
  %ev = lvx.evenwq %q0, %q2 : (!lvx.pair, !lvx.pair) -> !lvx.pair
  %od = lvx.oddwq %q0, %q2 : (!lvx.pair, !lvx.pair) -> !lvx.pair
  lvx.sq %ev, %base, 96 : i64 : (!lvx.pair, !lvx.reg<r0>)
  lvx.sq %od, %base, 112 : i64 : (!lvx.pair, !lvx.reg<r0>)
  lvx_func.return
}

// `ffmad`/`ffmsd`: real hardware has no separate destination register --
// the `c` operand and the result share one physical register in place
// (lvx-mlir/docs/RegisterAllocation.md, "`ffma`/`ffms` accumulator
// coalescing"). Two chained ops (`%5`'s result feeds `%6`'s `c`) confirm
// the whole chain coalesces to one register (`$r3` throughout) rather than
// each op getting an independent one.
// CHECK-LABEL: ffma:
// CHECK-NEXT: ffmad $r4 = $r0, $r1
// CHECK-NEXT: ;;
// CHECK-NEXT: ffmsd $r4 = $r2, $r3
// CHECK-NEXT: ;;
// CHECK-NEXT: copyd $r0 = $r4
// CHECK-NEXT: ;;
// CHECK-NEXT: ret
// CHECK-NEXT: ;;
// CHECK-NEXT: .global loop_step2
lvx_func.func @ffma(%a: !lvx.reg<r0>, %b: !lvx.reg<r1>, %c: !lvx.reg<r2>,
                    %d: !lvx.reg<r3>, %acc0: !lvx.reg<r4>) -> !lvx.reg<r0> {
  %0 = lvx.mv %a : (!lvx.reg<r0>) -> !lvx.reg
  %1 = lvx.mv %b : (!lvx.reg<r1>) -> !lvx.reg
  %2 = lvx.mv %c : (!lvx.reg<r2>) -> !lvx.reg
  %3 = lvx.mv %d : (!lvx.reg<r3>) -> !lvx.reg
  %4 = lvx.mv %acc0 : (!lvx.reg<r4>) -> !lvx.reg
  %5 = lvx.ffmad %0, %1, %4 : (!lvx.reg, !lvx.reg, !lvx.reg) -> !lvx.reg
  %6 = lvx.ffmsd %2, %3, %5 : (!lvx.reg, !lvx.reg, !lvx.reg) -> !lvx.reg
  %p = lvx.mv %6 : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %p : !lvx.reg<r0>
}

// A step-2 loop is a hardware loop (since 2026-10-16: any constant
// power-of-two step is eligible -- HardwareLoops.md). What this pins is the
// trip-count arithmetic reaching real assembly: `sbfd` gives ub - lb, then
// `addd` of step-1 and `srsd` by log2(step) make it ceil((ub-lb)/step) -- 10,
// 11, 5 here, which is the right trip count for 0..10 by 2. The spellings
// matter because the second RUN line feeds this to `lvx-mbr-as`.
// The copy-in is absent here too, and for the same reason.
// CHECK-LABEL: loop_step2:
// CHECK-NEXT: maked $r1 = 0
// CHECK-NEXT: ;;
// CHECK-NEXT: maked $r2 = 10
// CHECK-NEXT: ;;
// CHECK-NEXT: maked $r3 = 2
// CHECK-NEXT: ;;
// CHECK-NEXT: maked $r4 = 0
// CHECK-NEXT: ;;
// CHECK-NEXT: sbfd $r61 = $r1, $r2
// CHECK-NEXT: ;;
// CHECK-NEXT: addd $r61 = $r61, 1
// CHECK-NEXT: ;;
// CHECK-NEXT: srsd $r61 = $r61, 1
// CHECK-NEXT: ;;
// CHECK-NEXT: loopdo $r61, .LBB4
// CHECK-NEXT: ;;
// CHECK-NEXT: .LBB5:
// CHECK-NEXT: addd $r4 = $r4, $r0
// CHECK-NEXT: ;;
// CHECK-NEXT: addd $r1 = $r1, $r3
// CHECK-NEXT: ;;
// CHECK-NEXT: # end of hardware loop body
// CHECK-NEXT: .LBB4:
// CHECK-NEXT: copyd $r0 = $r4
// CHECK-NEXT: ;;
// CHECK-NEXT: ret
// CHECK-NEXT: ;;
// CHECK-NEXT: .global rounding
lvx_func.func @loop_step2(%a: !lvx.reg<r0>) -> !lvx.reg<r0> {
  %ov = lvx.mv %a : (!lvx.reg<r0>) -> !lvx.reg
  %lb = lvx.li 0 : i64 : !lvx.reg
  %ub = lvx.li 10 : i64 : !lvx.reg
  %step = lvx.li 2 : i64 : !lvx.reg
  %init = lvx.li 0 : i64 : !lvx.reg
  %r = lvx_scf.for %lb : !lvx.reg to %ub : !lvx.reg step %step : !lvx.reg iter_args(%init) : (!lvx.reg) -> (!lvx.reg) {
  ^bb0(%iv: !lvx.reg, %acc: !lvx.reg):
    %use = lvx.addd %acc, %ov : (!lvx.reg, !lvx.reg) -> !lvx.reg
    lvx_scf.yield %use : !lvx.reg
  }
  %p = lvx.mv %r : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %p : !lvx.reg<r0>
}

// -----

// The packed round-to-integral and square root, and the zeroing blend --
// all three print through the arity rule's default path rather than a case
// of their own, which is what has to be pinned here: the `floatmode`
// modifier rides on `withModifiers` (one of the four silent wrong answers
// Phase 6 found was exactly this modifier dropped at emission), and
// `blendz*` has no tied operand where `blend*` has one, so all three of its
// registers are printed.
// CHECK-LABEL: rounding:
// CHECK-NEXT: lq $r2r3 = 0[$r0]
// CHECK-NEXT: ;;
// CHECK-NEXT: froundwq.rd $r2r3 = $r2r3
// CHECK-NEXT: ;;
// CHECK-NEXT: blendzwq $r2r3 = $r2r3, $r1
// CHECK-NEXT: ;;
// CHECK-NEXT: sq 0[$r0] = $r2r3
// CHECK-NEXT: ;;
// CHECK-NEXT: lq $r2r3 = 16[$r0]
// CHECK-NEXT: ;;
// CHECK-NEXT: fsqrtdp $r2r3 = $r2r3
// CHECK-NEXT: ;;
// CHECK-NEXT: sq 16[$r0] = $r2r3
// CHECK-NEXT: ;;
// CHECK-NEXT: ret
// CHECK-NEXT: ;;
// CHECK-NEXT: .global splat_imm
lvx_func.func @rounding(%base: !lvx.reg<r0>, %mask: !lvx.reg<r1>) {
  %v = lvx.lq %base, 0 : i64 : (!lvx.reg<r0>) -> !lvx.pair
  %r = lvx.froundwq rd %v : (!lvx.pair) -> !lvx.pair
  %b = lvx.blendzwq %r, %mask : (!lvx.pair, !lvx.reg<r1>) -> !lvx.pair
  lvx.sq %b, %base, 0 : i64 : (!lvx.pair, !lvx.reg<r0>)
  %w = lvx.lq %base, 16 : i64 : (!lvx.reg<r0>) -> !lvx.pair
  %s = lvx.fsqrtdp %w : (!lvx.pair) -> !lvx.pair
  lvx.sq %s, %base, 16 : i64 : (!lvx.pair, !lvx.reg<r0>)
  lvx_func.return
}

// MAKEDP has no register operand, so the arity rule cannot reach it: zero
// printed operands and one result. It prints like `maked` at pair width,
// which is what it is. The second immediate is 7.0's f64 bit pattern --
// `-convert-to-lvx` bitcasts a float splat to its integer pattern here,
// because `.X`/`.Y` carry the full 64 bits.
// CHECK-LABEL: splat_imm:
// CHECK-NEXT: makedp $r2r3 = 7
// CHECK-NEXT: ;;
// CHECK-NEXT: makedp $r4r5 = 4619567317775286272
// CHECK-NEXT: ;;
// CHECK-NEXT: sq 0[$r0] = $r2r3
// CHECK-NEXT: ;;
// CHECK-NEXT: sq 16[$r0] = $r4r5
// CHECK-NEXT: ;;
// CHECK-NEXT: ret
// CHECK-NEXT: ;;
lvx_func.func @splat_imm(%base: !lvx.reg<r0>) {
  %i = lvx.makedp 7 : i64 : () -> !lvx.pair
  %f = lvx.makedp 4619567317775286272 : i64 : () -> !lvx.pair
  lvx.sq %i, %base, 0 : i64 : (!lvx.pair, !lvx.reg<r0>)
  lvx.sq %f, %base, 16 : i64 : (!lvx.pair, !lvx.reg<r0>)
  lvx_func.return
}
// A step of 3 is not a power of two, so it keeps the branch-based lowering --
// which is what still exercises the fallthrough-elision rule on the entry
// edge here (entry falls straight into the header with no printed `goto`).
// That coverage used to come from the step-2 case above, before a
// power-of-two step became a hardware loop.
// CHECK-LABEL: loop_step3:
// CHECK-NEXT: maked $r1 = 0
// CHECK-NEXT: ;;
// CHECK-NEXT: maked $r2 = 10
// CHECK-NEXT: ;;
// CHECK-NEXT: maked $r3 = 3
// CHECK-NEXT: ;;
// CHECK-NEXT: maked $r4 = 0
// CHECK-NEXT: ;;
// CHECK-NEXT: .LBB{{[0-9]+}}:
// CHECK-NEXT: compd.lt $r61 = $r1, $r2
// CHECK-NEXT: ;;
// CHECK-NEXT: cb.wnez $r61? .LBB{{[0-9]+}}
// CHECK-NEXT: ;;
// CHECK-NEXT: goto .LBB{{[0-9]+}}
// CHECK-NEXT: ;;
// CHECK-NEXT: .LBB{{[0-9]+}}:
// CHECK-NEXT: addd $r4 = $r4, $r0
// CHECK-NEXT: ;;
// CHECK-NEXT: addd $r1 = $r1, $r3
// CHECK-NEXT: ;;
// CHECK-NEXT: goto .LBB{{[0-9]+}}
// CHECK-NEXT: ;;
// CHECK-NEXT: .LBB{{[0-9]+}}:
// CHECK-NEXT: copyd $r0 = $r4
// CHECK-NEXT: ;;
// CHECK-NEXT: ret
// CHECK-NEXT: ;;
lvx_func.func @loop_step3(%a: !lvx.reg<r0>) -> !lvx.reg<r0> {
  %ov = lvx.mv %a : (!lvx.reg<r0>) -> !lvx.reg
  %lb = lvx.li 0 : i64 : !lvx.reg
  %ub = lvx.li 10 : i64 : !lvx.reg
  %step = lvx.li 3 : i64 : !lvx.reg
  %init = lvx.li 0 : i64 : !lvx.reg
  %r = lvx_scf.for %lb : !lvx.reg to %ub : !lvx.reg step %step : !lvx.reg iter_args(%init) : (!lvx.reg) -> (!lvx.reg) {
  ^bb0(%iv: !lvx.reg, %acc: !lvx.reg):
    %use = lvx.addd %acc, %ov : (!lvx.reg, !lvx.reg) -> !lvx.reg
    lvx_scf.yield %use : !lvx.reg
  }
  %p = lvx.mv %r : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %p : !lvx.reg<r0>
}
