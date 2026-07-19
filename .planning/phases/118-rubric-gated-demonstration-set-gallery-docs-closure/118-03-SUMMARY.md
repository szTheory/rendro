---
phase: 118-rubric-gated-demonstration-set-gallery-docs-closure
plan: 03
subsystem: examples
tags: [transform, decimal, date, fixtures, recipes, hidden-internals, elixir]

# Dependency graph
requires:
  - phase: 118-01
    provides: six priv/examples fixtures (invoice + statement/receipt/certificate/payslip/ticket) with money-as-decimal-strings, ISO dates, S4 empty brand slot
  - phase: 118-02
    provides: per-domain DOMAIN.md anatomy files the demonstration set cites
provides:
  - "Rendro.ExamplesData (@moduledoc false) — faithful per-family JSON→recipe transform: transform_{invoice,statement,receipt,certificate,payslip,ticket}/1 + transform/2 dispatcher"
  - "The D-06 single data source both the demo set (SHOW-01) and gallery (SHOW-03) render through"
  - "Unit test proving all six transforms feed their recipe's document/2 without KeyError/FunctionClauseError (Pitfall 1 closed) + payslip net_pay reconciliation"
  - "Hidden-internals contract entry keeping Rendro.ExamplesData out of priv/public_api.json"
affects: [118-04, 118-05, 118-06, 118-07]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Faithful money coercion: Decimal.new/1 preserves cents; invoice legacy :price uses Decimal.to_float/1 (bare number required, still cents-faithful — never Decimal.to_integer)"
    - "put_optional/4 helper drops nil/absent keys so optional fields (closing_balance, summary, totals, payment_method, subtitle, terms, venue) thread through only when present"
    - "Transform constructs only recipe-consumed atom keys; deliberately drops the empty S4 brand slot (certificate's validate_brand!/1 rejects %{logo: nil})"

key-files:
  created:
    - lib/rendro/examples_data.ex
    - test/rendro/examples_data_test.exs
  modified:
    - test/docs_contract/public_api_contract_test.exs
    - priv/examples/statement/northwind-ledger-co/statement.json

key-decisions:
  - "Invoice :price coerced to a bare number via Decimal.to_float/1, NOT Decimal.t() as the plan's behavior text stated — the Invoice recipe's validate_item_price!/2 explicitly rejects Decimal (INV-02 byte-compat split); to_float preserves cents (unlike to_integer)."
  - "transform_certificate/1 drops the fixture's empty S4 brand slot (%{logo: nil}) because Certificate.validate_brand!/1 only accepts nil or a full %{font_name:, logo_name:} — passing the slot would raise."
  - "Statement fixture ASCII-ified (em-dash→hyphen, ····8140→****8140) because the Statement recipe has no unicode fallback font; recipe-level fallback deferred (deferred-items.md)."

patterns-established:
  - "Per-family JSON→recipe transform seam (Rendro.ExamplesData) — the one place string-keyed fixture JSON becomes atom-keyed, Decimal/Date-typed recipe input."
  - "Transform unit test drives each fixture end-to-end through its real recipe document/2, asserting %Rendro.Document{} — the demo set's contract test."

requirements-completed: [SHOW-01, SHOW-03]

coverage:
  - id: D1
    description: "Rendro.ExamplesData faithful per-family transform module (six transform_<family>/1 + transform/2), @moduledoc false, cents-preserving money coercion"
    requirement: "SHOW-01"
    verification:
      - kind: unit
        ref: "test/rendro/examples_data_test.exs (6 family round-trips through document/2)"
        status: pass
      - kind: automated
        ref: "mix compile --warnings-as-errors; grep -c 'def transform_' = 6; grep -c 'Decimal.to_integer' = 0"
        status: pass
    human_judgment: false
  - id: D2
    description: "Payslip transform reconciles: net_pay == sum(earnings) − sum(deductions) (Decimal.equal?)"
    requirement: "SHOW-01"
    verification:
      - kind: unit
        ref: "test/rendro/examples_data_test.exs#transform_payslip feeds Rendro.Recipes.Payslip.document/1 and net_pay reconciles"
        status: pass
    human_judgment: false
  - id: D3
    description: "Rendro.ExamplesData registered as a hidden internal — @moduledoc false, absent from priv/public_api.json"
    requirement: "SHOW-03"
    verification:
      - kind: unit
        ref: "test/docs_contract/public_api_contract_test.exs (hidden_modules includes Rendro.ExamplesData)"
        status: pass
      - kind: automated
        ref: "grep -c ExamplesData priv/public_api.json = 0"
        status: pass
    human_judgment: false

