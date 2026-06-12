//===-- LVX.td - Describe the LVX Target Machine ----------*- tablegen -*-===//
//
// This is the top-level entry point for the LVX target description.
//
// Include order matters and each file is included exactly once:
//   - Target.td (and everything it pulls in, including ValueType
//     definitions from Intrinsics.td/ValueTypes.td) is included first,
//     here, before any file that depends on its classes (RegisterClass,
//     Operand, Instruction, CallingConv, etc.).
//   - LVXInstrInfo.td includes LVXRegisterInfo.td (for GPR/GPR128/GPR256/
//     CR register classes) and LVXInstrFormats.td (for modifier operand
//     types) internally — do NOT include either of those again here.
//   - LVXCallingConv.td depends on the register definitions from
//     LVXRegisterInfo.td (R0, R0R1, ...), which are already in scope by
//     the time it is processed because LVXInstrInfo.td (included above
//     it) pulled them in.
//
//===----------------------------------------------------------------------===//

include "llvm/Target/Target.td"

include "LVXInstrInfo.td"
include "LVXCallingConv.td"

def LVX : Target {
  let InstructionSet = LVXInstrInfo;
}
