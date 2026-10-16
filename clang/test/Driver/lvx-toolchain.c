// The lvx-mbr bare-metal cross: a GCC-installed toolchain whose runtime (crt0,
// newlib, libgloss, libgcc, the linker scripts) is what lvx-gcc installs and
// which clang reuses rather than shipping its own.
//
// Before LVXToolChain the triple fell through to Generic_ELF with no GCC
// installation found, which assembled and LINKED by invoking the host
// /usr/bin/gcc -- so a bare-metal link produced host objects, and every
// #include came from /usr/include (the first one failed on
// bits/libc-header-start.h, which no sysroot has).

// RUN: %clang -### --target=lvx-mbr -mcpu=lvx-1 \
// RUN:   --gcc-toolchain=%S/Inputs/lvx_mbr_tree -T link.ld %s 2>&1 \
// RUN: | FileCheck -check-prefix=LVX1 %s

// The assembler is external -- LVX has no MCCodeEmitter, so the back end emits
// text that lvx-mbr-as encodes -- and `as' defaults to lvx-1, so the core has
// to be stated to it as well as to the compiler. Getting this wrong is not a
// wrong encoding but a failed link: "architecture of input file is
// lvx:lvx-1:64, incompatible with lvx:lvx-2:64 output".
// LVX1: "-no-integrated-as"
// LVX1: "--march=lvx-1"

// The crt order is lvx-gcc's own, read off its -v output: crti, crtbegin, crt0
// going in, crtend and crtn coming out. crt0 after the other two is unusual and
// is what the installed runtime expects.
// LVX1: "{{.*}}lib/gcc/lvx-mbr/17.0.0/lvx-1{{/|\\\\}}crti.o"
// LVX1: "{{.*}}lib/gcc/lvx-mbr/17.0.0/lvx-1{{/|\\\\}}crtbegin.o"
// LVX1: "{{.*}}lvx-mbr/lib/lvx-1{{/|\\\\}}crt0.o"

// -lgcc on both sides of the group, as lvx-gcc emits it: libgcc needs libc for
// memcpy out of the vector helpers and libc needs libgcc for the division
// helpers, which the group alone does not close.
// LVX1: "-lgcc" "--start-group" "-lc" "-lgloss" "--end-group" "-lgcc"
// LVX1: "{{.*}}lvx-1{{/|\\\\}}crtend.o"
// LVX1: "{{.*}}lvx-1{{/|\\\\}}crtn.o"

// -mcpu picks the multilib, in both directories at once. lvx-gcc keys its
// multilibs on -march and clang spells the same choice -mcpu, so the selection
// is translated in findLVXMultilibs rather than taken from the GCC
// installation's own flag strings, which nothing this driver passes would match.
// RUN: %clang -### --target=lvx-mbr -mcpu=lvx-2 \
// RUN:   --gcc-toolchain=%S/Inputs/lvx_mbr_tree -T link.ld %s 2>&1 \
// RUN: | FileCheck -check-prefix=LVX2 %s
// LVX2: "--march=lvx-2"
// LVX2: "{{.*}}lib/gcc/lvx-mbr/17.0.0/lvx-2{{/|\\\\}}crti.o"
// LVX2: "{{.*}}lvx-mbr/lib/lvx-2{{/|\\\\}}crt0.o"

// With no -mcpu the default is lvx-1, which is lvx-gcc's default -march too.
// RUN: %clang -### --target=lvx-mbr \
// RUN:   --gcc-toolchain=%S/Inputs/lvx_mbr_tree -T link.ld %s 2>&1 \
// RUN: | FileCheck -check-prefix=DEFAULT %s
// DEFAULT: "--march=lvx-1"
// DEFAULT: "{{.*}}lvx-mbr/lib/lvx-1{{/|\\\\}}crt0.o"

// -march= is an ALIAS for -mcpu=, and has to be: lvx-gcc and lvx-mbr-as both
// spell the core -march, clang spells it -mcpu, and the two compilers are
// compared against each other on every benchmark. Until 2026-10-16 -march was
// claimed by nobody here, so it drew "argument unused during compilation" and
// the compile went to the DEFAULT core -- a warning for an option that changes
// which machine the output runs on, which lvx-perf's harness had to carry a
// comment and a workaround for. It must reach all three readers of the core:
// cc1's -target-cpu, the assembler's --march, and the multilib directories.
// RUN: %clang -### --target=lvx-mbr -march=lvx-2 \
// RUN:   --gcc-toolchain=%S/Inputs/lvx_mbr_tree -T link.ld %s 2>&1 \
// RUN: | FileCheck -check-prefix=MARCH %s
// MARCH-NOT: argument unused
// MARCH: "-target-cpu" "lvx-2"
// MARCH: "--march=lvx-2"
// MARCH: "{{.*}}lib/gcc/lvx-mbr/17.0.0/lvx-2{{/|\\\\}}crti.o"
// MARCH: "{{.*}}lvx-mbr/lib/lvx-2{{/|\\\\}}crt0.o"

// Both spellings together: the LAST one wins, as it would for two -mcpu.
// RUN: %clang -### --target=lvx-mbr -march=lvx-2 -mcpu=lvx-1 \
// RUN:   --gcc-toolchain=%S/Inputs/lvx_mbr_tree -c %s 2>&1 \
// RUN: | FileCheck -check-prefix=LASTWINS %s
// LASTWINS: "-target-cpu" "lvx-1"
// LASTWINS: "--march=lvx-1"

// The sysroot's headers, and NOT the host's: -nostdsysteminc is what keeps
// /usr/include out, and it is not a near-miss -- <stdio.h> there includes
// bits/libc-header-start.h, which the sysroot has no equivalent of.
// RUN: %clang -### --target=lvx-mbr -mcpu=lvx-1 \
// RUN:   --gcc-toolchain=%S/Inputs/lvx_mbr_tree -c %s 2>&1 \
// RUN: | FileCheck -check-prefix=INCLUDE %s
// INCLUDE: "-nostdsysteminc"
// (The path arrives unnormalised -- <install>/../../../../lvx-mbr/include --
// because computeSysRoot appends ".." rather than resolving, exactly as the
// other GCC-installed cross toolchains do.)
// INCLUDE: "-internal-isystem" "{{.*}}lvx-mbr{{/|\\\\}}include"

// -nostdlib drops the runtime but keeps the core selection, since the object
// still has to be encoded for the right one.
// RUN: %clang -### --target=lvx-mbr -mcpu=lvx-2 -nostdlib \
// RUN:   --gcc-toolchain=%S/Inputs/lvx_mbr_tree %s 2>&1 \
// RUN: | FileCheck -check-prefix=NOSTDLIB %s
// NOSTDLIB: "--march=lvx-2"
// NOSTDLIB-NOT: crt0.o
// NOSTDLIB-NOT: "-lgloss"

int main(void) { return 0; }
