# Assembly emission

Status: implemented and tested (`-lvx-scf-to-cf`, `-lvx-rewrite-divmod`,
`-lvx-emit-asm`), including assembling real output with the sibling
`lvx-csw` toolchain and, for the `divmod` family, a full run on real
`lvx-gem5`; not yet committed.

## Goal

Translate the fully register-allocated `lvx_func.func` IR (after
`-lvx-allocate-registers`, Steps 1-3 of `docs/lvx/RegisterAllocation.md`)
into real LVX assembly text, consumable by the sibling `lvx-csw` project's
already-built toolchain: `lvx-mbr-as` (assembler), `lvx-mbr-ld` (linker),
and the `lvx-gem5` ISS with its native-x86-differential validation harness
(see the `lvx-csw toolchain` memory). This closes the loop from MLIR IR to
something actually executable and checkable, rather than stopping at
FileCheck-verified IR shape.

## Pipeline order

```
convert-to-lvx  →  lvx-allocate-registers  →  lvx-rewrite-divmod  →  lvx-scf-to-cf  →  lvx-emit-asm
```

`lvx-rewrite-divmod` (see "A narrower fix for divmod" below) is another
post-allocation pass, like `lvx-scf-to-cf`; its own position relative to
`lvx-scf-to-cf` doesn't matter (they touch disjoint op sets), but it must
run after `lvx-allocate-registers` for the same reason `lvx-scf-to-cf`
does -- it consults each `divmod` result's *already-assigned* register.

`lvx-scf-to-cf` (new, this phase) must run **after** allocation, not
before. This is the opposite of the "usual" order (lower structured control
flow early) and is deliberate: `-lvx-allocate-registers`'s loop-carried
coalescing and numbering (`docs/lvx/RegisterAllocation.md`) depend on
`lvx_scf.for` still being structurally present. Lowering it to `lvx_cf`
branches earlier would regress that entire design. See "New values needing
a register" below for the consequence of lowering *after* allocation
instead.

## Syntax source and how it was verified

The MDS-generated `lvx-binutils/opcodes/lvx-opc.c` (`.as_op`/`.fmtstring`/
`.format` per opcode) is the text-syntax-authoritative table -- it's what
`lvx-mbr-as` itself parses against, one remove from the raw MDS tables but
still fully traceable to the same ground truth (`lvx-csw/CLAUDE.md`'s own
`BE/GBU` pipeline generates it). Reading `.fmtstring` alone was ambiguous
in one respect (see "modifier suffixes" below), so **every syntax pattern
used here was additionally confirmed by hand-assembling a representative
snippet with the real `lvx-mbr-as` and inspecting the `lvx-mbr-objdump`
disassembly** before writing any pass code -- not just inferred from
reading tables. This is the same "trust but verify against the real tool"
approach the validation harness itself is built on.

### Confirmed syntax

- Registers: `$r0`..`$r63` (dialect's `stringifyRegister` omits the `$`;
  emission must prepend it).
- Arithmetic/copy (no modifier): `<mnemonic> $rd = $rs1, $rs2` (binary),
  `<mnemonic> $rd = $rs` (unary/copy) -- `addd`, `muld`, `andd`, `iord`,
  `eord`, `slld`, `srad`, `srld`, `notd` and the `w`-suffixed 32-bit forms,
  plus `copyd`/`copyw` (what `lvx.mv` lowers to -- see below) and `make`
  (what `lvx.li` lowers to). **`sbfd`/`sbfw`/`fsbfd`/`fsbfw` are the one
  exception**: real hardware's "subtract FROM" semantics mean
  `$rd = $rs1, $rs2` computes `$rs2 - $rs1`, the reverse of every other
  binary op here -- found the hard way (a hardware-loop trip count
  silently computed backwards, looking like a hang rather than a crash)
  when a real kernel was run end to end; see
  `docs/lvx/EndToEndValidation.md` and `emitBinarySubtractFrom` in
  EmitAsm.cpp, which swaps the printed operand order so `lvx.sbfd`'s own
  `$lhs`/`$rhs` IR operands keep meaning the natural `lhs - rhs`.
- Memory: `<mnemonic> $rd = <offset>[$base]` for loads, `<mnemonic>
  <offset>[$base] = $rvalue` for stores -- note the store's operand order
  mirrors every other op's "thing written = things read" convention, the
  *opposite* of the load's own left-to-right reading order.
