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
// RUN: mlir-opt %s --pass-pipeline='builtin.module(any(lvx-modulo-schedule{engine=rcms fallback=false rcms-solver=%t.infeasible rcms-dir=%t.dir rcms-deps=aggregated}))' 2>&1 | FileCheck %s --check-prefix=INFEASIBLE
// RUN: FileCheck %s --check-prefix=MODEL < %t.dir/sum.0.ii1.lp
// RUN: ls %t.dir | FileCheck %s --check-prefix=KEPT
// The same model disaggregated, the default: lvx-gcc's text, row for row.
// RUN: rm -rf %t.ddir && mkdir -p %t.ddir
// RUN: mlir-opt %s --pass-pipeline='builtin.module(any(lvx-modulo-schedule{engine=rcms fallback=false rcms-solver=%t.infeasible rcms-dir=%t.ddir}))' -o /dev/null 2>&1
// RUN: FileCheck %s --check-prefix=DISAGG < %t.ddir/sum.0.ii1.lp
// MMRP then MCRL, aggregated dependences: the killers are time-indexed for
// the pressure rows, the summed value -- read after the loop -- has an exit
// arc from every node, and R is weighted above any MCRL.
// RUN: rm -rf %t.pdir && mkdir -p %t.pdir
// RUN: mlir-opt %s --pass-pipeline='builtin.module(any(lvx-modulo-schedule{engine=rcms fallback=false rcms-solver=%t.infeasible rcms-dir=%t.pdir rcms-objective=4 rcms-deps=aggregated}))' -o /dev/null 2>&1
// RUN: FileCheck %s --check-prefix=MMRP < %t.pdir/sum.1.ii2.lp
// The solver's R must be the dates' pressure under MMRP, and a bound on R
// holds under any objective.
// RUN: printf '#!/bin/sh\nprintf "STATUS OPTIMAL\\nx_0_0 1\\nx_1_1 1\\nx_2_16 1\\nx_3_0 1\\nR 99\\n" > "$2"\n' > %t.r99 && chmod +x %t.r99
// RUN: mlir-opt %s --pass-pipeline='builtin.module(any(lvx-modulo-schedule{engine=rcms fallback=false rcms-solver=%t.r99 rcms-objective=3}))' 2>&1 | FileCheck %s --check-prefix=RMISMATCH
// RUN: mlir-opt %s --pass-pipeline='builtin.module(any(lvx-modulo-schedule{engine=rcms fallback=false rcms-solver=%t.r99 rcms-max-pressure=1}))' 2>&1 | FileCheck %s --check-prefix=RBOUND
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
// An answer inside every window that breaks dependence 0 (both dates 1): the
// check reads the rows as written, so it is named per form.
// RUN: printf '#!/bin/sh\nprintf "STATUS OPTIMAL\\nx_0_1 1\\nx_1_1 1\\nx_2_16 1\\nx_3_0 1\\n" > "$2"\n' > %t.row && chmod +x %t.row
// RUN: mlir-opt %s --pass-pipeline='builtin.module(any(lvx-modulo-schedule{engine=rcms fallback=false rcms-solver=%t.row}))' 2>&1 | FileCheck %s --check-prefix=ROWD
// RUN: mlir-opt %s --pass-pipeline='builtin.module(any(lvx-modulo-schedule{engine=rcms fallback=false rcms-solver=%t.row rcms-deps=aggregated}))' 2>&1 | FileCheck %s --check-prefix=ROWA

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
// Disaggregated (LAO's default): a dependence i -> j of latency L is a row
// per date t, `i at t or later` and `j before t + L` not both; the killer
// is a time-indexed node with an assignment row, and each flow arc i -> j
// is the arc j -> killer(i) of latency II*omega, written the same way.
// Rows with an empty sum never bind and are not written; no General section.
// DISAGG: \ RCMS fn=sum ii=1 n=4 horizon=18
// DISAGG-NEXT: Minimize
// DISAGG-NEXT: obj: +1 k_0_1 +2 k_0_2 +16 k_1_16 +17 k_1_17 +17 k_2_17 +18 k_2_18 +1 k_3_1 +2 k_3_2 -1 x_0_1 -1 x_1_1 -2 x_1_2 -16 x_2_16 -17 x_2_17 -1 x_3_1
// DISAGG-NEXT: Subject To
// DISAGG-NEXT: asg_0: + x_0_0 + x_0_1 = 1
// DISAGG-NEXT: asg_1: + x_1_1 + x_1_2 = 1
// DISAGG-NEXT: asg_2: + x_2_16 + x_2_17 = 1
// DISAGG-NEXT: asg_3: + x_3_0 + x_3_1 = 1
// DISAGG-NEXT: dep_0_1: + x_0_1 + x_1_1 <= 1
// DISAGG-NEXT: dep_2_2: + x_1_2 + x_2_16 <= 1
// DISAGG-NEXT: dep_3_1: + x_3_1 + x_0_0 <= 1
// DISAGG-NEXT: kasg_0: + k_0_1 + k_0_2 = 1
// DISAGG-NEXT: kasg_1: + k_1_16 + k_1_17 = 1
// DISAGG-NEXT: kasg_2: + k_2_17 + k_2_18 = 1
// DISAGG-NEXT: kasg_3: + k_3_1 + k_3_2 = 1
// DISAGG-NEXT: life_0_2: + x_1_2 + k_0_1 <= 1
// DISAGG-NEXT: life_1_17: + x_2_17 + k_2_17 <= 1
// DISAGG-NEXT: life_2_17: + x_2_17 + k_1_16 <= 1
// DISAGG-NEXT: life_3_1: + x_0_1 + k_3_1 <= 1
// DISAGG-NEXT: life_4_1: + x_3_1 + k_3_1 <= 1
// DISAGG-NEXT: Bounds
// DISAGG-NEXT: Binaries
// DISAGG-NEXT: x_0_0
// DISAGG-NEXT: x_0_1
// DISAGG-NEXT: x_1_1
// DISAGG-NEXT: x_1_2
// DISAGG-NEXT: x_2_16
// DISAGG-NEXT: x_2_17
// DISAGG-NEXT: x_3_0
// DISAGG-NEXT: x_3_1
// DISAGG-NEXT: k_0_1
// DISAGG-NEXT: k_0_2
// DISAGG-NEXT: k_1_16
// DISAGG-NEXT: k_1_17
// DISAGG-NEXT: k_2_17
// DISAGG-NEXT: k_2_18
// DISAGG-NEXT: k_3_1
// DISAGG-NEXT: k_3_2
// DISAGG-NEXT: End

