---
name: symlink-vs-realfile-classify-before-deleting-fanout-dups
public: true
bundles: [authoring]
description: Use during a memory/skill/config dedup on a symlink-fanned tree (like claude-config, where install.sh symlinks universal cards into per-project dirs and ~/.claude) — before deleting any "duplicate", run a `test -L` classification loop so you delete only genuine real-file dups (often a sister session's copy) and KEEP the session's own install.sh fan-out symlinks. Guards against a near-miss deleting your own fan-out.
disable-model-invocation: true
scope: claude-config
---

# Classify Symlink vs Real File Before Deleting Fan-Out Duplicates

## Overview

In a symlink-fanned config tree, one logical file legitimately appears at many
paths. In `claude-config`, `scripts/install.sh` fans universal memory cards out
by **symlink** — one real file under `memory/_universal/`, symlinks into every
project's memory dir and into `~/.claude`. During a dedup sweep, those symlinks
look exactly like "duplicates" and a naive `find … -delete` or "remove the copy"
will destroy your own fan-out.

The rule: **never delete a path in a fan-out tree without classifying it first.**
A symlink pointing back at the canonical source is *intended fan-out* — keep it.
A **real file** with the same content as the canonical one is a genuine dup
(often a sister session's stray copy or a pre-symlink leftover) — that's what
you delete.

## When to Use

- Deduplicating memory cards / skills / any config across a tree that
  `install.sh` (or equivalent) symlink-fans-out.
- You've found N paths with the same name/content and are about to remove the
  "extras".
- Any symlink-fanned repo where one source is projected into many locations.

## The Classification Loop

Test each candidate path before touching it:

```bash
for p in <candidate-paths>; do
  if [ -L "$p" ]; then
    printf 'SYMLINK (keep — fan-out): %s -> %s\n' "$p" "$(readlink "$p")"
  else
    printf 'REAL FILE (candidate to delete): %s\n' "$p"
  fi
done
```

- **`-L` true → symlink → KEEP.** It's install.sh's fan-out. Confirm its
  `readlink` target is the canonical source; if so, deleting it just breaks the
  projection (and `install.sh` would recreate it anyway).
- **`-L` false → real file → delete candidate.** Only after confirming its
  content matches the canonical source (`diff <canonical> "$p"`), and that the
  canonical copy still exists.

## Do

- Classify with `test -L` first; delete only real-file dups whose canonical
  source survives.
- Verify the fan-out still resolves after the sweep — re-run `install.sh` (or
  its dry-run) so any legitimately-needed symlink is recreated.
- Treat a real-file dup you didn't create as possibly a sister session's WIP —
  check mtime and content before removing.

## Don't

- `find <tree> -name '<dup>' -delete` blind — it eats your own fan-out symlinks.
- Delete a symlink thinking it's a duplicate — it's the *point* of the tree.
- Delete a real-file dup without confirming the canonical source still exists —
  you could remove the last copy.

## Rerouting a card between scope tiers (the constructive counterpart)

Moving a card between `_universal/` ↔ project-memory (or project-A ↔ project-B) touches the
same fan-out mechanism, and it's deterministic-but-easy-to-drop-a-step. The invariants:

1. `git mv` the real file to the target scope.
2. **Update all three MEMORY.md indices the move touches** — source (remove), destination
   (add), and for a move to/from `_universal/` the universal index too.
3. **Run `bash scripts/install.sh`** to reseed symlinks. Moving *into* `_universal/` creates
   new fan-out symlinks in every project dir — they're tracked in git (mode 120000) and must
   be `git add`ed. Moving *out of* a project makes those source-project symlinks vanish;
   moving *into* a project materialises a real file. `git status` should show both kinds.
4. **Verify:** real file in the correct dir, expected symlinks present/absent, zero orphans
   (`find ~/.claude/projects/ -type l -xtype l`).

## Related

- `scripts/install.sh` — the fan-out mechanism this skill protects.
- dont touch sibling session unpushed commit — the sister-session hazard
  in the same shared-config regime.
