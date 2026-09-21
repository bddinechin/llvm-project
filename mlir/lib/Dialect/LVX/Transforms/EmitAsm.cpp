//===- EmitAsm.cpp - Emit real LVX assembly text -------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// See lvx-mlir/docs/AssemblyEmission.md for the syntax reference (confirmed by
// hand-assembling representative snippets with the real `lvx-mbr-as`, not
// just inferred from reading tables) and the scope decisions below.
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/LVX/Transforms/Passes.h"
#include "mlir/Dialect/LVX/IR/LVXComposites.h"
#include "mlir/Dialect/LVX/IR/LVXTiedOperands.h"
#include "mlir/Dialect/LVX/IR/RegisterUnits.h"

#include "mlir/Dialect/LVXCF/IR/LVXCF.h"
#include "mlir/Dialect/LVXFunc/IR/LVXFunc.h"
#include "llvm/ADT/TypeSwitch.h"
#include "llvm/Support/raw_ostream.h"

namespace mlir {
namespace lvx {
#define GEN_PASS_DEF_LVXEMITASMPASS
#include "mlir/Dialect/LVX/Transforms/Passes.h.inc"
} // namespace lvx
} // namespace mlir

using namespace mlir;
using namespace mlir::lvx;

namespace {

/// Real modifier text for `LVX_IntCompAttr`/`LVX_BcuCondAttr` cases omits
/// the leading dot (MLIR keyword syntax); real assembly concatenates it
/// directly onto the mnemonic (lvx-mlir/docs/AssemblyEmission.md, "modifier
/// suffixes").
static std::string dotted(StringRef modifier) { return ("." + modifier).str(); }

class AsmEmitter {
public:
  AsmEmitter(llvm::raw_ostream &os) : os(os) {}

  LogicalResult emitModule(ModuleOp module) {
    for (auto func : module.getOps<lvx_func::FuncOp>())
      if (failed(emitFunc(func)))
        return failure();
    return success();
  }

private:
  llvm::raw_ostream &os;

  /// While printing part k of a composite op (LVXComposites.h): every
  /// quad-typed value prints as its k-th pair, and only the last part ends
  /// the bundle -- the parts issue together, which is the point of them.
  std::optional<unsigned> compositePart;
  bool lastPart = true;
  /// Whether the op being printed is the last of its bundle -- the last op
  /// of its `cycle` (from -lvx-schedule); an op without the attribute is a
  /// bundle of its own. Only the last op of a bundle prints the `;;`, with
  /// the cycle it ends as a comment, the way lvx-gcc's output reads.
  bool endsBundle = true;
  std::optional<int64_t> cycle;
  std::string endOfOp() const {
    if (!(lastPart && endsBundle))
      return "\n";
    if (cycle)
      return ("\n\t;;\t# (end cycle " + Twine(*cycle) + ")\n").str();
    return "\n\t;;\n";
  }

  /// Whether `op` prints an instruction at all: the pseudos that only name a
  /// register print nothing, and a branch to the block that follows is a
  /// fall-through.
  static bool prints(Operation *op, Block *nextBlock) {
    if (isa<LaneOp, ConcatOp, SpOp, RegLiveInOp, RegLiveOutOp, lvx_cf::LoopendOp>(op))
      return false;
    if (auto br = dyn_cast<lvx_cf::BranchOp>(op))
      return br.getDest() != nextBlock;
    return true;
  }
  DenseMap<Block *, unsigned> blockIds;
  Block *entryBlock = nullptr;
  unsigned nextBlockId = 0;

  //===--------------------------------------------------------------------===//
  // Operand printing
  //===--------------------------------------------------------------------===//

  /// `v` must already be allocated (`!lvx.reg<rN>`, `!lvx.pair<rNrN+1>`,
  /// `!lvx.quad<...>`) -- true of every value reaching this pass, since it
  /// runs after `-lvx-allocate-registers`. A tuple prints as its primary
  /// name, `$r0r1`, never as a lane of something wider (design §8.8).
  FailureOr<std::string> reg(Value v) {
    std::optional<PhysLoc> loc = pinnedLoc(v.getType());
    if (!loc)
      return emitError(v.getLoc())
             << "value reaching lvx-emit-asm has no assigned physical "
                "register -- run -lvx-allocate-registers first";
    // A composite's part takes the k-th pair of each quad; a pair-typed
    // source is read whole by every part (a broadcast operand).
    if (compositePart && loc->width == 4)
      loc = PhysLoc{loc->base + 2 * *compositePart, 2};
    return ("$" + spellingOf(*loc)).str();
  }

