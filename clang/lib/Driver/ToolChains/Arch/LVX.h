//===--- LVX.h - LVX-specific Tool Helpers ----------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_CLANG_LIB_DRIVER_TOOLCHAINS_ARCH_LVX_H
#define LLVM_CLANG_LIB_DRIVER_TOOLCHAINS_ARCH_LVX_H

#include "llvm/ADT/StringRef.h"
#include "llvm/Option/ArgList.h"

namespace clang {
namespace driver {
namespace tools {
namespace lvx {

/// The core this compilation targets: the value of the last -mcpu= or -march=,
/// or "lvx-1", which is the default of every other tool in the toolchain.
///
/// lvx-gcc and lvx-mbr-as both spell the core -march, clang spells it -mcpu,
/// and the two compilers are compared against each other constantly, so -march
/// has to be accepted here rather than left to fall through to the generic
/// "argument unused during compilation" warning -- which is what it did until
/// 2026-10-16, quietly compiling for lvx-1 whatever it named. Both spellings
/// claim the argument, and the last one on the command line wins.
llvm::StringRef getLVXTargetCPU(const llvm::opt::ArgList &Args);

} // end namespace lvx
} // end namespace tools
} // end namespace driver
} // end namespace clang

#endif
