---
name: mobile-team
public: true
bundles: [mobile]
description: Deploy the mobile agents (mobile-app-builder, mobile-ux-optimizer) — with ui-designer/ux-researcher/frontend-developer on call — to design and build native or cross-platform mobile apps. Advisory-first for UX, build-and-verify for the app. Use standalone ("build the iOS app", "optimise this screen for mobile") or as the mobile lane inside a plan. Nascent — a growth area for the planned web+mobile package.
disable-model-invocation: true
---
# /mobile-team — Native & Cross-Platform Mobile

## Overview
The mobile lane, distinct from the web `frontend-team`:

| Agent | Role |
|---|---|
| `mobile-app-builder` | **Builds** — native iOS (Swift/SwiftUI) / Android (Kotlin/Compose) + cross-platform (React Native, Flutter, Expo); 60fps, platform integration, offline-first, app-store readiness |
| `mobile-ux-optimizer` | **Mobile UX** — touch targets, thumb-zone/one-handed flows, mobile-first layouts, theme consistency |
| `ui-designer` / `ux-researcher` (on call) | shared visual/UX judgement (web + mobile) |
| `performance-engineer` (on call) | mobile profiling (frame rate, memory, battery, startup) |

> **Status: nascent.** There are no mobile apps in the repos yet — this team exists
> for the **planned web+mobile package**. It's a deliberate growth area: as real
> mobile work starts, expect to add agents (e.g. release/store management, mobile
> CI/CD, deep-link/push specialists) and to harden the conventions. Treat it as a
> seed, not a finished unit.

## When to Use
- Building or designing a native/cross-platform app, or a mobile screen/flow.
- Deciding a mobile architecture (native vs RN vs Flutter) — pull `architect-team` too.
- Not for: mobile-*responsive web* (that's `frontend-team` + `ui-designer`, which now
  carries the mobile-first responsive specifics).

## Adaptive agent selection (token discipline)
- *UX/usability of a mobile screen* → `mobile-ux-optimizer` (+ `ux-researcher`).
- *build/implement a feature* → `mobile-app-builder`.
- *jank/perf on device* → `performance-engineer`.
- *new app from scratch* → design (ux/ui) → build (app-builder) → verify.

## Boundaries
- **Web vs mobile:** `frontend-team` owns web (Next.js/Tailwind); this owns native/
  cross-platform. Shared design language lives in `ui-designer` (used by both).
- Architecture decisions (native vs cross-platform, offline-sync model) → `architect-team`.
- Testing/perf → `testing-team` (`performance-engineer` shared); security/privacy
  (mobile permissions, secure storage) → `security-team`.

## Integration
- The `engineering-team` pulls this for mobile-shaped surfaces of a web+mobile plan,
  in parallel with `frontend-team` for the shared web surface.
- Keyword hook: a repo can register `mobile → deploy mobile-team` (or `ios`,
  `android`) in its `CLAUDE.md`/memory once a mobile app lands.

## Related
- `frontend-team` — the web counterpart; shares `ui-designer`/`ux-researcher`
- `architect-team` — native-vs-cross-platform + offline architecture decisions
- `testing-team` — `performance-engineer` for on-device profiling
