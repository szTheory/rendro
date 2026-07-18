---
phase: 116-new-families-payslip-ticket
plan: 02
subsystem: recipes
tags: [elixir, pdf, payslip, decimal, pagination, unicode-font-fallback, tdd]

# Dependency graph
requires:
  - phase: 116-new-families-payslip-ticket
    provides: "116-01: Rendro.Recipes.Pagination.label_resolver/2 (D-18), validate_labels!/2 + validate_formatters!/2 (D-19)"
provides:
  - "Rendro.Recipes.Payslip — new adapter-tier recipe module: document/2, page_template/1, sections/2 (3-rung pattern)"
  - "D-11 net-pay visual anchor (single :summary region, zero-height backdrop path block stacking trick)"
  - "D-12 combined 6-column earnings/deductions ledger with native multi-page pagination"
  - "D-13 gross-to-net Decimal.equal?/2 reconciliation (validate + kept-with-last render)"
  - "D-17 jurisdiction-neutral caller :description passthrough, test-enforced negative case"
  - "Unicode fallback font pattern (vendored B612 registered behind built-in Helvetica) for recipes rendering arbitrary caller text"
affects: [116-03-ticket, 116-04-registration, 117-edge-case-stress-matrix, 118-demos-gallery-docs]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Geometry-derived page_template/1 (Rendro.PageSize.resolve/2 + margins, zero hardcoded A4 numerics), mirroring certificate.ex rather than invoice.ex's fixed module attributes"
    - "Single-region visual-anchor composition: a backdrop %Rendro.Path{} block declared with explicit height: 0 does not advance anchor_region_blocks/3's per-region stacking cursor, so following text blocks paint on top of the full-height backdrop instead of being pushed below it — no extra region needed"
    - "Unicode fallback font registration (register_embedded_font + register_font with fallbacks: + put_default_font) applied to BOTH the real document/2 AND any throwaway Rendro.Document.new() used purely for Rendro.measure_rows/4, since measurement itself needs glyph coverage before a full document exists"
    - "glyph_safe/1 display-only character substitution (middot -> bullet) — the underlying data/fixture strings keep the exact spec'd masking token; only the rendered text swaps to a glyph the active font chain actually supports"

key-files:
  created:
    - lib/rendro/recipes/payslip.ex
    - test/rendro/recipes/payslip_test.exs
    - test/rendro/recipes/payslip_byte_identity_test.exs
  modified: []

key-decisions:
  - "Task 1 shipped a minimal document/2 stub (validate_data! + page_template only, no sections) purely to give validate_data!'s errors-as-product behavior a public entry point to test via TDD RED/GREEN, before Task 2 built sections/2 and replaced document/2 with the full assembly — the plan's own body_section stub-then-replace idiom applied one rung higher."
  - "Registered the already-vendored priv/branded/fonts/B612-Regular.ttf as a silent, always-on unicode fallback font (never caller-configurable) behind the built-in Helvetica default, because the built-in Helvetica metrics table is ASCII-only (32-126) and D-17 requires arbitrary accented caller :description content to render successfully, never be rejected or crash with :unsupported_glyph."
  - "The D-14 masking token stays the literal middot '·' (U+00B7) in all data/fixture strings exactly as specified and test-enforced (String.contains?/2) — but since neither built-in Helvetica nor B612 has a middot glyph, the RENDERED text swaps it for a bullet '•' (U+2022, present in B612) via glyph_safe/1, display-only, never touching the underlying data."
  - "__default_labels__/0 is a @doc false test-only accessor for the @default_labels module attribute (module attributes are compile-time-only, not runtime-inspectable) — excluded from the public API manifest the same way Sign/Protect's redact_* helpers are."

patterns-established:
  - "geometry(opts) private helper computing all page_template/1 x/y/width/height math once, reused by section builders (summary_section, body_section) that need the same region dimensions for D-11 band sizing and D-12 table capacity — avoids re-deriving PageSize.resolve/2 math in multiple places."
  - "derive_totals(data) is the single source of gross/deductions/net/*_ytd Decimal folds, shared verbatim by validate_reconciliation!/1 (validate half) and body_section/2 (render half) so the D-13 assertion and the rendered reconciliation line can never drift from each other."

