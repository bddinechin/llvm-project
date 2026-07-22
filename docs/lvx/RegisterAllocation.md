# Register allocation design: linear scan

Status: Steps 1 and 2 implemented and tested (`-lvx-print-live-intervals`,
`-lvx-allocate-registers`); not yet committed. See `docs/lvx/` for related
design notes as they're added.

## Goal and source

Register allocation for the `lvx`/`lvx_cf`/`lvx_scf`/`lvx_func` dialect
family (see the top-level `CLAUDE.md`), based on:

> Massimiliano Poletto and Vivek Sarkar, "Linear Scan Register Allocation,"
> ACM TOPLAS 21(5), 1999. (`/home/guembu/Downloads/Poletto_1999_TOPLAS.pdf`)

Implementation is planned in three steps:

1. Compute live intervals over the control-flow graph linearized in
   depth-first order.
2. Register assignment only (Fig. 1 of the paper, `SpillAtInterval`
   replaced by a hard error) — bail out if there aren't enough
   architectural registers.
3. Full linear scan including spill/restore.

## How this differs from the paper's setting

The paper's algorithm targets a **non-SSA** "RTL-like quads" model where one
variable name can be redefined multiple times (hence "holes" in a live
range — see its Fig. 2/§4.1). Our IR is SSA: every `!lvx.reg` value has
exactly one definition point (an op result, or a block argument standing in
for a phi). Per-value interval computation is therefore *simpler* than the
paper's general case — no "multiple defs of the same name" bookkeeping.
Loop-carried values (`lvx_scf.for` iter_args) are just ordinary SSA values
defined once at the loop body's entry.

We still adopt the paper's core simplification for interval *shape*: one
contiguous `[start, end]` bracket per value, holes ignored. That's what
"step 3, no interval splitting" means below.

**Pass granularity**: one function (`lvx_func.func`) at a time, matching
the paper (no interprocedural analysis) — an `OperationPass<lvx_func::FuncOp>`,
or a walk over them from a module pass.

## Step 1 — Live intervals over a DFS-linearized CFG

### Numbering scheme

The paper is explicit that "depth-first order" means the *reverse* of
postorder (the reverse of the order nodes are last visited in a preorder
traversal) — i.e. **reverse postorder (RPO)**, not preorder DFS itself
(§3, paragraph on instruction ordering). That's the standard ordering for
forward dataflow problems: for a reducible CFG it visits a block's
non-back-edge predecessors before the block itself.

Default: RPO over the function's blocks (`llvm::ReversePostOrderTraversal`
adapted to `Block*` successors), then number every *operation* sequentially
within each block in that order. Block arguments are numbered at their
block's first slot (their definition point).

### `lvx_scf.for` in a block-based DFS order

`lvx_scf.for` doesn't correspond to a CFG edge — from the outer block's
point of view it's a single operation with a nested region, not a branch.
Two concerns:

1. **Numbering**: number the loop body's block *inline*, right after the
   `lvx_scf.for` op's own number, recursing into the (single) nested block
   before continuing with the rest of the outer block. Everything stays in
   one flat, monotonically increasing numbering; RPO doesn't need to treat
   the loop as a graph node.
2. **Loop-carried extension** (the important one): a value defined
   *outside* the loop and used *inside* its body must be treated as live
   across the *entire* loop body, not just up to its last textual use
   before the op — the body executes multiple times, and on iteration 2+
   that value must still be valid. This mirrors the concern the CGO'25
   Snitch-backend paper calls out in its own allocator (§3.3).

   **Empirical finding (supersedes the paragraph above)**: no bespoke
   extension rule turned out to be necessary. Because the loop body is
   numbered *inline* (point 1), a use inside the body is just a normal,
   later-numbered use of the outer value from the interval-builder's point
   of view — extending `end` to "the last point the value is used" already
   covers it correctly, with no special-casing for the loop terminator.
   Verified by probing the existing upstream `-test-print-liveness` pass
   against a hand-built `lvx_scf.for` with an outer-captured operand before
   writing any of our own code: `mlir::Liveness`'s per-block live-out sets
   already include values captured into a nested region's ops, which is a
   second, independent way the same answer falls out (see below).

### Source of raw liveness

