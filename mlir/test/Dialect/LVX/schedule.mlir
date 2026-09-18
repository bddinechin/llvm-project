// RUN: mlir-opt %s --pass-pipeline='builtin.module(any(lvx-schedule))' | FileCheck %s
// RUN: mlir-opt %s --pass-pipeline='builtin.module(any(lvx-schedule),lvx-emit-asm)' -o /dev/null | FileCheck %s --check-prefix=ASM
// RUN: %if lvx-mbr-as %{ mlir-opt %s --pass-pipeline='builtin.module(any(lvx-schedule),lvx-emit-asm)' -o /dev/null 2>/dev/null | %lvx_mbr_as - -o %t.o %} %else %{ true %}

// The bundler (lvx-mlir/docs/Bundling.md): list scheduling over a block's
// dependence DAG, with latencies from the generated LVXLatency.inc and
// bundle legality from the generated reservations. The inputs are already
// allocated (the pass runs after -lvx-allocate-registers), so every value
// is a physical register and dependences are facts about units.

// Two independent adds share a bundle; the add that reads both results
// follows one bundle later (addd writes in cycle 2, reads in cycle 1: RAW
// latency 1), and the return, whose operand is the result register, one
// more.
// CHECK-LABEL: lvx_func.func @independent
// CHECK-NEXT: lvx.addd {{.*}} {cycle = 0 : i64}
// CHECK-NEXT: lvx.addd {{.*}} {cycle = 0 : i64}
// CHECK-NEXT: lvx.addd {{.*}} {cycle = 1 : i64}
// CHECK-NEXT: lvx_func.return {cycle = 2 : i64}
// ASM-LABEL: independent:
// ASM-NEXT: addd $r2 = $r0, $r1
// ASM-NEXT: addd $r3 = $r1, $r0
// ASM-NEXT: ;;
// ASM-NEXT: addd $r0 = $r2, $r3
// ASM-NEXT: ;;
// ASM-NEXT: ret
// ASM-NEXT: ;;
lvx_func.func @independent(%a: !lvx.reg<r0>, %b: !lvx.reg<r1>) -> !lvx.reg<r0> {
  %s = lvx.addd %a, %b : (!lvx.reg<r0>, !lvx.reg<r1>) -> !lvx.reg<r2>
  %t = lvx.addd %b, %a : (!lvx.reg<r1>, !lvx.reg<r0>) -> !lvx.reg<r3>
  %u = lvx.addd %s, %t : (!lvx.reg<r2>, !lvx.reg<r3>) -> !lvx.reg<r0>
  lvx_func.return %u : !lvx.reg<r0>
}

// A load writes in cycle 4 and an add reads in cycle 1: the add waits three
// bundles. Nothing else fills the gap, so bundles 1 and 2 are empty -- the
// indices jump, and the emitter prints no empty bundle (the hardware
// interlocks; the schedule is what the timing says, not padding).
// CHECK-LABEL: lvx_func.func @load_latency
// CHECK-NEXT: lvx.ld {{.*}} {cycle = 0 : i64}
// CHECK-NEXT: lvx.addd {{.*}} {cycle = 3 : i64}
// CHECK-NEXT: lvx_func.return {cycle = 4 : i64}
lvx_func.func @load_latency(%p: !lvx.reg<r0>) -> !lvx.reg<r0> {
  %v = lvx.ld %p, 0 : i64 : (!lvx.reg<r0>) -> !lvx.reg<r1>
  %w = lvx.addd %v, %v : (!lvx.reg<r1>, !lvx.reg<r1>) -> !lvx.reg<r0>
  lvx_func.return %w : !lvx.reg<r0>
}

// WAR is free: the add that overwrites r1 shares a bundle with the add that
// still reads the old r1 (reads precede writes in a bundle). WAW is not:
// the second writer of r2 is a bundle later. And a store reads its value a
// cycle late, so a writer of r1 does NOT share a bundle with a store of the
// old r1: the read in cycle 2 and the write in cycle 2 are a bundle apart.
// CHECK-LABEL: lvx_func.func @war_waw
// CHECK-NEXT: lvx.addd {{.*}} {cycle = 0 : i64} : {{.*}} -> !lvx.reg<r3>
// CHECK-NEXT: lvx.addd {{.*}} {cycle = 0 : i64} : {{.*}} -> !lvx.reg<r1>
// CHECK-NEXT: lvx.addd {{.*}} {cycle = 0 : i64} : {{.*}} -> !lvx.reg<r2>
// CHECK-NEXT: lvx.addd {{.*}} {cycle = 1 : i64} : {{.*}} -> !lvx.reg<r2>
// CHECK-NEXT: lvx.sd {{.*}} {cycle = 1 : i64}
lvx_func.func @war_waw(%p: !lvx.reg<r0>, %v: !lvx.reg<r1>) {
  %u = lvx.addd %v, %v : (!lvx.reg<r1>, !lvx.reg<r1>) -> !lvx.reg<r3>
  %a = lvx.addd %p, %p : (!lvx.reg<r0>, !lvx.reg<r0>) -> !lvx.reg<r1>
  %b = lvx.addd %p, %p : (!lvx.reg<r0>, !lvx.reg<r0>) -> !lvx.reg<r2>
  %c = lvx.addd %p, %p : (!lvx.reg<r0>, !lvx.reg<r0>) -> !lvx.reg<r2>
  lvx.sd %a, %p, 8 : i64 : (!lvx.reg<r1>, !lvx.reg<r0>)
  lvx.sd %c, %p, 16 : i64 : (!lvx.reg<r2>, !lvx.reg<r0>)
  lvx.sd %u, %p, 24 : i64 : (!lvx.reg<r3>, !lvx.reg<r0>)
  lvx_func.return
}

