//===- LVXSCFOps.td - LVX_scf dialect operation definitions --*- tablegen -*-==//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LVX_SCF_OPS
#define LVX_SCF_OPS

include "mlir/Dialect/LVXSCF/IR/LVXSCFBase.td"
include "mlir/Dialect/LVX/IR/LVXBase.td"
include "mlir/Interfaces/ControlFlowInterfaces.td"
include "mlir/Interfaces/SideEffectInterfaces.td"

class LVXSCF_Op<string mnemonic, list<Trait> traits = []> :
    Op<LVXSCF_Dialect, mnemonic, traits>;

def LVXSCF_YieldOp : LVXSCF_Op<"yield",
    [Pure, ReturnLike, Terminator, HasParent<"ForOp">]> {
  let summary = "loop-carried values produced by one iteration of `lvx_scf.for`";
  let arguments = (ins Variadic<LVX_RegType>:$results);
  let assemblyFormat = "attr-dict ($results^ `:` qualified(type($results)))?";
  let builders = [OpBuilder<(ins), [{ build($_builder, $_state, {}); }]>];
}

def LVXSCF_ForOp : LVXSCF_Op<"for",
    [RecursiveMemoryEffects,
     SingleBlockImplicitTerminator<"YieldOp">]> {
  let summary = "structured counted loop over `!lvx.reg` bounds/step";
  let description = [{
    Mirrors `scf.for`: the body region's entry block takes the induction
    variable followed by one block argument per loop-carried value
    (`initArgs`), and must end in an `lvx_scf.yield` producing values
    matching `initArgs`'s types, which become this op's results.
  }];
  let arguments = (ins LVX_RegType:$lowerBound,
                       LVX_RegType:$upperBound,
                       LVX_RegType:$step,
                       Variadic<LVX_RegType>:$initArgs);
  let results = (outs Variadic<LVX_RegType>:$results);
  let regions = (region SizedRegion<1>:$region);
  let assemblyFormat = [{
    $lowerBound `:` qualified(type($lowerBound))
    `to` $upperBound `:` qualified(type($upperBound))
    `step` $step `:` qualified(type($step))
    (`iter_args` `(` $initArgs^ `)` `:` `(` qualified(type($initArgs)) `)`)?
    (`->` `(` qualified(type($results))^ `)`)?
    $region attr-dict
  }];
  let hasVerifier = 1;
  let hasRegionVerifier = 1;
  let extraClassDeclaration = [{
    Block *getBody() { return &getRegion().front(); }
    Value getInductionVar() { return getBody()->getArgument(0); }
    Block::BlockArgListType getRegionIterArgs() {
      return getBody()->getArguments().drop_front();
    }
  }];
}

#endif // LVX_SCF_OPS
