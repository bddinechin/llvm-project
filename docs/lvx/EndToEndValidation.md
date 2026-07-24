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
