# Rendro

## What This Is

Rendro is a pure-Elixir, Phoenix-first PDF and document generation library for teams that need deterministic, production-grade output without depending on a browser runtime in core. It focuses on predictable layout and pagination for real business artifacts like invoices, statements, certificates, and reporting documents. The primary users are Phoenix SaaS engineers, back-office/reporting engineers, and operators who need trustworthy behavior under production load.

## Core Value

Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components, with clear pagination behavior and production-grade observability.

## Current State

**Shipped Version:** v1.10 Protected Delivery Hooks & Encryption Boundaries (2026-05-06)

Rendro now supports artifact-first password-to-open protection through `Rendro.Protect` and the first-party optional `qpdf` adapter, with AES-256-only public semantics, password-safe error/audit boundaries, password-aware Poppler structural validation, proof-backed Apple Preview support for the `protection` surface, and release-readiness gates that keep the canonical protected-delivery recipe truthful.

**Previous Shipped Version:** v1.9 Embedded Artifact Surfaces (2026-05-06)

Rendro supports document-level embedded files with explicit, deterministic metadata and curated link annotations limited to `http`/`https` URIs and in-document page targets. The writer emits deterministic `/EmbeddedFile`, `/Filespec`, `/Names`, and `/AF` catalog wiring and serializes `/Link` annotations through the existing page `/Annots` seam without named destinations or generic action dictionaries. Public claims are backed by structural proof through Poppler and recorded manual viewer evidence in Adobe Acrobat Reader and Apple Preview.

**Previous Shipped Version:** v1.8 Interactive PDF Forms (2026-05-05)

Rendro supports deterministic authored AcroForm text fields, checkboxes, and radio groups in the core pipeline with explicit appearance streams and proof-backed forms support boundaries.

**Previous Shipped Version:** v1.5 Validation and Trust Surfaces (2026-05-05)

Rendro provides validator-backed trust surfaces including the `Poppler` adapter for structural validation and a machine-readable support matrix for clear operational boundaries.

**Previous Shipped Version:** v1.4 Async Delivery and Artifact Operations (2026-05-05)

Rendro ships a queued render lifecycle, artifact metadata, persistence/sink contracts, and optional integrations (`Accrue`, `Mailglass`, `Oban.RenderWorker`) for production async/delivery workflows.

**Foundation Already Shipped:** v1.3 release readiness, v1.2 typography/assets truth, v1.1 layout-authoring maturity, and v1.0 deterministic core rendering.

## Current Milestone

No milestone is active right now. `v1.10` is shipped and verified; the next milestone should be defined fresh before more scoped implementation work begins.

## Next Milestone Goals

**Next candidate:** v2.0 Signature Fields & External Signing Preparation

**Direction:**
- Add unsigned signature-field authoring only if it fits the existing authored-form model truthfully.
- Add deterministic preparation seams for external signing without claiming in-core cryptographic trust.
- Keep PAdES/LTV/TSA/OCSP/CRL and broad compliance claims deferred until a separately-bounded proof-backed milestone.

## Requirements

### Validated

