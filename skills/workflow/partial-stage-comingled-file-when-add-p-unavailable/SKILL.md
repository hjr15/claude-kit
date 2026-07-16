---
name: partial-stage-comingled-file-when-add-p-unavailable
public: true
description: Use when you must commit ONLY your hunk of a tracked file that also carries another session's uncommitted edits, and `git add -p` is blocked (non-interactive harness) — stage exact content via a constructed blob + `git update-index`, leaving the foreign working-tree edits untouched.
---

# Partial-stage a co-mingled file without `git add -p`

## When this fires
You edited a tracked file (often a `MEMORY.md`, changelog, or shared config) and want to commit **only your** hunk — but `git status` shows the same file also carries **another session's uncommitted edits** you must not sweep in. The usual tool, `git add -p`, is interactive and this harness blocks interactive git. `git add <file>` would stage everything, including the foreign edits.

This is the **single-file** case of [[feedback_git_commit_no_pathspec_sweeps_staged_index]] (which covers the easier whole-file / explicit-pathspec case).

## The mechanic
Construct the exact content you want committed, hash it into a blob, and point the index at that blob — the working tree (with the foreign edits) is never touched:

```bash
# Build the desired committed content FROM the committed base, applying only your change.
# Example: your change is deleting one line; foreign edits are additions elsewhere.
git show HEAD:path/to/file | grep -v 'my-unique-deletion-token' > /tmp/desired

SHA=$(git hash-object -w /tmp/desired)                    # write it as a git blob
git update-index --cacheinfo 100644,$SHA,path/to/file     # stage THAT blob only
```

Derive `desired` from `HEAD:` (the clean committed base) + your change — **not** from the working-tree file, which already contains the foreign edits. For an addition, append/insert into the `HEAD:` content instead of `grep -v`.

## Verify before committing (mandatory)
```bash
git diff --cached -- path/to/file     # MUST show only your change, no foreign edits
git diff -- path/to/file              # foreign edits MUST still be present (unstaged) on disk
```
Only your hunk staged, foreign edits still dirty on disk → safe to `git commit` (index is clean of foreign work). After commit, the file re-shows as modified with just the foreign edits — correct; leave them for their owner.

## Guards
- **Never `git add <file>` / `git add -A` here** — that's the exact sweep you're avoiding.
- **Keep every foreign card/file/pointer in the working tree.** You are isolating YOUR change, not resolving theirs.
- If a live session is *actively writing* the file (recent mtimes), prefer to wait or leave it — this mechanic is for stale/co-resident edits, not a race against a live writer.
- Confirm no active concurrent writer first (mtimes idle, no live worktree) per [[feedback_preexisting_lane_worktree_means_occupied]].

## Related: a hook restages a file you didn't intend to commit

A different mechanism produces the same "unwanted file in my commit" outcome: a
pre-commit or PreToolUse hook (embed/codegen, settings-sync, capture-plugins)
auto-edits + `git add`s a file — e.g. reordering `global/settings.json` or
injecting a diagram into a template — folding it into your commit even though you
only staged your own files. The robust remedy is **commit by explicit pathspec**:
`git commit <your-paths> -F -` includes only the named files regardless of what
the hook stages, no `--no-verify` needed (other hooks keep running). If the hook
already produced a commit, `git reset --soft HEAD~1 && git restore --staged
<unwanted-file>`, then recommit by pathspec — and if the swept file is a legitimate
change of yours (e.g. settings.json), split it into its own honest commit rather
than burying it. Prefer pathspec over `--no-verify`; reach for `--no-verify` only
when you must skip the hook's *mutation* while still running its *verification*
half manually (see [[commit-no-verify-when-hook-mutates-unwanted-file]]).
