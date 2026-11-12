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

class RCMSEngine : public ModuloEngine {
public:
  RCMSEngine(const ModuloProblem &p, const RCMSOptions &o) : p(p), o(o) {
    // The span an operation occupies for the horizon and the makespan rows:
    // its longest outgoing flow latency, and at least the cycle it issues in.
    length.assign(p.numNodes(), 1);
    for (const ModuloArc &a : p.arcs)
      if (a.kind == ModuloArcKind::RegRaw)
        length[a.src] = std::max(length[a.src], a.theta);
    for (unsigned w : p.width)
      anyLife |= w != 0;
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
  bool mcrl() const { return o.objective == 2 && anyLife; }

  const ModuloProblem &p;
  RCMSOptions o;
  SmallVector<int64_t> length;
  bool anyLife = false;
  std::string funcName = "anonymous";
  /// Recomputed per interval.
  SmallVector<Window> win;
  int64_t horizon = 0;
  unsigned serial = 0;
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
  // `sum_t coef(t) * x_i_t` over i's window, the zero terms left out.
  auto dated = [&](llvm::raw_ostream &out, unsigned i, int64_t sign) {
    for (int64_t t = win[i].lo; t <= win[i].hi; ++t)
      if (t != 0)
        out << ' ' << (sign * t >= 0 ? "+" : "") << sign * t << ' ' << x(i, t);
  };

  if (os) {
    *os << "\\ RCMS fn=" << funcName << " ii=" << ii << " n=" << n
        << " horizon=" << horizon << "\n";
    if (mcrl()) {
      // sum width_i * (k_i - date(i)).
      *os << "Minimize\n obj:";
      for (unsigned i = 0; i != n; ++i)
        if (p.width[i])
          *os << " + " << p.width[i] << " k_" << i;
      for (unsigned i = 0; i != n; ++i)
        if (p.width[i])
          dated(*os, i, -static_cast<int64_t>(p.width[i]));
      *os << "\nSubject To\n";
    } else {
      *os << "Minimize\n obj: " << (o.objective == 0 ? "0 " : "")
          << "span\nSubject To\n";
    }
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

  // Dependences: date(j) - date(i) >= theta - II*omega, aggregated.
  for (auto [k, a] : llvm::enumerate(p.arcs)) {
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
    if (!check.empty() && check[a.dst] - check[a.src] < w) {
      why = "dependence " + std::to_string(k) + " violated";
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
        *os << " dep_" << k << ":" << terms << " <= " << -w << "\n";
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

  // The lifetimes: k_i >= date(j) + II*omega for every flow arc i -> j. A
  // read in a later iteration keeps the value alive that many intervals
  // longer; without the term a loop-carried value would be priced as dying
  // in its own iteration. One integer per value and one row per flow arc,
  // not a time-indexed node per value.
  if (os && mcrl())
    for (auto [k, a] : llvm::enumerate(p.arcs)) {
      if (a.kind != ModuloArcKind::RegRaw || !p.width[a.src])
        continue;
      *os << " life_" << k << ": k_" << a.src;
      dated(*os, a.dst, -1);
      *os << " >= " << ii * a.omega << "\n";
    }

  // The makespan: span >= date(i) + length(i).
  if (os && !mcrl())
    for (unsigned i = 0; i != n; ++i) {
      *os << " mk_" << i << ": span";
      dated(*os, i, -1);
      *os << " >= " << length[i] << "\n";
    }

  if (os) {
    *os << "Bounds\n";
    if (!mcrl())
      *os << " 0 <= span <= " << horizon + 1 << "\n";
    else
      for (unsigned i = 0; i != n; ++i)
        if (p.width[i])
          *os << " 0 <= k_" << i << " <= " << horizon + ii + 1 << "\n";
    *os << "General\n";
    if (!mcrl())
      *os << " span\n";
    else
      for (unsigned i = 0; i != n; ++i)
        if (p.width[i])
          *os << " k_" << i << "\n";
    *os << "Binaries\n";
    for (unsigned i = 0; i != n; ++i)
      for (int64_t t = win[i].lo; t <= win[i].hi; ++t)
        *os << ' ' << x(i, t) << "\n";
    *os << "End\n";
  }
  return true;
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
      if (value == "OPTIMAL" || value == "FEASIBLE")
        continue;
      why = value == "INFEASIBLE" ? "infeasible at this II (proved)"
                                  : "the solver returned no answer (unknown)";
      return false;
    }
    double v;
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
