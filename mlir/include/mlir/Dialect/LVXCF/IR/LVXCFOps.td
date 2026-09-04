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
  // The widened encoding, per design document O3. `cb`/`cbx`, `ccb`/`ccbx`,
  // `goto`/`gotox` and `call`/`callx` are the same operation with a wider
  // pc-relative displacement -- their FORMATS are `BCU_CB` and `BCU_CB.X`,
  // exactly the relationship `ALU_DWRI` and `ALU_DWRI.X` have for `addd` --
  // so the widened form is `format = x` on this op, not a second op.
  //
  // MDS gives them two `instruction=` records, which is what O3 originally
  // read as "widening is a change of mnemonic". It is bookkeeping: the
  // partition key is a choice, and D1 already excludes modifiers from it and
  // O5 the RegClass. One op with an attribute needs no cb/cbx pairing table
  // and no op-replacement pass, and it is the only model that stays correct
  // when the assembler grows automatic selection -- at which point the
  // attribute stops being load-bearing and reverts to what O2 says it is for
  // the ALU family, an input to bundle packing.
  //
  // It does NOT relax today: `cb` to a target 600 KB away is "Error: branch
  // out of range" from the real lvx-mbr-as, while `cbx` assembles. So
  // something must set this before a far branch can be emitted at all -- a
  // relaxation pass, which does not exist yet. Absent means the near form,
  // and the ranges are tight enough to matter: `ccb` reaches +/-4 KB, `cb`
  // +/-256 KB, `goto` and `call` +/-256 MB.
  let arguments = (ins Variadic<LVX_RegType>:$destOperands,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let successors = (successor AnySuccessor:$dest);
  let builders = [
    OpBuilder<(ins "Block *":$dest,
                   CArg<"ValueRange", "{}">:$destOperands), [{
      $_state.addSuccessors(dest);
      $_state.addOperands(destOperands);
    }]>];
  // `$format` is spelled as a keyword rather than left to attr-dict, which
  // cannot round-trip it: LVX_FormatAttr is a specialized enum attribute and
  // this dialect registers no attribute parsing hook, so `#lvx<Format x>` is
  // unparseable. Inside an assembly format the generated parser knows the
  // enum, which is how `$variant` on `lvx.ld` already works. Prints as
  // `lvx_cf.br ^bb1 x`.
  let assemblyFormat = [{
    $dest (`(` $destOperands^ `:` qualified(type($destOperands)) `)`)?
    ($format^)? attr-dict
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
  // The widened encoding: see LVXCF_BranchOp's `format`. It applies to the
  // `cb` this op prints, NOT to the fall-through `goto` that follows it when
  // the false edge is not the next block -- that goto has no op of its own to
  // carry an attribute, so it is always the near form.
  let arguments = (ins LVX_RegType:$test,
                       LVX_BcuCondAttr:$condition,
                       Variadic<LVX_RegType>:$trueDestOperands,
                       Variadic<LVX_RegType>:$falseDestOperands,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let successors = (successor AnySuccessor:$trueDest,
                              AnySuccessor:$falseDest);
  let builders = [
    OpBuilder<(ins "Value":$test, "::mlir::lvx::BcuCond":$condition,
                   "Block *":$trueDest, "ValueRange":$trueOperands,
                   "Block *":$falseDest, "ValueRange":$falseOperands), [{
      // The near form: `format` absent. A relaxation pass sets it when a
      // displacement does not fit -- see the `format` argument above.
      build($_builder, $_state, test, condition, trueOperands, falseOperands,
            /*format=*/nullptr, trueDest, falseDest);
    }]>];
  let assemblyFormat = [{
    $condition $test `:` qualified(type($test)) `,`
    $trueDest  (`(` $trueDestOperands^  `:` qualified(type($trueDestOperands))  `)`)? `,`
    $falseDest (`(` $falseDestOperands^ `:` qualified(type($falseDestOperands)) `)`)?
    ($format^)? attr-dict
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
