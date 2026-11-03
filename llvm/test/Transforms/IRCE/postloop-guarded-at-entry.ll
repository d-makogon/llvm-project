; RUN: opt -verify-loop-info -passes=irce -S < %s | FileCheck %s

; n - 1 <s len is known only from the check that guards the loop, and it is
; enough to prove that no post loop is needed.

define void @no_postloop_with_entry_guard(ptr %arr, ptr %a_len_ptr, i32 %n) {
; CHECK-LABEL: @no_postloop_with_entry_guard(
; CHECK:       loop:
; CHECK:         br i1 true, label %in.bounds, label %out.of.bounds
; CHECK-NOT:   postloop
entry:
  %len = load i32, ptr %a_len_ptr, !range !0
  %first.itr.check = icmp sgt i32 %n, 0
  br i1 %first.itr.check, label %check.len, label %exit

check.len:
  %n.minus.one = add nsw i32 %n, -1
  %n.le.len = icmp slt i32 %n.minus.one, %len
  br i1 %n.le.len, label %loop, label %exit

loop:
  %idx = phi i32 [ 0, %check.len ], [ %idx.next, %in.bounds ]
  %idx.next = add i32 %idx, 1
  %abc = icmp slt i32 %idx, %len
  br i1 %abc, label %in.bounds, label %out.of.bounds, !prof !1

in.bounds:
  %addr = getelementptr i32, ptr %arr, i32 %idx
  store i32 0, ptr %addr
  %next = icmp slt i32 %idx.next, %n
  br i1 %next, label %loop, label %exit

out.of.bounds:
  ret void

exit:
  ret void
}

!0 = !{i32 0, i32 2147483647}
!1 = !{!"branch_weights", i32 64, i32 4}
