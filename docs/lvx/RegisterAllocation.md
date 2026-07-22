# Register allocation design: linear scan

Status: design confirmed, implementation not yet started (see `docs/lvx/`
for related design notes as they're added).

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

**Decision (confirmed)**: synthesize a tiny fixed/pre-colored interval for
each caller-saved register at every `lvx_func.call` site (zero-width,
pinned, no associated value). This reuses the same "fixed interval"
machinery as ABI-pinned args/results (Step 1), so the main scan naturally
forces any value live across a call into a callee-saved register, or (step
3) a spill — no special-casing in the core loop.

### Multi-result ops

`lvx.divmodd`'s quotient+remainder need no special handling beyond each
result getting its own interval. LVX's real ISA is 3-address (no
2-address operand/result register reuse to model, unlike x86), so there's
no "coalesce dest with a source" concern either.

### Bail-out semantics

When `ExpireOldIntervals` leaves `|active| == R` and a new interval needs a
register: `op->emitError()` naming the value and the conflicting live
range, then `signalPassFailure()` — consistent with how the rest of this
codebase reports pass failures.

### Output representation

Since the dialect's design principle is "physical registers as types,"
this pass rewrites every `!lvx.reg` operand/result type in place to its
assigned `!lvx.reg<rN>`, rather than producing an out-of-band coloring map.

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
- Model call sites as clobbering all caller-saved registers via fixed
  intervals, from Step 2 onward (not deferred).
- `R14` allocatable in Step 2; revisited when Step 3 introduces stack
  frames.
- Step 1 gets its own standalone test pass
  (`-lvx-print-live-intervals`), separate from the allocation pass itself.
