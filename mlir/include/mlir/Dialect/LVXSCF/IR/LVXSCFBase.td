//===- LVXSCFBase.td - Base defs for the LVX_scf dialect -----*- tablegen -*-==//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LVX_SCF_BASE
#define LVX_SCF_BASE

include "mlir/IR/OpBase.td"

def LVXSCF_Dialect : Dialect {
  let name = "lvx_scf";
  let cppNamespace = "::mlir::lvx_scf";
  let description = [{
    Structured LVX control flow: a single `for` loop op mirroring `scf.for`,
    operating on `!lvx.reg` values. Kept structural (not lowered to
    `lvx_cf` branches) through this phase so that a later register
    allocation pass can build live ranges directly from loop structure
    (paper section 3.3), and so a later software-pipelining pass has a loop
    body to transform before that structure is discarded.
  }];
}

#endif // LVX_SCF_BASE
