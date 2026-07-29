---
phase: 122-typography-type-scale-application-font-role-leading-wiring
plan: 05
subsystem: recipes
tags: [typography, theme, font-role, unicode-fallback, centering, byte-identity, elixir]

# Dependency graph
requires:
  - phase: 122-01..04
    provides: "typography/1 seam (twin of palette/1) threading scale/fonts/leading into every %Text across all 7 recipes"
  - phase: 121
    provides: "role-derived :background full-page fill + Payslip :payslip_sans B612 unicode fallback"
provides:
  - "Themed Payslip renders its own canonical masked-middot + accented data (CR-01 closed): theme branch remaps fonts onto the fallback-bearing :payslip_sans"
  - "Certificate centering-measurement font keyed on the same font_role each run emits, with an honest {:unsupported_centered_font_role, _} guard (WR-01 closed)"
  - "Cross-recipe themed end-to-end Rendro.render/2 smoke test (7 recipes) closing the WR-02 render-path coverage hole"
affects: [123, from_brand, dark-gallery, themed-demos]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Recipe theme-font branch pins font roles to the recipe's own fallback-bearing registered font when glyph correctness outranks a themed swap"
    - "Centering-measurement font resolved from the SAME font_role the run emits, with a fail-loud guard on non-Helvetica-metric roles (errors-as-product)"
    - "Themed render smoke test exercises render/2 (not %Section{} equality) so themed-path regressions surface in CI, not at manual verification"

key-files:
  created:
    - test/rendro/recipes/certificate_typography_test.exs
    - test/rendro/recipes/themed_render_smoke_test.exs
  modified:
    - lib/rendro/recipes/payslip.ex
    - lib/rendro/recipes/certificate.ex
    - test/rendro/recipes/payslip_opts_threading_test.exs

key-decisions:
  - "Payslip theme branch remaps ALL font roles to :payslip_sans (its only registered, only fallback-bearing font) — glyph correctness (• U+2022, accents) outranks a themed font swap; no shipped theme sets non-:default fonts anyway"
  - "Certificate centering guard raises {:unsupported_centered_font_role, role} for any non-Helvetica-metric role rather than silently de-centering; :default and \"Helvetica\" are the only roles any shipped theme/no-theme branch produces"
  - "Certificate has NO non-centered text run, so the plan's {:unknown_text_font} Build.run raise-path is unreachable there — Certificate's honest representative raise-path is the centering guard; {:unknown_text_font} stays representatively proven on Statement (122-02)"

patterns-established:
  - "Fallback-font pinning: a recipe overriding put_default_font pins theme font roles to its registered fallback-bearing font on the theme branch, not just the no-theme branch"
  - "Measurement/emission font coupling: measure centering against the font resolved from the emitted role, guarding roles that cannot be measured at compose time"

requirements-completed: [TYPE-02]

coverage:
  - id: D1
    description: "Themed Payslip renders its own canonical masked-middot payment_method + accented earnings/deduction data via Rendro.render/2 (no {:unsupported_glyph, \"•\"}) — CR-01 closed, TYPE-02 font-role correctness for a fallback-bearing recipe"
    requirement: "TYPE-02"
    verification:
      - kind: integration
        ref: "test/rendro/recipes/payslip_opts_threading_test.exs#themed render succeeds on masked-middot + accented content (CR-01)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Certificate centering measurement and the emitted run resolve to the same font under the default theme (WR-01 coupling); a non-Helvetica-metric centered role raises {:unsupported_centered_font_role, _} instead of silently de-centering"
    verification:
      - kind: integration
        ref: "test/rendro/recipes/certificate_typography_test.exs#a themed Certificate renders {:ok, _} under Rendro.Theme.default()"
        status: pass
      - kind: unit
        ref: "test/rendro/recipes/certificate_typography_test.exs#an unregistered fonts.heading role raises {:unsupported_centered_font_role, _}"
        status: pass
    human_judgment: false
  - id: D3
    description: "Cross-recipe themed end-to-end render smoke test — one {:ok, _} = Rendro.render(Recipe.document(data, theme: default())) per recipe (7 total), closing the WR-02 coverage hole that let CR-01 ship"
    verification:
      - kind: e2e
        ref: "test/rendro/recipes/themed_render_smoke_test.exs (7 tests)"
        status: pass
    human_judgment: false
  - id: D4
    description: "No-theme byte-identity preserved: all 7 recipe goldens + edge_matrix render byte-identically with ZERO re-bless; default/0 and both recipes' nil branches untouched"
    verification:
      - kind: integration
        ref: "mix test test/rendro/recipes/*_byte_identity_test.exs test/rendro/edge_matrix_test.exs (83 tests) + git diff --exit-code priv/goldens/"
        status: pass
    human_judgment: false

