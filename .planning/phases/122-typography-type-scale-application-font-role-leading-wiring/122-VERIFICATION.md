---
phase: 122-typography-type-scale-application-font-role-leading-wiring
verified: 2026-07-28T20:15:00Z
status: passed
score: 6/6 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 5/6
  gaps_closed:
    - "CR-01 (BLOCKER): themed Payslip crashed on its own masked-middot/accented canonical data — now renders {:ok, _} via theme-branch remap onto the fallback-bearing :payslip_sans"
    - "WR-01 (WARNING): Certificate centering measured Helvetica while emitting a seamed font_role — measurement now keyed on the emitted role with an honest {:unsupported_centered_font_role, _} guard"
    - "WR-02 (coverage hole): themed assertions only compared %Section{} structs — a 7-recipe themed render/2 smoke test now exercises the full render path"
  gaps_remaining: []
  regressions: []
gaps: []
deferred: []
---

# Phase 122: Typography type-scale application + font-role/leading wiring — Verification Report

**Phase Goal:** Apply the theme's typography across all recipes — the single biggest lever for the Phase-118 hierarchy gap — by threading the materialized named type scale, `FontRegistry` font roles, and `leading`/widows/orphans into `%Text{}`, while `default/0` stays a metric no-op that leaves Phase-117 stress goldens unchanged.
**Verified:** 2026-07-28T20:15:00Z
**Status:** passed
**Re-verification:** Yes — after gap closure (plan 122-05, commits 553f748, 101c1b7, 54d2cbe)

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Named type scale materialized as explicit points + threaded into every `%Text{size}` across all 7 recipes, exactly one `display` anchor per recipe (TYPE-01, D-01) | ✓ VERIFIED | `defp typography/1` present in all 7 recipes; scales are literal integer points (e.g. payslip `%{display: 27, title: 13, subtitle: 11, body: 10, small: 9, caption: 8}`). `no_inline_size_literals_test.exs` guards re-introduction of inline `size:` literals (green). |
| 2 | Font roles resolve through `FontRegistry`; an unregistered role raises `{:unknown_text_font, _}` via `Build.run/1`, never a silent Helvetica substitute (TYPE-02, SC2) | ✓ VERIFIED | `invoice_typography_test.exs`, `statement_typography_test.exs`, `ticket_typography_test.exs` assert `{:error, {:unknown_text_font, :no_such_font}} = Build.run(doc)` for unregistered `fonts.body`/`fonts.mono`. Raise-path is real and passing. |
| 3 | `leading` → `%Text{line_height}` + widows/orphans theme-driven; `default/0` scale/leading a metric no-op — Phase-117 stress goldens byte-identical (TYPE-03, SC3) | ✓ VERIFIED | No-theme literal defaults reproduce 1.2/2/2. All 7 byte-identity goldens + `edge_matrix_test.exs` render byte-identically with ZERO re-bless. |
| 4 | The font-role seam applies theme typography **correctly** across recipes without regressing themed rendering (D-02 "dark/brand just works") — CR-01 | ✓ VERIFIED | **BLOCKER CLOSED.** Themed Payslip now renders its own canonical masked-middot + accented data: `payslip_opts_threading_test.exs:113` asserts `{:ok, _} = Rendro.render(Payslip.document(data, theme: Rendro.Theme.default()))` on `payment_method: "Direct Deposit ···· 4321"` (L110) + accented `"Impôt sur le revenu"` (L103). Code: `payslip.ex:899-901` theme branch returns `%{t \| fonts: %{heading: :payslip_sans, body: :payslip_sans, mono: :payslip_sans}}`, restoring the B612 unicode fallback. Behavioral test passes. |
| 5 | No-inline-`size:`-literal teeth test guards all 7 recipes; full suite green (only pre-existing unrelated failures) | ✓ VERIFIED | `no_inline_size_literals_test.exs` passing. Full `mix test`: 1689 tests, exactly 2 failures — both `Rendro.DocsContract.DxLocalReproducibilityClaimsTest` reading absent `.planning/phases/113-*` files (pre-existing, logged in deferred-items.md, NOT phase-122 regressions). |
| 6 | No-theme byte-identity preserved (all 7 goldens + edge_matrix, ZERO re-bless) | ✓ VERIFIED | 84 byte-identity + edge_matrix + teeth tests green; `git diff --exit-code priv/goldens/` clean before AND after test runs. Gap-closure commits (553f748/101c1b7/54d2cbe) touched only `lib/` + `test/`, no goldens. |

