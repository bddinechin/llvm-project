# Overlapping register classes: a reference for SIMD pairs/quads

Status: forward-looking reference, no code changes. LVX's register file
supports single registers, aligned register pairs, and aligned register
quadruples as overlapping operand classes -- but this project's dialect
and allocator don't implement any of that yet: `!lvx.pair`/`!lvx.quad`
are explicitly future work (`CLAUDE.md`, "Current phase"), and Steps 1-3
(`docs/lvx/RegisterAllocation.md`) allocate a single flat, interchangeable
register class (`!lvx.reg`, `kFullOrder`). This doc exists so the right
reference is on hand *when* that phase starts, not as a design in
progress now.

## Sources

> Michael D. Smith, Norman Ramsey, and Glenn Holloway, "A Generalized
> Algorithm for Graph-Coloring Register Allocation," PLDI 2004
> (`/home/guembu/Downloads/Smith_2004_PLDI.pdf`).

> Jonathan K. Lee, Jens Palsberg, and Fernando Magno Quintão Pereira,
> "Aliased Register Allocation for Straight-line Programs is NP-complete,"
> ICALP 2007 (`/home/guembu/Downloads/Lee_2007_ICALP.pdf`).

Not part of the linear-scan lineage discussed in
`docs/lvx/LinearScanComparison.md` -- this is Chaitin-style graph-coloring
allocation, generalized to handle two things Chaitin's original 1981
formulation assumes away: registers that are **not independent** (writing
one can change the value of another, i.e. aliasing) and registers that
belong to **more than one class** at once. Included here on its own,
separate from the linear-scan comparison doc, because it targets a
different problem (register *classes*) than that doc's scalar-allocator
comparison, using a different family of algorithm (graph coloring, not
linear scan).

The second paper is a direct follow-on to the first, by two of the same
authors' collaborators (Palsberg and Pereira, who also wrote the CSSA
paper discussed in `docs/lvx/LinearScanComparison.md`): it opens by
naming Smith/Ramsey/Holloway 2004 as "the best algorithm for aliased
register allocation so far" and asks the question that paper leaves open
-- does restricting to a simpler class of programs make aliased,
alignment-restricted register allocation any easier? The answer, proven
here, is no.

## The problem it solves

Chaitin's classic trivial-colorability test -- "node `n` is safe to color
if `degree_n < k`" -- assumes one flat register class with `k`
interchangeable, independent members. That breaks the moment a target has
aliasing (x86's `al`/`ah`/`ax`/`eax`, or ARM VFP's overlapping
single/double/quad-precision floating-point register views) or
non-disjoint classes (Motorola 68000's address-vs-data register
instructions). The paper's fix is a generalized criterion,
`squeeze_n* < |class_n|` (Eq. 1-2): `squeeze_n*` is the maximum number of
`class_n`'s own register names an adversary could deny `n` by choosing
colors for `n`'s neighbors. Computing this exactly is expensive, so
Sections 3.2-3.4 build a cheap, safe, and (for well-behaved architectures)
*exact* approximation via a **class tree**: classes related by
*alias-equivalence* (identical alias sets) or *alias-containment*
(`alias(C1) ⊂ alias(C2)`, written `C1 ⊏ C2`) are arranged into a tree, and
a precomputed "worst-case displacement" table lets the allocator update
each node's cached `squeeze` incrementally as neighbors enter or leave the
interference graph during simplification -- no more expensive, in the
common case, than Chaitin's original degree-counting.

## Where LVX's register file lands in their taxonomy

Section 3.4 ("Exactness") is the part that matters most here. The
approximation is not merely safe but **exact** -- no precision loss
relative to the (exponentially expensive) ideal `squeeze_n*` -- whenever a
register class's "multi-registers" are a power of two in size and align on
their own boundary. That is exactly LVX's own structure as described:
single registers, aligned pairs, aligned quadruples, each alias-contained
in the next (`Single ⊏ Pair ⊏ Quad`), forming the unique, optimal class
tree the paper's §3.4 construction always produces for this shape. Their
own worked example is the same pattern (single-precision register pairs
forming double-precision registers on MIPS/SPARC/PA-RISC and ARM VFP).

