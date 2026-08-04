//===- LVXFuncOps.cpp - LVX_func dialect op implementations ----------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/LVXFunc/IR/LVXFunc.h"
#include "mlir/IR/IRMapping.h"
#include "mlir/Interfaces/FunctionImplementation.h"

#define GET_OP_CLASSES
#include "mlir/Dialect/LVXFunc/IR/LVXFuncOps.cpp.inc"

using namespace mlir;
using namespace mlir::lvx_func;

// Per lvx-mds/lvx-refs' `Convention-lvx_v1-regular`: 12 argument
// registers ($r0-$r11) and 4 result registers ($r0-$r3).
static constexpr unsigned kMaxAbiArgRegs = 12;
static constexpr unsigned kMaxAbiResultRegs = 4;

//===----------------------------------------------------------------------===//
// FuncOp
//===----------------------------------------------------------------------===//

FuncOp FuncOp::create(Location location, StringRef name,
                                     FunctionType type,
                                     ArrayRef<NamedAttribute> attrs) {
  OpBuilder builder(location->getContext());
  OperationState state(location, getOperationName());
  FuncOp::build(builder, state, name, type, attrs);
  return cast<FuncOp>(Operation::create(state));
}

void FuncOp::build(OpBuilder &builder, OperationState &state,
                           StringRef name, FunctionType type,
                           ArrayRef<NamedAttribute> attrs,
                           ArrayRef<DictionaryAttr> argAttrs) {
  state.addAttribute(SymbolTable::getSymbolAttrName(),
                     builder.getStringAttr(name));
  state.addAttribute(getFunctionTypeAttrName(state.name), TypeAttr::get(type));
  state.attributes.append(attrs.begin(), attrs.end());
  state.addRegion();

  if (argAttrs.empty())
    return;
  assert(type.getNumInputs() == argAttrs.size());
  call_interface_impl::addArgAndResultAttrs(
      builder, state, argAttrs, /*resultAttrs=*/{},
      getArgAttrsAttrName(state.name), getResAttrsAttrName(state.name));
}

ParseResult FuncOp::parse(OpAsmParser &parser, OperationState &result) {
  auto buildFuncType = [](Builder &builder, ArrayRef<Type> argTypes,
                           ArrayRef<Type> results,
                           function_interface_impl::VariadicFlag,
                           std::string &) {
    return builder.getFunctionType(argTypes, results);
  };
  return function_interface_impl::parseFunctionOp(
      parser, result, /*allowVariadic=*/false,
      getFunctionTypeAttrName(result.name), buildFuncType,
      getArgAttrsAttrName(result.name), getResAttrsAttrName(result.name));
}

void FuncOp::print(OpAsmPrinter &p) {
  function_interface_impl::printFunctionOp(p, *this, /*isVariadic=*/false,
                                            getFunctionTypeAttrName(),
                                            getArgAttrsAttrName(),
                                            getResAttrsAttrName());
}

LogicalResult FuncOp::verify() {
  if (getFunctionType().getNumInputs() > kMaxAbiArgRegs)
    return emitOpError("has ")
           << getFunctionType().getNumInputs()
           << " arguments, exceeding the " << kMaxAbiArgRegs
           << " available argument registers ($r0-$r"
           << (kMaxAbiArgRegs - 1) << ") in the regular calling convention";
  if (getFunctionType().getNumResults() > kMaxAbiResultRegs)
    return emitOpError("has ")
           << getFunctionType().getNumResults()
           << " results, exceeding the " << kMaxAbiResultRegs
           << " available result registers ($r0-$r"
           << (kMaxAbiResultRegs - 1) << ") in the regular calling convention";
  return success();
}

LogicalResult FuncOp::verifyRegions() {
  // For external functions (declarations), the body must be empty.
  if (isExternal())
    return success();
  // A non-empty body must have at least one block.
  if (getBody().empty())
    return emitOpError("function body must not be empty");
  return success();
}

//===----------------------------------------------------------------------===//
// CallOp
//===----------------------------------------------------------------------===//

LogicalResult CallOp::verify() {
  if (getOperands().size() > kMaxAbiArgRegs)
    return emitOpError("has ")
           << getOperands().size() << " call operands, exceeding the "
           << kMaxAbiArgRegs << " available argument registers";
  if (getNumResults() > kMaxAbiResultRegs)
    return emitOpError("has ")
           << getNumResults() << " results, exceeding the "
           << kMaxAbiResultRegs << " available result registers";
  return success();
}

LogicalResult
CallOp::verifySymbolUses(SymbolTableCollection &symbolTable) {
  auto func = symbolTable.lookupNearestSymbolFrom<FuncOp>(
      *this, getCalleeAttr());
  if (!func)
    return emitOpError("'") << getCallee() << "' does not reference a valid "
                                              "lvx_func.func";
  FunctionType funcType = func.getFunctionType();
  if (funcType.getNumInputs() != getOperands().size())
    return emitOpError("callee expects ")
           << funcType.getNumInputs() << " operands, got "
           << getOperands().size();
  if (funcType.getNumResults() != getNumResults())
    return emitOpError("callee has ")
           << funcType.getNumResults() << " results, call has "
           << getNumResults();
  return success();
}

//===----------------------------------------------------------------------===//
// ReturnOp
//===----------------------------------------------------------------------===//

LogicalResult ReturnOp::verify() {
  auto func = cast<FuncOp>((*this)->getParentOp());
  FunctionType funcType = func.getFunctionType();
  if (getOperands().size() != funcType.getNumResults())
    return emitOpError("number of return values (")
           << getOperands().size()
           << ") must match function result count ("
           << funcType.getNumResults() << ")";
  for (auto [idx, opType, resType] :
       llvm::enumerate(getOperandTypes(), funcType.getResults())) {
    if (opType != resType)
      return emitOpError("type of return value #")
             << idx << " (" << opType
             << ") must match function result type (" << resType << ")";
  }
  return success();
}
