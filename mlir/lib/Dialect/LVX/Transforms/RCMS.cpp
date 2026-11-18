//===- RCMS.cpp - The modulo schedule as an integer program ---------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// RCMS, resource-constrained modulo scheduling, as one engine of the modulo
// scheduling framework (ModuloScheduling.h). A port of lvx-gcc's
// config/lvx/lvx-rcms.cc, which is itself a port of the `Dinechin' arm of
// LAO's Formulation.c.
//
// THE FORMULATION is the time-indexed one of Dupont de Dinechin's
// habilitation, chapter 2: a binary x_i_t per operation and date in its
// window, one assignment row per operation, one row per dependence, and one
// row per (resource, residue) -- (2.17). At a fixed II the whole thing is
// linear: II*omega and II*k are coefficients rather than products of
// variables. That is what the engine seam buys, and why the ladder stays in
// the framework rather than here.
//
// THE OBJECTIVE is MCRL, the minimum cumulative register lifetime, by
// default: one integer killer k_i per value, k_i >= date(j) + II*omega for
// every reader j, minimising sum width_i * (k_i - date(i)). lvx-gcc measured
// the makespan objective first and found it fights the allocator -- a
// compressed modulo schedule holds more values in flight -- so that the
// commonest reason a solved schedule was thrown away was a kernel that would
// not colour. Each value is weighted by its tuple width, a pair 2 and a quad
// 4, since that is what the allocator has to fit. The makespan (1) and plain
// feasibility (0) remain, over exactly the same rows.
//
// TWO FORMS OF THE SAME ROWS, `rcms-deps`. Aggregated, a dependence is one
// row over the average dates, sum t*x_i_t - sum t*x_j_t <= -(theta -
// II*omega), and a lifetime one row per flow arc over an integer killer.
// Disaggregated -- LAO's default (Formulation_buildDependencesDinechin,
// OptimizeRCMSSolving_AggrDeps off) -- a dependence is one row per date t,
// "i at t or later and j before t + theta - II*omega are not both true", and
// the killer is a time-indexed node with an assignment row, each flow arc
// i -> j becoming the arc j -> killer(i) of latency II*omega. The LP
// relaxation of the second constrains every date rather than the average,
// and both have the same integer optimum. The model text is lvx-gcc's,
// row for row and name for name, so the two ports' files diff.
//
// MMRP, THE MINIMUM MAXIMUM REGISTER PRESSURE (objective 3; 4 is MMRP
// then MCRL in one solve, R weighted above any MCRL): the modulo RCISP of
// Dinechin 2006, "Instruction Scheduling Problems and their Application to
// the ST200", §3.6, with the register availability R a variable. One row per
// residue tau counts the registers live in kernel cycle tau -- every cycle
// tau + k*II of the flat schedule folded together -- and bounds it by R;
// `rcms-max-pressure` bounds R under any objective. A value occupies
// [date + write, killer], the kernel allocator's interval
// (RegisterAllocation.cpp, kernelOccupancyOf): the write stage is the
// opcode's, a per-value offset where lvx-gcc has e_i = 1 for every value,
// and the killer arcs carry the reader's read stage. A value the code after
// the loop reads gets a killer arc from every node, latency II -- lvx-gcc
// LMS's occ_last rule. Row and variable names are lvx-gcc's (press_<tau>, R,
// exit_<i>_<j>), so the models diff; the coefficients differ by the offsets.
//
// THE SOLVER IS A SEPARATE PROCESS. Nothing is linked into mlir-opt: the
// model is CPLEX LP, written to a file, solved by a program named on the
// command line and called as `<solver> <model> <solution> <seconds>`, and
// read back as a STATUS line and name/value pairs. The model file is an
// artefact that a different solver can re-solve, which is the only way to
// tell a formulation bug from a solver bug. lvx-csw/validation/cms carries
// the wrappers.
//
// AND THAT IS SAFE because the framework verifies whatever comes back
// against every arc and the modulo reservation table before it can reach
// the construction. A wrong solution is a refusal, never wrong code.
//
//===----------------------------------------------------------------------===//

#include "mlir/Dialect/LVX/Transforms/ModuloScheduling.h"

#include "mlir/Dialect/LVXFunc/IR/LVXFunc.h"

#include "llvm/ADT/StringExtras.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/Path.h"
#include "llvm/Support/Program.h"
#include "llvm/Support/raw_ostream.h"

