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