requirements-completed: [FAM-01, FAM-03]

coverage:
  - id: D1
    description: "Rendro.Recipes.Payslip.document/2 renders {:ok, pdf} for a well-formed fictional payslip via the 3-rung pattern (document/2 -> page_template/1 -> sections/2)"
    requirement: "FAM-01"
    verification:
      - kind: unit
        ref: "test/rendro/recipes/payslip_test.exs#document/2 renders {:ok, pdf} starting with the PDF magic bytes"
        status: pass
    human_judgment: false
  - id: D2
    description: "Net pay is the single largest/heaviest text element on the rendered page (D-11, hierarchy=5) — test-asserted via a recursive %Rendro.Text{} size collector across all sections/blocks/tables, not eyeballed"
    requirement: "FAM-01"
    verification:
      - kind: unit
        ref: "test/rendro/recipes/payslip_test.exs#the net-pay anchor's value is the single largest text element on the page (D-11)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Earnings/deductions render as ONE combined 6-column ledger table (Earnings|Current|YTD|Deductions|Current|YTD) with money right-aligned via cell_align, zipped/blank-padded rows, bold-emphasis subtotal row as the table's last data row"
    requirement: "FAM-01"
    verification:
      - kind: unit
        ref: "test/rendro/recipes/payslip_test.exs#1 earnings + 1 deductions line renders with right-aligned formatted amounts"
        status: pass
    human_judgment: false
  - id: D4
    description: "The combined ledger paginates natively across pages via Pagination.chunk_rows_into_pages/2 when line count is large, repeating the 6-column header on every page, with the gross-to-net reconciliation block kept with the last table page only"
    requirement: "FAM-01"
    verification:
      - kind: unit
        ref: "test/rendro/recipes/payslip_test.exs#overflowing earnings paginate across 2+ pages, repeating the header, reconciliation only on the last page"
        status: pass
    human_judgment: false
  - id: D5
    description: "net_pay always equals gross earnings minus total deductions, asserted via Decimal.equal?/2 (never ==); a mismatch raises an instructive four-part ArgumentError naming both supplied and derived values"
    requirement: "FAM-01"
    verification:
      - kind: unit
        ref: "test/rendro/recipes/payslip_test.exs#raises an instructive ArgumentError naming the net_pay mismatch"
        status: pass
    human_judgment: false
  - id: D6
    description: "Float anywhere in earnings/deductions amounts, ytd fields, or net_pay raises an instructive ArgumentError (never ArithmeticError/BadMapError) instead of producing inexact financial output"
    requirement: "FAM-01"
    verification:
      - kind: unit
        ref: "test/rendro/recipes/payslip_test.exs#raises an instructive ArgumentError (not ArithmeticError) for a Float earnings amount"
        status: pass
      - kind: unit
        ref: "test/rendro/recipes/payslip_test.exs#validate_data!/1 (D-15 shape/type checks) (6 Float/type-rejection cases)"
        status: pass
    human_judgment: false
  - id: D7
    description: "Jurisdiction-specific line content lives in caller-supplied :description strings, never a library-enumerated type — proven by a negative test asserting arbitrary non-English/unrelated :description strings round-trip unchanged with no jurisdiction-keyword allowlist rejecting them (D-17)"
    requirement: "FAM-01"
    verification:
      - kind: unit
        ref: "test/rendro/recipes/payslip_test.exs#D-17: arbitrary non-English/unrelated :description strings round-trip unchanged, no jurisdiction-keyword filtering"
        status: pass
    human_judgment: false
  - id: D8
    description: "Every color read in Payslip's section builders resolves a role from palette(opts) (S1) — no inlined {0,0,0}/raw {r,g,b} literal anywhere outside palette/1's own default map (grep-verified, not eyeballed)"
    requirement: "FAM-01"
    verification:
      - kind: other
        ref: "grep -v '^\\s*#' lib/rendro/recipes/payslip.ex | grep -Ec 'color: \\{[0-9]|fill: \\{[0-9]' == 0"
        status: pass
    human_judgment: false
  - id: D9
    description: "@default_labels ships a complete jurisdiction-neutral English label set (13 keys) so Payslip.document(fixture) with zero :labels/:formatters opts renders correctly with no FunctionClauseError"
    requirement: "FAM-01"
    verification:
      - kind: unit
        ref: "test/rendro/recipes/payslip_test.exs#@default_labels (D-18) ships all 13 jurisdiction-neutral English label keys"
        status: pass
      - kind: unit
        ref: "test/rendro/recipes/payslip_test.exs#does NOT raise for a well-formed minimal payload (empty :deductions is valid)"
        status: pass
    human_judgment: false
  - id: D10
    description: "page_template/1 implements the D-14 4-region template (:header/:summary/:body/:footer); fixture employee/employer identifiers are masked (middot token, never a full-length unmasked SSN/bank-style numeric id), test-enforced via ExUnit regex assertions"
    requirement: "FAM-01"
    verification:
      - kind: unit
        ref: "test/rendro/recipes/payslip_test.exs#page_template/1 (region names + page_size geometry variance)"
        status: pass
      - kind: unit
        ref: "test/rendro/recipes/payslip_test.exs#PII masking is test-enforced (D-14, FAM-01)"
        status: pass
    human_judgment: false
  - id: D11
    description: "validate_data!/1 enforces the D-15 data map contract exactly: employer.name/employee.name/period.from,to/pay_date/earnings(non-empty)/deductions/net_pay required, totals/payment_method optional"
    requirement: "FAM-01"
    verification:
      - kind: unit
        ref: "test/rendro/recipes/payslip_test.exs#validate_data!/1 (D-15 shape/type checks) (full describe block)"
        status: pass
    human_judgment: false
  - id: D12
    description: "No jurisdiction profile or named :profile atom exists anywhere — :palette/:labels/:formatters are three orthogonal override seams merged over recipe-shipped defaults, the same convention as the S1 palette seam (D-16); :labels opts override renders end to end"
    requirement: "FAM-03"
    verification:
      - kind: unit
        ref: "test/rendro/recipes/payslip_test.exs#:labels opts override the net-pay label end to end"
        status: pass
      - kind: other
        ref: "grep -c ':profile' lib/rendro/recipes/payslip.ex == 0 (structural review — no :profile atom anywhere in the file)"
        status: pass
    human_judgment: false
  - id: D13
    description: "Two deterministic renders of the same fixture are byte-identical; a frozen sha256 golden (computed by actually running the render via mix run, never hand-typed) matches a fresh render"
    requirement: "FAM-01"
    verification:
      - kind: unit
        ref: "test/rendro/recipes/payslip_byte_identity_test.exs#D-13/D-14 byte-identity baseline (both tests)"
        status: pass
    human_judgment: false

