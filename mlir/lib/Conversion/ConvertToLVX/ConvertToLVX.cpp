//===- ConvertToLVX.cpp - Lower to LVX dialect ----------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "mlir/Conversion/ConvertToLVX/ConvertToLVX.h"

#include "mlir/Dialect/Arith/IR/Arith.h"
#include "mlir/Dialect/ControlFlow/IR/ControlFlowOps.h"
#include "mlir/Dialect/Func/IR/FuncOps.h"
#include "mlir/Dialect/Index/IR/IndexDialect.h"
#include "mlir/Dialect/Index/IR/IndexOps.h"
#include "mlir/Dialect/LVX/IR/LVX.h"
#include "mlir/Dialect/LVX/IR/RegisterUnits.h"
#include "mlir/Dialect/LVX/IR/LVXConvention.h"
#include "mlir/Dialect/LVXCF/IR/LVXCF.h"
#include "mlir/Dialect/LVXFunc/IR/LVXFunc.h"
#include "mlir/Dialect/LVXSCF/IR/LVXSCF.h"
#include "mlir/Dialect/Math/IR/Math.h"
#include "mlir/Dialect/MemRef/IR/MemRef.h"
#include "mlir/Dialect/SCF/IR/SCF.h"
#include "mlir/Dialect/Vector/IR/VectorOps.h"
#include "mlir/IR/IRMapping.h"
#include "mlir/Pass/Pass.h"
#include "mlir/Transforms/DialectConversion.h"

#include <optional>

namespace mlir {
#define GEN_PASS_DEF_CONVERTTOLVXPASS
#include "mlir/Conversion/Passes.h.inc"
} // namespace mlir

using namespace mlir;
using mlir::lvx::BcuCond;
using mlir::lvx::FloatComp;
using mlir::lvx::FloatMode;
using mlir::lvx::IntComp;
using mlir::lvx::RegisterType;
using mlir::lvx::Register;

// Per lvx-mds/lvx-refs' Convention.table, `Convention-lvx_v1-regular`, read
// from the generated LVXConvention.inc rather than transcribed.
static constexpr unsigned kMaxAbiArgRegs = lvx::kNumAbiArgRegs;
static constexpr unsigned kMaxAbiResultRegs = lvx::kNumAbiResultRegs;

// The n-th argument/result register. These used to be `static_cast<Register>(n)`
// -- correct only because `Convention-lvx_v1-regular` happens to start both
// sets at $r0 and run them contiguously. Nothing in the ABI promises that, and
// a description that reordered or renumbered either set would have left every
// call site here compiling and silently passing arguments in the wrong
// registers, which is precisely the failure a generated table removes.
static lvx::Register abiArgReg(unsigned n) {
  assert(n < lvx::kNumAbiArgRegs && "argument index beyond the ABI's capacity");
  return lvx::kAbiArgRegs[n];
}
/// A scalar pattern must not fire on a vector-typed op: it would pick a
/// mnemonic by "element width" and, on the way, ask a VectorType for its bit
/// width -- an assertion, not a diagnostic. A vector op either has its own
/// pattern below or has no lowering at all, and then the conversion must
/// *fail*, which is what docs/VectorCoverage.md measures as class D.
static LogicalResult rejectVectors(Operation *op,
                                   ConversionPatternRewriter &rewriter) {
  auto isVector = [](Type t) { return isa<VectorType>(t); };
  if (llvm::any_of(op->getOperandTypes(), isVector) ||
      llvm::any_of(op->getResultTypes(), isVector))
    return rewriter.notifyMatchFailure(op, "no lowering for this op on vectors");
  return success();
}

static lvx::Register abiResultReg(unsigned n) {
  assert(n < lvx::kNumAbiResultRegs && "result index beyond the ABI's capacity");
  return lvx::kAbiResultRegs[n];
}

