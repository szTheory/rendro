# Rendro

## What This Is

Rendro is a pure-Elixir, Phoenix-first PDF and document generation library for teams that need deterministic, production-grade output without depending on a browser runtime in core. It focuses on predictable layout and pagination for real business artifacts like invoices, statements, certificates, and reporting documents. The primary users are Phoenix SaaS engineers, back-office/reporting engineers, and operators who need trustworthy behavior under production load.

## Core Value

Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components, with clear pagination behavior and production-grade observability.

## Current State

**Shipped Version:** v1.1 Layout Authoring Maturity (2026-04-30)

Rendro now has a stable layout-authoring contract on top of the v1.0 engine core. `v1.1` shipped explicit page templates, named regions, reusable sections, deterministic wrapped-text measurement, authored keep/break pagination semantics, truthful fit validation, runtime-consumed table split policy, structured diagnostics/proof surfaces, and canonical invoice/report guidance through recipes and the Phoenix example.

**Previous Shipped Version:** v1.0 MVP (2026-04-28)

`v1.0` proved the core thesis: pure deterministic rendering, baseline layout/pagination, optional adapters, structured errors, and truthful CI/release verification contracts all ship with committed proof.

## Next Milestone Goals

- Add deterministic typography and asset support without weakening the existing layout contract.
- Define truthful support boundaries for custom fonts, fallback chains, image/logo assets, and Unicode/i18n behavior.
- Extend examples and verification proof so new rendering surfaces remain auditable and deterministic.
- Decide whether first public Hex release readiness should be part of the next milestone or remain backlog until more real-world workloads are proven.

## Requirements

### Validated

- [x] Merge-blocking verification is now truthful and executable: `mix ci` covers format, compile, tests, docs, and package build, and `mix verify` separates deterministic vs advisory lanes without early exit. Validated in Phase 12: Verification Chain Closure (`QUAL-01`, `QUAL-03`, `QUAL-05`).
- [x] Deterministic CI gate regression is fixed and traceability state perfectly mirrors the true gate status. Validated in Phase 17: Deterministic CI Gate Recovery Traceability Resync (`QUAL-01`).
- [x] Rendro v1.0 proved pure-core rendering, baseline layout primitives, optional adapters, and truthful operational verification as a shippable MVP. Validated at milestone close in `v1.0-REQUIREMENTS.md`.
- [x] Rendro v1.1 proved layout-authoring maturity with explicit templates/regions, deterministic wrapped text, keep/break pagination semantics, truthful fit validation, stronger table continuation, diagnostics proof, and canonical recipes. Validated at milestone close in `v1.1-REQUIREMENTS.md`.

### Active

- [ ] No active milestone requirements yet. Define the next milestone with `$gsd-new-milestone`.

### Out of Scope

- HTML/CSS parity or browser-style layout behavior — Rendro remains a deterministic document engine, not a browser renderer.
- WYSIWYG builders, hosted template editing, or app-specific layout hacks in core — they would widen surface area before the authoring contract is stable.
- Render manifests, persistence sinks, and richer async artifact lifecycle contracts — defer to a later async-delivery milestone.
- Blanket PDF/A, PDF/UA, signature, or compliance claims — require validator-backed proof in the later trust/validation arc.

## Context

Rendro's next challenge is no longer core authoring depth; it is rendering breadth without losing trust. The codebase now has stable layout semantics and proof surfaces, which means typography, assets, and broader public packaging can be tackled on top of a stronger base. The risk has shifted from missing author intent to overclaiming what the engine supports once fonts, fallback chains, logos, and wider release expectations enter the picture.

That makes the next milestone a boundary-setting exercise as much as an implementation milestone. Font and asset work must preserve deterministic measurement and truthful diagnostics. A public Hex release should follow that proof, not substitute for it.

## Constraints

- **Tech stack**: Keep the core pure Elixir with no hard dependency on Phoenix, Oban, browser runtimes, or external layout engines — preserves deterministic deployment and product boundaries.
- **Architecture**: Extend the existing `build -> compose -> measure -> paginate -> render -> validate` pipeline instead of creating an alternate rendering path — one engine must continue to power both APIs.
- **Product scope**: v1.1 is an authoring-contract milestone, not a typography/assets or async-ops milestone — later milestones depend on a stable layout core.
- **Determinism**: New layout semantics must remain deterministic and fixture-verifiable — pagination decisions cannot become heuristic or time/environment dependent.
- **Documentation honesty**: Public API fields and examples must not imply support that the writer/layout engine does not actually honor.
- **Verification**: Merge-blocking and docs-contract proof lanes must stay truthful while pagination semantics become more complex.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Make v1.1 a layout-authoring milestone before fonts/assets or async expansion | The current adoption gap was authoring depth, and later milestones depend on stable layout contracts | Shipped in v1.1 |
| Add first-class break semantics instead of hiding pagination policy in ad hoc block behavior | Business documents need explicit author intent for page breaks and content grouping | Shipped in v1.1 |
| Introduce reusable page templates/sections/regions for flow documents | Fonts, assets, headers/footers, and diagnostics need stable placement surfaces | Shipped in v1.1 |
| Treat break explanations, diagnostics, and verification artifacts as product behavior | Operators and adopters need to understand why a document split or overflowed | Shipped in v1.1 |
| Defer first public Hex release until support boundaries are battle-tested | Packaging ability alone is not the release bar for this library | Backlog (`Phase 999.1`) |

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
*Last updated: 2026-04-30 after v1.1 milestone close.*
