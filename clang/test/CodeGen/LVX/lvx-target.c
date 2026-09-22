// RUN: %clang_cc1 -triple lvx-mbr -emit-llvm -O1 -o - %s | FileCheck %s
// RUN: %clang_cc1 -triple lvx-mbr -target-cpu lvx-2 -E -dM -o - %s \
// RUN:   | FileCheck %s --check-prefix=CPU2

// The LVX target: LP64, little-endian, the same data layout the back end
// gives its TargetMachine -- a module carrying a different one is silently
// re-laid-out rather than rejected.
// CHECK: target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n32:64-S128"

// The variant reaches the front end as a CPU name and leaves as the macro
// lvx-gcc defines for it, so source switching on it sees one target.
// CPU2-DAG: #define __lvx_2__ 1
// CPU2-DAG: #define __lvx__ 1
// CPU2-NOT: #define __lvx_1__

// LP64: long and pointers are 64 bits, int is 32.
int sizes(void) { return sizeof(long) * 100 + sizeof(void *) * 10 + sizeof(int); }
// CHECK-LABEL: @sizes
// CHECK: ret i32 884

//===----------------------------------------------------------------------===//
// Both IEEE min/max families. Nothing but a NaN separates them, so a swap
// here survives every test that does not feed one in:
//   fmin/fmax   754-2019, PROPAGATE the NaN -> llvm.minimum/maximum
//   fminn/fmaxn 754-2008, return the NUMERIC operand -> llvm.minnum/maxnum
//===----------------------------------------------------------------------===//
double fmin_prop(double a, double b) { return __builtin_lvx_fmind(a, b); }
// CHECK-LABEL: @fmin_prop
// CHECK: call double @llvm.minimum.f64

double fmin_num(double a, double b) { return __builtin_lvx_fminnd(a, b); }
// CHECK-LABEL: @fmin_num
// CHECK: call double @llvm.minnum.f64

double fmax_prop(double a, double b) { return __builtin_lvx_fmaxd(a, b); }
// CHECK-LABEL: @fmax_prop
// CHECK: call double @llvm.maximum.f64

double fmax_num(double a, double b) { return __builtin_lvx_fmaxnd(a, b); }
// CHECK-LABEL: @fmax_num
// CHECK: call double @llvm.maxnum.f64

// copysignn takes the sign NEGATED -- lvx-gcc's lvx_fsignn<suffix> is
// (copysign a (neg b)) -- so the fneg is part of the instruction, not
// something the caller wrote.
double copysign_neg(double a, double b) { return __builtin_lvx_copysignnd(a, b); }
// CHECK-LABEL: @copysign_neg
// CHECK: fneg double
// CHECK: call double @llvm.copysign.f64

// __fp16 is computed on directly: the ISA has an f16 instruction wherever it
// has an f32 one. Said otherwise, clang routes every half through an i16
// bitcast and __builtin_copysignf16 comes out as llvm.copysign.i16, which
// does not exist and breaks the module.
_Float16 half_sign(_Float16 a, _Float16 b) { return __builtin_copysignf16(a, b); }
// CHECK-LABEL: @half_sign
// CHECK: call half @llvm.copysign.f16

//===----------------------------------------------------------------------===//
// The named address spaces. The numbers are ABI, shared with lvx-gcc's
// c_register_addr_space calls, and the back end reads them to pick the
// load's `variant` -- so a wrong one quietly compiles an uncached load as a
// cached one.
//===----------------------------------------------------------------------===//
int bypass_load(__bypass int *p) { return *p; }
// CHECK-LABEL: @bypass_load
// CHECK: load i32, ptr addrspace(1)

int preload_load(__preload int *p) { return *p; }
// CHECK-LABEL: @preload_load
// CHECK: load i32, ptr addrspace(2)

int speculate_load(__speculate int *p) { return *p; }
// CHECK-LABEL: @speculate_load
// CHECK: load i32, ptr addrspace(3)

// A cast between spaces moves no bits: every LVX address space is the same
// flat 64-bit address, and the space only chooses the load variant.
int converted(int *p) { return *(__bypass int *)(__convert int *)p; }
// CHECK-LABEL: @converted
// CHECK: load i32, ptr addrspace(1)

//===----------------------------------------------------------------------===//
// Vectors are passed in general registers as the integer of their width --
// a pair at 128 bits, a quad at 256 -- which is what lvx-gcc does and what
// the back end's calling convention can take apart. Passed as themselves,
// a <2 x i64> reached an assertion in LowerFormalArguments.
//===----------------------------------------------------------------------===//
typedef long v2di __attribute__((vector_size(16)));
typedef long v4di __attribute__((vector_size(32)));
v2di pass128(v2di a);
v4di pass256(v4di a);
v2di call128(v2di a) { return pass128(a); }
// CHECK-LABEL: @call128
// CHECK: call i128 @pass128(i128
v4di call256(v4di a) { return pass256(a); }
// CHECK-LABEL: @call256
// CHECK: call <4 x i64> @pass256(<4 x i64>