  /// A lane of `v`'s register: the single at unit `index` of a pinned
  /// tuple. What `catdq $rM = $rZ, $rY` wants for a pair copy.
  FailureOr<std::string> lane(Value v, unsigned index) {
    std::optional<PhysLoc> loc = pinnedLoc(v.getType());
    if (!loc)
      return emitError(v.getLoc())
             << "value reaching lvx-emit-asm has no assigned physical "
                "register -- run -lvx-allocate-registers first";
    return ("$" + spellingOf({loc->base + index, 1})).str();
  }

  /// `lvx.mv` at every width: `copyd $rd = $rs`; `catdq $rd = $rs.lo,
  /// $rs.hi`, the ISA's pair copy taking two singles, spelled as the singles
  /// they are; `copyo $rd = $rs`.
  LogicalResult emitMv(MvOp mv) {
    switch (widthOf(mv.getResult().getType())) {
    case 1:
      return emitUnary(mv, "copyd");
    case 2: {
      FailureOr<std::string> rd = reg(mv.getResult());
      FailureOr<std::string> lo = lane(mv.getSource(), 0);
      FailureOr<std::string> hi = lane(mv.getSource(), 1);
      if (failed(rd) || failed(lo) || failed(hi))
        return failure();
      os << "\tcatdq " << *rd << " = " << *lo << ", " << *hi << endOfOp();
      return success();
    }
    case 4:
      return emitUnary(mv, "copyo");
    }
    llvm_unreachable("lvx.mv is 1, 2 or 4 units wide");
  }

  std::string label(Block *block) {
    if (block == entryBlock)
      return std::string(cast<lvx_func::FuncOp>(entryBlock->getParentOp())
                             .getSymName());
    auto it = blockIds.find(block);
    if (it == blockIds.end())
      it = blockIds.insert({block, nextBlockId++}).first;
    return (".LBB" + Twine(it->second)).str();
  }

  /// Real `goto`/`cb` have no mechanism to pass values into a target
  /// block's arguments -- physical registers stand in for that. This is
  /// only satisfiable if every branch operand is already, by construction,
  /// pinned to the exact same register as the block argument it feeds
  /// (true of everything `-lvx-scf-to-cf` generates -- see
  /// lvx-mlir/docs/AssemblyEmission.md). Verify it rather than silently
  /// dropping the (unrepresentable) move a real phi-merge would need --
  /// see lvx-mlir/docs/RegisterAllocation.md's "general lvx_cf block-argument
  /// merges" known limitation.
  LogicalResult checkBranchOperands(Operation *branch, Block *dest,
                                    ValueRange operands) {
    for (auto [arg, operand] : llvm::zip_equal(dest->getArguments(), operands))
      if (arg.getType() != operand.getType())
        return branch->emitError()
               << "branch operand register does not match destination "
                  "block argument's register -- would need a register "
                  "move this dialect has no representation for at this "
                  "pipeline stage";
    return success();
  }

  /// The widened-branch suffix: `x` on a control op means the wide encoding,
  /// whose mnemonic is the near one with an `x` appended -- `cb`/`cbx`,
  /// `ccb`/`ccbx`, `goto`/`gotox`, `call`/`callx`.
  ///
  /// This is the one place a `format` attribute reaches the printed mnemonic.
  /// On an arithmetic op it does not: all four `addd` encodings share one
  /// mnemonic and the assembler picks from the immediate's magnitude (O2).
  /// Branches are not relaxed -- `cb` to a far target is "branch out of
  /// range" from the real assembler -- so here the attribute decides what is
  /// printed. If the assembler grows automatic selection this rule is what
  /// goes away, and nothing else has to change.
  static std::string widened(StringRef mnemonic, std::optional<Format> format) {
    if (format == Format::x)
      return (mnemonic + "x").str();
    return mnemonic.str();
  }

  /// Prints `goto <label(dest)>` as its own bundle, *unless* `dest` is the
  /// block immediately following the current one in emission order, in
  /// which case nothing is printed at all (real assembly just falls
  /// through). Purely an optimization.
  ///
  /// It was not always: a hardware loop's body-to-exit edge used to be an
  /// ordinary `lvx_cf.br` that had to be elided here, since a real `goto`
  /// overrides LOOPDO's implicit back-edge and truncates the loop to one
  /// iteration. That made correctness depend on block layout order and on
  /// this function's behaviour. `lvx_cf.loopend` now carries that edge and
  /// emits a comment of its own, so nothing here is load-bearing.
  void printGoto(Block *dest, Block *nextBlock,
                 std::optional<Format> format = std::nullopt) {
    if (dest != nextBlock)
      os << "\t" << widened("goto", format) << " " << label(dest)
         << endOfOp();
  }

  //===--------------------------------------------------------------------===//
  // Per-op emission
  //===--------------------------------------------------------------------===//

