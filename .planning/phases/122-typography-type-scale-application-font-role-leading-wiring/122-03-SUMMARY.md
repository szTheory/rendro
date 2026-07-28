---
phase: 122-typography-type-scale-application-font-role-leading-wiring
plan: 03
subsystem: recipes
tags: [typography, type-scale, font-roles, leading, theme, branded-invoice, certificate, ticket, byte-identity]

# Dependency graph
requires:
  - phase: 122-01
    provides: "proven defp typography/1 tracer on Invoice (structural twin of palette/1) — the exact template replicated here"
  - phase: 122-02
    provides: "clean-recipe replication + the byte-identity / :default-font-alias learnings (document-default-font caveat)"
  - phase: 120-s1-retrofit-theme-swap
    provides: "per-recipe palette/1 seam + theme: threaded through all rungs"
  - phase: 119-rendro-theme-core
    provides: "%Theme{} typography contract (scale/fonts/leading/widows/orphans) + Rendro.Theme.resolve/1"
provides:
  - "defp typography/1 seam on the three RISK recipes (BrandedInvoice, Certificate, Ticket) — twins of palette/1: no-theme literal-default scale/fonts/leading, theme branch reads Rendro.Theme.resolve(theme).typography, Map.merge :typography override layer"
  - "BrandedInvoice: brand name (18) is the SOLE display anchor (Q1); the two brand runs keep font: font_name on BOTH paths (Q2, brand ⊥ theme — the sole non-:default literal-default)"
  - "Certificate: each element's resolved size feeds BOTH the %Text{}/centered_line run AND the centering math (line_h/1, text_width/3); recipient name (34) is the sole display anchor; the size: 1 spacer is left literal (Pitfall 2)"
  - "Ticket: @caption_size (7) and @present_code_size (6) exempted from the scale seam (font-only mono); reference code (8) is the SOLE display anchor via non-monotone assignment (Q3)"
  - "Representative TYPE-02 raise-path test (Ticket) proving an unregistered font role raises {:unknown_text_font, _}, never a silent substitution — covers the group"
  - "All 7 recipes now typography-seamed (122-01 + 122-02 + this)"
affects: [122-04, 123-from-brand-rubric-docs]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "typography/1 per-recipe seam mirroring palette/1 (case opts[:theme] nil/theme + Map.merge override tail)"
    - "no-theme literal-default typography map carrying the recipe's CURRENT size/font/leading literals (byte-identity), never Rendro.Theme.default().typography"
    - "brand-font exception: a recipe's brand run keeps font: font_name (data-driven embedded font) on both no-theme AND themed paths — brand ⊥ theme, NOT seamed to a theme role"
    - "measurement-coupled seam: resolve a size ONCE and feed it into BOTH the text run and the centering math (line_h/text_width) so a themed render cannot de-center"
    - "scale-seam exemption: a distinct micro-size with no free role stays a literal module attr (variable read, not inline literal) and seams only its FONT — byte-identity holds and the no-inline-size teeth test does not trip"

key-files:
  created:
    - test/rendro/recipes/ticket_typography_test.exs
  modified:
    - lib/rendro/recipes/branded_invoice.ex
    - lib/rendro/recipes/certificate.ex
    - lib/rendro/recipes/ticket.ex
    - test/rendro/recipes/branded_invoice_opts_threading_test.exs
    - test/rendro/recipes/certificate_opts_threading_test.exs
    - test/rendro/recipes/ticket_opts_threading_test.exs
    - priv/goldens/certificate/dark.sha256

key-decisions:
  - "BrandedInvoice display anchor = brand name (18) — it has no Total-Due %Text run (totals live inside Rendro.table/2); a branded invoice leads with the brand (Q1). No new total run added (byte-risk)."
  - "BrandedInvoice's two brand runs keep font: font_name on BOTH paths (Q2) — the data-driven embedded brand font is the SOLE non-:default literal-default in the milestone; brand ⊥ theme. Only Date/thank-you seamed to a theme font role."
  - "Certificate resolves each element's size ONCE from the seam and threads it into BOTH the centered_line/centered_paragraph text run AND the line_h/1 + text_width/3 centering math (RESEARCH Pitfall 2), so a themed render recomputes centering against the new sizes instead of de-centering."
  - "Certificate keeps the Rendro.text(\"\", size: 1) spacer as a literal layout hack — never seamed to a scale role."
  - "Ticket resolves Q3 by exempting the two mono micro-sizes (@caption_size 7, @present_code_size 6) from the scale seam — they stay literal attrs, font-only mono — dropping the scale-seamed distinct set to ≤6 roles; reference code (8) is the sole display anchor via non-monotone assignment (title 26 / subtitle 16 / body 10 / small 9 / caption 8)."

