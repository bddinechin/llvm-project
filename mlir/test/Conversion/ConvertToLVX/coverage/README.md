# The vector coverage suite

One function per **row** of `lvx-mlir/docs/VectorCoverage.md` §6: one MLIR op
on one lane shape, lowered through the whole back end so its cost is
*measured* rather than estimated. `docs/tools/vector-coverage.py` runs this
directory and regenerates that table; `lit` runs it as an ordinary
regression test, which is what keeps the table honest -- a row cannot change
class without a test changing with it.

## Two files per family

| File | Rows | What lit pins |
|---|---|---|
| `<family>.mlir` | the ones that lower | `FileCheck`, one `CHECK-LABEL` block per row: the instruction chosen |
| `<family>-gaps.mlir` | the ones that do not (class D) | `-verify-diagnostics`: each row's `expected-error`. When the ISA fills the gap, this test fails until the row moves to the other file |

Families follow the phases of `VectorCoverage.md` §4: `elementwise`, `mask`,
`movement`, `reduction`, `convert`, `memory`.

## The shape of a row

```mlir
// ROW: vector.interleave | f32x4
func.func @interleave_f32x4(%a: memref<8xf32>, %b: memref<8xf32>, %c: memref<8xf32>) {
  %i = arith.constant 0 : index
  %x = vector.load %a[%i] : memref<8xf32>, vector<4xf32>
  %y = vector.load %b[%i] : memref<8xf32>, vector<4xf32>
  // ROW-OP
  %z = vector.interleave %x, %y : vector<4xf32> -> vector<8xf32>
  vector.store %z, %c[%i] : memref<8xf32>, vector<8xf32>
  return
}
```

- `// ROW: <op> | <shape>` heads the chunk. `<shape>` is `<element><lanes>`,
  e.g. `f32x4` (a pair) or `f32x8` (a quad); for an op whose operands and
  result differ, the shape is the *operand's*.
- `// ROW-OP` marks the single op under test, on the line before it. Loads
  and stores around it are the harness: the row's cost is attributed by
  **source location** -- every `lvx` op the conversion creates carries the
  location of the op it came from -- so no baseline function is needed and
  the harness is free by construction.
- Chunks are separated by `// -----`. One op under test per chunk.

## What is measured

Per row, from `-convert-to-lvx` and then the back-end pipeline
(`-lvx-allocate-registers -lvx-scf-to-cf -lvx-schedule`), counting only the
ops whose location is the marked line:

| Metric | Meaning |
|---|---|
| `ops` | `lvx` ops created, `lvx.lane`/`lvx.concat` excluded -- they are register-naming pseudos and emit nothing |
| `syllables` | instructions actually issued: one per op, `parts` for a composite (`LVXComposites.inc`) |
| `bundles` | distinct `cycle` values among those ops, i.e. how many bundles the row needs of its own |

and the class follows: **A** one instruction, **B** one composite, **C** a
sequence, **D** the conversion failed (a gap), **F** free (pseudos only --
a lane view).
