# Feature Research

**Domain:** Elixir-native PDF/document generation library
**Researched:** 2026-04-24
**Confidence:** HIGH

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing these = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Pure Elixir render path (no Chrome dependency) | Primary promise and deployment simplifier for target personas | MEDIUM | Must be true in core package and docs. |
| Automatic pagination for flowing content | Report/invoice use cases fail without predictable page breaks | HIGH | Needs deterministic behavior plus overflow diagnostics. |
| Multi-page tables with repeating headers | Back-office/reporting users expect this for real documents | HIGH | First-order requirement for v0.1 viability. |
| Headers/footers with page numbers | Standard for invoices, statements, certificates | MEDIUM | Must work with pagination and page templates. |
| Structured error surfaces | Teams need clear remediation when layout/render fails | MEDIUM | Error payload should include what/where/why/next. |
| Telemetry instrumentation | Ops needs throughput/duration/failure observability in production | MEDIUM | Emit lifecycle events for build/layout/paginate/render/validate. |
| Phoenix integration helpers | Phoenix SaaS engineers expect direct adoption path | MEDIUM | Must remain optional adapter to preserve core purity. |
| Deterministic mode for tests/fixtures | OSS maintainers need reproducible CI and artifact validation | MEDIUM | Stable IDs/order/timestamps in deterministic lane. |

### Differentiators (Competitive Advantage)

Features that set the product apart. Not required, but valuable.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Two APIs on one engine (fixed + flow) | Supports exact-form and report-document use cases without engine fragmentation | MEDIUM | Key product thesis from seed document. |
| Truthful support matrix + docs-contract checks | Builds user trust by aligning docs with verified capability | LOW | Strong adoption and maintainer leverage. |
| Optional adapters with hard boundary guarantees | Encourages ecosystem integration without polluting core | MEDIUM | Protects long-term architecture quality. |
| Validation hooks and conformance lanes | Enterprise users can add PDF quality/compliance checks gradually | MEDIUM | Keep deterministic vs advisory lanes explicit. |
| CI-verified example host app | Makes onboarding executable, not aspirational | MEDIUM | Reduces support load and regressions in docs. |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem good but create problems.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Full HTML/CSS browser parity in core | Familiar templating model | Turns project into browser-emulation scope and breaks core constraints | Keep HTML/Typst/browser paths as optional adapters |
| Broad compliance claims early (PDF/A, PDF/UA) | Sales/positioning pressure | Creates trust/legal risk without validator-backed evidence | Publish explicit "validated vs pending" support matrix |
| "Complete digital signing" in early milestones | Enterprise checkbox appeal | High complexity and validation burden, easy to mis-ship | Provide extension points first, full support later |
| Arbitrary PDF editing/parsing product scope | Perceived feature breadth | Diverts focus from generation reliability and deterministic layout | Stay focused on generation platform in v1 |

## Feature Dependencies

```
Automatic pagination
    └──requires──> Measurement and layout pipeline
                       └──requires──> Deterministic document AST

Multi-page tables ──requires──> Automatic pagination

Phoenix adapter ──enhances──> Core rendering engine

Compliance claims ──conflicts──> "Ship first, validate later" documentation
```

### Dependency Notes

- **Automatic pagination requires measurement pipeline:** Without reliable measurement, page breaks are unstable.
- **Multi-page tables require pagination primitives:** Table headers, row-splitting policy, and overflow strategy depend on pagination correctness.
- **Phoenix adapter enhances core:** It improves adoption but should consume core APIs rather than shape them.
- **Compliance claims conflict with unverified scope:** Claims must trail implementation and validator evidence.

## MVP Definition

### Launch With (v1)

Minimum viable product — what's needed to validate the concept.

- [ ] Deterministic pure-Elixir rendering for invoices/reports (no Chrome runtime in core)
- [ ] Layout primitives (pages, blocks, tables, headers/footers, metadata)
- [ ] Automatic pagination with repeatable behavior and table header repetition
- [ ] Structured errors and telemetry lifecycle events
- [ ] Phoenix integration helpers as optional adapter
- [ ] Merge-blocking quality gates + docs/contracts + example app CI proof

### Add After Validation (v1.x)

Features to add once core is working.

- [ ] Additional adapter recipes (`threadline`, `mailglass`, `accrue`) — after core APIs stabilize
- [ ] Extended layout controls (advanced row splitting, keep-with-next, richer template constructs) — once baseline pagination is trusted
- [ ] Validation adapter hardening (qpdf/veraPDF/mutool pipelines) — after deterministic baseline is stable

### Future Consideration (v2+)

Features to defer until product-market fit is established.

- [ ] Full compliance profile claims with validator-backed test matrix — high rigor required
- [ ] Digital signature end-to-end support — explicit implementation and compatibility testing needed
- [ ] Broader ecosystem integrations (`rulestead`, `sigra`, `lattice_stripe`, `lockspire`, `scrypath`, `kiln`) — stage by demonstrated demand

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Deterministic pure core rendering | HIGH | HIGH | P1 |
| Pagination + table headers/footers | HIGH | HIGH | P1 |
| Structured errors + telemetry | HIGH | MEDIUM | P1 |
| Optional Phoenix adapter | HIGH | MEDIUM | P1 |
| Quality/release contract + example app | HIGH | MEDIUM | P1 |
| Early integration recipes | MEDIUM | MEDIUM | P2 |
| Compliance/signature broad support | MEDIUM | HIGH | P3 |

**Priority key:**
- P1: Must have for launch
- P2: Should have, add when possible
- P3: Nice to have, future consideration

## Competitor Feature Analysis

| Feature | Competitor A | Competitor B | Our Approach |
|---------|--------------|--------------|--------------|
| HTML-to-PDF convenience | ChromicPDF excels via browser runtime | wkhtmltopdf wrappers prioritize HTML templates | Keep optional adapter path, do not make this core identity |
| Native deterministic layout primitives | Existing native efforts show demand but partial coverage | Browser tools often hide pagination internals | Focus on first-class deterministic layout and pagination controls |
| Production observability surfaces | Browser wrappers provide some telemetry | Many libs have weak operational guidance | Treat telemetry/errors/validation as product features from day one |

## Sources

- `prompts/rendro-gsd-seed.md`
- `prompts/elixir-native-pdf-generation-oss-lib-deep-research.md`
- `prompts/rendro-oss-dna.md`
- `prompts/rendro-integration-opportunities.md`

---
*Feature research for: Elixir-native PDF generation*
*Researched: 2026-04-24*