The negative case they give -- the Intel i960, whose triple-width integer
registers break exactness while remaining safe -- doesn't apply here.
Nothing in LVX's register file (`lvx-refs`' `RegFile`/`RegClass` tables,
`PGR`/`QGR` per `CLAUDE.md`) suggests a non-power-of-two
grouping. So *if* the class tree described in this paper is built for
LVX's actual register classes, the colorability criterion it produces
would be provably as good as an ideal, brute-force one -- not just a
conservative approximation that might over-spill.

**Read that last claim narrowly** -- it's about one local test (is a
single node's `squeeze` measure exact, not overcounting), not a claim
that the overall allocation problem becomes easy to solve. The next
section explains why that distinction matters a great deal for LVX.

## NP-completeness even in the easy case (Lee, Palsberg & Pereira 2007)

Smith 2004's `squeeze`/class-tree machinery runs *inside* a Chaitin-style
simplify-and-spill loop -- which is itself already a heuristic, because
graph coloring is NP-complete even for one flat, non-aliased register
class (Chaitin et al. 1981's original reduction). It would be easy to
read the previous section's "exact" result as meaning LVX's aligned
pair/quad case avoids that NP-hardness, given how much of this project's
own design leans on the fact that SSA-form, straight-line-like code makes
things easy elsewhere (`docs/lvx/LinearScanComparison.md`'s Wimmer
discussion: SSA gives short intervals and polynomial interval-graph
coloring for free). This paper shows that assumption doesn't survive
contact with aliasing.

Lee, Palsberg, and Pereira study almost exactly LVX's own pair model:
registers `r0..r(2K-1)`, where any *aligned* pair `r(2i), r(2i+1)` can
jointly hold a "long" value -- and restrict attention to straight-line
programs where each variable has at most one definition point (i.e.,
essentially SSA with no control flow at all, an even friendlier setting
than `lvx_scf.for`'s structured-but-general-purpose IR). For a
homogeneous register bank, this exact setting is the *easy* case:
interference graphs of straight-line single-def programs are interval
graphs, optimally colorable in linear time by greedy coloring on a
perfect elimination ordering -- precisely the property this project's own
Poletto & Sarkar-based Steps 1-3 already lean on for the current,
non-aliased `!lvx.reg` class. Their result (Theorem 1, via a 3-SAT → flow
→ "aligned 1-2-coloring" → register-allocation reduction chain): the
moment aligned-pair aliasing is added to that same easy setting, the
allocation decision problem becomes **NP-complete**. They also show the
*unaligned* version (any two registers may pair, not just aligned ones)
is separately NP-complete via a reduction to Stockmeyer's shipbuilding
problem, and note they could not reduce one direction to the other --
restricting to aligned pairs is not simply an easier special case of
general aliasing, it needed its own hardness proof.

**This applies to LVX's three-level model directly, by a trivial
reduction.** The paper only studies a two-level (single/pair) hierarchy,
but hardness of that restricted problem immediately implies hardness of
LVX's single/pair/quad model too: any straight-line program using only
singles and pairs is already a valid instance of the fuller model (simply
never construct a quad-typed value), so a polynomial algorithm for LVX's
model would solve their NP-complete problem as a special case. No new
reduction is needed to extend their result to quads.

**What this means concretely**: once `!lvx.pair`/`!lvx.quad` exist, no
allocator for them -- Smith's `squeeze`/class-tree machinery, the
bitset/buddy adaptation below, or anything else -- can be both polynomial
and *complete* (guaranteed to find a valid allocation whenever one
exists), unless P=NP. Smith's exactness result doesn't contradict this:
it says the *local* colorability test at each simplification step is as
precise as possible, not that the *global* search for a full coloring is
easy. Every real allocator in this space (Chaitin's original one
included) is a heuristic for an NP-complete problem; aliasing doesn't
introduce that heuristic-ness, it just proves it's unavoidable even in
the single friendliest input shape (straight-line, single-def) this
project's own design already relies on being easy in the non-aliased
case.

## Why the paper's own algorithm doesn't transplant directly

`squeeze`/the class tree/incremental recomputation on graph mutation exist
specifically to make trivial-colorability cheap to test *during Chaitin-
style graph simplification* (repeatedly removing low-degree nodes from an
explicit interference graph). Steps 1-3 here don't build an interference
graph or simplify one -- Poletto & Sarkar's linear scan tracks free
registers directly via an `active`-interval-list scan over a numbered
instruction stream (`docs/lvx/RegisterAllocation.md`). The two allocator
shapes don't share enough structure for the paper's specific
data-structure-and-recomputation machinery to drop in as-is.

## What does transplant: a bitset/buddy-style free-register tracker

The right-sized adaptation for *this* codebase's allocator is much
simpler than the paper's own algorithm, precisely because LVX's classes
are the "exact" power-of-two-aligned case: represent the free-register
pool as a bitset (one bit per single register, in place of today's flat
`kFullOrder` list) rather than adopting `squeeze`/class-tree bookkeeping.
A pair candidate is allocable at an aligned position iff both of its bits
are clear; a quad iff all four are; allocating or freeing a multi-register
candidate just sets/clears the corresponding bits together. This is
closer to a buddy allocator than to the paper's graph-coloring criterion,
and it's exact for exactly the same underlying reason the paper's own
approximation is exact for LVX's shape -- alignment and power-of-two
sizing remove any ambiguity about which singles a pair or quad occupies,
so there's no need for `squeeze`'s adversarial-coloring reasoning at all
in a scan-based allocator that already knows, at every program point,
precisely which registers are currently live.

That exactness is still only about *reading off which registers a
candidate would occupy* -- it says nothing about whether greedily
allocating in scan order will find a valid placement whenever one exists.
Per the NP-completeness result above, it provably cannot always do so: a
single-pass bitset/buddy tracker is a heuristic, exactly like Poletto's
own `SpillAtInterval` already is for the non-aliased case (it can spill a
value that a smarter, backtracking allocator wouldn't have needed to).
The difference introduced by aliasing is that no polynomial algorithm --
not this one, not Smith's, not any other -- can remove that heuristic
gap entirely.

## One confirmed parallel with what's already built

Not a new idea to adopt, just a point of interest matching a pattern seen
elsewhere in this project's literature comparisons (`JOIN`/union-find
independently matching Mössenböck's coalescing, `crossesCall` matching
Pereira's spare-register framing): the paper's "register exclusion"
technique (§4, "Representing register exclusions") -- track an
*excluded-register set* per candidate directly, rather than adding
exclusion nodes/edges to the interference graph to model e.g.
caller-saved-register unavailability across a call -- is the same shape
as this project's already-implemented `crossesCall` restriction in Step 2
(`docs/lvx/RegisterAllocation.md`, "Call clobbering"): restrict a
candidate's allocable set directly, don't model the restriction via
synthetic graph structure.

## Recommendation: revisit when `!lvx.pair`/`!lvx.quad` land

Not actionable now -- there is no multi-register candidate anywhere in
the dialect yet. When the SIMD phase starts (`RegFile`/`RegClass` read
from `lvx-refs` per `CLAUDE.md`, `!lvx.pair`/`!lvx.quad`
types, lane/blend/guard ops), the concrete next step is:

1. Confirm LVX's actual pair/quad alignment from the extracted
   `RegFile`/`RegClass` data (don't assume -- verify against
   `lvx-mds/lvx-refs/**` per `CLAUDE.md`'s ground-truth rule) matches the
   power-of-two/aligned shape assumed above.
2. If it does (expected, based on what's known today), skip the paper's
   own `squeeze`/class-tree machinery entirely and extend Step 2's
   free-register tracking to a bitset, checked/updated at aligned
   positions for pair/quad candidates -- no interference-graph
   construction needed, consistent with keeping the linear-scan shape
   Steps 1-3 already use.
3. If some future register class turns out *not* to be power-of-two/
   aligned (unlikely given what's known, but the i960 case is exactly the
   cautionary example), that's when the paper's own `squeeze`/class-tree
   apparatus becomes the right reference to implement for real, since the
   simpler bitset approach stops being exact in that case.
4. Accept, explicitly and in writing wherever this gets implemented, that
   the bitset/buddy tracker (or any polynomial alternative) is a
   heuristic that can fail to find a valid allocation some backtracking
   or ILP-based allocator would have found (Lee/Palsberg/Pereira 2007) --
   not a bug to chase, a property of the problem. Consistent with this
   project's existing posture (`docs/lvx/RegisterAllocation.md`'s Step 3
   hard-errors rather than attempting a cleverer spill search): treat an
   allocation failure on a pair/quad-heavy kernel as a signal to
   restructure the kernel or revisit the heuristic, not as a correctness
   bug in the allocator itself.