namespace {

//===----------------------------------------------------------------------===//
// Type converter: builtin scalars and memrefs become `!lvx.reg`.
//===----------------------------------------------------------------------===//

class LVXTypeConverter : public TypeConverter {
public:
  LVXTypeConverter(MLIRContext *ctx) {
    addConversion([](Type type) { return type; });
    addConversion([ctx](IntegerType) -> Type {
      return RegisterType::get(ctx, std::nullopt);
    });
    addConversion([ctx](IndexType) -> Type {
      return RegisterType::get(ctx, std::nullopt);
    });
    addConversion([ctx](FloatType) -> Type {
      return RegisterType::get(ctx, std::nullopt);
    });
    addConversion([ctx](MemRefType) -> Type {
      return RegisterType::get(ctx, std::nullopt);
    });
    // A vector is the register tuple that holds it: 128 bits a pair, 256 a
    // quad (lvx-mds/docs/MLIR-backend-design.md §8.7). What the lanes are is
    // not in the type -- it is in which op consumes the tuple, as with
    // `!lvx.reg` and i32/i64/f64. Any other shape has no register to live
    // in and is left unconverted, which fails the conversion loudly.
    addConversion([ctx](VectorType type) -> std::optional<Type> {
      if (type.isScalable() || type.getRank() != 1)
        return std::nullopt;
      // A mask is not data: `vector<Nxi1>` is one bit per lane in an
      // ordinary register, which is what `comp*q`/`fcomp*q` write and what
      // `blend*` and the `masks` prefix read (docs/VectorCoverage.md §1,
      // "Mask granularity"). The lane count is the *masked* vector's, so
      // every tuple shape's lane count is legal; the type says nothing
      // about how wide the masked lanes are, and nothing needs it to.
      if (type.getElementTypeBitWidth() == 1) {
        unsigned lanes = type.getNumElements();
        if (lanes >= 2 && lanes <= 32 && llvm::isPowerOf2_32(lanes))
          return RegisterType::get(ctx, std::nullopt);
        return std::nullopt;
      }
      switch (type.getElementTypeBitWidth() * type.getNumElements()) {
      case 128:
        return lvx::PairType::get(ctx, std::nullopt);
      case 256:
        return lvx::QuadType::get(ctx, std::nullopt);
      }
      return std::nullopt;
    });
  }
};

//===----------------------------------------------------------------------===//
// Small helpers shared by several patterns.
//===----------------------------------------------------------------------===//

/// Bit width of a scalar type for the purposes of picking a `d` (64-bit) or
/// `w` (32-bit) LVX mnemonic. `index` is treated as the native 64-bit
/// register width.
static unsigned getScalarBitWidth(Type type) {
  if (isa<IndexType>(type))
    return 64;
  return type.getIntOrFloatBitWidth();
}

template <typename DOp, typename WOp>
static Value createIntBinary(ConversionPatternRewriter &rewriter, Location loc,
                             unsigned width, Type regTy, Value lhs, Value rhs) {
  if (width <= 32)
    return rewriter.create<WOp>(loc, regTy, lhs, rhs);
  return rewriter.create<DOp>(loc, regTy, lhs, rhs);
}

template <typename DOp, typename WOp>
static Value createFloatBinary(ConversionPatternRewriter &rewriter,
                               Location loc, unsigned width, Type regTy,
                               Value lhs, Value rhs) {
  if (width <= 32)
    return rewriter.create<WOp>(loc, regTy, lhs, rhs);
  return rewriter.create<DOp>(loc, regTy, lhs, rhs);
}

//===----------------------------------------------------------------------===//
// Integer arithmetic
//===----------------------------------------------------------------------===//

template <typename SourceOp, typename DOp, typename WOp>
struct IntBinaryToLVX : public OpConversionPattern<SourceOp> {
  using OpConversionPattern<SourceOp>::OpConversionPattern;
  using OpAdaptor = typename OpConversionPattern<SourceOp>::OpAdaptor;
  LogicalResult
  matchAndRewrite(SourceOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    if (failed(rejectVectors(op, rewriter)))
      return failure();
    Type regTy = this->getTypeConverter()->convertType(op.getType());
    unsigned width = getScalarBitWidth(op.getType());
    Value result = createIntBinary<DOp, WOp>(rewriter, op.getLoc(), width,
                                             regTy, adaptor.getLhs(),
                                             adaptor.getRhs());
    rewriter.replaceOp(op, result);
    return success();
  }
};

using AddIToLVX = IntBinaryToLVX<arith::AddIOp, lvx::AdddOp, lvx::AddwOp>;
using SubIToLVX = IntBinaryToLVX<arith::SubIOp, lvx::SbfdOp, lvx::SbfwOp>;
using MulIToLVX = IntBinaryToLVX<arith::MulIOp, lvx::MuldOp, lvx::MulwOp>;
using AndIToLVX = IntBinaryToLVX<arith::AndIOp, lvx::AnddOp, lvx::AndwOp>;
using OrIToLVX  = IntBinaryToLVX<arith::OrIOp,  lvx::IordOp, lvx::IorwOp>;
using XOrIToLVX = IntBinaryToLVX<arith::XOrIOp, lvx::EordOp, lvx::EorwOp>;
using ShLIToLVX  = IntBinaryToLVX<arith::ShLIOp,  lvx::SlldOp, lvx::SllwOp>;
using ShRSIToLVX = IntBinaryToLVX<arith::ShRSIOp, lvx::SradOp, lvx::SrawOp>;
using ShRUIToLVX = IntBinaryToLVX<arith::ShRUIOp, lvx::SrldOp, lvx::SrlwOp>;

// Signed/unsigned divide and remainder: LVX only offers a fused divide-modulo
// instruction, so each of {div,rem}{s,u}i independently emits its own
// `divmod{d,w}{,u}` and reads the quotient or remainder out of its result.
// That result is one `!lvx.pair` -- the hardware writes an aligned register
// pair, quotient in the even register -- and the lane it wants is an
// `lvx.lane` view, which costs no instruction once the pair is allocated
// (lvx-mlir/docs/RegisterAllocation.md, "Lane views"). This duplicates the
// divmod computation when a kernel needs both quotient and remainder from
// the same operands; a future CSE pass can merge them.
template <typename SourceOp, typename DOp, typename WOp, unsigned Lane>
struct DivModToLVX : public OpConversionPattern<SourceOp> {
  using OpConversionPattern<SourceOp>::OpConversionPattern;
  using OpAdaptor = typename OpConversionPattern<SourceOp>::OpAdaptor;
  LogicalResult
  matchAndRewrite(SourceOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    if (failed(rejectVectors(op, rewriter)))
      return failure();
    Type regTy = this->getTypeConverter()->convertType(op.getType());
    Type pairTy = lvx::PairType::get(rewriter.getContext());
    unsigned width = getScalarBitWidth(op.getType());
    Value divmod;
    if (width <= 32)
      divmod = rewriter.create<WOp>(op.getLoc(), pairTy, adaptor.getLhs(),
                                    adaptor.getRhs());
    else
      divmod = rewriter.create<DOp>(op.getLoc(), pairTy, adaptor.getLhs(),
                                    adaptor.getRhs());
    rewriter.replaceOpWithNewOp<lvx::LaneOp>(op, regTy, divmod, Lane);
    return success();
  }
};

using DivSIToLVX = DivModToLVX<arith::DivSIOp, lvx::DivmoddOp, lvx::DivmodwOp, 0>;
using DivUIToLVX = DivModToLVX<arith::DivUIOp, lvx::DivmodudOp, lvx::DivmoduwOp, 0>;
using RemSIToLVX = DivModToLVX<arith::RemSIOp, lvx::DivmoddOp, lvx::DivmodwOp, 1>;
using RemUIToLVX = DivModToLVX<arith::RemUIOp, lvx::DivmodudOp, lvx::DivmoduwOp, 1>;

//===----------------------------------------------------------------------===//
// Float arithmetic
//===----------------------------------------------------------------------===//

template <typename SourceOp, typename DOp, typename WOp>
struct FloatBinaryToLVX : public OpConversionPattern<SourceOp> {
  using OpConversionPattern<SourceOp>::OpConversionPattern;
  using OpAdaptor = typename OpConversionPattern<SourceOp>::OpAdaptor;
  LogicalResult
  matchAndRewrite(SourceOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    if (failed(rejectVectors(op, rewriter)))
      return failure();
    Type regTy = this->getTypeConverter()->convertType(op.getType());
    unsigned width = getScalarBitWidth(op.getType());
    Value result = createFloatBinary<DOp, WOp>(rewriter, op.getLoc(), width,
                                               regTy, adaptor.getLhs(),
                                               adaptor.getRhs());
    rewriter.replaceOp(op, result);
    return success();
  }
};

using AddFToLVX = FloatBinaryToLVX<arith::AddFOp, lvx::FadddOp, lvx::FaddwOp>;
using SubFToLVX = FloatBinaryToLVX<arith::SubFOp, lvx::FsbfdOp, lvx::FsbfwOp>;
using MulFToLVX = FloatBinaryToLVX<arith::MulFOp, lvx::FmuldOp, lvx::FmulwOp>;
using DivFToLVX = FloatBinaryToLVX<arith::DivFOp, lvx::FdivdOp, lvx::FdivwOp>;

// `math.fma a, b, c` is `a*b + c` -- the same operand order as real
// `FFMAD`/`FFMAW`, whose `c` is the accumulator. Note the real instruction
// has only *two* explicit source registers (`ffmaw $rW = $rZ, $rY`): the
// destination doubles as `c`. That tie is not expressed here; the register
// allocator coalesces the `c` operand with the result into one physical
// register (lvx-mlir/docs/RegisterAllocation.md, "`ffma`/`ffms` accumulator
// coalescing"), and -lvx-emit-asm prints the two-source form.
//
// Only `math.fma` maps here, never a `mulf`+`addf` pair: fusing rounds once
// where the pair rounds twice, so silently contracting them would change
// results behind the author's back. Requiring the source to say `math.fma`
// keeps that an explicit choice.
static FailureOr<Value> lowerVectorFma(ConversionPatternRewriter &rewriter,
                                       const TypeConverter &typeConverter,
                                       Operation *op, Value lhs, Value rhs,
                                       Value acc, Value originalLhs,
                                       Value originalRhs);

// `math.fma` on a vector type -- what the affine super-vectorizer emits for
// a vectorized `math.fma`, where `vector.fma` is what a hand-written vector
// kernel says -- is the same instruction as `vector.fma` (below).
struct FmaToLVX : public OpConversionPattern<math::FmaOp> {
  using OpConversionPattern::OpConversionPattern;
  LogicalResult
  matchAndRewrite(math::FmaOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    if (isa<VectorType>(op.getType())) {
      FailureOr<Value> result = lowerVectorFma(
          rewriter, *getTypeConverter(), op, adaptor.getA(), adaptor.getB(),
          adaptor.getC(), op.getA(), op.getB());
      if (failed(result))
        return failure();
      rewriter.replaceOp(op, *result);
      return success();
    }
    Type regTy = getTypeConverter()->convertType(op.getType());
    unsigned width = getScalarBitWidth(op.getType());
    Value result;
    if (width <= 32)
      result = rewriter.create<lvx::FfmawOp>(op.getLoc(), regTy,
                                             adaptor.getA(), adaptor.getB(),
                                             adaptor.getC());
    else
      result = rewriter.create<lvx::FfmadOp>(op.getLoc(), regTy,
                                             adaptor.getA(), adaptor.getB(),
                                             adaptor.getC());
    rewriter.replaceOp(op, result);
    return success();
  }
};

// arith.negf has no direct LVX opcode; lower to `0.0 - operand`.
// Float min/max have the same shape as an integer binary op: two operands,
// no rounding-mode modifier, because a selection has nothing to round.
template <typename SourceOp, typename DOp, typename WOp>
using FloatMinMaxToLVX = IntBinaryToLVX<SourceOp, DOp, WOp>;

// The pairing here is the whole point, and it is exact because MLIR draws
// the same distinction the ISA does:
//
//   arith.minimumf  IEEE 754-2019 minimum -- propagates NaN  -> fmind
//   arith.minnumf   IEEE 754-2008 minNum  -- returns non-NaN -> fminnd
//
// Swapping them is invisible on every non-NaN input, which is exactly how
// the same mistake survived in lvx-gcc until 2026-08-04.
using MinimumFToLVX = FloatMinMaxToLVX<arith::MinimumFOp, lvx::FmindOp, lvx::FminwOp>;
using MaximumFToLVX = FloatMinMaxToLVX<arith::MaximumFOp, lvx::FmaxdOp, lvx::FmaxwOp>;
using MinNumFToLVX  = FloatMinMaxToLVX<arith::MinNumFOp, lvx::FminndOp, lvx::FminnwOp>;
using MaxNumFToLVX  = FloatMinMaxToLVX<arith::MaxNumFOp, lvx::FmaxndOp, lvx::FmaxnwOp>;

// Unary float ops with no modifier.
template <typename SourceOp, typename DOp, typename WOp>
struct FloatUnaryToLVX : public OpConversionPattern<SourceOp> {
  using OpConversionPattern<SourceOp>::OpConversionPattern;
  using OpAdaptor = typename OpConversionPattern<SourceOp>::OpAdaptor;
  LogicalResult
  matchAndRewrite(SourceOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    if (failed(rejectVectors(op, rewriter)))
      return failure();
    Type regTy = this->getTypeConverter()->convertType(op.getType());
    unsigned width = getScalarBitWidth(op.getType());
    Value result;
    if (width <= 32)
      result = rewriter.create<WOp>(op.getLoc(), regTy, adaptor.getOperand());
    else
      result = rewriter.create<DOp>(op.getLoc(), regTy, adaptor.getOperand());
    rewriter.replaceOp(op, result);
    return success();
  }
};

using AbsFToLVX = FloatUnaryToLVX<math::AbsFOp, lvx::FabsdOp, lvx::FabswOp>;

// Integer bit-counting and absolute value, all ALU_BWRW on the 32-bit side.
// CLS ("count leading sign bits") and the saturating negate/abs have no MLIR
// counterpart, so they are modelled in the dialect but unreachable here.
using CtlzToLVX  = FloatUnaryToLVX<math::CountLeadingZerosOp, lvx::ClzdOp, lvx::ClzwOp>;
using CttzToLVX  = FloatUnaryToLVX<math::CountTrailingZerosOp, lvx::CtzdOp, lvx::CtzwOp>;
using CtpopToLVX = FloatUnaryToLVX<math::CtPopOp, lvx::CbsdOp, lvx::CbswOp>;
using AbsIToLVX  = FloatUnaryToLVX<math::AbsIOp, lvx::AbsdOp, lvx::AbswOp>;

// `arith.negf` used to lower to `0.0 - x` via fsbfd, for want of a negate
// instruction. That is wrong on a signed zero: IEEE gives 0.0 - 0.0 = +0.0
// under round-to-nearest, where negating +0.0 must give -0.0. `fnegd` is a
// sign-bit flip, exact for zeros and NaNs alike.
using NegFToLVX = FloatUnaryToLVX<arith::NegFOp, lvx::FnegdOp, lvx::FnegwOp>;

// Unary float ops that carry a rounding mode. One instruction covers the
// whole round-to-integral family; only the modifier differs.
template <typename SourceOp, typename DOp, typename WOp, FloatMode Mode>
struct FloatUnaryModeToLVX : public OpConversionPattern<SourceOp> {
  using OpConversionPattern<SourceOp>::OpConversionPattern;
  using OpAdaptor = typename OpConversionPattern<SourceOp>::OpAdaptor;
  LogicalResult
  matchAndRewrite(SourceOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    if (failed(rejectVectors(op, rewriter)))
      return failure();
    Type regTy = this->getTypeConverter()->convertType(op.getType());
    unsigned width = getScalarBitWidth(op.getType());
    Value result;
    if (width <= 32)
      result = rewriter.create<WOp>(
          op.getLoc(), regTy, adaptor.getOperand(),
          lvx::FloatModeAttr::get(rewriter.getContext(), Mode));
    else
      result = rewriter.create<DOp>(
          op.getLoc(), regTy, adaptor.getOperand(),
          lvx::FloatModeAttr::get(rewriter.getContext(), Mode));
    rewriter.replaceOp(op, result);
    return success();
  }
};

// sqrt takes the CS rounding mode, which is now spelled by *absence* of the
// attribute -- so it uses the no-mode unary template, not the mode-carrying
// one. Only frint's directed variants name a mode.
using SqrtToLVX = FloatUnaryToLVX<math::SqrtOp, lvx::FsqrtdOp, lvx::FsqrtwOp>;
// frint's directed modes give the whole round-to-integral family.
using RoundEvenToLVX = FloatUnaryModeToLVX<math::RoundEvenOp, lvx::FrintdOp,
                                           lvx::FrintwOp, FloatMode::rn>;
// Named for math.trunc (round toward zero) -- distinct from the existing
// TruncFToLVX, which is arith.truncf, a width narrowing.
using MathTruncToLVX = FloatUnaryModeToLVX<math::TruncOp, lvx::FrintdOp,
                                           lvx::FrintwOp, FloatMode::rz>;
using FloorToLVX     = FloatUnaryModeToLVX<math::FloorOp, lvx::FrintdOp,
                                           lvx::FrintwOp, FloatMode::rd>;
using CeilToLVX      = FloatUnaryModeToLVX<math::CeilOp, lvx::FrintdOp,
                                           lvx::FrintwOp, FloatMode::ru>;
// math.round is round-half-away-from-zero, which is `.rm` ("ties to max
// magnitude"), not `.rn`.
using RoundToLVX     = FloatUnaryModeToLVX<math::RoundOp, lvx::FrintdOp,
                                           lvx::FrintwOp, FloatMode::rm>;
//===----------------------------------------------------------------------===//
// Comparisons
//===----------------------------------------------------------------------===//

static IntComp mapCmpIPredicate(arith::CmpIPredicate pred) {
  switch (pred) {
  case arith::CmpIPredicate::eq:  return IntComp::eq;
  case arith::CmpIPredicate::ne:  return IntComp::ne;
  case arith::CmpIPredicate::slt: return IntComp::lt;
  case arith::CmpIPredicate::sle: return IntComp::le;
  case arith::CmpIPredicate::sgt: return IntComp::gt;
  case arith::CmpIPredicate::sge: return IntComp::ge;
  case arith::CmpIPredicate::ult: return IntComp::ltu;
  case arith::CmpIPredicate::ule: return IntComp::leu;
  case arith::CmpIPredicate::ugt: return IntComp::gtu;
  case arith::CmpIPredicate::uge: return IntComp::geu;
  }
  llvm_unreachable("unhandled arith::CmpIPredicate");
}

struct CmpIToLVX : public OpConversionPattern<arith::CmpIOp> {
  using OpConversionPattern::OpConversionPattern;
  LogicalResult
  matchAndRewrite(arith::CmpIOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    if (failed(rejectVectors(op, rewriter)))
      return failure();
    Type regTy = getTypeConverter()->convertType(op.getType());
    unsigned width = getScalarBitWidth(op.getLhs().getType());
    IntComp pred = mapCmpIPredicate(op.getPredicate());
    Value result =
        width <= 32
            ? rewriter.create<lvx::CompwOp>(op.getLoc(), regTy, pred,
                                               adaptor.getLhs(), adaptor.getRhs())
                  .getResult()
            : rewriter.create<lvx::CompdOp>(op.getLoc(), regTy, pred,
                                               adaptor.getLhs(), adaptor.getRhs())
                  .getResult();
    rewriter.replaceOp(op, result);
    return success();
  }
};

namespace {
struct FloatCompMapping {
  FloatComp pred;
  bool swapOperands;
};
} // namespace

// LVX's `floatcomp` modifier only directly encodes 8 relations
// (one/ueq/oeq/une/olt/uge/oge/ult, per Description.yml). The remaining
// arith predicates that have a clean operand-swap equivalent are handled
// that way; `ord`/`uno`/always-true/always-false have no direct hardware
// support here and are left unconverted (arith's own folder eliminates the
// always-true/false cases in practice; `ord`/`uno` are rare in the kernels
// this dialect targets and are a follow-up once needed).
static std::optional<FloatCompMapping>
mapCmpFPredicate(arith::CmpFPredicate pred) {
  switch (pred) {
  case arith::CmpFPredicate::OEQ: return FloatCompMapping{FloatComp::oeq, false};
  case arith::CmpFPredicate::ONE: return FloatCompMapping{FloatComp::one, false};
  case arith::CmpFPredicate::UEQ: return FloatCompMapping{FloatComp::ueq, false};
  case arith::CmpFPredicate::UNE: return FloatCompMapping{FloatComp::une, false};
  case arith::CmpFPredicate::OLT: return FloatCompMapping{FloatComp::olt, false};
  case arith::CmpFPredicate::OGE: return FloatCompMapping{FloatComp::oge, false};
  case arith::CmpFPredicate::ULT: return FloatCompMapping{FloatComp::ult, false};
  case arith::CmpFPredicate::UGE: return FloatCompMapping{FloatComp::uge, false};
  case arith::CmpFPredicate::OGT: return FloatCompMapping{FloatComp::olt, true};
  case arith::CmpFPredicate::OLE: return FloatCompMapping{FloatComp::oge, true};
  case arith::CmpFPredicate::UGT: return FloatCompMapping{FloatComp::ult, true};
  case arith::CmpFPredicate::ULE: return FloatCompMapping{FloatComp::uge, true};
  default:
    return std::nullopt;
  }
}

struct CmpFToLVX : public OpConversionPattern<arith::CmpFOp> {
  using OpConversionPattern::OpConversionPattern;
  LogicalResult
  matchAndRewrite(arith::CmpFOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    if (failed(rejectVectors(op, rewriter)))
      return failure();
    std::optional<FloatCompMapping> mapping = mapCmpFPredicate(op.getPredicate());
    if (!mapping)
      return rewriter.notifyMatchFailure(
          op, "unsupported floating-point comparison predicate");
    Type regTy = getTypeConverter()->convertType(op.getType());
    unsigned width = getScalarBitWidth(op.getLhs().getType());
    Value lhs = mapping->swapOperands ? adaptor.getRhs() : adaptor.getLhs();
    Value rhs = mapping->swapOperands ? adaptor.getLhs() : adaptor.getRhs();
    Value result =
        width <= 32
            ? rewriter.create<lvx::FcompwOp>(op.getLoc(), regTy,
                                                mapping->pred, lhs, rhs)
                  .getResult()
            : rewriter.create<lvx::FcompdOp>(op.getLoc(), regTy,
                                                mapping->pred, lhs, rhs)
                  .getResult();
    rewriter.replaceOp(op, result);
    return success();
  }
};

//===----------------------------------------------------------------------===//
// Constant / select
//===----------------------------------------------------------------------===//

struct ConstantToLVX : public OpConversionPattern<arith::ConstantOp> {
  using OpConversionPattern::OpConversionPattern;
  LogicalResult
  matchAndRewrite(arith::ConstantOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    if (failed(rejectVectors(op, rewriter)))
      return failure();
    Type regTy = getTypeConverter()->convertType(op.getType());
    rewriter.replaceOpWithNewOp<lvx::LiOp>(op, regTy,
                                              cast<TypedAttr>(op.getValue()));
    return success();
  }
};

struct IndexConstantToLVX : public OpConversionPattern<index::ConstantOp> {
  using OpConversionPattern::OpConversionPattern;
  LogicalResult
  matchAndRewrite(index::ConstantOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    Type regTy = getTypeConverter()->convertType(op.getType());
    rewriter.replaceOpWithNewOp<lvx::LiOp>(op, regTy,
                                              cast<TypedAttr>(op.getValueAttr()));
    return success();
  }
};

// Backed by CMOVED, testing the (already 0/1-valued) condition register
// against `wnez` (word not equal zero).
struct SelectToLVX : public OpConversionPattern<arith::SelectOp> {
  using OpConversionPattern::OpConversionPattern;
  LogicalResult
  matchAndRewrite(arith::SelectOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    if (failed(rejectVectors(op, rewriter)))
      return failure();
    Type regTy = getTypeConverter()->convertType(op.getType());
    rewriter.replaceOpWithNewOp<lvx::CmovedOp>(
        op, regTy, BcuCond::wnez, adaptor.getCondition(),
        adaptor.getTrueValue(), adaptor.getFalseValue());
    return success();
  }
};

//===----------------------------------------------------------------------===//
// Casts
//===----------------------------------------------------------------------===//

// Truncation/bitcast are no-ops at the register level: LVX registers are
// always 64 bits wide, and narrower-width instructions simply read fewer of
// those bits, so no actual truncation instruction is needed.
template <typename SourceOp>
struct NoopCastToLVX : public OpConversionPattern<SourceOp> {
  using OpConversionPattern<SourceOp>::OpConversionPattern;
  using OpAdaptor = typename OpConversionPattern<SourceOp>::OpAdaptor;
  LogicalResult
  matchAndRewrite(SourceOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    if (failed(rejectVectors(op, rewriter)))
      return failure();
    Type regTy = this->getTypeConverter()->convertType(op.getType());
    rewriter.replaceOpWithNewOp<lvx::MvOp>(op, regTy, adaptor.getIn());
    return success();
  }
};

using TruncIToLVX = NoopCastToLVX<arith::TruncIOp>;

struct BitcastToLVX : public OpConversionPattern<arith::BitcastOp> {
  using OpConversionPattern::OpConversionPattern;
  LogicalResult
  matchAndRewrite(arith::BitcastOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    if (failed(rejectVectors(op, rewriter)))
      return failure();
    Type regTy = getTypeConverter()->convertType(op.getType());
    rewriter.replaceOpWithNewOp<lvx::BitcastOp>(op, regTy, adaptor.getIn());
    return success();
  }
};

// Sign/zero-extend dispatch on the *source* width: LVX's synthetic
// extend-to-double-word instructions always widen into a full 64-bit
// register regardless of the IR's nominal destination width.
template <typename SourceOp, bool IsSigned>
struct ExtIToLVX : public OpConversionPattern<SourceOp> {
  using OpConversionPattern<SourceOp>::OpConversionPattern;
  using OpAdaptor = typename OpConversionPattern<SourceOp>::OpAdaptor;
  LogicalResult
  matchAndRewrite(SourceOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    if (failed(rejectVectors(op, rewriter)))
      return failure();
    Type regTy = this->getTypeConverter()->convertType(op.getType());
    unsigned inWidth = getScalarBitWidth(op.getIn().getType());
    Location loc = op.getLoc();
    Value in = adaptor.getIn();
    Value result;
    if (inWidth == 1) {
      // i1 -> wider: our compares/constants already store exactly 0 or 1 in
      // the full register. Zero-extension is therefore a no-op; sign
      // extension of a 1-bit value maps 1 -> all-ones, computed as `0 - x`.
      if (IsSigned) {
        Value zero = rewriter.create<lvx::LiOp>(
            loc, regTy, rewriter.getI64IntegerAttr(0));
        result = rewriter.create<lvx::SbfdOp>(loc, regTy, zero, in);
      } else {
        result = rewriter.create<lvx::MvOp>(loc, regTy, in);
      }
    } else if (inWidth <= 8) {
      result = IsSigned ? rewriter.create<lvx::SxbdOp>(loc, regTy, in).getResult()
                        : rewriter.create<lvx::ZxbdOp>(loc, regTy, in).getResult();
    } else if (inWidth <= 16) {
      result = IsSigned ? rewriter.create<lvx::SxhdOp>(loc, regTy, in).getResult()
                        : rewriter.create<lvx::ZxhdOp>(loc, regTy, in).getResult();
    } else if (inWidth <= 32) {
      result = IsSigned ? rewriter.create<lvx::SxwdOp>(loc, regTy, in).getResult()
                        : rewriter.create<lvx::ZxwdOp>(loc, regTy, in).getResult();
    } else {
      // Already 64 bits: extension is a no-op.
      result = rewriter.create<lvx::MvOp>(loc, regTy, in);
    }
    rewriter.replaceOp(op, result);
    return success();
  }
};

using ExtSIToLVX = ExtIToLVX<arith::ExtSIOp, /*IsSigned=*/true>;
using ExtUIToLVX = ExtIToLVX<arith::ExtUIOp, /*IsSigned=*/false>;

template <typename SourceOp, typename TargetOp>
struct UnaryCastToLVX : public OpConversionPattern<SourceOp> {
  using OpConversionPattern<SourceOp>::OpConversionPattern;
  using OpAdaptor = typename OpConversionPattern<SourceOp>::OpAdaptor;
  LogicalResult
  matchAndRewrite(SourceOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    if (failed(rejectVectors(op, rewriter)))
      return failure();
    Type regTy = this->getTypeConverter()->convertType(op.getType());
    rewriter.replaceOpWithNewOp<TargetOp>(op, regTy, adaptor.getIn());
    return success();
  }
};

using SIToFPToLVX = UnaryCastToLVX<arith::SIToFPOp, lvx::SitofpOp>;
using UIToFPToLVX = UnaryCastToLVX<arith::UIToFPOp, lvx::UitofpOp>;
using FPToSIToLVX = UnaryCastToLVX<arith::FPToSIOp, lvx::FptosiOp>;
using FPToUIToLVX = UnaryCastToLVX<arith::FPToUIOp, lvx::FptouiOp>;

struct TruncFToLVX : public OpConversionPattern<arith::TruncFOp> {
  using OpConversionPattern::OpConversionPattern;
  LogicalResult
  matchAndRewrite(arith::TruncFOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    if (failed(rejectVectors(op, rewriter)))
      return failure();
    Type regTy = getTypeConverter()->convertType(op.getType());
    rewriter.replaceOpWithNewOp<lvx::FdtofwOp>(op, regTy, adaptor.getIn());
    return success();
  }
};

struct ExtFToLVX : public OpConversionPattern<arith::ExtFOp> {
  using OpConversionPattern::OpConversionPattern;
  LogicalResult
  matchAndRewrite(arith::ExtFOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    if (failed(rejectVectors(op, rewriter)))
      return failure();
    Type regTy = getTypeConverter()->convertType(op.getType());
    rewriter.replaceOpWithNewOp<lvx::FwtofdOp>(op, regTy, adaptor.getIn());
    return success();
  }
};

// index_cast(ui) behaves like sign/zero-extend when widening and like a
// no-op truncation when narrowing/same-width (register width is always 64).
template <typename SourceOp, bool IsSigned>
struct IndexCastToLVX : public OpConversionPattern<SourceOp> {
  using OpConversionPattern<SourceOp>::OpConversionPattern;
  using OpAdaptor = typename OpConversionPattern<SourceOp>::OpAdaptor;
  LogicalResult
  matchAndRewrite(SourceOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    if (failed(rejectVectors(op, rewriter)))
      return failure();
    Type regTy = this->getTypeConverter()->convertType(op.getType());
    unsigned inWidth = getScalarBitWidth(op.getIn().getType());
    unsigned outWidth = getScalarBitWidth(op.getOut().getType());
    Location loc = op.getLoc();
    Value in = adaptor.getIn();
    Value result;
    if (inWidth >= outWidth) {
      result = rewriter.create<lvx::MvOp>(loc, regTy, in);
    } else if (inWidth <= 8) {
      result = IsSigned ? rewriter.create<lvx::SxbdOp>(loc, regTy, in).getResult()
                        : rewriter.create<lvx::ZxbdOp>(loc, regTy, in).getResult();
    } else if (inWidth <= 16) {
      result = IsSigned ? rewriter.create<lvx::SxhdOp>(loc, regTy, in).getResult()
                        : rewriter.create<lvx::ZxhdOp>(loc, regTy, in).getResult();
    } else {
      result = IsSigned ? rewriter.create<lvx::SxwdOp>(loc, regTy, in).getResult()
                        : rewriter.create<lvx::ZxwdOp>(loc, regTy, in).getResult();
    }
    rewriter.replaceOp(op, result);
    return success();
  }
};

using IndexCastToLVXPat   = IndexCastToLVX<arith::IndexCastOp, /*IsSigned=*/true>;
using IndexCastUIToLVXPat = IndexCastToLVX<arith::IndexCastUIOp, /*IsSigned=*/false>;

//===----------------------------------------------------------------------===//
// MemRef load / store: linearize static-shape memref indices into a base
// register + byte offset, then emit a base+offset LVX load/store.
//===----------------------------------------------------------------------===//

static FailureOr<Value> computeAddress(ConversionPatternRewriter &rewriter,
                                       Location loc, MemRefType memrefType,
                                       Value base, ValueRange indices,
                                       Type regTy) {
  if (!memrefType.hasStaticShape())
    return failure();
  int64_t offset;
  SmallVector<int64_t> strides;
  if (failed(memrefType.getStridesAndOffset(strides, offset)))
    return failure();

  unsigned elemBits = getScalarBitWidth(memrefType.getElementType());
  int64_t elemBytes = std::max<int64_t>(1, elemBits / 8);

  Value address = base;
  for (auto [index, stride] : llvm::zip(indices, strides)) {
    int64_t byteStride = stride * elemBytes;
    Value strideConst = rewriter.create<lvx::LiOp>(
        loc, regTy, rewriter.getI64IntegerAttr(byteStride));
    Value term = rewriter.create<lvx::MuldOp>(loc, regTy, index, strideConst);
    address = rewriter.create<lvx::AdddOp>(loc, regTy, address, term);
  }
  if (offset != 0) {
    Value offsetConst = rewriter.create<lvx::LiOp>(
        loc, regTy, rewriter.getI64IntegerAttr(offset * elemBytes));
    address = rewriter.create<lvx::AdddOp>(loc, regTy, address, offsetConst);
  }
  return address;
}

struct MemRefLoadToLVX : public OpConversionPattern<memref::LoadOp> {
  using OpConversionPattern::OpConversionPattern;
  LogicalResult
  matchAndRewrite(memref::LoadOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    auto memrefType = cast<MemRefType>(op.getMemref().getType());
    Type regTy = getTypeConverter()->convertType(op.getType());
    FailureOr<Value> address =
        computeAddress(rewriter, op.getLoc(), memrefType, adaptor.getMemref(),
                       adaptor.getIndices(), regTy);
    if (failed(address))
      return rewriter.notifyMatchFailure(
          op, "unsupported memref layout for address linearization");
    auto zeroOffset = rewriter.getI64IntegerAttr(0);
    unsigned bits = getScalarBitWidth(memrefType.getElementType());
    Value result;
    if (bits <= 8)
      result = rewriter.create<lvx::LbzOp>(op.getLoc(), regTy, *address, zeroOffset);
    else if (bits <= 16)
      result = rewriter.create<lvx::LhzOp>(op.getLoc(), regTy, *address, zeroOffset);
    else if (bits <= 32)
      result = rewriter.create<lvx::LwzOp>(op.getLoc(), regTy, *address, zeroOffset);
    else
      result = rewriter.create<lvx::LdOp>(op.getLoc(), regTy, *address, zeroOffset);
    rewriter.replaceOp(op, result);
    return success();
  }
};

struct MemRefStoreToLVX : public OpConversionPattern<memref::StoreOp> {
  using OpConversionPattern::OpConversionPattern;
  LogicalResult
  matchAndRewrite(memref::StoreOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    auto memrefType = cast<MemRefType>(op.getMemref().getType());
    Type regTy = getTypeConverter()->convertType(memrefType);
    FailureOr<Value> address =
        computeAddress(rewriter, op.getLoc(), memrefType, adaptor.getMemref(),
                       adaptor.getIndices(), regTy);
    if (failed(address))
      return rewriter.notifyMatchFailure(
          op, "unsupported memref layout for address linearization");
    auto zeroOffset = rewriter.getI64IntegerAttr(0);
    unsigned bits = getScalarBitWidth(memrefType.getElementType());
    if (bits <= 8)
      rewriter.replaceOpWithNewOp<lvx::SbOp>(op, adaptor.getValue(), *address, zeroOffset);
    else if (bits <= 16)
      rewriter.replaceOpWithNewOp<lvx::ShOp>(op, adaptor.getValue(), *address, zeroOffset);
    else if (bits <= 32)
      rewriter.replaceOpWithNewOp<lvx::SwOp>(op, adaptor.getValue(), *address, zeroOffset);
    else
      rewriter.replaceOpWithNewOp<lvx::SdOp>(op, adaptor.getValue(), *address, zeroOffset);
    return success();
  }
};

//===----------------------------------------------------------------------===//
// Vectors (lvx-mds/docs/MLIR-backend-design.md §8.7): the four ops the
// vectorised `mymma` needs, over the tuple types. `vector.load`/`store` are
// the memref patterns above at tuple width -- the same address, `lq`/`sq`
// (`lo`/`so` for a quad) instead of a scalar access; `vector.broadcast` is
// the ISA's splat of a scalar by element width; `vector.fma` is `ffmawq`/
// `ffmadp`, the only element shapes the ISA has a pair fma for.
//===----------------------------------------------------------------------===//

/// The tuple width in units of a converted vector type, or 0.
static unsigned tupleWidth(Type converted) {
  return lvx::widthOf(converted) > 1 ? lvx::widthOf(converted) : 0;
}

struct VectorLoadToLVX : public OpConversionPattern<vector::LoadOp> {
  using OpConversionPattern::OpConversionPattern;
  LogicalResult
  matchAndRewrite(vector::LoadOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    auto memrefType = cast<MemRefType>(op.getBase().getType());
    Type tupleTy = getTypeConverter()->convertType(op.getType());
    Type regTy = getTypeConverter()->convertType(memrefType);
    if (!tupleTy || !tupleWidth(tupleTy))
      return rewriter.notifyMatchFailure(op, "vector shape has no register tuple");
    FailureOr<Value> address =
        computeAddress(rewriter, op.getLoc(), memrefType, adaptor.getBase(),
                       adaptor.getIndices(), regTy);
    if (failed(address))
      return rewriter.notifyMatchFailure(
          op, "unsupported memref layout for address linearization");
    auto zeroOffset = rewriter.getI64IntegerAttr(0);
    if (tupleWidth(tupleTy) == 2)
      rewriter.replaceOpWithNewOp<lvx::LqOp>(op, tupleTy, *address, zeroOffset);
    else
      rewriter.replaceOpWithNewOp<lvx::LoOp>(op, tupleTy, *address, zeroOffset);
    return success();
  }
};

struct VectorStoreToLVX : public OpConversionPattern<vector::StoreOp> {
  using OpConversionPattern::OpConversionPattern;
  LogicalResult
  matchAndRewrite(vector::StoreOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    auto memrefType = cast<MemRefType>(op.getBase().getType());
    Type regTy = getTypeConverter()->convertType(memrefType);
    unsigned width = tupleWidth(adaptor.getValueToStore().getType());
    if (!width)
      return rewriter.notifyMatchFailure(op, "vector shape has no register tuple");
    FailureOr<Value> address =
        computeAddress(rewriter, op.getLoc(), memrefType, adaptor.getBase(),
                       adaptor.getIndices(), regTy);
    if (failed(address))
      return rewriter.notifyMatchFailure(
          op, "unsupported memref layout for address linearization");
    auto zeroOffset = rewriter.getI64IntegerAttr(0);
    if (width == 2)
      rewriter.replaceOpWithNewOp<lvx::SqOp>(op, adaptor.getValueToStore(),
                                             *address, zeroOffset);
    else
      rewriter.replaceOpWithNewOp<lvx::SoOp>(op, adaptor.getValueToStore(),
                                             *address, zeroOffset);
    return success();
  }
};

// The `memref.load` a `vector.broadcast` to a quad splats, when the ISA
// loads and splats in one instruction: `l{b,h,w,d}so` (lvx-2) fill a quad
// from one lane in memory, so the splat leaves the dependence chain
// (address -> load -> splat -> fma becomes address -> load -> fma). The load
// must have no other use -- otherwise the scalar is wanted too, and a load
// plus a splat beats two loads. There is no pair form (`lwsq`): a pair
// broadcast stays `lwz` + `splatwq`.
static memref::LoadOp splatLoadOf(vector::BroadcastOp bcast,
                                  const TypeConverter &typeConverter) {
  auto load = bcast.getSource().getDefiningOp<memref::LoadOp>();
  if (!load || !load->hasOneUse())
    return {};
  Type tupleTy = typeConverter.convertType(bcast.getType());
  if (!tupleTy || tupleWidth(tupleTy) != 4)
    return {};
  unsigned bits = getScalarBitWidth(load.getType());
  if (bits != 8 && bits != 16 && bits != 32 && bits != 64)
    return {};
  return load;
}

/// `splat{b,h,w,d}q $d = $s` by element width, filling a pair; null when the
/// ISA has no splat for the width.
static Value createSplat(ConversionPatternRewriter &rewriter, Location loc,
                         Type pairTy, unsigned elemBits, Value scalar) {
  switch (elemBits) {
  case 8:
    return rewriter.create<lvx::SplatbqOp>(loc, pairTy, scalar);
  case 16:
    return rewriter.create<lvx::SplathqOp>(loc, pairTy, scalar);
  case 32:
    return rewriter.create<lvx::SplatwqOp>(loc, pairTy, scalar);
  case 64:
    return rewriter.create<lvx::SplatdqOp>(loc, pairTy, scalar);
  default:
    return {};
  }
}

/// A splat vector constant: the element into a register, then the splat. Two
/// ops, and the `lvx.li` is loop-invariant. Only a splat -- an arbitrary
/// `dense<[...]>` would be a constant pool this back end does not have, and
/// stays class D.
///
/// This is not only for source-written constants: a `vector.maskedload` whose
/// `pass_thru` is the zero vector consumes the constant rather than the
/// value, so the constant is left dead -- and `applyFullConversion` legalizes
/// dead ops too.
struct VectorSplatConstantToLVX : public OpConversionPattern<arith::ConstantOp> {
  using OpConversionPattern::OpConversionPattern;
  LogicalResult
  matchAndRewrite(arith::ConstantOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    auto vecTy = dyn_cast<VectorType>(op.getType());
    if (!vecTy)
      return rewriter.notifyMatchFailure(op, "the scalar pattern handles this");
    auto dense = dyn_cast<DenseElementsAttr>(op.getValue());
    if (!dense || !dense.isSplat())
      return rewriter.notifyMatchFailure(op, "only a splat constant");
    Type tupleTy = getTypeConverter()->convertType(vecTy);
    if (tupleWidth(tupleTy) != 2)
      return rewriter.notifyMatchFailure(
          op, "the ISA splats a pair; a quad splat has no composite");
    auto scalarAttr = dyn_cast<TypedAttr>(dense.getSplatValue<Attribute>());
    if (!scalarAttr)
      return rewriter.notifyMatchFailure(op, "no scalar attribute to load");
    Location loc = op.getLoc();
    Type regTy = RegisterType::get(rewriter.getContext(), std::nullopt);
    Value scalar = rewriter.create<lvx::LiOp>(loc, regTy, scalarAttr);
    Value result = createSplat(rewriter, loc, tupleTy,
                               vecTy.getElementTypeBitWidth(), scalar);
    if (!result)
      return rewriter.notifyMatchFailure(op, "no splat for this element width");
    rewriter.replaceOp(op, result);
    return success();
  }
};

// `vector.broadcast %s : T to vector<NxT>` of a scalar: `splat{b,h,w,d}q`
// by element width, which fills a pair; of a `memref.load` to a quad,
// `l{b,h,w,d}so` from the load's address (splatLoadOf). (Any other quad
// broadcast, or a vector source, has no single instruction and is not
// lowered.)
struct VectorBroadcastToLVX : public OpConversionPattern<vector::BroadcastOp> {
  using OpConversionPattern::OpConversionPattern;
  LogicalResult
  matchAndRewrite(vector::BroadcastOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    Type sourceTy = op.getSource().getType();
    if (isa<VectorType>(sourceTy))
      return rewriter.notifyMatchFailure(op, "only a scalar source splats");
    Type tupleTy = getTypeConverter()->convertType(op.getType());
    if (!tupleTy || !tupleWidth(tupleTy))
      return rewriter.notifyMatchFailure(op, "vector shape has no register tuple");
    if (memref::LoadOp load = splatLoadOf(op, *getTypeConverter()))
      if (succeeded(lowerSplatLoad(op, load, tupleTy, rewriter)))
        return success();
    // The ISA splats into a pair only. A quad broadcast becomes the pair
    // splat regardless: its consumers are the composite ops, whose parts
    // read a pair-typed source whole (pairSplatOf below folds it there), and
    // the pair-to-quad cast the framework inserts for any other consumer is
    // left unresolved, which fails the conversion for exactly that consumer.
    tupleTy = lvx::PairType::get(rewriter.getContext());
    Value result = createSplat(rewriter, op.getLoc(), tupleTy,
                               getScalarBitWidth(sourceTy), adaptor.getSource());
    if (!result)
      return rewriter.notifyMatchFailure(op, "no splat for this element width");
    rewriter.replaceOp(op, result);
    return success();
  }

