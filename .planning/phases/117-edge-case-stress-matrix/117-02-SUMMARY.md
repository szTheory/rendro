---
phase: 117-edge-case-stress-matrix
plan: 02
subsystem: testing
tags: [edge-matrix, fixtures, recipes, errors-as-product, pagination, rtl, deterministic]

requires:
  - phase: 117-01
    provides: Rendro.Test.Golden (assert_or_bless/2 + assert_deterministic!/1) — the byte-golden helper Wave-2 consumes alongside EdgeFixtures
  - phase: 116
    provides: Rendro.Recipes.Payslip and Rendro.Recipes.Ticket (the two newest families the matrix must cover)
provides:
  - Rendro.Test.EdgeFixtures — the single {family, dimension} -> recipe-shaped document dispatch table covering all 62 :applies matrix cells
  - EdgeFixtures.document/2 — the entry point 117-04 (goldens), 117-05 (errors), 117-06 (raster) all consume
  - Four EDGE-02 error fixtures (overflow, tall-row, RTL default-font, RTL shaping-required) reused by 117-05
affects: [117-04, 117-05, 117-06]

tech-stack:
  added: []
  patterns:
    - "Curated {family, dimension} dispatch fixture builder over six already-shipped recipes (zero lib/ edits)"
    - "Escape-hatch composition for odd/even parity via static only_on footer sections (not RunningContent funs)"
    - "Fake-font-registry clone for the RTL shaping-required error path (no vendored font)"

key-files:
  created:
    - test/support/edge_fixtures.ex
    - test/support/edge_fixtures_test.exs
  modified: []

key-decisions:
  - "GBP currency_format override uses an ASCII 'GBP ' prefix, not the '£' sign — the engine's built-in font metrics table is ASCII-only and '£' raises {:unsupported_glyph} at measure; no lib/ font change is in scope."
  - "Receipt currency_format is composed via escape hatch (page_template with no opts + sections with the formatter) because Receipt.page_template/1 forwards recipe-level opts unfiltered into struct!(PageTemplate) and crashes on :formatters — unlike Invoice/Statement which Keyword.take only template keys."
  - "odd_even_running_content uses static only_on footer blocks, NOT %Rendro.RunningContent{fun:} closures — the closure primitive's lazily-generated inner blocks bypass measure-stage font registration and fail full render+validate; recipes themselves use static token-substituted blocks."
  - "Certificate/Ticket text_wrap fixtures are capped at ~120 bytes — their free-text regions are vertically tight (160+ bytes overflow, verified via live probe); a 120-byte wrapping string still fills multiple lines and proves wrapping."

patterns-established:
  - "EdgeFixtures.build/2 catch-all raises ArgumentError pointing at edge_matrix_test.exs @matrix as the source of truth — never silently returns a nonsense map for N/A pairs."
  - "Payslip fixtures always re-derive :net_pay via exact Decimal.sub(gross, deductions) so validate_reconciliation!/1 never raises."

requirements-completed: [EDGE-01, EDGE-02]

coverage:
  - id: D1
    description: "Rendro.Test.EdgeFixtures.document/2 renders successfully through the real recipe for every one of the 62 :applies {family, dimension} matrix cells"
    requirement: "EDGE-01"
    verification:
      - kind: unit
        ref: "test/support/edge_fixtures_test.exs#document/2 — Task 1 cells all render without raising / Task 2 cells all render without raising"
        status: pass
    human_judgment: false
  - id: D2
    description: "build/2 raises ArgumentError for unrecognized/N-A pairs (never a nonsense document)"
    requirement: "EDGE-01"
    verification:
      - kind: unit
        ref: "test/support/edge_fixtures_test.exs#certificate/qty_zero is a genuine N/A cell: build/2 raises ArgumentError"
        status: pass
    human_judgment: false
  - id: D3
    description: "Four EDGE-02 error fixtures reproduce the exact typed %Rendro.Error{} stage/reason/details shapes (overflow, tall-row, RTL x2), built from public structs with zero lib/ edits"
    requirement: "EDGE-02"
    verification:
      - kind: unit
        ref: "test/support/edge_fixtures_test.exs#EDGE-02 error fixtures (overflow_document / tall_row_document / rtl_default_font_document / rtl_shaping_required_document / render never returns ok for RTL)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Money-dimension fixtures always satisfy each recipe's own Decimal.equal?/2 caller-assertion (Invoice totals, Payslip reconciliation)"
    requirement: "EDGE-01"
    verification:
      - kind: unit
        ref: "test/support/edge_fixtures_test.exs#invoice/money_large totals Decimal-equal the summed items / payslip/money_cents_rounding derives net_pay via exact Decimal.sub"
        status: pass
    human_judgment: false