#include <limits>

#define DEBUG_TYPE "lvx-modulo-schedule"

using namespace mlir;
using namespace mlir::lvx;

namespace {

/// A date beyond which no window may run. The horizon is derived from the
/// critical path, so this only bounds a pathological graph.
constexpr int64_t kMaxHorizon = 4096;

struct Window {
  int64_t lo; ///< earliest date, LAO's earlyDates
  int64_t hi; ///< latest date, LAO's lateDates
};

/// An arc into value `src`'s killer: killer(src) >= date(dst) + l.
struct KillerArc {
  unsigned src, dst;
  int64_t l;
  std::string name; ///< its row: life_<a> or exit_<i>_<j>
};

class RCMSEngine : public ModuloEngine {
public:
  RCMSEngine(const ModuloProblem &p, const RCMSOptions &o) : p(p), o(o) {
    // The span an operation occupies for the horizon and the makespan rows:
    // its longest outgoing flow latency, and at least the cycle it issues in.
    length.assign(p.numNodes(), 1);
    for (const ModuloArc &a : p.arcs)
      if (a.kind == ModuloArcKind::RegRaw)
        length[a.src] = std::max(length[a.src], a.theta);
    for (unsigned i = 0; i != p.numNodes(); ++i)
      anyLife |= weightOf(i) != 0;
    if (auto func = p.loop->getParentOfType<lvx_func::FuncOp>())
      funcName = func.getSymName().str();
  }

  StringRef name() const override { return "rcms"; }
  bool honoursResources() const override { return true; }

  bool scheduleAtII(int64_t ii, SmallVectorImpl<int64_t> &dates,
                    std::string &why) override;

  /// Writes the model at `ii` to `os` -- or, with `check`, tests those dates
  /// against every row the model would hold. One function read two ways: a
  /// checker that walked its own idea of the model would check nothing.
  bool model(int64_t ii, llvm::raw_ostream *os, ArrayRef<int64_t> check,
             std::string &why) const;

private:
  bool windows(int64_t ii, std::string &why);
  bool solve(StringRef modelPath, StringRef solPath, std::string &why) const;
  bool read(StringRef solPath, SmallVectorImpl<int64_t> &dates,
            std::string &why) const;
  /// The pressure rows and R: under MMRP (3), MMRP then MCRL (4), or a
  /// register bound under any objective.
  bool pressure() const {
    return o.objective == 3 || o.objective == 4 || o.maxPressure || o.pool;
  }
  bool mcrl() const {
    return (o.objective == 2 || o.objective == 4) && anyLife;
  }
  bool spanObjective() const { return o.objective <= 2 && !mcrl(); }
  /// The registers a value is priced at: its tuple width when the loop reads
  /// it, and, with the pressure rows on, when the code after the loop does.
  unsigned weightOf(unsigned i) const {
    unsigned w = p.width[i];
    if (o.objective == 3 || o.objective == 4 || o.maxPressure || o.pool)
      w = std::max(w, p.exitWidth[i]);
    return w;
  }
  /// R's upper bound: the bound asked for, the allocatable pool less what is
  /// live through the loop, or the register file.
  int64_t maxPressure() const {
    if (o.maxPressure)
      return *o.maxPressure;
    if (o.pool)
      return std::max<int64_t>(0, static_cast<int64_t>(o.registers) -
                                      p.liveThrough);
    return 64;
  }
  int64_t foldedPressure(int64_t ii, ArrayRef<int64_t> dates,
                         ArrayRef<int64_t> kill, bool occupancy = false) const;
  /// The killer arcs the model holds; with `occupancy`, those the pressure
  /// rows would hold whatever the objective, for reporting a pressure.
  SmallVector<KillerArc> killerArcs(int64_t ii, bool occupancy = false) const;
  /// Each value's killer date for `dates`: max over its killer arcs.
  SmallVector<int64_t> killersOf(int64_t ii, ArrayRef<int64_t> dates,
                                 bool occupancy = false) const;

  const ModuloProblem &p;
  RCMSOptions o;
  SmallVector<int64_t> length;
  bool anyLife = false;
  std::string funcName = "anonymous";
  /// Recomputed per interval.
  SmallVector<Window> win;
  int64_t horizon = 0;
  unsigned serial = 0;
  /// From the last solution read: its status and R, if it has one.
  mutable std::string status;
  mutable std::optional<int64_t> solvedR;
};

} // namespace

