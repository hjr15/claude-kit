---
name: push-from-worktree-to-integrate-past-foreign-dirty-main
public: true
description: Use when you need to integrate your finished branch but the shared main/master checkout holds a live sister session's UNCOMMITTED work — push your worktree branch straight to origin/main (or merge the PR from the worktree) instead of checkout/merge in the shared tree, after asserting your HEAD is an ancestor of origin/main AND the incoming diff has zero path-overlap with the sibling's WIP.
disable-model-invocation: true
---

# Integrate From a Worktree, Past a Foreign-Dirty Shared main

## Overview

You're finished on your branch and want to land it, but the shared `main`
(or `master`) checkout has a **live sister session's uncommitted work** in its
working tree. The reflex — `git checkout main && git merge <branch>` in that
tree — is wrong: switching branches or merging there disturbs the sibling's
WIP, and a `git pull`/`reset` can clobber it outright.

The safe path is to integrate **without ever touching that tree**: push your
branch straight to `origin/main` (fast-forward), or merge the PR on the
remote from your worktree. The shared checkout is never entered; the sibling's
uncommitted work is never at risk.

This is the *positive integration* companion to the two "leave it alone" and
"recover it" skills:
- [[dont-touch-sibling-session-unpushed-commit]] — the sibling has an unpushed
  *commit*; you leave it. Here the sibling has uncommitted *WIP* and you need
  to land your own work around it.
- [[multi-agent-branch-collision-recovery]] — *your* commit landed on the wrong
  branch; you recover it.

## When to Use

- Your work lives on a branch (often in a `git worktree`) and is ready to land.
- The shared `main`/`master` checkout has uncommitted changes owned by a
  concurrent session (`git -C <shared-tree> status --short` is non-empty and
  they're not yours).
- Fast-forwarding `main` to your branch is possible (no divergent remote
  commits you'd need to merge in that tree).

## Two Preconditions — Assert Both Before Pushing

1. **Ancestor check** — your branch tip must fast-forward onto `origin/main`,
   i.e. `origin/main` is an ancestor of your HEAD:

   ```bash
   git fetch origin
   git merge-base --is-ancestor origin/main HEAD && echo "FF-safe" || echo "STOP: diverged, would need a merge"
   ```

   If it prints STOP, origin advanced — rebase your branch onto `origin/main`
   *in your own worktree* first (see [[mid-session-master-advance-rebase]]),
   never in the shared tree.

2. **Zero path-overlap** — the files you're changing must not intersect the
   sibling's dirty paths, so integrating can't step on their in-flight edits:

   ```bash
   comm -12 \
     <(git diff --name-only origin/main..HEAD | sort -u) \
     <(git -C <shared-tree> status --porcelain | awk '{print $2}' | sort -u)
   ```

   Empty output = no overlap = safe. Any shared path = STOP and ask the user /
   the sibling session; landing it could invalidate work they're mid-edit on.

## Do

- Push straight to the remote branch from your worktree:
  ```bash
  git push origin HEAD:main        # fast-forward main on origin
  ```
  or, if the work is a PR, merge it on the remote (`gh pr merge --admin`
  after CI green) — again, from your worktree, not the shared checkout.
- Keep every git/gh command prefixed with `cd <your-worktree-abs-path> &&` in
  a cross-repo / multi-session context (see [[git-command-cross-repo-safety]]).

## If it's a real (non-FF) merge — a throwaway worktree, never the shared tree

When precondition 1 prints STOP because you genuinely need a merge (not just a
rebase), and `main` is checked out **nowhere** (`git worktree list` confirms),
merge into it without disturbing the occupied sibling checkout:

1. **Read-only conflict pre-check first** — no mutation, no worktree:
   ```bash
   git merge-tree --write-tree <merge-base> <your-branch> \
     | grep -E 'CONFLICT|changed in both|^<<<<<<<' && echo "CONFLICTS" || echo "clean"
   ```
2. **Clean fast-forward** → push locally without any worktree:
   `git push . <your-branch>:main` (then `git push origin main`).
3. **Real (non-FF) merge** → do it in a scratch worktree, not the shared tree:
   ```bash
   git worktree add /tmp/mergetmp main
   git -C /tmp/mergetmp merge --no-ff <your-branch>
   git -C /tmp/mergetmp push origin main
   git worktree remove /tmp/mergetmp
   ```
4. **Verify the sibling checkout is untouched** — `git branch --show-current`
   and the untracked-file count in the shared tree are unchanged.

## Don't

- `git checkout main` / `git merge` / `git pull` / `git reset` **in the shared
  checkout** — any of these disturbs or clobbers the sibling's uncommitted WIP.
- Push when the ancestor check fails — you'd need a merge, which forces a tree.
- Push when path-overlap is non-empty — coordinate first.

## Related

- [[dont-touch-sibling-session-unpushed-commit]] — the "leave the foreign
  commit alone" sibling case.
- [[multi-agent-branch-collision-recovery]] — recover your own mis-branched commit.
- [[mid-session-master-advance-rebase]] — origin advanced; rebase your branch first.
- [[git-command-cross-repo-safety]] — CWD-prefix discipline across repos.
