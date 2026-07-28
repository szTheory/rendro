---
phase: 121-light-dark-background-fill-mechanism-all-7-recipes
verified: 2026-07-28T00:48:13Z
status: passed
score: 10/10 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 121: Light/dark background-fill mechanism (all 7 recipes) Verification Report

**Phase Goal:** Give every recipe dark mode "for free" via a role-derived full-page background region that the paginator already repeats on every page — with the light default staying byte-identical to v2.10. This is a dedicated determinism-golden slice because the fill must appear on overflow pages too, and any per-draw float tint math would break byte-reproducibility.

**Verified:** 2026-07-28T00:48:13Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `Rendro.Theme.dark/1` derives dark by swapping pre-resolved integer role tuples — no separate art, no transcendental color math at draw time (SC1/MODE-01) | ✓ VERIFIED | `lib/rendro/theme.ex:243-246`: `dark(theme)` calls `resolve/1` then `Map.merge(resolved.colors, @dark_colors)` — pure integer-tuple merge, no float/trig math. Doctest `Rendro.Theme.dark(Rendro.Theme.default()).colors.background` == `{27, 23, 19}` passes. |
| 2 | `Rendro.Recipes.Background` (`emit?/1`, `region/2`, `section/3`) is the single source of truth for the `:background` region (D-10) | ✓ VERIFIED | `lib/rendro/recipes/background.ex` — `emit?/1` exact-tuple sentinel vs `{255,255,255}`, `region/2` builds a fixed full-page `%Rendro.Region{}` from caller-supplied dims, `section/3` builds a full-page fill via `Rendro.path/2`. All 7 recipes call these three functions exclusively (grep below) — no per-recipe re-implementation. |
| 3 | Dark mode paints a full-page background fill as the FIRST content op on page 1 of EVERY recipe (SC2/MODE-02) | ✓ VERIFIED | Behavioral test `theme_mode_background_golden_test.exs` case (b)/(f): asserts `:binary.match` offset of the `Rendro.Color.rg(dark_bg)` fill op precedes the first `BT` text token, on Statement (portrait) and Certificate (landscape). Test PASSES (ran directly, not just SUMMARY claim). |
| 4 | Dark mode paints the fill on EVERY page, including paginate-generated overflow pages — occurrence count == page count (SC2/MODE-02) | ✓ VERIFIED | Case (c): forces a 60-line Statement overflow render, asserts `fill_count == page_count` (not mere presence). Test PASSES. This is the phase's core behavior-dependent claim and it is exercised by a real render + byte-level assertion, not symbol presence alone. |
| 5 | The light/no-theme default emits ZERO background ops and stays byte-identical to v2.10 across all 7 recipes (SC2/MODE-02) | ✓ VERIFIED | All 7 `*_byte_identity_test.exs` pass with frozen `sha256`/`@toy_golden_sha256` values UNCHANGED — `git diff --stat <base>..HEAD -- priv/goldens/` shows only 2 files added (`statement/dark.sha256`, `certificate/dark.sha256`), zero existing goldens modified. Golden test cases (a)/(e) additionally `refute pdf =~ fill_op` on light renders. |
| 6 | Statement and Certificate text draw-sites read swappable `colors.*` roles at every seam site — no implicit black default remains (D-01/D-02) | ✓ VERIFIED | `grep -n "color: colors\."` across `statement.ex` (header, closing, `cell_text/2` at every body/BF/CF row, footer page-number) and `certificate.ex` (`centered_line`, `centered_paragraph`) shows every draw-site seamed. `no_inline_color_literals_test.exs` passes (no stray literal tuples outside `palette/1`). |
| 7 | Certificate proves the mechanism on non-portrait (landscape) geometry, using its OWN resolved `{pw, ph}`, never hardcoded A4-portrait constants (Pitfall 4) | ✓ VERIFIED | `certificate.ex:143-144,220-221` pass `pw, ph` from `Rendro.PageSize.resolve/2` to `Background.region/section`. Certificate's deliberate non-black `:rule` frame literal `{34, 34, 34}` is preserved unchanged on the nil-branch. |
| 8 | All 5 remaining recipes (Payslip, Invoice, Receipt, BrandedInvoice, Ticket) wire the shared region+section on their own resolved dims, gated on `Background.emit?/1`, with zero text/palette edits (Pitfall 6) | ✓ VERIFIED | `grep -n "Background\."` across all 5 files shows identical dual-gate `region`/`section` prepend wiring using each recipe's own dims (`geometry(opts)` for Payslip/Ticket, `@page_width`/`@page_height` for Invoice/Receipt/BrandedInvoice). All 5 `*_byte_identity_test.exs` pass unchanged. |
| 9 | Dark is documented as a screen-oriented mode with an explicit non-print-recommended boundary and a `theming.dark` support-matrix row — no print-safety/accessibility/PDF-UA claim; every shipped demo is light (SC3/MODE-03) | ✓ VERIFIED | `priv/support_matrix.json` `theming.dark` = `supported_screen_oriented` with `boundaries` map — all 4 keys (`print_recommended`, `accessibility_pdf_ua_claim`, `wcag_contrast_claim`, `gui_viewer_visual_fidelity_claim`) == `"unsupported"` (confirmed via direct JSON parse, not SUMMARY quote). `theme.ex`'s `dark/1` @doc contains the verbatim "screen-oriented, not recommended for print" sentence. |
| 10 | `theming_claims_test.exs` self-defends against overclaim and vacuity; `guides/theming.md` NOT created this phase (D-09 boundary) | ✓ VERIFIED | `mix test test/docs_contract/theming_claims_test.exs` passes (10 tests). `test -f guides/theming.md` → absent, confirmed directly on disk. |

