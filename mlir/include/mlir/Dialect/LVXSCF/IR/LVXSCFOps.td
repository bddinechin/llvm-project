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

def LVXSCF_TokenType : TypeDef<LVXSCF_Dialect, "Token"> {
  let mnemonic = "token";
  let summary = "names an `lvx_scf.loop` for the breaks that leave it";
  let description = [{
    The type of an `lvx_scf.loop`'s one block argument. It is not a value in
    any register: its only use is as the target of an `lvx_scf.break`, which
    is how a break nested in several regions says which loop it leaves.
  }];
}

def LVXSCF_YieldOp : LVXSCF_Op<"yield",
    [Pure, ReturnLike, Terminator, ParentOneOf<["ForOp", "IfOp"]>]> {
  let summary = "loop-carried values produced by one iteration of `lvx_scf.for`";
  let description = [{
    Also the end of an `lvx_scf.if` whose region falls through, with no
    values: an `if` has no results.
  }];
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

//===----------------------------------------------------------------------===//
// Structured early exits
//
// Upstream's proposal (llvm-project #166688) -- `scf.loop`, `scf.break`,
// `scf.continue`, and an `scf.if` a break may leave through -- with its syntax
// and meaning, so that moving to the upstream ops is a rename if it lands.
// Not taken from upstream because nothing that reads it here goes through
// upstream's interfaces: see docs/SoftwarePipelining.md, section 8 step 2c.
//
// First cut: no `continue`, no `iter_args`, no else region and no `if`
// results. A loop with no `continue` runs once, so it is a block with forward
// exits -- the shape of a software pipeline's remainder, whose counted exits
// each run a drain and leave with the live-outs.
//===----------------------------------------------------------------------===//

def LVXSCF_LoopOp : LVXSCF_Op<"loop", [RecursiveMemoryEffects]> {
  let summary = "a region left by `lvx_scf.break`, with the break's values";
  let description = [{
    The body is one block whose only argument is the loop's token, and which
    ends in an `lvx_scf.break`, of this loop or of one around it. A break
    nested in `lvx_scf.if`s and inner `lvx_scf.loop`s leaves it too, naming
    it by the token. Each break's operands become the
    loop's results, so every break of a loop carries the same types.

    ```mlir
    %r = lvx_scf.loop token(%L) -> (!lvx.reg) {
      lvx_scf.if wnez %done : !lvx.reg {
        lvx_scf.break [%L] %a : !lvx.reg
      }
      lvx_scf.break [%L] %b : !lvx.reg
    }
    ```

    Without `continue` the body runs once, so the loop is what upstream calls
    an early-exit region. There is no back edge, which is why liveness and
    allocation need nothing of `lvx_scf.for`'s re-execution handling here.
  }];
  let arguments = (ins LVX_CycleAttr:$cycle);
  let results = (outs Variadic<LVX_AnyRegType>:$results);
  let regions = (region SizedRegion<1>:$region);
  let hasCustomAssemblyFormat = 1;
  let hasRegionVerifier = 1;
  let skipDefaultBuilders = 1;
  let builders = [
    // An empty body block holding the token; the caller fills it and ends
    // it with a break.
    OpBuilder<(ins "::mlir::TypeRange":$results)>];
  let extraClassDeclaration = [{
    Block *getBody() { return &getRegion().front(); }
    Value getToken() { return getBody()->getArgument(0); }
  }];
}

def LVXSCF_BreakOp : LVXSCF_Op<"break", [Pure, Terminator]> {
  let summary = "leave the `lvx_scf.loop` that `token` names, with `args`";
  let description = [{
    Ends a loop's body, or an `lvx_scf.if` region inside it, at any depth:
    every op between the break and its loop must be an `lvx_scf.if` or an
    inner `lvx_scf.loop`, each of which runs at most once, so the exit is
    always forward.
    `args` become the loop's results and must match their types.
  }];
  let arguments = (ins LVXSCF_TokenType:$token,
                       Variadic<LVX_AnyRegType>:$args,
                       LVX_CycleAttr:$cycle);
  let assemblyFormat = [{
    ` ` `[` $token `]` ($args^ `:` qualified(type($args)))? attr-dict
  }];
  let hasVerifier = 1;
  let builders = [
    OpBuilder<(ins "::mlir::Value":$token, "::mlir::ValueRange":$args), [{
      build($_builder, $_state, token, args, ::mlir::IntegerAttr());
    }]>];
  let extraClassDeclaration = [{
    /// The loop this break leaves.
    LoopOp getLoop();
  }];
}

def LVXSCF_IfOp : LVXSCF_Op<"if", [RecursiveMemoryEffects, NoRegionArguments]> {
  let summary = "run the region when `test` passes `condition` (a CB test)";
  let description = [{
    The region runs when `test` satisfies the `BcuCond` `condition`, the same
    pair `lvx_cf.cond_br` and `lvx.guarded` carry, so lowering it costs one
    `cb` on the complementary condition and no compare. It ends either in an
    `lvx_scf.yield` with no values, which the printer and parser leave
    implicit, or in an `lvx_scf.break` that leaves an enclosing loop.

    ```mlir
    lvx_scf.if wnez %t : !lvx.reg {
      ...
      lvx_scf.break [%L] %v : !lvx.reg
    }
    ```

    A then-region only and no results: a pipeline's counted exit needs no
    more, and its drain leaves through the break.
  }];
  let arguments = (ins LVX_BcuCondAttr:$condition, LVX_RegType:$test,
                       LVX_CycleAttr:$cycle);
  let regions = (region SizedRegion<1>:$thenRegion);
  let hasCustomAssemblyFormat = 1;
  let hasRegionVerifier = 1;
  let skipDefaultBuilders = 1;
  let builders = [
    // The region holds an implicit `yield`; a caller that breaks instead
    // replaces it.
    OpBuilder<(ins "::mlir::lvx::BcuCond":$condition, "::mlir::Value":$test)>];
  let extraClassDeclaration = [{
    Block *getThenBlock() { return &getThenRegion().front(); }
  }];
}

#endif // LVX_SCF_OPS
