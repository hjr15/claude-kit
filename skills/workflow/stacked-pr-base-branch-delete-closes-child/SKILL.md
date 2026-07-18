---
name: stacked-pr-base-branch-delete-closes-child
public: true
bundles: [git]
description: Use before merging a base PR with `--delete-branch` when another (stacked) PR targets that base branch — deleting the base CLOSES the stacked child (GitHub won't retarget it to main) and it can't be reopened once the base is gone; retarget the child first, or open a fresh PR from the same head.
---

# Deleting a stacked PR's base branch closes the child

## Overview

When PR #B's base is the branch of PR #A (a stacked PR), merging #A with `--delete-branch` (or otherwise deleting #A's branch) makes GitHub **close** #B — it does *not* auto-retarget #B onto `main`/`master`. Worse, a closed PR whose base branch is gone **cannot be reopened** (the "Reopen" button errors). The work isn't lost (the head branch still exists), but the PR is dead and you must open a new one.

## When to use

Before `gh pr merge <A> --squash --delete-branch` (or merging via the UI with auto-delete) whenever any open PR uses #A's branch as its base.

## The rule

Pick one before deleting the base branch:

1. **Retarget the child first**, then merge+delete the base:
   ```bash
   gh pr edit <CHILD> --base main      # move the child onto main while its old base still exists
   gh pr merge <BASE> --squash --delete-branch
   ```
2. **Or** merge the base **without** `--delete-branch`, retarget the child, then delete the branch manually.

If you've already deleted the base and the child auto-closed: don't fight the closed PR — open a fresh one from the same head:
```bash
gh pr create --base main --head <child-branch> --title ... --body ...
```

## Symptoms

- A stacked PR shows **Closed** (not Merged) immediately after you merged + deleted its base branch.
- Clicking **Reopen** on it fails because the base branch no longer exists.

## Related

- epic pr bundling — bundling to avoid stacking in the first place when CI is slow.
- gh pr merge admin silent on success verify with pr view — verify PR state after merge ops.
