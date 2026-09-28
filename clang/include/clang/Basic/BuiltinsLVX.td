//===--- BuiltinsLVX.td - LVX Builtin function database ---------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// The LVX target builtins, named as lvx-gcc's lvx-builtins.def names them so
// that the same source compiles under either compiler.
//
// Only the scalar ones are here. The vector builtins are gated on lvx-2 in
// GCC's table too, and they need vector types in a prototype, which is a
// separate piece of work; a program using one under -mcpu=lvx-2 gets an
// "unknown builtin" rather than wrong code.
//
//===----------------------------------------------------------------------===//

include "clang/Basic/BuiltinsBase.td"

class LVXBuiltin<string prototype> : TargetBuiltin {
  let Prototype = prototype;
  // Pure and never trapping: these are single ALU instructions that read
  // their operands and write a register.
  let Attributes = [NoThrow, Const];
}

//===----------------------------------------------------------------------===//
// Minimum and maximum
//
// LVX has BOTH IEEE families and the names are the trap, so they are spelled
// out here rather than left to a reader's assumption:
//
//   fmin/fmax     754-2019 minimum/maximum -- PROPAGATE a NaN operand
//   fminn/fmaxn   754-2008 minNum/maxNum   -- return the NUMERIC operand,
//                                             which is what C's fmin/fmax
//                                             and LLVM's fminnum require
//
// Every non-NaN input gives the same answer from both, so a wrong pairing
// survives ordinary testing -- lvx-gcc emitted fmind for C's fmin until
// 2026-08-04. validation/tests/ir/minmax-nan.ll pins it on the ISS.
//===----------------------------------------------------------------------===//

def FMinH : LVXBuiltin<"_Float16(_Float16, _Float16)"> {
  let Spellings = ["__builtin_lvx_fminh"];
}
def FMinNH : LVXBuiltin<"_Float16(_Float16, _Float16)"> {
  let Spellings = ["__builtin_lvx_fminnh"];
}
def FMaxH : LVXBuiltin<"_Float16(_Float16, _Float16)"> {
  let Spellings = ["__builtin_lvx_fmaxh"];
}
def FMaxNH : LVXBuiltin<"_Float16(_Float16, _Float16)"> {
  let Spellings = ["__builtin_lvx_fmaxnh"];
}

def FMinW : LVXBuiltin<"float(float, float)"> {
  let Spellings = ["__builtin_lvx_fminw"];
}
def FMinNW : LVXBuiltin<"float(float, float)"> {
  let Spellings = ["__builtin_lvx_fminnw"];
}
def FMaxW : LVXBuiltin<"float(float, float)"> {
  let Spellings = ["__builtin_lvx_fmaxw"];
}
def FMaxNW : LVXBuiltin<"float(float, float)"> {
  let Spellings = ["__builtin_lvx_fmaxnw"];
}

def FMinD : LVXBuiltin<"double(double, double)"> {
  let Spellings = ["__builtin_lvx_fmind"];
}
def FMinND : LVXBuiltin<"double(double, double)"> {
  let Spellings = ["__builtin_lvx_fminnd"];
}
def FMaxD : LVXBuiltin<"double(double, double)"> {
  let Spellings = ["__builtin_lvx_fmaxd"];
}
def FMaxND : LVXBuiltin<"double(double, double)"> {
  let Spellings = ["__builtin_lvx_fmaxnd"];
}

//===----------------------------------------------------------------------===//
// Sign manipulation
//
//   copysign<w>   copysign(a, b)
//   copysignn<w>  copysign(a, -b)  -- the sign taken NEGATED, which is what
//                                     lvx-gcc's lvx_fsignn<suffix> pattern
//                                     spells as (copysign a (neg b))
//   xorsign<w>    a with its sign XORed with b's; scalar forms are the
//                 vector family's, so only the vector builtins exist
//===----------------------------------------------------------------------===//

def CopySignH : LVXBuiltin<"_Float16(_Float16, _Float16)"> {
  let Spellings = ["__builtin_lvx_copysignh"];
}
def CopySignNH : LVXBuiltin<"_Float16(_Float16, _Float16)"> {
  let Spellings = ["__builtin_lvx_copysignnh"];
}
def CopySignW : LVXBuiltin<"float(float, float)"> {
  let Spellings = ["__builtin_lvx_copysignw"];
}
def CopySignNW : LVXBuiltin<"float(float, float)"> {
  let Spellings = ["__builtin_lvx_copysignnw"];
}
def CopySignD : LVXBuiltin<"double(double, double)"> {
  let Spellings = ["__builtin_lvx_copysignd"];
}
def CopySignND : LVXBuiltin<"double(double, double)"> {
  let Spellings = ["__builtin_lvx_copysignnd"];
}

//===----------------------------------------------------------------------===//
// The vector sign family
//
// Same meanings as the scalar ones above, one lane at a time. The names carry
// the lane shape: WQ = 4x32 and HO = 8x16 and DP = 2x64 at 128 bits, WO = 8x32
// and DQ = 4x64 at 256 bits (issued as two 128-bit halves).
//
// xorsign has no scalar form to mirror: `a` with its sign bit XORed with b's.
// It is a bitwise operation, not `copysign(a, a*b)` -- those agree on every
// finite value but not on a NaN, whose sign the multiply does not carry.
//===----------------------------------------------------------------------===//

