---
name: backport-review-fix-into-plan-of-record
public: true
description: Use when a per-task review during subagent-driven development catches and fixes a real bug in code that a plan-of-record authored — edit the plan itself to carry the fix, so a future plan re-run doesn't reinstate the same bug on top of the corrected tree.
---

# Backport a Review Fix into the Plan-of-Record

## Overview

In subagent-driven development the plan-of-record is executable: a task's implementer prompt reproduces the authored code verbatim. When a per-task review then catches a real bug and you fix it in the working tree, the *plan* still contains the buggy version. Any later re-run of that task — a resumed session, a re-dispatch after a limit reset, a second pass over the same plan — will faithfully re-author the original bug over your corrected tree. The fix is only durable once it lives in the plan, not just in the commit.

## When to Use

- A per-task review (or `verify-subagent-completion`) catches and you fix a genuine bug in code an execution plan authored.
- The plan-of-record still holds executable code / verbatim snippets the implementer replays.
- The plan or its remaining tasks may be re-run, resumed, or handed to another session.

## When NOT to Use

- The plan is purely narrative ("implement auth middleware") with no reproducible code snippet — there's nothing to reinstate.
- One-shot work with no possibility of a re-run of that task.

## Steps

1. **Fix the bug in the working tree first** and confirm it (test passes, behaviour correct) per normal review flow.
2. **Locate the same code in the plan-of-record** — the task step whose implementer prompt authored the buggy line.
3. **Backport the exact fix into the plan** so the plan's snippet now matches the corrected tree. Fix it where the defect was authored, not in a trailing "note" the implementer might ignore.
4. **Re-read both** — confirm the plan snippet and the corrected file agree line-for-line, so a re-run reproduces the fix rather than the bug.
5. **If the fix crosses tasks** (a shared type, a helper signature), update every downstream task in the plan that references it, so cross-task consistency survives a re-run.

## Common Mistakes

| Mistake | Why it burns you |
|---|---|
| Fixing only the working tree | A plan re-run re-authors the original bug on top of your fix |
| Leaving the fix as a prose "note" beside the buggy snippet | The implementer replays the code snippet, not the marginalia |
| Backporting the fix but not its downstream uses | Cross-task drift — the corrected type mismatches later tasks that still reference the old shape |

## Related

- verify subagent completion — the review gate that surfaces the bug to backport.
- adversarial plan review before execution — catch execution-readiness defects in the plan *before* the first run; this skill closes the loop *after* a run.
- `superpowers:subagent-driven-development` — the outer loop whose plan-of-record this keeps authoritative.
- reverify claimed state against live source — re-check the live tree rather than trusting a prior claim after a re-run.
