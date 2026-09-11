//===-- LVXScheduling.inc - -*- C++ -*- ===//
//
// The processor resources each op reserves.
//
// Generated from the LVX Machine Description System by MDS/BE/MLIR, for core
// lvx_v2.  DO NOT EDIT -- your changes will be overwritten by the next
// `make -C BE/MLIR install`.  Change lvx-mds/lvx-family's YAML description,
// or the generator in MDS/BE/MLIR/BIN, instead.
//
//===----------------------------------------------------------------===//

#ifndef LVX_SCHEDULING_INC
#define LVX_SCHEDULING_INC

namespace mlir {
namespace lvx {

/// A processor resource a bundle provides.  `kResourceAvailability` is how
/// many of each one bundle has; an instruction's reservation says how many it
/// takes.  A bundle is legal when no resource is oversubscribed.
enum class Resource : unsigned {
  issue  = 0,  // Issue slots counted in 32-bit syllables.
  tiny   = 1,  // Tiny ALU function units.
  lite   = 2,  // Lite ALU function units.
  full   = 3,  // Full ALU function units.
  lsu    = 4,  // Load/Store function unit.
  comp   = 5,  // Extension main computational unit.
  bcu    = 6,  // Branch and control unit.
  ext    = 7,  // Extension coprocessor units.
  brrp   = 8,  // BCU register read port.
  auxr   = 9,  // Auxiliary core register read port shared with LSU (256 bits).
  auxw   = 10,  // Auxiliary core register write port shared with LSU (256 bits).
  xfer   = 11,  // Unconditional control-flow transfer.
  memw   = 12,  // Memory write or memory read-modify-write resource.
  misc   = 13,  // Extension miscellaneous execution units.
  accr   = 14,  // Extension compute execution unit addend port.
  outw   = 15,  // Extension miscellaneous execution unit write port.
};

inline constexpr unsigned kNumResources = 16;

inline constexpr ::llvm::StringLiteral kResourceName[kNumResources] = {
  "issue",
  "tiny",
  "lite",
  "full",
  "lsu",
  "comp",
  "bcu",
  "ext",
  "brrp",
  "auxr",
  "auxw",
  "xfer",
  "memw",
  "misc",
  "accr",
  "outw"
};

inline constexpr unsigned kResourceAvailability[kNumResources] = {
  8,  // issue,
  4,  // tiny,
  2,  // lite,
  1,  // full,
  2,  // lsu,
  1,  // comp,
  2,  // bcu,
  4,  // ext,
  2,  // brrp,
  2,  // auxr,
  2,  // auxw,
  1,  // xfer,
  1,  // memw,
  2,  // misc,
  1,  // accr,
  1,  // outw
};

struct ResourceUse {
  Resource resource;
  unsigned count;
};

/// One scheduling class: what it occupies, and the bundling class it implies.
struct Reservation {
  ::llvm::StringLiteral name;
  ::llvm::StringLiteral bundling;
  const ResourceUse *uses;
  unsigned numUses;
};

inline constexpr ResourceUse kUses_ALL[] = {{Resource::issue, 8}};
inline constexpr ResourceUse kUses_ALU_FULL[] = {{Resource::issue, 1}, {Resource::full, 1}, {Resource::lite, 1}, {Resource::tiny, 1}};
inline constexpr ResourceUse kUses_ALU_LITE[] = {{Resource::issue, 1}, {Resource::lite, 1}, {Resource::tiny, 1}};
inline constexpr ResourceUse kUses_ALU_LITE_X[] = {{Resource::issue, 2}, {Resource::lite, 1}, {Resource::tiny, 1}};
inline constexpr ResourceUse kUses_ALU_TINY[] = {{Resource::issue, 1}, {Resource::tiny, 1}};
inline constexpr ResourceUse kUses_ALU_TINY_X[] = {{Resource::issue, 2}, {Resource::tiny, 1}};
inline constexpr ResourceUse kUses_ALU_TINY_Y[] = {{Resource::issue, 3}, {Resource::tiny, 1}};
inline constexpr ResourceUse kUses_BCU2[] = {{Resource::issue, 1}, {Resource::bcu, 2}};
inline constexpr ResourceUse kUses_BCU2_TINY_LSU[] = {{Resource::issue, 1}, {Resource::bcu, 2}, {Resource::tiny, 1}, {Resource::lsu, 1}};
inline constexpr ResourceUse kUses_BCU_BRRP[] = {{Resource::issue, 1}, {Resource::bcu, 1}, {Resource::brrp, 1}};
inline constexpr ResourceUse kUses_BCU_BRRP2[] = {{Resource::issue, 1}, {Resource::bcu, 1}, {Resource::brrp, 2}};
inline constexpr ResourceUse kUses_LSU[] = {{Resource::issue, 1}, {Resource::tiny, 1}, {Resource::lsu, 1}};
inline constexpr ResourceUse kUses_LSU_X[] = {{Resource::issue, 2}, {Resource::tiny, 1}, {Resource::lsu, 1}};
inline constexpr ResourceUse kUses_LSU_Y[] = {{Resource::issue, 3}, {Resource::tiny, 1}, {Resource::lsu, 1}};
inline constexpr ResourceUse kUses_LSU2_MEMW[] = {{Resource::issue, 1}, {Resource::tiny, 1}, {Resource::lsu, 2}, {Resource::memw, 1}};
inline constexpr ResourceUse kUses_LSU2_MEMW_X[] = {{Resource::issue, 2}, {Resource::tiny, 1}, {Resource::lsu, 2}, {Resource::memw, 1}};
inline constexpr ResourceUse kUses_LSU2_MEMW_Y[] = {{Resource::issue, 3}, {Resource::tiny, 1}, {Resource::lsu, 2}, {Resource::memw, 1}};
inline constexpr ResourceUse kUses_LSU2_MEMW_AUXR[] = {{Resource::issue, 1}, {Resource::tiny, 1}, {Resource::lsu, 2}, {Resource::auxr, 1}, {Resource::memw, 1}};
inline constexpr ResourceUse kUses_LSU2_MEMW_AUXR_X[] = {{Resource::issue, 2}, {Resource::tiny, 1}, {Resource::lsu, 2}, {Resource::auxr, 1}, {Resource::memw, 1}};
inline constexpr ResourceUse kUses_LSU2_MEMW_AUXR_Y[] = {{Resource::issue, 3}, {Resource::tiny, 1}, {Resource::lsu, 2}, {Resource::auxr, 1}, {Resource::memw, 1}};
inline constexpr ResourceUse kUses_LSU2_MEMW_AUXR_AUXW[] = {{Resource::issue, 1}, {Resource::tiny, 1}, {Resource::lsu, 2}, {Resource::auxr, 1}, {Resource::auxw, 1}, {Resource::memw, 1}};
inline constexpr ResourceUse kUses_LSU2_MEMW_AUXR_AUXW_X[] = {{Resource::issue, 2}, {Resource::tiny, 1}, {Resource::lsu, 2}, {Resource::auxr, 1}, {Resource::auxw, 1}, {Resource::memw, 1}};
inline constexpr ResourceUse kUses_LSU2_MEMW_AUXR_AUXW_Y[] = {{Resource::issue, 3}, {Resource::tiny, 1}, {Resource::lsu, 2}, {Resource::auxr, 1}, {Resource::auxw, 1}, {Resource::memw, 1}};
inline constexpr ResourceUse kUses_LSU2_MEMW_AUXW[] = {{Resource::issue, 1}, {Resource::tiny, 1}, {Resource::lsu, 2}, {Resource::auxw, 1}, {Resource::memw, 1}};
inline constexpr ResourceUse kUses_LSU2_MEMW_AUXW_X[] = {{Resource::issue, 2}, {Resource::tiny, 1}, {Resource::lsu, 2}, {Resource::auxw, 1}, {Resource::memw, 1}};
inline constexpr ResourceUse kUses_LSU2_MEMW_AUXW_Y[] = {{Resource::issue, 3}, {Resource::tiny, 1}, {Resource::lsu, 2}, {Resource::auxw, 1}, {Resource::memw, 1}};
inline constexpr ResourceUse kUses_LSU_AUXR_AUXW[] = {{Resource::issue, 1}, {Resource::tiny, 1}, {Resource::lsu, 1}, {Resource::auxr, 1}, {Resource::auxw, 1}};
inline constexpr ResourceUse kUses_LSU_AUXW[] = {{Resource::issue, 1}, {Resource::tiny, 1}, {Resource::lsu, 1}, {Resource::auxw, 1}};
inline constexpr ResourceUse kUses_LSU_AUXW_X[] = {{Resource::issue, 2}, {Resource::tiny, 1}, {Resource::lsu, 1}, {Resource::auxw, 1}};
inline constexpr ResourceUse kUses_LSU_AUXW_Y[] = {{Resource::issue, 3}, {Resource::tiny, 1}, {Resource::lsu, 1}, {Resource::auxw, 1}};
inline constexpr ResourceUse kUses_LSU_MEMW_AUXR[] = {{Resource::issue, 1}, {Resource::tiny, 1}, {Resource::lsu, 1}, {Resource::auxr, 1}, {Resource::memw, 1}};
inline constexpr ResourceUse kUses_LSU_MEMW_AUXR_X[] = {{Resource::issue, 2}, {Resource::tiny, 1}, {Resource::lsu, 1}, {Resource::auxr, 1}, {Resource::memw, 1}};
inline constexpr ResourceUse kUses_LSU_MEMW_AUXR_Y[] = {{Resource::issue, 3}, {Resource::tiny, 1}, {Resource::lsu, 1}, {Resource::auxr, 1}, {Resource::memw, 1}};
inline constexpr ResourceUse kUses_LSU_MEMW_AUXW[] = {{Resource::issue, 1}, {Resource::tiny, 1}, {Resource::lsu, 1}, {Resource::auxw, 1}, {Resource::memw, 1}};
inline constexpr ResourceUse kUses_LSU_MEMW_AUXW_X[] = {{Resource::issue, 2}, {Resource::tiny, 1}, {Resource::lsu, 1}, {Resource::auxw, 1}, {Resource::memw, 1}};
inline constexpr ResourceUse kUses_LSU_MEMW_AUXW_Y[] = {{Resource::issue, 3}, {Resource::tiny, 1}, {Resource::lsu, 1}, {Resource::auxw, 1}, {Resource::memw, 1}};

inline constexpr Reservation kR_ALL                      = {"ALL", "ALL", kUses_ALL, 1};
inline constexpr Reservation kR_ALU_FULL                 = {"ALU_FULL", "FULL", kUses_ALU_FULL, 4};
inline constexpr Reservation kR_ALU_LITE                 = {"ALU_LITE", "LITE", kUses_ALU_LITE, 3};
inline constexpr Reservation kR_ALU_LITE_X               = {"ALU_LITE.X", "LITE.X", kUses_ALU_LITE_X, 3};
inline constexpr Reservation kR_ALU_TINY                 = {"ALU_TINY", "TINY", kUses_ALU_TINY, 2};
inline constexpr Reservation kR_ALU_TINY_X               = {"ALU_TINY.X", "TINY.X", kUses_ALU_TINY_X, 2};
inline constexpr Reservation kR_ALU_TINY_Y               = {"ALU_TINY.Y", "TINY.Y", kUses_ALU_TINY_Y, 2};
inline constexpr Reservation kR_BCU2                     = {"BCU2", "BCU2", kUses_BCU2, 2};
inline constexpr Reservation kR_BCU2_TINY_LSU            = {"BCU2_TINY_LSU", "BCU2", kUses_BCU2_TINY_LSU, 4};
inline constexpr Reservation kR_BCU_BRRP                 = {"BCU_BRRP", "BCU", kUses_BCU_BRRP, 3};
inline constexpr Reservation kR_BCU_BRRP2                = {"BCU_BRRP2", "BCU", kUses_BCU_BRRP2, 3};
inline constexpr Reservation kR_LSU                      = {"LSU", "LSU", kUses_LSU, 3};
inline constexpr Reservation kR_LSU_X                    = {"LSU.X", "LSU.X", kUses_LSU_X, 3};
inline constexpr Reservation kR_LSU_Y                    = {"LSU.Y", "LSU.Y", kUses_LSU_Y, 3};
inline constexpr Reservation kR_LSU2_MEMW                = {"LSU2_MEMW", "LSU0", kUses_LSU2_MEMW, 4};
inline constexpr Reservation kR_LSU2_MEMW_X              = {"LSU2_MEMW.X", "LSU0.X", kUses_LSU2_MEMW_X, 4};
inline constexpr Reservation kR_LSU2_MEMW_Y              = {"LSU2_MEMW.Y", "LSU0.Y", kUses_LSU2_MEMW_Y, 4};
inline constexpr Reservation kR_LSU2_MEMW_AUXR           = {"LSU2_MEMW_AUXR", "LSU0", kUses_LSU2_MEMW_AUXR, 5};
inline constexpr Reservation kR_LSU2_MEMW_AUXR_X         = {"LSU2_MEMW_AUXR.X", "LSU0.X", kUses_LSU2_MEMW_AUXR_X, 5};
inline constexpr Reservation kR_LSU2_MEMW_AUXR_Y         = {"LSU2_MEMW_AUXR.Y", "LSU0.Y", kUses_LSU2_MEMW_AUXR_Y, 5};
inline constexpr Reservation kR_LSU2_MEMW_AUXR_AUXW      = {"LSU2_MEMW_AUXR_AUXW", "LSU0", kUses_LSU2_MEMW_AUXR_AUXW, 6};
inline constexpr Reservation kR_LSU2_MEMW_AUXR_AUXW_X    = {"LSU2_MEMW_AUXR_AUXW.X", "LSU0.X", kUses_LSU2_MEMW_AUXR_AUXW_X, 6};
inline constexpr Reservation kR_LSU2_MEMW_AUXR_AUXW_Y    = {"LSU2_MEMW_AUXR_AUXW.Y", "LSU0.Y", kUses_LSU2_MEMW_AUXR_AUXW_Y, 6};
inline constexpr Reservation kR_LSU2_MEMW_AUXW           = {"LSU2_MEMW_AUXW", "LSU0", kUses_LSU2_MEMW_AUXW, 5};
inline constexpr Reservation kR_LSU2_MEMW_AUXW_X         = {"LSU2_MEMW_AUXW.X", "LSU0.X", kUses_LSU2_MEMW_AUXW_X, 5};
inline constexpr Reservation kR_LSU2_MEMW_AUXW_Y         = {"LSU2_MEMW_AUXW.Y", "LSU0.Y", kUses_LSU2_MEMW_AUXW_Y, 5};
inline constexpr Reservation kR_LSU_AUXR_AUXW            = {"LSU_AUXR_AUXW", "LSU", kUses_LSU_AUXR_AUXW, 5};
inline constexpr Reservation kR_LSU_AUXW                 = {"LSU_AUXW", "LSU", kUses_LSU_AUXW, 4};
inline constexpr Reservation kR_LSU_AUXW_X               = {"LSU_AUXW.X", "LSU.X", kUses_LSU_AUXW_X, 4};
inline constexpr Reservation kR_LSU_AUXW_Y               = {"LSU_AUXW.Y", "LSU.Y", kUses_LSU_AUXW_Y, 4};
inline constexpr Reservation kR_LSU_MEMW_AUXR            = {"LSU_MEMW_AUXR", "LSU0", kUses_LSU_MEMW_AUXR, 5};
inline constexpr Reservation kR_LSU_MEMW_AUXR_X          = {"LSU_MEMW_AUXR.X", "LSU0.X", kUses_LSU_MEMW_AUXR_X, 5};
inline constexpr Reservation kR_LSU_MEMW_AUXR_Y          = {"LSU_MEMW_AUXR.Y", "LSU0.Y", kUses_LSU_MEMW_AUXR_Y, 5};
inline constexpr Reservation kR_LSU_MEMW_AUXW            = {"LSU_MEMW_AUXW", "LSU0", kUses_LSU_MEMW_AUXW, 5};
inline constexpr Reservation kR_LSU_MEMW_AUXW_X          = {"LSU_MEMW_AUXW.X", "LSU0.X", kUses_LSU_MEMW_AUXW_X, 5};
inline constexpr Reservation kR_LSU_MEMW_AUXW_Y          = {"LSU_MEMW_AUXW.Y", "LSU0.Y", kUses_LSU_MEMW_AUXW_Y, 5};

inline constexpr Reservation kAllReservations[] = {
  kR_ALL,
  kR_ALU_FULL,
  kR_ALU_LITE,
  kR_ALU_LITE_X,
  kR_ALU_TINY,
  kR_ALU_TINY_X,
  kR_ALU_TINY_Y,
  kR_BCU2,
  kR_BCU2_TINY_LSU,
  kR_BCU_BRRP,
  kR_BCU_BRRP2,
  kR_LSU,
  kR_LSU_X,
  kR_LSU_Y,
  kR_LSU2_MEMW,
  kR_LSU2_MEMW_X,
  kR_LSU2_MEMW_Y,
  kR_LSU2_MEMW_AUXR,
  kR_LSU2_MEMW_AUXR_X,
  kR_LSU2_MEMW_AUXR_Y,
  kR_LSU2_MEMW_AUXR_AUXW,
  kR_LSU2_MEMW_AUXR_AUXW_X,
  kR_LSU2_MEMW_AUXR_AUXW_Y,
  kR_LSU2_MEMW_AUXW,
  kR_LSU2_MEMW_AUXW_X,
  kR_LSU2_MEMW_AUXW_Y,
  kR_LSU_AUXR_AUXW,
  kR_LSU_AUXW,
  kR_LSU_AUXW_X,
  kR_LSU_AUXW_Y,
  kR_LSU_MEMW_AUXR,
  kR_LSU_MEMW_AUXR_X,
  kR_LSU_MEMW_AUXR_Y,
  kR_LSU_MEMW_AUXW,
  kR_LSU_MEMW_AUXW_X,
  kR_LSU_MEMW_AUXW_Y
};
inline constexpr unsigned kNumReservations = 36;

/// The slot an absent `format` attribute uses.
inline constexpr unsigned kBareFormatSlot = 6;

inline constexpr const Reservation *kS_abdbx[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_abdbx_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_abdd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_abdd_i[] = {nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_abddp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_abddp_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_abdho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_abdho_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_abdsbx[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_abdsbx_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_abdsd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_abdsd_i[] = {nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_abdsdp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_abdsdp_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_abdsho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_abdsho_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_abdsw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_abdsw_i[] = {nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_abdswq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_abdswq_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_abdubx[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_abdubx_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_abdud[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_abdud_i[] = {nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_abdudp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_abdudp_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_abduho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_abduho_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_abduw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_abduw_i[] = {nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_abduwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_abduwq_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_abdw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_abdw_i[] = {nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_abdwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_abdwq_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_absbx[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_absd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_absdp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_absho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_abssbx[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_abssd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_abssdp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_abssho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_abssw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_absswq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_absw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_abswq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_acswapb[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR_AUXW};
inline constexpr const Reservation *kS_acswapb_i[] = {&kR_LSU2_MEMW_AUXR_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXR_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_acswapd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR_AUXW};
inline constexpr const Reservation *kS_acswapd_i[] = {&kR_LSU2_MEMW_AUXR_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXR_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_acswaph[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR_AUXW};
inline constexpr const Reservation *kS_acswaph_i[] = {&kR_LSU2_MEMW_AUXR_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXR_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_acswapq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR_AUXW};
inline constexpr const Reservation *kS_acswapq_i[] = {&kR_LSU2_MEMW_AUXR_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXR_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_acswapw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR_AUXW};
inline constexpr const Reservation *kS_acswapw_i[] = {&kR_LSU2_MEMW_AUXR_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXR_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_addbx[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_addbx_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_addd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_addd_i[] = {nullptr, &kR_ALU_TINY_X, nullptr, nullptr, &kR_ALU_TINY_X, &kR_ALU_TINY_Y, &kR_ALU_TINY};
inline constexpr const Reservation *kS_adddp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_adddp_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_addho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_addho_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_addq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_addq_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_addsbx[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_addsbx_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_addsd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_addsd_i[] = {nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_addsdp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_addsdp_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_addsho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_addsho_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_addsw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_addsw_i[] = {nullptr, nullptr, nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_addswq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_addswq_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_addusbx[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_addusbx_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_addusd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_addusd_i[] = {nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_addusdp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_addusdp_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_addusho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_addusho_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_addusw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_addusw_i[] = {nullptr, nullptr, nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_adduswq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_adduswq_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_addw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_addw_i[] = {nullptr, nullptr, nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_addwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_addwq_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_addx16bx[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_addx16bx_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_addx16d[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_addx16d_i[] = {nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_addx16dp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_addx16dp_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_addx16ho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_addx16ho_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_addx16w[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_addx16w_i[] = {nullptr, nullptr, nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_addx16wq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_addx16wq_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_addx2bx[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_addx2bx_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_addx2d[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_addx2d_i[] = {nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_addx2dp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_addx2dp_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_addx2ho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_addx2ho_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_addx2w[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_addx2w_i[] = {nullptr, nullptr, nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_addx2wq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_addx2wq_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_addx32d[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_addx32d_i[] = {nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_addx32w[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_addx32w_i[] = {nullptr, nullptr, nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_addx4bx[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_addx4bx_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_addx4d[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_addx4d_i[] = {nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_addx4dp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_addx4dp_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_addx4ho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_addx4ho_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_addx4w[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_addx4w_i[] = {nullptr, nullptr, nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_addx4wq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_addx4wq_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_addx64d[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_addx64d_i[] = {nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_addx64w[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_addx64w_i[] = {nullptr, nullptr, nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_addx8bx[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_addx8bx_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_addx8d[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_addx8d_i[] = {nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_addx8dp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_addx8dp_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_addx8ho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_addx8ho_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_addx8w[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_addx8w_i[] = {nullptr, nullptr, nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_addx8wq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_addx8wq_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_aladdb[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR_AUXW};
inline constexpr const Reservation *kS_aladdb_i[] = {&kR_LSU2_MEMW_AUXR_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXR_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_aladdd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR_AUXW};
inline constexpr const Reservation *kS_aladdd_i[] = {&kR_LSU2_MEMW_AUXR_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXR_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_aladdh[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR_AUXW};
inline constexpr const Reservation *kS_aladdh_i[] = {&kR_LSU2_MEMW_AUXR_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXR_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_aladdw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR_AUXW};
inline constexpr const Reservation *kS_aladdw_i[] = {&kR_LSU2_MEMW_AUXR_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXR_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_alandb[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR_AUXW};
inline constexpr const Reservation *kS_alandb_i[] = {&kR_LSU2_MEMW_AUXR_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXR_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_alandd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR_AUXW};
inline constexpr const Reservation *kS_alandd_i[] = {&kR_LSU2_MEMW_AUXR_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXR_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_alandh[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR_AUXW};
inline constexpr const Reservation *kS_alandh_i[] = {&kR_LSU2_MEMW_AUXR_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXR_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_alandw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR_AUXW};
inline constexpr const Reservation *kS_alandw_i[] = {&kR_LSU2_MEMW_AUXR_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXR_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_alb[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU_MEMW_AUXW};
inline constexpr const Reservation *kS_alb_i[] = {&kR_LSU_MEMW_AUXW_Y, nullptr, &kR_LSU_MEMW_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_alclrb[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXW};
inline constexpr const Reservation *kS_alclrb_i[] = {&kR_LSU2_MEMW_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_alclrd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXW};
inline constexpr const Reservation *kS_alclrd_i[] = {&kR_LSU2_MEMW_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_alclrh[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXW};
inline constexpr const Reservation *kS_alclrh_i[] = {&kR_LSU2_MEMW_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_alclrw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXW};
inline constexpr const Reservation *kS_alclrw_i[] = {&kR_LSU2_MEMW_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_ald[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU_MEMW_AUXW};
inline constexpr const Reservation *kS_ald_i[] = {&kR_LSU_MEMW_AUXW_Y, nullptr, &kR_LSU_MEMW_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_aldusb[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR_AUXW};
inline constexpr const Reservation *kS_aldusb_i[] = {&kR_LSU2_MEMW_AUXR_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXR_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_aldusd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR_AUXW};
inline constexpr const Reservation *kS_aldusd_i[] = {&kR_LSU2_MEMW_AUXR_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXR_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_aldush[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR_AUXW};
inline constexpr const Reservation *kS_aldush_i[] = {&kR_LSU2_MEMW_AUXR_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXR_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_aldusw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR_AUXW};
inline constexpr const Reservation *kS_aldusw_i[] = {&kR_LSU2_MEMW_AUXR_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXR_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_aleorb[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR_AUXW};
inline constexpr const Reservation *kS_aleorb_i[] = {&kR_LSU2_MEMW_AUXR_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXR_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_aleord[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR_AUXW};
inline constexpr const Reservation *kS_aleord_i[] = {&kR_LSU2_MEMW_AUXR_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXR_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_aleorh[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR_AUXW};
inline constexpr const Reservation *kS_aleorh_i[] = {&kR_LSU2_MEMW_AUXR_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXR_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_aleorw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR_AUXW};
inline constexpr const Reservation *kS_aleorw_i[] = {&kR_LSU2_MEMW_AUXR_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXR_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_alh[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU_MEMW_AUXW};
inline constexpr const Reservation *kS_alh_i[] = {&kR_LSU_MEMW_AUXW_Y, nullptr, &kR_LSU_MEMW_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_aliorb[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR_AUXW};
inline constexpr const Reservation *kS_aliorb_i[] = {&kR_LSU2_MEMW_AUXR_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXR_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_aliord[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR_AUXW};
inline constexpr const Reservation *kS_aliord_i[] = {&kR_LSU2_MEMW_AUXR_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXR_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_aliorh[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR_AUXW};
inline constexpr const Reservation *kS_aliorh_i[] = {&kR_LSU2_MEMW_AUXR_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXR_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_aliorw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR_AUXW};
inline constexpr const Reservation *kS_aliorw_i[] = {&kR_LSU2_MEMW_AUXR_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXR_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_almaxb[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR_AUXW};
inline constexpr const Reservation *kS_almaxb_i[] = {&kR_LSU2_MEMW_AUXR_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXR_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_almaxd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR_AUXW};
inline constexpr const Reservation *kS_almaxd_i[] = {&kR_LSU2_MEMW_AUXR_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXR_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_almaxh[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR_AUXW};
inline constexpr const Reservation *kS_almaxh_i[] = {&kR_LSU2_MEMW_AUXR_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXR_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_almaxub[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR_AUXW};
inline constexpr const Reservation *kS_almaxub_i[] = {&kR_LSU2_MEMW_AUXR_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXR_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_almaxud[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR_AUXW};
inline constexpr const Reservation *kS_almaxud_i[] = {&kR_LSU2_MEMW_AUXR_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXR_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_almaxuh[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR_AUXW};
inline constexpr const Reservation *kS_almaxuh_i[] = {&kR_LSU2_MEMW_AUXR_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXR_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_almaxuw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR_AUXW};
inline constexpr const Reservation *kS_almaxuw_i[] = {&kR_LSU2_MEMW_AUXR_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXR_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_almaxw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR_AUXW};
inline constexpr const Reservation *kS_almaxw_i[] = {&kR_LSU2_MEMW_AUXR_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXR_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_alminb[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR_AUXW};
inline constexpr const Reservation *kS_alminb_i[] = {&kR_LSU2_MEMW_AUXR_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXR_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_almind[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR_AUXW};
inline constexpr const Reservation *kS_almind_i[] = {&kR_LSU2_MEMW_AUXR_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXR_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_alminh[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR_AUXW};
inline constexpr const Reservation *kS_alminh_i[] = {&kR_LSU2_MEMW_AUXR_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXR_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_alminub[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR_AUXW};
inline constexpr const Reservation *kS_alminub_i[] = {&kR_LSU2_MEMW_AUXR_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXR_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_alminud[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR_AUXW};
inline constexpr const Reservation *kS_alminud_i[] = {&kR_LSU2_MEMW_AUXR_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXR_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_alminuh[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR_AUXW};
inline constexpr const Reservation *kS_alminuh_i[] = {&kR_LSU2_MEMW_AUXR_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXR_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_alminuw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR_AUXW};
inline constexpr const Reservation *kS_alminuw_i[] = {&kR_LSU2_MEMW_AUXR_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXR_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_alminw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR_AUXW};
inline constexpr const Reservation *kS_alminw_i[] = {&kR_LSU2_MEMW_AUXR_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXR_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_alw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU_MEMW_AUXW};
inline constexpr const Reservation *kS_alw_i[] = {&kR_LSU_MEMW_AUXW_Y, nullptr, &kR_LSU_MEMW_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_andd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_andd_i[] = {nullptr, &kR_ALU_TINY_X, nullptr, nullptr, &kR_ALU_TINY_X, &kR_ALU_TINY_Y, &kR_ALU_TINY};
inline constexpr const Reservation *kS_andnd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_andnd_i[] = {nullptr, &kR_ALU_TINY_X, nullptr, nullptr, &kR_ALU_TINY_X, &kR_ALU_TINY_Y, &kR_ALU_TINY};
inline constexpr const Reservation *kS_andnq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_andnq_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_andnw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_andnw_i[] = {nullptr, nullptr, nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_andq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_andq_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_andw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_andw_i[] = {nullptr, nullptr, nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_asaddb[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR};
inline constexpr const Reservation *kS_asaddb_i[] = {&kR_LSU2_MEMW_AUXR_Y, nullptr, &kR_LSU2_MEMW_AUXR_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_asaddd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR};
inline constexpr const Reservation *kS_asaddd_i[] = {&kR_LSU2_MEMW_AUXR_Y, nullptr, &kR_LSU2_MEMW_AUXR_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_asaddh[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR};
inline constexpr const Reservation *kS_asaddh_i[] = {&kR_LSU2_MEMW_AUXR_Y, nullptr, &kR_LSU2_MEMW_AUXR_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_asaddw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR};
inline constexpr const Reservation *kS_asaddw_i[] = {&kR_LSU2_MEMW_AUXR_Y, nullptr, &kR_LSU2_MEMW_AUXR_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_asandb[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR};
inline constexpr const Reservation *kS_asandb_i[] = {&kR_LSU2_MEMW_AUXR_Y, nullptr, &kR_LSU2_MEMW_AUXR_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_asandd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR};
inline constexpr const Reservation *kS_asandd_i[] = {&kR_LSU2_MEMW_AUXR_Y, nullptr, &kR_LSU2_MEMW_AUXR_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_asandh[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR};
inline constexpr const Reservation *kS_asandh_i[] = {&kR_LSU2_MEMW_AUXR_Y, nullptr, &kR_LSU2_MEMW_AUXR_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_asandw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR};
inline constexpr const Reservation *kS_asandw_i[] = {&kR_LSU2_MEMW_AUXR_Y, nullptr, &kR_LSU2_MEMW_AUXR_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_asb[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU_MEMW_AUXR};
inline constexpr const Reservation *kS_asb_i[] = {&kR_LSU_MEMW_AUXR_Y, nullptr, &kR_LSU_MEMW_AUXR_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_asd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU_MEMW_AUXR};
inline constexpr const Reservation *kS_asd_i[] = {&kR_LSU_MEMW_AUXR_Y, nullptr, &kR_LSU_MEMW_AUXR_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_asdusb[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR};
inline constexpr const Reservation *kS_asdusb_i[] = {&kR_LSU2_MEMW_AUXR_Y, nullptr, &kR_LSU2_MEMW_AUXR_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_asdusd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR};
inline constexpr const Reservation *kS_asdusd_i[] = {&kR_LSU2_MEMW_AUXR_Y, nullptr, &kR_LSU2_MEMW_AUXR_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_asdush[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR};
inline constexpr const Reservation *kS_asdush_i[] = {&kR_LSU2_MEMW_AUXR_Y, nullptr, &kR_LSU2_MEMW_AUXR_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_asdusw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR};
inline constexpr const Reservation *kS_asdusw_i[] = {&kR_LSU2_MEMW_AUXR_Y, nullptr, &kR_LSU2_MEMW_AUXR_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_aseorb[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR};
inline constexpr const Reservation *kS_aseorb_i[] = {&kR_LSU2_MEMW_AUXR_Y, nullptr, &kR_LSU2_MEMW_AUXR_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_aseord[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR};
inline constexpr const Reservation *kS_aseord_i[] = {&kR_LSU2_MEMW_AUXR_Y, nullptr, &kR_LSU2_MEMW_AUXR_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_aseorh[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR};
inline constexpr const Reservation *kS_aseorh_i[] = {&kR_LSU2_MEMW_AUXR_Y, nullptr, &kR_LSU2_MEMW_AUXR_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_aseorw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR};
inline constexpr const Reservation *kS_aseorw_i[] = {&kR_LSU2_MEMW_AUXR_Y, nullptr, &kR_LSU2_MEMW_AUXR_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_ash[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU_MEMW_AUXR};
inline constexpr const Reservation *kS_ash_i[] = {&kR_LSU_MEMW_AUXR_Y, nullptr, &kR_LSU_MEMW_AUXR_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_asiorb[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR};
inline constexpr const Reservation *kS_asiorb_i[] = {&kR_LSU2_MEMW_AUXR_Y, nullptr, &kR_LSU2_MEMW_AUXR_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_asiord[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR};
inline constexpr const Reservation *kS_asiord_i[] = {&kR_LSU2_MEMW_AUXR_Y, nullptr, &kR_LSU2_MEMW_AUXR_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_asiorh[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR};
inline constexpr const Reservation *kS_asiorh_i[] = {&kR_LSU2_MEMW_AUXR_Y, nullptr, &kR_LSU2_MEMW_AUXR_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_asiorw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR};
inline constexpr const Reservation *kS_asiorw_i[] = {&kR_LSU2_MEMW_AUXR_Y, nullptr, &kR_LSU2_MEMW_AUXR_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_asmaxb[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR};
inline constexpr const Reservation *kS_asmaxb_i[] = {&kR_LSU2_MEMW_AUXR_Y, nullptr, &kR_LSU2_MEMW_AUXR_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_asmaxd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR};
inline constexpr const Reservation *kS_asmaxd_i[] = {&kR_LSU2_MEMW_AUXR_Y, nullptr, &kR_LSU2_MEMW_AUXR_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_asmaxh[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR};
inline constexpr const Reservation *kS_asmaxh_i[] = {&kR_LSU2_MEMW_AUXR_Y, nullptr, &kR_LSU2_MEMW_AUXR_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_asmaxub[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR};
inline constexpr const Reservation *kS_asmaxub_i[] = {&kR_LSU2_MEMW_AUXR_Y, nullptr, &kR_LSU2_MEMW_AUXR_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_asmaxud[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR};
inline constexpr const Reservation *kS_asmaxud_i[] = {&kR_LSU2_MEMW_AUXR_Y, nullptr, &kR_LSU2_MEMW_AUXR_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_asmaxuh[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR};
inline constexpr const Reservation *kS_asmaxuh_i[] = {&kR_LSU2_MEMW_AUXR_Y, nullptr, &kR_LSU2_MEMW_AUXR_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_asmaxuw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR};
inline constexpr const Reservation *kS_asmaxuw_i[] = {&kR_LSU2_MEMW_AUXR_Y, nullptr, &kR_LSU2_MEMW_AUXR_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_asmaxw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR};
inline constexpr const Reservation *kS_asmaxw_i[] = {&kR_LSU2_MEMW_AUXR_Y, nullptr, &kR_LSU2_MEMW_AUXR_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_asminb[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR};
inline constexpr const Reservation *kS_asminb_i[] = {&kR_LSU2_MEMW_AUXR_Y, nullptr, &kR_LSU2_MEMW_AUXR_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_asmind[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR};
inline constexpr const Reservation *kS_asmind_i[] = {&kR_LSU2_MEMW_AUXR_Y, nullptr, &kR_LSU2_MEMW_AUXR_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_asminh[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR};
inline constexpr const Reservation *kS_asminh_i[] = {&kR_LSU2_MEMW_AUXR_Y, nullptr, &kR_LSU2_MEMW_AUXR_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_asminub[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR};
inline constexpr const Reservation *kS_asminub_i[] = {&kR_LSU2_MEMW_AUXR_Y, nullptr, &kR_LSU2_MEMW_AUXR_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_asminud[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR};
inline constexpr const Reservation *kS_asminud_i[] = {&kR_LSU2_MEMW_AUXR_Y, nullptr, &kR_LSU2_MEMW_AUXR_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_asminuh[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR};
inline constexpr const Reservation *kS_asminuh_i[] = {&kR_LSU2_MEMW_AUXR_Y, nullptr, &kR_LSU2_MEMW_AUXR_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_asminuw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR};
inline constexpr const Reservation *kS_asminuw_i[] = {&kR_LSU2_MEMW_AUXR_Y, nullptr, &kR_LSU2_MEMW_AUXR_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_asminw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR};
inline constexpr const Reservation *kS_asminw_i[] = {&kR_LSU2_MEMW_AUXR_Y, nullptr, &kR_LSU2_MEMW_AUXR_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_asw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU_MEMW_AUXR};
inline constexpr const Reservation *kS_asw_i[] = {&kR_LSU_MEMW_AUXR_Y, nullptr, &kR_LSU_MEMW_AUXR_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_aswapb[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR_AUXW};
inline constexpr const Reservation *kS_aswapb_i[] = {&kR_LSU2_MEMW_AUXR_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXR_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_aswapd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR_AUXW};
inline constexpr const Reservation *kS_aswapd_i[] = {&kR_LSU2_MEMW_AUXR_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXR_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_aswaph[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR_AUXW};
inline constexpr const Reservation *kS_aswaph_i[] = {&kR_LSU2_MEMW_AUXR_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXR_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_aswapw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_AUXR_AUXW};
inline constexpr const Reservation *kS_aswapw_i[] = {&kR_LSU2_MEMW_AUXR_AUXW_Y, nullptr, &kR_LSU2_MEMW_AUXR_AUXW_X, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_avgbx[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_avgbx_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_avgho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_avgho_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_avgrbx[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_avgrbx_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_avgrho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_avgrho_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_avgrubx[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_avgrubx_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_avgruho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_avgruho_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_avgruw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_avgruw_i[] = {nullptr, nullptr, nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_avgruwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_avgruwq_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_avgrw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_avgrw_i[] = {nullptr, nullptr, nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_avgrwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_avgrwq_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_avgubx[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_avgubx_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_avguho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_avguho_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_avguw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_avguw_i[] = {nullptr, nullptr, nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_avguwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_avguwq_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_avgw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_avgw_i[] = {nullptr, nullptr, nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_avgwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_avgwq_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_await[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALL};
inline constexpr const Reservation *kS_barrier[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALL};
inline constexpr const Reservation *kS_blend[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_BCU_BRRP};
inline constexpr const Reservation *kS_break[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALL};
inline constexpr const Reservation *kS_catdq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_cbsd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_cbsdp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_cbsho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_cbsw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_cbswq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_clsd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_clsdp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_clsho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_clsw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_clswq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_clzd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_clzdp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_clzho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_clzw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_clzwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_cmovebx[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_cmovebx_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_cmoved[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_cmoved_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_cmovedp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_cmovedp_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_cmoveho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_cmoveho_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_cmoveq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_cmovewq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_cmovewq_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_compbx[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_compbx_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_compd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_compd_i[] = {nullptr, nullptr, nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_compdp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_compdp_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_compho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_compho_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_compnbx[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_compnbx_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_compndp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_compndp_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_compnho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_compnho_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_compnwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_compnwq_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_compq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_compw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_compw_i[] = {nullptr, nullptr, nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_compwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_compwq_i[] = {nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_copyd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_copyo[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU_AUXR_AUXW};
inline constexpr const Reservation *kS_copyq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_copyw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_crcbellw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_crcbellw_i[] = {nullptr, nullptr, nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_crcbelmw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_crcbelmw_i[] = {nullptr, nullptr, nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_crclellw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_crclellw_i[] = {nullptr, nullptr, nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_crclelmw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_crclelmw_i[] = {nullptr, nullptr, nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_csrrc[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_BCU2_TINY_LSU};
inline constexpr const Reservation *kS_csrrs[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_BCU2_TINY_LSU};
inline constexpr const Reservation *kS_csrrw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_BCU2_TINY_LSU};
inline constexpr const Reservation *kS_ctzd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_ctzdp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_ctzho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_ctzw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_ctzwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_d1inval[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW};
inline constexpr const Reservation *kS_dflushl[] = {nullptr, nullptr, nullptr, nullptr, &kR_LSU_X, &kR_LSU_Y, &kR_LSU};
inline constexpr const Reservation *kS_dflushl_r[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU};
inline constexpr const Reservation *kS_dflushsw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW};
inline constexpr const Reservation *kS_dinvall[] = {nullptr, nullptr, nullptr, nullptr, &kR_LSU_X, &kR_LSU_Y, &kR_LSU};
inline constexpr const Reservation *kS_dinvall_r[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU};
inline constexpr const Reservation *kS_dinvalsw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW};
inline constexpr const Reservation *kS_divmodd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_FULL};
inline constexpr const Reservation *kS_divmodud[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_FULL};
inline constexpr const Reservation *kS_divmoduw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_FULL};
inline constexpr const Reservation *kS_divmodw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_FULL};
inline constexpr const Reservation *kS_dpurgel[] = {nullptr, nullptr, nullptr, nullptr, &kR_LSU_X, &kR_LSU_Y, &kR_LSU};
inline constexpr const Reservation *kS_dpurgel_r[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU};
inline constexpr const Reservation *kS_dpurgesw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW};
inline constexpr const Reservation *kS_dtouchl[] = {nullptr, nullptr, nullptr, nullptr, &kR_LSU_X, &kR_LSU_Y, &kR_LSU};
inline constexpr const Reservation *kS_dtouchl_r[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU};
inline constexpr const Reservation *kS_eord[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_eord_i[] = {nullptr, &kR_ALU_TINY_X, nullptr, nullptr, &kR_ALU_TINY_X, &kR_ALU_TINY_Y, &kR_ALU_TINY};
inline constexpr const Reservation *kS_eorq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_eorq_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_eorw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_eorw_i[] = {nullptr, nullptr, nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_errop[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_BCU_BRRP2};
inline constexpr const Reservation *kS_extfs[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_extfz[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_extlqbho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_extlqhwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_extlqnbx[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_extlqwdp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_extlsbho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_extlshwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_extlsnbx[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_extlswdp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_extlzbho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_extlzhwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_extlznbx[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_extlzwdp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fabsd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fabsdp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fabsh[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fabsho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fabsw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fabswp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fabswq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_faddd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fadddp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_faddh[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_faddho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_faddw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_faddwc[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_faddwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fclassd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fclassdp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fclassh[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fclassho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fclassw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fclasswp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fclasswq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fcompd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fcompd_i[] = {nullptr, nullptr, nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_fcompdp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fcompdp_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_fcomph[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fcomph_i[] = {nullptr, nullptr, nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_fcompho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fcompho_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_fcompndp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fcompndp_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_fcompnho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fcompnho_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_fcompnwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fcompnwq_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_fcompw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fcompw_i[] = {nullptr, nullptr, nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_fcompwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fcompwq_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_fdivd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_FULL};
inline constexpr const Reservation *kS_fdivh[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_FULL};
inline constexpr const Reservation *kS_fdivw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_FULL};
inline constexpr const Reservation *kS_fence[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW};
inline constexpr const Reservation *kS_fextlhwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_ffmad[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_ffmadp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_ffmah[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_ffmaho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_ffmaw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_ffmawc[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_ffmawq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_ffmsd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_ffmsdp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_ffmsh[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_ffmsho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_ffmsw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_ffmswq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fixedd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fixeddp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fixeddw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fixedho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fixedud[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fixedudp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fixedudw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fixeduho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fixeduw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fixeduwd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fixeduwp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fixeduwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fixedw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fixedwd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fixedwp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fixedwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_floatd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_floatdp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_floatdw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_floatho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_floatud[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_floatudp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_floatudw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_floatuho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_floatuw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_floatuwd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_floatuwp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_floatuwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_floatw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_floatwd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_floatwp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_floatwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fmaxd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fmaxdp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fmaxh[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fmaxho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fmaxnd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fmaxndp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fmaxnh[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fmaxnho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fmaxnw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fmaxnwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fmaxw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fmaxwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fmind[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fmindp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fminh[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fminho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fminnd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fminndp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fminnh[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fminnho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fminnw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fminnwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fminw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fminwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fmuld[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fmuldp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fmulh[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fmulho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fmulw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fmulwc[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fmulwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fnarrowdw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fnarrowdwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fnarrowwh[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fnarrowwho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fnegd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fnegdp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fnegh[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fnegho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fnegw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fnegwp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fnegwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fractdwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fracthbx[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fractwho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_frcsr[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_BCU2_TINY_LSU};
inline constexpr const Reservation *kS_frflags[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_BCU2_TINY_LSU};
inline constexpr const Reservation *kS_frintd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_frinth[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_frintw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_frrm[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_BCU2_TINY_LSU};
inline constexpr const Reservation *kS_fsbfd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fsbfdp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fsbfh[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fsbfho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fsbfw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fsbfwc[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fsbfwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fscsr[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_BCU2_TINY_LSU};
inline constexpr const Reservation *kS_fsflags[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_BCU2_TINY_LSU};
inline constexpr const Reservation *kS_fsignd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fsigndp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fsignh[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fsignho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fsignmd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fsignmdp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fsignmh[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fsignmho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fsignmw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fsignmwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fsignnd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fsignndp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fsignnh[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fsignnho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fsignnw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fsignnwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fsignw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fsignwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fsqrtd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_FULL};
inline constexpr const Reservation *kS_fsqrth[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_FULL};
inline constexpr const Reservation *kS_fsqrtw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_FULL};
inline constexpr const Reservation *kS_fsrecd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fsrecw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fsrecwp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fsrecwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fsrm[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_BCU2_TINY_LSU};
inline constexpr const Reservation *kS_fsrsrd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fsrsrw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fsrsrwp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fsrsrwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fwidenhw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fwidenhwp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fwidenhwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fwidenwd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_fwidenwdp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_get[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_BCU2_TINY_LSU};
inline constexpr const Reservation *kS_guard[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_BCU_BRRP};
inline constexpr const Reservation *kS_i1inval[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW};
inline constexpr const Reservation *kS_i1invals[] = {nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW_X, &kR_LSU2_MEMW_Y, &kR_LSU2_MEMW};
inline constexpr const Reservation *kS_i1invals_r[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU2_MEMW};
inline constexpr const Reservation *kS_iget[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_BCU2_TINY_LSU};
inline constexpr const Reservation *kS_insf[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_iord[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_iord_i[] = {nullptr, &kR_ALU_TINY_X, nullptr, nullptr, &kR_ALU_TINY_X, &kR_ALU_TINY_Y, &kR_ALU_TINY};
inline constexpr const Reservation *kS_iornd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_iornd_i[] = {nullptr, &kR_ALU_TINY_X, nullptr, nullptr, &kR_ALU_TINY_X, &kR_ALU_TINY_Y, &kR_ALU_TINY};
inline constexpr const Reservation *kS_iornq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_iornq_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_iornw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_iornw_i[] = {nullptr, nullptr, nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_iorq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_iorq_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_iorw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_iorw_i[] = {nullptr, nullptr, nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_landd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_landw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_lbs[] = {nullptr, nullptr, nullptr, nullptr, &kR_LSU_AUXW_X, &kR_LSU_AUXW_Y, &kR_LSU_AUXW};
inline constexpr const Reservation *kS_lbs_r[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU_AUXW};
inline constexpr const Reservation *kS_lbz[] = {nullptr, nullptr, nullptr, nullptr, &kR_LSU_AUXW_X, &kR_LSU_AUXW_Y, &kR_LSU_AUXW};
inline constexpr const Reservation *kS_lbz_r[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU_AUXW};
inline constexpr const Reservation *kS_ld[] = {nullptr, nullptr, nullptr, nullptr, &kR_LSU_AUXW_X, &kR_LSU_AUXW_Y, &kR_LSU_AUXW};
inline constexpr const Reservation *kS_ld_r[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU_AUXW};
inline constexpr const Reservation *kS_lhs[] = {nullptr, nullptr, nullptr, nullptr, &kR_LSU_AUXW_X, &kR_LSU_AUXW_Y, &kR_LSU_AUXW};
inline constexpr const Reservation *kS_lhs_r[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU_AUXW};
inline constexpr const Reservation *kS_lhz[] = {nullptr, nullptr, nullptr, nullptr, &kR_LSU_AUXW_X, &kR_LSU_AUXW_Y, &kR_LSU_AUXW};
inline constexpr const Reservation *kS_lhz_r[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU_AUXW};
inline constexpr const Reservation *kS_liord[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_liorw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_lnandd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_lnandw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_lniord[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_lniorw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_lo[] = {nullptr, nullptr, nullptr, nullptr, &kR_LSU_AUXW_X, &kR_LSU_AUXW_Y, &kR_LSU_AUXW};
inline constexpr const Reservation *kS_lo_r[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU_AUXW};
inline constexpr const Reservation *kS_lq[] = {nullptr, nullptr, nullptr, nullptr, &kR_LSU_AUXW_X, &kR_LSU_AUXW_Y, &kR_LSU_AUXW};
inline constexpr const Reservation *kS_lq_r[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU_AUXW};
inline constexpr const Reservation *kS_lws[] = {nullptr, nullptr, nullptr, nullptr, &kR_LSU_AUXW_X, &kR_LSU_AUXW_Y, &kR_LSU_AUXW};
inline constexpr const Reservation *kS_lws_r[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU_AUXW};
inline constexpr const Reservation *kS_lwz[] = {nullptr, nullptr, nullptr, nullptr, &kR_LSU_AUXW_X, &kR_LSU_AUXW_Y, &kR_LSU_AUXW};
inline constexpr const Reservation *kS_lwz_r[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU_AUXW};
inline constexpr const Reservation *kS_maddd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_maddd_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_madddp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_maddho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_maddw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_maddw_i[] = {nullptr, nullptr, nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_maddwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_maddxbho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_maddxdq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_maddxhwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_maddxwd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_maddxwd_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_maddxwdp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_maked[] = {nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY_X, &kR_ALU_TINY_Y, &kR_ALU_TINY};
inline constexpr const Reservation *kS_maxbx[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_maxbx_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_maxd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_maxd_i[] = {nullptr, &kR_ALU_TINY_X, nullptr, nullptr, &kR_ALU_TINY_X, &kR_ALU_TINY_Y, &kR_ALU_TINY};
inline constexpr const Reservation *kS_maxdp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_maxdp_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_maxho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_maxho_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_maxubx[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_maxubx_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_maxud[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_maxud_i[] = {nullptr, &kR_ALU_TINY_X, nullptr, nullptr, &kR_ALU_TINY_X, &kR_ALU_TINY_Y, &kR_ALU_TINY};
inline constexpr const Reservation *kS_maxudp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_maxudp_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_maxuho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_maxuho_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_maxuw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_maxuw_i[] = {nullptr, nullptr, nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_maxuwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_maxuwq_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_maxw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_maxw_i[] = {nullptr, nullptr, nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_maxwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_maxwq_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_minbx[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_minbx_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_mind[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_mind_i[] = {nullptr, &kR_ALU_TINY_X, nullptr, nullptr, &kR_ALU_TINY_X, &kR_ALU_TINY_Y, &kR_ALU_TINY};
inline constexpr const Reservation *kS_mindp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_mindp_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_minho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_minho_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_minubx[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_minubx_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_minud[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_minud_i[] = {nullptr, &kR_ALU_TINY_X, nullptr, nullptr, &kR_ALU_TINY_X, &kR_ALU_TINY_Y, &kR_ALU_TINY};
inline constexpr const Reservation *kS_minudp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_minudp_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_minuho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_minuho_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_minuw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_minuw_i[] = {nullptr, nullptr, nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_minuwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_minuwq_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_minw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_minw_i[] = {nullptr, nullptr, nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_minwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_minwq_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_msbfd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_msbfd_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_msbfdp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_msbfho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_msbfw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_msbfw_i[] = {nullptr, nullptr, nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_msbfwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_msbfxbho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_msbfxdq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_msbfxhwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_msbfxwd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_msbfxwd_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_msbfxwdp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_muld[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_muld_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_muldp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_mulho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_mulnd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_mulnd_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_mulndp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_mulnho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_mulnw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_mulnw_i[] = {nullptr, nullptr, nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_mulnwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_mulnxbho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_mulnxdq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_mulnxhwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_mulnxwd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_mulnxwd_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_mulnxwdp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_mulw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_mulw_i[] = {nullptr, nullptr, nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_mulwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_mulxbho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_mulxdq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_mulxhwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_mulxwd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_mulxwd_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_mulxwdp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_nandd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_nandd_i[] = {nullptr, &kR_ALU_TINY_X, nullptr, nullptr, &kR_ALU_TINY_X, &kR_ALU_TINY_Y, &kR_ALU_TINY};
inline constexpr const Reservation *kS_nandq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_nandq_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_nandw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_nandw_i[] = {nullptr, nullptr, nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_negbx[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_negd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_negdp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_negho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_negq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_negsbx[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_negsd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_negsdp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_negsho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_negsw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_negswq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_negw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_negwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_neord[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_neord_i[] = {nullptr, &kR_ALU_TINY_X, nullptr, nullptr, &kR_ALU_TINY_X, &kR_ALU_TINY_Y, &kR_ALU_TINY};
inline constexpr const Reservation *kS_neorq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_neorq_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_neorw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_neorw_i[] = {nullptr, nullptr, nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_niord[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_niord_i[] = {nullptr, &kR_ALU_TINY_X, nullptr, nullptr, &kR_ALU_TINY_X, &kR_ALU_TINY_Y, &kR_ALU_TINY};
inline constexpr const Reservation *kS_niorq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_niorq_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_niorw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_niorw_i[] = {nullptr, nullptr, nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_nop[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_notd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_notq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_notw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_pcrel[] = {nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY_X, &kR_ALU_TINY_Y, &kR_ALU_TINY};
inline constexpr const Reservation *kS_rfe[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALL};
inline constexpr const Reservation *kS_rold[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_rold_i[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_rolw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_rolw_i[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_rolwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_rolwq_i[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_rord[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_rord_i[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_rorw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_rorw_i[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_rorwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_rorwq_i[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_rswap[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_BCU2_TINY_LSU};
inline constexpr const Reservation *kS_sb[] = {nullptr, nullptr, nullptr, nullptr, &kR_LSU_MEMW_AUXR_X, &kR_LSU_MEMW_AUXR_Y, &kR_LSU_MEMW_AUXR};
inline constexpr const Reservation *kS_sb_r[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU_MEMW_AUXR};
inline constexpr const Reservation *kS_sbfbx[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_sbfbx_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_sbfd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_sbfd_i[] = {nullptr, &kR_ALU_TINY_X, nullptr, nullptr, &kR_ALU_TINY_X, &kR_ALU_TINY_Y, &kR_ALU_TINY};
inline constexpr const Reservation *kS_sbfdp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_sbfdp_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_sbfho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_sbfho_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_sbfq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_sbfq_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_sbfsbx[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_sbfsbx_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_sbfsd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_sbfsd_i[] = {nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_sbfsdp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_sbfsdp_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_sbfsho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_sbfsho_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_sbfsw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_sbfsw_i[] = {nullptr, nullptr, nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_sbfswq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_sbfswq_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_sbfusbx[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_sbfusbx_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_sbfusd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_sbfusd_i[] = {nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_sbfusdp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_sbfusdp_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_sbfusho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_sbfusho_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_sbfusw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_sbfusw_i[] = {nullptr, nullptr, nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_sbfuswq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_sbfuswq_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_sbfw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_sbfw_i[] = {nullptr, nullptr, nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_sbfwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_sbfwq_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_sbmm8[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_sbmm8_i[] = {nullptr, &kR_ALU_TINY_X, nullptr, nullptr, &kR_ALU_TINY_X, &kR_ALU_TINY_Y, &kR_ALU_TINY};
inline constexpr const Reservation *kS_sbmm8d[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_sbmm8d_i[] = {nullptr, &kR_ALU_TINY_X, nullptr, nullptr, &kR_ALU_TINY_X, &kR_ALU_TINY_Y, &kR_ALU_TINY};
inline constexpr const Reservation *kS_sbmm8dp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_sbmm8dp_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_sbmm8eord[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_sbmm8eord_i[] = {nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_sbmm8eordp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_sbmm8eordp_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_sbmmt8[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_sbmmt8_i[] = {nullptr, &kR_ALU_TINY_X, nullptr, nullptr, &kR_ALU_TINY_X, &kR_ALU_TINY_Y, &kR_ALU_TINY};
inline constexpr const Reservation *kS_sbmmt8d[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_sbmmt8d_i[] = {nullptr, &kR_ALU_TINY_X, nullptr, nullptr, &kR_ALU_TINY_X, &kR_ALU_TINY_Y, &kR_ALU_TINY};
inline constexpr const Reservation *kS_sbmmt8dp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_sbmmt8dp_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_sbmmt8eord[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_sbmmt8eord_i[] = {nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_sbmmt8eordp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_sbmmt8eordp_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_scall[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALL};
inline constexpr const Reservation *kS_scall_i[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALL};
inline constexpr const Reservation *kS_sd[] = {nullptr, nullptr, nullptr, nullptr, &kR_LSU_MEMW_AUXR_X, &kR_LSU_MEMW_AUXR_Y, &kR_LSU_MEMW_AUXR};
inline constexpr const Reservation *kS_sd_r[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU_MEMW_AUXR};
inline constexpr const Reservation *kS_set[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_BCU2};
inline constexpr const Reservation *kS_sh[] = {nullptr, nullptr, nullptr, nullptr, &kR_LSU_MEMW_AUXR_X, &kR_LSU_MEMW_AUXR_Y, &kR_LSU_MEMW_AUXR};
inline constexpr const Reservation *kS_sh_r[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU_MEMW_AUXR};
inline constexpr const Reservation *kS_signbx[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_signbx_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_signd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_signd_i[] = {nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_signdp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_signdp_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_signho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_signho_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_signsbx[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_signsbx_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_signsd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_signsd_i[] = {nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_signsdp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_signsdp_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_signsho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_signsho_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_signsw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_signsw_i[] = {nullptr, nullptr, nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_signswq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_signswq_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_signw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_signw_i[] = {nullptr, nullptr, nullptr, &kR_ALU_TINY_X, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_signwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_signwq_i[] = {nullptr, &kR_ALU_LITE_X, nullptr, nullptr, nullptr, nullptr, nullptr};
inline constexpr const Reservation *kS_sleep[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALL};
inline constexpr const Reservation *kS_sllbx[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_sllbx_i[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_slld[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_slld_i[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_slldp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_slldp_i[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_sllho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_sllho_i[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_sllw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_sllw_i[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_sllwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_sllwq_i[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_slsbx[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_slsbx_i[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_slsd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_slsd_i[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_slsdp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_slsdp_i[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_slsho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_slsho_i[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_slsw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_slsw_i[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_slswq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_slswq_i[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_slusbx[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_slusbx_i[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_slusd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_slusd_i[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_slusdp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_slusdp_i[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_slusho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_slusho_i[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_slusw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_slusw_i[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_sluswq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_sluswq_i[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_so[] = {nullptr, nullptr, nullptr, nullptr, &kR_LSU_MEMW_AUXR_X, &kR_LSU_MEMW_AUXR_Y, &kR_LSU_MEMW_AUXR};
inline constexpr const Reservation *kS_so_r[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU_MEMW_AUXR};
inline constexpr const Reservation *kS_splatbq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_splatdq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_splathq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_splatwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_sq[] = {nullptr, nullptr, nullptr, nullptr, &kR_LSU_MEMW_AUXR_X, &kR_LSU_MEMW_AUXR_Y, &kR_LSU_MEMW_AUXR};
inline constexpr const Reservation *kS_sq_r[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU_MEMW_AUXR};
inline constexpr const Reservation *kS_srabx[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_srabx_i[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_srad[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_srad_i[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_sradp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_sradp_i[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_sraho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_sraho_i[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_sraw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_sraw_i[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_srawq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_srawq_i[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_srlbx[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_srlbx_i[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_srld[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_srld_i[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_srldp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_srldp_i[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_srlho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_srlho_i[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_srlw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_srlw_i[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_srlwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_srlwq_i[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_srsbx[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_srsbx_i[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_srsd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_srsd_i[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_srsdp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_srsdp_i[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_srsho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_srsho_i[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_srsw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_srsw_i[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_srswq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_srswq_i[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_stop[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALL};
inline constexpr const Reservation *kS_stsud[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_stsudp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_stsuho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_stsuw[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_stsuwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_sw[] = {nullptr, nullptr, nullptr, nullptr, &kR_LSU_MEMW_AUXR_X, &kR_LSU_MEMW_AUXR_Y, &kR_LSU_MEMW_AUXR};
inline constexpr const Reservation *kS_sw_r[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_LSU_MEMW_AUXR};
inline constexpr const Reservation *kS_sxbd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_sxhd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_sxwd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_syncgroup[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_BCU2};
inline constexpr const Reservation *kS_tlbdinval[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALL};
inline constexpr const Reservation *kS_tlbiinval[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALL};
inline constexpr const Reservation *kS_tlbprobe[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALL};
inline constexpr const Reservation *kS_tlbread[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALL};
inline constexpr const Reservation *kS_tlbwrite[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALL};
inline constexpr const Reservation *kS_truncdwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_trunchbx[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_truncwho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_waitit[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_BCU2_TINY_LSU};
inline constexpr const Reservation *kS_wfxl[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_BCU2};
inline constexpr const Reservation *kS_wfxm[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_BCU2};
inline constexpr const Reservation *kS_widenqbho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_widenqhwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_widenqwdp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_widensbho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_widenshwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_widenswdp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_widenzbho[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_widenzhwq[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_widenzwdp[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_LITE};
inline constexpr const Reservation *kS_zxbd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_zxhd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};
inline constexpr const Reservation *kS_zxwd[] = {nullptr, nullptr, nullptr, nullptr, nullptr, nullptr, &kR_ALU_TINY};

/// What `mnemonic` reserves in `format`, or null where the description states
/// no scheduling class for that pairing -- which is every pseudo-op, none of
/// which is a real instruction with a slot to occupy.
inline const Reservation *reservationOf(::llvm::StringRef mnemonic,
                                        ::std::optional<Format> format) {
  const Reservation *const *row =
      ::llvm::StringSwitch<const Reservation *const *>(mnemonic)
          .Case("abdbx",           kS_abdbx)
          .Case("abdbx_i",         kS_abdbx_i)
          .Case("abdd",            kS_abdd)
          .Case("abdd_i",          kS_abdd_i)
          .Case("abddp",           kS_abddp)
          .Case("abddp_i",         kS_abddp_i)
          .Case("abdho",           kS_abdho)
          .Case("abdho_i",         kS_abdho_i)
          .Case("abdsbx",          kS_abdsbx)
          .Case("abdsbx_i",        kS_abdsbx_i)
          .Case("abdsd",           kS_abdsd)
          .Case("abdsd_i",         kS_abdsd_i)
          .Case("abdsdp",          kS_abdsdp)
          .Case("abdsdp_i",        kS_abdsdp_i)
          .Case("abdsho",          kS_abdsho)
          .Case("abdsho_i",        kS_abdsho_i)
          .Case("abdsw",           kS_abdsw)
          .Case("abdsw_i",         kS_abdsw_i)
          .Case("abdswq",          kS_abdswq)
          .Case("abdswq_i",        kS_abdswq_i)
          .Case("abdubx",          kS_abdubx)
          .Case("abdubx_i",        kS_abdubx_i)
          .Case("abdud",           kS_abdud)
          .Case("abdud_i",         kS_abdud_i)
          .Case("abdudp",          kS_abdudp)
          .Case("abdudp_i",        kS_abdudp_i)
          .Case("abduho",          kS_abduho)
          .Case("abduho_i",        kS_abduho_i)
          .Case("abduw",           kS_abduw)
          .Case("abduw_i",         kS_abduw_i)
          .Case("abduwq",          kS_abduwq)
          .Case("abduwq_i",        kS_abduwq_i)
          .Case("abdw",            kS_abdw)
          .Case("abdw_i",          kS_abdw_i)
          .Case("abdwq",           kS_abdwq)
          .Case("abdwq_i",         kS_abdwq_i)
          .Case("absbx",           kS_absbx)
          .Case("absd",            kS_absd)
          .Case("absdp",           kS_absdp)
          .Case("absho",           kS_absho)
          .Case("abssbx",          kS_abssbx)
          .Case("abssd",           kS_abssd)
          .Case("abssdp",          kS_abssdp)
          .Case("abssho",          kS_abssho)
          .Case("abssw",           kS_abssw)
          .Case("absswq",          kS_absswq)
          .Case("absw",            kS_absw)
          .Case("abswq",           kS_abswq)
          .Case("acswapb",         kS_acswapb)
          .Case("acswapb_i",       kS_acswapb_i)
          .Case("acswapd",         kS_acswapd)
          .Case("acswapd_i",       kS_acswapd_i)
          .Case("acswaph",         kS_acswaph)
          .Case("acswaph_i",       kS_acswaph_i)
          .Case("acswapq",         kS_acswapq)
          .Case("acswapq_i",       kS_acswapq_i)
          .Case("acswapw",         kS_acswapw)
          .Case("acswapw_i",       kS_acswapw_i)
          .Case("addbx",           kS_addbx)
          .Case("addbx_i",         kS_addbx_i)
          .Case("addd",            kS_addd)
          .Case("addd_i",          kS_addd_i)
          .Case("adddp",           kS_adddp)
          .Case("adddp_i",         kS_adddp_i)
          .Case("addho",           kS_addho)
          .Case("addho_i",         kS_addho_i)
          .Case("addq",            kS_addq)
          .Case("addq_i",          kS_addq_i)
          .Case("addsbx",          kS_addsbx)
          .Case("addsbx_i",        kS_addsbx_i)
          .Case("addsd",           kS_addsd)
          .Case("addsd_i",         kS_addsd_i)
          .Case("addsdp",          kS_addsdp)
          .Case("addsdp_i",        kS_addsdp_i)
          .Case("addsho",          kS_addsho)
          .Case("addsho_i",        kS_addsho_i)
          .Case("addsw",           kS_addsw)
          .Case("addsw_i",         kS_addsw_i)
          .Case("addswq",          kS_addswq)
          .Case("addswq_i",        kS_addswq_i)
          .Case("addusbx",         kS_addusbx)
          .Case("addusbx_i",       kS_addusbx_i)
          .Case("addusd",          kS_addusd)
          .Case("addusd_i",        kS_addusd_i)
          .Case("addusdp",         kS_addusdp)
          .Case("addusdp_i",       kS_addusdp_i)
          .Case("addusho",         kS_addusho)
          .Case("addusho_i",       kS_addusho_i)
          .Case("addusw",          kS_addusw)
          .Case("addusw_i",        kS_addusw_i)
          .Case("adduswq",         kS_adduswq)
          .Case("adduswq_i",       kS_adduswq_i)
          .Case("addw",            kS_addw)
          .Case("addw_i",          kS_addw_i)
          .Case("addwq",           kS_addwq)
          .Case("addwq_i",         kS_addwq_i)
          .Case("addx16bx",        kS_addx16bx)
          .Case("addx16bx_i",      kS_addx16bx_i)
          .Case("addx16d",         kS_addx16d)
          .Case("addx16d_i",       kS_addx16d_i)
          .Case("addx16dp",        kS_addx16dp)
          .Case("addx16dp_i",      kS_addx16dp_i)
          .Case("addx16ho",        kS_addx16ho)
          .Case("addx16ho_i",      kS_addx16ho_i)
          .Case("addx16w",         kS_addx16w)
          .Case("addx16w_i",       kS_addx16w_i)
          .Case("addx16wq",        kS_addx16wq)
          .Case("addx16wq_i",      kS_addx16wq_i)
          .Case("addx2bx",         kS_addx2bx)
          .Case("addx2bx_i",       kS_addx2bx_i)
          .Case("addx2d",          kS_addx2d)
          .Case("addx2d_i",        kS_addx2d_i)
          .Case("addx2dp",         kS_addx2dp)
          .Case("addx2dp_i",       kS_addx2dp_i)
          .Case("addx2ho",         kS_addx2ho)
          .Case("addx2ho_i",       kS_addx2ho_i)
          .Case("addx2w",          kS_addx2w)
          .Case("addx2w_i",        kS_addx2w_i)
          .Case("addx2wq",         kS_addx2wq)
          .Case("addx2wq_i",       kS_addx2wq_i)
          .Case("addx32d",         kS_addx32d)
          .Case("addx32d_i",       kS_addx32d_i)
          .Case("addx32w",         kS_addx32w)
          .Case("addx32w_i",       kS_addx32w_i)
          .Case("addx4bx",         kS_addx4bx)
          .Case("addx4bx_i",       kS_addx4bx_i)
          .Case("addx4d",          kS_addx4d)
          .Case("addx4d_i",        kS_addx4d_i)
          .Case("addx4dp",         kS_addx4dp)
          .Case("addx4dp_i",       kS_addx4dp_i)
          .Case("addx4ho",         kS_addx4ho)
          .Case("addx4ho_i",       kS_addx4ho_i)
          .Case("addx4w",          kS_addx4w)
          .Case("addx4w_i",        kS_addx4w_i)
          .Case("addx4wq",         kS_addx4wq)
          .Case("addx4wq_i",       kS_addx4wq_i)
          .Case("addx64d",         kS_addx64d)
          .Case("addx64d_i",       kS_addx64d_i)
          .Case("addx64w",         kS_addx64w)
          .Case("addx64w_i",       kS_addx64w_i)
          .Case("addx8bx",         kS_addx8bx)
          .Case("addx8bx_i",       kS_addx8bx_i)
          .Case("addx8d",          kS_addx8d)
          .Case("addx8d_i",        kS_addx8d_i)
          .Case("addx8dp",         kS_addx8dp)
          .Case("addx8dp_i",       kS_addx8dp_i)
          .Case("addx8ho",         kS_addx8ho)
          .Case("addx8ho_i",       kS_addx8ho_i)
          .Case("addx8w",          kS_addx8w)
          .Case("addx8w_i",        kS_addx8w_i)
          .Case("addx8wq",         kS_addx8wq)
          .Case("addx8wq_i",       kS_addx8wq_i)
          .Case("aladdb",          kS_aladdb)
          .Case("aladdb_i",        kS_aladdb_i)
          .Case("aladdd",          kS_aladdd)
          .Case("aladdd_i",        kS_aladdd_i)
          .Case("aladdh",          kS_aladdh)
          .Case("aladdh_i",        kS_aladdh_i)
          .Case("aladdw",          kS_aladdw)
          .Case("aladdw_i",        kS_aladdw_i)
          .Case("alandb",          kS_alandb)
          .Case("alandb_i",        kS_alandb_i)
          .Case("alandd",          kS_alandd)
          .Case("alandd_i",        kS_alandd_i)
          .Case("alandh",          kS_alandh)
          .Case("alandh_i",        kS_alandh_i)
          .Case("alandw",          kS_alandw)
          .Case("alandw_i",        kS_alandw_i)
          .Case("alb",             kS_alb)
          .Case("alb_i",           kS_alb_i)
          .Case("alclrb",          kS_alclrb)
          .Case("alclrb_i",        kS_alclrb_i)
          .Case("alclrd",          kS_alclrd)
          .Case("alclrd_i",        kS_alclrd_i)
          .Case("alclrh",          kS_alclrh)
          .Case("alclrh_i",        kS_alclrh_i)
          .Case("alclrw",          kS_alclrw)
          .Case("alclrw_i",        kS_alclrw_i)
          .Case("ald",             kS_ald)
          .Case("ald_i",           kS_ald_i)
          .Case("aldusb",          kS_aldusb)
          .Case("aldusb_i",        kS_aldusb_i)
          .Case("aldusd",          kS_aldusd)
          .Case("aldusd_i",        kS_aldusd_i)
          .Case("aldush",          kS_aldush)
          .Case("aldush_i",        kS_aldush_i)
          .Case("aldusw",          kS_aldusw)
          .Case("aldusw_i",        kS_aldusw_i)
          .Case("aleorb",          kS_aleorb)
          .Case("aleorb_i",        kS_aleorb_i)
          .Case("aleord",          kS_aleord)
          .Case("aleord_i",        kS_aleord_i)
          .Case("aleorh",          kS_aleorh)
          .Case("aleorh_i",        kS_aleorh_i)
          .Case("aleorw",          kS_aleorw)
          .Case("aleorw_i",        kS_aleorw_i)
          .Case("alh",             kS_alh)
          .Case("alh_i",           kS_alh_i)
          .Case("aliorb",          kS_aliorb)
          .Case("aliorb_i",        kS_aliorb_i)
          .Case("aliord",          kS_aliord)
          .Case("aliord_i",        kS_aliord_i)
          .Case("aliorh",          kS_aliorh)
          .Case("aliorh_i",        kS_aliorh_i)
          .Case("aliorw",          kS_aliorw)
          .Case("aliorw_i",        kS_aliorw_i)
          .Case("almaxb",          kS_almaxb)
          .Case("almaxb_i",        kS_almaxb_i)
          .Case("almaxd",          kS_almaxd)
          .Case("almaxd_i",        kS_almaxd_i)
          .Case("almaxh",          kS_almaxh)
          .Case("almaxh_i",        kS_almaxh_i)
          .Case("almaxub",         kS_almaxub)
          .Case("almaxub_i",       kS_almaxub_i)
          .Case("almaxud",         kS_almaxud)
          .Case("almaxud_i",       kS_almaxud_i)
          .Case("almaxuh",         kS_almaxuh)
          .Case("almaxuh_i",       kS_almaxuh_i)
          .Case("almaxuw",         kS_almaxuw)
          .Case("almaxuw_i",       kS_almaxuw_i)
          .Case("almaxw",          kS_almaxw)
          .Case("almaxw_i",        kS_almaxw_i)
          .Case("alminb",          kS_alminb)
          .Case("alminb_i",        kS_alminb_i)
          .Case("almind",          kS_almind)
          .Case("almind_i",        kS_almind_i)
          .Case("alminh",          kS_alminh)
          .Case("alminh_i",        kS_alminh_i)
          .Case("alminub",         kS_alminub)
          .Case("alminub_i",       kS_alminub_i)
          .Case("alminud",         kS_alminud)
          .Case("alminud_i",       kS_alminud_i)
          .Case("alminuh",         kS_alminuh)
          .Case("alminuh_i",       kS_alminuh_i)
          .Case("alminuw",         kS_alminuw)
          .Case("alminuw_i",       kS_alminuw_i)
          .Case("alminw",          kS_alminw)
          .Case("alminw_i",        kS_alminw_i)
          .Case("alw",             kS_alw)
          .Case("alw_i",           kS_alw_i)
          .Case("andd",            kS_andd)
          .Case("andd_i",          kS_andd_i)
          .Case("andnd",           kS_andnd)
          .Case("andnd_i",         kS_andnd_i)
          .Case("andnq",           kS_andnq)
          .Case("andnq_i",         kS_andnq_i)
          .Case("andnw",           kS_andnw)
          .Case("andnw_i",         kS_andnw_i)
          .Case("andq",            kS_andq)
          .Case("andq_i",          kS_andq_i)
          .Case("andw",            kS_andw)
          .Case("andw_i",          kS_andw_i)
          .Case("asaddb",          kS_asaddb)
          .Case("asaddb_i",        kS_asaddb_i)
          .Case("asaddd",          kS_asaddd)
          .Case("asaddd_i",        kS_asaddd_i)
          .Case("asaddh",          kS_asaddh)
          .Case("asaddh_i",        kS_asaddh_i)
          .Case("asaddw",          kS_asaddw)
          .Case("asaddw_i",        kS_asaddw_i)
          .Case("asandb",          kS_asandb)
          .Case("asandb_i",        kS_asandb_i)
          .Case("asandd",          kS_asandd)
          .Case("asandd_i",        kS_asandd_i)
          .Case("asandh",          kS_asandh)
          .Case("asandh_i",        kS_asandh_i)
          .Case("asandw",          kS_asandw)
          .Case("asandw_i",        kS_asandw_i)
          .Case("asb",             kS_asb)
          .Case("asb_i",           kS_asb_i)
          .Case("asd",             kS_asd)
          .Case("asd_i",           kS_asd_i)
          .Case("asdusb",          kS_asdusb)
          .Case("asdusb_i",        kS_asdusb_i)
          .Case("asdusd",          kS_asdusd)
          .Case("asdusd_i",        kS_asdusd_i)
          .Case("asdush",          kS_asdush)
          .Case("asdush_i",        kS_asdush_i)
          .Case("asdusw",          kS_asdusw)
          .Case("asdusw_i",        kS_asdusw_i)
          .Case("aseorb",          kS_aseorb)
          .Case("aseorb_i",        kS_aseorb_i)
          .Case("aseord",          kS_aseord)
          .Case("aseord_i",        kS_aseord_i)
          .Case("aseorh",          kS_aseorh)
          .Case("aseorh_i",        kS_aseorh_i)
          .Case("aseorw",          kS_aseorw)
          .Case("aseorw_i",        kS_aseorw_i)
          .Case("ash",             kS_ash)
          .Case("ash_i",           kS_ash_i)
          .Case("asiorb",          kS_asiorb)
          .Case("asiorb_i",        kS_asiorb_i)
          .Case("asiord",          kS_asiord)
          .Case("asiord_i",        kS_asiord_i)
          .Case("asiorh",          kS_asiorh)
          .Case("asiorh_i",        kS_asiorh_i)
          .Case("asiorw",          kS_asiorw)
          .Case("asiorw_i",        kS_asiorw_i)
          .Case("asmaxb",          kS_asmaxb)
          .Case("asmaxb_i",        kS_asmaxb_i)
          .Case("asmaxd",          kS_asmaxd)
          .Case("asmaxd_i",        kS_asmaxd_i)
          .Case("asmaxh",          kS_asmaxh)
          .Case("asmaxh_i",        kS_asmaxh_i)
          .Case("asmaxub",         kS_asmaxub)
          .Case("asmaxub_i",       kS_asmaxub_i)
          .Case("asmaxud",         kS_asmaxud)
          .Case("asmaxud_i",       kS_asmaxud_i)
          .Case("asmaxuh",         kS_asmaxuh)
          .Case("asmaxuh_i",       kS_asmaxuh_i)
          .Case("asmaxuw",         kS_asmaxuw)
          .Case("asmaxuw_i",       kS_asmaxuw_i)
          .Case("asmaxw",          kS_asmaxw)
          .Case("asmaxw_i",        kS_asmaxw_i)
          .Case("asminb",          kS_asminb)
          .Case("asminb_i",        kS_asminb_i)
          .Case("asmind",          kS_asmind)
          .Case("asmind_i",        kS_asmind_i)
          .Case("asminh",          kS_asminh)
          .Case("asminh_i",        kS_asminh_i)
          .Case("asminub",         kS_asminub)
          .Case("asminub_i",       kS_asminub_i)
          .Case("asminud",         kS_asminud)
          .Case("asminud_i",       kS_asminud_i)
          .Case("asminuh",         kS_asminuh)
          .Case("asminuh_i",       kS_asminuh_i)
          .Case("asminuw",         kS_asminuw)
          .Case("asminuw_i",       kS_asminuw_i)
          .Case("asminw",          kS_asminw)
          .Case("asminw_i",        kS_asminw_i)
          .Case("asw",             kS_asw)
          .Case("asw_i",           kS_asw_i)
          .Case("aswapb",          kS_aswapb)
          .Case("aswapb_i",        kS_aswapb_i)
          .Case("aswapd",          kS_aswapd)
          .Case("aswapd_i",        kS_aswapd_i)
          .Case("aswaph",          kS_aswaph)
          .Case("aswaph_i",        kS_aswaph_i)
          .Case("aswapw",          kS_aswapw)
          .Case("aswapw_i",        kS_aswapw_i)
          .Case("avgbx",           kS_avgbx)
          .Case("avgbx_i",         kS_avgbx_i)
          .Case("avgho",           kS_avgho)
          .Case("avgho_i",         kS_avgho_i)
          .Case("avgrbx",          kS_avgrbx)
          .Case("avgrbx_i",        kS_avgrbx_i)
          .Case("avgrho",          kS_avgrho)
          .Case("avgrho_i",        kS_avgrho_i)
          .Case("avgrubx",         kS_avgrubx)
          .Case("avgrubx_i",       kS_avgrubx_i)
          .Case("avgruho",         kS_avgruho)
          .Case("avgruho_i",       kS_avgruho_i)
          .Case("avgruw",          kS_avgruw)
          .Case("avgruw_i",        kS_avgruw_i)
          .Case("avgruwq",         kS_avgruwq)
          .Case("avgruwq_i",       kS_avgruwq_i)
          .Case("avgrw",           kS_avgrw)
          .Case("avgrw_i",         kS_avgrw_i)
          .Case("avgrwq",          kS_avgrwq)
          .Case("avgrwq_i",        kS_avgrwq_i)
          .Case("avgubx",          kS_avgubx)
          .Case("avgubx_i",        kS_avgubx_i)
          .Case("avguho",          kS_avguho)
          .Case("avguho_i",        kS_avguho_i)
          .Case("avguw",           kS_avguw)
          .Case("avguw_i",         kS_avguw_i)
          .Case("avguwq",          kS_avguwq)
          .Case("avguwq_i",        kS_avguwq_i)
          .Case("avgw",            kS_avgw)
          .Case("avgw_i",          kS_avgw_i)
          .Case("avgwq",           kS_avgwq)
          .Case("avgwq_i",         kS_avgwq_i)
          .Case("await",           kS_await)
          .Case("barrier",         kS_barrier)
          .Case("blend",           kS_blend)
          .Case("break",           kS_break)
          .Case("catdq",           kS_catdq)
          .Case("cbsd",            kS_cbsd)
          .Case("cbsdp",           kS_cbsdp)
          .Case("cbsho",           kS_cbsho)
          .Case("cbsw",            kS_cbsw)
          .Case("cbswq",           kS_cbswq)
          .Case("clsd",            kS_clsd)
          .Case("clsdp",           kS_clsdp)
          .Case("clsho",           kS_clsho)
          .Case("clsw",            kS_clsw)
          .Case("clswq",           kS_clswq)
          .Case("clzd",            kS_clzd)
          .Case("clzdp",           kS_clzdp)
          .Case("clzho",           kS_clzho)
          .Case("clzw",            kS_clzw)
          .Case("clzwq",           kS_clzwq)
          .Case("cmovebx",         kS_cmovebx)
          .Case("cmovebx_i",       kS_cmovebx_i)
          .Case("cmoved",          kS_cmoved)
          .Case("cmoved_i",        kS_cmoved_i)
          .Case("cmovedp",         kS_cmovedp)
          .Case("cmovedp_i",       kS_cmovedp_i)
          .Case("cmoveho",         kS_cmoveho)
          .Case("cmoveho_i",       kS_cmoveho_i)
          .Case("cmoveq",          kS_cmoveq)
          .Case("cmovewq",         kS_cmovewq)
          .Case("cmovewq_i",       kS_cmovewq_i)
          .Case("compbx",          kS_compbx)
          .Case("compbx_i",        kS_compbx_i)
          .Case("compd",           kS_compd)
          .Case("compd_i",         kS_compd_i)
          .Case("compdp",          kS_compdp)
          .Case("compdp_i",        kS_compdp_i)
          .Case("compho",          kS_compho)
          .Case("compho_i",        kS_compho_i)
          .Case("compnbx",         kS_compnbx)
          .Case("compnbx_i",       kS_compnbx_i)
          .Case("compndp",         kS_compndp)
          .Case("compndp_i",       kS_compndp_i)
          .Case("compnho",         kS_compnho)
          .Case("compnho_i",       kS_compnho_i)
          .Case("compnwq",         kS_compnwq)
          .Case("compnwq_i",       kS_compnwq_i)
          .Case("compq",           kS_compq)
          .Case("compw",           kS_compw)
          .Case("compw_i",         kS_compw_i)
          .Case("compwq",          kS_compwq)
          .Case("compwq_i",        kS_compwq_i)
          .Case("copyd",           kS_copyd)
          .Case("copyo",           kS_copyo)
          .Case("copyq",           kS_copyq)
          .Case("copyw",           kS_copyw)
          .Case("crcbellw",        kS_crcbellw)
          .Case("crcbellw_i",      kS_crcbellw_i)
          .Case("crcbelmw",        kS_crcbelmw)
          .Case("crcbelmw_i",      kS_crcbelmw_i)
          .Case("crclellw",        kS_crclellw)
          .Case("crclellw_i",      kS_crclellw_i)
          .Case("crclelmw",        kS_crclelmw)
          .Case("crclelmw_i",      kS_crclelmw_i)
          .Case("csrrc",           kS_csrrc)
          .Case("csrrs",           kS_csrrs)
          .Case("csrrw",           kS_csrrw)
          .Case("ctzd",            kS_ctzd)
          .Case("ctzdp",           kS_ctzdp)
          .Case("ctzho",           kS_ctzho)
          .Case("ctzw",            kS_ctzw)
          .Case("ctzwq",           kS_ctzwq)
          .Case("d1inval",         kS_d1inval)
          .Case("dflushl",         kS_dflushl)
          .Case("dflushl_r",       kS_dflushl_r)
          .Case("dflushsw",        kS_dflushsw)
          .Case("dinvall",         kS_dinvall)
          .Case("dinvall_r",       kS_dinvall_r)
          .Case("dinvalsw",        kS_dinvalsw)
          .Case("divmodd",         kS_divmodd)
          .Case("divmodud",        kS_divmodud)
          .Case("divmoduw",        kS_divmoduw)
          .Case("divmodw",         kS_divmodw)
          .Case("dpurgel",         kS_dpurgel)
          .Case("dpurgel_r",       kS_dpurgel_r)
          .Case("dpurgesw",        kS_dpurgesw)
          .Case("dtouchl",         kS_dtouchl)
          .Case("dtouchl_r",       kS_dtouchl_r)
          .Case("eord",            kS_eord)
          .Case("eord_i",          kS_eord_i)
          .Case("eorq",            kS_eorq)
          .Case("eorq_i",          kS_eorq_i)
          .Case("eorw",            kS_eorw)
          .Case("eorw_i",          kS_eorw_i)
          .Case("errop",           kS_errop)
          .Case("extfs",           kS_extfs)
          .Case("extfz",           kS_extfz)
          .Case("extlqbho",        kS_extlqbho)
          .Case("extlqhwq",        kS_extlqhwq)
          .Case("extlqnbx",        kS_extlqnbx)
          .Case("extlqwdp",        kS_extlqwdp)
          .Case("extlsbho",        kS_extlsbho)
          .Case("extlshwq",        kS_extlshwq)
          .Case("extlsnbx",        kS_extlsnbx)
          .Case("extlswdp",        kS_extlswdp)
          .Case("extlzbho",        kS_extlzbho)
          .Case("extlzhwq",        kS_extlzhwq)
          .Case("extlznbx",        kS_extlznbx)
          .Case("extlzwdp",        kS_extlzwdp)
          .Case("fabsd",           kS_fabsd)
          .Case("fabsdp",          kS_fabsdp)
          .Case("fabsh",           kS_fabsh)
          .Case("fabsho",          kS_fabsho)
          .Case("fabsw",           kS_fabsw)
          .Case("fabswp",          kS_fabswp)
          .Case("fabswq",          kS_fabswq)
          .Case("faddd",           kS_faddd)
          .Case("fadddp",          kS_fadddp)
          .Case("faddh",           kS_faddh)
          .Case("faddho",          kS_faddho)
          .Case("faddw",           kS_faddw)
          .Case("faddwc",          kS_faddwc)
          .Case("faddwq",          kS_faddwq)
          .Case("fclassd",         kS_fclassd)
          .Case("fclassdp",        kS_fclassdp)
          .Case("fclassh",         kS_fclassh)
          .Case("fclassho",        kS_fclassho)
          .Case("fclassw",         kS_fclassw)
          .Case("fclasswp",        kS_fclasswp)
          .Case("fclasswq",        kS_fclasswq)
          .Case("fcompd",          kS_fcompd)
          .Case("fcompd_i",        kS_fcompd_i)
          .Case("fcompdp",         kS_fcompdp)
          .Case("fcompdp_i",       kS_fcompdp_i)
          .Case("fcomph",          kS_fcomph)
          .Case("fcomph_i",        kS_fcomph_i)
          .Case("fcompho",         kS_fcompho)
          .Case("fcompho_i",       kS_fcompho_i)
          .Case("fcompndp",        kS_fcompndp)
          .Case("fcompndp_i",      kS_fcompndp_i)
          .Case("fcompnho",        kS_fcompnho)
          .Case("fcompnho_i",      kS_fcompnho_i)
          .Case("fcompnwq",        kS_fcompnwq)
          .Case("fcompnwq_i",      kS_fcompnwq_i)
          .Case("fcompw",          kS_fcompw)
          .Case("fcompw_i",        kS_fcompw_i)
          .Case("fcompwq",         kS_fcompwq)
          .Case("fcompwq_i",       kS_fcompwq_i)
          .Case("fdivd",           kS_fdivd)
          .Case("fdivh",           kS_fdivh)
          .Case("fdivw",           kS_fdivw)
          .Case("fence",           kS_fence)
          .Case("fextlhwq",        kS_fextlhwq)
          .Case("ffmad",           kS_ffmad)
          .Case("ffmadp",          kS_ffmadp)
          .Case("ffmah",           kS_ffmah)
          .Case("ffmaho",          kS_ffmaho)
          .Case("ffmaw",           kS_ffmaw)
          .Case("ffmawc",          kS_ffmawc)
          .Case("ffmawq",          kS_ffmawq)
          .Case("ffmsd",           kS_ffmsd)
          .Case("ffmsdp",          kS_ffmsdp)
          .Case("ffmsh",           kS_ffmsh)
          .Case("ffmsho",          kS_ffmsho)
          .Case("ffmsw",           kS_ffmsw)
          .Case("ffmswq",          kS_ffmswq)
          .Case("fixedd",          kS_fixedd)
          .Case("fixeddp",         kS_fixeddp)
          .Case("fixeddw",         kS_fixeddw)
          .Case("fixedho",         kS_fixedho)
          .Case("fixedud",         kS_fixedud)
          .Case("fixedudp",        kS_fixedudp)
          .Case("fixedudw",        kS_fixedudw)
          .Case("fixeduho",        kS_fixeduho)
          .Case("fixeduw",         kS_fixeduw)
          .Case("fixeduwd",        kS_fixeduwd)
          .Case("fixeduwp",        kS_fixeduwp)
          .Case("fixeduwq",        kS_fixeduwq)
          .Case("fixedw",          kS_fixedw)
          .Case("fixedwd",         kS_fixedwd)
          .Case("fixedwp",         kS_fixedwp)
          .Case("fixedwq",         kS_fixedwq)
          .Case("floatd",          kS_floatd)
          .Case("floatdp",         kS_floatdp)
          .Case("floatdw",         kS_floatdw)
          .Case("floatho",         kS_floatho)
          .Case("floatud",         kS_floatud)
          .Case("floatudp",        kS_floatudp)
          .Case("floatudw",        kS_floatudw)
          .Case("floatuho",        kS_floatuho)
          .Case("floatuw",         kS_floatuw)
          .Case("floatuwd",        kS_floatuwd)
          .Case("floatuwp",        kS_floatuwp)
          .Case("floatuwq",        kS_floatuwq)
          .Case("floatw",          kS_floatw)
          .Case("floatwd",         kS_floatwd)
          .Case("floatwp",         kS_floatwp)
          .Case("floatwq",         kS_floatwq)
          .Case("fmaxd",           kS_fmaxd)
          .Case("fmaxdp",          kS_fmaxdp)
          .Case("fmaxh",           kS_fmaxh)
          .Case("fmaxho",          kS_fmaxho)
          .Case("fmaxnd",          kS_fmaxnd)
          .Case("fmaxndp",         kS_fmaxndp)
          .Case("fmaxnh",          kS_fmaxnh)
          .Case("fmaxnho",         kS_fmaxnho)
          .Case("fmaxnw",          kS_fmaxnw)
          .Case("fmaxnwq",         kS_fmaxnwq)
          .Case("fmaxw",           kS_fmaxw)
          .Case("fmaxwq",          kS_fmaxwq)
          .Case("fmind",           kS_fmind)
          .Case("fmindp",          kS_fmindp)
          .Case("fminh",           kS_fminh)
          .Case("fminho",          kS_fminho)
          .Case("fminnd",          kS_fminnd)
          .Case("fminndp",         kS_fminndp)
          .Case("fminnh",          kS_fminnh)
          .Case("fminnho",         kS_fminnho)
          .Case("fminnw",          kS_fminnw)
          .Case("fminnwq",         kS_fminnwq)
          .Case("fminw",           kS_fminw)
          .Case("fminwq",          kS_fminwq)
          .Case("fmuld",           kS_fmuld)
          .Case("fmuldp",          kS_fmuldp)
          .Case("fmulh",           kS_fmulh)
          .Case("fmulho",          kS_fmulho)
          .Case("fmulw",           kS_fmulw)
          .Case("fmulwc",          kS_fmulwc)
          .Case("fmulwq",          kS_fmulwq)
          .Case("fnarrowdw",       kS_fnarrowdw)
          .Case("fnarrowdwq",      kS_fnarrowdwq)
          .Case("fnarrowwh",       kS_fnarrowwh)
          .Case("fnarrowwho",      kS_fnarrowwho)
          .Case("fnegd",           kS_fnegd)
          .Case("fnegdp",          kS_fnegdp)
          .Case("fnegh",           kS_fnegh)
          .Case("fnegho",          kS_fnegho)
          .Case("fnegw",           kS_fnegw)
          .Case("fnegwp",          kS_fnegwp)
          .Case("fnegwq",          kS_fnegwq)
          .Case("fractdwq",        kS_fractdwq)
          .Case("fracthbx",        kS_fracthbx)
          .Case("fractwho",        kS_fractwho)
          .Case("frcsr",           kS_frcsr)
          .Case("frflags",         kS_frflags)
          .Case("frintd",          kS_frintd)
          .Case("frinth",          kS_frinth)
          .Case("frintw",          kS_frintw)
          .Case("frrm",            kS_frrm)
          .Case("fsbfd",           kS_fsbfd)
          .Case("fsbfdp",          kS_fsbfdp)
          .Case("fsbfh",           kS_fsbfh)
          .Case("fsbfho",          kS_fsbfho)
          .Case("fsbfw",           kS_fsbfw)
          .Case("fsbfwc",          kS_fsbfwc)
          .Case("fsbfwq",          kS_fsbfwq)
          .Case("fscsr",           kS_fscsr)
          .Case("fsflags",         kS_fsflags)
          .Case("fsignd",          kS_fsignd)
          .Case("fsigndp",         kS_fsigndp)
          .Case("fsignh",          kS_fsignh)
          .Case("fsignho",         kS_fsignho)
          .Case("fsignmd",         kS_fsignmd)
          .Case("fsignmdp",        kS_fsignmdp)
          .Case("fsignmh",         kS_fsignmh)
          .Case("fsignmho",        kS_fsignmho)
          .Case("fsignmw",         kS_fsignmw)
          .Case("fsignmwq",        kS_fsignmwq)
          .Case("fsignnd",         kS_fsignnd)
          .Case("fsignndp",        kS_fsignndp)
          .Case("fsignnh",         kS_fsignnh)
          .Case("fsignnho",        kS_fsignnho)
          .Case("fsignnw",         kS_fsignnw)
          .Case("fsignnwq",        kS_fsignnwq)
          .Case("fsignw",          kS_fsignw)
          .Case("fsignwq",         kS_fsignwq)
          .Case("fsqrtd",          kS_fsqrtd)
          .Case("fsqrth",          kS_fsqrth)
          .Case("fsqrtw",          kS_fsqrtw)
          .Case("fsrecd",          kS_fsrecd)
          .Case("fsrecw",          kS_fsrecw)
          .Case("fsrecwp",         kS_fsrecwp)
          .Case("fsrecwq",         kS_fsrecwq)
          .Case("fsrm",            kS_fsrm)
          .Case("fsrsrd",          kS_fsrsrd)
          .Case("fsrsrw",          kS_fsrsrw)
          .Case("fsrsrwp",         kS_fsrsrwp)
          .Case("fsrsrwq",         kS_fsrsrwq)
          .Case("fwidenhw",        kS_fwidenhw)
          .Case("fwidenhwp",       kS_fwidenhwp)
          .Case("fwidenhwq",       kS_fwidenhwq)
          .Case("fwidenwd",        kS_fwidenwd)
          .Case("fwidenwdp",       kS_fwidenwdp)
          .Case("get",             kS_get)
          .Case("guard",           kS_guard)
          .Case("i1inval",         kS_i1inval)
          .Case("i1invals",        kS_i1invals)
          .Case("i1invals_r",      kS_i1invals_r)
          .Case("iget",            kS_iget)
          .Case("insf",            kS_insf)
          .Case("iord",            kS_iord)
          .Case("iord_i",          kS_iord_i)
          .Case("iornd",           kS_iornd)
          .Case("iornd_i",         kS_iornd_i)
          .Case("iornq",           kS_iornq)
          .Case("iornq_i",         kS_iornq_i)
          .Case("iornw",           kS_iornw)
          .Case("iornw_i",         kS_iornw_i)
          .Case("iorq",            kS_iorq)
          .Case("iorq_i",          kS_iorq_i)
          .Case("iorw",            kS_iorw)
          .Case("iorw_i",          kS_iorw_i)
          .Case("landd",           kS_landd)
          .Case("landw",           kS_landw)
          .Case("lbs",             kS_lbs)
          .Case("lbs_r",           kS_lbs_r)
          .Case("lbz",             kS_lbz)
          .Case("lbz_r",           kS_lbz_r)
          .Case("ld",              kS_ld)
          .Case("ld_r",            kS_ld_r)
          .Case("lhs",             kS_lhs)
          .Case("lhs_r",           kS_lhs_r)
          .Case("lhz",             kS_lhz)
          .Case("lhz_r",           kS_lhz_r)
          .Case("liord",           kS_liord)
          .Case("liorw",           kS_liorw)
          .Case("lnandd",          kS_lnandd)
          .Case("lnandw",          kS_lnandw)
          .Case("lniord",          kS_lniord)
          .Case("lniorw",          kS_lniorw)
          .Case("lo",              kS_lo)
          .Case("lo_r",            kS_lo_r)
          .Case("lq",              kS_lq)
          .Case("lq_r",            kS_lq_r)
          .Case("lws",             kS_lws)
          .Case("lws_r",           kS_lws_r)
          .Case("lwz",             kS_lwz)
          .Case("lwz_r",           kS_lwz_r)
          .Case("maddd",           kS_maddd)
          .Case("maddd_i",         kS_maddd_i)
          .Case("madddp",          kS_madddp)
          .Case("maddho",          kS_maddho)
          .Case("maddw",           kS_maddw)
          .Case("maddw_i",         kS_maddw_i)
          .Case("maddwq",          kS_maddwq)
          .Case("maddxbho",        kS_maddxbho)
          .Case("maddxdq",         kS_maddxdq)
          .Case("maddxhwq",        kS_maddxhwq)
          .Case("maddxwd",         kS_maddxwd)
          .Case("maddxwd_i",       kS_maddxwd_i)
          .Case("maddxwdp",        kS_maddxwdp)
          .Case("maked",           kS_maked)
          .Case("maxbx",           kS_maxbx)
          .Case("maxbx_i",         kS_maxbx_i)
          .Case("maxd",            kS_maxd)
          .Case("maxd_i",          kS_maxd_i)
          .Case("maxdp",           kS_maxdp)
          .Case("maxdp_i",         kS_maxdp_i)
          .Case("maxho",           kS_maxho)
          .Case("maxho_i",         kS_maxho_i)
          .Case("maxubx",          kS_maxubx)
          .Case("maxubx_i",        kS_maxubx_i)
          .Case("maxud",           kS_maxud)
          .Case("maxud_i",         kS_maxud_i)
          .Case("maxudp",          kS_maxudp)
          .Case("maxudp_i",        kS_maxudp_i)
          .Case("maxuho",          kS_maxuho)
          .Case("maxuho_i",        kS_maxuho_i)
          .Case("maxuw",           kS_maxuw)
          .Case("maxuw_i",         kS_maxuw_i)
          .Case("maxuwq",          kS_maxuwq)
          .Case("maxuwq_i",        kS_maxuwq_i)
          .Case("maxw",            kS_maxw)
          .Case("maxw_i",          kS_maxw_i)
          .Case("maxwq",           kS_maxwq)
          .Case("maxwq_i",         kS_maxwq_i)
          .Case("minbx",           kS_minbx)
          .Case("minbx_i",         kS_minbx_i)
          .Case("mind",            kS_mind)
          .Case("mind_i",          kS_mind_i)
          .Case("mindp",           kS_mindp)
          .Case("mindp_i",         kS_mindp_i)
          .Case("minho",           kS_minho)
          .Case("minho_i",         kS_minho_i)
          .Case("minubx",          kS_minubx)
          .Case("minubx_i",        kS_minubx_i)
          .Case("minud",           kS_minud)
          .Case("minud_i",         kS_minud_i)
          .Case("minudp",          kS_minudp)
          .Case("minudp_i",        kS_minudp_i)
          .Case("minuho",          kS_minuho)
          .Case("minuho_i",        kS_minuho_i)
          .Case("minuw",           kS_minuw)
          .Case("minuw_i",         kS_minuw_i)
          .Case("minuwq",          kS_minuwq)
          .Case("minuwq_i",        kS_minuwq_i)
          .Case("minw",            kS_minw)
          .Case("minw_i",          kS_minw_i)
          .Case("minwq",           kS_minwq)
          .Case("minwq_i",         kS_minwq_i)
          .Case("msbfd",           kS_msbfd)
          .Case("msbfd_i",         kS_msbfd_i)
          .Case("msbfdp",          kS_msbfdp)
          .Case("msbfho",          kS_msbfho)
          .Case("msbfw",           kS_msbfw)
          .Case("msbfw_i",         kS_msbfw_i)
          .Case("msbfwq",          kS_msbfwq)
          .Case("msbfxbho",        kS_msbfxbho)
          .Case("msbfxdq",         kS_msbfxdq)
          .Case("msbfxhwq",        kS_msbfxhwq)
          .Case("msbfxwd",         kS_msbfxwd)
          .Case("msbfxwd_i",       kS_msbfxwd_i)
          .Case("msbfxwdp",        kS_msbfxwdp)
          .Case("muld",            kS_muld)
          .Case("muld_i",          kS_muld_i)
          .Case("muldp",           kS_muldp)
          .Case("mulho",           kS_mulho)
          .Case("mulnd",           kS_mulnd)
          .Case("mulnd_i",         kS_mulnd_i)
          .Case("mulndp",          kS_mulndp)
          .Case("mulnho",          kS_mulnho)
          .Case("mulnw",           kS_mulnw)
          .Case("mulnw_i",         kS_mulnw_i)
          .Case("mulnwq",          kS_mulnwq)
          .Case("mulnxbho",        kS_mulnxbho)
          .Case("mulnxdq",         kS_mulnxdq)
          .Case("mulnxhwq",        kS_mulnxhwq)
          .Case("mulnxwd",         kS_mulnxwd)
          .Case("mulnxwd_i",       kS_mulnxwd_i)
          .Case("mulnxwdp",        kS_mulnxwdp)
          .Case("mulw",            kS_mulw)
          .Case("mulw_i",          kS_mulw_i)
          .Case("mulwq",           kS_mulwq)
          .Case("mulxbho",         kS_mulxbho)
          .Case("mulxdq",          kS_mulxdq)
          .Case("mulxhwq",         kS_mulxhwq)
          .Case("mulxwd",          kS_mulxwd)
          .Case("mulxwd_i",        kS_mulxwd_i)
          .Case("mulxwdp",         kS_mulxwdp)
          .Case("nandd",           kS_nandd)
          .Case("nandd_i",         kS_nandd_i)
          .Case("nandq",           kS_nandq)
          .Case("nandq_i",         kS_nandq_i)
          .Case("nandw",           kS_nandw)
          .Case("nandw_i",         kS_nandw_i)
          .Case("negbx",           kS_negbx)
          .Case("negd",            kS_negd)
          .Case("negdp",           kS_negdp)
          .Case("negho",           kS_negho)
          .Case("negq",            kS_negq)
          .Case("negsbx",          kS_negsbx)
          .Case("negsd",           kS_negsd)
          .Case("negsdp",          kS_negsdp)
          .Case("negsho",          kS_negsho)
          .Case("negsw",           kS_negsw)
          .Case("negswq",          kS_negswq)
          .Case("negw",            kS_negw)
          .Case("negwq",           kS_negwq)
          .Case("neord",           kS_neord)
          .Case("neord_i",         kS_neord_i)
          .Case("neorq",           kS_neorq)
          .Case("neorq_i",         kS_neorq_i)
          .Case("neorw",           kS_neorw)
          .Case("neorw_i",         kS_neorw_i)
          .Case("niord",           kS_niord)
          .Case("niord_i",         kS_niord_i)
          .Case("niorq",           kS_niorq)
          .Case("niorq_i",         kS_niorq_i)
          .Case("niorw",           kS_niorw)
          .Case("niorw_i",         kS_niorw_i)
          .Case("nop",             kS_nop)
          .Case("notd",            kS_notd)
          .Case("notq",            kS_notq)
          .Case("notw",            kS_notw)
          .Case("pcrel",           kS_pcrel)
          .Case("rfe",             kS_rfe)
          .Case("rold",            kS_rold)
          .Case("rold_i",          kS_rold_i)
          .Case("rolw",            kS_rolw)
          .Case("rolw_i",          kS_rolw_i)
          .Case("rolwq",           kS_rolwq)
          .Case("rolwq_i",         kS_rolwq_i)
          .Case("rord",            kS_rord)
          .Case("rord_i",          kS_rord_i)
          .Case("rorw",            kS_rorw)
          .Case("rorw_i",          kS_rorw_i)
          .Case("rorwq",           kS_rorwq)
          .Case("rorwq_i",         kS_rorwq_i)
          .Case("rswap",           kS_rswap)
          .Case("sb",              kS_sb)
          .Case("sb_r",            kS_sb_r)
          .Case("sbfbx",           kS_sbfbx)
          .Case("sbfbx_i",         kS_sbfbx_i)
          .Case("sbfd",            kS_sbfd)
          .Case("sbfd_i",          kS_sbfd_i)
          .Case("sbfdp",           kS_sbfdp)
          .Case("sbfdp_i",         kS_sbfdp_i)
          .Case("sbfho",           kS_sbfho)
          .Case("sbfho_i",         kS_sbfho_i)
          .Case("sbfq",            kS_sbfq)
          .Case("sbfq_i",          kS_sbfq_i)
          .Case("sbfsbx",          kS_sbfsbx)
          .Case("sbfsbx_i",        kS_sbfsbx_i)
          .Case("sbfsd",           kS_sbfsd)
          .Case("sbfsd_i",         kS_sbfsd_i)
          .Case("sbfsdp",          kS_sbfsdp)
          .Case("sbfsdp_i",        kS_sbfsdp_i)
          .Case("sbfsho",          kS_sbfsho)
          .Case("sbfsho_i",        kS_sbfsho_i)
          .Case("sbfsw",           kS_sbfsw)
          .Case("sbfsw_i",         kS_sbfsw_i)
          .Case("sbfswq",          kS_sbfswq)
          .Case("sbfswq_i",        kS_sbfswq_i)
          .Case("sbfusbx",         kS_sbfusbx)
          .Case("sbfusbx_i",       kS_sbfusbx_i)
          .Case("sbfusd",          kS_sbfusd)
          .Case("sbfusd_i",        kS_sbfusd_i)
          .Case("sbfusdp",         kS_sbfusdp)
          .Case("sbfusdp_i",       kS_sbfusdp_i)
          .Case("sbfusho",         kS_sbfusho)
          .Case("sbfusho_i",       kS_sbfusho_i)
          .Case("sbfusw",          kS_sbfusw)
          .Case("sbfusw_i",        kS_sbfusw_i)
          .Case("sbfuswq",         kS_sbfuswq)
          .Case("sbfuswq_i",       kS_sbfuswq_i)
          .Case("sbfw",            kS_sbfw)
          .Case("sbfw_i",          kS_sbfw_i)
          .Case("sbfwq",           kS_sbfwq)
          .Case("sbfwq_i",         kS_sbfwq_i)
          .Case("sbmm8",           kS_sbmm8)
          .Case("sbmm8_i",         kS_sbmm8_i)
          .Case("sbmm8d",          kS_sbmm8d)
          .Case("sbmm8d_i",        kS_sbmm8d_i)
          .Case("sbmm8dp",         kS_sbmm8dp)
          .Case("sbmm8dp_i",       kS_sbmm8dp_i)
          .Case("sbmm8eord",       kS_sbmm8eord)
          .Case("sbmm8eord_i",     kS_sbmm8eord_i)
          .Case("sbmm8eordp",      kS_sbmm8eordp)
          .Case("sbmm8eordp_i",    kS_sbmm8eordp_i)
          .Case("sbmmt8",          kS_sbmmt8)
          .Case("sbmmt8_i",        kS_sbmmt8_i)
          .Case("sbmmt8d",         kS_sbmmt8d)
          .Case("sbmmt8d_i",       kS_sbmmt8d_i)
          .Case("sbmmt8dp",        kS_sbmmt8dp)
          .Case("sbmmt8dp_i",      kS_sbmmt8dp_i)
          .Case("sbmmt8eord",      kS_sbmmt8eord)
          .Case("sbmmt8eord_i",    kS_sbmmt8eord_i)
          .Case("sbmmt8eordp",     kS_sbmmt8eordp)
          .Case("sbmmt8eordp_i",   kS_sbmmt8eordp_i)
          .Case("scall",           kS_scall)
          .Case("scall_i",         kS_scall_i)
          .Case("sd",              kS_sd)
          .Case("sd_r",            kS_sd_r)
          .Case("set",             kS_set)
          .Case("sh",              kS_sh)
          .Case("sh_r",            kS_sh_r)
          .Case("signbx",          kS_signbx)
          .Case("signbx_i",        kS_signbx_i)
          .Case("signd",           kS_signd)
          .Case("signd_i",         kS_signd_i)
          .Case("signdp",          kS_signdp)
          .Case("signdp_i",        kS_signdp_i)
          .Case("signho",          kS_signho)
          .Case("signho_i",        kS_signho_i)
          .Case("signsbx",         kS_signsbx)
          .Case("signsbx_i",       kS_signsbx_i)
          .Case("signsd",          kS_signsd)
          .Case("signsd_i",        kS_signsd_i)
          .Case("signsdp",         kS_signsdp)
          .Case("signsdp_i",       kS_signsdp_i)
          .Case("signsho",         kS_signsho)
          .Case("signsho_i",       kS_signsho_i)
          .Case("signsw",          kS_signsw)
          .Case("signsw_i",        kS_signsw_i)
          .Case("signswq",         kS_signswq)
          .Case("signswq_i",       kS_signswq_i)
          .Case("signw",           kS_signw)
          .Case("signw_i",         kS_signw_i)
          .Case("signwq",          kS_signwq)
          .Case("signwq_i",        kS_signwq_i)
          .Case("sleep",           kS_sleep)
          .Case("sllbx",           kS_sllbx)
          .Case("sllbx_i",         kS_sllbx_i)
          .Case("slld",            kS_slld)
          .Case("slld_i",          kS_slld_i)
          .Case("slldp",           kS_slldp)
          .Case("slldp_i",         kS_slldp_i)
          .Case("sllho",           kS_sllho)
          .Case("sllho_i",         kS_sllho_i)
          .Case("sllw",            kS_sllw)
          .Case("sllw_i",          kS_sllw_i)
          .Case("sllwq",           kS_sllwq)
          .Case("sllwq_i",         kS_sllwq_i)
          .Case("slsbx",           kS_slsbx)
          .Case("slsbx_i",         kS_slsbx_i)
          .Case("slsd",            kS_slsd)
          .Case("slsd_i",          kS_slsd_i)
          .Case("slsdp",           kS_slsdp)
          .Case("slsdp_i",         kS_slsdp_i)
          .Case("slsho",           kS_slsho)
          .Case("slsho_i",         kS_slsho_i)
          .Case("slsw",            kS_slsw)
          .Case("slsw_i",          kS_slsw_i)
          .Case("slswq",           kS_slswq)
          .Case("slswq_i",         kS_slswq_i)
          .Case("slusbx",          kS_slusbx)
          .Case("slusbx_i",        kS_slusbx_i)
          .Case("slusd",           kS_slusd)
          .Case("slusd_i",         kS_slusd_i)
          .Case("slusdp",          kS_slusdp)
          .Case("slusdp_i",        kS_slusdp_i)
          .Case("slusho",          kS_slusho)
          .Case("slusho_i",        kS_slusho_i)
          .Case("slusw",           kS_slusw)
          .Case("slusw_i",         kS_slusw_i)
          .Case("sluswq",          kS_sluswq)
          .Case("sluswq_i",        kS_sluswq_i)
          .Case("so",              kS_so)
          .Case("so_r",            kS_so_r)
          .Case("splatbq",         kS_splatbq)
          .Case("splatdq",         kS_splatdq)
          .Case("splathq",         kS_splathq)
          .Case("splatwq",         kS_splatwq)
          .Case("sq",              kS_sq)
          .Case("sq_r",            kS_sq_r)
          .Case("srabx",           kS_srabx)
          .Case("srabx_i",         kS_srabx_i)
          .Case("srad",            kS_srad)
          .Case("srad_i",          kS_srad_i)
          .Case("sradp",           kS_sradp)
          .Case("sradp_i",         kS_sradp_i)
          .Case("sraho",           kS_sraho)
          .Case("sraho_i",         kS_sraho_i)
          .Case("sraw",            kS_sraw)
          .Case("sraw_i",          kS_sraw_i)
          .Case("srawq",           kS_srawq)
          .Case("srawq_i",         kS_srawq_i)
          .Case("srlbx",           kS_srlbx)
          .Case("srlbx_i",         kS_srlbx_i)
          .Case("srld",            kS_srld)
          .Case("srld_i",          kS_srld_i)
          .Case("srldp",           kS_srldp)
          .Case("srldp_i",         kS_srldp_i)
          .Case("srlho",           kS_srlho)
          .Case("srlho_i",         kS_srlho_i)
          .Case("srlw",            kS_srlw)
          .Case("srlw_i",          kS_srlw_i)
          .Case("srlwq",           kS_srlwq)
          .Case("srlwq_i",         kS_srlwq_i)
          .Case("srsbx",           kS_srsbx)
          .Case("srsbx_i",         kS_srsbx_i)
          .Case("srsd",            kS_srsd)
          .Case("srsd_i",          kS_srsd_i)
          .Case("srsdp",           kS_srsdp)
          .Case("srsdp_i",         kS_srsdp_i)
          .Case("srsho",           kS_srsho)
          .Case("srsho_i",         kS_srsho_i)
          .Case("srsw",            kS_srsw)
          .Case("srsw_i",          kS_srsw_i)
          .Case("srswq",           kS_srswq)
          .Case("srswq_i",         kS_srswq_i)
          .Case("stop",            kS_stop)
          .Case("stsud",           kS_stsud)
          .Case("stsudp",          kS_stsudp)
          .Case("stsuho",          kS_stsuho)
          .Case("stsuw",           kS_stsuw)
          .Case("stsuwq",          kS_stsuwq)
          .Case("sw",              kS_sw)
          .Case("sw_r",            kS_sw_r)
          .Case("sxbd",            kS_sxbd)
          .Case("sxhd",            kS_sxhd)
          .Case("sxwd",            kS_sxwd)
          .Case("syncgroup",       kS_syncgroup)
          .Case("tlbdinval",       kS_tlbdinval)
          .Case("tlbiinval",       kS_tlbiinval)
          .Case("tlbprobe",        kS_tlbprobe)
          .Case("tlbread",         kS_tlbread)
          .Case("tlbwrite",        kS_tlbwrite)
          .Case("truncdwq",        kS_truncdwq)
          .Case("trunchbx",        kS_trunchbx)
          .Case("truncwho",        kS_truncwho)
          .Case("waitit",          kS_waitit)
          .Case("wfxl",            kS_wfxl)
          .Case("wfxm",            kS_wfxm)
          .Case("widenqbho",       kS_widenqbho)
          .Case("widenqhwq",       kS_widenqhwq)
          .Case("widenqwdp",       kS_widenqwdp)
          .Case("widensbho",       kS_widensbho)
          .Case("widenshwq",       kS_widenshwq)
          .Case("widenswdp",       kS_widenswdp)
          .Case("widenzbho",       kS_widenzbho)
          .Case("widenzhwq",       kS_widenzhwq)
          .Case("widenzwdp",       kS_widenzwdp)
          .Case("zxbd",            kS_zxbd)
          .Case("zxhd",            kS_zxhd)
          .Case("zxwd",            kS_zxwd)
          .Default(nullptr);
  if (!row)
    return nullptr;
  return row[format ? static_cast<unsigned>(*format) : kBareFormatSlot];
}

} // namespace lvx
} // namespace mlir

#endif // LVX_SCHEDULING_INC