/// THE WINDOWS, LAO's earlyDates/lateDates: the longest path from a virtual
/// source gives the earliest date and the longest path to a virtual sink the
/// latest, both over the arc weights theta - II*omega -- which is where the
/// II enters, and why this is per interval. A positive cycle means II is
/// below the graph's own period: a refusal, and the ladder moves on.
bool RCMSEngine::windows(int64_t ii, std::string &why) {
  unsigned n = p.numNodes();
  SmallVector<int64_t> asap(n, 0), alap(n, 0);
  auto weight = [&](const ModuloArc &a) { return a.theta - ii * a.omega; };

  for (unsigned pass = 0; pass <= n; ++pass) {
    bool moved = false;
    for (const ModuloArc &a : p.arcs)
      if (asap[a.src] + weight(a) > asap[a.dst]) {
        asap[a.dst] = asap[a.src] + weight(a);
        moved = true;
      }
    if (!moved)
      break;
    if (pass == n) {
      why = "positive cycle, II below the graph's period";
      return false;
    }
  }

  // The horizon: the critical path plus `margin` intervals, so that an
  // operation can be placed that many stages later than its earliest. Zero
  // makes the model smallest and can make a feasible II look infeasible.
  int64_t h = 0;
  for (unsigned i = 0; i != n; ++i)
    h = std::max(h, asap[i] + length[i]);
  h += static_cast<int64_t>(o.margin) * ii;
  if (h > kMaxHorizon) {
    why = "horizon too large";
    return false;
  }
  horizon = h;

  for (unsigned i = 0; i != n; ++i)
    alap[i] = h - length[i];
  for (unsigned pass = 0; pass <= n; ++pass) {
    bool moved = false;
    for (const ModuloArc &a : p.arcs)
      if (alap[a.dst] - weight(a) < alap[a.src]) {
        alap[a.src] = alap[a.dst] - weight(a);
        moved = true;
      }
    if (!moved)
      break;
    if (pass == n) {
      why = "positive cycle on the backward pass";
      return false;
    }
  }

  win.assign(n, Window{0, 0});
  for (unsigned i = 0; i != n; ++i) {
    win[i] = {asap[i], alap[i]};
    if (win[i].hi < win[i].lo) {
      why = "empty window";
      return false;
    }
  }
  return true;
}

