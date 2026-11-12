//===- ModuloScheduling.h - The modulo scheduling framework -----*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// The framework/engine split of LVX GCC's late modulo scheduling (LMS,
// lvx-gcc config/lvx/lvx-lms.h), in this IR.
//
// The FRAMEWORK owns everything that is about the loop rather than about how
// to search: the dependence graph over the body once, with each arc's latency
// and iteration distance; the two bounds, RecMII and ResMII; the II ladder;
// and acceptance -- every arc, the modulo reservation table for an engine
// that claims to honour it, and the back half, which is modulo variable
// expansion, register allocation and the pipeline construction
// (`pipelineAllocates`).
//
// An ENGINE chooses dates at one given initiation interval and nothing else.
// Two are built:
//
//   - DSP, decomposed software pipelining: PLC's resource-free schedule at
//     the period, the resources left to `-lvx-schedule`;
//   - RCMS, resource-constrained modulo scheduling as the time-indexed
//     integer program of Dupont de Dinechin's habilitation (2.17), with the
//     minimum cumulative register lifetime (MCRL) as its objective, solved by
//     an external program.
//
// Asked for the same II, two engines differ in the dates and in nothing else,
// which is what lets them be compared on one corpus. See
// lvx-mlir/docs/SoftwarePipelining.md §8, step 6.
//
//===----------------------------------------------------------------------===//

#ifndef MLIR_DIALECT_LVX_TRANSFORMS_MODULOSCHEDULING_H
#define MLIR_DIALECT_LVX_TRANSFORMS_MODULOSCHEDULING_H

#include "mlir/Dialect/LVX/IR/LVXScheduling.h"
#include "mlir/Dialect/LVX/Transforms/RegisterAllocation.h"
#include "mlir/Dialect/LVXSCF/IR/LVXSCF.h"
#include "mlir/Support/LLVM.h"

#include "llvm/ADT/SmallVector.h"

#include <array>
#include <memory>
#include <optional>
#include <string>

namespace mlir {
namespace lvx {

class ParametricLabelCorrecting;

/// On a loop: its dates are to be kept, not only its stages. Set by the
/// framework for an engine whose dates fit the modulo reservation table,
/// which DSP's do not.
constexpr llvm::StringLiteral kKeepDatesAttr = "lvx.keep_dates";
/// On a kernel op, when its loop kept its dates: the cycle in the kernel the
/// engine gave it, which `-lvx-schedule` releases it at and places first.
/// An op the construction or the allocator added has none, and fills what
/// the dated ones leave.
constexpr llvm::StringLiteral kKernelDateAttr = "lvx.kernel_date";

/// Where an arc came from: GCC's `lvx_lms_arc_kind`, restricted to what this
/// IR has. SSA leaves no register anti or output dependence but a tie's, and
/// `lvx_scf.for` has no early exit, so there is no control kind.
enum class ModuloArcKind {
  RegRaw,   ///< a value read, possibly in a later iteration
  RegWar,   ///< a tie: the reader of the tied operand precedes the overwrite
  MemIntra, ///< two accesses, one a write, in one iteration
  MemCross, ///< the same pair across the back edge, distance one
};

/// One arc of the dependence graph. At initiation interval II it constrains a
/// modulo schedule as
///
///   date(dst) - date(src) >= theta - omega * II.
///
/// The graph is over the loop body once, one node per body operation, with
/// the distance carried here rather than by copying the body.
struct ModuloArc {
  unsigned src;
  unsigned dst;
  int64_t theta;
  int64_t omega;
  ModuloArcKind kind;
};

/// What one operation reserves when it issues, in `Resource.yml`'s counters.
using ResourceVector = std::array<unsigned, kNumResources>;

/// The problem one engine is asked to schedule: GCC's `lvx_lms_problem`.
struct ModuloProblem {
  lvx_scf::ForOp loop;
  /// The body in program order, terminator excluded. Node i is ops[i].
  SmallVector<Operation *> ops;
  /// Whether the body reads the induction variable, in which case node
  /// `ops.size()` stands for its increment: the `lvx_scf.for` step is
  /// implicit in the body, but the kernel materialises it, one `addd` an
  /// iteration, and an engine that was not charged for it leaves no slot for
  /// it. It has an `addd`'s reservation, an arc to each reader and its own
  /// recurrence, and no operation; an engine dates it like any node, and only
  /// the operations' dates are written.
  bool induction = false;
  SmallVector<ModuloArc> arcs;
  /// Per operation, what it reserves. A BCU prefix is charged one BCU on
  /// every op that carries it: the bundler shares one syllable between ops
  /// with the same prefix, so this is an upper bound, and lvx-gcc found the
  /// cost of the opposite error -- its model left prefixes out, and gas
  /// refused the bundles.
  SmallVector<ResourceVector> demand;
  /// Per operation, the registers its value occupies -- 1 for a single, 2
  /// for a pair, 4 for a quad -- or 0 when no operation of the loop reads it.
  /// The weight MCRL prices a lifetime by.
  SmallVector<unsigned> width;
  int64_t recMII = 1;
  int64_t resMII = 1;

  /// The nodes an engine dates: the operations, then the induction.
  unsigned numNodes() const { return ops.size() + (induction ? 1 : 0); }

  /// max(RecMII, ResMII): where the ladder starts.
  int64_t lower() const { return std::max(recMII, resMII); }

  /// Builds the problem for `loop`'s body. Fails, with an error on the loop,
  /// on a dependence circuit of distance zero, which no period satisfies.
  static FailureOr<ModuloProblem> build(lvx_scf::ForOp loop);

