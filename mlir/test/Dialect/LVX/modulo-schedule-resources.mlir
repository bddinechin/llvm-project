// The resource rows of RCMS's model, on a loop whose loads oversubscribe the
// LSU in a resource-free schedule (SoftwarePipelining.md §8, step 6).
//
// DSP puts all three loads in one row of the II = 2 kernel -- three LSU
// reservations against two -- and leaves `-lvx-schedule` to repair it. The
// integer program has a row per (resource, residue), so its schedule fits
// the modulo reservation table, and the framework checks that it does: an
// RCMS answer that does not is refused, as DSP's would be.
//
// RUN: mlir-opt %s --pass-pipeline='builtin.module(any(lvx-modulo-schedule{engine=dsp}))' | FileCheck %s --check-prefix=DSP
// RUN: rm -rf %t.dir && mkdir -p %t.dir
// RUN: printf '#!/bin/sh\necho "STATUS INFEASIBLE" > "$2"\n' > %t.infeasible && chmod +x %t.infeasible
// RUN: mlir-opt %s --pass-pipeline='builtin.module(any(lvx-modulo-schedule{engine=rcms rcms-solver=%t.infeasible rcms-dir=%t.dir}))' -o /dev/null 2>&1
// RUN: FileCheck %s --check-prefix=MODEL < %t.dir/wide.0.ii2.lp
//
// The schedule GLPK finds for that model (validation/cms/rcms-glpk):
// RUN: printf '#!/bin/sh\nprintf "STATUS OPTIMAL\\nx_0_0 1\\nx_1_1 1\\nx_2_1 1\\nx_3_2 1\\nx_4_4 1\\nx_5_4 1\\nx_6_5 1\\n" > "$2"\n' > %t.rcms && chmod +x %t.rcms
// RUN: mlir-opt %s --pass-pipeline='builtin.module(any(lvx-modulo-schedule{engine=rcms fallback=false rcms-solver=%t.rcms}))' 2>&1 | FileCheck %s --check-prefix=RCMS
//
// DSP's dates, handed back as though a solver had found them:
// RUN: printf '#!/bin/sh\nprintf "STATUS OPTIMAL\\nx_0_0 1\\nx_1_1 1\\nx_2_1 1\\nx_3_1 1\\nx_4_4 1\\nx_5_4 1\\nx_6_5 1\\n" > "$2"\n' > %t.dsp && chmod +x %t.dsp
// RUN: mlir-opt %s --pass-pipeline='builtin.module(any(lvx-modulo-schedule{engine=rcms fallback=false rcms-solver=%t.dsp}))' 2>&1 | FileCheck %s --check-prefix=REFUSED

// DSP: lvx.ld {{.*}}lvx.date = 1
// DSP: lvx.ld {{.*}}lvx.date = 1
// DSP: lvx.ld {{.*}}lvx.date = 1
// DSP: lvx.ii = 2

// MODEL: \ RCMS fn=wide ii=2 n=7 horizon=8
// MODEL:  res_tiny_0: + 1 x_0_0 + 1 x_0_2 + 1 x_1_2 + 1 x_1_4 + 1 x_2_2 + 1 x_3_2 + 1 x_3_4 + 1 x_4_4 + 1 x_4_6 + 1 x_5_4 + 1 x_5_6 + 1 x_6_6 <= 4
// MODEL:  res_tiny_1: + 1 x_0_1 + 1 x_1_1 + 1 x_1_3 + 1 x_2_1 + 1 x_2_3 + 1 x_3_1 + 1 x_3_3 + 1 x_4_5 + 1 x_4_7 + 1 x_5_5 + 1 x_6_5 + 1 x_6_7 <= 4
// MODEL:  res_lsu_0: + 1 x_1_2 + 1 x_1_4 + 1 x_2_2 + 1 x_3_2 + 1 x_3_4 <= 2
// MODEL:  res_lsu_1: + 1 x_1_1 + 1 x_1_3 + 1 x_2_1 + 1 x_2_3 + 1 x_3_1 + 1 x_3_3 <= 2
// MODEL:  res_auxw_0: + 1 x_1_2 + 1 x_1_4 + 1 x_2_2 + 1 x_3_2 + 1 x_3_4 <= 2
// MODEL:  res_auxw_1: + 1 x_1_1 + 1 x_1_3 + 1 x_2_1 + 1 x_2_3 + 1 x_3_1 + 1 x_3_3 <= 2

// RCMS-NOT: remark
// RCMS: lvx.ld {{.*}}lvx.date = 1
// RCMS: lvx.ld {{.*}}lvx.date = 1
// RCMS: lvx.ld {{.*}}lvx.date = 2
// RCMS: lvx.ii = 2

// REFUSED: remark: not software-pipelined: no period from 2 to 10 is accepted
// REFUSED-SAME: lsu oversubscribed
// REFUSED-NOT: lvx.ii
lvx_func.func @wide(%base: !lvx.reg<r0>) -> !lvx.reg<r0> {
  %lo = lvx.li 0 : i64 : !lvx.reg
  %hi = lvx.li 64 : i64 : !lvx.reg
  %st = lvx.li 1 : i64 : !lvx.reg
  %z = lvx.li 0 : i64 : !lvx.reg
  %r:2 = lvx_scf.for %lo : !lvx.reg to %hi : !lvx.reg step %st : !lvx.reg
       iter_args(%z, %z) : (!lvx.reg, !lvx.reg) -> (!lvx.reg, !lvx.reg) {
  ^bb0(%i: !lvx.reg, %a: !lvx.reg, %b: !lvx.reg):
    %p = lvx.addx8d %i, %base : (!lvx.reg, !lvx.reg<r0>) -> !lvx.reg
    %v = lvx.ld %p, 0 : i64 : (!lvx.reg) -> !lvx.reg
    %w = lvx.ld %p, 8 : i64 : (!lvx.reg) -> !lvx.reg
    %x = lvx.ld %p, 16 : i64 : (!lvx.reg) -> !lvx.reg
    %s = lvx.addd %a, %v : (!lvx.reg, !lvx.reg) -> !lvx.reg
    %t = lvx.addd %b, %w : (!lvx.reg, !lvx.reg) -> !lvx.reg
    %u = lvx.addd %t, %x : (!lvx.reg, !lvx.reg) -> !lvx.reg
    lvx_scf.yield %s, %u : !lvx.reg, !lvx.reg
  }
  %o = lvx.addd %r#0, %r#1 : (!lvx.reg, !lvx.reg) -> !lvx.reg
  %out = lvx.mv %o : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %out : !lvx.reg<r0>
}