bool RCMSEngine::model(int64_t ii, llvm::raw_ostream *os,
                       ArrayRef<int64_t> check, std::string &why) const {
  unsigned n = p.numNodes();
  auto weight = [&](const ModuloArc &a) { return a.theta - ii * a.omega; };
  auto x = [&](unsigned i, int64_t t) {
    return "x_" + std::to_string(i) + "_" + std::to_string(t);
  };
  auto k = [&](unsigned i, int64_t t) {
    return "k_" + std::to_string(i) + "_" + std::to_string(t);
  };
  // ` %+d name`, printf's spelling, which lvx-gcc's model files use.
  auto coef = [](llvm::raw_ostream &out, int64_t c, const std::string &name) {
    out << ' ' << (c >= 0 ? "+" : "") << c << ' ' << name;
  };
  // `sum_t coef(t) * x_i_t` over i's window, the zero terms left out.
  auto dated = [&](llvm::raw_ostream &out, unsigned i, int64_t sign) {
    for (int64_t t = win[i].lo; t <= win[i].hi; ++t)
      if (t != 0)
        coef(out, sign * t, x(i, t));
  };
  bool disagg = !o.aggregated;
  bool press = pressure();
  bool wantMcrl = mcrl();
  bool wantSpan = spanObjective();
  // The killers exist for MCRL and for the pressure rows, and are a
  // time-indexed node whenever the rows need them dated (disaggregated, or
  // any pressure row: a press row counts a value live up to its killer).
  bool killers = wantMcrl || press;
  bool timeKillers = killers && (disagg || press);

  SmallVector<KillerArc> karcs = killerArcs(ii);
  SmallVector<int64_t> klo(n, std::numeric_limits<int64_t>::min());
  SmallVector<int64_t> khi(n, std::numeric_limits<int64_t>::min());
  SmallVector<int64_t> kdate(n, std::numeric_limits<int64_t>::min());
  int64_t kmax = 0;
  for (const KillerArc &a : karcs) {
    klo[a.src] = std::max(klo[a.src], win[a.dst].lo + a.l);
    khi[a.src] = std::max(khi[a.src], win[a.dst].hi + a.l);
    if (!check.empty())
      kdate[a.src] = std::max(kdate[a.src], check[a.dst] + a.l);
  }
  for (unsigned i = 0; i != n; ++i) {
    if (!killers || !weightOf(i))
      continue;
    khi[i] = std::min(khi[i], horizon + ii + 1);
    if (timeKillers && khi[i] < klo[i]) {
      why = "empty killer window";
      return false;
    }
    kmax = std::max(kmax, khi[i]);
  }
  // The killer's MCRL terms: sum_t t * k_i_t, or the aggregated integer.
  auto killerTerms = [&](llvm::raw_ostream &out, unsigned i, int64_t w) {
    if (!timeKillers) {
      out << " + " << w << " k_" << i;
      return;
    }
    for (int64_t t = klo[i]; t <= khi[i]; ++t)
      if (t != 0)
        coef(out, w * t, k(i, t));
  };

  if (os) {
    *os << "\\ RCMS fn=" << funcName << " ii=" << ii << " n=" << n
        << " horizon=" << horizon << "\n";
    *os << "Minimize\n obj:";
    if (o.objective == 3) {
      *os << " R";
    } else if (wantMcrl) {
      // sum width_i * (k_i - date(i)); under objective 4 below a weight on R
      // larger than any MCRL, so R is minimised first.
      if (o.objective == 4) {
        int64_t big = 1;
        for (unsigned i = 0; i != n; ++i)
          big += static_cast<int64_t>(weightOf(i)) * (kmax + 1);
        *os << " + " << big << " R";
      }
      for (unsigned i = 0; i != n; ++i)
        if (weightOf(i))
          killerTerms(*os, i, weightOf(i));
      for (unsigned i = 0; i != n; ++i)
        if (weightOf(i))
          dated(*os, i, -static_cast<int64_t>(weightOf(i)));
    } else if (o.objective == 4) {
      *os << " R";
    } else {
      *os << ' ' << (o.objective == 0 ? "0 " : "") << "span";
    }
    *os << "\nSubject To\n";
  }

  // Assignment: sum_t x_i_t = 1.
  for (unsigned i = 0; i != n; ++i) {
    if (!check.empty() && (check[i] < win[i].lo || check[i] > win[i].hi)) {
      why = "date outside the window";
      return false;
    }
    if (os) {
      *os << " asg_" << i << ":";
      for (int64_t t = win[i].lo; t <= win[i].hi; ++t)
        *os << " + " << x(i, t);
      *os << " = 1\n";
    }
  }

  // An arc of latency w from `src` (dated by `sv`) to `dst` (by `dv`),
  // disaggregated: for each date t, src at t or later and dst before t + w
  // cannot both hold. A row with either sum empty never binds and is not
  // written. Checked as written, so a mis-emitted row is caught.
  auto disaggregated = [&](StringRef name, Window si, int64_t sd,
                           auto srcName, Window dj, int64_t dd, auto dstName,
                           int64_t w, const std::string &what) {
    for (int64_t t = std::max(si.lo, dj.lo - w + 1); t <= si.hi; ++t) {
      int64_t last = std::min(t + w - 1, dj.hi);
      if (last < dj.lo)
        continue;
      if (!check.empty() &&
          (sd >= t && sd <= si.hi) + (dd >= dj.lo && dd <= last) > 1) {
        why = what + " violated";
        return false;
      }
      if (os) {
        *os << ' ' << name << '_' << t << ':';
        for (int64_t s = t; s <= si.hi; ++s)
          *os << " + " << srcName(s);
        for (int64_t s = dj.lo; s <= last; ++s)
          *os << " + " << dstName(s);
        *os << " <= 1\n";
      }
    }
    return true;
  };

  // Dependences: date(j) - date(i) >= theta - II*omega.
  for (auto [ak, a] : llvm::enumerate(p.arcs)) {
    int64_t w = weight(a);
    if (a.src == a.dst) {
      // A self arc has no variables: satisfiable iff its weight is not
      // positive. An empty row would be an LP syntax error, and dropping it
      // silently would lose a real infeasibility.
      if (w > 0) {
        why = "positive self arc";
        return false;
      }
      continue;
    }
    if (disagg) {
      // LAO's Formulation_buildDependencesDinechin, disaggregated.
      unsigned src = a.src, dst = a.dst;
      if (!disaggregated(
              "dep_" + std::to_string(ak), win[src],
              check.empty() ? 0 : check[src], [&](int64_t s) { return x(src, s); },
              win[dst], check.empty() ? 0 : check[dst],
              [&](int64_t s) { return x(dst, s); }, w,
              "disaggregated dependence " + std::to_string(ak)))
        return false;
      continue;
    }
    if (!check.empty() && check[a.dst] - check[a.src] < w) {
      why = "dependence " + std::to_string(ak) + " violated";
      return false;
    }
    if (os) {
      std::string terms;
      llvm::raw_string_ostream t(terms);
      dated(t, a.src, 1);
      dated(t, a.dst, -1);
      // Both windows {0}: no terms, and the windows already satisfy it,
      // having been computed from these very arcs.
      if (!terms.empty())
        *os << " dep_" << ak << ":" << terms << " <= " << -w << "\n";
    }
  }

  // Resources: one row per (resource, residue), exact because every
  // reservation is charged at issue. LAO's kill: a row whose worst case fits
  // can never bind, and is not written.
  for (unsigned r = 0; r != kNumResources; ++r) {
    unsigned avail = kResourceAvailability[r];
    for (int64_t tau = 0; tau != ii; ++tau) {
      unsigned most = 0, used = 0;
      for (unsigned i = 0; i != n; ++i) {
        unsigned b = p.demand[i][r];
        if (!b)
          continue;
        for (int64_t t = win[i].lo; t <= win[i].hi; ++t)
          if (((t % ii) + ii) % ii == tau) {
            most += b;
            break;
          }
        if (!check.empty() && ((check[i] % ii) + ii) % ii == tau)
          used += b;
      }
      if (!check.empty() && used > avail) {
        why = (kResourceName[r] + " oversubscribed").str();
        return false;
      }
      if (os && most > avail) {
        *os << " res_" << kResourceName[r] << "_" << tau << ":";
        for (unsigned i = 0; i != n; ++i) {
          unsigned b = p.demand[i][r];
          if (!b)
            continue;
          for (int64_t t = win[i].lo; t <= win[i].hi; ++t)
            if (((t % ii) + ii) % ii == tau)
              *os << " + " << b << ' ' << x(i, t);
        }
        *os << " <= " << avail << "\n";
      }
    }
  }

  // The lifetimes: killer(i) >= date(dst) + l for every killer arc. A read in
  // a later iteration keeps the value alive that many intervals longer;
  // without the term a loop-carried value would be priced as dying in its own
  // iteration. Aggregated: one row per arc over the integer killer, or over
  // the time-indexed one when the pressure rows date it. Disaggregated:
  // kasg_i gives the killer one date, and each killer arc is written as a
  // dependence.
  if (killers) {
    for (unsigned i = 0; i != n; ++i) {
      if (!weightOf(i) || check.empty())
        continue;
      int64_t lo = timeKillers ? klo[i] : 0;
      int64_t hi = timeKillers ? khi[i] : horizon + ii + 1;
      if (kdate[i] < lo || kdate[i] > hi) {
        why = "killer outside its window";
        return false;
      }
    }
    if (os && timeKillers)
      for (unsigned i = 0; i != n; ++i) {
        if (!weightOf(i))
          continue;
        *os << " kasg_" << i << ":";
        for (int64_t t = klo[i]; t <= khi[i]; ++t)
          *os << " + " << k(i, t);
        *os << " = 1\n";
      }
    for (const KillerArc &a : karcs) {
      if (!disagg) {
        // The killer is free above the last read, and the checked killer is
        // that read, so the row holds by construction; the window test above
        // is the part a schedule can violate.
        if (os) {
          *os << ' ' << a.name << ':';
          if (timeKillers) {
            for (int64_t t = klo[a.src]; t <= khi[a.src]; ++t)
              if (t != 0)
                coef(*os, t, k(a.src, t));
          } else {
            *os << " k_" << a.src;
          }
          dated(*os, a.dst, -1);
          *os << " >= " << a.l << "\n";
        }
        continue;
      }
      unsigned src = a.src, dst = a.dst;
      if (!disaggregated(
              a.name, win[dst], check.empty() ? 0 : check[dst],
              [&](int64_t s) { return x(dst, s); },
              Window{klo[src], khi[src]}, check.empty() ? 0 : kdate[src],
              [&](int64_t s) { return k(src, s); }, a.l,
              "disaggregated lifetime " + a.name))
        return false;
    }
  }

  // THE PRESSURE, MMRP: one row per residue tau, the registers live in the
  // kernel's cycle tau, which is every cycle tau + k*II of the flat schedule
  // folded together. A value occupies [date(i) + write(i), killer(i)], both
  // ends included -- the kernel allocator's interval -- so it is live in
  // cycle c iff date(i) <= c - write(i) and not killer(i) <= c - 1. In
  // lvx-gcc's notation e_i = 1 - write(i): a per-value offset here, since
  // the write stage is the opcode's. Collected per variable, so each row has
  // one term per variable and there are only II rows.
  if (press) {
    int64_t kk = std::max(kmax, horizon) / ii + 1;
    auto count = [&](int64_t t, int64_t tau, int64_t shift) {
      int64_t c = 0;
      for (int64_t q = 0; q <= kk; ++q)
        c += t <= tau + q * ii - shift;
      return c;
    };
    if (!check.empty()) {
      int64_t folded = foldedPressure(ii, check, kdate);
      if (folded > maxPressure()) {
        why = "register pressure " + std::to_string(folded) + " above " +
              std::to_string(maxPressure());
        return false;
      }
    }
    if (os)
      for (int64_t tau = 0; tau != ii; ++tau) {
        std::string terms;
        llvm::raw_string_ostream t(terms);
        for (unsigned i = 0; i != n; ++i) {
          int64_t w = weightOf(i);
          if (!w)
            continue;
          for (int64_t s = win[i].lo; s <= win[i].hi; ++s)
            if (int64_t c = count(s, tau, p.write[i]))
              coef(t, w * c, x(i, s));
          for (int64_t s = klo[i]; s <= khi[i]; ++s)
            if (int64_t c = count(s, tau, 1))
              coef(t, -w * c, k(i, s));
        }
        *os << " press_" << tau << ":" << (terms.empty() ? " 0 R" : "")
            << terms << " - R <= 0\n";
      }
  }

  // The makespan: span >= date(i) + length(i).
  if (os && wantSpan)
    for (unsigned i = 0; i != n; ++i) {
      *os << " mk_" << i << ": span";
      dated(*os, i, -1);
      *os << " >= " << length[i] << "\n";
    }

  if (os) {
    // "Bounds" is written even when empty; "General" only over something --
    // time-indexed killers are binaries.
    bool integerK = killers && !timeKillers;
    *os << "Bounds\n";
    if (wantSpan)
      *os << " 0 <= span <= " << horizon + 1 << "\n";
    if (press)
      *os << " 0 <= R <= " << maxPressure() << "\n";
    if (integerK)
      for (unsigned i = 0; i != n; ++i)
        if (weightOf(i))
          *os << " 0 <= k_" << i << " <= " << horizon + ii + 1 << "\n";
    if (wantSpan || press || integerK)
      *os << "General\n";
    if (wantSpan)
      *os << " span\n";
    if (press)
      *os << " R\n";
    if (integerK)
      for (unsigned i = 0; i != n; ++i)
        if (weightOf(i))
          *os << " k_" << i << "\n";
    *os << "Binaries\n";
    for (unsigned i = 0; i != n; ++i)
      for (int64_t t = win[i].lo; t <= win[i].hi; ++t)
        *os << ' ' << x(i, t) << "\n";
    if (timeKillers)
      for (unsigned i = 0; i != n; ++i)
        if (weightOf(i))
          for (int64_t t = klo[i]; t <= khi[i]; ++t)
            *os << ' ' << k(i, t) << "\n";
    *os << "End\n";
  }
  return true;
}

