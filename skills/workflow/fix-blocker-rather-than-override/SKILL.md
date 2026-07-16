---
name: fix-blocker-rather-than-override
public: true
description: Use when a pre-existing master CI gate is red and blocking your unrelated PR — decide between fix-the-blocker (compounds across all PRs) and admin-override (one-PR value + habit-debt)
---

# Fix the Blocker, Don't Override

## Overview
A red gate on master that's unrelated to your PR is still a real cost: every future PR pays the same gate-block tax until someone fixes it. Fixing the blocker compounds value across the whole queue. Admin-override extracts only your PR's worth of value and trains the team (or you) to bypass the signal.

## When to Use
- Your PR's CI shows a failing gate that's mechanically unrelated to your change
- Verifying the failure exists on master (not introduced by your PR) confirms it's pre-existing debt
- The blocker has no in-flight session already addressing it

## Decision rule
- **Fix the blocker first if**: root cause is tractable (~30–60min), you can diagnose from existing artifacts, the fix doesn't conflict with other in-flight work
- **Admin-override if**: the blocker is genuinely out-of-scope (different domain, large unknown), the user has explicitly authorised the chain, AND the override is logged in the close-out PR description

## Steps
1. Confirm the gate is failing on master itself (not just your PR) — `gh run list --branch master --workflow <name> --limit 3 --json conclusion,headSha`
2. Search the backlog for an existing tracking ticket — if absent, file one (the gate exposed real debt; don't lose the signal)
3. Recommend fixing the blocker; check parallel-session conflicts before starting
4. Land the blocker fix, rebase your original PR, merge cleanly via the normal flow
5. If you do admin-override instead, link the blocker ticket in the close-out PR description so future-you knows what you bypassed

## Red flag
"Just admin-merging this one — it's clearly unrelated." That's how admin-override becomes the default. The next time, someone else admin-merges and the gate stays red forever. Fix the root cause unless you can articulate why fixing is out-of-scope.
