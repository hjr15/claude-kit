---
name: multi-agent-branch-collision-recovery
public: true
description: Use when a commit landed on the wrong branch because a parallel agent shifted the active branch in a shared working directory. Recovers by cherry-picking onto the correct branch and resetting the wrong branch's ref without destructive force-push.
disable-model-invocation: true
---

# Multi-Agent Branch Collision Recovery

## Overview
A commit ends up on the wrong branch when:
1. You expect to be on branch A (created via `git checkout -b A`)
2. Another agent switches to branch B in the same working directory
3. You `git commit` — the commit lands on B, not A
4. `gh pr create` or `git push -u origin A` reveals the error

The recovery preserves both branches' intended state without force-pushing.

## When to Use
- `gh pr create` errors with "you must first push the current branch" but you thought you'd pushed
- The commit you expected on branch A shows up on branch B per `git log --oneline -3 B`
- Working in a shared checkout where multiple agents are active

## First: confirm the stray commit is yours
Before recovering anything, verify you authored the misplaced commit *this session*. If local `main`/`master` is ahead of `origin` by a commit you did **not** author (a sibling session just committed and hasn't pushed), this is not a recovery — it's a leave-alone:
- Diagnose: `git log --oneline origin/main..main`, `git reflog --date=iso | head`, `git log -1 --format='%an %ae %ci' main`. Fresh (minutes old) + not yours → a concurrent session owns it.
- Do **nothing destructive**: don't push it (publishes their in-flight work), don't `reset --hard` / `branch -f` / `rebase` / `commit --amend` it away, don't discard the working tree on its behalf. Just proceed on your own `KEY-n-slug` branch, never on the shared default. Report it to the user if you must surface it; the SessionStart unpushed-commit warning is not a to-do for you.

Only if the stray commit **is** yours, continue below.

## Steps
1. **Check actual state**: `git branch --show-current` and `git log --oneline -3 <expected-branch> <actual-branch>`
2. **Note the previous HEAD of the wrong branch** before your commit (visible in `git log` output above)
3. **Switch to the correct branch**: `git checkout <correct-branch>` — uncommitted working-tree changes follow you (these are the other agent's WIP; don't disturb them)
4. **Cherry-pick your commit**: `git cherry-pick <commit-sha>` — creates a fresh commit on the correct branch
5. **Reset the wrong branch's ref**: `git branch -f <wrong-branch> <previous-head-sha>` — removes your commit from that branch without touching the working tree
6. **Verify**: `git log --oneline -3` on both branches before pushing

## Don't
- Force-push to fix this (`git push --force-with-lease`) — destructive and unnecessary
- Reset the working tree (the other agent's uncommitted changes are theirs)
- Use `git reflog` to "recover" — the commit isn't lost, it's on the wrong branch
