---
phase: 77-v2-4-closure-format-gate-nyquist-drafts-recipe-input-validat
plan: "01"
subsystem: recipes
tags: [elixir, validation, argumenterror, statement, receipt, certificate, tdd]

# Dependency graph
requires:
  - phase: 75-receipt-report-and-certificate-recipes-support-contract
    provides: Receipt and Certificate recipe implementations with existing validate_data!/1 structure
  - phase: 74-statement-recipe
    provides: Statement recipe with canonical validate_period!/1 structured-ArgumentError pattern
provides:
  - validate_account!/1 in statement.ex wired into validate_data!/1
  - validate_customer!/1 and validate_date!/1 in receipt.ex wired into validate_data!/1
  - validate_date!/1 and validate_body!/1 in certificate.ex wired into validate_data!/1
  - Negative-path ArgumentError tests for all five new clauses
  - D-09 cosmetic cleanups (capacity comment, @default_row_height, Enum.reduce, dead _content_w removed)
affects:
  - 77-02 (format gate — modified files need to remain mix format clean)
  - 77-04 (full suite verification)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Structured ArgumentError with What:/Where:/Why:/Next: heredoc, Why: uses Rendro.Recipes.Pagination.type_name/1"
    - "Two-clause guard pattern: passing guard clause returns :ok, catch-all raises structured error"
    - "TDD RED/GREEN cycle: negative-path test written first, then implementation"

key-files:
  created: []
  modified:
    - lib/rendro/recipes/statement.ex
    - lib/rendro/recipes/receipt.ex
    - lib/rendro/recipes/certificate.ex
    - test/rendro/recipes/statement_test.exs
    - test/rendro/recipes/receipt_test.exs
    - test/rendro/recipes/certificate_test.exs

key-decisions:
  - "validate_account!/1 uses %{name: name} when is_binary(name) guard as the floor — map.get default in header_section already handles missing :name gracefully"
  - "validate_body!/1 three-clause pattern: byte_size > 2000 raises existing capacity error, is_binary passes, catch-all raises new type error"
  - "D-09 @default_row_height named 14.4 attribute placed with geometry constants near line 112"
  - "D-09 maybe_validate_summary!/1 Enum.map_reduce replaced with Enum.reduce — rows result was discarded via _ = rows"
  - "D-09 dead _content_w binding in certificate.ex body_section/3 removed; template parameter prefixed _ to silence unused-variable warning"

patterns-established:
  - "New validation clause always added in two-clause form: guard-passing + catch-all heredoc"
  - "validate_date!/1 at arity-1 (not indexed) for top-level :date fields"
  - "validate_customer!/1 mirrors validate_account!/1 — map + string :name floor"

requirements-completed: []

# Metrics
duration: 20min
completed: 2026-05-30
---

# Phase 77 Plan 01: Recipe Input Validation + D-09 Cosmetic Cleanups Summary

**Structured ArgumentError (not BadMapError/FunctionClauseError) on non-map :account, non-map :customer, non-%Date{} :date, and non-binary :body across Statement, Receipt, and Certificate recipes; plus four D-09 cosmetic fixes**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-05-30T01:38:00Z
- **Completed:** 2026-05-30T01:41:46Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added `validate_account!/1` to Statement with What:/Where:/Why:/Next: heredoc pattern, wired between `validate_period!` and `validate_lines!`
- Added `validate_customer!/1` and `validate_date!/1` to Receipt wired before `validate_lines!`
- Added `validate_date!/1` and `validate_body!/1` to Certificate (three-clause: byte cap + binary OK + type error), replacing old `if is_binary(body)` guard
- Four negative-path `assert_raise ArgumentError, ~r/key/i` tests added across statement/receipt/certificate test files
- D-09: capacity comment corrected; `@default_row_height` attribute extracted; `Enum.map_reduce` in `maybe_validate_summary!/1` replaced with `Enum.reduce`; dead `_content_w` binding in certificate.ex removed
- All 136 tests (3 properties + 133 ExUnit) pass; determinism tests unaffected

## Task Commits

Each task was committed atomically:

1. **Task 1: Statement :account validation + D-09 cosmetic cleanups** - `36c5eaa` (feat)
2. **Task 2: Receipt + Certificate input validation, cosmetic cleanup, and negative-path tests** - `83e5cb4` (feat)

## Files Created/Modified

- `lib/rendro/recipes/statement.ex` - Added `validate_account!/1`, `@default_row_height` attribute, corrected capacity comment, replaced `Enum.map_reduce` with `Enum.reduce` in `maybe_validate_summary!/1`
- `lib/rendro/recipes/receipt.ex` - Added `validate_customer!/1` and `validate_date!/1`, wired into `validate_data!/1`
- `lib/rendro/recipes/certificate.ex` - Added `validate_date!/1` and `validate_body!/1`, removed dead `_content_w` binding and its comment, prefixed unused `template` parameter with `_`
- `test/rendro/recipes/statement_test.exs` - Added "non-map :account raises ArgumentError mentioning account" in V8 describe block
- `test/rendro/recipes/receipt_test.exs` - Added V8 describe block with customer + date negative-path tests
- `test/rendro/recipes/certificate_test.exs` - Added C14 describe block with date + body negative-path tests

## Decisions Made

- `validate_account!/1` uses `%{name: name} when is_binary(name)` as the floor — `header_section/2` already uses `Map.get(account, :name, "")` which degrades gracefully on a missing `:name`, so a map-shape guard is sufficient
- `validate_body!/1` three-clause form (byte_size > 2000 → raises capacity error; is_binary → :ok; catch-all → raises type error) preserves the existing 2000-byte cap while adding type enforcement
- Dead `_content_w` binding removal required prefixing `template` parameter with `_` to avoid a new unused-variable compiler warning — deviation auto-fixed per Rule 1

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Unused `template` parameter warning after removing `_content_w`**

- **Found during:** Task 2 (certificate.ex dead binding removal)
- **Issue:** Removing `_content_w = template.width - template.margin_left - template.margin_right` left `template` with no uses in `body_section/3`, generating a compiler warning
- **Fix:** Prefixed the function parameter `template` to `_template`
- **Files modified:** `lib/rendro/recipes/certificate.ex`
- **Verification:** `mix test` passes with no warnings; all 69 receipt + certificate tests green
- **Committed in:** `83e5cb4` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 — compiler warning from dead binding removal)
**Impact on plan:** Required by the D-09 dead binding removal. No scope creep.

## Issues Encountered

None.

## Threat Coverage

| Threat ID | Disposition | Outcome |
|-----------|-------------|---------|
| T-77-01 | mitigate | All three recipes now raise structured ArgumentError with bounded What:/Where:/Why:/Next: messages instead of raw BadMapError/FunctionClauseError. |
| T-77-02 | mitigate | validate_body!/1 now rejects non-binary :body before it reaches the renderer, with explicit type error. 2000-byte cap preserved as first guard clause. |

## Known Stubs

None.

## Next Phase Readiness

- Plan 77-01 fully closes Success Criterion 4 (structured ArgumentError + D-09 cosmetic cleanup)
- All six modified files are `mix format`-clean
- Full recipe test suite (statement + receipt + certificate) and determinism tests are green
- 77-02 (format gate) can proceed — no format violations in any of this plan's files

---
*Phase: 77-v2-4-closure-format-gate-nyquist-drafts-recipe-input-validat*
*Completed: 2026-05-30*

## Self-Check: PASSED

All committed files confirmed present and in expected state.
