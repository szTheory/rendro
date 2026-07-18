---
phase: 115-invoice-anatomy-upgrade-format-public-promotion-palette-alig
plan: 04
subsystem: recipes
tags: [invoice, decimal, pagination, validation, palette, errors-as-product]

requires:
  - phase: 115-01
    provides: "Frozen sha256 golden of the pre-Phase-115 toy Invoice render (INV-01 baseline), asserted unbroken by every task in this plan"
  - phase: 115-02
    provides: "Rendro.Format public adapter-tier money/1, date/1, label/1 — the routing target for new anatomy money fields"
provides:
  - "Rendro.Recipes.Invoice.validate_data!/1 (private) — instructive ArgumentError boundary for non-map data, missing required keys, malformed optional anatomy fields, Float/Decimal money-type confusion, and totals caller-assertion mismatches"
  - "Rendro.Recipes.Invoice.palette/1 (private) — role map (ink/muted/accent/on_accent/background/surface/rule) defaulting to today's literals; footer_section and all new anatomy blocks read colors from it (S1 seam)"
  - "page_template/1 Keyword.take whitelist — closes the recipe-opts leak so :palette/:formatters thread to sections/2 without reaching struct!(PageTemplate, ...)"
  - "Additive optional Invoice fields :issuer, :customer, :due_date, :terms, :totals — render only when present; toy call (:id, :date, :items only) stays byte-identical"
  - "Decimal money split: new totals fields route through Rendro.Format.money/1; legacy line-item :price stays the literal bare-number \"$#{price}\" interpolation"
  - "Totals block validated via Decimal.equal?/2 (supplied vs. derived Σ items qty × price) and kept with the last table rows across a page break via a conservative per-page capacity reservation"
affects: [116, 117, 118]

tech-stack:
  added: []
  patterns:
    - "Frozen-path preservation: new optional-field rendering is added as NEW blocks (maybe_prepend/maybe_append helpers) around two literally untouched header lines and one untouched body cell, verified every task via the plan-01 sha256 golden"
    - "Uniform per-page capacity reservation (mirrors Statement's CF/BF pattern): since Rendro.Recipes.Pagination.chunk_rows_into_pages/2 accepts only one effective_capacity value, reserving totals-block height on every page (not just the last) guarantees whichever page ends up last always has headroom for the trailing totals block"
    - "Decimal derivation from bare-number legacy fields: item_line_total/1 converts qty (Integer) x legacy price (Integer|Float) into a Decimal via Decimal.new(to_string(price)) for totals-assertion comparison only — never for rendering, preserving the INV-02 byte-compat split"

key-files:
  created: []
  modified:
    - lib/rendro/recipes/invoice.ex
    - test/rendro/recipes/invoice_test.exs
    - test/rendro/recipes/invoice_opts_threading_test.exs

key-decisions:
  - "Task 2's totals rendering (build_totals_blocks/2, Format.money/1 routing, Float-type rejection) was implemented ahead of Task 3's Decimal.equal?/2 assertion + pagination reservation, matching the plan's task split; body_section was written twice (simple append in Task 2, then rewritten to Receipt-style chunked pagination in Task 3) rather than once, since kept-with-last-rows fundamentally required the chunked rewrite anyway."
  - "Chose uniform (every-page) totals-height reservation over a last-page-only reservation, because the shared Rendro.Recipes.Pagination.chunk_rows_into_pages/2 chunker takes a single effective_capacity value for all pages — this is the identical idiom Statement already uses for its brought-forward/carried-forward row reservation."
  - "Reserved totals height is a conservative per-line estimate (@totals_line_height 14pt x active-field count), not a measured value — no public API exists to measure a plain text block's rendered height (only Rendro.measure_rows/4 for tables). This estimate only biases chunking decisions, never rendered geometry, so it cannot introduce byte-compat drift."
  - "Derived subtotal for the Decimal.equal?/2 caller assertion is computed from items (qty x price), not from a Decimal-typed :totals field, because Invoice's legacy line items intentionally keep bare-number (non-Decimal) price per INV-02 — item_line_total/1 converts to Decimal only for this internal comparison."
  - "footer_section now reads its text color from palette(opts).ink instead of an implicit Rendro.Text default — chosen because Rendro.Text's struct default color is already {0, 0, 0} (verified in lib/rendro/text.ex), so explicitly passing colors.ink (default {0,0,0}) produces a structurally identical %Rendro.Text{} and stays byte-identical while giving Task 1 a concrete, testable palette-threading target without touching the two frozen toy header lines."
  - "issuer/customer are permissive maps validated only for is_map (not full shape) — Map.get with defaults avoids MatchError/FunctionClauseError leaks on a map missing :name, consistent with the errors-as-product boundary without over-specifying an anatomy shape the plan did not mandate."

