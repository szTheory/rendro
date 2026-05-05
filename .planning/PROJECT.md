# Rendro

## What This Is

Rendro is a pure-Elixir, Phoenix-first PDF and document generation library for teams that need deterministic, production-grade output without depending on a browser runtime in core. It focuses on predictable layout and pagination for real business artifacts like invoices, statements, certificates, and reporting documents. The primary users are Phoenix SaaS engineers, back-office/reporting engineers, and operators who need trustworthy behavior under production load.

## Core Value

Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components, with clear pagination behavior and production-grade observability.

## Current State

**Shipped Version:** v1.8 Interactive PDF Forms (2026-05-05)

Rendro now supports deterministic authored AcroForm text fields, checkboxes, and radio groups in the core pipeline. The writer emits explicit AcroForm objects and appearance streams, structural proof runs through the Poppler lane, and support claims for forms are constrained to evidence-backed boundaries.

**Previous Shipped Version:** v1.5 Validation and Trust Surfaces (2026-05-05)

Rendro provides validator-backed trust surfaces including the `Poppler` adapter for structural validation and a machine-readable support matrix for clear operational boundaries.

**Previous Shipped Version:** v1.4 Async Delivery and Artifact Operations (2026-05-05)

Rendro ships a queued render lifecycle, artifact metadata, persistence/sink contracts, and optional integrations (`Accrue`, `Mailglass`, `Oban.RenderWorker`) for production async/delivery workflows.

**Foundation Already Shipped:** v1.3 release readiness, v1.2 typography/assets truth, v1.1 layout-authoring maturity, and v1.0 deterministic core rendering.

## Current Milestone: TBD

**Goal:** TBD

**Target features:**
- TBD

## Requirements

### Validated

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

- [ ] No active milestone requirements are defined yet. Start the next milestone before reopening requirement tracking.

### Out of Scope

- HTML/CSS parity or browser-style layout behavior — Rendro remains a deterministic document engine, not a browser renderer.
- WYSIWYG builders, hosted template editing, or app-specific layout hacks in core — they would widen surface area before the authoring contract is stable.
- Render manifests, persistence sinks, and richer async artifact lifecycle contracts — defer to the later async-delivery milestone after first release readiness.
- Blanket PDF/A, PDF/UA, signature, or compliance claims — require validator-backed proof in the later trust/validation arc.
- Remote asset fetching, broad complex-script support, and "supports every language" positioning — defer until the engine has proof surfaces for them.

## Context

Rendro has moved beyond layout-authoring maturity and trust-surface basics into interactive document behavior. `v1.8` proved that authored AcroForm widgets can live inside the same deterministic measure/paginate/render pipeline as static content without widening the support contract beyond what is actually verified.

The next risk is not adding more surface area mechanically; it is preserving truthful operational boundaries as the PDF engine enters higher-trust features such as signatures, encryption, and attachments. Those features need narrow milestone scope and proof-backed claims from day one.

## Constraints

- **Tech stack**: Keep the core pure Elixir with no hard dependency on Phoenix, Oban, browser runtimes, or external layout engines — preserves deterministic deployment and product boundaries.
- **Architecture**: Extend the existing `build -> compose -> measure -> paginate -> render -> validate` pipeline instead of creating an alternate rendering path — one engine must continue to power both APIs.
- **Product scope**: Interactive forms do not imply broad viewer compatibility, XFA support, digital signatures, or compliance claims. Future milestones must keep those boundaries explicit.
- **Determinism**: Widget geometry, appearance generation, and PDF object allocation must remain deterministic for identical authored inputs.
- **Documentation honesty**: Public APIs, guides, and examples must not imply viewer support or form capabilities beyond what `priv/support_matrix.json` and proof lanes cover.
- **Verification**: Merge-blocking, docs-contract, structural-validation, and manual-viewer proof lanes must stay truthful as the PDF feature surface expands.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Reuse one `Rendro.form_field/3` / `%Rendro.FormField{}` authored boundary for all currently supported interactive widgets | Keeps DSL surface area narrow and preserves one normalization path into the core engine | Shipped in v1.8 |
| Generate explicit form appearance streams instead of relying on `NeedAppearances` | Viewer-generated appearances would weaken determinism and create false portability claims | Shipped in v1.8 |
| Publish support boundaries as machine-readable product contract | Viewer and feature claims need one canonical truth source that docs and tests can enforce | Shipped in v1.5 and extended in v1.8 |
| Preserve the core/adapter split even as operational features grow | Keeps Rendro deployable and testable without forcing downstream ecosystem choices | Reinforced across v1.4 through v1.8 |
| Treat verification artifacts as product behavior | Operators need clear proof of what the engine supports and what remains unverified | Reinforced across shipped milestones |

## Archived Milestone Context

<details>
<summary>v1.8 milestone focus before ship</summary>

- Add deterministic authored AcroForm text fields, checkboxes, and radio groups to the core engine.
- Keep validation and PDF serialization on existing pipeline seams rather than creating a parallel forms path.
- Publish truthful forms support boundaries with explicit viewer-proof status.
- Leave signatures, encryption, attachments, and annotations for a future milestone.

</details>

## Evolution Path

- The next milestone should define proof-backed requirements for signatures, encryption, and embedded artifact surfaces before any new implementation begins.
- Viewer support should continue to expand only when manual proof is recorded and reflected in `priv/support_matrix.json`.
- The core deterministic pipeline and optional-adapter boundary remain non-negotiable.

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
*Last updated: 2026-05-05 after v1.8 milestone complete.*