# Metrics
duration: 14min
completed: 2026-07-28
status: complete
---

# Phase 122 Plan 05: Typography Gap-Closure Summary

**Themed Payslip now renders its own masked-middot + accented data by pinning theme font roles to the fallback-bearing :payslip_sans (CR-01), Certificate centering is coupled to the emitted font role with an honest non-Helvetica-metric guard (WR-01), and a 7-recipe themed render/2 smoke test permanently closes the coverage hole that hid CR-01 (WR-02).**

## Performance

- **Duration:** ~14 min
- **Completed:** 2026-07-28
- **Tasks:** 3
- **Files modified:** 5 (2 lib, 3 test — 2 new)

## Accomplishments
- **CR-01 (BLOCKER) closed:** Payslip's `typography/1` theme branch now returns `%{t | fonts: %{heading: :payslip_sans, body: :payslip_sans, mono: :payslip_sans}}` instead of the resolved theme's bare `:default` atoms. That restores the B612 unicode fallback carried by `:payslip_sans`, so a themed Payslip renders its own documented masked-middot (`•` U+2022) + accented content instead of crashing with `{:unsupported_glyph, "•"}`. TYPE-02 (font-role correctness for a fallback-bearing recipe) is completed.
- **WR-01 (WARNING) closed:** Certificate's `body_section/2` no longer measures every centered line against an unconditionally-hardcoded Helvetica while emitting a seamed `font_role`. A new `centering_measure_font/1` resolves the measurement font from the SAME role the run emits (`:default`/`"Helvetica"` → built-in Helvetica) and raises `{:unsupported_centered_font_role, role}` for any other role — replacing silent de-centering with an honest error. The false comment claiming built-in Helvetica "is always the correct font" was corrected.
- **WR-02 (coverage hole) closed:** New `themed_render_smoke_test.exs` exercises the full `render/2` path (not `%Section{}` struct equality) for all 7 recipes under `Rendro.Theme.default()`; the Payslip row uses masked-middot + accented content to exercise the fallback end-to-end.
- **No-theme byte-identity preserved:** all 7 recipe goldens + edge_matrix (83 tests) pass with ZERO re-bless; `git diff --exit-code priv/goldens/` reports no change.

## Task Commits

Each task was committed atomically:

1. **Task 1 (tracer): Fix Payslip themed font path (CR-01)** - `553f748` (fix)
2. **Task 2: Guard Certificate centering-measurement font (WR-01)** - `101c1b7` (fix)
3. **Task 3: Cross-recipe themed render smoke test (WR-02)** - `54d2cbe` (test)

## Files Created/Modified
- `lib/rendro/recipes/payslip.ex` - `typography/1` theme branch remaps fonts onto `:payslip_sans`; seam comment rewritten to state the remap + reason
- `lib/rendro/recipes/certificate.ex` - `centering_measure_font/1` helper + role-keyed centering measurement in `body_section/2` and `centered_line/6`; false comment corrected
- `test/rendro/recipes/payslip_opts_threading_test.exs` - added themed `render/2` regression assertion (masked-middot + accented deduction)
- `test/rendro/recipes/certificate_typography_test.exs` - NEW: coupling + guard (heading/body) + guard-scoping (unused mono tolerated)
- `test/rendro/recipes/themed_render_smoke_test.exs` - NEW: 7-recipe themed `render/2` smoke assertions