duration: 35min
completed: 2026-07-19
status: complete
---

# Phase 117 Plan 02: EdgeFixtures Builder Summary

**Built `Rendro.Test.EdgeFixtures`, the single {family, dimension} -> recipe-shaped document dispatch table covering all 62 `:applies` cells across the six families plus the four EDGE-02 error fixtures — pure test-support composition of shipped recipes and public primitives, zero `lib/` edits.**

## Performance

- **Duration:** ~35 min
- **Completed:** 2026-07-19
- **Tasks:** 2 of 2
- **Files modified:** 2 (both created)

## Accomplishments
- `Rendro.Test.EdgeFixtures` exposes `recipe_module/1`, `build/2`, `opts/2`, `document/2` and the four error-fixture functions, all `@spec`-annotated, mirroring `pdfium_cli.ex`'s pure `@moduledoc false` shape.
- `document/2` renders successfully through the real `Rendro.Recipes.*` recipe for every one of the 62 `:applies` matrix cells (43 content-substitution + 19 structural/page-size/odd-even), and `build/2` raises `ArgumentError` for any unrecognized/N-A pair.
- The four EDGE-02 error fixtures reproduce the exact live-probe-verified `%Rendro.Error{}` shapes: `paginate/:content_overflow` with `details.block` (overflow) vs `details.row_height` and no `:block` (tall-row); `measure/{:unsupported_glyph, _}` (RTL default font); `measure/{:shaping_required, :arab, _}` (RTL fake-font clone).
- All fixtures satisfy each recipe's own caller-assertions — Invoice `maybe_validate_totals!` Decimal equality and Payslip `validate_reconciliation!` (net_pay always re-derived via exact `Decimal.sub`).

## Task Commits

1. **Task 1: build/2, opts/2, document/2 dispatch skeleton + content-substitution dimensions** - `6a31159` (test)
2. **Task 2: structural dimensions (pagination, page_size, odd/even) + EDGE-02 error fixtures** - `a6173a5` (test)

_Both tasks were tdd="true": tests and implementation landed together in one commit each, run green before commit._

## Files Created/Modified
- `test/support/edge_fixtures.ex` - `Rendro.Test.EdgeFixtures`; the fixture dispatch table + 4 error fixtures.
- `test/support/edge_fixtures_test.exs` - `Rendro.Test.EdgeFixturesTest` (`async: true`); behavior cases + full 62-cell render sweep + error-shape assertions.

## Decisions Made
See `key-decisions` frontmatter. The load-bearing ones: ASCII `GBP ` prefix (built-in font is ASCII-only), Receipt currency_format escape-hatch, static `only_on` footers for odd/even parity, and capped Certificate/Ticket wrap lengths.

## Deviations from Plan

The plan's structure was followed exactly; four fixture-construction details were adapted after verifying against live source/behavior (the plan's `critical_constraints` explicitly authorized adapting a fixture to construct a VALID document when a cited assumption drifts, recording it here). None required or involved a `lib/` edit.

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Invoice `:totals` added via `Map.put`, not map-update syntax**
- **Found during:** Task 1
- **Issue:** `%{base_data(:invoice) | totals: ...}` raised `KeyError` — the map-update `|` operator requires the key to already exist, but `:totals` is an optional key absent from the minimal base data.
- **Fix:** Switched the invoice money/currency clauses to `Map.put(:totals, ...)`.
- **Files modified:** test/support/edge_fixtures.ex
- **Committed in:** `6a31159`