Reuse `mlir::Liveness` (`mlir/Analysis/Liveness.h`) for per-block
live-in/live-out sets rather than hand-writing iterative dataflow — it
already does a correct fixpoint computation and works over nested regions.
The paper assumes "live variable information obtained via data-flow
analysis" as the input to its one-pass interval-building step (§4); this is
exactly that shape. Correctness matters more than compile speed here, so we
skip the paper's *alternative* fast reducible-CFG-only interval method
(§6/related discussion) as an unneeded optimization.

**Verified**: `mlir::Liveness` correctly includes a value captured from an
outer scope into a nested `lvx_scf.for` region in that region's live-in/
live-out sets, confirmed by probing the pre-existing upstream
`-test-print-liveness` pass against a hand-built loop before writing any of
our own code — no hand-rolled "union in captured operands" workaround was
needed.

### Implementation shape (as built)

The implementation (`mlir/{include,lib}/mlir/Dialect/LVX/Analysis/LiveIntervals.{h,cpp}`)
does three passes over the numbered instruction stream:

1. Seed each value's `start` at its definition point (block argument or op
   result), and detect `fixedReg` from `!lvx.reg<rN>` types.
2. Extend `end` by directly scanning every operand of every op in numbering
   order — this alone is sufficient for correctness, including the loop
   case above, given inline loop-body numbering.
3. Extend `end` again using `mlir::Liveness`'s per-block `out()` sets, as a
   defensive safety net for any pass-through-block case the direct scan
   might miss. Empirically this pass turned out to be redundant (it never
   changed the result on any test case, including the loop test) given pass
   2, but it's kept since it's cheap and guards against a class of bug
   (values live across a block with no direct reference in it) that direct
   operand-scanning alone doesn't obviously rule out for more complex CFGs
   than the ones tested so far.

### Building intervals

Single linear pass over the numbered instruction stream, per the paper's
"given live variable info, one pass suffices" (§4): walk in numbering
order, track a running `start`/`end` per value. First time a value is seen
live (via block livein, seeded from `Liveness`, or via its own def) sets
`start`; every point it's live extends `end`. Apply the loop-carried
extension rule as a post-pass (or inline when descending into a `for`
body).

### Pre-colored / fixed intervals

ABI-pinned values already exist as `!lvx.reg<rN>` in the IR (function entry
args, `lvx.mv`-pinned returns) — these aren't allocation candidates, they're
*constraints*: their register is fixed for their (short) live range, and
the allocator must not hand that register to anything else during that
window. Represent them as intervals with a `fixedRegister` field rather
than skipping them, so step 2's scan naturally sees the conflict. (Call
sites reuse the same mechanism — see Step 2.)

### Data structure

```
struct LiveInterval {
  Value value;
  unsigned start, end;
  std::optional<Register> fixedReg;
};
```

Collected into a vector, sorted by `start` ascending at the end (Fig. 1's
precondition).

### Testing

Expose this as a standalone analysis/pass pair — an `LVXLiveIntervals`
analysis class plus a thin `-lvx-print-live-intervals` test pass
(`mlir/test/lib/Dialect/LVX/TestLiveIntervals.cpp`), mirroring the existing
`TestLiveness.cpp` convention already in this tree
(`mlir/test/lib/Analysis/TestLiveness.cpp`) so it's FileCheck-testable
independent of steps 2/3.

**Gotcha (hit and fixed while building this)**: an `OperationPass<lvx_func::FuncOp>`
runs once per function in the module, and MLIR's pass manager runs those
instances *concurrently by default* when there's more than one sibling
function. A test pass that prints via `llvm::outs()` will hit a
`raw_ostream::SetBufferAndMode` assertion (buffered stream, concurrent
writers); `llvm::errs()` (unbuffered) avoids the crash but still
interleaves output byte-by-byte across functions, corrupting FileCheck
output. Fix used here, matching `TestLiveness.cpp`'s convention: print via
`llvm::errs()` *and* pass `-mlir-disable-threading` in the RUN line
(`2>&1 | FileCheck %s`, since `errs()` is stderr) — this applies to any
future per-function test pass in this tree, not just this one.

## Step 2 — Register assignment only, bail out on pressure

Fig. 1's `LinearScanRegisterAllocation` + `ExpireOldIntervals` verbatim,
with `SpillAtInterval` replaced by a hard error.

### Free register pool

From `lvx_Convention.yml`: exclude `R12` (stack pointer) and `R13`
(local/TLS) always — the other 62 GPRs are candidates. `R14` (frame
pointer) stays allocatable at this stage: step 2 has no stack frame /
spilling yet, so there's no frame pointer to protect. Revisit once step 3
needs a frame.