# Metrics
duration: 8min
completed: 2026-07-19
status: complete
---

# Phase 118 Plan 03: JSON→Recipe Transform Layer Summary

**Rendro.ExamplesData — a faithful, `@moduledoc false` per-family transform (`transform_{invoice,statement,receipt,certificate,payslip,ticket}/1` + a `transform/2` dispatcher) that turns string-keyed fixture JSON into the atom-keyed, Decimal/Date-typed maps each recipe's `document/2` consumes, preserving cents and unit-tested end-to-end through all six recipes.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-07-19T15:51:54Z
- **Completed:** 2026-07-19
- **Tasks:** 2
- **Files modified:** 4 (2 created, 2 modified)

## Accomplishments
- Authored `Rendro.ExamplesData` — the D-06 single data source both the demonstration set (SHOW-01) and gallery (SHOW-03) render through. Each `transform_<family>/1` maps `Rendro.Examples.load!/1`'s raw string-keyed JSON to the exact atom-keyed shape its recipe's `validate_data!/1` requires.
- Faithful money: every money field via `Decimal.new/1` (cents preserved, INV-02); invoice legacy `:price` via `Decimal.to_float/1` (bare number the recipe requires, still cents-faithful — never the lossy integer coercion the bench script uses).
- Proved Pitfall 1 closed: one unit test per family loads the fixture, transforms, feeds the real `Recipes.<Family>.document/2` (certificate with `border: true`), and asserts a `%Rendro.Document{}` — no `KeyError`/`FunctionClauseError`. Payslip test additionally asserts `net_pay` reconciles via `Decimal.equal?/2`.
- Registered `Rendro.ExamplesData` in the hidden-internals contract (`public_api_contract_test.exs` `hidden_modules`); it stays absent from `priv/public_api.json`.

## Task Commits

Each task committed atomically:

1. **Task 1: Author Rendro.ExamplesData faithful per-family transform** - `2b018e2` (feat)
2. **Fixture ASCII fix (deviation, unblocks Task 2 statement render)** - `956cb61` (fix)
3. **Task 2: Unit-test six transforms + register module hidden** - `a214cec` (test)
4. **Deferred item log (statement unicode fallback)** - `edfea2f` (docs)

## Files Created/Modified
- `lib/rendro/examples_data.ex` - New `@moduledoc false` transform module: six `transform_<family>/1` + `transform/2` dispatcher; `money/1`/`bare_money/1`/`date/1`/`put_optional/4` helpers.
- `test/rendro/examples_data_test.exs` - Six family round-trip tests through `document/2` + payslip reconciliation assertion.
- `test/docs_contract/public_api_contract_test.exs` - Added `Rendro.ExamplesData` to `hidden_modules`.
- `priv/examples/statement/northwind-ledger-co/statement.json` - ASCII-safe punctuation (deviation, see below).

