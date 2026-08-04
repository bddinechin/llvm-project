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

    `$body`'s own terminator must branch to `$exit` too (never anywhere
    else), and that branch must be the last thing printed as *nothing* --
    an explicit `goto` there would be a real branch, which per LOOPDO's own
    semantics overrides the hardware back-edge and would make the loop run
    exactly once regardless of `$tripCount`. See lvx-mlir/docs/HardwareLoops.md
    and `-lvx-emit-asm`'s fallthrough-elision rule, which this depends on
    for correctness, not just as an optimization.
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
