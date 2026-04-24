# Project Research Summary

**Project:** Rendro
**Domain:** Elixir-native PDF/document generation library
**Researched:** 2026-04-24
**Confidence:** HIGH

## Executive Summary

Rendro should be built as a native Elixir document engine with deterministic layout behavior, explicit pagination control, and production-grade observability as first-class product features. The strongest position is not "PDF generation exists," but "native, auditable, deterministic PDF generation that is operationally trustworthy for Phoenix teams without a browser runtime in core."

Research indicates the biggest execution risks are scope drift (HTML/CSS parity pressure), pagination underinvestment, and trust erosion from unverified claims. The architecture should therefore lock core boundaries early, prioritize layout/pagination primitives in the first meaningful release, and enforce docs/release truthfulness with contract checks and deterministic verification lanes.

The recommended roadmap sequence is: core deterministic engine first, pagination/table behavior second, adapter boundaries and operational integration third, and release/docs/integration hardening after those fundamentals are stable.

## Key Findings

### Recommended Stack

Rendro should target current stable Elixir/OTP and use optional adapters for web/jobs integrations. Telemetry and deterministic testing infrastructure are mandatory for the core value proposition.

**Core technologies:**
- Elixir 1.19.5 + OTP 28: pure core runtime baseline
- Telemetry 1.4.1: lifecycle observability contract
- Phoenix 1.8.5 (optional adapter): adoption path for Phoenix teams
- Oban 2.21.1 (optional adapter): bounded async rendering and retries

### Expected Features

Research confirms that early users expect deterministic core rendering, reliable pagination for large tables/reports, and operationally useful error/telemetry output.

**Must have (table stakes):**
- Deterministic pure-Elixir render path with no Chrome dependency in core
- Automatic pagination with repeating table headers and robust headers/footers
- Structured errors and telemetry lifecycle instrumentation
- Optional Phoenix integration helpers
- CI-backed docs/quality/release contract

**Should have (competitive):**
- Two APIs (fixed + flow) over one engine
- Strict optional-adapter boundaries and package hygiene
- Validation hook architecture and truth-first support matrix

**Defer (v2+):**
- Broad compliance claims, full digital signatures, and broad strategic integrations until validator-backed evidence and stable core maturity

### Architecture Approach

Use a data-first pipeline (`build -> compose -> measure -> paginate -> render -> validate`) with immutable intermediate representations. Keep adapter modules/packages optional and downstream from core. Treat pagination/table logic and observability/error quality as core engine concerns, not adapter concerns.

**Major components:**
1. Composition + document AST layer — captures intent as Elixir data.
2. Layout/pagination engine — deterministic placement, overflow management, table behavior.
3. Renderer/serializer + validation hooks — artifact generation, policy bounds, diagnostics.

### Critical Pitfalls

1. **Scope drift to browser rendering** — prevent with explicit support boundaries and adapter-only HTML paths.
2. **Pagination as a deferred concern** — avoid by making it a first-order success criterion in early phases.
3. **Optional dependency leakage** — isolate integrations and enforce compile/runtime guards.
4. **Unverified capability claims** — enforce docs-contract and release gates before publishing.
5. **Weak observability/error ergonomics** — require structured telemetry and actionable errors from earliest milestones.

## Implications for Roadmap

Based on research, suggested phase structure:

### Phase 1: Core Deterministic Foundation
**Rationale:** Pure-core boundary and deterministic contract are non-negotiable and unblock all downstream phases.
**Delivers:** Document model, rendering skeleton, deterministic mode, telemetry/error schema.
**Addresses:** Core architecture defaults and trust posture.
**Avoids:** Scope/coupling drift and flaky artifact behavior.

### Phase 2: Layout and Pagination Engine
**Rationale:** Real-world invoice/report viability depends on robust pagination and table behavior.
**Delivers:** Measure/flow/paginate pipeline, multi-page tables, headers/footers, overflow diagnostics.
**Uses:** Core rendering and deterministic foundation from Phase 1.
**Implements:** Layout and pagination architecture components.

### Phase 3: Optional Adapters and Operational Integration
**Rationale:** Phoenix/operator value lands after core layout is trustworthy.
**Delivers:** Phoenix helper adapter, optional Oban/job patterns, execution policy bounds, adapter boundary enforcement.
**Addresses:** Production adoption and operations personas.

### Phase 4: Quality, Documentation, and Release Hardening
**Rationale:** Trustworthiness is sustained by explicit verification and truthful docs/release discipline.
**Delivers:** `mix ci`/`mix verify.*` lanes, docs-contract tests, example host app CI, release parity checks.
**Avoids:** Claim drift and unstable release quality.

### Phase 5: Early Ecosystem Recipes
**Rationale:** `threadline`, `mailglass`, and `accrue` are high-value "Do Now" integrations once interfaces stabilize.
**Delivers:** Optional recipe/adapters and integration verification patterns.
**Uses:** Stable core + adapter contracts + quality gates from earlier phases.

### Phase Ordering Rationale

- Deterministic core and boundaries must precede layout scale features.
- Pagination/table correctness must precede adapter adoption and integration promotion.
- Quality/release contract should harden once capabilities exist and before broad ecosystem messaging.
- Integration recipes should land only after core and adapter boundaries are proven stable.

### Research Flags

Phases likely needing deeper research during planning:
- **Phase 2:** pagination edge-case strategy (row splitting, keep-with-next, overflow policies)
- **Phase 3:** policy defaults for bounded execution under mixed workloads
- **Phase 5:** adapter contract shape for each integration without hidden coupling

Phases with standard patterns (skip research-phase):
- **Phase 1:** core package boundaries and deterministic testing lanes are well-established
- **Phase 4:** CI/docs/release hygiene patterns have strong precedent from related OSS libraries

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Core and tooling choices validated by official ecosystem sources and current versions. |
| Features | HIGH | Strong alignment between seed brief, domain research, and target persona JTBDs. |
| Architecture | HIGH | Data-first, pure-core + optional adapters is internally consistent and precedent-backed. |
| Pitfalls | HIGH | Risks are concrete, recurring in related projects, and map cleanly to phase prevention. |

**Overall confidence:** HIGH

### Gaps to Address

- Font shaping/deep i18n specifics (beyond baseline path) should be explicitly scoped in later phase planning.
- Validation adapter depth (qpdf/veraPDF/mutool responsibilities) needs phase-level acceptance criteria.
- Artifact storage and retention policy defaults need product-level decisions during planning.

## Sources

### Primary (HIGH confidence)
- `prompts/rendro-gsd-seed.md`
- `prompts/elixir-native-pdf-generation-oss-lib-deep-research.md`
- `prompts/rendro-oss-dna.md`
- `prompts/rendro-integration-opportunities.md`
- [Elixir current version](https://elixir.current-version.com/)
- [Phoenix versions on Hex](https://hex.pm/packages/phoenix/versions)
- [Oban versions on Hex](https://hex.pm/packages/oban/versions)
- [Telemetry versions on Hex](https://hex.pm/packages/telemetry/versions)

### Secondary (MEDIUM confidence)
- [ExDoc versions on Hex](https://hex.pm/packages/ex_doc/versions)
- [Credo versions on Hex](https://hex.pm/packages/credo/versions)
- [Dialyxir versions on Hex](https://hex.pm/packages/dialyxir/versions)
- [StreamData versions on Hex](https://hex.pm/packages/stream_data/versions)

### Tertiary (LOW confidence)
- None.

---
*Research completed: 2026-04-24*
*Ready for roadmap: yes*