- [x] Rendro v1.10 delivered artifact-first password protection, a first-party optional `qpdf` adapter, password-aware structural validation, protected-artifact-safe delivery seams, proof-backed protection support language, and release-ready protection proof. Shipped at exact tag `v0.1.0`.
- [x] Rendro v1.9 delivered deterministic authored document-level embedded files and curated link annotations (`http`/`https` URIs and in-document page targets only), with one proof-backed support contract published across `priv/support_matrix.json` and `guides/api_stability.md`, structural proof through the Poppler lane, and recorded manual viewer evidence in Adobe Acrobat Reader (both surfaces) and Apple Preview (links). Validated at milestone close in `v1.9-MILESTONE-AUDIT.md`.
- [x] Rendro v1.8 delivered deterministic authored interactive PDF forms for text fields, checkboxes, and radio groups, along with truthful forms support boundaries. Validated at milestone close in `v1.8-MILESTONE-AUDIT.md`.
- [x] Rendro v1.5 delivered validator-backed trust surfaces, structural validation, and a machine-readable support matrix. Validated at milestone close in `v1.5-MILESTONE-AUDIT.md`.
- [x] Rendro v1.4 delivered Async Delivery and Artifact Operations, including a queued render lifecycle, artifact metadata, and persistence/sink contracts. Validated at milestone close in `v1.4-MILESTONE-AUDIT.md`.
- [x] Rendro v1.2 delivered deterministic typography, assets, and honest Unicode boundaries. Validated at milestone close in `v1.2-REQUIREMENTS.md`.
- [x] Rendro v1.3 delivered first public hex release readiness. Validated at milestone close in `v1.3-REQUIREMENTS.md`.
- [x] Merge-blocking verification is now truthful and executable: `mix ci` covers format, compile, tests, docs, and package build, and `mix verify` separates deterministic vs advisory lanes without early exit. Validated in Phase 12: Verification Chain Closure (`QUAL-01`, `QUAL-03`, `QUAL-05`).
- [x] Deterministic CI gate regression is fixed and traceability state perfectly mirrors the true gate status. Validated in Phase 17: Deterministic CI Gate Recovery Traceability Resync (`QUAL-01`).
- [x] Rendro v1.0 proved pure-core rendering, baseline layout primitives, optional adapters, and truthful operational verification as a shippable MVP. Validated at milestone close in `v1.0-REQUIREMENTS.md`.
- [x] Rendro v1.1 proved layout-authoring maturity with explicit templates/regions, deterministic wrapped text, keep/break pagination semantics, truthful fit validation, stronger table continuation, diagnostics proof, and canonical recipes. Validated at milestone close in `v1.1-REQUIREMENTS.md`.

### Active

- [ ] Define the next milestone through fresh context, requirements, and roadmap artifacts before starting new implementation work.
- [ ] Keep signing preparation narrower than cryptographic signing claims when `v2.0` is scoped.
- [ ] Continue expanding viewer support only through recorded proof and support-matrix promotion.

### Out of Scope

- HTML/CSS parity or browser-style layout behavior — Rendro remains a deterministic document engine, not a browser renderer.
- WYSIWYG builders, hosted template editing, or app-specific layout hacks in core — they would widen surface area before the authoring contract is stable.
- Render manifests, persistence sinks, and richer async artifact lifecycle contracts — defer to the later async-delivery milestone after first release readiness.
- Blanket PDF/A, PDF/UA, signature, or compliance claims — require validator-backed proof in the later trust/validation arc.
- Remote asset fetching, broad complex-script support, and "supports every language" positioning — defer until the engine has proof surfaces for them.

## Context

Rendro has now shipped four authored PDF surfaces inside one deterministic pipeline: static content (v1.0–v1.2), interactive forms (v1.8), document-level embedded files (v1.9), and curated link annotations (v1.9). `v1.9` proved that the core writer's existing allocation, catalog-injection, and `/Annots` seams can absorb new authored object kinds without creating parallel rendering paths or widening the public contract beyond recorded evidence.

`v1.10` proved that Rendro can expand its trust surfaces without widening the core rendering contract: protection shipped through external hooks first, password-to-open and advisory-permissions claims stayed narrow, and support promotion stayed tied to proof. The next milestone should preserve that pattern by treating signing preparation as a separate trust boundary rather than an incremental extension of protection.

## Constraints

