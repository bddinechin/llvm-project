//===- LVXFuncBase.td - Base defs for the LVX_func dialect ---*- tablegen -*-==//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LVX_FUNC_BASE
#define LVX_FUNC_BASE

include "mlir/IR/OpBase.td"

def LVXFunc_Dialect : Dialect {
  let name = "lvx_func";
  let cppNamespace = "::mlir::lvx_func";
  let description = [{
    ABI-constrained function definitions/calls for LVX, per the `regular`
    calling convention (lvx_Convention.yml): up to 12 arguments passed in
    $r0-$r11, up to 4 results returned in $r0-$r3, return address in $ra.
    A function's entry-block argument/result types should be pinned
    physical registers (`!lvx.reg<r0>`, ...); the body copies each into a
    fresh virtual register via `lvx.mv` before running on virtual
    registers, mirroring the paper's `rv.mv` ABI copy-in pattern.
  }];
}

#endif // LVX_FUNC_BASE