/// THE KILLER ARCS. Value i's killer dates max over its arcs of date(dst) +
/// l. A register flow arc i -> j gives one, l = II*omega; with the pressure
/// rows on, l also takes the reader's read cycle, since the kernel allocator
/// holds the register through the stage the last reader reads it in
/// (RegisterAllocation.cpp, kernelOccupancyOf). A value the code after the
/// loop reads gets an arc from every node of latency II -- lvx-gcc LMS's
/// occ_last rule: the allocator keeps a value read past the kernel for the
/// whole body.
SmallVector<KillerArc> RCMSEngine::killerArcs(int64_t ii,
                                              bool occupancy) const {
  SmallVector<KillerArc> karcs;
  bool press = pressure() || occupancy;
  if (!mcrl() && !press)
    return karcs;
  unsigned n = p.numNodes();
  for (auto [ak, a] : llvm::enumerate(p.arcs))
    if (a.kind == ModuloArcKind::RegRaw && (weightOf(a.src) || occupancy))
      karcs.push_back({a.src, a.dst, ii * a.omega + (press ? a.read : 0),
                       "life_" + std::to_string(ak)});
  if (press)
    for (unsigned i = 0; i != n; ++i)
      if (p.exitWidth[i])
        for (unsigned j = 0; j != n; ++j)
          karcs.push_back(
              {i, j, ii, "exit_" + std::to_string(i) + "_" + std::to_string(j)});
  return karcs;
}

