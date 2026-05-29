# Rendro

## What This Is

Rendro is a pure-Elixir, Phoenix-first PDF and document generation library for teams that need deterministic, production-grade output without depending on a browser runtime in core. It focuses on predictable layout and pagination for real business artifacts like invoices, statements, certificates, and reporting documents. The primary users are Phoenix SaaS engineers, back-office/reporting engineers, and operators who need trustworthy behavior under production load.

## Core Value

Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components, with clear pagination behavior and production-grade observability.

## Current State

**Active Milestone:** v2.3 Viewer Proof & Interop Closure — Phase 70 complete (2026-05-29): five pre-v2.3 legacy `supported` viewer rows consolidated into canonical `priv/viewer_evidence/` homes with matrix `evidence:` pointers, Tier-B promotion-complete schema enforcement, api_stability STACK mirrors, and zero legacy validation warnings. Six promotion-complete supported rows (including Phase 69 chrome_pdfium); 20 unverified cells remain for Phase 71.

**Shipped Version:** v2.2 Long-Lived Signatures & Compliance Evidence (2026-05-08)

Rendro now supports one proof-backed long-lived-signature path over the shipped cryptographic-signing seam: `Rendro.Sign.augment/2` adds timestamp and revocation evidence over signed artifacts on a separate seam from `sign/2`, the first-party optional pyHanko long-lived adapter provides timestamp and revocation facts without claiming certificate-trust ownership, and `validate/2` reports cryptographic integrity, timestamp presence, revocation evidence presence, and narrow compliance posture as distinct signals. The `long-lived-live-proof` CI lane runs the full `sign → augment → validate` workflow against an offline certomancer-backed PKI/TSA/OCSP fixture and is required on `main`. `priv/support_matrix.json` and `guides/api_stability.md` publish `signing.long_lived` evidence separately from blanket PDF/A claims, signer trust, viewer behavior, and multi-signature workflows, with the `67-VERIFICATION.md` ledger backing the exact supported path.

**Previous Shipped Version:** v2.1 Cryptographic Signing & Signed-Artifact Proof (2026-05-07)

Rendro now supports one proof-backed cryptographic-signing path over the shipped unsigned/preparation seam: `Rendro.Sign.sign/2` signs rendered artifacts, first-party optional pyHanko and pdfsig adapters keep runtime-executable and integrity-vs-trust boundaries explicit, and the live proof lane is both executable and enforced on `main` through the required `signing-live-proof` status check. The public support contract now distinguishes signed-artifact integrity from certificate trust, viewer posture, and deferred compliance narratives, and the closeout trail includes Phase 60-63 verification artifacts for full audit-grade requirement closure.

**Previous Shipped Version:** v2.0 Signature Fields & External Signing Preparation (2026-05-07)

Rendro now supports explicit unsigned signature-field authoring through `Rendro.signature_field/2`, deterministic unsigned `/Sig` widget serialization on the existing AcroForm seam, and artifact-first external-signing preparation through `Rendro.Sign.prepare/2`. The public support contract now names unsigned widgets and signing preparation separately from unsupported digital-signature, viewer-validity, tamper-evidence, and compliance claims, and the closeout trail now includes backfilled Phase 55 and 56 verification artifacts so requirement closure is audit-grade rather than summary-only.

**Previous Shipped Version:** v1.10 Protected Delivery Hooks & Encryption Boundaries (2026-05-06)

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

## Current Milestone: v2.3 Viewer Proof & Interop Closure

**Goal:** Close the trust-sensitive viewer evidence gap surface-by-surface so public support claims for forms, protection, signatures, signing preparation, signed artifacts, and long-lived evidence can be promoted with recorded per-viewer proof rather than deferred under blanket "unverified" rows.

**Target features (planned):**
- Recorded viewer checklists for forms, protection, signature widgets, signing preparation, signed artifacts, and long-lived signed artifacts
- Promotion of `priv/support_matrix.json` viewer rows that have completed evidence; explicit deferral for those that have not
- A documented operator-grade viewer-evidence recipe so future surfaces inherit the same proof discipline

**Why now:** With long-lived signing now proof-backed, the largest remaining trust-and-adoption gap is surface-by-surface viewer evidence. Operators need to know what actually works in Acrobat, Preview, PDFium, and PDF.js before any broader adoption claims grow stronger.

## Strategic Arc

**Active strategic arc:** production-ready trust and adoption

**Planned sequence after v2.3:**
- v2.4 Batteries-Included Workflow & Adoption Closure
- v2.5 Global Text Shaping & Script Support (conditional, only if demand stays strong enough to justify the core investment)

## Requirements

### Validated

