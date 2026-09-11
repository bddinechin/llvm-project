//===-- LVXTiedOperands.inc - -*- C++ -*- ===//
//
// Operands tied to a result, by op mnemonic.
//
// Generated from the LVX Machine Description System by MDS/BE/MLIR, for core
// lvx_v2.  DO NOT EDIT -- your changes will be overwritten by the next
// `make -C BE/MLIR install`.  Change lvx-mds/lvx-family's YAML description,
// or the generator in MDS/BE/MLIR/BIN, instead.
//
//===----------------------------------------------------------------===//

#ifndef LVX_TIED_OPERANDS_INC
#define LVX_TIED_OPERANDS_INC

namespace mlir {
namespace lvx {

/// An operand the instruction reads THROUGH its destination: real hardware
/// has one field for both, so the register allocator must give them the same
/// register and the assembly printer must not print the operand.
///
/// Which operands these are is `analysis`'s `Written;Read`, not a judgement:
/// an accumulator (`ffmad $rW = $rZ, $rY` computes `$rW += $rZ*$rY`), a
/// predicated move's prior value, an atomic's returned old value.
struct TiedOperand {
  unsigned operand;
  unsigned result;
};

/// The tied operands of the op with this mnemonic, empty if it has none.
/// Keyed by mnemonic rather than by C++ type so a caller can ask an
/// `Operation *` without a switch over every op in the dialect.
inline ::llvm::ArrayRef<TiedOperand> tiedOperandsOf(::llvm::StringRef mnemonic) {
  static constexpr TiedOperand k_aladdb[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_aladdb_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_aladdd[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_aladdd_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_aladdh[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_aladdh_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_aladdw[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_aladdw_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_alandb[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_alandb_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_alandd[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_alandd_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_alandh[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_alandh_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_alandw[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_alandw_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_aldusb[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_aldusb_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_aldusd[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_aldusd_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_aldush[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_aldush_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_aldusw[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_aldusw_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_aleorb[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_aleorb_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_aleord[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_aleord_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_aleorh[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_aleorh_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_aleorw[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_aleorw_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_aliorb[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_aliorb_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_aliord[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_aliord_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_aliorh[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_aliorh_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_aliorw[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_aliorw_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_almaxb[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_almaxb_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_almaxd[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_almaxd_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_almaxh[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_almaxh_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_almaxub[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_almaxub_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_almaxud[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_almaxud_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_almaxuh[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_almaxuh_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_almaxuw[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_almaxuw_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_almaxw[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_almaxw_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_alminb[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_alminb_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_almind[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_almind_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_alminh[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_alminh_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_alminub[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_alminub_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_alminud[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_alminud_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_alminuh[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_alminuh_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_alminuw[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_alminuw_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_alminw[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_alminw_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_aswapb[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_aswapb_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_aswapd[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_aswapd_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_aswaph[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_aswaph_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_aswapw[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_aswapw_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_cmovebx[] = {TiedOperand{2, 1}};
  static constexpr TiedOperand k_cmovebx_i[] = {TiedOperand{1, 1}};
  static constexpr TiedOperand k_cmoved[] = {TiedOperand{2, 0}};
  static constexpr TiedOperand k_cmoved_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_cmovedp[] = {TiedOperand{2, 1}};
  static constexpr TiedOperand k_cmovedp_i[] = {TiedOperand{1, 1}};
  static constexpr TiedOperand k_cmoveho[] = {TiedOperand{2, 1}};
  static constexpr TiedOperand k_cmoveho_i[] = {TiedOperand{1, 1}};
  static constexpr TiedOperand k_cmoveq[] = {TiedOperand{2, 1}};
  static constexpr TiedOperand k_cmovewq[] = {TiedOperand{2, 1}};
  static constexpr TiedOperand k_cmovewq_i[] = {TiedOperand{1, 1}};
  static constexpr TiedOperand k_crcbellw[] = {TiedOperand{2, 0}};
  static constexpr TiedOperand k_crcbellw_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_crcbelmw[] = {TiedOperand{2, 0}};
  static constexpr TiedOperand k_crcbelmw_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_crclellw[] = {TiedOperand{2, 0}};
  static constexpr TiedOperand k_crclellw_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_crclelmw[] = {TiedOperand{2, 0}};
  static constexpr TiedOperand k_crclelmw_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_csrrc[] = {TiedOperand{0, 0}};
  static constexpr TiedOperand k_csrrs[] = {TiedOperand{0, 0}};
  static constexpr TiedOperand k_csrrw[] = {TiedOperand{0, 0}};
  static constexpr TiedOperand k_ffmad[] = {TiedOperand{2, 0}};
  static constexpr TiedOperand k_ffmadp[] = {TiedOperand{2, 1}};
  static constexpr TiedOperand k_ffmah[] = {TiedOperand{2, 0}};
  static constexpr TiedOperand k_ffmaho[] = {TiedOperand{2, 1}};
  static constexpr TiedOperand k_ffmaw[] = {TiedOperand{2, 0}};
  static constexpr TiedOperand k_ffmawc[] = {TiedOperand{2, 0}};
  static constexpr TiedOperand k_ffmawq[] = {TiedOperand{2, 1}};
  static constexpr TiedOperand k_ffmsd[] = {TiedOperand{2, 0}};
  static constexpr TiedOperand k_ffmsdp[] = {TiedOperand{2, 1}};
  static constexpr TiedOperand k_ffmsh[] = {TiedOperand{2, 0}};
  static constexpr TiedOperand k_ffmsho[] = {TiedOperand{2, 1}};
  static constexpr TiedOperand k_ffmsw[] = {TiedOperand{2, 0}};
  static constexpr TiedOperand k_ffmswq[] = {TiedOperand{2, 1}};
  static constexpr TiedOperand k_frcsr[] = {TiedOperand{0, 0}};
  static constexpr TiedOperand k_frflags[] = {TiedOperand{0, 0}};
  static constexpr TiedOperand k_frrm[] = {TiedOperand{0, 0}};
  static constexpr TiedOperand k_fscsr[] = {TiedOperand{0, 0}};
  static constexpr TiedOperand k_fsflags[] = {TiedOperand{0, 0}};
  static constexpr TiedOperand k_fsrm[] = {TiedOperand{0, 0}};
  static constexpr TiedOperand k_iget[] = {TiedOperand{0, 0}};
  static constexpr TiedOperand k_insf[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_maddd[] = {TiedOperand{2, 0}};
  static constexpr TiedOperand k_maddd_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_madddp[] = {TiedOperand{2, 1}};
  static constexpr TiedOperand k_maddho[] = {TiedOperand{2, 1}};
  static constexpr TiedOperand k_maddw[] = {TiedOperand{2, 0}};
  static constexpr TiedOperand k_maddw_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_maddwq[] = {TiedOperand{2, 1}};
  static constexpr TiedOperand k_maddxbho[] = {TiedOperand{2, 1}};
  static constexpr TiedOperand k_maddxdq[] = {TiedOperand{2, 1}};
  static constexpr TiedOperand k_maddxhwq[] = {TiedOperand{2, 1}};
  static constexpr TiedOperand k_maddxwd[] = {TiedOperand{2, 0}};
  static constexpr TiedOperand k_maddxwd_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_maddxwdp[] = {TiedOperand{2, 1}};
  static constexpr TiedOperand k_msbfd[] = {TiedOperand{2, 0}};
  static constexpr TiedOperand k_msbfd_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_msbfdp[] = {TiedOperand{2, 1}};
  static constexpr TiedOperand k_msbfho[] = {TiedOperand{2, 1}};
  static constexpr TiedOperand k_msbfw[] = {TiedOperand{2, 0}};
  static constexpr TiedOperand k_msbfw_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_msbfwq[] = {TiedOperand{2, 1}};
  static constexpr TiedOperand k_msbfxbho[] = {TiedOperand{2, 1}};
  static constexpr TiedOperand k_msbfxdq[] = {TiedOperand{2, 1}};
  static constexpr TiedOperand k_msbfxhwq[] = {TiedOperand{2, 1}};
  static constexpr TiedOperand k_msbfxwd[] = {TiedOperand{2, 0}};
  static constexpr TiedOperand k_msbfxwd_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_msbfxwdp[] = {TiedOperand{2, 1}};
  static constexpr TiedOperand k_rswap[] = {TiedOperand{0, 0}, TiedOperand{1, 1}};
  static constexpr TiedOperand k_sbmm8eord[] = {TiedOperand{2, 0}};
  static constexpr TiedOperand k_sbmm8eord_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_sbmm8eordp[] = {TiedOperand{2, 1}};
  static constexpr TiedOperand k_sbmm8eordp_i[] = {TiedOperand{1, 1}};
  static constexpr TiedOperand k_sbmmt8eord[] = {TiedOperand{2, 0}};
  static constexpr TiedOperand k_sbmmt8eord_i[] = {TiedOperand{1, 0}};
  static constexpr TiedOperand k_sbmmt8eordp[] = {TiedOperand{2, 1}};
  static constexpr TiedOperand k_sbmmt8eordp_i[] = {TiedOperand{1, 1}};
  static constexpr TiedOperand k_waitit[] = {TiedOperand{0, 0}};
  return ::llvm::StringSwitch<::llvm::ArrayRef<TiedOperand>>(mnemonic)
      .Case("aladdb",          k_aladdb)
      .Case("aladdb_i",        k_aladdb_i)
      .Case("aladdd",          k_aladdd)
      .Case("aladdd_i",        k_aladdd_i)
      .Case("aladdh",          k_aladdh)
      .Case("aladdh_i",        k_aladdh_i)
      .Case("aladdw",          k_aladdw)
      .Case("aladdw_i",        k_aladdw_i)
      .Case("alandb",          k_alandb)
      .Case("alandb_i",        k_alandb_i)
      .Case("alandd",          k_alandd)
      .Case("alandd_i",        k_alandd_i)
      .Case("alandh",          k_alandh)
      .Case("alandh_i",        k_alandh_i)
      .Case("alandw",          k_alandw)
      .Case("alandw_i",        k_alandw_i)
      .Case("aldusb",          k_aldusb)
      .Case("aldusb_i",        k_aldusb_i)
      .Case("aldusd",          k_aldusd)
      .Case("aldusd_i",        k_aldusd_i)
      .Case("aldush",          k_aldush)
      .Case("aldush_i",        k_aldush_i)
      .Case("aldusw",          k_aldusw)
      .Case("aldusw_i",        k_aldusw_i)
      .Case("aleorb",          k_aleorb)
      .Case("aleorb_i",        k_aleorb_i)
      .Case("aleord",          k_aleord)
      .Case("aleord_i",        k_aleord_i)
      .Case("aleorh",          k_aleorh)
      .Case("aleorh_i",        k_aleorh_i)
      .Case("aleorw",          k_aleorw)
      .Case("aleorw_i",        k_aleorw_i)
      .Case("aliorb",          k_aliorb)
      .Case("aliorb_i",        k_aliorb_i)
      .Case("aliord",          k_aliord)
      .Case("aliord_i",        k_aliord_i)
      .Case("aliorh",          k_aliorh)
      .Case("aliorh_i",        k_aliorh_i)
      .Case("aliorw",          k_aliorw)
      .Case("aliorw_i",        k_aliorw_i)
      .Case("almaxb",          k_almaxb)
      .Case("almaxb_i",        k_almaxb_i)
      .Case("almaxd",          k_almaxd)
      .Case("almaxd_i",        k_almaxd_i)
      .Case("almaxh",          k_almaxh)
      .Case("almaxh_i",        k_almaxh_i)
      .Case("almaxub",         k_almaxub)
      .Case("almaxub_i",       k_almaxub_i)
      .Case("almaxud",         k_almaxud)
      .Case("almaxud_i",       k_almaxud_i)
      .Case("almaxuh",         k_almaxuh)
      .Case("almaxuh_i",       k_almaxuh_i)
      .Case("almaxuw",         k_almaxuw)
      .Case("almaxuw_i",       k_almaxuw_i)
      .Case("almaxw",          k_almaxw)
      .Case("almaxw_i",        k_almaxw_i)
      .Case("alminb",          k_alminb)
      .Case("alminb_i",        k_alminb_i)
      .Case("almind",          k_almind)
      .Case("almind_i",        k_almind_i)
      .Case("alminh",          k_alminh)
      .Case("alminh_i",        k_alminh_i)
      .Case("alminub",         k_alminub)
      .Case("alminub_i",       k_alminub_i)
      .Case("alminud",         k_alminud)
      .Case("alminud_i",       k_alminud_i)
      .Case("alminuh",         k_alminuh)
      .Case("alminuh_i",       k_alminuh_i)
      .Case("alminuw",         k_alminuw)
      .Case("alminuw_i",       k_alminuw_i)
      .Case("alminw",          k_alminw)
      .Case("alminw_i",        k_alminw_i)
      .Case("aswapb",          k_aswapb)
      .Case("aswapb_i",        k_aswapb_i)
      .Case("aswapd",          k_aswapd)
      .Case("aswapd_i",        k_aswapd_i)
      .Case("aswaph",          k_aswaph)
      .Case("aswaph_i",        k_aswaph_i)
      .Case("aswapw",          k_aswapw)
      .Case("aswapw_i",        k_aswapw_i)
      .Case("cmovebx",         k_cmovebx)
      .Case("cmovebx_i",       k_cmovebx_i)
      .Case("cmoved",          k_cmoved)
      .Case("cmoved_i",        k_cmoved_i)
      .Case("cmovedp",         k_cmovedp)
      .Case("cmovedp_i",       k_cmovedp_i)
      .Case("cmoveho",         k_cmoveho)
      .Case("cmoveho_i",       k_cmoveho_i)
      .Case("cmoveq",          k_cmoveq)
      .Case("cmovewq",         k_cmovewq)
      .Case("cmovewq_i",       k_cmovewq_i)
      .Case("crcbellw",        k_crcbellw)
      .Case("crcbellw_i",      k_crcbellw_i)
      .Case("crcbelmw",        k_crcbelmw)
      .Case("crcbelmw_i",      k_crcbelmw_i)
      .Case("crclellw",        k_crclellw)
      .Case("crclellw_i",      k_crclellw_i)
      .Case("crclelmw",        k_crclelmw)
      .Case("crclelmw_i",      k_crclelmw_i)
      .Case("csrrc",           k_csrrc)
      .Case("csrrs",           k_csrrs)
      .Case("csrrw",           k_csrrw)
      .Case("ffmad",           k_ffmad)
      .Case("ffmadp",          k_ffmadp)
      .Case("ffmah",           k_ffmah)
      .Case("ffmaho",          k_ffmaho)
      .Case("ffmaw",           k_ffmaw)
      .Case("ffmawc",          k_ffmawc)
      .Case("ffmawq",          k_ffmawq)
      .Case("ffmsd",           k_ffmsd)
      .Case("ffmsdp",          k_ffmsdp)
      .Case("ffmsh",           k_ffmsh)
      .Case("ffmsho",          k_ffmsho)
      .Case("ffmsw",           k_ffmsw)
      .Case("ffmswq",          k_ffmswq)
      .Case("frcsr",           k_frcsr)
      .Case("frflags",         k_frflags)
      .Case("frrm",            k_frrm)
      .Case("fscsr",           k_fscsr)
      .Case("fsflags",         k_fsflags)
      .Case("fsrm",            k_fsrm)
      .Case("iget",            k_iget)
      .Case("insf",            k_insf)
      .Case("maddd",           k_maddd)
      .Case("maddd_i",         k_maddd_i)
      .Case("madddp",          k_madddp)
      .Case("maddho",          k_maddho)
      .Case("maddw",           k_maddw)
      .Case("maddw_i",         k_maddw_i)
      .Case("maddwq",          k_maddwq)
      .Case("maddxbho",        k_maddxbho)
      .Case("maddxdq",         k_maddxdq)
      .Case("maddxhwq",        k_maddxhwq)
      .Case("maddxwd",         k_maddxwd)
      .Case("maddxwd_i",       k_maddxwd_i)
      .Case("maddxwdp",        k_maddxwdp)
      .Case("msbfd",           k_msbfd)
      .Case("msbfd_i",         k_msbfd_i)
      .Case("msbfdp",          k_msbfdp)
      .Case("msbfho",          k_msbfho)
      .Case("msbfw",           k_msbfw)
      .Case("msbfw_i",         k_msbfw_i)
      .Case("msbfwq",          k_msbfwq)
      .Case("msbfxbho",        k_msbfxbho)
      .Case("msbfxdq",         k_msbfxdq)
      .Case("msbfxhwq",        k_msbfxhwq)
      .Case("msbfxwd",         k_msbfxwd)
      .Case("msbfxwd_i",       k_msbfxwd_i)
      .Case("msbfxwdp",        k_msbfxwdp)
      .Case("rswap",           k_rswap)
      .Case("sbmm8eord",       k_sbmm8eord)
      .Case("sbmm8eord_i",     k_sbmm8eord_i)
      .Case("sbmm8eordp",      k_sbmm8eordp)
      .Case("sbmm8eordp_i",    k_sbmm8eordp_i)
      .Case("sbmmt8eord",      k_sbmmt8eord)
      .Case("sbmmt8eord_i",    k_sbmmt8eord_i)
      .Case("sbmmt8eordp",     k_sbmmt8eordp)
      .Case("sbmmt8eordp_i",   k_sbmmt8eordp_i)
      .Case("waitit",          k_waitit)
      .Default(::llvm::ArrayRef<TiedOperand>());
}

} // namespace lvx
} // namespace mlir

#endif // LVX_TIED_OPERANDS_INC