SmallVector<int64_t> RCMSEngine::killersOf(int64_t ii, ArrayRef<int64_t> dates,
                                           bool occupancy) const {
  SmallVector<int64_t> kill(p.numNodes(), std::numeric_limits<int64_t>::min());
  for (const KillerArc &a : killerArcs(ii, occupancy))
    kill[a.src] = std::max(kill[a.src], dates[a.dst] + a.l);
  return kill;
}

/// The registers live in the kernel's busiest cycle, for these dates and
/// killers: the press rows evaluated, with the same interval.
int64_t RCMSEngine::foldedPressure(int64_t ii, ArrayRef<int64_t> dates,
                                   ArrayRef<int64_t> kill,
                                   bool occupancy) const {
  int64_t most = 0;
  for (int64_t tau = 0; tau != ii; ++tau) {
    int64_t live = 0;
    for (unsigned i = 0; i != p.numNodes(); ++i) {
      int64_t w = occupancy ? std::max(p.width[i], p.exitWidth[i])
                            : weightOf(i);
      if (!w)
        continue;
      // Cycles c = tau + q*II in [date + write, killer].
      int64_t from = dates[i] + p.write[i], to = kill[i];
      for (int64_t c = tau; c <= to; c += ii)
        live += c >= from ? w : 0;
    }
    most = std::max(most, live);
  }
  return most;
}