// The pressure rows: one per residue, a value live in cycle c iff
// date + write <= c <= killer (the kernel allocator's interval), the
// flowing value's killer arcs carrying the reader's read cycle.
// MMRP: \ RCMS fn=sum ii=2 n=4 horizon=19
// MMRP-NEXT: Minimize
// MMRP-NEXT: obj: + 89 R +2 k_0_2 +3 k_0_3 +4 k_0_4 +17 k_1_17 +18 k_1_18 +19 k_1_19 +19 k_2_19 +20 k_2_20 +21 k_2_21 +3 k_3_3 +4 k_3_4 +5 k_3_5 +6 k_3_6 -1 x_0_1 -2 x_0_2 -1 x_1_1 -2 x_1_2 -3 x_1_3 -16 x_2_16 -17 x_2_17 -18 x_2_18 -1 x_3_1 -2 x_3_2 -3 x_3_3
// MMRP-NEXT: Subject To
// MMRP-NEXT: asg_0: + x_0_0 + x_0_1 + x_0_2 = 1
// MMRP-NEXT: asg_1: + x_1_1 + x_1_2 + x_1_3 = 1
// MMRP-NEXT: asg_2: + x_2_16 + x_2_17 + x_2_18 = 1
// MMRP-NEXT: asg_3: + x_3_0 + x_3_1 + x_3_2 + x_3_3 = 1
// MMRP-NEXT: dep_0: +1 x_0_1 +2 x_0_2 -1 x_1_1 -2 x_1_2 -3 x_1_3 <= -1
// MMRP-NEXT: dep_2: +1 x_1_1 +2 x_1_2 +3 x_1_3 -16 x_2_16 -17 x_2_17 -18 x_2_18 <= -15
// MMRP-NEXT: dep_3: +1 x_3_1 +2 x_3_2 +3 x_3_3 -1 x_0_1 -2 x_0_2 <= 1
// MMRP-NEXT: kasg_0: + k_0_2 + k_0_3 + k_0_4 = 1
// MMRP-NEXT: kasg_1: + k_1_17 + k_1_18 + k_1_19 = 1
// MMRP-NEXT: kasg_2: + k_2_19 + k_2_20 + k_2_21 = 1
// MMRP-NEXT: kasg_3: + k_3_3 + k_3_4 + k_3_5 + k_3_6 = 1
// MMRP-NEXT: life_0: +2 k_0_2 +3 k_0_3 +4 k_0_4 -1 x_1_1 -2 x_1_2 -3 x_1_3 >= 1
// MMRP-NEXT: life_1: +19 k_2_19 +20 k_2_20 +21 k_2_21 -16 x_2_16 -17 x_2_17 -18 x_2_18 >= 3
// MMRP-NEXT: life_2: +17 k_1_17 +18 k_1_18 +19 k_1_19 -16 x_2_16 -17 x_2_17 -18 x_2_18 >= 1
// MMRP-NEXT: life_3: +3 k_3_3 +4 k_3_4 +5 k_3_5 +6 k_3_6 -1 x_0_1 -2 x_0_2 >= 3
// MMRP-NEXT: life_4: +3 k_3_3 +4 k_3_4 +5 k_3_5 +6 k_3_6 -1 x_3_1 -2 x_3_2 -3 x_3_3 >= 3
// MMRP-NEXT: exit_2_0: +19 k_2_19 +20 k_2_20 +21 k_2_21 -1 x_0_1 -2 x_0_2 >= 2
// MMRP-NEXT: exit_2_1: +19 k_2_19 +20 k_2_20 +21 k_2_21 -1 x_1_1 -2 x_1_2 -3 x_1_3 >= 2
// MMRP-NEXT: exit_2_2: +19 k_2_19 +20 k_2_20 +21 k_2_21 -16 x_2_16 -17 x_2_17 -18 x_2_18 >= 2
// MMRP-NEXT: exit_2_3: +19 k_2_19 +20 k_2_20 +21 k_2_21 -1 x_3_1 -2 x_3_2 -3 x_3_3 >= 2
// MMRP-NEXT: press_0: +11 x_0_0 +10 x_0_1 +10 x_0_2 -10 k_0_2 -10 k_0_3 -9 k_0_4 +3 x_1_1 +3 x_1_2 +2 x_1_3 -3 k_1_17 -2 k_1_18 -2 k_1_19 +3 x_2_16 +2 x_2_17 +2 x_2_18 -2 k_2_19 -1 k_2_20 -1 k_2_21 +11 x_3_0 +10 x_3_1 +10 x_3_2 +9 x_3_3 -10 k_3_3 -9 k_3_4 -9 k_3_5 -8 k_3_6 - R <= 0
// MMRP-NEXT: press_1: +11 x_0_0 +11 x_0_1 +10 x_0_2 -11 k_0_2 -10 k_0_3 -10 k_0_4 +4 x_1_1 +3 x_1_2 +3 x_1_3 -3 k_1_17 -3 k_1_18 -2 k_1_19 +3 x_2_16 +3 x_2_17 +2 x_2_18 -2 k_2_19 -2 k_2_20 -1 k_2_21 +11 x_3_0 +11 x_3_1 +10 x_3_2 +10 x_3_3 -10 k_3_3 -10 k_3_4 -9 k_3_5 -9 k_3_6 - R <= 0
// MMRP-NEXT: Bounds
// MMRP-NEXT: 0 <= R <= 64
// MMRP-NEXT: General
// MMRP-NEXT: R
// MMRP-NEXT: Binaries
// MMRP-NEXT: x_0_0
// MMRP-NEXT: x_0_1
// MMRP-NEXT: x_0_2
// MMRP-NEXT: x_1_1
// MMRP-NEXT: x_1_2
// MMRP-NEXT: x_1_3
// MMRP-NEXT: x_2_16
// MMRP-NEXT: x_2_17
// MMRP-NEXT: x_2_18
// MMRP-NEXT: x_3_0
// MMRP-NEXT: x_3_1
// MMRP-NEXT: x_3_2
// MMRP-NEXT: x_3_3
// MMRP-NEXT: k_0_2
// MMRP-NEXT: k_0_3
// MMRP-NEXT: k_0_4
// MMRP-NEXT: k_1_17
// MMRP-NEXT: k_1_18
// MMRP-NEXT: k_1_19
// MMRP-NEXT: k_2_19
// MMRP-NEXT: k_2_20
// MMRP-NEXT: k_2_21
// MMRP-NEXT: k_3_3
// MMRP-NEXT: k_3_4
// MMRP-NEXT: k_3_5
// MMRP-NEXT: k_3_6
// MMRP-NEXT: End

// RMISMATCH: the solution breaks the model: its register pressure is 3, the solver's R 99
// RBOUND: the solution breaks the model: register pressure 3 above 1

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

// ROWD: the solution breaks the model: disaggregated dependence 0 violated
// ROWA: the solution breaks the model: dependence 0 violated
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
