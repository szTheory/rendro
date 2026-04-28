# Rendro

## What This Is

Rendro is a pure-Elixir, Phoenix-first PDF and document generation library for teams that need deterministic, production-grade output without depending on a browser runtime in core. It focuses on predictable layout and pagination for real business artifacts like invoices, statements, certificates, and reporting documents. The primary users are Phoenix SaaS engineers, back-office/reporting engineers, and operators who need trustworthy behavior under production load.

## Core Value

Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components, with clear pagination behavior and production-grade observability.

## Requirements

### Validated

- [x] Merge-blocking verification is now truthful and executable: `mix ci` covers format, compile, tests, docs, and package build, and `mix verify` separates deterministic vs advisory lanes without early exit. Validated in Phase 12: Verification Chain Closure (`QUAL-01`, `QUAL-03`, `QUAL-05`).

### Active

- [ ] Produce deterministic PDF output from Elixir data with repeatable layout and pagination results.
- [ ] Provide document and layout primitives for pages, blocks, tables, headers/footers, and metadata.
- [ ] Keep the rendering core pure Elixir with no hard dependency on Chrome/Chromium or Phoenix.
- [ ] Support two APIs on one engine: fixed-position composition and flow-based document/report composition.
- [ ] Ship Phoenix integration helpers for preview/download workflows via optional adapters.
- [ ] Expose telemetry events and structured, actionable error surfaces for render lifecycle operations.
- [ ] Deliver v0.1 that makes invoice/report generation viable and testable, prioritizing pagination, tables, and headers/footers.
- [ ] Include strong docs, executable examples, and release hygiene that make adoption and operation trustworthy.

### Out of Scope

- Full HTML/CSS browser-compat rendering — Rendro is not trying to beat browser renderers at browser rendering.
- Arbitrary PDF editing/parsing product scope — early focus is generation, not generalized document manipulation.
- Broad compliance claims (for example PDF/A or PDF/UA) without validator-backed proof — no unverified claims.
- "Complete" digital-signature support before explicit implementation and tests — defer until concrete, proven delivery.

## Context

Rendro is being positioned as a production-ready Elixir-native PDF engine that prioritizes deterministic behavior, composable APIs, and operational trust. The product thesis emphasizes truthful scope boundaries and avoids claiming capabilities that have not been implemented and verified.

Architecture defaults are currently locked: pure `rendro` core, optional adapters for integrations, a data-first pipeline (`build -> compose -> measure -> paginate -> render -> validate`), and two public APIs backed by one engine. Error quality is treated as part of the product: failures should communicate what happened, where, why, and what to try next.

Operational and OSS posture is informed by recent szTheory Elixir library patterns: canonical verify lanes (`mix ci`, `mix verify.*`), docs-contract checks, an example host app in CI, optional dependency gating, package whitelist discipline, source/tag parity checks, and explicit deterministic vs advisory verification semantics.

Integration opportunities are staged by lifecycle instead of hard coupling. Early adapters/recipes prioritize audit trails (`threadline`), transactional attachments (`mailglass`), and billing document workflows (`accrue`), with additional integrations deferred until core stability.

## Constraints

- **Tech stack**: Pure Elixir rendering core with no browser runtime dependency in core — preserves deterministic behavior and deploy simplicity.
- **Architecture**: Core must stay decoupled from Phoenix/jobs/admin tooling — adapters are optional and must not become hidden hard dependencies.
- **Product scope**: Deterministic layout and pagination are first-order priorities — this is the non-negotiable differentiator.
- **Quality**: Merge-blocking verification lanes must remain green (`format`, warnings-as-errors compile, tests, docs build, package build, docs/quickstart contracts) — protects trust in public claims.
- **Release process**: Release parity and dry-run checks are required before/after publish — avoids drift between source, docs, and package artifacts.
- **Honesty**: Compliance and signature claims require validator-backed proof and tests before being documented — prevents deceptive scope expansion.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Use pure Elixir core with optional adapters | Preserve deterministic behavior, deployment portability, and clean boundaries between engine and integrations | — Pending |
| Prioritize pagination, tables, and headers/footers in early milestones | These are essential for meaningful invoice/report use cases, not toy output | — Pending |
| Support two APIs (fixed-position and flow) on one rendering engine | Cover precise placement and report/document workflows without splitting core behavior | — Pending |
| Treat errors and telemetry as first-class product features | Operators need auditability and fast diagnosis to trust PDF generation in production | — Pending |
| Enforce truthful capability claims and defer unverified compliance/signature statements | Trust depends on matching documentation to verified implementation | — Pending |

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
*Last updated: 2026-04-28 after Phase 12 (Verification Chain Closure) completion — hosted CI now truthfully delegates to a canonical `mix ci` lane covering format, compile, tests, docs, and package build; `mix verify` completes deterministic and advisory lanes before a single final exit; closes `QUAL-01`, `QUAL-03`, and `QUAL-05`.*