## Decisions Made
- **Payslip pins theme fonts to `:payslip_sans`:** it is the only font Payslip registers and the only one carrying the B612 unicode fallback; correctness of Payslip's own glyphs outranks a themed font swap (no shipped theme sets non-`:default` fonts — both `Theme.default/0` and `from_brand/2` emit `fonts: :default`). This intentionally means Payslip no longer surfaces `{:unknown_text_font, _}` for an unregistered themed role; TYPE-02's raise-path stays representatively proven on Statement/Invoice/Ticket.
- **Certificate centering guard is fail-loud, not silent:** measurement is keyed on the emitted role; a non-Helvetica-metric role raises rather than de-centering. Resolving embedded-font metrics at the recipe compose layer needs new plumbing and is deferred.

## Deviations from Plan

### Corrected Assumption

**1. [Rule 1 - Plan assumption corrected] Certificate has no non-centered text run, so the `{:unknown_text_font}` Build.run raise-path is unreachable there**
- **Found during:** Task 2 (Certificate typography test)
- **Issue:** The plan's third Certificate assertion asked for a `{:unknown_text_font, _}` `Build.run/1` raise-path via a "non-centered" font role. Certificate emits ONLY centered runs (title, subtitle, recipient, body, date, seal — heading/body roles), all of which now route through `centering_measure_font/1`. An unregistered centered role therefore trips the `{:unsupported_centered_font_role, _}` guard BEFORE reaching build; the `{:unknown_text_font}` path is genuinely unreachable for Certificate (it has no `mono` run and no non-centered run).
- **Fix:** Implemented the third assertion honestly — the centering guard IS Certificate's representative raise-path (proven on `fonts.heading` AND `fonts.body`), plus a guard-scoping test proving an unused unregistered `fonts.mono` does NOT spuriously raise (Certificate emits no mono run). The `{:unknown_text_font}` build-time raise-path remains representatively proven on Statement/Invoice/Ticket (122-02), documented in the test's `@moduledoc` and the certificate module comments.
- **Files modified:** test/rendro/recipes/certificate_typography_test.exs
- **Verification:** `mix test test/rendro/recipes/certificate_typography_test.exs` exits 0 (guard fires on heading + body; unused mono tolerated)
- **Committed in:** `101c1b7` (Task 2 commit)

---

**Total deviations:** 1 corrected assumption (Rule 1)
**Impact on plan:** The correction makes the Certificate raise-path test truthful to the code rather than asserting an unreachable path. All plan truths and success criteria still met (coupling + honest guard for the centered path; no silent de-centering). No scope creep.

## Issues Encountered
None — all three tasks verified on the first run; byte-identity held with zero re-bless.

## User Setup Required
None — no external service configuration required.

## Phase-Level Verification
- **CR-01 closed:** `payslip_opts_threading_test.exs` (+ byte-identity) exits 0; themed masked-middot + accented render succeeds with no `{:unsupported_glyph, "•"}`.
- **WR-01 closed:** `certificate_typography_test.exs` exits 0 (coupling + heading/body guard + mono-scoping).
- **WR-02 closed:** `themed_render_smoke_test.exs` exits 0 (7 themed render/2 assertions).
- **No-theme byte-identity:** all 7 recipe byte-identity tests + edge_matrix (83 tests) exit 0; `git diff --exit-code priv/goldens/` reports NO change (ZERO re-bless).
- **No new failures:** full suite `1689 tests, 2 failures` — both are the pre-existing, unrelated Phase-113 `DxLocalReproducibilityClaimsTest` failures logged in deferred-items (they fail on the base commit too).

## Next Phase Readiness
- Phase 122 gap-closure complete: TYPE-02 completed; TYPE-01/TYPE-03 remain covered by 122-01..04.
- Themed Payslip + Certificate are now safe for Phase 123's themed/dark gallery and `from_brand/2` E2E — the class of themed-render regression that hid CR-01 is permanently guarded by the cross-recipe smoke test.

## Self-Check: PASSED

All created files exist on disk; all 3 task commits present in git history.

---
*Phase: 122-typography-type-scale-application-font-role-leading-wiring*
*Completed: 2026-07-28*
