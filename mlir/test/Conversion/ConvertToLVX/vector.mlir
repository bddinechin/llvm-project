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

// Eight lanes: the composite `ffmawo` (Builtin@split), one op over the quad
// whose two halves are `ffmawq`. The broadcast operand stays a pair splat --
// the composite's parts read a pair-typed source whole.
// CHECK-LABEL: lvx_func.func @axpy8
// CHECK: %[[X:.*]] = lvx.lo %{{.*}}, 0 : i64 : (!lvx.reg) -> !lvx.quad
// CHECK: %[[Y:.*]] = lvx.lo %{{.*}}, 0 : i64 : (!lvx.reg) -> !lvx.quad
// CHECK: %[[S:.*]] = lvx.splatwq %{{.*}} : (!lvx.reg) -> !lvx.pair
// CHECK: %[[F:.*]] = lvx.ffmawo %[[S]], %[[X]], %[[Y]] : (!lvx.pair, !lvx.quad, !lvx.quad) -> !lvx.quad
// CHECK: lvx.so %[[F]], %{{.*}}, 0 : i64 : (!lvx.quad, !lvx.reg)
func.func @axpy8(%a: f32, %x: memref<16xf32>, %y: memref<16xf32>, %i: index) {
  %av = vector.broadcast %a : f32 to vector<8xf32>
  %xv = vector.load %x[%i] : memref<16xf32>, vector<8xf32>
  %yv = vector.load %y[%i] : memref<16xf32>, vector<8xf32>
  %r = vector.fma %av, %xv, %yv : vector<8xf32>
  vector.store %r, %y[%i] : memref<16xf32>, vector<8xf32>
  return
}

// A broadcast of a loaded element to a quad is one `lwso` (lvx-2: load a
// lane, splat it across the quad), not `lwz` + `splatwq`; the composite
// reads the quad half by half. The load's own conversion (`lwz`) is left
// dead for -lvx-combine's driver to drop.
// CHECK-LABEL: lvx_func.func @axpy8_from_memory
// CHECK: %[[S:.*]] = lvx.lwso %{{.*}}, 0 : i64 : (!lvx.reg) -> !lvx.quad
// CHECK: %[[X:.*]] = lvx.lo %{{.*}}, 0 : i64 : (!lvx.reg) -> !lvx.quad
// CHECK: %[[Y:.*]] = lvx.lo %{{.*}}, 0 : i64 : (!lvx.reg) -> !lvx.quad
// CHECK-NOT: lvx.splatwq
// CHECK: lvx.ffmawo %[[S]], %[[X]], %[[Y]] : (!lvx.quad, !lvx.quad, !lvx.quad) -> !lvx.quad
func.func @axpy8_from_memory(%a: memref<4xf32>, %x: memref<16xf32>, %y: memref<16xf32>, %i: index) {
  %c0 = arith.constant 0 : index
  %s = memref.load %a[%c0] : memref<4xf32>
  %av = vector.broadcast %s : f32 to vector<8xf32>
  %xv = vector.load %x[%i] : memref<16xf32>, vector<8xf32>
  %yv = vector.load %y[%i] : memref<16xf32>, vector<8xf32>
  %r = vector.fma %av, %xv, %yv : vector<8xf32>
  vector.store %r, %y[%i] : memref<16xf32>, vector<8xf32>
  return
}

// The same element broadcast to a pair stays a load and a splat: there is
// no `lwsq`.
// CHECK-LABEL: lvx_func.func @axpy4_from_memory
// CHECK: %[[S:.*]] = lvx.lwz %{{.*}}, 0 : i64 : (!lvx.reg) -> !lvx.reg
// CHECK: lvx.splatwq %[[S]] : (!lvx.reg) -> !lvx.pair
func.func @axpy4_from_memory(%a: memref<4xf32>, %x: memref<16xf32>, %y: memref<16xf32>, %i: index) {
  %c0 = arith.constant 0 : index
  %s = memref.load %a[%c0] : memref<4xf32>
  %av = vector.broadcast %s : f32 to vector<4xf32>
  %xv = vector.load %x[%i] : memref<16xf32>, vector<4xf32>
  %yv = vector.load %y[%i] : memref<16xf32>, vector<4xf32>
  %r = vector.fma %av, %xv, %yv : vector<4xf32>
  vector.store %r, %y[%i] : memref<16xf32>, vector<4xf32>
  return
}

