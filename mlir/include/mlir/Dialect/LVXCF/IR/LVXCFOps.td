//===- LVXCFOps.td - LVX_cf dialect operation definitions ----*- tablegen -*-==//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LVX_CF_OPS
#define LVX_CF_OPS

include "mlir/Dialect/LVXCF/IR/LVXCFBase.td"
include "mlir/Dialect/LVX/IR/LVXBase.td"
include "mlir/Interfaces/ControlFlowInterfaces.td"
include "mlir/Interfaces/SideEffectInterfaces.td"

class LVXCF_Op<string mnemonic, list<Trait> traits = []> :
    Op<LVXCF_Dialect, mnemonic, traits>;

def LVXCF_BranchOp : LVXCF_Op<"br",
    [DeclareOpInterfaceMethods<BranchOpInterface, ["getSuccessorForOperands"]>,
     Pure, Terminator]> {
  let summary = "GOTO -- unconditional direct jump";
  let arguments = (ins Variadic<LVX_RegType>:$destOperands);
  let successors = (successor AnySuccessor:$dest);
  let builders = [
    OpBuilder<(ins "Block *":$dest,
                   CArg<"ValueRange", "{}">:$destOperands), [{
      $_state.addSuccessors(dest);
      $_state.addOperands(destOperands);
    }]>];
  let assemblyFormat = [{
    $dest (`(` $destOperands^ `:` qualified(type($destOperands)) `)`)? attr-dict
  }];
}

def LVXCF_LoopendOp : LVXCF_Op<"loopend",
    [DeclareOpInterfaceMethods<BranchOpInterface, ["getSuccessorForOperands"]>,
     Pure, Terminator]> {
  let summary = "end of a hardware-loop body -- emits no instruction";
  let description = [{
    Terminates an `lvx_cf.loopdo` body. Structurally it is an
    `lvx_cf.br` to the loop's exit block, and it carries the same
    forwarded operands, so the CFG and every liveness/coalescing analysis
    see the real fall-out edge. It implements `BranchOpInterface` for
    exactly that reason.

    The difference is what `-lvx-emit-asm` does with it: **nothing but a
    comment**. A hardware loop's back-edge is implicit -- LOOPDO decrements
    LC and jumps in hardware, with no instruction at the body's end -- so
    emitting a real `goto` here would override that back-edge and run the
    loop exactly once regardless of the trip count.

    A plain `lvx_cf.br` to the exit block expresses the same edge and used
    to be what this pass emitted, relying on `-lvx-emit-asm` eliding a
    branch whose target is the next block in layout order. That worked, but
    it made a *peephole* load-bearing: reordering blocks, or making the
    elision smarter, would silently truncate every hardware loop with no
    IR-level test failing. This op moves the decision into the IR, where it
    is stated rather than inferred.
  }];
  let arguments = (ins Variadic<LVX_RegType>:$destOperands);
  let successors = (successor AnySuccessor:$dest);
  let builders = [
    OpBuilder<(ins "Block *":$dest,
                   CArg<"ValueRange", "{}">:$destOperands), [{
      $_state.addSuccessors(dest);
      $_state.addOperands(destOperands);
    }]>];
  let assemblyFormat = [{
    $dest (`(` $destOperands^ `:` qualified(type($destOperands)) `)`)? attr-dict
  }];
}

def LVXCF_CondBranchOp : LVXCF_Op<"cond_br",
    [AttrSizedOperandSegments,
     DeclareOpInterfaceMethods<BranchOpInterface, ["getSuccessorForOperands"]>,
     Pure, Terminator]> {
  let summary = "CB -- conditional branch, tests $test against $condition (bcucond)";
  let arguments = (ins LVX_RegType:$test,
                       LVX_BcuCondAttr:$condition,
                       Variadic<LVX_RegType>:$trueDestOperands,
                       Variadic<LVX_RegType>:$falseDestOperands);
  let successors = (successor AnySuccessor:$trueDest,
                              AnySuccessor:$falseDest);
  let builders = [
    OpBuilder<(ins "Value":$test, "::mlir::lvx::BcuCond":$condition,
                   "Block *":$trueDest, "ValueRange":$trueOperands,
                   "Block *":$falseDest, "ValueRange":$falseOperands), [{
      build($_builder, $_state, test, condition, trueOperands, falseOperands,
            trueDest, falseDest);
    }]>];
  let assemblyFormat = [{
    $condition $test `:` qualified(type($test)) `,`
    $trueDest  (`(` $trueDestOperands^  `:` qualified(type($trueDestOperands))  `)`)? `,`
    $falseDest (`(` $falseDestOperands^ `:` qualified(type($falseDestOperands)) `)`)?
    attr-dict
  }];
}

def LVXCF_LoopdoOp : LVXCF_Op<"loopdo",
    [AttrSizedOperandSegments,
     DeclareOpInterfaceMethods<BranchOpInterface, ["getSuccessorForOperands"]>,
     Terminator]> {
  let summary = "LOOPDO -- hardware zero-overhead loop setup (BCU_HLS)";
  let description = [{
    Sets the hardware loop registers (LS = next bundle, LE = this bundle's
    PC plus the branch-offset encoding `$exit`'s target, LC = `$tripCount`)
    and falls through into `$body` -- there is no branch instruction here
    for the normal case, `$tripCount` iterations simply execute starting at
    the very next bundle. If `$tripCount` is zero, real hardware jumps
    straight to `$exit` instead (LVX's own "skip the body entirely"
    semantics, explicitly different from KVX's infinite-loop-on-zero
    behavior for the same opcode -- see lvx-mlir/docs/HardwareLoops.md).

    `$body`'s own terminator must be an `lvx_cf.loopend` targeting `$exit`
    (never anywhere else). It emits a comment and no instruction: an
    explicit `goto` there would be a real branch, which per LOOPDO's own
    semantics overrides the hardware back-edge and would make the loop run
    exactly once regardless of `$tripCount`.

    That used to be a plain `lvx_cf.br`, correct only because
    `-lvx-emit-asm` elides a branch to the immediately-following block --
    i.e. correctness rested on a peephole and on block layout order. See
    `lvx_cf.loopend` and lvx-mlir/docs/HardwareLoops.md.
  }];
  let arguments = (ins LVX_RegType:$tripCount,
                       Variadic<LVX_RegType>:$bodyOperands,
                       Variadic<LVX_RegType>:$exitOperands);
  let successors = (successor AnySuccessor:$body, AnySuccessor:$exit);
  let builders = [
    OpBuilder<(ins "Value":$tripCount,
                   "Block *":$body, "ValueRange":$bodyOperands,
                   "Block *":$exit, "ValueRange":$exitOperands), [{
      build($_builder, $_state, tripCount, bodyOperands, exitOperands,
            body, exit);
    }]>];
  let assemblyFormat = [{
    $tripCount `:` qualified(type($tripCount)) `,`
    $body (`(` $bodyOperands^ `:` qualified(type($bodyOperands)) `)`)? `,`
    $exit (`(` $exitOperands^ `:` qualified(type($exitOperands)) `)`)?
    attr-dict
  }];
}

#endif // LVX_CF_OPS
