# claude-kit

A library of **agents** and **skills** for [Claude Code](https://claude.com/claude-code).
Clone it, run the installer, and they show up in your own Claude Code.

- **Agents** are specialists you can dispatch for a job — a backend architect, a security
  reviewer, a UX researcher, a performance engineer.
- **Skills** are procedures Claude follows when a situation matches — how to review a diff,
  how to run a team of agents, how to recover a bad merge.

## Install

```bash
git clone https://github.com/hjr15/claude-kit.git
cd claude-kit
bash install.sh
```

Then start (or restart) Claude Code. That's it.

The installer symlinks `skills/` and `agents/` into `~/.claude/`. It touches nothing else —
no settings are merged, no hooks are installed, nothing is overwritten. Because they're
symlinks, `git pull` updates everything with no reinstall.

```bash
bash install.sh --check   # report drift without changing anything
bash install.sh --list    # print available bundles, write nothing
bash install.sh --bundle git,code   # install only items in the given bundle(s)
```

It's safe to re-run, and it will refuse rather than overwrite a skill or agent of your own
that happens to share a name.

To uninstall, delete the symlinks it made from `~/.claude/skills/` and `~/.claude/agents/`.

<!-- INSIDE:BEGIN -->
## What's inside

28 skills and 26 agents, grouped by discipline. Install one with `bash install.sh --bundle <name>`.

### `ai`
- **ai-engineer** (agent) — Practical ML/AI implementation specialist — LLM integration, RAG, recommendation/vision systems, model serving, and cost-optimised inference. Builds production-grade intelligent features from a spec for any AI stack.
- **ai-ethics-governance-specialist** (agent) — Responsible-AI specialist — bias detection, fairness metrics, explainability (SHAP/LIME), AI governance and risk frameworks, and regulatory alignment (EU AI Act, financial/credit, privacy). Advisory; keeps AI in-scope, auditable, and human-overseen.
- **llm-evals-engineer** (agent) — Given an LLM-backed feature (prompt, agent, RAG pipeline, classifier), design or review how its output quality is measured — eval datasets, graders, regression gates, and grounding/hallucination checks. Returns an eval design or a quality verdict, not a feature build.

### `api`
- **api-contract-reviewer** (agent) — Given a proposed or changed API contract (REST endpoints, GraphQL schema, OpenAPI spec, event payloads), review it for design quality, consistency, and — critically — breaking changes against the current contract. Returns a review with a breaking/safe verdict, not an implementation.
- **api-integration-specialist** (agent) — Internal API architecture & developer-experience specialist — REST/GraphQL/gRPC design, OpenAPI docs, SDKs, versioning, caching/performance, auth, and service-to-service communication. Builds APIs that are reliable to consume and evolve.
- **api-tester** (agent) — Comprehensive API testing specialist — performance/load profiling, contract validation (OpenAPI), integration, chaos, and basic security testing. Finds breaking points and contract drift before deploy, for any API stack.

### `architecture`
- **architect-team** (skill) — Deploy the architecture agents (architect, code-architect, backend-architect) as a coordinated design council to design or review a feature/system before it's built. Advisory-first — independent design perspectives → synthesis → ADR capture → implement. Use standalone ("how should I structure X?", "review this design") or as the design stage inside a plan/body-of-work.
- **adversarial-verifier** (agent) — Given a claim, finding, or "it works / it's fixed / it's done" assertion, try to REFUTE it. Returns a refuted/upheld/unproven verdict with the evidence actually checked, the holes that remain, and the positive + rollback test that would settle it.
- **architect** (agent) — Given a proposed design, feature, or change, give an independent architecture opinion — module boundaries, coupling, the simpler alternative, and which decisions are ADR-worthy. Returns an assessment, not an implementation.
- **backend-architect** (agent) — Server-side architecture specialist — API design, database modelling/optimisation, system design (microservices/serverless/event-driven), auth/security, performance, and deployability. Designs and implements robust backend services for any stack.
- **code-architect** (agent) — "Use this agent for project layout and code organization — scalable folder/directory structures, module organization, component hierarchy, and \"where does this file/feature go\" conventions. NOT for design review (use architect) or server/data design (use backend-architect). Examples: user: 'How should I organize my e-commerce product catalog feature?' -> assistant: 'Let me use the code-architect agent to design a scalable folder structure for your product catalog' -> <uses agent>. Another example: user: 'Where should these new auth files live and how should the module be laid out?' -> assistant: 'I'll use the code-architect agent to design the folder structure and module organization' -> <uses agent>."
- **database-architect** (agent) — Database design & optimisation specialist — schema modelling (SQL/NoSQL), indexing strategy, query optimisation, migrations, transactions/ACID, and data integrity. Designs and tunes the data layer; composes with backend-architect for deep DB work.
- **tech-lead** (agent) — Technical leadership & orchestration — architecture decisions, tech-debt strategy, ADRs, technology selection, risk, and coordinating specialist work across a large change. Conducts the engineering-team (maps a big plan to the right domain teams and sequences them); advise-and-coordinate, not hands-on implementation.

### `authoring`
- **caveman** (skill) — > Ultra-compressed communication mode. Cuts token usage ~75% by dropping filler, articles, and pleasantries while keeping full technical accuracy. Use when user says "caveman mode", "talk like caveman", "use caveman", "less tokens", "be brief", or invokes /caveman.
- **doc-accuracy-audit** (skill) — Use when asked to validate that a repo's READMEs and docs are accurate / up to date against the current code (not just diagrams — endpoints, ports, counts, env vars, commands, schemas, event contracts). Triggers on "validate the docs against the code", "make sure the docs are up to date", "audit the READMEs for accuracy", "are the docs still correct".
- **mcp-overflow-delegate-summary** (skill) — Use when an MCP tool result is dumped to a tool-results/*.txt file because it exceeded the token cap — delegate the read+summarize to a general-purpose subagent (or jq the file for targeted extraction) so the raw payload stays out of the main context.
- **normalize-and-group-imported-agent-pack** (skill) — Use when handed a batch of imported subagent .md files (e.g. agent-studio / B2B "agent packs") to integrate into this repo — strip studio/B2B frontmatter to clean name/description/model, decide merge-vs-keep-vs-drop against the existing roster, group keepers into an advisory-first domain "team" SKILL with model-tiering + adaptive selection + keyword hooks, then update the README catalogue and run install.sh. Distinct from skill-builder (builds one skill via interview) and library-audit (audits existing skills).
- **readme-diagram-audit** (skill) — Use when auditing a repo for diagram coverage and convention compliance — scans docs/diagrams/ for completeness, validates frontmatter against the taxonomy, and flags missing diagrams the repo would benefit from. Triggers on "audit diagrams", "check diagram coverage", "visual documentation audit".
- **skill-builder** (skill) — Use when creating a new skill from scratch — runs a discovery interview then builds the SKILL.md in the right category/format. For auditing existing skills use library-audit instead.
- **symlink-vs-realfile-classify-before-deleting-fanout-dups** (skill) — Use during a memory/skill/config dedup on a symlink-fanned tree (like claude-config, where install.sh symlinks universal cards into per-project dirs and ~/.claude) — before deleting any "duplicate", run a `test -L` classification loop so you delete only genuine real-file dups (often a sister session's copy) and KEEP the session's own install.sh fan-out symlinks. Guards against a near-miss deleting your own fan-out.
- **teach** (skill) — Teach the user a new skill or concept, within this workspace.

### `code`
- **code-team** (skill) — Deploy the code-quality agents (code-quality-reviewer, code-architect) alongside the /code-review skill to answer "is this code well-built?" — clean code, SOLID, structure, maintainability, refactoring. Advisory-first. Use standalone ("review this module's quality", "how should this be structured?", "is this refactor sound?") or as the quality lane inside a plan/body-of-work. Complements test/correctness review for "is it proven correct?".
- **adversarial-verifier** (agent) — Given a claim, finding, or "it works / it's fixed / it's done" assertion, try to REFUTE it. Returns a refuted/upheld/unproven verdict with the evidence actually checked, the holes that remain, and the positive + rollback test that would settle it.
- **code-architect** (agent) — "Use this agent for project layout and code organization — scalable folder/directory structures, module organization, component hierarchy, and \"where does this file/feature go\" conventions. NOT for design review (use architect) or server/data design (use backend-architect). Examples: user: 'How should I organize my e-commerce product catalog feature?' -> assistant: 'Let me use the code-architect agent to design a scalable folder structure for your product catalog' -> <uses agent>. Another example: user: 'Where should these new auth files live and how should the module be laid out?' -> assistant: 'I'll use the code-architect agent to design the folder structure and module organization' -> <uses agent>."
- **code-quality-reviewer** (agent) — Code-quality & clean-code reviewer — readability, SOLID, design patterns, code smells, complexity, DRY, and long-term maintainability with concrete refactoring guidance. Advisory; complements the diff-focused /code-review skill (which hunts correctness bugs).
- **performance-engineer** (agent) — Performance & efficiency specialist — profiling, bottleneck analysis, algorithm/memory optimisation, query tuning, caching, and frontend rendering/load performance. Measures first, optimises what matters, and avoids premature optimisation. Cross-cutting; composes with backend, frontend, and testing teams.

### `debugging`
- **debugging-feedback-loop** (skill) — Use when debugging a bug you can't yet reproduce reliably, or when you need a tight/automated reproduction loop before hypothesising — especially non-deterministic or flaky bugs. Complements superpowers:systematic-debugging (which says reproduce; this is HOW to build the loop).
- **generator-oracle-zero-diff-verify** (skill) — Use when building a code-generator, sanitizer, or export pipeline whose output already exists as a hand-maintained artifact — make zero-git-diff against that existing artifact the acceptance test, instead of hand-deriving a per-file classification.

### `devops`
- **ghcr-first-push-403-seed-and-link** (skill) — Use when a CI build succeeds but the GHCR push fails 403 Forbidden for a service whose package never existed, on a personal (non-org) account. Default GITHUB_TOKEN can push to existing packages but can't create one on first push. Gives the seed-and-link remediation.
- **grill-brainstorm-build** (skill) — Use when the user wants to go from a rough idea to implementation, running through interrogation, options exploration, and build in one flow. Triggers on "grill me then build", "design-to-build", or "think it through then implement".
- **devops-engineer** (agent) — Use when building or automating CI/CD pipelines, infrastructure-as-code, containers, or deployment workflows — DevOps/platform engineer — CI/CD pipelines, IaC (Terraform/Pulumi/Ansible), Docker/Kubernetes, deployment strategies (blue-green/canary/rolling), monitoring & observability, and cloud cost/reliability. Builds and automates production infrastructure for any stack.
- **n8n-workflow-builder** (agent) — n8n automation specialist — designs, builds, validates, and deploys n8n workflows using the n8n-MCP tooling, validation-first (discover → configure → pre-validate → build → validate → deploy). For self-hosted n8n; also useful as a data-ingestion/automation builder.

### `frontend`
- **brand-guardian** (agent) — Use when establishing or enforcing brand identity, design tokens, voice/tone, or cross-platform visual consistency — brand identity & visual-consistency specialist — brand foundations, design systems/tokens, voice & tone, asset management, and cross-platform consistency. Keeps every touchpoint on-brand without slowing delivery.
- **frontend-developer** (agent) — Use when implementing UI from a design or spec — building components, responsive layouts, state management, or frontend performance/accessibility work — elite frontend implementation specialist — modern JS frameworks (React, Vue, Angular, Svelte, Next.js), responsive design, performance, accessibility, and state management. Builds production-grade, maintainable UI from a design or spec for any frontend stack.
- **mobile-ux-optimizer** (agent) — "Use this agent for mobile-FIRST optimization of an EXISTING component or flow — touch targets, thumb-zone/one-handed layout, native mobile UX patterns, and mobile usability standards (WCAG, 44px targets). Takes a component that already exists and makes it work well on mobile. NOT for general/visual UI design or building UI from scratch — use ui-designer for that (it also covers responsive layouts). Examples: <example>Context: User has a desktop-focused component that breaks on mobile. user: 'I've built this navigation component but it's not working well on mobile devices' assistant: 'Let me use the mobile-ux-optimizer agent to optimize this existing component for a mobile-first experience' <commentary>An existing component needs mobile-specific optimization, so use mobile-ux-optimizer.</commentary></example> <example>Context: User wants an existing checkout flow made usable one-handed. user: 'Our checkout flow is hard to use on phones — too much scrolling and the buttons are tiny' assistant: 'I'll use the mobile-ux-optimizer agent to improve touch targets and thumb-reach in the existing checkout flow' <commentary>Mobile usability optimization of an existing flow is this agent's lane.</commentary></example>"
- **ui-designer** (agent) — Visionary UI design specialist for general UI and visual design — visual hierarchy, typography, color systems, design tokens, component states, platform conventions, responsive/mobile-first layouts, and implementation-ready specs for any frontend. Use for designing or styling a UI from scratch and overall visual direction. For mobile-FIRST optimization of an existing component or flow (touch targets, native mobile UX, mobile usability standards), use mobile-ux-optimizer instead.
- **ux-researcher** (agent) — Empathetic UX research specialist — lean research methods, heuristic evaluation, journey mapping, usability testing, behavioral analysis, persona development, and synthesis that turns user behavior into actionable design decisions for any product.

### `git`
- **backport-review-fix-into-plan-of-record** (skill) — Use when a per-task review during subagent-driven development catches and fixes a real bug in code that a plan-of-record authored — edit the plan itself to carry the fix, so a future plan re-run doesn't reinstate the same bug on top of the corrected tree.
- **fix-blocker-rather-than-override** (skill) — Use when a pre-existing master CI gate is red and blocking your unrelated PR — decide between fix-the-blocker (compounds across all PRs) and admin-override (one-PR value + habit-debt)
- **mid-session-master-advance-rebase** (skill) — Use when `git diff origin/master..HEAD` (or main) shows files you never touched as DELETED/modified, yet `git status` is clean and `git log` shows only your commits — origin advanced past your fork point and the diff shows its new commits inverted. Fix with `git fetch && git rebase`.
- **partial-stage-comingled-file-when-add-p-unavailable** (skill) — Use when you must commit ONLY your hunk of a tracked file that also carries another session's uncommitted edits, and `git add -p` is blocked (non-interactive harness) — stage exact content via a constructed blob + `git update-index`, leaving the foreign working-tree edits untouched.
- **push-from-worktree-to-integrate-past-foreign-dirty-main** (skill) — Use when you need to integrate your finished branch but the shared main/master checkout holds a live sister session's UNCOMMITTED work — push your worktree branch straight to origin/main (or merge the PR from the worktree) instead of checkout/merge in the shared tree, after asserting your HEAD is an ancestor of origin/main AND the incoming diff has zero path-overlap with the sibling's WIP.
- **remote-branch-graveyard-sweep** (skill) — Use to bulk-clean stale remote branches ("clean up the branches" / "make sure the repo is clean") — classify each with git cherry (all-minus = merged), and for any branch with unmerged commits, verify its unique artifact already exists on main BEFORE deleting, since work is often superseded (reimplemented under new SHAs) rather than literally merged.
- **stacked-pr-base-branch-delete-closes-child** (skill) — Use before merging a base PR with `--delete-branch` when another (stacked) PR targets that base branch — deleting the base CLOSES the stacked child (GitHub won't retarget it to main) and it can't be reopened once the base is gone; retarget the child first, or open a fresh PR from the same head.
- **stacked-pr-for-review-split** (skill) — Use when a user asks to review changes that are already committed inside an open PR, and you cannot (or should not) force-push the PR's history. Produces a non-destructive stacked PR carrying only the diff the user wants to review.
- **strip-claude-from-repo-for-public** (skill) — Use when making a Claude-built private repo public — strips the Claude footprint from BOTH the working tree and the git history before the flip, since a clean tree with a dirty history still leaks on a public flip.
- **vet-foreign-pr-mergeability** (skill) — Use when asked to investigate whether an open PR you didn't author (often a sister session's) can be merged — runs a throwaway-worktree merge-test + build gate + parallel content-review + scope-confine check before giving a merge verdict, then tears the worktree down. Not for shipping your own PRs (use multi-pr-sweep) or explaining a red rollup (use pr-check-rollup-vs-required-gate).

### `mobile`
- **mobile-team** (skill) — Deploy the mobile agents (mobile-app-builder, mobile-ux-optimizer) — with ui-designer/ux-researcher/frontend-developer on call — to design and build native or cross-platform mobile apps. Advisory-first for UX, build-and-verify for the app. Use standalone ("build the iOS app", "optimise this screen for mobile") or as the mobile lane inside a plan. Nascent — a growth area for the planned web+mobile package.
- **frontend-developer** (agent) — Use when implementing UI from a design or spec — building components, responsive layouts, state management, or frontend performance/accessibility work — elite frontend implementation specialist — modern JS frameworks (React, Vue, Angular, Svelte, Next.js), responsive design, performance, accessibility, and state management. Builds production-grade, maintainable UI from a design or spec for any frontend stack.
- **mobile-app-builder** (agent) — Mobile app developer — native iOS (Swift/SwiftUI) & Android (Kotlin/Compose) and cross-platform (React Native, Flutter, Expo); 60fps UI, platform integration (push, biometrics, deep links, camera), offline-first, and app-store readiness. Builds native-feeling mobile experiences for the planned web+mobile package.
- **mobile-ux-optimizer** (agent) — "Use this agent for mobile-FIRST optimization of an EXISTING component or flow — touch targets, thumb-zone/one-handed layout, native mobile UX patterns, and mobile usability standards (WCAG, 44px targets). Takes a component that already exists and makes it work well on mobile. NOT for general/visual UI design or building UI from scratch — use ui-designer for that (it also covers responsive layouts). Examples: <example>Context: User has a desktop-focused component that breaks on mobile. user: 'I've built this navigation component but it's not working well on mobile devices' assistant: 'Let me use the mobile-ux-optimizer agent to optimize this existing component for a mobile-first experience' <commentary>An existing component needs mobile-specific optimization, so use mobile-ux-optimizer.</commentary></example> <example>Context: User wants an existing checkout flow made usable one-handed. user: 'Our checkout flow is hard to use on phones — too much scrolling and the buttons are tiny' assistant: 'I'll use the mobile-ux-optimizer agent to improve touch targets and thumb-reach in the existing checkout flow' <commentary>Mobile usability optimization of an existing flow is this agent's lane.</commentary></example>"
- **performance-engineer** (agent) — Performance & efficiency specialist — profiling, bottleneck analysis, algorithm/memory optimisation, query tuning, caching, and frontend rendering/load performance. Measures first, optimises what matters, and avoids premature optimisation. Cross-cutting; composes with backend, frontend, and testing teams.
- **ui-designer** (agent) — Visionary UI design specialist for general UI and visual design — visual hierarchy, typography, color systems, design tokens, component states, platform conventions, responsive/mobile-first layouts, and implementation-ready specs for any frontend. Use for designing or styling a UI from scratch and overall visual direction. For mobile-FIRST optimization of an existing component or flow (touch targets, native mobile UX, mobile usability standards), use mobile-ux-optimizer instead.
- **ux-researcher** (agent) — Empathetic UX research specialist — lean research methods, heuristic evaluation, journey mapping, usability testing, behavioral analysis, persona development, and synthesis that turns user behavior into actionable design decisions for any product.

### `multi-agent`
- **multi-agent-branch-collision-recovery** (skill) — Use when a commit landed on the wrong branch because a parallel agent shifted the active branch in a shared working directory. Recovers by cherry-picking onto the correct branch and resetting the wrong branch's ref without destructive force-push.
- **recon-swarm** (skill) — Use before planning a non-trivial change to map the affected surfaces — dispatches read-only scout agents in parallel under chosen lenses and returns a synthesized recon brief. Triggers on "recon", "scout this", "map the surfaces before we plan".
- **shared-brief-parallel-fanout** (skill) — Use when a task splits into N same-shaped units (audit a corpus by cluster, author N notebooks, tag N subjects, scan N transcripts) and you fan out parallel agents from ONE shared brief — the brief artifact, uniform output contract, agent-vs-script split, and central integration.
- **adversarial-verifier** (agent) — Given a claim, finding, or "it works / it's fixed / it's done" assertion, try to REFUTE it. Returns a refuted/upheld/unproven verdict with the evidence actually checked, the holes that remain, and the positive + rollback test that would settle it.
- **deep-investigator** (agent) — For a cryptic bug or unexplained behaviour, run a multi-source, hypothesis-driven investigation (exact-error search, known-issue/changelog/Context7 lookup, code tracing) and return ranked root-cause hypotheses with confidence and the cheapest next probe for each. Investigates; does not fix.

### `security`
- **public-readiness-audit** (agent) — Audit a private repo to determine whether it can be safely flipped to public visibility. Scans HEAD + git history for live secrets, real PII, internal infrastructure references, business-confidential docs, and license/IP concerns. Returns a structured verdict with actionable next steps.
- **security-reviewer** (agent) — Adversarial security review of a change, PR, or set of manifests — threat-models the diff for injection, auth/secret-handling, supply-chain, CI-workflow, and k8s-manifest risks. Returns findings by severity with fixes. Complements (not duplicates) the public-readiness-audit agent and the /security-review skill.
- **security-specialist** (agent) — Use when designing or hardening security — auth/authz flows, encryption, input validation, secret handling, or dependency/supply-chain risk — secure-coding & application-security specialist — OWASP Top 10, auth/authz design, encryption & secret handling, input validation, dependency/supply-chain risk, and secure-by-design implementation. Advisory; complements the adversarial diff-focused security-reviewer.
<!-- INSIDE:END -->

Browse [`agents/`](agents/) and [`skills/`](skills/); every file is readable markdown, and
the frontmatter `description` is what Claude matches against to decide when to use it.

## Contributing

**Please open an issue** — for bugs, ideas, or a skill you'd like to see.

Pull requests can't be merged here, and that's structural rather than unfriendly: this repo
is generated automatically from a private one, so any commit made directly here is
overwritten by the next export. An issue is the way in, and it's genuinely welcome.

## Licence

MIT — see [LICENSE](LICENSE). Use it, fork it, adapt it.
