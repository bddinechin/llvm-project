// The modulo scheduling framework with each engine (SoftwarePipelining.md §8,
// step 6). The solver is a stand-in written here, so the test runs with none
// installed: what it checks is the framework's half -- the model written, the
// answer read, verified and accepted or refused -- not a solver's.
//
// RUN: mlir-opt %s --pass-pipeline='builtin.module(any(lvx-modulo-schedule{engine=dsp annotate-period=true}))' | FileCheck %s --check-prefix=DSP
//
// No solver configured: every II refused, and DSP's schedule taken.
// RUN: mlir-opt %s --pass-pipeline='builtin.module(any(lvx-modulo-schedule{engine=rcms}))' 2>&1 | FileCheck %s --check-prefix=NONE
//
// A solver that proves every II infeasible, with and without the fallback;
// the models are kept, and the first is the formulation checked below.
// RUN: rm -rf %t.dir && mkdir -p %t.dir
// RUN: printf '#!/bin/sh\necho "STATUS INFEASIBLE" > "$2"\n' > %t.infeasible && chmod +x %t.infeasible
// RUN: mlir-opt %s --pass-pipeline='builtin.module(any(lvx-modulo-schedule{engine=rcms fallback=false rcms-solver=%t.infeasible rcms-dir=%t.dir}))' 2>&1 | FileCheck %s --check-prefix=INFEASIBLE
// RUN: FileCheck %s --check-prefix=MODEL < %t.dir/sum.0.ii1.lp
// RUN: ls %t.dir | FileCheck %s --check-prefix=KEPT
//
// A solver that answers UNKNOWN is not a proof: the remark says so.
// RUN: printf '#!/bin/sh\necho "STATUS UNKNOWN" > "$2"\n' > %t.unknown && chmod +x %t.unknown
// RUN: mlir-opt %s --pass-pipeline='builtin.module(any(lvx-modulo-schedule{engine=rcms fallback=false rcms-solver=%t.unknown}))' 2>&1 | FileCheck %s --check-prefix=UNKNOWN
//
// A solver that answers with a schedule: accepted, and the dates are its.
// RUN: printf '#!/bin/sh\nprintf "STATUS OPTIMAL\\nx_0_0 1\\nx_1_1 1\\nx_2_16 1\\nx_3_0 1\\nk_0 1\\n" > "$2"\n' > %t.optimal && chmod +x %t.optimal
// RUN: mlir-opt %s --pass-pipeline='builtin.module(any(lvx-modulo-schedule{engine=rcms fallback=false rcms-solver=%t.optimal}))' 2>&1 | FileCheck %s --check-prefix=OPTIMAL
//
// A solver whose answer breaks an arc: refused by the framework, never built.
// RUN: printf '#!/bin/sh\nprintf "STATUS OPTIMAL\\nx_0_0 1\\nx_1_1 1\\nx_2_2 1\\nx_3_0 1\\n" > "$2"\n' > %t.wrong && chmod +x %t.wrong
// RUN: mlir-opt %s --pass-pipeline='builtin.module(any(lvx-modulo-schedule{engine=rcms fallback=false rcms-solver=%t.wrong}))' 2>&1 | FileCheck %s --check-prefix=WRONG

// A fifteen-cycle `.u` load feeding an accumulation: RecMII 1 (the add's
// own recurrence), ResMII 1, so the ladder starts at II = 1.

// DSP-LABEL: lvx_func.func @sum
// DSP: lvx.addx8d {{.*}}lvx.date = 0
// DSP: lvx.ld {{.*}}lvx.date = 1
// DSP: lvx.addd {{.*}}lvx.date = 16
// DSP: lvx.ii = 1 : i64, lvx.period = 1 : i64}

// NONE: remark: rcms found no schedule (rcms at II = 9: no solver configured (rcms-solver=)); dsp's is taken
// NONE: lvx.ii = 1

// INFEASIBLE: remark: not software-pipelined: no period from 1 to 9 is accepted; the last refusal: rcms at II = 9: infeasible at this II (proved)
// INFEASIBLE-NOT: lvx.ii

