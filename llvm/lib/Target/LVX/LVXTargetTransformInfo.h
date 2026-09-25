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

  // Whether this build has lane-wise ARITHMETIC, counted from the generated
  // per-core list. Not a hand-written flag and not keyed on -mcpu:
  // lib/Target/LVX holds one core's description at a time, validation passes
  // -mcpu=lvx-2 against a build that may hold lvx_v1, and reporting vector
  // registers there would vectorize into instructions this build does not
  // contain.
  //
  // Splats are deliberately NOT counted. lvx-1 has splatbq/hq/wq/dq and no
  // lane-wise arithmetic at all, so a vectorized loop there is still unrolled
  // to scalars with packing around it -- pure loss, which is what the
  // vectorizer must be told by reporting no vector registers. Only an
  // operation that computes makes a vector worth forming.
  static constexpr unsigned LaneOps = 0
#define LVX_LANE_OP(OP, VT) +1
#include "LVXLaneSIMD.inc"
      ;
  static constexpr bool HasLaneSIMD = LaneOps != 0;

  // Left absent entirely, the vectorizers costed against BasicTTIImpl's
  // defaults and vectorized anything, reaching shapes with no lowering:
  // "bitcast <4 x i1> to i4", the lane-mask packing lvx-2's COMP* does in one
  // instruction and lvx-1 cannot do at all, crashed the legalizer outright.
  unsigned getNumberOfRegisters(unsigned ClassID) const override {
    bool Vector = ClassID == 1;
    if (Vector)
      return HasLaneSIMD ? 64 : 0;
    return 64; // $r0-$r63
  }

  TypeSize getRegisterBitWidth(TTI::RegisterKind K) const override {
    switch (K) {
    case TTI::RGK_Scalar:
      return TypeSize::getFixed(64);
    case TTI::RGK_FixedWidthVector:
      // The lane-wise instructions are 128-bit; a 256-bit operation is two
      // of them, which lvx-gcc costs as no ALU gain (see its
      // lvx_autovectorize_vector_modes).
      return TypeSize::getFixed(HasLaneSIMD ? 128 : 0);
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
