---
phase: 122-typography-type-scale-application-font-role-leading-wiring
plan: 02
subsystem: recipes
tags: [typography, type-scale, font-roles, leading, theme, statement, receipt, payslip, byte-identity]

# Dependency graph
requires:
  - phase: 122-01
    provides: "proven defp typography/1 tracer on Invoice (structural twin of palette/1) — the exact template replicated here"
  - phase: 120-s1-retrofit-theme-swap
    provides: "per-recipe palette/1 seam + theme: threaded through all rungs"
  - phase: 119-rendro-theme-core
    provides: "%Theme{} typography contract (scale/fonts/leading/widows/orphans) + Rendro.Theme.resolve/1"
provides:
  - "defp typography/1 seam on Statement, Receipt, Payslip (twins of palette/1): no-theme literal-default scale/fonts/leading, theme branch reads Rendro.Theme.resolve(theme).typography, Map.merge :typography override layer"
  - "Every %Text{} in these 3 recipes threaded through the seam: size via scale.<role>, font via fonts.<role>, line_height/widows/orphans via leading/widows/orphans"
  - "Exactly one display-anchored element per recipe (Statement closing balance, Receipt total, Payslip net pay) per D-01"
  - "Representative TYPE-02 raise-path test (Statement) proving an unregistered font role raises {:unknown_text_font, _}, never a silent substitution — covers the group (identical resolution path)"
  - "5 of 7 recipes now typography-seamed (Invoice + Statement + Receipt + Payslip); BrandedInvoice/Certificate/Ticket remain for 122-03"
affects: [122-03, 122-04, 123-from-brand-rubric-docs]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "typography/1 per-recipe seam mirroring palette/1 (case opts[:theme] nil/theme + Map.merge override tail)"
    - "no-theme literal-default typography map carrying the recipe's CURRENT size/font/leading literals (byte-identity), never Rendro.Theme.default().typography"
    - "Payslip no-theme fonts use the STRING \"Helvetica\" (resolves to the document default :payslip_sans WITH unicode fallback), NOT the :default atom — recipe-specific byte-identity requirement when put_default_font is overridden"
    - "shared cell_text/N helper keeps ONE font role (body) for both label and amount columns (RESEARCH Pitfall 5)"

key-files:
  created:
    - test/rendro/recipes/statement_typography_test.exs
  modified:
    - lib/rendro/recipes/statement.ex
    - lib/rendro/recipes/receipt.ex
    - lib/rendro/recipes/payslip.ex
    - test/rendro/recipes/statement_opts_threading_test.exs
    - test/rendro/recipes/receipt_opts_threading_test.exs
    - test/rendro/recipes/payslip_opts_threading_test.exs
    - priv/goldens/statement/dark.sha256

key-decisions:
  - "Payslip no-theme fonts are the STRING \"Helvetica\", NOT :default — Payslip overrides the document default font to :payslip_sans (Helvetica + B612 unicode fallback); the atom :default resolves to a bare built-in Helvetica (no fallback, different font resource), which would drop the '•' payment-method glyph and drift bytes. font_registry.ex normalize_reference/2 maps the string \"Helvetica\" to the document default font, reproducing today's unset-font resolution exactly."
  - "Statement/Payslip cell_text/N shared helper keeps ONE font role (body) — not mono-ised — per RESEARCH Pitfall 5 (it renders both label and amount columns)."
  - "Payslip page_number seamed via the typography attrs (page_number/1 wraps Rendro.text/1, so size/font/line_height/widows/orphans thread through it)."
  - "Statement dark golden re-blessed: the themed path now collapses onto the theme's uniform type scale (intended TYPE-01), so the themed dark render legitimately changed; determinism held, no-theme goldens unchanged."

patterns-established:
  - "The 122-01 typography/1 tracer replicates mechanically onto clean recipes — Statement/Receipt/Payslip added with zero structural risk"
  - "no-theme literal-default map dictated by each recipe's current typographic literals; font literal-default may be \"Helvetica\" (string) rather than :default when the recipe overrides its document default font"

requirements-completed: [TYPE-01, TYPE-02, TYPE-03]