  // The load is converted on its own (to `lwz`) before this op is reached,
  // and that conversion is left to die unused, as pairSplatOf below leaves
  // a pair splat: the address is recomputed here from the load's remapped
  // operands, which the greedy `-lvx-combine` driver and `-cse` then
  // merge with the dead one's before removing it.
  LogicalResult lowerSplatLoad(vector::BroadcastOp op, memref::LoadOp load,
                               Type quadTy,
                               ConversionPatternRewriter &rewriter) const {
    SmallVector<Value> operands;
    if (failed(rewriter.getRemappedValues(load->getOperands(), operands)))
      return failure();
    auto memrefType = cast<MemRefType>(load.getMemref().getType());
    Type regTy = getTypeConverter()->convertType(memrefType);
    FailureOr<Value> address = computeAddress(
        rewriter, op.getLoc(), memrefType, operands.front(),
        ValueRange(operands).drop_front(), regTy);
    if (failed(address))
      return failure();
    auto zeroOffset = rewriter.getI64IntegerAttr(0);
    Value result;
    switch (getScalarBitWidth(load.getType())) {
    case 8:
      result = rewriter.create<lvx::LbsoOp>(op.getLoc(), quadTy, *address, zeroOffset);
      break;
    case 16:
      result = rewriter.create<lvx::LhsoOp>(op.getLoc(), quadTy, *address, zeroOffset);
      break;
    case 32:
      result = rewriter.create<lvx::LwsoOp>(op.getLoc(), quadTy, *address, zeroOffset);
      break;
    default:
      result = rewriter.create<lvx::LdsoOp>(op.getLoc(), quadTy, *address, zeroOffset);
      break;
    }
    rewriter.replaceOp(op, result);
    return success();
  }
};

// `vector.fma` (or a vector-typed `math.fma`) on vector<4xf32> is `ffmawq`, on
// vector<2xf64> `ffmadp`; like
// the scalar `ffmaw`/`ffmad`, the accumulator is tied to the result and the
// allocator coalesces them. On vector<8xf32>/vector<4xf64> it is the
// composite `ffmawo`/`ffmadq` (Builtin@split): the same instruction on each
// pair of the quad, one op, issued in one bundle.
//
// A broadcast operand of the composite stays a pair: the ISA has no quad
// splat, and the composite's parts read a pair-typed source whole
// (LVX_PairOrQuadType), so `vector.broadcast` feeding a wide fma is folded
// here into the pair splat rather than lowered to a quad it cannot become.
// That is a fold of the *original* operand; a wide broadcast with another
// use still has no lowering and fails the conversion, loudly.
//
// A broadcast that became an `l{b,h,w,d}so` is already the quad the
// composite's parts read half by half, and is left alone.
static Value pairSplatOf(ConversionPatternRewriter &rewriter, Location loc,
                         const TypeConverter &typeConverter, Value converted,
                         Value original) {
  auto bcast = original.getDefiningOp<vector::BroadcastOp>();
  if (!bcast || isa<VectorType>(bcast.getSource().getType()))
    return converted;
  if (splatLoadOf(bcast, typeConverter))
    return converted;
  Type pairTy = lvx::PairType::get(rewriter.getContext());
  Value scalar = rewriter.getRemappedValue(bcast.getSource());
  if (!scalar)
    return converted;
  switch (getScalarBitWidth(bcast.getSource().getType())) {
  case 32:
    return rewriter.create<lvx::SplatwqOp>(loc, pairTy, scalar);
  case 64:
    return rewriter.create<lvx::SplatdqOp>(loc, pairTy, scalar);
  }
  return converted;
}

static FailureOr<Value> lowerVectorFma(ConversionPatternRewriter &rewriter,
                                       const TypeConverter &typeConverter,
                                       Operation *op, Value lhs, Value rhs,
                                       Value acc, Value originalLhs,
                                       Value originalRhs) {
  auto vecTy = cast<VectorType>(op->getResult(0).getType());
  Type tupleTy = typeConverter.convertType(vecTy);
  unsigned width = tupleTy ? tupleWidth(tupleTy) : 0;
  if (!width || !isa<FloatType>(vecTy.getElementType()))
    return rewriter.notifyMatchFailure(op, "the ISA has a pair fma for f32 x4 and f64 x2, and their composites, only");
  bool f32 = vecTy.getElementTypeBitWidth() == 32;
  Location loc = op->getLoc();
  if (width == 2) {
    if (f32)
      return rewriter.create<lvx::FfmawqOp>(loc, tupleTy, lhs, rhs, acc)
          .getResult();
    return rewriter.create<lvx::FfmadpOp>(loc, tupleTy, lhs, rhs, acc)
        .getResult();
  }
  lhs = pairSplatOf(rewriter, loc, typeConverter, lhs, originalLhs);
  rhs = pairSplatOf(rewriter, loc, typeConverter, rhs, originalRhs);
  if (f32)
    return rewriter.create<lvx::FfmawoOp>(loc, tupleTy, lhs, rhs, acc)
        .getResult();
  return rewriter.create<lvx::FfmadqOp>(loc, tupleTy, lhs, rhs, acc)
      .getResult();
}

struct VectorFMAToLVX : public OpConversionPattern<vector::FMAOp> {
  using OpConversionPattern::OpConversionPattern;
  LogicalResult
  matchAndRewrite(vector::FMAOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    FailureOr<Value> result = lowerVectorFma(
        rewriter, *getTypeConverter(), op, adaptor.getLhs(), adaptor.getRhs(),
        adaptor.getAcc(), op.getLhs(), op.getRhs());
    if (failed(result))
      return failure();
    rewriter.replaceOp(op, *result);
    return success();
  }
};

// The lane shuffles, EVEN*Q/ODD*Q/ZIP*DQ (after ARM's UZP1/UZP2/ZIP1/ZIP2),
// are `vector.deinterleave` and `vector.interleave` at the quad:
//
//   deinterleave %q : vector<8xf32>  -> evenwq %q[0], %q[2] ; oddwq %q[0], %q[2]
//   interleave %a, %b : vector<4xf32> -> concat(zipwdq %a[0], %b[0] ; zipwdq %a[1], %b[1])
//
// `evenwq $p = $a, $b` packs the even lanes of pair `a` into the low single
// and of pair `b` into the high one, so the even lanes of a quad are one
// instruction on its two pairs (lane views). `zipwdq $p = $x, $y` is the
// perfect shuffle of two singles into a pair, so interleaving two pairs is
// one on the low singles and one on the high ones, and the quad is the
// two results side by side -- `lvx.concat`, which the allocator places
// (no instruction). Double-word lanes have no ZIPDDQ: zipping two doubles
// is `catdq`. There is no pair form of either -- the halves would be
// 64-bit vectors, which have no register type -- and no octuple form.
template <typename VecOp>
static unsigned laneBitsOf(VecOp op, Type vectorTy) {
  return cast<VectorType>(vectorTy).getElementTypeBitWidth();
}

struct VectorDeinterleaveToLVX
    : public OpConversionPattern<vector::DeinterleaveOp> {
  using OpConversionPattern::OpConversionPattern;
  LogicalResult
  matchAndRewrite(vector::DeinterleaveOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    Type quadTy = getTypeConverter()->convertType(op.getSourceVectorType());
    Type pairTy = getTypeConverter()->convertType(op.getResultVectorType());
    if (!quadTy || tupleWidth(quadTy) != 4 || !pairTy || tupleWidth(pairTy) != 2)
      return rewriter.notifyMatchFailure(op, "the ISA deinterleaves a quad into two pairs");
    Location loc = op.getLoc();
    Value lo = rewriter.create<lvx::LaneOp>(loc, pairTy, adaptor.getSource(), 0);
    Value hi = rewriter.create<lvx::LaneOp>(loc, pairTy, adaptor.getSource(), 2);
    Value even, odd;
    switch (laneBitsOf(op, op.getSourceVectorType())) {
    case 8:
      even = rewriter.create<lvx::EvenbqOp>(loc, pairTy, lo, hi);
      odd = rewriter.create<lvx::OddbqOp>(loc, pairTy, lo, hi);
      break;
    case 16:
      even = rewriter.create<lvx::EvenhqOp>(loc, pairTy, lo, hi);
      odd = rewriter.create<lvx::OddhqOp>(loc, pairTy, lo, hi);
      break;
    case 32:
      even = rewriter.create<lvx::EvenwqOp>(loc, pairTy, lo, hi);
      odd = rewriter.create<lvx::OddwqOp>(loc, pairTy, lo, hi);
      break;
    case 64:
      even = rewriter.create<lvx::EvendqOp>(loc, pairTy, lo, hi);
      odd = rewriter.create<lvx::OdddqOp>(loc, pairTy, lo, hi);
      break;
    default:
      return rewriter.notifyMatchFailure(op, "no shuffle for this lane width");
    }
    rewriter.replaceOp(op, {even, odd});
    return success();
  }
};

/// Two pairs into a quad: the perfect shuffle of their low singles and of
/// their high singles, side by side. `vector.interleave` and the equivalent
/// `vector.shuffle` mask both land here.
static LogicalResult lowerInterleave(ConversionPatternRewriter &rewriter,
                                     Operation *op, Type quadTy, unsigned bits,
                                     Value lhs, Value rhs) {
  MLIRContext *ctx = rewriter.getContext();
  Type pairTy = lvx::PairType::get(ctx, std::nullopt);
  Type regTy = RegisterType::get(ctx, std::nullopt);
  Location loc = op->getLoc();
  Value half[2];
  for (unsigned k = 0; k != 2; ++k) {
    Value a = rewriter.create<lvx::LaneOp>(loc, regTy, lhs, k);
    Value b = rewriter.create<lvx::LaneOp>(loc, regTy, rhs, k);
    switch (bits) {
    case 8:
      half[k] = rewriter.create<lvx::ZipbdqOp>(loc, pairTy, a, b);
      break;
    case 16:
      half[k] = rewriter.create<lvx::ZiphdqOp>(loc, pairTy, a, b);
      break;
    case 32:
      half[k] = rewriter.create<lvx::ZipwdqOp>(loc, pairTy, a, b);
      break;
    case 64:
      half[k] = rewriter.create<lvx::CatdqOp>(loc, pairTy, a, b);
      break;
    default:
      return rewriter.notifyMatchFailure(op, "no shuffle for this lane width");
    }
  }
  rewriter.replaceOpWithNewOp<lvx::ConcatOp>(op, quadTy,
                                             ValueRange{half[0], half[1]});
  return success();
}

struct VectorInterleaveToLVX : public OpConversionPattern<vector::InterleaveOp> {
  using OpConversionPattern::OpConversionPattern;
  LogicalResult
  matchAndRewrite(vector::InterleaveOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    Type pairTy = getTypeConverter()->convertType(op.getSourceVectorType());
    Type quadTy = getTypeConverter()->convertType(op.getResultVectorType());
    if (!pairTy || tupleWidth(pairTy) != 2 || !quadTy || tupleWidth(quadTy) != 4)
      return rewriter.notifyMatchFailure(op, "the ISA interleaves two pairs into a quad");
    return lowerInterleave(rewriter, op, quadTy,
                           laneBitsOf(op, op.getSourceVectorType()),
                           adaptor.getLhs(), adaptor.getRhs());
  }
};

//===----------------------------------------------------------------------===//
// Elementwise arithmetic on vectors (docs/VectorCoverage.md, Phase 1).
//
// A scalar pattern keys on one bit -- `w` below 33 bits, `d` above. A lane
// pattern keys on four element widths and two tuple widths, so the tables
// below name one LVX op per (family, element width) at pair width, and one
// at quad width, where `NoLaneOp` means the ISA has no instruction for that
// shape. A row with `NoLaneOp` at pair width fails the conversion and
// becomes a class-D row of the coverage table; a row with `NoLaneOp` only at
// quad width is *split* into the two pair ops over lane views, which is what
// `Builtin@split` would have produced had the builtin been declared (a
// missing `split:` is a Builtin.yml record, not a missing instruction --
// VectorCoverage.md §5).
//===----------------------------------------------------------------------===//

/// The (family, element width) shapes the ISA does not have.
struct NoLaneOp {};

template <typename Op> struct LaneBinary {
  static Value create(ConversionPatternRewriter &rewriter, Location loc,
                      Type resultTy, Value lhs, Value rhs) {
    return rewriter.create<Op>(loc, resultTy, lhs, rhs);
  }
};
template <> struct LaneBinary<NoLaneOp> {
  static Value create(ConversionPatternRewriter &, Location, Type, Value,
                      Value) {
    return {};
  }
};

template <typename Op> struct LaneUnary {
  static Value create(ConversionPatternRewriter &rewriter, Location loc,
                      Type resultTy, Value operand) {
    return rewriter.create<Op>(loc, resultTy, operand);
  }
};
template <> struct LaneUnary<NoLaneOp> {
  static Value create(ConversionPatternRewriter &, Location, Type, Value) {
    return {};
  }
};

/// The pair halves of a quad, as lane views (no instruction).
static Value quadHalf(ConversionPatternRewriter &rewriter, Location loc,
                      Value quad, unsigned k) {
  Type pairTy = lvx::PairType::get(rewriter.getContext(), std::nullopt);
  if (lvx::widthOf(quad.getType()) == 2)
    return quad; // a pair operand (a splat) is read whole by both halves
  return rewriter.create<lvx::LaneOp>(loc, pairTy, quad, 2 * k);
}

template <typename B, typename H, typename W, typename D>
static Value byWidthBinary(unsigned bits, ConversionPatternRewriter &rewriter,
                           Location loc, Type resultTy, Value lhs, Value rhs) {
  switch (bits) {
  case 8:  return LaneBinary<B>::create(rewriter, loc, resultTy, lhs, rhs);
  case 16: return LaneBinary<H>::create(rewriter, loc, resultTy, lhs, rhs);
  case 32: return LaneBinary<W>::create(rewriter, loc, resultTy, lhs, rhs);
  case 64: return LaneBinary<D>::create(rewriter, loc, resultTy, lhs, rhs);
  }
  return {};
}

template <typename B, typename H, typename W, typename D>
static Value byWidthUnary(unsigned bits, ConversionPatternRewriter &rewriter,
                          Location loc, Type resultTy, Value operand) {
  switch (bits) {
  case 8:  return LaneUnary<B>::create(rewriter, loc, resultTy, operand);
  case 16: return LaneUnary<H>::create(rewriter, loc, resultTy, operand);
  case 32: return LaneUnary<W>::create(rewriter, loc, resultTy, operand);
  case 64: return LaneUnary<D>::create(rewriter, loc, resultTy, operand);
  }
  return {};
}

/// `SourceOp` on a vector: `P*` at pair width, `Q*` (a composite) at quad
/// width, and failing that the pair op on each half.
template <typename SourceOp, typename PB, typename PH, typename PW,
          typename PD, typename QB, typename QH, typename QW, typename QD>
struct VectorBinaryToLVX : public OpConversionPattern<SourceOp> {
  using OpConversionPattern<SourceOp>::OpConversionPattern;
  using OpAdaptor = typename OpConversionPattern<SourceOp>::OpAdaptor;
  LogicalResult
  matchAndRewrite(SourceOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    auto vecTy = dyn_cast<VectorType>(op.getType());
    if (!vecTy)
      return rewriter.notifyMatchFailure(op, "the scalar pattern handles this");
    Type tupleTy = this->getTypeConverter()->convertType(vecTy);
    unsigned units = tupleTy ? tupleWidth(tupleTy) : 0;
    if (!units)
      return rewriter.notifyMatchFailure(op, "vector shape has no register tuple");
    unsigned bits = vecTy.getElementTypeBitWidth();
    Location loc = op.getLoc();
    Value lhs = adaptor.getLhs(), rhs = adaptor.getRhs();
    if (units == 2) {
      Value result = byWidthBinary<PB, PH, PW, PD>(bits, rewriter, loc, tupleTy,
                                                   lhs, rhs);
      if (!result)
        return rewriter.notifyMatchFailure(op, "no instruction for this lane shape");
      rewriter.replaceOp(op, result);
      return success();
    }
    if (Value composite = byWidthBinary<QB, QH, QW, QD>(bits, rewriter, loc,
                                                        tupleTy, lhs, rhs)) {
      rewriter.replaceOp(op, composite);
      return success();
    }
    Type pairTy = lvx::PairType::get(rewriter.getContext(), std::nullopt);
    Value half[2];
    for (unsigned k = 0; k != 2; ++k) {
      half[k] = byWidthBinary<PB, PH, PW, PD>(
          bits, rewriter, loc, pairTy, quadHalf(rewriter, loc, lhs, k),
          quadHalf(rewriter, loc, rhs, k));
      if (!half[k])
        return rewriter.notifyMatchFailure(op, "no instruction for this lane shape");
    }
    rewriter.replaceOpWithNewOp<lvx::ConcatOp>(op, tupleTy,
                                               ValueRange{half[0], half[1]});
    return success();
  }
};

template <typename SourceOp, typename PB, typename PH, typename PW,
          typename PD, typename QB, typename QH, typename QW, typename QD>
struct VectorUnaryToLVX : public OpConversionPattern<SourceOp> {
  using OpConversionPattern<SourceOp>::OpConversionPattern;
  using OpAdaptor = typename OpConversionPattern<SourceOp>::OpAdaptor;
  LogicalResult
  matchAndRewrite(SourceOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    auto vecTy = dyn_cast<VectorType>(op.getType());
    if (!vecTy)
      return rewriter.notifyMatchFailure(op, "the scalar pattern handles this");
    Type tupleTy = this->getTypeConverter()->convertType(vecTy);
    unsigned units = tupleTy ? tupleWidth(tupleTy) : 0;
    if (!units)
      return rewriter.notifyMatchFailure(op, "vector shape has no register tuple");
    unsigned bits = vecTy.getElementTypeBitWidth();
    Location loc = op.getLoc();
    Value operand = adaptor.getOperands().front();
    if (units == 2) {
      Value result = byWidthUnary<PB, PH, PW, PD>(bits, rewriter, loc, tupleTy,
                                                  operand);
      if (!result)
        return rewriter.notifyMatchFailure(op, "no instruction for this lane shape");
      rewriter.replaceOp(op, result);
      return success();
    }
    if (Value composite = byWidthUnary<QB, QH, QW, QD>(bits, rewriter, loc,
                                                       tupleTy, operand)) {
      rewriter.replaceOp(op, composite);
      return success();
    }
    Type pairTy = lvx::PairType::get(rewriter.getContext(), std::nullopt);
    Value half[2];
    for (unsigned k = 0; k != 2; ++k) {
      half[k] = byWidthUnary<PB, PH, PW, PD>(
          bits, rewriter, loc, pairTy, quadHalf(rewriter, loc, operand, k));
      if (!half[k])
        return rewriter.notifyMatchFailure(op, "no instruction for this lane shape");
    }
    rewriter.replaceOpWithNewOp<lvx::ConcatOp>(op, tupleTy,
                                               ValueRange{half[0], half[1]});
    return success();
  }
};

/// The shifts are not elementwise in their second operand: `sll{bx,ho,wq,dp}`
/// shift every lane by the *same* amount, held in an ordinary register, where
/// `arith.shli` gives each lane its own. So a shift by a splat lowers, and a
/// genuinely per-lane shift does not (the ISA has no equivalent of AVX2's
/// `vpsllvd`) -- a class-D row of the coverage table.
template <typename SourceOp, typename PB, typename PH, typename PW, typename PD>
struct VectorShiftToLVX : public OpConversionPattern<SourceOp> {
  using OpConversionPattern<SourceOp>::OpConversionPattern;
  using OpAdaptor = typename OpConversionPattern<SourceOp>::OpAdaptor;
  LogicalResult
  matchAndRewrite(SourceOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    auto vecTy = dyn_cast<VectorType>(op.getType());
    if (!vecTy)
      return rewriter.notifyMatchFailure(op, "the scalar pattern handles this");
    Type tupleTy = this->getTypeConverter()->convertType(vecTy);
    unsigned units = tupleTy ? tupleWidth(tupleTy) : 0;
    if (!units)
      return rewriter.notifyMatchFailure(op, "vector shape has no register tuple");
    Location loc = op.getLoc();
    Type regTy = RegisterType::get(rewriter.getContext(), std::nullopt);

    // The uniform shift amount, from a broadcast or a splat constant.
    Value amount;
    Value original = op.getRhs();
    if (auto bcast = original.template getDefiningOp<vector::BroadcastOp>()) {
      if (!isa<VectorType>(bcast.getSource().getType()))
        amount = rewriter.getRemappedValue(bcast.getSource());
    } else if (auto cst = original.template getDefiningOp<arith::ConstantOp>()) {
      auto dense = dyn_cast<DenseIntElementsAttr>(cst.getValue());
      if (dense && dense.isSplat())
        amount = rewriter.create<lvx::LiOp>(
            loc, regTy,
            rewriter.getI64IntegerAttr(
                dense.template getSplatValue<APInt>().getZExtValue()));
    }
    if (!amount)
      return rewriter.notifyMatchFailure(
          op, "the ISA shifts every lane by one amount; this shift is per-lane");

    unsigned bits = vecTy.getElementTypeBitWidth();
    Value value = adaptor.getLhs();
    if (units == 2) {
      Value result = byWidthBinary<PB, PH, PW, PD>(bits, rewriter, loc, tupleTy,
                                                   value, amount);
      if (!result)
        return rewriter.notifyMatchFailure(op, "no shift for this lane width");
      rewriter.replaceOp(op, result);
      return success();
    }
    Type pairTy = lvx::PairType::get(rewriter.getContext(), std::nullopt);
    Value half[2];
    for (unsigned k = 0; k != 2; ++k) {
      half[k] = byWidthBinary<PB, PH, PW, PD>(
          bits, rewriter, loc, pairTy, quadHalf(rewriter, loc, value, k), amount);
      if (!half[k])
        return rewriter.notifyMatchFailure(op, "no shift for this lane width");
    }
    rewriter.replaceOpWithNewOp<lvx::ConcatOp>(op, tupleTy,
                                               ValueRange{half[0], half[1]});
    return success();
  }
};

// The tables. One line per source op: the pair ops by element width, then
// the quad composites. `NoLaneOp` is a shape the ISA has not got.
//
//                                        i8         i16        i32        i64
using VAddIToLVX = VectorBinaryToLVX<arith::AddIOp,
    lvx::AddbxOp, lvx::AddhoOp, lvx::AddwqOp, lvx::AdddpOp,
    lvx::AddbvOp, lvx::AddhxOp, lvx::AddwoOp, lvx::AdddqOp>;
using VSubIToLVX = VectorBinaryToLVX<arith::SubIOp,
    lvx::SbfbxOp, lvx::SbfhoOp, lvx::SbfwqOp, lvx::SbfdpOp,
    lvx::SbfbvOp, lvx::SbfhxOp, lvx::SbfwoOp, lvx::SbfdqOp>;
// No 8-bit multiply: only the widening `mulxbho`, which is another op.
using VMulIToLVX = VectorBinaryToLVX<arith::MulIOp,
    NoLaneOp,     lvx::MulhoOp, lvx::MulwqOp, lvx::MuldpOp,
    NoLaneOp,     NoLaneOp,     NoLaneOp,     NoLaneOp>;
using VMinSIToLVX = VectorBinaryToLVX<arith::MinSIOp,
    lvx::MinbxOp, lvx::MinhoOp, lvx::MinwqOp, lvx::MindpOp,
    lvx::MinbvOp, lvx::MinhxOp, lvx::MinwoOp, lvx::MindqOp>;
using VMaxSIToLVX = VectorBinaryToLVX<arith::MaxSIOp,
    lvx::MaxbxOp, lvx::MaxhoOp, lvx::MaxwqOp, lvx::MaxdpOp,
    lvx::MaxbvOp, lvx::MaxhxOp, lvx::MaxwoOp, lvx::MaxdqOp>;
using VMinUIToLVX = VectorBinaryToLVX<arith::MinUIOp,
    lvx::MinubxOp, lvx::MinuhoOp, lvx::MinuwqOp, lvx::MinudpOp,
    lvx::MinubvOp, lvx::MinuhxOp, lvx::MinuwoOp, lvx::MinudqOp>;
using VMaxUIToLVX = VectorBinaryToLVX<arith::MaxUIOp,
    lvx::MaxubxOp, lvx::MaxuhoOp, lvx::MaxuwqOp, lvx::MaxudpOp,
    lvx::MaxubvOp, lvx::MaxuhxOp, lvx::MaxuwoOp, lvx::MaxudqOp>;
// The bitwise ops do not care where the lanes are: `andq`/`iorq`/`eorq` are
// quadword-wide, so one op serves every element type, and a 256-bit vector
// is two of them.
using VAndIToLVX = VectorBinaryToLVX<arith::AndIOp,
    lvx::AndqOp, lvx::AndqOp, lvx::AndqOp, lvx::AndqOp,
    NoLaneOp,    NoLaneOp,    NoLaneOp,    NoLaneOp>;
using VOrIToLVX = VectorBinaryToLVX<arith::OrIOp,
    lvx::IorqOp, lvx::IorqOp, lvx::IorqOp, lvx::IorqOp,
    NoLaneOp,    NoLaneOp,    NoLaneOp,    NoLaneOp>;
using VXOrIToLVX = VectorBinaryToLVX<arith::XOrIOp,
    lvx::EorqOp, lvx::EorqOp, lvx::EorqOp, lvx::EorqOp,
    NoLaneOp,    NoLaneOp,    NoLaneOp,    NoLaneOp>;
using VShLIToLVX = VectorShiftToLVX<arith::ShLIOp,
    lvx::SllbxOp, lvx::SllhoOp, lvx::SllwqOp, lvx::SlldpOp>;
using VShRSIToLVX = VectorShiftToLVX<arith::ShRSIOp,
    lvx::SrabxOp, lvx::SrahoOp, lvx::SrawqOp, lvx::SradpOp>;
using VShRUIToLVX = VectorShiftToLVX<arith::ShRUIOp,
    lvx::SrlbxOp, lvx::SrlhoOp, lvx::SrlwqOp, lvx::SrldpOp>;
using VAbsIToLVX = VectorUnaryToLVX<math::AbsIOp,
    lvx::AbsbxOp, lvx::AbshoOp, lvx::AbswqOp, lvx::AbsdpOp,
    lvx::AbsbvOp, lvx::AbshxOp, lvx::AbswoOp, lvx::AbsdqOp>;
// No 8-bit bit-counting: `clzbx`/`ctzbx`/`cbsbx` do not exist.
using VCtlzToLVX = VectorUnaryToLVX<math::CountLeadingZerosOp,
    NoLaneOp, lvx::ClzhoOp, lvx::ClzwqOp, lvx::ClzdpOp,
    NoLaneOp, NoLaneOp,     NoLaneOp,     NoLaneOp>;
using VCttzToLVX = VectorUnaryToLVX<math::CountTrailingZerosOp,
    NoLaneOp, lvx::CtzhoOp, lvx::CtzwqOp, lvx::CtzdpOp,
    NoLaneOp, NoLaneOp,     NoLaneOp,     NoLaneOp>;
using VCtpopToLVX = VectorUnaryToLVX<math::CtPopOp,
    NoLaneOp, lvx::CbshoOp, lvx::CbswqOp, lvx::CbsdpOp,
    NoLaneOp, NoLaneOp,     NoLaneOp,     NoLaneOp>;

// Float. There is no 8-bit float, and f16 (`ho`/`hx`) is out of scope for
// now (VectorCoverage.md §1), but the ops are named here anyway: the type
// converter decides what reaches them.
using VAddFToLVX = VectorBinaryToLVX<arith::AddFOp,
    NoLaneOp, lvx::FaddhoOp, lvx::FaddwqOp, lvx::FadddpOp,
    NoLaneOp, lvx::FaddhxOp, lvx::FaddwoOp, lvx::FadddqOp>;
using VSubFToLVX = VectorBinaryToLVX<arith::SubFOp,
    NoLaneOp, lvx::FsbfhoOp, lvx::FsbfwqOp, lvx::FsbfdpOp,
    NoLaneOp, lvx::FsbfhxOp, lvx::FsbfwoOp, lvx::FsbfdqOp>;
using VMulFToLVX = VectorBinaryToLVX<arith::MulFOp,
    NoLaneOp, lvx::FmulhoOp, lvx::FmulwqOp, lvx::FmuldpOp,
    NoLaneOp, lvx::FmulhxOp, lvx::FmulwoOp, lvx::FmuldqOp>;
// 754-2019 minimum/maximum (NaN propagating) and 754-2008 minNum/maxNum
// (NaN returning the other operand) are different instructions, and pairing
// them wrongly is invisible on non-NaN input -- see the min/max invariant in
// the top-level CLAUDE.md.
using VMinimumFToLVX = VectorBinaryToLVX<arith::MinimumFOp,
    NoLaneOp, lvx::FminhoOp, lvx::FminwqOp, lvx::FmindpOp,
    NoLaneOp, lvx::FminhxOp, lvx::FminwoOp, lvx::FmindqOp>;
using VMaximumFToLVX = VectorBinaryToLVX<arith::MaximumFOp,
    NoLaneOp, lvx::FmaxhoOp, lvx::FmaxwqOp, lvx::FmaxdpOp,
    NoLaneOp, lvx::FmaxhxOp, lvx::FmaxwoOp, lvx::FmaxdqOp>;
using VMinNumFToLVX = VectorBinaryToLVX<arith::MinNumFOp,
    NoLaneOp, lvx::FminnhoOp, lvx::FminnwqOp, lvx::FminndpOp,
    NoLaneOp, lvx::FminnhxOp, lvx::FminnwoOp, lvx::FminndqOp>;
using VMaxNumFToLVX = VectorBinaryToLVX<arith::MaxNumFOp,
    NoLaneOp, lvx::FmaxnhoOp, lvx::FmaxnwqOp, lvx::FmaxndpOp,
    NoLaneOp, lvx::FmaxnhxOp, lvx::FmaxnwoOp, lvx::FmaxndqOp>;
// `copysign` is `fsign*` at pair width and `copysign*` -- the composite of
// `fsign*` -- at quad width, one of the few places the two names differ.
using VCopySignToLVX = VectorBinaryToLVX<math::CopySignOp,
    NoLaneOp, lvx::FsignhoOp,   lvx::FsignwqOp,   lvx::FsigndpOp,
    NoLaneOp, lvx::CopysignhxOp, lvx::CopysignwoOp, lvx::CopysigndqOp>;
using VNegFToLVX = VectorUnaryToLVX<arith::NegFOp,
    NoLaneOp, lvx::FneghoOp, lvx::FnegwqOp, lvx::FnegdpOp,
    NoLaneOp, lvx::FneghxOp, lvx::FnegwoOp, lvx::FnegdqOp>;
using VAbsFToLVX = VectorUnaryToLVX<math::AbsFOp,
    NoLaneOp, lvx::FabshoOp, lvx::FabswqOp, lvx::FabsdpOp,
    NoLaneOp, lvx::FabshxOp, lvx::FabswoOp, lvx::FabsdqOp>;

//===----------------------------------------------------------------------===//
// Masks: the vector compares write one, `blend` reads one.
//
// `vector<Nxi1>` is a register holding N low bits (the type converter above).
// `comp*q`/`fcomp*q` produce exactly that -- and since 2026-09-22 they clear
// the register's upper bits first, so nothing has to mask the result.
//===----------------------------------------------------------------------===//

/// The lane count of a vector operand, if the ISA has a lane-parallel form
/// for it: a pair (128 bits) or, through `Builtin@split`, a quad.
static unsigned laneCountOf(Type converted, VectorType vecTy) {
  unsigned units = converted ? tupleWidth(converted) : 0;
  return units ? vecTy.getNumElements() : 0;
}

struct VectorCmpIToLVX : public OpConversionPattern<arith::CmpIOp> {
  using OpConversionPattern::OpConversionPattern;
  LogicalResult
  matchAndRewrite(arith::CmpIOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    auto vecTy = dyn_cast<VectorType>(op.getLhs().getType());
    if (!vecTy)
      return rewriter.notifyMatchFailure(op, "the scalar pattern handles this");
    Type tupleTy = getTypeConverter()->convertType(vecTy);
    Type regTy = getTypeConverter()->convertType(op.getType());
    if (!laneCountOf(tupleTy, vecTy) || !regTy)
      return rewriter.notifyMatchFailure(op, "no register tuple, or no mask");
    if (tupleWidth(tupleTy) != 2)
      return rewriter.notifyMatchFailure(
          op, "the ISA compares a pair; a quad compare has no composite");
    IntComp pred = mapCmpIPredicate(op.getPredicate());
    Location loc = op.getLoc();
    Value lhs = adaptor.getLhs(), rhs = adaptor.getRhs();
    Value result;
    switch (vecTy.getElementTypeBitWidth()) {
    case 8:
      result = rewriter.create<lvx::CompbxOp>(loc, regTy, pred, lhs, rhs);
      break;
    case 16:
      result = rewriter.create<lvx::ComphoOp>(loc, regTy, pred, lhs, rhs);
      break;
    case 32:
      result = rewriter.create<lvx::CompwqOp>(loc, regTy, pred, lhs, rhs);
      break;
    case 64:
      result = rewriter.create<lvx::CompdpOp>(loc, regTy, pred, lhs, rhs);
      break;
    default:
      return rewriter.notifyMatchFailure(op, "no compare for this lane width");
    }
    rewriter.replaceOp(op, result);
    return success();
  }
};

struct VectorCmpFToLVX : public OpConversionPattern<arith::CmpFOp> {
  using OpConversionPattern::OpConversionPattern;
  LogicalResult
  matchAndRewrite(arith::CmpFOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    auto vecTy = dyn_cast<VectorType>(op.getLhs().getType());
    if (!vecTy)
      return rewriter.notifyMatchFailure(op, "the scalar pattern handles this");
    Type tupleTy = getTypeConverter()->convertType(vecTy);
    Type regTy = getTypeConverter()->convertType(op.getType());
    if (!laneCountOf(tupleTy, vecTy) || !regTy)
      return rewriter.notifyMatchFailure(op, "no register tuple, or no mask");
    if (tupleWidth(tupleTy) != 2)
      return rewriter.notifyMatchFailure(
          op, "the ISA compares a pair; a quad compare has no composite");
    std::optional<FloatCompMapping> mapping = mapCmpFPredicate(op.getPredicate());
    if (!mapping)
      return rewriter.notifyMatchFailure(op, "unsupported predicate");
    Location loc = op.getLoc();
    Value lhs = mapping->swapOperands ? adaptor.getRhs() : adaptor.getLhs();
    Value rhs = mapping->swapOperands ? adaptor.getLhs() : adaptor.getRhs();
    Value result;
    switch (vecTy.getElementTypeBitWidth()) {
    case 16:
      result = rewriter.create<lvx::FcomphoOp>(loc, regTy, mapping->pred, lhs, rhs);
      break;
    case 32:
      result = rewriter.create<lvx::FcompwqOp>(loc, regTy, mapping->pred, lhs, rhs);
      break;
    case 64:
      result = rewriter.create<lvx::FcompdpOp>(loc, regTy, mapping->pred, lhs, rhs);
      break;
    default:
      return rewriter.notifyMatchFailure(op, "no compare for this lane width");
    }
    rewriter.replaceOp(op, result);
    return success();
  }
};

/// `arith.select` under a lane mask: `blend*`, which writes *through* its
/// destination -- the lanes the mask clears keep what was there. So the
/// false value is the tied operand, and when it is live past the select the
/// tied-operand preserving-copy pass gives the blend a private copy, exactly
/// as it does for an `ffma` accumulator.
/// `blend{bx,ho,wq,dp} $d = $mask? $yes, $no` at `vecTy`'s lane width, or null
/// when the ISA has no blend for it. The blend writes through its destination,
/// so `no` is its tied operand and the preserving-copy pass covers a `no` that
/// is live past it.
static Value createBlend(ConversionPatternRewriter &rewriter, Location loc,
                         Type tupleTy, VectorType vecTy, Value yes, Value mask,
                         Value no) {
  switch (vecTy.getElementTypeBitWidth()) {
  case 8:
    return rewriter.create<lvx::BlendbxOp>(loc, tupleTy, yes, mask, no);
  case 16:
    return rewriter.create<lvx::BlendhoOp>(loc, tupleTy, yes, mask, no);
  case 32:
    return rewriter.create<lvx::BlendwqOp>(loc, tupleTy, yes, mask, no);
  case 64:
    return rewriter.create<lvx::BlenddpOp>(loc, tupleTy, yes, mask, no);
  default:
    return {};
  }
}

/// Is `v` a vector constant of all zeros? Asked of the *original* operand, so
/// the constant is still an `arith.constant` here.
static bool isZeroVector(Value v) {
  auto constant = v.getDefiningOp<arith::ConstantOp>();
  if (!constant)
    return false;
  auto dense = dyn_cast<DenseElementsAttr>(constant.getValue());
  if (!dense || !dense.isSplat())
    return false;
  if (isa<FloatType>(dense.getElementType()))
    return dense.getSplatValue<APFloat>().isZero();
  return dense.getSplatValue<APInt>().isZero();
}

struct VectorSelectToLVX : public OpConversionPattern<arith::SelectOp> {
  using OpConversionPattern::OpConversionPattern;
  LogicalResult
  matchAndRewrite(arith::SelectOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    auto vecTy = dyn_cast<VectorType>(op.getType());
    auto condTy = dyn_cast<VectorType>(op.getCondition().getType());
    if (!vecTy || !condTy)
      return rewriter.notifyMatchFailure(op, "the scalar pattern handles this");
    Type tupleTy = getTypeConverter()->convertType(vecTy);
    if (!laneCountOf(tupleTy, vecTy) ||
        condTy.getNumElements() != vecTy.getNumElements())
      return rewriter.notifyMatchFailure(op, "no register tuple for this shape");
    if (tupleWidth(tupleTy) != 2)
      return rewriter.notifyMatchFailure(
          op, "the ISA blends a pair; a quad blend has no composite");
    Location loc = op.getLoc();
    Value yes = adaptor.getTrueValue(), mask = adaptor.getCondition(),
          no = adaptor.getFalseValue();
    Value result = createBlend(rewriter, loc, tupleTy, vecTy, yes, mask, no);
    if (!result)
      return rewriter.notifyMatchFailure(op, "no blend for this lane width");
    rewriter.replaceOp(op, result);
    return success();
  }
};

//===----------------------------------------------------------------------===//
// Masks: making one, and the memory accesses that consume one.
//
// A `vector<Nxi1>` is a register holding N low bits, one per lane -- what
// `comp*q`/`fcomp*q` write and what `masks` reads (§1). Making one from a
// lane *count* is the loop-tail idiom: lanes `0..n-1` active is `(1 << n) - 1`.
//
// The LSU is the exception to bit-per-lane: `maskm` takes one bit per *byte*,
// the LSU block having no room to encode a lane size, so a masked access puts
// an `extb{2,4,8}d` between the lane mask and the prefix (lvx-mds
// docs/Lane-masking-design.md §4). That widening is a real op with a real
// result, so CSE shares it between a masked load and a masked store of the
// same lane width under the same mask -- which is the whole of a masked loop
// body.
//===----------------------------------------------------------------------===//

/// The byte-enable mask an LSU access needs, from a lane mask: `extb{2,4,8}d`
/// replicates each lane's bit over that lane's bytes. Byte lanes need none.
static Value laneMaskToByteEnables(ConversionPatternRewriter &rewriter,
                                   Location loc, Value mask,
                                   unsigned bytesPerLane) {
  Type regTy = mask.getType();
  switch (bytesPerLane) {
  case 1:
    return mask;
  case 2:
    return rewriter.create<lvx::Extb2dOp>(loc, regTy, mask);
  case 4:
    return rewriter.create<lvx::Extb4dOp>(loc, regTy, mask);
  case 8:
    return rewriter.create<lvx::Extb8dOp>(loc, regTy, mask);
  default:
    return {};
  }
}

/// `vector.constant_mask [n]`: the constant `(1 << n) - 1`, one `lvx.li`.
struct VectorConstantMaskToLVX
    : public OpConversionPattern<vector::ConstantMaskOp> {
  using OpConversionPattern::OpConversionPattern;
  LogicalResult
  matchAndRewrite(vector::ConstantMaskOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    auto vecTy = cast<VectorType>(op.getType());
    ArrayRef<int64_t> dims = op.getMaskDimSizes();
    if (vecTy.getRank() != 1 || dims.size() != 1)
      return rewriter.notifyMatchFailure(op, "only a 1-D mask has a register");
    unsigned lanes = vecTy.getNumElements();
    if (lanes > 64)
      return rewriter.notifyMatchFailure(op, "more lanes than a register bits");
    Type regTy = getTypeConverter()->convertType(vecTy);
    if (!regTy)
      return rewriter.notifyMatchFailure(op, "no register for this mask");
    uint64_t active = std::min<int64_t>(dims[0], lanes);
    uint64_t bits = active == 64 ? ~uint64_t{0} : (uint64_t{1} << active) - 1;
    rewriter.replaceOpWithNewOp<lvx::LiOp>(
        op, regTy, rewriter.getI64IntegerAttr(static_cast<int64_t>(bits)));
    return success();
  }
};

/// `vector.create_mask %n`: `(1 << n) - 1`, with `%n` clamped to `[0, lanes]`
/// first. The clamp is not optional -- `vector.create_mask` is defined for a
/// count outside the vector (a negative one masks nothing, a large one masks
/// everything) whereas a shift by 64 or more is not defined at all, and a
/// negative count would shift by its low six bits and set the wrong lanes.
/// Five ops -- `maxd_i`, `mind_i`, the `li` the shift's source needs, `slld`,
/// `addd_i` -- of which the `li` is loop-invariant, so four per iteration. A
/// constant count folds to `vector.constant_mask` upstream and is one `li`.
struct VectorCreateMaskToLVX : public OpConversionPattern<vector::CreateMaskOp> {
  using OpConversionPattern::OpConversionPattern;
  LogicalResult
  matchAndRewrite(vector::CreateMaskOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    auto vecTy = cast<VectorType>(op.getType());
    if (vecTy.getRank() != 1 || adaptor.getOperands().size() != 1)
      return rewriter.notifyMatchFailure(op, "only a 1-D mask has a register");
    unsigned lanes = vecTy.getNumElements();
    if (lanes > 63)
      return rewriter.notifyMatchFailure(op, "more lanes than a shift reaches");
    Type regTy = getTypeConverter()->convertType(vecTy);
    if (!regTy)
      return rewriter.notifyMatchFailure(op, "no register for this mask");
    Location loc = op.getLoc();
    Value count = adaptor.getOperands()[0];
    Value low = rewriter.create<lvx::MaxdImmOp>(loc, regTy, count,
                                                rewriter.getI64IntegerAttr(0));
    Value clamped = rewriter.create<lvx::MindImmOp>(
        loc, regTy, low, rewriter.getI64IntegerAttr(lanes));
    Value one = rewriter.create<lvx::LiOp>(loc, regTy,
                                           rewriter.getI64IntegerAttr(1));
    Value shifted = rewriter.create<lvx::SlldOp>(loc, regTy, one, clamped);
    rewriter.replaceOpWithNewOp<lvx::AdddImmOp>(
        op, regTy, shifted, rewriter.getI64IntegerAttr(-1));
    return success();
  }
};

/// The bytes one lane of `vecTy` occupies, or 0 when the ISA has no mask
/// granularity for it.
static unsigned bytesPerLaneOf(VectorType vecTy) {
  unsigned bits = vecTy.getElementTypeBitWidth();
  return (bits == 8 || bits == 16 || bits == 32 || bits == 64) ? bits / 8 : 0;
}

/// `vector.maskedload`: `extb*` to byte enables, then the `maskm`-prefixed
/// access. Inactive lanes come back zero, so a `pass_thru` that is not a zero
/// constant needs a blend after -- `maskm` has no merge form, by design
/// (lvx-mds docs/Lane-masking-design.md §1).
struct VectorMaskedLoadToLVX
    : public OpConversionPattern<vector::MaskedLoadOp> {
  using OpConversionPattern::OpConversionPattern;
  LogicalResult
  matchAndRewrite(vector::MaskedLoadOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    auto vecTy = op.getVectorType();
    auto memrefType = cast<MemRefType>(op.getBase().getType());
    Type tupleTy = getTypeConverter()->convertType(vecTy);
    Type regTy = getTypeConverter()->convertType(memrefType);
    unsigned bytes = bytesPerLaneOf(vecTy);
    if (!tupleWidth(tupleTy) || !bytes)
      return rewriter.notifyMatchFailure(op, "no register tuple for this shape");
    FailureOr<Value> address =
        computeAddress(rewriter, op.getLoc(), memrefType, adaptor.getBase(),
                       adaptor.getIndices(), regTy);
    if (failed(address))
      return rewriter.notifyMatchFailure(
          op, "unsupported memref layout for address linearization");
    Location loc = op.getLoc();
    Value enables =
        laneMaskToByteEnables(rewriter, loc, adaptor.getMask(), bytes);
    Value loaded = rewriter.create<lvx::MaskedLoadOp>(
        loc, tupleTy, enables, *address, rewriter.getI64IntegerAttr(0));
    if (isZeroVector(op.getPassThru())) {
      rewriter.replaceOp(op, loaded);
      return success();
    }
    // Inactive lanes are zero, so blending them against the pass-thru under
    // the *lane* mask restores them.
    Value blended = createBlend(rewriter, loc, tupleTy, vecTy, loaded,
                                adaptor.getMask(), adaptor.getPassThru());
    if (!blended)
      return rewriter.notifyMatchFailure(
          op, "no blend for this lane width, and pass_thru is not zero");
    rewriter.replaceOp(op, blended);
    return success();
  }
};

/// `vector.maskedstore`: the same widening, then the prefixed store. Disabled
/// bytes are not written at all -- no read-modify-write, so no data race with
/// whatever else owns them.
struct VectorMaskedStoreToLVX
    : public OpConversionPattern<vector::MaskedStoreOp> {
  using OpConversionPattern::OpConversionPattern;
  LogicalResult
  matchAndRewrite(vector::MaskedStoreOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    auto vecTy = op.getVectorType();
    auto memrefType = cast<MemRefType>(op.getBase().getType());
    Type regTy = getTypeConverter()->convertType(memrefType);
    unsigned bytes = bytesPerLaneOf(vecTy);
    if (!tupleWidth(adaptor.getValueToStore().getType()) || !bytes)
      return rewriter.notifyMatchFailure(op, "no register tuple for this shape");
    FailureOr<Value> address =
        computeAddress(rewriter, op.getLoc(), memrefType, adaptor.getBase(),
                       adaptor.getIndices(), regTy);
    if (failed(address))
      return rewriter.notifyMatchFailure(
          op, "unsupported memref layout for address linearization");
    Location loc = op.getLoc();
    Value enables =
        laneMaskToByteEnables(rewriter, loc, adaptor.getMask(), bytes);
    rewriter.replaceOpWithNewOp<lvx::MaskedStoreOp>(
        op, adaptor.getValueToStore(), enables, *address,
        rewriter.getI64IntegerAttr(0));
    return success();
  }
};

//===----------------------------------------------------------------------===//
// Lanes: extract, insert, shuffle, and the casts that are free.
//
// A register tuple is a row of 64-bit units, so an element's home is a unit
// and a bit offset inside it (docs/VectorCoverage.md, Phase 3):
//
//   64-bit elements  one per unit    -- a lane view, no instruction at all
//   narrower ones    several per unit -- a bit field of it, `extfzd`/`insfd`
//
// Building a *new* tuple is `lvx.concat`, which the allocator places (no
// instruction) -- but only values it places may be parts of it, so a part
// taken from another live tuple is copied first. Without the copy the concat
// would put the new value in the old tuple's register while the old tuple is
// still live, which the allocator cannot detect: `lvx.concat`'s members are
// unified, not tested for interference. A tied `lvx.insert_lane` pseudo plus
// the preserving-copy pass would elide the copies when the source dies at
// the insert; see docs/VectorCoverage.md §7.
//===----------------------------------------------------------------------===//
// Reductions (Phase 4).
//
// The ISA has no horizontal instruction, and the 64-bit SIMD family was
// retired, so there is no lane-parallel op below a pair. That fixes the shape
// of a reduction:
//
//   * a quad folds to a pair with one lane-parallel op on its two halves, and
//     the halves are lane views, so that step is one instruction;
//
//   * with 64-bit lanes a pair's two units *are* its two lanes, so one scalar
//     op finishes it -- `vector.reduction <add>` over `vector<2xi64>` is a
//     single `addd`;
//
//   * narrower lanes have several per unit and nothing adds two units
//     lane-wise, so each level brings the lanes alongside each other first:
//     `even<w>q(v, v)` puts the even lanes of the whole pair in each unit and
//     `odd<w>q(v, v)` the odd ones, and the lane-parallel op on those two
//     halves the live lane count. Three instructions a level, log2(lanes)
//     levels, and lane 0 holds the answer at the end.
//
// So i64x2 is 1, i32x4 is 6, i16x8 is 9, i8x16 is 12 -- which is the measure
// §1 asked for before proposing a horizontal instruction, and the i8 and i16
// rows are what would justify one.
//===----------------------------------------------------------------------===//

/// The lane-parallel op of `kind` on two pairs, or null when the ISA has none
/// at that lane width. The tables are the elementwise lowering's own.
static Value reduceStep(ConversionPatternRewriter &rewriter, Location loc,
                        vector::CombiningKind kind, unsigned bits, bool isFloat,
                        Type pairTy, Value a, Value b) {
  using K = vector::CombiningKind;
  // `add` and `mul` name both families; the element type is what says which.
  switch (kind) {
  case K::ADD:
    if (isFloat)
      return byWidthBinary<NoLaneOp, lvx::FaddhoOp, lvx::FaddwqOp,
                           lvx::FadddpOp>(bits, rewriter, loc, pairTy, a, b);
    return byWidthBinary<lvx::AddbxOp, lvx::AddhoOp, lvx::AddwqOp,
                         lvx::AdddpOp>(bits, rewriter, loc, pairTy, a, b);
  case K::MUL:
    if (isFloat)
      return byWidthBinary<NoLaneOp, lvx::FmulhoOp, lvx::FmulwqOp,
                           lvx::FmuldpOp>(bits, rewriter, loc, pairTy, a, b);
    return byWidthBinary<NoLaneOp, lvx::MulhoOp, lvx::MulwqOp, lvx::MuldpOp>(
        bits, rewriter, loc, pairTy, a, b);
  case K::MINSI:
    return byWidthBinary<lvx::MinbxOp, lvx::MinhoOp, lvx::MinwqOp,
                         lvx::MindpOp>(bits, rewriter, loc, pairTy, a, b);
  case K::MAXSI:
    return byWidthBinary<lvx::MaxbxOp, lvx::MaxhoOp, lvx::MaxwqOp,
                         lvx::MaxdpOp>(bits, rewriter, loc, pairTy, a, b);
  case K::MINUI:
    return byWidthBinary<lvx::MinubxOp, lvx::MinuhoOp, lvx::MinuwqOp,
                         lvx::MinudpOp>(bits, rewriter, loc, pairTy, a, b);
  case K::MAXUI:
    return byWidthBinary<lvx::MaxubxOp, lvx::MaxuhoOp, lvx::MaxuwqOp,
                         lvx::MaxudpOp>(bits, rewriter, loc, pairTy, a, b);
  case K::AND:
    return rewriter.create<lvx::AndqOp>(loc, pairTy, a, b);
  case K::OR:
    return rewriter.create<lvx::IorqOp>(loc, pairTy, a, b);
  case K::XOR:
    return rewriter.create<lvx::EorqOp>(loc, pairTy, a, b);
  // `minimumf`/`maximumf` propagate a NaN, `minnumf`/`maxnumf` return the
  // numeric operand -- the split the whole toolchain turns on (lvx-csw
  // CLAUDE.md, "The min/max NaN split"). `fmin`/`fmax` are the propagating
  // pair, `fminn`/`fmaxn` the numeric one.
  case K::MINIMUMF:
    return byWidthBinary<NoLaneOp, lvx::FminhoOp, lvx::FminwqOp,
                         lvx::FmindpOp>(bits, rewriter, loc, pairTy, a, b);
  case K::MAXIMUMF:
    return byWidthBinary<NoLaneOp, lvx::FmaxhoOp, lvx::FmaxwqOp,
                         lvx::FmaxdpOp>(bits, rewriter, loc, pairTy, a, b);
  case K::MINNUMF:
    return byWidthBinary<NoLaneOp, lvx::FminnhoOp, lvx::FminnwqOp,
                         lvx::FminndpOp>(bits, rewriter, loc, pairTy, a, b);
  case K::MAXNUMF:
    return byWidthBinary<NoLaneOp, lvx::FmaxnhoOp, lvx::FmaxnwqOp,
                         lvx::FmaxndpOp>(bits, rewriter, loc, pairTy, a, b);
  }
  return {};
}

/// `even<w>q(v, v)` / `odd<w>q(v, v)`: the even (resp. odd) lanes of the whole
/// pair, in both of the result's units.
static Value evenOdd(ConversionPatternRewriter &rewriter, Location loc,
                     unsigned bits, Type pairTy, Value v, bool odd) {
  if (odd)
    return byWidthBinary<lvx::OddbqOp, lvx::OddhqOp, lvx::OddwqOp,
                         lvx::OdddqOp>(bits, rewriter, loc, pairTy, v, v);
  return byWidthBinary<lvx::EvenbqOp, lvx::EvenhqOp, lvx::EvenwqOp,
                       lvx::EvendqOp>(bits, rewriter, loc, pairTy, v, v);
}

/// The scalar op of `kind` on two 64-bit registers, for the last step when
/// the lanes are 64 bits wide. Only the kinds a 64-bit lane can carry.
static Value reduceScalar64(ConversionPatternRewriter &rewriter, Location loc,
                            vector::CombiningKind kind, bool isFloat,
                            Type regTy, Value a, Value b) {
  using K = vector::CombiningKind;
  switch (kind) {
  case K::ADD:
    if (isFloat) return rewriter.create<lvx::FadddOp>(loc, regTy, a, b);
    return rewriter.create<lvx::AdddOp>(loc, regTy, a, b);
  case K::MUL:
    if (isFloat) return rewriter.create<lvx::FmuldOp>(loc, regTy, a, b);
    return rewriter.create<lvx::MuldOp>(loc, regTy, a, b);
  case K::MINSI:    return rewriter.create<lvx::MindOp>(loc, regTy, a, b);
  case K::MAXSI:    return rewriter.create<lvx::MaxdOp>(loc, regTy, a, b);
  case K::MINUI:    return rewriter.create<lvx::MinudOp>(loc, regTy, a, b);
  case K::MAXUI:    return rewriter.create<lvx::MaxudOp>(loc, regTy, a, b);
  case K::AND:      return rewriter.create<lvx::AnddOp>(loc, regTy, a, b);
  case K::OR:       return rewriter.create<lvx::IordOp>(loc, regTy, a, b);
  case K::XOR:      return rewriter.create<lvx::EordOp>(loc, regTy, a, b);
  case K::MINIMUMF: return rewriter.create<lvx::FmindOp>(loc, regTy, a, b);
  case K::MAXIMUMF: return rewriter.create<lvx::FmaxdOp>(loc, regTy, a, b);
  case K::MINNUMF:  return rewriter.create<lvx::FminndOp>(loc, regTy, a, b);
  case K::MAXNUMF:  return rewriter.create<lvx::FmaxndOp>(loc, regTy, a, b);
  }
  return {};
}

/// `and`/`or`/`xor` on two 64-bit registers.
static Value bitwiseScalar(ConversionPatternRewriter &rewriter, Location loc,
                           vector::CombiningKind kind, Type regTy, Value a,
                           Value b) {
  using K = vector::CombiningKind;
  if (kind == K::AND)
    return rewriter.create<lvx::AnddOp>(loc, regTy, a, b);
  if (kind == K::OR)
    return rewriter.create<lvx::IordOp>(loc, regTy, a, b);
  return rewriter.create<lvx::EordOp>(loc, regTy, a, b);
}

struct VectorReductionToLVX : public OpConversionPattern<vector::ReductionOp> {
  using OpConversionPattern::OpConversionPattern;
  LogicalResult
  matchAndRewrite(vector::ReductionOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    VectorType vecTy = op.getSourceVectorType();
    Type tupleTy = getTypeConverter()->convertType(vecTy);
    unsigned units = tupleTy ? tupleWidth(tupleTy) : 0;
    if (!units || vecTy.getRank() != 1)
      return rewriter.notifyMatchFailure(op, "vector shape has no register tuple");
    unsigned bits = vecTy.getElementTypeBitWidth();
    unsigned lanes = vecTy.getNumElements();
    // A float reduction may only be reassociated when the op says so, and a
    // tree reassociates -- that is what makes it a tree. Without `reassoc`
    // the answer would differ from the source's left-to-right order in the
    // last bit, so leave it to upstream to unroll into a lane chain (§1: a
    // float reduction without reassoc is the sequential chain, not refused).
    // The attribute is DefaultValued, so it is the *flag* that has to be
    // tested -- asking whether the attribute is present answers `yes` even
    // for `fastmath<none>`.
    if (isa<FloatType>(vecTy.getElementType()) &&
        !arith::bitEnumContainsAll(op.getFastmath(),
                                   arith::FastMathFlags::reassoc))
      return rewriter.notifyMatchFailure(
          op, "a float reduction without reassoc is the sequential chain");
    vector::CombiningKind kind = op.getKind();
    bool isFloat = isa<FloatType>(vecTy.getElementType());
    Location loc = op.getLoc();
    Type pairTy = lvx::PairType::get(rewriter.getContext(), std::nullopt);
    Type regTy = RegisterType::get(rewriter.getContext(), std::nullopt);
    Value v = adaptor.getVector();

    // `and`/`or`/`xor` are bitwise and lane-independent, so their lanes never
    // have to be brought alongside each other: fold the units with the 64-bit
    // scalar op, then halve *within* the unit by shifting it down over itself.
    // The shift brings in zeros, which is the identity for `or` and `xor` and
    // for `and` only clears bits above the answer's own. Half the tree's cost
    // -- i32x4 is 3 ops rather than 6, i8x16 is 7 rather than 12.
    using K = vector::CombiningKind;
    if (kind == K::AND || kind == K::OR || kind == K::XOR) {
      if (units == 4) {
        Value lo = quadHalf(rewriter, loc, v, 0);
        Value hi = quadHalf(rewriter, loc, v, 1);
        v = kind == K::AND
                ? rewriter.create<lvx::AndqOp>(loc, pairTy, lo, hi).getResult()
            : kind == K::OR
                ? rewriter.create<lvx::IorqOp>(loc, pairTy, lo, hi).getResult()
                : rewriter.create<lvx::EorqOp>(loc, pairTy, lo, hi).getResult();
      }
      Value r = bitwiseScalar(rewriter, loc, kind, regTy,
                              rewriter.create<lvx::LaneOp>(loc, regTy, v, 0),
                              rewriter.create<lvx::LaneOp>(loc, regTy, v, 1));
      for (unsigned sh = 32; sh >= bits && sh >= 8; sh /= 2) {
        Value down = rewriter.create<lvx::SrldImmOp>(
            loc, regTy, r, rewriter.getI64IntegerAttr(sh));
        r = bitwiseScalar(rewriter, loc, kind, regTy, r, down);
      }
      rewriter.replaceOp(op, r);
      return success();
    }

    if (units == 4) { // a quad: one op on its two halves, and it is a pair
      v = reduceStep(rewriter, loc, kind, bits, isFloat, pairTy,
                     quadHalf(rewriter, loc, v, 0),
                     quadHalf(rewriter, loc, v, 1));
      if (!v)
        return rewriter.notifyMatchFailure(op, "no instruction for this lane shape");
      lanes /= 2;
    }
    while (lanes > 1) {
      if (bits == 64) { // the pair's units are its lanes
        Value lo = rewriter.create<lvx::LaneOp>(loc, regTy, v, 0);
        Value hi = rewriter.create<lvx::LaneOp>(loc, regTy, v, 1);
        Value r = reduceScalar64(rewriter, loc, kind, isFloat, regTy, lo, hi);
        if (!r)
          return rewriter.notifyMatchFailure(op, "no scalar op for this kind");
        rewriter.replaceOp(op, r);
        return success();
      }
      Value even = evenOdd(rewriter, loc, bits, pairTy, v, /*odd=*/false);
      Value odd = evenOdd(rewriter, loc, bits, pairTy, v, /*odd=*/true);
      if (!even || !odd)
        return rewriter.notifyMatchFailure(op, "no even/odd at this lane width");
      v = reduceStep(rewriter, loc, kind, bits, isFloat, pairTy, even, odd);
      if (!v)
        return rewriter.notifyMatchFailure(op, "no instruction for this lane shape");
      lanes /= 2;
    }
    // Lane 0 of the surviving pair is the answer, and a lane view of unit 0
    // is the register whose low `bits` hold it -- no instruction.
    rewriter.replaceOpWithNewOp<lvx::LaneOp>(op, regTy, v, 0);
    return success();
  }
};

//===----------------------------------------------------------------------===//

/// The unit of `tuple` holding element `pos`, and the element's bit offset in
/// it.
static std::pair<unsigned, unsigned> homeOf(unsigned pos, unsigned elemBits) {
  unsigned bit = pos * elemBits;
  return {bit / 64, bit % 64};
}

static Value laneOf(ConversionPatternRewriter &rewriter, Location loc,
                    Value tuple, unsigned unit, unsigned width) {
  MLIRContext *ctx = rewriter.getContext();
  Type ty = width == 1   ? Type(RegisterType::get(ctx, std::nullopt))
            : width == 2 ? Type(lvx::PairType::get(ctx, std::nullopt))
                         : Type(lvx::QuadType::get(ctx, std::nullopt));
  return rewriter.create<lvx::LaneOp>(loc, ty, tuple, unit);
}

/// A private copy of units `[unit, unit + width)` of `tuple`, safe to place
/// in a tuple being built.
static Value copyOfUnits(ConversionPatternRewriter &rewriter, Location loc,
                         Value tuple, unsigned unit, unsigned width,
                         unsigned tupleWidth) {
  Value part = width == tupleWidth
                   ? tuple
                   : laneOf(rewriter, loc, tuple, unit, width);
  return rewriter.create<lvx::MvOp>(loc, part.getType(), part);
}

/// `vector.extract` at a static position: the element's unit, and a bit-field
/// extract out of it when the element is narrower than the unit.
struct VectorExtractToLVX : public OpConversionPattern<vector::ExtractOp> {
  using OpConversionPattern::OpConversionPattern;
  LogicalResult
  matchAndRewrite(vector::ExtractOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    VectorType srcTy = op.getSourceVectorType();
    Type tupleTy = getTypeConverter()->convertType(srcTy);
    if (srcTy.getRank() != 1 || !tupleTy || !tupleWidth(tupleTy))
      return rewriter.notifyMatchFailure(op, "not a 1-D vector in a tuple");
    if (isa<VectorType>(op.getType()))
      return rewriter.notifyMatchFailure(op, "only a scalar element");
    ArrayRef<int64_t> pos = op.getStaticPosition();
    if (pos.size() != 1 || ShapedType::isDynamic(pos[0]))
      return rewriter.notifyMatchFailure(op, "only a static position");

    unsigned bits = srcTy.getElementTypeBitWidth();
    auto [unit, offset] = homeOf(pos[0], bits);
    Value single = laneOf(rewriter, op.getLoc(), adaptor.getSource(), unit, 1);
    if (bits == 64) {
      rewriter.replaceOp(op, single);
      return success();
    }
    Type regTy = getTypeConverter()->convertType(op.getType());
    rewriter.replaceOpWithNewOp<lvx::ExtfzdImmOp>(
        op, regTy, single, rewriter.getI64IntegerAttr(bits),
        rewriter.getI64IntegerAttr(offset));
    return success();
  }
};

/// `vector.insert` of a scalar at a static position: the result is built from
/// private copies of the units the insert leaves alone -- taken in the
/// largest aligned groups, so a quad keeps its untouched pair in one `copyq`
/// -- and the target unit, which is the scalar itself when the element fills
/// a unit and an `insfd` into a copy of it when it does not.
struct VectorInsertToLVX : public OpConversionPattern<vector::InsertOp> {
  using OpConversionPattern::OpConversionPattern;
  LogicalResult
  matchAndRewrite(vector::InsertOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    VectorType dstTy = op.getType();
    Type tupleTy = getTypeConverter()->convertType(dstTy);
    unsigned units = tupleTy ? tupleWidth(tupleTy) : 0;
    if (dstTy.getRank() != 1 || !units)
      return rewriter.notifyMatchFailure(op, "not a 1-D vector in a tuple");
    if (isa<VectorType>(op.getValueToStore().getType()))
      return rewriter.notifyMatchFailure(op, "only a scalar element");
    ArrayRef<int64_t> pos = op.getStaticPosition();
    if (pos.size() != 1 || ShapedType::isDynamic(pos[0]))
      return rewriter.notifyMatchFailure(op, "only a static position");

    unsigned bits = dstTy.getElementTypeBitWidth();
    auto [target, offset] = homeOf(pos[0], bits);
    Location loc = op.getLoc();
    Value src = adaptor.getDest();

    SmallVector<Value> parts;
    for (unsigned unit = 0; unit != units;) {
      if (unit == target) {
        Value single = adaptor.getValueToStore();
        if (bits != 64) {
          // `insfd` writes through its second operand, so that operand must
          // be a register nothing else needs: a copy of the target unit.
          Value into = copyOfUnits(rewriter, loc, src, unit, 1, units);
          single = rewriter.create<lvx::InsfdImmOp>(
              loc, into.getType(), single, into,
              rewriter.getI64IntegerAttr(bits),
              rewriter.getI64IntegerAttr(offset));
        }
        parts.push_back(single);
        ++unit;
        continue;
      }
      // The largest aligned run of untouched units starting here.
      unsigned width = 1;
      while (width < units && unit % (2 * width) == 0 &&
             unit + 2 * width <= units && target >= unit + 2 * width)
        width *= 2;
      parts.push_back(copyOfUnits(rewriter, loc, src, unit, width, units));
      unit += width;
    }
    if (parts.size() == 1)
      rewriter.replaceOp(op, parts.front());
    else
      rewriter.replaceOpWithNewOp<lvx::ConcatOp>(op, tupleTy, parts);
    return success();
  }
};

/// `vector.shuffle` with a constant mask, in the four shapes the ISA has an
/// answer for. `even`/`odd` first, because they are one instruction where
/// the register-level reading of the same mask would be two copies.
struct VectorShuffleToLVX : public OpConversionPattern<vector::ShuffleOp> {
  using OpConversionPattern::OpConversionPattern;
  LogicalResult
  matchAndRewrite(vector::ShuffleOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    VectorType srcTy = op.getV1VectorType();
    VectorType resTy = op.getResultVectorType();
    Type srcTuple = getTypeConverter()->convertType(srcTy);
    Type resTuple = getTypeConverter()->convertType(resTy);
    unsigned srcUnits = srcTuple ? tupleWidth(srcTuple) : 0;
    unsigned resUnits = resTuple ? tupleWidth(resTuple) : 0;
    if (srcTy.getRank() != 1 || !srcUnits || !resUnits)
      return rewriter.notifyMatchFailure(op, "not 1-D vectors in tuples");

    ArrayRef<int64_t> mask = op.getMask();
    unsigned bits = srcTy.getElementTypeBitWidth();
    unsigned lanes = srcTy.getNumElements();
    unsigned perUnit = 64 / bits;
    Location loc = op.getLoc();
    Value v1 = adaptor.getV1(), v2 = adaptor.getV2();

    // The even and the odd lanes of the two sources, taken together: one
    // `even*q` / `odd*q`.
    if (mask.size() == lanes && srcUnits == resUnits) {
      auto strided = [&](int64_t first) {
        return llvm::all_of(llvm::enumerate(mask), [&](auto it) {
          return it.value() == int64_t(2 * it.index()) + first;
        });
      };
      if (strided(0) || strided(1)) {
        bool even = strided(0);
        Value r;
        switch (bits) {
        case 8:
          r = even ? rewriter.create<lvx::EvenbqOp>(loc, resTuple, v1, v2).getResult()
                   : rewriter.create<lvx::OddbqOp>(loc, resTuple, v1, v2).getResult();
          break;
        case 16:
          r = even ? rewriter.create<lvx::EvenhqOp>(loc, resTuple, v1, v2).getResult()
                   : rewriter.create<lvx::OddhqOp>(loc, resTuple, v1, v2).getResult();
          break;
        case 32:
          r = even ? rewriter.create<lvx::EvenwqOp>(loc, resTuple, v1, v2).getResult()
                   : rewriter.create<lvx::OddwqOp>(loc, resTuple, v1, v2).getResult();
          break;
        case 64:
          r = even ? rewriter.create<lvx::EvendqOp>(loc, resTuple, v1, v2).getResult()
                   : rewriter.create<lvx::OdddqOp>(loc, resTuple, v1, v2).getResult();
          break;
        default:
          return rewriter.notifyMatchFailure(op, "no shuffle for this lane width");
        }
        rewriter.replaceOp(op, r);
        return success();
      }
    }

    // The perfect shuffle: `vector.interleave` spelled as a mask.
    if (mask.size() == 2 * lanes) {
      bool zip = true;
      for (auto [i, m] : llvm::enumerate(mask))
        zip &= m == int64_t(i % 2 ? lanes + i / 2 : i / 2);
      if (zip)
        return lowerInterleave(rewriter, op, resTuple, bits, v1, v2);
    }

    // Otherwise the mask has to be read at register granularity: each unit
    // of the result must be a whole unit of one source. Then the result is
    // those units side by side -- `lvx.concat`, which emits nothing, over
    // *copies* of them, which do: a part placed in the result's block would
    // otherwise share registers with the source tuple it still belongs to.
    // A result that is exactly one unit (or one whole source) needs no
    // concat, and is then free.
    if (mask.size() % perUnit)
      return rewriter.notifyMatchFailure(op, "mask is not register-aligned");
    struct Part { Value source; unsigned unit, width; };
    SmallVector<Part> parts;
    for (unsigned u = 0; u != resUnits; ++u) {
      int64_t base = mask[u * perUnit];
      if (base % perUnit)
        return rewriter.notifyMatchFailure(op, "mask is not register-aligned");
      for (unsigned i = 1; i != perUnit; ++i)
        if (mask[u * perUnit + i] != base + i)
          return rewriter.notifyMatchFailure(op, "mask is not register-aligned");
      parts.push_back({base < int64_t(lanes) ? v1 : v2,
                       unsigned((base % lanes) / perUnit), 1});
    }
    // Neighbouring units of one source become one wider copy where both the
    // source and the destination stay aligned: a quad's untouched half is
    // one `copyq`, not two `copyd`.
    auto mergePass = [&](unsigned w) {
      SmallVector<Part> merged;
      unsigned dst = 0;
      for (unsigned i = 0; i != parts.size();) {
        if (i + 1 != parts.size() && parts[i].width == w &&
            parts[i + 1].width == w && parts[i].source == parts[i + 1].source &&
            parts[i + 1].unit == parts[i].unit + w &&
            parts[i].unit % (2 * w) == 0 && dst % (2 * w) == 0) {
          merged.push_back({parts[i].source, parts[i].unit, 2 * w});
          dst += 2 * w;
          i += 2;
        } else {
          merged.push_back(parts[i]);
          dst += parts[i].width;
          ++i;
        }
      }
      parts = merged;
    };
    mergePass(1);
    mergePass(2);
    if (parts.size() == 1) {
      const Part &p = parts.front();
      Value whole = p.width == tupleWidth(p.source.getType()) && p.unit == 0
                        ? p.source
                        : laneOf(rewriter, loc, p.source, p.unit, p.width);
      rewriter.replaceOp(op, whole);
      return success();
    }
    SmallVector<Value> values;
    for (const Part &p : parts)
      values.push_back(copyOfUnits(rewriter, loc, p.source, p.unit, p.width,
                                   tupleWidth(p.source.getType())));
    rewriter.replaceOpWithNewOp<lvx::ConcatOp>(op, resTuple, values);
    return success();
  }
};

/// `vector.shape_cast` and `vector.bitcast` between 1-D vectors of the same
/// total width: the tuple does not change, and what the lanes are was never
/// in the type (lvx-mds/docs/MLIR-backend-design.md §8.7). Free.
template <typename SourceOp>
struct VectorReinterpretToLVX : public OpConversionPattern<SourceOp> {
  using OpConversionPattern<SourceOp>::OpConversionPattern;
  using OpAdaptor = typename OpConversionPattern<SourceOp>::OpAdaptor;
  LogicalResult
  matchAndRewrite(SourceOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    auto srcTy = dyn_cast<VectorType>(op.getSource().getType());
    auto resTy = dyn_cast<VectorType>(op.getType());
    if (!srcTy || !resTy || srcTy.getRank() != 1 || resTy.getRank() != 1)
      return rewriter.notifyMatchFailure(op, "not between 1-D vectors");
    const TypeConverter *tc = this->getTypeConverter();
    Type from = tc->convertType(srcTy), to = tc->convertType(resTy);
    if (!from || from != to)
      return rewriter.notifyMatchFailure(op, "not the same register tuple");
    rewriter.replaceOp(op, adaptor.getSource());
    return success();
  }
};

using VectorShapeCastToLVX = VectorReinterpretToLVX<vector::ShapeCastOp>;
using VectorBitCastToLVX = VectorReinterpretToLVX<vector::BitCastOp>;

//===----------------------------------------------------------------------===//
// Control flow: cf.br/cf.cond_br -> lvx_cf; scf.for/scf.yield -> lvx_scf.
//===----------------------------------------------------------------------===//

struct BrToLVX : public OpConversionPattern<cf::BranchOp> {
  using OpConversionPattern::OpConversionPattern;
  LogicalResult
  matchAndRewrite(cf::BranchOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    rewriter.replaceOpWithNewOp<lvx_cf::BranchOp>(op, op.getDest(),
                                                       adaptor.getDestOperands());
    return success();
  }
};

// The condition is a 0/1-valued register (from a compare or any other i1
// producer); fusing the originating compare's predicate directly into the
// branch's `bcucond` (avoiding this extra register test) is a follow-up
// optimization, not implemented in this phase.
struct CondBrToLVX : public OpConversionPattern<cf::CondBranchOp> {
  using OpConversionPattern::OpConversionPattern;
  LogicalResult
  matchAndRewrite(cf::CondBranchOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    rewriter.replaceOpWithNewOp<lvx_cf::CondBranchOp>(
        op, adaptor.getCondition(), BcuCond::wnez, op.getTrueDest(),
        adaptor.getTrueDestOperands(), op.getFalseDest(),
        adaptor.getFalseDestOperands());
    return success();
  }
};

struct ForToLVX : public OpConversionPattern<scf::ForOp> {
  using OpConversionPattern::OpConversionPattern;
  LogicalResult
  matchAndRewrite(scf::ForOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    // Every loop-carried value keeps its own converted type: a scalar is a
    // single, a vector<4xf32> accumulator a pair. The induction variable is
    // always a single.
    Type regTy = RegisterType::get(getContext(), std::nullopt);
    SmallVector<Type> resultTypes;
    for (Type t : op.getResultTypes()) {
      Type converted = getTypeConverter()->convertType(t);
      if (!converted)
        return rewriter.notifyMatchFailure(op, "loop-carried type has no register");
      resultTypes.push_back(converted);
    }
    auto newFor = rewriter.create<lvx_scf::ForOp>(
        op.getLoc(), resultTypes, adaptor.getLowerBound(),
        adaptor.getUpperBound(), adaptor.getStep(), adaptor.getInitArgs());

    Block *oldBody = op.getBody();
    SmallVector<Type> argTypes{regTy};
    argTypes.append(resultTypes);
    SmallVector<Location> argLocs(oldBody->getNumArguments(), op.getLoc());
    Block *newBody =
        rewriter.createBlock(&newFor.getRegion(), {}, argTypes, argLocs);
    rewriter.mergeBlocks(oldBody, newBody, newBody->getArguments());

    rewriter.replaceOp(op, newFor.getResults());
    return success();
  }
};

struct YieldToLVX : public OpConversionPattern<scf::YieldOp> {
  using OpConversionPattern::OpConversionPattern;
  LogicalResult
  matchAndRewrite(scf::YieldOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    rewriter.replaceOpWithNewOp<lvx_scf::YieldOp>(op, adaptor.getResults());
    return success();
  }
};

//===----------------------------------------------------------------------===//
// Functions: ABI-pin entry-block args/results per Convention.table, and
// copy pinned argument registers into fresh virtual registers on entry
// (mirrors the paper's `rv.mv` ABI copy-in pattern).
//===----------------------------------------------------------------------===//

struct FuncFuncToLVX : public OpConversionPattern<func::FuncOp> {
  using OpConversionPattern::OpConversionPattern;
  LogicalResult
  matchAndRewrite(func::FuncOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    MLIRContext *ctx = getContext();
    if (op.getNumArguments() > kMaxAbiArgRegs ||
        op.getNumResults() > kMaxAbiResultRegs)
      return rewriter.notifyMatchFailure(
          op, "function signature exceeds the regular calling convention's "
              "register capacity");

    SmallVector<Type> pinnedArgTypes;
    for (unsigned i = 0; i < op.getNumArguments(); ++i)
      pinnedArgTypes.push_back(RegisterType::get(ctx, abiArgReg(i)));
    SmallVector<Type> pinnedResultTypes;
    for (unsigned i = 0; i < op.getNumResults(); ++i)
      pinnedResultTypes.push_back(RegisterType::get(ctx, abiResultReg(i)));
    auto newFuncType =
        rewriter.getFunctionType(pinnedArgTypes, pinnedResultTypes);

    auto lvxFunc = rewriter.create<lvx_func::FuncOp>(
        op.getLoc(), op.getName(), newFuncType);
    if (auto vis = op.getSymVisibilityAttr())
      lvxFunc.setSymVisibilityAttr(vis);

    if (!op.isExternal()) {
      // First, generically convert every block's argument types in the
      // original region -- entry block included, but also any block only
      // reachable via cf.br/cf.cond_br -- via the installed type converter
      // (e.g. i64/index/memref -> plain virtual `!lvx.reg`).
      if (failed(rewriter.convertRegionTypes(&op.getBody(), *getTypeConverter())))
        return failure();

      // Prepend a fresh ABI entry block with pinned argument registers,
      // each immediately copied into a virtual register via `lvx.mv`, then
      // move the (now uniformly-converted) original region right after it
      // and branch into its entry block. Because that entry block's
      // arguments were just converted to plain `!lvx.reg` above, they
      // match the `lvx.mv` results' type exactly, so no further remapping
      // is needed.
      Type virtualRegTy = RegisterType::get(ctx, std::nullopt);
      SmallVector<Location> argLocs(pinnedArgTypes.size(), op.getLoc());
      Block *abiEntry =
          rewriter.createBlock(&lvxFunc.getBody(), {}, pinnedArgTypes, argLocs);
      rewriter.setInsertionPointToStart(abiEntry);
      SmallVector<Value> mvArgs;
      for (BlockArgument pinned : abiEntry->getArguments())
        mvArgs.push_back(
            rewriter.create<lvx::MvOp>(op.getLoc(), virtualRegTy, pinned));

      rewriter.inlineRegionBefore(op.getBody(), lvxFunc.getBody(),
                                  lvxFunc.getBody().end());
      Block &convertedEntry = *std::next(lvxFunc.getBody().begin());

      rewriter.setInsertionPointToEnd(abiEntry);
      rewriter.create<lvx_cf::BranchOp>(op.getLoc(), &convertedEntry, mvArgs);
    }
    rewriter.eraseOp(op);
    return success();
  }
};

// Mirrors `ReturnToLVX`'s copy-in and `FuncFuncToLVX`'s copy-out patterns: the
// callee's ABI (like a function's own entry/exit) is expressed as pinned
// physical registers, so a call's operands must be `mv`'d into the ABI
// argument registers ($r0-$r11) immediately before the call, and its pinned
// results `mv`'d back out into fresh virtual registers immediately after --
// otherwise Step 1-3's general register-allocation scan is free to assign a
// call's operands/results to arbitrary registers that don't match what the
// callee actually expects/produces.
struct CallToLVX : public OpConversionPattern<func::CallOp> {
  using OpConversionPattern::OpConversionPattern;
  LogicalResult
  matchAndRewrite(func::CallOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    MLIRContext *ctx = getContext();
    Location loc = op.getLoc();
    if (adaptor.getOperands().size() > kMaxAbiArgRegs ||
        op.getNumResults() > kMaxAbiResultRegs)
      return rewriter.notifyMatchFailure(
          op, "call exceeds the regular calling convention's register "
              "capacity");

    SmallVector<Value> pinnedOperands;
    for (auto [idx, operand] : llvm::enumerate(adaptor.getOperands())) {
      Type pinnedTy = RegisterType::get(ctx, abiArgReg(idx));
      pinnedOperands.push_back(
          rewriter.create<lvx::MvOp>(loc, pinnedTy, operand));
    }
    SmallVector<Type> pinnedResultTypes;
    for (unsigned i = 0; i < op.getNumResults(); ++i)
      pinnedResultTypes.push_back(RegisterType::get(ctx, abiResultReg(i)));
    auto call = rewriter.create<lvx_func::CallOp>(
        loc, op.getCallee(), pinnedResultTypes, pinnedOperands);

    Type virtualRegTy = RegisterType::get(ctx, std::nullopt);
    SmallVector<Value> mvResults;
    for (Value result : call.getResults())
      mvResults.push_back(
          rewriter.create<lvx::MvOp>(loc, virtualRegTy, result));
    rewriter.replaceOp(op, mvResults);
    return success();
  }
};

// lvx_func.func's declared result types are pinned ABI registers (see
// FuncFuncToLVX); return operands must be explicitly `mv`'d into those same
// pinned registers to match.
struct ReturnToLVX : public OpConversionPattern<func::ReturnOp> {
  using OpConversionPattern::OpConversionPattern;
  LogicalResult
  matchAndRewrite(func::ReturnOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    MLIRContext *ctx = getContext();
    SmallVector<Value> pinnedOperands;
    for (auto [idx, operand] : llvm::enumerate(adaptor.getOperands())) {
      Type pinnedTy = RegisterType::get(ctx, abiResultReg(idx));
      pinnedOperands.push_back(
          rewriter.create<lvx::MvOp>(op.getLoc(), pinnedTy, operand));
    }
    rewriter.replaceOpWithNewOp<lvx_func::ReturnOp>(op, pinnedOperands);
    return success();
  }
};

//===----------------------------------------------------------------------===//
// Pass
//===----------------------------------------------------------------------===//

struct ConvertToLVXPass
    : public impl::ConvertToLVXPassBase<ConvertToLVXPass> {
  void runOnOperation() override {
    MLIRContext *ctx = &getContext();
    LVXTypeConverter typeConverter(ctx);
    RewritePatternSet patterns(ctx);
    populateConvertToLVXPatterns(typeConverter, patterns);

    ConversionTarget target(*ctx);
    target.addLegalDialect<lvx::LVXDialect, lvx_cf::LVXCFDialect,
                           lvx_scf::LVXSCFDialect, lvx_func::LVXFuncDialect>();
    target.addIllegalDialect<arith::ArithDialect, cf::ControlFlowDialect,
                             scf::SCFDialect, func::FuncDialect,
                             memref::MemRefDialect, index::IndexDialect,
                             vector::VectorDialect>();
    // Only math.fma is lowered; the rest of `math` (transcendentals etc.)
    // has no LVX opcode, so leave the dialect legal and mark just this op.
    target.addIllegalOp<math::CountLeadingZerosOp,
                        math::CountTrailingZerosOp, math::CtPopOp,
                        math::AbsIOp,
                        math::FmaOp, math::AbsFOp, math::SqrtOp,
                        math::RoundEvenOp, math::TruncOp, math::FloorOp,
                        math::CeilOp, math::RoundOp>();
    target.addLegalOp<ModuleOp>();

    if (failed(applyFullConversion(getOperation(), target,
                                   std::move(patterns))))
      signalPassFailure();
  }
};

} // namespace

