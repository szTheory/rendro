# Rendro

## What This Is

Rendro is a pure-Elixir, Phoenix-first PDF and document generation library for teams that need deterministic, production-grade output without depending on a browser runtime in core. It focuses on predictable layout and pagination for real business artifacts like invoices, statements, certificates, and reporting documents. The primary users are Phoenix SaaS engineers, back-office/reporting engineers, and operators who need trustworthy behavior under production load.

## Core Value

Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components, with clear pagination behavior and production-grade observability.

## Current State

**Shipped Version:** v1.0 (MVP)
The v1.0 milestone proved the core thesis: pure deterministic rendering, robust baseline layout/pagination, Phoenix integration helpers, pipeline telemetry, structured errors, and truthful CI/release verification contracts are all now shipped with committed proof.

**v1.1 in flight — Phase 22 complete:** Canonical recipes (`Rendro.Recipes.Invoice`) now compose documents through the new pipeable builder API (`Rendro.Document.new |> add_template |> set_template |> add_section`) and the Tiered Composition pattern (`document/2`, `page_template/1`, `sections/2`). The `Rendro.Adapters.Accrue` adapter and the Phoenix example controller adopt explicit `:header`/`:body`/`:footer` regions, eliminating the legacy `header:`/`footer:` kwargs from primary guidance. README leads adopters with the builder API + Tiered Composition; legacy kwargs are demoted to a backward-compat note.

## Current Milestone: v1.1 Layout Authoring Maturity

**Goal:** Turn Rendro from a credible PDF engine into a credible document authoring base by making layout semantics, pagination behavior, and break diagnostics expressive enough for serious business documents.

**Target features:**
- First-class break semantics such as `keep_together`, `keep_with_next`, and explicit break directives.
- Reusable page templates, sections, and bounded layout regions for flow documents.
- Deterministic width-aware text measurement and flow-page geometry instead of hard-coded layout assumptions.
- Richer table sizing and pagination behavior with row integrity, repeated headers, and explicit split policy.
- Truthful fixed-position fit validation and operator-facing break diagnostics.
- Canonical recipes/examples that demonstrate the new authoring surface without app-specific pagination glue.

## Requirements

### Validated

- [x] Merge-blocking verification is now truthful and executable: `mix ci` covers format, compile, tests, docs, and package build, and `mix verify` separates deterministic vs advisory lanes without early exit. Validated in Phase 12: Verification Chain Closure (`QUAL-01`, `QUAL-03`, `QUAL-05`).
- [x] Deterministic CI gate regression is fixed and traceability state perfectly mirrors the true gate status. Validated in Phase 17: Deterministic CI Gate Recovery Traceability Resync (`QUAL-01`).
- [x] Rendro v1.0 proved pure-core rendering, baseline layout primitives, optional adapters, and truthful operational verification as a shippable MVP. Validated at milestone close in `v1.0-REQUIREMENTS.md`.

### Active

- [ ] Engineers can author wrapped, width-constrained flow text with deterministic line-breaking behavior.
- [ ] Engineers can define reusable page templates, sections, and layout regions instead of relying on a single default flow page.
- [ ] Engineers can control pagination explicitly through keep/break directives and stable overflow semantics.
- [ ] Engineers can render serious multi-page tables with deterministic sizing and row-split behavior.
- [ ] Operators can see why a block moved, split, or overflowed through structured diagnostics and telemetry.
- [ ] Maintainers can prove pagination invariants with deterministic regression fixtures that remain stable as later milestones add fonts, assets, and async workflows.

### Out of Scope

- HTML/CSS parity or browser-style layout behavior — Rendro remains a deterministic document engine, not a browser renderer.
- WYSIWYG builders, hosted template editing, or app-specific layout hacks in core — they would widen surface area before the authoring contract is stable.
- Custom font embedding, fallback chains, image/logo rendering, and broad Unicode/i18n claims — defer to the planned v1.2 typography/assets milestone.
- Render manifests, persistence sinks, and richer async artifact lifecycle contracts — defer to the planned v1.3 async-delivery milestone.
- Blanket PDF/A, PDF/UA, signature, or compliance claims — require validator-backed proof in the later trust/validation arc.

## Context

Rendro's post-v1.0 challenge is no longer engine credibility; it is authoring depth. The shipped core proves that deterministic Elixir-native PDF generation works, but the current authoring model is still narrow: flow layout is mostly vertical block stacking, tables rely on fixed constants, flow pagination uses a default page template, and break behavior is not yet expressed as first-class document intent.

That makes v1.1 the structural milestone for the rest of the epic. v1.2 needs stable measurement and layout-region contracts before fonts/assets can change metrics safely. v1.3 needs stable post-pagination structure and diagnostics before async artifact workflows can expose meaningful manifests or lifecycle metadata. If v1.1 cuts corners here, later milestones will be layering typography and operations on top of unstable pagination semantics.

The codebase evidence is clear about the current gaps: `Rendro.Block`, `Rendro.Table`, `Rendro.Document`, and `Rendro.Page` expose only a thin authoring surface; `Rendro.Pipeline.Measure` still uses single-font and fixed-row assumptions; `Rendro.Pipeline.Paginate` depends on a default `%Rendro.Page{}` template and simplistic split logic; and several public API fields imply more than the engine currently honors (`Text.font`, `Table.width`, `Table.border`, and footer region semantics).

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
| Make v1.1 a layout-authoring milestone before fonts/assets or async expansion | The current adoption gap is authoring depth, and both v1.2 and v1.3 depend on stable layout contracts | — Pending |
| Add first-class break semantics instead of hiding pagination policy in ad hoc block behavior | Business documents need explicit author intent for page breaks and content grouping | — Pending |
| Introduce reusable page templates/sections/regions for flow documents | Fonts, assets, headers/footers, and diagnostics all need stable placement surfaces | — Pending |
| Refactor measurement/pagination around deterministic measured-layout contracts | Hard-coded constants cannot support future typography or trustworthy diagnostics | — Pending |
| Treat break explanations as product behavior, not debug leftovers | Operators and adopters need to understand why a document split or overflowed | — Pending |

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
*Last updated: 2026-04-30 after Phase 22 (Authoring Ergonomics and Canonical Recipes) closed LAY-12.*