coverage:
  - id: D1
    description: "Statement/Receipt/Payslip type scales materialized in defp typography/1 and threaded into every %Text{size}, with exactly one display anchor per recipe (Statement closing balance, Receipt total, Payslip net pay)"
    requirement: TYPE-01
    verification:
      - kind: unit
        ref: "test/rendro/recipes/statement_byte_identity_test.exs (no-theme sha256 unchanged)"
        status: pass
      - kind: unit
        ref: "test/rendro/recipes/receipt_byte_identity_test.exs (no-theme sha256 unchanged)"
        status: pass
      - kind: unit
        ref: "test/rendro/recipes/payslip_byte_identity_test.exs (no-theme sha256 unchanged)"
        status: pass
      - kind: unit
        ref: "test/rendro/recipes/{statement,receipt,payslip}_opts_threading_test.exs (typography no-op + :typography leading override live seam)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Font roles resolve through FontRegistry; an unregistered role in theme.typography.fonts raises {:unknown_text_font, _} via Build.run/1, never a silent substitute — proven on the representative Statement recipe (identical resolution path across the group)"
    requirement: TYPE-02
    verification:
      - kind: unit
        ref: "test/rendro/recipes/statement_typography_test.exs (unregistered fonts.heading and fonts.mono -> {:unknown_text_font, :no_such_font} from Build.run/1)"
        status: pass
    human_judgment: false
  - id: D3
    description: "leading -> %Text{line_height} plus widows/orphans threaded onto every text block in all 3 recipes; no-theme path reproduces today's exact 1.2/2/2 (metric no-op)"
    requirement: TYPE-03
    verification:
      - kind: unit
        ref: "test/rendro/edge_matrix_test.exs (leading/widows/orphans no-op, byte-identical)"
        status: pass
      - kind: unit
        ref: "test/rendro/recipes/{statement,receipt,payslip}_byte_identity_test.exs (byte-identical)"
        status: pass
    human_judgment: false

# Metrics
duration: 32min
completed: 2026-07-27
status: complete
---

# Phase 122 Plan 02: Seam Statement/Receipt/Payslip typography Summary

**The proven Invoice `typography/1` tracer replicated mechanically onto the three CLEAN recipes (Statement, Receipt, Payslip) — type scale, font roles, and leading/widows/orphans threaded through every `%Text{}` with byte-identity preserved on the no-theme path (zero re-bless) and a representative TYPE-02 raise-path proven with teeth.**

## Performance

- **Duration:** ~32 min
- **Tasks:** 3 (Statement + representative raise-path, Receipt, Payslip)
- **Files modified:** 6 modified + 1 created (+ 1 golden refresh)

## Accomplishments
- Added `defp typography/1` to `statement.ex`, `receipt.ex`, `payslip.ex` — each a structural twin of `palette/1`: `case opts[:theme]` split (nil → per-recipe literal defaults, theme → `Rendro.Theme.resolve(theme).typography`) with a `Map.merge(base, Keyword.get(opts, :typography, %{}))` override tail.
- **Statement:** closing balance → `scale.display` (sole D-01 anchor) + `fonts.mono`; account name → `title` + `heading`; `cell_text/3` cells → `subtitle` + `body` (one font role, Pitfall 5); period/opening-balance → `body`; closing-balance label → `small`. Literal scale display 22 / title 14 / subtitle 12 / body 10 / small 9.
- **Receipt:** Total → `scale.display` (sole D-01 anchor) + `fonts.mono`; merchant/section header → `title` + `heading`; receipt title → `subtitle` + `heading`; customer name → `body`; date → `small`; minor totals → `caption` + `mono`. All six roles consumed exactly once (display 18 / title 16 / subtitle 14 / body 12 / small 10 / caption 9); retired `@minor_totals_size`/`@dominant_total_size`.
- **Payslip:** net pay → `scale.display` (sole D-01 anchor) + `fonts.mono`; employer → `title` + `heading`; employee AND `cell_text/3` cells → `subtitle` + `body`; net-pay label/period/pay-date → `body`; equation → `body` + `mono`; footer notes/payment-method/page number → `small` + `body`. Literal scale display 27 / title 13 / subtitle 11 / body 10 / small 9; retired `@cell_size`.
- Extended the three `*_opts_threading_test.exs` with a typography no-op (`sections(data) == sections(data, typography: %{})`) + a live-seam assertion (a `:typography` leading override changes output).
- Created `statement_typography_test.exs` — the representative TYPE-02 raise-path for the wave-2 group: an unregistered `fonts.heading`/`fonts.mono` atom surfaces the exact `{:error, {:unknown_text_font, :no_such_font}}` from `Build.run/1`.
- All three no-theme byte-identity goldens + `edge_matrix_test.exs` preserved with **zero re-bless**.

## Task Commits

Each task was committed atomically:

1. **Task 1: Seam Statement typography + representative TYPE-02 raise-path** - `e7692ab` (feat)
2. **Task 2: Seam Receipt typography (all six roles, exactly full)** - `a11e5dc` (feat)
3. **Task 3: Seam Payslip typography (cell_text single-role + font-alias caveat)** - `2988e7f` (feat)
4. **Statement dark golden refresh (authorized themed drift)** - `7edc04c` (test)

## Files Created/Modified
- `lib/rendro/recipes/statement.ex` — added `defp typography/1`; threaded header + `cell_text/3` (arity bumped for the `type` seam) through it.
- `lib/rendro/recipes/receipt.ex` — added `defp typography/1`; threaded header, `merchant_block/3`, and totals through it; retired the two totals-size attrs.
- `lib/rendro/recipes/payslip.ex` — added `defp typography/1` (no-theme fonts `"Helvetica"`); threaded header, summary net-pay anchor, `cell_text/3`, `subtotal_row/5`, reconciliation equation, YTD notes, and footer page_number through it; retired `@cell_size`.
- `test/rendro/recipes/statement_typography_test.exs` — NEW representative TYPE-02 raise-path.
- `test/rendro/recipes/{statement,receipt,payslip}_opts_threading_test.exs` — added `typography(opts) seam` describe blocks.
- `priv/goldens/statement/dark.sha256` — authorized refresh (themed type-scale application).