  /// The real `signextw` modifier on 32-bit ALU ops: bare means zero-extend
  /// the 32-bit result into the 64-bit register, `.sx` means sign-extend.
  /// Carried as a unit attribute, so absent == the hardware default and the
  /// ordinary form prints exactly as it always did.
  static std::string withSx(Operation *op, StringRef mnemonic) {
    if (op->hasAttr("sx"))
      return (mnemonic + ".sx").str();
    return mnemonic.str();
  }

  LogicalResult emitBinary(Operation *op, StringRef mnemonic) {
    FailureOr<std::string> rd = reg(op->getResult(0));
    FailureOr<std::string> rs1 = reg(op->getOperand(0));
    FailureOr<std::string> rs2 = reg(op->getOperand(1));
    if (failed(rd) || failed(rs1) || failed(rs2))
      return failure();
    os << "\t" << withSx(op, mnemonic) << " " << *rd << " = " << *rs1 << ", "
       << *rs2 << endOfOp();
    return success();
  }

  /// `SBFD`/`SBFW`/`FSBFD`/`FSBFW` are real "subtract FROM" opcodes: per
  /// ground truth (lvx-mds Description.yml, "The %2 is subtracted from the
  /// %3"), `mnemonic $rd = $rs1, $rs2` computes `$rs2 - $rs1`, the reverse
  /// of every other binary op's `$rd = $rs1 op $rs2` reading -- confirmed
  /// both from the spec text and empirically on real gem5 (a naive
  /// `$rd = $rs1, $rs2` for `$rs1=5, $rs2=0` executes to -5, not 5).
  /// `SbfdOp`/`SbfwOp`/`FsbfdOp`/`FsbfwOp`'s own `$lhs`/`$rhs` IR operands
  /// keep the natural "result = lhs - rhs" meaning every caller already
  /// assumes (arith.subi lowering, i1 sign-extension, the hardware-loop
  /// trip-count computation in SCFToCF.cpp); this swaps the *printed*
  /// operand order so the natural IR semantics survive translation to the
  /// real "subtract from" encoding, rather than pushing the inversion onto
  /// every call site.
  LogicalResult emitBinarySubtractFrom(Operation *op, StringRef mnemonic) {
    FailureOr<std::string> rd = reg(op->getResult(0));
    FailureOr<std::string> rs1 = reg(op->getOperand(1));
    FailureOr<std::string> rs2 = reg(op->getOperand(0));
    if (failed(rd) || failed(rs1) || failed(rs2))
      return failure();
    os << "\t" << withSx(op, mnemonic) << " " << *rd << " = " << *rs1 << ", " << *rs2
       << endOfOp();
    return success();
  }

  LogicalResult emitTernary(Operation *op, StringRef mnemonic) {
    FailureOr<std::string> rd = reg(op->getResult(0));
    FailureOr<std::string> rs1 = reg(op->getOperand(0));
    FailureOr<std::string> rs2 = reg(op->getOperand(1));
    FailureOr<std::string> rs3 = reg(op->getOperand(2));
    if (failed(rd) || failed(rs1) || failed(rs2) || failed(rs3))
      return failure();
    os << "\t" << mnemonic << " " << *rd << " = " << *rs1 << ", " << *rs2
       << ", " << *rs3 << endOfOp();
    return success();
  }

  /// `FFMAD`/`FFMAW`/`FFMSD`/`FFMSW` (lvx-mds Opcode.table's
  /// `registerW_registerZ_registerY` shape) have only *two* explicit
  /// source registers -- the destination doubles as the third, implicit
  /// accumulate-into operand, so real syntax is `ffmad $rW = $rZ, $rY`,
  /// not a 4-register ternary. `-lvx-allocate-registers` coalesces this
  /// op's `c` operand with its own result to guarantee they land in the
  /// same physical register (lvx-mlir/docs/RegisterAllocation.md, "`ffma`/
  /// `ffms` accumulator coalescing"); this only re-checks that invariant
  /// rather than assuming it, so a mis-ordered pipeline (this pass run
  /// without register allocation's coalescing having applied) is caught as
  /// an error instead of emitting a real instruction with a silently wrong
  /// accumulator.
  /// How many trailing operands this op reads through its destination, and
  /// therefore must NOT print -- real hardware has one field for both. Checks
  /// that the allocator did give each tied pair the same register, since
  /// otherwise the instruction has no way to be printed at all.
  ///
  /// This replaced `emitFma`, which did the same for `ffma`/`ffms` alone with
  /// the tie hardcoded at operand 2. The table says which operands they are
  /// for all 129 ops that have one; see LVXTiedOperands.h.
  FailureOr<unsigned> tiedSuffix(Operation *op) {
    ArrayRef<TiedOperand> ties = tiedOperandsOf(op->getName().stripDialect());
    for (TiedOperand tie : ties) {
      FailureOr<std::string> rt = reg(op->getOperand(tie.operand));
      FailureOr<std::string> rd = reg(op->getResult(tie.result));
      if (failed(rt) || failed(rd))
        return failure();
      if (*rt != *rd)
        return op->emitError("lvx-emit-asm: ")
               << op->getName().stripDialect() << "'s tied operand #"
               << tie.operand << " is " << *rt << " but result #"
               << tie.result << " is " << *rd
               << " -- real hardware has no separate destination field, so "
                  "they must be the same register (run "
                  "-lvx-allocate-registers first)";
    }
    return static_cast<unsigned>(ties.size());
  }

