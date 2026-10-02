// If-conversion runs on the branch form, after -convert-to-lvx: a store's
// address arithmetic does not exist before the lowering, so converting
// earlier would guard three pure ops along with the store. See
// lvx-mlir/docs/IfConversion.md.
// RUN: mlir-opt %s -convert-scf-to-cf -convert-to-lvx -lvx-combine -cse \
// RUN:   -lvx-if-convert -split-input-file | FileCheck %s
// RUN: mlir-opt %s -convert-scf-to-cf -convert-to-lvx -lvx-combine -cse \
// RUN:   -lvx-if-convert=max-guarded=1 -split-input-file \
// RUN:   | FileCheck %s --check-prefix=ONE

// A store under a branch becomes a guarded store: the branch is gone and the
// one instruction left carries the condition. The address arithmetic the
// lowering put beside the store is hoisted out of the guard -- it is free to
// speculate, so it costs no prefix syllable.
// CHECK-LABEL: @then_only
// CHECK-NOT: lvx_cf.cond_br
// CHECK: lvx.guarded wnez %{{.*}} : !lvx.reg {
// CHECK-NEXT: lvx.sq
// CHECK-NEXT: }
// ONE-LABEL: @then_only
// ONE: lvx.guarded wnez
func.func @then_only(%a: memref<4xi32>, %b: memref<4xi32>, %c: i1) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<4xi32>, vector<4xi32>
  scf.if %c {
    vector.store %x, %b[%i] : memref<4xi32>, vector<4xi32>
  }
  return
}

// -----

// Both arms, on one register and with no inversion: `wnez` for the arm the
// branch tested and `weqz` for the other. Every BcuCond has a complement --
// the ISA pairs them adjacently in the encoding -- so the else-arm costs no
// extra compare and no `not`.
//
// The arms store at *different widths* on purpose. `-lvx-combine`'s region
// simplification merges two blocks holding the same sequence of ops before
// this pass runs, promoting every operand they differ in to a block argument
// -- so symmetric arms never reach here, however different their operands.
// That is the right division of labour (one block plus phis is the select
// shape, and a select is one instruction) and it means the `max-guarded`
// budget is only ever spent on arms that genuinely differ. To test both arms
// the op sequences have to differ, not just the values.
// CHECK-LABEL: @both_arms
// CHECK-NOT: lvx_cf.cond_br
// CHECK: lvx.guarded wnez %[[C:.*]] : !lvx.reg {
// CHECK: lvx.guarded weqz %[[C]] : !lvx.reg {
// Two to guard, so max-guarded=1 keeps the branch.
// ONE-LABEL: @both_arms
// ONE: lvx_cf.cond_br
// ONE-NOT: lvx.guarded
func.func @both_arms(%a: memref<4xi32>, %b: memref<4xi32>, %c: i1) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<4xi32>, vector<4xi32>
  %k = arith.constant 7 : i32
  scf.if %c {
    vector.store %x, %b[%i] : memref<4xi32>, vector<4xi32>
  } else {
    memref.store %k, %b[%i] : memref<4xi32>
  }
  return
}

// -----

// Speculate what is free (lvx-gcc CE3's rule): the packed add has no memory
// effect and cannot trap, so it runs unconditionally, outside the guard. Only
// the store is left, which is what makes `lvx.guarded`'s no-results
// restriction cheap rather than crippling.
// CHECK-LABEL: @speculate_free
// CHECK: lvx.addwq
// CHECK-NOT: lvx_cf.cond_br
// CHECK: lvx.guarded wnez
// CHECK-NEXT: lvx.sq
// ONE-LABEL: @speculate_free
// ONE: lvx.guarded wnez
func.func @speculate_free(%a: memref<4xi32>, %b: memref<4xi32>, %c: i1) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<4xi32>, vector<4xi32>
  scf.if %c {
    %s = arith.addi %x, %x : vector<4xi32>
    vector.store %s, %b[%i] : memref<4xi32>, vector<4xi32>
  }
  return
}

// -----

// A value flowing out of the arms is a phi at the join, which is a select and
// not a guard: `arith.select` is one `cmoved`/`blend*`, strictly better than
// predicating both arms. The pass leaves the branch alone -- whether the two
// arms were merged into one block with an argument (`trueDest == falseDest`)
// or kept apart (the join takes arguments), both are declines.
//
// An `i32` rather than a vector: returning a `vector<4xi32>` fails to
// legalize for an unrelated reason -- the result side of the ABI pins one
// register for a pair -- and this test is not about that.
// CHECK-LABEL: @has_result
// CHECK: lvx_cf.cond_br
// CHECK-NOT: lvx.guarded
// ONE-LABEL: @has_result
// ONE: lvx_cf.cond_br
func.func @has_result(%a: memref<4xi32>, %c: i1) -> i32 {
  %i = arith.constant 0 : index
  %x = memref.load %a[%i] : memref<4xi32>
  %r = scf.if %c -> i32 {
    scf.yield %x : i32
  } else {
    %z = arith.constant 0 : i32
    scf.yield %z : i32
  }
  return %r : i32
}

// -----

// A load in the arm is neither free to speculate (it may fault, which is often
// exactly why the branch is there) nor result-less, so the branch stays. A
// guarded load needs `lvx.guarded` to yield, which it does not.
// CHECK-LABEL: @guarded_load
// CHECK: lvx_cf.cond_br
// CHECK-NOT: lvx.guarded
// ONE-LABEL: @guarded_load
// ONE: lvx_cf.cond_br
func.func @guarded_load(%a: memref<4xi32>, %b: memref<4xi32>, %c: i1) {
  %i = arith.constant 0 : index
  scf.if %c {
    %x = vector.load %a[%i] : memref<4xi32>, vector<4xi32>
    vector.store %x, %b[%i] : memref<4xi32>, vector<4xi32>
  }
  return
}

// -----

// Five stores: past `max-guarded` (4), so the branch is kept. A guarded op
// occupies its slot in every bundle the arm spans whether the condition holds
// or not, which is what the bound is about.
// CHECK-LABEL: @too_long
// CHECK: lvx_cf.cond_br
// CHECK-NOT: lvx.guarded
// ONE-LABEL: @too_long
// ONE: lvx_cf.cond_br
func.func @too_long(%b: memref<32xi32>, %c: i1) {
  %v = arith.constant dense<1> : vector<4xi32>
  %i0 = arith.constant 0 : index
  %i1 = arith.constant 4 : index
  %i2 = arith.constant 8 : index
  %i3 = arith.constant 12 : index
  %i4 = arith.constant 16 : index
  scf.if %c {
    vector.store %v, %b[%i0] : memref<32xi32>, vector<4xi32>
    vector.store %v, %b[%i1] : memref<32xi32>, vector<4xi32>
    vector.store %v, %b[%i2] : memref<32xi32>, vector<4xi32>
    vector.store %v, %b[%i3] : memref<32xi32>, vector<4xi32>
    vector.store %v, %b[%i4] : memref<32xi32>, vector<4xi32>
  }
  return
}
