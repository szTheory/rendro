---
phase: 122-typography-type-scale-application-font-role-leading-wiring
verified: 2026-07-28T18:32:00Z
status: gaps_found
score: 5/6 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "The font-role seam applies theme typography correctly across all recipes without regression — themed rendering works (D-02 'seam text→ink NOW so dark/brand just works')"
    status: failed
    reason: >-
      REPRODUCED BLOCKER (CR-01). Payslip's typography/1 theme branch returns
      Rendro.Theme.resolve(theme).typography whose fonts.<role> are bare :default
      atoms (fallback-less built-in Helvetica). The no-theme branch correctly
      threads the "Helvetica" string (→ :payslip_sans, which carries the B612
      unicode fallback), but the theme branch severs that fallback. Under ANY
      theme, every Payslip text run loses the fallback its own D-14 glyph_safe
      output (middot "·" → "•", U+2022) and D-17 accented content depend on, so a
      themed Payslip fails to render on its canonical documented data. This is a
      regression from Phase 121 (themed Payslip rendered these glyphs fine when
      the theme affected colors only). The 122-02 SUMMARY explicitly notes the
      :default atom "would drop the '•' payment-method glyph" yet guarded only the
      no-theme branch, leaving the theme branch broken.
    artifacts:
      - path: "lib/rendro/recipes/payslip.ex"
        issue: >-
          typography/1 (L877-894) theme branch returns resolve(theme).typography
          with fonts = :default atoms; no remap onto the fallback-bearing
          :payslip_sans role. Reproduced: Payslip.document(data, theme:
          Rendro.Theme.default()) |> Rendro.render → {:error, %Rendro.Error{reason:
          {:unsupported_glyph, "•"}, stage: :measure}} on the byte-identity
          fixture's own "Direct Deposit ···· 4321" payment_method.
      - path: "test/rendro/recipes/payslip_opts_threading_test.exs"
        issue: >-
          Themed assertions compare sections/2 %Section{} struct output only
          (refute equality) — never render/2 or measure_rows/4. No end-to-end
          themed Payslip render is exercised, which is exactly why CR-01 passes CI
          (WR-02).
    missing:
      - "Remap the resolved theme typography's fonts onto Payslip's fallback-bearing font (e.g. %{t | fonts: %{heading: :payslip_sans, body: :payslip_sans, mono: :payslip_sans}}) OR register the theme's font-role atoms with fallbacks: [:payslip_unicode_fallback] in with_unicode_fallback_font/1, so themed Payslip preserves the B612 fallback."
      - "Add a themed end-to-end render assertion for Payslip covering a masked payment_method (middot) and an accented :description — assert {:ok, _} = Rendro.render(Payslip.document(data, theme: Rendro.Theme.default())) (WR-02). Consider one themed render smoke test per recipe."
  - truth: "Certificate threads the resolved size into BOTH the %Text{} and the centering math so themed centering does not drift"
    status: partial
    reason: >-
      WR-01. Certificate's body_section/2 fixes font = Rendro.PDF.Font.helvetica()
      (L340) for every centering measurement (text_width at L352 and inside
      centered_line), but the emitted %Text{} carries the seamed font: font_role.
      The size was given the "measure once, render once" treatment; the font was
      not. On the default/no-theme path type.fonts.* == :default == built-in
      Helvetica so measurement matches and centering is correct. Under a theme
      whose typography.fonts names a real non-Helvetica embedded font (the
      raise-path tests prove roles are freely settable), recipient name / title /
      body would be measured with Helvetica metrics but rendered with the themed
      font — visibly mis-centered. Not a crash; a correctness gap in the exact
      font-role wiring this phase delivers.
    artifacts:
      - path: "lib/rendro/recipes/certificate.ex"
        issue: "L340 hardcoded helvetica() used for centering measurement while runs carry font_role (L367-419)."
    missing:
      - "Resolve the centering-measurement font from the same seam role used for the run (or document/guard that Certificate centering is only correct for Helvetica-metric font roles)."
deferred: []
human_verification:
  - test: "Confirm the intended themed-Payslip behavior contract: should applying a theme to a recipe with a document-default fallback font (Payslip's B612) preserve that fallback, or is themed rendering of fallback-dependent recipes explicitly out of scope until Phase 123?"
    expected: "Product decision — but the current behavior (themed Payslip crashes on its own canonical documented data) is a regression from Phase 121 and blocks Phase 123's themed/dark gallery render of Payslip, so it should be fixed here rather than deferred."
    why_human: "Scope/intent judgment on whether a themed-render regression is acceptable at phase close; the crash itself is machine-verified above."
