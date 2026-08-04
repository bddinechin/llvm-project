//===-- LVXInstrPatterns.td - -*- tablegen -*- ===//
//
// SelectionDAG patterns derived from each opcode's Behavior.
//
// Generated from the LVX Machine Description System by MDS/BE/LLVM,
// for core lvx_v1.  DO NOT EDIT -- your changes will be overwritten by
// the next `make -C BE/LLVM install`.  Change lvx-mds/lvx-family's YAML
// description, or the generator in MDS/BE/LLVM/BIN, instead.
//
//===----------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Selection patterns
//
// Each pattern's operand placement comes from the opcode's Behavior, not from
// its assembly syntax: the syntax prints "$rW = $rZ, $rY" whether or not the
// operation is commutative, while the Behavior states which source is which.
//===----------------------------------------------------------------------===//

def : Pat<(add GPR128:$rO, GPR128:$rP),
           (ADDQ_QWRR0 GPR128:$rP, GPR128:$rO)>;
def : Pat<(add GPR:$rY, GPR:$rZ),
           (ADDD_DWRR0 GPR:$rZ, GPR:$rY)>;
def : Pat<(add GPR:$rZ, wimm32imm:$imm),
           (ADDD_DWRR0_M GPR:$rZ, wimm32imm:$imm, 0)>;
def : Pat<(add GPR:$rZ, simm10imm:$imm),
           (ADDD_DWRI GPR:$rZ, simm10imm:$imm)>;
def : Pat<(add GPR:$rZ, simm37imm:$imm),
           (ADDD_DWRI_X GPR:$rZ, simm37imm:$imm)>;
def : Pat<(add GPR:$rZ, wimm64imm:$imm),
           (ADDD_DWRI_Y GPR:$rZ, wimm64imm:$imm)>;
def : Pat<(sub GPR128:$rO, GPR128:$rP),
           (SBFQ_QWRR0 GPR128:$rP, GPR128:$rO)>;   // operand order is significant
def : Pat<(sub GPR:$rY, GPR:$rZ),
           (SBFD_DWRR0 GPR:$rZ, GPR:$rY)>;   // operand order is significant
def : Pat<(sub wimm32imm:$imm, GPR:$rZ),
           (SBFD_DWRR0_M GPR:$rZ, wimm32imm:$imm, 0)>;   // operand order is significant
def : Pat<(sub simm10imm:$imm, GPR:$rZ),
           (SBFD_DWRI GPR:$rZ, simm10imm:$imm)>;   // operand order is significant
def : Pat<(sub simm37imm:$imm, GPR:$rZ),
           (SBFD_DWRI_X GPR:$rZ, simm37imm:$imm)>;   // operand order is significant
def : Pat<(sub wimm64imm:$imm, GPR:$rZ),
           (SBFD_DWRI_Y GPR:$rZ, wimm64imm:$imm)>;   // operand order is significant
def : Pat<(and GPR128:$rP, GPR128:$rO),
           (ANDQ_QWRR0 GPR128:$rP, GPR128:$rO)>;
def : Pat<(and GPR:$rZ, GPR:$rY),
           (ANDD_DWRR0 GPR:$rZ, GPR:$rY)>;
def : Pat<(and GPR:$rZ, wimm32imm:$imm),
           (ANDD_DWRR0_M GPR:$rZ, wimm32imm:$imm, 0)>;
def : Pat<(and GPR:$rZ, simm10imm:$imm),
           (ANDD_DWRI GPR:$rZ, simm10imm:$imm)>;
def : Pat<(and GPR:$rZ, simm37imm:$imm),
           (ANDD_DWRI_X GPR:$rZ, simm37imm:$imm)>;
def : Pat<(and GPR:$rZ, wimm64imm:$imm),
           (ANDD_DWRI_Y GPR:$rZ, wimm64imm:$imm)>;
def : Pat<(or GPR128:$rP, GPR128:$rO),
           (IORQ_QWRR0 GPR128:$rP, GPR128:$rO)>;
def : Pat<(or GPR:$rZ, GPR:$rY),
           (IORD_DWRR0 GPR:$rZ, GPR:$rY)>;
def : Pat<(or GPR:$rZ, wimm32imm:$imm),
           (IORD_DWRR0_M GPR:$rZ, wimm32imm:$imm, 0)>;
def : Pat<(or GPR:$rZ, simm10imm:$imm),
           (IORD_DWRI GPR:$rZ, simm10imm:$imm)>;
def : Pat<(or GPR:$rZ, simm37imm:$imm),
           (IORD_DWRI_X GPR:$rZ, simm37imm:$imm)>;
def : Pat<(or GPR:$rZ, wimm64imm:$imm),
           (IORD_DWRI_Y GPR:$rZ, wimm64imm:$imm)>;
def : Pat<(xor GPR128:$rP, GPR128:$rO),
           (EORQ_QWRR0 GPR128:$rP, GPR128:$rO)>;
def : Pat<(xor GPR:$rZ, GPR:$rY),
           (EORD_DWRR0 GPR:$rZ, GPR:$rY)>;
def : Pat<(xor GPR:$rZ, wimm32imm:$imm),
           (EORD_DWRR0_M GPR:$rZ, wimm32imm:$imm, 0)>;
def : Pat<(xor GPR:$rZ, simm10imm:$imm),
           (EORD_DWRI GPR:$rZ, simm10imm:$imm)>;
def : Pat<(xor GPR:$rZ, simm37imm:$imm),
           (EORD_DWRI_X GPR:$rZ, simm37imm:$imm)>;
def : Pat<(xor GPR:$rZ, wimm64imm:$imm),
           (EORD_DWRI_Y GPR:$rZ, wimm64imm:$imm)>;
def : Pat<(mulhs GPR:$rZ, GPR:$rY),
           (MULD_DMWRR GPR:$rZ, GPR:$rY, 0)>;
def : Pat<(mulhu GPR:$rZ, GPR:$rY),
           (MULD_DMWRR GPR:$rZ, GPR:$rY, 1)>;
def : Pat<(mul GPR:$rZ, GPR:$rY),
           (MULD_DMWRR GPR:$rZ, GPR:$rY, 3)>;
