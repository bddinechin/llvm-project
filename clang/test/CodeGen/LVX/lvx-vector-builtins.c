// RUN: %clang_cc1 -triple lvx-mbr -target-cpu lvx-2 -emit-llvm -O0 -o - %s | FileCheck %s

// The vector builtins are emitted as plain IR rather than as target
// intrinsics: llvm.copysign is overloaded so a vector operand is the lane-wise
// operation, a widening multiply is an extend plus a multiply at the wider
// width, and a splatting load is a load plus a splat. That means they are
// CORRECT on both cores -- an lvx_v1 description simply scalarises what an
// lvx_v2 one selects as one instruction -- and it is why these checks are on
// the IR, not on the assembly.

typedef float          v4sf __attribute__((vector_size(16)));
typedef _Float16       v8hf __attribute__((vector_size(16)));
typedef double         v2df __attribute__((vector_size(16)));
typedef double         v4df __attribute__((vector_size(32)));
typedef short          v8hi __attribute__((vector_size(16)));
typedef int            v8si __attribute__((vector_size(32)));
typedef int            v4si __attribute__((vector_size(16)));
typedef long           v4di __attribute__((vector_size(32)));
typedef unsigned char  v32u8 __attribute__((vector_size(32)));

// CHECK-LABEL: @sign_wq(
// CHECK: call <4 x float> @llvm.copysign.v4f32(
v4sf sign_wq(v4sf a, v4sf b) { return __builtin_lvx_copysignwq(a, b); }

// copysignn takes the sign NEGATED, which is part of what the instruction
// means rather than something the caller wrote.
// CHECK-LABEL: @sign_ndq(
// CHECK: fneg <4 x double>
// CHECK: call <4 x double> @llvm.copysign.v4f64(
v4df sign_ndq(v4df a, v4df b) { return __builtin_lvx_copysignndq(a, b); }

// xorsign FLIPS the sign rather than replacing it, and is done on the bits:
// copysign(a, a*b) would agree on every finite value but not on a NaN, whose
// sign a multiply does not carry.
// CHECK-LABEL: @xsign_dp(
// CHECK: and <2 x i64> {{.*}}, splat (i64 -9223372036854775808)
// CHECK: xor <2 x i64>
// CHECK-NOT: fmul
v2df xsign_dp(v2df a, v2df b) { return __builtin_lvx_xorsigndp(a, b); }

// A widening multiply extends both operands to the destination lane width and
// multiplies there. "" is signed...
// CHECK-LABEL: @mul_s(
// CHECK: sext <8 x i16> {{.*}} to <8 x i32>
// CHECK: sext <8 x i16> {{.*}} to <8 x i32>
// CHECK: mul <8 x i32>
v8si mul_s(v8hi a, v8hi b) { return __builtin_lvx_mulxhwo(a, b, ""); }

// ... ".u" unsigned ...
// CHECK-LABEL: @mul_u(
// CHECK: zext <8 x i16> {{.*}} to <8 x i32>
// CHECK: zext <8 x i16> {{.*}} to <8 x i32>
// CHECK: mul <8 x i32>
v8si mul_u(v8hi a, v8hi b) { return __builtin_lvx_mulxhwo(a, b, ".u"); }

// ... and ".su" is the FIRST operand signed, the second unsigned.
// CHECK-LABEL: @mul_su(
// CHECK: sext <4 x i32> {{.*}} to <4 x i64>
// CHECK: zext <4 x i32> {{.*}} to <4 x i64>
// CHECK: mul <4 x i64>
v4di mul_su(v4si a, v4si b) { return __builtin_lvx_mulxwdq(a, b, ".su"); }

// maddx accumulates and msbfx subtracts, and which way round matters: the
// product is subtracted FROM the accumulator, not the other way about.
// CHECK-LABEL: @madd(
// CHECK: mul <8 x i32>
// CHECK: add <8 x i32>
v8si madd(v8hi a, v8hi b, v8si c) { return __builtin_lvx_maddxhwo(a, b, c, ""); }

// CHECK-LABEL: @msbf(
// CHECK: [[P:%[0-9a-z.]+]] = mul <8 x i32>
// CHECK: sub <8 x i32> {{%[0-9a-z.]+}}, [[P]]
v8si msbf(v8hi a, v8hi b, v8si c) { return __builtin_lvx_msbfxhwo(a, b, c, ""); }

// A splatting load: one element read, broadcast across the 256-bit quad. The
// trailing string is the load variant, which changes no value.
// CHECK-LABEL: @splat_load(
// CHECK: load i8
// CHECK: shufflevector <32 x i8> {{.*}} zeroinitializer
v32u8 splat_load(const void *p) { return __builtin_lvx_loadbso(p, ""); }

// CHECK-LABEL: @splat_load_d(
// CHECK: load i64
// CHECK: shufflevector <4 x i64>
v4di splat_load_d(const void *p) {
  return (v4di)__builtin_lvx_loaddso(p, ".u");
}
