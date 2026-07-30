//===- LVXOps.td - LVX dialect operation definitions --------*- tablegen -*-==//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
// Operations mirror real LVX_v1 assembly instructions (mnemonic + modifier
// suffixes), as described by /home/guembu/bd3/lvx-csw/lvx-target
// (lvx_Opcode.txt / lvx_Format.yml / lvx_Modifier.yml / lvx_Synthetic.yml).
// Every operand/result that represents a live machine value has type
// `!lvx.reg` (see LVXBase.td). Precise bit-exact assembly encoding/printing
// (e.g. immediate range splitting for `lvx.li`) is left to a later
// instruction-selection phase; here we only need operation/operand/result
// shapes that are faithful enough to drive register allocation.
//===----------------------------------------------------------------------===//

#ifndef LVX_OPS
#define LVX_OPS

include "mlir/Dialect/LVX/IR/LVXBase.td"
include "mlir/IR/BuiltinAttributeInterfaces.td"
include "mlir/Interfaces/InferTypeOpInterface.td"
include "mlir/Interfaces/SideEffectInterfaces.td"

// Base class for all LVX ops.
class LVX_Op<string mnemonic, list<Trait> traits = []> :
    Op<LVX_Dialect, mnemonic, traits>;

//===----------------------------------------------------------------------===//
// Register pseudo-ops: constant materialization and register-to-register
// move (used e.g. to copy ABI-pinned argument registers into fresh virtual
// registers on function entry).
//===----------------------------------------------------------------------===//

def LVX_LiOp : LVX_Op<"li", [Pure]> {
  let summary = "load an integer or floating-point immediate (pseudo)";
  let description = [{
    Synthetic pseudo-instruction (not a single real opcode) that materializes
    an arbitrary-width constant into a register. Backed by the real 16-bit
    `MAKE`/`PCREL` immediate-load formats (ALU_DWI) for narrow values; wider
    constants expand to a `MAKE` + refinement sequence at assembly-printing
    time, which is out of scope for this dialect.
  }];
  let arguments = (ins TypedAttrInterface:$value);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "attr-dict $value `:` type($result)";
  let hasVerifier = 1;
}

def LVX_MvOp : LVX_Op<"mv", [Pure]> {
  let summary = "register-to-register move";
  let arguments = (ins LVX_RegType:$source);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$source attr-dict `:` functional-type($source, $result)";
}

def LVX_SpOp : LVX_Op<"sp", [Pure]> {
  let summary = "materialize the current stack-pointer value (pseudo)";
  let description = [{
    Synthetic pseudo-instruction (not a real opcode, like `lvx.li`/`lvx.mv`
    above) that materializes the function's current stack-pointer value as
    an SSA value, typed `!lvx.reg<r12>` (R12 is `lvx_Convention.yml`'s
    `stack` register). Inserted by the register allocator's spill rewrite
    (docs/lvx/RegisterAllocation.md, Step 3) to give spill `lvx.sd`/`lvx.ld`
    instructions a base operand; not user-written.
  }];
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "attr-dict `:` type($result)";
}

def LVX_GetraOp : LVX_Op<"getra", [Pure]> {
  let summary = "read the return-address register into a GPR";
  let description = [{
    Backed by the real `GET_registerZ_systemS3` opcode (`$rd = $ra`,
    printed `get`, confirmed against the real `lvx-mbr-as`/`lvx-mbr-objdump`
    -- see docs/lvx/RegisterAllocation.md, "Return-address save/restore").
    $ra is LVX's single hardware link register, written implicitly by
    every real `call` with no software-visible call stack; a non-leaf
    function (one that itself executes a `call`) must snapshot its own
    $ra with this op before making any call of its own, since that call
    will overwrite it. Inserted by the register allocator's non-leaf
    prologue (Step 3), not user-written.
  }];
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "attr-dict `:` type($result)";
}