- **Modifier suffixes concatenate directly onto the mnemonic with a
  leading dot**, e.g. `compd.lt $rd = $rs1, $rs2`, `cb.wnez $rz? target`
  -- confirmed by the `.fmtstring` having *no* leading space when an op
  has a modifier operand (contrast `addd`'s `" %s = %s, %s"`, which does),
  and independently by round-tripping `compd.lt`/`cb.wnez` through the
  real assembler. The dialect's own `LVX_BcuCondAttr`/`LVX_IntCompAttr`
  case names (e.g. `wnez`, `lt`) omit the leading dot (MLIR keyword
  syntax), so emission must add it back.
- Control flow: `goto <label>` (unconditional), `call <label>`, `ret`,
  `scall <N>` (unused here, harness-only). `call` is the one exception to
  "control flow only appears as a block terminator": a real `call` returns
  control to the very next instruction, so `lvx_func.call` legitimately
  sits mid-block and has no `Terminator` trait -- it's emitted via its own
  case in `emitOp`'s dispatch, not `emitTerminator`'s (see
  `docs/lvx/RegisterAllocation.md`, "Return-address save/restore", for the
  bug this caused before it had one).
- Bundle terminator: `;;` on its own line after each bundle.
- Comments: `#`. Labels: `name:` for global/function symbols, `.Lxxx:` for
  internal-only ones (block labels here), plus the usual numeric
  local-label convention (`1:`/`1b`/`1f`) this pass doesn't use. **Gotcha,
  found by actually assembling the output**: `.L`-prefixed labels are
  excluded from the output symbol table but are *not* auto-scoped the way
  GNU-as's numeric local labels are -- two functions each emitting
  `.LBB0` collide as a duplicate-symbol error in the same assembled file.
  Block-label numbering must be a single counter for the whole module, not
  reset per function.

## Scope: supported ops

Every `lvx`/`lvx_cf`/`lvx_func` op actually reachable from `ConvertToLVX`'s
lowering plus the register allocator's own insertions (`lvx.sp`,
spill `lvx.ld`/`lvx.sd`) has a 1:1, correctly-matching real opcode and is
emitted directly. One op is **explicitly unsupported, hard error rather
than silently wrong output**:

- **`lvx.cmoved`**: the dialect models a full 3-operand select
  (test, trueValue, falseValue → result); the real opcode (`CMOVED`,
  confirmed via `lvx-opc.c`) is an in-place conditional move with only
  *two* value registers (test, src) that leaves the destination unchanged
  when the condition is false -- semantically different, not just a syntax
  gap. Reconciling this needs a dialect-level design decision, not an
  emission-time workaround.

Not exercised by any current lit test's *emission* path (the register-
allocation tests use it structurally, but no straight-line kernel test
reaches assembly emission through it yet), so this is a documented gap,
not a silently-passing broken path.

### `divmod`'s dual output: pinned register pair, implemented

`lvx.divmodd`/`lvx.divmodud`/`lvx.divmodw`/`lvx.divmoduw`'s real opcode
destination is a `registerM` operand class -- an *adjacent register
pair* -- but the dialect's quotient and remainder are two independently-
allocated values that Steps 1-3 can land on any two (possibly
non-adjacent) registers. The *general* version of this problem (an
arbitrary candidate needing an arbitrary aligned pair) needs register-
pair/`RegClass` allocation, still future work (`docs/lvx/
MultiRegisterClasses.md`); `divmod`'s own case is narrower -- it's always
the *same* op needing the *same* kind of pair, at a point where the
allocator already has ordinary registers picked out for the quotient and
remainder -- and that narrower shape has a narrower fix, `-lvx-rewrite-
divmod` (`RewriteDivmod.cpp`), reusing machinery this project already had
with no changes to Steps 1-3 themselves.

**Ground truth, confirmed against real ground truth and, where the
extracted YAML text was ambiguous, against the real toolchain directly:**