requirements-completed: [INV-01, INV-02, INV-03, INV-06, INV-07]

coverage:
  - id: D1
    description: "Toy call (:id, :date, :items only) renders byte-identically to the pre-Phase-115 frozen sha256 golden across all three tasks; new fields render only when present"
    requirement: "INV-01"
    verification:
      - kind: unit
        ref: "test/rendro/recipes/invoice_byte_identity_test.exs#INV-01 baseline: toy-call byte identity fresh render sha256 matches the frozen pre-Phase-115 golden"
        status: pass
      - kind: unit
        ref: "test/rendro/recipes/invoice_test.exs#optional anatomy fields (INV-01) issuer/customer/due_date/terms renders only when present"
        status: pass
    human_judgment: false
  - id: D2
    description: "New Decimal totals fields route through Rendro.Format.money/1; legacy bare-number :price stays \"$#{price}\"; Float in a new money field and %Decimal{} in legacy :price each raise instructive ArgumentErrors"
    requirement: "INV-02"
    verification:
      - kind: unit
        ref: "test/rendro/recipes/invoice_test.exs#money split (INV-02)"
        status: pass
    human_judgment: false
  - id: D3
    description: ":totals block renders only when supplied, validated via Decimal.equal?/2 against derived items sum (raising Supplied/Derived on mismatch), and stays with the last table rows across a page break via per-page capacity reservation (never keep_together)"
    requirement: "INV-03"
    verification:
      - kind: unit
        ref: "test/rendro/recipes/invoice_test.exs#totals block (INV-03) totals stays with the last rows when the last table page is near capacity"
        status: pass
    human_judgment: false
  - id: D4
    description: "validate_data!/1 raises instructive ArgumentError (What/Where/Why/Next) on non-map data or missing required keys, never leaking BadMapError/FunctionClauseError; the toy call is never rejected"
    requirement: "INV-06"
    verification:
      - kind: unit
        ref: "test/rendro/recipes/invoice_test.exs#validate_data!/1 (INV-06)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Every section reads colors via a private palette(opts); page_template/1's Keyword.take whitelist closes the recipe-opts leak (no KeyError on :palette/:formatters) while top-level opts stays open"
    requirement: "INV-07"
    verification:
      - kind: unit
        ref: "test/rendro/recipes/invoice_opts_threading_test.exs#page_template/1 opts whitelist (INV-07) / palette(opts) seam (INV-07 / S1)"
        status: pass
    human_judgment: false

duration: ~20min
completed: 2026-07-18
status: complete
---

# Phase 115 Plan 04: Invoice Anatomy Upgrade + Palette/Whitelist Seams Summary

**Upgraded `Rendro.Recipes.Invoice` from a toy 3-field recipe to full optional anatomy (issuer/customer/due_date/terms/totals) with a Decimal money split routed through `Rendro.Format.money/1`, an errors-as-product `validate_data!/1` boundary, a `Decimal.equal?/2`-validated totals block kept with the last table rows via per-page capacity reservation, and a `palette(opts)` color seam — while the pre-upgrade toy call keeps rendering byte-identically to the frozen sha256 golden.**

## Performance

- **Duration:** ~20 min
- **Completed:** 2026-07-18T18:41:46Z
- **Tasks:** 3 completed
- **Files modified:** 3 (`lib/rendro/recipes/invoice.ex`, `test/rendro/recipes/invoice_test.exs`, `test/rendro/recipes/invoice_opts_threading_test.exs`)