---

# Phase 122: Typography type-scale application + font-role/leading wiring — Verification Report

**Phase Goal:** Apply the theme's typography across all recipes — the single biggest lever for the Phase-118 hierarchy gap — by threading the materialized named type scale, `FontRegistry` font roles, and `leading`/widows/orphans into `%Text{}`, while `default/0` stays a metric no-op that leaves Phase-117 stress goldens unchanged.
**Verified:** 2026-07-28T18:32:00Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Named type scale materialized as explicit points + threaded into every `%Text{size}` across all 7 recipes, exactly one `display` anchor per recipe (TYPE-01, D-01) | ✓ VERIFIED | `defp typography(` present in all 7 recipes (invoice, branded_invoice, statement, receipt, payslip, certificate, ticket). Scales are literal integer/decimal points (e.g. payslip `%{display: 27, title: 13, ...}`). `no_inline_size_literals_test.exs` guards re-introduction of inline `size:` literals. Anchors documented per recipe (Total Due / total / closing balance / net pay / reference code / recipient name). |
| 2 | Font roles resolve through `FontRegistry`; an unregistered role raises `{:unknown_text_font, _}` via `Build.run/1`, never a silent Helvetica substitute (TYPE-02, SC2) | ✓ VERIFIED | `invoice_typography_test.exs`, `statement_typography_test.exs`, `ticket_typography_test.exs` assert `{:error, {:unknown_text_font, :no_such_font}} = Build.run(doc)` for unregistered `fonts.body`/`fonts.mono`. Raise-path is real. |
| 3 | `leading` → `%Text{line_height}` + widows/orphans theme-driven; `default/0` scale/leading a metric no-op — Phase-117 stress goldens byte-identical (TYPE-03, SC3) | ✓ VERIFIED | No-theme literal defaults reproduce 1.2/2/2. All 7 byte-identity goldens + `edge_matrix_test.exs` render byte-identically with ZERO re-bless (93/93 phase tests green). |
| 4 | The font-role seam applies theme typography **correctly** across recipes without regressing themed rendering (D-02 "dark/brand just works") | ✗ FAILED | **BLOCKER (CR-01), independently reproduced.** Themed Payslip crashes: `Payslip.document(data, theme: Rendro.Theme.default()) \|> Rendro.render` → `{:error, %Rendro.Error{reason: {:unsupported_glyph, "•"}, stage: :measure}}` on the byte-identity fixture's own masked payment_method. Theme branch returns `:default` atoms → drops the B612 fallback. Regression from Phase 121. |
| 5 | No-inline-`size:`-literal teeth test guards all 7 recipes; full suite green | ✓ VERIFIED | `no_inline_size_literals_test.exs` present + passing. Full `mix test`: 1676 tests, only 2 failures — both unrelated (missing `.planning/phases/113-*` files, pre-existing, logged in deferred-items.md). |
| 6 | No-theme byte-identity preserved (all 7 goldens + edge_matrix, ZERO re-bless) | ✓ VERIFIED | 93/93 targeted byte-identity + edge_matrix tests green. (Statement *dark/themed* golden was re-blessed as authorized themed drift — the no-theme goldens are unchanged, which is what the must-have constrains.) |

