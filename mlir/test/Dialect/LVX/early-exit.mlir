// RUN: mlir-opt %s --pass-pipeline='builtin.module(any(lvx-allocate-registers),any(lvx-scf-to-cf))' | FileCheck %s --check-prefix=CF
// RUN: mlir-opt %s --pass-pipeline='builtin.module(any(lvx-allocate-registers),any(lvx-scf-to-cf),any(lvx-schedule),lvx-emit-asm)' -o /dev/null | FileCheck %s --check-prefix=ASM
// RUN: %if lvx-mbr-as %{ mlir-opt %s --pass-pipeline='builtin.module(any(lvx-allocate-registers),any(lvx-scf-to-cf),any(lvx-schedule),lvx-emit-asm)' -o /dev/null 2>/dev/null | %lvx_mbr_as - -o %t.o %} %else %{ true %}

// The structured early exits through allocation, bundling and lowering
// (docs/SoftwarePipelining.md, section 8 step 2c). Three ways out of one
// loop: n == 0 gives 3a, n == 1 gives 2a, anything else 4a.
//
// What the allocator must get right: `%x` is live after the first exit and
// broken out by the second, and the straight line computes `%y` while `%x`
// is still live -- so the break values cannot simply share the result's
// register, and each break operand is a copy of its own
// (`insertBreakCopies`). Every break then forwards exactly the register of
// the continuation's argument, which -lvx-emit-asm checks.

// CF-LABEL: lvx_func.func @exits
// CF:         lvx_cf.br ^bb1
// CF-NEXT:  ^bb1:
// CF:         lvx_cf.cond_br dnez %{{.*}}, ^bb3, ^bb2
// CF-NEXT:  ^bb2:
// CF:         lvx_cf.br ^[[CONT:bb[0-9]+]](%{{.*}} : !lvx.reg<[[R:r[0-9]+]]>)
// CF-NEXT:  ^bb3:
// CF:         lvx_cf.cond_br dnez %{{.*}}, ^bb5, ^bb4
// CF-NEXT:  ^bb4:
// CF:         lvx_cf.br ^[[CONT]](%{{.*}} : !lvx.reg<[[R]]>)
// CF-NEXT:  ^bb5:
// CF:         lvx_cf.br ^[[CONT]](%{{.*}} : !lvx.reg<[[R]]>)
// CF-NEXT:  ^[[CONT]](%{{.*}}: !lvx.reg<[[R]]>):
// CF:         lvx_func.return

// The first exit's test falls through into its drain; each drain jumps to
// the continuation, and the last falls through to it.
// ASM-LABEL: exits:
// ASM:         cb.dnez $r{{[0-9]+}}? [[SKIP1:\.L[A-Za-z0-9_]+]]
// ASM:         goto [[CONT:\.L[A-Za-z0-9_]+]]
// ASM:       [[SKIP1]]:
// ASM:         cb.dnez $r{{[0-9]+}}? [[SKIP2:\.L[A-Za-z0-9_]+]]
// ASM:         goto [[CONT]]
// ASM:       [[SKIP2]]:
// ASM-NOT:     goto
// ASM:       [[CONT]]:
// ASM:         ret
lvx_func.func @exits(%n: !lvx.reg<r0>, %a: !lvx.reg<r1>) -> !lvx.reg<r0> {
  %n0 = lvx.mv %n : (!lvx.reg<r0>) -> !lvx.reg
  %a0 = lvx.mv %a : (!lvx.reg<r1>) -> !lvx.reg
  %r = lvx_scf.loop token(%L) -> (!lvx.reg) {
    %x = lvx.addd %a0, %a0 : (!lvx.reg, !lvx.reg) -> !lvx.reg
    lvx_scf.if deqz %n0 : !lvx.reg {
      %d = lvx.addd %x, %a0 : (!lvx.reg, !lvx.reg) -> !lvx.reg
      lvx_scf.break [%L] %d : !lvx.reg
    }
    %m = lvx.addd_i %n0, -1 : i64 : (!lvx.reg) -> !lvx.reg
    lvx_scf.if deqz %m : !lvx.reg {
      lvx_scf.break [%L] %x : !lvx.reg
    }
    %y = lvx.addd %x, %x : (!lvx.reg, !lvx.reg) -> !lvx.reg
    lvx_scf.break [%L] %y : !lvx.reg
  }
  %p = lvx.mv %r : (!lvx.reg) -> !lvx.reg<r0>
  lvx_func.return %p : !lvx.reg<r0>
}
