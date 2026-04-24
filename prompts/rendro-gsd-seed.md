# Rendro GSD Seed

Use this document as the source brief for `/gsd-new-project --auto`.

## Project

- **Name:** Rendro
- **Tagline:** Native PDF layout for Elixir.
- **One-line goal:** Build a pure-Elixir, Phoenix-first PDF/document generation library that is production-ready without requiring Chrome/Chromium runtime in core.

## Core value (non-negotiable)

Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components, with clear pagination behavior and production-grade observability.

If this fails, the project fails.

## Product thesis

Rendro should win on:
- deterministic layout and pagination
- clear, composable Elixir APIs
- operational trust (telemetry, validation hooks, bounded execution)
- truthful scope boundaries

Rendro should not try to beat browser renderers at browser rendering.

## Primary personas and JTBD

1. **Phoenix SaaS engineer**
- JTBD: generate invoices, receipts, statements, certificates, and operational docs with minimal setup.

2. **Back-office/reporting engineer**
- JTBD: render large tables/reports with predictable page breaks and repeatable layout.

3. **Ops/SRE and maintainers**
- JTBD: operate PDF generation safely at scale, diagnose failures quickly, and trust release quality.

## Scope boundaries

### In-scope for early versions

- Pure-Elixir core rendering pipeline.
- Document/layout primitives (pages, blocks, tables, headers/footers, metadata).
- Deterministic mode for tests and fixtures.
- Phoenix integration helpers (download/preview-friendly adapter layer).
- Telemetry events and structured error surfaces.
- Strong docs + examples + CI/release hygiene.

### Explicitly out of scope (until later)

- Full HTML/CSS renderer compatibility.
- Arbitrary PDF editing/parsing product.
- Broad compliance claims (PDF/A, PDF/UA) before validator-backed proof.
- Digital signature "complete support" before explicit implementation and tests.

## Architecture defaults (locked unless explicitly changed)

1. **Core is pure**
- `rendro` core has no hard dependency on Phoenix/Oban/admin tooling.

2. **Adapters are optional**
- Phoenix, jobs, validation, and ecosystem bridges live in optional adapters.

3. **Data-first pipeline**
- Build -> compose -> measure -> paginate -> render -> validate.

4. **Two APIs, one engine**
- Fixed-position API for exact placement use cases.
- Flow API for document/report use cases.

5. **Errors are product**
- Every major failure should say what happened, where, why, and what to try next.

## OSS DNA defaults (from recent szTheory Elixir libraries)

Adopt these from day one:

- Canonical verify lanes (`mix ci`, `mix verify.*`) and explicit release preflight.
- Docs-contract tests to lock public claims and quickstart behavior.
- Example host app tested in CI as executable adoption proof.
- Optional dependency gating (`optional: true` + compile/runtime guards).
- Strict package whitelists and source-ref tag parity for docs.
- Explicit deterministic vs advisory verification lanes.
- Manual milestone-close fallback process (do not depend on one close command).

Reference synthesis:
- `prompts/rendro-oss-dna.md`

## Integration opportunities (decision map)

Use this as lifecycle guidance, not hard coupling:

### Do Now (early adapters/recipes)
- `threadline`: audit trail adapter for template/render lifecycle events.
- `mailglass`: transactional email attachment recipe/adapter for rendered docs.
- `accrue`: invoice/statement integration recipe.

### Soon (after core stabilizes)
- `rulestead`: rollout/feature flags for renderer behavior.
- `sigra`: admin auth/MFA patterns for any operator UI.
- `lattice_stripe`: Stripe-focused billing/payment document recipes.

### Track (strategic adjacency)
- `lockspire`: OAuth/OIDC surface for future API use cases.
- `scrypath`: searchable render/template artifact indexing.
- `kiln`: autonomous fixture/regression generation loops.

Detailed matrix:
- `prompts/rendro-integration-opportunities.md`

## Quality and release posture

### Merge-blocking checks
- format
- compile with warnings-as-errors
- tests
- docs build
- package build
- docs/quickstart contract checks

### Release gates
- version/tag parity checks
- publish dry-run before publish
- release parity checks after publish

### Verification semantics
- deterministic lanes are required for merge
- provider/live/advisory lanes are labeled and non-deceptive

## Initial delivery strategy

Build for a meaningful first use case, not a toy writer:
- v0.1 should make invoice/report generation viable and testable.
- Pagination, tables, and headers/footers are first-order.
- Include one Phoenix example app and one production-checklist guide.

## Lifecycle decision hooks (revisit at each milestone)

1. Are we preserving pure-core boundaries?
2. Did we add any unverified claims to README/docs?
3. Are deterministic and advisory lanes still clearly separated?
4. Did a new integration create hidden hard coupling?
5. Are requirements traceability and verification artifacts current?

## Source context

Primary research and brand direction:
- `prompts/elixir-native-pdf-generation-oss-lib-deep-research.md`
- `prompts/Rendro Brand Book.txt`

Cross-library engineering DNA:
- `prompts/rendro-oss-dna.md`

Integration prioritization:
- `prompts/rendro-integration-opportunities.md`

## Fresh-window bootstrap command

Use this in a clean context window:

```text
/clear
/gsd-new-project --auto @prompts/rendro-gsd-seed.md
```

Fallback interactive path:

```text
/clear
/gsd-new-project
```

Then paste the core sections from this file if prompted.