**Score:** 5/6 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/rendro/recipes/*.ex` (×7) | `defp typography/1` seam | ✓ VERIFIED | All 7 present, mirroring `palette/1` |
| `test/rendro/recipes/no_inline_size_literals_test.exs` | TYPE-01 teeth test | ✓ VERIFIED | Present + passing |
| `test/rendro/recipes/{invoice,statement,ticket}_typography_test.exs` | TYPE-02 raise-path | ✓ VERIFIED | Assert `{:unknown_text_font, :no_such_font}` |
| `lib/rendro/recipes/payslip.ex` themed font path | correct themed resolution | ✗ FAILED | Theme branch severs B612 fallback (CR-01) |
| `lib/rendro/recipes/certificate.ex` centering | size+font measurement coupling | ⚠️ PARTIAL | Size coupled; font hardcoded Helvetica (WR-01) |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `opts[:theme]` nil branch | per-recipe literal defaults | byte-identity split | ✓ WIRED | No-theme byte-identity holds across all 7 |
| `theme.typography.fonts.<role>` (unregistered) | `build.ex {:unknown_text_font,_}` | FontRegistry miss | ✓ WIRED | Raise-path tests pass |
| Payslip theme branch | fallback-bearing `:payslip_sans` | font-role remap | ✗ NOT_WIRED | Theme branch returns bare `:default` — fallback dropped (CR-01) |
| Certificate run `font_role` | centering `text_width` measurement | shared font resolve | ⚠️ PARTIAL | Measurement hardcodes Helvetica (WR-01) |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| No-theme Payslip renders | `Payslip.document(data) \|> Rendro.render` | `:ok` | ✓ PASS |
| Themed Payslip renders (canonical masked payment_method) | `Payslip.document(data, theme: Rendro.Theme.default()) \|> Rendro.render` | `{:error, {:unsupported_glyph, "•"}}` | ✗ FAIL |
| Full suite | `mix test` | 1676 tests, 2 failures (unrelated phase-113 files) | ✓ PASS (phase scope) |
| Phase byte-identity + raise-path + teeth | targeted `mix test` (12 files) | 93 tests, 0 failures | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| TYPE-01 | 122-01/02/03/04 | Named type scale materialized as explicit points, threaded into `%Text{}` size | ✓ SATISFIED | Seam in all 7; teeth test; byte-identity |
| TYPE-02 | 122-01/02/03 | Font roles resolve via FontRegistry; unregistered raises typed error | ⚠️ PARTIAL | Raise-path proven; but themed resolution severs Payslip fallback (CR-01) — the seam resolves roles but not *correctly* for a fallback-bearing recipe |
| TYPE-03 | 122-01/02 | `leading`/widows/orphans theme-driven; `default/0` metric no-op | ✓ SATISFIED | Byte-identity goldens unchanged, zero re-bless |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `lib/rendro/recipes/payslip.ex` | 877-894 | Themed font branch returns fallback-less `:default` atoms | 🛑 Blocker | Themed Payslip fails to render (CR-01) |
| `lib/rendro/recipes/certificate.ex` | 340 | Hardcoded `helvetica()` for centering while run uses seamed font role | ⚠️ Warning | Themed mis-centering under custom-font themes (WR-01) |
| `test/rendro/recipes/*_opts_threading_test.exs` | themed assertions | Only `%Section{}` struct equality; never renders themed | ⚠️ Warning | Coverage hole that let CR-01 ship (WR-02) |
| `lib/rendro/recipes/ticket.ex` | 438-439 | `@caption_size 7` / `@present_code_size 6` exempt from scale seam | ℹ️ Info | Documented Q3 decision; two ticket sizes intentionally don't scale with theme (IN-02) |

### Human Verification Required

1. **Themed-Payslip scope/intent decision** — Is a themed-render regression acceptable at phase close, or must the B612 fallback be preserved on the themed path here? The crash is machine-verified; the scope call is human. Note: Phase 123 (themed/dark gallery renders) *depends on* Phase 122 delivering a working typography seam, so deferring this crash to Phase 123 would break Phase 123's own themed-Payslip gallery render — argues for fixing in-phase.

### Gaps Summary

The phase's **no-theme** contract is fully delivered and well-executed: all 7 recipes gained a `typography/1` seam mirroring `palette/1`, the materialized explicit-point type scale threads into every `%Text{}` size, the TYPE-02 raise-path is proven with teeth, leading/widows/orphans are threaded as a metric no-op, and every no-theme byte-identity golden + edge_matrix renders byte-identically with zero re-bless. Against the three literal ROADMAP success criteria (scale threaded, raise-path, no-theme metric no-op), the phase is technically green.

However, the phase **goal** is "apply the theme's typography across all recipes," and the D-02 intent is explicitly "seam text→ink NOW so dark/brand just works." That intent is **not** achieved: applying any theme to Payslip breaks rendering on its own canonical documented data (`{:unsupported_glyph, "•"}`), because the theme branch threads fallback-less `:default` font atoms and severs the B612 unicode fallback that Payslip's D-14/D-17 features depend on. This is a **reproduced regression** from Phase 121 (themed Payslip rendered these glyphs fine when the theme was color-only). The 122-02 SUMMARY itself documents that the `:default` atom "would drop the '•' payment-method glyph" yet only guarded the no-theme branch. A secondary correctness gap (Certificate themed mis-centering, WR-01) and the coverage hole that hid both (themed rendering asserted only via `%Section{}` struct equality, WR-02) compound the issue.

Because a must-have asserting correct themed font-role behavior FAILED and the failure is a machine-reproduced regression, status is **gaps_found**. The fix is localized to `payslip.ex` (remap themed font roles onto the fallback-bearing `:payslip_sans`, or register the theme role atoms with the B612 fallback) plus a themed end-to-end render test, with the Certificate measurement-font coupling as a follow-on warning.

---

_Verified: 2026-07-28T18:32:00Z_
_Verifier: Claude (gsd-verifier)_
