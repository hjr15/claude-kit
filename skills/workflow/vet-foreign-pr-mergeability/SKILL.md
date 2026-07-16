---
name: vet-foreign-pr-mergeability
public: true
description: Use when asked to investigate whether an open PR you didn't author (often a sister session's) can be merged — runs a throwaway-worktree merge-test + build gate + parallel content-review + scope-confine check before giving a merge verdict, then tears the worktree down. Not for shipping your own PRs (use multi-pr-sweep) or explaining a red rollup (use pr-check-rollup-vs-required-gate).
disable-model-invocation: true
---

# Vet a Foreign PR's Mergeability

## Overview

A PR you didn't write needs a real merge-test, not just a green-checks glance. Test the merge in an isolated worktree, run the build gate on the result, review the diff's content, confirm it stays in its lane, then report — and re-verify live state first, because an "open" PR can already be merged by a concurrent session (reverify claimed state against live source).

## When to use

- "investigate this open PR — can it be merged?" / "is PR #N safe to merge?"
- merging a sister session's PR in a multi-lane repo
- any PR whose diff you haven't authored and must vouch for

Distinct from `multi-pr-sweep-pipeline` (ships YOUR N near-identical PRs) and pr check rollup vs required gate (explains red rollups).

## Steps

1. **Re-verify it's still open & not already in master:** GitHub MCP `pull_request_read` + `git merge-base --is-ancestor origin/<branch> origin/master`.
2. **Merge-test in a throwaway worktree:** `git worktree add /tmp/vet-<pr> origin/master`; in it `git merge --no-edit origin/<branch>` — note conflicts vs "Already up to date". For a read-only conflict preview with no worktree at all, `git merge-tree --write-tree --name-only origin/master origin/<branch>` enumerates the conflicting files without touching any tree; still use the full worktree when you also need to run the gate.
3. **Run the repo's gate** on the merge result (e.g. `mkdocs build --strict`, the test suite).
4. **Content-review in parallel:** dispatch a subagent on `git diff origin/master...origin/<branch>` while the gate runs.
5. **Scope-confine:** `git diff --name-only origin/master...origin/<branch> | grep -v <allowed-path>` should be empty — a foreign PR straying outside its lane is a red flag.
6. **Report the verdict** (clean-merge / gate-green / content nits / out-of-scope) and tear down: `git worktree remove /tmp/vet-<pr>`.

## Triaging several PRs at once

When handed N open PRs with "status + what to do", classify each before deep-vetting all of them: sort by `mergeable_state`, file-overlap conflict risk between the PRs, and data/branch staleness, then give a merge / merge / close verdict per PR. Deep-vet (the steps above) only the ones you'll actually merge; recommend closing stale or superseded ones outright.