  LogicalResult emitUnary(Operation *op, StringRef mnemonic) {
    FailureOr<std::string> rd = reg(op->getResult(0));
    FailureOr<std::string> rs = reg(op->getOperand(0));
    if (failed(rd) || failed(rs))
      return failure();
    os << "\t" << withSx(op, mnemonic) << " " << *rd << " = " << *rs
       << endOfOp();
    return success();
  }

  /// Unary op whose real encoding carries a `floatmode` modifier, printed
  /// as a suffix on the mnemonic. `cs` is the empty suffix -- "use the
  /// rounding mode currently in $cs" -- so `frintd` bare is rint, while
  /// `frintd.rd` is floor. Emitting these through the generic unary path
  /// would silently drop the mode and turn every floor into a rint.
  LogicalResult emitUnaryMode(Operation *op, StringRef mnemonic,
                              std::optional<FloatMode> mode) {
    FailureOr<std::string> rd = reg(op->getResult(0));
    FailureOr<std::string> rs = reg(op->getOperand(0));
    if (failed(rd) || failed(rs))
      return failure();
    os << "\t" << mnemonic;
    // Absent means the CS rounding mode, whose real suffix is empty -- so
    // there is nothing to print. See LVXBase.td on why `cs` is not a member.
    if (mode)
      os << dotted(stringifyFloatMode(*mode));
    os << " " << *rd << " = " << *rs << endOfOp();
    return success();
  }

  LogicalResult emitCompare(Operation *op, StringRef mnemonic,
                            StringRef predicate) {
    FailureOr<std::string> rd = reg(op->getResult(0));
    FailureOr<std::string> rs1 = reg(op->getOperand(0));
    FailureOr<std::string> rs2 = reg(op->getOperand(1));
    if (failed(rd) || failed(rs1) || failed(rs2))
      return failure();
    os << "\t" << mnemonic << dotted(predicate) << " " << *rd << " = "
       << *rs1 << ", " << *rs2 << endOfOp();
    return success();
  }

  /// The generated memory ops carry their displacement as a
  /// `TypedAttrInterface` -- the shape every generated immediate has, since
  /// MDS states an immediate's width, not an MLIR attribute kind -- where
  /// the hand-written ones used an `SI32Attr` and handed out a plain
  /// `int32_t`. The assembler wants an integer, so unwrap it here rather
  /// than at each of the eleven call sites, and reject anything else loudly:
  /// a symbol-reference displacement is legal in the ISA and this pass has
  /// no encoding for it yet.
  FailureOr<int64_t> displacement(Operation *op, TypedAttr offset) {
    auto intAttr = dyn_cast_or_null<IntegerAttr>(offset);
    if (!intAttr)
      return op->emitError(
          "lvx-emit-asm: memory displacement is not an integer attribute");
    return intAttr.getValue().getSExtValue();
  }

  /// The real `variant` modifier on a load: bare, `.s` (speculative), `.u`
  /// (uncached) or `.us`. Absent is the hardware default and prints as the
  /// plain mnemonic, exactly as `withSx` handles `signextw`.
  static std::string withVariant(std::optional<Variant> variant,
                                 StringRef mnemonic) {
    if (!variant)
      return mnemonic.str();
    return (mnemonic + "." + stringifyVariant(*variant)).str();
  }

  LogicalResult emitLoad(Operation *op, StringRef mnemonic, Value base,
                        TypedAttr offset, std::optional<Variant> variant) {
    FailureOr<std::string> rd = reg(op->getResult(0));
    FailureOr<std::string> rb = reg(base);
    FailureOr<int64_t> disp = displacement(op, offset);
    if (failed(rd) || failed(rb) || failed(disp))
      return failure();
    os << "\t" << withVariant(variant, mnemonic) << " " << *rd << " = " << *disp
       << "[" << *rb << "]" << endOfOp();
    return success();
  }

