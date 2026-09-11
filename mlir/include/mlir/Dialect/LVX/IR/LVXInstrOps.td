//===-- LVXInstrOps.td - -*- tablegen -*- ===//
//
// Operations for the LVX dialect, one or two per instruction.
//
// Generated from the LVX Machine Description System by MDS/BE/MLIR, for core
// lvx_v2.  DO NOT EDIT -- your changes will be overwritten by the next
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

// BCU:AWAIT -- register form, from AWAIT_simple
def LVX_AwaitOp : LVX_Op<"await">{
  let summary = "AWAIT -- Wait for any event or interrupt.";
  let arguments = (ins OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "attr-dict";
}

// BCU:SLEEP -- register form, from SLEEP_simple
def LVX_SleepOp : LVX_Op<"sleep">{
  let summary = "SLEEP -- Wait for an eligible interrupt.";
  let arguments = (ins OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "attr-dict";
}

// BCU:STOP -- register form, from STOP_simple
def LVX_StopOp : LVX_Op<"stop">{
  let summary = "STOP -- Wait for power controller wake-up.";
  let arguments = (ins OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "attr-dict";
}

// BCU:BARRIER -- register form, from BARRIER_simple
def LVX_BarrierOp : LVX_Op<"barrier">{
  let summary = "BARRIER -- Instruction Pipeline Barrier";
  let arguments = (ins OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "attr-dict";
}

// BCU:TLBREAD -- register form, from TLBREAD_simple
def LVX_TlbreadOp : LVX_Op<"tlbread">{
  let summary = "TLBREAD -- Read TLB Entry";
  let arguments = (ins OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "attr-dict";
}

// BCU:TLBPROBE -- register form, from TLBPROBE_simple
def LVX_TlbprobeOp : LVX_Op<"tlbprobe">{
  let summary = "TLBPROBE -- Probe TLB";
  let arguments = (ins OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "attr-dict";
}

// BCU:TLBWRITE -- register form, from TLBWRITE_simple
def LVX_TlbwriteOp : LVX_Op<"tlbwrite">{
  let summary = "TLBWRITE -- TLB Entry Write";
  let arguments = (ins OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "attr-dict";
}

// BCU:TLBDINVAL -- register form, from TLBDINVAL_simple
def LVX_TlbdinvalOp : LVX_Op<"tlbdinval">{
  let summary = "TLBDINVAL -- Invalidate Data Micro-TLB.";
  let arguments = (ins OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "attr-dict";
}

// BCU:TLBIINVAL -- register form, from TLBIINVAL_simple
def LVX_TlbiinvalOp : LVX_Op<"tlbiinval">{
  let summary = "TLBIINVAL -- Invalidate Instruction Micro-TLB.";
  let arguments = (ins OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "attr-dict";
}

// BCU:BREAK -- immediate form, from BREAK_brknumber_simple
def LVX_BreakImmOp : LVX_Op<"break">{
  let summary = "BREAK -- Debugger Breakpoint";
  let arguments = (ins TypedAttrInterface:$brknumber,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "$brknumber attr-dict";
  let builders = [
    OpBuilder<(ins "::mlir::TypedAttr":$brknumber), [{
      build($_builder, $_state, brknumber, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// BCU:RFE -- register form, from RFE_simple
def LVX_RfeOp : LVX_Op<"rfe">{
  let summary = "RFE -- Return from Exception";
  let arguments = (ins OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "attr-dict";
}

// BCU:SCALL -- register form, from SCALL_registerZ_simple
def LVX_ScallOp : LVX_Op<"scall">{
  let summary = "SCALL -- System Call";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$operand), [{
      build($_builder, $_state, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// BCU:SCALL -- immediate form, from SCALL_sysnumber_simple
def LVX_ScallImmOp : LVX_Op<"scall_i">{
  let summary = "SCALL -- System Call";
  let arguments = (ins TypedAttrInterface:$sysnumber,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "$sysnumber attr-dict";
  let builders = [
    OpBuilder<(ins "::mlir::TypedAttr":$sysnumber), [{
      build($_builder, $_state, sysnumber, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// BCU:WFXL -- register form, from WFXL_systemT2_registerZ_simple
def LVX_WfxlOp : LVX_Op<"wfxl">{
  let summary = "WFXL -- Effects on Least Significant Word System Register";
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

// BCU:WFXM -- register form, from WFXM_systemT2_registerZ_simple
def LVX_WfxmOp : LVX_Op<"wfxm">{
  let summary = "WFXM -- Word Effects on Most Significant Word System Register";
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

// BCU:GET -- register form, from GET_registerZ_systemS2_simple
def LVX_GetOp : LVX_Op<"get">{
  let summary = "GET -- Get System Register";
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

// BCU:IGET -- register form, from IGET_registerZ_simple
def LVX_IgetOp : LVX_Op<"iget">{
  let summary = "IGET -- Indirect Get System Register";
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

// BCU:SET -- register form, from SET_systemT3_registerZ_simple
def LVX_SetOp : LVX_Op<"set">{
  let summary = "SET -- Set System Register";
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

// BCU:RSWAP -- register form, from RSWAP_registerZ_systemS4_simple
def LVX_RswapOp : LVX_Op<"rswap">{
  let summary = "RSWAP -- General and System Register Swap";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// BCU:CSRRW -- immediate form, from CSRRW_registerZ_csrnumber_simple
def LVX_CsrrwImmOp : LVX_Op<"csrrw">{
  let summary = "CSRRW -- RISC-V CSR Read/Write (atomic) of the fcsr view of Compute Status";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$csrnumber,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$csrnumber `,` $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$csrnumber), [{
      build($_builder, $_state, resultType, operand, csrnumber, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// BCU:CSRRS -- immediate form, from CSRRS_registerZ_csrnumber_simple
def LVX_CsrrsImmOp : LVX_Op<"csrrs">{
  let summary = "CSRRS -- RISC-V CSR Read/Set (atomic) of the fcsr view of Compute Status";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$csrnumber,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$csrnumber `,` $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$csrnumber), [{
      build($_builder, $_state, resultType, operand, csrnumber, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// BCU:CSRRC -- immediate form, from CSRRC_registerZ_csrnumber_simple
def LVX_CsrrcImmOp : LVX_Op<"csrrc">{
  let summary = "CSRRC -- RISC-V CSR Read/Clear (atomic) of the fcsr view of Compute Status";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$csrnumber,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$csrnumber `,` $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$csrnumber), [{
      build($_builder, $_state, resultType, operand, csrnumber, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// BCU:WAITIT -- register form, from WAITIT_registerZ_simple
def LVX_WaititOp : LVX_Op<"waitit">{
  let summary = "WAITIT -- Wait for Interrupt";
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

// BCU:SYNCGROUP -- register form, from SYNCGROUP_registerZ_simple
def LVX_SyncgroupOp : LVX_Op<"syncgroup">{
  let summary = "SYNCGROUP -- Synchronize Group of Cores";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$operand), [{
      build($_builder, $_state, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// BCU:GUARD -- immediate form, from GUARD_execpred_registerZ_activate_simple
def LVX_GuardImmOp : LVX_Op<"guard">{
  let summary = "GUARD -- Guarded execution prefix.";
  let arguments = (ins LVX_BcuCondAttr:$execpred,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$activate,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "$execpred $operand `,` $activate attr-dict `:` `(` qualified(type($operand)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::lvx::BcuCond":$execpred, "::mlir::Value":$operand, "::mlir::TypedAttr":$activate), [{
      build($_builder, $_state, ::mlir::lvx::BcuCondAttr::get($_builder.getContext(), execpred), operand, activate, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// BCU:BLEND -- immediate form, from BLEND_lanetodo_lanesize_registerZ_activate_simple
def LVX_BlendImmOp : LVX_Op<"blend">{
  let summary = "BLEND -- Blended execution prefix";
  let arguments = (ins LVX_LaneTodoAttr:$lanetodo,
                       OptionalAttr<LVX_LaneSizeAttr>:$lanesize,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$activate,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "$lanetodo ($lanesize^)? $operand `,` $activate attr-dict `:` `(` qualified(type($operand)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::lvx::LaneTodo":$lanetodo, "::mlir::Value":$operand, "::mlir::TypedAttr":$activate, CArg<"::mlir::lvx::LaneSizeAttr", "{}">:$lanesize), [{
      build($_builder, $_state, ::mlir::lvx::LaneTodoAttr::get($_builder.getContext(), lanetodo), lanesize, operand, activate, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:LBZ -- register form, from LBZ_variant_registerW_registerY_registerZ_simple
def LVX_LbzRegOp : LVX_Op<"lbz_r", [MemoryEffects<[MemRead]>]>{
  let summary = "LBZ -- Load Byte Zero Extended";
  let arguments = (ins OptionalAttr<LVX_VariantAttr>:$variant,
                       LVX_RegType:$base,
                       LVX_RegType:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($variant^)? $base `,` $offset attr-dict `:` `(` qualified(type($base)) `,` qualified(type($offset)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$offset, CArg<"::mlir::lvx::VariantAttr", "{}">:$variant), [{
      build($_builder, $_state, resultType, variant, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:LBZ -- immediate form, from LBZ_variant_registerW_signed10_registerZ_simple
def LVX_LbzOp : LVX_Op<"lbz", [MemoryEffects<[MemRead]>]>{
  let summary = "LBZ -- Load Byte Zero Extended";
  let arguments = (ins OptionalAttr<LVX_VariantAttr>:$variant,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($variant^)? $base `,` $offset attr-dict `:` `(` qualified(type($base)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::TypedAttr":$offset, CArg<"::mlir::lvx::VariantAttr", "{}">:$variant), [{
      build($_builder, $_state, resultType, variant, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:LBS -- register form, from LBS_variant_registerW_registerY_registerZ_simple
def LVX_LbsRegOp : LVX_Op<"lbs_r", [MemoryEffects<[MemRead]>]>{
  let summary = "LBS -- Load Byte Sign Extended";
  let arguments = (ins OptionalAttr<LVX_VariantAttr>:$variant,
                       LVX_RegType:$base,
                       LVX_RegType:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($variant^)? $base `,` $offset attr-dict `:` `(` qualified(type($base)) `,` qualified(type($offset)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$offset, CArg<"::mlir::lvx::VariantAttr", "{}">:$variant), [{
      build($_builder, $_state, resultType, variant, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:LBS -- immediate form, from LBS_variant_registerW_signed10_registerZ_simple
def LVX_LbsOp : LVX_Op<"lbs", [MemoryEffects<[MemRead]>]>{
  let summary = "LBS -- Load Byte Sign Extended";
  let arguments = (ins OptionalAttr<LVX_VariantAttr>:$variant,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($variant^)? $base `,` $offset attr-dict `:` `(` qualified(type($base)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::TypedAttr":$offset, CArg<"::mlir::lvx::VariantAttr", "{}">:$variant), [{
      build($_builder, $_state, resultType, variant, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:LHZ -- register form, from LHZ_variant_registerW_registerY_registerZ_simple
def LVX_LhzRegOp : LVX_Op<"lhz_r", [MemoryEffects<[MemRead]>]>{
  let summary = "LHZ -- Load Half Word Zero Extended";
  let arguments = (ins OptionalAttr<LVX_VariantAttr>:$variant,
                       LVX_RegType:$base,
                       LVX_RegType:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($variant^)? $base `,` $offset attr-dict `:` `(` qualified(type($base)) `,` qualified(type($offset)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$offset, CArg<"::mlir::lvx::VariantAttr", "{}">:$variant), [{
      build($_builder, $_state, resultType, variant, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:LHZ -- immediate form, from LHZ_variant_registerW_signed10_registerZ_simple
def LVX_LhzOp : LVX_Op<"lhz", [MemoryEffects<[MemRead]>]>{
  let summary = "LHZ -- Load Half Word Zero Extended";
  let arguments = (ins OptionalAttr<LVX_VariantAttr>:$variant,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($variant^)? $base `,` $offset attr-dict `:` `(` qualified(type($base)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::TypedAttr":$offset, CArg<"::mlir::lvx::VariantAttr", "{}">:$variant), [{
      build($_builder, $_state, resultType, variant, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:LHS -- register form, from LHS_variant_registerW_registerY_registerZ_simple
def LVX_LhsRegOp : LVX_Op<"lhs_r", [MemoryEffects<[MemRead]>]>{
  let summary = "LHS -- Load Half Word Sign Extended";
  let arguments = (ins OptionalAttr<LVX_VariantAttr>:$variant,
                       LVX_RegType:$base,
                       LVX_RegType:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($variant^)? $base `,` $offset attr-dict `:` `(` qualified(type($base)) `,` qualified(type($offset)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$offset, CArg<"::mlir::lvx::VariantAttr", "{}">:$variant), [{
      build($_builder, $_state, resultType, variant, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:LHS -- immediate form, from LHS_variant_registerW_signed10_registerZ_simple
def LVX_LhsOp : LVX_Op<"lhs", [MemoryEffects<[MemRead]>]>{
  let summary = "LHS -- Load Half Word Sign Extended";
  let arguments = (ins OptionalAttr<LVX_VariantAttr>:$variant,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($variant^)? $base `,` $offset attr-dict `:` `(` qualified(type($base)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::TypedAttr":$offset, CArg<"::mlir::lvx::VariantAttr", "{}">:$variant), [{
      build($_builder, $_state, resultType, variant, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:LWZ -- register form, from LWZ_variant_registerW_registerY_registerZ_simple
def LVX_LwzRegOp : LVX_Op<"lwz_r", [MemoryEffects<[MemRead]>]>{
  let summary = "LWZ -- Load Word Zero Extended";
  let arguments = (ins OptionalAttr<LVX_VariantAttr>:$variant,
                       LVX_RegType:$base,
                       LVX_RegType:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($variant^)? $base `,` $offset attr-dict `:` `(` qualified(type($base)) `,` qualified(type($offset)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$offset, CArg<"::mlir::lvx::VariantAttr", "{}">:$variant), [{
      build($_builder, $_state, resultType, variant, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:LWZ -- immediate form, from LWZ_variant_registerW_signed10_registerZ_simple
def LVX_LwzOp : LVX_Op<"lwz", [MemoryEffects<[MemRead]>]>{
  let summary = "LWZ -- Load Word Zero Extended";
  let arguments = (ins OptionalAttr<LVX_VariantAttr>:$variant,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($variant^)? $base `,` $offset attr-dict `:` `(` qualified(type($base)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::TypedAttr":$offset, CArg<"::mlir::lvx::VariantAttr", "{}">:$variant), [{
      build($_builder, $_state, resultType, variant, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:LWS -- register form, from LWS_variant_registerW_registerY_registerZ_simple
def LVX_LwsRegOp : LVX_Op<"lws_r", [MemoryEffects<[MemRead]>]>{
  let summary = "LWS -- Load Word Sign Extended";
  let arguments = (ins OptionalAttr<LVX_VariantAttr>:$variant,
                       LVX_RegType:$base,
                       LVX_RegType:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($variant^)? $base `,` $offset attr-dict `:` `(` qualified(type($base)) `,` qualified(type($offset)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$offset, CArg<"::mlir::lvx::VariantAttr", "{}">:$variant), [{
      build($_builder, $_state, resultType, variant, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:LWS -- immediate form, from LWS_variant_registerW_signed10_registerZ_simple
def LVX_LwsOp : LVX_Op<"lws", [MemoryEffects<[MemRead]>]>{
  let summary = "LWS -- Load Word Sign Extended";
  let arguments = (ins OptionalAttr<LVX_VariantAttr>:$variant,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($variant^)? $base `,` $offset attr-dict `:` `(` qualified(type($base)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::TypedAttr":$offset, CArg<"::mlir::lvx::VariantAttr", "{}">:$variant), [{
      build($_builder, $_state, resultType, variant, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:LD -- register form, from LD_variant_registerW_registerY_registerZ_simple
def LVX_LdRegOp : LVX_Op<"ld_r", [MemoryEffects<[MemRead]>]>{
  let summary = "LD -- Load Double Word";
  let arguments = (ins OptionalAttr<LVX_VariantAttr>:$variant,
                       LVX_RegType:$base,
                       LVX_RegType:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($variant^)? $base `,` $offset attr-dict `:` `(` qualified(type($base)) `,` qualified(type($offset)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$offset, CArg<"::mlir::lvx::VariantAttr", "{}">:$variant), [{
      build($_builder, $_state, resultType, variant, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:LD -- immediate form, from LD_variant_registerW_signed10_registerZ_simple
def LVX_LdOp : LVX_Op<"ld", [MemoryEffects<[MemRead]>]>{
  let summary = "LD -- Load Double Word";
  let arguments = (ins OptionalAttr<LVX_VariantAttr>:$variant,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($variant^)? $base `,` $offset attr-dict `:` `(` qualified(type($base)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::TypedAttr":$offset, CArg<"::mlir::lvx::VariantAttr", "{}">:$variant), [{
      build($_builder, $_state, resultType, variant, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:LQ -- register form, from LQ_variant_registerM_registerY_registerZ_simple
def LVX_LqRegOp : LVX_Op<"lq_r", [MemoryEffects<[MemRead]>]>{
  let summary = "LQ -- Load Quadruple Word";
  let arguments = (ins OptionalAttr<LVX_VariantAttr>:$variant,
                       LVX_RegType:$base,
                       LVX_RegType:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($variant^)? $base `,` $offset attr-dict `:` `(` qualified(type($base)) `,` qualified(type($offset)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$base, "::mlir::Value":$offset, CArg<"::mlir::lvx::VariantAttr", "{}">:$variant), [{
      build($_builder, $_state, resultTypes, variant, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:LQ -- immediate form, from LQ_variant_registerM_signed10_registerZ_simple
def LVX_LqOp : LVX_Op<"lq", [MemoryEffects<[MemRead]>]>{
  let summary = "LQ -- Load Quadruple Word";
  let arguments = (ins OptionalAttr<LVX_VariantAttr>:$variant,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($variant^)? $base `,` $offset attr-dict `:` `(` qualified(type($base)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$base, "::mlir::TypedAttr":$offset, CArg<"::mlir::lvx::VariantAttr", "{}">:$variant), [{
      build($_builder, $_state, resultTypes, variant, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:LO -- register form, from LO_variant_registerN_registerY_registerZ_simple
def LVX_LoRegOp : LVX_Op<"lo_r", [MemoryEffects<[MemRead]>]>{
  let summary = "LO -- Load Octuple Word";
  let arguments = (ins OptionalAttr<LVX_VariantAttr>:$variant,
                       LVX_RegType:$base,
                       LVX_RegType:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$x, LVX_RegType:$y, LVX_RegType:$z, LVX_RegType:$t);
  let assemblyFormat = "($variant^)? $base `,` $offset attr-dict `:` `(` qualified(type($base)) `,` qualified(type($offset)) `)` `->` `(` qualified(type($x)) `,` qualified(type($y)) `,` qualified(type($z)) `,` qualified(type($t)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$base, "::mlir::Value":$offset, CArg<"::mlir::lvx::VariantAttr", "{}">:$variant), [{
      build($_builder, $_state, resultTypes, variant, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:LO -- immediate form, from LO_variant_registerN_signed10_registerZ_simple
def LVX_LoOp : LVX_Op<"lo", [MemoryEffects<[MemRead]>]>{
  let summary = "LO -- Load Octuple Word";
  let arguments = (ins OptionalAttr<LVX_VariantAttr>:$variant,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$x, LVX_RegType:$y, LVX_RegType:$z, LVX_RegType:$t);
  let assemblyFormat = "($variant^)? $base `,` $offset attr-dict `:` `(` qualified(type($base)) `)` `->` `(` qualified(type($x)) `,` qualified(type($y)) `,` qualified(type($z)) `,` qualified(type($t)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$base, "::mlir::TypedAttr":$offset, CArg<"::mlir::lvx::VariantAttr", "{}">:$variant), [{
      build($_builder, $_state, resultTypes, variant, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:SB -- register form, from SB_registerY_registerZ_registerT_simple
def LVX_SbRegOp : LVX_Op<"sb_r", [MemoryEffects<[MemWrite]>]>{
  let summary = "SB -- Store Byte";
  let arguments = (ins LVX_RegType:$value,
                       LVX_RegType:$base,
                       LVX_RegType:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "$value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `,` qualified(type($offset)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::Value":$offset), [{
      build($_builder, $_state, value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:SB -- immediate form, from SB_signed10_registerZ_registerT_simple
def LVX_SbOp : LVX_Op<"sb", [MemoryEffects<[MemWrite]>]>{
  let summary = "SB -- Store Byte";
  let arguments = (ins LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "$value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:SH -- register form, from SH_registerY_registerZ_registerT_simple
def LVX_ShRegOp : LVX_Op<"sh_r", [MemoryEffects<[MemWrite]>]>{
  let summary = "SH -- Store Half Word";
  let arguments = (ins LVX_RegType:$value,
                       LVX_RegType:$base,
                       LVX_RegType:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "$value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `,` qualified(type($offset)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::Value":$offset), [{
      build($_builder, $_state, value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:SH -- immediate form, from SH_signed10_registerZ_registerT_simple
def LVX_ShOp : LVX_Op<"sh", [MemoryEffects<[MemWrite]>]>{
  let summary = "SH -- Store Half Word";
  let arguments = (ins LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "$value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:SW -- register form, from SW_registerY_registerZ_registerT_simple
def LVX_SwRegOp : LVX_Op<"sw_r", [MemoryEffects<[MemWrite]>]>{
  let summary = "SW -- Store Word";
  let arguments = (ins LVX_RegType:$value,
                       LVX_RegType:$base,
                       LVX_RegType:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "$value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `,` qualified(type($offset)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::Value":$offset), [{
      build($_builder, $_state, value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:SW -- immediate form, from SW_signed10_registerZ_registerT_simple
def LVX_SwOp : LVX_Op<"sw", [MemoryEffects<[MemWrite]>]>{
  let summary = "SW -- Store Word";
  let arguments = (ins LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "$value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:SD -- register form, from SD_registerY_registerZ_registerT_simple
def LVX_SdRegOp : LVX_Op<"sd_r", [MemoryEffects<[MemWrite]>]>{
  let summary = "SD -- Store Double Word";
  let arguments = (ins LVX_RegType:$value,
                       LVX_RegType:$base,
                       LVX_RegType:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "$value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `,` qualified(type($offset)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::Value":$offset), [{
      build($_builder, $_state, value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:SD -- immediate form, from SD_signed10_registerZ_registerT_simple
def LVX_SdOp : LVX_Op<"sd", [MemoryEffects<[MemWrite]>]>{
  let summary = "SD -- Store Double Word";
  let arguments = (ins LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "$value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:SQ -- register form, from SQ_registerY_registerZ_registerU_simple
def LVX_SqRegOp : LVX_Op<"sq_r", [MemoryEffects<[MemWrite]>]>{
  let summary = "SQ -- Store Quadruple Word";
  let arguments = (ins LVX_RegType:$value,
                       LVX_RegType:$base,
                       LVX_RegType:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "$value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `,` qualified(type($offset)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::Value":$offset), [{
      build($_builder, $_state, value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:SQ -- immediate form, from SQ_signed10_registerZ_registerU_simple
def LVX_SqOp : LVX_Op<"sq", [MemoryEffects<[MemWrite]>]>{
  let summary = "SQ -- Store Quadruple Word";
  let arguments = (ins LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "$value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:SO -- register form, from SO_registerY_registerZ_registerV_simple
def LVX_SoRegOp : LVX_Op<"so_r", [MemoryEffects<[MemWrite]>]>{
  let summary = "SO -- Store Octuple Word";
  let arguments = (ins LVX_RegType:$value,
                       LVX_RegType:$base,
                       LVX_RegType:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "$value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `,` qualified(type($offset)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::Value":$offset), [{
      build($_builder, $_state, value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:SO -- immediate form, from SO_signed10_registerZ_registerV_simple
def LVX_SoOp : LVX_Op<"so", [MemoryEffects<[MemWrite]>]>{
  let summary = "SO -- Store Octuple Word";
  let arguments = (ins LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "$value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ACSWAPB -- register form, from ACSWAPB_boolcas_coherency_registerW_registerZ_registerO_simple
def LVX_AcswapbOp : LVX_Op<"acswapb", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ACSWAPB -- Atomic Compare and Swap Byte";
  let arguments = (ins UnitAttr:$v,
                       UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? (`v` $v^)? $value `,` $base attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$value, "::mlir::Value":$base), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), ::mlir::UnitAttr(), value, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ACSWAPB -- immediate form, from ACSWAPB_boolcas_coherency_registerW_offset27_registerZ_registerO_double
def LVX_AcswapbImmOp : LVX_Op<"acswapb_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ACSWAPB -- Atomic Compare and Swap Byte";
  let arguments = (ins UnitAttr:$v,
                       UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? (`v` $v^)? $value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), ::mlir::UnitAttr(), value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ACSWAPH -- register form, from ACSWAPH_boolcas_coherency_registerW_registerZ_registerO_simple
def LVX_AcswaphOp : LVX_Op<"acswaph", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ACSWAPH -- Atomic Compare and Swap Half Word";
  let arguments = (ins UnitAttr:$v,
                       UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? (`v` $v^)? $value `,` $base attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$value, "::mlir::Value":$base), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), ::mlir::UnitAttr(), value, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ACSWAPH -- immediate form, from ACSWAPH_boolcas_coherency_registerW_offset27_registerZ_registerO_double
def LVX_AcswaphImmOp : LVX_Op<"acswaph_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ACSWAPH -- Atomic Compare and Swap Half Word";
  let arguments = (ins UnitAttr:$v,
                       UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? (`v` $v^)? $value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), ::mlir::UnitAttr(), value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ACSWAPW -- register form, from ACSWAPW_boolcas_coherency_registerW_registerZ_registerO_simple
def LVX_AcswapwOp : LVX_Op<"acswapw", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ACSWAPW -- Atomic Compare and Swap Word";
  let arguments = (ins UnitAttr:$v,
                       UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? (`v` $v^)? $value `,` $base attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$value, "::mlir::Value":$base), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), ::mlir::UnitAttr(), value, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ACSWAPW -- immediate form, from ACSWAPW_boolcas_coherency_registerW_offset27_registerZ_registerO_double
def LVX_AcswapwImmOp : LVX_Op<"acswapw_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ACSWAPW -- Atomic Compare and Swap Word";
  let arguments = (ins UnitAttr:$v,
                       UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? (`v` $v^)? $value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), ::mlir::UnitAttr(), value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ACSWAPD -- register form, from ACSWAPD_boolcas_coherency_registerW_registerZ_registerO_simple
def LVX_AcswapdOp : LVX_Op<"acswapd", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ACSWAPD -- Atomic Compare and Swap Double Word";
  let arguments = (ins UnitAttr:$v,
                       UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? (`v` $v^)? $value `,` $base attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$value, "::mlir::Value":$base), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), ::mlir::UnitAttr(), value, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ACSWAPD -- immediate form, from ACSWAPD_boolcas_coherency_registerW_offset27_registerZ_registerO_double
def LVX_AcswapdImmOp : LVX_Op<"acswapd_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ACSWAPD -- Atomic Compare and Swap Double Word";
  let arguments = (ins UnitAttr:$v,
                       UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? (`v` $v^)? $value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), ::mlir::UnitAttr(), value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ACSWAPQ -- register form, from ACSWAPQ_boolcas_coherency_registerM_registerZ_registerQ_simple
def LVX_AcswapqOp : LVX_Op<"acswapq", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ACSWAPQ -- Atomic Compare and Swap Quadruple Word";
  let arguments = (ins UnitAttr:$v,
                       UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`g` $g^)? (`v` $v^)? $value `,` $base attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$value, "::mlir::Value":$base), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), ::mlir::UnitAttr(), value, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ACSWAPQ -- immediate form, from ACSWAPQ_boolcas_coherency_registerM_offset27_registerZ_registerQ_double
def LVX_AcswapqImmOp : LVX_Op<"acswapq_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ACSWAPQ -- Atomic Compare and Swap Quadruple Word";
  let arguments = (ins UnitAttr:$v,
                       UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`g` $g^)? (`v` $v^)? $value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), ::mlir::UnitAttr(), value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALB -- register form, from ALB_coherency_registerW_registerZ_simple
def LVX_AlbOp : LVX_Op<"alb", [MemoryEffects<[MemRead]>]>{
  let summary = "ALB -- Atomic Load Byte";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base attr-dict `:` `(` qualified(type($base)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALB -- immediate form, from ALB_coherency_registerW_offset27_registerZ_double
def LVX_AlbImmOp : LVX_Op<"alb_i", [MemoryEffects<[MemRead]>]>{
  let summary = "ALB -- Atomic Load Byte";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $offset `,` $base attr-dict `:` `(` qualified(type($base)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALH -- register form, from ALH_coherency_registerW_registerZ_simple
def LVX_AlhOp : LVX_Op<"alh", [MemoryEffects<[MemRead]>]>{
  let summary = "ALH -- Atomic Load Half Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base attr-dict `:` `(` qualified(type($base)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALH -- immediate form, from ALH_coherency_registerW_offset27_registerZ_double
def LVX_AlhImmOp : LVX_Op<"alh_i", [MemoryEffects<[MemRead]>]>{
  let summary = "ALH -- Atomic Load Half Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $offset `,` $base attr-dict `:` `(` qualified(type($base)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALW -- register form, from ALW_coherency_registerW_registerZ_simple
def LVX_AlwOp : LVX_Op<"alw", [MemoryEffects<[MemRead]>]>{
  let summary = "ALW -- Atomic Load Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base attr-dict `:` `(` qualified(type($base)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALW -- immediate form, from ALW_coherency_registerW_offset27_registerZ_double
def LVX_AlwImmOp : LVX_Op<"alw_i", [MemoryEffects<[MemRead]>]>{
  let summary = "ALW -- Atomic Load Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $offset `,` $base attr-dict `:` `(` qualified(type($base)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALD -- register form, from ALD_coherency_registerW_registerZ_simple
def LVX_AldOp : LVX_Op<"ald", [MemoryEffects<[MemRead]>]>{
  let summary = "ALD -- Atomic Load Double Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base attr-dict `:` `(` qualified(type($base)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALD -- immediate form, from ALD_coherency_registerW_offset27_registerZ_double
def LVX_AldImmOp : LVX_Op<"ald_i", [MemoryEffects<[MemRead]>]>{
  let summary = "ALD -- Atomic Load Double Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $offset `,` $base attr-dict `:` `(` qualified(type($base)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALCLRB -- register form, from ALCLRB_coherency_registerW_registerZ_simple
def LVX_AlclrbOp : LVX_Op<"alclrb", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALCLRB -- Atomic Load and Clear Byte";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base attr-dict `:` `(` qualified(type($base)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALCLRB -- immediate form, from ALCLRB_coherency_registerW_offset27_registerZ_double
def LVX_AlclrbImmOp : LVX_Op<"alclrb_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALCLRB -- Atomic Load and Clear Byte";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $offset `,` $base attr-dict `:` `(` qualified(type($base)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALCLRH -- register form, from ALCLRH_coherency_registerW_registerZ_simple
def LVX_AlclrhOp : LVX_Op<"alclrh", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALCLRH -- Atomic Load and Clear Half Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base attr-dict `:` `(` qualified(type($base)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALCLRH -- immediate form, from ALCLRH_coherency_registerW_offset27_registerZ_double
def LVX_AlclrhImmOp : LVX_Op<"alclrh_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALCLRH -- Atomic Load and Clear Half Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $offset `,` $base attr-dict `:` `(` qualified(type($base)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALCLRW -- register form, from ALCLRW_coherency_registerW_registerZ_simple
def LVX_AlclrwOp : LVX_Op<"alclrw", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALCLRW -- Atomic Load and Clear Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base attr-dict `:` `(` qualified(type($base)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALCLRW -- immediate form, from ALCLRW_coherency_registerW_offset27_registerZ_double
def LVX_AlclrwImmOp : LVX_Op<"alclrw_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALCLRW -- Atomic Load and Clear Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $offset `,` $base attr-dict `:` `(` qualified(type($base)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALCLRD -- register form, from ALCLRD_coherency_registerW_registerZ_simple
def LVX_AlclrdOp : LVX_Op<"alclrd", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALCLRD -- Atomic Load and Clear Double Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base attr-dict `:` `(` qualified(type($base)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALCLRD -- immediate form, from ALCLRD_coherency_registerW_offset27_registerZ_double
def LVX_AlclrdImmOp : LVX_Op<"alclrd_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALCLRD -- Atomic Load and Clear Double Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $offset `,` $base attr-dict `:` `(` qualified(type($base)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASWAPB -- register form, from ASWAPB_coherency_registerZ_registerT_simple
def LVX_AswapbOp : LVX_Op<"aswapb", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASWAPB -- Atomic Swap Byte";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASWAPB -- immediate form, from ASWAPB_coherency_offset27_registerZ_registerT_double
def LVX_AswapbImmOp : LVX_Op<"aswapb_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASWAPB -- Atomic Swap Byte";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $offset `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASWAPH -- register form, from ASWAPH_coherency_registerZ_registerT_simple
def LVX_AswaphOp : LVX_Op<"aswaph", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASWAPH -- Atomic Swap Half Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASWAPH -- immediate form, from ASWAPH_coherency_offset27_registerZ_registerT_double
def LVX_AswaphImmOp : LVX_Op<"aswaph_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASWAPH -- Atomic Swap Half Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $offset `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASWAPW -- register form, from ASWAPW_coherency_registerZ_registerT_simple
def LVX_AswapwOp : LVX_Op<"aswapw", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASWAPW -- Atomic Swap Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASWAPW -- immediate form, from ASWAPW_coherency_offset27_registerZ_registerT_double
def LVX_AswapwImmOp : LVX_Op<"aswapw_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASWAPW -- Atomic Swap Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $offset `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASWAPD -- register form, from ASWAPD_coherency_registerZ_registerT_simple
def LVX_AswapdOp : LVX_Op<"aswapd", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASWAPD -- Atomic Swap Double Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASWAPD -- immediate form, from ASWAPD_coherency_offset27_registerZ_registerT_double
def LVX_AswapdImmOp : LVX_Op<"aswapd_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASWAPD -- Atomic Swap Double Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $offset `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASB -- register form, from ASB_coherency_registerZ_registerT_simple
def LVX_AsbOp : LVX_Op<"asb", [MemoryEffects<[MemWrite]>]>{
  let summary = "ASB -- Atomic Store Byte";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASB -- immediate form, from ASB_coherency_offset27_registerZ_registerT_double
def LVX_AsbImmOp : LVX_Op<"asb_i", [MemoryEffects<[MemWrite]>]>{
  let summary = "ASB -- Atomic Store Byte";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASH -- register form, from ASH_coherency_registerZ_registerT_simple
def LVX_AshOp : LVX_Op<"ash", [MemoryEffects<[MemWrite]>]>{
  let summary = "ASH -- Atomic Store Half Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASH -- immediate form, from ASH_coherency_offset27_registerZ_registerT_double
def LVX_AshImmOp : LVX_Op<"ash_i", [MemoryEffects<[MemWrite]>]>{
  let summary = "ASH -- Atomic Store Half Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASW -- register form, from ASW_coherency_registerZ_registerT_simple
def LVX_AswOp : LVX_Op<"asw", [MemoryEffects<[MemWrite]>]>{
  let summary = "ASW -- Atomic Store Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASW -- immediate form, from ASW_coherency_offset27_registerZ_registerT_double
def LVX_AswImmOp : LVX_Op<"asw_i", [MemoryEffects<[MemWrite]>]>{
  let summary = "ASW -- Atomic Store Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASD -- register form, from ASD_coherency_registerZ_registerT_simple
def LVX_AsdOp : LVX_Op<"asd", [MemoryEffects<[MemWrite]>]>{
  let summary = "ASD -- Atomic Store Double Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASD -- immediate form, from ASD_coherency_offset27_registerZ_registerT_double
def LVX_AsdImmOp : LVX_Op<"asd_i", [MemoryEffects<[MemWrite]>]>{
  let summary = "ASD -- Atomic Store Double Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALADDB -- register form, from ALADDB_coherency_registerZ_registerT_simple
def LVX_AladdbOp : LVX_Op<"aladdb", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALADDB -- Atomic Load and Add Byte";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALADDB -- immediate form, from ALADDB_coherency_offset27_registerZ_registerT_double
def LVX_AladdbImmOp : LVX_Op<"aladdb_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALADDB -- Atomic Load and Add Byte";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $offset `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALADDH -- register form, from ALADDH_coherency_registerZ_registerT_simple
def LVX_AladdhOp : LVX_Op<"aladdh", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALADDH -- Atomic Load and Add Half Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALADDH -- immediate form, from ALADDH_coherency_offset27_registerZ_registerT_double
def LVX_AladdhImmOp : LVX_Op<"aladdh_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALADDH -- Atomic Load and Add Half Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $offset `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALADDW -- register form, from ALADDW_coherency_registerZ_registerT_simple
def LVX_AladdwOp : LVX_Op<"aladdw", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALADDW -- Atomic Load and Add Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALADDW -- immediate form, from ALADDW_coherency_offset27_registerZ_registerT_double
def LVX_AladdwImmOp : LVX_Op<"aladdw_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALADDW -- Atomic Load and Add Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $offset `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALADDD -- register form, from ALADDD_coherency_registerZ_registerT_simple
def LVX_AladddOp : LVX_Op<"aladdd", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALADDD -- Atomic Load and Add Double Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALADDD -- immediate form, from ALADDD_coherency_offset27_registerZ_registerT_double
def LVX_AladddImmOp : LVX_Op<"aladdd_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALADDD -- Atomic Load and Add Double Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $offset `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALANDB -- register form, from ALANDB_coherency_registerZ_registerT_simple
def LVX_AlandbOp : LVX_Op<"alandb", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALANDB -- Atomic Load and AND Byte";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALANDB -- immediate form, from ALANDB_coherency_offset27_registerZ_registerT_double
def LVX_AlandbImmOp : LVX_Op<"alandb_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALANDB -- Atomic Load and AND Byte";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $offset `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALANDH -- register form, from ALANDH_coherency_registerZ_registerT_simple
def LVX_AlandhOp : LVX_Op<"alandh", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALANDH -- Atomic Load and AND Half Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALANDH -- immediate form, from ALANDH_coherency_offset27_registerZ_registerT_double
def LVX_AlandhImmOp : LVX_Op<"alandh_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALANDH -- Atomic Load and AND Half Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $offset `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALANDW -- register form, from ALANDW_coherency_registerZ_registerT_simple
def LVX_AlandwOp : LVX_Op<"alandw", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALANDW -- Atomic Load and AND Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALANDW -- immediate form, from ALANDW_coherency_offset27_registerZ_registerT_double
def LVX_AlandwImmOp : LVX_Op<"alandw_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALANDW -- Atomic Load and AND Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $offset `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALANDD -- register form, from ALANDD_coherency_registerZ_registerT_simple
def LVX_AlanddOp : LVX_Op<"alandd", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALANDD -- Atomic Load and AND Double Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALANDD -- immediate form, from ALANDD_coherency_offset27_registerZ_registerT_double
def LVX_AlanddImmOp : LVX_Op<"alandd_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALANDD -- Atomic Load and AND Double Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $offset `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALIORB -- register form, from ALIORB_coherency_registerZ_registerT_simple
def LVX_AliorbOp : LVX_Op<"aliorb", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALIORB -- Atomic Load and IOR Byte";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALIORB -- immediate form, from ALIORB_coherency_offset27_registerZ_registerT_double
def LVX_AliorbImmOp : LVX_Op<"aliorb_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALIORB -- Atomic Load and IOR Byte";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $offset `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALIORH -- register form, from ALIORH_coherency_registerZ_registerT_simple
def LVX_AliorhOp : LVX_Op<"aliorh", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALIORH -- Atomic Load and IOR Half Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALIORH -- immediate form, from ALIORH_coherency_offset27_registerZ_registerT_double
def LVX_AliorhImmOp : LVX_Op<"aliorh_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALIORH -- Atomic Load and IOR Half Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $offset `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALIORW -- register form, from ALIORW_coherency_registerZ_registerT_simple
def LVX_AliorwOp : LVX_Op<"aliorw", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALIORW -- Atomic Load and IOR Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALIORW -- immediate form, from ALIORW_coherency_offset27_registerZ_registerT_double
def LVX_AliorwImmOp : LVX_Op<"aliorw_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALIORW -- Atomic Load and IOR Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $offset `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALIORD -- register form, from ALIORD_coherency_registerZ_registerT_simple
def LVX_AliordOp : LVX_Op<"aliord", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALIORD -- Atomic Load and IOR Double Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALIORD -- immediate form, from ALIORD_coherency_offset27_registerZ_registerT_double
def LVX_AliordImmOp : LVX_Op<"aliord_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALIORD -- Atomic Load and IOR Double Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $offset `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALEORB -- register form, from ALEORB_coherency_registerZ_registerT_simple
def LVX_AleorbOp : LVX_Op<"aleorb", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALEORB -- Atomic Load and EOR Byte";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALEORB -- immediate form, from ALEORB_coherency_offset27_registerZ_registerT_double
def LVX_AleorbImmOp : LVX_Op<"aleorb_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALEORB -- Atomic Load and EOR Byte";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $offset `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALEORH -- register form, from ALEORH_coherency_registerZ_registerT_simple
def LVX_AleorhOp : LVX_Op<"aleorh", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALEORH -- Atomic Load and EOR Half Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALEORH -- immediate form, from ALEORH_coherency_offset27_registerZ_registerT_double
def LVX_AleorhImmOp : LVX_Op<"aleorh_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALEORH -- Atomic Load and EOR Half Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $offset `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALEORW -- register form, from ALEORW_coherency_registerZ_registerT_simple
def LVX_AleorwOp : LVX_Op<"aleorw", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALEORW -- Atomic Load and EOR Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALEORW -- immediate form, from ALEORW_coherency_offset27_registerZ_registerT_double
def LVX_AleorwImmOp : LVX_Op<"aleorw_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALEORW -- Atomic Load and EOR Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $offset `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALEORD -- register form, from ALEORD_coherency_registerZ_registerT_simple
def LVX_AleordOp : LVX_Op<"aleord", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALEORD -- Atomic Load and EOR Double Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALEORD -- immediate form, from ALEORD_coherency_offset27_registerZ_registerT_double
def LVX_AleordImmOp : LVX_Op<"aleord_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALEORD -- Atomic Load and EOR Double Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $offset `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALMINB -- register form, from ALMINB_coherency_registerZ_registerT_simple
def LVX_AlminbOp : LVX_Op<"alminb", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALMINB -- Atomic Load and MIN Byte";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALMINB -- immediate form, from ALMINB_coherency_offset27_registerZ_registerT_double
def LVX_AlminbImmOp : LVX_Op<"alminb_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALMINB -- Atomic Load and MIN Byte";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $offset `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALMINH -- register form, from ALMINH_coherency_registerZ_registerT_simple
def LVX_AlminhOp : LVX_Op<"alminh", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALMINH -- Atomic Load and MIN Half Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALMINH -- immediate form, from ALMINH_coherency_offset27_registerZ_registerT_double
def LVX_AlminhImmOp : LVX_Op<"alminh_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALMINH -- Atomic Load and MIN Half Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $offset `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALMINW -- register form, from ALMINW_coherency_registerZ_registerT_simple
def LVX_AlminwOp : LVX_Op<"alminw", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALMINW -- Atomic Load and MIN Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALMINW -- immediate form, from ALMINW_coherency_offset27_registerZ_registerT_double
def LVX_AlminwImmOp : LVX_Op<"alminw_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALMINW -- Atomic Load and MIN Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $offset `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALMIND -- register form, from ALMIND_coherency_registerZ_registerT_simple
def LVX_AlmindOp : LVX_Op<"almind", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALMIND -- Atomic Load and MIN Double Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALMIND -- immediate form, from ALMIND_coherency_offset27_registerZ_registerT_double
def LVX_AlmindImmOp : LVX_Op<"almind_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALMIND -- Atomic Load and MIN Double Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $offset `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALMAXB -- register form, from ALMAXB_coherency_registerZ_registerT_simple
def LVX_AlmaxbOp : LVX_Op<"almaxb", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALMAXB -- Atomic Load and MAX Byte";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALMAXB -- immediate form, from ALMAXB_coherency_offset27_registerZ_registerT_double
def LVX_AlmaxbImmOp : LVX_Op<"almaxb_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALMAXB -- Atomic Load and MAX Byte";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $offset `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALMAXH -- register form, from ALMAXH_coherency_registerZ_registerT_simple
def LVX_AlmaxhOp : LVX_Op<"almaxh", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALMAXH -- Atomic Load and MAX Half Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALMAXH -- immediate form, from ALMAXH_coherency_offset27_registerZ_registerT_double
def LVX_AlmaxhImmOp : LVX_Op<"almaxh_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALMAXH -- Atomic Load and MAX Half Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $offset `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALMAXW -- register form, from ALMAXW_coherency_registerZ_registerT_simple
def LVX_AlmaxwOp : LVX_Op<"almaxw", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALMAXW -- Atomic Load and MAX Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALMAXW -- immediate form, from ALMAXW_coherency_offset27_registerZ_registerT_double
def LVX_AlmaxwImmOp : LVX_Op<"almaxw_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALMAXW -- Atomic Load and MAX Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $offset `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALMAXD -- register form, from ALMAXD_coherency_registerZ_registerT_simple
def LVX_AlmaxdOp : LVX_Op<"almaxd", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALMAXD -- Atomic Load and MAX Double Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALMAXD -- immediate form, from ALMAXD_coherency_offset27_registerZ_registerT_double
def LVX_AlmaxdImmOp : LVX_Op<"almaxd_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALMAXD -- Atomic Load and MAX Double Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $offset `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALMINUB -- register form, from ALMINUB_coherency_registerZ_registerT_simple
def LVX_AlminubOp : LVX_Op<"alminub", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALMINUB -- Atomic Load and MIN Unsigned Byte";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALMINUB -- immediate form, from ALMINUB_coherency_offset27_registerZ_registerT_double
def LVX_AlminubImmOp : LVX_Op<"alminub_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALMINUB -- Atomic Load and MIN Unsigned Byte";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $offset `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALMINUH -- register form, from ALMINUH_coherency_registerZ_registerT_simple
def LVX_AlminuhOp : LVX_Op<"alminuh", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALMINUH -- Atomic Load and MIN Unsigned Half Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALMINUH -- immediate form, from ALMINUH_coherency_offset27_registerZ_registerT_double
def LVX_AlminuhImmOp : LVX_Op<"alminuh_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALMINUH -- Atomic Load and MIN Unsigned Half Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $offset `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALMINUW -- register form, from ALMINUW_coherency_registerZ_registerT_simple
def LVX_AlminuwOp : LVX_Op<"alminuw", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALMINUW -- Atomic Load and MIN Unsigned Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALMINUW -- immediate form, from ALMINUW_coherency_offset27_registerZ_registerT_double
def LVX_AlminuwImmOp : LVX_Op<"alminuw_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALMINUW -- Atomic Load and MIN Unsigned Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $offset `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALMINUD -- register form, from ALMINUD_coherency_registerZ_registerT_simple
def LVX_AlminudOp : LVX_Op<"alminud", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALMINUD -- Atomic Load and MIN Unsigned Double Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALMINUD -- immediate form, from ALMINUD_coherency_offset27_registerZ_registerT_double
def LVX_AlminudImmOp : LVX_Op<"alminud_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALMINUD -- Atomic Load and MIN Unsigned Double Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $offset `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALMAXUB -- register form, from ALMAXUB_coherency_registerZ_registerT_simple
def LVX_AlmaxubOp : LVX_Op<"almaxub", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALMAXUB -- Atomic Load and MAX Unsigned Byte";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALMAXUB -- immediate form, from ALMAXUB_coherency_offset27_registerZ_registerT_double
def LVX_AlmaxubImmOp : LVX_Op<"almaxub_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALMAXUB -- Atomic Load and MAX Unsigned Byte";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $offset `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALMAXUH -- register form, from ALMAXUH_coherency_registerZ_registerT_simple
def LVX_AlmaxuhOp : LVX_Op<"almaxuh", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALMAXUH -- Atomic Load and MAX Unsigned Half Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALMAXUH -- immediate form, from ALMAXUH_coherency_offset27_registerZ_registerT_double
def LVX_AlmaxuhImmOp : LVX_Op<"almaxuh_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALMAXUH -- Atomic Load and MAX Unsigned Half Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $offset `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALMAXUW -- register form, from ALMAXUW_coherency_registerZ_registerT_simple
def LVX_AlmaxuwOp : LVX_Op<"almaxuw", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALMAXUW -- Atomic Load and MAX Unsigned Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALMAXUW -- immediate form, from ALMAXUW_coherency_offset27_registerZ_registerT_double
def LVX_AlmaxuwImmOp : LVX_Op<"almaxuw_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALMAXUW -- Atomic Load and MAX Unsigned Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $offset `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALMAXUD -- register form, from ALMAXUD_coherency_registerZ_registerT_simple
def LVX_AlmaxudOp : LVX_Op<"almaxud", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALMAXUD -- Atomic Load and MAX Unsigned Double Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALMAXUD -- immediate form, from ALMAXUD_coherency_offset27_registerZ_registerT_double
def LVX_AlmaxudImmOp : LVX_Op<"almaxud_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALMAXUD -- Atomic Load and MAX Unsigned Double Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $offset `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALDUSB -- register form, from ALDUSB_coherency_registerZ_registerT_simple
def LVX_AldusbOp : LVX_Op<"aldusb", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALDUSB -- Atomic Load and Decrement Unsigned Saturating Byte";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALDUSB -- immediate form, from ALDUSB_coherency_offset27_registerZ_registerT_double
def LVX_AldusbImmOp : LVX_Op<"aldusb_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALDUSB -- Atomic Load and Decrement Unsigned Saturating Byte";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $offset `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALDUSH -- register form, from ALDUSH_coherency_registerZ_registerT_simple
def LVX_AldushOp : LVX_Op<"aldush", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALDUSH -- Atomic Load and DUS Half Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALDUSH -- immediate form, from ALDUSH_coherency_offset27_registerZ_registerT_double
def LVX_AldushImmOp : LVX_Op<"aldush_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALDUSH -- Atomic Load and DUS Half Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $offset `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALDUSW -- register form, from ALDUSW_coherency_registerZ_registerT_simple
def LVX_AlduswOp : LVX_Op<"aldusw", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALDUSW -- Atomic Load and DUS Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALDUSW -- immediate form, from ALDUSW_coherency_offset27_registerZ_registerT_double
def LVX_AlduswImmOp : LVX_Op<"aldusw_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALDUSW -- Atomic Load and DUS Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $offset `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALDUSD -- register form, from ALDUSD_coherency_registerZ_registerT_simple
def LVX_AldusdOp : LVX_Op<"aldusd", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALDUSD -- Atomic Load and DUS Double Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ALDUSD -- immediate form, from ALDUSD_coherency_offset27_registerZ_registerT_double
def LVX_AldusdImmOp : LVX_Op<"aldusd_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ALDUSD -- Atomic Load and DUS Double Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$base,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`g` $g^)? $base `,` $offset `,` $rhs attr-dict `:` `(` qualified(type($base)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$base, "::mlir::Value":$rhs, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), base, rhs, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASADDB -- register form, from ASADDB_coherency_registerZ_registerT_simple
def LVX_AsaddbOp : LVX_Op<"asaddb", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASADDB -- Atomic Store Add Byte";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASADDB -- immediate form, from ASADDB_coherency_offset27_registerZ_registerT_double
def LVX_AsaddbImmOp : LVX_Op<"asaddb_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASADDB -- Atomic Store Add Byte";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASADDH -- register form, from ASADDH_coherency_registerZ_registerT_simple
def LVX_AsaddhOp : LVX_Op<"asaddh", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASADDH -- Atomic Store Add Half Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASADDH -- immediate form, from ASADDH_coherency_offset27_registerZ_registerT_double
def LVX_AsaddhImmOp : LVX_Op<"asaddh_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASADDH -- Atomic Store Add Half Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASADDW -- register form, from ASADDW_coherency_registerZ_registerT_simple
def LVX_AsaddwOp : LVX_Op<"asaddw", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASADDW -- Atomic Store Add Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASADDW -- immediate form, from ASADDW_coherency_offset27_registerZ_registerT_double
def LVX_AsaddwImmOp : LVX_Op<"asaddw_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASADDW -- Atomic Store Add Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASADDD -- register form, from ASADDD_coherency_registerZ_registerT_simple
def LVX_AsadddOp : LVX_Op<"asaddd", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASADDD -- Atomic Store Add Double Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASADDD -- immediate form, from ASADDD_coherency_offset27_registerZ_registerT_double
def LVX_AsadddImmOp : LVX_Op<"asaddd_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASADDD -- Atomic Store Add Double Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASANDB -- register form, from ASANDB_coherency_registerZ_registerT_simple
def LVX_AsandbOp : LVX_Op<"asandb", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASANDB -- Atomic Store AND Byte";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASANDB -- immediate form, from ASANDB_coherency_offset27_registerZ_registerT_double
def LVX_AsandbImmOp : LVX_Op<"asandb_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASANDB -- Atomic Store AND Byte";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASANDH -- register form, from ASANDH_coherency_registerZ_registerT_simple
def LVX_AsandhOp : LVX_Op<"asandh", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASANDH -- Atomic Store AND Half Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASANDH -- immediate form, from ASANDH_coherency_offset27_registerZ_registerT_double
def LVX_AsandhImmOp : LVX_Op<"asandh_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASANDH -- Atomic Store AND Half Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASANDW -- register form, from ASANDW_coherency_registerZ_registerT_simple
def LVX_AsandwOp : LVX_Op<"asandw", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASANDW -- Atomic Store AND Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASANDW -- immediate form, from ASANDW_coherency_offset27_registerZ_registerT_double
def LVX_AsandwImmOp : LVX_Op<"asandw_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASANDW -- Atomic Store AND Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASANDD -- register form, from ASANDD_coherency_registerZ_registerT_simple
def LVX_AsanddOp : LVX_Op<"asandd", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASANDD -- Atomic Store AND Double Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASANDD -- immediate form, from ASANDD_coherency_offset27_registerZ_registerT_double
def LVX_AsanddImmOp : LVX_Op<"asandd_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASANDD -- Atomic Store AND Double Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASIORB -- register form, from ASIORB_coherency_registerZ_registerT_simple
def LVX_AsiorbOp : LVX_Op<"asiorb", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASIORB -- Atomic Store IOR Byte";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASIORB -- immediate form, from ASIORB_coherency_offset27_registerZ_registerT_double
def LVX_AsiorbImmOp : LVX_Op<"asiorb_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASIORB -- Atomic Store IOR Byte";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASIORH -- register form, from ASIORH_coherency_registerZ_registerT_simple
def LVX_AsiorhOp : LVX_Op<"asiorh", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASIORH -- Atomic Store IOR Half Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASIORH -- immediate form, from ASIORH_coherency_offset27_registerZ_registerT_double
def LVX_AsiorhImmOp : LVX_Op<"asiorh_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASIORH -- Atomic Store IOR Half Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASIORW -- register form, from ASIORW_coherency_registerZ_registerT_simple
def LVX_AsiorwOp : LVX_Op<"asiorw", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASIORW -- Atomic Store IOR Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASIORW -- immediate form, from ASIORW_coherency_offset27_registerZ_registerT_double
def LVX_AsiorwImmOp : LVX_Op<"asiorw_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASIORW -- Atomic Store IOR Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASIORD -- register form, from ASIORD_coherency_registerZ_registerT_simple
def LVX_AsiordOp : LVX_Op<"asiord", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASIORD -- Atomic Store IOR Double Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASIORD -- immediate form, from ASIORD_coherency_offset27_registerZ_registerT_double
def LVX_AsiordImmOp : LVX_Op<"asiord_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASIORD -- Atomic Store IOR Double Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASEORB -- register form, from ASEORB_coherency_registerZ_registerT_simple
def LVX_AseorbOp : LVX_Op<"aseorb", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASEORB -- Atomic Store EOR Byte";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASEORB -- immediate form, from ASEORB_coherency_offset27_registerZ_registerT_double
def LVX_AseorbImmOp : LVX_Op<"aseorb_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASEORB -- Atomic Store EOR Byte";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASEORH -- register form, from ASEORH_coherency_registerZ_registerT_simple
def LVX_AseorhOp : LVX_Op<"aseorh", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASEORH -- Atomic Store EOR Half Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASEORH -- immediate form, from ASEORH_coherency_offset27_registerZ_registerT_double
def LVX_AseorhImmOp : LVX_Op<"aseorh_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASEORH -- Atomic Store EOR Half Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASEORW -- register form, from ASEORW_coherency_registerZ_registerT_simple
def LVX_AseorwOp : LVX_Op<"aseorw", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASEORW -- Atomic Store EOR Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASEORW -- immediate form, from ASEORW_coherency_offset27_registerZ_registerT_double
def LVX_AseorwImmOp : LVX_Op<"aseorw_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASEORW -- Atomic Store EOR Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASEORD -- register form, from ASEORD_coherency_registerZ_registerT_simple
def LVX_AseordOp : LVX_Op<"aseord", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASEORD -- Atomic Store EOR Double Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASEORD -- immediate form, from ASEORD_coherency_offset27_registerZ_registerT_double
def LVX_AseordImmOp : LVX_Op<"aseord_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASEORD -- Atomic Store EOR Double Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASMINB -- register form, from ASMINB_coherency_registerZ_registerT_simple
def LVX_AsminbOp : LVX_Op<"asminb", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASMINB -- Atomic Store MIN Byte";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASMINB -- immediate form, from ASMINB_coherency_offset27_registerZ_registerT_double
def LVX_AsminbImmOp : LVX_Op<"asminb_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASMINB -- Atomic Store MIN Byte";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASMINH -- register form, from ASMINH_coherency_registerZ_registerT_simple
def LVX_AsminhOp : LVX_Op<"asminh", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASMINH -- Atomic Store MIN Half Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASMINH -- immediate form, from ASMINH_coherency_offset27_registerZ_registerT_double
def LVX_AsminhImmOp : LVX_Op<"asminh_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASMINH -- Atomic Store MIN Half Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASMINW -- register form, from ASMINW_coherency_registerZ_registerT_simple
def LVX_AsminwOp : LVX_Op<"asminw", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASMINW -- Atomic Store MIN Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASMINW -- immediate form, from ASMINW_coherency_offset27_registerZ_registerT_double
def LVX_AsminwImmOp : LVX_Op<"asminw_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASMINW -- Atomic Store MIN Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASMIND -- register form, from ASMIND_coherency_registerZ_registerT_simple
def LVX_AsmindOp : LVX_Op<"asmind", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASMIND -- Atomic Store MIN Double Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASMIND -- immediate form, from ASMIND_coherency_offset27_registerZ_registerT_double
def LVX_AsmindImmOp : LVX_Op<"asmind_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASMIND -- Atomic Store MIN Double Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASMAXB -- register form, from ASMAXB_coherency_registerZ_registerT_simple
def LVX_AsmaxbOp : LVX_Op<"asmaxb", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASMAXB -- Atomic Store MAX Byte";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASMAXB -- immediate form, from ASMAXB_coherency_offset27_registerZ_registerT_double
def LVX_AsmaxbImmOp : LVX_Op<"asmaxb_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASMAXB -- Atomic Store MAX Byte";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASMAXH -- register form, from ASMAXH_coherency_registerZ_registerT_simple
def LVX_AsmaxhOp : LVX_Op<"asmaxh", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASMAXH -- Atomic Store MAX Half Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASMAXH -- immediate form, from ASMAXH_coherency_offset27_registerZ_registerT_double
def LVX_AsmaxhImmOp : LVX_Op<"asmaxh_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASMAXH -- Atomic Store MAX Half Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASMAXW -- register form, from ASMAXW_coherency_registerZ_registerT_simple
def LVX_AsmaxwOp : LVX_Op<"asmaxw", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASMAXW -- Atomic Store MAX Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASMAXW -- immediate form, from ASMAXW_coherency_offset27_registerZ_registerT_double
def LVX_AsmaxwImmOp : LVX_Op<"asmaxw_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASMAXW -- Atomic Store MAX Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASMAXD -- register form, from ASMAXD_coherency_registerZ_registerT_simple
def LVX_AsmaxdOp : LVX_Op<"asmaxd", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASMAXD -- Atomic Store MAX Double Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASMAXD -- immediate form, from ASMAXD_coherency_offset27_registerZ_registerT_double
def LVX_AsmaxdImmOp : LVX_Op<"asmaxd_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASMAXD -- Atomic Store MAX Double Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASMINUB -- register form, from ASMINUB_coherency_registerZ_registerT_simple
def LVX_AsminubOp : LVX_Op<"asminub", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASMINUB -- Atomic Store MIN Unsigned Byte";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASMINUB -- immediate form, from ASMINUB_coherency_offset27_registerZ_registerT_double
def LVX_AsminubImmOp : LVX_Op<"asminub_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASMINUB -- Atomic Store MIN Unsigned Byte";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASMINUH -- register form, from ASMINUH_coherency_registerZ_registerT_simple
def LVX_AsminuhOp : LVX_Op<"asminuh", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASMINUH -- Atomic Store MIN Unsigned Half Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASMINUH -- immediate form, from ASMINUH_coherency_offset27_registerZ_registerT_double
def LVX_AsminuhImmOp : LVX_Op<"asminuh_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASMINUH -- Atomic Store MIN Unsigned Half Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASMINUW -- register form, from ASMINUW_coherency_registerZ_registerT_simple
def LVX_AsminuwOp : LVX_Op<"asminuw", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASMINUW -- Atomic Store MIN Unsigned Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASMINUW -- immediate form, from ASMINUW_coherency_offset27_registerZ_registerT_double
def LVX_AsminuwImmOp : LVX_Op<"asminuw_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASMINUW -- Atomic Store MIN Unsigned Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASMINUD -- register form, from ASMINUD_coherency_registerZ_registerT_simple
def LVX_AsminudOp : LVX_Op<"asminud", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASMINUD -- Atomic Store MIN Unsigned Double Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASMINUD -- immediate form, from ASMINUD_coherency_offset27_registerZ_registerT_double
def LVX_AsminudImmOp : LVX_Op<"asminud_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASMINUD -- Atomic Store MIN Unsigned Double Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASMAXUB -- register form, from ASMAXUB_coherency_registerZ_registerT_simple
def LVX_AsmaxubOp : LVX_Op<"asmaxub", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASMAXUB -- Atomic Store MAX Unsigned Byte";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASMAXUB -- immediate form, from ASMAXUB_coherency_offset27_registerZ_registerT_double
def LVX_AsmaxubImmOp : LVX_Op<"asmaxub_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASMAXUB -- Atomic Store MAX Unsigned Byte";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASMAXUH -- register form, from ASMAXUH_coherency_registerZ_registerT_simple
def LVX_AsmaxuhOp : LVX_Op<"asmaxuh", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASMAXUH -- Atomic Store MAX Unsigned Half Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASMAXUH -- immediate form, from ASMAXUH_coherency_offset27_registerZ_registerT_double
def LVX_AsmaxuhImmOp : LVX_Op<"asmaxuh_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASMAXUH -- Atomic Store MAX Unsigned Half Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASMAXUW -- register form, from ASMAXUW_coherency_registerZ_registerT_simple
def LVX_AsmaxuwOp : LVX_Op<"asmaxuw", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASMAXUW -- Atomic Store MAX Unsigned Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASMAXUW -- immediate form, from ASMAXUW_coherency_offset27_registerZ_registerT_double
def LVX_AsmaxuwImmOp : LVX_Op<"asmaxuw_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASMAXUW -- Atomic Store MAX Unsigned Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASMAXUD -- register form, from ASMAXUD_coherency_registerZ_registerT_simple
def LVX_AsmaxudOp : LVX_Op<"asmaxud", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASMAXUD -- Atomic Store MAX Unsigned Double Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASMAXUD -- immediate form, from ASMAXUD_coherency_offset27_registerZ_registerT_double
def LVX_AsmaxudImmOp : LVX_Op<"asmaxud_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASMAXUD -- Atomic Store MAX Unsigned Double Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASDUSB -- register form, from ASDUSB_coherency_registerZ_registerT_simple
def LVX_AsdusbOp : LVX_Op<"asdusb", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASDUSB -- Atomic Store Decrement Unsigned Saturating Byte";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASDUSB -- immediate form, from ASDUSB_coherency_offset27_registerZ_registerT_double
def LVX_AsdusbImmOp : LVX_Op<"asdusb_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASDUSB -- Atomic Store Decrement Unsigned Saturating Byte";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASDUSH -- register form, from ASDUSH_coherency_registerZ_registerT_simple
def LVX_AsdushOp : LVX_Op<"asdush", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASDUSH -- Atomic Store DUS Half Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASDUSH -- immediate form, from ASDUSH_coherency_offset27_registerZ_registerT_double
def LVX_AsdushImmOp : LVX_Op<"asdush_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASDUSH -- Atomic Store DUS Half Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASDUSW -- register form, from ASDUSW_coherency_registerZ_registerT_simple
def LVX_AsduswOp : LVX_Op<"asdusw", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASDUSW -- Atomic Store DUS Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASDUSW -- immediate form, from ASDUSW_coherency_offset27_registerZ_registerT_double
def LVX_AsduswImmOp : LVX_Op<"asdusw_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASDUSW -- Atomic Store DUS Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASDUSD -- register form, from ASDUSD_coherency_registerZ_registerT_simple
def LVX_AsdusdOp : LVX_Op<"asdusd", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASDUSD -- Atomic Store DUS Double Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:ASDUSD -- immediate form, from ASDUSD_coherency_offset27_registerZ_registerT_double
def LVX_AsdusdImmOp : LVX_Op<"asdusd_i", [MemoryEffects<[MemRead, MemWrite]>]>{
  let summary = "ASDUSD -- Atomic Store DUS Double Word";
  let arguments = (ins UnitAttr:$g,
                       LVX_RegType:$value,
                       LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "(`g` $g^)? $value `,` $base `,` $offset attr-dict `:` `(` qualified(type($value)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$value, "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, ::mlir::UnitAttr(), value, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:DTOUCHL -- register form, from DTOUCHL_registerY_registerZ_simple
def LVX_DtouchlRegOp : LVX_Op<"dtouchl_r">{
  let summary = "DTOUCHL -- Data Cache Touch Line";
  let arguments = (ins LVX_RegType:$base,
                       LVX_RegType:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "$base `,` $offset attr-dict `:` `(` qualified(type($base)) `,` qualified(type($offset)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$base, "::mlir::Value":$offset), [{
      build($_builder, $_state, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:DTOUCHL -- immediate form, from DTOUCHL_signed10_registerZ_simple
def LVX_DtouchlOp : LVX_Op<"dtouchl">{
  let summary = "DTOUCHL -- Data Cache Touch Line";
  let arguments = (ins LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "$base `,` $offset attr-dict `:` `(` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:DINVALL -- register form, from DINVALL_registerY_registerZ_simple
def LVX_DinvallRegOp : LVX_Op<"dinvall_r">{
  let summary = "DINVALL -- Data Cache Invalidate Line";
  let arguments = (ins LVX_RegType:$base,
                       LVX_RegType:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "$base `,` $offset attr-dict `:` `(` qualified(type($base)) `,` qualified(type($offset)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$base, "::mlir::Value":$offset), [{
      build($_builder, $_state, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:DINVALL -- immediate form, from DINVALL_signed10_registerZ_simple
def LVX_DinvallOp : LVX_Op<"dinvall">{
  let summary = "DINVALL -- Data Cache Invalidate Line";
  let arguments = (ins LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "$base `,` $offset attr-dict `:` `(` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:DINVALSW -- register form, from DINVALSW_cachelev_registerY_registerZ_simple
def LVX_DinvalswOp : LVX_Op<"dinvalsw">{
  let summary = "DINVALSW -- Data Cache Invalidate Line by Set and Way";
  let arguments = (ins LVX_CacheLevAttr:$cachelev,
                       LVX_RegType:$test,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "$cachelev $test `,` $base attr-dict `:` `(` qualified(type($test)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::lvx::CacheLev":$cachelev, "::mlir::Value":$test, "::mlir::Value":$base), [{
      build($_builder, $_state, ::mlir::lvx::CacheLevAttr::get($_builder.getContext(), cachelev), test, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:DPURGEL -- register form, from DPURGEL_registerY_registerZ_simple
def LVX_DpurgelRegOp : LVX_Op<"dpurgel_r">{
  let summary = "DPURGEL -- Data Cache Purge Line";
  let arguments = (ins LVX_RegType:$base,
                       LVX_RegType:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "$base `,` $offset attr-dict `:` `(` qualified(type($base)) `,` qualified(type($offset)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$base, "::mlir::Value":$offset), [{
      build($_builder, $_state, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:DPURGEL -- immediate form, from DPURGEL_signed10_registerZ_simple
def LVX_DpurgelOp : LVX_Op<"dpurgel">{
  let summary = "DPURGEL -- Data Cache Purge Line";
  let arguments = (ins LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "$base `,` $offset attr-dict `:` `(` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:DPURGESW -- register form, from DPURGESW_cachelev_registerY_registerZ_simple
def LVX_DpurgeswOp : LVX_Op<"dpurgesw">{
  let summary = "DPURGESW -- Data Cache Purge Line by Set and Way";
  let arguments = (ins LVX_CacheLevAttr:$cachelev,
                       LVX_RegType:$test,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "$cachelev $test `,` $base attr-dict `:` `(` qualified(type($test)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::lvx::CacheLev":$cachelev, "::mlir::Value":$test, "::mlir::Value":$base), [{
      build($_builder, $_state, ::mlir::lvx::CacheLevAttr::get($_builder.getContext(), cachelev), test, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:DFLUSHL -- register form, from DFLUSHL_registerY_registerZ_simple
def LVX_DflushlRegOp : LVX_Op<"dflushl_r">{
  let summary = "DFLUSHL -- Data Cache Flush Line";
  let arguments = (ins LVX_RegType:$base,
                       LVX_RegType:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "$base `,` $offset attr-dict `:` `(` qualified(type($base)) `,` qualified(type($offset)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$base, "::mlir::Value":$offset), [{
      build($_builder, $_state, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:DFLUSHL -- immediate form, from DFLUSHL_signed10_registerZ_simple
def LVX_DflushlOp : LVX_Op<"dflushl">{
  let summary = "DFLUSHL -- Data Cache Flush Line";
  let arguments = (ins LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "$base `,` $offset attr-dict `:` `(` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:DFLUSHSW -- register form, from DFLUSHSW_cachelev_registerY_registerZ_simple
def LVX_DflushswOp : LVX_Op<"dflushsw">{
  let summary = "DFLUSHSW -- Data Cache Flush Line by Set and Way";
  let arguments = (ins LVX_CacheLevAttr:$cachelev,
                       LVX_RegType:$test,
                       LVX_RegType:$base,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "$cachelev $test `,` $base attr-dict `:` `(` qualified(type($test)) `,` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::lvx::CacheLev":$cachelev, "::mlir::Value":$test, "::mlir::Value":$base), [{
      build($_builder, $_state, ::mlir::lvx::CacheLevAttr::get($_builder.getContext(), cachelev), test, base, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:I1INVALS -- register form, from I1INVALS_registerY_registerZ_simple
def LVX_I1invalsRegOp : LVX_Op<"i1invals_r">{
  let summary = "I1INVALS -- Instruction Cache 1 Invalidate Set";
  let arguments = (ins LVX_RegType:$base,
                       LVX_RegType:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "$base `,` $offset attr-dict `:` `(` qualified(type($base)) `,` qualified(type($offset)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$base, "::mlir::Value":$offset), [{
      build($_builder, $_state, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:I1INVALS -- immediate form, from I1INVALS_signed10_registerZ_simple
def LVX_I1invalsOp : LVX_Op<"i1invals">{
  let summary = "I1INVALS -- Instruction Cache 1 Invalidate Set";
  let arguments = (ins LVX_RegType:$base,
                       TypedAttrInterface:$offset,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "$base `,` $offset attr-dict `:` `(` qualified(type($base)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::Value":$base, "::mlir::TypedAttr":$offset), [{
      build($_builder, $_state, base, offset, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:D1INVAL -- register form, from D1INVAL_simple
def LVX_D1invalOp : LVX_Op<"d1inval">{
  let summary = "D1INVAL -- Data Cache 1 Invalidate";
  let arguments = (ins OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "attr-dict";
}

// LSU:I1INVAL -- register form, from I1INVAL_simple
def LVX_I1invalOp : LVX_Op<"i1inval">{
  let summary = "I1INVAL -- Instruction Cache 1 Invalidate";
  let arguments = (ins OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "attr-dict";
}

// LSU:FENCE -- register form, from FENCE_accesses_simple
def LVX_FenceOp : LVX_Op<"fence">{
  let summary = "FENCE -- Memory Fence";
  let arguments = (ins OptionalAttr<LVX_AccessesAttr>:$accesses,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "($accesses^)? attr-dict";
  let builders = [
    OpBuilder<(ins CArg<"::mlir::lvx::AccessesAttr", "{}">:$accesses), [{
      build($_builder, $_state, accesses, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:NOP -- register form, from NOP_simple
def LVX_NopOp : LVX_Op<"nop", [Pure]>{
  let summary = "NOP -- No Operation";
  let arguments = (ins OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "attr-dict";
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

// ALU:STSUDP -- register form, from STSUDP_registerM_registerP_registerO_simple
def LVX_StsudpOp : LVX_Op<"stsudp", [Pure]>{
  let summary = "STSUDP -- Subtract, Test and Shift Unsigned Double Word Pair";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
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

// ALU:STSUWQ -- register form, from STSUWQ_registerM_registerP_registerO_simple
def LVX_StsuwqOp : LVX_Op<"stsuwq", [Pure]>{
  let summary = "STSUWQ -- Subtract, Test and Shift Unsigned Word Quadruple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:STSUHO -- register form, from STSUHO_registerM_registerP_registerO_simple
def LVX_StsuhoOp : LVX_Op<"stsuho", [Pure]>{
  let summary = "STSUHO -- Subtract, Test and Shift Unsigned Half Word Octuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ABDDP -- register form, from ABDDP_registerM_registerP_registerO_simple
def LVX_AbddpOp : LVX_Op<"abddp", [Pure]>{
  let summary = "ABDDP -- Absolute Difference Double Word Pair";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ABDDP -- immediate form, from ABDDP_registerM_registerP_upper27_lower5_splat32_double
def LVX_AbddpImmOp : LVX_Op<"abddp_i", [Pure]>{
  let summary = "ABDDP -- Absolute Difference Double Word Pair";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "(`sx` $sx^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ABDWQ -- register form, from ABDWQ_registerM_registerP_registerO_simple
def LVX_AbdwqOp : LVX_Op<"abdwq", [Pure]>{
  let summary = "ABDWQ -- Absolute Difference Word Quadruple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ABDWQ -- immediate form, from ABDWQ_registerM_registerP_upper27_lower5_splat32_double
def LVX_AbdwqImmOp : LVX_Op<"abdwq_i", [Pure]>{
  let summary = "ABDWQ -- Absolute Difference Word Quadruple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ABDHO -- register form, from ABDHO_registerM_registerP_registerO_simple
def LVX_AbdhoOp : LVX_Op<"abdho", [Pure]>{
  let summary = "ABDHO -- Absolute Difference Half Word Octuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ABDHO -- immediate form, from ABDHO_registerM_registerP_upper27_lower5_splat32_double
def LVX_AbdhoImmOp : LVX_Op<"abdho_i", [Pure]>{
  let summary = "ABDHO -- Absolute Difference Half Word Octuple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ABDBX -- register form, from ABDBX_registerM_registerP_registerO_simple
def LVX_AbdbxOp : LVX_Op<"abdbx", [Pure]>{
  let summary = "ABDBX -- Absolute Difference Byte Hexadecuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ABDBX -- immediate form, from ABDBX_registerM_registerP_upper27_lower5_splat32_double
def LVX_AbdbxImmOp : LVX_Op<"abdbx_i", [Pure]>{
  let summary = "ABDBX -- Absolute Difference Byte Hexadecuple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ABDSDP -- register form, from ABDSDP_registerM_registerP_registerO_simple
def LVX_AbdsdpOp : LVX_Op<"abdsdp", [Pure]>{
  let summary = "ABDSDP -- Absolute Difference Saturated Double Word Pair";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ABDSDP -- immediate form, from ABDSDP_registerM_registerP_upper27_lower5_splat32_double
def LVX_AbdsdpImmOp : LVX_Op<"abdsdp_i", [Pure]>{
  let summary = "ABDSDP -- Absolute Difference Saturated Double Word Pair";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "(`sx` $sx^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ABDSWQ -- register form, from ABDSWQ_registerM_registerP_registerO_simple
def LVX_AbdswqOp : LVX_Op<"abdswq", [Pure]>{
  let summary = "ABDSWQ -- Absolute Difference Saturated Word Quadruple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ABDSWQ -- immediate form, from ABDSWQ_registerM_registerP_upper27_lower5_splat32_double
def LVX_AbdswqImmOp : LVX_Op<"abdswq_i", [Pure]>{
  let summary = "ABDSWQ -- Absolute Difference Saturated Word Quadruple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ABDSHO -- register form, from ABDSHO_registerM_registerP_registerO_simple
def LVX_AbdshoOp : LVX_Op<"abdsho", [Pure]>{
  let summary = "ABDSHO -- Absolute Difference Saturated Half Word Octuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ABDSHO -- immediate form, from ABDSHO_registerM_registerP_upper27_lower5_splat32_double
def LVX_AbdshoImmOp : LVX_Op<"abdsho_i", [Pure]>{
  let summary = "ABDSHO -- Absolute Difference Saturated Half Word Octuple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ABDSBX -- register form, from ABDSBX_registerM_registerP_registerO_simple
def LVX_AbdsbxOp : LVX_Op<"abdsbx", [Pure]>{
  let summary = "ABDSBX -- Absolute Difference Saturated Byte Hexadecuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ABDSBX -- immediate form, from ABDSBX_registerM_registerP_upper27_lower5_splat32_double
def LVX_AbdsbxImmOp : LVX_Op<"abdsbx_i", [Pure]>{
  let summary = "ABDSBX -- Absolute Difference Saturated Byte Hexadecuple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ABDUDP -- register form, from ABDUDP_registerM_registerP_registerO_simple
def LVX_AbdudpOp : LVX_Op<"abdudp", [Pure]>{
  let summary = "ABDUDP -- Absolute Difference Unsigned Double Word Pair";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ABDUDP -- immediate form, from ABDUDP_registerM_registerP_upper27_lower5_splat32_double
def LVX_AbdudpImmOp : LVX_Op<"abdudp_i", [Pure]>{
  let summary = "ABDUDP -- Absolute Difference Unsigned Double Word Pair";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "(`sx` $sx^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ABDUWQ -- register form, from ABDUWQ_registerM_registerP_registerO_simple
def LVX_AbduwqOp : LVX_Op<"abduwq", [Pure]>{
  let summary = "ABDUWQ -- Absolute Difference Unsigned Word Quadruple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ABDUWQ -- immediate form, from ABDUWQ_registerM_registerP_upper27_lower5_splat32_double
def LVX_AbduwqImmOp : LVX_Op<"abduwq_i", [Pure]>{
  let summary = "ABDUWQ -- Absolute Difference Unsigned Word Quadruple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ABDUHO -- register form, from ABDUHO_registerM_registerP_registerO_simple
def LVX_AbduhoOp : LVX_Op<"abduho", [Pure]>{
  let summary = "ABDUHO -- Absolute Difference Unsigned Half Word Octuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ABDUHO -- immediate form, from ABDUHO_registerM_registerP_upper27_lower5_splat32_double
def LVX_AbduhoImmOp : LVX_Op<"abduho_i", [Pure]>{
  let summary = "ABDUHO -- Absolute Difference Unsigned Half Word Octuple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ABDUBX -- register form, from ABDUBX_registerM_registerP_registerO_simple
def LVX_AbdubxOp : LVX_Op<"abdubx", [Pure]>{
  let summary = "ABDUBX -- Absolute Difference Unsigned Byte Hexadecuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ABDUBX -- immediate form, from ABDUBX_registerM_registerP_upper27_lower5_splat32_double
def LVX_AbdubxImmOp : LVX_Op<"abdubx_i", [Pure]>{
  let summary = "ABDUBX -- Absolute Difference Unsigned Byte Hexadecuple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDQ -- register form, from ADDQ_registerM_registerP_registerO_simple
def LVX_AddqOp : LVX_Op<"addq", [Pure]>{
  let summary = "ADDQ -- Add Quadruple Word to Quadruple Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
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
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
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
  let assemblyFormat = "$operand `,` $signed10 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
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
  let assemblyFormat = "(`sx` $sx^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDDP -- register form, from ADDDP_registerM_registerP_registerO_simple
def LVX_AdddpOp : LVX_Op<"adddp", [Pure]>{
  let summary = "ADDDP -- Add Double Word Pair";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDDP -- immediate form, from ADDDP_registerM_registerP_upper27_lower5_splat32_double
def LVX_AdddpImmOp : LVX_Op<"adddp_i", [Pure]>{
  let summary = "ADDDP -- Add Double Word Pair";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDWQ -- register form, from ADDWQ_registerM_registerP_registerO_simple
def LVX_AddwqOp : LVX_Op<"addwq", [Pure]>{
  let summary = "ADDWQ -- Add Word Quadruple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDWQ -- immediate form, from ADDWQ_registerM_registerP_upper27_lower5_splat32_double
def LVX_AddwqImmOp : LVX_Op<"addwq_i", [Pure]>{
  let summary = "ADDWQ -- Add Word Quadruple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDHO -- register form, from ADDHO_registerM_registerP_registerO_simple
def LVX_AddhoOp : LVX_Op<"addho", [Pure]>{
  let summary = "ADDHO -- Add Half Word Octuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDHO -- immediate form, from ADDHO_registerM_registerP_upper27_lower5_splat32_double
def LVX_AddhoImmOp : LVX_Op<"addho_i", [Pure]>{
  let summary = "ADDHO -- Add Half Word Octuple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDBX -- register form, from ADDBX_registerM_registerP_registerO_simple
def LVX_AddbxOp : LVX_Op<"addbx", [Pure]>{
  let summary = "ADDBX -- Add Byte Hexadecuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDBX -- immediate form, from ADDBX_registerM_registerP_upper27_lower5_splat32_double
def LVX_AddbxImmOp : LVX_Op<"addbx_i", [Pure]>{
  let summary = "ADDBX -- Add Byte Hexadecuple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDSDP -- register form, from ADDSDP_registerM_registerP_registerO_simple
def LVX_AddsdpOp : LVX_Op<"addsdp", [Pure]>{
  let summary = "ADDSDP -- Add Saturated Double Word Pair";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDSDP -- immediate form, from ADDSDP_registerM_registerP_upper27_lower5_splat32_double
def LVX_AddsdpImmOp : LVX_Op<"addsdp_i", [Pure]>{
  let summary = "ADDSDP -- Add Saturated Double Word Pair";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "(`sx` $sx^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDSWQ -- register form, from ADDSWQ_registerM_registerP_registerO_simple
def LVX_AddswqOp : LVX_Op<"addswq", [Pure]>{
  let summary = "ADDSWQ -- Add Saturated Word Quadruple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDSWQ -- immediate form, from ADDSWQ_registerM_registerP_upper27_lower5_splat32_double
def LVX_AddswqImmOp : LVX_Op<"addswq_i", [Pure]>{
  let summary = "ADDSWQ -- Add Saturated Word Quadruple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDSHO -- register form, from ADDSHO_registerM_registerP_registerO_simple
def LVX_AddshoOp : LVX_Op<"addsho", [Pure]>{
  let summary = "ADDSHO -- Add Saturated Half Word Octuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDSHO -- immediate form, from ADDSHO_registerM_registerP_upper27_lower5_splat32_double
def LVX_AddshoImmOp : LVX_Op<"addsho_i", [Pure]>{
  let summary = "ADDSHO -- Add Saturated Half Word Octuple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDSBX -- register form, from ADDSBX_registerM_registerP_registerO_simple
def LVX_AddsbxOp : LVX_Op<"addsbx", [Pure]>{
  let summary = "ADDSBX -- Add Saturated Byte Hexadecuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDSBX -- immediate form, from ADDSBX_registerM_registerP_upper27_lower5_splat32_double
def LVX_AddsbxImmOp : LVX_Op<"addsbx_i", [Pure]>{
  let summary = "ADDSBX -- Add Saturated Byte Hexadecuple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDUSDP -- register form, from ADDUSDP_registerM_registerP_registerO_simple
def LVX_AddusdpOp : LVX_Op<"addusdp", [Pure]>{
  let summary = "ADDUSDP -- Add Unsigned Saturated Double Word Pair";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDUSDP -- immediate form, from ADDUSDP_registerM_registerP_upper27_lower5_splat32_double
def LVX_AddusdpImmOp : LVX_Op<"addusdp_i", [Pure]>{
  let summary = "ADDUSDP -- Add Unsigned Saturated Double Word Pair";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "(`sx` $sx^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDUSWQ -- register form, from ADDUSWQ_registerM_registerP_registerO_simple
def LVX_AdduswqOp : LVX_Op<"adduswq", [Pure]>{
  let summary = "ADDUSWQ -- Add Unsigned Saturated Word Quadruple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDUSWQ -- immediate form, from ADDUSWQ_registerM_registerP_upper27_lower5_splat32_double
def LVX_AdduswqImmOp : LVX_Op<"adduswq_i", [Pure]>{
  let summary = "ADDUSWQ -- Add Unsigned Saturated Word Quadruple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDUSHO -- register form, from ADDUSHO_registerM_registerP_registerO_simple
def LVX_AddushoOp : LVX_Op<"addusho", [Pure]>{
  let summary = "ADDUSHO -- Add Unsigned Saturated Half Word Octuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDUSHO -- immediate form, from ADDUSHO_registerM_registerP_upper27_lower5_splat32_double
def LVX_AddushoImmOp : LVX_Op<"addusho_i", [Pure]>{
  let summary = "ADDUSHO -- Add Unsigned Saturated Half Word Octuple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDUSBX -- register form, from ADDUSBX_registerM_registerP_registerO_simple
def LVX_AddusbxOp : LVX_Op<"addusbx", [Pure]>{
  let summary = "ADDUSBX -- Add Unsigned Saturated Byte Hexadecuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDUSBX -- immediate form, from ADDUSBX_registerM_registerP_upper27_lower5_splat32_double
def LVX_AddusbxImmOp : LVX_Op<"addusbx_i", [Pure]>{
  let summary = "ADDUSBX -- Add Unsigned Saturated Byte Hexadecuple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBFQ -- register form, from SBFQ_registerM_registerP_registerO_simple
def LVX_SbfqOp : LVX_Op<"sbfq", [Pure]>{
  let summary = "SBFQ -- Subtract From Quadruple Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
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
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
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
  let assemblyFormat = "$operand `,` $signed10 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$signed10), [{
      build($_builder, $_state, resultType, operand, signed10, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBFDP -- register form, from SBFDP_registerM_registerP_registerO_simple
def LVX_SbfdpOp : LVX_Op<"sbfdp", [Pure]>{
  let summary = "SBFDP -- Subtract From Double Word Pair";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBFDP -- immediate form, from SBFDP_registerM_registerP_upper27_lower5_splat32_double
def LVX_SbfdpImmOp : LVX_Op<"sbfdp_i", [Pure]>{
  let summary = "SBFDP -- Subtract From Double Word Pair";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "(`sx` $sx^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBFWQ -- register form, from SBFWQ_registerM_registerP_registerO_simple
def LVX_SbfwqOp : LVX_Op<"sbfwq", [Pure]>{
  let summary = "SBFWQ -- Subtract From Word Quadruple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBFWQ -- immediate form, from SBFWQ_registerM_registerP_upper27_lower5_splat32_double
def LVX_SbfwqImmOp : LVX_Op<"sbfwq_i", [Pure]>{
  let summary = "SBFWQ -- Subtract From Word Quadruple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBFHO -- register form, from SBFHO_registerM_registerP_registerO_simple
def LVX_SbfhoOp : LVX_Op<"sbfho", [Pure]>{
  let summary = "SBFHO -- Subtract From Half Word Octuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBFHO -- immediate form, from SBFHO_registerM_registerP_upper27_lower5_splat32_double
def LVX_SbfhoImmOp : LVX_Op<"sbfho_i", [Pure]>{
  let summary = "SBFHO -- Subtract From Half Word Octuple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBFBX -- register form, from SBFBX_registerM_registerP_registerO_simple
def LVX_SbfbxOp : LVX_Op<"sbfbx", [Pure]>{
  let summary = "SBFBX -- Subtract From Byte Hexadecuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBFBX -- immediate form, from SBFBX_registerM_registerP_upper27_lower5_splat32_double
def LVX_SbfbxImmOp : LVX_Op<"sbfbx_i", [Pure]>{
  let summary = "SBFBX -- Subtract From Byte Hexadecuple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBFSDP -- register form, from SBFSDP_registerM_registerP_registerO_simple
def LVX_SbfsdpOp : LVX_Op<"sbfsdp", [Pure]>{
  let summary = "SBFSDP -- Subtract Saturated Double Word Pair";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBFSDP -- immediate form, from SBFSDP_registerM_registerP_upper27_lower5_splat32_double
def LVX_SbfsdpImmOp : LVX_Op<"sbfsdp_i", [Pure]>{
  let summary = "SBFSDP -- Subtract Saturated Double Word Pair";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "(`sx` $sx^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBFSWQ -- register form, from SBFSWQ_registerM_registerP_registerO_simple
def LVX_SbfswqOp : LVX_Op<"sbfswq", [Pure]>{
  let summary = "SBFSWQ -- Subtract Saturated Word Quadruple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBFSWQ -- immediate form, from SBFSWQ_registerM_registerP_upper27_lower5_splat32_double
def LVX_SbfswqImmOp : LVX_Op<"sbfswq_i", [Pure]>{
  let summary = "SBFSWQ -- Subtract Saturated Word Quadruple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBFSHO -- register form, from SBFSHO_registerM_registerP_registerO_simple
def LVX_SbfshoOp : LVX_Op<"sbfsho", [Pure]>{
  let summary = "SBFSHO -- Subtract Saturated Half Word Octuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBFSHO -- immediate form, from SBFSHO_registerM_registerP_upper27_lower5_splat32_double
def LVX_SbfshoImmOp : LVX_Op<"sbfsho_i", [Pure]>{
  let summary = "SBFSHO -- Subtract Saturated Half Word Octuple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBFSBX -- register form, from SBFSBX_registerM_registerP_registerO_simple
def LVX_SbfsbxOp : LVX_Op<"sbfsbx", [Pure]>{
  let summary = "SBFSBX -- Subtract Saturated Byte Hexadecuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBFSBX -- immediate form, from SBFSBX_registerM_registerP_upper27_lower5_splat32_double
def LVX_SbfsbxImmOp : LVX_Op<"sbfsbx_i", [Pure]>{
  let summary = "SBFSBX -- Subtract Saturated Byte Hexadecuple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBFUSDP -- register form, from SBFUSDP_registerM_registerP_registerO_simple
def LVX_SbfusdpOp : LVX_Op<"sbfusdp", [Pure]>{
  let summary = "SBFUSDP -- Subtract Unsigned Saturated Double Word Pair";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBFUSDP -- immediate form, from SBFUSDP_registerM_registerP_upper27_lower5_splat32_double
def LVX_SbfusdpImmOp : LVX_Op<"sbfusdp_i", [Pure]>{
  let summary = "SBFUSDP -- Subtract Unsigned Saturated Double Word Pair";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "(`sx` $sx^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBFUSWQ -- register form, from SBFUSWQ_registerM_registerP_registerO_simple
def LVX_SbfuswqOp : LVX_Op<"sbfuswq", [Pure]>{
  let summary = "SBFUSWQ -- Subtract Unsigned Saturated Word Quadruple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBFUSWQ -- immediate form, from SBFUSWQ_registerM_registerP_upper27_lower5_splat32_double
def LVX_SbfuswqImmOp : LVX_Op<"sbfuswq_i", [Pure]>{
  let summary = "SBFUSWQ -- Subtract Unsigned Saturated Word Quadruple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBFUSHO -- register form, from SBFUSHO_registerM_registerP_registerO_simple
def LVX_SbfushoOp : LVX_Op<"sbfusho", [Pure]>{
  let summary = "SBFUSHO -- Subtract Unsigned Saturated Half Word Octuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBFUSHO -- immediate form, from SBFUSHO_registerM_registerP_upper27_lower5_splat32_double
def LVX_SbfushoImmOp : LVX_Op<"sbfusho_i", [Pure]>{
  let summary = "SBFUSHO -- Subtract Unsigned Saturated Half Word Octuple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBFUSBX -- register form, from SBFUSBX_registerM_registerP_registerO_simple
def LVX_SbfusbxOp : LVX_Op<"sbfusbx", [Pure]>{
  let summary = "SBFUSBX -- Subtract Unsigned Saturated Byte Hexadecuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBFUSBX -- immediate form, from SBFUSBX_registerM_registerP_upper27_lower5_splat32_double
def LVX_SbfusbxImmOp : LVX_Op<"sbfusbx_i", [Pure]>{
  let summary = "SBFUSBX -- Subtract Unsigned Saturated Byte Hexadecuple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "$operand `,` $signed10 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$signed10), [{
      build($_builder, $_state, resultType, operand, signed10, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MINDP -- register form, from MINDP_registerM_registerP_registerO_simple
def LVX_MindpOp : LVX_Op<"mindp", [Pure]>{
  let summary = "MINDP -- Minimum Double Word Pair";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MINDP -- immediate form, from MINDP_registerM_registerP_upper27_lower5_splat32_double
def LVX_MindpImmOp : LVX_Op<"mindp_i", [Pure]>{
  let summary = "MINDP -- Minimum Double Word Pair";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "(`sx` $sx^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MINWQ -- register form, from MINWQ_registerM_registerP_registerO_simple
def LVX_MinwqOp : LVX_Op<"minwq", [Pure]>{
  let summary = "MINWQ -- Minimum Word Quadruple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MINWQ -- immediate form, from MINWQ_registerM_registerP_upper27_lower5_splat32_double
def LVX_MinwqImmOp : LVX_Op<"minwq_i", [Pure]>{
  let summary = "MINWQ -- Minimum Word Quadruple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MINHO -- register form, from MINHO_registerM_registerP_registerO_simple
def LVX_MinhoOp : LVX_Op<"minho", [Pure]>{
  let summary = "MINHO -- Minimum Half Word Octuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MINHO -- immediate form, from MINHO_registerM_registerP_upper27_lower5_splat32_double
def LVX_MinhoImmOp : LVX_Op<"minho_i", [Pure]>{
  let summary = "MINHO -- Minimum Half Word Octuple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MINBX -- register form, from MINBX_registerM_registerP_registerO_simple
def LVX_MinbxOp : LVX_Op<"minbx", [Pure]>{
  let summary = "MINBX -- Minimum Byte Hexadecuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MINBX -- immediate form, from MINBX_registerM_registerP_upper27_lower5_splat32_double
def LVX_MinbxImmOp : LVX_Op<"minbx_i", [Pure]>{
  let summary = "MINBX -- Minimum Byte Hexadecuple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "$operand `,` $signed10 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$signed10), [{
      build($_builder, $_state, resultType, operand, signed10, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MAXDP -- register form, from MAXDP_registerM_registerP_registerO_simple
def LVX_MaxdpOp : LVX_Op<"maxdp", [Pure]>{
  let summary = "MAXDP -- Maximum Double Word Pair";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MAXDP -- immediate form, from MAXDP_registerM_registerP_upper27_lower5_splat32_double
def LVX_MaxdpImmOp : LVX_Op<"maxdp_i", [Pure]>{
  let summary = "MAXDP -- Maximum Double Word Pair";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "(`sx` $sx^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MAXWQ -- register form, from MAXWQ_registerM_registerP_registerO_simple
def LVX_MaxwqOp : LVX_Op<"maxwq", [Pure]>{
  let summary = "MAXWQ -- Maximum Word Quadruple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MAXWQ -- immediate form, from MAXWQ_registerM_registerP_upper27_lower5_splat32_double
def LVX_MaxwqImmOp : LVX_Op<"maxwq_i", [Pure]>{
  let summary = "MAXWQ -- Maximum Word Quadruple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MAXHO -- register form, from MAXHO_registerM_registerP_registerO_simple
def LVX_MaxhoOp : LVX_Op<"maxho", [Pure]>{
  let summary = "MAXHO -- Maximum Half Word Octuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MAXHO -- immediate form, from MAXHO_registerM_registerP_upper27_lower5_splat32_double
def LVX_MaxhoImmOp : LVX_Op<"maxho_i", [Pure]>{
  let summary = "MAXHO -- Maximum Half Word Octuple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MAXBX -- register form, from MAXBX_registerM_registerP_registerO_simple
def LVX_MaxbxOp : LVX_Op<"maxbx", [Pure]>{
  let summary = "MAXBX -- Maximum Byte Hexadecuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MAXBX -- immediate form, from MAXBX_registerM_registerP_upper27_lower5_splat32_double
def LVX_MaxbxImmOp : LVX_Op<"maxbx_i", [Pure]>{
  let summary = "MAXBX -- Maximum Byte Hexadecuple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "$operand `,` $signed10 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$signed10), [{
      build($_builder, $_state, resultType, operand, signed10, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MINUDP -- register form, from MINUDP_registerM_registerP_registerO_simple
def LVX_MinudpOp : LVX_Op<"minudp", [Pure]>{
  let summary = "MINUDP -- Minimum Unsigned Double Word Pair";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MINUDP -- immediate form, from MINUDP_registerM_registerP_upper27_lower5_splat32_double
def LVX_MinudpImmOp : LVX_Op<"minudp_i", [Pure]>{
  let summary = "MINUDP -- Minimum Unsigned Double Word Pair";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "(`sx` $sx^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MINUWQ -- register form, from MINUWQ_registerM_registerP_registerO_simple
def LVX_MinuwqOp : LVX_Op<"minuwq", [Pure]>{
  let summary = "MINUWQ -- Minimum Unsigned Word Quadruple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MINUWQ -- immediate form, from MINUWQ_registerM_registerP_upper27_lower5_splat32_double
def LVX_MinuwqImmOp : LVX_Op<"minuwq_i", [Pure]>{
  let summary = "MINUWQ -- Minimum Unsigned Word Quadruple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MINUHO -- register form, from MINUHO_registerM_registerP_registerO_simple
def LVX_MinuhoOp : LVX_Op<"minuho", [Pure]>{
  let summary = "MINUHO -- Minimum Unsigned Half Word Octuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MINUHO -- immediate form, from MINUHO_registerM_registerP_upper27_lower5_splat32_double
def LVX_MinuhoImmOp : LVX_Op<"minuho_i", [Pure]>{
  let summary = "MINUHO -- Minimum Unsigned Half Word Octuple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MINUBX -- register form, from MINUBX_registerM_registerP_registerO_simple
def LVX_MinubxOp : LVX_Op<"minubx", [Pure]>{
  let summary = "MINUBX -- Minimum Unsigned Byte Hexadecuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MINUBX -- immediate form, from MINUBX_registerM_registerP_upper27_lower5_splat32_double
def LVX_MinubxImmOp : LVX_Op<"minubx_i", [Pure]>{
  let summary = "MINUBX -- Minimum Unsigned Byte Hexadecuple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "$operand `,` $signed10 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$signed10), [{
      build($_builder, $_state, resultType, operand, signed10, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MAXUDP -- register form, from MAXUDP_registerM_registerP_registerO_simple
def LVX_MaxudpOp : LVX_Op<"maxudp", [Pure]>{
  let summary = "MAXUDP -- Maximum Unsigned Double Word Pair";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MAXUDP -- immediate form, from MAXUDP_registerM_registerP_upper27_lower5_splat32_double
def LVX_MaxudpImmOp : LVX_Op<"maxudp_i", [Pure]>{
  let summary = "MAXUDP -- Maximum Unsigned Double Word Pair";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "(`sx` $sx^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MAXUWQ -- register form, from MAXUWQ_registerM_registerP_registerO_simple
def LVX_MaxuwqOp : LVX_Op<"maxuwq", [Pure]>{
  let summary = "MAXUWQ -- Maximum Unsigned Word Quadruple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MAXUWQ -- immediate form, from MAXUWQ_registerM_registerP_upper27_lower5_splat32_double
def LVX_MaxuwqImmOp : LVX_Op<"maxuwq_i", [Pure]>{
  let summary = "MAXUWQ -- Maximum Unsigned Word Quadruple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MAXUHO -- register form, from MAXUHO_registerM_registerP_registerO_simple
def LVX_MaxuhoOp : LVX_Op<"maxuho", [Pure]>{
  let summary = "MAXUHO -- Maximum Unsigned Half Word Octuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MAXUHO -- immediate form, from MAXUHO_registerM_registerP_upper27_lower5_splat32_double
def LVX_MaxuhoImmOp : LVX_Op<"maxuho_i", [Pure]>{
  let summary = "MAXUHO -- Maximum Unsigned Half Word Octuple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MAXUBX -- register form, from MAXUBX_registerM_registerP_registerO_simple
def LVX_MaxubxOp : LVX_Op<"maxubx", [Pure]>{
  let summary = "MAXUBX -- Maximum Unsigned Byte Hexadecuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MAXUBX -- immediate form, from MAXUBX_registerM_registerP_upper27_lower5_splat32_double
def LVX_MaxubxImmOp : LVX_Op<"maxubx_i", [Pure]>{
  let summary = "MAXUBX -- Maximum Unsigned Byte Hexadecuple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ANDQ -- register form, from ANDQ_registerM_registerP_registerO_simple
def LVX_AndqOp : LVX_Op<"andq", [Pure]>{
  let summary = "ANDQ -- Bitwise And Quadruple Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
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
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
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
  let assemblyFormat = "$operand `,` $signed10 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
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
  let assemblyFormat = "(`sx` $sx^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
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
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
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
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
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
  let assemblyFormat = "$operand `,` $signed10 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
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
  let assemblyFormat = "(`sx` $sx^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
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
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
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
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
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
  let assemblyFormat = "$operand `,` $signed10 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
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
  let assemblyFormat = "(`sx` $sx^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
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
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
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
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
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
  let assemblyFormat = "$operand `,` $signed10 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
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
  let assemblyFormat = "(`sx` $sx^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
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
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
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
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
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
  let assemblyFormat = "$operand `,` $signed10 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
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
  let assemblyFormat = "(`sx` $sx^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
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
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
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
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
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
  let assemblyFormat = "$operand `,` $signed10 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
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
  let assemblyFormat = "(`sx` $sx^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
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
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
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
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
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
  let assemblyFormat = "$operand `,` $signed10 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
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
  let assemblyFormat = "(`sx` $sx^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
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
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
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
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
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
  let assemblyFormat = "$operand `,` $signed10 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
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
  let assemblyFormat = "(`sx` $sx^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
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
  let assemblyFormat = "$operand `,` $unsigned6 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultType, operand, unsigned6, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SRLDP -- register form, from SRLDP_registerM_registerP_registerO_simple
def LVX_SrldpOp : LVX_Op<"srldp", [Pure]>{
  let summary = "SRLDP -- Shift Right Logical Double Word Pair";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SRLDP -- immediate form, from SRLDP_registerM_registerP_unsigned6_simple
def LVX_SrldpImmOp : LVX_Op<"srldp_i", [Pure]>{
  let summary = "SRLDP -- Shift Right Logical Double Word Pair";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$unsigned6,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand `,` $unsigned6 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultTypes, operand, unsigned6, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "(`sx` $sx^)? $operand `,` $unsigned6 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, unsigned6, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SRLWQ -- register form, from SRLWQ_registerM_registerP_registerY_simple
def LVX_SrlwqOp : LVX_Op<"srlwq", [Pure]>{
  let summary = "SRLWQ -- Shift Right Logical Word Quadruple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SRLWQ -- immediate form, from SRLWQ_registerM_registerP_unsigned6_simple
def LVX_SrlwqImmOp : LVX_Op<"srlwq_i", [Pure]>{
  let summary = "SRLWQ -- Shift Right Logical Word Quadruple";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$unsigned6,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand `,` $unsigned6 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultTypes, operand, unsigned6, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SRLHO -- register form, from SRLHO_registerM_registerP_registerY_simple
def LVX_SrlhoOp : LVX_Op<"srlho", [Pure]>{
  let summary = "SRLHO -- Shift Right Logical Half Word Octuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SRLHO -- immediate form, from SRLHO_registerM_registerP_unsigned6_simple
def LVX_SrlhoImmOp : LVX_Op<"srlho_i", [Pure]>{
  let summary = "SRLHO -- Shift Right Logical Half Word Octuple";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$unsigned6,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand `,` $unsigned6 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultTypes, operand, unsigned6, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SRLBX -- register form, from SRLBX_registerM_registerP_registerY_simple
def LVX_SrlbxOp : LVX_Op<"srlbx", [Pure]>{
  let summary = "SRLBX -- Shift Right Logical Byte Hexadecuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SRLBX -- immediate form, from SRLBX_registerM_registerP_unsigned6_simple
def LVX_SrlbxImmOp : LVX_Op<"srlbx_i", [Pure]>{
  let summary = "SRLBX -- Shift Right Logical Byte Hexadecuple";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$unsigned6,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand `,` $unsigned6 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultTypes, operand, unsigned6, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "$operand `,` $unsigned6 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultType, operand, unsigned6, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SRADP -- register form, from SRADP_registerM_registerP_registerO_simple
def LVX_SradpOp : LVX_Op<"sradp", [Pure]>{
  let summary = "SRADP -- Shift Right Arithmetic Double Word Pair";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SRADP -- immediate form, from SRADP_registerM_registerP_unsigned6_simple
def LVX_SradpImmOp : LVX_Op<"sradp_i", [Pure]>{
  let summary = "SRADP -- Shift Right Arithmetic Double Word Pair";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$unsigned6,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand `,` $unsigned6 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultTypes, operand, unsigned6, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "(`sx` $sx^)? $operand `,` $unsigned6 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, unsigned6, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SRAWQ -- register form, from SRAWQ_registerM_registerP_registerY_simple
def LVX_SrawqOp : LVX_Op<"srawq", [Pure]>{
  let summary = "SRAWQ -- Shift Right Arithmetic Word Quadruple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SRAWQ -- immediate form, from SRAWQ_registerM_registerP_unsigned6_simple
def LVX_SrawqImmOp : LVX_Op<"srawq_i", [Pure]>{
  let summary = "SRAWQ -- Shift Right Arithmetic Word Quadruple";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$unsigned6,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand `,` $unsigned6 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultTypes, operand, unsigned6, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SRAHO -- register form, from SRAHO_registerM_registerP_registerY_simple
def LVX_SrahoOp : LVX_Op<"sraho", [Pure]>{
  let summary = "SRAHO -- Shift Right Arithmetic Half Word Octuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SRAHO -- immediate form, from SRAHO_registerM_registerP_unsigned6_simple
def LVX_SrahoImmOp : LVX_Op<"sraho_i", [Pure]>{
  let summary = "SRAHO -- Shift Right Arithmetic Half Word Octuple";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$unsigned6,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand `,` $unsigned6 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultTypes, operand, unsigned6, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SRABX -- register form, from SRABX_registerM_registerP_registerY_simple
def LVX_SrabxOp : LVX_Op<"srabx", [Pure]>{
  let summary = "SRABX -- Shift Right Arithmetic Byte Hexadecuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SRABX -- immediate form, from SRABX_registerM_registerP_unsigned6_simple
def LVX_SrabxImmOp : LVX_Op<"srabx_i", [Pure]>{
  let summary = "SRABX -- Shift Right Arithmetic Byte Hexadecuple";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$unsigned6,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand `,` $unsigned6 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultTypes, operand, unsigned6, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "$operand `,` $unsigned6 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultType, operand, unsigned6, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SRSDP -- register form, from SRSDP_registerM_registerP_registerO_simple
def LVX_SrsdpOp : LVX_Op<"srsdp", [Pure]>{
  let summary = "SRSDP -- Shift Right Symmetric Double Word Pair";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SRSDP -- immediate form, from SRSDP_registerM_registerP_unsigned6_simple
def LVX_SrsdpImmOp : LVX_Op<"srsdp_i", [Pure]>{
  let summary = "SRSDP -- Shift Right Symmetric Double Word Pair";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$unsigned6,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand `,` $unsigned6 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultTypes, operand, unsigned6, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "(`sx` $sx^)? $operand `,` $unsigned6 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, unsigned6, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SRSWQ -- register form, from SRSWQ_registerM_registerP_registerY_simple
def LVX_SrswqOp : LVX_Op<"srswq", [Pure]>{
  let summary = "SRSWQ -- Shift Right Symmetric Word Quadruple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SRSWQ -- immediate form, from SRSWQ_registerM_registerP_unsigned6_simple
def LVX_SrswqImmOp : LVX_Op<"srswq_i", [Pure]>{
  let summary = "SRSWQ -- Shift Right Symmetric Word Quadruple";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$unsigned6,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand `,` $unsigned6 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultTypes, operand, unsigned6, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SRSHO -- register form, from SRSHO_registerM_registerP_registerY_simple
def LVX_SrshoOp : LVX_Op<"srsho", [Pure]>{
  let summary = "SRSHO -- Shift Right Symmetric Half Word Octuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SRSHO -- immediate form, from SRSHO_registerM_registerP_unsigned6_simple
def LVX_SrshoImmOp : LVX_Op<"srsho_i", [Pure]>{
  let summary = "SRSHO -- Shift Right Symmetric Half Word Octuple";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$unsigned6,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand `,` $unsigned6 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultTypes, operand, unsigned6, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SRSBX -- register form, from SRSBX_registerM_registerP_registerY_simple
def LVX_SrsbxOp : LVX_Op<"srsbx", [Pure]>{
  let summary = "SRSBX -- Shift Right Symmetric Byte Hexadecuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SRSBX -- immediate form, from SRSBX_registerM_registerP_unsigned6_simple
def LVX_SrsbxImmOp : LVX_Op<"srsbx_i", [Pure]>{
  let summary = "SRSBX -- Shift Right Symmetric Byte Hexadecuple";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$unsigned6,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand `,` $unsigned6 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultTypes, operand, unsigned6, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "$operand `,` $unsigned6 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultType, operand, unsigned6, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SLLDP -- register form, from SLLDP_registerM_registerP_registerO_simple
def LVX_SlldpOp : LVX_Op<"slldp", [Pure]>{
  let summary = "SLLDP -- Shift Left Logical Word Pair by Scalar";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SLLDP -- immediate form, from SLLDP_registerM_registerP_unsigned6_simple
def LVX_SlldpImmOp : LVX_Op<"slldp_i", [Pure]>{
  let summary = "SLLDP -- Shift Left Logical Word Pair by Scalar";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$unsigned6,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand `,` $unsigned6 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultTypes, operand, unsigned6, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "(`sx` $sx^)? $operand `,` $unsigned6 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, unsigned6, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SLLWQ -- register form, from SLLWQ_registerM_registerP_registerY_simple
def LVX_SllwqOp : LVX_Op<"sllwq", [Pure]>{
  let summary = "SLLWQ -- Shift Left Logical Word Quadruple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SLLWQ -- immediate form, from SLLWQ_registerM_registerP_unsigned6_simple
def LVX_SllwqImmOp : LVX_Op<"sllwq_i", [Pure]>{
  let summary = "SLLWQ -- Shift Left Logical Word Quadruple";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$unsigned6,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand `,` $unsigned6 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultTypes, operand, unsigned6, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SLLHO -- register form, from SLLHO_registerM_registerP_registerY_simple
def LVX_SllhoOp : LVX_Op<"sllho", [Pure]>{
  let summary = "SLLHO -- Shift Left Logical Half Word Octuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SLLHO -- immediate form, from SLLHO_registerM_registerP_unsigned6_simple
def LVX_SllhoImmOp : LVX_Op<"sllho_i", [Pure]>{
  let summary = "SLLHO -- Shift Left Logical Half Word Octuple";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$unsigned6,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand `,` $unsigned6 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultTypes, operand, unsigned6, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SLLBX -- register form, from SLLBX_registerM_registerP_registerY_simple
def LVX_SllbxOp : LVX_Op<"sllbx", [Pure]>{
  let summary = "SLLBX -- Shift Left Logical Byte Hexadecuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SLLBX -- immediate form, from SLLBX_registerM_registerP_unsigned6_simple
def LVX_SllbxImmOp : LVX_Op<"sllbx_i", [Pure]>{
  let summary = "SLLBX -- Shift Left Logical Byte Hexadecuple";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$unsigned6,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand `,` $unsigned6 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultTypes, operand, unsigned6, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "$operand `,` $unsigned6 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultType, operand, unsigned6, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SLSDP -- register form, from SLSDP_registerM_registerP_registerO_simple
def LVX_SlsdpOp : LVX_Op<"slsdp", [Pure]>{
  let summary = "SLSDP -- Shift Left Saturated Double Word Pair";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SLSDP -- immediate form, from SLSDP_registerM_registerP_unsigned6_simple
def LVX_SlsdpImmOp : LVX_Op<"slsdp_i", [Pure]>{
  let summary = "SLSDP -- Shift Left Saturated Double Word Pair";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$unsigned6,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand `,` $unsigned6 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultTypes, operand, unsigned6, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "(`sx` $sx^)? $operand `,` $unsigned6 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, unsigned6, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SLSWQ -- register form, from SLSWQ_registerM_registerP_registerY_simple
def LVX_SlswqOp : LVX_Op<"slswq", [Pure]>{
  let summary = "SLSWQ -- Shift Left Saturated Word Quadruple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SLSWQ -- immediate form, from SLSWQ_registerM_registerP_unsigned6_simple
def LVX_SlswqImmOp : LVX_Op<"slswq_i", [Pure]>{
  let summary = "SLSWQ -- Shift Left Saturated Word Quadruple";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$unsigned6,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand `,` $unsigned6 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultTypes, operand, unsigned6, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SLSHO -- register form, from SLSHO_registerM_registerP_registerY_simple
def LVX_SlshoOp : LVX_Op<"slsho", [Pure]>{
  let summary = "SLSHO -- Shift Left Saturated Half Word Octuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SLSHO -- immediate form, from SLSHO_registerM_registerP_unsigned6_simple
def LVX_SlshoImmOp : LVX_Op<"slsho_i", [Pure]>{
  let summary = "SLSHO -- Shift Left Saturated Half Word Octuple";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$unsigned6,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand `,` $unsigned6 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultTypes, operand, unsigned6, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SLSBX -- register form, from SLSBX_registerM_registerP_registerY_simple
def LVX_SlsbxOp : LVX_Op<"slsbx", [Pure]>{
  let summary = "SLSBX -- Shift Left Saturated Byte Hexadecuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SLSBX -- immediate form, from SLSBX_registerM_registerP_unsigned6_simple
def LVX_SlsbxImmOp : LVX_Op<"slsbx_i", [Pure]>{
  let summary = "SLSBX -- Shift Left Saturated Byte Hexadecuple";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$unsigned6,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand `,` $unsigned6 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultTypes, operand, unsigned6, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "$operand `,` $unsigned6 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultType, operand, unsigned6, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SLUSDP -- register form, from SLUSDP_registerM_registerP_registerO_simple
def LVX_SlusdpOp : LVX_Op<"slusdp", [Pure]>{
  let summary = "SLUSDP -- Shift Left Unsigned Saturated Double Word Pair";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SLUSDP -- immediate form, from SLUSDP_registerM_registerP_unsigned6_simple
def LVX_SlusdpImmOp : LVX_Op<"slusdp_i", [Pure]>{
  let summary = "SLUSDP -- Shift Left Unsigned Saturated Double Word Pair";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$unsigned6,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand `,` $unsigned6 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultTypes, operand, unsigned6, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "(`sx` $sx^)? $operand `,` $unsigned6 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, unsigned6, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SLUSWQ -- register form, from SLUSWQ_registerM_registerP_registerY_simple
def LVX_SluswqOp : LVX_Op<"sluswq", [Pure]>{
  let summary = "SLUSWQ -- Shift Left Unsigned Saturated Word Quadruple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SLUSWQ -- immediate form, from SLUSWQ_registerM_registerP_unsigned6_simple
def LVX_SluswqImmOp : LVX_Op<"sluswq_i", [Pure]>{
  let summary = "SLUSWQ -- Shift Left Unsigned Saturated Word Quadruple";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$unsigned6,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand `,` $unsigned6 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultTypes, operand, unsigned6, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SLUSHO -- register form, from SLUSHO_registerM_registerP_registerY_simple
def LVX_SlushoOp : LVX_Op<"slusho", [Pure]>{
  let summary = "SLUSHO -- Shift Left Unsigned Saturated Half Word Octuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SLUSHO -- immediate form, from SLUSHO_registerM_registerP_unsigned6_simple
def LVX_SlushoImmOp : LVX_Op<"slusho_i", [Pure]>{
  let summary = "SLUSHO -- Shift Left Unsigned Saturated Half Word Octuple";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$unsigned6,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand `,` $unsigned6 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultTypes, operand, unsigned6, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SLUSBX -- register form, from SLUSBX_registerM_registerP_registerY_simple
def LVX_SlusbxOp : LVX_Op<"slusbx", [Pure]>{
  let summary = "SLUSBX -- Shift Left Unsigned Saturated Byte Hexadecuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SLUSBX -- immediate form, from SLUSBX_registerM_registerP_unsigned6_simple
def LVX_SlusbxImmOp : LVX_Op<"slusbx_i", [Pure]>{
  let summary = "SLUSBX -- Shift Left Unsigned Saturated Byte Hexadecuple";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$unsigned6,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand `,` $unsigned6 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultTypes, operand, unsigned6, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "$operand `,` $unsigned6 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
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
  let assemblyFormat = "(`sx` $sx^)? $operand `,` $unsigned6 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, unsigned6, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ROLWQ -- register form, from ROLWQ_registerM_registerP_registerY_simple
def LVX_RolwqOp : LVX_Op<"rolwq", [Pure]>{
  let summary = "ROLWQ -- Rotate Left Word Quadruple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ROLWQ -- immediate form, from ROLWQ_registerM_registerP_unsigned6_simple
def LVX_RolwqImmOp : LVX_Op<"rolwq_i", [Pure]>{
  let summary = "ROLWQ -- Rotate Left Word Quadruple";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$unsigned6,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand `,` $unsigned6 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultTypes, operand, unsigned6, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "$operand `,` $unsigned6 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
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
  let assemblyFormat = "(`sx` $sx^)? $operand `,` $unsigned6 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, unsigned6, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:RORWQ -- register form, from RORWQ_registerM_registerP_registerY_simple
def LVX_RorwqOp : LVX_Op<"rorwq", [Pure]>{
  let summary = "RORWQ -- Rotate Right Word Quadruple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:RORWQ -- immediate form, from RORWQ_registerM_registerP_unsigned6_simple
def LVX_RorwqImmOp : LVX_Op<"rorwq_i", [Pure]>{
  let summary = "RORWQ -- Rotate Right Word Quadruple";
  let arguments = (ins LVX_RegType:$operand,
                       TypedAttrInterface:$unsigned6,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand `,` $unsigned6 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$unsigned6), [{
      build($_builder, $_state, resultTypes, operand, unsigned6, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "$operand `,` $signed10 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$signed10), [{
      build($_builder, $_state, resultType, operand, signed10, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBMM8DP -- register form, from SBMM8DP_registerM_registerP_registerO_simple
def LVX_Sbmm8dpOp : LVX_Op<"sbmm8dp", [Pure]>{
  let summary = "SBMM8DP -- Swapped Bit Matrix Multiplication 8$\times$8 Double Word Pair";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBMM8DP -- immediate form, from SBMM8DP_registerM_registerP_upper27_lower5_splat32_double
def LVX_Sbmm8dpImmOp : LVX_Op<"sbmm8dp_i", [Pure]>{
  let summary = "SBMM8DP -- Swapped Bit Matrix Multiplication 8$\times$8 Double Word Pair";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "$operand `,` $signed10 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$signed10), [{
      build($_builder, $_state, resultType, operand, signed10, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBMMT8DP -- register form, from SBMMT8DP_registerM_registerP_registerO_simple
def LVX_Sbmmt8dpOp : LVX_Op<"sbmmt8dp", [Pure]>{
  let summary = "SBMMT8DP -- Swapped Bit Matrix Multiplication Transposed 8$\times$8 Double Word Pair";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBMMT8DP -- immediate form, from SBMMT8DP_registerM_registerP_upper27_lower5_splat32_double
def LVX_Sbmmt8dpImmOp : LVX_Op<"sbmmt8dp_i", [Pure]>{
  let summary = "SBMMT8DP -- Swapped Bit Matrix Multiplication Transposed 8$\times$8 Double Word Pair";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBMM8EORD -- register form, from SBMM8EORD_registerW_registerZ_registerY_simple
def LVX_Sbmm8eordOp : LVX_Op<"sbmm8eord", [Pure]>{
  let summary = "SBMM8EORD -- Swapped Bit Matrix Multiplication 8$\times$8 Exclusive OR Double Word";
  let arguments = (ins LVX_RegType:$a,
                       LVX_RegType:$b,
                       LVX_RegType:$c,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$a `,` $b `,` $c attr-dict `:` `(` qualified(type($a)) `,` qualified(type($b)) `,` qualified(type($c)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$a, "::mlir::Value":$b, "::mlir::Value":$c), [{
      build($_builder, $_state, resultType, a, b, c, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBMM8EORD -- immediate form, from SBMM8EORD_registerW_registerZ_upper27_lower5_splat32_double
def LVX_Sbmm8eordImmOp : LVX_Op<"sbmm8eord_i", [Pure]>{
  let summary = "SBMM8EORD -- Swapped Bit Matrix Multiplication 8$\times$8 Exclusive OR Double Word";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`splat32` $splat32^)? $lhs `,` $upper27_lower5 `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), lhs, rhs, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBMM8EORDP -- register form, from SBMM8EORDP_registerM_registerP_registerO_simple
def LVX_Sbmm8eordpOp : LVX_Op<"sbmm8eordp", [Pure]>{
  let summary = "SBMM8EORDP -- Swapped Bit Matrix Multiplication 8$\times$8 Exclusive OR Double Word Pair";
  let arguments = (ins LVX_RegType:$a,
                       LVX_RegType:$b,
                       LVX_RegType:$c,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$a `,` $b `,` $c attr-dict `:` `(` qualified(type($a)) `,` qualified(type($b)) `,` qualified(type($c)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$a, "::mlir::Value":$b, "::mlir::Value":$c), [{
      build($_builder, $_state, resultTypes, a, b, c, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBMM8EORDP -- immediate form, from SBMM8EORDP_registerM_registerP_upper27_lower5_splat32_double
def LVX_Sbmm8eordpImmOp : LVX_Op<"sbmm8eordp_i", [Pure]>{
  let summary = "SBMM8EORDP -- Swapped Bit Matrix Multiplication 8$\times$8 Exclusive OR Double Word Pair";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $lhs `,` $upper27_lower5 `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), lhs, rhs, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBMMT8EORD -- register form, from SBMMT8EORD_registerW_registerZ_registerY_simple
def LVX_Sbmmt8eordOp : LVX_Op<"sbmmt8eord", [Pure]>{
  let summary = "SBMMT8EORD -- Swapped Bit Matrix Multiplication Transposed 8$\times$8 Exclusive OR Double Word";
  let arguments = (ins LVX_RegType:$a,
                       LVX_RegType:$b,
                       LVX_RegType:$c,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$a `,` $b `,` $c attr-dict `:` `(` qualified(type($a)) `,` qualified(type($b)) `,` qualified(type($c)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$a, "::mlir::Value":$b, "::mlir::Value":$c), [{
      build($_builder, $_state, resultType, a, b, c, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBMMT8EORD -- immediate form, from SBMMT8EORD_registerW_registerZ_upper27_lower5_splat32_double
def LVX_Sbmmt8eordImmOp : LVX_Op<"sbmmt8eord_i", [Pure]>{
  let summary = "SBMMT8EORD -- Swapped Bit Matrix Multiplication Transposed 8$\times$8 Exclusive OR Double Word";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`splat32` $splat32^)? $lhs `,` $upper27_lower5 `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), lhs, rhs, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBMMT8EORDP -- register form, from SBMMT8EORDP_registerM_registerP_registerO_simple
def LVX_Sbmmt8eordpOp : LVX_Op<"sbmmt8eordp", [Pure]>{
  let summary = "SBMMT8EORDP -- Swapped Bit Matrix Multiplication Transposed 8$\times$8 Exclusive OR Double Word Pair";
  let arguments = (ins LVX_RegType:$a,
                       LVX_RegType:$b,
                       LVX_RegType:$c,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$a `,` $b `,` $c attr-dict `:` `(` qualified(type($a)) `,` qualified(type($b)) `,` qualified(type($c)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$a, "::mlir::Value":$b, "::mlir::Value":$c), [{
      build($_builder, $_state, resultTypes, a, b, c, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SBMMT8EORDP -- immediate form, from SBMMT8EORDP_registerM_registerP_upper27_lower5_splat32_double
def LVX_Sbmmt8eordpImmOp : LVX_Op<"sbmmt8eordp_i", [Pure]>{
  let summary = "SBMMT8EORDP -- Swapped Bit Matrix Multiplication Transposed 8$\times$8 Exclusive OR Double Word Pair";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $lhs `,` $upper27_lower5 `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), lhs, rhs, upper27_lower5, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "(`sx` $sx^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:AVGWQ -- register form, from AVGWQ_registerM_registerP_registerO_simple
def LVX_AvgwqOp : LVX_Op<"avgwq", [Pure]>{
  let summary = "AVGWQ -- Average Word Quadruple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:AVGWQ -- immediate form, from AVGWQ_registerM_registerP_upper27_lower5_splat32_double
def LVX_AvgwqImmOp : LVX_Op<"avgwq_i", [Pure]>{
  let summary = "AVGWQ -- Average Word Quadruple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:AVGHO -- register form, from AVGHO_registerM_registerP_registerO_simple
def LVX_AvghoOp : LVX_Op<"avgho", [Pure]>{
  let summary = "AVGHO -- Average Half Word Octuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:AVGHO -- immediate form, from AVGHO_registerM_registerP_upper27_lower5_splat32_double
def LVX_AvghoImmOp : LVX_Op<"avgho_i", [Pure]>{
  let summary = "AVGHO -- Average Half Word Octuple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:AVGBX -- register form, from AVGBX_registerM_registerP_registerO_simple
def LVX_AvgbxOp : LVX_Op<"avgbx", [Pure]>{
  let summary = "AVGBX -- Average Byte Hexadecuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:AVGBX -- immediate form, from AVGBX_registerM_registerP_upper27_lower5_splat32_double
def LVX_AvgbxImmOp : LVX_Op<"avgbx_i", [Pure]>{
  let summary = "AVGBX -- Average Byte Hexadecuple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "(`sx` $sx^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:AVGUWQ -- register form, from AVGUWQ_registerM_registerP_registerO_simple
def LVX_AvguwqOp : LVX_Op<"avguwq", [Pure]>{
  let summary = "AVGUWQ -- Average Unsigned Word Quadruple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:AVGUWQ -- immediate form, from AVGUWQ_registerM_registerP_upper27_lower5_splat32_double
def LVX_AvguwqImmOp : LVX_Op<"avguwq_i", [Pure]>{
  let summary = "AVGUWQ -- Average Unsigned Word Quadruple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:AVGUHO -- register form, from AVGUHO_registerM_registerP_registerO_simple
def LVX_AvguhoOp : LVX_Op<"avguho", [Pure]>{
  let summary = "AVGUHO -- Average Unsigned Half Word Octuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:AVGUHO -- immediate form, from AVGUHO_registerM_registerP_upper27_lower5_splat32_double
def LVX_AvguhoImmOp : LVX_Op<"avguho_i", [Pure]>{
  let summary = "AVGUHO -- Average Unsigned Half Word Octuple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:AVGUBX -- register form, from AVGUBX_registerM_registerP_registerO_simple
def LVX_AvgubxOp : LVX_Op<"avgubx", [Pure]>{
  let summary = "AVGUBX -- Average Unsigned Byte Hexadecuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:AVGUBX -- immediate form, from AVGUBX_registerM_registerP_upper27_lower5_splat32_double
def LVX_AvgubxImmOp : LVX_Op<"avgubx_i", [Pure]>{
  let summary = "AVGUBX -- Average Unsigned Byte Hexadecuple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "(`sx` $sx^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:AVGRWQ -- register form, from AVGRWQ_registerM_registerP_registerO_simple
def LVX_AvgrwqOp : LVX_Op<"avgrwq", [Pure]>{
  let summary = "AVGRWQ -- Average Rounded Word Quadruple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:AVGRWQ -- immediate form, from AVGRWQ_registerM_registerP_upper27_lower5_splat32_double
def LVX_AvgrwqImmOp : LVX_Op<"avgrwq_i", [Pure]>{
  let summary = "AVGRWQ -- Average Rounded Word Quadruple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:AVGRHO -- register form, from AVGRHO_registerM_registerP_registerO_simple
def LVX_AvgrhoOp : LVX_Op<"avgrho", [Pure]>{
  let summary = "AVGRHO -- Average Rounded Half Word Octuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:AVGRHO -- immediate form, from AVGRHO_registerM_registerP_upper27_lower5_splat32_double
def LVX_AvgrhoImmOp : LVX_Op<"avgrho_i", [Pure]>{
  let summary = "AVGRHO -- Average Rounded Half Word Octuple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:AVGRBX -- register form, from AVGRBX_registerM_registerP_registerO_simple
def LVX_AvgrbxOp : LVX_Op<"avgrbx", [Pure]>{
  let summary = "AVGRBX -- Average Rounded Byte Hexadecuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:AVGRBX -- immediate form, from AVGRBX_registerM_registerP_upper27_lower5_splat32_double
def LVX_AvgrbxImmOp : LVX_Op<"avgrbx_i", [Pure]>{
  let summary = "AVGRBX -- Average Rounded Byte Hexadecuple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "(`sx` $sx^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:AVGRUWQ -- register form, from AVGRUWQ_registerM_registerP_registerO_simple
def LVX_AvgruwqOp : LVX_Op<"avgruwq", [Pure]>{
  let summary = "AVGRUWQ -- Average Rounded Unsigned Word Quadruple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:AVGRUWQ -- immediate form, from AVGRUWQ_registerM_registerP_upper27_lower5_splat32_double
def LVX_AvgruwqImmOp : LVX_Op<"avgruwq_i", [Pure]>{
  let summary = "AVGRUWQ -- Average Rounded Unsigned Word Quadruple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:AVGRUHO -- register form, from AVGRUHO_registerM_registerP_registerO_simple
def LVX_AvgruhoOp : LVX_Op<"avgruho", [Pure]>{
  let summary = "AVGRUHO -- Average Rounded Unsigned Half Word Octuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:AVGRUHO -- immediate form, from AVGRUHO_registerM_registerP_upper27_lower5_splat32_double
def LVX_AvgruhoImmOp : LVX_Op<"avgruho_i", [Pure]>{
  let summary = "AVGRUHO -- Average Rounded Unsigned Half Word Octuple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:AVGRUBX -- register form, from AVGRUBX_registerM_registerP_registerO_simple
def LVX_AvgrubxOp : LVX_Op<"avgrubx", [Pure]>{
  let summary = "AVGRUBX -- Average Rounded Unsigned Byte Hexadecuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:AVGRUBX -- immediate form, from AVGRUBX_registerM_registerP_upper27_lower5_splat32_double
def LVX_AvgrubxImmOp : LVX_Op<"avgrubx_i", [Pure]>{
  let summary = "AVGRUBX -- Average Rounded Unsigned Byte Hexadecuple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SIGNDP -- register form, from SIGNDP_registerM_registerP_registerO_simple
def LVX_SigndpOp : LVX_Op<"signdp", [Pure]>{
  let summary = "SIGNDP -- Apply Sign Double Word Pair";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SIGNDP -- immediate form, from SIGNDP_registerM_registerP_upper27_lower5_splat32_double
def LVX_SigndpImmOp : LVX_Op<"signdp_i", [Pure]>{
  let summary = "SIGNDP -- Apply Sign Double Word Pair";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "(`sx` $sx^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SIGNWQ -- register form, from SIGNWQ_registerM_registerP_registerO_simple
def LVX_SignwqOp : LVX_Op<"signwq", [Pure]>{
  let summary = "SIGNWQ -- Apply Sign Word Quadruple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SIGNWQ -- immediate form, from SIGNWQ_registerM_registerP_upper27_lower5_splat32_double
def LVX_SignwqImmOp : LVX_Op<"signwq_i", [Pure]>{
  let summary = "SIGNWQ -- Apply Sign Word Quadruple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SIGNHO -- register form, from SIGNHO_registerM_registerP_registerO_simple
def LVX_SignhoOp : LVX_Op<"signho", [Pure]>{
  let summary = "SIGNHO -- Apply Sign Half Word Octuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SIGNHO -- immediate form, from SIGNHO_registerM_registerP_upper27_lower5_splat32_double
def LVX_SignhoImmOp : LVX_Op<"signho_i", [Pure]>{
  let summary = "SIGNHO -- Apply Sign Half Word Octuple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SIGNBX -- register form, from SIGNBX_registerM_registerP_registerO_simple
def LVX_SignbxOp : LVX_Op<"signbx", [Pure]>{
  let summary = "SIGNBX -- Apply Sign Byte Hexadecuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SIGNBX -- immediate form, from SIGNBX_registerM_registerP_upper27_lower5_splat32_double
def LVX_SignbxImmOp : LVX_Op<"signbx_i", [Pure]>{
  let summary = "SIGNBX -- Apply Sign Byte Hexadecuple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SIGNSDP -- register form, from SIGNSDP_registerM_registerP_registerO_simple
def LVX_SignsdpOp : LVX_Op<"signsdp", [Pure]>{
  let summary = "SIGNSDP -- Apply Sign Saturated Double Word Pair";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SIGNSDP -- immediate form, from SIGNSDP_registerM_registerP_upper27_lower5_splat32_double
def LVX_SignsdpImmOp : LVX_Op<"signsdp_i", [Pure]>{
  let summary = "SIGNSDP -- Apply Sign Saturated Double Word Pair";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "(`sx` $sx^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SIGNSWQ -- register form, from SIGNSWQ_registerM_registerP_registerO_simple
def LVX_SignswqOp : LVX_Op<"signswq", [Pure]>{
  let summary = "SIGNSWQ -- Apply Sign Saturated Word Quadruple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SIGNSWQ -- immediate form, from SIGNSWQ_registerM_registerP_upper27_lower5_splat32_double
def LVX_SignswqImmOp : LVX_Op<"signswq_i", [Pure]>{
  let summary = "SIGNSWQ -- Apply Sign Saturated Word Quadruple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SIGNSHO -- register form, from SIGNSHO_registerM_registerP_registerO_simple
def LVX_SignshoOp : LVX_Op<"signsho", [Pure]>{
  let summary = "SIGNSHO -- Apply Sign Saturated Half Word Octuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SIGNSHO -- immediate form, from SIGNSHO_registerM_registerP_upper27_lower5_splat32_double
def LVX_SignshoImmOp : LVX_Op<"signsho_i", [Pure]>{
  let summary = "SIGNSHO -- Apply Sign Saturated Half Word Octuple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SIGNSBX -- register form, from SIGNSBX_registerM_registerP_registerO_simple
def LVX_SignsbxOp : LVX_Op<"signsbx", [Pure]>{
  let summary = "SIGNSBX -- Apply Sign Saturated Byte Hexadecuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SIGNSBX -- immediate form, from SIGNSBX_registerM_registerP_upper27_lower5_splat32_double
def LVX_SignsbxImmOp : LVX_Op<"signsbx_i", [Pure]>{
  let summary = "SIGNSBX -- Apply Sign Saturated Byte Hexadecuple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX2DP -- register form, from ADDX2DP_registerM_registerP_registerO_simple
def LVX_Addx2dpOp : LVX_Op<"addx2dp", [Pure]>{
  let summary = "ADDX2DP -- Add to Times 2 Double Word Pair";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX2DP -- immediate form, from ADDX2DP_registerM_registerP_upper27_lower5_splat32_double
def LVX_Addx2dpImmOp : LVX_Op<"addx2dp_i", [Pure]>{
  let summary = "ADDX2DP -- Add to Times 2 Double Word Pair";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "(`sx` $sx^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX2WQ -- register form, from ADDX2WQ_registerM_registerP_registerO_simple
def LVX_Addx2wqOp : LVX_Op<"addx2wq", [Pure]>{
  let summary = "ADDX2WQ -- Add to Times 2 Word Quadruple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX2WQ -- immediate form, from ADDX2WQ_registerM_registerP_upper27_lower5_splat32_double
def LVX_Addx2wqImmOp : LVX_Op<"addx2wq_i", [Pure]>{
  let summary = "ADDX2WQ -- Add to Times 2 Word Quadruple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX2HO -- register form, from ADDX2HO_registerM_registerP_registerO_simple
def LVX_Addx2hoOp : LVX_Op<"addx2ho", [Pure]>{
  let summary = "ADDX2HO -- Add to Times 2 Half Word Octuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX2HO -- immediate form, from ADDX2HO_registerM_registerP_upper27_lower5_splat32_double
def LVX_Addx2hoImmOp : LVX_Op<"addx2ho_i", [Pure]>{
  let summary = "ADDX2HO -- Add to Times 2 Half Word Octuple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX2BX -- register form, from ADDX2BX_registerM_registerP_registerO_simple
def LVX_Addx2bxOp : LVX_Op<"addx2bx", [Pure]>{
  let summary = "ADDX2BX -- Add to Times 2 Byte Hexadecuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX2BX -- immediate form, from ADDX2BX_registerM_registerP_upper27_lower5_splat32_double
def LVX_Addx2bxImmOp : LVX_Op<"addx2bx_i", [Pure]>{
  let summary = "ADDX2BX -- Add to Times 2 Byte Hexadecuple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX4DP -- register form, from ADDX4DP_registerM_registerP_registerO_simple
def LVX_Addx4dpOp : LVX_Op<"addx4dp", [Pure]>{
  let summary = "ADDX4DP -- Add to Times 4 Double Word Pair";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX4DP -- immediate form, from ADDX4DP_registerM_registerP_upper27_lower5_splat32_double
def LVX_Addx4dpImmOp : LVX_Op<"addx4dp_i", [Pure]>{
  let summary = "ADDX4DP -- Add to Times 4 Double Word Pair";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "(`sx` $sx^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX4WQ -- register form, from ADDX4WQ_registerM_registerP_registerO_simple
def LVX_Addx4wqOp : LVX_Op<"addx4wq", [Pure]>{
  let summary = "ADDX4WQ -- Add to Times 4 Word Quadruple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX4WQ -- immediate form, from ADDX4WQ_registerM_registerP_upper27_lower5_splat32_double
def LVX_Addx4wqImmOp : LVX_Op<"addx4wq_i", [Pure]>{
  let summary = "ADDX4WQ -- Add to Times 4 Word Quadruple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX4HO -- register form, from ADDX4HO_registerM_registerP_registerO_simple
def LVX_Addx4hoOp : LVX_Op<"addx4ho", [Pure]>{
  let summary = "ADDX4HO -- Add to Times 4 Half Word Octuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX4HO -- immediate form, from ADDX4HO_registerM_registerP_upper27_lower5_splat32_double
def LVX_Addx4hoImmOp : LVX_Op<"addx4ho_i", [Pure]>{
  let summary = "ADDX4HO -- Add to Times 4 Half Word Octuple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX4BX -- register form, from ADDX4BX_registerM_registerP_registerO_simple
def LVX_Addx4bxOp : LVX_Op<"addx4bx", [Pure]>{
  let summary = "ADDX4BX -- Add to Times 4 Byte Hexadecuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX4BX -- immediate form, from ADDX4BX_registerM_registerP_upper27_lower5_splat32_double
def LVX_Addx4bxImmOp : LVX_Op<"addx4bx_i", [Pure]>{
  let summary = "ADDX4BX -- Add to Times 4 Byte Hexadecuple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX8DP -- register form, from ADDX8DP_registerM_registerP_registerO_simple
def LVX_Addx8dpOp : LVX_Op<"addx8dp", [Pure]>{
  let summary = "ADDX8DP -- Add to Times 8 Double Word Pair";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX8DP -- immediate form, from ADDX8DP_registerM_registerP_upper27_lower5_splat32_double
def LVX_Addx8dpImmOp : LVX_Op<"addx8dp_i", [Pure]>{
  let summary = "ADDX8DP -- Add to Times 8 Double Word Pair";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "(`sx` $sx^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX8WQ -- register form, from ADDX8WQ_registerM_registerP_registerO_simple
def LVX_Addx8wqOp : LVX_Op<"addx8wq", [Pure]>{
  let summary = "ADDX8WQ -- Add to Times 8 Word Quadruple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX8WQ -- immediate form, from ADDX8WQ_registerM_registerP_upper27_lower5_splat32_double
def LVX_Addx8wqImmOp : LVX_Op<"addx8wq_i", [Pure]>{
  let summary = "ADDX8WQ -- Add to Times 8 Word Quadruple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX8HO -- register form, from ADDX8HO_registerM_registerP_registerO_simple
def LVX_Addx8hoOp : LVX_Op<"addx8ho", [Pure]>{
  let summary = "ADDX8HO -- Add to Times 8 Half Word Octuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX8HO -- immediate form, from ADDX8HO_registerM_registerP_upper27_lower5_splat32_double
def LVX_Addx8hoImmOp : LVX_Op<"addx8ho_i", [Pure]>{
  let summary = "ADDX8HO -- Add to Times 8 Half Word Octuple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX8BX -- register form, from ADDX8BX_registerM_registerP_registerO_simple
def LVX_Addx8bxOp : LVX_Op<"addx8bx", [Pure]>{
  let summary = "ADDX8BX -- Add to Times 8 Byte Hexadecuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX8BX -- immediate form, from ADDX8BX_registerM_registerP_upper27_lower5_splat32_double
def LVX_Addx8bxImmOp : LVX_Op<"addx8bx_i", [Pure]>{
  let summary = "ADDX8BX -- Add to Times 8 Byte Hexadecuple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX16DP -- register form, from ADDX16DP_registerM_registerP_registerO_simple
def LVX_Addx16dpOp : LVX_Op<"addx16dp", [Pure]>{
  let summary = "ADDX16DP -- Add to Times 16 Double Word Pair";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX16DP -- immediate form, from ADDX16DP_registerM_registerP_upper27_lower5_splat32_double
def LVX_Addx16dpImmOp : LVX_Op<"addx16dp_i", [Pure]>{
  let summary = "ADDX16DP -- Add to Times 16 Double Word Pair";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "(`sx` $sx^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX16WQ -- register form, from ADDX16WQ_registerM_registerP_registerO_simple
def LVX_Addx16wqOp : LVX_Op<"addx16wq", [Pure]>{
  let summary = "ADDX16WQ -- Add to Times 16 Word Quadruple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX16WQ -- immediate form, from ADDX16WQ_registerM_registerP_upper27_lower5_splat32_double
def LVX_Addx16wqImmOp : LVX_Op<"addx16wq_i", [Pure]>{
  let summary = "ADDX16WQ -- Add to Times 16 Word Quadruple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX16HO -- register form, from ADDX16HO_registerM_registerP_registerO_simple
def LVX_Addx16hoOp : LVX_Op<"addx16ho", [Pure]>{
  let summary = "ADDX16HO -- Add to Times 16 Half Word Octuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX16HO -- immediate form, from ADDX16HO_registerM_registerP_upper27_lower5_splat32_double
def LVX_Addx16hoImmOp : LVX_Op<"addx16ho_i", [Pure]>{
  let summary = "ADDX16HO -- Add to Times 16 Half Word Octuple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX16BX -- register form, from ADDX16BX_registerM_registerP_registerO_simple
def LVX_Addx16bxOp : LVX_Op<"addx16bx", [Pure]>{
  let summary = "ADDX16BX -- Add to Times 16 Byte Hexadecuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ADDX16BX -- immediate form, from ADDX16BX_registerM_registerP_upper27_lower5_splat32_double
def LVX_Addx16bxImmOp : LVX_Op<"addx16bx_i", [Pure]>{
  let summary = "ADDX16BX -- Add to Times 16 Byte Hexadecuple";
  let arguments = (ins UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
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
  let assemblyFormat = "(`sx` $sx^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
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
  let assemblyFormat = "(`splat32` $splat32^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
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
  let assemblyFormat = "(`sx` $sx^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
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

// FPU:FNEGD -- register form, from FNEGD_registerW_registerZ_simple
def LVX_FnegdOp : LVX_Op<"fnegd", [Pure]>{
  let summary = "FNEGD -- Floating-Point Negate Double Word";
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

// FPU:FNEGDP -- register form, from FNEGDP_registerM_registerP_simple
def LVX_FnegdpOp : LVX_Op<"fnegdp", [Pure]>{
  let summary = "FNEGDP -- Floating-Point Negate Double Word Pair";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FNEGW -- register form, from FNEGW_registerW_registerZ_simple
def LVX_FnegwOp : LVX_Op<"fnegw", [Pure]>{
  let summary = "FNEGW -- Floating-Point Negate Word";
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

// FPU:FNEGWP -- register form, from FNEGWP_registerW_registerZ_simple
def LVX_FnegwpOp : LVX_Op<"fnegwp", [Pure]>{
  let summary = "FNEGWP -- Floating-Point Negate Word Pair";
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

// FPU:FNEGWQ -- register form, from FNEGWQ_registerM_registerP_simple
def LVX_FnegwqOp : LVX_Op<"fnegwq", [Pure]>{
  let summary = "FNEGWQ -- Floating-Point Negate Word Quadruple";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FNEGH -- register form, from FNEGH_registerW_registerZ_simple
def LVX_FneghOp : LVX_Op<"fnegh", [Pure]>{
  let summary = "FNEGH -- Floating-Point Negate Half Word";
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

// FPU:FNEGHO -- register form, from FNEGHO_registerM_registerP_simple
def LVX_FneghoOp : LVX_Op<"fnegho", [Pure]>{
  let summary = "FNEGHO -- Floating-Point Negate Half Word Octuple";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FABSD -- register form, from FABSD_registerW_registerZ_simple
def LVX_FabsdOp : LVX_Op<"fabsd", [Pure]>{
  let summary = "FABSD -- Floating-Point Absolute Value Double Word";
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

// FPU:FABSDP -- register form, from FABSDP_registerM_registerP_simple
def LVX_FabsdpOp : LVX_Op<"fabsdp", [Pure]>{
  let summary = "FABSDP -- Floating-Point Absolute Value Double Word Pair";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FABSW -- register form, from FABSW_registerW_registerZ_simple
def LVX_FabswOp : LVX_Op<"fabsw", [Pure]>{
  let summary = "FABSW -- Floating-Point Absolute Value Word";
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

// FPU:FABSWP -- register form, from FABSWP_registerW_registerZ_simple
def LVX_FabswpOp : LVX_Op<"fabswp", [Pure]>{
  let summary = "FABSWP -- Floating-Point Absolute Value Word Pair";
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

// FPU:FABSWQ -- register form, from FABSWQ_registerM_registerP_simple
def LVX_FabswqOp : LVX_Op<"fabswq", [Pure]>{
  let summary = "FABSWQ -- Floating-Point Absolute Value Word Quadruple";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FABSH -- register form, from FABSH_registerW_registerZ_simple
def LVX_FabshOp : LVX_Op<"fabsh", [Pure]>{
  let summary = "FABSH -- Floating-Point Absolute Value Half Word";
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

// FPU:FABSHO -- register form, from FABSHO_registerM_registerP_simple
def LVX_FabshoOp : LVX_Op<"fabsho", [Pure]>{
  let summary = "FABSHO -- Floating-Point Absolute Value Half Word Octuple";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FSRECD -- register form, from FSRECD_registerW_registerZ_simple
def LVX_FsrecdOp : LVX_Op<"fsrecd", [Pure]>{
  let summary = "FSRECD -- Floating-Point Seed for Reciprocal Double Word";
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

// FPU:FSRECW -- register form, from FSRECW_registerW_registerZ_simple
def LVX_FsrecwOp : LVX_Op<"fsrecw", [Pure]>{
  let summary = "FSRECW -- Floating-Point Seed for Reciprocal Word";
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

// FPU:FSRECWP -- register form, from FSRECWP_registerW_registerZ_simple
def LVX_FsrecwpOp : LVX_Op<"fsrecwp", [Pure]>{
  let summary = "FSRECWP -- Floating-Point Seed for Reciprocal Word Pair";
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

// FPU:FSRECWQ -- register form, from FSRECWQ_registerM_registerP_simple
def LVX_FsrecwqOp : LVX_Op<"fsrecwq", [Pure]>{
  let summary = "FSRECWQ -- Floating-Point Seed for Reciprocal Word Quadruple";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FSRSRD -- register form, from FSRSRD_registerW_registerZ_simple
def LVX_FsrsrdOp : LVX_Op<"fsrsrd", [Pure]>{
  let summary = "FSRSRD -- Floating-Point Seed for Reciprocal Square Root Double Word";
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

// FPU:FSRSRW -- register form, from FSRSRW_registerW_registerZ_simple
def LVX_FsrsrwOp : LVX_Op<"fsrsrw", [Pure]>{
  let summary = "FSRSRW -- Floating-Point Seed for Reciprocal Square Root Word";
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

// FPU:FSRSRWP -- register form, from FSRSRWP_registerW_registerZ_simple
def LVX_FsrsrwpOp : LVX_Op<"fsrsrwp", [Pure]>{
  let summary = "FSRSRWP -- Floating-Point Seed for Reciprocal Square Root Word Pair";
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

// FPU:FSRSRWQ -- register form, from FSRSRWQ_registerM_registerP_simple
def LVX_FsrsrwqOp : LVX_Op<"fsrsrwq", [Pure]>{
  let summary = "FSRSRWQ -- Floating-Point Seed for Reciprocal Square Root Word Quadruple";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FCLASSD -- register form, from FCLASSD_registerW_registerZ_simple
def LVX_FclassdOp : LVX_Op<"fclassd", [Pure]>{
  let summary = "FCLASSD -- Floating-Point Classify Double Word";
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

// FPU:FCLASSDP -- register form, from FCLASSDP_registerM_registerP_simple
def LVX_FclassdpOp : LVX_Op<"fclassdp", [Pure]>{
  let summary = "FCLASSDP -- Floating-Point Classify Double Word Pair";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FCLASSW -- register form, from FCLASSW_registerW_registerZ_simple
def LVX_FclasswOp : LVX_Op<"fclassw", [Pure]>{
  let summary = "FCLASSW -- Floating-Point Classify Word";
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

// FPU:FCLASSWP -- register form, from FCLASSWP_registerW_registerZ_simple
def LVX_FclasswpOp : LVX_Op<"fclasswp", [Pure]>{
  let summary = "FCLASSWP -- Floating-Point Classify Word Pair";
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

// FPU:FCLASSWQ -- register form, from FCLASSWQ_registerM_registerP_simple
def LVX_FclasswqOp : LVX_Op<"fclasswq", [Pure]>{
  let summary = "FCLASSWQ -- Floating-Point Classify Word Quadruple";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FCLASSH -- register form, from FCLASSH_registerW_registerZ_simple
def LVX_FclasshOp : LVX_Op<"fclassh", [Pure]>{
  let summary = "FCLASSH -- Floating-Point Classify Half Word";
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

// FPU:FCLASSHO -- register form, from FCLASSHO_registerM_registerP_simple
def LVX_FclasshoOp : LVX_Op<"fclassho", [Pure]>{
  let summary = "FCLASSHO -- Floating-Point Classify Half Word Octuple";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FWIDENWD -- register form, from FWIDENWD_mostsig_registerW_registerZ_simple
def LVX_FwidenwdOp : LVX_Op<"fwidenwd", [Pure]>{
  let summary = "FWIDENWD -- Floating Point Widen Word to Double Word";
  let arguments = (ins UnitAttr:$m,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`m` $m^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FWIDENWDP -- register form, from FWIDENWDP_mostsig_registerM_registerP_simple
def LVX_FwidenwdpOp : LVX_Op<"fwidenwdp", [Pure]>{
  let summary = "FWIDENWDP -- Floating Point Widen Word to Double Word Pair";
  let arguments = (ins UnitAttr:$m,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`m` $m^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FWIDENHW -- register form, from FWIDENHW_mostsig_registerW_registerZ_simple
def LVX_FwidenhwOp : LVX_Op<"fwidenhw", [Pure]>{
  let summary = "FWIDENHW -- Floating Point Widen Half Word to Word";
  let arguments = (ins UnitAttr:$m,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`m` $m^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FWIDENHWP -- register form, from FWIDENHWP_mostsig_registerW_registerZ_simple
def LVX_FwidenhwpOp : LVX_Op<"fwidenhwp", [Pure]>{
  let summary = "FWIDENHWP -- Floating Point Widen Half Word to Word Pair";
  let arguments = (ins UnitAttr:$m,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`m` $m^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FWIDENHWQ -- register form, from FWIDENHWQ_mostsig_registerM_registerP_simple
def LVX_FwidenhwqOp : LVX_Op<"fwidenhwq", [Pure]>{
  let summary = "FWIDENHWQ -- Floating Point Widen Half Word to Word Quadruple";
  let arguments = (ins UnitAttr:$m,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`m` $m^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FEXTLHWQ -- register form, from FEXTLHWQ_oddlanes_registerM_registerP_simple
def LVX_FextlhwqOp : LVX_Op<"fextlhwq", [Pure]>{
  let summary = "FEXTLHWQ -- Floating Point Extend Lane Half Word to Word Quadruple";
  let arguments = (ins UnitAttr:$o,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`o` $o^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FNARROWDW -- register form, from FNARROWDW_floatmode_registerW_registerZ_simple
def LVX_FnarrowdwOp : LVX_Op<"fnarrowdw", [Pure]>{
  let summary = "FNARROWDW -- Floating Point Narrow Double Word to Word";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($floatmode^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, floatmode, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:FNARROWDWQ -- register form, from FNARROWDWQ_floatmode_registerM_registerR_simple
def LVX_FnarrowdwqOp : LVX_Op<"fnarrowdwq", [Pure]>{
  let summary = "FNARROWDWQ -- Floating Point Narrow Double Word to Word Quadruple";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($floatmode^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultTypes, floatmode, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FNARROWWH -- register form, from FNARROWWH_floatmode_registerW_registerZ_simple
def LVX_FnarrowwhOp : LVX_Op<"fnarrowwh", [Pure]>{
  let summary = "FNARROWWH -- Floating Point Narrow Word to Half Word";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($floatmode^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, floatmode, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:FNARROWWHO -- register form, from FNARROWWHO_floatmode_registerM_registerR_simple
def LVX_FnarrowwhoOp : LVX_Op<"fnarrowwho", [Pure]>{
  let summary = "FNARROWWHO -- Floating Point Narrow Word to Half Word Octuple";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($floatmode^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultTypes, floatmode, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:INSF -- immediate form, from INSF_registerW_registerZ_stopbit2_stopbit4_startbit_simple
def LVX_InsfImmOp : LVX_Op<"insf", [Pure]>{
  let summary = "INSF -- Insert Bit Field into Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$stopbit2_stopbit4,
                       TypedAttrInterface:$startbit,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $stopbit2_stopbit4 `,` $startbit `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs, "::mlir::TypedAttr":$stopbit2_stopbit4, "::mlir::TypedAttr":$startbit), [{
      build($_builder, $_state, resultType, lhs, rhs, stopbit2_stopbit4, startbit, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "$operand `,` $stopbit2_stopbit4 `,` $startbit attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
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
  let assemblyFormat = "$operand `,` $stopbit2_stopbit4 `,` $startbit attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
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
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$intcomp $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
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
  let assemblyFormat = "$intcomp $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
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
  let assemblyFormat = "(`sx` $sx^)? $intcomp $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::lvx::IntComp":$intcomp, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::lvx::IntCompAttr::get($_builder.getContext(), intcomp), ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:COMPDP -- register form, from COMPDP_intcomp_registerW_registerP_registerO_simple
def LVX_CompdpOp : LVX_Op<"compdp", [Pure]>{
  let summary = "COMPDP -- Compare Double Word Pair";
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

// ALU:COMPDP -- immediate form, from COMPDP_intcomp_registerW_registerP_upper27_lower5_splat32_double
def LVX_CompdpImmOp : LVX_Op<"compdp_i", [Pure]>{
  let summary = "COMPDP -- Compare Double Word Pair";
  let arguments = (ins LVX_IntCompAttr:$intcomp,
                       UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`splat32` $splat32^)? $intcomp $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::lvx::IntComp":$intcomp, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::lvx::IntCompAttr::get($_builder.getContext(), intcomp), ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:COMPWQ -- register form, from COMPWQ_intcomp_registerW_registerP_registerO_simple
def LVX_CompwqOp : LVX_Op<"compwq", [Pure]>{
  let summary = "COMPWQ -- Compare Word Quadruple";
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

// ALU:COMPWQ -- immediate form, from COMPWQ_intcomp_registerW_registerP_upper27_lower5_splat32_double
def LVX_CompwqImmOp : LVX_Op<"compwq_i", [Pure]>{
  let summary = "COMPWQ -- Compare Word Quadruple";
  let arguments = (ins LVX_IntCompAttr:$intcomp,
                       UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`splat32` $splat32^)? $intcomp $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::lvx::IntComp":$intcomp, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::lvx::IntCompAttr::get($_builder.getContext(), intcomp), ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:COMPHO -- register form, from COMPHO_intcomp_registerW_registerP_registerO_simple
def LVX_ComphoOp : LVX_Op<"compho", [Pure]>{
  let summary = "COMPHO -- Compare Half Word Octuple";
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

// ALU:COMPHO -- immediate form, from COMPHO_intcomp_registerW_registerP_upper27_lower5_splat32_double
def LVX_ComphoImmOp : LVX_Op<"compho_i", [Pure]>{
  let summary = "COMPHO -- Compare Half Word Octuple";
  let arguments = (ins LVX_IntCompAttr:$intcomp,
                       UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`splat32` $splat32^)? $intcomp $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::lvx::IntComp":$intcomp, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::lvx::IntCompAttr::get($_builder.getContext(), intcomp), ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:COMPBX -- register form, from COMPBX_intcomp_registerW_registerP_registerO_simple
def LVX_CompbxOp : LVX_Op<"compbx", [Pure]>{
  let summary = "COMPBX -- Compare Byte Hexadecuple";
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

// ALU:COMPBX -- immediate form, from COMPBX_intcomp_registerW_registerP_upper27_lower5_splat32_double
def LVX_CompbxImmOp : LVX_Op<"compbx_i", [Pure]>{
  let summary = "COMPBX -- Compare Byte Hexadecuple";
  let arguments = (ins LVX_IntCompAttr:$intcomp,
                       UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`splat32` $splat32^)? $intcomp $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::lvx::IntComp":$intcomp, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::lvx::IntCompAttr::get($_builder.getContext(), intcomp), ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:COMPNDP -- register form, from COMPNDP_intcomp_registerM_registerP_registerO_simple
def LVX_CompndpOp : LVX_Op<"compndp", [Pure]>{
  let summary = "COMPNDP -- Compare Negate Double Word Pair";
  let arguments = (ins LVX_IntCompAttr:$intcomp,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$intcomp $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::lvx::IntComp":$intcomp, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, ::mlir::lvx::IntCompAttr::get($_builder.getContext(), intcomp), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:COMPNDP -- immediate form, from COMPNDP_intcomp_registerM_registerP_upper27_lower5_splat32_double
def LVX_CompndpImmOp : LVX_Op<"compndp_i", [Pure]>{
  let summary = "COMPNDP -- Compare Negate Double Word Pair";
  let arguments = (ins LVX_IntCompAttr:$intcomp,
                       UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $intcomp $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::lvx::IntComp":$intcomp, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::lvx::IntCompAttr::get($_builder.getContext(), intcomp), ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:COMPNWQ -- register form, from COMPNWQ_intcomp_registerM_registerP_registerO_simple
def LVX_CompnwqOp : LVX_Op<"compnwq", [Pure]>{
  let summary = "COMPNWQ -- Compare Negate Word Quadruple";
  let arguments = (ins LVX_IntCompAttr:$intcomp,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$intcomp $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::lvx::IntComp":$intcomp, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, ::mlir::lvx::IntCompAttr::get($_builder.getContext(), intcomp), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:COMPNWQ -- immediate form, from COMPNWQ_intcomp_registerM_registerP_upper27_lower5_splat32_double
def LVX_CompnwqImmOp : LVX_Op<"compnwq_i", [Pure]>{
  let summary = "COMPNWQ -- Compare Negate Word Quadruple";
  let arguments = (ins LVX_IntCompAttr:$intcomp,
                       UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $intcomp $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::lvx::IntComp":$intcomp, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::lvx::IntCompAttr::get($_builder.getContext(), intcomp), ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:COMPNHO -- register form, from COMPNHO_intcomp_registerM_registerP_registerO_simple
def LVX_CompnhoOp : LVX_Op<"compnho", [Pure]>{
  let summary = "COMPNHO -- Compare Negate Half Word Octuple";
  let arguments = (ins LVX_IntCompAttr:$intcomp,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$intcomp $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::lvx::IntComp":$intcomp, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, ::mlir::lvx::IntCompAttr::get($_builder.getContext(), intcomp), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:COMPNHO -- immediate form, from COMPNHO_intcomp_registerM_registerP_upper27_lower5_splat32_double
def LVX_CompnhoImmOp : LVX_Op<"compnho_i", [Pure]>{
  let summary = "COMPNHO -- Compare Negate Half Word Octuple";
  let arguments = (ins LVX_IntCompAttr:$intcomp,
                       UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $intcomp $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::lvx::IntComp":$intcomp, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::lvx::IntCompAttr::get($_builder.getContext(), intcomp), ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:COMPNBX -- register form, from COMPNBX_intcomp_registerM_registerP_registerO_simple
def LVX_CompnbxOp : LVX_Op<"compnbx", [Pure]>{
  let summary = "COMPNBX -- Compare Negate Byte Hexadecuple";
  let arguments = (ins LVX_IntCompAttr:$intcomp,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$intcomp $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::lvx::IntComp":$intcomp, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, ::mlir::lvx::IntCompAttr::get($_builder.getContext(), intcomp), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:COMPNBX -- immediate form, from COMPNBX_intcomp_registerM_registerP_upper27_lower5_splat32_double
def LVX_CompnbxImmOp : LVX_Op<"compnbx_i", [Pure]>{
  let summary = "COMPNBX -- Compare Negate Byte Hexadecuple";
  let arguments = (ins LVX_IntCompAttr:$intcomp,
                       UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $intcomp $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::lvx::IntComp":$intcomp, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::lvx::IntCompAttr::get($_builder.getContext(), intcomp), ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
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
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$cmovecond $test `,` $trueValue `,` $falseValue attr-dict `:` `(` qualified(type($test)) `,` qualified(type($trueValue)) `,` qualified(type($falseValue)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
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
                       LVX_RegType:$falseValue,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`splat32` $splat32^)? $cmovecond $test `,` $upper27_lower5 `,` $falseValue attr-dict `:` `(` qualified(type($test)) `,` qualified(type($falseValue)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::lvx::BcuCond":$cmovecond, "::mlir::Value":$test, "::mlir::Value":$falseValue, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::lvx::BcuCondAttr::get($_builder.getContext(), cmovecond), ::mlir::UnitAttr(), test, falseValue, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:CMOVEDP -- register form, from CMOVEDP_lanecond_registerP_registerM_registerO_simple
def LVX_CmovedpOp : LVX_Op<"cmovedp", [Pure]>{
  let summary = "CMOVEDP -- Conditional Move Double Word Pair";
  let arguments = (ins LVX_LaneCondAttr:$lanecond,
                       LVX_RegType:$test,
                       LVX_RegType:$trueValue,
                       LVX_RegType:$falseValue,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lanecond $test `,` $trueValue `,` $falseValue attr-dict `:` `(` qualified(type($test)) `,` qualified(type($trueValue)) `,` qualified(type($falseValue)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::lvx::LaneCond":$lanecond, "::mlir::Value":$test, "::mlir::Value":$trueValue, "::mlir::Value":$falseValue), [{
      build($_builder, $_state, resultTypes, ::mlir::lvx::LaneCondAttr::get($_builder.getContext(), lanecond), test, trueValue, falseValue, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:CMOVEDP -- immediate form, from CMOVEDP_lanecond_registerP_registerM_upper27_lower5_splat32_double
def LVX_CmovedpImmOp : LVX_Op<"cmovedp_i", [Pure]>{
  let summary = "CMOVEDP -- Conditional Move Double Word Pair";
  let arguments = (ins LVX_LaneCondAttr:$lanecond,
                       UnitAttr:$splat32,
                       LVX_RegType:$test,
                       LVX_RegType:$falseValue,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $lanecond $test `,` $upper27_lower5 `,` $falseValue attr-dict `:` `(` qualified(type($test)) `,` qualified(type($falseValue)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::lvx::LaneCond":$lanecond, "::mlir::Value":$test, "::mlir::Value":$falseValue, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::lvx::LaneCondAttr::get($_builder.getContext(), lanecond), ::mlir::UnitAttr(), test, falseValue, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:CMOVEWQ -- register form, from CMOVEWQ_lanecond_registerP_registerM_registerO_simple
def LVX_CmovewqOp : LVX_Op<"cmovewq", [Pure]>{
  let summary = "CMOVEWQ -- Conditional Move Word Quadruple";
  let arguments = (ins LVX_LaneCondAttr:$lanecond,
                       LVX_RegType:$test,
                       LVX_RegType:$trueValue,
                       LVX_RegType:$falseValue,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lanecond $test `,` $trueValue `,` $falseValue attr-dict `:` `(` qualified(type($test)) `,` qualified(type($trueValue)) `,` qualified(type($falseValue)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::lvx::LaneCond":$lanecond, "::mlir::Value":$test, "::mlir::Value":$trueValue, "::mlir::Value":$falseValue), [{
      build($_builder, $_state, resultTypes, ::mlir::lvx::LaneCondAttr::get($_builder.getContext(), lanecond), test, trueValue, falseValue, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:CMOVEWQ -- immediate form, from CMOVEWQ_lanecond_registerP_registerM_upper27_lower5_splat32_double
def LVX_CmovewqImmOp : LVX_Op<"cmovewq_i", [Pure]>{
  let summary = "CMOVEWQ -- Conditional Move Word Quadruple";
  let arguments = (ins LVX_LaneCondAttr:$lanecond,
                       UnitAttr:$splat32,
                       LVX_RegType:$test,
                       LVX_RegType:$falseValue,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $lanecond $test `,` $upper27_lower5 `,` $falseValue attr-dict `:` `(` qualified(type($test)) `,` qualified(type($falseValue)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::lvx::LaneCond":$lanecond, "::mlir::Value":$test, "::mlir::Value":$falseValue, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::lvx::LaneCondAttr::get($_builder.getContext(), lanecond), ::mlir::UnitAttr(), test, falseValue, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:CMOVEHO -- register form, from CMOVEHO_lanecond_registerP_registerM_registerO_simple
def LVX_CmovehoOp : LVX_Op<"cmoveho", [Pure]>{
  let summary = "CMOVEHO -- Conditional Move Half Word Octuple";
  let arguments = (ins LVX_LaneCondAttr:$lanecond,
                       LVX_RegType:$test,
                       LVX_RegType:$trueValue,
                       LVX_RegType:$falseValue,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lanecond $test `,` $trueValue `,` $falseValue attr-dict `:` `(` qualified(type($test)) `,` qualified(type($trueValue)) `,` qualified(type($falseValue)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::lvx::LaneCond":$lanecond, "::mlir::Value":$test, "::mlir::Value":$trueValue, "::mlir::Value":$falseValue), [{
      build($_builder, $_state, resultTypes, ::mlir::lvx::LaneCondAttr::get($_builder.getContext(), lanecond), test, trueValue, falseValue, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:CMOVEHO -- immediate form, from CMOVEHO_lanecond_registerP_registerM_upper27_lower5_splat32_double
def LVX_CmovehoImmOp : LVX_Op<"cmoveho_i", [Pure]>{
  let summary = "CMOVEHO -- Conditional Move Half Word Octuple";
  let arguments = (ins LVX_LaneCondAttr:$lanecond,
                       UnitAttr:$splat32,
                       LVX_RegType:$test,
                       LVX_RegType:$falseValue,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $lanecond $test `,` $upper27_lower5 `,` $falseValue attr-dict `:` `(` qualified(type($test)) `,` qualified(type($falseValue)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::lvx::LaneCond":$lanecond, "::mlir::Value":$test, "::mlir::Value":$falseValue, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::lvx::LaneCondAttr::get($_builder.getContext(), lanecond), ::mlir::UnitAttr(), test, falseValue, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:CMOVEBX -- register form, from CMOVEBX_lanecond_registerP_registerM_registerO_simple
def LVX_CmovebxOp : LVX_Op<"cmovebx", [Pure]>{
  let summary = "CMOVEBX -- Conditional Move Byte Hexadecuple";
  let arguments = (ins LVX_LaneCondAttr:$lanecond,
                       LVX_RegType:$test,
                       LVX_RegType:$trueValue,
                       LVX_RegType:$falseValue,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lanecond $test `,` $trueValue `,` $falseValue attr-dict `:` `(` qualified(type($test)) `,` qualified(type($trueValue)) `,` qualified(type($falseValue)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::lvx::LaneCond":$lanecond, "::mlir::Value":$test, "::mlir::Value":$trueValue, "::mlir::Value":$falseValue), [{
      build($_builder, $_state, resultTypes, ::mlir::lvx::LaneCondAttr::get($_builder.getContext(), lanecond), test, trueValue, falseValue, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:CMOVEBX -- immediate form, from CMOVEBX_lanecond_registerP_registerM_upper27_lower5_splat32_double
def LVX_CmovebxImmOp : LVX_Op<"cmovebx_i", [Pure]>{
  let summary = "CMOVEBX -- Conditional Move Byte Hexadecuple";
  let arguments = (ins LVX_LaneCondAttr:$lanecond,
                       UnitAttr:$splat32,
                       LVX_RegType:$test,
                       LVX_RegType:$falseValue,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $lanecond $test `,` $upper27_lower5 `,` $falseValue attr-dict `:` `(` qualified(type($test)) `,` qualified(type($falseValue)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::lvx::LaneCond":$lanecond, "::mlir::Value":$test, "::mlir::Value":$falseValue, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::lvx::LaneCondAttr::get($_builder.getContext(), lanecond), ::mlir::UnitAttr(), test, falseValue, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MAKED -- immediate form, from MAKED_registerW_signed16_simple
def LVX_MakedImmOp : LVX_Op<"maked", [Pure]>{
  let summary = "MAKED -- Make Double Word from Immediate";
  let arguments = (ins TypedAttrInterface:$signed16,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$signed16 attr-dict `:` `(`  `)` `->` qualified(type($result))";
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
  let assemblyFormat = "$signed16 attr-dict `:` `(`  `)` `->` qualified(type($result))";
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
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
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
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
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

// ALU:NEGDP -- register form, from NEGDP_registerM_registerP_simple
def LVX_NegdpOp : LVX_Op<"negdp", [Pure]>{
  let summary = "NEGDP -- Negate Double Word Pair";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
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

// ALU:NEGWQ -- register form, from NEGWQ_registerM_registerP_simple
def LVX_NegwqOp : LVX_Op<"negwq", [Pure]>{
  let summary = "NEGWQ -- Negate Word Quadruple";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:NEGHO -- register form, from NEGHO_registerM_registerP_simple
def LVX_NeghoOp : LVX_Op<"negho", [Pure]>{
  let summary = "NEGHO -- Negate Half Word Octuple";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:NEGBX -- register form, from NEGBX_registerM_registerP_simple
def LVX_NegbxOp : LVX_Op<"negbx", [Pure]>{
  let summary = "NEGBX -- Negate Byte Hexadecuple";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
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

// ALU:NEGSDP -- register form, from NEGSDP_registerM_registerP_simple
def LVX_NegsdpOp : LVX_Op<"negsdp", [Pure]>{
  let summary = "NEGSDP -- Negate Saturated Double Word Pair";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
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

// ALU:NEGSWQ -- register form, from NEGSWQ_registerM_registerP_simple
def LVX_NegswqOp : LVX_Op<"negswq", [Pure]>{
  let summary = "NEGSWQ -- Negate Saturated Word Quadruple";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:NEGSHO -- register form, from NEGSHO_registerM_registerP_simple
def LVX_NegshoOp : LVX_Op<"negsho", [Pure]>{
  let summary = "NEGSHO -- Negate Saturated Half Word Octuple";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:NEGSBX -- register form, from NEGSBX_registerM_registerP_simple
def LVX_NegsbxOp : LVX_Op<"negsbx", [Pure]>{
  let summary = "NEGSBX -- Negate Saturated Byte Hexadecuple";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
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

// ALU:ABSDP -- register form, from ABSDP_registerM_registerP_simple
def LVX_AbsdpOp : LVX_Op<"absdp", [Pure]>{
  let summary = "ABSDP -- Absolute Value Double Word Pair";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
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

// ALU:ABSWQ -- register form, from ABSWQ_registerM_registerP_simple
def LVX_AbswqOp : LVX_Op<"abswq", [Pure]>{
  let summary = "ABSWQ -- Absolute Value Word Quadruple";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ABSHO -- register form, from ABSHO_registerM_registerP_simple
def LVX_AbshoOp : LVX_Op<"absho", [Pure]>{
  let summary = "ABSHO -- Absolute Value Half Word Octuple";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ABSBX -- register form, from ABSBX_registerM_registerP_simple
def LVX_AbsbxOp : LVX_Op<"absbx", [Pure]>{
  let summary = "ABSBX -- Absolute Value Byte Hexadecuple";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
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

// ALU:ABSSDP -- register form, from ABSSDP_registerM_registerP_simple
def LVX_AbssdpOp : LVX_Op<"abssdp", [Pure]>{
  let summary = "ABSSDP -- Absolute Value Saturated Double Word Pair";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
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

// ALU:ABSSWQ -- register form, from ABSSWQ_registerM_registerP_simple
def LVX_AbsswqOp : LVX_Op<"absswq", [Pure]>{
  let summary = "ABSSWQ -- Absolute Value Saturated Word Quadruple";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ABSSHO -- register form, from ABSSHO_registerM_registerP_simple
def LVX_AbsshoOp : LVX_Op<"abssho", [Pure]>{
  let summary = "ABSSHO -- Absolute Value Saturated Half Word Octuple";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:ABSSBX -- register form, from ABSSBX_registerM_registerP_simple
def LVX_AbssbxOp : LVX_Op<"abssbx", [Pure]>{
  let summary = "ABSSBX -- Absolute Value Saturated Byte Hexadecuple";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
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

// ALU:CLZDP -- register form, from CLZDP_registerM_registerP_simple
def LVX_ClzdpOp : LVX_Op<"clzdp", [Pure]>{
  let summary = "CLZDP -- Count Leading Zeroes Double Word Pair";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
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

// ALU:CLZWQ -- register form, from CLZWQ_registerM_registerP_simple
def LVX_ClzwqOp : LVX_Op<"clzwq", [Pure]>{
  let summary = "CLZWQ -- Count Leading Zeroes Word Quadruple";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:CLZHO -- register form, from CLZHO_registerM_registerP_simple
def LVX_ClzhoOp : LVX_Op<"clzho", [Pure]>{
  let summary = "CLZHO -- Count Leading Zeroes Half Word Octuple";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
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

// ALU:CLSDP -- register form, from CLSDP_registerM_registerP_simple
def LVX_ClsdpOp : LVX_Op<"clsdp", [Pure]>{
  let summary = "CLSDP -- Count Leading Signs Double Word Pair";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
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

// ALU:CLSWQ -- register form, from CLSWQ_registerM_registerP_simple
def LVX_ClswqOp : LVX_Op<"clswq", [Pure]>{
  let summary = "CLSWQ -- Count Leading Signs Word Quadruple";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:CLSHO -- register form, from CLSHO_registerM_registerP_simple
def LVX_ClshoOp : LVX_Op<"clsho", [Pure]>{
  let summary = "CLSHO -- Count Leading Signs Half Word Octuple";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
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

// ALU:CBSDP -- register form, from CBSDP_registerM_registerP_simple
def LVX_CbsdpOp : LVX_Op<"cbsdp", [Pure]>{
  let summary = "CBSDP -- Count Bit Sets Double Word Pair";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
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

// ALU:CBSWQ -- register form, from CBSWQ_registerM_registerP_simple
def LVX_CbswqOp : LVX_Op<"cbswq", [Pure]>{
  let summary = "CBSWQ -- Count Bit Sets Word Quadruple";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:CBSHO -- register form, from CBSHO_registerM_registerP_simple
def LVX_CbshoOp : LVX_Op<"cbsho", [Pure]>{
  let summary = "CBSHO -- Count Bit Sets Half Word Octuple";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
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

// ALU:CTZDP -- register form, from CTZDP_registerM_registerP_simple
def LVX_CtzdpOp : LVX_Op<"ctzdp", [Pure]>{
  let summary = "CTZDP -- Count Trailing Zeroes Double Word Pair";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
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

// ALU:CTZWQ -- register form, from CTZWQ_registerM_registerP_simple
def LVX_CtzwqOp : LVX_Op<"ctzwq", [Pure]>{
  let summary = "CTZWQ -- Count Trailing Zeroes Word Quadruple";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:CTZHO -- register form, from CTZHO_registerM_registerP_simple
def LVX_CtzhoOp : LVX_Op<"ctzho", [Pure]>{
  let summary = "CTZHO -- Count Trailing Zeroes Half Word Octuple";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:WIDENZWDP -- register form, from WIDENZWDP_mostsig_registerM_registerP_simple
def LVX_WidenzwdpOp : LVX_Op<"widenzwdp", [Pure]>{
  let summary = "WIDENZWDP -- Zero Widen Word to Double Word Pair";
  let arguments = (ins UnitAttr:$m,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`m` $m^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:WIDENZHWQ -- register form, from WIDENZHWQ_mostsig_registerM_registerP_simple
def LVX_WidenzhwqOp : LVX_Op<"widenzhwq", [Pure]>{
  let summary = "WIDENZHWQ -- Zero Widen Half Word to Word Quadruple";
  let arguments = (ins UnitAttr:$m,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`m` $m^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:WIDENZBHO -- register form, from WIDENZBHO_mostsig_registerM_registerP_simple
def LVX_WidenzbhoOp : LVX_Op<"widenzbho", [Pure]>{
  let summary = "WIDENZBHO -- Zero Widen Byte to Half Word Octuple";
  let arguments = (ins UnitAttr:$m,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`m` $m^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:WIDENSWDP -- register form, from WIDENSWDP_mostsig_registerM_registerP_simple
def LVX_WidenswdpOp : LVX_Op<"widenswdp", [Pure]>{
  let summary = "WIDENSWDP -- Sign Widen Word to Double Word Pair";
  let arguments = (ins UnitAttr:$m,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`m` $m^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:WIDENSHWQ -- register form, from WIDENSHWQ_mostsig_registerM_registerP_simple
def LVX_WidenshwqOp : LVX_Op<"widenshwq", [Pure]>{
  let summary = "WIDENSHWQ -- Sign Widen Half Word to Word Quadruple";
  let arguments = (ins UnitAttr:$m,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`m` $m^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:WIDENSBHO -- register form, from WIDENSBHO_mostsig_registerM_registerP_simple
def LVX_WidensbhoOp : LVX_Op<"widensbho", [Pure]>{
  let summary = "WIDENSBHO -- Sign Widen Byte to Half Word Octuple";
  let arguments = (ins UnitAttr:$m,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`m` $m^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:WIDENQWDP -- register form, from WIDENQWDP_mostsig_registerM_registerP_simple
def LVX_WidenqwdpOp : LVX_Op<"widenqwdp", [Pure]>{
  let summary = "WIDENQWDP -- Widen Q31 Word to Double Word Pair";
  let arguments = (ins UnitAttr:$m,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`m` $m^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:WIDENQHWQ -- register form, from WIDENQHWQ_mostsig_registerM_registerP_simple
def LVX_WidenqhwqOp : LVX_Op<"widenqhwq", [Pure]>{
  let summary = "WIDENQHWQ -- Widen Q15 Half Word to Word Quadruple";
  let arguments = (ins UnitAttr:$m,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`m` $m^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:WIDENQBHO -- register form, from WIDENQBHO_mostsig_registerM_registerP_simple
def LVX_WidenqbhoOp : LVX_Op<"widenqbho", [Pure]>{
  let summary = "WIDENQBHO -- Widen Q7 Byte to Half Word Octuple";
  let arguments = (ins UnitAttr:$m,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`m` $m^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:EXTLZWDP -- register form, from EXTLZWDP_oddlanes_registerM_registerP_simple
def LVX_ExtlzwdpOp : LVX_Op<"extlzwdp", [Pure]>{
  let summary = "EXTLZWDP -- Extend Lane with Zero Word to Double Word Pair";
  let arguments = (ins UnitAttr:$o,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`o` $o^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:EXTLZHWQ -- register form, from EXTLZHWQ_oddlanes_registerM_registerP_simple
def LVX_ExtlzhwqOp : LVX_Op<"extlzhwq", [Pure]>{
  let summary = "EXTLZHWQ -- Extend Lane with Zero Half Word to Word Quadruple";
  let arguments = (ins UnitAttr:$o,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`o` $o^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:EXTLZBHO -- register form, from EXTLZBHO_oddlanes_registerM_registerP_simple
def LVX_ExtlzbhoOp : LVX_Op<"extlzbho", [Pure]>{
  let summary = "EXTLZBHO -- Extend Lane with Zero Byte to Half Word Octuple";
  let arguments = (ins UnitAttr:$o,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`o` $o^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:EXTLZNBX -- register form, from EXTLZNBX_oddlanes_registerM_registerP_simple
def LVX_ExtlznbxOp : LVX_Op<"extlznbx", [Pure]>{
  let summary = "EXTLZNBX -- Extend Lane with Zero Nibble to Byte Hexadecuple";
  let arguments = (ins UnitAttr:$o,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`o` $o^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:EXTLSWDP -- register form, from EXTLSWDP_oddlanes_registerM_registerP_simple
def LVX_ExtlswdpOp : LVX_Op<"extlswdp", [Pure]>{
  let summary = "EXTLSWDP -- Extend Lane with Sign Word to Double Word Pair";
  let arguments = (ins UnitAttr:$o,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`o` $o^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:EXTLSHWQ -- register form, from EXTLSHWQ_oddlanes_registerM_registerP_simple
def LVX_ExtlshwqOp : LVX_Op<"extlshwq", [Pure]>{
  let summary = "EXTLSHWQ -- Extend Lane with Sign Half Word to Word Quadruple";
  let arguments = (ins UnitAttr:$o,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`o` $o^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:EXTLSBHO -- register form, from EXTLSBHO_oddlanes_registerM_registerP_simple
def LVX_ExtlsbhoOp : LVX_Op<"extlsbho", [Pure]>{
  let summary = "EXTLSBHO -- Extend Lane with Sign Byte to Half Word Octuple";
  let arguments = (ins UnitAttr:$o,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`o` $o^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:EXTLSNBX -- register form, from EXTLSNBX_oddlanes_registerM_registerP_simple
def LVX_ExtlsnbxOp : LVX_Op<"extlsnbx", [Pure]>{
  let summary = "EXTLSNBX -- Extend Lane with Sign Nibble to Byte Hexadecuple";
  let arguments = (ins UnitAttr:$o,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`o` $o^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:EXTLQWDP -- register form, from EXTLQWDP_oddlanes_registerM_registerP_simple
def LVX_ExtlqwdpOp : LVX_Op<"extlqwdp", [Pure]>{
  let summary = "EXTLQWDP -- Extend Lane Q31 Word to Double Word Pair";
  let arguments = (ins UnitAttr:$o,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`o` $o^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:EXTLQHWQ -- register form, from EXTLQHWQ_oddlanes_registerM_registerP_simple
def LVX_ExtlqhwqOp : LVX_Op<"extlqhwq", [Pure]>{
  let summary = "EXTLQHWQ -- Extend Lane Q15 Half Word to Word Quadruple";
  let arguments = (ins UnitAttr:$o,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`o` $o^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:EXTLQBHO -- register form, from EXTLQBHO_oddlanes_registerM_registerP_simple
def LVX_ExtlqbhoOp : LVX_Op<"extlqbho", [Pure]>{
  let summary = "EXTLQBHO -- Extend Lane Q7 Byte to Half Word Octuple";
  let arguments = (ins UnitAttr:$o,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`o` $o^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:EXTLQNBX -- register form, from EXTLQNBX_oddlanes_registerM_registerP_simple
def LVX_ExtlqnbxOp : LVX_Op<"extlqnbx", [Pure]>{
  let summary = "EXTLQNBX -- Extend Lane Q3 Nibble to Byte Hexadecuple";
  let arguments = (ins UnitAttr:$o,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`o` $o^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FCOMPD -- register form, from FCOMPD_floatcomp_registerW_registerZ_registerY_simple
def LVX_FcompdOp : LVX_Op<"fcompd", [Pure]>{
  let summary = "FCOMPD -- Floating-Point Compare Double Word";
  let arguments = (ins LVX_FloatCompAttr:$floatcomp,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$floatcomp $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::lvx::FloatComp":$floatcomp, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::lvx::FloatCompAttr::get($_builder.getContext(), floatcomp), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FCOMPD -- immediate form, from FCOMPD_floatcomp_registerW_registerZ_upper27_lower5_double
def LVX_FcompdImmOp : LVX_Op<"fcompd_i", [Pure]>{
  let summary = "FCOMPD -- Floating-Point Compare Double Word";
  let arguments = (ins LVX_FloatCompAttr:$floatcomp,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$floatcomp $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::lvx::FloatComp":$floatcomp, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::lvx::FloatCompAttr::get($_builder.getContext(), floatcomp), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FCOMPDP -- register form, from FCOMPDP_floatcomp_registerW_registerP_registerO_simple
def LVX_FcompdpOp : LVX_Op<"fcompdp", [Pure]>{
  let summary = "FCOMPDP -- Floating-Point Compare Double Word Pair";
  let arguments = (ins LVX_FloatCompAttr:$floatcomp,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$floatcomp $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::lvx::FloatComp":$floatcomp, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::lvx::FloatCompAttr::get($_builder.getContext(), floatcomp), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FCOMPDP -- immediate form, from FCOMPDP_floatcomp_registerW_registerP_upper27_lower5_splat32_double
def LVX_FcompdpImmOp : LVX_Op<"fcompdp_i", [Pure]>{
  let summary = "FCOMPDP -- Floating-Point Compare Double Word Pair";
  let arguments = (ins LVX_FloatCompAttr:$floatcomp,
                       UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`splat32` $splat32^)? $floatcomp $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::lvx::FloatComp":$floatcomp, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::lvx::FloatCompAttr::get($_builder.getContext(), floatcomp), ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FCOMPW -- register form, from FCOMPW_floatcomp_registerW_registerZ_registerY_simple
def LVX_FcompwOp : LVX_Op<"fcompw", [Pure]>{
  let summary = "FCOMPW -- Floating-Point Compare Word";
  let arguments = (ins LVX_FloatCompAttr:$floatcomp,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$floatcomp $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::lvx::FloatComp":$floatcomp, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::lvx::FloatCompAttr::get($_builder.getContext(), floatcomp), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FCOMPW -- immediate form, from FCOMPW_floatcomp_registerW_registerZ_upper27_lower5_double
def LVX_FcompwImmOp : LVX_Op<"fcompw_i", [Pure]>{
  let summary = "FCOMPW -- Floating-Point Compare Word";
  let arguments = (ins LVX_FloatCompAttr:$floatcomp,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$floatcomp $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::lvx::FloatComp":$floatcomp, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::lvx::FloatCompAttr::get($_builder.getContext(), floatcomp), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:FCOMPWQ -- register form, from FCOMPWQ_floatcomp_registerW_registerP_registerO_simple
def LVX_FcompwqOp : LVX_Op<"fcompwq", [Pure]>{
  let summary = "FCOMPWQ -- Floating-Point Compare Word Quadruple";
  let arguments = (ins LVX_FloatCompAttr:$floatcomp,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$floatcomp $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::lvx::FloatComp":$floatcomp, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::lvx::FloatCompAttr::get($_builder.getContext(), floatcomp), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:FCOMPWQ -- immediate form, from FCOMPWQ_floatcomp_registerW_registerP_upper27_lower5_splat32_double
def LVX_FcompwqImmOp : LVX_Op<"fcompwq_i", [Pure]>{
  let summary = "FCOMPWQ -- Floating-Point Compare Word Quadruple";
  let arguments = (ins LVX_FloatCompAttr:$floatcomp,
                       UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`splat32` $splat32^)? $floatcomp $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::lvx::FloatComp":$floatcomp, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::lvx::FloatCompAttr::get($_builder.getContext(), floatcomp), ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FCOMPH -- register form, from FCOMPH_floatcomp_registerW_registerZ_registerY_simple
def LVX_FcomphOp : LVX_Op<"fcomph", [Pure]>{
  let summary = "FCOMPH -- Floating-Point Compare Half Word";
  let arguments = (ins LVX_FloatCompAttr:$floatcomp,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$floatcomp $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::lvx::FloatComp":$floatcomp, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::lvx::FloatCompAttr::get($_builder.getContext(), floatcomp), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FCOMPH -- immediate form, from FCOMPH_floatcomp_registerW_registerZ_upper27_lower5_double
def LVX_FcomphImmOp : LVX_Op<"fcomph_i", [Pure]>{
  let summary = "FCOMPH -- Floating-Point Compare Half Word";
  let arguments = (ins LVX_FloatCompAttr:$floatcomp,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$floatcomp $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::lvx::FloatComp":$floatcomp, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::lvx::FloatCompAttr::get($_builder.getContext(), floatcomp), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:FCOMPHO -- register form, from FCOMPHO_floatcomp_registerW_registerP_registerO_simple
def LVX_FcomphoOp : LVX_Op<"fcompho", [Pure]>{
  let summary = "FCOMPHO -- Floating-Point Compare Half Word Octuple";
  let arguments = (ins LVX_FloatCompAttr:$floatcomp,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$floatcomp $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::lvx::FloatComp":$floatcomp, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultType, ::mlir::lvx::FloatCompAttr::get($_builder.getContext(), floatcomp), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:FCOMPHO -- immediate form, from FCOMPHO_floatcomp_registerW_registerP_upper27_lower5_splat32_double
def LVX_FcomphoImmOp : LVX_Op<"fcompho_i", [Pure]>{
  let summary = "FCOMPHO -- Floating-Point Compare Half Word Octuple";
  let arguments = (ins LVX_FloatCompAttr:$floatcomp,
                       UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`splat32` $splat32^)? $floatcomp $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::lvx::FloatComp":$floatcomp, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, ::mlir::lvx::FloatCompAttr::get($_builder.getContext(), floatcomp), ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FCOMPNDP -- register form, from FCOMPNDP_floatcomp_registerM_registerP_registerO_simple
def LVX_FcompndpOp : LVX_Op<"fcompndp", [Pure]>{
  let summary = "FCOMPNDP -- Floating-Point Compare Negate Double Word Pair";
  let arguments = (ins LVX_FloatCompAttr:$floatcomp,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$floatcomp $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::lvx::FloatComp":$floatcomp, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, ::mlir::lvx::FloatCompAttr::get($_builder.getContext(), floatcomp), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FCOMPNDP -- immediate form, from FCOMPNDP_floatcomp_registerM_registerP_upper27_lower5_splat32_double
def LVX_FcompndpImmOp : LVX_Op<"fcompndp_i", [Pure]>{
  let summary = "FCOMPNDP -- Floating-Point Compare Negate Double Word Pair";
  let arguments = (ins LVX_FloatCompAttr:$floatcomp,
                       UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $floatcomp $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::lvx::FloatComp":$floatcomp, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::lvx::FloatCompAttr::get($_builder.getContext(), floatcomp), ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FCOMPNWQ -- register form, from FCOMPNWQ_floatcomp_registerM_registerP_registerO_simple
def LVX_FcompnwqOp : LVX_Op<"fcompnwq", [Pure]>{
  let summary = "FCOMPNWQ -- Floating-Point Compare Negate Word Quadruple";
  let arguments = (ins LVX_FloatCompAttr:$floatcomp,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$floatcomp $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::lvx::FloatComp":$floatcomp, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, ::mlir::lvx::FloatCompAttr::get($_builder.getContext(), floatcomp), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FCOMPNWQ -- immediate form, from FCOMPNWQ_floatcomp_registerM_registerP_upper27_lower5_splat32_double
def LVX_FcompnwqImmOp : LVX_Op<"fcompnwq_i", [Pure]>{
  let summary = "FCOMPNWQ -- Floating-Point Compare Negate Word Quadruple";
  let arguments = (ins LVX_FloatCompAttr:$floatcomp,
                       UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $floatcomp $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::lvx::FloatComp":$floatcomp, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::lvx::FloatCompAttr::get($_builder.getContext(), floatcomp), ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FCOMPNHO -- register form, from FCOMPNHO_floatcomp_registerM_registerP_registerO_simple
def LVX_FcompnhoOp : LVX_Op<"fcompnho", [Pure]>{
  let summary = "FCOMPNHO -- Floating-Point Compare Negate Half Word Octuple";
  let arguments = (ins LVX_FloatCompAttr:$floatcomp,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$floatcomp $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::lvx::FloatComp":$floatcomp, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, ::mlir::lvx::FloatCompAttr::get($_builder.getContext(), floatcomp), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FCOMPNHO -- immediate form, from FCOMPNHO_floatcomp_registerM_registerP_upper27_lower5_splat32_double
def LVX_FcompnhoImmOp : LVX_Op<"fcompnho_i", [Pure]>{
  let summary = "FCOMPNHO -- Floating-Point Compare Negate Half Word Octuple";
  let arguments = (ins LVX_FloatCompAttr:$floatcomp,
                       UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`splat32` $splat32^)? $floatcomp $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::lvx::FloatComp":$floatcomp, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultTypes, ::mlir::lvx::FloatCompAttr::get($_builder.getContext(), floatcomp), ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FMIND -- register form, from FMIND_registerW_registerZ_registerY_simple
def LVX_FmindOp : LVX_Op<"fmind", [Pure]>{
  let summary = "FMIND -- Floating-Point Minimum Double Word";
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

// FPU:FMINDP -- register form, from FMINDP_registerM_registerP_registerO_simple
def LVX_FmindpOp : LVX_Op<"fmindp", [Pure]>{
  let summary = "FMINDP -- Floating-Point Minimum Double Word Pair";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FMINW -- register form, from FMINW_registerW_registerZ_registerY_simple
def LVX_FminwOp : LVX_Op<"fminw", [Pure]>{
  let summary = "FMINW -- Floating-Point Minimum Word";
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

// FPU:FMINWQ -- register form, from FMINWQ_registerM_registerP_registerO_simple
def LVX_FminwqOp : LVX_Op<"fminwq", [Pure]>{
  let summary = "FMINWQ -- Floating-Point Minimum Word Quadruple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FMINH -- register form, from FMINH_registerW_registerZ_registerY_simple
def LVX_FminhOp : LVX_Op<"fminh", [Pure]>{
  let summary = "FMINH -- Floating-Point Minimum Half Word";
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

// FPU:FMINHO -- register form, from FMINHO_registerM_registerP_registerO_simple
def LVX_FminhoOp : LVX_Op<"fminho", [Pure]>{
  let summary = "FMINHO -- Floating-Point Minimum Half Word Octuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FMINND -- register form, from FMINND_registerW_registerZ_registerY_simple
def LVX_FminndOp : LVX_Op<"fminnd", [Pure]>{
  let summary = "FMINND -- Floating-Point Minimum Number Double Word";
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

// FPU:FMINNDP -- register form, from FMINNDP_registerM_registerP_registerO_simple
def LVX_FminndpOp : LVX_Op<"fminndp", [Pure]>{
  let summary = "FMINNDP -- Floating-Point Minimum Number Double Word Pair";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FMINNW -- register form, from FMINNW_registerW_registerZ_registerY_simple
def LVX_FminnwOp : LVX_Op<"fminnw", [Pure]>{
  let summary = "FMINNW -- Floating-Point Minimum Number Word";
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

// FPU:FMINNWQ -- register form, from FMINNWQ_registerM_registerP_registerO_simple
def LVX_FminnwqOp : LVX_Op<"fminnwq", [Pure]>{
  let summary = "FMINNWQ -- Floating-Point Minimum Number Word Quadruple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FMINNH -- register form, from FMINNH_registerW_registerZ_registerY_simple
def LVX_FminnhOp : LVX_Op<"fminnh", [Pure]>{
  let summary = "FMINNH -- Floating-Point Minimum Number Half Word";
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

// FPU:FMINNHO -- register form, from FMINNHO_registerM_registerP_registerO_simple
def LVX_FminnhoOp : LVX_Op<"fminnho", [Pure]>{
  let summary = "FMINNHO -- Floating-Point Minimum Number Half Word Octuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FMAXD -- register form, from FMAXD_registerW_registerZ_registerY_simple
def LVX_FmaxdOp : LVX_Op<"fmaxd", [Pure]>{
  let summary = "FMAXD -- Floating-Point Maximum Double Word";
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

// FPU:FMAXDP -- register form, from FMAXDP_registerM_registerP_registerO_simple
def LVX_FmaxdpOp : LVX_Op<"fmaxdp", [Pure]>{
  let summary = "FMAXDP -- Floating-Point Maximum Double Word Pair";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FMAXW -- register form, from FMAXW_registerW_registerZ_registerY_simple
def LVX_FmaxwOp : LVX_Op<"fmaxw", [Pure]>{
  let summary = "FMAXW -- Floating-Point Maximum Word";
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

// FPU:FMAXWQ -- register form, from FMAXWQ_registerM_registerP_registerO_simple
def LVX_FmaxwqOp : LVX_Op<"fmaxwq", [Pure]>{
  let summary = "FMAXWQ -- Floating-Point Maximum Word Quadruple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FMAXH -- register form, from FMAXH_registerW_registerZ_registerY_simple
def LVX_FmaxhOp : LVX_Op<"fmaxh", [Pure]>{
  let summary = "FMAXH -- Floating-Point Maximum Half Word";
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

// FPU:FMAXHO -- register form, from FMAXHO_registerM_registerP_registerO_simple
def LVX_FmaxhoOp : LVX_Op<"fmaxho", [Pure]>{
  let summary = "FMAXHO -- Floating-Point Maximum Half Word Octuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FMAXND -- register form, from FMAXND_registerW_registerZ_registerY_simple
def LVX_FmaxndOp : LVX_Op<"fmaxnd", [Pure]>{
  let summary = "FMAXND -- Floating-Point Maximum Number Double Word";
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

// FPU:FMAXNDP -- register form, from FMAXNDP_registerM_registerP_registerO_simple
def LVX_FmaxndpOp : LVX_Op<"fmaxndp", [Pure]>{
  let summary = "FMAXNDP -- Floating-Point Maximum Number Double Word Pair";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FMAXNW -- register form, from FMAXNW_registerW_registerZ_registerY_simple
def LVX_FmaxnwOp : LVX_Op<"fmaxnw", [Pure]>{
  let summary = "FMAXNW -- Floating-Point Maximum Number Word";
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

// FPU:FMAXNWQ -- register form, from FMAXNWQ_registerM_registerP_registerO_simple
def LVX_FmaxnwqOp : LVX_Op<"fmaxnwq", [Pure]>{
  let summary = "FMAXNWQ -- Floating-Point Maximum Number Word Quadruple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FMAXNH -- register form, from FMAXNH_registerW_registerZ_registerY_simple
def LVX_FmaxnhOp : LVX_Op<"fmaxnh", [Pure]>{
  let summary = "FMAXNH -- Floating-Point Maximum Number Half Word";
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

// FPU:FMAXNHO -- register form, from FMAXNHO_registerM_registerP_registerO_simple
def LVX_FmaxnhoOp : LVX_Op<"fmaxnho", [Pure]>{
  let summary = "FMAXNHO -- Floating-Point Maximum Number Half Word Octuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FSIGND -- register form, from FSIGND_registerW_registerZ_registerY_simple
def LVX_FsigndOp : LVX_Op<"fsignd", [Pure]>{
  let summary = "FSIGND -- Floating-Point Sign Transfer Double Word";
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

// FPU:FSIGNDP -- register form, from FSIGNDP_registerM_registerP_registerO_simple
def LVX_FsigndpOp : LVX_Op<"fsigndp", [Pure]>{
  let summary = "FSIGNDP -- Floating-Point Sign Transfer Double Word Pair";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FSIGNW -- register form, from FSIGNW_registerW_registerZ_registerY_simple
def LVX_FsignwOp : LVX_Op<"fsignw", [Pure]>{
  let summary = "FSIGNW -- Floating-Point Sign Transfer Word";
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

// FPU:FSIGNWQ -- register form, from FSIGNWQ_registerM_registerP_registerO_simple
def LVX_FsignwqOp : LVX_Op<"fsignwq", [Pure]>{
  let summary = "FSIGNWQ -- Floating-Point Sign Transfer Word Quadruple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FSIGNH -- register form, from FSIGNH_registerW_registerZ_registerY_simple
def LVX_FsignhOp : LVX_Op<"fsignh", [Pure]>{
  let summary = "FSIGNH -- Floating-Point Sign Transfer Half Word";
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

// FPU:FSIGNHO -- register form, from FSIGNHO_registerM_registerP_registerO_simple
def LVX_FsignhoOp : LVX_Op<"fsignho", [Pure]>{
  let summary = "FSIGNHO -- Floating-Point Sign Transfer Half Word Octuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FSIGNND -- register form, from FSIGNND_registerW_registerZ_registerY_simple
def LVX_FsignndOp : LVX_Op<"fsignnd", [Pure]>{
  let summary = "FSIGNND -- Floating-Point Sign Negate Transfer Double Word";
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

// FPU:FSIGNNDP -- register form, from FSIGNNDP_registerM_registerP_registerO_simple
def LVX_FsignndpOp : LVX_Op<"fsignndp", [Pure]>{
  let summary = "FSIGNNDP -- Floating-Point Sign Negate Transfer Double Word Pair";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FSIGNNW -- register form, from FSIGNNW_registerW_registerZ_registerY_simple
def LVX_FsignnwOp : LVX_Op<"fsignnw", [Pure]>{
  let summary = "FSIGNNW -- Floating-Point Sign Negate Transfer Word";
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

// FPU:FSIGNNWQ -- register form, from FSIGNNWQ_registerM_registerP_registerO_simple
def LVX_FsignnwqOp : LVX_Op<"fsignnwq", [Pure]>{
  let summary = "FSIGNNWQ -- Floating-Point Sign Negate Transfer Word Quadruple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FSIGNNH -- register form, from FSIGNNH_registerW_registerZ_registerY_simple
def LVX_FsignnhOp : LVX_Op<"fsignnh", [Pure]>{
  let summary = "FSIGNNH -- Floating-Point Sign Negate Transfer Half Word";
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

// FPU:FSIGNNHO -- register form, from FSIGNNHO_registerM_registerP_registerO_simple
def LVX_FsignnhoOp : LVX_Op<"fsignnho", [Pure]>{
  let summary = "FSIGNNHO -- Floating-Point Sign Negate Transfer Half Word Octuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FSIGNMD -- register form, from FSIGNMD_registerW_registerZ_registerY_simple
def LVX_FsignmdOp : LVX_Op<"fsignmd", [Pure]>{
  let summary = "FSIGNMD -- Floating-Point Sign Combine Transfer Double Word";
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

// FPU:FSIGNMDP -- register form, from FSIGNMDP_registerM_registerP_registerO_simple
def LVX_FsignmdpOp : LVX_Op<"fsignmdp", [Pure]>{
  let summary = "FSIGNMDP -- Floating-Point Sign Combine Transfer Double Word Pair";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FSIGNMW -- register form, from FSIGNMW_registerW_registerZ_registerY_simple
def LVX_FsignmwOp : LVX_Op<"fsignmw", [Pure]>{
  let summary = "FSIGNMW -- Floating-Point Sign Combine Transfer Word";
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

// FPU:FSIGNMWQ -- register form, from FSIGNMWQ_registerM_registerP_registerO_simple
def LVX_FsignmwqOp : LVX_Op<"fsignmwq", [Pure]>{
  let summary = "FSIGNMWQ -- Floating-Point Sign Combine Transfer Double Word Quadruple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FSIGNMH -- register form, from FSIGNMH_registerW_registerZ_registerY_simple
def LVX_FsignmhOp : LVX_Op<"fsignmh", [Pure]>{
  let summary = "FSIGNMH -- Floating-Point Sign Combine Transfer Half Word";
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

// FPU:FSIGNMHO -- register form, from FSIGNMHO_registerM_registerP_registerO_simple
def LVX_FsignmhoOp : LVX_Op<"fsignmho", [Pure]>{
  let summary = "FSIGNMHO -- Floating-Point Sign Combine Transfer Half Word Octuple";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FLOATD -- register form, from FLOATD_floatmode_registerW_registerZ_simple
def LVX_FloatdOp : LVX_Op<"floatd", [Pure]>{
  let summary = "FLOATD -- Floating Point Conversion from Fixed-Point Double Word";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($floatmode^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, floatmode, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FLOATDP -- register form, from FLOATDP_floatmode_registerM_registerP_simple
def LVX_FloatdpOp : LVX_Op<"floatdp", [Pure]>{
  let summary = "FLOATDP -- Floating Point Conversion from Fixed-Point Double Word Pair";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($floatmode^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultTypes, floatmode, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FLOATW -- register form, from FLOATW_floatmode_registerW_registerZ_simple
def LVX_FloatwOp : LVX_Op<"floatw", [Pure]>{
  let summary = "FLOATW -- Floating Point Conversion from Fixed-Point";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($floatmode^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, floatmode, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FLOATWP -- register form, from FLOATWP_floatmode_registerW_registerZ_simple
def LVX_FloatwpOp : LVX_Op<"floatwp", [Pure]>{
  let summary = "FLOATWP -- Floating Point Conversion from Fixed-Point Word Pair";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($floatmode^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, floatmode, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FLOATWQ -- register form, from FLOATWQ_floatmode_registerM_registerP_simple
def LVX_FloatwqOp : LVX_Op<"floatwq", [Pure]>{
  let summary = "FLOATWQ -- Floating Point Conversion from Fixed-Point Word Quadruple";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($floatmode^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultTypes, floatmode, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FLOATHO -- register form, from FLOATHO_floatmode_registerM_registerP_simple
def LVX_FloathoOp : LVX_Op<"floatho", [Pure]>{
  let summary = "FLOATHO -- Floating Point Conversion from Fixed-Point Half Word Octuple";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($floatmode^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultTypes, floatmode, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FLOATUD -- register form, from FLOATUD_floatmode_registerW_registerZ_simple
def LVX_FloatudOp : LVX_Op<"floatud", [Pure]>{
  let summary = "FLOATUD -- Floating Point Conversion from Unsigned Fixed-Point Double Word";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($floatmode^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, floatmode, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FLOATUDP -- register form, from FLOATUDP_floatmode_registerM_registerP_simple
def LVX_FloatudpOp : LVX_Op<"floatudp", [Pure]>{
  let summary = "FLOATUDP -- Floating Point Conversion from Unsigned Fixed-Point Double Word Pair";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($floatmode^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultTypes, floatmode, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FLOATUW -- register form, from FLOATUW_floatmode_registerW_registerZ_simple
def LVX_FloatuwOp : LVX_Op<"floatuw", [Pure]>{
  let summary = "FLOATUW -- Floating Point Conversion from Unsigned Fixed-Point";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($floatmode^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, floatmode, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FLOATUWP -- register form, from FLOATUWP_floatmode_registerW_registerZ_simple
def LVX_FloatuwpOp : LVX_Op<"floatuwp", [Pure]>{
  let summary = "FLOATUWP -- Floating Point Conversion from Unsigned Fixed-Point Word Pair";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($floatmode^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, floatmode, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FLOATUWQ -- register form, from FLOATUWQ_floatmode_registerM_registerP_simple
def LVX_FloatuwqOp : LVX_Op<"floatuwq", [Pure]>{
  let summary = "FLOATUWQ -- Floating Point Conversion from Unsigned Fixed-Point Word Quadruple";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($floatmode^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultTypes, floatmode, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FLOATUHO -- register form, from FLOATUHO_floatmode_registerM_registerP_simple
def LVX_FloatuhoOp : LVX_Op<"floatuho", [Pure]>{
  let summary = "FLOATUHO -- Floating Point Conversion from Unsigned Fixed-Point Half Word Octuple";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($floatmode^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultTypes, floatmode, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FLOATWD -- register form, from FLOATWD_floatmode_registerW_registerZ_simple
def LVX_FloatwdOp : LVX_Op<"floatwd", [Pure]>{
  let summary = "FLOATWD -- Floating Point Conversion from Fixed-Point Word to Double Word";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($floatmode^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, floatmode, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FLOATUWD -- register form, from FLOATUWD_floatmode_registerW_registerZ_simple
def LVX_FloatuwdOp : LVX_Op<"floatuwd", [Pure]>{
  let summary = "FLOATUWD -- Floating Point Conversion from Unsigned Fixed-Point Word to Double Word";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($floatmode^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, floatmode, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FLOATDW -- register form, from FLOATDW_floatmode_registerW_registerZ_simple
def LVX_FloatdwOp : LVX_Op<"floatdw", [Pure]>{
  let summary = "FLOATDW -- Floating Point Conversion from Fixed-Point Double Word to Word";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($floatmode^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, floatmode, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FLOATUDW -- register form, from FLOATUDW_floatmode_registerW_registerZ_simple
def LVX_FloatudwOp : LVX_Op<"floatudw", [Pure]>{
  let summary = "FLOATUDW -- Floating Point Conversion from Unsigned Fixed-Point Double Word to Word";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($floatmode^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, floatmode, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FIXEDD -- register form, from FIXEDD_floatmode_registerW_registerZ_simple
def LVX_FixeddOp : LVX_Op<"fixedd", [Pure]>{
  let summary = "FIXEDD -- Floating Point Conversion to Fixed-Point Double Word";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($floatmode^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, floatmode, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FIXEDDP -- register form, from FIXEDDP_floatmode_registerM_registerP_simple
def LVX_FixeddpOp : LVX_Op<"fixeddp", [Pure]>{
  let summary = "FIXEDDP -- Floating Point Conversion to Fixed-Point Double Word Pair";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($floatmode^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultTypes, floatmode, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FIXEDW -- register form, from FIXEDW_floatmode_registerW_registerZ_simple
def LVX_FixedwOp : LVX_Op<"fixedw", [Pure]>{
  let summary = "FIXEDW -- Floating Point Conversion to Fixed-Point";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($floatmode^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, floatmode, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FIXEDWP -- register form, from FIXEDWP_floatmode_registerW_registerZ_simple
def LVX_FixedwpOp : LVX_Op<"fixedwp", [Pure]>{
  let summary = "FIXEDWP -- Floating Point Conversion to Fixed-Point Word Pair";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($floatmode^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, floatmode, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FIXEDWQ -- register form, from FIXEDWQ_floatmode_registerM_registerP_simple
def LVX_FixedwqOp : LVX_Op<"fixedwq", [Pure]>{
  let summary = "FIXEDWQ -- Floating Point Conversion to Fixed-Point Word Quadruple";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($floatmode^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultTypes, floatmode, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FIXEDHO -- register form, from FIXEDHO_floatmode_registerM_registerP_simple
def LVX_FixedhoOp : LVX_Op<"fixedho", [Pure]>{
  let summary = "FIXEDHO -- Floating Point Conversion to Fixed-Point Half Word Octuple";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($floatmode^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultTypes, floatmode, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FIXEDUD -- register form, from FIXEDUD_floatmode_registerW_registerZ_simple
def LVX_FixedudOp : LVX_Op<"fixedud", [Pure]>{
  let summary = "FIXEDUD -- Floating Point Conversion to Unsigned Fixed-Point Double Word";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($floatmode^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, floatmode, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FIXEDUDP -- register form, from FIXEDUDP_floatmode_registerM_registerP_simple
def LVX_FixedudpOp : LVX_Op<"fixedudp", [Pure]>{
  let summary = "FIXEDUDP -- Floating Point Conversion to Unsigned Fixed-Point Double Word Pair";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($floatmode^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultTypes, floatmode, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FIXEDUW -- register form, from FIXEDUW_floatmode_registerW_registerZ_simple
def LVX_FixeduwOp : LVX_Op<"fixeduw", [Pure]>{
  let summary = "FIXEDUW -- Floating Point Conversion to Unsigned Fixed-Point";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($floatmode^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, floatmode, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FIXEDUWP -- register form, from FIXEDUWP_floatmode_registerW_registerZ_simple
def LVX_FixeduwpOp : LVX_Op<"fixeduwp", [Pure]>{
  let summary = "FIXEDUWP -- Floating Point Conversion to Unsigned Fixed-Point Word Pair";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($floatmode^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, floatmode, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FIXEDUWQ -- register form, from FIXEDUWQ_floatmode_registerM_registerP_simple
def LVX_FixeduwqOp : LVX_Op<"fixeduwq", [Pure]>{
  let summary = "FIXEDUWQ -- Floating Point Conversion to Unsigned Fixed-Point Word Quadruple";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($floatmode^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultTypes, floatmode, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FIXEDUHO -- register form, from FIXEDUHO_floatmode_registerM_registerP_simple
def LVX_FixeduhoOp : LVX_Op<"fixeduho", [Pure]>{
  let summary = "FIXEDUHO -- Floating Point Conversion to Unsigned Fixed-Point Half Word Octuple";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($floatmode^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultTypes, floatmode, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FIXEDWD -- register form, from FIXEDWD_floatmode_registerW_registerZ_simple
def LVX_FixedwdOp : LVX_Op<"fixedwd", [Pure]>{
  let summary = "FIXEDWD -- Floating Point Conversion from Word to Fixed-Point Double Word";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($floatmode^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, floatmode, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FIXEDUWD -- register form, from FIXEDUWD_floatmode_registerW_registerZ_simple
def LVX_FixeduwdOp : LVX_Op<"fixeduwd", [Pure]>{
  let summary = "FIXEDUWD -- Floating Point Conversion from Word to Unsigned Fixed-Point Double Word";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($floatmode^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, floatmode, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FIXEDDW -- register form, from FIXEDDW_floatmode_registerW_registerZ_simple
def LVX_FixeddwOp : LVX_Op<"fixeddw", [Pure]>{
  let summary = "FIXEDDW -- Floating Point Conversion from Double Word to Fixed-Point Word";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($floatmode^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, floatmode, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FIXEDUDW -- register form, from FIXEDUDW_floatmode_registerW_registerZ_simple
def LVX_FixedudwOp : LVX_Op<"fixedudw", [Pure]>{
  let summary = "FIXEDUDW -- Floating Point Conversion from Double Word to Unsigned Fixed-Point Word";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($floatmode^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, floatmode, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FRINTD -- register form, from FRINTD_floatmode_registerW_registerZ_simple
def LVX_FrintdOp : LVX_Op<"frintd", [Pure]>{
  let summary = "FRINTD -- Floating Point Round to Int Double Word";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($floatmode^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, floatmode, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FRINTW -- register form, from FRINTW_floatmode_registerW_registerZ_simple
def LVX_FrintwOp : LVX_Op<"frintw", [Pure]>{
  let summary = "FRINTW -- Floating Point Round to Int Word";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($floatmode^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, floatmode, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FRINTH -- register form, from FRINTH_floatmode_registerW_registerZ_simple
def LVX_FrinthOp : LVX_Op<"frinth", [Pure]>{
  let summary = "FRINTH -- Floating Point Round to Int Half Word";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($floatmode^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, floatmode, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FSQRTD -- register form, from FSQRTD_floatmode_registerW_registerZ_simple
def LVX_FsqrtdOp : LVX_Op<"fsqrtd", [Pure]>{
  let summary = "FSQRTD -- Floating Point Square Root Double Word";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($floatmode^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, floatmode, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FSQRTW -- register form, from FSQRTW_floatmode_registerW_registerZ_simple
def LVX_FsqrtwOp : LVX_Op<"fsqrtw", [Pure]>{
  let summary = "FSQRTW -- Floating Point Square Root Word";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($floatmode^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, floatmode, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FSQRTH -- register form, from FSQRTH_floatmode_registerW_registerZ_simple
def LVX_FsqrthOp : LVX_Op<"fsqrth", [Pure]>{
  let summary = "FSQRTH -- Floating Point Square Root Half Word";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($floatmode^)? $operand attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, floatmode, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MULD -- register form, from MULD_highmult_registerW_registerZ_registerY_simple
def LVX_MuldOp : LVX_Op<"muld", [Pure]>{
  let summary = "MULD -- Multiply Double Word";
  let arguments = (ins OptionalAttr<LVX_HighMultAttr>:$highmult,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($highmult^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs, CArg<"::mlir::lvx::HighMultAttr", "{}">:$highmult), [{
      build($_builder, $_state, resultType, highmult, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MULD -- immediate form, from MULD_highmult_registerW_registerZ_upper27_lower5_splat32_double
def LVX_MuldImmOp : LVX_Op<"muld_i", [Pure]>{
  let summary = "MULD -- Multiply Double Word";
  let arguments = (ins OptionalAttr<LVX_HighMultAttr>:$highmult,
                       UnitAttr:$splat32,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`splat32` $splat32^)? ($highmult^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5, CArg<"::mlir::lvx::HighMultAttr", "{}">:$highmult), [{
      build($_builder, $_state, resultType, highmult, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MULDP -- register form, from MULDP_highmult_registerM_registerP_registerO_simple
def LVX_MuldpOp : LVX_Op<"muldp", [Pure]>{
  let summary = "MULDP -- Multiply Double Word Pair";
  let arguments = (ins OptionalAttr<LVX_HighMultAttr>:$highmult,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($highmult^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs, CArg<"::mlir::lvx::HighMultAttr", "{}">:$highmult), [{
      build($_builder, $_state, resultTypes, highmult, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MULW -- register form, from MULW_highmult_signextw_registerW_registerZ_registerY_simple
def LVX_MulwOp : LVX_Op<"mulw", [Pure]>{
  let summary = "MULW -- Multiply Word";
  let arguments = (ins OptionalAttr<LVX_HighMultAttr>:$highmult,
                       UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? ($highmult^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs, CArg<"::mlir::lvx::HighMultAttr", "{}">:$highmult), [{
      build($_builder, $_state, resultType, highmult, ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MULW -- immediate form, from MULW_highmult_signextw_registerW_registerZ_upper27_lower5_double
def LVX_MulwImmOp : LVX_Op<"mulw_i", [Pure]>{
  let summary = "MULW -- Multiply Word";
  let arguments = (ins OptionalAttr<LVX_HighMultAttr>:$highmult,
                       UnitAttr:$sx,
                       LVX_RegType:$operand,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? ($highmult^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5, CArg<"::mlir::lvx::HighMultAttr", "{}">:$highmult), [{
      build($_builder, $_state, resultType, highmult, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MULWQ -- register form, from MULWQ_highmult_registerM_registerP_registerO_simple
def LVX_MulwqOp : LVX_Op<"mulwq", [Pure]>{
  let summary = "MULWQ -- Multiply Word Quadruple";
  let arguments = (ins OptionalAttr<LVX_HighMultAttr>:$highmult,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($highmult^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs, CArg<"::mlir::lvx::HighMultAttr", "{}">:$highmult), [{
      build($_builder, $_state, resultTypes, highmult, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MULHO -- register form, from MULHO_highmult_registerM_registerP_registerO_simple
def LVX_MulhoOp : LVX_Op<"mulho", [Pure]>{
  let summary = "MULHO -- Multiply Half Word Octuple";
  let arguments = (ins OptionalAttr<LVX_HighMultAttr>:$highmult,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($highmult^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs, CArg<"::mlir::lvx::HighMultAttr", "{}">:$highmult), [{
      build($_builder, $_state, resultTypes, highmult, lhs, rhs, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "($highmult^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs, CArg<"::mlir::lvx::HighMultAttr", "{}">:$highmult), [{
      build($_builder, $_state, resultType, highmult, lhs, rhs, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "(`splat32` $splat32^)? ($highmult^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5, CArg<"::mlir::lvx::HighMultAttr", "{}">:$highmult), [{
      build($_builder, $_state, resultType, highmult, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MULNDP -- register form, from MULNDP_highmult_registerM_registerP_registerO_simple
def LVX_MulndpOp : LVX_Op<"mulndp", [Pure]>{
  let summary = "MULNDP -- Multiply Negate Double Word Pair";
  let arguments = (ins OptionalAttr<LVX_HighMultAttr>:$highmult,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($highmult^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs, CArg<"::mlir::lvx::HighMultAttr", "{}">:$highmult), [{
      build($_builder, $_state, resultTypes, highmult, lhs, rhs, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "(`sx` $sx^)? ($highmult^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs, CArg<"::mlir::lvx::HighMultAttr", "{}">:$highmult), [{
      build($_builder, $_state, resultType, highmult, ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "(`sx` $sx^)? ($highmult^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5, CArg<"::mlir::lvx::HighMultAttr", "{}">:$highmult), [{
      build($_builder, $_state, resultType, highmult, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MULNWQ -- register form, from MULNWQ_highmult_registerM_registerP_registerO_simple
def LVX_MulnwqOp : LVX_Op<"mulnwq", [Pure]>{
  let summary = "MULNWQ -- Multiply Negate Word Quadruple";
  let arguments = (ins OptionalAttr<LVX_HighMultAttr>:$highmult,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($highmult^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs, CArg<"::mlir::lvx::HighMultAttr", "{}">:$highmult), [{
      build($_builder, $_state, resultTypes, highmult, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MULNHO -- register form, from MULNHO_highmult_registerM_registerP_registerO_simple
def LVX_MulnhoOp : LVX_Op<"mulnho", [Pure]>{
  let summary = "MULNHO -- Multiply Negate Half Word Octuple";
  let arguments = (ins OptionalAttr<LVX_HighMultAttr>:$highmult,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($highmult^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs, CArg<"::mlir::lvx::HighMultAttr", "{}">:$highmult), [{
      build($_builder, $_state, resultTypes, highmult, lhs, rhs, ::mlir::lvx::FormatAttr());
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
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($widemult^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs, CArg<"::mlir::lvx::WideMultAttr", "{}">:$widemult), [{
      build($_builder, $_state, resultTypes, widemult, lhs, rhs, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "($widemult^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs, CArg<"::mlir::lvx::WideMultAttr", "{}">:$widemult), [{
      build($_builder, $_state, resultType, widemult, lhs, rhs, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "(`splat32` $splat32^)? ($widemult^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5, CArg<"::mlir::lvx::WideMultAttr", "{}">:$widemult), [{
      build($_builder, $_state, resultType, widemult, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MULXWDP -- register form, from MULXWDP_widemult_registerM_registerZ_registerY_simple
def LVX_MulxwdpOp : LVX_Op<"mulxwdp", [Pure]>{
  let summary = "MULXWDP -- Multiply Extend Word to Double Word Pair";
  let arguments = (ins OptionalAttr<LVX_WideMultAttr>:$widemult,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($widemult^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs, CArg<"::mlir::lvx::WideMultAttr", "{}">:$widemult), [{
      build($_builder, $_state, resultTypes, widemult, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MULXHWQ -- register form, from MULXHWQ_widemult_registerM_registerZ_registerY_simple
def LVX_MulxhwqOp : LVX_Op<"mulxhwq", [Pure]>{
  let summary = "MULXHWQ -- Multiply Extend Half Word to Word Quadruple";
  let arguments = (ins OptionalAttr<LVX_WideMultAttr>:$widemult,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($widemult^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs, CArg<"::mlir::lvx::WideMultAttr", "{}">:$widemult), [{
      build($_builder, $_state, resultTypes, widemult, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MULXBHO -- register form, from MULXBHO_widemult_registerM_registerZ_registerY_simple
def LVX_MulxbhoOp : LVX_Op<"mulxbho", [Pure]>{
  let summary = "MULXBHO -- Multiply Extend Byte to Half Word Octuple";
  let arguments = (ins OptionalAttr<LVX_WideMultAttr>:$widemult,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($widemult^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs, CArg<"::mlir::lvx::WideMultAttr", "{}">:$widemult), [{
      build($_builder, $_state, resultTypes, widemult, lhs, rhs, ::mlir::lvx::FormatAttr());
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
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($widemult^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs, CArg<"::mlir::lvx::WideMultAttr", "{}">:$widemult), [{
      build($_builder, $_state, resultTypes, widemult, lhs, rhs, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "($widemult^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs, CArg<"::mlir::lvx::WideMultAttr", "{}">:$widemult), [{
      build($_builder, $_state, resultType, widemult, lhs, rhs, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "(`splat32` $splat32^)? ($widemult^)? $operand `,` $upper27_lower5 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$operand, "::mlir::TypedAttr":$upper27_lower5, CArg<"::mlir::lvx::WideMultAttr", "{}">:$widemult), [{
      build($_builder, $_state, resultType, widemult, ::mlir::UnitAttr(), operand, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MULNXWDP -- register form, from MULNXWDP_widemult_registerM_registerZ_registerY_simple
def LVX_MulnxwdpOp : LVX_Op<"mulnxwdp", [Pure]>{
  let summary = "MULNXWDP -- Multiply Negate Extend Word to Double Word Pair";
  let arguments = (ins OptionalAttr<LVX_WideMultAttr>:$widemult,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($widemult^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs, CArg<"::mlir::lvx::WideMultAttr", "{}">:$widemult), [{
      build($_builder, $_state, resultTypes, widemult, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MULNXHWQ -- register form, from MULNXHWQ_widemult_registerM_registerZ_registerY_simple
def LVX_MulnxhwqOp : LVX_Op<"mulnxhwq", [Pure]>{
  let summary = "MULNXHWQ -- Multiply Negate Extend Half Word to Word Quadruple";
  let arguments = (ins OptionalAttr<LVX_WideMultAttr>:$widemult,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($widemult^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs, CArg<"::mlir::lvx::WideMultAttr", "{}">:$widemult), [{
      build($_builder, $_state, resultTypes, widemult, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MULNXBHO -- register form, from MULNXBHO_widemult_registerM_registerZ_registerY_simple
def LVX_MulnxbhoOp : LVX_Op<"mulnxbho", [Pure]>{
  let summary = "MULNXBHO -- Multiply Negate Extend Byte to Half Word Octuple";
  let arguments = (ins OptionalAttr<LVX_WideMultAttr>:$widemult,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($widemult^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs, CArg<"::mlir::lvx::WideMultAttr", "{}">:$widemult), [{
      build($_builder, $_state, resultTypes, widemult, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MADDD -- register form, from MADDD_highmult_registerW_registerZ_registerY_simple
def LVX_MadddOp : LVX_Op<"maddd", [Pure]>{
  let summary = "MADDD -- Multiply Add Double Word";
  let arguments = (ins OptionalAttr<LVX_HighMultAttr>:$highmult,
                       LVX_RegType:$a,
                       LVX_RegType:$b,
                       LVX_RegType:$c,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($highmult^)? $a `,` $b `,` $c attr-dict `:` `(` qualified(type($a)) `,` qualified(type($b)) `,` qualified(type($c)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$a, "::mlir::Value":$b, "::mlir::Value":$c, CArg<"::mlir::lvx::HighMultAttr", "{}">:$highmult), [{
      build($_builder, $_state, resultType, highmult, a, b, c, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MADDD -- immediate form, from MADDD_highmult_registerW_registerZ_upper27_lower5_splat32_double
def LVX_MadddImmOp : LVX_Op<"maddd_i", [Pure]>{
  let summary = "MADDD -- Multiply Add Double Word";
  let arguments = (ins OptionalAttr<LVX_HighMultAttr>:$highmult,
                       UnitAttr:$splat32,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`splat32` $splat32^)? ($highmult^)? $lhs `,` $upper27_lower5 `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs, "::mlir::TypedAttr":$upper27_lower5, CArg<"::mlir::lvx::HighMultAttr", "{}">:$highmult), [{
      build($_builder, $_state, resultType, highmult, ::mlir::UnitAttr(), lhs, rhs, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MADDDP -- register form, from MADDDP_highmult_registerM_registerP_registerO_simple
def LVX_MadddpOp : LVX_Op<"madddp", [Pure]>{
  let summary = "MADDDP -- Multiply Add Double Word Pair";
  let arguments = (ins OptionalAttr<LVX_HighMultAttr>:$highmult,
                       LVX_RegType:$a,
                       LVX_RegType:$b,
                       LVX_RegType:$c,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($highmult^)? $a `,` $b `,` $c attr-dict `:` `(` qualified(type($a)) `,` qualified(type($b)) `,` qualified(type($c)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$a, "::mlir::Value":$b, "::mlir::Value":$c, CArg<"::mlir::lvx::HighMultAttr", "{}">:$highmult), [{
      build($_builder, $_state, resultTypes, highmult, a, b, c, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MADDW -- register form, from MADDW_highmult_signextw_registerW_registerZ_registerY_simple
def LVX_MaddwOp : LVX_Op<"maddw", [Pure]>{
  let summary = "MADDW -- Multiply Add Word";
  let arguments = (ins OptionalAttr<LVX_HighMultAttr>:$highmult,
                       UnitAttr:$sx,
                       LVX_RegType:$a,
                       LVX_RegType:$b,
                       LVX_RegType:$c,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? ($highmult^)? $a `,` $b `,` $c attr-dict `:` `(` qualified(type($a)) `,` qualified(type($b)) `,` qualified(type($c)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$a, "::mlir::Value":$b, "::mlir::Value":$c, CArg<"::mlir::lvx::HighMultAttr", "{}">:$highmult), [{
      build($_builder, $_state, resultType, highmult, ::mlir::UnitAttr(), a, b, c, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MADDW -- immediate form, from MADDW_highmult_signextw_registerW_registerZ_upper27_lower5_double
def LVX_MaddwImmOp : LVX_Op<"maddw_i", [Pure]>{
  let summary = "MADDW -- Multiply Add Word";
  let arguments = (ins OptionalAttr<LVX_HighMultAttr>:$highmult,
                       UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? ($highmult^)? $lhs `,` $upper27_lower5 `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs, "::mlir::TypedAttr":$upper27_lower5, CArg<"::mlir::lvx::HighMultAttr", "{}">:$highmult), [{
      build($_builder, $_state, resultType, highmult, ::mlir::UnitAttr(), lhs, rhs, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MADDWQ -- register form, from MADDWQ_highmult_registerM_registerP_registerO_simple
def LVX_MaddwqOp : LVX_Op<"maddwq", [Pure]>{
  let summary = "MADDWQ -- Multiply Add Word Quadruple";
  let arguments = (ins OptionalAttr<LVX_HighMultAttr>:$highmult,
                       LVX_RegType:$a,
                       LVX_RegType:$b,
                       LVX_RegType:$c,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($highmult^)? $a `,` $b `,` $c attr-dict `:` `(` qualified(type($a)) `,` qualified(type($b)) `,` qualified(type($c)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$a, "::mlir::Value":$b, "::mlir::Value":$c, CArg<"::mlir::lvx::HighMultAttr", "{}">:$highmult), [{
      build($_builder, $_state, resultTypes, highmult, a, b, c, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MADDHO -- register form, from MADDHO_highmult_registerM_registerP_registerO_simple
def LVX_MaddhoOp : LVX_Op<"maddho", [Pure]>{
  let summary = "MADDHO -- Multiply Add Half Word Octuple";
  let arguments = (ins OptionalAttr<LVX_HighMultAttr>:$highmult,
                       LVX_RegType:$a,
                       LVX_RegType:$b,
                       LVX_RegType:$c,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($highmult^)? $a `,` $b `,` $c attr-dict `:` `(` qualified(type($a)) `,` qualified(type($b)) `,` qualified(type($c)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$a, "::mlir::Value":$b, "::mlir::Value":$c, CArg<"::mlir::lvx::HighMultAttr", "{}">:$highmult), [{
      build($_builder, $_state, resultTypes, highmult, a, b, c, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MADDXDQ -- register form, from MADDXDQ_widemult_registerM_registerZ_registerY_simple
def LVX_MaddxdqOp : LVX_Op<"maddxdq", [Pure]>{
  let summary = "MADDXDQ -- Multiply Add Extend Double Word to Quadruple Word";
  let arguments = (ins OptionalAttr<LVX_WideMultAttr>:$widemult,
                       LVX_RegType:$a,
                       LVX_RegType:$b,
                       LVX_RegType:$c,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($widemult^)? $a `,` $b `,` $c attr-dict `:` `(` qualified(type($a)) `,` qualified(type($b)) `,` qualified(type($c)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$a, "::mlir::Value":$b, "::mlir::Value":$c, CArg<"::mlir::lvx::WideMultAttr", "{}">:$widemult), [{
      build($_builder, $_state, resultTypes, widemult, a, b, c, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MADDXWD -- register form, from MADDXWD_widemult_registerW_registerZ_registerY_simple
def LVX_MaddxwdOp : LVX_Op<"maddxwd", [Pure]>{
  let summary = "MADDXWD -- Multiply Add Extend Word to Double Word";
  let arguments = (ins OptionalAttr<LVX_WideMultAttr>:$widemult,
                       LVX_RegType:$a,
                       LVX_RegType:$b,
                       LVX_RegType:$c,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($widemult^)? $a `,` $b `,` $c attr-dict `:` `(` qualified(type($a)) `,` qualified(type($b)) `,` qualified(type($c)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$a, "::mlir::Value":$b, "::mlir::Value":$c, CArg<"::mlir::lvx::WideMultAttr", "{}">:$widemult), [{
      build($_builder, $_state, resultType, widemult, a, b, c, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MADDXWD -- immediate form, from MADDXWD_widemult_registerW_registerZ_upper27_lower5_splat32_double
def LVX_MaddxwdImmOp : LVX_Op<"maddxwd_i", [Pure]>{
  let summary = "MADDXWD -- Multiply Add Extend Word to Double Word";
  let arguments = (ins OptionalAttr<LVX_WideMultAttr>:$widemult,
                       UnitAttr:$splat32,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`splat32` $splat32^)? ($widemult^)? $lhs `,` $upper27_lower5 `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs, "::mlir::TypedAttr":$upper27_lower5, CArg<"::mlir::lvx::WideMultAttr", "{}">:$widemult), [{
      build($_builder, $_state, resultType, widemult, ::mlir::UnitAttr(), lhs, rhs, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MADDXWDP -- register form, from MADDXWDP_widemult_registerM_registerZ_registerY_simple
def LVX_MaddxwdpOp : LVX_Op<"maddxwdp", [Pure]>{
  let summary = "MADDXWDP -- Multiply Add Extend Word to Double Word Pair";
  let arguments = (ins OptionalAttr<LVX_WideMultAttr>:$widemult,
                       LVX_RegType:$a,
                       LVX_RegType:$b,
                       LVX_RegType:$c,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($widemult^)? $a `,` $b `,` $c attr-dict `:` `(` qualified(type($a)) `,` qualified(type($b)) `,` qualified(type($c)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$a, "::mlir::Value":$b, "::mlir::Value":$c, CArg<"::mlir::lvx::WideMultAttr", "{}">:$widemult), [{
      build($_builder, $_state, resultTypes, widemult, a, b, c, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MADDXHWQ -- register form, from MADDXHWQ_widemult_registerM_registerZ_registerY_simple
def LVX_MaddxhwqOp : LVX_Op<"maddxhwq", [Pure]>{
  let summary = "MADDXHWQ -- Multiply Add Extend Half Word to Word Quadruple";
  let arguments = (ins OptionalAttr<LVX_WideMultAttr>:$widemult,
                       LVX_RegType:$a,
                       LVX_RegType:$b,
                       LVX_RegType:$c,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($widemult^)? $a `,` $b `,` $c attr-dict `:` `(` qualified(type($a)) `,` qualified(type($b)) `,` qualified(type($c)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$a, "::mlir::Value":$b, "::mlir::Value":$c, CArg<"::mlir::lvx::WideMultAttr", "{}">:$widemult), [{
      build($_builder, $_state, resultTypes, widemult, a, b, c, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MADDXBHO -- register form, from MADDXBHO_widemult_registerM_registerZ_registerY_simple
def LVX_MaddxbhoOp : LVX_Op<"maddxbho", [Pure]>{
  let summary = "MADDXBHO -- Multiply Add Extend Byte to Half Word Octuple";
  let arguments = (ins OptionalAttr<LVX_WideMultAttr>:$widemult,
                       LVX_RegType:$a,
                       LVX_RegType:$b,
                       LVX_RegType:$c,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($widemult^)? $a `,` $b `,` $c attr-dict `:` `(` qualified(type($a)) `,` qualified(type($b)) `,` qualified(type($c)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$a, "::mlir::Value":$b, "::mlir::Value":$c, CArg<"::mlir::lvx::WideMultAttr", "{}">:$widemult), [{
      build($_builder, $_state, resultTypes, widemult, a, b, c, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MSBFD -- register form, from MSBFD_highmult_registerW_registerZ_registerY_simple
def LVX_MsbfdOp : LVX_Op<"msbfd", [Pure]>{
  let summary = "MSBFD -- Multiply Subtract From Double Word";
  let arguments = (ins OptionalAttr<LVX_HighMultAttr>:$highmult,
                       LVX_RegType:$a,
                       LVX_RegType:$b,
                       LVX_RegType:$c,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($highmult^)? $a `,` $b `,` $c attr-dict `:` `(` qualified(type($a)) `,` qualified(type($b)) `,` qualified(type($c)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$a, "::mlir::Value":$b, "::mlir::Value":$c, CArg<"::mlir::lvx::HighMultAttr", "{}">:$highmult), [{
      build($_builder, $_state, resultType, highmult, a, b, c, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MSBFD -- immediate form, from MSBFD_highmult_registerW_registerZ_upper27_lower5_splat32_double
def LVX_MsbfdImmOp : LVX_Op<"msbfd_i", [Pure]>{
  let summary = "MSBFD -- Multiply Subtract From Double Word";
  let arguments = (ins OptionalAttr<LVX_HighMultAttr>:$highmult,
                       UnitAttr:$splat32,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`splat32` $splat32^)? ($highmult^)? $lhs `,` $upper27_lower5 `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs, "::mlir::TypedAttr":$upper27_lower5, CArg<"::mlir::lvx::HighMultAttr", "{}">:$highmult), [{
      build($_builder, $_state, resultType, highmult, ::mlir::UnitAttr(), lhs, rhs, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MSBFDP -- register form, from MSBFDP_highmult_registerM_registerP_registerO_simple
def LVX_MsbfdpOp : LVX_Op<"msbfdp", [Pure]>{
  let summary = "MSBFDP -- Multiply Subtract From Double Word Pair";
  let arguments = (ins OptionalAttr<LVX_HighMultAttr>:$highmult,
                       LVX_RegType:$a,
                       LVX_RegType:$b,
                       LVX_RegType:$c,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($highmult^)? $a `,` $b `,` $c attr-dict `:` `(` qualified(type($a)) `,` qualified(type($b)) `,` qualified(type($c)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$a, "::mlir::Value":$b, "::mlir::Value":$c, CArg<"::mlir::lvx::HighMultAttr", "{}">:$highmult), [{
      build($_builder, $_state, resultTypes, highmult, a, b, c, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MSBFW -- register form, from MSBFW_highmult_signextw_registerW_registerZ_registerY_simple
def LVX_MsbfwOp : LVX_Op<"msbfw", [Pure]>{
  let summary = "MSBFW -- Multiply Subtract From Word";
  let arguments = (ins OptionalAttr<LVX_HighMultAttr>:$highmult,
                       UnitAttr:$sx,
                       LVX_RegType:$a,
                       LVX_RegType:$b,
                       LVX_RegType:$c,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? ($highmult^)? $a `,` $b `,` $c attr-dict `:` `(` qualified(type($a)) `,` qualified(type($b)) `,` qualified(type($c)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$a, "::mlir::Value":$b, "::mlir::Value":$c, CArg<"::mlir::lvx::HighMultAttr", "{}">:$highmult), [{
      build($_builder, $_state, resultType, highmult, ::mlir::UnitAttr(), a, b, c, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MSBFW -- immediate form, from MSBFW_highmult_signextw_registerW_registerZ_upper27_lower5_double
def LVX_MsbfwImmOp : LVX_Op<"msbfw_i", [Pure]>{
  let summary = "MSBFW -- Multiply Subtract From Word";
  let arguments = (ins OptionalAttr<LVX_HighMultAttr>:$highmult,
                       UnitAttr:$sx,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`sx` $sx^)? ($highmult^)? $lhs `,` $upper27_lower5 `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs, "::mlir::TypedAttr":$upper27_lower5, CArg<"::mlir::lvx::HighMultAttr", "{}">:$highmult), [{
      build($_builder, $_state, resultType, highmult, ::mlir::UnitAttr(), lhs, rhs, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MSBFWQ -- register form, from MSBFWQ_highmult_registerM_registerP_registerO_simple
def LVX_MsbfwqOp : LVX_Op<"msbfwq", [Pure]>{
  let summary = "MSBFWQ -- Multiply Subtract Word Quadruple";
  let arguments = (ins OptionalAttr<LVX_HighMultAttr>:$highmult,
                       LVX_RegType:$a,
                       LVX_RegType:$b,
                       LVX_RegType:$c,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($highmult^)? $a `,` $b `,` $c attr-dict `:` `(` qualified(type($a)) `,` qualified(type($b)) `,` qualified(type($c)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$a, "::mlir::Value":$b, "::mlir::Value":$c, CArg<"::mlir::lvx::HighMultAttr", "{}">:$highmult), [{
      build($_builder, $_state, resultTypes, highmult, a, b, c, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MSBFHO -- register form, from MSBFHO_highmult_registerM_registerP_registerO_simple
def LVX_MsbfhoOp : LVX_Op<"msbfho", [Pure]>{
  let summary = "MSBFHO -- Multiply Subtract Half Word Octuple";
  let arguments = (ins OptionalAttr<LVX_HighMultAttr>:$highmult,
                       LVX_RegType:$a,
                       LVX_RegType:$b,
                       LVX_RegType:$c,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($highmult^)? $a `,` $b `,` $c attr-dict `:` `(` qualified(type($a)) `,` qualified(type($b)) `,` qualified(type($c)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$a, "::mlir::Value":$b, "::mlir::Value":$c, CArg<"::mlir::lvx::HighMultAttr", "{}">:$highmult), [{
      build($_builder, $_state, resultTypes, highmult, a, b, c, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MSBFXDQ -- register form, from MSBFXDQ_widemult_registerM_registerZ_registerY_simple
def LVX_MsbfxdqOp : LVX_Op<"msbfxdq", [Pure]>{
  let summary = "MSBFXDQ -- Multiply Subtract From Extend Double Word to Quadruple Word";
  let arguments = (ins OptionalAttr<LVX_WideMultAttr>:$widemult,
                       LVX_RegType:$a,
                       LVX_RegType:$b,
                       LVX_RegType:$c,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($widemult^)? $a `,` $b `,` $c attr-dict `:` `(` qualified(type($a)) `,` qualified(type($b)) `,` qualified(type($c)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$a, "::mlir::Value":$b, "::mlir::Value":$c, CArg<"::mlir::lvx::WideMultAttr", "{}">:$widemult), [{
      build($_builder, $_state, resultTypes, widemult, a, b, c, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MSBFXWD -- register form, from MSBFXWD_widemult_registerW_registerZ_registerY_simple
def LVX_MsbfxwdOp : LVX_Op<"msbfxwd", [Pure]>{
  let summary = "MSBFXWD -- Multiply Subtract From Extend Word to Double Word";
  let arguments = (ins OptionalAttr<LVX_WideMultAttr>:$widemult,
                       LVX_RegType:$a,
                       LVX_RegType:$b,
                       LVX_RegType:$c,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($widemult^)? $a `,` $b `,` $c attr-dict `:` `(` qualified(type($a)) `,` qualified(type($b)) `,` qualified(type($c)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$a, "::mlir::Value":$b, "::mlir::Value":$c, CArg<"::mlir::lvx::WideMultAttr", "{}">:$widemult), [{
      build($_builder, $_state, resultType, widemult, a, b, c, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MSBFXWD -- immediate form, from MSBFXWD_widemult_registerW_registerZ_upper27_lower5_splat32_double
def LVX_MsbfxwdImmOp : LVX_Op<"msbfxwd_i", [Pure]>{
  let summary = "MSBFXWD -- Multiply Subtract From Extend Word to Double Word";
  let arguments = (ins OptionalAttr<LVX_WideMultAttr>:$widemult,
                       UnitAttr:$splat32,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`splat32` $splat32^)? ($widemult^)? $lhs `,` $upper27_lower5 `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs, "::mlir::TypedAttr":$upper27_lower5, CArg<"::mlir::lvx::WideMultAttr", "{}">:$widemult), [{
      build($_builder, $_state, resultType, widemult, ::mlir::UnitAttr(), lhs, rhs, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MSBFXWDP -- register form, from MSBFXWDP_widemult_registerM_registerZ_registerY_simple
def LVX_MsbfxwdpOp : LVX_Op<"msbfxwdp", [Pure]>{
  let summary = "MSBFXWDP -- Multiply Subtract From Extend Word to Double Word Pair";
  let arguments = (ins OptionalAttr<LVX_WideMultAttr>:$widemult,
                       LVX_RegType:$a,
                       LVX_RegType:$b,
                       LVX_RegType:$c,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($widemult^)? $a `,` $b `,` $c attr-dict `:` `(` qualified(type($a)) `,` qualified(type($b)) `,` qualified(type($c)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$a, "::mlir::Value":$b, "::mlir::Value":$c, CArg<"::mlir::lvx::WideMultAttr", "{}">:$widemult), [{
      build($_builder, $_state, resultTypes, widemult, a, b, c, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MSBFXHWQ -- register form, from MSBFXHWQ_widemult_registerM_registerZ_registerY_simple
def LVX_MsbfxhwqOp : LVX_Op<"msbfxhwq", [Pure]>{
  let summary = "MSBFXHWQ -- Multiply Subtract From Extend Half Word to Word Quadruple";
  let arguments = (ins OptionalAttr<LVX_WideMultAttr>:$widemult,
                       LVX_RegType:$a,
                       LVX_RegType:$b,
                       LVX_RegType:$c,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($widemult^)? $a `,` $b `,` $c attr-dict `:` `(` qualified(type($a)) `,` qualified(type($b)) `,` qualified(type($c)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$a, "::mlir::Value":$b, "::mlir::Value":$c, CArg<"::mlir::lvx::WideMultAttr", "{}">:$widemult), [{
      build($_builder, $_state, resultTypes, widemult, a, b, c, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:MSBFXBHO -- register form, from MSBFXBHO_widemult_registerM_registerZ_registerY_simple
def LVX_MsbfxbhoOp : LVX_Op<"msbfxbho", [Pure]>{
  let summary = "MSBFXBHO -- Multiply Subtract From Extend Byte to Half Word Octuple";
  let arguments = (ins OptionalAttr<LVX_WideMultAttr>:$widemult,
                       LVX_RegType:$a,
                       LVX_RegType:$b,
                       LVX_RegType:$c,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($widemult^)? $a `,` $b `,` $c attr-dict `:` `(` qualified(type($a)) `,` qualified(type($b)) `,` qualified(type($c)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$a, "::mlir::Value":$b, "::mlir::Value":$c, CArg<"::mlir::lvx::WideMultAttr", "{}">:$widemult), [{
      build($_builder, $_state, resultTypes, widemult, a, b, c, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:DIVMODD -- register form, from DIVMODD_registerM_registerZ_registerY_simple
def LVX_DivmoddOp : LVX_Op<"divmodd", [Pure]>{
  let summary = "DIVMODD -- Integer Division Modulus Double Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
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
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`sx` $sx^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
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
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
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
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`sx` $sx^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:TRUNCDWQ -- register form, from TRUNCDWQ_registerM_registerR_simple
def LVX_TruncdwqOp : LVX_Op<"truncdwq", [Pure]>{
  let summary = "TRUNCDWQ -- Truncate Double Word to Word Quadruple";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:TRUNCWHO -- register form, from TRUNCWHO_registerM_registerR_simple
def LVX_TruncwhoOp : LVX_Op<"truncwho", [Pure]>{
  let summary = "TRUNCWHO -- Truncate Word to Half Word Octuple";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:TRUNCHBX -- register form, from TRUNCHBX_registerM_registerR_simple
def LVX_TrunchbxOp : LVX_Op<"trunchbx", [Pure]>{
  let summary = "TRUNCHBX -- Truncate Half Word to Byte Hexadecuple";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:FRACTDWQ -- register form, from FRACTDWQ_registerM_registerR_simple
def LVX_FractdwqOp : LVX_Op<"fractdwq", [Pure]>{
  let summary = "FRACTDWQ -- Fraction Double Word to Word Quadruple";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:FRACTWHO -- register form, from FRACTWHO_registerM_registerR_simple
def LVX_FractwhoOp : LVX_Op<"fractwho", [Pure]>{
  let summary = "FRACTWHO -- Fraction Word to Half Word Octuple";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:FRACTHBX -- register form, from FRACTHBX_registerM_registerR_simple
def LVX_FracthbxOp : LVX_Op<"fracthbx", [Pure]>{
  let summary = "FRACTHBX -- Fraction Half Word to Byte Hexadecuple";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:CRCBELMW -- register form, from CRCBELMW_registerW_registerZ_registerY_simple
def LVX_CrcbelmwOp : LVX_Op<"crcbelmw", [Pure]>{
  let summary = "CRCBELMW -- Cyclic Redundancy Check Big-Endian Least Significant with Most Significant Word";
  let arguments = (ins LVX_RegType:$a,
                       LVX_RegType:$b,
                       LVX_RegType:$c,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$a `,` $b `,` $c attr-dict `:` `(` qualified(type($a)) `,` qualified(type($b)) `,` qualified(type($c)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$a, "::mlir::Value":$b, "::mlir::Value":$c), [{
      build($_builder, $_state, resultType, a, b, c, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:CRCBELMW -- immediate form, from CRCBELMW_registerW_registerZ_upper27_lower5_double
def LVX_CrcbelmwImmOp : LVX_Op<"crcbelmw_i", [Pure]>{
  let summary = "CRCBELMW -- Cyclic Redundancy Check Big-Endian Least Significant with Most Significant Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $upper27_lower5 `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, lhs, rhs, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:CRCBELLW -- register form, from CRCBELLW_registerW_registerZ_registerY_simple
def LVX_CrcbellwOp : LVX_Op<"crcbellw", [Pure]>{
  let summary = "CRCBELLW -- Cyclic Redundancy Check Big-Endian Least Significant with Least Significant Word";
  let arguments = (ins LVX_RegType:$a,
                       LVX_RegType:$b,
                       LVX_RegType:$c,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$a `,` $b `,` $c attr-dict `:` `(` qualified(type($a)) `,` qualified(type($b)) `,` qualified(type($c)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$a, "::mlir::Value":$b, "::mlir::Value":$c), [{
      build($_builder, $_state, resultType, a, b, c, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:CRCBELLW -- immediate form, from CRCBELLW_registerW_registerZ_upper27_lower5_double
def LVX_CrcbellwImmOp : LVX_Op<"crcbellw_i", [Pure]>{
  let summary = "CRCBELLW -- Cyclic Redundancy Check Big-Endian Least Significant with Least Significant Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $upper27_lower5 `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, lhs, rhs, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:CRCLELMW -- register form, from CRCLELMW_registerW_registerZ_registerY_simple
def LVX_CrclelmwOp : LVX_Op<"crclelmw", [Pure]>{
  let summary = "CRCLELMW -- Cyclic Redundancy Check Little-Endian Least Significant with Most Significant Word";
  let arguments = (ins LVX_RegType:$a,
                       LVX_RegType:$b,
                       LVX_RegType:$c,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$a `,` $b `,` $c attr-dict `:` `(` qualified(type($a)) `,` qualified(type($b)) `,` qualified(type($c)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$a, "::mlir::Value":$b, "::mlir::Value":$c), [{
      build($_builder, $_state, resultType, a, b, c, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:CRCLELMW -- immediate form, from CRCLELMW_registerW_registerZ_upper27_lower5_double
def LVX_CrclelmwImmOp : LVX_Op<"crclelmw_i", [Pure]>{
  let summary = "CRCLELMW -- Cyclic Redundancy Check Little-Endian Least Significant with Most Significant Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $upper27_lower5 `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, lhs, rhs, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:CRCLELLW -- register form, from CRCLELLW_registerW_registerZ_registerY_simple
def LVX_CrclellwOp : LVX_Op<"crclellw", [Pure]>{
  let summary = "CRCLELLW -- Cyclic Redundancy Check Little-Endian Least Significant with Least Significant Word";
  let arguments = (ins LVX_RegType:$a,
                       LVX_RegType:$b,
                       LVX_RegType:$c,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$a `,` $b `,` $c attr-dict `:` `(` qualified(type($a)) `,` qualified(type($b)) `,` qualified(type($c)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$a, "::mlir::Value":$b, "::mlir::Value":$c), [{
      build($_builder, $_state, resultType, a, b, c, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:CRCLELLW -- immediate form, from CRCLELLW_registerW_registerZ_upper27_lower5_double
def LVX_CrclellwImmOp : LVX_Op<"crclellw_i", [Pure]>{
  let summary = "CRCLELLW -- Cyclic Redundancy Check Little-Endian Least Significant with Least Significant Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       TypedAttrInterface:$upper27_lower5,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "$lhs `,` $upper27_lower5 `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs, "::mlir::TypedAttr":$upper27_lower5), [{
      build($_builder, $_state, resultType, lhs, rhs, upper27_lower5, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FADDD -- register form, from FADDD_floatmode_registerW_registerZ_registerY_simple
def LVX_FadddOp : LVX_Op<"faddd", [Pure]>{
  let summary = "FADDD -- Floating-Point Add Double Word";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($floatmode^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, floatmode, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FADDDP -- register form, from FADDDP_floatmode_registerM_registerP_registerO_simple
def LVX_FadddpOp : LVX_Op<"fadddp", [Pure]>{
  let summary = "FADDDP -- Floating-Point Add Double Word Pair";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($floatmode^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultTypes, floatmode, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FADDW -- register form, from FADDW_floatmode_registerW_registerZ_registerY_simple
def LVX_FaddwOp : LVX_Op<"faddw", [Pure]>{
  let summary = "FADDW -- Floating-Point Add Word";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($floatmode^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, floatmode, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FADDWQ -- register form, from FADDWQ_floatmode_registerM_registerP_registerO_simple
def LVX_FaddwqOp : LVX_Op<"faddwq", [Pure]>{
  let summary = "FADDWQ -- Floating-Point Add Word Quadruple";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($floatmode^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultTypes, floatmode, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FADDH -- register form, from FADDH_floatmode_registerW_registerZ_registerY_simple
def LVX_FaddhOp : LVX_Op<"faddh", [Pure]>{
  let summary = "FADDH -- Floating-Point Add Half Word";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($floatmode^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, floatmode, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FADDHO -- register form, from FADDHO_floatmode_registerM_registerP_registerO_simple
def LVX_FaddhoOp : LVX_Op<"faddho", [Pure]>{
  let summary = "FADDHO -- Floating-Point Add Half Word Octuple";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($floatmode^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultTypes, floatmode, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FSBFD -- register form, from FSBFD_floatmode_registerW_registerZ_registerY_simple
def LVX_FsbfdOp : LVX_Op<"fsbfd", [Pure]>{
  let summary = "FSBFD -- Floating-Point Subtract From Double Word";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($floatmode^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, floatmode, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FSBFDP -- register form, from FSBFDP_floatmode_registerM_registerP_registerO_simple
def LVX_FsbfdpOp : LVX_Op<"fsbfdp", [Pure]>{
  let summary = "FSBFDP -- Floating-Point Subtract From Double Word Pair";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($floatmode^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultTypes, floatmode, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FSBFW -- register form, from FSBFW_floatmode_registerW_registerZ_registerY_simple
def LVX_FsbfwOp : LVX_Op<"fsbfw", [Pure]>{
  let summary = "FSBFW -- Floating-Point Subtract From Word";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($floatmode^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, floatmode, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FSBFWQ -- register form, from FSBFWQ_floatmode_registerM_registerP_registerO_simple
def LVX_FsbfwqOp : LVX_Op<"fsbfwq", [Pure]>{
  let summary = "FSBFWQ -- Floating-Point Subtract From Word Quadruple";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($floatmode^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultTypes, floatmode, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FSBFH -- register form, from FSBFH_floatmode_registerW_registerZ_registerY_simple
def LVX_FsbfhOp : LVX_Op<"fsbfh", [Pure]>{
  let summary = "FSBFH -- Floating-Point Subtract From Half Word";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "($floatmode^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, floatmode, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FSBFHO -- register form, from FSBFHO_floatmode_registerM_registerP_registerO_simple
def LVX_FsbfhoOp : LVX_Op<"fsbfho", [Pure]>{
  let summary = "FSBFHO -- Floating-Point Subtract From Half Word Octuple";
  let arguments = (ins OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "($floatmode^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultTypes, floatmode, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FMULD -- register form, from FMULD_fnegate_floatmode_registerW_registerZ_registerY_simple
def LVX_FmuldOp : LVX_Op<"fmuld", [Pure]>{
  let summary = "FMULD -- Floating-Point Multiply Double Word";
  let arguments = (ins UnitAttr:$n,
                       OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`n` $n^)? ($floatmode^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), floatmode, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FMULDP -- register form, from FMULDP_fnegate_floatmode_registerM_registerP_registerO_simple
def LVX_FmuldpOp : LVX_Op<"fmuldp", [Pure]>{
  let summary = "FMULDP -- Floating-Point Multiply Double Word Pair";
  let arguments = (ins UnitAttr:$n,
                       OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`n` $n^)? ($floatmode^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), floatmode, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FMULW -- register form, from FMULW_fnegate_floatmode_registerW_registerZ_registerY_simple
def LVX_FmulwOp : LVX_Op<"fmulw", [Pure]>{
  let summary = "FMULW -- Floating-Point Multiply Word";
  let arguments = (ins UnitAttr:$n,
                       OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`n` $n^)? ($floatmode^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), floatmode, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FMULWQ -- register form, from FMULWQ_fnegate_floatmode_registerM_registerP_registerO_simple
def LVX_FmulwqOp : LVX_Op<"fmulwq", [Pure]>{
  let summary = "FMULWQ -- Floating-Point Multiply Word Quadruple";
  let arguments = (ins UnitAttr:$n,
                       OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`n` $n^)? ($floatmode^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), floatmode, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FMULH -- register form, from FMULH_fnegate_floatmode_registerW_registerZ_registerY_simple
def LVX_FmulhOp : LVX_Op<"fmulh", [Pure]>{
  let summary = "FMULH -- Floating-Point Multiply Half Word";
  let arguments = (ins UnitAttr:$n,
                       OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`n` $n^)? ($floatmode^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), floatmode, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FMULHO -- register form, from FMULHO_fnegate_floatmode_registerM_registerP_registerO_simple
def LVX_FmulhoOp : LVX_Op<"fmulho", [Pure]>{
  let summary = "FMULHO -- Floating-Point Multiply Half Word Octuple";
  let arguments = (ins UnitAttr:$n,
                       OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`n` $n^)? ($floatmode^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), floatmode, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FDIVD -- register form, from FDIVD_fnegate_floatmode_registerW_registerZ_registerY_simple
def LVX_FdivdOp : LVX_Op<"fdivd", [Pure]>{
  let summary = "FDIVD -- Floating-Point Divide Double Word";
  let arguments = (ins UnitAttr:$n,
                       OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`n` $n^)? ($floatmode^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), floatmode, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FDIVW -- register form, from FDIVW_fnegate_floatmode_registerW_registerZ_registerY_simple
def LVX_FdivwOp : LVX_Op<"fdivw", [Pure]>{
  let summary = "FDIVW -- Floating-Point Divide Word";
  let arguments = (ins UnitAttr:$n,
                       OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`n` $n^)? ($floatmode^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), floatmode, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FDIVH -- register form, from FDIVH_fnegate_floatmode_registerW_registerZ_registerY_simple
def LVX_FdivhOp : LVX_Op<"fdivh", [Pure]>{
  let summary = "FDIVH -- Floating-Point Divide Half Word";
  let arguments = (ins UnitAttr:$n,
                       OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`n` $n^)? ($floatmode^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), floatmode, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FFMAD -- register form, from FFMAD_fnegate_floatmode_registerW_registerZ_registerY_simple
def LVX_FfmadOp : LVX_Op<"ffmad", [Pure]>{
  let summary = "FFMAD -- Floating-Point Fused Multiply Add Double Word";
  let arguments = (ins UnitAttr:$n,
                       OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$a,
                       LVX_RegType:$b,
                       LVX_RegType:$c,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`n` $n^)? ($floatmode^)? $a `,` $b `,` $c attr-dict `:` `(` qualified(type($a)) `,` qualified(type($b)) `,` qualified(type($c)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$a, "::mlir::Value":$b, "::mlir::Value":$c, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), floatmode, a, b, c, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FFMADP -- register form, from FFMADP_fnegate_floatmode_registerM_registerP_registerO_simple
def LVX_FfmadpOp : LVX_Op<"ffmadp", [Pure]>{
  let summary = "FFMADP -- Floating-Point Fused Multiply Add Double Word Pair";
  let arguments = (ins UnitAttr:$n,
                       OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$a,
                       LVX_RegType:$b,
                       LVX_RegType:$c,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`n` $n^)? ($floatmode^)? $a `,` $b `,` $c attr-dict `:` `(` qualified(type($a)) `,` qualified(type($b)) `,` qualified(type($c)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$a, "::mlir::Value":$b, "::mlir::Value":$c, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), floatmode, a, b, c, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FFMAW -- register form, from FFMAW_fnegate_floatmode_registerW_registerZ_registerY_simple
def LVX_FfmawOp : LVX_Op<"ffmaw", [Pure]>{
  let summary = "FFMAW -- Floating-Point Fused Multiply Add Word";
  let arguments = (ins UnitAttr:$n,
                       OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$a,
                       LVX_RegType:$b,
                       LVX_RegType:$c,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`n` $n^)? ($floatmode^)? $a `,` $b `,` $c attr-dict `:` `(` qualified(type($a)) `,` qualified(type($b)) `,` qualified(type($c)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$a, "::mlir::Value":$b, "::mlir::Value":$c, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), floatmode, a, b, c, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FFMAH -- register form, from FFMAH_fnegate_floatmode_registerW_registerZ_registerY_simple
def LVX_FfmahOp : LVX_Op<"ffmah", [Pure]>{
  let summary = "FFMAH -- Floating-Point Fused Multiply Add Half Word";
  let arguments = (ins UnitAttr:$n,
                       OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$a,
                       LVX_RegType:$b,
                       LVX_RegType:$c,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`n` $n^)? ($floatmode^)? $a `,` $b `,` $c attr-dict `:` `(` qualified(type($a)) `,` qualified(type($b)) `,` qualified(type($c)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$a, "::mlir::Value":$b, "::mlir::Value":$c, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), floatmode, a, b, c, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FFMAWQ -- register form, from FFMAWQ_fnegate_floatmode_registerM_registerP_registerO_simple
def LVX_FfmawqOp : LVX_Op<"ffmawq", [Pure]>{
  let summary = "FFMAWQ -- Floating-Point Fused Multiply Add Word Quadruple";
  let arguments = (ins UnitAttr:$n,
                       OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$a,
                       LVX_RegType:$b,
                       LVX_RegType:$c,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`n` $n^)? ($floatmode^)? $a `,` $b `,` $c attr-dict `:` `(` qualified(type($a)) `,` qualified(type($b)) `,` qualified(type($c)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$a, "::mlir::Value":$b, "::mlir::Value":$c, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), floatmode, a, b, c, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FFMAHO -- register form, from FFMAHO_fnegate_floatmode_registerM_registerP_registerO_simple
def LVX_FfmahoOp : LVX_Op<"ffmaho", [Pure]>{
  let summary = "FFMAHO -- Floating-Point Fused Multiply Add Half Word Octuple";
  let arguments = (ins UnitAttr:$n,
                       OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$a,
                       LVX_RegType:$b,
                       LVX_RegType:$c,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`n` $n^)? ($floatmode^)? $a `,` $b `,` $c attr-dict `:` `(` qualified(type($a)) `,` qualified(type($b)) `,` qualified(type($c)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$a, "::mlir::Value":$b, "::mlir::Value":$c, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), floatmode, a, b, c, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FFMSD -- register form, from FFMSD_fnegate_floatmode_registerW_registerZ_registerY_simple
def LVX_FfmsdOp : LVX_Op<"ffmsd", [Pure]>{
  let summary = "FFMSD -- Floating-Point Fused Multiply Subtract From Double Word";
  let arguments = (ins UnitAttr:$n,
                       OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$a,
                       LVX_RegType:$b,
                       LVX_RegType:$c,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`n` $n^)? ($floatmode^)? $a `,` $b `,` $c attr-dict `:` `(` qualified(type($a)) `,` qualified(type($b)) `,` qualified(type($c)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$a, "::mlir::Value":$b, "::mlir::Value":$c, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), floatmode, a, b, c, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FFMSDP -- register form, from FFMSDP_fnegate_floatmode_registerM_registerP_registerO_simple
def LVX_FfmsdpOp : LVX_Op<"ffmsdp", [Pure]>{
  let summary = "FFMSDP -- Floating-Point Fused Multiply Subtract From Double Word Pair";
  let arguments = (ins UnitAttr:$n,
                       OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$a,
                       LVX_RegType:$b,
                       LVX_RegType:$c,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`n` $n^)? ($floatmode^)? $a `,` $b `,` $c attr-dict `:` `(` qualified(type($a)) `,` qualified(type($b)) `,` qualified(type($c)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$a, "::mlir::Value":$b, "::mlir::Value":$c, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), floatmode, a, b, c, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FFMSW -- register form, from FFMSW_fnegate_floatmode_registerW_registerZ_registerY_simple
def LVX_FfmswOp : LVX_Op<"ffmsw", [Pure]>{
  let summary = "FFMSW -- Floating-Point Fused Multiply Subtract From Word";
  let arguments = (ins UnitAttr:$n,
                       OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$a,
                       LVX_RegType:$b,
                       LVX_RegType:$c,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`n` $n^)? ($floatmode^)? $a `,` $b `,` $c attr-dict `:` `(` qualified(type($a)) `,` qualified(type($b)) `,` qualified(type($c)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$a, "::mlir::Value":$b, "::mlir::Value":$c, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), floatmode, a, b, c, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FFMSH -- register form, from FFMSH_fnegate_floatmode_registerW_registerZ_registerY_simple
def LVX_FfmshOp : LVX_Op<"ffmsh", [Pure]>{
  let summary = "FFMSH -- Floating-Point Fused Multiply Subtract From Half Word";
  let arguments = (ins UnitAttr:$n,
                       OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$a,
                       LVX_RegType:$b,
                       LVX_RegType:$c,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`n` $n^)? ($floatmode^)? $a `,` $b `,` $c attr-dict `:` `(` qualified(type($a)) `,` qualified(type($b)) `,` qualified(type($c)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$a, "::mlir::Value":$b, "::mlir::Value":$c, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), floatmode, a, b, c, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FFMSWQ -- register form, from FFMSWQ_fnegate_floatmode_registerM_registerP_registerO_simple
def LVX_FfmswqOp : LVX_Op<"ffmswq", [Pure]>{
  let summary = "FFMSWQ -- Floating-Point Fused Multiply Subtract From Word Quadruple";
  let arguments = (ins UnitAttr:$n,
                       OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$a,
                       LVX_RegType:$b,
                       LVX_RegType:$c,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`n` $n^)? ($floatmode^)? $a `,` $b `,` $c attr-dict `:` `(` qualified(type($a)) `,` qualified(type($b)) `,` qualified(type($c)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$a, "::mlir::Value":$b, "::mlir::Value":$c, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), floatmode, a, b, c, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FFMSHO -- register form, from FFMSHO_fnegate_floatmode_registerM_registerP_registerO_simple
def LVX_FfmshoOp : LVX_Op<"ffmsho", [Pure]>{
  let summary = "FFMSHO -- Floating-Point Fused Multiply Subtract From Half Word Octuple";
  let arguments = (ins UnitAttr:$n,
                       OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$a,
                       LVX_RegType:$b,
                       LVX_RegType:$c,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "(`n` $n^)? ($floatmode^)? $a `,` $b `,` $c attr-dict `:` `(` qualified(type($a)) `,` qualified(type($b)) `,` qualified(type($c)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$a, "::mlir::Value":$b, "::mlir::Value":$c, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultTypes, ::mlir::UnitAttr(), floatmode, a, b, c, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FADDWC -- register form, from FADDWC_conjugate_imultiply_floatmode_registerW_registerZ_registerY_simple
def LVX_FaddwcOp : LVX_Op<"faddwc", [Pure]>{
  let summary = "FADDWC -- Floating-Point Add to Word Complex";
  let arguments = (ins UnitAttr:$c,
                       UnitAttr:$mi,
                       OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`mi` $mi^)? (`c` $c^)? ($floatmode^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), ::mlir::UnitAttr(), floatmode, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FSBFWC -- register form, from FSBFWC_conjugate_imultiply_floatmode_registerW_registerZ_registerY_simple
def LVX_FsbfwcOp : LVX_Op<"fsbfwc", [Pure]>{
  let summary = "FSBFWC -- Floating-Point Subtract from Word Complex";
  let arguments = (ins UnitAttr:$c,
                       UnitAttr:$mi,
                       OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`mi` $mi^)? (`c` $c^)? ($floatmode^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), ::mlir::UnitAttr(), floatmode, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FMULWC -- register form, from FMULWC_conjugate_imultiply_floatmode_registerW_registerZ_registerY_simple
def LVX_FmulwcOp : LVX_Op<"fmulwc", [Pure]>{
  let summary = "FMULWC -- Floating-Point Multiply Word Complex";
  let arguments = (ins UnitAttr:$c,
                       UnitAttr:$mi,
                       OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`mi` $mi^)? (`c` $c^)? ($floatmode^)? $lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$lhs, "::mlir::Value":$rhs, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), ::mlir::UnitAttr(), floatmode, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// FPU:FFMAWC -- register form, from FFMAWC_conjugate_imultiply_floatmode_registerW_registerZ_registerY_simple
def LVX_FfmawcOp : LVX_Op<"ffmawc", [Pure]>{
  let summary = "FFMAWC -- Floating-Point Multiply Add Word Complex";
  let arguments = (ins UnitAttr:$c,
                       UnitAttr:$mi,
                       OptionalAttr<LVX_FloatModeAttr>:$floatmode,
                       LVX_RegType:$a,
                       LVX_RegType:$b,
                       LVX_RegType:$cReg,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$result);
  let assemblyFormat = "(`mi` $mi^)? (`c` $c^)? ($floatmode^)? $a `,` $b `,` $cReg attr-dict `:` `(` qualified(type($a)) `,` qualified(type($b)) `,` qualified(type($cReg)) `)` `->` qualified(type($result))";
  let builders = [
    OpBuilder<(ins "::mlir::Type":$resultType, "::mlir::Value":$a, "::mlir::Value":$b, "::mlir::Value":$cReg, CArg<"::mlir::lvx::FloatModeAttr", "{}">:$floatmode), [{
      build($_builder, $_state, resultType, ::mlir::UnitAttr(), ::mlir::UnitAttr(), floatmode, a, b, cReg, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// LSU:COPYO -- register form, from COPYO_registerN_registerR_simple
def LVX_CopyoOp : LVX_Op<"copyo", [Pure]>{
  let summary = "COPYO -- Copy Octuple Word";
  let arguments = (ins LVX_RegType:$value,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$x, LVX_RegType:$y, LVX_RegType:$z, LVX_RegType:$t);
  let assemblyFormat = "$value attr-dict `:` `(` qualified(type($value)) `)` `->` `(` qualified(type($x)) `,` qualified(type($y)) `,` qualified(type($z)) `,` qualified(type($t)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$value), [{
      build($_builder, $_state, resultTypes, value, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:CATDQ -- register form, from CATDQ_registerM_registerZ_registerY_simple
def LVX_CatdqOp : LVX_Op<"catdq", [Pure]>{
  let summary = "CATDQ -- Catenate Double to Quadruple Word";
  let arguments = (ins LVX_RegType:$lhs,
                       LVX_RegType:$rhs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$lhs, "::mlir::Value":$rhs), [{
      build($_builder, $_state, resultTypes, lhs, rhs, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SPLATBQ -- register form, from SPLATBQ_registerM_registerZ_simple
def LVX_SplatbqOp : LVX_Op<"splatbq", [Pure]>{
  let summary = "SPLATBQ -- Splat Byte to Quadruple Word";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SPLATHQ -- register form, from SPLATHQ_registerM_registerZ_simple
def LVX_SplathqOp : LVX_Op<"splathq", [Pure]>{
  let summary = "SPLATHQ -- Splat Half Word to Quadruple Word";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SPLATWQ -- register form, from SPLATWQ_registerM_registerZ_simple
def LVX_SplatwqOp : LVX_Op<"splatwq", [Pure]>{
  let summary = "SPLATWQ -- Splat Word to Quadruple Word";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
    }]>
  ];
}

// ALU:SPLATDQ -- register form, from SPLATDQ_registerM_registerZ_simple
def LVX_SplatdqOp : LVX_Op<"splatdq", [Pure]>{
  let summary = "SPLATDQ -- Splat Double Word to Quadruple Word";
  let arguments = (ins LVX_RegType:$operand,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$operand attr-dict `:` `(` qualified(type($operand)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
  let builders = [
    OpBuilder<(ins "::mlir::TypeRange":$resultTypes, "::mlir::Value":$operand), [{
      build($_builder, $_state, resultTypes, operand, ::mlir::lvx::FormatAttr());
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
  let assemblyFormat = "$operand `,` $signed10 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
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
  let assemblyFormat = "$operand `,` $signed10 attr-dict `:` `(` qualified(type($operand)) `)` `->` qualified(type($result))";
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
  let results = (outs LVX_RegType:$lo, LVX_RegType:$hi);
  let assemblyFormat = "$lhs `,` $rhs attr-dict `:` `(` qualified(type($lhs)) `,` qualified(type($rhs)) `)` `->` `(` qualified(type($lo)) `,` qualified(type($hi)) `)`";
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

// BCU:ERROP -- register form, from ERROP_simple
def LVX_ErropOp : LVX_Op<"errop">{
  let summary = "ERROP -- Error opcode.";
  let arguments = (ins OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs );
  let assemblyFormat = "attr-dict";
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

// BCU:FRCSR -- register form, from FRCSR_registerZ_simple
def LVX_FrcsrOp : LVX_Op<"frcsr">{
  let summary = "FRCSR -- Read \texttt{fcsr} (pseudo of \texttt{csrrs} on \texttt{fcsr})";
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

// BCU:FSCSR -- register form, from FSCSR_registerZ_simple
def LVX_FscsrOp : LVX_Op<"fscsr">{
  let summary = "FSCSR -- Write \texttt{fcsr} (pseudo of \texttt{csrrw} on \texttt{fcsr})";
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

// BCU:FRFLAGS -- register form, from FRFLAGS_registerZ_simple
def LVX_FrflagsOp : LVX_Op<"frflags">{
  let summary = "FRFLAGS -- Read \texttt{fflags} (pseudo of \texttt{csrrs} on \texttt{fflags})";
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

// BCU:FSFLAGS -- register form, from FSFLAGS_registerZ_simple
def LVX_FsflagsOp : LVX_Op<"fsflags">{
  let summary = "FSFLAGS -- Write \texttt{fflags} (pseudo of \texttt{csrrw} on \texttt{fflags})";
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

// BCU:FRRM -- register form, from FRRM_registerZ_simple
def LVX_FrrmOp : LVX_Op<"frrm">{
  let summary = "FRRM -- Read \texttt{frm} (pseudo of \texttt{csrrs} on \texttt{frm})";
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

// BCU:FSRM -- register form, from FSRM_registerZ_simple
def LVX_FsrmOp : LVX_Op<"fsrm">{
  let summary = "FSRM -- Write \texttt{frm} (pseudo of \texttt{csrrw} on \texttt{frm})";
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

#endif // LVX_INSTR_OPS
