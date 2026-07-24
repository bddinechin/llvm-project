# Linear scan: comparison against the SSA-based literature

Status: discussion record, no code changes resulted. Not a design doc for
work in progress -- see `docs/lvx/RegisterAllocation.md` for what's
actually implemented.

## Sources

> Hanspeter Mössenböck and Michael Pfeiffer, "Linear Scan Register
> Allocation in the Context of SSA Form and Register Constraints," CC 2002
> (`/home/guembu/Downloads/Mossenbock_2002_CC.pdf`).

> Christian Wimmer and Michael Franz, "Linear Scan Register Allocation on
> SSA Form," CGO 2010 (`/home/guembu/Downloads/Wimmer_2010_CGO.pdf`).

Compared against what's implemented here (`docs/lvx/RegisterAllocation.md`,
Poletto & Sarkar 1999) and against Poletto & Sarkar itself. The two papers
are not independent alternatives -- Wimmer co-authored the 2002 paper's
follow-on (2005) and this 2010 paper is a further refinement of the same
lineage: Poletto 1999 (base algorithm) → Traub 1998 (lifetime holes +
interval splitting, "second-chance binpacking") → Mössenböck & Pfeiffer
2002 (fixed intervals, SSA-*aware*) → Wimmer & Mössenböck 2005 (interval
splitting refinements) → Wimmer & Franz 2010 (SSA-*native*: allocate
directly on SSA form, no dataflow analysis needed to build intervals).

## Lineage, not two independent approaches

Mössenböck's `LinearScan` is Poletto's scan with one structural addition: a
fourth interval set, `inactive`, for values that are live but currently
sitting in a lifetime hole. Poletto's base algorithm -- the one actually
implemented here -- has only `unhandled`/`active`/`handled` and no holes.
On core scan mechanics, this implementation follows Poletto exactly;
Mössenböck is one specific direction beyond it, not taken here.

## Where this implementation actually sits

A hybrid of the two papers' premises:

- **Input form**: SSA (MLIR is inherently SSA), matching Mössenböck's
  setting, not Poletto's non-SSA "quads with reused names." The existing
  design doc independently makes the same argument Mössenböck makes in his
  §6.2 for skipping interval splitting: SSA gives short intervals for
  free, so Traub's second-chance-binpacking-style splitting isn't as
  necessary.
- **Scan algorithm**: Poletto's plain 3-state scan, not Mössenböck's
  4-state hole-aware one. So this implementation has the *setting* of one
  paper and the *algorithm* of the other.

## Mössenböck & Pfeiffer 2002: point-by-point findings

**φ-functions / block-argument merges** -- Mössenböck's SSA adaptation
(insert moves for φ-operands, exclude φ's from live intervals, `JOIN` the
φ and its operands into one representative via union-find so the φ
disappears) is exactly the reference design for the "general `lvx_cf`
block-argument merges" limitation already flagged as unimplemented in
`docs/lvx/RegisterAllocation.md` -- not reachable from any current
lowering path, so left alone rather than spending effort on unreachable
code.

**Coalescing / `JOIN`** -- Mössenböck's `JOIN`/`REP` (§4.4) is a
union-find with a representative pointer per value. The `lvx_scf.for`
loop-carried coalescing here does the same thing structurally
(`{initArg, iterArg, yieldOperand, result}` sharing one register), and
the nested-loop union-find fix landed a few turns before this
discussion turned out to be the same algorithm, arrived at
independently rather than borrowed. One place this implementation is
*coarser*: Mössenböck's `JOIN` compatibility check allows joining a
fixed value with a free one as long as the fixed register isn't in use by
a *specific* overlapping interval; this implementation requires all
members of a group to agree on the exact same fixed register or hard
errors -- simpler and more conservative, not more precise.

**Spill heuristic** -- the one place Mössenböck is a real, measurable
improvement. Poletto's `SpillAtInterval` (what's implemented here) spills
whichever of the current/active intervals has the furthest end point --
pure interval length, no notion of how expensive a value actually is to
spill. Mössenböck's `AssignMemLoc` weights by access count × loop nesting
depth. This implementation can spill a cheap-to-keep, hot, deeply-nested
value in favor of an expensive-to-keep one touched once, purely because
the latter's interval happens to be shorter -- Mössenböck's wouldn't make
that mistake.