### Allocation order

Mirror the *separate* LVX LLVM backend's stated preference
(`LVXRegisterInfo.td`, in `/home/guembu/bd3/LLVM/llvm-project`) for
consistency: argument/result registers `R0-R11` first, then other
caller-saved scratch (`R15-R17`, `R32-R63`), then callee-saved (`R14`,
`R18-R31`) last — using a callee-saved register forces prologue/epilogue
save/restore code we don't emit yet.

### Call clobbering

The base algorithm has no notion of calls, but `lvx_func.call` exists in
this IR, and real calling conventions clobber caller-saved registers across
a call. Ignoring this produces *silently wrong* code (not just suboptimal)
for any interval live across a call in a caller-saved register, once
callees actually use those registers.

**Original decision (superseded — unsound as stated)**: the walkthrough's
plan was to synthesize a zero-width fixed interval for each caller-saved
register at every call site and let it compete for `active` slots via the
normal fixed-interval machinery. Working through the implementation exposed
two problems with this:

1. **False positive at the boundary.** A value whose *last* use is the call
   itself (e.g. one of the call's own arguments) has `end == callNumber`.
   Fig. 1's `ExpireOldIntervals` only removes an interval when
   `end < newStart` (strict), so that value is still "active" — and holding
   some caller-saved register R — at the exact instant the synthetic
   clobber interval for R is inserted. That reads as a genuine register
   conflict and would hard-error on completely ordinary code (any call with
   arguments, essentially).
2. **Too late to matter.** For a value that *does* survive past the call
   while sitting in a caller-saved register — the real case this is meant
   to catch — the conflict is only visible once the scan reaches the call's
   position, by which point that value's register was already greedily
   assigned earlier in the scan. The base algorithm has no live-range
   splitting (Step 2/3 decision above), so there's nothing to *do* with the
   conflict at that point except wrongly error out on code a smarter
   allocator would accept.

**Revised mechanism**: decide *before* the greedy scan runs, per
allocation item (see the coalescing note below — an "item" may be a single
value or a coalesced loop-carried group), whether its `[start, end]` range
strictly contains at least one call site (`start < callNumber < end` —
strict on both ends, so a value merely produced or consumed *by* the call
itself doesn't count). Collect all `lvx_func.call` op numbers once up
front (sorted, for a cheap binary-search-style check) and precompute one
`crossesCall` bit per item. Register selection then restricts to the
callee-saved subset for any item with `crossesCall == true`; ordinary
items use the full preference order (below). No synthetic intervals, no
special-casing inside `ExpireOldIntervals` — the restriction happens purely
at the "which register do I hand out" step, which is a strictly simpler
place to enforce it than trying to retrofit a conflict into the active-list
scan after the fact.

### Loop-carried register coalescing (not anticipated in the walkthrough)

`lvx_scf::ForOp::verify()` requires
`initArgs[i].getType() == results[i].getType()` for every loop-carried
value, and `verifyRegions()` requires the matching `lvx_scf.yield` operand
type to equal that same type too. Concretely, for iter_arg index `i`, three
*distinct* SSA values — the init operand feeding the loop, the op's own
result, and the operand `lvx_scf.yield` produces at the end of the body —
must end up with the **identical** `!lvx.reg<rN>` type once allocated, or
the rewritten IR fails verification outright. (The in-body block argument,
`getRegionIterArgs()[i]`, is *not* constrained by the verifier to match —
but assigning it a different physical register than the channel it reads
from/feeds back into would be operationally wrong on real hardware, since
nothing in this IR inserts a register-to-register copy at the loop
boundary to reconcile a mismatch. So it's included in the group too.)

This wasn't visible while just computing live intervals (Step 1 treats
these as four ordinary, independently-computed SSA values — correctly, for
liveness purposes), but it is a hard constraint for Step 2, which actually
assigns architectural registers. Independently allocating the four values
would, in the `loop` test case already in the tree, very likely assign the
init operand and the loop's result *different* registers (their computed
Step-1 intervals — `[5, 6]` and `[6, 10]` in that test — merely touch at
one point, not overlap, so nothing in the base algorithm would naturally
force them together).

**Mechanism**: before running the scan, walk every `lvx_scf.for` in the
function and, for each iter_arg index, group `{initArg, bodyIterArg,
yieldOperand, result}` into one *allocation item* whose range is the union
of the four members' individual Step-1 intervals (`min(starts)` to
`max(ends)`). This item is what participates in the scan (one slot in
`active`, one register decision) instead of its four members
individually; once a register is chosen (or the item is fixed, if any
member happens to carry a `fixedReg` — conflicting fixed regs within one
group is a hard error, a malformed program), every member's SSA value gets
that same `!lvx.reg<rN>` type in the rewrite step. All other values
(including the loop's own induction variable, which has no life outside
the body) keep their individual Step-1 intervals unchanged.

