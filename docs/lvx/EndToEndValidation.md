# End-to-end validation: a real kernel through the whole pipeline

Status: done. Four real bugs found and fixed; one known limitation
documented, not fixed.

## Motivation

Every prior test in this project's history (Steps 1-3, hardware loops,
assembly emission, nested-loop coalescing) was validated against
hand-written `lvx`-dialect IR, or against `-convert-to-lvx` output checked
only structurally (FileCheck on the printed op names/operand types). Never
before had a kernel gone through the *entire* pipeline --
`arith`/`scf`/`func` source, through `-convert-to-lvx`,
`-lvx-allocate-registers`, `-lvx-scf-to-cf`, `-lvx-emit-asm`, the real
`lvx-mbr-as`/`lvx-mbr-ld`, and actual execution on the real `lvx-gem5` ISS
-- and never before had generated code's *numeric* correctness been
checked, only its shape. This exercise closed that gap, using:

```mlir
func.func @sum_squares(%n: index) -> i64 {
  %c0 = arith.constant 0 : index
  %c1 = arith.constant 1 : index
  %zero = arith.constant 0 : i64
  %sum = scf.for %i = %c0 to %n step %c1 iter_args(%acc = %zero) -> i64 {
    %iv64 = arith.index_cast %i : index to i64
    %sq = arith.muli %iv64, %iv64 : i64
    %newacc = arith.addi %acc, %sq : i64
    scf.yield %newacc : i64
  }
  return %sum : i64
}
```

Computing `sum(i*i for i in 0..n-1)`, checked against two different `n`
(5 -> 30, 7 -> 91) run on real gem5, both correct after the fixes below.
This is a small kernel, but it is the *first* one in the project's history
whose loop body reads its own induction variable and whose function has a
real ABI argument threaded through a whole-program conversion -- both
"obvious" things a real kernel does that no existing hand-written test
happened to exercise, and both of which turned out to be broken.

## Bugs found, in the order they surfaced

### 1. Register allocator never coalesced ordinary `lvx_cf` branch edges

`-lvx-allocate-registers`'s `buildAllocItems` (`RegisterAllocation.cpp`)
only ever union-find-coalesced `lvx_scf.for`'s own loop-carried tuples
(init/iter_arg/yield/result). A plain `lvx_cf.br`/`cond_br` with block
arguments -- which is exactly the shape `-convert-to-lvx`'s
`FuncFuncToLVX` pattern always produces for a function's entry block (copy
ABI args in, then branch into the real body block, per top-level
CLAUDE.md's own note that this must handle non-entry blocks too) -- got
each side of the edge allocated *independently*, with nothing forcing the
branch operand's register to match the destination block argument's
register. Every existing hand-written test used bare (argument-less)
blocks for `lvx_cf.br`, so this was never exercised; real
`-convert-to-lvx` output hits it immediately (a type-mismatch verifier
error on the very first pipeline run).

Fixed by extending the same union-find pass to walk every
`BranchOpInterface` op and unite each forwarded operand with the matching
successor block argument -- the same JOIN/phi-coalescing idea already used
for loops, just generalized to `cf`-style edges. A genuine multi-
predecessor merge point unions correctly too (every incoming edge's
operand and the shared block argument land in one connected component).

### 2. `sbfd`/`sbfw`/`fsbfd`/`fsbfw` have "subtract FROM" semantics, backwards from every caller's assumption

Real hardware (`lvx-mds/refs/FE/YAML/lvx/lvx_v1/Description.yml`, `SBFD`
et al.): "The %2 is subtracted from the %3" -- `mnemonic $rd = $rs1, $rs2`
computes `$rs2 - $rs1`, the *reverse* of every other binary op's
`$rd = $rs1 op $rs2` reading. Confirmed both from the spec text and
empirically on real gem5 (`sbfd $r1 = $r1, $r2` with r1=5, r2=0 executes
to -5, not 5).

