; Input for address-space-variant.ll's UNSUPPORTED check: a load in the
; __convert address space (4), which has no load encoding and must be
; diagnosed rather than silently compiled as a cached load.
define i64 @convert_load(ptr addrspace(4) %p) {
  %v = load i64, ptr addrspace(4) %p
  ret i64 %v
}
