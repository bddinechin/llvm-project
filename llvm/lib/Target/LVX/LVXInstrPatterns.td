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
def : Pat<(f64 (fpextend f32:$rZ)),
           (FWIDENWD_FDWIDEN f32:$rZ, 0)>;   // to_f64
def : Pat<(f32 (fpround f64:$rZ)),
           (FNARROWDW_FWWR f64:$rZ, 7)>;   // to_f32
def : Pat<(fminimum f64:$rZ, f64:$rY),
           (FMIND_FDMMWR f64:$rZ, f64:$rY)>;   // min
def : Pat<(fminimum f32:$rZ, f32:$rY),
           (FMINW_FWMMWR f32:$rZ, f32:$rY)>;   // min
def : Pat<(fminnum f64:$rZ, f64:$rY),
           (FMINND_FDMMWR f64:$rZ, f64:$rY)>;   // minNum
def : Pat<(fminnum f32:$rZ, f32:$rY),
           (FMINNW_FWMMWR f32:$rZ, f32:$rY)>;   // minNum
def : Pat<(fmaximum f64:$rZ, f64:$rY),
           (FMAXD_FDMMWR f64:$rZ, f64:$rY)>;   // max
def : Pat<(fmaximum f32:$rZ, f32:$rY),
           (FMAXW_FWMMWR f32:$rZ, f32:$rY)>;   // max
def : Pat<(fmaxnum f64:$rZ, f64:$rY),
           (FMAXND_FDMMWR f64:$rZ, f64:$rY)>;   // maxNum
def : Pat<(fmaxnum f32:$rZ, f32:$rY),
           (FMAXNW_FWMMWR f32:$rZ, f32:$rY)>;   // maxNum
def : Pat<(f64 (sint_to_fp i64:$rZ)),
           (FLOATD_FDFLOAT i64:$rZ, 7)>;   // to_f64
def : Pat<(f64 (uint_to_fp i64:$rZ)),
           (FLOATUD_FDFLOAT i64:$rZ, 7)>;   // to_f64
def : Pat<(f32 (sint_to_fp i64:$rZ)),
           (FLOATDW_FWFLOAT i64:$rZ, 7)>;   // to_f32
def : Pat<(f32 (uint_to_fp i64:$rZ)),
           (FLOATUDW_FWFLOAT i64:$rZ, 7)>;   // to_f32
def : Pat<(i64 (fp_to_sint f64:$rZ)),
           (FIXEDD_FDFIXED f64:$rZ, 1)>;   // to_i64
def : Pat<(i64 (fp_to_uint f64:$rZ)),
           (FIXEDUD_FDFIXED f64:$rZ, 1)>;   // to_ui64
def : Pat<(i64 (fp_to_sint f32:$rZ)),
           (FIXEDWD_FDFIXED f32:$rZ, 1)>;   // to_i64
def : Pat<(i64 (fp_to_uint f32:$rZ)),
           (FIXEDUWD_FDFIXED f32:$rZ, 1)>;   // to_ui64
def : Pat<(frint f64:$rZ),
           (FRINTD_FDMO0 f64:$rZ, 7)>;   // rint
def : Pat<(frint f32:$rZ),
           (FRINTW_FWMO0 f32:$rZ, 7)>;   // rint
def : Pat<(fsqrt f64:$rZ),
           (FSQRTD_FDMO0 f64:$rZ, 7)>;   // sqrt
def : Pat<(fsqrt f32:$rZ),
           (FSQRTW_FWMO0 f32:$rZ, 7)>;   // sqrt
def : Pat<(mulhs GPR:$rZ, GPR:$rY),
           (MULD_DMWRR GPR:$rZ, GPR:$rY, 0)>;
def : Pat<(mulhu GPR:$rZ, GPR:$rY),
           (MULD_DMWRR GPR:$rZ, GPR:$rY, 1)>;
def : Pat<(mul GPR:$rZ, GPR:$rY),
           (MULD_DMWRR GPR:$rZ, GPR:$rY, 3)>;
def : Pat<(fadd f64:$rZ, f64:$rY),
           (FADDD_FDADD f64:$rZ, f64:$rY, 7)>;   // add
def : Pat<(fadd f32:$rZ, f32:$rY),
           (FADDW_FWADD f32:$rZ, f32:$rY, 7)>;   // add
def : Pat<(fsub f64:$rY, f64:$rZ),
           (FSBFD_FDADD f64:$rZ, f64:$rY, 7)>;   // sub
def : Pat<(fsub f32:$rY, f32:$rZ),
           (FSBFW_FWADD f32:$rZ, f32:$rY, 7)>;   // sub
def : Pat<(fmul f64:$rZ, f64:$rY),
           (FMULD_FDMUL f64:$rZ, f64:$rY, 7, 0)>;   // mul
def : Pat<(fmul f32:$rZ, f32:$rY),
           (FMULW_FWMUL f32:$rZ, f32:$rY, 7, 0)>;   // mul
def : Pat<(fdiv f64:$rZ, f64:$rY),
           (FDIVD_FDMUL f64:$rZ, f64:$rY, 7, 0)>;   // div
def : Pat<(fdiv f32:$rZ, f32:$rY),
           (FDIVW_FWMUL f32:$rZ, f32:$rY, 7, 0)>;   // div
def : Pat<(fma f64:$rY, f64:$rZ, f64:$rW),
           (FFMAD_FDFMA f64:$rW, f64:$rZ, f64:$rY, 7, 0)>;   // mulAdd
def : Pat<(fma f32:$rY, f32:$rZ, f32:$rW),
           (FFMAW_FWFMA f32:$rW, f32:$rZ, f32:$rY, 7, 0)>;   // mulAdd
def : Pat<(fma (fneg f64:$rY), f64:$rZ, f64:$rW),
           (FFMSD_FDFMA f64:$rW, f64:$rZ, f64:$rY, 7, 0)>;   // mulnAdd
def : Pat<(fma (fneg f32:$rY), f32:$rZ, f32:$rW),
           (FFMSW_FWFMA f32:$rW, f32:$rZ, f32:$rY, 7, 0)>;   // mulnAdd
