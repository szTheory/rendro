---
phase: 121-light-dark-background-fill-mechanism-all-7-recipes
plan: 03
subsystem: recipes
tags: [elixir, pdf, theme, dark-mode, payslip, invoice, receipt, branded-invoice, ticket, background-fill]

# Dependency graph
requires:
  - phase: 121-light-dark-background-fill-mechanism-all-7-recipes
    provides: "Rendro.Recipes.Background helper (emit?/1, region/2, section/3) and the page_template/1+sections/2 dual-gate wiring shape, proven on Statement (121-01)"
provides:
  - "Payslip, Invoice, Receipt, BrandedInvoice, Ticket all wire the shared :background region+section into page_template/1 and sections/2, gated on Background.emit?(palette(opts))"
  - "BrandedInvoice's own explicit @page_width/@page_height (595.28 x 841.89) module attributes, mirroring the %Rendro.PageTemplate{} struct default it has always implicitly relied on"
  - "All 7 recipes (with Statement 121-01 and Certificate 121-02) now carry the shared :background region — the phase's core dark-mode mechanism is complete across the full recipe family"
affects: [121-04-docs-contract, 122-typography-type-scale]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "page_template/1 must resolve palette(opts) directly (not just inside section builders) whenever it needs to gate the shared :background region — this is a required consequence of Background.emit?/1 needing the resolved colors before regions are built, not a Certificate/Statement-only pattern"
    - "PLUMB-02 whitelist tests that pass a placeholder theme: :ignored atom to page_template/1 (to prove the Keyword.take whitelist prevents a KeyError) must use a value Rendro.Theme.resolve/1 actually accepts (e.g. theme: %{}) once page_template/1 resolves palette(opts) for real"

key-files:
  created: []
  modified:
    - lib/rendro/recipes/payslip.ex
    - lib/rendro/recipes/invoice.ex
    - lib/rendro/recipes/receipt.ex
    - lib/rendro/recipes/branded_invoice.ex
    - lib/rendro/recipes/ticket.ex
    - test/rendro/recipes/receipt_byte_identity_test.exs
    - test/rendro/recipes/branded_invoice_byte_identity_test.exs

key-decisions:
  - "BrandedInvoice gained explicit @page_width 595.28 / @page_height 841.89 module attributes (it previously had none, relying implicitly on %Rendro.PageTemplate{}'s own A4 struct default) so the background fill covers the FULL rendered page — never the 451.28pt content-box width its :body region happens to use"
  - "Receipt and BrandedInvoice's PLUMB-02 whitelist tests (`page_template(theme: :ignored)`) were fixed to `theme: %{}` — page_template/1 now resolves palette(opts) directly to gate the background region, so the placeholder atom no longer round-trips through Rendro.Theme.resolve/1 (a keyword/map/%Theme{} value is required, not a bare atom)"

patterns-established: []

requirements-completed: [MODE-02]

coverage:
  - id: D1
    description: "Payslip, Invoice, Receipt each wire the shared :background region+section into page_template/1 and sections/2, gated on Background.emit?(palette(opts)), using their own resolved page dims (geometry(opts) for Payslip, @page_width/@page_height for Invoice/Receipt)"
    requirement: MODE-02
    verification:
      - kind: unit
        ref: "test/rendro/recipes/payslip_byte_identity_test.exs, invoice_byte_identity_test.exs, receipt_byte_identity_test.exs — frozen sha256 values UNCHANGED (no re-bless)"
        status: pass
      - kind: unit
        ref: "test/rendro/recipes/no_inline_color_literals_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "BrandedInvoice and Ticket wire the shared :background region+section into page_template/1 and sections/2, gated on Background.emit?(palette(opts)); BrandedInvoice uses its own full A4 page dims (595.28 x 841.89), never the 451.28pt content-box width; Ticket uses geometry(opts) -> g.pw/g.ph (A6 default)"
    requirement: MODE-02
    verification:
      - kind: unit
        ref: "test/rendro/recipes/branded_invoice_byte_identity_test.exs, ticket_byte_identity_test.exs — frozen sha256 values UNCHANGED (no re-bless)"
        status: pass
      - kind: unit
        ref: "test/rendro/recipes/no_inline_color_literals_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "All 5 recipes' no-theme (light) renders stay byte-identical to v2.10 — text draw-sites and palette/1 nil-branches were verify-only, not edited"
    requirement: MODE-02
    verification:
      - kind: unit
        ref: "full test/rendro/recipes/ suite (343 tests, 3 doctests) — 0 failures"
        status: pass
      - kind: other
        ref: "git diff --stat lib/rendro/recipes/{payslip,invoice,receipt,branded_invoice,ticket}.ex shows edits confined to page_template/1 and sections/2 only"
        status: pass
    human_judgment: false

