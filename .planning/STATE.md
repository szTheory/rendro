---
gsd_state_version: 1.0
milestone: v2.3
milestone_name: milestone
status: executing
last_updated: "2026-05-29T00:37:02.588Z"
last_activity: 2026-05-29
progress:
  total_phases: 5
  completed_phases: 3
  total_plans: 9
  completed_plans: 9
  percent: 60
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-07 after v2.2 milestone definition)

**Core value:** Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components, with clear pagination behavior and production-grade observability.
**Current focus:** Phase 70 — consolidate-already-validated-surfaces

## Current Position

Phase: 71
Plan: Not started
Status: Executing Phase 70
Last activity: 2026-05-29
Resume: .planning/phases/70-consolidate-already-validated-surfaces/70-CONTEXT.md

## Milestone Snapshot

- Milestone: `v2.2 Long-Lived Signatures & Compliance Evidence` (shipped and archived on 2026-05-08; see `milestones/v2.2-MILESTONE-AUDIT.md`).
- Previous shipped milestone: `v2.1 Cryptographic Signing & Signed-Artifact Proof` (shipped and archived on 2026-05-07; see `milestones/v2.1-ROADMAP.md`).
- Strategic next-up after `v2.2`: `v2.3 Viewer Proof & Interop Closure`, then `v2.4 Batteries-Included Workflow & Adoption Closure`.

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
- [v2.2 planning]: Prioritize long-lived evidence as the next prerequisite between “can sign” and “production-credible signed workflow,” then follow with viewer-proof and adoption-closure milestones.
- [Phase 64]: Keep long-lived support on one explicit `Rendro.Sign.augment/2` seam over already signed artifacts, with adapter `augment/2` callback validation and redacted `:augment` diagnostics.
- [Phase 64]: Persist shared posture under `metadata.long_lived`, keep tool-shaped facts in `metadata.long_lived_adapter`, and force explicit non-determinism on every augmented artifact.

### Roadmap Evolution

- `v1.9` closed 2026-05-06 as a shipped milestone — embedded artifact surfaces (document-level embedded files + curated links).
- `v1.10` closed 2026-05-06 as a shipped milestone — protected delivery hooks and encryption boundaries (external hooks first, narrow security claims, proof-backed validation before any in-core encryption).
- `v2.0` closed 2026-05-07 as a shipped milestone — unsigned signature authoring, deterministic unsigned widget serialization, artifact-first signing preparation, truthful support boundaries, and verification-backfill closure for Phases 55/56.
- `v2.1` closed 2026-05-07 as a shipped milestone — cryptographic signing and signed-artifact proof over the shipped `v2.0` seam, with enforced proof gates and truthful support boundaries.
- `v2.2` closed 2026-05-08 as a shipped milestone — long-lived signatures and compliance evidence; phases 64–67.
- `v2.3` opened 2026-05-08 as the active milestone — viewer proof and interop closure; phases 68–72; 19 requirements mapped across 5 phases (parallel-safe at 70/71).

### Pending Todos

- Keep the v2.2 implementation artifact-first and proof-backed; do not widen into viewer or blanket compliance claims mid-milestone.
- Preserve the new strategic arc so `v2.3` and `v2.4` planning can start from an explicit game plan instead of reopening milestone selection from scratch.

### Blockers/Concerns

- Long-lived-signature work must not soften the current boundary into implied signer trust, blanket compliance support, or generic “enterprise signing” marketing.
- Viewer promotion for signing, long-lived evidence, and protection remains separately proof-gated; do not smuggle viewer claims into `v2.2`.
- Multi-signature workflows, HSM orchestration, and global text-shaping remain tempting adjacent problems; they should not leak into the active milestone without a deliberate re-scope.

## Deferred Items

Items still deferred or intentionally left outside the active milestone as of 2026-05-07:

| Category | Item | Status |
|----------|------|--------|
| viewer_proof | Apple Preview × `embedded_files` | unverified (viewer-side gap; Rendro authoring is correct per structural lane) |
| viewer_proof | Adobe Acrobat Reader forms checklist (Phase 47) | still unverified — not in `v2.2` scope |
| viewer_proof | Signature-specific viewer promotion | unverified until recorded per-viewer evidence exists |
| adoption | Additional signing or long-lived adapters beyond the first proof-backed path | deferred until demand and proof justify them |
| workflows | Multi-signature workflows and signer orchestration | deferred beyond `v2.2` |
| globalization | Global text shaping, RTL support, and broader script coverage | deferred to a later candidate milestone unless urgency changes |

## Operator Next Steps

- Plan phase 68 with /gsd-plan-phase 68