- `DIVMODD`'s format (`ALU_DDMWRR`) destination operand is `{ pairedReg:
  registerM }` -- a distinct operand class from `{ singleReg: ... }`,
  encoded in a 5-bit field (`registerM: "-----"`) versus `singleReg`'s
  6 bits, i.e. `registerM` names one of 32 register *pairs* directly,
  confirmed via `lvx-mds/lvx-refs/FE/YAML/lvx/lvx_v1/Description.yml` (its
  `Format` entries).
- **Assembly syntax**: `$r<even>r<odd>` with no separator or dot (e.g.
  `divmodd $r30r31 = $r1, $r2`) -- found empirically, since the register-
  name table in `lvx-binutils/opcodes/lvx-opc.c` lists entries like
  `{30, "$r30r31.lo"}`/`{31, "$r30r31.hi"}` that turned out to be a
  *different* operand class (word views into a pair, not `pairedReg`
  itself); brute-forcing candidate syntaxes against the real `lvx-mbr-as`
  and disassembling the accepted one with `lvx-mbr-objdump` was what
  actually nailed it down, not the register-name table alone.
- **Low register = quotient, high register = remainder**: the YAML's
  `execution:` block packs the result into one 128-bit value
  (`result1.64[0]` = quotient, `result1.64[1]` = remainder) but doesn't
  independently name which physical register holds which half. Confirmed
  by actually running `divmodd $r0r1 = $r2, $r3` on real gem5 with
  `$r2=17, $r3=5` and reading back `$r0`/`$r1` separately: `$r0` (low) =
  3 (the quotient), `$r1` (high) = 2 (the remainder).

**The key simplification: a valid pair already sits inside the existing
scratch reservation.** Step 3's `kSpillScratchRegs` (`docs/lvx/
RegisterAllocation.md`, "Reserved scratch registers") is `{r29, r30,
r31}` -- and `r30:r31` (pair index 15: `2×15=30`, `31=30+1`) is already a
*valid, aligned* pair, entirely within that existing reservation. That
reservation's own comment already anticipated this exact need ("covers
the worst case among currently-defined ops needing simultaneous scratch
registers: ... `lvx.divmodd`/.../'s two results") without yet spelling out
that they'd need to be an aligned pair specifically -- they already are,
by what looks like foresight rather than coincidence. No new register
needs to be carved out of the general pool; `r29` is left over for
whatever else already uses single-register scratch (e.g. the
hardware-loop trip count, `docs/lvx/HardwareLoops.md`, uses `r29`
itself -- `r30`/`r31` stay free for this).

**The mechanism: a post-allocation rewrite, exactly like
`-lvx-scf-to-cf`'s own pattern.** `SCFToCF.cpp` already established the
precedent this follows: run *after* `-lvx-allocate-registers` has picked
ordinary registers for every value, synthesize a new op with a result
*pinned* to a reserved scratch register (`SbfdOp`'s trip count, pinned to
`r29`), and -- where the pinned value needs to end up somewhere else --
bridge the gap with an ordinary `lvx.mv` copy (the induction-variable
copy-in, the ABI copy-in/copy-out at function boundaries). The same shape
applies here, as its own new pass, `-lvx-rewrite-divmod`:

1. Steps 1-3 allocate `%q, %r = lvx.divmodd %a, %b` completely
   normally -- `%q`/`%r` land on whatever ordinary, unpinned registers the
   scan picks, exactly like any other value; no allocator changes needed.
2. `-lvx-rewrite-divmod`, run after `-lvx-allocate-registers`, finds every
   `lvx.divmodd`/`divmodud`/`divmodw`/`divmoduw` op and rewrites it in
   place: retypes its own two results to the fixed pair
   (`!lvx.reg<r30>`/`!lvx.reg<r31>`), then, for each result that actually
   has a use, inserts an `lvx.mv` copy from `r30`/`r31` into that result's
   *original* allocated register (skipped for a discarded quotient or
   remainder -- `arith.divsi`/`remsi` each lower to their own full
   `lvx.divmodd`, per the "duplicates the divmod computation" note above,
   so one of the two results is often unused; a no-op, harmless copy in
   the rare case Steps 1-3 happened to pick `r30`/`r31` already -- same
   "cheap even when same-register" reasoning already used for the
   induction-variable copy-in).
3. `-lvx-emit-asm` gets a matching case: prints the `divmod` family using
   the confirmed `pairedReg` destination syntax, re-deriving the pair from
   the (by then always r30:r31) result types rather than hard-coding them,
   so a mis-ordered pipeline is caught as an error instead of emitting
   wrong syntax silently.

Steps 1-3's actual allocation logic needed **no changes** -- `%q`/`%r`
never become fixed/pinned intervals in the allocator's own view, they're
ordinary values like any other. Verified with a full `arith.divsi`/
`arith.remsi` kernel run through the entire pipeline (`convert-to-lvx` →
`lvx-allocate-registers` → `lvx-rewrite-divmod` → `lvx-scf-to-cf` →
`lvx-emit-asm` → real `lvx-mbr-as`/`lvx-mbr-ld` → real `lvx-gem5`): `17 /
5, 17 % 5` computed as `q*100+r`, exit code 302, matching `3*100+2`.

**Why a `swap` instruction (`docs/lvx/LinearScanComparison.md`'s Hack
2006 discussion) doesn't help here, for the record.** It was considered
and doesn't apply: swap/permutation machinery resolves values that need
to trade places with each other, which isn't `divmod`'s problem at all.
Nothing needs to be exchanged in place -- the quotient/remainder just
need to move *out* of a hardware-fixed pair after the instruction runs,
into wherever they were already going to live. That's two ordinary
one-way copies (step 2 above), not a permutation, and this project
already has a mechanism for exactly that shape without needing any
bundling trick.

### `ffma`/`ffms`: implicit accumulator, implemented

`lvx.ffmad`/`lvx.ffmaw`/`lvx.ffmsd`/`lvx.ffmsw` were declared in the
dialect (`ops.mlir` had a bare parser/printer round-trip test) but had
never actually been checked against a real opcode until now, the same gap
`divmod`'s dual output and the call ABI-pinning issue both turned out to
have: existing doesn't mean correct.

Real `FFMAD`/`FFMAW`/`FFMSD`/`FFMSW` (`registerW_registerZ_registerY`
shape) have only two explicit source registers -- the destination doubles
as the third, implicit "accumulate into" operand, confirmed by hand-
assembling `ffmad $r1 = $r2, $r3` with the real `lvx-mbr-as` (accepted,
disassembles back identically) versus a 4-register form (rejected: "Extra
token when parsing"). `-lvx-emit-asm` used to fall through to the generic
arity-based dispatch for these ops (3 operands, 1 result → the wrong
4-register ternary shape); it now has its own case (`emitFma`) that prints
only the two non-accumulator source registers and hard-errors if the
accumulator operand's register doesn't match the result's -- which is only
possible if `-lvx-allocate-registers`'s new coalescing (docs/lvx/
RegisterAllocation.md, "`ffma`/`ffms` accumulator coalescing") didn't run,
so this is a pipeline-ordering check, not a normal-path failure.

Verified via the real `lvx-mbr-as`/`lvx-mbr-objdump` round-trip
(`emit-asm.mlir`'s `@ffma` case) and via real execution on `lvx-gem5`
(a chained `ffmad`→`ffmsd` kernel, bit-exact against an independently
computed fused result) -- see `docs/lvx/EndToEndValidation.md`, "`ffma`/
`ffms` accumulator coalescing, verified end to end" for the full account,
including two since-fixed `lvx-gem5` crashes this verification ran into
along the way (floating-point arithmetic, then comparisons -- both
sibling-project gaps, not this fix's own correctness).

**Out of scope, not attempted**: `FFMAH`/`FFMSH` (half-precision) and
`FFMAWC` (complex-number fused multiply-add with `conjugate`/`imultiply`
modifiers) also match "`FFMA*`/`FFMS*`" in `Opcode.table`, but neither fits
this dialect's current phase -- no half-precision op of *any* kind exists
yet (not even plain `faddh`), and `FFMAWC`'s complex/lane-packed semantics
belong with the later SIMD phase (top-level CLAUDE.md, "Current phase"),
not scalar arithmetic. The `fnegate` modifier (an overall-negate on the
whole FMA, distinct from the `mulnAdd`/subtract already modeled) also
isn't represented, matching the existing gap that float `mode` (rounding)
attributes are accepted at the dialect level but silently dropped by every
current float-op emission path, not just `ffma`/`ffms` -- a pre-existing,
broader issue, not reintroduced by this fix.

### `lvx.sp` is never emitted

`lvx.sp`'s only purpose was to give the (pre-emission) SSA IR an anchor
value for "the r12 register" so spill loads/stores could reference it as a
normal operand. In real assembly there's no such instruction -- you just
write `$r12` directly. Emission special-cases `lvx.sp`'s result: no
instruction is printed for the op itself, and every *use* of its result
prints `$r12` directly (looked up from the value's own pinned type, which
is always `<r12>` by construction).

### `lvx.mv`/`lvx.li` lower to real opcodes at emission time

Per their own doc comments (pseudo-ops, "not a single real opcode"):
`lvx.mv` → `copyd`/`copyw` (width picked the same way `ConvertToLVX`
already picks `d`-vs-`w` mnemonics elsewhere: from a `-w`/`-d`-suffixed
sibling convention -- here, simplest and sufficient since every value is
LP64: always `copyd`, matching this dialect's "one unified 64-bit GPR
file" design and the fact that no 32-bit-narrowed `lvx.mv` currently
exists in any lowering path). `lvx.li` → `make $rd = <value>`, printing an
`IntegerAttr`'s value directly or a `FloatAttr`'s bit pattern
(`APFloat::bitcastToAPInt`) -- the latter is a best-effort choice, not
verified against a real floating-point `make` test case, since no current
lowering path produces a float `lvx.li`.

## `lvx-scf-to-cf`: lowering after allocation

Standard `scf.for`-to-`cf` shape (header/body/exit), operating on
already-register-pinned types:

```
  br ^header(%lb, %init)