- **Tech stack**: Keep the core pure Elixir with no hard dependency on Phoenix, Oban, browser runtimes, or external layout engines — preserves deterministic deployment and product boundaries.
- **Architecture**: Extend the existing `build -> compose -> measure -> paginate -> render -> validate` pipeline instead of creating an alternate rendering path — one engine must continue to power both APIs.
- **Product scope**: Interactive forms do not imply broad viewer compatibility, XFA support, generic annotations, digital signatures, or compliance claims. Future milestones must keep those boundaries explicit.
- **Determinism**: Widget geometry, appearance generation, and PDF object allocation must remain deterministic for identical authored inputs.
- **Documentation honesty**: Public APIs, guides, and examples must not imply viewer support or form capabilities beyond what `priv/support_matrix.json` and proof lanes cover.
- **Terminology**: Delivery attachments in adapters and embedded files inside PDFs must remain distinct in naming and docs to avoid user confusion.
- **Verification**: Merge-blocking, docs-contract, structural-validation, and manual-viewer proof lanes must stay truthful as the PDF feature surface expands.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Embedded files live on the document in a dedicated registry, not on `metadata.custom` or in writer-owned state | Preserves the registry-backed authored-input pattern and keeps serialization separate from authoring state | ✓ Shipped in v1.9 |
| Embedded-file metadata is validated in `Rendro.Pipeline.Validate` with tuple errors, not registration-time exceptions | Keeps malformed authored state in the standard validate-stage error envelope before writer work begins | ✓ Shipped in v1.9 |
| Embedded files extend the existing writer allocation/build funnel; no inline serializer or separate PDF surface | Preserves one deterministic object-planning seam in the core writer | ✓ Shipped in v1.9 |
| Attachment catalog wiring stays document-level only (`/Names`, `/EmbeddedFiles`, `/AF`); no page-level file-attachment annotations | Matches the phase threat model and prevents generic-annotation scope creep | ✓ Shipped in v1.9 |
| Curated links accept only explicit `uri:` (`http`/`https`) or `page:` targets; no named destinations, no `/GoToR`, no generic actions | Narrowest useful annotation surface that reuses the existing `/Annots` seam without opening a generic review/comment API | ✓ Shipped in v1.9 |
| Hold viewer claims at `unverified` until manual evidence is recorded; promote only proof-backed pairs at milestone close | Keeps the public support contract truthful and auditable; prevents portability overclaims | ✓ Shipped in v1.9 |
| Reuse one `Rendro.form_field/3` / `%Rendro.FormField{}` authored boundary for all currently supported interactive widgets | Keeps DSL surface area narrow and preserves one normalization path into the core engine | ✓ Shipped in v1.8 |
| Generate explicit form appearance streams instead of relying on `NeedAppearances` | Viewer-generated appearances would weaken determinism and create false portability claims | ✓ Shipped in v1.8 |
| Publish support boundaries as machine-readable product contract | Viewer and feature claims need one canonical truth source that docs and tests can enforce | ✓ Shipped in v1.5 and extended in v1.8/v1.9 |
| Preserve the core/adapter split even as operational features grow | Keeps Rendro deployable and testable without forcing downstream ecosystem choices | ✓ Reinforced across v1.4 through v1.9 |
| Treat verification artifacts as product behavior | Operators need clear proof of what the engine supports and what remains unverified | ✓ Reinforced across shipped milestones |

## Archived Milestone Context

<details>
<summary>v1.9 milestone focus before ship</summary>

- Add document-level embedded files with deterministic metadata and validate-stage rejection of ambiguous state.
- Add curated link annotations only — `http`/`https` URIs and in-document page targets — through the existing `/Annots` seam, with no named destinations or generic action dictionaries.
- Publish one proof-backed support contract for the new families across `priv/support_matrix.json` and `guides/api_stability.md`.
- Defer native encryption to v1.10 and digital signatures to v2.0.

</details>

<details>
<summary>v1.8 milestone focus before ship</summary>

- Add deterministic authored AcroForm text fields, checkboxes, and radio groups to the core engine.
- Keep validation and PDF serialization on existing pipeline seams rather than creating a parallel forms path.
- Publish truthful forms support boundaries with explicit viewer-proof status.
- Leave signatures, encryption, attachments, and annotations for a future milestone.

</details>

## Evolution Path

- `v2.0` should introduce signature preparation through narrow authored fields and external-signing seams, not broad cryptographic or compliance claims.
- Signature work should remain a later milestone and should separate unsigned field authoring and external-signing preparation from actual cryptographic-signature claims (PAdES, LTV, TSA/OCSP/CRL stay deferred).
- Viewer support should continue to expand only when manual proof is recorded and reflected in `priv/support_matrix.json` (e.g., promoting Apple Preview × `embedded_files` if a future Preview release surfaces document-level embedded files).
- The core deterministic pipeline and the optional-adapter boundary remain non-negotiable.

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? -> Move to Out of Scope with reason
2. Requirements validated? -> Move to Validated with phase reference
3. New requirements emerged? -> Add to Active
4. Decisions to log? -> Add to Key Decisions
5. "What This Is" still accurate? -> Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check -> still the right priority?
3. Audit Out of Scope -> reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-05-06 after v1.10 milestone close.*