def LVX_SetraOp : LVX_Op<"setra"> {
  let summary = "write a GPR's value into the return-address register";
  let description = [{
    Backed by the real `SET_systemRA_registerZ` opcode (`$ra = $rs`,
    printed `set`). Restores $ra from a snapshot taken by `lvx.getra` at
    function entry, immediately before `lvx_func.return` in a non-leaf
    function -- see that op's own doc comment. Not `Pure`: writes a
    system register that the real `ret` immediately following depends on
    with no SSA-visible use, a genuine side effect that must not be
    treated as dead code.
  }];
  let arguments = (ins LVX_RegType:$source);
  let assemblyFormat = "$source attr-dict `:` type($source)";
}

//===----------------------------------------------------------------------===//
// Integer arithmetic (paired 64-bit `d` / 32-bit `w` real mnemonics).
//===----------------------------------------------------------------------===//

// Note: operands and result are *not* constrained to the same type. Before
// register allocation all are the same unpinned `!lvx.reg`, but after
// allocation a source and the destination will typically be pinned to
// different physical registers (e.g. `addd $r5, $r1, $r2`), so their types
// must be allowed to diverge; each is printed independently.
class LVX_IntBinaryOp<string mnemonic, list<Trait> traits = []> :
    LVX_Op<mnemonic, traits # [Pure]>,
    Arguments<(ins LVX_RegType:$lhs, LVX_RegType:$rhs)>,
    Results<(outs LVX_RegType:$result)> {
  let assemblyFormat =
    "$lhs `,` $rhs attr-dict `:` `(` type($lhs) `,` type($rhs) `)` `->` type($result)";
}

class LVX_IntUnaryOp<string mnemonic, list<Trait> traits = []> :
    LVX_Op<mnemonic, traits # [Pure]>,
    Arguments<(ins LVX_RegType:$operand)>,
    Results<(outs LVX_RegType:$result)> {
  let assemblyFormat =
    "$operand attr-dict `:` functional-type($operand, $result)";
}

// 64-bit ("d") integer ops.
def LVX_AdddOp : LVX_IntBinaryOp<"addd", [Commutative]> {
  let summary = "ADDD -- 64-bit integer addition";
}
def LVX_SbfdOp : LVX_IntBinaryOp<"sbfd"> {
  let summary = "SBFD -- 64-bit integer subtraction";
}
def LVX_MuldOp : LVX_IntBinaryOp<"muld", [Commutative]> {
  let summary = "MULD -- 64-bit integer multiplication (low bits)";
}
def LVX_AnddOp : LVX_IntBinaryOp<"andd", [Commutative]> {
  let summary = "ANDD -- 64-bit bitwise AND";
}
def LVX_IorddOp : LVX_IntBinaryOp<"iord", [Commutative]> {
  let summary = "IORD -- 64-bit bitwise OR";
}
def LVX_EorddOp : LVX_IntBinaryOp<"eord", [Commutative]> {
  let summary = "EORD -- 64-bit bitwise XOR";
}
def LVX_NotdOp : LVX_IntUnaryOp<"notd"> {
  let summary = "NOTD -- 64-bit bitwise complement";
}
def LVX_SlldOp : LVX_IntBinaryOp<"slld"> {
  let summary = "SLLD -- 64-bit shift left logical";
}
def LVX_SradOp : LVX_IntBinaryOp<"srad"> {
  let summary = "SRAD -- 64-bit shift right arithmetic";
}
def LVX_SrldOp : LVX_IntBinaryOp<"srld"> {
  let summary = "SRLD -- 64-bit shift right logical";
}

// Signed/unsigned 64-bit divide-modulo: real hardware writes quotient and
// remainder into an aligned register pair (registerM); we model this as two
// independent `!lvx.reg` results for now (pairing is a register-allocation
// concern, deferred to that phase).
class LVX_DivModOp<string mnemonic> :
    LVX_Op<mnemonic, []>,
    Arguments<(ins LVX_RegType:$lhs, LVX_RegType:$rhs)>,
    Results<(outs LVX_RegType:$quotient, LVX_RegType:$remainder)> {
  let assemblyFormat =
    "$lhs `,` $rhs attr-dict `:` `(` type($lhs) `,` type($rhs) `)` `->` "
    "`(` type($quotient) `,` type($remainder) `)`";
}
def LVX_DivmoddOp  : LVX_DivModOp<"divmodd"> {
  let summary = "DIVMODD -- signed 64-bit divide-modulo";
}
def LVX_DivmodudOp : LVX_DivModOp<"divmodud"> {
  let summary = "DIVMODUD -- unsigned 64-bit divide-modulo";
}

