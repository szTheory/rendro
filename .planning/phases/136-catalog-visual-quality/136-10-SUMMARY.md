---
phase: 136-catalog-visual-quality
plan: "10"
subsystem: deterministic recipe layout
tags: [elixir, pdf, measured-layout, pagination, tdd, catalog]

requires:
  - phase: 136-09
    provides: committed final Ticket atomic locator profile and exact six-target catalog scope
provides:
  - Nil-safe optional Payslip YTD through the sequential measured render path
  - Held-out measured wrapping and pagination evidence for Invoice and Statement semantic profiles
  - Atomic one-row Ticket locators across long prose boundaries in light and dark
affects: [catalog-evidence, visual-review, recipe-regressions]

actuals:
  tokens: 11394
  tasks: 3
  commits: 9

tech-stack:
  added: []
  patterns:
    - Private presentation profiles bound layout corrections without changing public recipe APIs
    - Complete deterministic bytes, ordered extracted text, and measured geometry prove objective layout invariants

key-files:
  created: []
  modified:
    - lib/rendro/recipes/invoice.ex
    - lib/rendro/recipes/statement.ex
    - lib/rendro/recipes/payslip.ex
    - lib/rendro/recipes/ticket.ex
    - test/rendro/recipes/invoice_test.exs
    - test/rendro/recipes/statement_test.exs
    - test/rendro/recipes/payslip_test.exs
    - test/rendro/recipes/ticket_byte_identity_test.exs
    - test/rendro/recipes/ticket_test.exs

key-decisions:
  - "The private atomic Ticket profile caps themed locator values at 1.5 times the title role, preserving hierarchy while keeping GA, H, 24, and B on one equal-share row."
  - "Held-out tests establish deterministic text, pagination, and geometry invariants only; they do not manufacture aesthetic, accessibility, print-safety, or human-review claims."

patterns-established:
  - "Target-scoped measurement: private profile corrections remain inactive for omitted and unrelated profiles, whose frozen bytes stay unchanged."
  - "Boundary evidence: empty, exact-fit, one-step-over, equal-order, and pagination cases compare full bytes plus extracted text and geometry."

requirements-completed: [CATALOG-11, CATALOG-12]

coverage:
  - id: D1
    description: Optional and nil Payslip YTD values remain blank without crashes while real rows, money, continuations, headers, totals, and reconciliation stay deterministic.
    requirement: CATALOG-11
    verification:
      - kind: integration
        ref: "test/rendro/recipes/payslip_test.exs#optional YTD and sequential measured boundary groups"
        status: pass
    human_judgment: false
  - id: D2
    description: Invoice and Statement semantic profiles measure long facts, labels, descriptions, and page boundaries without clipping, reordering, or default-path drift.
    requirement: CATALOG-11
    verification:
      - kind: integration
        ref: "test/rendro/recipes/invoice_test.exs and test/rendro/recipes/statement_test.exs#long semantic profile groups"
        status: pass
    human_judgment: false
  - id: D3
    description: Ticket subtitle, terms, and reference prose wrap deterministically while GA, H, 24, and B remain atomic, ordered, equal-share, and geometrically identical across light and dark.
    requirement: CATALOG-12
    verification:
      - kind: integration
        ref: "test/rendro/recipes/ticket_byte_identity_test.exs#136-10 held-out prose boundaries"
        status: pass
    human_judgment: false

duration: 24min
completed: 2026-08-28
status: complete
---

# Phase 136 Plan 10: Deterministic Recipe Boundary Closure Summary

**Nil-safe Payslip rows, measured Invoice and Statement semantic content, and profile-bounded atomic Ticket locators now have deterministic held-out text, pagination, byte, and geometry evidence.**

## Performance

- **Duration:** 24 min
- **Started:** 2026-08-28T19:30:08Z
- **Completed:** 2026-08-28T19:54:38Z
- **Tasks:** 3
- **Files modified:** 9

## Accomplishments

- Made omitted and nil Payslip YTD values flow through the existing blank formatter while preserving real-row cardinality, stable order, measured money columns, continuations, repeated headers, totals, Net Pay, and reconciliation.
- Added held-out exact-fit, one-step-over, equal-order, long-content, and pagination evidence for the Invoice and Statement semantic profiles while preserving omitted-profile controls.
- Proved Ticket subtitle, terms, and reference wrapping in both modes without locator movement; the private atomic profile keeps GA, H, 24, and B one-line, one-row, equal-share, ordered, and byte-deterministic.

## Task Commits

Tasks 1 and 2 used RED/GREEN follow-up commits plus broader boundary coverage; Task 3 resumed from an observed failing regression and was committed atomically with the authorized correction.

1. **Task 1 RED: optional YTD render regression** - `10520ae` (test)
2. **Task 1 GREEN: nil-safe sequential YTD** - `d563acc` (fix)
3. **Task 1 boundary coverage** - `90d6db2` (test)
4. **Task 2 Invoice RED: long semantic profile** - `209bf9a` (test)
5. **Task 2 Invoice GREEN: measured semantic headers** - `b4aa8c3` (fix)
6. **Task 2 Statement RED: long semantic context** - `2798e42` (test)
7. **Task 2 Statement GREEN: measured semantic context** - `6597de8` (fix)
8. **Task 2 held-out boundary coverage** - `fe1fa1a` (test)
9. **Task 3: atomic Ticket locators under long prose** - `9fb5ae7` (fix)