# Metrics
duration: 20min
completed: 2026-07-27
status: complete
---

# Phase 121 Plan 03: Background Wiring for Payslip, Invoice, Receipt, BrandedInvoice, Ticket Summary

**All 5 remaining verify-only recipes (Payslip, Invoice, Receipt, BrandedInvoice, Ticket) wire the shared `Rendro.Recipes.Background` region+section into `page_template/1`/`sections/2` on their own resolved page dims, completing dark-mode-for-free across all 7 recipes with zero light-path byte drift.**

## Performance

- **Duration:** 20 min
- **Started:** 2026-07-27T20:20:00-04:00 (approx)
- **Completed:** 2026-07-27T20:42:27-04:00
- **Tasks:** 2
- **Files modified:** 7 (5 recipes, 2 test fixes)

## Accomplishments
- Wired `page_template/1` + `sections/2` in Payslip, Invoice, Receipt, BrandedInvoice, and Ticket to prepend the shared `:background` region/section first, both gated on the identical `Background.emit?(palette(opts))` predicate (Pitfall 3 dual-gate invariant — region and section can never disagree)
- Resolved each recipe's own page dims correctly: Payslip and Ticket via `geometry(opts)` → `g.pw`/`g.ph`; Invoice and Receipt via existing `@page_width`/`@page_height` constants; BrandedInvoice via two newly-added explicit `@page_width 595.28` / `@page_height 841.89` module attributes mirroring the `%Rendro.PageTemplate{}` struct's own A4 default it had always implicitly relied on (never the 451.28pt content-box width)
- Left every text draw-site and every `palette/1` nil-branch completely untouched — all 5 recipes were text-seam VERIFY-ONLY (D-02); confirmed each already carries `background` in its palette nil-branch and swappable `color:` roles on every `Rendro.text`
- All 5 frozen `*_byte_identity_test.exs` goldens pass with UNCHANGED sha256 values (no re-bless) — light/no-theme paths stay byte-identical to v2.10
- Full `test/rendro/recipes/` suite green (343 tests, 3 doctests, 0 failures); the phase's shared `theme_mode_background_golden_test.exs` also green (7 tests)
- All 7 recipes (Statement 121-01, Certificate 121-02, and these 5) now carry the shared `:background` region — the phase's core MODE-02 mechanism is structurally complete across the entire recipe family

## Task Commits

Each task was committed atomically:

1. **Task 1: Wire background region+section into Payslip, Invoice, Receipt** - `054e238` (feat)
2. **Task 2: Wire background region+section into BrandedInvoice and Ticket** - `9906810` (feat)

## Files Created/Modified
- `lib/rendro/recipes/payslip.ex` - `page_template/1`/`sections/2` wired to prepend the background region/section, gated on `Background.emit?(palette(opts))`, dims from `geometry(opts)`
- `lib/rendro/recipes/invoice.ex` - Same wiring shape, dims from `@page_width`/`@page_height`
- `lib/rendro/recipes/receipt.ex` - Same wiring shape, dims from `@page_width`/`@page_height`
- `lib/rendro/recipes/branded_invoice.ex` - Same wiring shape; gained new `@page_width`/`@page_height` module attributes (595.28 x 841.89) it previously had none of
- `lib/rendro/recipes/ticket.ex` - Same wiring shape, dims from `geometry(opts)` (A6 default)
- `test/rendro/recipes/receipt_byte_identity_test.exs` - PLUMB-02 whitelist test fixed: `theme: :ignored` → `theme: %{}`
- `test/rendro/recipes/branded_invoice_byte_identity_test.exs` - Same PLUMB-02 whitelist test fix