**2. [Rule 1 - Bug] GBP currency override uses ASCII prefix, not the `£` sign**
- **Found during:** Task 1
- **Issue:** The RESEARCH sketch's `"£" <> ...` formatter raised `{:unsupported_glyph, "£"}` at the measure stage — the engine's built-in font metrics table is ASCII-only (a known 116-02 constraint). This is not a defect in the engine; it is a font-coverage boundary, and no `lib/` font change is in scope for this test-only phase.
- **Fix:** The `:formatters[:amount]` override now emits `"GBP " <> String.trim_leading(Rendro.Format.money(d), "$")` (still reuses `Format.money/1`'s grouping/rounding, still proves the caller override replaces the default USD `$`).
- **Files modified:** test/support/edge_fixtures.ex
- **Committed in:** `6a31159`

**3. [Rule 3 - Blocking] Receipt currency_format composed via escape hatch**
- **Found during:** Task 1
- **Issue:** Passing `[formatters: [...]]` to `Receipt.document/2` raised `KeyError key :formatters not found` inside `struct!(PageTemplate, ...)`. Unlike Invoice/Statement (which `Keyword.take` only template keys), Receipt's `page_template/1` does `Rendro.page_template(Keyword.merge(defaults, opts))`, forwarding recipe-level opts unfiltered into the struct builder. This is a pre-existing Receipt robustness gap (out of scope to fix here — zero `lib/` edits).
- **Fix:** `document(:receipt, :currency_format)` composes the document via escape hatch — `Receipt.page_template()` with no opts + `Receipt.sections(data, formatter_opts)` — so the formatter threads only to the body section that actually consumes it. Valid rendering fixture, no `lib/` change.
- **Files modified:** test/support/edge_fixtures.ex
- **Committed in:** `6a31159`

**4. [Rule 1 - Bug] odd/even uses static `only_on` footers, not `RunningContent` closures**
- **Found during:** Task 2
- **Issue:** The RESEARCH sketch wrapped each parity footer in `%Rendro.RunningContent{fun: fn {pn, _tp} -> ... end}`. A full `Rendro.render/1` of such a document failed post-render validation with `:structural_corruption` (`:invalid_block_bounds` + `{:missing_font_reference, "Helvetica"}`) — the closure's lazily-generated inner blocks never pass through the measure stage's font-registration/bounds pass. `%Rendro.RunningContent{fun:}` is a paginate-stage unit-test construct; the recipes themselves never use it (they emit static token-substituted blocks via `Rendro.page_number/1`).
- **Fix:** `document(family, :odd_even_running_content)` now uses static `only_on: :odd`/`:even` footer sections with differing text — the actual v2.7 physical-page-parity mechanism — which render validly through the full pipeline and still prove parity-differing footer content. Verified via live probe (both parity strings present in a 2+ page render).
- **Files modified:** test/support/edge_fixtures.ex
- **Committed in:** `a6173a5`

**5. [Rule 3 - Blocking] Certificate/Ticket text_wrap length capped to fit tight regions**
- **Found during:** Task 1
- **Issue:** A 300/400-byte body/terms string overflowed Certificate's and Ticket's vertically-tight free-text regions (`paginate/:content_overflow`). Live probe: both fit up to ~120 bytes, overflow at ~160.
- **Fix:** Both fixtures use a 120-byte wrapping string — still multi-line (proves wrapping) yet fits.
- **Files modified:** test/support/edge_fixtures.ex
- **Committed in:** `6a31159`

---

**Total deviations:** 5 auto-fixed (2× Rule 1, 3× Rule 3). All are fixture-construction adaptations that keep every cell a VALID rendering fixture; none touched `lib/`. No scope creep.

**Impact on plan:** None on scope or the 62-cell coverage contract. Two adaptations (#3, #4) surface pre-existing product observations worth noting for a future phase (see Threat Flags / Issues).

## Issues Encountered
- **Receipt opts-forwarding gap:** `Receipt.page_template/1` does not whitelist recipe-level opts before `struct!(PageTemplate, ...)`, so any non-template opt passed to `Receipt.document/2` crashes. Worked around here (escape-hatch composition); a broader `Keyword.take` fix in `lib/rendro/recipes/receipt.ex` mirroring Invoice/Statement would be a small future robustness patch (deferred — out of this test-only phase's scope).
- **Payslip `rows_per_page` is an approximation:** Payslip has no published `rows_per_page/0` test analog and its capacity depends on a trailing subtotal row + reconciliation reserve; the helper derives capacity from the recipe's own geometry attributes. No test in this plan asserts Payslip's exact page boundary (only that `line_items_60_plus` spans multiple pages, which it does at 65 rows), so the approximation is sufficient.

## User Setup Required
None - no external service configuration required.

## Known Stubs
None. Every `:applies` cell builds a real recipe-shaped document that renders through the actual pipeline; N/A pairs raise loudly.

## Self-Check: PASSED
- `test/support/edge_fixtures.ex` — FOUND
- `test/support/edge_fixtures_test.exs` — FOUND
- Commit `6a31159` — FOUND
- Commit `a6173a5` — FOUND
- `mix test test/support/edge_fixtures_test.exs` — 81 tests, 0 failures
- `mix compile --warnings-as-errors` — clean