duration: 17min
completed: 2026-07-18
status: complete
---

# Phase 116 Plan 02: Payslip Recipe (Net-Pay Anchor, Combined Ledger, D-13 Reconciliation) Summary

**`Rendro.Recipes.Payslip` shipped end-to-end on the 3-rung pattern: a geometry-derived 4-region template with a zero-height-backdrop net-pay anchor band, a D-12 combined 6-column earnings/deductions ledger that paginates natively, and a `Decimal.equal?/2`-asserted D-13 gross-to-net reconciliation kept with the last page — plus a reusable vendored-font unicode-fallback pattern so D-17's "never reject caller content" promise actually renders accented text instead of crashing.**

## Performance

- **Duration:** ~17 min
- **Started:** 2026-07-18T19:24:58-04:00 (approx., first Task-1 commit)
- **Completed:** 2026-07-18T19:41:50-04:00
- **Tasks:** 3
- **Files modified:** 3 (1 lib file created, 2 test files created)

## Accomplishments
- `Rendro.Recipes.Payslip` — new adapter-tier module: `document/2`, `page_template/1`, `sections/2`, all geometry derived from `Rendro.PageSize.resolve/2` (zero hardcoded A4 numerics, both A4 and US Letter proven via `page_size:` opt)
- D-11 net-pay visual anchor: single `:summary` region, backdrop `%Rendro.Path{}` block with explicit `height: 0` so it doesn't advance `anchor_region_blocks/3`'s per-region stacking cursor — label+value text paint on top of the full-height tinted band with zero extra regions; value renders at size 27, test-asserted as the global-max text size on the page (never eyeballed)
- D-12 combined ledger: 6-column table (Earnings|Current|YTD|Deductions|Current|YTD), rows zipped/blank-padded, money right-aligned via `cell_align`, bold-emphasis subtotal row as the table's own last data row, native multi-page pagination via `Pagination.chunk_rows_into_pages/2`
- D-13 reconciliation: `Decimal.equal?/2` assertion (never `==`) in `validate_data!/1` raising an instructive four-part `ArgumentError` naming both supplied and derived `net_pay`; optional `:totals` (gross/deductions/net/\*\_ytd) independently asserted when present; the render half (equation + optional YTD trio) appends only after the last ledger table block, height-reserved on every page so the last page always has room
- D-17 proven test-enforced: arbitrary non-English/unrelated `:description` strings (including accented "Impôt sur le revenu") round-trip unchanged through `validate_data!/1` and `body_section/2` — no jurisdiction-keyword allowlist exists anywhere in the file
- D-14 PII masking test-enforced (not prose-only): fixture's masked employee id / payment method both contain the middot `·` masking token and both `refute` unmasked SSN/bank-style numeric-id regex patterns
- Full errors-as-product `validate_data!/1`: required-key, shape, type, and reconciliation violations all raise instructive four-part `ArgumentError`s — never a leaked `BadMapError`/`ArithmeticError`
- Byte-identity holds across two deterministic renders (frozen sha256 golden, computed via an actual `mix run`, never hand-typed)
- Source-assertion clean: `grep`-verified zero inlined `color:`/`fill:` `{r,g,b}` literals outside `palette/1`'s own default map

