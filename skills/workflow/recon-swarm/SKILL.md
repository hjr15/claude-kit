---
name: recon-swarm
public: true
bundles: [multi-agent]
description: Use before planning a non-trivial change to map the affected surfaces — dispatches read-only scout agents in parallel under chosen lenses and returns a synthesized recon brief. Triggers on "recon", "scout this", "map the surfaces before we plan".
disable-model-invocation: true
---
# /recon-swarm — Adaptive Read-Only Scout Swarm

## Overview
Reconnaissance before planning: fan out `Explore` agents across the codebase under independent lenses, then synthesize findings into a recon brief. The brief gives [[grill-brainstorm-build]] (and solve) something to interrogate against reality rather than assumptions.

This skill only reads. It produces no changes.

## When to Use
- Non-trivial work item or idea where affected surfaces are unclear
- Before invoking [[grill-brainstorm-build]] on anything that touches more than one file or system boundary
- Standalone "map X before we plan it" requests
- When you suspect a plan-from-memory risk (drift, hidden dependencies, unknown owners)

## Adaptive Lens Selection

Pick lenses for the job — more lenses for larger scope, fewer for narrow changes. The menu below is a starting set; ad-hoc lenses are allowed; **no upper limit**.

| Lens | What the scout maps |
|---|---|
| `runtime/ops` | How the component runs in production: startup, config, health, restarts, logs |
| `data-layer` | Schemas, migrations, persistence contracts, query patterns |
| `frontend/UI` | Components, routes, state, visual contracts affected by the change |
| `risk/security` | Auth boundaries, secret handling, injection surfaces, trust assumptions |
| `integration/contract` | API boundaries, event contracts, upstream/downstream dependencies |
| `prior-art` | Existing implementations, adjacent patterns, past decisions, test coverage |

`prior-art` runs on nearly everything. When in doubt, include it.

## Keyword-Gated Extensions

Project repos may register `keyword → scout brief` mappings in their own `CLAUDE.md` or memory files (e.g. `billing → scan Stripe webhooks and idempotency keys`). Recon-swarm reads those mappings and adds matching lenses automatically. It does not own or define them.

## Read-Only Contract

Scouts are dispatched as `Explore` agents. They **must not mutate the tree** — no edits, no writes, no shell side-effects. If a scout's output proposes a change, discard the proposal and capture it as an open question in the brief instead.

## Dispatch

Fan out in parallel — one `Explore` agent per selected lens — per dispatching parallel agents.

Each scout receives a scoped brief:

> "Map the **\<lens\>** aspect of **\<item\>**: what exists, where it lives, risks or surprises, and open questions. Read only."

Collect all results before synthesizing.

### Model tiering (token economy)

Recon is the widest fan-out in the lifecycle, so scout model choice dominates its cost. Dispatch `Explore` agents with an explicit `model`:

| Lens | Model | Why |
|---|---|---|
| `prior-art`, `runtime/ops`, `data-layer`, `frontend/UI` | **haiku** | Read-only mapping/extraction — locate code and summarise; cheap model is sufficient |
| `risk/security`, `integration/contract` | **sonnet** | Reasoning over trust boundaries / contract drift rewards a stronger model |

Synthesis of the brief happens in the conductor's own session (not a scout), so it inherits the session model — keep planning sessions on a strong model. Override a lens up a tier when the item is unusually subtle; never silently downshift `risk/security`.

## Output — Recon Brief

Return a structured brief with these sections:

- **Surfaces touched** — files, modules, services identified per lens
- **Risks and surprises** — anything unexpected or load-bearing that planners must account for
- **Prior art** — existing patterns, adjacent implementations, past decisions relevant to the item
- **Open questions** — unresolved ambiguities that the grill phase should probe

## Related

- [[grill-brainstorm-build]] — consumes the recon brief as grounding context
- solve — Stage 0 of the solve lifecycle invokes recon-swarm before planning
