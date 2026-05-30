---
phase: 78-public-api-surface-definition-cleanup
plan: "03"
subsystem: api
tags: [elixir, recipes, opts-threading, invoice, branded-invoice, api-cleanup]

requires: []

provides:
  - "Invoice.sections/2 with named opts parameter threaded to all three section helpers"
  - "BrandedInvoice.sections/2 with named opts parameter threaded to all four section helpers"
  - "Arity-2 heads (_opts) on all private helpers in both recipe modules"
  - "Uniform opts handling across all five recipes (Invoice, BrandedInvoice, Statement, Receipt, Certificate)"

affects:
  - "78-04 (public API manifest — recipe modules listed as adapter tier)"
  - "80 (stability contract docs — recipe sections/2 opts threading documented)"

tech-stack:
  added: []
  patterns:
    - "opts-threading: rename _opts to opts in sections/2; thread to each helper; add _opts as second param to each private helper body (no validation — D-13)"

key-files:
  created:
    - "test/rendro/recipes/invoice_opts_threading_test.exs"
    - "test/rendro/recipes/branded_invoice_opts_threading_test.exs"
  modified:
    - "lib/rendro/recipes/invoice.ex"
    - "lib/rendro/recipes/branded_invoice.ex"

key-decisions:
  - "D-11 enforced: default rendered output is byte-identical — all helpers receive _opts but do not use it; no formatter/label threading attempted"
  - "D-12 confirmed: no @behaviour Rendro.Recipes.Recipe introduced — arity-2 heads only"
  - "D-13 confirmed: NimbleOptions validation deferred — out of scope for this additive opts-threading plan"

patterns-established:
  - "Recipe opts threading: sections/2 uses named opts; each private helper takes _opts as second param with underscore prefix to satisfy --warnings-as-errors"

requirements-completed:
  - API-05

duration: 8min
completed: "2026-05-30"
---

# Phase 78 Plan 03: Statement/Receipt/Certificate-pattern opts threading for Invoice and BrandedInvoice Summary

**Named opts threading normalized across all five recipes: Invoice and BrandedInvoice now match Statement/Receipt/Certificate with sections(data, opts) and arity-2 helper heads using _opts**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-05-30T14:18:00Z
- **Completed:** 2026-05-30T14:26:03Z
- **Tasks:** 2
- **Files modified:** 4 (2 source, 2 test)

## Accomplishments

- `Invoice.sections/2` renamed from `_opts` to `opts`; threaded to `header_section/2`, `body_section/2`, `footer_section/2`
- `BrandedInvoice.sections/2` renamed from `_opts` to `opts`; threaded to all four helpers (logo, header, body, footer)
- All seven private helpers (3 Invoice + 4 BrandedInvoice) now have arity-2 heads with `_opts` as second param
- `mix compile --warnings-as-errors` exits 0; `mix test` 925 tests, 0 failures; docs contract tests unchanged
- TDD cycle: RED (test commits) → GREEN (implementation commits)

## Task Commits

1. **RED — TDD tests for opts threading** - `56de442` (test)
2. **Task 1: Normalize Invoice.sections/2** - `1536601` (feat)
3. **Task 2: Normalize BrandedInvoice.sections/2** - `f61a8fe` (feat)

## Files Created/Modified

- `lib/rendro/recipes/invoice.ex` — `sections/2` renamed `_opts` → `opts`; all three helpers get arity-2 heads with `_opts`
- `lib/rendro/recipes/branded_invoice.ex` — same pattern; four helpers (logo/header/body/footer) get arity-2 heads
- `test/rendro/recipes/invoice_opts_threading_test.exs` — TDD tests for opts threading contract
- `test/rendro/recipes/branded_invoice_opts_threading_test.exs` — TDD tests for BrandedInvoice opts threading

## Decisions Made

- D-11 applied: did not wire real formatter/label support into invoice helpers — bodies are unchanged; `_opts` prefix keeps helpers unused-var-warning free under `--warnings-as-errors`
- D-12 confirmed: no `@behaviour Rendro.Recipes.Recipe` added
- D-13 confirmed: no NimbleOptions validation added

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- All five recipes now have uniform `sections(data, opts \\ [])` signatures with opts threaded to all helpers
- Phase 79 (public API contract enforcement) can enumerate the recipe modules without worrying about opts inconsistency
- Phase 80 (stability contract docs) can document the uniform recipe API pattern

---

## Self-Check

**Files exist:**
- `lib/rendro/recipes/invoice.ex` — verified (modified in place)
- `lib/rendro/recipes/branded_invoice.ex` — verified (modified in place)
- `test/rendro/recipes/invoice_opts_threading_test.exs` — verified (created)
- `test/rendro/recipes/branded_invoice_opts_threading_test.exs` — verified (created)

**Commits exist:**
- `56de442` — test(78-03): add failing tests for Invoice/BrandedInvoice opts threading
- `1536601` — feat(78-03): normalize Invoice.sections/2 opts threading
- `f61a8fe` — feat(78-03): normalize BrandedInvoice.sections/2 opts threading

**Acceptance criteria:**
- `grep "def sections(data, opts" invoice.ex` → matches (verified)
- `grep "def sections(data, _opts" invoice.ex` → empty (verified)
- `grep "def sections(data, opts" branded_invoice.ex` → matches (verified)
- `grep "def sections(data, _opts" branded_invoice.ex` → empty (verified)
- All 7 private helpers have arity-2 heads with `_opts` (verified)
- `mix compile --warnings-as-errors` → exits 0 (verified)
- `mix test test/docs_contract/recipes_contract_test.exs` → 6 tests, 0 failures (verified)
- `mix test` → 925 tests, 0 failures (verified)
- No `@behaviour` in either file (verified)
- No `NimbleOptions` in either file (verified)

## Self-Check: PASSED

---
*Phase: 78-public-api-surface-definition-cleanup*
*Completed: 2026-05-30*
