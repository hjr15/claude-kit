---
name: readme-diagram-audit
public: true
description: Use when auditing a repo for diagram coverage and convention compliance — scans docs/diagrams/ for completeness, validates frontmatter against the taxonomy, and flags missing diagrams the repo would benefit from. Triggers on "audit diagrams", "check diagram coverage", "visual documentation audit".
disable-model-invocation: true
---

# README Diagram Audit

## Overview

Audit a repo's `docs/diagrams/` folder for convention compliance and coverage. For each file: validate frontmatter; check the taxonomy value is recognised; ensure exactly one code block exists. Flag missing diagrams the repo would benefit from (architecture, deployment, etc.) based on repo content.

## Steps

### Step 1 — Confirm the folder exists

```bash
ls <repo>/docs/diagrams/
```

If missing: offer to create it via the `docs-scaffold` skill in audit mode.

### Step 2 — Validate every diagram file

For each `<repo>/docs/diagrams/*.md` not prefixed with `_`:

| Check | Pass if |
|---|---|
| Has YAML frontmatter | First non-blank line is `---` |
| `title` field present | Non-empty string |
| `type` field present | In the recognised taxonomy, or accepted as an extension (warn but pass) |
| `format` field present | One of `mermaid`, `png`, `svg`, `excalidraw` |
| Exactly one code block | `grep -c '^```' file` returns exactly 2 |

The fastest way to run this: `python <repo>/scripts/embed_diagrams.py --check` covers most of it and additionally verifies all embedded copies are in sync.

### Step 3 — Assess coverage

Based on repo content, flag missing diagram types:

| Repo signal | Suggested diagram type |
|---|---|
| Has a CI/CD workflow or deploy pipeline | `deployment` |
| Has a cluster / multi-host topology | `infra-topology` |
| Has a request lifecycle, auth handshake, or hook flow | `sequence` |
| Has a domain entity with status transitions | `state-machine` |
| Has a relational DB schema | `data-model` (consider hi/lo split: `data-model-overview.md` + `data-model-schema.md`) |
| Has a multi-page user flow | `user-flow` |

Don't auto-create missing diagrams — report the gap and suggest creating them next session.

### Step 4 — Check the embed sync

```bash
cd <repo>
python scripts/embed_diagrams.py --check
```

If exit code 1 (stale), recommend running without `--check` and committing.

If exit code 2 (rogue mermaid), surface the file/line and suggest moving the diagram into `docs/diagrams/` and wrapping the README occurrence in markers.

### Step 5 — Report

Output as a table with columns: Check / Status / Action. Group by Pass / Warn / Fail.

## Variant — diagram-necessity audit of a prose corpus

The steps above target a code repo's `docs/diagrams/`. To audit a *large prose corpus* (e.g. `personal/notes/`) for which pages would *benefit from* a diagram, fan out per [[shared-brief-parallel-fanout]]:

1. Partition the corpus into thematic clusters; dispatch one `Explore` agent per cluster, all reading the same auditor brief.
2. Each agent returns the **same table**: `File | Concept | Diagram type | Why-it-helps | Priority`.
3. Parent editorial triage **cuts** any row already served by a table, notebook, plotted curve, flat list, or existing image — expect to drop ~40%.
4. Emit one consolidated audit; ship per-cluster after the user reviews the rendered visuals.

Humanities/opinion-heavy clusters are usually near-empty here — don't manufacture diagrams to fill the table.