bool RCMSEngine::solve(StringRef modelPath, StringRef solPath,
                       std::string &why) const {
  if (o.solver.empty()) {
    why = "no solver configured (rcms-solver=)";
    return false;
  }
  std::string program = o.solver;
  if (!llvm::sys::path::is_absolute(program) &&
      !llvm::sys::path::has_parent_path(program)) {
    llvm::ErrorOr<std::string> found = llvm::sys::findProgramByName(program);
    if (!found) {
      why = "solver '" + program + "' not found on PATH";
      return false;
    }
    program = *found;
  }
  std::string secs = std::to_string(std::max(1u, o.seconds));
  SmallVector<StringRef> args = {o.solver, modelPath, solPath, secs};
  std::string error;
  int rc = llvm::sys::ExecuteAndWait(program, args, /*Env=*/std::nullopt,
                                     /*Redirects=*/{}, /*SecondsToWait=*/0,
                                     /*MemoryLimit=*/0, &error);
  if (rc != 0) {
    why = rc < 0 ? "could not run the solver: " + error
                 : "the solver exited with " + std::to_string(rc);
    return false;
  }
  return true;
}

/// The answer: a STATUS line, then name/value pairs. INFEASIBLE must stay
/// distinct from UNKNOWN -- feasibility at a fixed II is NP-complete, so a
/// solver that ran out of time has proved nothing, and reading the two alike
/// would make the ladder's minimum an upper bound wearing a minimum's name.
bool RCMSEngine::read(StringRef solPath, SmallVectorImpl<int64_t> &dates,
                      std::string &why) const {
  auto buffer = llvm::MemoryBuffer::getFile(solPath);
  if (!buffer) {
    why = "no solution file";
    return false;
  }
  unsigned n = p.numNodes();
  SmallVector<int64_t> got(n, -1);
  bool haveStatus = false;
  SmallVector<StringRef> lines;
  (*buffer)->getBuffer().split(lines, '\n', -1, false);
  for (StringRef line : lines) {
    line = line.trim();
    if (line.empty() || line.starts_with("\\"))
      continue;
    auto [name, value] = line.split(' ');
    value = value.trim();
    if (!haveStatus) {
      if (name != "STATUS")
        continue;
      haveStatus = true;
      status = value.str();
      solvedR.reset();
      if (value == "OPTIMAL" || value == "FEASIBLE")
        continue;
      why = value == "INFEASIBLE" ? "infeasible at this II (proved)"
                                  : "the solver returned no answer (unknown)";
      return false;
    }
    double v;
    if (name == "R" && !value.getAsDouble(v)) {
      solvedR = static_cast<int64_t>(std::llround(v));
      continue;
    }
    if (value.getAsDouble(v) || v < 0.5 || !name.consume_front("x_"))
      continue;
    auto [is, ts] = name.split('_');
    unsigned i;
    int64_t t;
    if (is.getAsInteger(10, i) || ts.getAsInteger(10, t) || i >= n)
      continue;
    if (got[i] >= 0) {
      why = "two dates for one operation";
      return false;
    }
    got[i] = t;
  }
  if (!haveStatus) {
    why = "the solution has no STATUS line";
    return false;
  }
  for (int64_t d : got)
    if (d < 0) {
      why = "the solution does not place every operation";
      return false;
    }
  dates.assign(got.begin(), got.end());
  return true;
}

