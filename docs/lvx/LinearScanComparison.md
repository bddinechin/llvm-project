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

> Fernando Magno Quintão Pereira and Jens Palsberg, "SSA Elimination after
> Register Allocation," CC 2009 (`/home/guembu/Downloads/Pereira_2009_CC.pdf`).

> Sebastian Hack, Daniel Grund, and Gerhard Goos, "Register Allocation for
> Programs in SSA-Form," CC 2006 (`/home/guembu/Downloads/Hack_2006_CC.pdf`).

Compared against what's implemented here (`docs/lvx/RegisterAllocation.md`,
Poletto & Sarkar 1999) and against Poletto & Sarkar itself. The two papers
are not independent alternatives -- Wimmer co-authored the 2002 paper's
follow-on (2005) and this 2010 paper is a further refinement of the same
lineage: Poletto 1999 (base algorithm) → Traub 1998 (lifetime holes +
interval splitting, "second-chance binpacking") → Mössenböck & Pfeiffer
2002 (fixed intervals, SSA-*aware*) → Wimmer & Mössenböck 2005 (interval
splitting refinements) → Wimmer & Franz 2010 (SSA-*native*: allocate
directly on SSA form, no dataflow analysis needed to build intervals).

Pereira & Palsberg 2009 and Hack, Grund & Goos 2006 are not part of the
linear-scan lineage above at all -- they're from the *SSA-based
graph-coloring* thread (Hack, Pereira's own puzzle-solving allocator), a
separately-evolved family that shares only the underlying problem
(register allocation on SSA-form programs), not any algorithmic ancestry
with Poletto/Mössenböck/Wimmer. The two are directly connected to each
other, not independent: Hack 2006 is reference [13] in Pereira 2009's own
bibliography, and Pereira's earlier chordal-graph-coloring paper (APLAS
2005, cited by both) is reference [19] in Hack 2006's -- same
Karlsruhe/UCLA-adjacent research group, building on each other's results.
Both are included here because together they answer a question the
linear-scan papers only mention in passing: given a program with
φ-related variables that ended up sharing a register, what has to be true
for that to be *safe*, precisely, and how cheap can resolving the ones
that *aren't* safe actually be?

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

## Pereira & Palsberg 2009: point-by-point findings

**CSSA and the precise safety condition for coalescing this project has
been missing.** Mössenböck 2002 and Wimmer 2010 each note in passing that
aggressive coalescing can force *more* registers than necessary (see the
"hard merge vs. soft hints" entry above) -- but neither gives a checkable
criterion for when it's actually unsafe, only a qualitative "usually a bad
trade." Pereira & Palsberg's Conventional SSA (CSSA) form makes this
precise (Definition 1): variables related by a φ-function may share a
register only if, for every pair, they **do not interfere**. Their intro
cites their own earlier result (Pereira & Palsberg, APLAS 2005) that
coalescing without this check can force a strictly worse register count
than a correct allocation would need.

**This is the exact, previously-undiagnosed cause of the "combined
accumulator" bug.** `buildAllocItems`'s union-find (`RegisterAllocation.cpp`)
coalesces every `lvx_scf.for` loop-carried tuple and every `lvx_cf` branch
edge into one register with no interference check at all -- pure
aggressive coalescing, unconditionally. `docs/lvx/RegisterAllocation.md`'s
"Nested `lvx_scf.for`" section already documents a concrete failure of
this (`%sum = lvx.addd %acc, %innerResult` compiling to a self-add) as a
"known, narrower remaining gap," but without a name for *why* it happens.
Pereira's Definition 1 supplies that name: `%acc` and the inner loop's own
result are coalesced by this project's union-find (both flow through the
same loop-carried channel), but they interfere (`%acc` is read again,
via the `addd`, after the inner result is already live) -- exactly the
"CSSA property violated" case the whole paper exists to detect and avoid.
This isn't a new bug the paper reveals; it's a precise diagnosis of one
already on record.

