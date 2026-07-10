target datalayout = "e-m:e-p:64:64-i64:64-i128:128-n32:64-S128"

define i64 @identity_i64(i64 %a) {
  ret i64 %a
}

define i64 @return_second_i64(i64 %a, i64 %b) {
  ret i64 %b
}
