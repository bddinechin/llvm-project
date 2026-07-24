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

## Source

> Michael D. Smith, Norman Ramsey, and Glenn Holloway, "A Generalized
> Algorithm for Graph-Coloring Register Allocation," PLDI 2004
> (`/home/guembu/Downloads/Smith_2004_PLDI.pdf`).

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
Nothing in LVX's register file (`lvx-target`'s eventual `RegFile`/`RegClass`
extraction, `PGR`/`QGR` per `CLAUDE.md`) suggests a non-power-of-two
grouping. So *if* the class tree described in this paper is built for
LVX's actual register classes, the colorability criterion it produces
would be provably as good as an ideal, brute-force one -- not just a
conservative approximation that might over-spill.

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
the dialect yet. When the SIMD phase starts (new `lvx-target`
`RegFile`/`RegClass` extraction per `CLAUDE.md`, `!lvx.pair`/`!lvx.quad`
types, lane/blend/guard ops), the concrete next step is:

1. Confirm LVX's actual pair/quad alignment from the extracted
   `RegFile`/`RegClass` data (don't assume -- verify against
   `lvx-mds/refs/**` per `CLAUDE.md`'s ground-truth rule) matches the
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