// The model at II = 1: the MCRL objective, each value weighted by its width;
// one assignment row per node; the flow arcs as aggregated dependence rows;
// the lifetimes, the accumulator's carrying its iteration distance. Node 3 is
// the induction's increment, which the body reads through the address and
// the kernel materialises: one `addd` an iteration, charged here.
// MODEL: \ RCMS fn=sum ii=1 n=4 horizon=18
// MODEL-NEXT: Minimize
// MODEL-NEXT: obj: + 1 k_0 + 1 k_1 + 1 k_2 + 1 k_3 -1 x_0_1 -1 x_1_1 -2 x_1_2 -16 x_2_16 -17 x_2_17 -1 x_3_1
// MODEL-NEXT: Subject To
// MODEL-NEXT: asg_0: + x_0_0 + x_0_1 = 1
// MODEL-NEXT: asg_1: + x_1_1 + x_1_2 = 1
// MODEL-NEXT: asg_2: + x_2_16 + x_2_17 = 1
// MODEL-NEXT: asg_3: + x_3_0 + x_3_1 = 1
// MODEL-NEXT: dep_0: +1 x_0_1 -1 x_1_1 -2 x_1_2 <= -1
// MODEL-NEXT: dep_2: +1 x_1_1 +2 x_1_2 -16 x_2_16 -17 x_2_17 <= -15
// MODEL-NEXT: dep_3: +1 x_3_1 -1 x_0_1 <= 0
// MODEL-NEXT: life_0: k_0 -1 x_1_1 -2 x_1_2 >= 0
// MODEL-NEXT: life_1: k_2 -16 x_2_16 -17 x_2_17 >= 1
// MODEL-NEXT: life_2: k_1 -16 x_2_16 -17 x_2_17 >= 0
// MODEL-NEXT: life_3: k_3 -1 x_0_1 >= 1
// MODEL-NEXT: life_4: k_3 -1 x_3_1 >= 1
// MODEL-NEXT: Bounds
// MODEL-NEXT: 0 <= k_0 <= 20
// MODEL-NEXT: 0 <= k_1 <= 20
// MODEL-NEXT: 0 <= k_2 <= 20
// MODEL-NEXT: 0 <= k_3 <= 20
// MODEL-NEXT: General
// MODEL-NEXT: k_0
// MODEL-NEXT: k_1
// MODEL-NEXT: k_2
// MODEL-NEXT: k_3
// MODEL-NEXT: Binaries
// MODEL-NEXT: x_0_0
// MODEL-NEXT: x_0_1
// MODEL-NEXT: x_1_1
// MODEL-NEXT: x_1_2
// MODEL-NEXT: x_2_16
// MODEL-NEXT: x_2_17
// MODEL-NEXT: x_3_0
// MODEL-NEXT: x_3_1
// MODEL-NEXT: End

// KEPT: sum.0.ii1.lp
// KEPT: sum.0.ii1.lp.sol

// UNKNOWN: the last refusal: rcms at II = 9: the solver returned no answer (unknown)

// OPTIMAL-NOT: remark
// OPTIMAL: lvx.addx8d {{.*}}lvx.date = 0
// OPTIMAL: lvx.ld {{.*}}lvx.date = 1
// OPTIMAL: lvx.addd {{.*}}lvx.date = 16
// OPTIMAL: lvx.ii = 1 : i64, lvx.keep_dates

// WRONG: remark: not software-pipelined: no period from 1 to 9 is accepted
// WRONG-NOT: lvx.ii
lvx_func.func @sum(%base: !lvx.reg<r0>) -> !lvx.reg<r0> {
  %lo = lvx.li 0 : i64 : !lvx.reg
  %hi = lvx.li 64 : i64 : !lvx.reg
  %st = lvx.li 1 : i64 : !lvx.reg
  %z = lvx.li 0 : i64 : !lvx.reg
  %r = lvx_scf.for %lo : !lvx.reg to %hi : !lvx.reg step %st : !lvx.reg
       iter_args(%z) : (!lvx.reg) -> (!lvx.reg) {
  ^bb0(%i: !lvx.reg, %a: !lvx.reg):
    %p = lvx.addx8d %i, %base : (!lvx.reg, !lvx.reg<r0>) -> !lvx.reg
    %v = lvx.ld %p, 0 : i64 {variant = 2 : i64} : (!lvx.reg) -> !lvx.reg
    %s = lvx.addd %a, %v : (!lvx.reg, !lvx.reg) -> !lvx.reg
    lvx_scf.yield %s : !lvx.reg
  }
  %out = lvx.mv %r : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %out : !lvx.reg<r0>
}
