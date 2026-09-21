//===- LowerVectorTransfers.cpp - vector.transfer_* -> load/store/bcast --===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// The vectorization stage of lvx-mlir is upstream's affine super-vectorizer;
// this pass is the glue that brings its output into the vector subset
// `-convert-to-lvx` lowers (`vector.load`/`store`/`broadcast`/`fma`). Both
// halves are upstream utilities that only exist behind the transform dialect
// (`transform.structured.hoist_redundant_vector_transfers`,
// `transform.apply_patterns.vector.lower_transfer`); a pass is what the
// one-invocation-per-stage build script wants, and what a lit test can name.
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/LVX/Transforms/Passes.h"

#include "mlir/Dialect/Linalg/Transforms/Hoisting.h"
#include "mlir/Dialect/Vector/Transforms/LoweringPatterns.h"
#include "mlir/Transforms/GreedyPatternRewriteDriver.h"

namespace mlir {
namespace lvx {
#define GEN_PASS_DEF_LVXLOWERVECTORTRANSFERSPASS
#include "mlir/Dialect/LVX/Transforms/Passes.h.inc"
} // namespace lvx
} // namespace mlir

using namespace mlir;

namespace {

/// `vector.load %m[...] : vector<T>` (0-d, what a transfer_read of a scalar
/// broadcast operand reduces to) -> `memref.load` + `vector.broadcast` to
/// the 0-d vector. Upstream only lowers a 0-d transfer_read that feeds a
/// `vector.extract`; ours feeds a `vector.broadcast`, and the broadcast of
/// this broadcast folds into one (`BroadcastFolder`), leaving the scalar
/// load and the wide broadcast `-convert-to-lvx` turns into `ld`+`splatwq`.
struct ZeroDimLoadToScalar : public OpRewritePattern<vector::LoadOp> {
  using OpRewritePattern::OpRewritePattern;
  LogicalResult matchAndRewrite(vector::LoadOp op,
                                PatternRewriter &rewriter) const override {
    VectorType vecTy = op.getVectorType();
    if (vecTy.getRank() != 0)
      return failure();
    Value scalar = rewriter.create<memref::LoadOp>(
        op.getLoc(), op.getBase(), op.getIndices(), op.getNontemporal());
    rewriter.replaceOpWithNewOp<vector::BroadcastOp>(op, vecTy, scalar);
    return success();
  }
};

struct LVXLowerVectorTransfersPass
    : public lvx::impl::LVXLowerVectorTransfersPassBase<
          LVXLowerVectorTransfersPass> {
  void runOnOperation() override {
    func::FuncOp func = getOperation();

    // 1. The accumulator: a transfer_read/transfer_write pair on the same
    // loop-invariant address becomes an scf.for iter_arg. Before the
    // transfers are lowered, because the hoister only knows transfers.
    linalg::hoistRedundantVectorTransfers(func);

    // 2. What remains are per-iteration transfers. Three pattern sets, by
    // benefit: strip broadcast dimensions off the permutation map first
    // (a rank-reduced transfer plus vector.broadcast), lower a 0-d read
    // that feeds an extract to a scalar memref.load, and lower the
    // in-bounds identity transfers that are left into vector.load/store;
    // then the 0-d vector.load that leaves behind, and the broadcast chain.
    RewritePatternSet patterns(&getContext());
    vector::populateVectorTransferPermutationMapLoweringPatterns(patterns,
                                                                 /*benefit=*/3);
    vector::populateScalarVectorTransferLoweringPatterns(
        patterns, /*benefit=*/2, /*allowMultipleUses=*/true);
    vector::populateVectorTransferLoweringPatterns(patterns,
                                                   /*maxTransferRank=*/1);
    patterns.add<ZeroDimLoadToScalar>(&getContext());
    vector::BroadcastOp::getCanonicalizationPatterns(patterns, &getContext());
    if (failed(applyPatternsGreedily(func, std::move(patterns))))
      signalPassFailure();
  }
};

} // namespace
