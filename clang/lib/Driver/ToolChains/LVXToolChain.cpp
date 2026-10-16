//===--- LVXToolChain.cpp - LVX ToolChain Implementations -------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "LVXToolChain.h"
#include "clang/Driver/CommonArgs.h"
#include "clang/Driver/Compilation.h"
#include "clang/Driver/InputInfo.h"
#include "clang/Options/Options.h"
#include "llvm/Option/ArgList.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/Path.h"

using namespace clang::driver;
using namespace clang::driver::toolchains;
using namespace clang::driver::tools;
using namespace clang;
using namespace llvm::opt;

// lvx-gcc builds two multilibs, "lvx-1" and "lvx-2", and selects between them
// with -march; clang spells the same choice -mcpu. Translate here rather than
// going through GCCInstallation's MultilibSet: its flag strings are
// "@march=lvx-1@fdata-sections@ffunction-sections", which nothing this driver
// passes will ever match, so the set would silently pick the first entry and a
// -mcpu=lvx-2 program would link against the lvx-1 runtime.
static std::string coreSuffixFor(const ArgList &Args) {
  if (const Arg *A = Args.getLastArg(options::OPT_mcpu_EQ))
    if (StringRef(A->getValue()) == "lvx-2")
      return "lvx-2";
  return "lvx-1";
}

LVXToolChain::LVXToolChain(const Driver &D, const llvm::Triple &Triple,
                           const ArgList &Args)
    : Generic_ELF(D, Triple, Args), CoreSuffix(coreSuffixFor(Args)) {
  GCCInstallation.init(Triple, Args);

  path_list &Paths = getFilePaths();
  if (GCCInstallation.isValid()) {
    // crti.o, crtbegin.o, crtend.o, crtn.o and libgcc.a come from the GCC
    // installation's multilib directory; crt0.o, libc.a and libgloss.a from
    // newlib's, under the sysroot. Both unsuffixed directories are kept after
    // them so a file that exists in only one place is still found.
    StringRef Install = GCCInstallation.getInstallPath();
    addPathIfExists(D, Install + "/" + CoreSuffix, Paths);
    addPathIfExists(D, Install, Paths);

    ToolChain::path_list &PPaths = getProgramPaths();
    // Where lvx-mbr-as and lvx-mbr-ld live. Driver::GetProgramPath tries the
    // triple-prefixed name in each of these, which is what resolves the plain
    // tool names "as" and "ld" to the cross binaries.
    PPaths.push_back(Twine(GCCInstallation.getParentLibPath() + "/../" +
                           GCCInstallation.getTriple().str() + "/bin")
                         .str());
    PPaths.push_back((GCCInstallation.getParentLibPath() + "/../bin").str());
  }
  addPathIfExists(D, computeSysRoot() + "/lib/" + CoreSuffix, Paths);
  addPathIfExists(D, computeSysRoot() + "/lib", Paths);
  getProgramPaths().push_back(D.Dir);
}

std::string LVXToolChain::computeSysRoot() const {
  if (!getDriver().SysRoot.empty())
    return getDriver().SysRoot;

  // <prefix>/lvx-mbr, beside the <prefix>/lib/gcc/lvx-mbr/<version> the GCC
  // installation was found in -- the layout lvx-gcc installs.
  SmallString<128> Dir;
  if (GCCInstallation.isValid())
    llvm::sys::path::append(Dir, GCCInstallation.getParentLibPath(), "..",
                            GCCInstallation.getTriple().str());
  else
    llvm::sys::path::append(Dir, getDriver().Dir, "..",
                            getDriver().getTargetTriple());

  if (!llvm::sys::fs::exists(Dir))
    return std::string();
  return std::string(Dir);
}

void LVXToolChain::addClangTargetOptions(const ArgList &DriverArgs,
                                         ArgStringList &CC1Args,
                                         Action::OffloadKind) const {
  // The host's /usr/include is not newlib's, and picking it up is not a
  // near-miss: <stdio.h> there includes <bits/libc-header-start.h>, which does
  // not exist in the sysroot, so the first #include of a C header failed.
  CC1Args.push_back("-nostdsysteminc");
}

