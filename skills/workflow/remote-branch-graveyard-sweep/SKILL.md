---
name: remote-branch-graveyard-sweep
public: true
description: Use to bulk-clean stale remote branches ("clean up the branches" / "make sure the repo is clean") — classify each with git cherry (all-minus = merged), and for any branch with unmerged commits, verify its unique artifact already exists on main BEFORE deleting, since work is often superseded (reimplemented under new SHAs) rather than literally merged.
disable-model-invocation: true
---

# Remote Branch Graveyard Sweep

## Overview

A branch with unmerged commits is **not** automatically dead — its work may have been superseded on `main` via different SHAs (squash-merge, reimplementation). Verify the unique artifact landed before deleting, or you risk both losing real work and leaving a stale graveyard. Codifies superseded not merged verify artifact.

## When to use

- "clean up the branches" / "make sure the repo is clean"
- a remote with many stale feature/worktree branches

## Steps

0. **Prune stale worktree registrations first.** A worktree registered from *another* repo can pollute `git worktree list` and make a branch-iterating loop exit-128 mid-sweep. Run `git worktree prune` before iterating.
1. **Classify** every remote branch:
   ```bash
   for b in $(git branch -r | grep -vE 'origin/(main|HEAD)$'); do
     n=$(git cherry origin/main "$b" | grep -c '^+')
     [ "$n" -eq 0 ] && echo "$b MERGED" || echo "$b $n-unmerged"
   done
   ```
2. **MERGED branches** (every commit prefixed `-`) → safe to delete.
3. **For each `N-unmerged` branch**, before treating the count as real, run two cheap cross-checks — `git cherry` / ancestry gives a false "unmerged" for squash-merged and reimplemented work:
   - **PR history:** `gh pr list --state merged --json headRefName,number` — a merged PR whose `headRefName` matches the branch means the work landed (squashed).
   - **Content diff:** `git diff origin/main <branch> --stat` — **empty output = content is already on main** even though `git cherry` reported unmerged commits.
   - If both are inconclusive, find the branch's unique artifact and confirm it on main: `git ls-tree -r --name-only main | grep <file>` or `git show main:<path> | grep <feature>`.
4. **Delete only** branches whose unique work is confirmed on main (`git push origin --delete <b>`). **Report anything genuinely unmerged for a human decision** — never delete on the `git cherry` count alone.