**The paper's own fix doesn't apply as-is, but the diagnosis suggests a
much smaller one.** Pereira & Palsberg's actual contribution -- *spill-free
SSA elimination* -- solves a harder, more general problem than this
project has: given a CSSA-form, register-allocated program with φ-functions
still unresolved, replace each one with copy/swap instructions without
needing a spare register, by showing the necessary parallel copies always
form a restricted graph shape ("spartan": unions of cycles and paths, never
Sreedhar's more general "windmills") solvable via `ImplementSpartan`
(Section 5) with no temporary register required even for memory-to-memory
transfers. lvx-mlir doesn't have that problem in the first place, because
it never lets a φ (or `lvx_scf.for`'s loop-carried channel) survive
unresolved into a separate elimination pass -- it resolves the "same
register or not" question during allocation itself, by forcing coalescing.
Adopting CSSA/spartan-graph machinery wholesale would mean *creating* the
problem Pereira solves, not reusing the solution.

What *is* directly reusable is much narrower: use Definition 1 as a guard
before each `unite` call in `buildAllocItems`. The live intervals needed
to check it already exist (Step 1 computes them for every value); this
project doesn't need CSSA's general machinery to ask "would this specific
union create an interference," it can just check the two intervals against
each other, exactly as `expireOldIntervals`/the conflict-detection code in
Step 2 already do for other purposes. Where a union would be unsafe, fall
back to what this project already does everywhere else a value needs to
move between registers: insert an explicit `lvx.mv` copy (the same pattern
as the ABI copy-in/copy-out, the induction-variable copy-in, and the
hardware-loop increment), rather than forcing one register onto two
interfering values. This is a small, local, correctness-motivated change,
not an architectural one -- unlike Wimmer's `Resolve` phase, it doesn't
require giving up the "no unresolved parallel copies" design at all; it
just stops assuming every structurally-related tuple is safe to merge
without checking.

**One incidental parallel worth noting.** Pereira's paper frames "spare
register" (permanently reserving one register to implement memory-to-memory
copies during φ-elimination) as the naive, costly baseline their spill-free
approach improves on (5.2% more spill code in their SPEC measurements,
Section 1). This project already pays that exact cost for an unrelated
reason: Step 3 permanently reserves `r29`-`r31` as spill/compare scratch
registers (`docs/lvx/RegisterAllocation.md`, "Reserved scratch registers").
That reservation already exists and is already paid for, so if the
interference-check-then-copy fix above needs a scratch register at some
program point where every general-purpose register is genuinely live, it
has one available for free -- no new cost, unlike Pereira's baseline where
reserving that register was the thing being optimized away.

## Hack, Grund & Goos 2006: point-by-point findings

**A formal proof for something this project has twice found empirically.**
Hack's core theorem: interference graphs of *strict* SSA-form programs
(every use dominated by its definition -- true of any program `-convert-
to-lvx` produces) are **chordal**. Chordal graphs are perfect (chromatic
number = largest clique) and, crucially, always admit a *perfect
elimination order* obtainable directly from a post-order walk of the
program's dominance tree -- no search needed, no NP-complete "does a PEO
exist" question to answer. This is a second, independent formal
justification for the same phenomenon already noted twice in this
document: Wimmer's dataflow-free interval construction above, and Step
1's own empirical finding that `mlir::Liveness`'s dataflow correction pass
"turned out to be redundant." Wimmer's proof is about *building intervals*
without dataflow; Hack's is about *coloring* being reducible to a
dominance-order walk instead of general graph search. Different papers,
different mechanisms, same underlying cause -- SSA's dominance property
does almost all the work, and this project's Step 1 numbering
(`ReversePostOrderTraversal` plus inline `lvx_scf.for` numbering,
`docs/lvx/RegisterAllocation.md`) already produces a dominance-respecting
order for exactly this reason, independently of either paper.

**This chordality result is precisely what Lee/Palsberg/Pereira 2007
(`docs/lvx/MultiRegisterClasses.md`) shows doesn't survive aliasing.**
Worth stating explicitly since the two papers were read separately: Hack's
"SSA makes coloring easy" and Lee 2007's "aliased register allocation is
NP-complete even for the friendliest SSA-like programs" are not in
tension, they're the same boundary described from two sides. Hack's
result needs one flat, non-aliased register class; the moment LVX's
pair/quad aliasing enters (`docs/lvx/MultiRegisterClasses.md`), chordality
and the free perfect-elimination-order are exactly what's lost, which is
*why* the problem becomes NP-complete instead of staying polynomial. This
project's current Steps 1-3 sit safely on the easy side of that boundary
(one register class, `!lvx.reg`, `kFullOrder`); the SIMD phase is what
would cross it.

**φ-resolution via swap/permutation, and why it's unusually cheap on
LVX specifically.** Hack's §4.2-4.3 addresses the same "how do we turn a
φ-function into real instructions" problem as Pereira 2009 above, from a
different angle: a block's φ-operations, executed simultaneously, are
provably a *permutation* on registers (Figure 2's worked example: two
φ's at a loop header literally swap `R1`/`R2` on the back edge), and any
permutation decomposes into at most `n-1` transpositions with **no spare
register needed** if the target has a swap instruction (`xchg` on x86) or
three `xor`s if it doesn't.

LVX has no dedicated register-register swap opcode -- checked directly
against ground truth (`lvx-mds/refs/FE/YAML/lvx/lvx_v1/Description.yml`):
the only `*SWAP*` entries are `RSWAP` (a system-register swap, not
general-purpose) and the `ASWAP`/`ACSWAP` families (atomic *memory*
swap/compare-swap via the LSU, unrelated to register-register exchange).
But it doesn't need one, for a reason neither Hack's nor Pereira's paper
had available to them (both target scalar, non-VLIW machines): LVX's
bundle semantics already give a *stronger* primitive than a pairwise
swap, for free. Confirmed directly in the already-verified `lvx-gem5`
reference model, not inferred (`static_inst.cc`, `LvxStaticInst::execute`):
every sub-instruction in a bundle runs its `Fetch` (register reads) phase
*before any* sub-instruction in that bundle runs its `Commit` (register
writes) phase -- "so all source reads (fetch) happen before any register
write (commit) — VLIW parallel semantics," in the code's own comment.
That is exactly the "all φ-operations execute simultaneously" semantics
Hack's paper defines for a block's φ-matrix (§1, §4.2) -- LVX's ordinary
bundle execution model *is* a hardware parallel-copy primitive. A whole
φ-block's worth of permutation can be implemented as a bundle of ordinary
`copyd` instructions, with no cycle/path decomposition, no swap-vs-xor
case analysis, and no spare register ever needed, for any permutation
that fits in one bundle's move-capable issue slots. From the gem5
reference model's own execution-unit assignment (`static_inst.cc`,
`enum Exu`): up to four ALU-class slots per bundle (`EXU_ALU0`/`EXU_ALU1`
plus `EXU_LSU0`/`EXU_LSU1` when not otherwise used for real loads/stores)
can each carry a `copyd`, so a permutation touching up to four registers
is exactly free; a larger one would need staging across multiple bundles
(each bundle still absorbing up to four registers' worth of movement at
once, not one pairwise swap at a time as Hack's transposition-based
algorithm would need) -- still meaningfully cheaper than either paper's
general-purpose algorithm, which was designed for machines without this
option.

**Not usable today, and why.** This is a real property of the target, not
of this project's own code -- `-lvx-emit-asm` currently emits exactly one
instruction per bundle (`docs/lvx/AssemblyEmission.md`, "Bundling": real
VLIW co-issue is explicit future work). Exploiting any of the above would
need that bundling support built first, and only becomes relevant at all
once there's an actual unresolved φ/parallel-copy to resolve -- which,
per the Pereira 2009 discussion above, this project doesn't have today by
construction (coalescing resolves the question during allocation, not
after). The concrete payoff is specific and deferred: *if* Wimmer's
splitting + general `Resolve` phase is ever adopted (this document's own
"if/when revisited" list below), the φ/parallel-copy resolution step that
phase needs is unusually cheap to implement correctly on LVX -- no
spartan-graph analysis (Pereira) or transposition decomposition (Hack)
required, just emit the permutation as ordinary bundled moves -- *provided*
real multi-instruction bundling exists by then.

## Decision: not fixing most of these now

Most of the identified gaps -- from all four papers -- are still not
correctness bugs in reachable code paths:

- The general φ-merge gap (differing values from different predecessors)
  is dead code -- nothing in the current lowering produces a real merge
  block with non-uniform incoming values.
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
- Hack 2006's chordality result and bundle-based φ-resolution are both
  confirmations/future-payoff findings, not gaps at all -- there's nothing
  to fix, only something to remember when the `Resolve`-phase item below
  is eventually picked up.

**The interference-check gap Pereira 2009 diagnosed was the one exception
to this list, and is now fixed** (`docs/lvx/RegisterAllocation.md`,
"Nested `lvx_scf.for`", the "Narrower gap" paragraph). Unlike the rest of
this list, it wasn't speculative: it was the precise cause of a bug
already on record (the "combined accumulator" case) in reachable code.
One correction to how the fix was originally scoped here: it turned out
*not* to be a simple guard inside `buildAllocItems`'s `unite` calls --
`ForOp`'s verifier still requires the loop's whole channel to share one
register (initArg/yield/result types must match), so the union itself
can't be skipped. The actual fix (`insertLoopCarriedPreservingCopies`)
is real code motion, run *before* Step 1 builds live intervals: insert an
`lvx.mv` snapshot of any loop init-arg that has a use besides being that
operand, and redirect the other use(s) to the snapshot, leaving the
loop's own channel coalescing untouched. Verified end-to-end including
real execution on `lvx-gem5`, not just structurally
(`scf-to-cf.mlir`'s `@nested_combined_accumulator`).

**If/when revisited, roughly in priority order**:
1. ~~The Pereira-diagnosed interference check~~ -- done, see above.
2. Mössenböck's weighted `AssignMemLoc` -- a heuristic swap within the
   existing no-splitting design, once a real spill-heavy kernel shows the
   current furthest-endpoint heuristic making a bad call.
3. Interval splitting + a Wimmer-style `Resolve` phase -- a bigger,
   structural addition, worth it only once spilling a value for its
   *entire* interval (today's behavior) is shown to cost real performance
   on a real kernel. When this is picked up, its φ/parallel-copy
   resolution step should target LVX's bundled-`copyd` primitive (Hack
   2006 discussion above) rather than porting Wimmer's, Hack's, or
   Pereira's general-purpose resolution algorithms verbatim -- doing so
   also requires real multi-instruction bundling in `-lvx-emit-asm`
   first (`docs/lvx/AssemblyEmission.md`), which doesn't exist yet
   either.
4. Dropping the `mlir::Liveness` safety net in Step 1 in favor of
   Wimmer's dataflow-free construction, on the strength of his proof
   rather than re-deriving it -- a simplification with no behavior change,
   lowest urgency of the group.
5. The general φ-merge (differing predecessor values) and holes/`inactive`-
   set gaps, and Pereira's full CSSA/spartan-graph machinery for resolving
   *unresolved* parallel copies, stay architecture to add when something in
   the actual lowering pipeline needs them, not before.