patterns-established:
  - "The 122-01 typography/1 tracer replicates onto the RISK recipes with the three open questions resolved in-place; no structural change to the seam mechanism."
  - "Authorized golden refresh: a THEMED render legitimately drifts when the seam collapses it onto the theme's uniform type scale (intended TYPE-01); the NO-THEME byte-identity golden must stay unchanged (zero re-bless)."

requirements-completed: [TYPE-01, TYPE-02, TYPE-03]

coverage:
  - id: D1
    description: "BrandedInvoice/Certificate/Ticket type scales materialized in defp typography/1 and threaded into every %Text{size}, with exactly one display anchor per recipe (BrandedInvoice brand name, Certificate recipient name, Ticket reference code)"
    requirement: TYPE-01
    verification:
      - kind: unit
        ref: "test/rendro/recipes/branded_invoice_byte_identity_test.exs (no-theme sha256 unchanged)"
        status: pass
      - kind: unit
        ref: "test/rendro/recipes/certificate_byte_identity_test.exs (no-theme sha256 unchanged)"
        status: pass
      - kind: unit
        ref: "test/rendro/recipes/ticket_byte_identity_test.exs (no-theme sha256 unchanged)"
        status: pass
      - kind: unit
        ref: "test/rendro/recipes/{branded_invoice,certificate,ticket}_opts_threading_test.exs (typography no-op + :typography leading override live seam)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Font roles resolve through FontRegistry; an unregistered role in theme.typography.fonts raises {:unknown_text_font, _} via Build.run/1, never a silent substitute — proven on the representative Ticket recipe (identical resolution path across the group)"
    requirement: TYPE-02
    verification:
      - kind: unit
        ref: "test/rendro/recipes/ticket_typography_test.exs (unregistered fonts.mono and fonts.heading -> {:unknown_text_font, :no_such_font} from Build.run/1)"
        status: pass
    human_judgment: false
  - id: D3
    description: "leading -> %Text{line_height} plus widows/orphans threaded onto every seamed text block in all 3 recipes; no-theme path reproduces today's exact 1.2/2/2 (metric no-op)"
    requirement: TYPE-03
    verification:
      - kind: unit
        ref: "test/rendro/edge_matrix_test.exs (leading/widows/orphans no-op, byte-identical)"
        status: pass
      - kind: unit
        ref: "test/rendro/recipes/{branded_invoice,certificate,ticket}_byte_identity_test.exs (byte-identical)"
        status: pass
    human_judgment: false

# Metrics
duration: 9min
completed: 2026-07-28
status: complete
---

# Phase 122 Plan 03: Seam BrandedInvoice/Certificate/Ticket typography Summary

**The proven Invoice `typography/1` tracer replicated onto the three RISK recipes with all three RESEARCH open questions resolved in-place — BrandedInvoice (Q1 brand-name anchor + Q2 brand font wins on both paths), Certificate (measurement-math coupling threaded from one resolved size), and Ticket (Q3: exempt two mono micro-sizes, reference code as the sole display anchor via non-monotone assignment) — with all three no-theme byte-identity goldens preserved (zero re-bless) and a representative TYPE-02 raise-path proven with teeth.**

## Performance

- **Duration:** ~9 min
- **Tasks:** 3 (BrandedInvoice, Certificate, Ticket + representative raise-path)
- **Files modified:** 6 modified + 1 created (+ 1 authorized themed golden refresh)

