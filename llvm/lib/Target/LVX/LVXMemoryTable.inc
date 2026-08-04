//===-- LVXMemoryTable.inc - -*- C++ -*- ===//
//
// Load and store instructions by access width.
//
// Generated from the LVX Machine Description System by MDS/BE/LLVM,
// for core lvx_v1.  DO NOT EDIT -- your changes will be overwritten by
// the next `make -C BE/LLVM install`.  Change lvx-mds/lvx-family's YAML
// description, or the generator in MDS/BE/LLVM/BIN, instead.
//
//===----------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Loads, by what a SelectionDAG load node knows about itself.
//
// LVX_LOAD(bits, extension, class, base+offset, +37-bit, +64-bit, indexed)
//
//   bits        how many bits of memory the access touches
//   extension   SEXT / ZEXT / NONE -- how it fills the rest of the register,
//               taken from the SX/ZX wrapping the Behavior's MEM_load
//   class       the register class the value lands in
//   the four addressing forms, narrowest displacement first
//
// The caller picks between the addressing forms; getFormForImmediate walks
// the same widening chain from a displacement.  The `variant` modifier is an
// operand of all four, not part of the opcode, so it is not a column here.
//===----------------------------------------------------------------------===//

#ifdef LVX_LOAD
LVX_LOAD(   8, SEXT, GPR   , LBS_LSBO    , LBS_LSBO_X    , LBS_LSBO_Y    , LBS_LSBI    )   // lbs
LVX_LOAD(   8, ZEXT, GPR   , LBZ_LSBO    , LBZ_LSBO_X    , LBZ_LSBO_Y    , LBZ_LSBI    )   // lbz
LVX_LOAD(  16, SEXT, GPR   , LHS_LSBO    , LHS_LSBO_X    , LHS_LSBO_Y    , LHS_LSBI    )   // lhs
LVX_LOAD(  16, ZEXT, GPR   , LHZ_LSBO    , LHZ_LSBO_X    , LHZ_LSBO_Y    , LHZ_LSBI    )   // lhz
LVX_LOAD(  32, SEXT, GPR   , LWS_LSBO    , LWS_LSBO_X    , LWS_LSBO_Y    , LWS_LSBI    )   // lws
LVX_LOAD(  32, ZEXT, GPR   , LWZ_LSBO    , LWZ_LSBO_X    , LWZ_LSBO_Y    , LWZ_LSBI    )   // lwz
LVX_LOAD(  64, NONE, GPR   , LD_LSBO     , LD_LSBO_X     , LD_LSBO_Y     , LD_LSBI     )   // ld
LVX_LOAD( 128, NONE, GPR128, LQ_LQBO     , LQ_LQBO_X     , LQ_LQBO_Y     , LQ_LQBI     )   // lq
LVX_LOAD( 256, NONE, GPR256, LO_LOBO     , LO_LOBO_X     , LO_LOBO_Y     , LO_LOBI     )   // lo
#undef LVX_LOAD
#endif

//===----------------------------------------------------------------------===//
// Stores, by how many bits of memory they write.
//
// LVX_STORE(bits, class, base+offset, +37-bit, +64-bit, indexed)
//
// There is no extension column: a store truncates its value to the width it
// writes, so unlike a load there is nothing to say about the bits above it.
// The width comes from the byte mask the Behavior hands MEM_store.
//
// Getting one of these wrong does not produce a wrong value, it produces a
// wrong-SIZED write -- SH where SW was meant leaves two bytes of whatever was
// there before, and SW where SH was meant destroys two bytes that belonged to
// something else.
//===----------------------------------------------------------------------===//

#ifdef LVX_STORE
LVX_STORE(   8, GPR   , SB_SSBO     , SB_SSBO_X     , SB_SSBO_Y     , SB_SSBI     )   // sb
LVX_STORE(  16, GPR   , SH_SSBO     , SH_SSBO_X     , SH_SSBO_Y     , SH_SSBI     )   // sh
LVX_STORE(  32, GPR   , SW_SSBO     , SW_SSBO_X     , SW_SSBO_Y     , SW_SSBI     )   // sw
LVX_STORE(  64, GPR   , SD_SSBO     , SD_SSBO_X     , SD_SSBO_Y     , SD_SSBI     )   // sd
LVX_STORE( 128, GPR128, SQ_SQBO     , SQ_SQBO_X     , SQ_SQBO_Y     , SQ_SQBI     )   // sq
#undef LVX_STORE
#endif

// NOT COVERED by the rows above:
//   writes a span whose width is not constant:
//     so

//===----------------------------------------------------------------------===//
// The `variant` modifier's values.
//
// LVX_LOAD_VARIANT(value, suffix, dismissible, memoryLevel)
//
//   dismissible   the load does not fault -- a speculative load
//   memoryLevel   2 bypasses the L1, 1 is an ordinary cached access
//
// Which of these a load gets is NOT a codegen choice: it is read off the
// pointer's address space, and the address-space numbering is ABI shared
// with lvx-gcc, so it cannot be derived here.  These rows exist so
// LVXAddressSpaces.h can be checked against the machine description instead
// of merely agreeing with it by hand.
//
// Description properties: %0.S: Dismissible, %0.U: MemoryLevel=2 %0.US: MemoryLevel=2;Dismissible
//===----------------------------------------------------------------------===//

#ifdef LVX_LOAD_VARIANT
LVX_LOAD_VARIANT(0, ""    , 0, 1)
LVX_LOAD_VARIANT(1, ".s"  , 1, 1)
LVX_LOAD_VARIANT(2, ".u"  , 0, 2)
LVX_LOAD_VARIANT(3, ".us" , 1, 2)
#undef LVX_LOAD_VARIANT
#endif
