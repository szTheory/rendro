---
phase: 114-domain-research-reader-quality-rubric-realistic-example-data
plan: 03
subsystem: testing
tags: [json-schema, jsv, fixtures, decimal, money, bench, docs-contract]

# Dependency graph
requires:
  - phase: 114-01
    provides: de-quarantined invoice fixture (priv/examples/invoice/acme-phoenix-saas/invoice.json) + repointed bench consumers
  - phase: 114-02
    provides: priv/schemas/examples.schema.json (money-string JSON Schema)
provides:
  - Normalized invoice fixture with Decimal-safe string money fields (price/subtotal/tax/total)
  - S4 optional empty brand/logo slot on the invoice fixture
  - Four bench consumer scripts adapted to the string money format (byte-identical Rendro render)
  - Automated schema-validation lane (test/docs_contract/examples_schema_contract_test.exs)
affects: [114-04, 114-05, 114-06, 114-07, invoice-anatomy, format-promotion, new-families]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Money-as-strings: fixtures encode currency as fixed 2-decimal strings, never JSON floats or cents-integers"
    - "Docs-contract validation: inline JSV.build!/1 + JSV.validate/2 over a Path.wildcard fixture loop, no bespoke Validator module"
    - "S4 brand/logo seam: present-but-empty optional slot reserved on every fixture"

key-files:
  created:
    - test/docs_contract/examples_schema_contract_test.exs
  modified:
    - priv/examples/invoice/acme-phoenix-saas/invoice.json
    - bench/comparison/fixtures/invoice_rendro.exs
    - bench/comparison/fixtures/invoice_typst.typ
    - bench/comparison/fixtures/invoice_pdf_generator.html.eex
    - bench/comparison/fixtures/invoice_chromic_pdf.html.eex

key-decisions:
  - "Money normalization committed SEPARATELY from Plan 114-01's verbatim move (per RESEARCH.md Pitfall 6)"
  - "invoice_rendro.exs derives the identical integer price via Decimal.new(item[\"price\"]) |> Decimal.to_integer() to preserve the toy-call byte-identical render — Decimal/Rendro.Format.money wiring is Phase 115's job, not this phase"
  - "The two comparator-only .eex dev scripts simplified from :erlang.float_to_binary(cents/100) to the pre-formatted string — no behavior change"

patterns-established:
  - "Money-as-strings fixture convention (EXL-01)"
  - "Fixture schema-contract test loop guarding against a silently-empty wildcard (EXL-03)"

requirements-completed: [EXL-01, EXL-03, EXL-06]

coverage:
  - id: D1
    description: "Invoice fixture money normalized to Decimal-safe 2-decimal strings (zero _cents fields), byte-identical Rendro render"
    requirement: "EXL-01"
    verification:
      - kind: integration
        ref: "mix rendro.comparison.check && byte-diff of re-rendered PDF vs bench/results/raw/rendro.json sha256 (BYTE_IDENTICAL_PDF + NO_CENTS_FIELDS)"
        status: pass
    human_judgment: false
  - id: D2
    description: "S4 optional empty brand/logo slot present on the invoice fixture"
    requirement: "EXL-06"
    verification:
      - kind: unit
        ref: "test/docs_contract/examples_schema_contract_test.exs (schema permits brand.logo null slot; fixture validates)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Automated schema-validation lane validating every priv/examples/ fixture against examples.schema.json"
    requirement: "EXL-03"
    verification:
      - kind: unit
        ref: "test/docs_contract/examples_schema_contract_test.exs#every fixture under priv/examples/ validates against examples.schema.json"
        status: pass
    human_judgment: false

# Metrics
duration: 2min
completed: 2026-07-11
status: complete
---

# Phase 114 Plan 03: Money normalization + schema-contract test Summary

**Invoice fixture money normalized to Decimal-safe 2-decimal strings with an S4 brand/logo slot (byte-identical Rendro render), plus the first automated JSV schema-validation lane over priv/examples/.**

## Performance

- **Duration:** 2 min
- **Started:** 2026-07-11T05:20:09Z
- **Completed:** 2026-07-11T05:22:36Z
- **Tasks:** 2
- **Files modified:** 6 (5 modified, 1 created)

## Accomplishments
- Normalized all 60 invoice line items and the totals block from integer cents (`price_cents`, `subtotal_cents`, `tax_cents`, `total_cents`) to fixed 2-decimal string money fields (`price` `"79.00"`, `subtotal` `"4740.00"`, `tax` `"379.20"`, `total` `"5119.20"`) — zero `_cents` fields remain.
- Added the top-level `"brand": {"logo": null}` S4 seam (optional, present-but-empty).
- Updated all four bench consumer scripts to read the string money format; Rendro's own rendered PDF stays byte-identical (`e629d371…`) to the recorded evidence, and `mix rendro.comparison.check` stays green.
- Authored `test/docs_contract/examples_schema_contract_test.exs`, the first real consumer of Plan 114-02's schema, validating every discovered fixture.

## Task Commits

Each task was committed atomically:

1. **Task 1: Normalize money to Decimal-safe strings + S4 brand/logo slot; update 4 consumer scripts** - `16f5da3` (refactor)
2. **Task 2: Fixture schema-contract test (EXL-03)** - `dc7684c` (test)

_Note: Task 2 was tdd="true"; because Task 1 already produced the normalized fixture the contract test passed on first run (the fixture artifact it validates genuinely already existed) — a single test commit, no separate RED/GREEN implementation cycle since this task adds only validation coverage._

## Files Created/Modified
- `priv/examples/invoice/acme-phoenix-saas/invoice.json` - Money fields normalized to 2-decimal strings; added `brand.logo` empty slot
- `bench/comparison/fixtures/invoice_rendro.exs` - Derives integer price via `Decimal.new/1 |> Decimal.to_integer/1` from the string field
- `bench/comparison/fixtures/invoice_typst.typ` - Reads pre-formatted `item.price` / `data.totals.total` directly (no `str(.../100)`)
- `bench/comparison/fixtures/invoice_pdf_generator.html.eex` - Reads `item["price"]` string directly
- `bench/comparison/fixtures/invoice_chromic_pdf.html.eex` - Reads `item["price"]` / `totals["total"]` strings directly
- `test/docs_contract/examples_schema_contract_test.exs` - Non-empty wildcard guard + per-fixture JSV validation loop

## Decisions Made
- Kept money normalization as a commit separate from Plan 114-01's verbatim move (RESEARCH.md Pitfall 6).
- Used `Decimal.new(item["price"]) |> Decimal.to_integer()` in the Rendro bench script to preserve the exact prior toy-call rendering — Decimal-aware money formatting via `Rendro.Format.money/1` is deferred to Phase 115.

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
None.

## Known Stubs
- `priv/examples/invoice/acme-phoenix-saas/invoice.json` — `brand.logo` is `null`. This is intentional: the S4 seam reserves an optional, present-but-empty brand/logo slot for this milestone (EXL-06). It is wired/populated in a later phase (theming, Phase 115+), not a defect.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Fixture money convention (EXL-01) and schema-validation lane (EXL-03) are established; Plan 114-04's loader (`Rendro.Examples`) and Plan 114-07's tarball/text-only test can build on the validated fixture.
- No blockers.

## Self-Check: PASSED

- FOUND: test/docs_contract/examples_schema_contract_test.exs
- FOUND: priv/examples/invoice/acme-phoenix-saas/invoice.json (normalized)
- FOUND: commit 16f5da3 (Task 1)
- FOUND: commit dc7684c (Task 2)

---
*Phase: 114-domain-research-reader-quality-rubric-realistic-example-data*
*Completed: 2026-07-11*
