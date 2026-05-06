---
gsd_state_version: 1.0
milestone: v2.0
milestone_name: signature-fields-and-external-signing-preparation
status: defining_requirements
last_updated: "2026-05-06T21:15:00Z"
last_activity: 2026-05-06 — v2.0 started with research-backed milestone scoping
progress:
  total_phases: 4
  completed_phases: 3
  total_plans: 8
  completed_plans: 8
  percent: 100
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-06 after v1.9 close)

**Core value:** Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components, with clear pagination behavior and production-grade observability.
**Current focus:** Define and plan `v2.0 Signature Fields & External Signing Preparation` from a shipped and release-verified v1.10 baseline.

## Current Position

Phase: Not started (defining requirements)
Plan: -
Status: Defining requirements and roadmap for `v2.0 Signature Fields & External Signing Preparation`
Last activity: 2026-05-06 — milestone goals confirmed and research completed

Progress: [==========] 100%

## Milestone Snapshot

- Active milestone: `v2.0 Signature Fields & External Signing Preparation` (requirements and roadmap in progress).
- Last shipped: `v1.10 Protected Delivery Hooks & Encryption Boundaries (2026-05-06)` — see `milestones/v1.10-ROADMAP.md`.
- Phase numbering continues from v1.10 — v2.0 starts at Phase 55.

## Performance Metrics

Per-phase metrics for shipped milestones live in their archives under `.planning/milestones/v[X.Y]-ROADMAP.md` and per-plan SUMMARY frontmatter.

## Accumulated Context

### Decisions

- Keep protection option normalization inside `Rendro.Protect` so the canonical public seam stays explicit and artifact-first.
- Redact qpdf process failures to exit-status or exception-module tuples so passwords and raw stderr never escape typed `:protect` errors.
- Keep qpdf executable lookup and command execution injectable while guaranteeing temp-dir cleanup on every adapter path.
- [Phase 52]: Classify Poppler protected-PDF failures into stable redacted reasons and pin the real qpdf + pdfinfo lane behind the explicit `live_pdf_tools` tag.
- [Phase 51]: Keep protected output as a normal %Rendro.Artifact{} with one narrow metadata.protection contract.
- [Phase 51]: Recurse through nested maps and lists when scrubbing audit metadata so protection secrets never cross audit boundaries.
- [Phase 51]: Keep protected-delivery docs artifact-first so Oban args and Mailglass transport never persist passwords.
- [Phase 53]: Keep `Rendro.Storage` narrow while `Rendro.Storage.Local` preserves only safe protected-artifact metadata in a first-party sidecar.
- [Phase 53]: Publish one canonical protected-delivery recipe: `render_to_artifact -> Protect.password -> store/deliver`, with identifiers-only async args and transport-only Mailglass docs.
- [Phase 54]: Promote only Apple Preview for `protection` after the full five-check proof row passes; keep Adobe Acrobat Reader `unverified` until it has its own recorded checklist.
- [Phase 54]: Release readiness must fail early when the current changelog entry omits the canonical protected-delivery pointer.

### Roadmap Evolution

- `v1.9` closed 2026-05-06 as a shipped milestone — embedded artifact surfaces (document-level embedded files + curated links).
- `v1.10` closed 2026-05-06 as a shipped milestone — protected delivery hooks and encryption boundaries (external hooks first, narrow security claims, proof-backed validation before any in-core encryption).
- `v2.0` is now active — signature fields and external signing preparation, with PAdES/LTV/TSA/OCSP/CRL still deferred.

### Pending Todos

- Finalize `v2.0` requirements and phase roadmap.
- Publish `v0.2.0` from the verified release tag if it has not been pushed to external registries yet.

### Blockers/Concerns

- No local release-verification blocker remains: `mix ci`, `mix release.preflight`, and `scripts/release_preflight_proof.exs --current-version-tag --worktree /tmp/rendro-release-proof` all pass at exact tag `v0.2.0`.
- Tracking-artifact debt from v1.9 (missing `49-VERIFICATION.md`, stale `wave_0_complete: false` flags, inconsistent SUMMARY frontmatter shape) was accepted at close per the v1.9 audit; remediable retroactively if needed.

## Deferred Items

Items deferred at v1.9 milestone close on 2026-05-06:

| Category | Item | Status |
|----------|------|--------|
| viewer_proof | Apple Preview × `embedded_files` | unverified (viewer-side gap; Rendro authoring is correct per structural lane) |
| viewer_proof | Adobe Acrobat Reader forms checklist (Phase 47) | still unverified — not in v1.9 scope |
| encryption | Native PDF encryption in core | deferred to v1.10 |
| signatures | Digital signatures and compliance-oriented signing claims | deferred to v2.0+ |
| docs | Regenerate `49-VERIFICATION.md` and refresh stale `wave_0_complete` flags on `49`/`50` `VALIDATION.md` | tech debt accepted at v1.9 close |
| docs | Standardize SUMMARY frontmatter shape (explicit `requirements:` list across all plans) | tech debt accepted at v1.9 close |
| Phase 51 P02 | 2 min | 2 tasks | 7 files |
