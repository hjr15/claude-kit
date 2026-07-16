---
name: code-team
public: true
description: Deploy the code-quality agents (code-quality-reviewer, code-architect) alongside the /code-review skill to answer "is this code well-built?" — clean code, SOLID, structure, maintainability, refactoring. Advisory-first. Use standalone ("review this module's quality", "how should this be structured?", "is this refactor sound?") or as the quality lane inside a plan/body-of-work. Pairs with the testing-team for "is it proven correct?".
disable-model-invocation: true
---
# /code-team — "Is this code well-built?"

## Overview
The quality lane — distinct from, and run alongside, the testing lane:

| Tool | Answers |
|---|---|
| `/code-review` skill | **Correctness + reuse/simplification** on the *diff* (bugs, dead code, efficiency) — the existing, primary review entry point |
| `code-quality-reviewer` agent | **Clean code / maintainability** — readability, SOLID, code smells, complexity, DRY, with concrete refactoring guidance |
| `code-architect` agent | **Structure** — folder/module organisation, layering, boundaries (shared with `architect-team`) |

**Boundary:** `code-team` = *is it well-built and maintainable?* The **testing-team**
= *is it proven correct?* They run separately and compose; don't fold one into the
other (your call — sharper focus, lower per-task token cost).

## Adaptive agent selection (token discipline)
Deploy **only what the task needs**:
- *review a PR/diff* → start with the `/code-review` skill; add `code-quality-reviewer`
  when maintainability/refactoring (not just correctness) is the concern.
- *"how should this be organised?"* / new module layout → `code-architect`.
- *"is this code healthy?"* on existing code → `code-quality-reviewer`.
- *big refactor* → `code-architect` (structure) + `code-quality-reviewer` (smells),
  then testing-team to lock behaviour.

One tool is the norm. Don't run all three for a small change.

## When to Use
- Standalone: "review this module's quality", "is this refactor sound?", "where are
  the code smells?".
- As the **quality lane** inside execution: after a feature lands (or during a
  refactor), run the code lane and the testing lane in parallel before merge.
- Not for: correctness-only review of a small diff — just use `/code-review`.

## Phases
1. **Scope** — the code/diff/module and the goal: review / structure / refactor.
2. **Review (advisory)** — dispatch the selected tool(s); read-only. For a diff,
   `/code-review` first; layer `code-quality-reviewer` for maintainability depth.
3. **Approve** — present findings, ranked, separating must-fix from nice-to-have
   ([[feedback_prefer_simple_solutions]] — don't gold-plate). Structural decisions
   may be ADR-worthy ([[feedback_check_adr_before_architecture]]).
4. **Implement** — apply approved changes (the owning coder/team); process bar applies.
5. **Verify** — re-review the changed surface; **hand to the testing-team** to prove
   behaviour is preserved (refactors must stay green); [[adversarial-verifier]] for
   high-stakes refactors.

## Model tiering
Both agents on sonnet; the `/code-review` skill runs at its own configured effort.

## Integration
- Runs **in parallel with the testing-team** as the two quality lanes; the
  `engineering-team` deploys both when a task needs "well-built + proven correct".
- `code-architect` is shared with `architect-team` (design-time) — here it's used at
  review/refactor time.
- Keyword hook: a repo can register `code-quality → deploy code-team` in its
  `CLAUDE.md`/memory.

## Related
- `/code-review` skill — the primary diff review (correctness + simplification)
- `/simplify` skill — applies reuse/simplification cleanups
- `testing-team` — the paired "is it proven correct?" lane
- `architect-team` — design-time home of `code-architect`