## Decisions Made
- BrandedInvoice's background dims are the recipe's own explicit `@page_width`/`@page_height` constants (595.28 x 841.89) rather than reading `%Rendro.PageTemplate{}`'s struct defaults indirectly — makes the "full page, not content-box" invariant self-documenting and matches the pattern every other recipe already uses (a named module attribute, not an implicit struct default)
- Fixed (did not merely work around) the two stale PLUMB-02 whitelist tests rather than leaving them broken — their premise (`page_template/1` never resolves `:theme`) was true before this plan and became false by design once `page_template/1` needed `palette(opts)` to gate the background region; `theme: %{}` still exercises the original intent (proving `:theme` is filtered from `struct!/2`'s keys and reaches `palette/1` without a `KeyError`)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fixed stale PLUMB-02 whitelist test in receipt_byte_identity_test.exs**
- **Found during:** Task 1 verification (`mix test test/rendro/recipes/receipt_byte_identity_test.exs`)
- **Issue:** `test "page_template/1 does not raise KeyError on :palette / :theme opts"` called `Receipt.page_template(theme: :ignored)`. Before this plan, `page_template/1` never called `palette(opts)`, so the placeholder atom `:ignored` was never actually resolved — the test only verified the `Keyword.take` whitelist didn't reach `struct!/2`. This plan's wiring requires `page_template/1` to call `palette(opts)` directly (to gate the background region), which now resolves `:theme` for real via `Rendro.Theme.resolve/1` — and `:ignored` is not a valid `Rendro.Theme.resolve/1` input (not a keyword list, map, or `%Theme{}` struct), so it raised `FunctionClauseError` in `Theme.normalize/1`.
- **Fix:** Changed `theme: :ignored` to `theme: %{}` — an empty map is valid `Theme.resolve/1` input (resolves to theme defaults) and still exercises the whitelist property the test was written to prove.
- **Files modified:** `test/rendro/recipes/receipt_byte_identity_test.exs`
- **Verification:** `mix test test/rendro/recipes/receipt_byte_identity_test.exs` — 3 tests, 0 failures
- **Committed in:** `054e238` (Task 1 commit)

**2. [Rule 3 - Blocking] Fixed the same stale PLUMB-02 whitelist test in branded_invoice_byte_identity_test.exs**
- **Found during:** Task 2 verification (`mix test test/rendro/recipes/branded_invoice_byte_identity_test.exs`)
- **Issue:** Identical root cause to deviation #1 — `BrandedInvoice.page_template(theme: :ignored)` raised the same `FunctionClauseError` once `page_template/1` started calling `palette(opts)` directly.
- **Fix:** Changed `theme: :ignored` to `theme: %{}`.
- **Files modified:** `test/rendro/recipes/branded_invoice_byte_identity_test.exs`
- **Verification:** `mix test test/rendro/recipes/branded_invoice_byte_identity_test.exs` — 3 tests, 0 failures
- **Committed in:** `9906810` (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (both Rule 3 - Blocking)
**Impact on plan:** Both fixes were necessary consequences of this plan's own required wiring shape (page_template/1 resolving palette(opts) to gate the background region), not scope creep — the underlying tests' original intent (proving the opts whitelist prevents a KeyError) is fully preserved with a valid placeholder value.

## Issues Encountered
- `mix format --check-formatted` flagged two PRE-EXISTING unformatted files (`test/rendro/recipes/payslip_opts_threading_test.exs`, `test/rendro/recipes/theme_mode_background_golden_test.exs`) — neither touched by this plan; confirmed out of scope (SCOPE BOUNDARY) and left untouched.
- `ticket.ex`'s new `base_sections` line exceeded the formatter's line length after editing; `mix format lib/rendro/recipes/ticket.ex` auto-wrapped it (only this plan's own file, no scope creep).
- Full `mix test` surfaces the same 2 pre-existing, unrelated failures documented in 121-01's SUMMARY (`test/docs_contract/dx_local_reproducibility_claims_test.exs` — missing archived Phase-113 planning artifacts, unrelated to this plan).

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- All 7 recipes now carry the shared `:background` region+section wiring; the phase's dark-mode mechanism is structurally complete across the full recipe family.
- Ready for 121-04 (docs/contract closure — support-matrix rows and boundary claims) if not already covered; per STATE.md, 121-04 already executed and committed (`8fc0c88`) ahead of this plan in commit order, covering the theming support-matrix and overclaim tripwire work.
- No blockers.

---
*Phase: 121-light-dark-background-fill-mechanism-all-7-recipes*
*Completed: 2026-07-27*

## Self-Check: PASSED

All 7 modified files found on disk; both task commits (`054e238`, `9906810`) found in git log.
