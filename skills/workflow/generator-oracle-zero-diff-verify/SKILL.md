---
name: generator-oracle-zero-diff-verify
public: true
description: Use when building a code-generator, sanitizer, or export pipeline whose output already exists as a hand-maintained artifact — make zero-git-diff against that existing artifact the acceptance test, instead of hand-deriving a per-file classification.
---

# Generator Oracle: Zero-Diff Verify

## Overview

When you build a generator/sanitizer/transform whose output **already exists as
a maintained artifact** (e.g. a public template repo's `main` branch generated
from a private source), use that artifact as the **oracle**: iterate the
manifest + transforms + overlay until `generate()` produces a **zero git-diff**
against it. One assertion subsumes the narrower grep/leak gate and proves both
completeness (nothing missing) and determinism in a single test.

## When to Use

- Building an export / template / codegen / sanitisation pipeline
- The target output already exists as a hand-maintained reference
- You're tempted to write a per-file "is this leaked?" classification by hand

## Steps

1. Identify that the target output already exists as a maintained artifact —
   that's the oracle.
2. Build the generator to a clean output directory.
3. `git diff --no-index <generated> <oracle>` — every residual diff line drives
   the next transform or overlay rule.
4. Loop until the diff is empty. An empty diff ⊇ any narrower content/leak gate,
   so you can drop the hand-maintained grep checklist.

**Determinism sub-check:** if you prove idempotence with "regenerate, then
`git diff <generated-file>`", the diff is **vacuous while the file is untracked** —
diffing an untracked path always shows clean, a false pass. `git add <file>` to
establish a baseline first, *then* regenerate and `git diff --stat` (staged vs
working). Distinguish genuinely-changed live values (today's reading) from
structural churn.

## Caveat

The oracle may embed downstream changes not present in the source (e.g. a later
dependency pin, a sibling repo's contract file). Those become **overlay files**
in the generator — the zero-diff requirement forces you to account for them
either way, which is the point.

## A green diff can still be a false success

Exit 0 is necessary, not sufficient. Interrogate *how* the green was reached:

- **Green by snapshotting the target.** The gate is satisfiable by vendoring a
  copy of the oracle and copying it back — converging by overlaying, not
  *deriving*. After the test goes green, inspect the **derive-count vs
  copy/overlay-count** composition against the ticket's intent; refuse to
  rubber-stamp a green achieved mostly by copying (e.g. 73 of 80 files overlaid).
- **Thin-derivation pivot.** If a "derive the public artifact from source"
  pipeline turns out to derive only a handful and must vendor the rest verbatim,
  stop and surface the honest derive-vs-vendor split via AskUserQuestion, and
  record the reduced value in the ADR Consequences rather than shipping it as if
  the spec's promise held.
- **Distrust a stale/multi-agent fixture.** When the oracle diff disagrees across
  agent runs (one says pass, another "pre-existing failure"), a prior agent
  likely left a dirty `/tmp/...-oracle` dir. Re-materialize the comparison fixture
  into a *fresh* dir (`git archive origin/main | tar -x`) before trusting any
  verdict — a persisted golden rots silently.

## Merge conflicts in the generated output

Never hand-merge a generated index/hub. If a sibling lane regenerated the same
generated file and you conflict, re-run the generator (it writes the union of both
inputs) and overwrite the conflict markers with its output.