// 32-bit ("w") integer ops.
def LVX_AddwOp : LVX_IntBinaryOp<"addw", [Commutative]> {
  let summary = "ADDW -- 32-bit integer addition";
}
def LVX_SbfwOp : LVX_IntBinaryOp<"sbfw"> {
  let summary = "SBFW -- 32-bit integer subtraction";
}
def LVX_MulwOp : LVX_IntBinaryOp<"mulw", [Commutative]> {
  let summary = "MULW -- 32-bit integer multiplication (low bits)";
}
def LVX_AndwOp : LVX_IntBinaryOp<"andw", [Commutative]> {
  let summary = "ANDW -- 32-bit bitwise AND";
}
def LVX_IorwOp : LVX_IntBinaryOp<"iorw", [Commutative]> {
  let summary = "IORW -- 32-bit bitwise OR";
}
def LVX_EorwOp : LVX_IntBinaryOp<"eorw", [Commutative]> {
  let summary = "EORW -- 32-bit bitwise XOR";
}
def LVX_NotwOp : LVX_IntUnaryOp<"notw"> {
  let summary = "NOTW -- 32-bit bitwise complement";
}
def LVX_SllwOp : LVX_IntBinaryOp<"sllw"> {
  let summary = "SLLW -- 32-bit shift left logical";
}
def LVX_SrawOp : LVX_IntBinaryOp<"sraw"> {
  let summary = "SRAW -- 32-bit shift right arithmetic";
}
def LVX_SrlwOp : LVX_IntBinaryOp<"srlw"> {
  let summary = "SRLW -- 32-bit shift right logical";
}
def LVX_DivmodwOp  : LVX_DivModOp<"divmodw"> {
  let summary = "DIVMODW -- signed 32-bit divide-modulo";
}
def LVX_DivmoduwOp : LVX_DivModOp<"divmoduw"> {
  let summary = "DIVMODUW -- unsigned 32-bit divide-modulo";
}

//===----------------------------------------------------------------------===//
// Floating-point arithmetic. Each carries an `LVX_FloatModeAttr` (rounding
// mode, printed as a suffix, e.g. `faddd.rn`); default is `cs` (use the
// mode configured in $cs), matching the empty-suffix case in lvx_Modifier.yml.
//===----------------------------------------------------------------------===//

class LVX_FloatBinaryOp<string mnemonic, list<Trait> traits = []> :
    LVX_Op<mnemonic, traits # [Pure]>,
    Arguments<(ins LVX_RegType:$lhs, LVX_RegType:$rhs,
                  DefaultValuedAttr<LVX_FloatModeAttr, "FloatMode::cs">:$mode)>,
    Results<(outs LVX_RegType:$result)> {
  let assemblyFormat =
    "$mode $lhs `,` $rhs attr-dict `:` `(` type($lhs) `,` type($rhs) `)` `->` type($result)";
}

