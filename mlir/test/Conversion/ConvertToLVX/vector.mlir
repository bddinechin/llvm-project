// RUN: mlir-opt %s -convert-to-lvx | FileCheck %s

// The vector ops the ISA has a register-pair instruction for (lvx-mds/docs/
// MLIR-backend-design.md §8.7): vector<4xf32> and vector<2xf64> are
// !lvx.pair, and the four ops lower one-to-one. The pair crosses the loop
// as an lvx_scf.for iter_arg.

// CHECK-LABEL: lvx_func.func @axpy4
// CHECK: %[[S:.*]] = lvx.splatwq %{{.*}} : (!lvx.reg) -> !lvx.pair
// CHECK: %[[X:.*]] = lvx.lq %{{.*}}, 0 : i64 : (!lvx.reg) -> !lvx.pair
// CHECK: %[[Y:.*]] = lvx.lq %{{.*}}, 0 : i64 : (!lvx.reg) -> !lvx.pair
// CHECK: %[[F:.*]] = lvx.ffmawq %[[S]], %[[X]], %[[Y]] : (!lvx.pair, !lvx.pair, !lvx.pair) -> !lvx.pair
// CHECK: lvx.sq %[[F]], %{{.*}}, 0 : i64 : (!lvx.pair, !lvx.reg)
func.func @axpy4(%a: f32, %x: memref<8xf32>, %y: memref<8xf32>, %i: index) {
  %av = vector.broadcast %a : f32 to vector<4xf32>
  %xv = vector.load %x[%i] : memref<8xf32>, vector<4xf32>
  %yv = vector.load %y[%i] : memref<8xf32>, vector<4xf32>
  %r = vector.fma %av, %xv, %yv : vector<4xf32>
  vector.store %r, %y[%i] : memref<8xf32>, vector<4xf32>
  return
}

// CHECK-LABEL: lvx_func.func @axpy2
// CHECK: lvx.splatdq %{{.*}} : (!lvx.reg) -> !lvx.pair
// CHECK: lvx.ffmadp %{{.*}} : (!lvx.pair, !lvx.pair, !lvx.pair) -> !lvx.pair
func.func @axpy2(%a: f64, %x: memref<8xf64>, %y: memref<8xf64>, %i: index) {
  %av = vector.broadcast %a : f64 to vector<2xf64>
  %xv = vector.load %x[%i] : memref<8xf64>, vector<2xf64>
  %yv = vector.load %y[%i] : memref<8xf64>, vector<2xf64>
  %r = vector.fma %av, %xv, %yv : vector<2xf64>
  vector.store %r, %y[%i] : memref<8xf64>, vector<2xf64>
  return
}

// A quad is a 256-bit vector: lo/so, no arithmetic (the ISA has none).
// CHECK-LABEL: lvx_func.func @copy8
// CHECK: %[[Q:.*]] = lvx.lo %{{.*}}, 0 : i64 : (!lvx.reg) -> !lvx.quad
// CHECK: lvx.so %[[Q]], %{{.*}}, 0 : i64 : (!lvx.quad, !lvx.reg)
func.func @copy8(%x: memref<8xf32>, %y: memref<8xf32>, %i: index) {
  %v = vector.load %x[%i] : memref<8xf32>, vector<8xf32>
  vector.store %v, %y[%i] : memref<8xf32>, vector<8xf32>
  return
}

// The accumulator of a reduction loop is a pair-typed iter_arg.
// CHECK-LABEL: lvx_func.func @dot_rows
// CHECK: %[[INIT:.*]] = lvx.lq
// CHECK: lvx_scf.for %{{.*}} : !lvx.reg to %{{.*}} : !lvx.reg step %{{.*}} : !lvx.reg iter_args(%[[INIT]]) : (!lvx.pair) -> (!lvx.pair)
// CHECK-NEXT: ^bb0(%{{.*}}: !lvx.reg, %[[ACC:.*]]: !lvx.pair):
// CHECK: %[[F:.*]] = lvx.ffmawq %{{.*}}, %{{.*}}, %[[ACC]]
// CHECK: lvx_scf.yield %[[F]] : !lvx.pair
func.func @dot_rows(%A: memref<4x8xf32>, %B: memref<8x4xf32>, %C: memref<4x4xf32>, %i: index) {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %c8 = arith.constant 8 : index
  %init = vector.load %C[%i, %c0] : memref<4x4xf32>, vector<4xf32>
  %acc = scf.for %k = %c0 to %c8 step %c1 iter_args(%a = %init) -> (vector<4xf32>) {
    %s = memref.load %A[%i, %k] : memref<4x8xf32>
    %sv = vector.broadcast %s : f32 to vector<4xf32>
    %bv = vector.load %B[%k, %c0] : memref<8x4xf32>, vector<4xf32>
    %f = vector.fma %sv, %bv, %a : vector<4xf32>
    scf.yield %f : vector<4xf32>
  }
  vector.store %acc, %C[%i, %c0] : memref<4x4xf32>, vector<4xf32>
  return
}