  /// Adds the graph to `g`: node 0 a source with a zero arc to every
  /// operation, operation i as node i + 1.
  void addTo(ParametricLabelCorrecting &g) const;
};

/// The first arc `dates` violates at `ii`, if any.
std::optional<std::string> checkDependences(const ModuloProblem &p, int64_t ii,
                                            ArrayRef<int64_t> dates);

/// The first (resource, row) the dates oversubscribe at `ii`, if any.
std::optional<std::string> checkResources(const ModuloProblem &p, int64_t ii,
                                          ArrayRef<int64_t> dates);

/// An engine: asked for a schedule at a given II and nothing else. GCC's
/// `lvx_lms_engine`, whose prepare/finish pair is the constructor and the
/// destructor here: the per-loop work an engine must not redo per interval
/// belongs in the constructor.
class ModuloEngine {
public:
  virtual ~ModuloEngine();
  virtual StringRef name() const = 0;
  /// Whether the dates satisfy the modulo reservation table. DSP's do not --
  /// its resources are `-lvx-schedule`'s -- and the framework checks the
  /// table only for an engine that says they do.
  virtual bool honoursResources() const = 0;
  /// Fills `dates`, one per node, and returns true; or returns
  /// false with `why` naming the obstacle. Any search of the engine's own
  /// happens inside, so two engines asked for the same II differ in one
  /// thing only.
  virtual bool scheduleAtII(int64_t ii, SmallVectorImpl<int64_t> &dates,
                            std::string &why) = 0;
};

/// DSP: PLC's earliest resource-free schedule at the period.
std::unique_ptr<ModuloEngine> createDSPEngine(const ModuloProblem &p);

/// RCMS's knobs: GCC's `-mlms-rcms-*`.
struct RCMSOptions {
  /// The program run to solve one model, as
  /// `<solver> <model.lp> <solution> <seconds>`. The compiler never learns a
  /// solver's flags: a new solver is a new wrapper (lvx-csw/validation/cms).
  std::string solver;
  unsigned seconds = 10;
  /// Keep each model, and its solution, in this directory.
  std::string dir;
  /// Intervals of slack above the critical path in the horizon.
  unsigned margin = 1;
  /// 0 feasibility, 1 the makespan, 2 MCRL.
  unsigned objective = 2;
};

/// RCMS: the time-indexed integer program, solved by `options.solver`.
std::unique_ptr<ModuloEngine> createRCMSEngine(const ModuloProblem &p,
                                               const RCMSOptions &options);

/// What the ladder settled on.
struct ModuloSchedule {
  int64_t ii = 0;
  /// One per node, the operations' from zero.
  SmallVector<int64_t> dates;
  /// Whether the schedule spans more than one stage. One that does not has
  /// nothing crossing the back edge and is left unpipelined.
  bool pipelined = false;
  /// Whether the dates fit the modulo reservation table, so that the kernel
  /// can keep them through `-lvx-schedule`.
  bool fitsResources = false;
};

/// How far past its first interval the ladder goes: GCC's
/// `try_ii <= first_ii + 8`.
constexpr int64_t kMaxPeriodRaise = 8;

/// The ladder: asks `engine` for a schedule at each II from `p.lower()`
/// upward and accepts the first whose dates satisfy every arc, the modulo
/// reservation table when the engine honours it, and allocate as well as
/// the loop. Returns nothing when no II up to `kMaxPeriodRaise` past the
/// first passes; `why` then names the last refusal.
std::optional<ModuloSchedule> scheduleLoop(const ModuloProblem &p,
                                           ModuloEngine &engine,
                                           unsigned maxRegisters,
                                           std::string &why);

/// Records `s` as the schedule `-lvx-pipeline` consumes: `lvx.date` on each
/// body operation and `lvx.ii` on the loop, and `lvx.keep_dates` when the
/// dates fit the reservation table.
void annotateSchedule(const ModuloProblem &p, const ModuloSchedule &s);

/// What the driver is told: which engine, and the framework's knobs.
struct ModuloDriverOptions {
  /// "dsp" or "rcms".
  std::string engine = "dsp";
  unsigned maxRegisters = 59;
  /// Also record the period as `lvx.period`, for tests.
  bool annotatePeriod = false;
  /// When RCMS finds no schedule, ask DSP.
  bool fallback = true;
  RCMSOptions rcms;
};

/// Modulo-schedules every innermost `lvx_scf.for` of `func` with the engine
/// `options` names, and annotates those whose schedule is accepted and spans
/// more than one stage. A loop with no accepted schedule is left alone, with
/// a remark. Fails only on a loop no period can schedule.
LogicalResult moduloScheduleFunction(lvx_func::FuncOp func,
                                     const ModuloDriverOptions &options);

/// Whether `loop` is innermost: modulo scheduling is for innermost loops.
bool isInnermostLoop(lvx_scf::ForOp loop);

/// The format `-lvx-schedule` will give `op`, so the resources an engine is
/// charged are the ones the bundler will charge. Read, not set: the
/// pipeliner rewrites immediates after scheduling, and a format fixed now
/// would outlive the value it was chosen for. Defined in Schedule.cpp, beside
/// the bundler that owns the rule.
std::optional<Format> formatOf(Operation *op);

/// Whether `op` needs a BCU prefix syllable. Defined in Schedule.cpp.
bool needsBcuPrefix(Operation *op);

} // namespace lvx
} // namespace mlir

#endif // MLIR_DIALECT_LVX_TRANSFORMS_MODULOSCHEDULING_H