## Decisions Made
- **Invoice `:price` is a bare number, not `Decimal.t()`.** The plan's behavior text (sourced from the 118-PATTERNS table) said `price: Decimal.t()`, but the Invoice recipe's `validate_item_price!/2` explicitly *rejects* Decimal for byte-compat with the toy call (INV-02's split, confirmed by STATE decision from 115-04). Coerced via `Decimal.to_float/1` — satisfies the recipe's `is_number` guard while preserving cents (never `Decimal.to_integer`).
- **Dropped the empty S4 brand slot in the certificate transform.** `Certificate.validate_brand!/1` accepts only `nil` or a full `%{font_name:, logo_name:}`; the fixture's `%{logo: nil}` would fall through to its raise clause. The transform simply omits `:brand`.
- **Added a `transform/2` family dispatcher** alongside the six named functions (grep count for `def transform_` stays exactly 6) so 118-04's repoint can dispatch by family atom.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Plan behavior text specified an invalid invoice `:price` type**
- **Found during:** Task 1 (authoring transform_invoice)
- **Issue:** The plan/PATTERNS stated `transform_invoice → items[].price: Decimal.t()`, but `Rendro.Recipes.Invoice.validate_item_price!/2` raises on a Decimal `:price` (legacy bare-number contract, INV-02). Following the plan literally would fail Task 2's invoice render.
- **Fix:** Coerce invoice `:price` via `Decimal.new(str) |> Decimal.to_float()` — a bare number that preserves cents (never `Decimal.to_integer`, which drops them).
- **Files modified:** lib/rendro/examples_data.ex
- **Verification:** invoice round-trip test renders `%Rendro.Document{}`; `grep -c Decimal.to_integer` = 0.
- **Committed in:** 2b018e2 (Task 1 commit)

**2. [Rule 3 - Blocking] Statement fixture glyphs abort the Statement recipe's render**
- **Found during:** Task 2 (statement round-trip test)
- **Issue:** The 118-01 statement fixture contains an em-dash (`—`) and middle-dot account masking (`····8140`). The Statement recipe builds `Rendro.Document.new()` (built-in Helvetica, ASCII 32–126 only) with no unicode-fallback and no opts injection point, so both glyphs raise `{:unsupported_glyph}` inside `measure_rows/4`. Unlike Payslip (given a B612 fallback + `glyph_safe/1` in 116-02), Statement has no such treatment.
- **Fix:** ASCII-ified the fixture — em-dash → hyphen, `····8140` → `****8140` (both standard ASCII banking conventions, realism preserved). Data-only change; no statement byte-goldens exist, so zero regression risk. The realism-maximizing alternative (give Statement the same B612 fallback + middle-dot `glyph_safe` as Payslip, then restore the richer punctuation) is logged in `deferred-items.md` for a future plan — it is a recipe change outside this plan's `files_modified` with byte-output implications.
- **Files modified:** priv/examples/statement/northwind-ledger-co/statement.json
- **Verification:** statement round-trip test renders `%Rendro.Document{}`; `mix test test/docs_contract/` green (271 tests, 0 failures — schema-validation lane unaffected).
- **Committed in:** 956cb61

---

**Total deviations:** 2 (1 plan-text bug corrected, 1 blocking fixture fix)
**Impact on plan:** Both necessary to satisfy the plan's own success criteria (all six transforms feed their recipe cleanly). No scope creep — the deferred statement recipe upgrade was explicitly NOT taken on and is logged for a dedicated plan.

## Issues Encountered
- Confirmed against each recipe's `validate_data!/1` that money/date typing differs per family: statement/receipt/payslip use `Decimal.t()` amounts and `Date.t()` dates; invoice uniquely keeps a bare-number `:price`; ticket is strings-only. The transform mirrors each precisely (see the 118-PATTERNS shape table, corrected for the invoice-price case).

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- **For 118-04 (gallery repoint, D-06):** call `Rendro.Examples.load!("<domain>/<business>/<family>.json") |> Rendro.ExamplesData.transform_<family>()` (or `transform(family, loaded)`), then the family's `document/2`. Certificate needs `document(data, border: true)`. All six are proven to feed cleanly.
- **Transform signatures:** `transform_invoice/1`, `transform_statement/1`, `transform_receipt/1`, `transform_certificate/1`, `transform_payslip/1`, `transform_ticket/1`, plus `transform(family_atom, loaded_map)`.
- **Watch item:** the Statement recipe still cannot render em-dash/middle-dot glyphs — if a future demo/gallery needs richer statement typography, resolve the deferred unicode-fallback item first.

## Self-Check: PASSED

- All created files verified present (examples_data.ex, examples_data_test.exs, SUMMARY.md).
- All 4 commits verified in git history (2b018e2, 956cb61, a214cec, edfea2f).

---
*Phase: 118-rubric-gated-demonstration-set-gallery-docs-closure*
*Completed: 2026-07-19*
