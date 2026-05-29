---
phase: 74-statement-recipe
plan: "03"
subsystem: recipes
tags: [statement, recipe, decimal, validation, page-number, three-rung]
dependency_graph:
  requires: ["74-01", "74-02"]
  provides: ["Rendro.Recipes.Statement skeleton", "validate_data!/1", "Decimal balance fold"]
  affects: ["lib/rendro/recipes/statement.ex"]
tech_stack:
  added: []
  patterns:
    - "Three-rung escape hatch (document/2 / page_template/1 / sections/2) mirrored from Invoice"
    - "errors-as-product validate_data!/1 with what/where/why/next ArgumentError messages"
    - "Exact signed Decimal.add/2 map_reduce fold for running balance"
    - "Non-zero footer region height (24pt) reserving space for PAGE primitive"
    - "Rendro.page_number/1 wired into footer section (D-03 / STMT-04)"
key_files:
  created:
    - lib/rendro/recipes/statement.ex
  modified: []
decisions:
  - "Period shape is %{from: Date.t(), to: Date.t()} — chosen over Date.range/2 per CONTEXT D-07 / RESEARCH Open Q3 recommendation; consistent, guard-able, explicit"
  - "Footer section carries ONLY Rendro.page_number/1; no balances in footer (D-03)"
  - "body_section/2 emits a single placeholder table for all rows (plan 74-04 adds per-page chunking + carried/brought-forward)"
  - "En-dash character in period string replaced with ASCII 'to' — en-dash is not in the default Helvetica glyph set (Rule 1 bug auto-fixed)"
  - "validate_data!/1 uses ArgumentError, not Rendro.Error — Rendro.Error is a plain defstruct/not a defexception (Pitfall 6 from RESEARCH)"
metrics:
  duration: "4m 23s"
  completed: "2026-05-29"
  tasks: 2
  files_created: 1
  files_modified: 0
---

# Phase 74 Plan 03: Statement Recipe Skeleton Summary

Statement recipe skeleton with three-rung API, non-zero footer height carrying the PAGE primitive, errors-as-product validate_data!/1, and exact signed Decimal running-balance fold.

## What Was Built

`lib/rendro/recipes/statement.ex` — `Rendro.Recipes.Statement` with:

- **Three-rung escape hatch** consistent with `Rendro.Recipes.Invoice` (STMT-03):
  - `document/2` — validates data, builds template + sections, reduces via Document builder chain
  - `page_template/1` — three regions (header 48pt, body fills remaining, footer 24pt NON-ZERO)
  - `sections/2` — validates data, returns `[header_section, body_section, footer_section]`

- **Footer carries ONLY the PAGE primitive** (D-03/STMT-04): `footer_section/2` emits `[Rendro.page_number(page_number_opts)]`; footer region height = 24pt so `body_capacity` reserves space.

- **`validate_data!/1`** (D-08, errors-as-product): raises `ArgumentError` (NOT `Rendro.Error`) with what/where/why/next messages for: missing required keys, Float/non-Decimal `opening_balance`, malformed `period`, missing line keys, Float line `amount` (instructive Decimal message), caller-supplied per-line `:balance` (rejected per D-06), invalid `closing_balance`/`summary` assertions.

- **`fold_balance/2`** (D-05/D-06): `Enum.map_reduce` over lines with `Decimal.add/2`; returns rows annotated with `:balance`. Optional caller `closing_balance` and `summary.closing_balance` validated via `Decimal.equal?/2`.

- **`Rendro.Format` integration** (D-11): `header_section/2` formats opening balance via `Rendro.Format.money/1` and dates via `Rendro.Format.date/1`; `:formatters`/`:labels` override opts forwarded to all formatters.

- **Body placeholder** (deferred per plan scope): single non-paginated table of all rows with signed Amount + running Balance columns. Plan 74-04 replaces with per-page chunking + carried/brought-forward rows.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] En-dash character in period string replaced with ASCII "to"**
- **Found during:** Task 1 smoke render verification
- **Issue:** `"#{from} – #{to}"` used a Unicode en-dash (U+2013) which is not in Rendro's default Helvetica glyph set, causing `{:error, %Rendro.Error{reason: {:unsupported_glyph, "–"}}}`.
- **Fix:** Changed separator to ASCII `" to "` which is always in the Latin-1/Helvetica glyph set.
- **Files modified:** `lib/rendro/recipes/statement.ex`
- **Commit:** 81b48f2 (inline with Task 1 fix)

**2. [Rule 1 - Bug] Removed unused `@row_epsilon` module attribute**
- **Found during:** Task 1 compilation
- **Issue:** `@row_epsilon 2.0` was defined but not used (needed only in plan 74-04's per-page chunking). `mix compile --warnings-as-errors` failed.
- **Fix:** Removed the attribute; it will be re-added in plan 74-04 when the chunking logic is implemented.
- **Files modified:** `lib/rendro/recipes/statement.ex`
- **Commit:** 81b48f2 (inline)

## Verification Results

| Check | Result |
|-------|--------|
| `mix compile --warnings-as-errors` exits 0 | PASSED |
| Single-page statement renders `{:ok, _pdf}` | PASSED |
| Float line amount raises `ArgumentError` | PASSED |
| `page_template/1` footer region height > 0 (24pt) | PASSED |
| Footer section contains only page_number block | PASSED |
| Missing required key raises `ArgumentError` | PASSED |
| Float `opening_balance` raises `ArgumentError` | PASSED |
| Caller-supplied per-line `:balance` rejected | PASSED |
| Malformed `:period` raises `ArgumentError` | PASSED |
| Missing line `:date` raises `ArgumentError` | PASSED |
| Float message mentions `Decimal` | PASSED |

## Known Stubs

- **`body_section/2` placeholder table** (`lib/rendro/recipes/statement.ex:~177`): emits a single non-paginated table of all rows. Does NOT implement per-page chunking, carried-forward rows, or brought-forward rows (D-01/D-02/D-10). This is intentional per the plan scope — plan 74-04 replaces this with the full pagination logic.

## Threat Surface Scan

No new security-relevant surfaces introduced beyond the plan's `<threat_model>`. `validate_data!/1` implements the T-74-07 mitigation (rejecting malformed input at the recipe boundary). T-74-08 mitigation is satisfied by `fold_balance/2` using `Decimal.add/2` exclusively (no Float paths reach the fold).

## Self-Check: PASSED

- `lib/rendro/recipes/statement.ex` exists at the worktree path.
- Commit `81b48f2` exists in git log.
- All plan verification checks pass.
