---
name: normalize-and-group-imported-agent-pack
public: true
bundles: [authoring]
description: Use when handed a batch of imported subagent .md files (e.g. agent-studio / B2B "agent packs") to integrate into this repo — strip studio/B2B frontmatter to clean name/description/model, decide merge-vs-keep-vs-drop against the existing roster, group keepers into an advisory-first domain "team" SKILL with model-tiering + adaptive selection + keyword hooks, then update the README catalogue and run install.sh. Distinct from skill-builder (builds one skill via interview) and library-audit (audits existing skills).
disable-model-invocation: true
scope: claude-config
---

# Normalize and Group an Imported Agent Pack

## What This Skill Does

Ingests a batch of externally-authored subagent `.md` files (typically
"agent-studio" / B2B packs handed over in groups of 8–12) and folds them into
this repo's `agents/` roster + `skills/<domain>/<domain>-team/` ecosystem.
This is **agent/team plumbing**, not skill authoring — use `skill-builder` to
write a single new skill from an interview, and `library-audit` to review skills
that already exist.

The pipeline recurred identically across multiple packs, so the operations are
codified here rather than re-derived each time.

## Context to read first

- `agents/` — the current roster you are merging against (canonical names + descriptions).
- An existing team SKILL as the structural template, e.g.
  `skills/api/api-team/SKILL.md` — copy its section shape exactly:
  Overview table → Adaptive agent selection → When to Use → Phases 1–5 →
  Model tiering → Integration (recon-swarm + keyword hook) → Related.
- `skills/README.md` — the catalogue you must update (source of truth for layout).
- `scripts/install.sh` — the deploy step run at the end.

## Steps

### 1. Normalize each incoming file
Strip studio/B2B framing down to a clean agent definition:
- Reduce frontmatter to `name`, `description`, `model` (drop everything else).
- Delete framing walls: legal disclaimers, "millions of users", "6-week sprint",
  marketing voice, literal `\n` escape garbage from bad exports.
- Rewrite `description` in house style — a disambiguating trigger sentence, not
  a generic blurb.

### 2. Decide merge-vs-keep-vs-drop per agent (against the roster)
For each normalized agent, compare to the existing `agents/` roster:
- **Merge** — an existing agent already covers it. Fold any unique capability
  text into the existing agent's definition, then **delete the imported file**.
- **Keep** — genuinely new capability. Place under `agents/` with the cleaned definition.
- **Drop** — redundant or out of scope. Delete, no roster change.

Bias toward merge/drop; a pack of 12 should not yield 12 new agents.

### 3. Group keepers into a domain team SKILL
Cluster related keepers into a `skills/<domain>/<domain>-team/SKILL.md` modelled
on the existing team skills. Each team SKILL is **advisory-first**:
analyse (read-only, parallel) → approval gate → implement → re-verify loop.
Required sections (mirror `api-team`):
- **Overview table** mapping each agent to its role in the team.
- **Adaptive agent selection** — deploy only the agents the task needs; scale to
  scope, not a reflex swarm (token discipline).
- **Phases 1–5** — Scope, Analyse, Approve, Implement, Verify-loop.
- **Model tiering** table — assign each agent its model + one-line why.
- **Singleton-fold rule:** a lone keeper that doesn't form a team does **not**
  get its own team skill — fold it into the nearest existing team (note the fold
  in that team's Overview/Adaptive section).

### 4. Wire integration hooks
In each new/edited team SKILL:
- Reference `[[recon-swarm]]` lenses that feed the team's Phase 1.
- Add a **keyword hook** line (e.g. "a repo can register `X → deploy x-team` in
  CLAUDE.md/memory").
- Cross-link `[[adversarial-verifier]]` for high-stakes Phase-5 verification and
  any stack-specific gotcha skills in **Related**.

### 5. Update catalogue + deploy
- Add the new/changed team skills and any new agents to `skills/README.md`.
- Run `scripts/install.sh` to fan out to `~/.claude/`.

## Notes
- The unit of value is the **team**, not the individual agent — always ask
  "do these keepers cluster into one advisory loop?" before creating files.
- Don't invent a new domain category if an existing team fits (singleton-fold).
- Deleting on merge/drop is part of the job — leaving the imported file behind is
  the most common defect.
- Side-effecting (writes agent files, edits README, runs install.sh), so this is
  explicit-invocation only (`disable-model-invocation: true`).
