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
include "mlir/Interfaces/LoopLikeInterface.td"
include "mlir/Interfaces/SideEffectInterfaces.td"

class LVXSCF_Op<string mnemonic, list<Trait> traits = []> :
    Op<LVXSCF_Dialect, mnemonic, traits>;

def LVXSCF_YieldOp : LVXSCF_Op<"yield",
    [Pure, ReturnLike, Terminator, HasParent<"ForOp">]> {
  let summary = "loop-carried values produced by one iteration of `lvx_scf.for`";
  let arguments = (ins Variadic<LVX_AnyRegType>:$results, LVX_CycleAttr:$cycle);
  let assemblyFormat = "attr-dict ($results^ `:` qualified(type($results)))?";
  let builders = [
    OpBuilder<(ins), [{ build($_builder, $_state, {}, ::mlir::IntegerAttr()); }]>,
    OpBuilder<(ins "::mlir::ValueRange":$results), [{
      build($_builder, $_state, results, ::mlir::IntegerAttr());
    }]>];
}

def LVXSCF_ForOp : LVXSCF_Op<"for",
    [RecursiveMemoryEffects,
     DeclareOpInterfaceMethods<LoopLikeOpInterface,
         ["getLoopRegions", "getInitsMutable", "getYieldedValuesMutable",
          "getLoopResults"]>,
     SingleBlockImplicitTerminator<"YieldOp">]> {
  let summary = "structured counted loop over `!lvx.reg` bounds/step";
  let description = [{
    `LoopLikeOpInterface` because `-loop-invariant-code-motion` is the only
    thing that can hoist what `-convert-to-lvx` leaves inside a loop: the
    conversion materializes a `lvx.li`/`muld`/`addd` address computation at
    each access, and the part of it that does not depend on the induction
    variable is loop-invariant work created *after* every upstream pass that
    could have moved it. Without the interface the LICM pass does not
    recognize this op as a loop at all and is a byte-for-byte no-op
    (measured: `docs/Vectorization.md` §4). Only `getLoopRegions` is
    implemented; every other interface method has a default, and nothing
    needs more than the region to hoist out of.

    Four methods, not one, and the other three are not optional: the
    interface carries a verifier (`detail::verifyLoopLikeOpInterface`) that
    checks inits against region iter_args, yielded values against iter_args,
    and loop results against iter_args. Their defaults return empty, so
    declaring the interface and implementing only `getLoopRegions` made that
    verifier compare 0 inits against the 1 iter_arg our own
    `getRegionIterArgs` reports -- every loop carrying a value failed to
    verify, in 8 of 45 lit tests. The loop-carried accessors have to agree
    with the shape this op actually has.

    The bounds accessors (`getSingleInductionVar`, `getSingleLowerBound` and
    friends) keep their defaults deliberately: nothing here consumes them,
    and a wrong answer would be worse than no answer.

    Mirrors `scf.for`: the body region's entry block takes the induction
    variable followed by one block argument per loop-carried value
    (`initArgs`), and must end in an `lvx_scf.yield` producing values
    matching `initArgs`'s types, which become this op's results.
  }];
  let arguments = (ins LVX_RegType:$lowerBound,
                       LVX_RegType:$upperBound,
                       LVX_RegType:$step,
                       Variadic<LVX_AnyRegType>:$initArgs,
                       LVX_CycleAttr:$cycle);
  let results = (outs Variadic<LVX_AnyRegType>:$results);
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
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$results, "::mlir::Value":$lowerBound,
                   "::mlir::Value":$upperBound, "::mlir::Value":$step,
                   "::mlir::ValueRange":$initArgs), [{
      build($_builder, $_state, results, lowerBound, upperBound, step,
            initArgs, ::mlir::IntegerAttr());
    }]>];
  let extraClassDeclaration = [{
    Block *getBody() { return &getRegion().front(); }
    Value getInductionVar() { return getBody()->getArgument(0); }
    Block::BlockArgListType getRegionIterArgs() {
      return getBody()->getArguments().drop_front();
    }
  }];
}

#endif // LVX_SCF_OPS
