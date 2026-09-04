//===- LVXFuncOps.td - LVX_func dialect operation definitions -*- tablegen -*-=//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LVX_FUNC_OPS
#define LVX_FUNC_OPS

include "mlir/Dialect/LVXFunc/IR/LVXFuncBase.td"
include "mlir/Dialect/LVX/IR/LVXBase.td"
include "mlir/Interfaces/CallInterfaces.td"
include "mlir/Interfaces/ControlFlowInterfaces.td"
include "mlir/Interfaces/FunctionInterfaces.td"
include "mlir/Interfaces/SideEffectInterfaces.td"
include "mlir/IR/SymbolInterfaces.td"

class LVXFunc_Op<string mnemonic, list<Trait> traits = []> :
    Op<LVXFunc_Dialect, mnemonic, traits>;

def LVXFunc_FuncOp : LVXFunc_Op<"func",
    [FunctionOpInterface, IsolatedFromAbove, Symbol]> {
  let summary = "function definition, ABI-constrained per Convention.table";
  let arguments = (ins SymbolNameAttr:$sym_name,
                       TypeAttrOf<FunctionType>:$function_type,
                       OptionalAttr<StrAttr>:$sym_visibility,
                       OptionalAttr<DictArrayAttr>:$arg_attrs,
                       OptionalAttr<DictArrayAttr>:$res_attrs);
  let regions = (region AnyRegion:$body);
  let builders = [OpBuilder<(ins
    "StringRef":$name, "FunctionType":$type,
    CArg<"ArrayRef<NamedAttribute>", "{}">:$attrs,
    CArg<"ArrayRef<DictionaryAttr>", "{}">:$argAttrs)
  >];
  let extraClassDeclaration = [{
    static FuncOp create(Location location, StringRef name,
                                 FunctionType type,
                                 ArrayRef<NamedAttribute> attrs = {});

    ::mlir::Region *getCallableRegion() {
      return isExternal() ? nullptr : &getBody();
    }
    ArrayRef<Type> getArgumentTypes() {
      return getFunctionType().getInputs();
    }
    ArrayRef<Type> getResultTypes() {
      return getFunctionType().getResults();
    }
    bool isDeclaration() { return isExternal(); }
  }];
  let hasCustomAssemblyFormat = 1;
  let hasVerifier = 1;
  let hasRegionVerifier = 1;
}

def LVXFunc_CallOp : LVXFunc_Op<"call",
    [CallOpInterface,
     DeclareOpInterfaceMethods<SymbolUserOpInterface>]> {
  let summary = "direct function call, ABI-constrained per Convention.table";
  // The widened encoding, `callx`: see lvx_cf.br's `format`, which records
  // why the wide form is an attribute rather than a second op (O3).
  let arguments = (ins FlatSymbolRefAttr:$callee,
                       Variadic<LVX_RegType>:$operands,
                       OptionalAttr<DictArrayAttr>:$arg_attrs,
                       OptionalAttr<DictArrayAttr>:$res_attrs,
                       OptionalAttr<LVX_FormatAttr>:$format);
  let results = (outs Variadic<LVX_RegType>);
  let builders = [
    OpBuilder<(ins "FuncOp":$callee,
                   CArg<"ValueRange", "{}">:$operands), [{
      $_state.addOperands(operands);
      $_state.addAttribute("callee", SymbolRefAttr::get(callee));
      $_state.addTypes(callee.getFunctionType().getResults());
    }]>,
    OpBuilder<(ins "StringRef":$callee, "TypeRange":$results,
                   CArg<"ValueRange", "{}">:$operands), [{
      $_state.addOperands(operands);
      $_state.addAttribute("callee",
          FlatSymbolRefAttr::get($_builder.getContext(), callee));
      $_state.addTypes(results);
    }]>];
  let extraClassDeclaration = [{
    operand_range getArgOperands() { return getOperands(); }
    MutableOperandRange getArgOperandsMutable() {
      return getOperandsMutable();
    }
    CallInterfaceCallable getCallableForCallee() {
      return (*this)->getAttrOfType<SymbolRefAttr>("callee");
    }
    void setCalleeFromCallable(CallInterfaceCallable callee) {
      (*this)->setAttr("callee", cast<SymbolRefAttr>(callee));
    }
  }];
  let hasVerifier = 1;
  let assemblyFormat = [{
    $callee `(` $operands `)` ($format^)? attr-dict `:` functional-type($operands, results)
  }];
}

def LVXFunc_ReturnOp : LVXFunc_Op<"return",
    [Pure, HasParent<"FuncOp">, ReturnLike, Terminator]> {
  let summary = "function return";
  let arguments = (ins Variadic<LVX_RegType>:$operands);
  let builders = [OpBuilder<(ins), [{
    build($_builder, $_state, {});
  }]>];
  let assemblyFormat = "attr-dict ($operands^ `:` qualified(type($operands)))?";
  let hasVerifier = 1;
}

#endif // LVX_FUNC_OPS