## Task Commits

Each task was committed atomically (strict TDD RED/GREEN pairs):

1. **Task 1: Geometry, palette, @default_labels, and validate_data!/1 shape/type checks**
   - `7818d9c` (test) — RED: 10 failing tests for page_template geometry, @default_labels keys, validate_data! shape/type checks, D-14 PII masking assertions
   - `a05155d` (feat) — GREEN: `page_template/1`, `palette/1` (S1, verbatim from Invoice), `@default_labels` (13 D-18 keys), `validate_data!/1` (D-15 shape/type checks, no reconciliation yet), minimal `document/2` stub
2. **Task 2: sections/2, document/2, header/summary/footer content, D-11 net-pay visual anchor**
   - `7c6e584` (test) — RED: 4 failing tests for sections/2 region coverage, document/2 render success, D-11 max-text-size assertion, :labels opts override
   - `0b11d83` (feat) — GREEN: `sections/2`, full `document/2` (mirrors invoice.ex:172-186), `header_section/2`, `summary_section/2` (D-11 anchor), `body_section/2` stub, `footer_section/2`; registered the B612 unicode fallback font; bumped `header_h` 64->88pt to fit the denser 4-5 line identity block
3. **Task 3: Combined ledger table, pagination, D-13 reconciliation, byte-identity**
   - `d091588` (test) — RED: 5 failing tests for the combined ledger, overflow pagination, net_pay mismatch, Float rejection, D-17 negative case + new `payslip_byte_identity_test.exs`
   - `bbf0ad4` (feat) — GREEN: real `body_section/2` (D-12 ledger + subtotal row), `validate_reconciliation!/1` + `maybe_validate_totals!/2` (D-13 validate half), `build_reconciliation_blocks/5` (D-13 render half), `derive_totals/1` shared fold, byte-identity golden computed and frozen

**Plan metadata:** (final docs commit follows this SUMMARY)

_Note: All three tasks used strict TDD RED/GREEN — tests written and confirmed failing before any implementation code was added, per `tdd="true"` on every task._

