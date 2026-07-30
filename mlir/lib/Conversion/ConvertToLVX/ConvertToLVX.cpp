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
#include "mlir/Dialect/LVXCF/IR/LVXCF.h"
#include "mlir/Dialect/LVXFunc/IR/LVXFunc.h"
#include "mlir/Dialect/LVXSCF/IR/LVXSCF.h"
#include "mlir/Dialect/MemRef/IR/MemRef.h"
#include "mlir/Dialect/SCF/IR/SCF.h"
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

// Per lvx_Convention.yml's `regular` calling convention.
static constexpr unsigned kMaxAbiArgRegs = 12;
static constexpr unsigned kMaxAbiResultRegs = 4;

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
    return rewriter.create<WOp>(loc, regTy, lhs, rhs, FloatMode::cs);
  return rewriter.create<DOp>(loc, regTy, lhs, rhs, FloatMode::cs);
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
using OrIToLVX  = IntBinaryToLVX<arith::OrIOp,  lvx::IorddOp, lvx::IorwOp>;
using XOrIToLVX = IntBinaryToLVX<arith::XOrIOp, lvx::EorddOp, lvx::EorwOp>;
using ShLIToLVX  = IntBinaryToLVX<arith::ShLIOp,  lvx::SlldOp, lvx::SllwOp>;
using ShRSIToLVX = IntBinaryToLVX<arith::ShRSIOp, lvx::SradOp, lvx::SrawOp>;
using ShRUIToLVX = IntBinaryToLVX<arith::ShRUIOp, lvx::SrldOp, lvx::SrlwOp>;

// Signed/unsigned divide and remainder: LVX only offers a fused divide-modulo
// instruction, so each of {div,rem}{s,u}i independently emits its own
// `divmod{d,w}{,u}` and picks the quotient or remainder result. This
// duplicates the divmod computation when a kernel needs both quotient and
// remainder from the same operands; a future CSE pass can merge them.
template <typename SourceOp, typename DOp, typename WOp, unsigned ResultIdx>
struct DivModToLVX : public OpConversionPattern<SourceOp> {
  using OpConversionPattern<SourceOp>::OpConversionPattern;
  using OpAdaptor = typename OpConversionPattern<SourceOp>::OpAdaptor;
  LogicalResult
  matchAndRewrite(SourceOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    Type regTy = this->getTypeConverter()->convertType(op.getType());
    unsigned width = getScalarBitWidth(op.getType());
    Operation *divmod;
    if (width <= 32)
      divmod = rewriter.create<WOp>(op.getLoc(), TypeRange{regTy, regTy},
                                    adaptor.getLhs(), adaptor.getRhs());
    else
      divmod = rewriter.create<DOp>(op.getLoc(), TypeRange{regTy, regTy},
                                    adaptor.getLhs(), adaptor.getRhs());
    rewriter.replaceOp(op, divmod->getResult(ResultIdx));
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

// arith.negf has no direct LVX opcode; lower to `0.0 - operand`.
struct NegFToLVX : public OpConversionPattern<arith::NegFOp> {
  using OpConversionPattern::OpConversionPattern;
  LogicalResult
  matchAndRewrite(arith::NegFOp op, OpAdaptor adaptor,
                  ConversionPatternRewriter &rewriter) const override {
    Type regTy = getTypeConverter()->convertType(op.getType());
    unsigned width = getScalarBitWidth(op.getType());
    auto zeroAttr = rewriter.getFloatAttr(op.getType(), 0.0);
    Value zero = rewriter.create<lvx::LiOp>(op.getLoc(), regTy, zeroAttr);
    Value result = createFloatBinary<lvx::FsbfdOp, lvx::FsbfwOp>(
        rewriter, op.getLoc(), width, regTy, zero, adaptor.getOperand());
    rewriter.replaceOp(op, result);
    return success();
  }
};

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
// (one/ueq/oeq/une/olt/uge/oge/ult, per lvx_Modifier.yml). The remaining
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
    auto zeroOffset = rewriter.getSI32IntegerAttr(0);
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
    auto zeroOffset = rewriter.getSI32IntegerAttr(0);
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
    Type regTy = RegisterType::get(getContext(), std::nullopt);
    SmallVector<Type> resultTypes(op.getNumResults(), regTy);
    auto newFor = rewriter.create<lvx_scf::ForOp>(
        op.getLoc(), resultTypes, adaptor.getLowerBound(),
        adaptor.getUpperBound(), adaptor.getStep(), adaptor.getInitArgs());

    Block *oldBody = op.getBody();
    SmallVector<Type> argTypes(oldBody->getNumArguments(), regTy);
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
// Functions: ABI-pin entry-block args/results per lvx_Convention.yml, and
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
      pinnedArgTypes.push_back(
          RegisterType::get(ctx, static_cast<Register>(i)));
    SmallVector<Type> pinnedResultTypes;
    for (unsigned i = 0; i < op.getNumResults(); ++i)
      pinnedResultTypes.push_back(
          RegisterType::get(ctx, static_cast<Register>(i)));
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
      Type pinnedTy = RegisterType::get(ctx, static_cast<Register>(idx));
      pinnedOperands.push_back(
          rewriter.create<lvx::MvOp>(loc, pinnedTy, operand));
    }
    SmallVector<Type> pinnedResultTypes;
    for (unsigned i = 0; i < op.getNumResults(); ++i)
      pinnedResultTypes.push_back(
          RegisterType::get(ctx, static_cast<Register>(i)));
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
      Type pinnedTy = RegisterType::get(ctx, static_cast<Register>(idx));
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
                             memref::MemRefDialect, index::IndexDialect>();
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
    MemRefLoadToLVX, MemRefStoreToLVX,
    // Control flow
    BrToLVX, CondBrToLVX, ForToLVX, YieldToLVX,
    // Functions
    FuncFuncToLVX, CallToLVX, ReturnToLVX
  >(typeConverter, ctx);
  // clang-format on
}
