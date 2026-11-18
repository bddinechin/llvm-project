// RUN: %clang_cc1 -triple lvx-mbr -target-cpu lvx-2 -emit-llvm -O0 -o - %s | FileCheck %s

// The builtins libgcc's vector dividers (libgcc/config/lvx/divmodvx*.c) are
// written against -- abs, widen, trunc, select, cat/low/high -- and the lane
// STSU family. All but STSU are generic IR; STSU is the lane form of the
// stsud intrinsic, and its 256-bit spellings are two of it on the halves.

typedef signed char v16qi __attribute__((vector_size(16)));
typedef short       v8hi  __attribute__((vector_size(16)));
typedef short       v16hi __attribute__((vector_size(32)));
typedef int         v4si  __attribute__((vector_size(16)));
typedef int         v8si  __attribute__((vector_size(32)));
typedef long        v2di  __attribute__((vector_size(16)));
typedef long        v4di  __attribute__((vector_size(32)));
typedef unsigned char  v16qu __attribute__((vector_size(16)));
typedef unsigned char  v32qu __attribute__((vector_size(32)));
typedef unsigned short v8hu  __attribute__((vector_size(16)));
typedef unsigned short v16hu __attribute__((vector_size(32)));
typedef unsigned int   v4su  __attribute__((vector_size(16)));
typedef unsigned long  v2du  __attribute__((vector_size(16)));
typedef unsigned long  v4du  __attribute__((vector_size(32)));

// CHECK-LABEL: @abs_bx(
// CHECK: call <16 x i8> @llvm.abs.v16i8(<16 x i8> %{{.*}}, i1 false)
v16qi abs_bx(v16qi a) { return __builtin_lvx_absbx(a, ""); }

// The saturating one: -MIN saturates to MAX, so max(a, 0 -sat a).
// CHECK-LABEL: @abss_wq(
// CHECK: [[N:%.*]] = call <4 x i32> @llvm.ssub.sat.v4i32(<4 x i32> zeroinitializer, <4 x i32> [[A:%.*]])
// CHECK: call <4 x i32> @llvm.smax.v4i32(<4 x i32> [[A]], <4 x i32> [[N]])
v4si abss_wq(v4si a) { return __builtin_lvx_abswq(a, ".s"); }

// CHECK-LABEL: @abs_wo(
// CHECK: call <8 x i32> @llvm.abs.v8i32(
v8si abs_wo(v8si a) { return __builtin_lvx_abswo(a, ""); }

// CHECK-LABEL: @widen_s(
// CHECK: sext <16 x i8> %{{.*}} to <16 x i16>
v16hi widen_s(v16qi a) { return __builtin_lvx_widenbhx(a, ""); }

// CHECK-LABEL: @widen_z(
// CHECK: zext <4 x i32> %{{.*}} to <4 x i64>
// CHECK-NOT: shl
v4di widen_z(v4si a) { return __builtin_lvx_widenwdq(a, ".z"); }

// ".q" is Q31 -> Q63: the lane in the top half, the bottom half zero.
// CHECK-LABEL: @widen_q(
// CHECK: [[Z:%.*]] = zext <8 x i16> %{{.*}} to <8 x i32>
// CHECK: shl <8 x i32> [[Z]], splat (i32 16)
v8si widen_q(v8hi a) { return __builtin_lvx_widenhwo(a, ".q"); }

// CHECK-LABEL: @trunc_dwq(
// CHECK: trunc <4 x i64> %{{.*}} to <4 x i32>
v4si trunc_dwq(v4di a) { return __builtin_lvx_truncdwq(a); }

// select(t, f, c, cond) is cond(c) ? t : f, lane by lane.
// CHECK-LABEL: @select_ltz(
// CHECK: [[C:%.*]] = icmp slt <4 x i32> %{{.*}}, zeroinitializer
// CHECK: select <4 x i1> [[C]], <4 x i32> [[T:%[^,]*]], <4 x i32> [[F:%[^,]*]]
v4si select_ltz(v4si t, v4si f, v4si c) {
  return __builtin_lvx_selectwq(t, f, c, ".ltz");
}

// CHECK-LABEL: @select_odd(
// CHECK: [[L:%.*]] = and <8 x i16> %{{.*}}, splat (i16 1)
// CHECK: icmp ne <8 x i16> [[L]], zeroinitializer
v8hi select_odd(v8hi t, v8hi f, v8hi c) {
  return __builtin_lvx_selectho(t, f, c, ".odd");
}

// CHECK-LABEL: @cat(
// CHECK: shufflevector <2 x i64> %{{.*}}, <2 x i64> %{{.*}}, <4 x i32> <i32 0, i32 1, i32 2, i32 3>
v32qu cat(v16qu lo, v16qu hi) { return __builtin_lvx_cat256(lo, hi); }

// CHECK-LABEL: @high(
// CHECK: shufflevector <4 x i64> %{{.*}}, <4 x i64> poison, <2 x i32> <i32 2, i32 3>
v16qu high(v32qu a) { return __builtin_lvx_high128(a); }

// CHECK-LABEL: @low(
// CHECK: shufflevector <4 x i64> %{{.*}}, <4 x i64> poison, <2 x i32> <i32 0, i32 1>
v16qu low(v32qu a) { return __builtin_lvx_low128(a); }

// CHECK-LABEL: @stsu_dp(
// CHECK: call <2 x i64> @llvm.lvx.stsudp(<2 x i64> %{{.*}}, <2 x i64> %{{.*}})
v2du stsu_dp(v2du z, v2du y) { return __builtin_lvx_stsudp(z, y); }

// CHECK-LABEL: @stsu_ho(
// CHECK: call <8 x i16> @llvm.lvx.stsuho(
v8hu stsu_ho(v8hu z, v8hu y) { return __builtin_lvx_stsuho(z, y); }

// CHECK-LABEL: @stsu_wq(
// CHECK: call <4 x i32> @llvm.lvx.stsuwq(
v4su stsu_wq(v4su z, v4su y) { return __builtin_lvx_stsuwq(z, y); }

// 256 bits: two steps on the halves, put back together.
// CHECK-LABEL: @stsu_hx(
// CHECK: shufflevector <16 x i16> {{.*}} <i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7>
// CHECK: call <8 x i16> @llvm.lvx.stsuho(
// CHECK: shufflevector <16 x i16> {{.*}} <i32 8, i32 9, i32 10, i32 11, i32 12, i32 13, i32 14, i32 15>
// CHECK: call <8 x i16> @llvm.lvx.stsuho(
// CHECK: shufflevector <8 x i16> %{{.*}}, <8 x i16> %{{.*}}, <16 x i32>
v16hu stsu_hx(v16hu z, v16hu y) { return __builtin_lvx_stsuhx(z, y); }

// CHECK-LABEL: @stsu_dq(
// CHECK-COUNT-2: call <2 x i64> @llvm.lvx.stsudp(
v4du stsu_dq(v4du z, v4du y) { return __builtin_lvx_stsudq(z, y); }
