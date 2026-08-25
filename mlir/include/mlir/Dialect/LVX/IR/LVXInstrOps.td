//===-- LVXInstrOps.td - -*- tablegen -*- ===//
//
// Operations for the LVX dialect, one or two per instruction.
//
// Generated from the LVX Machine Description System by MDS/BE/MLIR, for core
// lvx_v1.  DO NOT EDIT -- your changes will be overwritten by the next
// `make -C BE/MLIR install`.  Change lvx-mds/lvx-family's YAML description,
// or the generator in MDS/BE/MLIR/BIN, instead.
//
//===----------------------------------------------------------------===//

#ifndef LVX_INSTR_OPS
#define LVX_INSTR_OPS

include "mlir/Dialect/LVX/IR/LVXBase.td"
include "mlir/Dialect/LVX/IR/LVXModifiers.td"
// Pure, and the side-effect traits a later Behavior parser will also need.
include "mlir/Interfaces/SideEffectInterfaces.td"
// TypedAttrInterface, which every immediate operand is typed as for now.
include "mlir/IR/AttrTypeBase.td"
include "mlir/IR/BuiltinAttributeInterfaces.td"

// Format-extension suffix (O1). The bare format has NO member: absence
// means it, definitely, and never "not yet decided" -- O2. The assembler
// picks the encoding from the value, so this exists to account for size
// (bare/.x/.y are 1/2/3 syllables against a 3-syllable bundle), not to
// instruct the assembler.
def LVX_FormatAttr : I64EnumAttr<
    "Format", "LVX format-extension suffix",
    [
      I64EnumAttrCase<"d",  0, "d"  >,  // 93 formats
      I64EnumAttrCase<"m",  1, "m"  >,  // 57 formats
      I64EnumAttrCase<"o",  2, "o"  >,  // 93 formats
      I64EnumAttrCase<"w",  3, "w"  >,  // 43 formats
      I64EnumAttrCase<"x",  4, "x"  >,  // 44 formats
      I64EnumAttrCase<"y",  5, "y"  >,  // 40 formats
    ]> {
  let cppNamespace = "::mlir::lvx";
}

