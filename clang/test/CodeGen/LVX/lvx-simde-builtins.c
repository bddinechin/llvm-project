// RUN: %clang_cc1 -triple lvx-mbr -target-cpu lvx-2 -emit-llvm -O0 -o - %s | FileCheck %s

// The sixteen builtins SIMDe's LVX backend (lvx-simde/lvx/compute/) calls, and
// so the sixteen lvx-perf's lvx-ssw benchmark reaches LVX through. Fifteen are
// plain IR for the reason the rest of this family is -- an lvx_v1 description
// scalarises what an lvx_v2 one selects as one instruction, so they are
// correct on both cores -- and only the lane COMPARE needs a target intrinsic,
// its result being a bitcast of a <16 x i1> that has no lowering here.

typedef signed char v16qi __attribute__((vector_size(16)));
typedef short       v8hi  __attribute__((vector_size(16)));
typedef int         v4si  __attribute__((vector_size(16)));
typedef long        v2di  __attribute__((vector_size(16)));

// CHECK-LABEL: @add_bx(
// CHECK: add <16 x i8>
v16qi add_bx(v16qi a, v16qi b) { return __builtin_lvx_addbx(a, b, ""); }

// CHECK-LABEL: @adds_bx(
// CHECK: call <16 x i8> @llvm.sadd.sat.v16i8(
v16qi adds_bx(v16qi a, v16qi b) { return __builtin_lvx_addbx(a, b, ".s"); }

// CHECK-LABEL: @addus_bx(
// CHECK: call <16 x i8> @llvm.uadd.sat.v16i8(
v16qi addus_bx(v16qi a, v16qi b) { return __builtin_lvx_addbx(a, b, ".us"); }

// CHECK-LABEL: @add_ho(
// CHECK: add <8 x i16>
v8hi add_ho(v8hi a, v8hi b) { return __builtin_lvx_addho(a, b, ""); }

// CHECK-LABEL: @adds_ho(
// CHECK: call <8 x i16> @llvm.sadd.sat.v8i16(
v8hi adds_ho(v8hi a, v8hi b) { return __builtin_lvx_addho(a, b, ".s"); }

// SBF is "subtract FROM": sbf(a, b) is b - a, so the operands come out of the
// builtin SWAPPED. A swap agrees with the other order wherever a == b, which
// is why it is pinned by argument position here and warned about in three
// places.
// (The loads are from %a.addr/%b.addr rather than %a/%b: a 128-bit vector is
// passed as the integer of its width, so the parameters arrive coerced and are
// stored before use. Naming the pointer is what makes the check pin the swap
// rather than an operand number.)
// CHECK-LABEL: @sbf_bx(
// CHECK: %[[A:.*]] = load <16 x i8>, ptr %a.addr
// CHECK: %[[B:.*]] = load <16 x i8>, ptr %b.addr
// CHECK: sub <16 x i8> %[[B]], %[[A]]
v16qi sbf_bx(v16qi a, v16qi b) { return __builtin_lvx_sbfbx(a, b, ""); }

// CHECK-LABEL: @sbfus_ho(
// CHECK: %[[A:.*]] = load <8 x i16>, ptr %a.addr
// CHECK: %[[B:.*]] = load <8 x i16>, ptr %b.addr
// CHECK: call <8 x i16> @llvm.usub.sat.v8i16(<8 x i16> %[[B]], <8 x i16> %[[A]])
v8hi sbfus_ho(v8hi a, v8hi b) { return __builtin_lvx_sbfho(a, b, ".us"); }

// min/max: the signedness is in the OPERATION, not in the type -- the unsigned
// forms take the same signed vector type, as lvx-gcc's
// V16QI_FTYPE_V16QI_V16QI does for minubx.
// CHECK-LABEL: @min_bx(
// CHECK: call <16 x i8> @llvm.smin.v16i8(
v16qi min_bx(v16qi a, v16qi b) { return __builtin_lvx_minbx(a, b); }

// CHECK-LABEL: @minu_bx(
// CHECK: call <16 x i8> @llvm.umin.v16i8(
v16qi minu_bx(v16qi a, v16qi b) { return __builtin_lvx_minubx(a, b); }

// CHECK-LABEL: @max_bx(
// CHECK: call <16 x i8> @llvm.smax.v16i8(
v16qi max_bx(v16qi a, v16qi b) { return __builtin_lvx_maxbx(a, b); }

// CHECK-LABEL: @maxu_bx(
// CHECK: call <16 x i8> @llvm.umax.v16i8(
v16qi maxu_bx(v16qi a, v16qi b) { return __builtin_lvx_maxubx(a, b); }

// CHECK-LABEL: @min_ho(
// CHECK: call <8 x i16> @llvm.smin.v8i16(
v8hi min_ho(v8hi a, v8hi b) { return __builtin_lvx_minho(a, b); }

// CHECK-LABEL: @minu_ho(
// CHECK: call <8 x i16> @llvm.umin.v8i16(
v8hi minu_ho(v8hi a, v8hi b) { return __builtin_lvx_minuho(a, b); }

// CHECK-LABEL: @max_ho(
// CHECK: call <8 x i16> @llvm.smax.v8i16(
v8hi max_ho(v8hi a, v8hi b) { return __builtin_lvx_maxho(a, b); }

// CHECK-LABEL: @maxu_ho(
// CHECK: call <8 x i16> @llvm.umax.v8i16(
v8hi maxu_ho(v8hi a, v8hi b) { return __builtin_lvx_maxuho(a, b); }

// The lane compare: a target intrinsic, the relation arriving as its 0..11
// intcomp encoding, and the i64 the instruction writes truncated to the uint32
// lvx-gcc gives the builtin. .lt is 0.
// CHECK-LABEL: @comp_bx(
// CHECK: %[[M:.*]] = call i64 @llvm.lvx.compbx(<16 x i8> {{.*}}, <16 x i8> {{.*}}, i64 0)
// CHECK: trunc i64 %[[M]] to i32
unsigned comp_bx(v16qi a, v16qi b) { return __builtin_lvx_compbx(a, b, ".lt"); }

// .geu is 3, and is its own encoding rather than a swap of .ltu.
// CHECK-LABEL: @comp_ho(
// CHECK: call i64 @llvm.lvx.compho(<8 x i16> {{.*}}, <8 x i16> {{.*}}, i64 3)
unsigned comp_ho(v8hi a, v8hi b) { return __builtin_lvx_compho(a, b, ".geu"); }

// CHECK-LABEL: @comp_wq(
// CHECK: call i64 @llvm.lvx.compwq(<4 x i32> {{.*}}, <4 x i32> {{.*}}, i64 5)
unsigned comp_wq(v4si a, v4si b) { return __builtin_lvx_compwq(a, b, ".ne"); }

// .none is 7 and is not a relation at all: it asks whether the bitwise AND of
// the two lanes has no bits set.
// CHECK-LABEL: @comp_dp(
// CHECK: call i64 @llvm.lvx.compdp(<2 x i64> {{.*}}, <2 x i64> {{.*}}, i64 7)
unsigned comp_dp(v2di a, v2di b) { return __builtin_lvx_compdp(a, b, ".none"); }
