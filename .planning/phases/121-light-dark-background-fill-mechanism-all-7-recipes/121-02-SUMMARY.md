---
phase: 121-light-dark-background-fill-mechanism-all-7-recipes
plan: 02
subsystem: recipes
tags: [elixir, pdf, theme, dark-mode, certificate, background-fill, landscape, tdd-golden]

# Dependency graph
requires:
  - phase: 121-01
    provides: "Rendro.Recipes.Background (emit?/1, region/2, section/3) + the shared theme_mode_background_golden_test.exs to extend"
provides:
  - "Certificate fully text-seamed (D-01/D-02): both body text draw-sites (centered_line, centered_paragraph) read colors.ink"
  - "Certificate palette/1 nil-branch completed (ink/muted/background) — non-black rule: {34,34,34} stress default preserved unchanged"
  - "Certificate dark-mode background wiring: :background region + section prepended first in page_template/1 and sections/2, gated on Background.emit?(palette(opts)), passing Certificate's OWN resolved landscape {pw, ph}"
  - "priv/goldens/certificate/dark.sha256 — blessed Certificate dark golden, proving the mechanism on non-portrait (landscape) geometry"
  - "theme_mode_background_golden_test.exs extended with Certificate (e)/(f)/(g) cases"
affects: [121-03-remaining-5-recipes, 121-04-docs-contract]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Non-portrait geometry proof: Certificate's default landscape {pw, ph} = Rendro.PageSize.resolve(page_size, orientation) is threaded to Background.region/section directly — never Statement's portrait A4 constants (Pitfall 4)"
    - "Background wiring mirrors a recipe's existing conditional-region idiom (Certificate's pre-existing :frame region/section pattern) rather than introducing a new shape"

key-files:
  created:
    - priv/goldens/certificate/dark.sha256
  modified:
    - lib/rendro/recipes/certificate.ex
    - test/rendro/recipes/theme_mode_background_golden_test.exs

key-decisions:
  - "sections/2 and page_template/1 restructured to compute page_size/orientation/{pw,ph}/colors unconditionally at the top of the function (previously only computed inside the `if border do` branch) — this is a pure refactor with no behavior change on the border:false && no-theme path (values are simply unused, not emitted), verified via the unchanged certificate_byte_identity_test.exs sha256"
  - "Certificate's single-page landscape shape meant the dark golden test needed no forced-overflow (c) case analog — instead (f) asserts fill_count == 1 (exactly one page, one fill) as the landscape-specific structural proof"
  - "Kept the plan's TDD RED/GREEN discipline for Task 2: RED commit lands with 1 failing test (missing golden ref hard-flunk), GREEN commit blesses via MIX_GOLDEN_BLESS=true"

patterns-established: []

requirements-completed: [MODE-01, MODE-02]

coverage:
  - id: D1
    description: "Certificate wires the shared Background region+section using its OWN resolved landscape {pw, ph}, proving the mechanism on non-portrait geometry"
    requirement: MODE-01
    verification:
      - kind: unit
        ref: "test/rendro/recipes/theme_mode_background_golden_test.exs#(f) Certificate dark: background fill is the first content op on the landscape page"
        status: pass
      - kind: unit
        ref: "test/rendro/recipes/no_inline_color_literals_test.exs — no recipe section builder inlines a literal {r,g,b} color tuple"
        status: pass
    human_judgment: false
  - id: D2
    description: "Certificate's two body text draw-sites (centered_line, centered_paragraph) read colors.ink; the :rule frame keeps its non-black {34,34,34} default and rides the dark swap for free"
    requirement: MODE-01
    verification:
      - kind: other
        ref: "grep -c '34, 34, 34' lib/rendro/recipes/certificate.ex == 5 (unchanged from HEAD baseline, verified manually during execution)"
        status: pass
      - kind: other
        ref: "grep -n 'color: colors.ink' lib/rendro/recipes/certificate.ex — both centered_line and centered_paragraph carry it"
        status: pass
    human_judgment: false
  - id: D3
    description: "Certificate.document(data) with NO theme: opt emits ZERO background ops and stays byte-identical to v2.10"
    requirement: MODE-02
    verification:
      - kind: unit
        ref: "test/rendro/recipes/certificate_byte_identity_test.exs — frozen sha256 unchanged, no re-bless"
        status: pass
      - kind: unit
        ref: "test/rendro/recipes/theme_mode_background_golden_test.exs#(e) Certificate light/no-theme: zero background ops, byte-identical"
        status: pass
    human_judgment: false
  - id: D4
    description: "Dark golden test gains a Certificate (landscape) case: dark paints the full-page fill first, locked by a blessed priv/goldens/certificate/dark.sha256"
    requirement: MODE-02
    verification:
      - kind: unit
        ref: "test/rendro/recipes/theme_mode_background_golden_test.exs#(g) Certificate determinism/composition + blessed dark golden"
        status: pass
    human_judgment: false