## Files Created/Modified
- `lib/rendro/recipes/payslip.ex` — new module (`@moduledoc tags: [:adapter]`), 3-rung pattern, D-11/D-12/D-13/D-14/D-16/D-17/D-18 all implemented
- `test/rendro/recipes/payslip_test.exs` — new file, 21 tests across page_template/1, @default_labels, validate_data!/1, PII masking, sections/2, document/2, D-11 anchor, D-12 ledger, D-13 reconciliation, D-17
- `test/rendro/recipes/payslip_byte_identity_test.exs` — new file, 2 tests (deterministic byte-identity + frozen sha256 golden)

## Decisions Made
- Task 1 shipped a minimal `document/2` stub (validate + template only) purely to give `validate_data!/1`'s TDD tests a public entry point before Task 2 built the real `sections/2`/`document/2` — the same stub-then-replace idiom the plan itself specifies for `body_section/2` one rung higher.
- Registered the already-vendored `priv/branded/fonts/B612-Regular.ttf` (previously used only by Certificate/BrandedInvoice branding) as a silent, always-on unicode fallback font behind the built-in Helvetica default, applied in both `document/2` and `body_section/2`'s own `Rendro.measure_rows/4` throwaway document.
- The D-14 masking token in DATA stays the literal middot `·` exactly as spec'd; the RENDERED text swaps it for bullet `•` (present in B612) via `glyph_safe/1` — display-only, the underlying fixture/data strings are never touched, so the D-14 `String.contains?(field, "·")` test still holds exactly as written.
- `__default_labels__/0` is a `@doc false` test-only accessor for the `@default_labels` module attribute (unreachable at runtime otherwise) — excluded from the public API manifest the same way `Sign`/`Protect`'s `redact_*` helpers are.
- `header_h` bumped from the plan's "~64pt" guidance to 88pt after the real 4-5 line identity block (employer name+address, employee name+id+tax_code, pay period, pay date) measured taller than 64pt and hit `:content_overflow` — within the plan's explicitly stated discretion ("Exact point sizes ... are guidance-level").
- Table columns: `[{:share, 2}, {:fixed, 55}, {:fixed, 55}, {:share, 2}, {:fixed, 55}, {:fixed, 55}]` — within the plan's explicit "e.g." discretion for the 6-column layout.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Registered a vendored unicode fallback font — the built-in Helvetica metrics table is ASCII-only (32-126)**
- **Found during:** Task 2 (document/2 render) and Task 3 (D-17 accented-description test)
- **Issue:** `lib/rendro/pdf/font.ex`'s built-in Helvetica width table only covers codepoints 32-126. Rendering the fixture's middot masking token (`·`, U+00B7) or D-17's required accented test string ("Impôt sur le revenu") with no font registered aborted the whole render with a typed `{:unsupported_glyph, ...}` pipeline error — a hard blocker for both the plan's own explicit D-17 behavior case ("renders `{:ok, pdf}` ... including the non-ASCII 'Impôt sur le revenu' string") and for rendering the fixture's own masked identifiers.
- **Fix:** Registered the already-vendored `priv/branded/fonts/B612-Regular.ttf` (used elsewhere by Certificate/BrandedInvoice branding) as a silent, always-on `fallbacks:` entry behind the built-in Helvetica default (`with_unicode_fallback_font/1`), applied to both `document/2`'s real document and `body_section/2`'s own measurement-only `Rendro.Document.new()`. B612 covers common Latin-1 accented characters (confirmed "ô" present) but not middot, so the D-14 masking token is separately handled by `glyph_safe/1` (display-only substitution to bullet `•`, which B612 does have) — the underlying data/fixture strings keep the literal middot untouched.
- **Files modified:** lib/rendro/recipes/payslip.ex
- **Verification:** `mix test test/rendro/recipes/payslip_test.exs test/rendro/recipes/payslip_byte_identity_test.exs` green (23/23); full suite green (1310 tests, 0 failures) confirming no regression to other recipes/font paths.
- **Committed in:** `0b11d83` (font registration + `glyph_safe/1`), `bbf0ad4` (measurement-document fallback for `body_section/2`)