  LogicalResult emitStore(Operation *op, StringRef mnemonic, Value value,
                         Value base, TypedAttr offset) {
    FailureOr<std::string> rv = reg(value);
    FailureOr<std::string> rb = reg(base);
    FailureOr<int64_t> disp = displacement(op, offset);
    if (failed(rv) || failed(rb) || failed(disp))
      return failure();
    os << "\t" << mnemonic << " " << *disp << "[" << *rb << "] = " << *rv
       << endOfOp();
    return success();
  }

  /// `cmoved.cond $rZ? $rW = $rY` -- a predicated in-place move: when the
  /// guard holds, the destination takes `$rY`; otherwise it keeps what it
  /// had. The dialect models that as a 3-operand select, which is what SSA
  /// requires, so the "keep what it had" operand (#2, `falseValue`) must
  /// already share the result's register. `hasTiedAccumulator` in
  /// RegisterAllocation.cpp guarantees it, the same way it does for ffma's
  /// accumulator; assert rather than silently emit a wrong register.
  LogicalResult emitCmove(Operation *op, StringRef mnemonic) {
    auto cond = op->getAttrOfType<BcuCondAttr>("cmovecond");
    if (!cond)
      cond = op->getAttrOfType<BcuCondAttr>("condition");
    if (!cond)
      return op->emitError("lvx-emit-asm: cmove without a condition attribute");

    FailureOr<std::string> rd = reg(op->getResult(0));
    FailureOr<std::string> guard = reg(op->getOperand(0));
    FailureOr<std::string> ry = reg(op->getOperand(1));
    FailureOr<std::string> tied = reg(op->getOperand(2));
    if (failed(rd) || failed(guard) || failed(ry) || failed(tied))
      return failure();
    if (*rd != *tied)
      return op->emitError("lvx-emit-asm: cmove's false-case operand (")
             << *tied << ") must share the result's register (" << *rd
             << ") -- register allocation should have coalesced them";

    os << "\t" << mnemonic << "." << stringifyBcuCond(cond.getValue()) << " "
       << *guard << "? " << *rd << " = " << *ry << endOfOp();
    return success();
  }