## Accomplishments
- **Task 1:** Added `validate_data!/1` (non-map + missing-required-key guards, called at the top of `sections/2` and `document/2`), the private `palette(opts)` role map (`ink`/`muted`/`accent`/`on_accent`/`background`/`surface`/`rule`, defaults reproducing today's all-black/white literals), and replaced `page_template/1`'s `Keyword.merge(defaults, opts)` leak with a `Keyword.take` whitelist (mirrors `Statement`). Wired `footer_section` to read its color from `palette(opts).ink` to give the seam a concrete, testable target without touching the frozen toy header lines.
- **Task 2:** Added optional anatomy rendering — `header_section` prepends an issuer block and appends customer/due_date/terms blocks only when `Map.get(data, key)` is non-nil (via new `maybe_prepend/maybe_append` helpers), while the two frozen toy header lines and the legacy `"$#{item.price}"` body cell stay literally unchanged. Added `build_totals_blocks/2` (Subtotal/Tax/Discount/Total lines routed through `Rendro.Format.money/1`), and extended `validate_data!/1` with `is_map`/`Date`/`String` shape guards for the new optional fields plus Float/Decimal money-type-confusion rejection (legacy `:price` rejects `%Decimal{}`; new `:totals.*` fields reject `Float`).
- **Task 3:** Rewrote `body_section` to per-page chunked table rendering (mirrors `Receipt`'s `Rendro.measure_rows` + `Pagination.chunk_rows_into_pages` pattern) — proven byte-identical for the toy call (single page, `break_before: false` structurally equals the prior unchunked block). Added a conservative `@totals_line_height`-based per-page capacity reservation so the final table page always has headroom for the trailing totals block (uniform reservation across all pages, mirroring Statement's CF/BF idiom, since the shared chunker takes one capacity value). Added `maybe_validate_totals!/1`, validating supplied `:totals.subtotal`/`:totals.total` against a derived value (`Σ items qty × price` via `Decimal.add/2`) using `Decimal.equal?/2` (never `==`), raising an instructive Supplied/Derived `ArgumentError` on mismatch.
- Full `mix test`: 1269 tests + 12 doctests + 4 properties, 0 failures. `mix compile --warnings-as-errors`: clean. `mix format --check-formatted`: clean.

## Task Commits

Each task was committed atomically:

1. **Task 1: validate_data!/1 (INV-06) + palette/1 + page_template/1 whitelist (INV-07)** - `9e23b0d` (feat)
2. **Task 2: Additive optional anatomy fields + Decimal money split (INV-01, INV-02)** - `6c1aac0` (feat)
3. **Task 3: Totals block — Decimal.equal? assertion + kept with last rows (INV-03)** - `79d2d2c` (feat)

## Files Created/Modified
- `lib/rendro/recipes/invoice.ex` - `validate_data!/1`, `palette/1`, `page_template/1` whitelist, optional anatomy field rendering, `build_totals_blocks/2`, chunked `body_section` with totals-height reservation, `maybe_validate_totals!/1`.
- `test/rendro/recipes/invoice_test.exs` - INV-06 validation cases, INV-01 present-vs-absent anatomy cases, INV-02 money-split cases (bare price / Format.money / Float-reject / Decimal-in-legacy-price-reject), INV-03 totals cases (absent/present/mismatch/kept-with-last-rows boundary test).
- `test/rendro/recipes/invoice_opts_threading_test.exs` - INV-07 `page_template/1` whitelist cases (`:palette`/`:formatters` no `KeyError`) and `palette(opts)` seam cases (override changes only the footer section).

## Decisions Made
See `key-decisions` in frontmatter. Summary: body_section's chunked-pagination rewrite was deferred to Task 3 (matching the plan's task split) even though it's used by Task 2's simple totals-append too; totals-height reservation is applied uniformly to every page (not just the last) since the shared chunker only accepts one capacity value; the Decimal.equal?/2 assertion derives its comparison value from items (qty × price) rather than from a stored Decimal field, since legacy items intentionally stay bare-number typed.

## Deviations from Plan
None - plan executed exactly as written. The footer_section palette wiring in Task 1 was an implementation detail needed to give the palette seam a concrete, byte-identity-preserving test target (Rendro.Text's default color is already `{0,0,0}`, so this is not a behavior change) — not a deviation from the plan's INV-07 acceptance criteria, which explicitly require "every section reads colors via a private `palette(opts)`."

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
`Rendro.Recipes.Invoice` now supports full optional anatomy (issuer/customer/due_date/terms/totals), Decimal-correct money handling, errors-as-product validation, a palette color seam ready for Milestone B's `Rendro.Theme`, and a `page_template/1` whitelist that leaves top-level `opts` open for future `theme:` plumbing. The pre-upgrade toy call remains byte-identical to the plan-01 frozen golden. Phase 115 (Invoice anatomy + `Format` public promotion + `cell_align`/`palette` seams) is now fully implemented across all 4 plans. No blockers for Phase 116 (new families — Payslip & Ticket), which can reuse the `palette(opts)` pattern and the `validate_data!/1` errors-as-product shape established here.

---
*Phase: 115-invoice-anatomy-upgrade-format-public-promotion-palette-alig*
*Completed: 2026-07-18*

## Self-Check: PASSED

- FOUND: lib/rendro/recipes/invoice.ex
- FOUND: test/rendro/recipes/invoice_test.exs
- FOUND: test/rendro/recipes/invoice_opts_threading_test.exs
- FOUND: .planning/phases/115-invoice-anatomy-upgrade-format-public-promotion-palette-alig/115-04-SUMMARY.md
- FOUND: 9e23b0d
- FOUND: 6c1aac0
- FOUND: 79d2d2c