**Fixed/pinned registers and two-address moves** -- Mössenböck's
move-insertion-then-`JOIN`-away pattern for values needing a specific
register is the same shape as the ABI copy-in/copy-out via `lvx.mv` here,
and the same shape as the induction-variable copy-in
(`docs/lvx/AssemblyEmission.md`) needed for the hardware-loop lowering.
LVX is 3-address (`CLAUDE.md`), so Mössenböck's two-address
(`x = y op z` needing `x`/`y` in one register) `JOIN` case doesn't apply
here at all.

**Outside both papers (as of the 2002 comparison)** -- structured loop
constructs as first-class SSA ops (`lvx_scf.for`) and the coalescing that
requires, the nested-loop cross-loop union, and the `LOOPDO` hardware-loop
lowering (`docs/lvx/HardwareLoops.md`) are all absent from Poletto and
Mössenböck 2002 alike, which target flat CFGs with unstructured
branches/φ's. Call-clobbering (`crossesCall` restricting to callee-saved
registers) is also absent from both -- neither paper's allocator models
calls.

## Wimmer & Franz 2010: point-by-point findings

**Correction to the 2002 comparison above**: Wimmer's own related-work
section (§8) is explicit that Mössenböck 2002 is SSA-*aware* but still
**deconstructs SSA before register allocation** -- it inserts moves into
predecessor blocks for φ-operands and builds intervals via ordinary
dataflow analysis, same as Poletto. What this 2010 paper adds beyond 2002
is allocating *directly on* SSA form: intervals built with no dataflow
analysis at all, φ-functions kept unresolved with parallel-copy semantics
through the whole scan, SSA deconstruction folded into a resolution phase
run *after* allocation. The φ/`JOIN` comparison drawn against 2002 above
still holds (this implementation's `lvx_scf.for` coalescing is the same
algorithm as Mössenböck's `JOIN`), it's just worth being precise that 2002
itself hadn't gone as far toward "no dataflow" as 2010 does.

**Building intervals without dataflow -- proves something found here only
empirically**. Wimmer's headline trick (§4, `BuildIntervals`): given SSA's
dominance guarantee (a definition dominates all its uses) plus a specific
block order (predecessors before a block except loop back-edges, and all
of a loop's blocks contiguous), lifetime intervals can be built in one
reverse pass with no fixed-point dataflow iteration at all. This is a
striking match to something already found here empirically but not
formally justified: `docs/lvx/RegisterAllocation.md`'s Step 1 notes that
`mlir::Liveness`'s dataflow-based block-liveOut correction pass "turned
out to be redundant" against direct operand scanning on every test case
tried, kept only as a defensive safety net. Wimmer's paper is the formal
argument for exactly that phenomenon -- given SSA plus the right block
order, the dataflow pass genuinely cannot add information the structural
scan doesn't already have. That was discovered here by testing; Wimmer
proves it as a theorem and, on the strength of the proof, removes the
dataflow analysis entirely. Here it was kept as a hedge instead, for lack
of the general argument.

**Loop-carried liveness: structured IR wins this one outright.** Wimmer
needs an explicit special case at loop headers, because his loops are
*inferred* from a flattened, unstructured CFG -- detecting "this is a loop
header, extend liveness across the whole loop body" is a distinct
algorithmic step, and §4.3 spends a full page on what breaks for
irreducible loops (multiple entry points), requiring either a real loop
analysis or frontend cooperation (extra φ's at every irreducible loop
header) to keep the algorithm correct. `docs/lvx/RegisterAllocation.md`'s
Step 1 originally anticipated exactly this as a hard problem before any
code was written ("Loop-carried extension") -- and it turned out to fall
out for free from numbering the loop body inline plus direct operand
scanning, no special-casing needed. The reason: `lvx_scf.for` is a
*structured* op. There is no loop to rediscover from block topology, so
there is no irreducible-loop edge case to worry about either. This is the
cleanest instance across both comparisons of a structured-loop IR being
strictly simpler than the flat-CFG setting all three reference papers
actually operate in.

**No splitting (here) vs. splitting + general resolution (Wimmer) --
the biggest structural gap.** Wimmer's allocator splits intervals: a value
can be in a register for part of its life and on the stack (or a different
register) for the rest, which requires a general `Resolve` phase (§6,
Fig. 7) that walks every control-flow edge and inserts a move wherever a
value's location differs between the end of one block and the start of
the next. SSA deconstruction (φ resolution) falls out as one special case
of that same machinery, not a separate pass. Step 3 here does not split --
it follows Poletto's base algorithm exactly, a spilled value is
memory-resident for its entire interval (`docs/lvx/RegisterAllocation.md`,
"No interval splitting / no lifetime holes"). Because of that, this
implementation never needs Wimmer's general "value ended up somewhere
different than expected" resolver: what exists instead is narrower and
purpose-built for each *known* mismatch -- ABI copy-in/copy-out via
`lvx.mv`, loop-channel coalescing, the induction-variable copy-in fix
(`docs/lvx/AssemblyEmission.md`), and Step 3's fixed spill-store/reload
points -- verified by `checkBranchOperands` in `-lvx-emit-asm` rather than
resolved generically. Adding splitting later (to improve spill quality by
letting a value live in a register through the hot part of its lifetime
and spill only elsewhere) would need something like Wimmer's `Resolve`;
that is the natural next step beyond Step 3, not something to backfill
speculatively now.

**Coalescing: hard merge (here, matches Mössenböck 2002) vs. soft hints
(Wimmer, deliberately not merging).** Wimmer explicitly does not coalesce
intervals -- not purely for compile-speed reasons, but because merging
can lengthen intervals and force more spilling (the same critique
Mössenböck's own 2002 paper already raises in passing about coalescing in
general). Instead, values that should share a register are linked by a
lightweight *hint*; the allocator honors it when convenient but is not
required to. The `lvx_scf.for` coalescing here is a real merge (the same
union-find shape as Mössenböck's `JOIN`), and the reason differs from
Wimmer's tradeoff entirely: it is not a quality choice, it is forced by
`ForOp`'s hard verifier requirement that `initArg`/`result` types be
identical -- there is no "hint" that would satisfy that; the IR literally
fails to verify otherwise. Where Wimmer's own field moved away from
merging because it is usually a bad trade, this implementation doesn't
have the option to make that trade for this specific case.

**What this means for lvx-mlir specifically.** Wimmer's measured payoff
(§7) is compile-time and compiler-code-size (4-8% faster overall
compilation, ~200 fewer lines of C++, negligible *run-time* difference
since the underlying allocation decisions are unchanged) -- it is an
engineering-simplicity result for a JIT that recompiles constantly, not a
code-quality result. That motivation applies much less to an
ahead-of-time systems-compiler prototype like this one, where compilation
happens once and correctness during bring-up matters more than shaving
milliseconds off allocation. The dataflow-elimination *proof* is the one
piece worth keeping regardless of that framing -- it is a legitimate
argument for eventually dropping the `mlir::Liveness` safety net in Step
1, not just an empirical hunch that it happens to be unneeded so far.

## Decision: not fixing these now

None of the identified gaps -- from either paper -- are correctness bugs
in reachable code paths:

- The φ-merge gap is dead code -- nothing in the current lowering
  produces a real merge block.
- The stricter `JOIN`/fixed-conflict check and the missing
  holes/`inactive` set are precision/conservatism gaps, not wrong output.
- Even the weighted spill heuristic is optimizing a path (Step 3
  spilling) exercised so far only by tiny synthetic
  `max-registers`-forced tests, not a real kernel.
- Interval splitting (and the general resolution phase it would need)
  solves a problem -- spill quality via partial-register residency -- that
  hasn't been shown to matter yet for the same reason.
- The dataflow-elimination proof would only let something already-cheap
  (Step 1's redundant safety-net pass) get slightly cheaper; it isn't
  fixing a bug either.

Spending effort on spill-quality tuning, interval splitting, or general
φ-coalescing before a single real numeric kernel has run end-to-end
(still blocked on `divmod`/`cmoved` emission support and the broken
`lvx-gem5` build -- `docs/lvx/AssemblyEmission.md`) would be polishing a
component nothing has actually stressed yet.

**If/when revisited, roughly in priority order**:
1. Mössenböck's weighted `AssignMemLoc` -- the cheapest win, a heuristic
   swap within the existing no-splitting design, once a real spill-heavy
   kernel shows the current furthest-endpoint heuristic making a bad call.
2. Interval splitting + a Wimmer-style `Resolve` phase -- a bigger,
   structural addition, worth it only once spilling a value for its
   *entire* interval (today's behavior) is shown to cost real performance
   on a real kernel.
3. Dropping the `mlir::Liveness` safety net in Step 1 in favor of
   Wimmer's dataflow-free construction, on the strength of his proof
   rather than re-deriving it -- a simplification with no behavior change,
   lowest urgency of the three.
4. The φ-merge and holes/`inactive`-set gaps stay architecture to add when
   something in the actual lowering pipeline needs them, not before.