**Score:** 6/6 truths verified (0 present, behavior-unverified)

### Gap-Closure Verification (Plan 122-05 must_haves)

| # | 122-05 must-have | Status | Evidence |
|---|------------------|--------|----------|
| 1 | Themed Payslip renders own canonical data (CR-01 closed; TYPE-02 font-role correctness for a fallback-bearing recipe) | ✓ VERIFIED | `payslip.ex:899-901` remap; render/2 test green (masked-middot + accented). No `{:unsupported_glyph, "•"}`. |
| 2 | Certificate centering measurement + emitted run resolve to same font under every shipped theme; non-Helvetica-metric role rejected honestly (WR-01) | ✓ VERIFIED | `certificate.ex` `centering_measure_font/1` (L462-479) routed through `body_section/2` (L345) and `centered_line/6` (L411), keyed on the emitted `font_role`. Guard raises `{:unsupported_centered_font_role, role}` for any non-Helvetica-metric role. Coupling + heading/body guard tests pass. |
| 3 | No-theme byte-identity, ZERO re-bless; `default/0` and nil branches of both recipes untouched | ✓ VERIFIED | 84 goldens/edge_matrix green; git diff clean. `payslip.ex:890-897` nil branch unchanged (still `fonts: "Helvetica"` string, same literal scale). |
| 4 | Themed render/2 test exercises the full render path (not `%Section{}` equality) for Payslip + all 7 recipes (WR-02) | ✓ VERIFIED | `themed_render_smoke_test.exs`: 7 `{:ok, _} = Rendro.render(Recipe.document(data, theme: default()))` assertions; Payslip row uses masked-middot + accented content. All green. |

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/rendro/recipes/*.ex` (×7) | `defp typography/1` seam | ✓ VERIFIED | All 7 present, mirroring `palette/1` |
| `lib/rendro/recipes/payslip.ex` themed font path | correct themed resolution | ✓ VERIFIED | Theme branch remaps to fallback-bearing `:payslip_sans` (L899-901); nil branch untouched |
| `lib/rendro/recipes/certificate.ex` centering | size+font measurement coupling + guard | ✓ VERIFIED | `centering_measure_font/1` couples measurement to emitted role; honest guard on non-Helvetica-metric roles; false comment corrected |
| `test/rendro/recipes/no_inline_size_literals_test.exs` | TYPE-01 teeth test | ✓ VERIFIED | Present + passing |
| `test/rendro/recipes/{invoice,statement,ticket}_typography_test.exs` | TYPE-02 raise-path | ✓ VERIFIED | Assert `{:unknown_text_font, :no_such_font}` |
| `test/rendro/recipes/certificate_typography_test.exs` | WR-01 coupling + guard | ✓ VERIFIED | NEW; coupling render + heading/body guard + mono-scoping |
| `test/rendro/recipes/themed_render_smoke_test.exs` | WR-02 render-path coverage | ✓ VERIFIED | NEW; 7 themed render/2 assertions |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `opts[:theme]` nil branch | per-recipe literal defaults | byte-identity split | ✓ WIRED | No-theme byte-identity holds across all 7 |
| `theme.typography.fonts.<role>` (unregistered) | `build.ex {:unknown_text_font,_}` | FontRegistry miss | ✓ WIRED | Raise-path tests pass (Statement/Invoice/Ticket) |
| Payslip theme branch | fallback-bearing `:payslip_sans` | font-role remap | ✓ WIRED | `payslip.ex:899-901` — themed runs keep B612 fallback; render/2 test green |
| Certificate run `font_role` | centering `text_width` measurement | `centering_measure_font/1` | ✓ WIRED | Measurement keyed on emitted role; non-Helvetica-metric role raises honestly |
| Every recipe `document(data, theme:)` | `Rendro.render/2` → `{:ok,_}` | themed render smoke | ✓ WIRED | 7-recipe smoke test green |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Gap-closure tests | `mix test payslip_opts_threading + certificate_typography + themed_render_smoke` | 20 tests, 0 failures | ✓ PASS |
| No-theme byte-identity (7 goldens + edge_matrix + teeth) | `mix test *_byte_identity + edge_matrix + no_inline_size_literals` | 84 tests, 0 failures | ✓ PASS |
| Golden re-bless check (binding constraint) | `git diff --exit-code priv/goldens/` | clean before and after test runs | ✓ PASS |
| Full suite | `mix test` | 1689 tests, 2 failures (pre-existing phase-113 `DxLocalReproducibilityClaimsTest`, unrelated) | ✓ PASS (phase scope) |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| TYPE-01 | 122-01..04 | Named type scale materialized as explicit points, threaded into `%Text{}` size | ✓ SATISFIED | `typography/1` literal scales in all 7 recipes; teeth test guards inline literals |
| TYPE-02 | 122-02, 122-05 | Font roles resolve through `FontRegistry`; unregistered raises `{:unknown_text_font, _}`, never silent substitute | ✓ SATISFIED | Raise-path on Statement/Invoice/Ticket; Payslip fallback-bearing font-role correctness closed in 122-05 (CR-01); Certificate centering guard is its representative honest raise-path |
| TYPE-03 | 122-03 | `leading` + widows/orphans theme-driven; `default/0` a metric no-op; Phase-117 goldens unchanged | ✓ SATISFIED | No-theme defaults 1.2/2/2; all goldens + edge_matrix byte-identical, ZERO re-bless |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| — | — | none | — | No TBD/FIXME/XXX/HACK/placeholder markers in modified `payslip.ex`/`certificate.ex`. The Certificate embedded-font-metrics "deferred" note is a documented, honest design boundary backed by a fail-loud guard, not silent debt. |

### Human Verification Required

None. All gap-closure truths are behavior-verified by passing end-to-end `render/2` tests; the byte-identity binding constraint is machine-verified via `git diff --exit-code`.

### Gaps Summary

No gaps. The three prior-verification gaps are closed and independently re-verified:

- **CR-01 (was BLOCKER):** Payslip's `typography/1` theme branch now remaps all font roles onto the fallback-bearing `:payslip_sans`, restoring the B612 unicode fallback. A themed Payslip renders its own canonical masked-middot (`•` U+2022) + accented (`Impôt sur le revenu`) data with `{:ok, _}` — proven by an end-to-end `render/2` assertion, not `%Section{}` equality.
- **WR-01 (was PARTIAL):** Certificate's centering measurement is now resolved via `centering_measure_font/1` keyed on the SAME `font_role` each run emits, with an honest `{:unsupported_centered_font_role, _}` raise for non-Helvetica-metric roles instead of silent de-centering.
- **WR-02 (coverage hole):** A new `themed_render_smoke_test.exs` exercises the full `render/2` path for all 7 recipes under `Rendro.Theme.default()`, permanently guarding the class of themed-path regression that hid CR-01.

The binding no-theme byte-identity contract holds: all 7 recipe goldens + edge_matrix are byte-identical with ZERO re-bless (`git diff --exit-code priv/goldens/` clean; gap-closure commits touched no goldens). The only full-suite failures are the 2 pre-existing, unrelated Phase-113 `DxLocalReproducibilityClaimsTest` failures documented in deferred-items.md.

---

_Verified: 2026-07-28T20:15:00Z_
_Verifier: Claude (gsd-verifier)_
