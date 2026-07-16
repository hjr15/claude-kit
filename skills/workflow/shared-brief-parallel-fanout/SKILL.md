---
name: shared-brief-parallel-fanout
public: true
description: Use when a task splits into N same-shaped units (audit a corpus by cluster, author N notebooks, tag N subjects, scan N transcripts) and you fan out parallel agents from ONE shared brief — the brief artifact, uniform output contract, agent-vs-script split, and central integration.
---

# Shared-Brief Parallel Fanout

## Overview

dispatching parallel agents (superpowers) gives the generic rule: one agent per independent domain, dispatch concurrently, integrate. This skill is the recipe for the *homogeneous* variant — N units of the **same shape** (one per cluster / notebook / subject / transcript) — where the leverage comes from a **single shared brief** plus a **uniform output contract** so the parent can mechanically integrate.

**Core principle:** write the brief once, make every agent read it in full, make every agent emit the same structure, then integrate centrally. Agents do prose judgment; scripts do mechanical or fragile-format edits.

## When to Use

- A task partitions into N comparable units that don't share files (corpus clusters, per-subject pages, per-strand notebooks, per-session transcripts).
- Each unit is a bounded "read the brief → do the work → report in the agreed shape" task.
- You want consistency across the N outputs (same columns, same template, same dedup baseline).

Not this skill: heterogeneous independent failures (use dispatching parallel agents directly); N tasks that each need their own isolated git branch (use parallel worktree tasks); kicking off N *sister sessions* via handoff briefs (use parallel handoff brief fanout).

## The recipe

### 0. Preflight before fanning out

For content-authoring fanouts, don't dispatch N agents against an unproven
template. First author the hub + **one** fully-finished sample unit yourself,
build + browser-verify it, and get a user spot-check (AskUserQuestion: "right
depth/style to replicate?"). Only then fan out from the confirmed exemplar — the
shared brief points at it as the gold standard. Skip this and N agents faithfully
reproduce the wrong shape.

For a review/audit fanout over a repo checkout, confirm the checkout is on the
intended branch and not stale relative to `origin/main` (`git fetch && git log
HEAD..origin/main --oneline`) *before* dispatching, not after. Real cost of
skipping this: a 12-agent board review ran against a branch that predated a
pivot already merged on `origin/main`, and ~55% of the findings came back moot.

### 1. Write the shared brief once

One artifact (`AUTHOR_GUIDE.md`, an auditor brief, a scanner brief) holding everything common: the standard, the house conventions, the output contract, the constraints. Each agent is told to **read it in full** before starting. The brief is the single source of truth — never paraphrase per-agent.

### 2. Decide agent vs. script per sub-task

| Sub-task character | Do it with |
|---|---|
| Prose judgment, content authoring, classification needing reading | a parallel **agent** |
| Mechanical, deterministic, or fragile-format edit (e.g. JSON `.ipynb` cells, bulk find-replace) | a **script run by the parent**, not an agent |

Keep agents off fragile formats. If 21 units are a deterministic transform and 9 need judgment, script the 21 and dispatch 9 agents — don't dispatch 30.

### 3. Pass a dedup / no-overlap baseline into each agent

Each agent gets the slice it owns **plus** what NOT to re-do — the existing slug list, the already-served items, the sibling lanes' scope. This is what stops N agents producing overlapping or duplicate output.

### 4. Fix a uniform output contract

Every agent returns the **same structure** (same table columns, same template, same report fields, no file writes unless the brief says so). Uniformity is what makes step 5 mechanical instead of a per-agent reconciliation.

### 5. Integrate centrally + editorial cut

Parent collects all N outputs, then:
- runs the combined check (e.g. `--check`, full test suite) once,
- applies an **editorial triage** — cut candidates already served elsewhere (a table, a notebook, a flat list), expect to drop a meaningful fraction,
- verifies for real (browser / render / spot-check) before shipping,
- ships in one consolidated PR after the user reviews.

## Anti-patterns

- Re-deriving the brief per agent instead of one shared artifact every agent reads in full.
- Dispatching an agent for a deterministic or fragile-format edit a script should own.
- Free-form agent outputs that force per-agent reconciliation instead of a uniform contract.
- Skipping the dedup baseline → overlapping/duplicate work across lanes.
- Accepting all N outputs without the central editorial cut and real verification.

## Domain instances (already folded into their skills)

This skill is the spine; the domain specifics live where the work happens:
- Diagram-necessity audit of a prose corpus → [[readme-diagram-audit]].
- N parallel notebook authors from a shared AUTHOR_GUIDE → notes migration (and the notebook build flow).
- Per-subject tagging with a script fallback for fragile JSON → notes migration.
- N parallel session-transcript scanners pre-deduped against the slug list → session harvest.
