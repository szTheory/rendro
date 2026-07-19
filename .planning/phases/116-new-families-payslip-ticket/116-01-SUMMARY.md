---
phase: 116-new-families-payslip-ticket
plan: 01
subsystem: recipes
tags: [elixir, pagination, labels, validation, tdd]

# Dependency graph
requires:
  - phase: 115-invoice-anatomy-upgrade-format-public-promotion-palette-alig
    provides: "Rendro.Format public adapter-tier promotion (money/1, date/1, label/1) that label_resolver/2 falls through to"
provides:
  - "Rendro.Recipes.Pagination.label_resolver/2 — additive arity-2 label resolution with recipe-owned default_labels (D-18)"
  - "Rendro.Recipes.Pagination.validate_labels!/2 — opts[:labels] shape/type validator with four-part ArgumentError (D-19)"
  - "Rendro.Recipes.Pagination.validate_formatters!/2 — opts[:formatters] shape/type validator with four-part ArgumentError (D-19)"
affects: [116-02-payslip, 116-03-ticket]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Additive default-argument generalization (label_resolver/1 -> label_resolver/2 via default_labels \\\\ %{}) to avoid breaking existing arity-1 call sites"
    - "Four-part What/Where/Why/Next ArgumentError idiom (mirrored from Invoice.validate_totals_field_type!/2), naming the caller's public entry point via a recipe_mfa string argument"

key-files:
  created:
    - test/rendro/recipes/pagination_test.exs
  modified:
    - lib/rendro/recipes/pagination.ex

key-decisions:
  - "label_resolver/2 merge order is opts[:labels] -> default_labels -> Rendro.Format.label/1 (D-18), implemented exactly as shown in 116-RESEARCH.md's Code Examples section"
  - "validate_labels!/2 and validate_formatters!/2 take a recipe_mfa string (e.g. \"Rendro.Recipes.Payslip.document/2\") so raised errors name the caller's public API, not this private validator"
  - "Pagination stays @moduledoc false — none of this plan's additions touch priv/public_api.json (confirmed via mix test, no public_api_contract_test regression)"

patterns-established:
  - "Recipe-owned @default_labels maps consumed via label_resolver(opts, @default_labels) — the pattern 116-02 (Payslip) and 116-03 (Ticket) will both use"
  - "Opts-shape validation happens once, centrally, before any recipe's sections/2 touches raw :labels/:formatters values — prevents each new recipe from reinventing (and diverging on) the same guards"

requirements-completed: [FAM-03]

coverage:
  - id: D1
    description: "label_resolver/2 additive arity-2 generalization: opts[:labels] -> default_labels -> Rendro.Format.label/1 merge order, with existing arity-1 call sites (statement.ex:274, statement.ex:294) compiling and resolving unmodified"
    requirement: "FAM-03"
    verification:
      - kind: unit
        ref: "test/rendro/recipes/pagination_test.exs#label_resolver/2 (D-18)"
        status: pass
      - kind: unit
        ref: "test/rendro/recipes/statement_test.exs (full suite, zero edits, regression check)"
        status: pass
    human_judgment: false
  - id: D2
    description: "validate_labels!/2 and validate_formatters!/2 raise instructive four-part ArgumentError on malformed opts shapes instead of leaking BadMapError/FunctionClauseError/BadArityError"
    requirement: "FAM-03"
    verification:
      - kind: unit
        ref: "test/rendro/recipes/pagination_test.exs#validate_labels!/2 and validate_formatters!/2 (D-19)"
        status: pass
    human_judgment: false

duration: 5min
completed: 2026-07-18
status: complete
---

# Phase 116 Plan 01: Pagination Shared Seam (label_resolver/2 + D-19 Validators) Summary

**Additive `label_resolver/2` merge-order generalization plus `validate_labels!/2`/`validate_formatters!/2` opts-shape guards in `Rendro.Recipes.Pagination`, landed via strict RED/GREEN TDD with zero edits to Statement's existing call sites or tests.**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-07-18T23:10:00Z (approx.)
- **Completed:** 2026-07-18T23:12:00Z (approx.)
- **Tasks:** 2
- **Files modified:** 2 (1 created, 1 modified)

