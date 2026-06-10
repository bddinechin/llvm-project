include "llvm/Target/Target.td"

include "LVXRegisterInfo.td"
include "LVXInstrInfo.td"
include "LVXCallingConv.td"

def LVXInstrInfo : InstrInfo;

def LVX : Target {
  let InstructionSet = LVXInstrInfo;
}

