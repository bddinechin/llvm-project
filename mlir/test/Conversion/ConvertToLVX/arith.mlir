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
  // `arith.negf` lowered to `0.0 - x` until fnegd existed, which is wrong on
  // a signed zero: IEEE gives 0.0 - 0.0 = +0.0, where negating +0.0 must
  // give -0.0. fnegd flips the sign bit, exact for zeros and NaNs.
  // CHECK: lvx.fnegd
  // CHECK-NOT: lvx.fsbfd
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

// `math.fma a, b, c` is `a*b + c`, matching real FFMAD/FFMAW's operand order
// with `c` as the accumulator. Width dispatch is the usual f64 -> `d`,
// f32 -> `w`. Nothing lowers a separate mulf+addf pair to an ffma: fusing
// rounds once where the pair rounds twice, so it must be asked for.
// CHECK-LABEL: lvx_func.func @fma_ops
func.func @fma_ops(%a: f64, %b: f64, %c: f64, %x: f32, %y: f32, %z: f32) -> f64 {
  // CHECK: lvx.ffmad
  %0 = math.fma %a, %b, %c : f64
  // CHECK: lvx.ffmaw
  %1 = math.fma %x, %y, %z : f32
  // A mulf/addf pair stays two instructions.
  // CHECK: lvx.fmuld
  // CHECK: lvx.faddd
  %2 = arith.mulf %a, %b : f64
  %3 = arith.addf %c, %2 : f64
  return %0 : f64
}

// The scalar FP ops added 2026-08-05. Two things are worth asserting beyond
// "it lowers": that min/max pick the right *family*, and that the
// round-to-integral ops pick the right rounding modifier -- both are
// invisible on ordinary inputs and only show up on NaNs or halfway cases.
//
//   arith.minimumf  IEEE-2019 minimum, propagates NaN  -> fmind
//   arith.minnumf   IEEE-2008 minNum, returns non-NaN  -> fminnd
//
// CHECK-LABEL: lvx_func.func @fp_scalar
func.func @fp_scalar(%a: f64, %b: f64, %x: f32, %y: f32) -> f64 {
  // CHECK: lvx.fmind
  %0 = arith.minimumf %a, %b : f64
  // CHECK: lvx.fminnd
  %1 = arith.minnumf %a, %b : f64
  // CHECK: lvx.fmaxd
  %2 = arith.maximumf %0, %1 : f64
  // CHECK: lvx.fmaxnd
  %3 = arith.maxnumf %2, %b : f64
  // CHECK: lvx.fsqrtd
  %4 = math.sqrt %3 : f64
  // CHECK: lvx.fabsd
  %5 = math.absf %4 : f64
  // CHECK: lvx.fnegd
  %6 = arith.negf %5 : f64
  // One instruction, five modifiers: rd=floor, ru=ceil, rn=roundeven,
  // rz=trunc, and rm ("ties to max magnitude") = round-half-away-from-zero,
  // which is what math.round means -- not rn.
  // CHECK: lvx.frintd rd
  %7 = math.floor %6 : f64
  // CHECK: lvx.frintd ru
  %8 = math.ceil %7 : f64
  // CHECK: lvx.frintd rn
  %9 = math.roundeven %8 : f64
  // CHECK: lvx.frintd rz
  %10 = math.trunc %9 : f64
  // CHECK: lvx.frintd rm
  %11 = math.round %10 : f64
  // 32-bit forms go to the `w` instructions. Distinct operands on purpose:
  // `minimumf %x, %x` folds to %x upstream, before any conversion pattern
  // sees it (same trap CLAUDE.md notes for select/trunci).
  // CHECK: lvx.fminw
  %12 = arith.minimumf %x, %y : f32
  // CHECK: lvx.fsqrtw
  %13 = math.sqrt %12 : f32
  %14 = arith.extf %13 : f32 to f64
  %15 = arith.addf %11, %14 : f64
  return %15 : f64
}