Every existing call site -- `arith.subi` lowering (`ConvertToLVX.cpp`,
`SubIToLVX`), the `i1`-to-wider signed-extension pattern (`0 - x` for
sign-extending a 1-bit value), and this exercise's own hardware-loop
trip-count computation (`SCFToCF.cpp`'s `lowerForHardware`, `ub - lb`) --
assumed ordinary `lhs - rhs` and got the reverse. This had gone completely
unnoticed because every test checking `sbfd`/`fsbfd` output was a
structural FileCheck (does the op appear, with which operand *names*), and
none ever executed the result and checked the actual arithmetic value --
exactly the class of bug only a real execution test can catch. In this
kernel's case the reversed subtraction fed directly into `loopdo`'s trip
count: `ub - lb` computed backwards is a huge unsigned value (two's
complement of a small negative number), which manifested as an apparent
*hang* under gem5 (not a crash) -- trillions of loop iterations, not an
infinite loop, indistinguishable from one within any reasonable timeout.

Fixed at the printer (`EmitAsm.cpp`'s new `emitBinarySubtractFrom`), not
at each call site: `SbfdOp`/`SbfwOp`/`FsbfdOp`/`FsbfwOp` keep their
dialect-level `$lhs`/`$rhs` operands meaning the natural "result = lhs -
rhs" that every caller already assumes (matching every other binary op in
the dialect); only the *printed* operand order is swapped to match real
hardware's "subtract from" encoding. This transparently fixes all three
call sites above with a single change, rather than requiring every current
and future caller to remember to pass operands backwards.

### 3. Induction variable's live range didn't account for the lowering-synthesized increment

`-lvx-scf-to-cf` (both `lowerForBranch` and `lowerForHardware`) synthesizes
an in-place `iv = iv + step` increment immediately before the loop body's
terminator -- but it runs *after* `-lvx-allocate-registers`, so this
increment doesn't exist as an SSA op when Step 1 (`LiveIntervals.cpp`)
computes live ranges. Step 1 only saw the induction variable's *actual*
uses in the original `lvx_scf.for` IR; if the body reads `iv` for its own
purposes (this kernel: copying it out to multiply by itself), that read is
usually the induction variable's *only* visible use, so its computed
interval ended right there -- long before the body's end, where the
synthesized increment will actually need to read it back. Nothing in the
existing hand-written test suite ever read `iv` inside a loop body, so
this was invisible until now: another value (here, the squared result)
could legally get allocated the same register in the gap, silently
clobbering `iv` before the increment ran.

The `step` operand has the identical problem for a different reason: it
has *no* use anywhere in the original IR except as the `for` op's own
operand (never referenced inside the body), so it never got any interval
extension at all; the synthesized increment reads it at the body's end
regardless.

Fixed by explicitly extending both intervals (induction variable and
`step`) to the body's last instruction in `LiveIntervals.cpp`'s
`buildIntervals`, mirroring how call-crossing is already a precomputed
restriction rather than a plain SSA-use fact -- this is the same class of
"implicit use invisible to generic dataflow" gap.

### 4. (Not a codegen bug) No `$ra` save/restore anywhere in the pipeline

Discovered while building the driver, not the kernel itself: LVX has a
single link register (`$ra`), no hardware call stack (per top-level
CLAUDE.md's ABI note). A hand-written driver that nests two nonleaf `call`s
(`_start` calls `main`, `main` calls a function and then itself `ret`s)
hangs -- confirmed by direct reproduction (`nestedcall.s`) independent of
any lvx-mlir-generated code: the second `call` overwrites `$ra` before the
first caller's own `ret` gets to use it, so that `ret` jumps back to
itself and spins forever (not a real "hang," but computationally
indistinguishable from one for a program this size).

Checked against the actual pipeline: neither `RegisterAllocation.cpp` nor
`EmitAsm.cpp` has any `$ra` save/restore logic for `lvx_func.call`/
`lvx_func.return` -- so any *compiled* non-leaf function (one that both
calls something and is itself called) would hit the identical bug. This
kernel (`sum_squares`) is a leaf (calls nothing), so it isn't affected,
and the validation driver was rewritten to a single call level
(`_start` calls `sum_squares` directly) specifically to sidestep this
rather than fix it. **Deliberately not fixed now** -- out of scope for
this exercise, and a real fix (caller- or callee-saved `$ra` around calls,
i.e. a genuine prologue/epilogue for non-leaf functions) is a
substantially bigger feature than anything else in this session. Flagged
here so it isn't rediscovered the hard way; the next kernel that needs a
real call graph (not just a single-level driver) will need this.

**Fixed later** (see the "return-address save/restore, and a real call
chain (2026-07-30)" section below) -- this is no longer a known limitation.

## What this confirms

- `lvx-gem5`'s build is healthy again (it was confirmed broken -- universal
  SIGILL on every ELF, including its own pre-existing smoke tests -- the
  last time this was checked, during the assembly-emission phase). All of
  `exit42.s`, `hwloop0.s`, `hwloop3.s` (pre-existing smoke tests) and this
  kernel now execute correctly.
- The hardware-loop (`LOOPDO`) lowering is correct on real hardware, not
  just correct-looking in disassembly -- this is the first time any
  `lvx_cf.loopdo` this project emitted has actually *executed*.
- The nested-`lvx_scf.for` union-find coalescing fix
  (`docs/lvx/RegisterAllocation.md`) and the branch-argument coalescing fix
  above are both instances of the same underlying idea (Mössenböck-style
  JOIN/phi coalescing via union-find); the codebase now applies it
  uniformly across both `lvx_scf.for` loop-carried channels and ordinary
  `lvx_cf` control flow.

## Re-verified on the rebuilt, dual-core `lvx-gem5` (2026-07-28)

`lvx-gem5` was rebuilt again after the above, now producing two
core-specific binaries, `build/gem5-lvx1.opt` and `build/gem5-lvx2.opt`
(the old single `build/LVX/gem5.opt` path no longer exists -- see the
`lvx_csw_toolchain` reference memory). Re-ran every execution check from
this doc (`exit42`/`hwloop0`/`hwloop3` smoke tests, `sum_squares` at
`n=5` and `n=7`, and `scf-to-cf.mlir`'s `@nested_combined_accumulator`)
against both binaries: all six give the same correct results
(`42`/`0`/`3`/`30`/`91`/`46035`) on both `gem5-lvx1.opt` and
`gem5-lvx2.opt`, with identical tick/cycle counts between the two on this
test set (unsurprising under the `atomic` CPU model, which doesn't model
timing at all). lvx-mlir only targets the `lvx_v1` core (`CLAUDE.md`'s
ground-truth note), so `gem5-lvx1.opt` is the one that actually matters
going forward; `gem5-lvx2.opt` agreeing is a bonus cross-check, not a
claim that lvx-mlir targets that core too.

One methodological note worth keeping: the first re-run attempt (reusing
the `.elf` files built during the original exercise, before this rebuild)
gave a wrong result (`0` instead of `30`/`91`) on the `sum_squares`
kernel specifically, while the smoke tests and the combined-accumulator
kernel -- built in the same original session -- still ran correctly. That
turned out to be a stale-artifact problem, not a real regression: a fresh
rebuild from the same unchanged source (re-run through `mlir-opt`,
re-assembled, re-linked with the rebuilt toolchain) gave the correct
result immediately. After any toolchain or `lvx-gem5` rebuild, rebuild
`.o`/`.elf` artifacts from source rather than reusing old ones sitting
around from before the rebuild, even for cases that look unrelated to
whatever changed.

## `divmod` kernel, real quotient/remainder through the full pipeline (2026-07-28)

A second real kernel, once `-lvx-rewrite-divmod` existed
(`docs/lvx/AssemblyEmission.md`, "`divmod`'s dual output: pinned register
pair, implemented"):

```mlir
func.func @divmod_kernel(%n: i64, %d: i64) -> i64 {
  %q = arith.divsi %n, %d : i64
  %r = arith.remsi %n, %d : i64
  %c100 = arith.constant 100 : i64
  %scaled = arith.muli %q, %c100 : i64
  %result = arith.addi %scaled, %r : i64
  return %result : i64
}
```

Run through `convert-to-lvx` → `lvx-allocate-registers` →
`lvx-rewrite-divmod` → `lvx-scf-to-cf` → `lvx-emit-asm` → real
`lvx-mbr-as`/`lvx-mbr-ld` → real `lvx-gem5`, with a driver calling it as
`divmod_kernel(17, 5)`: exit code `302`, matching the hand-computed
`3*100 + 2` (`17 / 5 = 3`, `17 % 5 = 2`). `arith.divsi`/`arith.remsi`
each lower to their own independent `lvx.divmodd` (per `ConvertToLVX`'s
"duplicates the divmod computation" note), so this also exercises two
separate `divmodd` instructions in the same function, each pinned to and
copied out of the same `r30:r31` pair in sequence -- no interference
between the two, confirming the "always transient, dead before the next
instruction" reasoning the reserved-pair design relies on.

## Return-address save/restore, and a real call chain (2026-07-30)

Implementing `$ra` save/restore (`docs/lvx/RegisterAllocation.md`,
"Return-address save/restore") for real, and trying to verify it end to
end with a genuine compiler-generated call (not a hand-written driver
calling a single leaf kernel, like every prior exercise above), surfaced
two more previously-unknown bugs in the same area, both fixed as part of
this work:

1. **`lvx_func.call` emission was silently wrong.** It has no `Terminator`
   trait (a real `call` returns control to the very next instruction, so
   it legitimately sits mid-block, unlike `lvx_cf.br`/`lvx_func.return`) --
   so `-lvx-emit-asm`'s `emitBlock` never routed it to `emitTerminator`'s
   (correct, but dead) `CallOp` handling, and it fell through to the
   generic arity-based `.Default` dispatch instead. For a 1-operand/
   1-result call this misfired as a plain binary op, printing `call $r0 =
   $r0` -- ignoring the callee symbol entirely -- which real `lvx-mbr-as`
   rejects outright. Fixed by giving `lvx_func.call` its own case directly
   in `emitOp`'s `TypeSwitch`.
2. **A call's operands/results were never pinned to the ABI's
   argument/result registers anywhere in the real pipeline.** Confirmed by
   running a real multi-argument `func.call` through `-convert-to-lvx` and
   observing the emitted `lvx_func.call`'s operands/results were plain
   unpinned `!lvx.reg` -- meaning Step 1-3's general register-allocation
   scan was free to assign them to whatever register was convenient, not
   necessarily where the callee actually expects/produces them. This is a
   real correctness gap for *any* compiled call with real arguments, not
   just a `$ra` corner case. Fixed in `ConvertToLVX.cpp`'s `CallToLVX`
   pattern by mirroring the copy-in/copy-out shape already used for
   function entry/exit: `lvx.mv` each operand into its pinned argument
   register immediately before the call, `lvx.mv` each pinned result back
   into a fresh virtual register immediately after.

With both fixed, a genuine two-level call chain was compiled and run
end to end:

```mlir
func.func private @callee(%x: i64) -> i64 {
  %c1 = arith.constant 1 : i64
  %r = arith.addi %x, %c1 : i64
  return %r : i64
}
func.func @caller(%a: i64) -> i64 {
  %r = func.call @callee(%a) : (i64) -> i64
  %c2 = arith.constant 2 : i64
  %s = arith.addi %r, %c2 : i64
  return %s : i64
}
```

`@caller` is non-leaf (it calls `@callee`), so it gets the full `$ra`
save/restore prologue/epilogue even though nothing is spilled. Run through
the same full pipeline as the kernels above, assembled/linked with the
real toolchain, and driven by a hand-written `_start` that does
`make $r0 = 10`, `call caller`, `scall 1`: exit code `13`, matching the
hand-computed `(10 + 1) + 2`. Without the `$ra` fix this would hang
(`@caller`'s own `ret` would loop back into itself after `@callee`'s
`call` clobbers `$ra`); without the two emission/ABI-pinning fixes above,
it wouldn't even assemble. All 15 lit tests continue to pass.

## `ffma`/`ffms` accumulator coalescing, and floating-point instructions crash `lvx-gem5` (2026-07-30)

Checking whether `lvx.ffmad`/`lvx.ffmaw`/`lvx.ffmsd`/`lvx.ffmsw` (declared
in the dialect, but never exercised beyond a bare parser/printer
round-trip test) could actually be generated correctly surfaced the same
"does this op existing prove it works" gap as the divmod dual-output bug
and the call ABI-pinning issue: real `FFMAD` et al. have no separate
destination register (the accumulator operand and the destination are the
same physical register on real hardware), which this dialect's plain
3-independent-operand modeling didn't enforce anywhere. Fixed --
`-lvx-allocate-registers` now coalesces the accumulator operand with the
op's own result (with a defensive copy when the accumulator is read again
elsewhere), and `-lvx-emit-asm` prints the real two-source-register form
instead of a non-existent 4-register one. Full details and the (also
fixed) `a*b-c` → `c-a*b` sign-doc bug: `docs/lvx/RegisterAllocation.md`,
"`ffma`/`ffms` accumulator coalescing", and `docs/lvx/AssemblyEmission.md`,
"`ffma`/`ffms`: implicit accumulator, implemented".

Verification hit a wall one level lower than any previous exercise in this
project's history, though: trying to actually *run* an `ffmad` on real
`lvx-gem5` (the same rigor as every kernel above) crashes the simulator
itself --

```
$ build/gem5-lvx1.opt tests/lvx/run_lvx.py ffma_isolated.elf
...
== LVX gem5 (atomic): beginning execution of .../ffma_isolated.elf ==
Illegal instruction (core dumped)
```

This is gem5's own process taking `SIGILL` and dumping core -- not a
simulated trap inside the guest program (compare to a real illegal
instruction in the guest, which gem5 would report and handle without
crashing itself). Isolated down to confirm scope:

- The assembled encoding round-trips correctly through the real
  `lvx-mbr-as`/`lvx-mbr-objdump` (`ffmad $r3 = $r5, $r0` assembles and
  disassembles back to itself) -- this is not an encoding bug on the
  lvx-mlir/toolchain side.
- A `make` loading the same 64-bit float bit pattern into a register, with
  no FPU-class instruction after it, runs fine (`exit code 0` as
  expected).
- **Every floating-point instruction tried crashes gem5 identically, not
  just `ffmad`**: a plain `faddd $r0 = $r5, $r0` (no `ffma`-specific
  coalescing involved at all) crashes exactly the same way. This is a
  general, pre-existing gap in this build's floating-point instruction
  support, not anything specific to `ffma`/`ffms` or to this session's
  fix -- consistent with the fact that no kernel in this project's history
  (`sum_squares`, `divmod_kernel`, the `$ra` call-chain kernel above) ever
  exercised a single floating-point opcode on real gem5 before now.

**Out of scope, not attempted**: `lvx-gem5` is a sibling project
(`lvx-csw/lvx-gem5`), not part of this repository, and fixing a simulator-
level crash in its FPU instruction decode/execution is a substantially
different kind of work than anything else in this codebase. Flagged here
so it isn't rediscovered the hard way -- the next kernel that needs a
*real, executed* floating-point result (not just a correctly-assembled
one) will need this fixed on the `lvx-gem5` side first. This fix's own
correctness is verified at the assembler level (real encode/decode
round-trip) and structurally (the coalescing and emission lit tests), the
same standard `docs/lvx/RegisterAllocation.md`'s "What remains a hard
error" cases are held to when execution-level verification isn't available.