**2. [Rule 1 - Test-design correction] Adjusted raw-PDF-bytes assertions to account for embedded-font glyph-ID encoding and table-column text wrapping**
- **Found during:** Task 3 (D-17 test, reconciliation-only-on-last-page test)
- **Issue:** `lib/rendro/pdf/writer.ex` encodes text runs that use an embedded font (i.e. any run containing a B612-fallback glyph) as hex glyph-ID tokens (`<...>`), not literal `(text)` strings — so a raw `pdf =~ "Impôt sur le revenu"` substring check can never match the accented portion even on a correct render. Separately, long descriptions wrap across multiple lines/Tj calls at the ledger's narrow `{:share, 2}` column width, so `"Gross Pay"` immediately followed by a closing paren (`"(Gross Pay)"`) only matches the standalone subtotal-row cell, not the same phrase embedded mid-sentence inside the reconciliation equation.
- **Fix:** For D-17, verify the exact original description strings appear unmutated in the built `%Rendro.Section{}`/`%Rendro.Block{}` content (pre-render, via a recursive collector) — the structurally correct place to prove "no jurisdiction-keyword allowlist" — combined with a successful full render and a raw-byte check on the pure-ASCII description fragment only. For the reconciliation-only-on-last-page test, switched to unparenthesized raw substring counts (`"Gross Pay"`/`"Total Deductions"` without an expected immediate closing paren), which correctly counts both the subtotal-row cell and the equation-line occurrence regardless of surrounding text.
- **Files modified:** test/rendro/recipes/payslip_test.exs
- **Verification:** All 21 tests in `payslip_test.exs` pass; debug script (`mix run`, not committed) confirmed the real page count (3, not 2, for the 80-line overflow fixture) and exact occurrence counts before finalizing the assertions.
- **Committed in:** `bbf0ad4` (Task 3 GREEN)

---

**Total deviations:** 2 auto-fixed (1 blocking-issue font registration, 1 test-design correction for engine text-encoding realities)
**Impact on plan:** Both fixes were necessary for the plan's own explicit D-17/D-14 behavior cases to actually pass — no scope creep beyond what those cases already required. The font-fallback pattern is a new, reusable, small piece of engine-adjacent surface (a private helper inside the recipe, not a core `lib/rendro/pdf` change) that 116-03 (Ticket) may also need if it renders arbitrary caller text.

## Issues Encountered
None beyond the two deviations above (both resolved inline, no open follow-ups).

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- `Rendro.Recipes.Payslip` is fully implemented and tested; ready for 116-04's `priv/public_api.json` (adapter tier) and `priv/support_matrix.json` (`payslip` surface) registration, per this plan's explicit deferral.
- The unicode-fallback-font pattern (`with_unicode_fallback_font/1` idiom) is available as a reference for 116-03 (Ticket) if its human-readable reference/caller-supplied labels need the same accented-character resilience.
- Full suite green (1310 tests, 0 failures, including `statement_test.exs` — no regression from 116-01's `Pagination.label_resolver/2` generalization).
- `priv/public_api.json`'s `public_api_contract_test.exs` correctly did NOT flag `Payslip` as drift — its module list (`Mix.Tasks.Rendro.Api.Gen.public_modules/0`) is an explicit hardcoded list, confirming registration is genuinely deferred to 116-04 as the plan states, not accidentally skipped.

---
*Phase: 116-new-families-payslip-ticket*
*Completed: 2026-07-18*

## Self-Check: PASSED

- FOUND: lib/rendro/recipes/payslip.ex
- FOUND: test/rendro/recipes/payslip_test.exs
- FOUND: test/rendro/recipes/payslip_byte_identity_test.exs
- FOUND: 7818d9c (test: Task 1 RED)
- FOUND: a05155d (feat: Task 1 GREEN)
- FOUND: 7c6e584 (test: Task 2 RED)
- FOUND: 0b11d83 (feat: Task 2 GREEN)
- FOUND: d091588 (test: Task 3 RED)
- FOUND: bbf0ad4 (feat: Task 3 GREEN)
