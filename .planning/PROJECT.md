# Rendro

## What This Is

Rendro is a pure-Elixir, Phoenix-first PDF and document generation library for teams that need deterministic, production-grade output without depending on a browser runtime in core. It focuses on predictable layout and pagination for real business artifacts like invoices, statements, certificates, and reporting documents. The primary users are Phoenix SaaS engineers, back-office/reporting engineers, and operators who need trustworthy behavior under production load.

## Core Value

Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components, with clear pagination behavior and production-grade observability.

## Current State

**Shipped Version:** v1.4 Async Delivery and Artifact Operations (2026-05-05)

Rendro now has a queued render lifecycle, artifact metadata, and persistence/sink contracts. It implements optional integrations (`Accrue`, `Mailglass`, `Oban.RenderWorker`) to power production async/delivery workflows and supports advanced table fragmentation DSL.

**Previous Shipped Version:** v1.3 First Public Hex Release Readiness (2026-05-03)

Rendro now has licensing, metadata, API stability policy, and release preflight mechanics in place.

Rendro now has a stable layout-authoring contract on top of the v1.0 engine core. `v1.1` shipped explicit page templates, named regions, reusable sections, deterministic wrapped-text measurement, authored keep/break pagination semantics, truthful fit validation, runtime-consumed table split policy, structured diagnostics/proof surfaces, and canonical invoice/report guidance through recipes and the Phoenix example.

**Previous Shipped Version:** v1.2 Deterministic Typography (2026-05-03)

`v1.2` delivered typography, assets, and honest Unicode boundaries.

`v1.0` proved the core thesis: pure deterministic rendering, baseline layout/pagination, optional adapters, structured errors, and truthful CI/release verification contracts all ship with committed proof.

## Current Milestone: v1.5 Validation and Trust Surfaces

**Goal:** Strengthen the evidence and support surface around produced PDFs without pretending to offer universal compliance.

**Target features:**
- Optional validator adapters and advisory verification lanes.
- Stronger structural validation and preflight reporting.
- Machine-readable support matrix for validated, experimental, and unsupported surfaces.
- Validation reports that attach cleanly to artifact metadata and release docs.

## Requirements

### Validated

- [x] Rendro v1.4 delivered Async Delivery and Artifact Operations, including a queued render lifecycle, artifact metadata, and persistence/sink contracts. Validated at milestone close in `v1.4-MILESTONE-AUDIT.md`.
- [x] Rendro v1.2 delivered deterministic typography, assets, and honest Unicode boundaries. Validated at milestone close in `v1.2-REQUIREMENTS.md`.
- [x] Rendro v1.3 delivered first public hex release readiness. Validated at milestone close in `v1.3-REQUIREMENTS.md`.

- [x] Merge-blocking verification is now truthful and executable: `mix ci` covers format, compile, tests, docs, and package build, and `mix verify` separates deterministic vs advisory lanes without early exit. Validated in Phase 12: Verification Chain Closure (`QUAL-01`, `QUAL-03`, `QUAL-05`).
- [x] Deterministic CI gate regression is fixed and traceability state perfectly mirrors the true gate status. Validated in Phase 17: Deterministic CI Gate Recovery Traceability Resync (`QUAL-01`).
- [x] Rendro v1.0 proved pure-core rendering, baseline layout primitives, optional adapters, and truthful operational verification as a shippable MVP. Validated at milestone close in `v1.0-REQUIREMENTS.md`.
- [x] Rendro v1.1 proved layout-authoring maturity with explicit templates/regions, deterministic wrapped text, keep/break pagination semantics, truthful fit validation, stronger table continuation, diagnostics proof, and canonical recipes. Validated at milestone close in `v1.1-REQUIREMENTS.md`.

### Active

- [ ] Strengthen the evidence and support surface around produced PDFs.
- [ ] Implement optional validator adapters and advisory verification lanes.
- [ ] Add stronger structural validation and preflight reporting.
- [ ] Provide machine-readable support matrix.

### Out of Scope

