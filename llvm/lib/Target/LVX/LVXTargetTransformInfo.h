//===-- LVXTargetTransformInfo.h - LVX specific TTI -------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// What the middle end is allowed to assume about this target's cost model.
// Until now there was no TTI at all, which is not neutral: it means the
// vectorizers run against BasicTTIImpl's defaults, invent vector types this
// back end has no instructions for, and are stopped -- if at all -- only by
// -fno-vectorize on the command line.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_LVX_LVXTARGETTRANSFORMINFO_H
#define LLVM_LIB_TARGET_LVX_LVXTARGETTRANSFORMINFO_H

#include "LVXSubtarget.h"
#include "LVXTargetMachine.h"
#include "llvm/Analysis/TargetTransformInfo.h"
#include "llvm/CodeGen/BasicTTIImpl.h"

namespace llvm {

class LVXTTIImpl final : public BasicTTIImplBase<LVXTTIImpl> {
  using BaseT = BasicTTIImplBase<LVXTTIImpl>;
  using TTI = TargetTransformInfo;
  friend BaseT;

  const LVXSubtarget *ST;
  const LVXTargetLowering *TLI;

  const LVXSubtarget *getST() const { return ST; }
  const LVXTargetLowering *getTLI() const { return TLI; }

public:
  explicit LVXTTIImpl(const LVXTargetMachine *TM, const Function &F)
      : BaseT(TM, F.getDataLayout()), ST(TM->getSubtargetImpl(F)),
        TLI(ST->getTargetLowering()) {}

  // No vector registers. This is a statement about the DESCRIPTION this back
  // end was built against, not about the architecture: lib/Target/LVX holds
  // one core's generated description at a time and it is lvx_v1 by default,
  // which has no SIMD at all. lvx-gcc says the same thing the same way --
  // lvx_autovectorize_vector_modes returns 0 unless LVX_2.
  //
  // It cannot be keyed on -mcpu, tempting as that is: validation passes
  // -mcpu=lvx-2 while the build still holds the lvx_v1 description, and
  // reporting vector registers there would vectorize into instructions that
  // are not in this build at all.
  //
  // Reporting 0 is what makes the vectorizers decline. Left absent, they
  // costed against BasicTTIImpl's defaults and vectorized anything -- which
  // on a core with no SIMD is pure loss (every vector operation scalarizes
  // again, plus the packing around it), and reached shapes with no lowering:
  // "bitcast <4 x i1> to i4", the lane-mask packing lvx-2's COMP* does in one
  // instruction and lvx-1 cannot do at all, crashed the legalizer outright.
  //
  // When lib/Target/LVX holds lvx_v2, this is one of the places that changes:
  // 128 bits, and real costs beside it.
  unsigned getNumberOfRegisters(unsigned ClassID) const override {
    bool Vector = ClassID == 1;
    if (Vector)
      return 0;
    return 64; // $r0-$r63
  }

  TypeSize getRegisterBitWidth(TTI::RegisterKind K) const override {
    switch (K) {
    case TTI::RGK_Scalar:
      return TypeSize::getFixed(64);
    case TTI::RGK_FixedWidthVector:
    case TTI::RGK_ScalableVector:
      return TypeSize::getFixed(0);
    }
    llvm_unreachable("Unsupported register kind");
  }

  // A jump table costs a load and an indirect branch through $ra-less igoto,
  // and LVX has no table-branch instruction; the compare chain the middle end
  // builds instead is what lvx-gcc gets too.
  bool shouldBuildLookupTables() const override { return true; }
};

} // end namespace llvm

#endif // LLVM_LIB_TARGET_LVX_LVXTARGETTRANSFORMINFO_H