void mlir::populateConvertToLVXPatterns(TypeConverter &typeConverter,
                                        RewritePatternSet &patterns) {
  MLIRContext *ctx = patterns.getContext();
  // clang-format off
  patterns.add<
    // Integer arithmetic
    AddIToLVX, SubIToLVX, MulIToLVX,
    DivSIToLVX, DivUIToLVX, RemSIToLVX, RemUIToLVX,
    // Bitwise / shift
    AndIToLVX, OrIToLVX, XOrIToLVX,
    ShLIToLVX, ShRSIToLVX, ShRUIToLVX,
    // Float arithmetic
    AddFToLVX, SubFToLVX, MulFToLVX, DivFToLVX, NegFToLVX,
    // Casts
    TruncIToLVX, ExtSIToLVX, ExtUIToLVX,
    SIToFPToLVX, UIToFPToLVX, FPToSIToLVX, FPToUIToLVX,
    TruncFToLVX, ExtFToLVX, BitcastToLVX,
    IndexCastToLVXPat, IndexCastUIToLVXPat,
    // Compare
    CmpIToLVX, CmpFToLVX,
    // Constant / select
    ConstantToLVX, IndexConstantToLVX, SelectToLVX,
    // Memory
    MemRefLoadToLVX, MemRefStoreToLVX, FmaToLVX,
    // Vectors
    VectorLoadToLVX, VectorStoreToLVX, VectorBroadcastToLVX, VectorFMAToLVX,
    VectorDeinterleaveToLVX, VectorInterleaveToLVX,
    VectorExtractToLVX, VectorInsertToLVX, VectorShuffleToLVX,
    VectorCmpIToLVX, VectorCmpFToLVX, VectorSelectToLVX,
    VectorSplatConstantToLVX,
    VectorConstantMaskToLVX, VectorCreateMaskToLVX, VectorReductionToLVX,
    VectorMaskedLoadToLVX, VectorMaskedStoreToLVX,
    // Elementwise arithmetic (Phase 1)
    VAddIToLVX, VSubIToLVX, VMulIToLVX,
    VMinSIToLVX, VMaxSIToLVX, VMinUIToLVX, VMaxUIToLVX,
    VAndIToLVX, VOrIToLVX, VXOrIToLVX,
    VShLIToLVX, VShRSIToLVX, VShRUIToLVX,
    VAbsIToLVX, VCtlzToLVX, VCttzToLVX, VCtpopToLVX,
    VAddFToLVX, VSubFToLVX, VMulFToLVX,
    VMinimumFToLVX, VMaximumFToLVX, VMinNumFToLVX, VMaxNumFToLVX,
    VCopySignToLVX, VNegFToLVX, VAbsFToLVX,
    VectorShapeCastToLVX, VectorBitCastToLVX,
    MinimumFToLVX, MaximumFToLVX, MinNumFToLVX, MaxNumFToLVX,
    AbsFToLVX, CtlzToLVX, CttzToLVX, CtpopToLVX, AbsIToLVX,
    SqrtToLVX, RoundEvenToLVX, MathTruncToLVX, FloorToLVX,
    CeilToLVX, RoundToLVX,
    // Control flow
    BrToLVX, CondBrToLVX, ForToLVX, YieldToLVX,
    // Functions
    FuncFuncToLVX, CallToLVX, ReturnToLVX
  >(typeConverter, ctx);
  // clang-format on
}
