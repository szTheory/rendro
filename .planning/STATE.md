---
gsd_state_version: 1.0
milestone: v2.0
milestone_name: signature-fields-and-external-signing-preparation
status: between_milestones
last_updated: "2026-05-07T14:30:00Z"
last_activity: 2026-05-07 — v2.0 archived after verification backfill closed all requirement gaps
progress:
  total_phases: 5
  completed_phases: 5
  total_plans: 8
  completed_plans: 8
  percent: 100
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-07 after v2.0 close)

**Core value:** Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components, with clear pagination behavior and production-grade observability.
**Current focus:** Start the next milestone definition from a shipped `v2.0` baseline.

## Current Position

Phase: none active
Plan: none active
Status: Milestone `v2.0` is shipped and archived; no new milestone has been defined yet
Last activity: 2026-05-07 — v2.0 milestone archive completed after Phase 58/59 verification backfill closed the audit trail

Progress: [==========] 100%

## Milestone Snapshot

- Milestone: `v2.0 Signature Fields & External Signing Preparation` (shipped and archived on 2026-05-07; see `milestones/v2.0-ROADMAP.md`).
- Last shipped before that: `v1.10 Protected Delivery Hooks & Encryption Boundaries (2026-05-06)` — see `milestones/v1.10-ROADMAP.md`.
- Next milestone should continue phase numbering after Phase 59.

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
- [Phase 56]: Prepare rendered signature fields by patching Rendro-owned `/FT /Sig` widget bytes after render instead of threading `%Rendro.Document{}` or a new render-time index into the API.
- [Phase 56]: Keep the shared signing-preparation manifest generic under `metadata.signing_preparation` and isolate adapter-local handoff data under `metadata.signing_preparation_adapter`.
- [Phase 58]: Verification backfill can close shipped requirement gaps later without rewriting implementation history when the artifact trail is missing.
- [Phase 59]: Runtime tests remain the authoritative signing-preparation proof; docs/support lanes align claims but do not replace behavioral evidence.

### Roadmap Evolution

- `v1.9` closed 2026-05-06 as a shipped milestone — embedded artifact surfaces (document-level embedded files + curated links).
- `v1.10` closed 2026-05-06 as a shipped milestone — protected delivery hooks and encryption boundaries (external hooks first, narrow security claims, proof-backed validation before any in-core encryption).
- `v2.0` closed 2026-05-07 as a shipped milestone — unsigned signature authoring, deterministic unsigned widget serialization, artifact-first signing preparation, truthful support boundaries, and verification-backfill closure for Phases 55/56.

### Pending Todos

- Define the next milestone through `/gsd-new-milestone` (questioning -> research -> requirements -> roadmap).
- Publish `v0.2.0` from the verified release tag if it has not been pushed to external registries yet.

### Blockers/Concerns

- No local release-verification blocker remains from the last published release: `mix ci`, `mix release.preflight`, and `scripts/release_preflight_proof.exs --current-version-tag --worktree /tmp/rendro-release-proof` all pass at exact tag `v0.2.0`.
- Future signing work must not soften the current unsigned/preparation boundary into implied cryptographic trust, compliance, or viewer-validity claims.
- Tracking-artifact debt from v1.9 (missing `49-VERIFICATION.md`, stale `wave_0_complete: false` flags, inconsistent SUMMARY frontmatter shape) was accepted at close per the v1.9 audit; remediable retroactively if needed.

## Deferred Items

Items deferred at v2.0 milestone close on 2026-05-07:

| Category | Item | Status |
|----------|------|--------|
| viewer_proof | Apple Preview × `embedded_files` | unverified (viewer-side gap; Rendro authoring is correct per structural lane) |
| viewer_proof | Adobe Acrobat Reader forms checklist (Phase 47) | still unverified — not in v1.9 scope |
| signatures | Cryptographic digital signatures in core | deferred beyond v2.0 |
| compliance | PAdES/LTV/TSA/OCSP/CRL and broad compliance claims | deferred beyond v2.0 |
| viewer_proof | Signature-specific viewer promotion | unverified until recorded per-viewer evidence exists |
| docs | Regenerate `49-VERIFICATION.md` and refresh stale `wave_0_complete: false` flags on `49`/`50` `VALIDATION.md` | tech debt accepted at v1.9 close |
| docs | Standardize SUMMARY frontmatter shape (explicit `requirements:` list across all plans) | tech debt accepted at v1.9 close |