// Real FFMAD/FFMAW/FFMSD/FFMSW/FFMAH/FFMSH (lvx-mds Opcode.table's
// `registerW_registerZ_registerY` shape) only have *two* explicit source
// registers (Z, Y); the destination (W) doubles as the third, implicit
// "accumulate into" operand -- syntax is `ffmad $rW = $rZ, $rY`, computing
// `$rW := $rZ * $rY [+|-] $rW` in place. There is no separate destination
// field. This dialect still models it as a plain 3-independent-operand SSA
// op (`a`, `b`, `c` -> `result`, no `SameOperandsAndResultType`-style
// constraint at the type-system level, consistent with this dialect's
// general stance -- see top-level CLAUDE.md's "type-system invariant to
// preserve"), but `-lvx-allocate-registers` must coalesce `c` and `result`
// into the *same* physical register before `-lvx-emit-asm` can print a
// real instruction -- see docs/lvx/RegisterAllocation.md, "`ffma`/`ffms`
// accumulator coalescing".
class LVX_FloatTernaryOp<string mnemonic, list<Trait> traits = []> :
    LVX_Op<mnemonic, traits # [Pure]>,
    Arguments<(ins LVX_RegType:$a, LVX_RegType:$b, LVX_RegType:$c,
                  DefaultValuedAttr<LVX_FloatModeAttr, "FloatMode::cs">:$mode)>,
    Results<(outs LVX_RegType:$result)> {
  let assemblyFormat =
    "$mode $a `,` $b `,` $c attr-dict `:` "
    "`(` type($a) `,` type($b) `,` type($c) `)` `->` type($result)";
}

def LVX_FadddOp : LVX_FloatBinaryOp<"faddd"> {
  let summary = "FADDD -- double-precision floating-point addition";
}
def LVX_FsbfdOp : LVX_FloatBinaryOp<"fsbfd"> {
  let summary = "FSBFD -- double-precision floating-point subtraction";
}
def LVX_FmuldOp : LVX_FloatBinaryOp<"fmuld"> {
  let summary = "FMULD -- double-precision floating-point multiplication";
}
def LVX_FdivdOp : LVX_FloatBinaryOp<"fdivd"> {
  let summary = "FDIVD -- double-precision floating-point division";
}
def LVX_FfmadOp : LVX_FloatTernaryOp<"ffmad"> {
  let summary = "FFMAD -- double-precision fused multiply-add: a*b+c";
}
// Real hardware's `f64_mulnAdd` negates the *product*, not the whole
// expression: `result = c - a*b`, not `a*b - c` (confirmed against
// lvx-mds Opcode.table's FFMSD execution semantics, which previously
// disagreed with this summary -- an actual doc/semantics bug, not just a
// missing feature, since a lowering pattern written against the old text
// would compute the wrong sign).
def LVX_FfmsdOp : LVX_FloatTernaryOp<"ffmsd"> {
  let summary = "FFMSD -- double-precision fused multiply-subtract: c-a*b";
}

def LVX_FaddwOp : LVX_FloatBinaryOp<"faddw"> {
  let summary = "FADDW -- single-precision floating-point addition";
}
def LVX_FsbfwOp : LVX_FloatBinaryOp<"fsbfw"> {
  let summary = "FSBFW -- single-precision floating-point subtraction";
}
def LVX_FmulwOp : LVX_FloatBinaryOp<"fmulw"> {
  let summary = "FMULW -- single-precision floating-point multiplication";
}
def LVX_FdivwOp : LVX_FloatBinaryOp<"fdivw"> {
  let summary = "FDIVW -- single-precision floating-point division";
}
def LVX_FfmawOp : LVX_FloatTernaryOp<"ffmaw"> {
  let summary = "FFMAW -- single-precision fused multiply-add: a*b+c";
}
// See LVX_FfmsdOp: same `c - a*b` correction applies here.
def LVX_FfmswOp : LVX_FloatTernaryOp<"ffmsw"> {
  let summary = "FFMSW -- single-precision fused multiply-subtract: c-a*b";
}

//===----------------------------------------------------------------------===//
// Comparisons. Real hardware writes a full register (0/1), not a flag bit.
//===----------------------------------------------------------------------===//

def LVX_CompdOp : LVX_Op<"compd", [Pure]> {
  let summary = "COMPD -- 64-bit integer comparison";
  let arguments = (ins LVX_IntCompAttr:$predicate,
                       LVX_RegType:$lhs, LVX_RegType:$rhs);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat =
    "$predicate $lhs `,` $rhs attr-dict `:` `(` type($lhs) `,` type($rhs) `)` `->` type($result)";
}

