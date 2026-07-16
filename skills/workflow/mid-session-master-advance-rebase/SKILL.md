---
name: mid-session-master-advance-rebase
public: true
description: Use when `git diff origin/master..HEAD` (or main) shows files you never touched as DELETED/modified, yet `git status` is clean and `git log` shows only your commits — origin advanced past your fork point and the diff shows its new commits inverted. Fix with `git fetch && git rebase`.
---

# Mid-Session Master Advance Rebase

## Overview

When sister sessions are running in parallel and merging to the default branch, `origin/master` (or `origin/main`) advances without your worktree noticing. `git diff origin/master..HEAD` becomes misleading: it shows the **inverse** of any new upstream commits — a file added on master shows as DELETED in your diff; a line added shows as removed. Easy to mistake for cross-session contamination of your worktree.

## When to Use

- Pre-push verification: `git diff origin/master..HEAD` shows unfamiliar file changes
- `git status` says the working tree is clean
- `git log --oneline <fork-point>..HEAD` shows only your own commits
- You're in a worktree with one or more sister worktrees on other branches

## Diagnosis

```bash
git fetch origin
git log --oneline origin/master | head -3      # has master moved past your fork point?
git log --oneline <my-branch> | head -3        # what's your branch tip?
git merge-base HEAD origin/master              # is your fork point now behind origin?
```

If origin/master has commits beyond your fork point, that's the source of the "spurious diff" — it is upstream's new work shown inverted, not anything in your tree.

## Fix

```bash
git rebase origin/master
# rebases are usually clean for non-overlapping packages — re-run the test suite to verify
git diff origin/master..HEAD                   # now shows only your changes
```

## Why rebase rather than just push

Pushing as-is works (GitHub computes its own merge-base), but rebasing first:

- Makes the local `git diff origin/master..HEAD` honest, so pre-PR verification is meaningful
- Catches real conflicts EARLY instead of in the PR
- Keeps your branch linearisable for squash-merge

## Neighbouring hazards (dirty tree, not the clean-diff case)

This skill assumes a **clean** worktree where the confusion is only in the diff base. Two dirty-tree variants of "origin advanced" need different handling:

- **Untracked file blocks the ff-pull / rebase.** If `git fetch && git rebase` or `git pull --ff-only` aborts with *"untracked working tree files would be overwritten by merge"*, an untracked local copy — often a parallel lane's file or an Obsidian phantom — collides with a file the incoming history adds as tracked. Confirm content-equality (`git show origin/<branch>:<path>` + `git diff --no-index`), move the untracked copy to `/tmp`, re-pull, then discard the copy.
- **The user's checkout is many commits behind origin AND dirty.** Distinct from the agent's own clean worktree: never blow it away to "get latest". Snapshot everything (tracked + untracked) onto a `wip-backup-<date>` branch (`git switch -c wip-backup-<date> && git add -A && git commit` — skip `.claude/`), then `git branch -f <main> origin/<main>` + `git switch <main>` to surface the merged work losing nothing. Prove no loss by diffing `wip-backup-<date>` vs `origin/<main>` (the "lost edits" are usually just stale older copies) before declaring done; leave the backup branch in place as a safety net.

## Related

- [[parallel-worktree-tasks]] — the multi-worktree setup that makes this happen
- Distinct from a *dirty-tree* hazard — here the tree is clean and the confusion is purely in the diff base.