^header(%iv, %acc):
  %test = lvx.compd lt %iv, %ub : (...) -> !lvx.reg<r29>
  lvx_cf.cond_br wnez %test : ..., ^body, ^exit
^body:
  ...original body, with %iv/%acc now header block args...
  %next = lvx.addd %iv, %step : ... -> <iv's own type>
  br ^header(%next, %yielded)
^exit:
  ...rest of function, using %acc (header's arg) as the for op's result...
```

`%iv`/`%acc`'s header-block-argument types are copied directly from the
original `lvx_scf.for`'s already-allocated operand/body-arg/result types
(no new allocation decision -- Steps 2/3 already guaranteed `initArg`,
`bodyIterArg`, `yieldOperand`, and `result` all share one register, and
the induction variable keeps its own individually-assigned one).

### New values needing a register

The loop-test comparison (`%test` above) and the induction variable's
increment (`%next`) are brand-new SSA values with no allocation decision
from Steps 2/3 (they didn't exist during that scan). Since this pass runs
strictly *after* `-lvx-allocate-registers`, there's no allocator left to
consult -- so it reuses Step 3's existing reserved spill-scratch
registers (`docs/lvx/RegisterAllocation.md`, "Reserved scratch
registers"): `%test` gets `r29` (Step 3's own store-scratch register, safe
to reuse here for the same reason it's safe there -- these transient,
single-use, non-overlapping windows never collide with anything else,
since r29-r31 are permanently excluded from the general pool), `%next`
reuses the induction variable's own type (it's produced and consumed
within one bundle-adjacent window before the branch, same non-overlap
argument). This is a deliberate, documented coupling: `-lvx-scf-to-cf` is
not a general-purpose lowering usable at an arbitrary pipeline point, only
immediately after `-lvx-allocate-registers`.

Signedness: the comparison is always `lt` (signed less-than). The dialect
doesn't currently track loop-bound signedness (`lvx_scf.for`'s bounds are
plain `!lvx.reg`, no sign marker), so this is a simplification, not a
derived fact -- fine for the counted-up loops every current test uses,
worth revisiting if an unsigned-bound loop ever matters.

## Bundling

One instruction per bundle (a `;;` after every instruction). Real VLIW
co-issue (packing independent instructions into the same bundle) is
explicit future work per the top-level `CLAUDE.md` ("no software
pipelining... yet") -- correct but unoptimized output, not a correctness
gap.

## Testing

Beyond FileCheck lit tests for both passes' own IR/text output
(`mlir/test/Dialect/LVX/{scf-to-cf,emit-asm}.mlir`), `emit-asm.mlir`'s
trailing RUN line additionally assembles the straight-line/branch-diamond/
loop output with the *real* `lvx-mbr-as` — an actual integration check, not
just pattern matching. This depends on the sibling `lvx-csw` checkout's
toolchain existing at a fixed path; if that ever moves, update the path
there rather than deleting the check. Two real bugs were caught exactly
this way, not by reasoning about the code: the induction-variable
copy-in gap (`lvx-scf-to-cf`'s own section above) and the module-wide
(not per-function) block-label numbering requirement ("Confirmed syntax").

**Later landed** (`docs/lvx/EndToEndValidation.md`): a full link-and-run
under the real `lvx-gem5` ISS was attempted here and blocked at the time —
the `lvx-gem5/build/LVX/gem5.opt` binary segfaulted with `SIGILL` on *any*
input, confirmed pre-existing and unrelated to this work by reproducing
the identical crash on `lvx-gem5`'s own already-verified `compute.s` smoke
test (that project was being actively rebuilt at the time). By the time a
real kernel was carried all the way through execution, the rebuild had
completed and gem5 ran correctly; that same end-to-end exercise also found
and fixed three real, previously-latent bugs (register-allocator branch-
argument coalescing, `sbfd`'s reversed operand order, and an induction-
variable live-interval gap) that pure structural/FileCheck testing could
never have caught, since none of them produced wrong-*shaped* IR or
assembly, only wrong *numbers*.