// The lane shuffles: `vector.interleave` of two pairs is `zipwdq` on the
// low singles and on the high singles, side by side in a quad
// (`lvx.concat`); `vector.deinterleave` of a quad is `evenwq`/`oddwq` on
// its two pairs. Double-word lanes zip with `catdq` and unzip with
// `evendq`/`odddq`.
// CHECK-LABEL: lvx_func.func @shuffle32
// CHECK: %[[X:.*]] = lvx.lq
// CHECK: %[[Y:.*]] = lvx.lq
// CHECK: %[[X0:.*]] = lvx.lane %[[X]][0] : (!lvx.pair) -> !lvx.reg
// CHECK: %[[Y0:.*]] = lvx.lane %[[Y]][0] : (!lvx.pair) -> !lvx.reg
// CHECK: %[[LO:.*]] = lvx.zipwdq %[[X0]], %[[Y0]] : (!lvx.reg, !lvx.reg) -> !lvx.pair
// CHECK: %[[X1:.*]] = lvx.lane %[[X]][1] : (!lvx.pair) -> !lvx.reg
// CHECK: %[[Y1:.*]] = lvx.lane %[[Y]][1] : (!lvx.pair) -> !lvx.reg
// CHECK: %[[HI:.*]] = lvx.zipwdq %[[X1]], %[[Y1]] : (!lvx.reg, !lvx.reg) -> !lvx.pair
// CHECK: %[[Z:.*]] = lvx.concat %[[LO]], %[[HI]] : (!lvx.pair, !lvx.pair) -> !lvx.quad
// CHECK: %[[Z0:.*]] = lvx.lane %[[Z]][0] : (!lvx.quad) -> !lvx.pair
// CHECK: %[[Z2:.*]] = lvx.lane %[[Z]][2] : (!lvx.quad) -> !lvx.pair
// CHECK: %[[EV:.*]] = lvx.evenwq %[[Z0]], %[[Z2]] : (!lvx.pair, !lvx.pair) -> !lvx.pair
// CHECK: %[[OD:.*]] = lvx.oddwq %[[Z0]], %[[Z2]] : (!lvx.pair, !lvx.pair) -> !lvx.pair
// CHECK: lvx.sq %[[EV]]
// CHECK: lvx.sq %[[OD]]
func.func @shuffle32(%a: memref<4xf32>, %b: memref<4xf32>, %d: memref<4xf32>, %e: memref<4xf32>) {
  %c0 = arith.constant 0 : index
  %x = vector.load %a[%c0] : memref<4xf32>, vector<4xf32>
  %y = vector.load %b[%c0] : memref<4xf32>, vector<4xf32>
  %z = vector.interleave %x, %y : vector<4xf32> -> vector<8xf32>
  %ev, %od = vector.deinterleave %z : vector<8xf32> -> vector<4xf32>
  vector.store %ev, %d[%c0] : memref<4xf32>, vector<4xf32>
  vector.store %od, %e[%c0] : memref<4xf32>, vector<4xf32>
  return
}

// CHECK-LABEL: lvx_func.func @shuffle64
// CHECK: lvx.catdq %{{.*}}, %{{.*}} : (!lvx.reg, !lvx.reg) -> !lvx.pair
// CHECK: lvx.catdq %{{.*}}, %{{.*}} : (!lvx.reg, !lvx.reg) -> !lvx.pair
// CHECK: lvx.concat %{{.*}}, %{{.*}} : (!lvx.pair, !lvx.pair) -> !lvx.quad
// CHECK: lvx.evendq %{{.*}}, %{{.*}} : (!lvx.pair, !lvx.pair) -> !lvx.pair
// CHECK: lvx.odddq %{{.*}}, %{{.*}} : (!lvx.pair, !lvx.pair) -> !lvx.pair
func.func @shuffle64(%a: memref<2xi64>, %b: memref<2xi64>, %d: memref<2xi64>, %e: memref<2xi64>) {
  %c0 = arith.constant 0 : index
  %x = vector.load %a[%c0] : memref<2xi64>, vector<2xi64>
  %y = vector.load %b[%c0] : memref<2xi64>, vector<2xi64>
  %z = vector.interleave %x, %y : vector<2xi64> -> vector<4xi64>
  %ev, %od = vector.deinterleave %z : vector<4xi64> -> vector<2xi64>
  vector.store %ev, %d[%c0] : memref<2xi64>, vector<2xi64>
  vector.store %od, %e[%c0] : memref<2xi64>, vector<2xi64>
  return
}