// ALU:STSUD -- register form, from STSUD_registerW_registerZ_registerY_simple
def LVX_StsudOp : LVX_Op<"stsud", [Pure]>{
  let summary = "STSUD -- Subtract, Test and Shift Unsigned Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:STSUW -- register form, from STSUW_signextw_registerW_registerZ_registerY_simple
def LVX_StsuwOp : LVX_Op<"stsuw", [Pure]>{
  let summary = "STSUW -- Subtract, Test and Shift Unsigned Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ABDD -- register form, from ABDD_registerW_registerZ_registerY_simple
def LVX_AbddOp : LVX_Op<"abdd", [Pure]>{
  let summary = "ABDD -- Absolute Difference Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ABDD -- immediate form, from ABDD_registerW_registerZ_upper27_lower5_splat32_double
def LVX_AbddImmOp : LVX_Op<"abdd_i", [Pure]>{
  let summary = "ABDD -- Absolute Difference Double Word";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`splat32` $splat32^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ABDW -- register form, from ABDW_signextw_registerW_registerZ_registerY_simple
def LVX_AbdwOp : LVX_Op<"abdw", [Pure]>{
  let summary = "ABDW -- Absolute Difference Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ABDW -- immediate form, from ABDW_signextw_registerW_registerZ_upper27_lower5_double
def LVX_AbdwImmOp : LVX_Op<"abdw_i", [Pure]>{
  let summary = "ABDW -- Absolute Difference Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ABDSD -- register form, from ABDSD_registerW_registerZ_registerY_simple
def LVX_AbdsdOp : LVX_Op<"abdsd", [Pure]>{
  let summary = "ABDSD -- Absolute Difference Saturated Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ABDSD -- immediate form, from ABDSD_registerW_registerZ_upper27_lower5_splat32_double
def LVX_AbdsdImmOp : LVX_Op<"abdsd_i", [Pure]>{
  let summary = "ABDSD -- Absolute Difference Saturated Double Word";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`splat32` $splat32^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ABDSW -- register form, from ABDSW_signextw_registerW_registerZ_registerY_simple
def LVX_AbdswOp : LVX_Op<"abdsw", [Pure]>{
  let summary = "ABDSW -- Absolute Difference Saturated Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ABDSW -- immediate form, from ABDSW_signextw_registerW_registerZ_upper27_lower5_double
def LVX_AbdswImmOp : LVX_Op<"abdsw_i", [Pure]>{
  let summary = "ABDSW -- Absolute Difference Saturated Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ABDUD -- register form, from ABDUD_registerW_registerZ_registerY_simple
def LVX_AbdudOp : LVX_Op<"abdud", [Pure]>{
  let summary = "ABDUD -- Absolute Difference Unsigned Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ABDUD -- immediate form, from ABDUD_registerW_registerZ_upper27_lower5_splat32_double
def LVX_AbdudImmOp : LVX_Op<"abdud_i", [Pure]>{
  let summary = "ABDUD -- Absolute Difference Unsigned Double Word";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`splat32` $splat32^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ABDUW -- register form, from ABDUW_signextw_registerW_registerZ_registerY_simple
def LVX_AbduwOp : LVX_Op<"abduw", [Pure]>{
  let summary = "ABDUW -- Absolute Difference Unsigned Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ABDUW -- immediate form, from ABDUW_signextw_registerW_registerZ_upper27_lower5_double
def LVX_AbduwImmOp : LVX_Op<"abduw_i", [Pure]>{
  let summary = "ABDUW -- Absolute Difference Unsigned Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDQ -- register form, from ADDQ_registerM_registerP_registerO_simple
def LVX_AddqOp : LVX_Op<"addq", [Pure]>{
  let summary = "ADDQ -- Add Quadruple Word to Quadruple Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$quotient, LVX_RegType:$remainder);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($quotient)) `,` qualified(type($remainder)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDQ -- immediate form, from ADDQ_registerM_registerP_upper27_lower5_splat32_double
def LVX_AddqImmOp : LVX_Op<"addq_i", [Pure]>{
  let summary = "ADDQ -- Add Quadruple Word to Quadruple Word";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$quotient, LVX_RegType:$remainder);
  let assemblyFormat = "(`splat32` $splat32^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($quotient)) `,` qualified(type($remainder)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDD -- register form, from ADDD_registerW_registerZ_registerY_simple
def LVX_AdddOp : LVX_Op<"addd", [Pure, Commutative]>{
  let summary = "ADDD -- Add Double Word to Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDD -- immediate form, from ADDD_registerW_registerZ_signed10_simple
def LVX_AdddImmOp : LVX_Op<"addd_i", [Pure, Commutative]>{
  let summary = "ADDD -- Add Double Word to Double Word";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$signed10,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$signed10), [{
      build($_builder, $_state, resultType, operand, signed10, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDW -- register form, from ADDW_signextw_registerW_registerZ_registerY_simple
def LVX_AddwOp : LVX_Op<"addw", [Pure, Commutative]>{
  let summary = "ADDW -- Add Word to Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDW -- immediate form, from ADDW_signextw_registerW_registerZ_upper27_lower5_double
def LVX_AddwImmOp : LVX_Op<"addw_i", [Pure, Commutative]>{
  let summary = "ADDW -- Add Word to Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDSD -- register form, from ADDSD_registerW_registerZ_registerY_simple
def LVX_AddsdOp : LVX_Op<"addsd", [Pure]>{
  let summary = "ADDSD -- Add Saturated Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDSD -- immediate form, from ADDSD_registerW_registerZ_upper27_lower5_splat32_double
def LVX_AddsdImmOp : LVX_Op<"addsd_i", [Pure]>{
  let summary = "ADDSD -- Add Saturated Double Word";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`splat32` $splat32^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDSW -- register form, from ADDSW_signextw_registerW_registerZ_registerY_simple
def LVX_AddswOp : LVX_Op<"addsw", [Pure]>{
  let summary = "ADDSW -- Add Saturated Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDSW -- immediate form, from ADDSW_signextw_registerW_registerZ_upper27_lower5_double
def LVX_AddswImmOp : LVX_Op<"addsw_i", [Pure]>{
  let summary = "ADDSW -- Add Saturated Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDUSD -- register form, from ADDUSD_registerW_registerZ_registerY_simple
def LVX_AddusdOp : LVX_Op<"addusd", [Pure]>{
  let summary = "ADDUSD -- Add Unsigned Saturated Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDUSD -- immediate form, from ADDUSD_registerW_registerZ_upper27_lower5_splat32_double
def LVX_AddusdImmOp : LVX_Op<"addusd_i", [Pure]>{
  let summary = "ADDUSD -- Add Unsigned Saturated Double Word";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`splat32` $splat32^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDUSW -- register form, from ADDUSW_signextw_registerW_registerZ_registerY_simple
def LVX_AdduswOp : LVX_Op<"addusw", [Pure]>{
  let summary = "ADDUSW -- Add Unsigned Saturated Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDUSW -- immediate form, from ADDUSW_signextw_registerW_registerZ_upper27_lower5_double
def LVX_AdduswImmOp : LVX_Op<"addusw_i", [Pure]>{
  let summary = "ADDUSW -- Add Unsigned Saturated Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBFQ -- register form, from SBFQ_registerM_registerP_registerO_simple
def LVX_SbfqOp : LVX_Op<"sbfq", [Pure]>{
  let summary = "SBFQ -- Subtract From Quadruple Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$quotient, LVX_RegType:$remainder);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($quotient)) `,` qualified(type($remainder)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBFQ -- immediate form, from SBFQ_registerM_registerP_upper27_lower5_splat32_double
def LVX_SbfqImmOp : LVX_Op<"sbfq_i", [Pure]>{
  let summary = "SBFQ -- Subtract From Quadruple Word";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$quotient, LVX_RegType:$remainder);
  let assemblyFormat = "(`splat32` $splat32^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($quotient)) `,` qualified(type($remainder)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBFD -- register form, from SBFD_registerW_registerZ_registerY_simple
def LVX_SbfdOp : LVX_Op<"sbfd", [Pure]>{
  let summary = "SBFD -- Subtract From Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBFD -- immediate form, from SBFD_registerW_registerZ_signed10_simple
def LVX_SbfdImmOp : LVX_Op<"sbfd_i", [Pure]>{
  let summary = "SBFD -- Subtract From Double Word";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$signed10,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$signed10), [{
      build($_builder, $_state, resultType, operand, signed10, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBFW -- register form, from SBFW_signextw_registerW_registerZ_registerY_simple
def LVX_SbfwOp : LVX_Op<"sbfw", [Pure]>{
  let summary = "SBFW -- Subtract From Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBFW -- immediate form, from SBFW_signextw_registerW_registerZ_upper27_lower5_double
def LVX_SbfwImmOp : LVX_Op<"sbfw_i", [Pure]>{
  let summary = "SBFW -- Subtract From Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBFSD -- register form, from SBFSD_registerW_registerZ_registerY_simple
def LVX_SbfsdOp : LVX_Op<"sbfsd", [Pure]>{
  let summary = "SBFSD -- Subtract Saturated Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBFSD -- immediate form, from SBFSD_registerW_registerZ_upper27_lower5_splat32_double
def LVX_SbfsdImmOp : LVX_Op<"sbfsd_i", [Pure]>{
  let summary = "SBFSD -- Subtract Saturated Double Word";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`splat32` $splat32^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBFSW -- register form, from SBFSW_signextw_registerW_registerZ_registerY_simple
def LVX_SbfswOp : LVX_Op<"sbfsw", [Pure]>{
  let summary = "SBFSW -- Subtract Saturated Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBFSW -- immediate form, from SBFSW_signextw_registerW_registerZ_upper27_lower5_double
def LVX_SbfswImmOp : LVX_Op<"sbfsw_i", [Pure]>{
  let summary = "SBFSW -- Subtract Saturated Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBFUSD -- register form, from SBFUSD_registerW_registerZ_registerY_simple
def LVX_SbfusdOp : LVX_Op<"sbfusd", [Pure]>{
  let summary = "SBFUSD -- Subtract Unsigned Saturated Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBFUSD -- immediate form, from SBFUSD_registerW_registerZ_upper27_lower5_splat32_double
def LVX_SbfusdImmOp : LVX_Op<"sbfusd_i", [Pure]>{
  let summary = "SBFUSD -- Subtract Unsigned Saturated Double Word";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`splat32` $splat32^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBFUSW -- register form, from SBFUSW_signextw_registerW_registerZ_registerY_simple
def LVX_SbfuswOp : LVX_Op<"sbfusw", [Pure]>{
  let summary = "SBFUSW -- Subtract Unsigned Saturated Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBFUSW -- immediate form, from SBFUSW_signextw_registerW_registerZ_upper27_lower5_double
def LVX_SbfuswImmOp : LVX_Op<"sbfusw_i", [Pure]>{
  let summary = "SBFUSW -- Subtract Unsigned Saturated Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MIND -- register form, from MIND_registerW_registerZ_registerY_simple
def LVX_MindOp : LVX_Op<"mind", [Pure]>{
  let summary = "MIND -- Minimum Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MIND -- immediate form, from MIND_registerW_registerZ_signed10_simple
def LVX_MindImmOp : LVX_Op<"mind_i", [Pure]>{
  let summary = "MIND -- Minimum Double Word";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$signed10,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$signed10), [{
      build($_builder, $_state, resultType, operand, signed10, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MINW -- register form, from MINW_signextw_registerW_registerZ_registerY_simple
def LVX_MinwOp : LVX_Op<"minw", [Pure]>{
  let summary = "MINW -- Minimum Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MINW -- immediate form, from MINW_signextw_registerW_registerZ_upper27_lower5_double
def LVX_MinwImmOp : LVX_Op<"minw_i", [Pure]>{
  let summary = "MINW -- Minimum Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MAXD -- register form, from MAXD_registerW_registerZ_registerY_simple
def LVX_MaxdOp : LVX_Op<"maxd", [Pure]>{
  let summary = "MAXD -- Maximum Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MAXD -- immediate form, from MAXD_registerW_registerZ_signed10_simple
def LVX_MaxdImmOp : LVX_Op<"maxd_i", [Pure]>{
  let summary = "MAXD -- Maximum Double Word";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$signed10,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$signed10), [{
      build($_builder, $_state, resultType, operand, signed10, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MAXW -- register form, from MAXW_signextw_registerW_registerZ_registerY_simple
def LVX_MaxwOp : LVX_Op<"maxw", [Pure]>{
  let summary = "MAXW -- Maximum Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MAXW -- immediate form, from MAXW_signextw_registerW_registerZ_upper27_lower5_double
def LVX_MaxwImmOp : LVX_Op<"maxw_i", [Pure]>{
  let summary = "MAXW -- Maximum Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MINUD -- register form, from MINUD_registerW_registerZ_registerY_simple
def LVX_MinudOp : LVX_Op<"minud", [Pure]>{
  let summary = "MINUD -- Minimum Unsigned Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MINUD -- immediate form, from MINUD_registerW_registerZ_signed10_simple
def LVX_MinudImmOp : LVX_Op<"minud_i", [Pure]>{
  let summary = "MINUD -- Minimum Unsigned Double Word";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$signed10,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$signed10), [{
      build($_builder, $_state, resultType, operand, signed10, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MINUW -- register form, from MINUW_signextw_registerW_registerZ_registerY_simple
def LVX_MinuwOp : LVX_Op<"minuw", [Pure]>{
  let summary = "MINUW -- Minimum Unsigned Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MINUW -- immediate form, from MINUW_signextw_registerW_registerZ_upper27_lower5_double
def LVX_MinuwImmOp : LVX_Op<"minuw_i", [Pure]>{
  let summary = "MINUW -- Minimum Unsigned Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MAXUD -- register form, from MAXUD_registerW_registerZ_registerY_simple
def LVX_MaxudOp : LVX_Op<"maxud", [Pure]>{
  let summary = "MAXUD -- Maximum Unsigned Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MAXUD -- immediate form, from MAXUD_registerW_registerZ_signed10_simple
def LVX_MaxudImmOp : LVX_Op<"maxud_i", [Pure]>{
  let summary = "MAXUD -- Maximum Unsigned Double Word";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$signed10,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$signed10), [{
      build($_builder, $_state, resultType, operand, signed10, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MAXUW -- register form, from MAXUW_signextw_registerW_registerZ_registerY_simple
def LVX_MaxuwOp : LVX_Op<"maxuw", [Pure]>{
  let summary = "MAXUW -- Maximum Unsigned Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MAXUW -- immediate form, from MAXUW_signextw_registerW_registerZ_upper27_lower5_double
def LVX_MaxuwImmOp : LVX_Op<"maxuw_i", [Pure]>{
  let summary = "MAXUW -- Maximum Unsigned Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ANDQ -- register form, from ANDQ_registerM_registerP_registerO_simple
def LVX_AndqOp : LVX_Op<"andq", [Pure]>{
  let summary = "ANDQ -- Bitwise And Quadruple Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$quotient, LVX_RegType:$remainder);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($quotient)) `,` qualified(type($remainder)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ANDQ -- immediate form, from ANDQ_registerM_registerP_upper27_lower5_splat32_double
def LVX_AndqImmOp : LVX_Op<"andq_i", [Pure]>{
  let summary = "ANDQ -- Bitwise And Quadruple Word";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$quotient, LVX_RegType:$remainder);
  let assemblyFormat = "(`splat32` $splat32^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($quotient)) `,` qualified(type($remainder)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ANDD -- register form, from ANDD_registerW_registerZ_registerY_simple
def LVX_AnddOp : LVX_Op<"andd", [Pure, Commutative]>{
  let summary = "ANDD -- Bitwise And Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ANDD -- immediate form, from ANDD_registerW_registerZ_signed10_simple
def LVX_AnddImmOp : LVX_Op<"andd_i", [Pure, Commutative]>{
  let summary = "ANDD -- Bitwise And Double Word";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$signed10,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$signed10), [{
      build($_builder, $_state, resultType, operand, signed10, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ANDW -- register form, from ANDW_signextw_registerW_registerZ_registerY_simple
def LVX_AndwOp : LVX_Op<"andw", [Pure, Commutative]>{
  let summary = "ANDW -- Bitwise And Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ANDW -- immediate form, from ANDW_signextw_registerW_registerZ_upper27_lower5_double
def LVX_AndwImmOp : LVX_Op<"andw_i", [Pure, Commutative]>{
  let summary = "ANDW -- Bitwise And Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:NANDQ -- register form, from NANDQ_registerM_registerP_registerO_simple
def LVX_NandqOp : LVX_Op<"nandq", [Pure]>{
  let summary = "NANDQ -- Bitwise Not And Quadruple Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$quotient, LVX_RegType:$remainder);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($quotient)) `,` qualified(type($remainder)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:NANDQ -- immediate form, from NANDQ_registerM_registerP_upper27_lower5_splat32_double
def LVX_NandqImmOp : LVX_Op<"nandq_i", [Pure]>{
  let summary = "NANDQ -- Bitwise Not And Quadruple Word";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$quotient, LVX_RegType:$remainder);
  let assemblyFormat = "(`splat32` $splat32^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($quotient)) `,` qualified(type($remainder)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:NANDD -- register form, from NANDD_registerW_registerZ_registerY_simple
def LVX_NanddOp : LVX_Op<"nandd", [Pure]>{
  let summary = "NANDD -- Bitwise Not And Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:NANDD -- immediate form, from NANDD_registerW_registerZ_signed10_simple
def LVX_NanddImmOp : LVX_Op<"nandd_i", [Pure]>{
  let summary = "NANDD -- Bitwise Not And Double Word";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$signed10,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$signed10), [{
      build($_builder, $_state, resultType, operand, signed10, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:NANDW -- register form, from NANDW_signextw_registerW_registerZ_registerY_simple
def LVX_NandwOp : LVX_Op<"nandw", [Pure]>{
  let summary = "NANDW -- Bitwise Not And Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:NANDW -- immediate form, from NANDW_signextw_registerW_registerZ_upper27_lower5_double
def LVX_NandwImmOp : LVX_Op<"nandw_i", [Pure]>{
  let summary = "NANDW -- Bitwise Not And Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:IORQ -- register form, from IORQ_registerM_registerP_registerO_simple
def LVX_IorqOp : LVX_Op<"iorq", [Pure]>{
  let summary = "IORQ -- Bitwise Inclusive Or Quadruple Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$quotient, LVX_RegType:$remainder);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($quotient)) `,` qualified(type($remainder)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:IORQ -- immediate form, from IORQ_registerM_registerP_upper27_lower5_splat32_double
def LVX_IorqImmOp : LVX_Op<"iorq_i", [Pure]>{
  let summary = "IORQ -- Bitwise Inclusive Or Quadruple Word";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$quotient, LVX_RegType:$remainder);
  let assemblyFormat = "(`splat32` $splat32^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($quotient)) `,` qualified(type($remainder)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:IORD -- register form, from IORD_registerW_registerZ_registerY_simple
def LVX_IordOp : LVX_Op<"iord", [Pure, Commutative]>{
  let summary = "IORD -- Bitwise Inclusive Or Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:IORD -- immediate form, from IORD_registerW_registerZ_signed10_simple
def LVX_IordImmOp : LVX_Op<"iord_i", [Pure, Commutative]>{
  let summary = "IORD -- Bitwise Inclusive Or Double Word";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$signed10,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$signed10), [{
      build($_builder, $_state, resultType, operand, signed10, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:IORW -- register form, from IORW_signextw_registerW_registerZ_registerY_simple
def LVX_IorwOp : LVX_Op<"iorw", [Pure, Commutative]>{
  let summary = "IORW -- Bitwise Inclusive Or Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:IORW -- immediate form, from IORW_signextw_registerW_registerZ_upper27_lower5_double
def LVX_IorwImmOp : LVX_Op<"iorw_i", [Pure, Commutative]>{
  let summary = "IORW -- Bitwise Inclusive Or Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:NIORQ -- register form, from NIORQ_registerM_registerP_registerO_simple
def LVX_NiorqOp : LVX_Op<"niorq", [Pure]>{
  let summary = "NIORQ -- Bitwise Not Inclusive Or Quadruple Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$quotient, LVX_RegType:$remainder);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($quotient)) `,` qualified(type($remainder)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:NIORQ -- immediate form, from NIORQ_registerM_registerP_upper27_lower5_splat32_double
def LVX_NiorqImmOp : LVX_Op<"niorq_i", [Pure]>{
  let summary = "NIORQ -- Bitwise Not Inclusive Or Quadruple Word";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$quotient, LVX_RegType:$remainder);
  let assemblyFormat = "(`splat32` $splat32^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($quotient)) `,` qualified(type($remainder)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:NIORD -- register form, from NIORD_registerW_registerZ_registerY_simple
def LVX_NiordOp : LVX_Op<"niord", [Pure]>{
  let summary = "NIORD -- Bitwise Not Inclusive Or Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:NIORD -- immediate form, from NIORD_registerW_registerZ_signed10_simple
def LVX_NiordImmOp : LVX_Op<"niord_i", [Pure]>{
  let summary = "NIORD -- Bitwise Not Inclusive Or Double Word";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$signed10,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$signed10), [{
      build($_builder, $_state, resultType, operand, signed10, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:NIORW -- register form, from NIORW_signextw_registerW_registerZ_registerY_simple
def LVX_NiorwOp : LVX_Op<"niorw", [Pure]>{
  let summary = "NIORW -- Bitwise Not Inclusive Or Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:NIORW -- immediate form, from NIORW_signextw_registerW_registerZ_upper27_lower5_double
def LVX_NiorwImmOp : LVX_Op<"niorw_i", [Pure]>{
  let summary = "NIORW -- Bitwise Not Inclusive Or Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:EORQ -- register form, from EORQ_registerM_registerP_registerO_simple
def LVX_EorqOp : LVX_Op<"eorq", [Pure]>{
  let summary = "EORQ -- Bitwise Exclusive Or Quadruple Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$quotient, LVX_RegType:$remainder);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($quotient)) `,` qualified(type($remainder)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:EORQ -- immediate form, from EORQ_registerM_registerP_upper27_lower5_splat32_double
def LVX_EorqImmOp : LVX_Op<"eorq_i", [Pure]>{
  let summary = "EORQ -- Bitwise Exclusive Or Quadruple Word";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$quotient, LVX_RegType:$remainder);
  let assemblyFormat = "(`splat32` $splat32^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($quotient)) `,` qualified(type($remainder)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:EORD -- register form, from EORD_registerW_registerZ_registerY_simple
def LVX_EordOp : LVX_Op<"eord", [Pure, Commutative]>{
  let summary = "EORD -- Bitwise Exclusive Or Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:EORD -- immediate form, from EORD_registerW_registerZ_signed10_simple
def LVX_EordImmOp : LVX_Op<"eord_i", [Pure, Commutative]>{
  let summary = "EORD -- Bitwise Exclusive Or Double Word";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$signed10,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$signed10), [{
      build($_builder, $_state, resultType, operand, signed10, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:EORW -- register form, from EORW_signextw_registerW_registerZ_registerY_simple
def LVX_EorwOp : LVX_Op<"eorw", [Pure, Commutative]>{
  let summary = "EORW -- Bitwise Exclusive Or Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:EORW -- immediate form, from EORW_signextw_registerW_registerZ_upper27_lower5_double
def LVX_EorwImmOp : LVX_Op<"eorw_i", [Pure, Commutative]>{
  let summary = "EORW -- Bitwise Exclusive Or Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:NEORQ -- register form, from NEORQ_registerM_registerP_registerO_simple
def LVX_NeorqOp : LVX_Op<"neorq", [Pure]>{
  let summary = "NEORQ -- Bitwise Not Exclusive Or Quadruple Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$quotient, LVX_RegType:$remainder);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($quotient)) `,` qualified(type($remainder)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:NEORQ -- immediate form, from NEORQ_registerM_registerP_upper27_lower5_splat32_double
def LVX_NeorqImmOp : LVX_Op<"neorq_i", [Pure]>{
  let summary = "NEORQ -- Bitwise Not Exclusive Or Quadruple Word";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$quotient, LVX_RegType:$remainder);
  let assemblyFormat = "(`splat32` $splat32^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($quotient)) `,` qualified(type($remainder)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:NEORD -- register form, from NEORD_registerW_registerZ_registerY_simple
def LVX_NeordOp : LVX_Op<"neord", [Pure]>{
  let summary = "NEORD -- Bitwise Not Exclusive Or Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:NEORD -- immediate form, from NEORD_registerW_registerZ_signed10_simple
def LVX_NeordImmOp : LVX_Op<"neord_i", [Pure]>{
  let summary = "NEORD -- Bitwise Not Exclusive Or Double Word";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$signed10,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$signed10), [{
      build($_builder, $_state, resultType, operand, signed10, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:NEORW -- register form, from NEORW_signextw_registerW_registerZ_registerY_simple
def LVX_NeorwOp : LVX_Op<"neorw", [Pure]>{
  let summary = "NEORW -- Bitwise Not Exclusive Or Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:NEORW -- immediate form, from NEORW_signextw_registerW_registerZ_upper27_lower5_double
def LVX_NeorwImmOp : LVX_Op<"neorw_i", [Pure]>{
  let summary = "NEORW -- Bitwise Not Exclusive Or Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ANDNQ -- register form, from ANDNQ_registerM_registerP_registerO_simple
def LVX_AndnqOp : LVX_Op<"andnq", [Pure]>{
  let summary = "ANDNQ -- Bitwise And with Not Operand Quadruple Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$quotient, LVX_RegType:$remainder);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($quotient)) `,` qualified(type($remainder)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ANDNQ -- immediate form, from ANDNQ_registerM_registerP_upper27_lower5_splat32_double
def LVX_AndnqImmOp : LVX_Op<"andnq_i", [Pure]>{
  let summary = "ANDNQ -- Bitwise And with Not Operand Quadruple Word";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$quotient, LVX_RegType:$remainder);
  let assemblyFormat = "(`splat32` $splat32^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($quotient)) `,` qualified(type($remainder)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ANDND -- register form, from ANDND_registerW_registerZ_registerY_simple
def LVX_AndndOp : LVX_Op<"andnd", [Pure]>{
  let summary = "ANDND -- Bitwise And with Not Operand Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ANDND -- immediate form, from ANDND_registerW_registerZ_signed10_simple
def LVX_AndndImmOp : LVX_Op<"andnd_i", [Pure]>{
  let summary = "ANDND -- Bitwise And with Not Operand Double Word";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$signed10,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$signed10), [{
      build($_builder, $_state, resultType, operand, signed10, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ANDNW -- register form, from ANDNW_signextw_registerW_registerZ_registerY_simple
def LVX_AndnwOp : LVX_Op<"andnw", [Pure]>{
  let summary = "ANDNW -- Bitwise And with Not Operand Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ANDNW -- immediate form, from ANDNW_signextw_registerW_registerZ_upper27_lower5_double
def LVX_AndnwImmOp : LVX_Op<"andnw_i", [Pure]>{
  let summary = "ANDNW -- Bitwise And with Not Operand Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:IORNQ -- register form, from IORNQ_registerM_registerP_registerO_simple
def LVX_IornqOp : LVX_Op<"iornq", [Pure]>{
  let summary = "IORNQ -- Bitwise Inclusive Or with Not Operand Quadruple Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$quotient, LVX_RegType:$remainder);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($quotient)) `,` qualified(type($remainder)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:IORNQ -- immediate form, from IORNQ_registerM_registerP_upper27_lower5_splat32_double
def LVX_IornqImmOp : LVX_Op<"iornq_i", [Pure]>{
  let summary = "IORNQ -- Bitwise Inclusive Or with Not Operand Quadruple Word";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$quotient, LVX_RegType:$remainder);
  let assemblyFormat = "(`splat32` $splat32^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($quotient)) `,` qualified(type($remainder)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:IORND -- register form, from IORND_registerW_registerZ_registerY_simple
def LVX_IorndOp : LVX_Op<"iornd", [Pure]>{
  let summary = "IORND -- Bitwise Inclusive Or with Not Operand Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:IORND -- immediate form, from IORND_registerW_registerZ_signed10_simple
def LVX_IorndImmOp : LVX_Op<"iornd_i", [Pure]>{
  let summary = "IORND -- Bitwise Inclusive Or with Not Operand Double Word";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$signed10,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$signed10), [{
      build($_builder, $_state, resultType, operand, signed10, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:IORNW -- register form, from IORNW_signextw_registerW_registerZ_registerY_simple
def LVX_IornwOp : LVX_Op<"iornw", [Pure]>{
  let summary = "IORNW -- Bitwise Inclusive Or with Not Operand Double Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:IORNW -- immediate form, from IORNW_signextw_registerW_registerZ_upper27_lower5_double
def LVX_IornwImmOp : LVX_Op<"iornw_i", [Pure]>{
  let summary = "IORNW -- Bitwise Inclusive Or with Not Operand Double Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SRLD -- register form, from SRLD_registerW_registerZ_registerY_simple
def LVX_SrldOp : LVX_Op<"srld", [Pure]>{
  let summary = "SRLD -- Shift Right Logical Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SRLD -- immediate form, from SRLD_registerW_registerZ_unsigned6_simple
def LVX_SrldImmOp : LVX_Op<"srld_i", [Pure]>{
  let summary = "SRLD -- Shift Right Logical Double Word";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$unsigned6,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultType, operand, unsigned6, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SRLW -- register form, from SRLW_signextw_registerW_registerZ_registerY_simple
def LVX_SrlwOp : LVX_Op<"srlw", [Pure]>{
  let summary = "SRLW -- Shift Right Logical Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SRLW -- immediate form, from SRLW_signextw_registerW_registerZ_unsigned6_simple
def LVX_SrlwImmOp : LVX_Op<"srlw_i", [Pure]>{
  let summary = "SRLW -- Shift Right Logical Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$unsigned6,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, unsigned6, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SRAD -- register form, from SRAD_registerW_registerZ_registerY_simple
def LVX_SradOp : LVX_Op<"srad", [Pure]>{
  let summary = "SRAD -- Shift Right Arithmetic Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SRAD -- immediate form, from SRAD_registerW_registerZ_unsigned6_simple
def LVX_SradImmOp : LVX_Op<"srad_i", [Pure]>{
  let summary = "SRAD -- Shift Right Arithmetic Double Word";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$unsigned6,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultType, operand, unsigned6, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SRAW -- register form, from SRAW_signextw_registerW_registerZ_registerY_simple
def LVX_SrawOp : LVX_Op<"sraw", [Pure]>{
  let summary = "SRAW -- Shift Right Arithmetic Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SRAW -- immediate form, from SRAW_signextw_registerW_registerZ_unsigned6_simple
def LVX_SrawImmOp : LVX_Op<"sraw_i", [Pure]>{
  let summary = "SRAW -- Shift Right Arithmetic Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$unsigned6,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, unsigned6, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SRSD -- register form, from SRSD_registerW_registerZ_registerY_simple
def LVX_SrsdOp : LVX_Op<"srsd", [Pure]>{
  let summary = "SRSD -- Shift Right Symmetric Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SRSD -- immediate form, from SRSD_registerW_registerZ_unsigned6_simple
def LVX_SrsdImmOp : LVX_Op<"srsd_i", [Pure]>{
  let summary = "SRSD -- Shift Right Symmetric Double Word";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$unsigned6,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultType, operand, unsigned6, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SRSW -- register form, from SRSW_signextw_registerW_registerZ_registerY_simple
def LVX_SrswOp : LVX_Op<"srsw", [Pure]>{
  let summary = "SRSW -- Shift Right Symmetric Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SRSW -- immediate form, from SRSW_signextw_registerW_registerZ_unsigned6_simple
def LVX_SrswImmOp : LVX_Op<"srsw_i", [Pure]>{
  let summary = "SRSW -- Shift Right Symmetric Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$unsigned6,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, unsigned6, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SLLD -- register form, from SLLD_registerW_registerZ_registerY_simple
def LVX_SlldOp : LVX_Op<"slld", [Pure]>{
  let summary = "SLLD -- Shift Left Logical Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SLLD -- immediate form, from SLLD_registerW_registerZ_unsigned6_simple
def LVX_SlldImmOp : LVX_Op<"slld_i", [Pure]>{
  let summary = "SLLD -- Shift Left Logical Double Word";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$unsigned6,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultType, operand, unsigned6, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SLLW -- register form, from SLLW_signextw_registerW_registerZ_registerY_simple
def LVX_SllwOp : LVX_Op<"sllw", [Pure]>{
  let summary = "SLLW -- Shift Left Logical Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SLLW -- immediate form, from SLLW_signextw_registerW_registerZ_unsigned6_simple
def LVX_SllwImmOp : LVX_Op<"sllw_i", [Pure]>{
  let summary = "SLLW -- Shift Left Logical Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$unsigned6,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, unsigned6, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SLSD -- register form, from SLSD_registerW_registerZ_registerY_simple
def LVX_SlsdOp : LVX_Op<"slsd", [Pure]>{
  let summary = "SLSD -- Shift Left Saturated Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SLSD -- immediate form, from SLSD_registerW_registerZ_unsigned6_simple
def LVX_SlsdImmOp : LVX_Op<"slsd_i", [Pure]>{
  let summary = "SLSD -- Shift Left Saturated Double Word";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$unsigned6,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultType, operand, unsigned6, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SLSW -- register form, from SLSW_signextw_registerW_registerZ_registerY_simple
def LVX_SlswOp : LVX_Op<"slsw", [Pure]>{
  let summary = "SLSW -- Shift Left Saturated Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SLSW -- immediate form, from SLSW_signextw_registerW_registerZ_unsigned6_simple
def LVX_SlswImmOp : LVX_Op<"slsw_i", [Pure]>{
  let summary = "SLSW -- Shift Left Saturated Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$unsigned6,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, unsigned6, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SLUSD -- register form, from SLUSD_registerW_registerZ_registerY_simple
def LVX_SlusdOp : LVX_Op<"slusd", [Pure]>{
  let summary = "SLUSD -- Shift Left Unsigned Saturated Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SLUSD -- immediate form, from SLUSD_registerW_registerZ_unsigned6_simple
def LVX_SlusdImmOp : LVX_Op<"slusd_i", [Pure]>{
  let summary = "SLUSD -- Shift Left Unsigned Saturated Double Word";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$unsigned6,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultType, operand, unsigned6, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SLUSW -- register form, from SLUSW_signextw_registerW_registerZ_registerY_simple
def LVX_SluswOp : LVX_Op<"slusw", [Pure]>{
  let summary = "SLUSW -- Shift Left Unsigned Saturated Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SLUSW -- immediate form, from SLUSW_signextw_registerW_registerZ_unsigned6_simple
def LVX_SluswImmOp : LVX_Op<"slusw_i", [Pure]>{
  let summary = "SLUSW -- Shift Left Unsigned Saturated Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$unsigned6,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, unsigned6, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ROLD -- register form, from ROLD_registerW_registerZ_registerY_simple
def LVX_RoldOp : LVX_Op<"rold", [Pure]>{
  let summary = "ROLD -- Rotate Left Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ROLD -- immediate form, from ROLD_registerW_registerZ_unsigned6_simple
def LVX_RoldImmOp : LVX_Op<"rold_i", [Pure]>{
  let summary = "ROLD -- Rotate Left Double Word";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$unsigned6,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultType, operand, unsigned6, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ROLW -- register form, from ROLW_signextw_registerW_registerZ_registerY_simple
def LVX_RolwOp : LVX_Op<"rolw", [Pure]>{
  let summary = "ROLW -- Rotate Left Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ROLW -- immediate form, from ROLW_signextw_registerW_registerZ_unsigned6_simple
def LVX_RolwImmOp : LVX_Op<"rolw_i", [Pure]>{
  let summary = "ROLW -- Rotate Left Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$unsigned6,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, unsigned6, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:RORD -- register form, from RORD_registerW_registerZ_registerY_simple
def LVX_RordOp : LVX_Op<"rord", [Pure]>{
  let summary = "RORD -- Rotate Right Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:RORD -- immediate form, from RORD_registerW_registerZ_unsigned6_simple
def LVX_RordImmOp : LVX_Op<"rord_i", [Pure]>{
  let summary = "RORD -- Rotate Right Double Word";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$unsigned6,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultType, operand, unsigned6, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:RORW -- register form, from RORW_signextw_registerW_registerZ_registerY_simple
def LVX_RorwOp : LVX_Op<"rorw", [Pure]>{
  let summary = "RORW -- Rotate Right Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:RORW -- immediate form, from RORW_signextw_registerW_registerZ_unsigned6_simple
def LVX_RorwImmOp : LVX_Op<"rorw_i", [Pure]>{
  let summary = "RORW -- Rotate Right Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$unsigned6,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, unsigned6, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBMM8D -- register form, from SBMM8D_registerW_registerZ_registerY_simple
def LVX_Sbmm8dOp : LVX_Op<"sbmm8d", [Pure]>{
  let summary = "SBMM8D -- Swapped Bit Matrix Multiplication 8$\times$8 Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBMM8D -- immediate form, from SBMM8D_registerW_registerZ_signed10_simple
def LVX_Sbmm8dImmOp : LVX_Op<"sbmm8d_i", [Pure]>{
  let summary = "SBMM8D -- Swapped Bit Matrix Multiplication 8$\times$8 Double Word";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$signed10,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$signed10), [{
      build($_builder, $_state, resultType, operand, signed10, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBMMT8D -- register form, from SBMMT8D_registerW_registerZ_registerY_simple
def LVX_Sbmmt8dOp : LVX_Op<"sbmmt8d", [Pure]>{
  let summary = "SBMMT8D -- Swapped Bit Matrix Multiplication Transposed 8$\times$8 Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBMMT8D -- immediate form, from SBMMT8D_registerW_registerZ_signed10_simple
def LVX_Sbmmt8dImmOp : LVX_Op<"sbmmt8d_i", [Pure]>{
  let summary = "SBMMT8D -- Swapped Bit Matrix Multiplication Transposed 8$\times$8 Double Word";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$signed10,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$signed10), [{
      build($_builder, $_state, resultType, operand, signed10, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBMM8EORD -- register form, from SBMM8EORD_registerW_registerZ_registerY_simple
def LVX_Sbmm8eordOp : LVX_Op<"sbmm8eord", [Pure]>{
  let summary = "SBMM8EORD -- Swapped Bit Matrix Multiplication 8$\times$8 Exclusive OR Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBMM8EORD -- immediate form, from SBMM8EORD_registerW_registerZ_upper27_lower5_splat32_double
def LVX_Sbmm8eordImmOp : LVX_Op<"sbmm8eord_i", [Pure]>{
  let summary = "SBMM8EORD -- Swapped Bit Matrix Multiplication 8$\times$8 Exclusive OR Double Word";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`splat32` $splat32^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBMMT8EORD -- register form, from SBMMT8EORD_registerW_registerZ_registerY_simple
def LVX_Sbmmt8eordOp : LVX_Op<"sbmmt8eord", [Pure]>{
  let summary = "SBMMT8EORD -- Swapped Bit Matrix Multiplication Transposed 8$\times$8 Exclusive OR Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBMMT8EORD -- immediate form, from SBMMT8EORD_registerW_registerZ_upper27_lower5_splat32_double
def LVX_Sbmmt8eordImmOp : LVX_Op<"sbmmt8eord_i", [Pure]>{
  let summary = "SBMMT8EORD -- Swapped Bit Matrix Multiplication Transposed 8$\times$8 Exclusive OR Double Word";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`splat32` $splat32^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:AVGW -- register form, from AVGW_signextw_registerW_registerZ_registerY_simple
def LVX_AvgwOp : LVX_Op<"avgw", [Pure]>{
  let summary = "AVGW -- Average Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:AVGW -- immediate form, from AVGW_signextw_registerW_registerZ_upper27_lower5_double
def LVX_AvgwImmOp : LVX_Op<"avgw_i", [Pure]>{
  let summary = "AVGW -- Average Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:AVGUW -- register form, from AVGUW_signextw_registerW_registerZ_registerY_simple
def LVX_AvguwOp : LVX_Op<"avguw", [Pure]>{
  let summary = "AVGUW -- Average Unsigned Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:AVGUW -- immediate form, from AVGUW_signextw_registerW_registerZ_upper27_lower5_double
def LVX_AvguwImmOp : LVX_Op<"avguw_i", [Pure]>{
  let summary = "AVGUW -- Average Unsigned Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:AVGRW -- register form, from AVGRW_signextw_registerW_registerZ_registerY_simple
def LVX_AvgrwOp : LVX_Op<"avgrw", [Pure]>{
  let summary = "AVGRW -- Average Rounded Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:AVGRW -- immediate form, from AVGRW_signextw_registerW_registerZ_upper27_lower5_double
def LVX_AvgrwImmOp : LVX_Op<"avgrw_i", [Pure]>{
  let summary = "AVGRW -- Average Rounded Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:AVGRUW -- register form, from AVGRUW_signextw_registerW_registerZ_registerY_simple
def LVX_AvgruwOp : LVX_Op<"avgruw", [Pure]>{
  let summary = "AVGRUW -- Average Rounded Unsigned Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:AVGRUW -- immediate form, from AVGRUW_signextw_registerW_registerZ_upper27_lower5_double
def LVX_AvgruwImmOp : LVX_Op<"avgruw_i", [Pure]>{
  let summary = "AVGRUW -- Average Rounded Unsigned Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SIGND -- register form, from SIGND_registerW_registerZ_registerY_simple
def LVX_SigndOp : LVX_Op<"signd", [Pure]>{
  let summary = "SIGND -- Apply Sign Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SIGND -- immediate form, from SIGND_registerW_registerZ_upper27_lower5_splat32_double
def LVX_SigndImmOp : LVX_Op<"signd_i", [Pure]>{
  let summary = "SIGND -- Apply Sign Double Word";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`splat32` $splat32^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SIGNW -- register form, from SIGNW_signextw_registerW_registerZ_registerY_simple
def LVX_SignwOp : LVX_Op<"signw", [Pure]>{
  let summary = "SIGNW -- Apply Sign Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SIGNW -- immediate form, from SIGNW_signextw_registerW_registerZ_upper27_lower5_double
def LVX_SignwImmOp : LVX_Op<"signw_i", [Pure]>{
  let summary = "SIGNW -- Apply Sign Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SIGNSD -- register form, from SIGNSD_registerW_registerZ_registerY_simple
def LVX_SignsdOp : LVX_Op<"signsd", [Pure]>{
  let summary = "SIGNSD -- Apply Sign Saturated Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SIGNSD -- immediate form, from SIGNSD_registerW_registerZ_upper27_lower5_splat32_double
def LVX_SignsdImmOp : LVX_Op<"signsd_i", [Pure]>{
  let summary = "SIGNSD -- Apply Sign Saturated Double Word";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`splat32` $splat32^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SIGNSW -- register form, from SIGNSW_signextw_registerW_registerZ_registerY_simple
def LVX_SignswOp : LVX_Op<"signsw", [Pure]>{
  let summary = "SIGNSW -- Apply Sign Saturated Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SIGNSW -- immediate form, from SIGNSW_signextw_registerW_registerZ_upper27_lower5_double
def LVX_SignswImmOp : LVX_Op<"signsw_i", [Pure]>{
  let summary = "SIGNSW -- Apply Sign Saturated Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX2D -- register form, from ADDX2D_registerW_registerZ_registerY_simple
def LVX_Addx2dOp : LVX_Op<"addx2d", [Pure]>{
  let summary = "ADDX2D -- Add to Times 2 Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX2D -- immediate form, from ADDX2D_registerW_registerZ_upper27_lower5_splat32_double
def LVX_Addx2dImmOp : LVX_Op<"addx2d_i", [Pure]>{
  let summary = "ADDX2D -- Add to Times 2 Double Word";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`splat32` $splat32^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX2W -- register form, from ADDX2W_signextw_registerW_registerZ_registerY_simple
def LVX_Addx2wOp : LVX_Op<"addx2w", [Pure]>{
  let summary = "ADDX2W -- Add to Times 2 Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX2W -- immediate form, from ADDX2W_signextw_registerW_registerZ_upper27_lower5_double
def LVX_Addx2wImmOp : LVX_Op<"addx2w_i", [Pure]>{
  let summary = "ADDX2W -- Add to Times 2 Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX4D -- register form, from ADDX4D_registerW_registerZ_registerY_simple
def LVX_Addx4dOp : LVX_Op<"addx4d", [Pure]>{
  let summary = "ADDX4D -- Add to Times 4 Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX4D -- immediate form, from ADDX4D_registerW_registerZ_upper27_lower5_splat32_double
def LVX_Addx4dImmOp : LVX_Op<"addx4d_i", [Pure]>{
  let summary = "ADDX4D -- Add to Times 4 Double Word";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`splat32` $splat32^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX4W -- register form, from ADDX4W_signextw_registerW_registerZ_registerY_simple
def LVX_Addx4wOp : LVX_Op<"addx4w", [Pure]>{
  let summary = "ADDX4W -- Add to Times 4 Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX4W -- immediate form, from ADDX4W_signextw_registerW_registerZ_upper27_lower5_double
def LVX_Addx4wImmOp : LVX_Op<"addx4w_i", [Pure]>{
  let summary = "ADDX4W -- Add to Times 4 Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX8D -- register form, from ADDX8D_registerW_registerZ_registerY_simple
def LVX_Addx8dOp : LVX_Op<"addx8d", [Pure]>{
  let summary = "ADDX8D -- Add to Times 8 Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX8D -- immediate form, from ADDX8D_registerW_registerZ_upper27_lower5_splat32_double
def LVX_Addx8dImmOp : LVX_Op<"addx8d_i", [Pure]>{
  let summary = "ADDX8D -- Add to Times 8 Double Word";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`splat32` $splat32^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX8W -- register form, from ADDX8W_signextw_registerW_registerZ_registerY_simple
def LVX_Addx8wOp : LVX_Op<"addx8w", [Pure]>{
  let summary = "ADDX8W -- Add to Times 8 Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX8W -- immediate form, from ADDX8W_signextw_registerW_registerZ_upper27_lower5_double
def LVX_Addx8wImmOp : LVX_Op<"addx8w_i", [Pure]>{
  let summary = "ADDX8W -- Add to Times 8 Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX16D -- register form, from ADDX16D_registerW_registerZ_registerY_simple
def LVX_Addx16dOp : LVX_Op<"addx16d", [Pure]>{
  let summary = "ADDX16D -- Add Double Word to Double Word Times 16";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX16D -- immediate form, from ADDX16D_registerW_registerZ_upper27_lower5_splat32_double
def LVX_Addx16dImmOp : LVX_Op<"addx16d_i", [Pure]>{
  let summary = "ADDX16D -- Add Double Word to Double Word Times 16";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`splat32` $splat32^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX16W -- register form, from ADDX16W_signextw_registerW_registerZ_registerY_simple
def LVX_Addx16wOp : LVX_Op<"addx16w", [Pure]>{
  let summary = "ADDX16W -- Add Word to Word Times 16";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX16W -- immediate form, from ADDX16W_signextw_registerW_registerZ_upper27_lower5_double
def LVX_Addx16wImmOp : LVX_Op<"addx16w_i", [Pure]>{
  let summary = "ADDX16W -- Add Word to Word Times 16";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX32D -- register form, from ADDX32D_registerW_registerZ_registerY_simple
def LVX_Addx32dOp : LVX_Op<"addx32d", [Pure]>{
  let summary = "ADDX32D -- Add to Times 32 Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX32D -- immediate form, from ADDX32D_registerW_registerZ_upper27_lower5_splat32_double
def LVX_Addx32dImmOp : LVX_Op<"addx32d_i", [Pure]>{
  let summary = "ADDX32D -- Add to Times 32 Double Word";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`splat32` $splat32^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX32W -- register form, from ADDX32W_signextw_registerW_registerZ_registerY_simple
def LVX_Addx32wOp : LVX_Op<"addx32w", [Pure]>{
  let summary = "ADDX32W -- Add to Times 32 Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX32W -- immediate form, from ADDX32W_signextw_registerW_registerZ_upper27_lower5_double
def LVX_Addx32wImmOp : LVX_Op<"addx32w_i", [Pure]>{
  let summary = "ADDX32W -- Add to Times 32 Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX64D -- register form, from ADDX64D_registerW_registerZ_registerY_simple
def LVX_Addx64dOp : LVX_Op<"addx64d", [Pure]>{
  let summary = "ADDX64D -- Add to Times 64 Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX64D -- immediate form, from ADDX64D_registerW_registerZ_upper27_lower5_splat32_double
def LVX_Addx64dImmOp : LVX_Op<"addx64d_i", [Pure]>{
  let summary = "ADDX64D -- Add to Times 64 Double Word";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`splat32` $splat32^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX64W -- register form, from ADDX64W_signextw_registerW_registerZ_registerY_simple
def LVX_Addx64wOp : LVX_Op<"addx64w", [Pure]>{
  let summary = "ADDX64W -- Add to Times 64 Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX64W -- immediate form, from ADDX64W_signextw_registerW_registerZ_upper27_lower5_double
def LVX_Addx64wImmOp : LVX_Op<"addx64w_i", [Pure]>{
  let summary = "ADDX64W -- Add to Times 64 Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:LANDD -- register form, from LANDD_registerW_registerZ_registerY_simple
def LVX_LanddOp : LVX_Op<"landd", [Pure]>{
  let summary = "LANDD -- Logical And Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:LNANDD -- register form, from LNANDD_registerW_registerZ_registerY_simple
def LVX_LnanddOp : LVX_Op<"lnandd", [Pure]>{
  let summary = "LNANDD -- Logical Not And Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:LIORD -- register form, from LIORD_registerW_registerZ_registerY_simple
def LVX_LiordOp : LVX_Op<"liord", [Pure]>{
  let summary = "LIORD -- Logical Or Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:LNIORD -- register form, from LNIORD_registerW_registerZ_registerY_simple
def LVX_LniordOp : LVX_Op<"lniord", [Pure]>{
  let summary = "LNIORD -- Logical Not Or Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:LANDW -- register form, from LANDW_registerW_registerZ_registerY_simple
def LVX_LandwOp : LVX_Op<"landw", [Pure]>{
  let summary = "LANDW -- Logical And Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:LNANDW -- register form, from LNANDW_registerW_registerZ_registerY_simple
def LVX_LnandwOp : LVX_Op<"lnandw", [Pure]>{
  let summary = "LNANDW -- Logical Not And Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:LIORW -- register form, from LIORW_registerW_registerZ_registerY_simple
def LVX_LiorwOp : LVX_Op<"liorw", [Pure]>{
  let summary = "LIORW -- Logical Or Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:LNIORW -- register form, from LNIORW_registerW_registerZ_registerY_simple
def LVX_LniorwOp : LVX_Op<"lniorw", [Pure]>{
  let summary = "LNIORW -- Logical Not Or Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:INSF -- immediate form, from INSF_registerW_registerZ_stopbit2_stopbit4_startbit_simple
def LVX_InsfImmOp : LVX_Op<"insf", [Pure]>{
  let summary = "INSF -- Insert Bit Field into Word";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$stopbit2_stopbit4,
                       TypedAttrInterface:$startbit,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$stopbit2_stopbit4, "::mlir::TypedAttr":$startbit), [{
      build($_builder, $_state, resultType, operand, stopbit2_stopbit4, startbit, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:EXTFZ -- immediate form, from EXTFZ_registerW_registerZ_stopbit2_stopbit4_startbit_simple
def LVX_ExtfzImmOp : LVX_Op<"extfz", [Pure]>{
  let summary = "EXTFZ -- Extract Bit Field and Zero Extend to Double Word";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$stopbit2_stopbit4,
                       TypedAttrInterface:$startbit,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$stopbit2_stopbit4, "::mlir::TypedAttr":$startbit), [{
      build($_builder, $_state, resultType, operand, stopbit2_stopbit4, startbit, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:EXTFS -- immediate form, from EXTFS_registerW_registerZ_stopbit2_stopbit4_startbit_simple
def LVX_ExtfsImmOp : LVX_Op<"extfs", [Pure]>{
  let summary = "EXTFS -- Extract Bit Field and Sign Extend to Double Word";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$stopbit2_stopbit4,
                       TypedAttrInterface:$startbit,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$stopbit2_stopbit4, "::mlir::TypedAttr":$startbit), [{
      build($_builder, $_state, resultType, operand, stopbit2_stopbit4, startbit, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:COMPQ -- register form, from COMPQ_intcomp_registerM_registerP_registerO_simple
def LVX_CompqOp : LVX_Op<"compq", [Pure]>{
  let summary = "COMPQ -- Compare Quadruple Word";
  let arguments = (ins LVX_IntCompAttr:$intcomp,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$quotient, LVX_RegType:$remainder);
  let assemblyFormat = "$intcomp $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($quotient)) `,` qualified(type($remainder)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::lvx::IntComp":$intcomp, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, ::mlir::lvx::IntCompAttr::get($_builder.getContext(), intcomp), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:COMPD -- register form, from COMPD_intcomp_registerW_registerZ_registerY_simple
def LVX_CompdOp : LVX_Op<"compd", [Pure]>{
  let summary = "COMPD -- Compare Double Word";
  let arguments = (ins LVX_IntCompAttr:$intcomp,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$intcomp $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::lvx::IntComp":$intcomp, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::lvx::IntCompAttr::get($_builder.getContext(), intcomp), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:COMPD -- immediate form, from COMPD_intcomp_registerW_registerZ_upper27_lower5_double
def LVX_CompdImmOp : LVX_Op<"compd_i", [Pure]>{
  let summary = "COMPD -- Compare Double Word";
  let arguments = (ins LVX_IntCompAttr:$intcomp,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$intcomp $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::lvx::IntComp":$intcomp, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::lvx::IntCompAttr::get($_builder.getContext(), intcomp), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:COMPW -- register form, from COMPW_intcomp_signextw_registerW_registerZ_registerY_simple
def LVX_CompwOp : LVX_Op<"compw", [Pure]>{
  let summary = "COMPW -- Compare Word";
  let arguments = (ins LVX_IntCompAttr:$intcomp,
                       UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $intcomp $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::lvx::IntComp":$intcomp, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::lvx::IntCompAttr::get($_builder.getContext(), intcomp), ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:COMPW -- immediate form, from COMPW_intcomp_signextw_registerW_registerZ_upper27_lower5_double
def LVX_CompwImmOp : LVX_Op<"compw_i", [Pure]>{
  let summary = "COMPW -- Compare Word";
  let arguments = (ins LVX_IntCompAttr:$intcomp,
                       UnitAttr:$sx,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $intcomp $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::lvx::IntComp":$intcomp, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::lvx::IntCompAttr::get($_builder.getContext(), intcomp), ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:CMOVEQ -- register form, from CMOVEQ_cmovecond_registerZ_registerM_registerO_simple
def LVX_CmoveqOp : LVX_Op<"cmoveq", [Pure]>{
  let summary = "CMOVEQ -- Conditional Move Quadruple Word";
  let arguments = (ins LVX_BcuCondAttr:$cmovecond,
                       LVX_RegType:$test,
                       LVX_RegType:$trueValue,
                       LVX_RegType:$falseValue,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$quotient, LVX_RegType:$remainder);
  let assemblyFormat = "$cmovecond $test `,` $trueValue `,` $falseValue attr-dict `:` `(` qualified(type($test)) `,` qualified(type($trueValue)) `,` qualified(type($falseValue)) `)` `->` `(` qualified(type($quotient)) `,` qualified(type($remainder)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::lvx::BcuCond":$cmovecond, "::mlir::Value":$test, "::mlir::Value":$trueValue, "::mlir::Value":$falseValue), [{
      build($_builder, $_state, resultTypes, ::mlir::lvx::BcuCondAttr::get($_builder.getContext(), cmovecond), test, trueValue, falseValue, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:CMOVED -- register form, from CMOVED_cmovecond_registerZ_registerW_registerY_simple
def LVX_CmovedOp : LVX_Op<"cmoved", [Pure]>{
  let summary = "CMOVED -- Conditional Move Double Word";
  let arguments = (ins LVX_BcuCondAttr:$cmovecond,
                       LVX_RegType:$test,
                       LVX_RegType:$trueValue,
                       LVX_RegType:$falseValue,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$cmovecond $test `,` $trueValue `,` $falseValue attr-dict `:` `(` qualified(type($test)) `,` qualified(type($trueValue)) `,` qualified(type($falseValue)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::lvx::BcuCond":$cmovecond, "::mlir::Value":$test, "::mlir::Value":$trueValue, "::mlir::Value":$falseValue), [{
      build($_builder, $_state, resultType, ::mlir::lvx::BcuCondAttr::get($_builder.getContext(), cmovecond), test, trueValue, falseValue, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:CMOVED -- immediate form, from CMOVED_cmovecond_registerZ_registerW_upper27_lower5_splat32_double
def LVX_CmovedImmOp : LVX_Op<"cmoved_i", [Pure]>{
  let summary = "CMOVED -- Conditional Move Double Word";
  let arguments = (ins LVX_BcuCondAttr:$cmovecond,
                       UnitAttr:$splat32,
                       LVX_RegType:$test,
                       LVX_RegType:$trueValue,
                       LVX_RegType:$falseValue,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`splat32` $splat32^)? $cmovecond $test `,` $trueValue `,` $falseValue attr-dict `:` `(` qualified(type($test)) `,` qualified(type($trueValue)) `,` qualified(type($falseValue)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::lvx::BcuCond":$cmovecond, "::mlir::Value":$test, "::mlir::Value":$trueValue, "::mlir::Value":$falseValue, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::lvx::BcuCondAttr::get($_builder.getContext(), cmovecond), ::mlir::UnitAttr(), test, trueValue, falseValue, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MAKED -- immediate form, from MAKED_registerW_signed16_simple
def LVX_MakedImmOp : LVX_Op<"maked", [Pure]>{
  let summary = "MAKED -- Make Double Word from Immediate";
  let arguments = (ins TypedAttrInterface:$signed16,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = " attr-dict `:` `(`  `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::TypedAttr":$signed16), [{
      build($_builder, $_state, resultType, signed16, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:PCREL -- immediate form, from PCREL_registerW_signed16_simple
def LVX_PcrelImmOp : LVX_Op<"pcrel", [Pure]>{
  let summary = "PCREL -- PC-Relative";
  let arguments = (ins TypedAttrInterface:$signed16,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = " attr-dict `:` `(`  `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::TypedAttr":$signed16), [{
      build($_builder, $_state, resultType, signed16, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:NOTQ -- register form, from NOTQ_registerM_registerP_simple
def LVX_NotqOp : LVX_Op<"notq", [Pure]>{
  let summary = "NOTQ -- Negate Quadruple Word";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$quotient, LVX_RegType:$remainder);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($quotient)) `,` qualified(type($remainder)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:NOTD -- register form, from NOTD_registerW_registerZ_simple
def LVX_NotdOp : LVX_Op<"notd", [Pure]>{
  let summary = "NOTD -- Negate Double Word";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultType, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:NOTW -- register form, from NOTW_signextw_registerW_registerZ_simple
def LVX_NotwOp : LVX_Op<"notw", [Pure]>{
  let summary = "NOTW -- Negate Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:NEGQ -- register form, from NEGQ_registerM_registerP_simple
def LVX_NegqOp : LVX_Op<"negq", [Pure]>{
  let summary = "NEGQ -- Negate Quadruple Word";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$quotient, LVX_RegType:$remainder);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($quotient)) `,` qualified(type($remainder)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:NEGD -- register form, from NEGD_registerW_registerZ_simple
def LVX_NegdOp : LVX_Op<"negd", [Pure]>{
  let summary = "NEGD -- Negate Double Word";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultType, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:NEGW -- register form, from NEGW_signextw_registerW_registerZ_simple
def LVX_NegwOp : LVX_Op<"negw", [Pure]>{
  let summary = "NEGW -- Negate Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:NEGSD -- register form, from NEGSD_registerW_registerZ_simple
def LVX_NegsdOp : LVX_Op<"negsd", [Pure]>{
  let summary = "NEGSD -- Negate Saturated Double Word";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultType, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:NEGSW -- register form, from NEGSW_signextw_registerW_registerZ_simple
def LVX_NegswOp : LVX_Op<"negsw", [Pure]>{
  let summary = "NEGSW -- Negate Saturated Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ABSD -- register form, from ABSD_registerW_registerZ_simple
def LVX_AbsdOp : LVX_Op<"absd", [Pure]>{
  let summary = "ABSD -- Absolute Value Double Word";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultType, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ABSW -- register form, from ABSW_signextw_registerW_registerZ_simple
def LVX_AbswOp : LVX_Op<"absw", [Pure]>{
  let summary = "ABSW -- Absolute Value Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ABSSD -- register form, from ABSSD_registerW_registerZ_simple
def LVX_AbssdOp : LVX_Op<"abssd", [Pure]>{
  let summary = "ABSSD -- Absolute Value Saturated Double Word";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultType, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ABSSW -- register form, from ABSSW_signextw_registerW_registerZ_simple
def LVX_AbsswOp : LVX_Op<"abssw", [Pure]>{
  let summary = "ABSSW -- Absolute Value Saturated Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:CLZD -- register form, from CLZD_registerW_registerZ_simple
def LVX_ClzdOp : LVX_Op<"clzd", [Pure]>{
  let summary = "CLZD -- Count Leading Zero Double Word";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultType, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:CLZW -- register form, from CLZW_signextw_registerW_registerZ_simple
def LVX_ClzwOp : LVX_Op<"clzw", [Pure]>{
  let summary = "CLZW -- Count Leading Zero Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:CLSD -- register form, from CLSD_registerW_registerZ_simple
def LVX_ClsdOp : LVX_Op<"clsd", [Pure]>{
  let summary = "CLSD -- Count Leading Sign Double Word";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultType, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:CLSW -- register form, from CLSW_signextw_registerW_registerZ_simple
def LVX_ClswOp : LVX_Op<"clsw", [Pure]>{
  let summary = "CLSW -- Count Leading Sign Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:CBSD -- register form, from CBSD_registerW_registerZ_simple
def LVX_CbsdOp : LVX_Op<"cbsd", [Pure]>{
  let summary = "CBSD -- Count Bit Set Double Word";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultType, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:CBSW -- register form, from CBSW_signextw_registerW_registerZ_simple
def LVX_CbswOp : LVX_Op<"cbsw", [Pure]>{
  let summary = "CBSW -- Count Bit Set Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:CTZD -- register form, from CTZD_registerW_registerZ_simple
def LVX_CtzdOp : LVX_Op<"ctzd", [Pure]>{
  let summary = "CTZD -- Count Trailing Zero Double Word";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultType, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:CTZW -- register form, from CTZW_signextw_registerW_registerZ_simple
def LVX_CtzwOp : LVX_Op<"ctzw", [Pure]>{
  let summary = "CTZW -- Count Trailing Zero Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MULD -- register form, from MULD_highmult_registerW_registerZ_registerY_simple
def LVX_MuldOp : LVX_Op<"muld", [Pure, Commutative]>{
  let summary = "MULD -- Multiply Double Word";
  let arguments = (ins OptionalAttr<LVX_HighMultAttr>:$highmult,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`` $highmult^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::lvx::HighMultAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MULD -- immediate form, from MULD_highmult_registerW_registerZ_upper27_lower5_splat32_double
def LVX_MuldImmOp : LVX_Op<"muld_i", [Pure, Commutative]>{
  let summary = "MULD -- Multiply Double Word";
  let arguments = (ins OptionalAttr<LVX_HighMultAttr>:$highmult,
                       UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`splat32` $splat32^)? (`` $highmult^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::lvx::HighMultAttr(), ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MULW -- register form, from MULW_highmult_signextw_registerW_registerZ_registerY_simple
def LVX_MulwOp : LVX_Op<"mulw", [Pure, Commutative]>{
  let summary = "MULW -- Multiply Word";
  let arguments = (ins OptionalAttr<LVX_HighMultAttr>:$highmult,
                       UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? (`` $highmult^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::lvx::HighMultAttr(), ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MULW -- immediate form, from MULW_highmult_signextw_registerW_registerZ_upper27_lower5_double
def LVX_MulwImmOp : LVX_Op<"mulw_i", [Pure, Commutative]>{
  let summary = "MULW -- Multiply Word";
  let arguments = (ins OptionalAttr<LVX_HighMultAttr>:$highmult,
                       UnitAttr:$sx,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? (`` $highmult^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::lvx::HighMultAttr(), ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MULND -- register form, from MULND_highmult_registerW_registerZ_registerY_simple
def LVX_MulndOp : LVX_Op<"mulnd", [Pure]>{
  let summary = "MULND -- Multiply Negate Double Word";
  let arguments = (ins OptionalAttr<LVX_HighMultAttr>:$highmult,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`` $highmult^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::lvx::HighMultAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MULND -- immediate form, from MULND_highmult_registerW_registerZ_upper27_lower5_splat32_double
def LVX_MulndImmOp : LVX_Op<"mulnd_i", [Pure]>{
  let summary = "MULND -- Multiply Negate Double Word";
  let arguments = (ins OptionalAttr<LVX_HighMultAttr>:$highmult,
                       UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`splat32` $splat32^)? (`` $highmult^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::lvx::HighMultAttr(), ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MULNW -- register form, from MULNW_highmult_signextw_registerW_registerZ_registerY_simple
def LVX_MulnwOp : LVX_Op<"mulnw", [Pure]>{
  let summary = "MULNW -- Multiply Negate Word";
  let arguments = (ins OptionalAttr<LVX_HighMultAttr>:$highmult,
                       UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? (`` $highmult^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::lvx::HighMultAttr(), ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MULNW -- immediate form, from MULNW_highmult_signextw_registerW_registerZ_upper27_lower5_double
def LVX_MulnwImmOp : LVX_Op<"mulnw_i", [Pure]>{
  let summary = "MULNW -- Multiply Negate Word";
  let arguments = (ins OptionalAttr<LVX_HighMultAttr>:$highmult,
                       UnitAttr:$sx,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? (`` $highmult^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::lvx::HighMultAttr(), ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MULXDQ -- register form, from MULXDQ_widemult_registerM_registerZ_registerY_simple
def LVX_MulxdqOp : LVX_Op<"mulxdq", [Pure]>{
  let summary = "MULXDQ -- Multiply Extend Double Word to Quadruple Word";
  let arguments = (ins OptionalAttr<LVX_WideMultAttr>:$widemult,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$quotient, LVX_RegType:$remainder);
  let assemblyFormat = "(`` $widemult^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($quotient)) `,` qualified(type($remainder)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, ::mlir::lvx::WideMultAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MULXWD -- register form, from MULXWD_widemult_registerW_registerZ_registerY_simple
def LVX_MulxwdOp : LVX_Op<"mulxwd", [Pure]>{
  let summary = "MULXWD -- Multiply Extend Word to Double Word";
  let arguments = (ins OptionalAttr<LVX_WideMultAttr>:$widemult,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`` $widemult^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::lvx::WideMultAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MULXWD -- immediate form, from MULXWD_widemult_registerW_registerZ_upper27_lower5_splat32_double
def LVX_MulxwdImmOp : LVX_Op<"mulxwd_i", [Pure]>{
  let summary = "MULXWD -- Multiply Extend Word to Double Word";
  let arguments = (ins OptionalAttr<LVX_WideMultAttr>:$widemult,
                       UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`splat32` $splat32^)? (`` $widemult^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::lvx::WideMultAttr(), ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MULNXDQ -- register form, from MULNXDQ_widemult_registerM_registerZ_registerY_simple
def LVX_MulnxdqOp : LVX_Op<"mulnxdq", [Pure]>{
  let summary = "MULNXDQ -- Multiply Negate Extend Double Word to Quadruple Word";
  let arguments = (ins OptionalAttr<LVX_WideMultAttr>:$widemult,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$quotient, LVX_RegType:$remainder);
  let assemblyFormat = "(`` $widemult^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($quotient)) `,` qualified(type($remainder)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, ::mlir::lvx::WideMultAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MULNXWD -- register form, from MULNXWD_widemult_registerW_registerZ_registerY_simple
def LVX_MulnxwdOp : LVX_Op<"mulnxwd", [Pure]>{
  let summary = "MULNXWD -- Multiply Negate Extend Word to Double Word";
  let arguments = (ins OptionalAttr<LVX_WideMultAttr>:$widemult,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`` $widemult^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::lvx::WideMultAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MULNXWD -- immediate form, from MULNXWD_widemult_registerW_registerZ_upper27_lower5_splat32_double
def LVX_MulnxwdImmOp : LVX_Op<"mulnxwd_i", [Pure]>{
  let summary = "MULNXWD -- Multiply Negate Extend Word to Double Word";
  let arguments = (ins OptionalAttr<LVX_WideMultAttr>:$widemult,
                       UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`splat32` $splat32^)? (`` $widemult^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::lvx::WideMultAttr(), ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MADDD -- register form, from MADDD_highmult_registerW_registerZ_registerY_simple
def LVX_MadddOp : LVX_Op<"maddd", [Pure]>{
  let summary = "MADDD -- Multiply Add Double Word";
  let arguments = (ins OptionalAttr<LVX_HighMultAttr>:$highmult,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`` $highmult^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::lvx::HighMultAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MADDD -- immediate form, from MADDD_highmult_registerW_registerZ_upper27_lower5_splat32_double
def LVX_MadddImmOp : LVX_Op<"maddd_i", [Pure]>{
  let summary = "MADDD -- Multiply Add Double Word";
  let arguments = (ins OptionalAttr<LVX_HighMultAttr>:$highmult,
                       UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`splat32` $splat32^)? (`` $highmult^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::lvx::HighMultAttr(), ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MADDW -- register form, from MADDW_highmult_signextw_registerW_registerZ_registerY_simple
def LVX_MaddwOp : LVX_Op<"maddw", [Pure]>{
  let summary = "MADDW -- Multiply Add Word";
  let arguments = (ins OptionalAttr<LVX_HighMultAttr>:$highmult,
                       UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? (`` $highmult^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::lvx::HighMultAttr(), ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MADDW -- immediate form, from MADDW_highmult_signextw_registerW_registerZ_upper27_lower5_double
def LVX_MaddwImmOp : LVX_Op<"maddw_i", [Pure]>{
  let summary = "MADDW -- Multiply Add Word";
  let arguments = (ins OptionalAttr<LVX_HighMultAttr>:$highmult,
                       UnitAttr:$sx,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? (`` $highmult^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::lvx::HighMultAttr(), ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MADDXDQ -- register form, from MADDXDQ_widemult_registerM_registerZ_registerY_simple
def LVX_MaddxdqOp : LVX_Op<"maddxdq", [Pure]>{
  let summary = "MADDXDQ -- Multiply Add Extend Double Word to Quadruple Word";
  let arguments = (ins OptionalAttr<LVX_WideMultAttr>:$widemult,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$quotient, LVX_RegType:$remainder);
  let assemblyFormat = "(`` $widemult^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($quotient)) `,` qualified(type($remainder)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, ::mlir::lvx::WideMultAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MADDXWD -- register form, from MADDXWD_widemult_registerW_registerZ_registerY_simple
def LVX_MaddxwdOp : LVX_Op<"maddxwd", [Pure]>{
  let summary = "MADDXWD -- Multiply Add Extend Word to Double Word";
  let arguments = (ins OptionalAttr<LVX_WideMultAttr>:$widemult,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`` $widemult^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::lvx::WideMultAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MADDXWD -- immediate form, from MADDXWD_widemult_registerW_registerZ_upper27_lower5_splat32_double
def LVX_MaddxwdImmOp : LVX_Op<"maddxwd_i", [Pure]>{
  let summary = "MADDXWD -- Multiply Add Extend Word to Double Word";
  let arguments = (ins OptionalAttr<LVX_WideMultAttr>:$widemult,
                       UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`splat32` $splat32^)? (`` $widemult^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::lvx::WideMultAttr(), ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MSBFD -- register form, from MSBFD_highmult_registerW_registerZ_registerY_simple
def LVX_MsbfdOp : LVX_Op<"msbfd", [Pure]>{
  let summary = "MSBFD -- Multiply Subtract From Double Word";
  let arguments = (ins OptionalAttr<LVX_HighMultAttr>:$highmult,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`` $highmult^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::lvx::HighMultAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MSBFD -- immediate form, from MSBFD_highmult_registerW_registerZ_upper27_lower5_splat32_double
def LVX_MsbfdImmOp : LVX_Op<"msbfd_i", [Pure]>{
  let summary = "MSBFD -- Multiply Subtract From Double Word";
  let arguments = (ins OptionalAttr<LVX_HighMultAttr>:$highmult,
                       UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`splat32` $splat32^)? (`` $highmult^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::lvx::HighMultAttr(), ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MSBFW -- register form, from MSBFW_highmult_signextw_registerW_registerZ_registerY_simple
def LVX_MsbfwOp : LVX_Op<"msbfw", [Pure]>{
  let summary = "MSBFW -- Multiply Subtract From Word";
  let arguments = (ins OptionalAttr<LVX_HighMultAttr>:$highmult,
                       UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? (`` $highmult^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::lvx::HighMultAttr(), ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MSBFW -- immediate form, from MSBFW_highmult_signextw_registerW_registerZ_upper27_lower5_double
def LVX_MsbfwImmOp : LVX_Op<"msbfw_i", [Pure]>{
  let summary = "MSBFW -- Multiply Subtract From Word";
  let arguments = (ins OptionalAttr<LVX_HighMultAttr>:$highmult,
                       UnitAttr:$sx,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? (`` $highmult^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::lvx::HighMultAttr(), ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MSBFXDQ -- register form, from MSBFXDQ_widemult_registerM_registerZ_registerY_simple
def LVX_MsbfxdqOp : LVX_Op<"msbfxdq", [Pure]>{
  let summary = "MSBFXDQ -- Multiply Subtract From Extend Double Word to Quadruple Word";
  let arguments = (ins OptionalAttr<LVX_WideMultAttr>:$widemult,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$quotient, LVX_RegType:$remainder);
  let assemblyFormat = "(`` $widemult^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($quotient)) `,` qualified(type($remainder)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, ::mlir::lvx::WideMultAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MSBFXWD -- register form, from MSBFXWD_widemult_registerW_registerZ_registerY_simple
def LVX_MsbfxwdOp : LVX_Op<"msbfxwd", [Pure]>{
  let summary = "MSBFXWD -- Multiply Subtract From Extend Word to Double Word";
  let arguments = (ins OptionalAttr<LVX_WideMultAttr>:$widemult,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`` $widemult^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::lvx::WideMultAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MSBFXWD -- immediate form, from MSBFXWD_widemult_registerW_registerZ_upper27_lower5_splat32_double
def LVX_MsbfxwdImmOp : LVX_Op<"msbfxwd_i", [Pure]>{
  let summary = "MSBFXWD -- Multiply Subtract From Extend Word to Double Word";
  let arguments = (ins OptionalAttr<LVX_WideMultAttr>:$widemult,
                       UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`splat32` $splat32^)? (`` $widemult^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::lvx::WideMultAttr(), ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:DIVMODD -- register form, from DIVMODD_registerM_registerZ_registerY_simple
def LVX_DivmoddOp : LVX_Op<"divmodd", [Pure]>{
  let summary = "DIVMODD -- Integer Division Modulus Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$quotient, LVX_RegType:$remainder);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($quotient)) `,` qualified(type($remainder)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:DIVMODW -- register form, from DIVMODW_signextw_registerM_registerZ_registerY_simple
def LVX_DivmodwOp : LVX_Op<"divmodw", [Pure]>{
  let summary = "DIVMODW -- Integer Division Modulus Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$quotient, LVX_RegType:$remainder);
  let assemblyFormat = "(`sx` $sx^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($quotient)) `,` qualified(type($remainder)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:DIVMODUD -- register form, from DIVMODUD_registerM_registerZ_registerY_simple
def LVX_DivmodudOp : LVX_Op<"divmodud", [Pure]>{
  let summary = "DIVMODUD -- Integer Division Modulus Unsigned Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$quotient, LVX_RegType:$remainder);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($quotient)) `,` qualified(type($remainder)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:DIVMODUW -- register form, from DIVMODUW_signextw_registerM_registerZ_registerY_simple
def LVX_DivmoduwOp : LVX_Op<"divmoduw", [Pure]>{
  let summary = "DIVMODUW -- Integer Division Modulus Unsigned Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$quotient, LVX_RegType:$remainder);
  let assemblyFormat = "(`sx` $sx^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($quotient)) `,` qualified(type($remainder)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:CRCBELMW -- register form, from CRCBELMW_registerW_registerZ_registerY_simple
def LVX_CrcbelmwOp : LVX_Op<"crcbelmw", [Pure]>{
  let summary = "CRCBELMW -- Cyclic Redundancy Check Big-Endian Least Significant with Most Significant Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:CRCBELMW -- immediate form, from CRCBELMW_registerW_registerZ_upper27_lower5_double
def LVX_CrcbelmwImmOp : LVX_Op<"crcbelmw_i", [Pure]>{
  let summary = "CRCBELMW -- Cyclic Redundancy Check Big-Endian Least Significant with Most Significant Word";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:CRCBELLW -- register form, from CRCBELLW_registerW_registerZ_registerY_simple
def LVX_CrcbellwOp : LVX_Op<"crcbellw", [Pure]>{
  let summary = "CRCBELLW -- Cyclic Redundancy Check Big-Endian Least Significant with Least Significant Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:CRCBELLW -- immediate form, from CRCBELLW_registerW_registerZ_upper27_lower5_double
def LVX_CrcbellwImmOp : LVX_Op<"crcbellw_i", [Pure]>{
  let summary = "CRCBELLW -- Cyclic Redundancy Check Big-Endian Least Significant with Least Significant Word";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:CRCLELMW -- register form, from CRCLELMW_registerW_registerZ_registerY_simple
def LVX_CrclelmwOp : LVX_Op<"crclelmw", [Pure]>{
  let summary = "CRCLELMW -- Cyclic Redundancy Check Little-Endian Least Significant with Most Significant Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:CRCLELMW -- immediate form, from CRCLELMW_registerW_registerZ_upper27_lower5_double
def LVX_CrclelmwImmOp : LVX_Op<"crclelmw_i", [Pure]>{
  let summary = "CRCLELMW -- Cyclic Redundancy Check Little-Endian Least Significant with Most Significant Word";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:CRCLELLW -- register form, from CRCLELLW_registerW_registerZ_registerY_simple
def LVX_CrclellwOp : LVX_Op<"crclellw", [Pure]>{
  let summary = "CRCLELLW -- Cyclic Redundancy Check Little-Endian Least Significant with Least Significant Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:CRCLELLW -- immediate form, from CRCLELLW_registerW_registerZ_upper27_lower5_double
def LVX_CrclellwImmOp : LVX_Op<"crclellw_i", [Pure]>{
  let summary = "CRCLELLW -- Cyclic Redundancy Check Little-Endian Least Significant with Least Significant Word";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:CATDQ -- register form, from CATDQ_registerM_registerZ_registerY_simple
def LVX_CatdqOp : LVX_Op<"catdq", [Pure]>{
  let summary = "CATDQ -- Catenate Double to Quadruple Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$quotient, LVX_RegType:$remainder);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($quotient)) `,` qualified(type($remainder)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBMM8 -- register form, from SBMM8_registerW_registerZ_registerY_simple
def LVX_Sbmm8Op : LVX_Op<"sbmm8", [Pure]>{
  let summary = "SBMM8 -- Swapped Bit Matrix Multiplication 8$\times$8";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBMM8 -- immediate form, from SBMM8_registerW_registerZ_signed10_simple
def LVX_Sbmm8ImmOp : LVX_Op<"sbmm8_i", [Pure]>{
  let summary = "SBMM8 -- Swapped Bit Matrix Multiplication 8$\times$8";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$signed10,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$signed10), [{
      build($_builder, $_state, resultType, operand, signed10, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBMMT8 -- register form, from SBMMT8_registerW_registerZ_registerY_simple
def LVX_Sbmmt8Op : LVX_Op<"sbmmt8", [Pure]>{
  let summary = "SBMMT8 -- Swapped Bit Matrix Multiplication Transposed 8$\times$8";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBMMT8 -- immediate form, from SBMMT8_registerW_registerZ_signed10_simple
def LVX_Sbmmt8ImmOp : LVX_Op<"sbmmt8_i", [Pure]>{
  let summary = "SBMMT8 -- Swapped Bit Matrix Multiplication Transposed 8$\times$8";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$signed10,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$signed10), [{
      build($_builder, $_state, resultType, operand, signed10, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:COPYQ -- register form, from COPYQ_registerM_registerZ_registerY_simple
def LVX_CopyqOp : LVX_Op<"copyq", [Pure]>{
  let summary = "COPYQ -- Copy Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$quotient, LVX_RegType:$remainder);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($quotient)) `,` qualified(type($remainder)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:COPYD -- register form, from COPYD_registerW_registerZ_simple
def LVX_CopydOp : LVX_Op<"copyd", [Pure]>{
  let summary = "COPYD -- Copy Double Word";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultType, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ZXBD -- register form, from ZXBD_registerW_registerZ_simple
def LVX_ZxbdOp : LVX_Op<"zxbd", [Pure]>{
  let summary = "ZXBD -- Zero Extend Byte to Double Word";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultType, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SXBD -- register form, from SXBD_registerW_registerZ_simple
def LVX_SxbdOp : LVX_Op<"sxbd", [Pure]>{
  let summary = "SXBD -- Sign Extend Byte to Double Word";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultType, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ZXHD -- register form, from ZXHD_registerW_registerZ_simple
def LVX_ZxhdOp : LVX_Op<"zxhd", [Pure]>{
  let summary = "ZXHD -- Zero Extend Half Word to Double Word";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultType, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SXHD -- register form, from SXHD_registerW_registerZ_simple
def LVX_SxhdOp : LVX_Op<"sxhd", [Pure]>{
  let summary = "SXHD -- Sign Extend Half Word to Double Word";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultType, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ZXWD -- register form, from ZXWD_registerW_registerZ_simple
def LVX_ZxwdOp : LVX_Op<"zxwd", [Pure]>{
  let summary = "ZXWD -- Zero Extend Word to Double Word";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultType, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SXWD -- register form, from SXWD_registerW_registerZ_simple
def LVX_SxwdOp : LVX_Op<"sxwd", [Pure]>{
  let summary = "SXWD -- Sign Extend Word to Double Word";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultType, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:COPYW -- register form, from COPYW_signextw_registerW_registerZ_simple
def LVX_CopywOp : LVX_Op<"copyw", [Pure]>{
  let summary = "COPYW -- Copy Word";
  let arguments = (ins UnitAttr:$sx,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

#endif // LVX_INSTR_OPS