## Decisions Made
- **Payslip no-theme fonts are the STRING `"Helvetica"`, not the `:default` atom.** Payslip calls `put_default_font(:payslip_sans)` (Helvetica built-in + B612 unicode fallback). `font_registry.ex` `normalize_reference/2` maps the string `"Helvetica"` to the *document default font* (`:payslip_sans` + fallback) while the `:default` atom maps to the bare built-in Helvetica (no fallback, different font resource). Every current Payslip run passes no `font:` → the struct-default `"Helvetica"` string → `:payslip_sans`; seaming to `:default` broke the `•` payment-method glyph AND drifted bytes. Threading `"Helvetica"` reproduces the exact current resolution. (Caught by `payslip_byte_identity_test.exs`; fixed before commit.)
- **Shared `cell_text/N` helpers keep ONE font role (`body`)** on Statement and Payslip — not mono-ised — per RESEARCH Pitfall 5 (they render both label and amount columns).
- **Representative TYPE-02 on Statement** (per the plan) — Statement reads `fonts.heading` (account name, always rendered), `fonts.mono` (closing balance), and `fonts.body`; the raise-path is proven on `heading` and `mono`. The resolution path is identical across recipes, so one representative test covers the group.

## Deviations from Plan

### Auto-fixed / handled

**1. [Rule 1 - Byte-identity bug] Payslip no-theme font must be `"Helvetica"`, not `:default`**
- **Found during:** Task 3 (`payslip_byte_identity_test.exs` red — `Missing glyph for character: •` + hash drift).
- **Issue:** The tracer's `:default` font literal is byte-identical only when the recipe's document default IS the built-in Helvetica. Payslip overrides it to `:payslip_sans` (with unicode fallback), so `:default` dropped the fallback and changed the font resource.
- **Fix:** Payslip's no-theme `fonts` map uses the string `"Helvetica"` for all three roles (resolves to the document default via `normalize_reference/2`), reproducing the current unset-font resolution exactly.
- **Files modified:** `lib/rendro/recipes/payslip.ex`
- **Commit:** `2988e7f`

**2. [Authorized golden refresh] Statement dark themed golden re-blessed**
- **Found during:** phase-gate `mix test` (`ThemeModeBackgroundGoldenTest` `statement/dark`).
- **Issue:** The typography seam intentionally collapses the THEMED render onto the theme's uniform type scale (TYPE-01). The dark golden captured Statement's pre-seam hardcoded sizes, so the themed dark render legitimately changed.
- **Resolution:** Re-blessed `priv/goldens/statement/dark.sha256` (`MIX_GOLDEN_BLESS`). Determinism held (`assert_deterministic!` green — two dark renders byte-identical); the NO-THEME byte-identity goldens are unchanged (zero re-bless); dark is screen-oriented (no print/PDF-UA claim). This is the intended themed behavior, not a regression.
- **Files modified:** `priv/goldens/statement/dark.sha256`
- **Commit:** `7edc04c`

## Issues Encountered
- Two pre-existing, unrelated failures remain in the full suite: `Rendro.DocsContract.DxLocalReproducibilityClaimsTest` (2 tests) read `.planning/phases/113-.../113-UAT.md` and report files that are ABSENT from this working tree (untracked/missing planning artifacts). They fail independent of 122-02 and are out of scope. Logged to `deferred-items.md`.

## Known Stubs
None — all seams are wired live; no placeholder/empty data paths introduced.

## User Setup Required
None — no external service configuration required.

## Next Phase Readiness
- 5 of 7 recipes are now typography-seamed (Invoice, Statement, Receipt, Payslip). The remaining three — BrandedInvoice (brand-font literal-default + no Total-Due `%Text`), Certificate (measurement-coupled `@*_size` attrs), Ticket (7 distinct sizes vs 6 roles) — carry the flagged replication risks and are resolved in `122-03-PLAN.md` (RESEARCH Open Questions Q1/Q2/Q3).
- The Payslip `"Helvetica"`-string font lesson generalizes: any recipe that overrides its document default font must use the string literal on the no-theme path, not `:default`. Certificate (registers a brand font) and BrandedInvoice (brand embedded font) should heed this in 122-03.

## Self-Check: PASSED

All created/modified files exist on disk; all four task commits (`e7692ab`, `a11e5dc`, `2988e7f`, `7edc04c`) are present in git history.

---
*Phase: 122-typography-type-scale-application-font-role-leading-wiring*
*Completed: 2026-07-27*
