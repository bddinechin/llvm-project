# Assembly emission

Status: implemented and tested (`-lvx-scf-to-cf`, `-lvx-emit-asm`),
including assembling real output with the sibling `lvx-csw` toolchain; not
yet committed.

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
convert-to-lvx  →  lvx-allocate-registers  →  lvx-scf-to-cf  →  lvx-emit-asm
```

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
  `<mnemonic> $rd = $rs` (unary/copy) -- `addd`, `sbfd`, `muld`, `andd`,
  `iord`, `eord`, `slld`, `srad`, `srld`, `notd` and the `w`-suffixed
  32-bit forms, plus `copyd`/`copyw` (what `lvx.mv` lowers to -- see
  below) and `make` (what `lvx.li` lowers to).
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
  `scall <N>` (unused here, harness-only).
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
emitted directly. Two ops are **explicitly unsupported, hard error rather
than silently wrong output**:

- **`lvx.cmoved`**: the dialect models a full 3-operand select
  (test, trueValue, falseValue → result); the real opcode (`CMOVED`,
  confirmed via `lvx-opc.c`) is an in-place conditional move with only
  *two* value registers (test, src) that leaves the destination unchanged
  when the condition is false -- semantically different, not just a syntax
  gap. Reconciling this needs a dialect-level design decision, not an
  emission-time workaround.
- **`lvx.divmodd`/`lvx.divmodud`/`lvx.divmodw`/`lvx.divmoduw`**: the real
  opcode's destination is a `registerM` operand class -- an *adjacent
  register pair* -- but the dialect's quotient and remainder are two
  independently-allocated `AllocItem`s that can land on any two (possibly
  non-adjacent) registers. Fixing this needs register-pair/`RegClass`
  allocation, already called out as explicit future work in the top-level
  `CLAUDE.md` ("later phases... `RegFile`/`RegClass` (`PGR`/`QGR`) data").

Neither is exercised by any current lit test's *emission* path (the
register-allocation tests use them structurally, but no straight-line
kernel test reaches assembly emission through one yet), so this is a
documented gap, not a silently-passing broken path.

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

**Attempted, not landed**: a full link-and-run under the real `lvx-gem5`
ISS (assemble → link with a tiny `_start` driver, mirroring
`validation/lib/crt.S` → run via `tests/lvx/run_lvx.py`). The assembled
straight-line/branches/loop kernels linked cleanly, but the current
`lvx-gem5/build/LVX/gem5.opt` binary segfaults with `SIGILL` on *any*
input — confirmed pre-existing and unrelated to this work by reproducing
the identical crash on `lvx-gem5`'s own already-verified `compute.s` smoke
test. This is an `lvx-gem5`-side build/environment issue (that project was
being actively rebuilt at the time), not something to chase down here;
worth retrying once that's resolved.
