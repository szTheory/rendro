---
gsd_state_version: 1.0
milestone: v2.0
milestone_name: signature-fields-and-external-signing-preparation
status: ready_to_plan
last_updated: "2026-05-07T00:40:52Z"
last_activity: 2026-05-06 — Phase 55 executed with unsigned signature authoring and support-boundary closure
progress:
  total_phases: 3
  completed_phases: 1
  total_plans: 6
  completed_plans: 2
  percent: 33
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-06 after v1.9 close)

**Core value:** Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components, with clear pagination behavior and production-grade observability.
**Current focus:** Plan Phase 56 `Writer and External Signing Preparation Seam` on top of the completed Phase 55 unsigned-signature contract.

## Current Position

Phase: 56 (Writer and External Signing Preparation Seam)
Plan: Not started
Status: Ready to plan
Last activity: 2026-05-06 — Phase 55 completed and Phase 56 unblocked

Progress: [===.......] 33%

## Milestone Snapshot

- Active milestone: `v2.0 Signature Fields & External Signing Preparation` (Phase 55 complete; Phase 56 ready to plan).
- Last shipped: `v1.10 Protected Delivery Hooks & Encryption Boundaries (2026-05-06)` — see `milestones/v1.10-ROADMAP.md`.
- Phase numbering continues from v1.10 — v2.0 currently sits at completed Phase 55 / upcoming Phase 56.

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
- [Phase 55]: Keep unsigned signature placeholders on the existing `%Rendro.FormField{}` seam through `Rendro.signature_field/2` rather than opening a second forms engine.
- [Phase 55]: Preserve blocked signature metadata only on a finite rejection-only carrier so validate-stage typed errors stay explicit and signing-preparation behavior remains deferred.
- [Phase 55]: Public support claims must name the authored unsigned helper while keeping rendered signature widgets and digital signatures explicitly unsupported.

### Roadmap Evolution

- `v1.9` closed 2026-05-06 as a shipped milestone — embedded artifact surfaces (document-level embedded files + curated links).
- `v1.10` closed 2026-05-06 as a shipped milestone — protected delivery hooks and encryption boundaries (external hooks first, narrow security claims, proof-backed validation before any in-core encryption).
- `v2.0` is now active — Phase 55 shipped the unsigned signature authoring contract; Phase 56 will handle deterministic widget serialization and external-signing preparation seams.

### Pending Todos

- Publish `v0.2.0` from the verified release tag if it has not been pushed to external registries yet.

### Blockers/Concerns

- No local release-verification blocker remains: `mix ci`, `mix release.preflight`, and `scripts/release_preflight_proof.exs --current-version-tag --worktree /tmp/rendro-release-proof` all pass at exact tag `v0.2.0`.
- Phase 56 depends on keeping the new signature-field support boundary truthful while adding writer-side structures and final-byte handoff rules.
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