bool RCMSEngine::scheduleAtII(int64_t ii, SmallVectorImpl<int64_t> &dates,
                              std::string &why) {
  if (p.numNodes() == 0) {
    why = "empty loop";
    return false;
  }
  if (!windows(ii, why))
    return false;

  // With a directory the model is kept, named by the function, a serial and
  // the interval: the ladder asks one loop for several intervals and a
  // function holds several loops, and a name without both keeps the last
  // model only.
  SmallString<128> modelPath, solPath;
  bool keep = !o.dir.empty();
  if (keep) {
    modelPath = o.dir;
    llvm::sys::path::append(modelPath, funcName + "." +
                                           std::to_string(serial++) + ".ii" +
                                           std::to_string(ii) + ".lp");
    solPath = modelPath;
    solPath += ".sol";
  } else if (llvm::sys::fs::createTemporaryFile("lvx-rcms", "lp", modelPath) ||
             llvm::sys::fs::createTemporaryFile("lvx-rcms", "sol", solPath)) {
    why = "cannot create a temporary file";
    return false;
  }

  bool ok = [&] {
    std::error_code ec;
    llvm::raw_fd_ostream os(modelPath, ec);
    if (ec) {
      why = "cannot write the model: " + ec.message();
      return false;
    }
    if (!model(ii, &os, {}, why))
      return false;
    os.close();
    return solve(modelPath, solPath, why) && read(solPath, dates, why);
  }();

  // The answer against the model it answers: a solution that breaks a row
  // the model holds is a reader or solver bug, named as such rather than
  // left to surface as a dependence refusal.
  if (ok) {
    std::string bad;
    if (!model(ii, nullptr, dates, bad)) {
      why = "the solution breaks the model: " + bad;
      ok = false;
    }
  }
  // MMRP solved to optimality: the pressure of the dates is R, or the model
  // and the check disagree about what a register is.
  if (ok && o.objective == 3 && status == "OPTIMAL" && solvedR) {
    int64_t folded = foldedPressure(ii, dates, killersOf(ii, dates));
    if (folded != *solvedR) {
      why = "the solution breaks the model: its register pressure is " +
            std::to_string(folded) + ", the solver's R " +
            std::to_string(*solvedR);
      ok = false;
    }
  }
  LLVM_DEBUG(if (ok) llvm::dbgs()
             << "lvx-modulo-schedule: rcms " << funcName << " ii=" << ii
             << " pressure="
             << foldedPressure(ii, dates, killersOf(ii, dates, true),
                               /*occupancy=*/true)
             << (solvedR ? " R=" + std::to_string(*solvedR) : "") << "\n");
  LLVM_DEBUG(llvm::dbgs() << "lvx-modulo-schedule: rcms " << funcName
                          << " ii=" << ii << " horizon=" << horizon << ": "
                          << (ok ? "solved" : why) << "\n");
  if (!keep) {
    llvm::sys::fs::remove(modelPath);
    llvm::sys::fs::remove(solPath);
  }
  return ok;
}

std::unique_ptr<ModuloEngine>
mlir::lvx::createRCMSEngine(const ModuloProblem &p, const RCMSOptions &o) {
  return std::make_unique<RCMSEngine>(p, o);
}