### Known limitation: general `lvx_cf` block-argument merges

`lvx_cf.br`/`lvx_cf.cond_br` support passing operands into a destination
block's arguments, which is this dialect's only other value-merging
mechanism besides `lvx_scf.for`. A block argument fed by more than one
predecessor with different values is a real phi-like merge point, and
correctness would need the same kind of coalescing (or, lacking that, an
explicit inserted `lvx.mv` copy) as the loop case above. **This is not
implemented in Step 2.** Reasons this is an acceptable gap for now, not an
oversight: `ConvertToLVX` never currently lowers anything into a
value-carrying `lvx_cf` branch (no `scf.if`/`scf.while` lowering exists
yet), so no test or real lowering path exercises it; and the paper's own
base algorithm has no merge-point concept at all (its non-SSA model
side-steps this by reusing one variable name). Revisit if/when a lowering
starts producing merge blocks — flagged here so it isn't silently
mishandled later.

### Multi-result ops

`lvx.divmodd`'s quotient+remainder need no special handling beyond each
result getting its own interval. LVX's real ISA is 3-address (no
2-address operand/result register reuse to model, unlike x86), so there's
no "coalesce dest with a source" concern either.

### Bail-out semantics

Two distinct hard-error cases, both `emitError` (via `value.getLoc()`,
which resolves correctly for both op results and block arguments) +
`signalPassFailure()`:

- A *fixed* item's register is already held by something else still in
  `active` when the fixed item is reached — a genuine ABI conflict in the
  IR itself (two overlapping values independently pinned to the same
  physical register). Not expected to trigger on any current lowering
  output, but worth a real diagnostic rather than an assert if it ever
  does, since it'd indicate a bug elsewhere (e.g. in `ConvertToLVX`) rather
  than in the allocator.
- A *non-fixed* item finds no free candidate in its allowed pool (full
  62-register order, or the callee-saved-only subset if `crossesCall`).
  This is the expected/designed bail-out this step exists to produce.

**Bug found and fixed while implementing this**: the first case above,
applied naively, spuriously fires on completely ordinary code. Consider
`%3 = ...; %4 = lvx.mv %3 : (!lvx.reg) -> !lvx.reg<r0>` — `%3`'s interval
ends at the same instruction number where `%4`'s fixed interval begins.
Fig. 1's own `ExpireOldIntervals` rule (`end < start`, strict) is exactly
what we *want* for two ordinary items sharing a boundary (it's what forces
an op's result into a different register than an operand it's still
reading — see "Multi-result ops" below) — but applied to a *fixed* item's
conflict check, that same strictness means `%3` reads as "still active,
still holding some register" at the exact instant `%4` needs to claim that
register, even when `%3`'s only remaining "use" is being consumed by the
very op that produces `%4`. Any `lvx.mv %x : (...) -> !lvx.reg<rN>` (the
standard ABI copy-out pattern used throughout this dialect) hits this if
`%x` happens to have been assigned register `rN` earlier in the scan — not
a rare coincidence, since low-numbered registers are early in the
preference order and thus commonly assigned. Fix: when checking a *fixed*
item for a conflict, first expire active items with `end <= start`
(inclusive), not just `end < start` — i.e. the boundary-inclusive rule
applies only to the fixed-item conflict check, not to ordinary
(non-fixed) `ExpireOldIntervals` calls, which keep Fig. 1's exact rule.
Caught by testing `@straight` (`mlir/test/Dialect/LVX/register-allocation.mlir`)
before this ever reached the user — every `!lvx.reg<rN>`-returning function
in the test suite exercises this pattern via its final `lvx.mv`.

### Output representation

