# Hardware loops (LOOPDO)

Status: implemented and tested; not yet committed.

## What LOOPDO does

Ground truth: `lvx-mds/lvx-family/FE/YAML/lvx/Instruction.yml`'s `LOOPDO`
entry (format `BCU_HLS`), cross-checked against the already-verified
`lvx-gem5` shim/`static_inst.cc` implementation.

`loopdo $rz, target` sets three hardware SFRs and otherwise falls through
normally:

- `LS` (Loop Start) = PC of the next bundle (i.e. wherever the very next
  instruction after `loopdo` is — the loop body's first bundle).
- `LE` (Loop End) = this bundle's PC plus `target`'s offset.
- `LC` (Loop Count) = `$rz`.

**The back-edge is not a branch instruction.** It's a fetch-engine-level
mechanism (confirmed in `lvx-gem5/src/arch/lvx/static_inst.cc`): whenever
the naturally-computed next bundle PC equals `LE` and nothing branched in
that bundle, hardware redirects to `LS` if `LC-1 != 0` (decrementing `LC`),
or falls through past `LE` if `LC` has been exhausted. **A real branch
taken in the loop body's last bundle overrides this and wins** — this is
architecturally intentional (it's how an early-exit `break` would work),
but it also means printing an explicit `goto` for what should be the
implicit back-edge silently truncates the loop to one iteration.

**Zero trip count is safe on LVX, unlike KVX.** If `$rz == 0` when
`loopdo` executes, the next bundle PC is set directly to `LE` — the loop
body is skipped entirely (Tensilica `LOOPNEZ`-style). `Instruction.yml`
explicitly flags this as a deliberate LVX-specific difference from KVX,
where the same opcode loops forever on a zero count. This mattered because
the reference LLVM backend and any KVX-derived example code assume the
opposite; do not carry that assumption over.

**No nesting.** `LC`/`LS`/`LE` are a single register set, not a stack. A
hardware loop nested inside another hardware loop's body would clobber the
outer loop's state mid-flight. This implementation therefore only lowers
*leaf* `lvx_scf.for` loops (no nested `lvx_scf.for` anywhere in the body);
nested loops keep using the existing branch-based lowering. A save/restore
scheme around inner loops would lift this, but isn't implemented.

**`PS.HLE` is a non-issue for now.** Real hardware traps `LOOPDO` unless
the `PS.HLE` privilege bit is set. `lvx-gem5`'s SE-mode shim hardcodes it
reported-set unconditionally (`shim.cc`, `misc_reg::ps::SE_MODE_VALUE`)
specifically so this never traps in the environment this project's near-term
validation goal (the gem5 differential-testing harness) actually targets —
confirmed by the pre-existing `hwloop0.s`/`hwloop3.s` smoke tests having no
enable sequence at all. A real-silicon freestanding runtime would need to
enable this once (crt0-level, not per function); out of scope here.

**No auto-incremented induction variable.** `LOOPDO` only manages the trip
count and the branch; if the loop body actually reads the induction
variable, it still needs its own explicit increment every iteration,
exactly as the branch-based lowering already does.

## New op: `lvx_cf.loopdo`

Lives in `lvx_cf` (not the bare `lvx` dialect): `LOOPDO`'s own format,
`BCU_HLS`, is a BCU-family format exactly like `lvx_cf.br`/`cond_br`'s
`BCU_UB`/`BCU_CB`, and `lvx_cf`'s existing doc comment already scopes
itself to "mirroring the real `BCU_*` instruction formats" — this is the
same category of op, not a new one.

```
lvx_cf.loopdo %tripCount : !lvx.reg<r29>,
    ^body(%ivInit, %initArgs... : ...),
    ^exit(%initArgs... : ...)
```

A terminator with **two** successors, mirroring `cond_br`'s
`AttrSizedOperandSegments` shape:

- `body`: always taken in the sense that control always falls through to
  it immediately after `loopdo` executes for a nonzero trip count — but it
  is also the *statically declared* structural successor MLIR's verifier
  needs, matching what real hardware would fetch next.
- `exit`: the successor `loopdo` actually branches to directly only in the
  zero-trip-count case (skip the body entirely) — its operands are
  therefore the loop's *initial* `iter_args`, exactly matching "zero
  iterations ran, so the final value equals the initial value." This is
  the same shape the old branch-based header's false-edge already used.

Confirmed decision from the walkthrough: this design (new op with a
successor) over the alternative (keep the existing `lvx_cf.br`-based
shape and tag/elide it at emission time) — closer to what the real
instruction actually does, keeps the hardware-loop-ness localized to one
op rather than smeared across a printer-side special case.

## Lowering (`-lvx-scf-to-cf`, extended)

Per-loop eligibility check, added at the top of the existing `lowerFor`:
take the hardware-loop path only if `step` is the compile-time constant
`1` (defined by an `lvx.li` with `IntegerAttr` value `1` — detected by
walking the def, not inferred) *and* the body contains no nested
`lvx_scf.for`. Otherwise, fall back to the unchanged branch-based lowering
(`docs/lvx/AssemblyEmission.md`).

Why constant-step-1 specifically: `loopdo` needs an explicit trip-count
*register*, not bounds — for arbitrary `step` that's
`ceil((ub-lb)/step)`, a division, and `divmod` is a documented hard error
in `-lvx-emit-asm` (real opcode's destination is an adjacent register pair
this allocator doesn't model — see `docs/lvx/AssemblyEmission.md`). With
`step == 1`, trip count is just `ub - lb`, one `sbfd`, no division needed.

Shape produced:

```
currentBlock:
  %trip = lvx.sbfd %ub, %lb : (...) -> !lvx.reg<r29>
  %ivInit = lvx.mv %lb : (...) -> <induction variable's own register>
  lvx_cf.loopdo %trip : !lvx.reg<r29>,
      ^body(%ivInit, %initArgs... : ...),
      ^exit(%initArgs... : ...)

^body(%iv, %acc...):                      // forOp's original body, reused as-is
  ...original ops, unchanged...
  %next_iv = lvx.addd %iv, %step : (...) -> <iv's own register>   // in-place: same
                                                                    // register as %iv
  lvx_cf.br ^exit(%yieldedValues...)        // never printed -- see emission below

^exit(%result...):
  ...rest of function, using %result as forOp's own result, unchanged...
```

Two register-matching subtleties, both already-established patterns reused
here rather than new ones:

- `%trip` and the loop-test comparison in the branch-based lowering share
  the same reasoning for reusing `r29` (Step 3's store-scratch register,
  docs/lvx/RegisterAllocation.md): a short-lived, single-use value that
  never overlaps anything else, safe to pin to a register permanently
  excluded from the general pool.
- `%ivInit`'s explicit copy-in from `%lb` is the *exact* fix already made
  for the branch-based lowering (`docs/lvx/AssemblyEmission.md`,
  "New values needing a register") — the lower bound and the body's own
  induction-variable register are independently allocated by Steps 1-3
  with no forced coalescing, so nothing guarantees they match without an
  explicit copy.

**New subtlety specific to hardware loops**: `%next_iv` must be pinned to
*exactly* the same register as `%iv` itself (already true here since its
type is copied directly from `iv.getType()`, matching the existing
increment code in the branch-based path). This isn't the same kind of
"independently allocated, needs a bridging copy" situation as the entry
edge -- a real hardware loop has *no* mechanism at all to pass values into
its own next iteration (no branch executes for the back-edge, so there is
no operand list to speak of). The only way the increment carries forward
is if it physically overwrites the same register the next textual pass
through the body will read -- which is exactly what pinning `%next_iv` to
`%iv`'s own register achieves. Get this wrong and the loop would silently
recompute from the same starting value every "iteration."

## Emission (`-lvx-emit-asm`, extended)

Two additions:

1. A `lvx_cf::LoopdoOp` case: print `loopdo $rz, <exit-label>` as a normal
   instruction (its own `;;`-terminated bundle). Its `body` successor
   needs no printed jump at all — control already falls through to
   whatever comes textually next once block order places `body`
   immediately after `loopdo`'s own block, which the lowering above
   guarantees by construction (no separate elision logic needed for this
   edge specifically, since nothing ever *would* print a `goto` for a
   plain fallthrough on the entry side).
2. A general "elide a branch whose target is the block immediately
   following it in emission order" rule, applied to `lvx_cf.br`/`cond_br`.
   This is **required for correctness** on the loop body's own
   `lvx_cf.br ^exit(...)` terminator specifically — printing that as an
   explicit `goto` would be a real branch instruction, which per
   `LOOPDO`'s own semantics overrides the hardware back-edge and silently
   turns the loop into a single iteration regardless of trip count. It's
   a minor, harmless cleanup everywhere else it happens to apply (ordinary
   branch-to-fallthrough is always safe to elide for non-loop code too).

## Known limitations (recap)

- Only `step == 1` (compile-time constant) loops take the hardware-loop
  path; everything else uses the existing branch-based lowering.
- No nested hardware loops; a nested `lvx_scf.for` anywhere in the body
  disqualifies the whole loop from this path.
- `PS.HLE` enablement is not emitted; relies on `lvx-gem5`'s SE-mode
  always reporting it set. Real-silicon bring-up would need this addressed
  at the runtime/crt0 level.
- **Found while testing, not fixed here**: nested `lvx_scf.for` is broken
  further upstream, independent of hardware loops. A value that is
  simultaneously an inner loop's result and an outer loop's directly-
  yielded operand needs to belong to two independent Step 2/3 coalescing
  groups at once (docs/lvx/RegisterAllocation.md) -- one wants it in one
  register, the other in another -- which either fails
  `-lvx-allocate-registers`'s own verifier or crashes `-lvx-scf-to-cf`
  outright depending on the exact shape. `isHardwareLoopEligible`'s
  nested-for exclusion is still correct as written, but there is no
  end-to-end test of it, since a well-formed nested loop can't currently
  reach this pass at all. Worth fixing before nested loops are used for
  anything, hardware loops or not.