## Files Created/Modified

- `lib/rendro/recipes/payslip.ex` - Uses nil-safe access and the existing blank amount formatter in sequential rows and money-width measurement.
- `lib/rendro/recipes/invoice.ex` - Measures semantic-profile header and fact content at held-out long boundaries.
- `lib/rendro/recipes/statement.ex` - Measures semantic-profile context and description content at held-out long boundaries.
- `lib/rendro/recipes/ticket.ex` - Privately clamps atomic-profile locator values so the dominant target tokens remain one line.
- `test/rendro/recipes/payslip_test.exs` - Covers optional YTD, real-row cardinality/order, boundary wrapping, pagination, totals, and determinism.
- `test/rendro/recipes/invoice_test.exs` - Covers long semantic facts, labels, items, exact fits, overflow steps, and default controls.
- `test/rendro/recipes/statement_test.exs` - Covers long ledger facts, descriptions, context, ordering, and pagination thresholds.
- `test/rendro/recipes/ticket_byte_identity_test.exs` - Covers empty/exact-fit/one-step-over/multiline prose, atomic cells, measured cross-mode geometry, and frozen default bytes.
- `test/rendro/recipes/ticket_test.exs` - Updates the private atomic-profile size contract to the corrected dominant 30pt value.

## Decisions Made

- The smallest safe Ticket correction is private and profile-gated: themed atomic locator values use the lesser of the display role and 1.5 times the title role. Brutalist resolves to 30pt, still larger than the 20pt title while fitting the widest fixed target token.
- Objective test evidence remains intentionally narrower than visual approval. No test or summary claim expands into aesthetic scoring, accessibility, PDF/UA, WCAG, print safety, or universal viewer fidelity.

## Deviations from Plan

### Human-Approved Scope Adjustment

**1. [Rule 4 - Approved decision] Corrected Ticket production layout after the held-out regression exposed wrapped `GA`**
- **Found during:** Task 3 (Ticket prose wrapping without locator movement)
- **Issue:** The plan originally restricted Task 3 to tests and required surfacing any Ticket source need. The failing regression measured `GA` as two lines in both modes even though every cell was pagination-atomic.
- **Decision:** At the blocking-human checkpoint, the user selected Option 1 and authorized the smallest private correction in `lib/rendro/recipes/ticket.ex`.
- **Fix:** Clamped only themed `:atomic_equal_share` locator values; default, omitted-profile, unrelated-profile, public API, catalog identity, and unrelated bytes remain unchanged.
- **Files modified:** `lib/rendro/recipes/ticket.ex`, `test/rendro/recipes/ticket_test.exs`, `test/rendro/recipes/ticket_byte_identity_test.exs`
- **Verification:** 41 Ticket tests, 147 plan recipe tests, frozen default SHA-256, measured one-line cells, and exact light/dark table geometry all passed.
- **Committed in:** `9fb5ae7`

**Total deviations:** 1 human-approved scope adjustment. **Impact:** The correction is confined to the already-private target profile and closes the planned locator truth without broader behavior or claim expansion.

## Issues Encountered

- Task 3's `<read_first>` lists `test/support/recipe_helpers.ex`, but that path does not exist in repository history or the current tree. The Ticket regression uses its file-local render, extraction, and geometry helpers; no replacement support abstraction was invented.
- `mix ci.fast` still stops at the pre-existing `quality.hygiene` finding for `.planning/todos/pending/2026-08-28-unify-catalog-recipe-visual-design-system.md`, already documented by Plan 09. All remaining CI-fast stages were run directly and passed.

## Verification

- `mix test test/rendro/recipes/invoice_test.exs test/rendro/recipes/statement_test.exs test/rendro/recipes/payslip_test.exs test/rendro/recipes/ticket_byte_identity_test.exs --max-failures 1` - 147 tests, 0 failures.
- `mix test test/rendro/recipes/ticket_test.exs test/rendro/recipes/ticket_byte_identity_test.exs --max-failures 1` - 41 tests, 0 failures.
- `mix format --check-formatted` - passed.
- Remaining `mix ci.fast` stages - Hex package build passed; warnings-as-errors compilation passed; 1,998 tests plus 12 doctests and 8 properties passed with 0 failures; ExDoc warnings-as-errors passed; Credo strict found no issues; Dialyzer reported 0 errors.

## Known Stubs

None. A scan of every plan-modified file found no new TODO, FIXME, placeholder, coming-soon, unavailable-data, or rendered empty-value stub.

## Threat Flags

None. The plan introduced no network endpoint, authentication path, file-access boundary, dependency, or schema change beyond the declared recipe-input-to-measured-layout trust boundary.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- All nine behavior-unverified groups from the Phase 136 verification report now have deterministic recipe evidence.
- Plan 136-11 may consume these closed layout invariants while preserving the exact six-cell boundary and objective/advisory evidence separation.

## Self-Check: PASSED

- All nine plan-modified production/test files exist.
- All nine Task 1-3 commits exist in repository history.
- Task and plan verification evidence above was produced in this execution session.

---
*Phase: 136-catalog-visual-quality*
*Plan: 10*
*Completed: 2026-08-28*
