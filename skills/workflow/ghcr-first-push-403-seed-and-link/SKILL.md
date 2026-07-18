---
name: ghcr-first-push-403-seed-and-link
public: true
bundles: [devops]
description: Use when a CI build succeeds but the GHCR push fails 403 Forbidden for a service whose package never existed, on a personal (non-org) account. Default GITHUB_TOKEN can push to existing packages but can't create one on first push. Gives the seed-and-link remediation.
disable-model-invocation: true  # audit 2026-06-12: primary action pushes images to a registry + edits package settings
---
# GHCR First-Push 403: Seed and Link a New Package
## Steps
1. Diagnose, don't retry: gh run view --log-failed | grep 403/denied; confirm via authed docker manifest inspect that NO image exists yet.
2. Owner action — stop and ask (pushing to a registry unprompted is a scope escalation).
3. Seed at the merge SHA (not a throwaway tag) with a write:packages PAT.
4. Link package → repo: LABEL org.opencontainers.image.source + Package settings → Manage Actions access → repo = Write.
5. Restore live fast by pinning the existing seed tag rather than a 40-min rebuild (see seed-pin-restore...).
6. Prove going-forward on the POST-merge run (PR builds with push:false never exercise the 403).