# Metrics
duration: 12min
completed: 2026-07-28
status: complete
---

# Phase 121 Plan 02: Certificate Text Seams + Dark Background Wiring Summary

**Certificate's two body-text draw-sites now read colors.ink, its palette/1 nil-branch is completed while the non-black {34,34,34} frame stress default is preserved, and the shared Background helper is wired into Certificate's own resolved landscape dims — proving the dark-mode mechanism on non-portrait geometry and locked by a newly blessed priv/goldens/certificate/dark.sha256.**

## Performance

- **Duration:** 12 min
- **Started:** 2026-07-28T00:34:00Z (approx)
- **Completed:** 2026-07-28T00:35:45Z
- **Tasks:** 2
- **Files modified:** 3 (1 edited recipe, 1 extended test, 1 blessed golden ref)

## Accomplishments
- Threaded `colors = palette(opts)` into `body_section/3`, passed to both `centered_line` and `centered_paragraph` so both body text draw-sites read `colors.ink` (D-01/D-02) — the empty spacer left unseamed per plan discretion (no glyphs)
- Completed `palette/1`'s nil-branch with `ink: {0,0,0}`, `muted: {0,0,0}`, `background: {255,255,255}` while keeping `rule: {34,34,34}` — Certificate's deliberate non-black stress literal — byte-for-byte unchanged (D-03)
- Wired `page_template/1` and `sections/2` to prepend the shared `Rendro.Recipes.Background` region and section first, gated on `Background.emit?(palette(opts))`, passing Certificate's own resolved landscape `{pw, ph}` from `Rendro.PageSize.resolve/2` — never Statement's portrait A4 constants (Pitfall 4/D-04)
- Extended `theme_mode_background_golden_test.exs` with 3 new Certificate cases: (e) light/no-theme zero-ops + byte-identity, (f) dark fill-op-precedes-BT plus exactly-one-fill-op (single landscape page), (g) blessed dark golden lock
- Followed the plan's TDD RED/GREEN gate for Task 2 (test="true"): RED commit landed with the missing-golden hard-flunk, then a separate GREEN commit blessed `priv/goldens/certificate/dark.sha256` via `MIX_GOLDEN_BLESS=true`
- Confirmed `certificate_byte_identity_test.exs` stays green with its frozen sha256 unchanged (no re-bless) — light no-theme path byte-identical to v2.10

## Task Commits

Each task was committed atomically:

1. **Task 1: Wire Certificate background region+section, seam its body text to colors.ink, complete palette nil-branch** - `f887040` (feat)
2. **Task 2 (RED): Add failing dark-mode background golden test for Certificate** - `bacd712` (test)
3. **Task 2 (GREEN): Bless the Certificate dark background golden** - `a0ebf0b` (feat)

_Note: Task 2 followed the plan-mandated `tdd="true"` RED/GREEN cycle (test commit, then a separate bless commit) rather than a single combined commit._

## Files Created/Modified
- `lib/rendro/recipes/certificate.ex` - `palette/1` nil-branch completed (rule unchanged), `centered_line`/`centered_paragraph` seamed to `colors.ink`, `page_template/1`/`sections/2` restructured to prepend the shared background region/section on Certificate's own resolved landscape dims
- `test/rendro/recipes/theme_mode_background_golden_test.exs` - Extended with Certificate (e)/(f)/(g) describe blocks (light zero-ops, dark fill-op-order + single-page count, blessed golden)
- `priv/goldens/certificate/dark.sha256` - Newly blessed Certificate dark golden (1-line hash)

## Decisions Made
- Restructured `sections/2` and `page_template/1` to compute `page_size`/`orientation`/`{pw, ph}`/`colors` unconditionally at the top of each function (previously these were only computed inside the `if border do` branch, duplicated). This is a pure refactor — on the `border: false` + no-theme path the extra values are simply unused, not emitted anywhere — verified byte-identical via the unchanged `certificate_byte_identity_test.exs` frozen sha256.
- Certificate is single-page (validation rejects a body long enough to overflow), so the dark golden test's landscape-specific structural proof is "exactly one fill op" rather than Statement's forced-overflow "fill op per page" case — the more direct non-portrait single-page analog.

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- `Rendro.Recipes.Background` now has two proven callers (Statement portrait/multi-page, Certificate landscape/single-page) — 121-03 (remaining 5 recipes: Payslip, Invoice, Receipt, BrandedInvoice, Ticket) has both geometry shapes to model against.
- `theme_mode_background_golden_test.exs` now carries 7 cases (Statement a-d, Certificate e-g) and is ready for 121-03 to extend with the remaining 5 recipes' cases.
- No blockers.

---
*Phase: 121-light-dark-background-fill-mechanism-all-7-recipes*
*Completed: 2026-07-28*
