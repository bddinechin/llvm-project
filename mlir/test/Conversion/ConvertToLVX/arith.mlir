// RUN: mlir-opt %s -convert-to-lvx | FileCheck %s

// CHECK-LABEL: lvx_func.func @arith_ops
func.func @arith_ops(%a: i64, %b: i64, %c: i32) -> i64 {
  // CHECK: lvx.addd
  %0 = arith.addi %a, %b : i64
  // CHECK: lvx.addw
  %1 = arith.addi %c, %c : i32
  // CHECK: lvx.muld
  %2 = arith.muli %a, %b : i64
  // CHECK: %{{.*}}, %{{.*}} = lvx.divmodd
  %3 = arith.divsi %a, %b : i64
  // CHECK: %{{.*}}, %{{.*}} = lvx.divmodd
  %4 = arith.remsi %a, %b : i64
  // CHECK: lvx.compd eq
  %5 = arith.cmpi eq, %a, %b : i64
  // CHECK: lvx.cmoved wnez
  // %0/%2 (not %a/%b) as the select operands avoids arith.select's builtin
  // "select(cmpi eq a,b, a, b) -> b" fold, which would eliminate the op
  // before ConvertToLVX ever sees it.
  %6 = arith.select %5, %0, %2 : i64
  return %6 : i64
}

// CHECK-LABEL: lvx_func.func @float_ops
func.func @float_ops(%a: f64, %b: f64) -> f64 {
  // CHECK: lvx.faddd
  %0 = arith.addf %a, %b : f64
  // CHECK: lvx.fcompd olt
  %1 = arith.cmpf olt, %a, %b : f64
  // CHECK: lvx.fcompd olt
  // CHECK-SAME: %{{[0-9]+}}, %{{[0-9]+}}
  %2 = arith.cmpf ogt, %a, %b : f64
  // CHECK: lvx.li
  %c0 = arith.constant 0.0 : f64
  // CHECK: lvx.fsbfd
  %3 = arith.negf %a : f64
  return %0 : f64
}

// CHECK-LABEL: lvx_func.func @casts
// All intermediate results below are threaded into the final return value:
// results that are truly dead get eliminated before ConvertToLVX runs
// (arith ops are Pure), which would otherwise make several of these CHECKs
// spuriously match unrelated, later `lvx.mv`/etc. ops instead of failing.
func.func @casts(%a: i8, %b: i32, %c: f64) -> i64 {
  // CHECK: lvx.sxbd
  %0 = arith.extsi %a : i8 to i64
  // CHECK: lvx.zxwd
  %1 = arith.extui %b : i32 to i64
  // CHECK: lvx.mv
  // Truncate %0 (sign-extended from i8), not %1 (zero-extended from i32):
  // trunci-of-an-extui-back-to-its-original-width is a standard arith fold
  // that would eliminate this op entirely before ConvertToLVX runs.
  %2 = arith.trunci %0 : i64 to i32
  %trunc64 = arith.extui %2 : i32 to i64
  // CHECK: lvx.fdtofw
  %3 = arith.truncf %c : f64 to f32
  // CHECK: lvx.fwtofd
  %4 = arith.extf %3 : f32 to f64
  // CHECK: lvx.sitofp
  %5 = arith.sitofp %a : i8 to f64
  %6 = arith.addf %4, %5 : f64
  // CHECK: lvx.fptosi
  %7 = arith.fptosi %6 : f64 to i64
  %8 = arith.addi %0, %1 : i64
  %9 = arith.addi %8, %trunc64 : i64
  %10 = arith.addi %9, %7 : i64
  return %10 : i64
}