**Score:** 10/10 truths verified (0 present-but-behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/rendro/recipes/background.ex` | Shared `emit?/1`/`region/2`/`section/3` helper | ✓ VERIFIED | Exists, substantive (81 lines, real logic, no stubs), wired into all 7 recipes |
| `lib/rendro/recipes/statement.ex` | Text-seamed + background-wired | ✓ VERIFIED | `palette/1` nil-branch completed, all draw-sites seamed, `cell_text/2` added, background wiring in `page_template/1`/`sections/2` |
| `lib/rendro/recipes/certificate.ex` | Text-seamed (ink) + landscape-wired | ✓ VERIFIED | Body draw-sites seamed, `{34,34,34}` rule preserved, own resolved `{pw,ph}` used |
| `lib/rendro/recipes/{payslip,invoice,receipt,branded_invoice,ticket}.ex` | Background-wired, text/palette untouched | ✓ VERIFIED | All 5 wired identically; byte-identity goldens unchanged confirming no text/palette edits leaked |
| `test/rendro/recipes/theme_mode_background_golden_test.exs` | Dark-mechanism golden (a-g cases) | ✓ VERIFIED | 169 lines, 7 real behavioral test cases (Statement a-d, Certificate e-g), all pass |
| `priv/goldens/statement/dark.sha256`, `priv/goldens/certificate/dark.sha256` | Blessed dark goldens | ✓ VERIFIED | Both exist, single-line lowercase-hex, newly added (not re-blessed existing goldens) |
| `priv/support_matrix.json` (`theming` section) | Light/dark rows + boundaries | ✓ VERIFIED | Parsed directly — matches plan spec exactly (see Truth 9) |
| `test/docs_contract/theming_claims_test.exs` | Boundary/overclaim/vacuity tests | ✓ VERIFIED | 10 tests, all pass |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `page_template/1` (all 7 recipes) | `Background.region/2` | `Background.emit?(colors)` gate | ✓ WIRED | Confirmed by grep in all 7 recipe files |
| `sections/2` (all 7 recipes) | `Background.section/3` | Same `Background.emit?(colors)` gate on SAME `palette(opts)` (Pitfall 3 dual-gate) | ✓ WIRED | Region and section call sites both gate on `colors = palette(opts)` computed once per function — cannot disagree |
| Statement/Certificate text draw-sites | `palette(opts)` | `colors.ink`/`colors.muted` read at call site | ✓ WIRED | grep confirms `color: colors.*` at every seam site named in the plans |
| `theme_mode_background_golden_test.exs` | `priv/goldens/{statement,certificate}/dark.sha256` | `Rendro.Test.Golden.assert_or_bless/3` | ✓ WIRED | Real SHA-256 comparison against committed refs, not a stub |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Dark-mechanism golden test suite (7 cases) | `mix test test/rendro/recipes/theme_mode_background_golden_test.exs` | 17 tests (incl. doctests), 0 failures | ✓ PASS |
| Docs-contract theming claims test | `mix test test/docs_contract/theming_claims_test.exs` | Included in above run, 0 failures | ✓ PASS |
| All 7 recipes' byte-identity goldens + no-inline-literal guard | `mix test test/rendro/recipes/*_byte_identity_test.exs test/rendro/recipes/no_inline_color_literals_test.exs` | 20 tests, 0 failures | ✓ PASS |
| Full project test suite | `mix test` | 1653 tests, 2 failures (both pre-existing, out-of-scope — see below) | ✓ PASS (scoped) |
| No new compile warnings | `mix compile --warnings-as-errors` | Clean, no output | ✓ PASS |
| No re-bless of existing goldens | `git diff --stat <pre-phase>..HEAD -- priv/goldens/` | Only 2 files added (`statement/dark.sha256`, `certificate/dark.sha256`); 0 modified | ✓ PASS |
| `guides/theming.md` not created (D-09) | `test -f guides/theming.md` | Absent | ✓ PASS |
| No debt markers (TBD/FIXME/XXX/TODO/HACK/PLACEHOLDER) in phase files | `grep -riE` across all lib/test files touched by this phase | No matches | ✓ PASS |

**Pre-existing failures (confirmed out-of-scope):** `test/docs_contract/dx_local_reproducibility_claims_test.exs` — 2 failures, both `File.read!` on `.planning/phases/113-dx-local-reproducibility-validation/113-METRICS.md`/`113-UAT.md`, which are absent from the working tree. Independently confirmed these files do not exist anywhere in git history (only `113-PATTERNS.md`/`113-RESEARCH.md` exist under that phase directory) — this is a genuine Phase 113 artifact gap, unrelated to Phase 121's recipe/background changes. Logged in `deferred-items.md` and matches the task prompt's explicit instruction not to attribute these to this phase.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|--------------|--------|----------|
| MODE-01 | 121-01, 121-02 | `mode:` selector, `Theme.dark/1` swaps pre-resolved integer tuples, no transcendental math; `Background` helper is single source of truth | ✓ SATISFIED | Truths 1, 2, 6, 7 |
| MODE-02 | 121-01, 121-02, 121-03 | Full-page background on every page incl. overflow; light emits no rect, byte-identical to v2.10 | ✓ SATISFIED | Truths 3, 4, 5, 8 |
| MODE-03 | 121-04 | Dark documented as screen-oriented, non-print boundary, support-matrix row, no accessibility/PDF-UA claim | ✓ SATISFIED | Truths 9, 10 |

No orphaned requirements — REQUIREMENTS.md maps exactly MODE-01/02/03 to Phase 121, and all three appear in the `requirements:` frontmatter of at least one of the 4 plans.

### Anti-Patterns Found

None. No debt markers (TBD/FIXME/XXX/TODO/HACK/PLACEHOLDER), no empty implementations, no hardcoded-empty stubs found in any file touched by this phase.

### Human Verification Required

None. All must-haves are verifiable via automated tests, grep-based structural checks, and direct JSON/doc inspection — no visual, real-time, or external-service behavior is involved in this phase.

### Gaps Summary

None. All 10 derived observable truths (covering ROADMAP Success Criteria 1-3 and all `must_haves` across the 4 plans' PLAN frontmatter) are verified against the actual codebase, not just SUMMARY claims. Both behavior-dependent claims (fill-first-on-page-1, fill-on-every-overflow-page) are exercised by real behavioral tests that were run directly during this verification (not inferred from symbol presence). The 2 failing tests in the full suite are pre-existing, confirmed unrelated to this phase's changes, and correctly out of scope per the task's explicit instruction.

---

_Verified: 2026-07-28T00:48:13Z_
_Verifier: Claude (gsd-verifier)_
