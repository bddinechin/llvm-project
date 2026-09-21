// RUN: mlir-opt %s -convert-linalg-to-affine-loops -affine-super-vectorize="virtual-vector-size=8" \
// RUN:   -lower-affine -lvx-lower-vector-transfers -canonicalize | FileCheck %s --check-prefix=VEC
// RUN: mlir-opt %s -convert-linalg-to-affine-loops -affine-super-vectorize="virtual-vector-size=8" \
// RUN:   -lower-affine -lvx-lower-vector-transfers -canonicalize -convert-to-lvx | FileCheck %s

// The vectorization stage of examples/build-mymma.sh (VEC=8), from the
// linalg matmul down: upstream's affine super-vectorizer along j, then
// -lvx-lower-vector-transfers hoists the accumulator's transfer pair out of
// the k loop into an iter_arg and lowers the transfers. What comes out is
// the hand-written examples/mymma_vec8.mlir, up to a math.fma for its
// vector.fma, and -convert-to-lvx takes it the same way.

// VEC-LABEL: func.func @mymma
// VEC:         scf.for %[[I:.*]] = %c0 to %c8 step %c1 {
// VEC:           scf.for %[[J:.*]] = %c0 to %c16 step %c8 {
// VEC:             %[[INIT:.*]] = vector.load %arg2[%[[I]], %[[J]]] : memref<8x16xf32>, vector<8xf32>
// VEC:             %[[ACC:.*]] = scf.for %[[K:.*]] = %c0 to %c16 step %c1 iter_args(%[[A:.*]] = %[[INIT]]) -> (vector<8xf32>) {
// VEC:               %[[S:.*]] = memref.load %arg0[%[[I]], %[[K]]] : memref<8x16xf32>
// VEC:               %[[SV:.*]] = vector.broadcast %[[S]] : f32 to vector<8xf32>
// VEC:               %[[BV:.*]] = vector.load %arg1[%[[K]], %[[J]]] : memref<16x16xf32>, vector<8xf32>
// VEC:               %[[F:.*]] = math.fma %[[SV]], %[[BV]], %[[A]] : vector<8xf32>
// VEC:               scf.yield %[[F]] : vector<8xf32>
// VEC:             }
// VEC:             vector.store %[[ACC]], %arg2[%[[I]], %[[J]]] : memref<8x16xf32>, vector<8xf32>
// VEC-NOT:       vector.transfer_read
// VEC-NOT:       vector.transfer_write

// CHECK-LABEL: lvx_func.func @mymma
// CHECK:         %[[INIT:.*]] = lvx.lo %{{.*}}, 0 : i64 : (!lvx.reg) -> !lvx.quad
// CHECK:         lvx_scf.for %{{.*}} : !lvx.reg to %{{.*}} : !lvx.reg step %{{.*}} : !lvx.reg iter_args(%[[INIT]]) : (!lvx.quad) -> (!lvx.quad)
// CHECK:           %[[S:.*]] = lvx.lw
// CHECK:           %[[BV:.*]] = lvx.lo %{{.*}}, 0 : i64 : (!lvx.reg) -> !lvx.quad
// CHECK:           %[[SV:.*]] = lvx.splatwq %[[S]] : (!lvx.reg) -> !lvx.pair
// CHECK:           %[[F:.*]] = lvx.ffmawo %[[SV]], %[[BV]], %{{.*}} : (!lvx.pair, !lvx.quad, !lvx.quad) -> !lvx.quad
// CHECK:           lvx_scf.yield %[[F]] : !lvx.quad
// CHECK:         }
// CHECK:         lvx.so %{{.*}}, %{{.*}}, 0 : i64 : (!lvx.quad, !lvx.reg)
func.func @mymma(%A: memref<8x16xf32>, %B: memref<16x16xf32>, %C: memref<8x16xf32>) {
  linalg.generic {
    indexing_maps = [
      affine_map<(d0, d1, d2) -> (d0, d2)>,
      affine_map<(d0, d1, d2) -> (d2, d1)>,
      affine_map<(d0, d1, d2) -> (d0, d1)>
    ],
    iterator_types = ["parallel", "parallel", "reduction"]
  }
    ins(%A, %B : memref<8x16xf32>, memref<16x16xf32>)
    outs(%C : memref<8x16xf32>)
    {
    ^bb0(%in: f32, %in_0: f32, %out: f32):
      %1 = math.fma %in, %in_0, %out : f32
      linalg.yield %1 : f32
    }
  return
}
