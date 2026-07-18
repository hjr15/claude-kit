---
name: stacked-pr-for-review-split
public: true
bundles: [git]
description: Use when a user asks to review changes that are already committed inside an open PR, and you cannot (or should not) force-push the PR's history. Produces a non-destructive stacked PR carrying only the diff the user wants to review.
disable-model-invocation: true
---

# Stacked PR for Review Split

## Overview

When corrections (or any subset of changes) live inside an already-pushed PR and the user wants them reviewable as their own PR, force-pushing rewrites history and breaks reviewer continuity. Use a `git revert` + cherry-pick pattern to split the diff non-destructively.

## When to Use

- User asks "create a new PR for me to review" but corrections are already in an open PR
- Safety guardrails block force-push to a branch with an active PR
- You want reviewers to see the corrections in isolation without losing the original PR's diff

## Steps

1. Identify the commit(s) you want to isolate (the "corrections SHA").
2. On the original PR branch, add a `git revert <corrections-SHA>` commit. Push (no force needed). The PR now contains the original work then the revert — net diff is the original state.
3. Create a new branch off the PR branch's current HEAD (which now has the revert).
4. `git cherry-pick <corrections-SHA>` onto the new branch. The cherry-pick applies cleanly because the working state matches what the original commit was based on.
5. Push the new branch and open a PR with `base=<original-PR-branch>` (stacked).
6. Reviewer flow: review the original PR first, then the corrections PR on top. End state after both merge is identical to merging the un-split original.

## Caveats

- PR #1 gets two "noise" commits (the revert and original corrections). Acceptable trade-off vs. force-push.
- If PR #1 merges first to default branch, GitHub typically auto-rebases PR #2's base. Verify.
- Do not use this pattern if the user has explicitly authorized force-push — `git push --force-with-lease` is simpler when allowed.