// CHECK-LABEL: lvx_func.func @store_war
// CHECK-NEXT: lvx.sd {{.*}} {cycle = 0 : i64}
// CHECK-NEXT: lvx.addd {{.*}} {cycle = 1 : i64} : {{.*}} -> !lvx.reg<r1>
lvx_func.func @store_war(%p: !lvx.reg<r0>, %v: !lvx.reg<r1>) {
  lvx.sd %v, %p, 0 : i64 : (!lvx.reg<r1>, !lvx.reg<r0>)
  %a = lvx.addd %p, %p : (!lvx.reg<r0>, !lvx.reg<r0>) -> !lvx.reg<r1>
  lvx.sd %a, %p, 8 : i64 : (!lvx.reg<r1>, !lvx.reg<r0>)
  lvx_func.return
}

// A store reads its value a cycle late (cycle 2): the store of a product
// (muld writes in cycle 3) is one bundle after it, not two -- GCC's
// "bypass", here just arithmetic.
// CHECK-LABEL: lvx_func.func @late_read
// CHECK-NEXT: lvx.muld {{.*}} {cycle = 0 : i64}
// CHECK-NEXT: lvx.sd {{.*}} {cycle = 1 : i64}
lvx_func.func @late_read(%p: !lvx.reg<r0>, %v: !lvx.reg<r1>) {
  %m = lvx.muld %v, %v : (!lvx.reg<r1>, !lvx.reg<r1>) -> !lvx.reg<r2>
  lvx.sd %m, %p, 0 : i64 : (!lvx.reg<r2>, !lvx.reg<r0>)
  lvx_func.return
}

// Resources: the bundle has one FULL unit and two LITE. Three fmuld (LITE)
// need two bundles; three LITE ops and a FULL op (divmodd) need two as
// well, the FULL taking a LITE and a TINY of its own. Memory: two stores
// to unknown addresses stay ordered (memw is one per bundle anyway).
// CHECK-LABEL: lvx_func.func @resources
// CHECK: lvx.fmuld {{.*}} {cycle = 0 : i64}
// CHECK-NEXT: lvx.fmuld {{.*}} {cycle = 0 : i64}
// CHECK-NEXT: lvx.fmuld {{.*}} {cycle = 1 : i64}
lvx_func.func @resources(%a: !lvx.reg<r0>, %b: !lvx.reg<r1>) {
  %x = lvx.fmuld %a, %b : (!lvx.reg<r0>, !lvx.reg<r1>) -> !lvx.reg<r2>
  %y = lvx.fmuld %a, %b : (!lvx.reg<r0>, !lvx.reg<r1>) -> !lvx.reg<r3>
  %z = lvx.fmuld %a, %b : (!lvx.reg<r0>, !lvx.reg<r1>) -> !lvx.reg<r4>
  lvx.sd %x, %a, 0 : i64 : (!lvx.reg<r2>, !lvx.reg<r0>)
  lvx.sd %y, %a, 8 : i64 : (!lvx.reg<r3>, !lvx.reg<r0>)
  lvx.sd %z, %a, 16 : i64 : (!lvx.reg<r4>, !lvx.reg<r0>)
  lvx_func.return
}

// The format is chosen from the immediate: an offset of 8 fits signed 10
// (bare, one syllable), 100000 needs the 37-bit `.x` form (two syllables),
// and the scheduler records the choice so the ISSUE count it reserved is
// what the assembler will encode.
// CHECK-LABEL: lvx_func.func @formats
// CHECK: lvx.ld %arg0, 100000 : i64 {cycle = 0 : i64, format = 4 : i64}
// CHECK: lvx.ld %arg0, 8 : i64 {cycle = 0 : i64}
lvx_func.func @formats(%p: !lvx.reg<r0>) {
  %x = lvx.ld %p, 100000 : i64 : (!lvx.reg<r0>) -> !lvx.reg<r1>
  %y = lvx.ld %p, 8 : i64 : (!lvx.reg<r0>) -> !lvx.reg<r2>
  lvx_func.return
}