def LVX_CompwOp : LVX_Op<"compw", [Pure]> {
  let summary = "COMPW -- 32-bit integer comparison";
  let arguments = (ins LVX_IntCompAttr:$predicate,
                       LVX_RegType:$lhs, LVX_RegType:$rhs);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat =
    "$predicate $lhs `,` $rhs attr-dict `:` `(` type($lhs) `,` type($rhs) `)` `->` type($result)";
}

def LVX_FcompdOp : LVX_Op<"fcompd", [Pure]> {
  let summary = "FCOMPD -- double-precision floating-point comparison";
  let arguments = (ins LVX_FloatCompAttr:$predicate,
                       LVX_RegType:$lhs, LVX_RegType:$rhs);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat =
    "$predicate $lhs `,` $rhs attr-dict `:` `(` type($lhs) `,` type($rhs) `)` `->` type($result)";
}

def LVX_FcompwOp : LVX_Op<"fcompw", [Pure]> {
  let summary = "FCOMPW -- single-precision floating-point comparison";
  let arguments = (ins LVX_FloatCompAttr:$predicate,
                       LVX_RegType:$lhs, LVX_RegType:$rhs);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat =
    "$predicate $lhs `,` $rhs attr-dict `:` `(` type($lhs) `,` type($rhs) `)` `->` type($result)";
}

//===----------------------------------------------------------------------===//
// Conditional move (CMOVED/CMOVEQ). Per the ground truth
// (FE/YAML/lvx/lvx_v1/Description.yml), the `cmovecond` modifier field is
// parsed with the same enumeration as `bcucond`, so we reuse LVX_BcuCondAttr
// rather than introducing a separate (unexported) enum.
//===----------------------------------------------------------------------===//

def LVX_CmovedOp : LVX_Op<"cmoved", [Pure]> {
  let summary = "CMOVED -- conditional move, selects between two registers";
  let arguments = (ins LVX_BcuCondAttr:$condition,
                       LVX_RegType:$test,
                       LVX_RegType:$trueValue,
                       LVX_RegType:$falseValue);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = [{
    $condition $test `,` $trueValue `,` $falseValue attr-dict `:`
    `(` type($test) `,` type($trueValue) `,` type($falseValue) `)` `->` type($result)
  }];
}

//===----------------------------------------------------------------------===//
// Memory ops: base register + signed 10-bit immediate offset (LSU_LSBO /
// LSU_SSBO). No memref types here -- address linearization from `memref`
// happens in the ConvertToLVX lowering pass, before these ops are created.
//===----------------------------------------------------------------------===//

class LVX_LoadOp<string mnemonic> :
    LVX_Op<mnemonic>,
    Arguments<(ins LVX_RegType:$base, SI32Attr:$offset)>,
    Results<(outs LVX_RegType:$result)> {
  let assemblyFormat =
    "$base `,` $offset attr-dict `:` functional-type($base, $result)";
}

def LVX_LbzOp : LVX_LoadOp<"lbz"> { let summary = "LBZ -- load byte, zero-extend"; }
def LVX_LbsOp : LVX_LoadOp<"lbs"> { let summary = "LBS -- load byte, sign-extend"; }
def LVX_LhzOp : LVX_LoadOp<"lhz"> { let summary = "LHZ -- load half-word, zero-extend"; }
def LVX_LhsOp : LVX_LoadOp<"lhs"> { let summary = "LHS -- load half-word, sign-extend"; }
def LVX_LwzOp : LVX_LoadOp<"lwz"> { let summary = "LWZ -- load word, zero-extend"; }
def LVX_LwsOp : LVX_LoadOp<"lws"> { let summary = "LWS -- load word, sign-extend"; }
def LVX_LdOp  : LVX_LoadOp<"ld">  { let summary = "LD -- load double word"; }

class LVX_StoreOp<string mnemonic> :
    LVX_Op<mnemonic>,
    Arguments<(ins LVX_RegType:$value, LVX_RegType:$base, SI32Attr:$offset)> {
  let assemblyFormat =
    "$value `,` $base `,` $offset attr-dict `:` `(` type($value) `,` type($base) `)`";
}