  LogicalResult emitOp(Operation *op) {
    return llvm::TypeSwitch<Operation *, LogicalResult>(op)
        // Pseudo-ops.
        .Case([&](SpOp) { return success(); }) // never emitted; see doc.
        // Like SpOp: only names an already-live physical register so an
        // ordinary lvx.sd can store it. No instruction of its own.
        .Case([&](RegLiveInOp) { return success(); })
        // Likewise: only states that a register is live out. See its
        // description for why the restore before it needs saying so.
        .Case([&](RegLiveOutOp) { return success(); })
        .Case([&](LiOp li) {
          FailureOr<std::string> rd = reg(li.getResult());
          if (failed(rd))
            return failure();
          Attribute value = li.getValue();
          if (auto intAttr = dyn_cast<IntegerAttr>(value))
            os << "\tmaked " << *rd << " = " << intAttr.getValue() << endOfOp();
          else
            os << "\tmaked " << *rd << " = "
               << cast<FloatAttr>(value).getValue().bitcastToAPInt()
               << endOfOp();
          return success();
        })
        .Case([&](MvOp mv) { return emitMv(mv); })
        // A lane of a pinned tuple is a register, not an instruction: the
        // allocator typed the result as that register (lvx-mlir/docs/
        // RegisterAllocation.md, "Lane views"), and there is nothing to emit.
        .Case([&](LaneOp) { return success(); })
        .Case([&](ConcatOp) { return success(); })
        // $ra save/restore (lvx-mlir/docs/RegisterAllocation.md, "Return-
        // address save/restore"): real `get`/`set` on the RA system
        // register, confirmed via the real lvx-mbr-as/lvx-mbr-objdump.
        // `lvx.get`/`lvx.set` need no case of their own: both are one
        // result and one operand, so the arity dispatch below prints
        // `get $rN = $ra` and `set $ra = $rN` from the operand types. They
        // replaced the hand-written `lvx.getra`/`lvx.setra` pseudos, which
        // existed only because `!lvx.reg` could not name $ra (O5).
        // Memory.
        .Case([&](LbzOp op) { return emitLoad(op, "lbz", op.getBase(), op.getOffset(), op.getVariant()); })
        .Case([&](LbsOp op) { return emitLoad(op, "lbs", op.getBase(), op.getOffset(), op.getVariant()); })
        .Case([&](LhzOp op) { return emitLoad(op, "lhz", op.getBase(), op.getOffset(), op.getVariant()); })
        .Case([&](LhsOp op) { return emitLoad(op, "lhs", op.getBase(), op.getOffset(), op.getVariant()); })
        .Case([&](LwzOp op) { return emitLoad(op, "lwz", op.getBase(), op.getOffset(), op.getVariant()); })
        .Case([&](LwsOp op) { return emitLoad(op, "lws", op.getBase(), op.getOffset(), op.getVariant()); })
        .Case([&](LdOp op) { return emitLoad(op, "ld", op.getBase(), op.getOffset(), op.getVariant()); })
        .Case([&](LqOp op) { return emitLoad(op, "lq", op.getBase(), op.getOffset(), op.getVariant()); })
        .Case([&](LoOp op) { return emitLoad(op, "lo", op.getBase(), op.getOffset(), op.getVariant()); })
        .Case([&](LbsoOp op) { return emitLoad(op, "lbso", op.getBase(), op.getOffset(), op.getVariant()); })
        .Case([&](LhsoOp op) { return emitLoad(op, "lhso", op.getBase(), op.getOffset(), op.getVariant()); })
        .Case([&](LwsoOp op) { return emitLoad(op, "lwso", op.getBase(), op.getOffset(), op.getVariant()); })
        .Case([&](LdsoOp op) { return emitLoad(op, "ldso", op.getBase(), op.getOffset(), op.getVariant()); })
        .Case([&](SbOp op) { return emitStore(op, "sb", op.getValue(), op.getBase(), op.getOffset()); })
        .Case([&](ShOp op) { return emitStore(op, "sh", op.getValue(), op.getBase(), op.getOffset()); })
        .Case([&](SwOp op) { return emitStore(op, "sw", op.getValue(), op.getBase(), op.getOffset()); })
        .Case([&](SdOp op) { return emitStore(op, "sd", op.getValue(), op.getBase(), op.getOffset()); })
        .Case([&](SqOp op) { return emitStore(op, "sq", op.getValue(), op.getBase(), op.getOffset()); })
        .Case([&](SoOp op) { return emitStore(op, "so", op.getValue(), op.getBase(), op.getOffset()); })
        // Unary float ops carrying a rounding-mode suffix.
        .Case([&](FsqrtdOp op) { return emitUnaryMode(op, "fsqrtd", op.getFloatmode()); })
        .Case([&](FsqrtwOp op) { return emitUnaryMode(op, "fsqrtw", op.getFloatmode()); })
        .Case([&](FrintdOp op) { return emitUnaryMode(op, "frintd", op.getFloatmode()); })
        .Case([&](FrintwOp op) { return emitUnaryMode(op, "frintw", op.getFloatmode()); })
        // Comparisons (dotted predicate).
        // All four comparisons are generated now and name the attribute
        // after the MDS modifier -- `intcomp` for the integer pair,
        // `floatcomp` for the float pair.
        .Case([&](CompdOp op) { return emitCompare(op, "compd", stringifyIntComp(op.getIntcomp())); })
        .Case([&](CompwOp op) { return emitCompare(op, "compw", stringifyIntComp(op.getIntcomp())); })
        .Case([&](FcompdOp op) { return emitCompare(op, "fcompd", stringifyFloatComp(op.getFloatcomp())); })
        .Case([&](FcompwOp op) { return emitCompare(op, "fcompw", stringifyFloatComp(op.getFloatcomp())); })
        // "Subtract FROM" opcodes: real hardware's operand order is the
        // reverse of this dialect's `$lhs, $rhs` -- see
        // emitBinarySubtractFrom's comment.
        .Case([&](Addx2dOp op) { return emitBinary(op, "addx2d"); })
        .Case([&](Addx2wOp op) { return emitBinary(op, "addx2w"); })
        .Case([&](Addx4dOp op) { return emitBinary(op, "addx4d"); })
        .Case([&](Addx4wOp op) { return emitBinary(op, "addx4w"); })
        .Case([&](Addx8dOp op) { return emitBinary(op, "addx8d"); })
        .Case([&](Addx8wOp op) { return emitBinary(op, "addx8w"); })
        .Case([&](Addx16dOp op) { return emitBinary(op, "addx16d"); })
        .Case([&](Addx16wOp op) { return emitBinary(op, "addx16w"); })
        .Case([&](Addx32dOp op) { return emitBinary(op, "addx32d"); })
        .Case([&](Addx32wOp op) { return emitBinary(op, "addx32w"); })
        .Case([&](Addx64dOp op) { return emitBinary(op, "addx64d"); })
        .Case([&](Addx64wOp op) { return emitBinary(op, "addx64w"); })
        .Case([&](SbfdOp op) { return emitBinarySubtractFrom(op, "sbfd"); })
        .Case([&](SbfwOp op) { return emitBinarySubtractFrom(op, "sbfw"); })
        .Case([&](FsbfdOp op) { return emitBinarySubtractFrom(op, "fsbfd"); })
        .Case([&](FsbfwOp op) { return emitBinarySubtractFrom(op, "fsbfw"); })
        // Predicated in-place move: operand #2 is tied to the result, see
        // emitCmove's comment.
        .Case([&](CmovedOp op) { return emitCmove(op, "cmoved"); })
        // divmod needs no case: its result is one `!lvx.pair`, printed as
        // `$r<even>r<odd>` by the binary rule like any pair-writing op.
        // ffma/ffms and the 125 other ops with a tied operand need no case:
        // the arity dispatch below drops the tied suffix, see tiedSuffix.
        // `lvx_func.call` is not a terminator -- a real `call` returns
        // control to the very next instruction, so it can (and typically
        // does) sit mid-block, unlike `lvx_cf.br`/`lvx_func.return`. It
        // therefore never reaches `emitTerminator`'s dispatch and must be
        // handled here instead; its own operands/results are pinned to the
        // ABI's argument/result registers by `-convert-to-lvx`'s
        // `CallToLVX`, so nothing but the callee symbol needs printing.
        .Case([&](lvx_func::CallOp op) {
          os << "\t" << widened("call", op.getFormat()) << " "
             << op.getCallee() << endOfOp();
          return success();
        })
        // Everything else with plain (unattributed) register
        // operands/results is dispatched purely by arity: this dialect's
        // mnemonics match real LVX mnemonics verbatim (top-level
        // CLAUDE.md), and the "$rd = $rs..." shape is uniform across the
        // arithmetic/cast op families (lvx-mlir/docs/AssemblyEmission.md).
        .Default([&](Operation *op) -> LogicalResult {
          StringRef mnemonic = op->getName().stripDialect();
          // A composite op (Builtin@split): its part's instruction once per
          // pair of the quad, in one bundle. Each part is printed by the
          // same arity rule as the instruction itself, with `reg` folding
          // the quads down to the part's pair.
          if (std::optional<Composite> composite = compositeOf(mnemonic)) {
            for (unsigned k = 0; k != composite->parts; ++k) {
              compositePart = k;
              lastPart = k + 1 == composite->parts;
              LogicalResult r = emitByArity(op, composite->part);
              compositePart = std::nullopt;
              lastPart = true;
              if (failed(r))
                return failure();
            }
            return success();
          }
          return emitByArity(op, mnemonic);
        });
  }

