---
name: strip-claude-from-repo-for-public
public: true
disable-model-invocation: true
description: Use when making a Claude-built private repo public — strips the Claude footprint from BOTH the working tree and the git history before the flip, since a clean tree with a dirty history still leaks on a public flip.
---

# Strip Claude For Public

## Overview

Removing Claude footprint before a public flip is **two separate problems**:
file artifacts in the tree, and metadata in git history. A repo can have a
spotless working tree and still leak everything via Co-Authored-By trailers,
Claude-named commit subjects, branches, and merge commits — and the
`public-readiness-audit` agent does **not** flag commit metadata. Decide history
handling before the flip, because a non-squashed history exposes all of it.

## When to Use

- Flipping a Claude-built repo from private to public
- Generating/publishing a public mirror of a private repo
- Any "make this repo shareable" task where Claude authored commits

## Steps

1. **Tree refs:** `git grep -i claude` for files, README bullets, CLAUDE.md,
   installer scripts, `docs/superpowers/`, Claude-only secrets.
2. **Map coupling before deleting.** Removing a Claude-only secret or script may
   orphan a generic framework. Keep the generic framework; neutralise only the
   Claude-coupled variable.
3. **Confirm test suites don't enumerate deleted scripts by name** (a globbed
   bootstrap is safe; a hardcoded list breaks).
4. **History:** `git log --format='%an %ae %s' | grep -i claude` and check
   trailers, branch names, and merge-commit subjects. **Scope the audit and any
   rewrite to `git log main`** (what actually ships), NOT `git log --all` — `--all`
   over-reports unreachable feature-branch tips that never go public, causing
   false-positive panic. Re-verify `origin/main` after the force-push.
5. **Decide history handling BEFORE the flip** — squash vs `git filter-repo`.
   Non-squashed history exposes everything.
6. **Deliberately OMIT the Co-Authored-By trailer on the strip commit itself.**
7. Add a LICENSE; build the squashed/clean state on a NEW `public-release`
   branch leaving `main` intact; **pause before force-push / visibility flip**
   for a final review.
8. **Fresh-clone external-user gate (beyond the leak audit).** Do an
   unauthenticated clone → scaffold → run → render as an outside user. Confirm
   manifests resolve and the gitignore actually keeps user data out — assert with
   `git check-ignore <path>`, **never by grepping `.gitignore` text**: a `!negation`
   un-ignore line matches the same regex and falsely reports the path protected (a
   real privacy bug). This end-to-end pass catches usability/privacy-mode defects
   (broken plugin-install paths, gitignore not applying in a given mode) that the
   file/history leak audit never flags.

## Relation

Complements the `public-readiness-audit` agent (which detects tree-level
secrets/PII but misses commit metadata) and reinforces the
scrub git history not just files for public memory. Sibling skill
`clean-room-reimplement-fork-enhancement-for-upstream-pr` covers the narrower
case of contributing one enhancement upstream (fresh clone + omit-Claude-trailer)
rather than flipping a whole repo public.