def CopySignWQ : LVXBuiltin<"_Vector<4, float>(_Vector<4, float>, _Vector<4, float>)"> {
  let Spellings = ["__builtin_lvx_copysignwq"];
}
def CopySignNWQ : LVXBuiltin<"_Vector<4, float>(_Vector<4, float>, _Vector<4, float>)"> {
  let Spellings = ["__builtin_lvx_copysignnwq"];
}
def CopySignHO : LVXBuiltin<"_Vector<8, _Float16>(_Vector<8, _Float16>, _Vector<8, _Float16>)"> {
  let Spellings = ["__builtin_lvx_copysignho"];
}
def CopySignDP : LVXBuiltin<"_Vector<2, double>(_Vector<2, double>, _Vector<2, double>)"> {
  let Spellings = ["__builtin_lvx_copysigndp"];
}
def CopySignWO : LVXBuiltin<"_Vector<8, float>(_Vector<8, float>, _Vector<8, float>)"> {
  let Spellings = ["__builtin_lvx_copysignwo"];
}
def CopySignDQ : LVXBuiltin<"_Vector<4, double>(_Vector<4, double>, _Vector<4, double>)"> {
  let Spellings = ["__builtin_lvx_copysigndq"];
}
def CopySignNDQ : LVXBuiltin<"_Vector<4, double>(_Vector<4, double>, _Vector<4, double>)"> {
  let Spellings = ["__builtin_lvx_copysignndq"];
}
def XorSignWQ : LVXBuiltin<"_Vector<4, float>(_Vector<4, float>, _Vector<4, float>)"> {
  let Spellings = ["__builtin_lvx_xorsignwq"];
}
def XorSignHO : LVXBuiltin<"_Vector<8, _Float16>(_Vector<8, _Float16>, _Vector<8, _Float16>)"> {
  let Spellings = ["__builtin_lvx_xorsignho"];
}
def XorSignDP : LVXBuiltin<"_Vector<2, double>(_Vector<2, double>, _Vector<2, double>)"> {
  let Spellings = ["__builtin_lvx_xorsigndp"];
}
def XorSignWO : LVXBuiltin<"_Vector<8, float>(_Vector<8, float>, _Vector<8, float>)"> {
  let Spellings = ["__builtin_lvx_xorsignwo"];
}

//===----------------------------------------------------------------------===//
// Widening multiply
//
//   mulx<s><d>   widen each lane and multiply:  d = a * b
//   maddx<s><d>  and accumulate:                d = c + a * b
//   msbfx<s><d>  and subtract:                  d = c - a * b
//
// HWO is 8x16 -> 8x32 and WDQ is 4x32 -> 4x64, so the result is 256 bits and
// the compiler issues two 128-bit instructions. The trailing string is the
// EXTENDMUL flavour, exactly as lvx-gcc spells it: "" signed, ".u" unsigned,
// ".su" signed times unsigned. It must be a string literal -- but NOT declared
// `_Constant`, which marks an integer constant expression and asserts in
// ASTContext on any other type ("Integer constant 'I' type must be an
// integer"); codegen checks for the literal itself.
//===----------------------------------------------------------------------===//

def MulXHWO : LVXBuiltin<"_Vector<8, int>(_Vector<8, short>, _Vector<8, short>, char const*)"> {
  let Spellings = ["__builtin_lvx_mulxhwo"];
}
def MulXWDQ : LVXBuiltin<"_Vector<4, long int>(_Vector<4, int>, _Vector<4, int>, char const*)"> {
  let Spellings = ["__builtin_lvx_mulxwdq"];
}
def MAddXHWO : LVXBuiltin<"_Vector<8, int>(_Vector<8, short>, _Vector<8, short>, _Vector<8, int>, char const*)"> {
  let Spellings = ["__builtin_lvx_maddxhwo"];
}
def MAddXWDQ : LVXBuiltin<"_Vector<4, long int>(_Vector<4, int>, _Vector<4, int>, _Vector<4, long int>, char const*)"> {
  let Spellings = ["__builtin_lvx_maddxwdq"];
}
def MSbfXHWO : LVXBuiltin<"_Vector<8, int>(_Vector<8, short>, _Vector<8, short>, _Vector<8, int>, char const*)"> {
  let Spellings = ["__builtin_lvx_msbfxhwo"];
}
def MSbfXWDQ : LVXBuiltin<"_Vector<4, long int>(_Vector<4, int>, _Vector<4, int>, _Vector<4, long int>, char const*)"> {
  let Spellings = ["__builtin_lvx_msbfxwdq"];
}

//===----------------------------------------------------------------------===//
// Splatting load
//
// Load one element and broadcast it across a 256-bit quad. The trailing string
// is the load VARIANT (""/".s"/".u"/".us"), which selects caching behaviour and
// changes no value, so it is accepted and does not affect the IR here.
//===----------------------------------------------------------------------===//

def LoadBSO : LVXBuiltin<"_Vector<32, unsigned char>(void const*, char const*)"> {
  let Spellings = ["__builtin_lvx_loadbso"];
  let Attributes = [NoThrow];   // reads memory: not Const
}
def LoadHSO : LVXBuiltin<"_Vector<16, unsigned short>(void const*, char const*)"> {
  let Spellings = ["__builtin_lvx_loadhso"];
  let Attributes = [NoThrow];
}
def LoadWSO : LVXBuiltin<"_Vector<8, unsigned int>(void const*, char const*)"> {
  let Spellings = ["__builtin_lvx_loadwso"];
  let Attributes = [NoThrow];
}
def LoadDSO : LVXBuiltin<"_Vector<4, unsigned long int>(void const*, char const*)"> {
  let Spellings = ["__builtin_lvx_loaddso"];
  let Attributes = [NoThrow];
}