  /// The arity rule: this dialect's mnemonics match real LVX mnemonics
  /// verbatim (top-level CLAUDE.md), and the "$rd = $rs..." shape is uniform
  /// across the arithmetic/cast op families (lvx-mlir/docs/AssemblyEmission.md).
  LogicalResult emitByArity(Operation *op, StringRef mnemonic) {
    // A tied operand is read through the destination and has no field of
    // its own, so it is not part of the printed shape.
    FailureOr<unsigned> tied = tiedSuffix(op);
    if (failed(tied))
      return failure();
    unsigned printed = op->getNumOperands() - *tied;
    if (op->getNumResults() == 1 && printed == 1)
      return emitUnary(op, mnemonic);
    if (op->getNumResults() == 1 && printed == 2)
      return emitBinary(op, mnemonic);
    if (op->getNumResults() == 1 && printed == 3)
      return emitTernary(op, mnemonic);
    return op->emitError("lvx-emit-asm: no emission rule for this op's shape");
  }

  //===--------------------------------------------------------------------===//
  // Control flow and structure
  //===--------------------------------------------------------------------===//

  LogicalResult emitTerminator(Operation *op, Block *nextBlock) {
    // A hardware loop's body-to-exit edge. Real, and checked like any other
    // branch, but emitted as a comment only: LOOPDO's back-edge is implicit
    // in hardware, so a `goto` here would override it and run the body once.
    // See lvx-mlir/docs/HardwareLoops.md.
    if (auto loopend = dyn_cast<lvx_cf::LoopendOp>(op)) {
      if (failed(checkBranchOperands(op, loopend.getDest(),
                                     loopend.getDestOperands())))
        return failure();
      os << "\t# end of hardware loop body -- LOOPDO back-edge is implicit\n";
      return success();
    }

    if (auto br = dyn_cast<lvx_cf::BranchOp>(op)) {
      if (failed(checkBranchOperands(op, br.getDest(), br.getDestOperands())))
        return failure();
      printGoto(br.getDest(), nextBlock, br.getFormat());
      return success();
    }
    if (auto cbr = dyn_cast<lvx_cf::CondBranchOp>(op)) {
      if (failed(checkBranchOperands(op, cbr.getTrueDest(), cbr.getTrueDestOperands())) ||
          failed(checkBranchOperands(op, cbr.getFalseDest(), cbr.getFalseDestOperands())))
        return failure();
      FailureOr<std::string> rt = reg(cbr.getTest());
      if (failed(rt))
        return failure();
      // Real hardware branches on the condition being true; the false
      // edge just falls through to whatever comes textually next.
      os << "\t" << widened("cb", cbr.getFormat())
         << dotted(stringifyBcuCond(cbr.getCondition())) << " "
         << *rt << "? " << label(cbr.getTrueDest()) << endOfOp();
      // The fall-through edge is a goto with no op of its own, so there is
      // no attribute to widen it with -- see LVXCF_CondBranchOp's `format`.
      printGoto(cbr.getFalseDest(), nextBlock);
      return success();
    }
    if (auto loopdo = dyn_cast<lvx_cf::LoopdoOp>(op)) {
      if (failed(checkBranchOperands(op, loopdo.getBody(), loopdo.getBodyOperands())) ||
          failed(checkBranchOperands(op, loopdo.getExit(), loopdo.getExitOperands())))
        return failure();
      FailureOr<std::string> rt = reg(loopdo.getTripCount());
      if (failed(rt))
        return failure();
      // `body` is never printed as a jump target: real LOOPDO falls
      // through to it unconditionally (the lowering guarantees `body`
      // immediately follows in block order -- see
      // lvx-mlir/docs/HardwareLoops.md). Only `exit` is a real operand, the
      // branch target encoded in the instruction itself.
      os << "\tloopdo " << *rt << ", " << label(loopdo.getExit()) << endOfOp();
      if (loopdo.getBody() != nextBlock)
        return loopdo.emitError(
            "lvx-emit-asm: lvx_cf.loopdo's body successor must be the "
            "block immediately following it in emission order");
      return success();
    }
    if (isa<lvx_func::ReturnOp>(op)) {
      os << "\tret" << endOfOp();
      return success();
    }
    return op->emitError("lvx-emit-asm: unsupported terminator");
  }

