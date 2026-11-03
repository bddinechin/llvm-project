// RUN: mlir-opt %s | mlir-opt | FileCheck %s
// RUN: mlir-opt %s --mlir-print-op-generic | mlir-opt | FileCheck %s

// The structured early exits (docs/SoftwarePipelining.md, section 8 step 2c):
// upstream #166688's loop/break/if, in lvx_scf.

// A loop with no results, left from an if and at its end.
// CHECK-LABEL: func @bare
// CHECK:       lvx_scf.loop token(%[[L:.*]]) {
// CHECK-NEXT:    lvx_scf.if wnez %{{.*}} : !lvx.reg {
// CHECK-NEXT:      lvx_scf.break [%[[L]]]
// CHECK-NEXT:    }
// CHECK-NEXT:    lvx_scf.break [%[[L]]]
// CHECK-NEXT:  }
lvx_func.func @bare(%t: !lvx.reg) {
  lvx_scf.loop token(%L) {
    lvx_scf.if wnez %t : !lvx.reg {
      lvx_scf.break [%L]
    }
    lvx_scf.break [%L]
  }
  lvx_func.return
}

// The remainder's shape: each exit computes its own values and leaves with
// them; falling through an if continues the straight line.
// CHECK-LABEL: func @exits
// CHECK:       %[[R:.*]]:2 = lvx_scf.loop token(%[[L:.*]]) -> (!lvx.reg, !lvx.reg) {
// CHECK:         lvx_scf.if deqz %{{.*}} : !lvx.reg {
// CHECK:           lvx_scf.break [%[[L]]] %{{.*}}, %{{.*}} : !lvx.reg, !lvx.reg
// CHECK-NEXT:    }
// CHECK:         lvx_scf.if dnez %{{.*}} : !lvx.reg {
// CHECK-NEXT:      lvx.addd
// CHECK-NEXT:    }
// CHECK:         lvx_scf.break [%[[L]]] %{{.*}}, %{{.*}} : !lvx.reg, !lvx.reg
// CHECK:       lvx_func.return %[[R]]#0, %[[R]]#1
lvx_func.func @exits(%a: !lvx.reg, %b: !lvx.reg, %n: !lvx.reg) -> (!lvx.reg, !lvx.reg) {
  %r:2 = lvx_scf.loop token(%L) -> (!lvx.reg, !lvx.reg) {
    %x = lvx.addd %a, %b : (!lvx.reg, !lvx.reg) -> !lvx.reg
    lvx_scf.if deqz %n : !lvx.reg {
      %d = lvx.addd %x, %x : (!lvx.reg, !lvx.reg) -> !lvx.reg
      lvx_scf.break [%L] %d, %x : !lvx.reg, !lvx.reg
    }
    lvx_scf.if dnez %x : !lvx.reg {
      %u = lvx.addd %x, %a : (!lvx.reg, !lvx.reg) -> !lvx.reg
    }
    %y = lvx.addd %x, %a : (!lvx.reg, !lvx.reg) -> !lvx.reg
    lvx_scf.break [%L] %y, %x : !lvx.reg, !lvx.reg
  }
  lvx_func.return %r#0, %r#1 : !lvx.reg, !lvx.reg
}

// A break leaves several levels at once: through two ifs, and past an inner
// loop to the outer one.
// CHECK-LABEL: func @nested
// CHECK:       lvx_scf.loop token(%[[OUTER:.*]]) -> (!lvx.reg) {
// CHECK:         lvx_scf.loop token(%[[INNER:.*]]) {
// CHECK:           lvx_scf.if wnez
// CHECK-NEXT:        lvx_scf.if weqz
// CHECK-NEXT:          lvx_scf.break [%[[OUTER]]] %{{.*}} : !lvx.reg
// CHECK:           lvx_scf.break [%[[INNER]]]
// CHECK:         lvx_scf.break [%[[OUTER]]] %{{.*}} : !lvx.reg
lvx_func.func @nested(%a: !lvx.reg, %t: !lvx.reg) -> !lvx.reg {
  %r = lvx_scf.loop token(%outer) -> (!lvx.reg) {
    lvx_scf.loop token(%inner) {
      lvx_scf.if wnez %t : !lvx.reg {
        lvx_scf.if weqz %a : !lvx.reg {
          lvx_scf.break [%outer] %a : !lvx.reg
        }
      }
      lvx_scf.break [%inner]
    }
    lvx_scf.break [%outer] %t : !lvx.reg
  }
  lvx_func.return %r : !lvx.reg
}

// An inner loop's body may end by leaving the outer one.
// CHECK-LABEL: func @outer_end
// CHECK:       lvx_scf.loop token(%[[OUTER:.*]]) {
// CHECK-NEXT:    lvx_scf.loop token(%{{.*}}) {
// CHECK-NEXT:      lvx_scf.break [%[[OUTER]]]
lvx_func.func @outer_end() {
  lvx_scf.loop token(%outer) {
    lvx_scf.loop token(%inner) {
      lvx_scf.break [%outer]
    }
    lvx_scf.break [%outer]
  }
  lvx_func.return
}
