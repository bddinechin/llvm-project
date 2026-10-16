//===--- LVXToolChain.h - LVX ToolChain Implementations ---------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_CLANG_LIB_DRIVER_TOOLCHAINS_LVXTOOLCHAIN_H
#define LLVM_CLANG_LIB_DRIVER_TOOLCHAINS_LVXTOOLCHAIN_H

#include "Gnu.h"
#include "clang/Driver/ToolChain.h"

namespace clang {
namespace driver {
namespace toolchains {

// The lvx-mbr bare-metal cross, which is a GCC-installed one: the runtime
// (crt0, newlib, libgloss, libgcc and the linker scripts) is what lvx-gcc
// installs, and clang reuses it rather than shipping its own. Modelled on
// CSKYToolChain, which is the same arrangement.
//
// Without this class the triple fell through to Generic_ELF with no GCC
// installation, which assembles and LINKS by invoking the host /usr/bin/gcc --
// so a bare-metal link produced host objects or nothing at all, and every
// #include came from /usr/include.
class LLVM_LIBRARY_VISIBILITY LVXToolChain : public Generic_ELF {
public:
  LVXToolChain(const Driver &D, const llvm::Triple &Triple,
               const llvm::opt::ArgList &Args);

  void AddClangSystemIncludeArgs(const llvm::opt::ArgList &DriverArgs,
                                 llvm::opt::ArgStringList &CC1Args) const override;
  void addClangTargetOptions(const llvm::opt::ArgList &DriverArgs,
                             llvm::opt::ArgStringList &CC1Args,
                             Action::OffloadKind) const override;
  RuntimeLibType GetDefaultRuntimeLibType() const override;
  UnwindLibType GetUnwindLibType(const llvm::opt::ArgList &Args) const override;
  bool isPICDefault() const override { return false; }
  bool isPIEDefault(const llvm::opt::ArgList &Args) const override { return false; }
  bool isPICDefaultForced() const override { return false; }

  // The multilib subdirectory the runtime lives in -- "lvx-1" or "lvx-2".
  // lvx-gcc keys its multilibs on -march and clang spells the same choice
  // -mcpu, so the selection is made here rather than through the GCC
  // installation's MultilibSet: its flag strings would never match what this
  // driver passes.
  StringRef getCoreSuffix() const { return CoreSuffix; }

  std::string computeSysRoot() const override;

protected:
  Tool *buildLinker() const override;

private:
  std::string CoreSuffix;
};

} // end namespace toolchains

namespace tools {
namespace LVX {

class LLVM_LIBRARY_VISIBILITY Linker final : public Tool {
public:
  Linker(const ToolChain &TC) : Tool("LVX::Linker", "lvx-mbr-ld", TC) {}
  bool hasIntegratedCPP() const override { return false; }
  bool isLinkJob() const override { return true; }
  void ConstructJob(Compilation &C, const JobAction &JA,
                    const InputInfo &Output, const InputInfoList &Inputs,
                    const llvm::opt::ArgList &TCArgs,
                    const char *LinkingOutput) const override;
};

} // end namespace LVX
} // end namespace tools
} // end namespace driver
} // end namespace clang

#endif // LLVM_CLANG_LIB_DRIVER_TOOLCHAINS_LVXTOOLCHAIN_H
