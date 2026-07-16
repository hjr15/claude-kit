---
name: debugging-feedback-loop
public: true
description: Use when debugging a bug you can't yet reproduce reliably, or when you need a tight/automated reproduction loop before hypothesising — especially non-deterministic or flaky bugs. Complements superpowers:systematic-debugging (which says reproduce; this is HOW to build the loop).
---

# Debugging — build the feedback loop first

## Overview
`superpowers:systematic-debugging` tells you to reproduce the bug consistently and form
a hypothesis before fixing. This skill is the missing **HOW**: constructing the
reproduction (feedback) loop that makes hypothesis-testing cheap. **The loop is the
skill — everything after it is mechanical.** Do not proceed to hypothesise without one.
Adapted from mattpocock/skills `engineering/diagnose`.

## When to Use
- You have a bug but can't reliably reproduce it, or each reproduction is slow/manual.
- The bug is non-deterministic / flaky / timing-dependent.
- You're about to start guessing because reproduction is painful — stop and build a loop.

Do NOT use this as a *replacement* for systematic-debugging — run that for the overall
discipline (root cause before fix). Use this for the reproduce step inside it.

## The feedback-loop ladder (build the highest rung you can)
Pick the fastest, most deterministic loop available:
1. A failing automated test at the bug's level (unit / integration).
2. A single `curl` / CLI command that triggers it.
3. A CLI snapshot diff (capture output, compare to expected).
4. A headless-browser script (Playwright) for UI bugs.
5. A trace / log replay against a captured request.
6. A throwaway harness script that drives just the failing path.
7. A property / fuzz test that searches inputs for the trigger.
8. A `git bisect run` harness (a script that exits 0/1) to find the breaking commit.
9. A differential old-vs-new comparison (run both versions on the same input).
10. A human-in-the-loop bash script (you run steps, it prints `KEY=VALUE` back for the agent).

Then **iterate on the loop itself** — make it faster, sharper, and more deterministic
before you start changing production code.

## Probe-then-delete before the RED test
When the bug's mechanism depends on **opaque framework/DB behaviour you can't read
off the code** (ORM version-row semantics, transaction visibility, serialization
round-trips), don't trust the brief's root-cause guess. Write a throwaway probe
(`_probe-<topic>.test.ts` / a scratch script) that drives the *real* backend and
dumps raw state — audit rows, actual ids, recomputed hashes — read the true
behaviour, then **delete the probe** and write the RED test from correct
understanding. This is rung 6 of the ladder aimed at characterization: it caught a
"one bug" that was actually two distinct defects. For a review "could break" risk,
probe that exact path and bake the observed result into a regression assertion.

## Non-deterministic bugs
The goal is not a clean repro — it's a **higher reproduction rate**. Raise it (stress,
concurrency, fixed seeds, repeated runs, timing pressure) until the bug fires often
enough to debug. Don't burn time chasing a single clean reproduction.

## When you genuinely cannot build a loop
Stop. List exactly what you tried, and ask the user for the missing access —
environment, artifact, credentials, or instrumentation. **Do not hypothesise without a
loop.**

## Fixing — the "correct seam"
Write the test-before-fix only where a **correct seam** exists: one that exercises the
real bug pattern at the actual call site. If no correct seam exists, that itself is the
finding — a shallow seam gives false confidence. Flag the missing seam (an architecture
issue) rather than writing a test that passes without exercising the bug. Prove the fix
against ground truth, not just "no error" — see
[[reverify-claimed-state-against-live-source]].

## Hard rules
- The loop comes before the hypothesis. No loop → no guessing.
- For non-deterministic bugs, raise the reproduction rate; don't demand a clean repro.
- No correct seam = a finding to report, not a reason to write a hollow test.
