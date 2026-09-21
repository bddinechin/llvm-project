// RUN: mlir-opt %s -split-input-file -verify-diagnostics

// There is no `$r1r2`: pairs are the aligned set, and the type cannot name
// anything else (lvx-mds/docs/MLIR-backend-design.md §8.1).
// expected-error @below {{invalid LVX register pair name 'r1r2'}}
func.func @misaligned_pair(%p: !lvx.pair<r1r2>)

// -----

// expected-error @below {{invalid LVX register quadruple name 'r2r3r4r5'}}
func.func @misaligned_quad(%q: !lvx.quad<r2r3r4r5>)

// -----

// A single's name is not a pair's, and vice versa.
// expected-error @below {{invalid LVX register pair name 'r0'}}
func.func @single_as_pair(%p: !lvx.pair<r0>)

// -----

// expected-error @below {{invalid LVX register name 'r0r1'}}
func.func @pair_as_single(%p: !lvx.reg<r0r1>)

// -----

// `lvx.lane`'s index is a unit offset that must be a lane of the result's
// width within the source.
func.func @lane_index(%p: !lvx.pair) {
  // expected-error @below {{index 2 is not a lane of the source}}
  %0 = "lvx.lane"(%p) {index = 2 : i64} : (!lvx.pair) -> !lvx.reg
  return
}

// -----

func.func @lane_misaligned(%q: !lvx.quad) {
  // expected-error @below {{index 1 is not a lane of the source}}
  %0 = "lvx.lane"(%q) {index = 1 : i64} : (!lvx.quad) -> !lvx.pair
  return
}

// -----

func.func @lane_same_width(%p: !lvx.pair) {
  // expected-error @below {{result must be narrower than the source}}
  %0 = "lvx.lane"(%p) {index = 0 : i64} : (!lvx.pair) -> !lvx.pair
  return
}

// -----

// Once both ends are pinned they must agree: lane 1 of r2r3 is r3.
func.func @lane_pinned(%p: !lvx.pair<r2r3>) {
  // expected-error @below {{result is pinned to r4 but lane 1 of r2r3 is r3}}
  %0 = "lvx.lane"(%p) {index = 1 : i64} : (!lvx.pair<r2r3>) -> !lvx.reg<r4>
  return
}

// -----

// `lvx.concat`, the reverse: the parts' widths add up to the result's ...
func.func @concat_width(%p: !lvx.pair, %r: !lvx.reg) {
  // expected-error @below {{the parts' widths add up to 3 units, the result has 4}}
  %0 = lvx.concat %p, %r : (!lvx.pair, !lvx.reg) -> !lvx.quad
  return
}

// -----

// ... each part sits at a multiple of its width (a pair at unit 1 is no
// register pair) ...
func.func @concat_misaligned(%p: !lvx.pair, %r: !lvx.reg) {
  // expected-error @below {{part 1 would sit at unit 1, not a multiple of its width 2}}
  %0 = lvx.concat %r, %p, %r : (!lvx.reg, !lvx.pair, !lvx.reg) -> !lvx.quad
  return
}

// -----

// ... and once pinned, a part is the result's lane at its offset.
func.func @concat_pinned(%lo: !lvx.pair<r4r5>, %hi: !lvx.pair<r8r9>) {
  // expected-error @below {{part 1 is pinned to r8r9 but lane 2 of r4r5r6r7 is r6r7}}
  %0 = lvx.concat %lo, %hi : (!lvx.pair<r4r5>, !lvx.pair<r8r9>) -> !lvx.quad<r4r5r6r7>
  return
}

// -----

// A copy does not change register file.
func.func @mv_width(%p: !lvx.pair) {
  // expected-error @below {{source and result must be the same width}}
  %0 = "lvx.mv"(%p) : (!lvx.pair) -> !lvx.reg
  return
}