## Accomplishments
- `label_resolver/2` generalized additively (`default_labels \\ %{}`), preserving `statement.ex:274`/`statement.ex:294`'s arity-1 call sites byte-identically while giving Payslip/Ticket a recipe-owned default-labels seam
- `validate_labels!/2` and `validate_formatters!/2` added, both raising the codebase's established four-part What/Where/Why/Next `ArgumentError` (mirroring `Invoice.validate_totals_field_type!/2`) instead of letting raw `BadMapError`/`FunctionClauseError`/`BadArityError` escape
- `test/rendro/recipes/pagination_test.exs` created — first dedicated unit test file for this previously-untested `@moduledoc false` shared helper, 12 tests covering all behavior cases from both tasks
- Full regression suite (1287 tests) stays green; `Pagination` remains `@moduledoc false` with zero `priv/public_api.json` impact

## Task Commits

Each task was committed atomically (TDD RED/GREEN pairs):

1. **Task 1: Generalize label_resolver to arity-2 (additive, D-18)**
   - `aa0f400` (test) — RED: 4 failing tests for merge order
   - `f08b812` (feat) — GREEN: `label_resolver/2` implementation
2. **Task 2: D-19 opts-shape validators (validate_labels!/2, validate_formatters!/2)**
   - `d806647` (test) — RED: 8 failing tests for validator behavior
   - `1a2ade2` (feat) — GREEN: `validate_labels!/2` + `validate_formatters!/2` implementation

**Plan metadata:** (final docs commit follows this SUMMARY)

## Files Created/Modified
- `lib/rendro/recipes/pagination.ex` — added `label_resolver/2` (additive over `label_resolver/1`), `validate_labels!/2`, `validate_formatters!/2`; still `@moduledoc false`
- `test/rendro/recipes/pagination_test.exs` — new file, `describe "label_resolver/2 (D-18)"` (4 tests) + `describe "validate_labels!/2 and validate_formatters!/2 (D-19)"` (8 tests)

## Decisions Made
- Implemented `label_resolver/2`'s merge-order logic exactly as prescribed in `116-RESEARCH.md`'s "Additive `label_resolver/2` (D-18, Pagination change)" code example (nested `Map.fetch` chain: `user_labels` -> `default_labels` -> `Rendro.Format.label/1`)
- Added an explicit code comment above `label_resolver/2` documenting the `Rendro.Format.label/1` no-fallback-clause gotcha (per the plan's Task 1 action, this is the load-bearing warning 116-02/116-03 rely on when building `@default_labels` maps)
- Empty-string `:labels` values are rejected by `validate_labels!/2` (not just non-string values) — per the plan's explicit behavior case, an empty label would silently blank a chrome/anchor label rather than raising

## Deviations from Plan

None - plan executed exactly as written. Both tasks' TDD RED/GREEN gates were followed strictly (tests written and confirmed failing before any implementation code was added).

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- `Pagination.label_resolver/2`, `validate_labels!/2`, and `validate_formatters!/2` are ready for 116-02 (Payslip) and 116-03 (Ticket) to call from their respective `sections/2` implementations, per this plan's `key_links` must-have
- Statement's full test suite and the project's full 1287-test suite are green — no regression risk carried forward into the parallel Payslip/Ticket waves

---
*Phase: 116-new-families-payslip-ticket*
*Completed: 2026-07-18*

## Self-Check: PASSED

- FOUND: lib/rendro/recipes/pagination.ex
- FOUND: test/rendro/recipes/pagination_test.exs
- FOUND: aa0f400 (test: label_resolver/2 RED)
- FOUND: f08b812 (feat: label_resolver/2 GREEN)
- FOUND: d806647 (test: D-19 validators RED)
- FOUND: 1a2ade2 (feat: D-19 validators GREEN)
