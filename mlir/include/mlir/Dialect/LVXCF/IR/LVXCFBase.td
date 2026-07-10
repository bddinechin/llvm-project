//===- LVXCFBase.td - Base defs for the LVX_cf dialect -------*- tablegen -*-==//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LVX_CF_BASE
#define LVX_CF_BASE

include "mlir/IR/OpBase.td"

def LVXCF_Dialect : Dialect {
  let name = "lvx_cf";
  let cppNamespace = "::mlir::lvx_cf";
  let description = [{
    Unstructured LVX control flow: direct/conditional jumps between blocks,
    mirroring the real BCU_UB (`GOTO`) and BCU_CB (`CB`) instruction formats.
    Kept as a dialect separate from `lvx` (the core ISA) and `lvx_scf`
    (structured loops), following the paper's rv/rv_cf/rv_scf split: control
    flow that survives lowering out of `scf`/`cf` without being captured
    structurally by `lvx_scf.for` ends up here.
  }];
}

#endif // LVX_CF_BASE
