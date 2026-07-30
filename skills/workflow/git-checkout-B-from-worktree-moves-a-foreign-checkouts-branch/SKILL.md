---
name: git-checkout-B-from-worktree-moves-a-foreign-checkouts-branch
public: true
bundles: [git]
description: Use before running `git checkout -B <branch>` / `git branch -f` / `git reset --hard <ref>` on a SHARED branch name from inside a git worktree — `-B` force-moves the branch ref even when another checkout is sitting on it, silently rebasing that checkout's HEAD under a sister session and making its whole tree look staged. Also covers restoring it with `reset --soft`.
disable-model-invocation: true
---

# `git checkout -B` From a Worktree Moves Another Checkout's Branch

## Overview

Worktrees share one ref store. `git checkout <branch>` refuses when another
worktree holds that branch — which is the guard everyone relies on. **`git
checkout -B <branch> <start>` does not stop there**: it force-updates the ref
first. The other checkout keeps its files and its index, but its HEAD silently
jumps to `<start>`, so every file that differs between the two commits appears
as a *staged modification* in a session that changed nothing.

The damage is presentational, not destructive — nothing on disk is lost — but it
is alarming, it buries the sibling's real WIP in hundreds of phantom entries,
and it is invisible in `git reflog` (which shows HEAD moves, not ref moves).

## When to Use

- About to run `git checkout -B`, `git branch -f`, or `git switch -C` from a
  worktree, on a branch name the main checkout might hold (`main`, `master`).
- Writing a defensive `git checkout X || git checkout -B X origin/X` fallback —
  **the fallback is the hazard**, and it fires exactly when the branch is taken.
- A checkout you never touched suddenly reports a huge staged diff, its worktree
  files are intact, and its `git reflog` shows nothing recent.

## Diagnosing it

`git reflog` is the wrong log — it records HEAD moves. Read the **branch ref's**
reflog, which names the operation and the date:

```bash
git reflog show master --date=short | head -3
# d764ef9 master@{2026-07-29}: branch: Reset to origin/master   <- the -B
# 918182c master@{2026-07-25}: pull --ff-only origin master
```

`branch: Reset to <ref>` is the signature of `checkout -B` / `switch -C`.

Confirm the index was left behind (this is what makes it recoverable):

```bash
git diff --cached <old-sha> --stat   # empty  → index still at the old tree
git diff --cached HEAD --stat        # large  → HEAD is what moved, not the files
```

## Restoring it

Because the index and working tree were untouched, `--soft` puts the ref back
and changes nothing else:

```bash
git -C <shared-checkout> reset --soft <old-sha>
```

Do **not** reach for `reset --hard` (destroys the sibling's uncommitted work) or
plain `reset` (rewrites the index they may have staged deliberately). Verify by
comparing `git status --porcelain | wc -l` against what it was before.

## Avoiding it

- Always branch from an explicit ref instead of switching:
  `git worktree add -b <new-branch> <path> origin/master` — never
  `checkout -B` an existing shared name.
- If you need the default branch's *content* in a worktree, check out a
  **detached** HEAD: `git checkout --detach origin/master`. It reads the same
  tree and touches no ref.
- Drop `|| git checkout -B ...` fallbacks entirely. Let the command fail loudly;
  a refusal is the guard doing its job.
- Before any ref-moving command in a repo with worktrees:
  `git worktree list` names who holds what.

## Red flags

- `git checkout -B main`, `git switch -C master`, or `git branch -f main` typed
  anywhere other than a repo you exclusively own.
- A `checkout || checkout -B` pair written for robustness.
- Treating "git refuses to check out a branch used by another worktree" as
  protection that applies to *all* branch commands. It applies to plain
  `checkout` only.
- Concluding a foreign checkout was "already dirty" because status is huge —
  compare the count to what you observed earlier before believing it.

> Promoted 2026-07-29 from a live session, where a
> `git checkout -q master || git checkout -q -B master origin/master` fallback
> in a worktree moved the shared `master` ref 24 commits forward under a sister
> session, turning its 16 real dirty files into 232 entries. Restored with
> `reset --soft`; nothing was lost.