def LVX_SbOp : LVX_StoreOp<"sb"> { let summary = "SB -- store byte"; }
def LVX_ShOp : LVX_StoreOp<"sh"> { let summary = "SH -- store half-word"; }
def LVX_SwOp : LVX_StoreOp<"sw"> { let summary = "SW -- store word"; }
def LVX_SdOp : LVX_StoreOp<"sd"> { let summary = "SD -- store double word"; }

//===----------------------------------------------------------------------===//
// Control flow: unconditional/direct jump primitives (BCU_UB). Structured
// (`lvx_scf`) and unstructured-with-successors (`lvx_cf`) control flow live
// in their own sibling dialects; `lvx.goto`/`lvx.call` here are the
// leaf real-opcode building blocks referenced by those dialects' lowering
// and by `lvx_func.call`.
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Casts, backed by lvx_Synthetic.yml pseudo-instructions.
//===----------------------------------------------------------------------===//

class LVX_CastOp<string mnemonic, list<Trait> traits = []> :
    LVX_Op<mnemonic, traits # [Pure]>,
    Arguments<(ins LVX_RegType:$in)>,
    Results<(outs LVX_RegType:$out)>{
  let assemblyFormat = "$in attr-dict `:` functional-type($in, $out)";
}

def LVX_ZxbdOp : LVX_CastOp<"zxbd"> {
  let summary = "ZXBD (synthetic, EXTFZ) -- zero-extend byte to double word";
}
def LVX_SxbdOp : LVX_CastOp<"sxbd"> {
  let summary = "SXBD (synthetic, EXTFS) -- sign-extend byte to double word";
}
def LVX_ZxhdOp : LVX_CastOp<"zxhd"> {
  let summary = "ZXHD (synthetic, EXTFZ) -- zero-extend half word to double word";
}
def LVX_SxhdOp : LVX_CastOp<"sxhd"> {
  let summary = "SXHD (synthetic, EXTFS) -- sign-extend half word to double word";
}
def LVX_ZxwdOp : LVX_CastOp<"zxwd"> {
  let summary = "ZXWD (synthetic, EXTFZ) -- zero-extend word to double word";
}
def LVX_SxwdOp : LVX_CastOp<"sxwd"> {
  let summary = "SXWD (synthetic, EXTFS) -- sign-extend word to double word";
}
def LVX_CopywOp : LVX_CastOp<"copyw"> {
  let summary = "COPYW (synthetic, SLLW #0) -- truncate/copy to word width";
}
def LVX_CopydOp : LVX_CastOp<"copyd"> {
  let summary = "COPYD (synthetic, IORD #0) -- copy double word";
}

// Integer <-> floating-point conversions and bitcast do not have direct
// lvx_Synthetic.yml pseudo-mnemonics exported yet; keep them as thin
// dialect-native casts for now (flagged for a follow-up ground-truth pass
// once the relevant ALU_FD*FLOAT / ALU_FD*FIXED formats are exported).
def LVX_SitofpOp : LVX_CastOp<"sitofp"> {
  let summary = "signed integer to floating-point (ALU_FDFLOAT family)";
}
def LVX_UitofpOp : LVX_CastOp<"uitofp"> {
  let summary = "unsigned integer to floating-point (ALU_FDFLOAT family)";
}
def LVX_FptosiOp : LVX_CastOp<"fptosi"> {
  let summary = "floating-point to signed integer (ALU_FDFIXED family)";
}
def LVX_FptouiOp : LVX_CastOp<"fptoui"> {
  let summary = "floating-point to unsigned integer (ALU_FDFIXED family)";
}
def LVX_FdtofwOp : LVX_CastOp<"fdtofw"> {
  let summary = "double-precision to single-precision narrowing (ALU_FDMO family)";
}
def LVX_FwtofdOp : LVX_CastOp<"fwtofd"> {
  let summary = "single-precision to double-precision widening (ALU_FWWIDEN family)";
}
def LVX_BitcastOp : LVX_CastOp<"bitcast"> {
  let summary = "bitcast between same-width types (no-op at the register level)";
}

#endif // LVX_OPS