- HTML/CSS parity or browser-style layout behavior — Rendro remains a deterministic document engine, not a browser renderer.
- WYSIWYG builders, hosted template editing, or app-specific layout hacks in core — they would widen surface area before the authoring contract is stable.
- Render manifests, persistence sinks, and richer async artifact lifecycle contracts — defer to the later async-delivery milestone after first release readiness.
- Blanket PDF/A, PDF/UA, signature, or compliance claims — require validator-backed proof in the later trust/validation arc.
- Remote asset fetching, broad complex-script support, and "supports every language" positioning — defer until the engine has proof surfaces for them.

## Context

Rendro's next challenge is no longer core authoring depth; it is rendering breadth without losing trust. The codebase now has stable layout semantics and proof surfaces, which means typography and assets can be layered in as the next real adoption surface. The risk has shifted from missing author intent to overclaiming what the engine supports once fonts, fallback chains, logos, and wider Unicode expectations enter the picture.

That makes `v1.2` a boundary-setting capability milestone. Font and asset work must preserve deterministic measurement, pagination truth, and explicit failure semantics. A first public Hex release should follow this proof layer immediately after `v1.2`, not be substituted for it.

## Constraints

- **Tech stack**: Keep the core pure Elixir with no hard dependency on Phoenix, Oban, browser runtimes, or external layout engines — preserves deterministic deployment and product boundaries.
- **Architecture**: Extend the existing `build -> compose -> measure -> paginate -> render -> validate` pipeline instead of creating an alternate rendering path — one engine must continue to power both APIs.
- **Product scope**: `v1.2` is a typography/assets truth milestone, not a browser-layout, remote-asset, or broad internationalization milestone.
- **Determinism**: New measurement, fallback, and asset-placement semantics must remain deterministic and fixture-verifiable — pagination decisions cannot become heuristic or environment dependent.
- **Documentation honesty**: Public APIs, guides, and examples must not imply shaping, RTL, or asset-fetch behavior that the engine does not actually honor.
- **Verification**: Merge-blocking, docs-contract, and example proof lanes must stay truthful while font and asset behavior expands.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Make v1.1 a layout-authoring milestone before fonts/assets or async expansion | The current adoption gap was authoring depth, and later milestones depend on stable layout contracts | Shipped in v1.1 |
| Add first-class break semantics instead of hiding pagination policy in ad hoc block behavior | Business documents need explicit author intent for page breaks and content grouping | Shipped in v1.1 |
| Introduce reusable page templates/sections/regions for flow documents | Fonts, assets, headers/footers, and diagnostics need stable placement surfaces | Shipped in v1.1 |
| Treat break explanations, diagnostics, and verification artifacts as product behavior | Operators and adopters need to understand why a document split or overflowed | Shipped in v1.1 |
| Make v1.2 a typography/assets milestone before public release work | Branded documents and truthful support boundaries are the highest-leverage adoption layer after v1.1 | Active |
| Pull first public Hex release readiness ahead of async artifact operations | A credible first public package depends more on finished branded document support than on richer queued-delivery workflows | Active future arc |
| Defer first public Hex release until support boundaries are battle-tested | Packaging ability alone is not the release bar for this library | Backlog (`Phase 999.1`, targeted for v1.3) |

## Archived Milestone Context

<details>
<summary>v1.1 milestone focus before ship</summary>

- First-class break semantics such as `keep_together`, `keep_with_next`, and explicit break directives.
- Reusable page templates, sections, and bounded layout regions for flow documents.
- Deterministic width-aware text measurement and flow-page geometry instead of hard-coded layout assumptions.
- Richer table sizing and pagination behavior with row integrity, repeated headers, and explicit split policy.
- Truthful fixed-position fit validation and operator-facing break diagnostics.
- Canonical recipes/examples that demonstrate the new authoring surface without app-specific pagination glue.

</details>

## Evolution Path

- `v1.2` focuses on deterministic typography, assets, and honest Unicode/i18n boundaries.
- `v1.3` should promote first public Hex release readiness from backlog into active scope if `v1.2` closes truthfully.
- `v1.4` should tackle async delivery and artifact operations after the public release boundary is defined.
- `v1.5` should strengthen validator-backed trust surfaces and support-matrix evidence.

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
*Last updated: 2026-05-03 after v1.3 milestone complete.*
