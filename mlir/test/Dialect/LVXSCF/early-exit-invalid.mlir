// RUN: mlir-opt %s -split-input-file -verify-diagnostics

lvx_func.func @types(%a: !lvx.reg) {
  lvx_scf.loop token(%L) -> (!lvx.reg) {
    // expected-error @+1 {{carries 0 value(s) of types  but the loop's results are '!lvx.reg'}}
    lvx_scf.break [%L]
  }
  lvx_func.return
}

// -----

lvx_func.func @pair(%a: !lvx.reg) {
  %r = lvx_scf.loop token(%L) -> (!lvx.pair) {
    // expected-error @+1 {{carries 1 value(s) of types '!lvx.reg' but the loop's results are '!lvx.pair'}}
    lvx_scf.break [%L] %a : !lvx.reg
  }
  lvx_func.return
}

// -----

lvx_func.func @through_for(%lb: !lvx.reg, %ub: !lvx.reg, %s: !lvx.reg) {
  lvx_scf.loop token(%L) {
    lvx_scf.for %lb : !lvx.reg to %ub : !lvx.reg step %s : !lvx.reg {
    ^bb0(%iv: !lvx.reg):
      lvx_scf.if wnez %iv : !lvx.reg {
        // expected-error @+1 {{may only leave its loop through lvx_scf.if and lvx_scf.loop, not lvx_scf.for}}
        lvx_scf.break [%L]
      }
      lvx_scf.yield
    }
    lvx_scf.break [%L]
  }
  lvx_func.return
}

// -----

lvx_func.func @if_values(%t: !lvx.reg) {
  lvx_scf.if wnez %t : !lvx.reg {
    // expected-error @+1 {{in an lvx_scf.if carries no values}}
    lvx_scf.yield %t : !lvx.reg
  }
  lvx_func.return
}

// -----

lvx_func.func @cond(%t: !lvx.reg) {
  // expected-error @+1 {{expected a BcuCond, got 'never'}}
  lvx_scf.if never %t : !lvx.reg {
  }
  lvx_func.return
}