Since the dialect's design principle is "physical registers as types,"
this pass rewrites every `!lvx.reg` operand/result type in place to its
assigned `!lvx.reg<rN>` via `Value::setType`, rather than producing an
out-of-band coloring map. No new ops are inserted (that's out of scope
until Step 3's spill/reload rewriting) — this step only ever changes
types.

### Implementation shape (as being built)

- `mlir/include/mlir/Dialect/LVX/Transforms/{Passes.td,Passes.h,CMakeLists.txt}`
  and `mlir/lib/Dialect/LVX/Transforms/{RegisterAllocation.cpp,CMakeLists.txt}`,
  mirroring the existing `ConvertToLVXPass` TableGen-based pass convention
  (`Passes.td` + `GEN_PASS_DECL`/`GEN_PASS_DEF`, registered from
  `mlir/lib/RegisterAllPasses.cpp` via `lvx::registerLVXPasses()`) rather
  than the test-only `PassWrapper` pattern Step 1's test pass used — this
  is a real, production pass, not a test probe.
- Pass name: `-lvx-allocate-registers`, scoped `OperationPass<lvx_func::FuncOp>`
  (`Pass<"lvx-allocate-registers", "::mlir::lvx_func::FuncOp">`), matching
  Step 1's per-function granularity.
- One test-only pass option, `max-registers` (default 62, the real pool
  size), letting lit tests exercise the bail-out path without hand-writing
  62 simultaneously-live values — set it low in a test to force a
  synthetic "ran out of registers" case.
- Internally: build a list of allocation items (individual Step-1
  intervals, except `lvx_scf.for` loop-carried groups collapsed per the
  coalescing rule above), each with `{values, start, end, fixedReg,
  crossesCall}`; sort by `start`; run Fig. 1's `ExpireOldIntervals` +
  assign-from-preference-order loop; rewrite types for every successfully
  assigned (or already-fixed) item's member values.

## Step 3 — Full linear scan with spill/restore

### Spill heuristic

Exactly Fig. 1's `SpillAtInterval`: compare the current interval's end
against the *furthest-end* interval in `active` (its last element, since
`active` is sorted by increasing endpoint); spill whichever ends later.
The paper's "spill the one that lives longest" heuristic, shown optimal
for straight-line single-def/single-use code (§4.1) and reported to work
well generally.

### New infrastructure needed

Spilling means inserting `lvx.sd`/`lvx.ld` against a stack-relative base
register at a per-spilled-interval offset. None of this exists yet: no
prologue/epilogue concept, no frame-size tracking, no stack-pointer-relative
addressing convention in the dialect. Treat "allocate a spill slot" as
bump-allocating offsets from a per-function frame-size counter tracked
alongside the allocator's state. Open question to decide when we get here:
whether prologue/epilogue emission (adjusting `R12`) is part of this pass
or a separate follow-up pass.

### No interval splitting / no lifetime holes

Matches the paper's stated base algorithm (explicitly contrasted against
"second-chance binpacking" in §2 as a *more* complex extension, not the
default): once a value is spilled, it's memory-resident for the rest of
its interval; every subsequent use gets a fresh reload into a short-lived
temporary register right before that use.

This makes step 3 naturally two passes:
1. Run the scan exactly as in step 2, but call `SpillAtInterval` instead of
   erroring; record register-vs-memory decisions.
2. Rewrite the IR: insert a spill-store at each spilled value's definition
   and a reload-load before each of its uses.

### Open nuance: spilled loop-carried values

Spilling a loop-carried `iter_arg` is worth a dedicated test case rather
than assuming it falls out for free. The reload has to happen once per
iteration (at the top of the loop body), not once overall — the "insert a
load right before each use" recipe still works mechanically, since the use
is textually inside the loop body and naturally re-executes each iteration,
but this hasn't been exercised yet.

## Confirmed decisions (recap)

- Reuse `mlir::Liveness` as the dataflow engine (not hand-rolled).
- Model call sites as clobbering all caller-saved registers, from Step 2
  onward (not deferred) — via a precomputed per-item `crossesCall`
  restriction (see above), not synthetic fixed intervals as originally
  sketched.
- `lvx_scf.for` loop-carried values (init operand / body iter_arg / yield
  operand / result) are coalesced into one allocation item per iter_arg
  index, required by `ForOp`'s own verifier — not anticipated in the
  original walkthrough, discovered while designing Step 2.
- General `lvx_cf` block-argument merges are *not* coalesced in Step 2
  (documented known limitation, not currently reachable from any lowering
  path).
- `R14` allocatable in Step 2; revisited when Step 3 introduces stack
  frames.
- Step 1 gets its own standalone test pass
  (`-lvx-print-live-intervals`), separate from the allocation pass itself.
  Step 2 is a real, TableGen-registered pass (`-lvx-allocate-registers`),
  not a test-only probe.