  LogicalResult emitBlock(Block *block, Block *nextBlock) {
    if (block != entryBlock)
      os << label(block) << ":\n";
    // The cycle of each op, from -lvx-schedule; an unscheduled op is alone
    // in a bundle of its own. A bundle is the ops of one cycle, and its last
    // PRINTING op ends it, since the ones that print nothing cannot.
    auto cycleOf = [](Operation *op) -> std::optional<int64_t> {
      if (auto c = op->getAttrOfType<IntegerAttr>("cycle"))
        return c.getInt();
      return std::nullopt;
    };
    for (Operation &op : *block) {
      cycle = cycleOf(&op);
      endsBundle = true;
      if (cycle)
        for (Operation *later = op.getNextNode(); later;
             later = later->getNextNode()) {
          if (cycleOf(later) != cycle)
            break;
          if (prints(later, nextBlock)) {
            endsBundle = false;
            break;
          }
        }
      LogicalResult r = op.hasTrait<OpTrait::IsTerminator>()
                            ? emitTerminator(&op, nextBlock)
                            : emitOp(&op);
      endsBundle = true;
      cycle = std::nullopt;
      if (failed(r))
        return failure();
    }
    return success();
  }

  LogicalResult emitFunc(lvx_func::FuncOp func) {
    if (func.isExternal())
      return success();
    if (!func.getSymVisibility() || *func.getSymVisibility() != "private")
      os << "\t.global " << func.getSymName() << "\n";
    // Note: `blockIds`/`nextBlockId` are *not* reset here -- `.L`-prefixed
    // labels are excluded from the output symbol table but, unlike
    // GNU-as's numeric local-label scheme (`1:`/`1b`/`1f`), are not
    // auto-scoped: two functions independently emitting `.LBB0` collide
    // as duplicate-symbol errors in the same assembled file (found by
    // actually assembling this pass's output with the real `lvx-mbr-as`
    // -- see lvx-mlir/docs/AssemblyEmission.md). One counter for the whole
    // module keeps every label unique.
    entryBlock = &func.getBody().front();
    os << func.getSymName() << ":\n";
    // lvx_func.call requires -lvx-scf-to-cf to have already run: real
    // assembly (and this emitter) has no structured-loop representation.
    for (Block &block : func.getBody()) {
      Block *nextBlock = block.getNextNode();
      if (failed(emitBlock(&block, nextBlock)))
        return failure();
    }
    return success();
  }
};

struct LVXEmitAsmPass : public lvx::impl::LVXEmitAsmPassBase<LVXEmitAsmPass> {
  using LVXEmitAsmPassBase::LVXEmitAsmPassBase;

  void runOnOperation() override {
    AsmEmitter emitter(llvm::outs());
    llvm::outs() << "\t.section .text, \"ax\", @progbits\n";
    if (failed(emitter.emitModule(getOperation())))
      signalPassFailure();
  }
};

} // namespace
