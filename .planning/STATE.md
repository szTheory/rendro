---
gsd_state_version: 1.0
milestone: v2.1
milestone_name: cryptographic-signing-and-signed-artifact-proof
status: between_milestones
last_updated: "2026-05-07T20:49:47Z"
last_activity: 2026-05-07 — v2.1 archived after signing proof, branch protection, and verification closure aligned
progress:
  total_phases: 4
  completed_phases: 4
  total_plans: 8
  completed_plans: 8
  percent: 100
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-07 after v2.1 close)

**Core value:** Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components, with clear pagination behavior and production-grade observability.
**Current focus:** Start the next milestone definition from a shipped `v2.1` baseline.

## Current Position

Phase: none active
Plan: none active
Status: Milestone `v2.1` is shipped and archived; no new milestone has been defined yet
Last activity: 2026-05-07 — v2.1 milestone archive completed after signing proof, verification artifacts, and required-check enforcement all closed

Progress: [==========] 100%

## Milestone Snapshot

- Milestone: `v2.1 Cryptographic Signing & Signed-Artifact Proof` (shipped and archived on 2026-05-07; see `milestones/v2.1-ROADMAP.md`).
- Last shipped before that: `v2.0 Signature Fields & External Signing Preparation (2026-05-07)` — see `milestones/v2.0-ROADMAP.md`.
- Next milestone should continue phase numbering after Phase 63.

## Performance Metrics

Per-phase metrics for shipped milestones live in their archives under `.planning/milestones/v[X.Y]-ROADMAP.md` and per-plan SUMMARY frontmatter.

## Accumulated Context

### Decisions

- Keep protection option normalization inside `Rendro.Protect` so the canonical public seam stays explicit and artifact-first.
- Redact qpdf process failures to exit-status or exception-module tuples so passwords and raw stderr never escape typed `:protect` errors.
- Keep qpdf executable lookup and command execution injectable while guaranteeing temp-dir cleanup on every adapter path.
- [Phase 52]: Classify Poppler protected-PDF failures into stable redacted reasons and pin the real qpdf + pdfinfo lane behind the explicit `live_pdf_tools` tag.
- [Phase 51]: Keep protected output as a normal `%Rendro.Artifact{}` with one narrow `metadata.protection` contract.
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
- [v2.1]: Prove one narrow cryptographic-signing path before any compliance or long-lived-signature stories.
- [Phase 62]: Require `signing-live-proof` on `main` so the supported cryptographic-signing path remains an operational gate rather than advisory proof only.

### Roadmap Evolution

- `v1.9` closed 2026-05-06 as a shipped milestone — embedded artifact surfaces (document-level embedded files + curated links).
- `v1.10` closed 2026-05-06 as a shipped milestone — protected delivery hooks and encryption boundaries (external hooks first, narrow security claims, proof-backed validation before any in-core encryption).
- `v2.0` closed 2026-05-07 as a shipped milestone — unsigned signature authoring, deterministic unsigned widget serialization, artifact-first signing preparation, truthful support boundaries, and verification-backfill closure for Phases 55/56.
- `v2.1` closed 2026-05-07 as a shipped milestone — cryptographic signing and signed-artifact proof over the shipped `v2.0` seam, with enforced proof gates and truthful support boundaries.

### Pending Todos

- Define the next milestone through `/gsd-new-milestone` (questioning -> research -> requirements -> roadmap).
- Publish the next release/tag from the now-verified signing milestone when you are ready to ship externally.

### Blockers/Concerns

- Future signing work must not soften the current unsigned/preparation boundary into implied trust anchoring, blanket viewer support, or compliance claims.
- Long-lived signatures, timestamps, revocation evidence, and PAdES narratives remain outside `v2.1` until there is a dedicated proof lane.

## Deferred Items

Items deferred at `v2.1` milestone close on 2026-05-07:

| Category | Item | Status |
|----------|------|--------|
| viewer_proof | Apple Preview × `embedded_files` | unverified (viewer-side gap; Rendro authoring is correct per structural lane) |
| viewer_proof | Adobe Acrobat Reader forms checklist (Phase 47) | still unverified — not in `v2.1` scope |
| signatures | Long-lived signatures, timestamps, and revocation evidence | deferred beyond `v2.1` |
| compliance | PAdES/LTV/TSA/OCSP/CRL and broad compliance claims | deferred beyond `v2.1` |
| viewer_proof | Signature-specific viewer promotion | unverified until recorded per-viewer evidence exists |
| adapters | Additional signing adapters beyond the first proof-backed path | deferred until demand and proof justify them |
