---
name: grill-brainstorm-build
public: true
description: Use when the user wants to go from a rough idea to implementation, running through interrogation, options exploration, and build in one flow. Triggers on "grill me then build", "design-to-build", or "think it through then implement".
disable-model-invocation: true
---
# Grill → Brainstorm → Build

## Overview
A three-phase pipeline that takes a rough design idea through structured interrogation, options exploration, and implementation — without requiring the user to manually chain skill invocations.

## When to Use
- User says "grill me on this then build it"
- User says "think it through then implement"
- User says "design-to-build" or "full flow"
- User is starting a non-trivial feature and has a rough idea but no firm spec
- **Alignment-only mode:** user says "grill me so we're aligned", "firm up my understanding", or "find the drift" — the goal is comprehension, not a build (see Notes)

## Steps

### Phase 1: Grill
Invoke the `superpowers:brainstorming` skill (or run an inline interrogation if the plugin is unavailable: ask the user 5+ probing questions about scope, constraints, edge cases, success criteria, and out-of-scope items before proceeding to options exploration). Do not proceed to Phase 2 until the user has answered all branches and confirmed they are satisfied with the interrogation.

### Phase 2: Brainstorm
Invoke the `superpowers:brainstorming` skill using the outputs of Phase 1 as context. Surface at least 3 distinct implementation options. Do not proceed until the user selects or synthesizes a direction.

### Phase 3: Build
Invoke `superpowers:writing-plans` to produce a structured plan, then hand off to `superpowers:subagent-driven-development` for execution. Apply `superpowers:verification-before-completion` before declaring done.

## Notes
- Never collapse phases. Each phase requires explicit user confirmation before proceeding.
- If user skips Phase 1 explicitly, note the skipped interrogation and proceed.
- **Product before schedule.** Lead the grill with product and technical-scope questions; defer schedule/timeline/weekly-hours/sequencing questions until the user raises them — asking them up front reads as off-focus even when a kickoff brief mandated them.
- **De-jargon multiple-choice options.** When a grill question offers options phrased in technical or business jargon, put a one-line plain-language "why this matters" up front, not buried in the option description.
- **Alignment-only mode** — when the goal is to firm up understanding / find drift, not build: state up front that you're using the grill methodology and dropping Phases 2–3. **Ground-truth first** — dispatch Explore agents / read the real current code + docs so you grill against reality, not assumptions (drift is the whole point). Answer the user's "where is this documented?" sub-questions with file paths. Stop at Phase 1; only continue to Brainstorm/Build if the user explicitly asks.
