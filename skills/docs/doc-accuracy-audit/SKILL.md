---
name: doc-accuracy-audit
public: true
disable-model-invocation: true
description: Use when asked to validate that a repo's READMEs and docs are accurate / up to date against the current code (not just diagrams — endpoints, ports, counts, env vars, commands, schemas, event contracts). Triggers on "validate the docs against the code", "make sure the docs are up to date", "audit the READMEs for accuracy", "are the docs still correct".
---

# Documentation Accuracy Audit

## Overview

Verify every factual claim in a repo's long-lived docs against the **current code**, fix the doc drift, and split out the code/config bugs the audit surfaces. Distinct from `readme-diagram-audit` (which only checks diagram coverage/convention) — this checks whether prose claims (endpoints, ports, service counts, env vars, commands, DB schema, event routing keys, file paths) still match reality.

Scope to **long-lived docs that are meant to track current state**. Explicitly EXCLUDE point-in-time records — `docs/archive/`, `docs/superpowers/specs|plans/`, changelogs, and any git worktree subdirectories (`*-<ticket>/`) — those are frozen by design; "correcting" them is wrong.

## Steps

### Step 1 — Pre-flight

- Confirm CWD and branch; `git fetch && git log HEAD..@{u} --oneline` — stop if origin is ahead (per cross-repo safety).
- Enumerate the in-scope doc set: root `README.md`, `CLAUDE.md`, `docs/**` (minus the excludes above), every `services/*/README.md`, `apps/*/README.md`, `packages/**/README.md`, `deploy/README.md`. Filter out nested worktree dirs and caches.
- Create a `KEY-n` branch before editing (tracked work).

### Step 2 — Fan out auditors by cluster

Dispatch parallel read-only/general-purpose subagents, one per doc cluster (keep clusters file-disjoint so they never collide). Typical clusters: (1) root README + CLAUDE.md + index; (2) service READMEs; (3) app + package READMEs; (4) architecture + diagrams; (5) operations + deploy; (6) ADRs + testing. Each agent **reports** structured findings — does NOT edit — with: `file:line`, the claim, what the code/config actually shows (cited), severity (HIGH/MEDIUM/LOW), and a concrete suggested fix. Tell each agent the exclude-list explicitly.

### Step 3 — Spot-check before acting

Subagent reviewers hallucinate. Before any edit, independently verify the most surprising / load-bearing findings (a `grep`/`ls`/file read each). Confirm the counts, the "this endpoint doesn't exist", and especially any claim that implies a **code bug** — those must be real before you file a ticket.

### Step 4 — Split findings into two categories

- **Category A — doc drift**: the doc is wrong, the code is right → fix the doc.
- **Category B — code/config bug**: the audit found the *code* (or a script/DDL/manifest) is wrong or self-inconsistent (e.g. an entity maps to a table the bootstrap SQL never creates; a bootstrap script waits on a renamed resource). These are NOT doc fixes — file a bug ticket each, with evidence, and keep the doc pass docs-only. Decide A-vs-B with the user if scope is ambiguous.

### Step 5 — Apply Category-A fixes (default HIGH+MEDIUM)

Read each file before editing; preserve the doc's existing voice and table formatting. Confirm the replacement text against the actual source (don't paste a subagent's suggestion blind). Skip LOW/cosmetic unless asked.

**Diagram-embedded values** (counts, ports shown in a Mermaid diagram that appears in multiple files via `<!-- DIAGRAM:BEGIN -->` markers): edit only the **canonical** `docs/diagrams/*.md`, never the embedded copies. Then propagate:

```bash
python3 scripts/embed_diagrams.py        # regenerate embeds
python3 scripts/embed_diagrams.py --check # must say "in sync"
```

⚠️ **Gotcha:** some embed scripts scan the whole tree and will rewrite embeds inside nested git worktrees (`*-<ticket>/`) using the *current* tree's canonical — polluting other branches' working state. After running it, `git -C <each-worktree> status`; if dirtied, the owning session must revert (don't force-discard another session's worktree without authorization). Consider adding a worktree/`archive` skip to the script.

### Step 6 — Verify

- `git diff` the full change set; sanity-read each hunk.
- `embed_diagrams.py --check` is clean.
- Optional: run the docs build/lint (`mkdocs build`) if present.
- Docs-only changes don't need the code-review gate, but say so explicitly.

### Step 7 — Land

Commit with explicit paths (NOT `git add -A` — nested worktree dirs show as untracked and must not be staged). Open the PR; comment the PR URL on any Category-B tickets that reference the docs. Report Category-A (fixed) and Category-B (ticketed) separately.

## Why this shape

Fan-out covers a large doc set in one pass; report-then-spot-check stops hallucinated "fixes"; the A/B split keeps the docs PR clean while real bugs get tracked instead of silently "fixed" in a doc edit.