## Accomplishments
- Added `defp typography/1` to `branded_invoice.ex`, `certificate.ex`, `ticket.ex` — each a structural twin of `palette/1`: `case opts[:theme]` split (nil → per-recipe literal defaults, theme → `Rendro.Theme.resolve(theme).typography`) with a `Map.merge(base, Keyword.get(opts, :typography, %{}))` override tail.
- **BrandedInvoice (Q1/Q2):** brand name `Rendro, Inc.` (18) → `scale.display` (the **sole** anchor, since there is no Total-Due `%Text{}` run) **keeping** `font: font_name`; invoice id (12) → `scale.title` **keeping** `font: font_name`; Date/thank-you (10) → `scale.body` + `fonts.body`. The two brand runs keep the data-driven embedded brand font on BOTH paths (brand ⊥ theme). All four header/footer runs gained `line_height/widows/orphans`.
- **Certificate (Pitfall 2):** each element's size resolved **once** from the seam and fed into BOTH the `centered_line`/`centered_paragraph` text run AND the `line_h/1` + `text_width/3` centering math — recipient name (34) → `scale.display` (sole anchor) + `fonts.heading`; title (20) → `title` + heading; "This certifies that" (12) → `subtitle` + body; body paragraph (11) → `body` + body; date/seal (10) → `small` + body. The `Rendro.text("", size: 1)` spacer stays a literal layout hack. Retired the five `@*_size` module attrs (folded into the scale seam).
- **Ticket (Q3):** the two mono micro-sizes `@caption_size` (7) and `@present_code_size` (6) are **exempted** from the scale seam — they stay literal module attrs and seam only their FONT to `mono` (the `size:` is a variable read, not an inline literal). The remaining 5 distinct sizes map across the 6 roles non-monotonically: reference code (8) → `scale.display` (sole anchor) + `fonts.mono`; placement value (26) → `title` + body; ticket title (16) → `subtitle` + heading; subtitle text (10) → `body`; issuer (9) → `small`; placement-label/terms (8) → `caption`. Retired `@reference_size`/`@placement_value_size`.
- Extended the three `*_opts_threading_test.exs` with a typography no-op (`sections(data) == sections(data, typography: %{})`) + a live-seam assertion (a `:typography` leading override changes output).
- Created `ticket_typography_test.exs` — the representative TYPE-02 raise-path for this expansion group: an unregistered `fonts.mono`/`fonts.heading` atom surfaces the exact `{:error, {:unknown_text_font, :no_such_font}}` from `Build.run/1`.
- All three no-theme byte-identity goldens + `edge_matrix_test.exs` preserved with **zero re-bless**; full recipes + edge suite green (430 tests, 0 failures).

## Task Commits

Each task was committed atomically:

1. **Task 1: Seam BrandedInvoice typography (Q1 anchor + Q2 brand font)** - `d1004a0` (feat)
2. **Task 2: Seam Certificate typography (measurement-coupled sizes)** - `a1f5e5b` (feat)
3. **Task 3: Seam Ticket typography (Q3 exempt 2 mono micro-sizes) + TYPE-02 raise-path** - `c7e430e` (feat)
4. **Fix stale @placement_value_size comment reference in Ticket** - `d3908ed` (docs)
5. **Re-bless certificate dark themed golden (authorized type-scale drift)** - `eb09a3d` (test)

## Files Created/Modified
- `lib/rendro/recipes/branded_invoice.ex` — added `defp typography/1`; seamed the header (brand name/id/date, brand runs keeping `font_name`) + footer thank-you.
- `lib/rendro/recipes/certificate.ex` — added `defp typography/1`; threaded each element's resolved size into both the text run and the centering math; retired the five `@*_size` attrs; kept the `size: 1` spacer literal.
- `lib/rendro/recipes/ticket.ex` — added `defp typography/1`; seamed `main_section` / `stub_section` / `terms_section`; exempted `@caption_size`/`@present_code_size` (font-only mono); retired `@reference_size`/`@placement_value_size`; threaded `type` through `code_area_blocks`/`reference_blocks`/`present_code_caption`.
- `test/rendro/recipes/ticket_typography_test.exs` — NEW representative TYPE-02 raise-path (mono + heading).
- `test/rendro/recipes/{branded_invoice,certificate,ticket}_opts_threading_test.exs` — added `typography(opts) seam` describe blocks.
- `priv/goldens/certificate/dark.sha256` — authorized refresh (themed type-scale application).

