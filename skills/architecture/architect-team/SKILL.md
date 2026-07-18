---
name: architect-team
public: true
bundles: [architecture]
description: Deploy the architecture agents (architect, code-architect, backend-architect) as a coordinated design council to design or review a feature/system before it's built. Advisory-first — independent design perspectives → synthesis → ADR capture → implement. Use standalone ("how should I structure X?", "review this design") or as the design stage inside a plan/body-of-work.
disable-model-invocation: true
---
# /architect-team — Coordinated Design Council

## Overview
Three perspectives on a design instead of one, deployed as a unit:

| Agent | Perspective | Model |
|---|---|---|
| `architect` | Independent judgement — boundaries, coupling, the simpler alternative, what's ADR-worthy. **Advise-only.** | opus |
| `code-architect` | Structure — folder/module organisation, layering, naming conventions | sonnet |
| `backend-architect` | Server side — API/system design, auth, performance, deployability | sonnet |
| `database-architect` | Data layer — schema/indexing/query-optimisation/migrations/integrity (composable; pulled when the data model is non-trivial) | sonnet |

**Advisory-first contract:** this council *designs and critiques*; it doesn't ship
code. `architect` never implements. The output is an agreed design + the ADRs it
warrants. Implementation is a separate, approved step.

This is the council to deploy **whenever anything architecture-related is being
reviewed, worked on, or analysed** — a new feature/module, a refactor of code
organisation, a service boundary, or "what's the right shape for X?".

## When to Use
- **Standalone:** "how should I structure the X feature?", "review this design
  before I build it", "is this the right service boundary?".
- **As the design stage inside execution:** before writing plans
  turns a spec into tasks, or mid-flight when an approach needs a sanity check.
  Feeds the agreed design into the plan.
- Whenever a change is hard-to-reverse or sets a lasting convention — the council
  surfaces the ADR before code locks it in.

Not for: a one-file change with an obvious shape (just do it — don't convene a
council for a function rename).

## Phase 1 — Scope
- The feature/system/change under design, its goal/ticket, and the surfaces it
  touches (feed in a [[recon-swarm]] brief if the surfaces are unclear).
- The existing patterns to respect — map current structure first; don't invent
  new conventions where the repo already has one.

## Phase 2 — Perspectives (parallel, advisory)
Dispatch the relevant agents **in parallel** per
dispatching parallel agents against the same scoped design:
- `architect` always (the independent judgement + ADR radar).
- `code-architect` when structure/organisation is in question.
- `backend-architect` when server/system design is in question.
- `database-architect` when the data model is non-trivial (new schema, indexing,
  migration, or a query-performance problem) — composes with `backend-architect`.
- Scale down for narrow changes — `architect` alone is often enough. Token
  discipline: deploy only the perspectives the design actually needs.

All are read-only/advisory. Discard any code they sketch; keep it as a proposal.

## Phase 3 — Synthesize & Approve (the gate)
In your own session: reconcile the perspectives (they will sometimes disagree —
that's the point), pick the design, and bias to the **simpler alternative** per
prefer simple solutions. Present it to the user with the trade-offs.

**Capture ADRs here.** Anything that clears all three bars — hard to reverse,
surprising without context, a real trade-off — becomes an ADR per
check adr before architecture and app design decision needs adr.
Don't manufacture an ADR for routine choices; instance config is not an ADR
(adr framework not instance). Durable decisions also belong in
long-lived docs (promote decisions to longlived docs).

## Phase 4 — Implement (separate, approved step)
Hand the agreed design to the right executor — `backend-architect` for server
work, frontend team for UI, api team for API surfaces, or
subagent driven development for general tasks. Follow the repo's
process bar (branch + per-commit Jira key, `code-review`, `context7`).

## Phase 5 — Verify
After implementation, optionally re-run `architect` on the result to confirm the
built shape matches the agreed design (drift between design and build is common).
[[adversarial-verifier]] for high-stakes structural claims.

## Integration — deploying the council inside a body of work
- This is the **design stage** that precedes planning/execution. In the `/solve`
  lifecycle it sits between recon and plan: recon maps surfaces → council agrees
  the shape → plan turns it into tasks.
- Keyword hook: a repo can register `architecture → deploy architect-team` (or
  `design → ...`) in its `CLAUDE.md`/memory.
- Note the existing single-agent `architect` is the lightweight path — convene the
  full council only when structure *and* server design are both in play.

## Related
- [[recon-swarm]] — maps the surfaces the council designs against
- frontend team / api team — the execution units the agreed design hands to
- [[adversarial-verifier]] — verify high-stakes structural claims
