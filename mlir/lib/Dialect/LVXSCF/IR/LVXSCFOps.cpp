//===- LVXSCFOps.cpp - LVX_scf dialect op implementations ------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/LVXSCF/IR/LVXSCF.h"
#include "mlir/Dialect/LVX/IR/LVX.h"

#define GET_OP_CLASSES
#include "mlir/Dialect/LVXSCF/IR/LVXSCFOps.cpp.inc"

using namespace mlir;
using namespace mlir::lvx_scf;
using mlir::lvx::RegisterType;

//===----------------------------------------------------------------------===//
// ForOp
//===----------------------------------------------------------------------===//

// LoopLikeOpInterface. The body is the only region, and it is the one a
// hoisted op leaves.
SmallVector<Region *> ForOp::getLoopRegions() { return {&getRegion()}; }

// The loop-carried accessors, which the interface's own verifier checks
// against each other: the inits are the trailing variadic operands after the
// three bounds, the yielded values are the terminator's operands, and the
// results are this op's. Leaving these to their defaults (empty) makes that
// verifier reject every loop that carries a value.
MutableArrayRef<OpOperand> ForOp::getInitsMutable() {
  return getOperation()->getOpOperands().drop_front(/*lb, ub, step=*/3);
}

std::optional<MutableArrayRef<OpOperand>> ForOp::getYieldedValuesMutable() {
  return cast<YieldOp>(getBody()->getTerminator())
      .getOperation()
      ->getOpOperands();
}

std::optional<ResultRange> ForOp::getLoopResults() { return getResults(); }

LogicalResult ForOp::verify() {
  if (getInitArgs().size() != getResults().size())
    return emitOpError("number of loop-carried init args (")
           << getInitArgs().size() << ") must match number of results ("
           << getResults().size() << ")";
  for (auto [idx, initTy, resTy] :
       llvm::enumerate(getInitArgs().getTypes(), getResultTypes())) {
    if (initTy != resTy)
      return emitOpError("type of init arg #")
             << idx << " (" << initTy << ") must match result type ("
             << resTy << ")";
  }
  return success();
}

LogicalResult ForOp::verifyRegions() {
  Block &body = *getBody();
  size_t expectedArgs = 1 + getInitArgs().size();
  if (body.getNumArguments() != expectedArgs)
    return emitOpError("expected body to take ")
           << expectedArgs << " arguments (induction variable + "
           << getInitArgs().size() << " iter args), got "
           << body.getNumArguments();
  if (!isa<RegisterType>(body.getArgument(0).getType()))
    return emitOpError("the induction variable must have type !lvx.reg");
  for (BlockArgument arg : body.getArguments().drop_front())
    if (!isa<RegisterType, lvx::PairType, lvx::QuadType>(arg.getType()))
      return emitOpError(
          "iter args must have type !lvx.reg, !lvx.pair or !lvx.quad");

  auto yield = cast<YieldOp>(body.getTerminator());
  if (yield.getResults().size() != getInitArgs().size())
    return yield.emitOpError("number of yielded values (")
           << yield.getResults().size()
           << ") must match number of loop-carried init args ("
           << getInitArgs().size() << ")";
  for (auto [idx, yieldTy, initTy] : llvm::enumerate(
           yield.getResults().getTypes(), getInitArgs().getTypes())) {
    if (yieldTy != initTy)
      return yield.emitOpError("type of yielded value #")
             << idx << " (" << yieldTy
             << ") must match the corresponding init arg/result type ("
             << initTy << ")";
  }
  return success();
}

//===----------------------------------------------------------------------===//
// LoopOp
//===----------------------------------------------------------------------===//

void LoopOp::build(OpBuilder &builder, OperationState &state,
                   TypeRange results) {
  state.addTypes(results);
  Region *region = state.addRegion();
  Block *body = new Block();
  body->addArgument(TokenType::get(builder.getContext()), state.location);
  region->push_back(body);
}

// `lvx_scf.loop token(%L) -> (types) { ... } attr-dict`, upstream's spelling
// with this dialect's parenthesised result list.
ParseResult LoopOp::parse(OpAsmParser &parser, OperationState &result) {
  OpAsmParser::Argument token;
  if (parser.parseKeyword("token") || parser.parseLParen() ||
      parser.parseArgument(token) || parser.parseRParen())
    return failure();
  token.type = TokenType::get(parser.getContext());
  SmallVector<Type> types;
  if (succeeded(parser.parseOptionalArrow()))
    if (parser.parseLParen() || parser.parseTypeList(types) ||
        parser.parseRParen())
      return failure();
  result.addTypes(types);
  Region *body = result.addRegion();
  if (parser.parseRegion(*body, {token}) ||
      parser.parseOptionalAttrDict(result.attributes))
    return failure();
  return success();
}

void LoopOp::print(OpAsmPrinter &p) {
  p << " token(";
  p.printRegionArgument(getBody()->getArgument(0), /*argAttrs=*/{},
                        /*omitType=*/true);
  p << ")";
  if (!getResults().empty()) {
    p << " -> (";
    llvm::interleaveComma(getResultTypes(), p);
    p << ")";
  }
  p << " ";
  p.printRegion(getRegion(), /*printEntryBlockArgs=*/false);
  p.printOptionalAttrDict((*this)->getAttrs());
}

