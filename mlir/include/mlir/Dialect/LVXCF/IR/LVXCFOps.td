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
    $dest (`(` $destOperands^ `:` type($destOperands) `)`)? attr-dict
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
    $condition $test `:` type($test) `,`
    $trueDest  (`(` $trueDestOperands^  `:` type($trueDestOperands)  `)`)? `,`
    $falseDest (`(` $falseDestOperands^ `:` type($falseDestOperands) `)`)?
    attr-dict
  }];
}

#endif // LVX_CF_OPS