## Decisions Made
- **BrandedInvoice display anchor = brand name (18).** D-01 names "Total Due," but BrandedInvoice's totals live inside `Rendro.table/2`, not a `%Text{}` run. Binding `display` to the brand name (the current largest run, and a branded invoice's de-facto "one key fact") satisfies the exactly-one-anchor rule without adding a byte-risky new total run (Q1).
- **BrandedInvoice brand font wins on both paths (Q2).** The two brand runs keep `font: font_name` (the data-driven embedded brand font) on both the no-theme and themed paths — the sole non-`:default` literal-default in this milestone. Brand ⊥ theme (a standing Key Decision): the theme controls *how* (tokens), the brand controls *who* (assets/fonts). Only the non-brand runs (Date, thank-you) seam to a theme font role.
- **Certificate threads one resolved size into both the text run and the measurement (Pitfall 2).** Resolving the size once per element and feeding it to both `centered_line`/`centered_paragraph` AND `line_h/1`/`text_width/3` guarantees a themed render recomputes its centering against the new sizes instead of de-centering.
- **Ticket exempts the two mono micro-sizes (Q3).** With 7 distinct sizes and only 6 scale roles, byte-identity forbids collapsing any two. Exempting `@caption_size` (7) and `@present_code_size` (6) — machine/label micro-text, not part of the semantic display→caption ramp — as literal attrs with font-only mono drops the scale-seamed distinct set to ≤6, letting the reference code (8) be the sole display anchor.

## Deviations from Plan

### Auto-fixed / handled

**1. [Authorized golden refresh] Certificate dark themed golden re-blessed**
- **Found during:** phase-gate `mix test` (`ThemeModeBackgroundGoldenTest` `certificate/dark`).
- **Issue:** The typography seam intentionally collapses the THEMED render onto the theme's uniform type scale (TYPE-01). The dark golden captured Certificate's pre-seam hardcoded sizes, so the themed dark render legitimately changed.
- **Resolution:** Re-blessed `priv/goldens/certificate/dark.sha256` (`MIX_GOLDEN_BLESS=true`). Determinism held (`assert_deterministic!` green — two dark renders byte-identical); the NO-THEME certificate byte-identity golden is unchanged (zero re-bless); dark is screen-oriented (no print/PDF-UA claim). Same authorized-refresh class as 122-02's `statement/dark`. This is the intended themed behavior, not a regression.
- **Files modified:** `priv/goldens/certificate/dark.sha256`
- **Commit:** `eb09a3d`

## Issues Encountered
- Two pre-existing, unrelated full-suite failures remain: `Rendro.DocsContract.DxLocalReproducibilityClaimsTest` (2 tests) read `.planning/phases/113-.../113-UAT.md` and report files that are ABSENT from this working tree (untracked/missing planning artifacts). They fail independent of 122-03 (they fail on the base commit too) and are out of scope — already logged to the phase `deferred-items.md` in 122-02.

## Known Stubs
None — all seams are wired live; no placeholder/empty data paths introduced.

## User Setup Required
None — no external service configuration required.

## Next Phase Readiness
- All 7 recipes are now typography-seamed (Invoice + Statement/Receipt/Payslip in 122-02 + BrandedInvoice/Certificate/Ticket here). The three flagged replication risks (BrandedInvoice brand-font literal-default + no Total-Due run, Certificate measurement-coupled `@*_size` attrs, Ticket 7-vs-6 sizes) are all resolved.
- The Certificate authorized themed golden refresh means all themed dark goldens now reflect the applied type scale; 122-04 (or Phase 123) can build the SHOW-01 rubric fix on top of a fully-seamed themed surface.

## Self-Check: PASSED

All created/modified files exist on disk; all five task commits (`d1004a0`, `a1f5e5b`, `c7e430e`, `d3908ed`, `eb09a3d`) are present in git history.

---
*Phase: 122-typography-type-scale-application-font-role-leading-wiring*
*Completed: 2026-07-28*