- [x] Rendro v2.2 delivered one proof-backed long-lived-signature path over the shipped cryptographic-signing seam: `Rendro.Sign.augment/2` for timestamp and revocation evidence, the first-party optional pyHanko long-lived adapter, validator-backed posture classification with distinct integrity/timestamp/revocation/compliance signals, the offline certomancer-backed `long-lived-live-proof` CI lane (now required on `main`), and a truthful `signing.long_lived` support contract that stays separate from blanket PDF/A claims, signer trust, viewer behavior, and multi-signature workflows. Shipped on 2026-05-08 and archived in `milestones/v2.2-ROADMAP.md` / `milestones/v2.2-REQUIREMENTS.md`.
- [x] Rendro v2.0 delivered unsigned signature-field authoring, deterministic unsigned signature-widget serialization, artifact-first external-signing preparation, truthful signature support language, and backfilled verification artifacts for full audit-grade requirement closure. Shipped on 2026-05-07 and archived in `milestones/v2.0-ROADMAP.md` / `milestones/v2.0-REQUIREMENTS.md`.
- [x] Rendro v1.10 delivered artifact-first password protection, a first-party optional `qpdf` adapter, password-aware structural validation, protected-artifact-safe delivery seams, proof-backed protection support language, and release-ready protection proof. Shipped at exact tag `v0.2.0`.
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
- [x] Rendro v2.1 delivered one proof-backed cryptographic-signing path, first-party optional pyHanko/pdfsig adapters, enforced live proof, and a truthful signed-artifact support contract. Shipped on 2026-05-07 and archived in `milestones/v2.1-ROADMAP.md` / `milestones/v2.1-REQUIREMENTS.md`.

### Active

- [ ] Record proof-backed per-viewer evidence for forms, protection, signature widgets, signing preparation, signed artifacts, and long-lived signed artifacts, and promote `priv/support_matrix.json` rows only where evidence is recorded.
- [ ] Establish a durable, repeatable operator-grade viewer-evidence recipe that future surfaces inherit so viewer-proof discipline does not regress under new feature pressure.
- [ ] Keep viewer claims narrower than blanket "works in every viewer" marketing, blanket compliance narratives, and signer identity trust unless a separate milestone proves them.
- [ ] Preserve the multi-milestone game plan (v2.3 viewer proof → v2.4 adoption closure → conditional v2.5) so the next planning pass can continue from an explicit trust-and-adoption arc instead of reopening strategy from scratch.

### Out of Scope

- HTML/CSS parity or browser-style layout behavior — Rendro remains a deterministic document engine, not a browser renderer.
- WYSIWYG builders, hosted template editing, or app-specific layout hacks in core — they widen surface area before the authoring contract is stable.
- In-core key custody, certificate-store management, HSM orchestration, or signer identity workflows — these belong to optional adapters or external infrastructure.
- Blanket compliance branding, generic “signed PDF works everywhere” positioning, or viewer promotion without recorded evidence — public claims must stay proof-backed and narrow.
- Remote asset fetching, broad complex-script support, and “supports every language” positioning — defer until the engine has proof surfaces and a dedicated milestone for those capabilities.

## Context

Rendro has now shipped four authored PDF surfaces inside one deterministic pipeline (static content v1.0-v1.2, interactive forms v1.8, document-level embedded files v1.9, curated link annotations v1.9) and one full trust-sensitive stack as artifact-first or optional-adapter seams: protection through `Rendro.Protect` (v1.10), unsigned signature preparation through `Rendro.Sign.prepare/2` (v2.0), cryptographic signing through `Rendro.Sign.sign/2` plus first-party optional runtime adapters (v2.1), and long-lived signature augmentation through `Rendro.Sign.augment/2` plus a dedicated long-lived-live-proof CI lane (v2.2). All of this lands without widening the core rendering contract or the deterministic `build → compose → measure → paginate → render → validate` pipeline.

The remaining trust-and-adoption gaps are now visible on every recorded support row: viewers. Rendro's structural validity, signing integrity, and long-lived posture stories are proof-backed end-to-end, but per-viewer behavior across Acrobat, Preview, PDFium, and PDF.js is still mostly carried as `unverified`. Closing that gap is the highest-leverage next step before any batteries-included adoption push, because it is the only thing standing between recorded engine truth and recorded operator-facing truth.

## Constraints