void LVXToolChain::AddClangSystemIncludeArgs(const ArgList &DriverArgs,
                                             ArgStringList &CC1Args) const {
  if (DriverArgs.hasArg(options::OPT_nostdinc))
    return;
  if (!DriverArgs.hasArg(options::OPT_nobuiltininc))
    addSystemInclude(DriverArgs, CC1Args, getDriver().ResourceDir + "/include");
  if (!DriverArgs.hasArg(options::OPT_nostdlibinc)) {
    SmallString<128> Dir(computeSysRoot());
    llvm::sys::path::append(Dir, "include");
    addSystemInclude(DriverArgs, CC1Args, Dir.str());
  }
}

ToolChain::RuntimeLibType LVXToolChain::GetDefaultRuntimeLibType() const {
  // libgcc, always: there is no compiler-rt built for lvx, and libgcc is what
  // holds the division and the 128-bit helpers this target needs.
  return ToolChain::RLT_Libgcc;
}

ToolChain::UnwindLibType
LVXToolChain::GetUnwindLibType(const llvm::opt::ArgList &Args) const {
  return ToolChain::UNW_None;
}

Tool *LVXToolChain::buildLinker() const { return new tools::LVX::Linker(*this); }

void LVX::Linker::ConstructJob(Compilation &C, const JobAction &JA,
                               const InputInfo &Output,
                               const InputInfoList &Inputs, const ArgList &Args,
                               const char *LinkingOutput) const {
  const auto &TC = static_cast<const LVXToolChain &>(getToolChain());
  const Driver &D = TC.getDriver();
  ArgStringList CmdArgs;

  if (!D.SysRoot.empty())
    CmdArgs.push_back(Args.MakeArgString("--sysroot=" + D.SysRoot));

  bool WantCRTs =
      !Args.hasArg(options::OPT_nostdlib, options::OPT_nostartfiles);

  // The order is lvx-gcc's own, read off its -v output rather than assumed:
  // crti, crtbegin, crt0 going in, crtend and crtn coming out. crt0 after the
  // other two is unusual and is what the installed runtime expects.
  if (WantCRTs) {
    CmdArgs.push_back(Args.MakeArgString(TC.GetFilePath("crti.o")));
    CmdArgs.push_back(Args.MakeArgString(TC.GetFilePath("crtbegin.o")));
    CmdArgs.push_back(Args.MakeArgString(TC.GetFilePath("crt0.o")));
  }

  Args.AddAllArgs(CmdArgs, options::OPT_L);
  TC.AddFilePathLibArgs(Args, CmdArgs);
  // OPT_T_Group is what carries -T: a bare-metal link needs the script for the
  // heap bounds (_heap_start/_heap_end, which libgloss's sbrk reads) and lvx-gcc
  // does not supply one either, so an explicit -T is part of the recipe on both
  // compilers rather than something clang defaults differently.
  Args.addAllArgs(CmdArgs, {options::OPT_T_Group, options::OPT_s,
                            options::OPT_t, options::OPT_r});

  AddLinkerInputs(TC, Inputs, Args, CmdArgs, JA);

  if (!Args.hasArg(options::OPT_nostdlib) &&
      !Args.hasArg(options::OPT_nodefaultlibs)) {
    // -lgcc on both sides of the group, as lvx-gcc emits it: libgcc needs libc
    // (memcpy out of the vector helpers) and libc needs libgcc (the division
    // helpers), and the group alone does not close that cycle.
    CmdArgs.push_back("-lgcc");
    CmdArgs.push_back("--start-group");
    CmdArgs.push_back("-lc");
    CmdArgs.push_back("-lgloss");
    CmdArgs.push_back("--end-group");
    CmdArgs.push_back("-lgcc");
  }

  if (WantCRTs) {
    CmdArgs.push_back(Args.MakeArgString(TC.GetFilePath("crtend.o")));
    CmdArgs.push_back(Args.MakeArgString(TC.GetFilePath("crtn.o")));
  }

  CmdArgs.push_back("-o");
  CmdArgs.push_back(Output.getFilename());
  C.addCommand(std::make_unique<Command>(
      JA, *this, ResponseFileSupport::AtFileCurCP(),
      Args.MakeArgString(TC.GetLinkerPath()), CmdArgs, Inputs, Output));
}