LogicalResult LoopOp::verifyRegions() {
  Block &body = *getBody();
  if (body.getNumArguments() != 1 ||
      !isa<TokenType>(body.getArgument(0).getType()))
    return emitOpError("expected the body to take one argument, the token");
  // A token is a name, not a value: anything but a break reading it would be
  // reading nothing.
  for (Operation *user : getToken().getUsers())
    if (!isa<BreakOp>(user))
      return user->emitOpError("may not use an lvx_scf.loop's token");
  // No `continue`, so the body's end is always a way out -- of this loop or
  // of one around it.
  if (!body.mightHaveTerminator() || !isa<BreakOp>(body.getTerminator()))
    return emitOpError("expected the body to end in a break");
  return success();
}

//===----------------------------------------------------------------------===//
// BreakOp
//===----------------------------------------------------------------------===//

LoopOp BreakOp::getLoop() {
  return cast<LoopOp>(cast<BlockArgument>(getToken()).getOwner()->getParentOp());
}

LogicalResult BreakOp::verify() {
  auto arg = dyn_cast<BlockArgument>(getToken());
  if (!arg || !isa<LoopOp>(arg.getOwner()->getParentOp()))
    return emitOpError("expected the token of an enclosing lvx_scf.loop");
  LoopOp loop = getLoop();
  // Upstream's PropagateControlFlowBreak, which here `if` and `loop` have:
  // every region a break leaves on its way out runs at most once, so its edge
  // to the loop's continuation is forward. Leaving an `lvx_scf.for` would
  // need its trip count left behind, which no lowering here does.
  for (Operation *op = (*this)->getParentOp(); op != loop;
       op = op->getParentOp())
    if (!isa<IfOp, LoopOp>(op))
      return emitOpError("may only leave its loop through lvx_scf.if and "
                         "lvx_scf.loop, not ")
             << op->getName();
  if (getArgs().getTypes() != loop.getResultTypes())
    return emitOpError("carries ")
           << getArgs().size() << " value(s) of types " << getArgs().getTypes()
           << " but the loop's results are " << loop.getResultTypes();
  return success();
}

//===----------------------------------------------------------------------===//
// IfOp
//===----------------------------------------------------------------------===//

void IfOp::build(OpBuilder &builder, OperationState &state, lvx::BcuCond cond,
                 Value test) {
  state.addAttribute(getConditionAttrName(state.name),
                     lvx::BcuCondAttr::get(builder.getContext(), cond));
  state.addOperands(test);
  Region *region = state.addRegion();
  Block *body = new Block();
  region->push_back(body);
  OpBuilder::InsertionGuard guard(builder);
  builder.setInsertionPointToEnd(body);
  builder.create<YieldOp>(state.location);
}

// `lvx_scf.if <bcucond> %test : type { ... } attr-dict`, the order
// `lvx.guarded` uses. A region that falls through ends in a `yield` with no
// values, which is left implicit both ways.
ParseResult IfOp::parse(OpAsmParser &parser, OperationState &result) {
  lvx::BcuCond cond;
  StringRef keyword;
  SMLoc loc = parser.getCurrentLocation();
  if (parser.parseKeyword(&keyword))
    return failure();
  std::optional<lvx::BcuCond> parsed = lvx::symbolizeBcuCond(keyword);
  if (!parsed)
    return parser.emitError(loc, "expected a BcuCond, got '") << keyword << "'";
  cond = *parsed;
  result.addAttribute(getConditionAttrName(result.name),
                      lvx::BcuCondAttr::get(parser.getContext(), cond));
  OpAsmParser::UnresolvedOperand test;
  Type testType;
  if (parser.parseOperand(test) || parser.parseColonType(testType) ||
      parser.resolveOperand(test, testType, result.operands))
    return failure();
  Region *body = result.addRegion();
  if (parser.parseRegion(*body, /*arguments=*/{}) ||
      parser.parseOptionalAttrDict(result.attributes))
    return failure();
  if (body->empty())
    body->push_back(new Block());
  Block &block = body->front();
  if (block.empty() || !block.back().hasTrait<OpTrait::IsTerminator>()) {
    OpBuilder builder(parser.getContext());
    builder.setInsertionPointToEnd(&block);
    builder.create<YieldOp>(result.location);
  }
  return success();
}

void IfOp::print(OpAsmPrinter &p) {
  p << " " << lvx::stringifyBcuCond(getCondition()) << " " << getTest()
    << " : " << getTest().getType() << " ";
  // Implicit only when there is nothing to lose: the bundler's `cycle` on the
  // yield would not survive being left out.
  Operation *end = getThenBlock()->getTerminator();
  bool implicitYield = isa<YieldOp>(end) && end->getAttrs().empty();
  p.printRegion(getThenRegion(), /*printEntryBlockArgs=*/false,
                /*printBlockTerminators=*/!implicitYield);
  p.printOptionalAttrDict((*this)->getAttrs(), {getConditionAttrName()});
}

LogicalResult IfOp::verifyRegions() {
  if (!getThenBlock()->mightHaveTerminator())
    return emitOpError("expected the region to end in yield or break");
  Operation *end = getThenBlock()->getTerminator();
  if (auto yield = dyn_cast<YieldOp>(end)) {
    if (!yield.getResults().empty())
      return yield.emitOpError("in an lvx_scf.if carries no values");
    return success();
  }
  if (!isa<BreakOp>(end))
    return emitOpError("expected the region to end in yield or break");
  return success();
}
