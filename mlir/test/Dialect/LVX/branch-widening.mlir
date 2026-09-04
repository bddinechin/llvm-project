// RUN: mlir-opt %s | mlir-opt | FileCheck %s
// RUN: mlir-opt %s -lvx-emit-asm | FileCheck %s --check-prefix=ASM

// Design document O3. `cb`/`cbx`, `ccb`/`ccbx`, `goto`/`gotox` and
// `call`/`callx` are the same operation with a wider pc-relative
// displacement -- their formats are `BCU_CB` and `BCU_CB.X`, exactly the
// relationship `ALU_DWRI` and `ALU_DWRI.X` have for `addd` -- so the widened
// form is a `format = x` attribute, not a second op.
//
// The attribute is the ONE place a format reaches the printed mnemonic. On
// an arithmetic op it does not: all four `addd` encodings share one mnemonic
// and the assembler picks from the immediate. Branches are not relaxed --
// `cb` to a target 600 KB away is "Error: branch out of range" from the real
// lvx-mbr-as, while `cbx`, `callx` and `gotox` assemble -- so here the
// attribute decides what is printed.

lvx_func.func private @callee(!lvx.reg<r0>) -> !lvx.reg<r0>

lvx_func.func @wide(%c: !lvx.reg<r5>, %a: !lvx.reg<r0>) -> !lvx.reg<r0> {
  lvx_cf.cond_br wnez %c : !lvx.reg<r5>, ^far, ^body x
^body:
  %r = lvx_func.call @callee(%a) x : (!lvx.reg<r0>) -> !lvx.reg<r0>
  lvx_func.return %r : !lvx.reg<r0>
^far:
  lvx_cf.br ^body x
}

// The attribute round-trips as a keyword. It is spelled in the assembly
// format rather than left to attr-dict, which cannot parse a specialized
// enum attribute without a dialect hook this dialect does not have.
// CHECK-LABEL: lvx_func.func @wide
// CHECK:         lvx_cf.cond_br wnez %{{.*}}, ^bb{{[0-9]}}, ^bb{{[0-9]}} x
// CHECK:         lvx_func.call @callee(%{{.*}}) x :
// CHECK:         lvx_cf.br ^bb{{[0-9]}} x

// ASM: cbx.wnez $r5? .LBB
// ASM: callx callee
// ASM: gotox .LBB

// Absent means the near form, which is every other test in this directory.
lvx_func.func @near(%c: !lvx.reg<r5>, %a: !lvx.reg<r0>) -> !lvx.reg<r0> {
  lvx_cf.cond_br wnez %c : !lvx.reg<r5>, ^other, ^body
^body:
  %r = lvx_func.call @callee(%a) : (!lvx.reg<r0>) -> !lvx.reg<r0>
  lvx_func.return %r : !lvx.reg<r0>
^other:
  lvx_cf.br ^body
}
// CHECK-LABEL: lvx_func.func @near
// CHECK:         lvx_cf.cond_br wnez %{{.*}}, ^bb{{[0-9]}}, ^bb{{[0-9]}}{{$}}
// ASM: cb.wnez $r5? .LBB
// ASM: call callee
// ASM: goto .LBB