- **Tech stack**: Keep the core pure Elixir with no hard dependency on Phoenix, Oban, browser runtimes, Python packages, or external signing binaries — preserves deterministic deployment and product boundaries.
- **Architecture**: Extend the existing `build -> compose -> measure -> paginate -> render -> validate` pipeline instead of creating an alternate rendering path — one engine must continue to power both APIs.
- **Product scope**: Viewer claims must stay narrower than blanket "works everywhere" positioning, signer identity trust, or broad compliance narratives unless recorded per-viewer evidence and matching `priv/support_matrix.json` rows back the claim.
- **Determinism**: Unsigned render output remains deterministic; signed and long-lived artifacts are intentionally non-deterministic and must be labeled as such rather than hidden behind deterministic claims.
- **Operational safety**: Key paths, passphrases, raw tool stderr, revocation blobs, and signer-specific secrets must stay redacted in errors, metadata, and audit surfaces.
- **Documentation honesty**: Public APIs, guides, and examples must not imply viewer support, trust anchoring, or compliance coverage beyond what `priv/support_matrix.json` and proof lanes cover.
- **Verification**: Merge-blocking, docs-contract, structural-validation, and live-tool proof lanes must stay truthful as the signing surface expands.

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
| Publish support boundaries as machine-readable product contract | Viewer and feature claims need one canonical truth source that docs and tests can enforce | ✓ Shipped in v1.5 and extended in v1.8/v1.9/v2.0/v2.1 |
| Preserve the core/adapter split even as operational features grow | Keeps Rendro deployable and testable without forcing downstream ecosystem choices | ✓ Reinforced across v1.4 through v2.1 |
| Treat verification artifacts as product behavior | Operators need clear proof of what the engine supports and what remains unverified | ✓ Reinforced across shipped milestones |
| `v2.1` proved one narrow cryptographic-signing path before any compliance or long-lived-signature stories | Protected the product contract from widening faster than the evidence lanes could support it | ✓ Shipped in v2.1 |
| `v2.2` added long-lived evidence before broader viewer or adoption expansion | Durable signature evidence was the highest-leverage prerequisite between “we can sign” and “users can trust the signed workflow long term” | ✓ Shipped in v2.2 |
| Long-lived augmentation lives on a separate `Rendro.Sign.augment/2` seam over signed artifacts, not as new options on `Rendro.Sign.sign/2` or new render-time semantics | Keeps signing, augmentation, and validation as three explicit boundaries instead of one widening API | ✓ Shipped in v2.2 |
| Persist long-lived posture under `metadata.long_lived` and adapter-shaped facts under `metadata.long_lived_adapter`, with explicit non-determinism on every augmented artifact | Keeps shared metadata posture-only, isolates tool-shaped data, and forces truthful determinism labeling | ✓ Shipped in v2.2 |
| Use an offline certomancer-backed PKI/TSA/OCSP fixture for the required `long-lived-live-proof` lane | Keeps the operationally enforced proof reproducible without depending on any public PKI/TSA/CRL endpoint | ✓ Shipped in v2.2 |
| Publish long-lived evidence as nested `signing.long_lived` rather than a new top-level family in `priv/support_matrix.json` | Reuses one signing taxonomy and prevents accidental coupling to broad compliance, viewer, or signer-identity rows | ✓ Shipped in v2.2 |
| `v2.3` should close per-viewer evidence before any batteries-included adoption push | Engine-level truth (structure, signing, long-lived) is now proof-backed; per-viewer truth is the next blocker before stronger adoption claims | → Activated for v2.3 planning |

## Archived Milestone Context

<details>
<summary>v2.2 milestone focus before ship</summary>

- Add one truthful long-lived-signature path over the shipped cryptographic-signing seam through `Rendro.Sign.augment/2`.
- Ship a first-party optional long-lived adapter and validator-backed posture classification without coupling certificate trust into the integrity story.
- Prove the supported `sign → augment → validate` path with an offline `long-lived-live-proof` CI lane and require it on `main`.
- Publish long-lived and narrow compliance posture as their own taxonomy, separate from blanket PDF/A claims, signer trust, viewer behavior, and multi-signature workflows.
- Defer broader viewer portability claims, multi-signature workflows, signer-identity orchestration, HSM/key custody in core, and generic regulatory packaging.

</details>

<details>
<summary>v2.1 milestone focus before ship</summary>

- Add one truthful cryptographic-signing path over the shipped unsigned/preparation seam.
- Ship first-party optional signing and signed-artifact validation adapters without widening render-core semantics.
- Prove the supported signed-artifact path in CI and align every public claim to that exact proof.
- Defer long-lived signatures, timestamps, revocation evidence, PAdES/LTV/TSA/OCSP/CRL, and blanket compliance narratives.

</details>

<details>
<summary>v2.0 milestone focus before ship</summary>

- Add unsigned signature-field authoring that fits the existing authored form model truthfully.
- Add deterministic unsigned signature-widget serialization and artifact-first external-signing preparation without changing `Rendro.render/2`.
- Publish support boundaries that distinguish field authoring and preparation from actual digital signatures, viewer validity, and compliance claims.
- Defer cryptographic signing, key custody, PAdES/LTV/TSA/OCSP/CRL, and broad compliance narratives.

</details>

## Evolution Path

- `v2.0` shipped signature preparation through narrow authored fields and external-signing seams, not broad cryptographic or compliance claims.
- `v2.1` added actual cryptographic signing and signed-artifact proof without collapsing integrity, trust, viewer posture, and compliance into one claim.
- `v2.2` shipped timestamp/revocation evidence and a narrow long-lived-signature posture over the proof-backed signing seam, with `long-lived-live-proof` enforced on `main` and `signing.long_lived` published as its own support taxonomy.
- `v2.3` is now activated to close per-viewer evidence across all shipped surfaces, promoting `priv/support_matrix.json` viewer rows only where recorded proof exists.
- The planned follow-on sequence is: batteries-included adoption closure, then global text shaping only if demand keeps justifying the investment.
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
*Last updated: 2026-05-28 after Phase 68 (viewer evidence schema, Mix task, docs-contract lane).*
