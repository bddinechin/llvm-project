//===--- LVX.cpp - LVX Helpers for Tools ------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "LVX.h"
#include "clang/Options/Options.h"

using namespace clang::driver;
using namespace clang::driver::tools;
using namespace clang;
using namespace llvm::opt;

llvm::StringRef lvx::getLVXTargetCPU(const ArgList &Args) {
  if (const Arg *A =
          Args.getLastArg(options::OPT_mcpu_EQ, options::OPT_march_EQ))
    return A->getValue();
  return "lvx-1";
}
