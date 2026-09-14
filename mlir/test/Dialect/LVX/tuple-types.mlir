// RUN: mlir-opt %s | mlir-opt | FileCheck %s

// The pair and quad types (lvx-mds/docs/MLIR-backend-design.md §8.3) parse
// and print like `!lvx.reg`: unparameterized before allocation, pinned to a
// physical aligned pair or quadruple after. No generated op takes them yet
// (§8.4 is the generator step), so `func.func`, which accepts any type,
// carries them through the round trip.

// CHECK-LABEL: func.func @virtual
// CHECK-SAME: (%{{.*}}: !lvx.pair, %{{.*}}: !lvx.quad) -> (!lvx.pair, !lvx.quad)
func.func @virtual(%p: !lvx.pair, %q: !lvx.quad) -> (!lvx.pair, !lvx.quad) {
  return %p, %q : !lvx.pair, !lvx.quad
}

// The spelling is the pair's primary name, r0r1 .. r62r63, the value its
// first component's number: both ends of each file, and one in the middle
// that a quad's lanes would name the other way (`$r2r3` is `$r0r1r2r3.hi`).
// CHECK-LABEL: func.func @pinned
// CHECK-SAME: (%{{.*}}: !lvx.pair<r0r1>, %{{.*}}: !lvx.pair<r2r3>, %{{.*}}: !lvx.pair<r62r63>, %{{.*}}: !lvx.quad<r0r1r2r3>, %{{.*}}: !lvx.quad<r60r61r62r63>)
func.func @pinned(%a: !lvx.pair<r0r1>, %b: !lvx.pair<r2r3>, %c: !lvx.pair<r62r63>,
                  %d: !lvx.quad<r0r1r2r3>, %e: !lvx.quad<r60r61r62r63>) {
  return
}
