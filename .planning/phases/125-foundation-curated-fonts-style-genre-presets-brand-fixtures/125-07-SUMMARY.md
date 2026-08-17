---
phase: 125-foundation-curated-fonts-style-genre-presets-brand-fixtures
plan: 07
subsystem: example fixtures
tags: [json-schema, fixtures, svg, decimal, brands-as-data]
requires:
  - phase: 125-01
    provides: Canonical preset names and data-only fixture direction
provides:
  - Generic, safe-local brand metadata schema contract
  - Northline Logistics and Cedar Mutual Invoice and Payslip fixtures
  - Cross-domain identity, SVG, arithmetic, and original-byte contract coverage
affects: [125-08, 125-09, 125-10, phase-127-catalog]
tech-stack:
  added: []
  patterns: [generic brand tuples, deterministic one-color local SVG marks, Decimal fixture reconciliation]
key-files:
  created:
    - priv/examples/invoice/northline-logistics/invoice.json
    - priv/examples/invoice/cedar-mutual/invoice.json
    - priv/examples/payslip/northline-logistics/payslip.json
    - priv/examples/payslip/cedar-mutual/payslip.json
  modified:
    - priv/schemas/examples.schema.json
    - test/docs_contract/examples_schema_contract_test.exs
key-decisions:
  - "Preserve legacy fixtures through an explicit logo-null schema branch while requiring complete metadata for new branded fixtures."
  - "Use identical local SVG bytes for each cross-domain brand so identity consistency is mechanically verifiable."
patterns-established:
  - "Brand fixtures remain generic JSON data keyed by domain and slug; no brand modules or recipe branches."
  - "A local SVG mark is limited to text-free, one-color geometry and is verified beside its JSON fixture."
requirements-completed: [CATALOG-05]
coverage:
  - id: D1
    description: Generic brand metadata and safe local asset contract
    requirement: CATALOG-05
    verification:
      - kind: unit
        ref: test/docs_contract/examples_schema_contract_test.exs#generic brand metadata requires a complete safe local identity tuple
        status: pass
    human_judgment: false
  - id: D2
    description: Northline Logistics and Cedar Mutual Invoice and Payslip fixture matrix
    requirement: CATALOG-05
    verification:
      - kind: integration
        ref: mix test test/docs_contract/examples_schema_contract_test.exs test/rendro/examples_data_test.exs --max-failures 1
        status: pass
    human_judgment: false
duration: 9min
completed: 2026-08-17
status: complete
---

# Phase 125 Plan 07: Generic Brand Contract and Invoice/Payslip Fixtures Summary

**Generic brand tuples now safely carry identity and local marks, with Northline Logistics and Cedar Mutual supplied consistently across Invoice and Payslip.**

## Performance

- **Duration:** 9 min
- **Started:** 2026-08-17T00:29:00Z
- **Completed:** 2026-08-17T00:38:42Z
- **Tasks:** 2/2
- **Files modified:** 11

## Accomplishments

- Extended the generic schema with complete, canonical brand metadata while retaining original `logo: null` fixtures unchanged.
- Added two synthetic, safe-local, Decimal-reconciling Invoice brands and their deterministic geometry-only SVG marks.
- Added matching Payslip brands, including period and YTD Decimal reconciliation plus cross-domain identity and mark checks.

## Task Commits

1. **Task 1: Extend the generic contract and add Invoice brands** — `f56d331` (RED), `d629727` (GREEN)
2. **Task 2: Reuse Northline and Cedar consistently in Payslip** — `a635051` (RED), `fb2c936` (GREEN)

## Files Created/Modified

- `priv/schemas/examples.schema.json` — generic brand tuple and optional Payslip YTD validation.
- `test/docs_contract/examples_schema_contract_test.exs` — schema, safe SVG, count, identity, arithmetic, and original-byte controls.
- `priv/examples/invoice/{northline-logistics,cedar-mutual}/` — synthetic Invoice data and local marks.
- `priv/examples/payslip/{northline-logistics,cedar-mutual}/` — synthetic Payslip data and matching local marks.

## Decisions Made

- Retained legacy fixture compatibility only for the explicit `logo: null` shape; new brand fixtures must provide all five generic fields.
- Reused identical SVG geometry per brand across the two domains to make consistency deterministic and auditable.

## Verification

- `mix test test/docs_contract/examples_schema_contract_test.exs test/rendro/examples_data_test.exs --max-failures 1` — passed (15 tests, 0 failures).
- `mix format --check-formatted` — passed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] SVG test treated the required SVG namespace as an external reference**
- **Found during:** Task 1
- **Issue:** The initial external-reference regex rejected the standard `xmlns="http://www.w3.org/2000/svg"` declaration.
- **Fix:** Restricted the assertion to real `href`/`url(...)` asset references while retaining script, image, gradient, filter, and text exclusions.
- **Files modified:** `test/docs_contract/examples_schema_contract_test.exs`
- **Verification:** Fixture contract suite passes for both marks.
- **Committed in:** `d629727`

**2. [Rule 2 - Missing Critical] Validated explicit Payslip net-pay YTD values as decimal strings**
- **Found during:** Task 2
- **Issue:** Full YTD reconciliation needs a declared net YTD assertion, not only line-level YTD amounts.
- **Fix:** Added optional `net_pay_ytd` schema validation and checked its exact Decimal reconciliation in the fixture contract.
- **Files modified:** `priv/schemas/examples.schema.json`, `test/docs_contract/examples_schema_contract_test.exs`
- **Verification:** Payslip fixture contract passes for period and YTD arithmetic.
- **Committed in:** `fb2c936`

**Total deviations:** 2 auto-fixed (1 Rule 1 bug, 1 Rule 2 missing critical validation).
**Impact on plan:** Both corrections are scoped to the promised safe SVG and exact YTD fixture contracts; no product architecture changed.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

The generic brands-as-data contract is proven in two domains and can be repeated for the remaining Phase 125 fixture plans without adding brand code or remote assets.

## Self-Check: PASSED

- All ten schema, test, JSON, and SVG artifacts exist on disk.
- All four RED/GREEN task commits are present in git history.

---
*Phase: 125-foundation-curated-fonts-style-genre-presets-brand-fixtures*
*Completed: 2026-08-17*
