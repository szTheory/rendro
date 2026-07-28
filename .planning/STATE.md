---
gsd_state_version: 1.0
milestone: v2.11
milestone_name: Document Theming & Design-Token System
current_phase: 121
current_phase_name: all 7 recipes
status: planning
stopped_at: Completed 123-05-PLAN.md
last_updated: "2026-07-28T21:08:46.675Z"
last_activity: 2026-07-28
last_activity_desc: Phase 123 complete, transitioned to Phase 121
progress:
  total_phases: 12
  completed_phases: 5
  total_plans: 25
  completed_plans: 21
  percent: 42
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-07-27)

**Core value:** Phoenix teams can generate reliable, auditable, deterministic PDFs from Elixir data/components, with clear pagination behavior and production-grade observability.
**Current focus:** Phase 123 — from-brand-2-e2e-honest-rubric-gap-closure-gallery-docs-mani

## Current Position

Phase: 121 — Light/dark background-fill mechanism (all 7 recipes)
Plan: Not started
Status: Ready to plan
Last activity: 2026-07-28 — Phase 123 complete, transitioned to Phase 121

Progress: [████████░░] 84%

## Roadmap Snapshot (v2.11, Phases 119-123)

```text
[████████████████░░░░░░░░░░░░░░░░░░░░░░░░] 40% — 2/5 phases complete
Phase 119 Rendro.Theme core module (one-way door) ........ ✓ Complete
Phase 120 S1 retrofit + theme: swap (7 recipes) .......... ✓ Complete
Phase 121 Light/dark background-fill mechanism ........... Ready to plan
Phase 122 Typography type-scale application .............. Not started
Phase 123 from_brand/2 E2E + honest rubric-gap + docs .... Not started
```

## Accumulated Context

### Decisions

Full log in PROJECT.md Key Decisions. Milestone-B locks carried into planning:

- **Additive minor (hex `1.2.0`), NOT a major.** The public API only grows (new `Rendro.Theme`); `default/0` is engineered so an un-themed `document(data)` reproduces v2.10 bytes for all 7 recipes (PLUMB-03 — the central regression guard).
- **The single irreversible act:** `Rendro.Theme` entering `priv/public_api.json` on the **adapter/Evolving** tier (field shape frozen by discipline; token values + rendered output may evolve). Expect a planned red→green on `public_api_contract_test.exs` — grep ALL hidden-modules assertions incl. any duplicate in `manifest_test.exs` (the Phase-115 `Format` lesson).
- **Code-grounded correction:** the S1 `palette` seam exists in only **3 of 7** recipes. The 4 un-seamed recipes (Statement/Certificate/Receipt/BrandedInvoice) need a byte-identical `palette/1` retrofit (Phase 120) with sha256 goldens committed **separately** from any theme swap. Certificate's `{34,34,34}` frame is the non-black default to flag in-plan.
- **Light/dark determinism:** background is a first-in-list `:background` page-template region (`apply_page_template/5` repeats it on every page incl. overflow — zero paginate change); emit the rect ONLY when it changes pixels; resolve every role to integer `{r,g,b}` once in `resolve/1` (no per-draw float tint math).
- **Type scale = the one net-new surface + biggest rubric lever.** Materialize as explicit point sizes (not a `:math.pow` formula); `default/0` scale/leading is a metric no-op (Phase-117 goldens unchanged); `leading` is a multiplier matching `Text.line_height`.
- **Rubric-gap remediation honesty:** the Phase-118 SHOW-01 root cause is DATA not color. Fix `transform_invoice` (dropped parties/totals) → make the one key fact structurally dominant → THEN apply `default/0` → re-score with human sign-off. Never flip a rubric score to `passed:true` in a commit that only changed colors.
- **Guards held:** engine untouched (no theme-aware field on any pipeline stage); `brand:` orthogonal to `theme:` (`from_brand/2` emits tokens only, never registers an asset); every shipped demo is light (dark is screen-oriented, no print/PDF-UA claim); permanent exclusions by construction (shadow/z-index/opacity/gradient/motion/focus/raw-scales/weight-axis/letter-spacing/wide-gamut); industry-agnostic `lib/` guard on `theme.ex`; zero new dependencies.
- [Phase ?]: Compact density honored as fixed-constant leading nudge (1.1) to preserve resolve/1 idempotence
- [Phase 119]: WCAG 2.4 gamma computed via :math.exp/:math.log (no :math.pow); type scale stays explicit points
- [Phase ?]: 119-02: Rendro.Theme registered on adapter tier; both byte-equality manifest assertions RG-1 (public_api_contract_test:72) + RG-2 (manifest_test:98) reconciled green together per D-06
- [Phase ?]: 120-01: Certificate resolve_frame_opts widened /7->/8 to thread colors; byte-identical since colors.rule defaults to {34,34,34}
- [Phase ?]: 120-01: Statement/Certificate palette/1 seams frozen with sha256 byte-identity tests; zero theme reads (split-commit before swap)
- [Phase ?]: 120-02: Receipt/BrandedInvoice palette/1 ink seams retrofitted; primary text reads colors.ink (default {0,0,0}); byte-identical frozen sha256 goldens (BrandedInvoice net-new). Zero theme reads (split-commit before swap).
- [Phase ?]: 120-02: Receipt/BrandedInvoice page_template/1 KeyError gotcha fixed via Keyword.take struct-key whitelist (dropping :palette/:theme so they thread to palette/1).
- [Phase ?]: Phase 120 Plan 03: swapped Statement/Certificate/Receipt/BrandedInvoice palette/1 to theme.colors via case opts[:theme]; :palette wins over :theme (D-01); no-theme byte-identical (PLUMB-03)
- [Phase ?]: 120-04: swapped Invoice/Payslip/Ticket palette/1 to theme.colors via case opts[:theme]; :palette wins over :theme (D-01); no-theme byte-identical (PLUMB-03). Phase-wide no_inline_color_literals source-scan (PLUMB-02) + typography-free guard (D-04) added. Phase 120 complete: all 7 recipes themable.
- [Phase ?]: 121-01: Rendro.Recipes.Background helper (emit?/region/section) created as the single source of truth for the :background full-page fill; Statement fully text-seamed + wired, byte-identical light path, dark golden blessed
- [Phase ?]: 121-04: theming support-matrix rows (light=supported, dark=supported_screen_oriented) added with boundaries flat-map; dark/1 @doc gained explicit screen-oriented not-for-print sentence; theming_claims_test.exs binds every boundary to proof with overclaim tripwire + non-vacuity teeth
- [Phase ?]: Certificate palette/1 nil-branch completed with ink/muted/background; deliberate non-black rule:{34,34,34} frame stress default preserved unchanged (121-02)
- [Phase ?]: Certificate's own resolved landscape {pw,ph} threaded to Background.region/section — proves the dark mechanism on non-portrait geometry, never Statement's portrait A4 constants (121-02, Pitfall 4)
- [Phase ?]: 121-03: Payslip/Invoice/Receipt/BrandedInvoice/Ticket all wire the shared :background region+section into page_template/1+sections/2, gated on Background.emit?(palette(opts)); BrandedInvoice gained explicit @page_width/@page_height (595.28x841.89) mirroring the PageTemplate struct default it always implicitly relied on; all 7 recipes now carry the dark-mode background mechanism
- [Phase ?]: 121-03: fixed 2 stale PLUMB-02 whitelist tests (Receipt, BrandedInvoice) using theme: :ignored -- page_template/1 now resolves palette(opts) for real to gate the background region, so the placeholder atom no longer round-trips through Theme.resolve/1; swapped to theme: %{}
- [Phase ?]: 122-01: Invoice typography/1 seam (twin of palette/1) threads scale/fonts/leading into every %Text; no-theme literal-defaults preserve byte-identity (zero re-bless); Total Due is the sole display anchor (D-01); TYPE-02 raise-path proven on fonts.mono/body; D-04 guard retired
- [Phase ?]: 122-02: replicated the typography/1 tracer onto Statement/Receipt/Payslip; each has a defp typography/1 (twin of palette/1) threading scale/fonts/leading into every %Text with exactly one display anchor (closing balance / total / net pay); no-theme byte-identity preserved (zero re-bless)
- [Phase ?]: 122-02: Payslip no-theme fonts use the STRING "Helvetica" (resolves to document default :payslip_sans + B612 unicode fallback), NOT :default atom — :default drops the fallback + changes the font resource, breaking the '•' glyph and byte-identity. General rule: recipes overriding put_default_font must use the string literal on the no-theme path
- [Phase ?]: 122-02: statement/dark themed golden re-blessed — the seam intentionally collapses the themed render onto the theme's uniform type scale (TYPE-01); determinism held, no-theme goldens unchanged, dark is screen-oriented
- [Phase ?]: 122-03: BrandedInvoice display anchor = brand name (18), the sole non-:default literal-default font exception (brand font kept on both paths, brand-orthogonal-to-theme)
- [Phase ?]: 122-03: Certificate threads one resolved size into BOTH the %Text{} run AND the centering math (line_h/text_width) to avoid themed de-centering (Pitfall 2)
- [Phase ?]: 122-03: Ticket exempts @caption_size(7)/@present_code_size(6) from the scale seam (font-only mono); reference code(8) is the sole display anchor via non-monotone assignment (Q3)
- [Phase ?]: 122-04: TYPE-01 teeth test keys @size_literal on a numeric literal after size:, so size: type.scale.<role> and size: @attr variable reads are inherently non-matching — no per-recipe allowlist needed for exempt mono micro-sizes.
- [Phase ?]: 122-05: Payslip theme branch remaps fonts onto :payslip_sans (its only fallback-bearing font) to close CR-01 — themed Payslip renders its own masked/accented data; glyph correctness outranks a themed font swap since no shipped theme sets non-:default fonts
- [Phase ?]: 122-05: Certificate centering-measurement font keyed on the emitted font_role via centering_measure_font/1; non-Helvetica-metric role raises {:unsupported_centered_font_role} (WR-01). Certificate has no non-centered run so {:unknown_text_font} stays representatively proven on Statement
- [Phase ?]: 123-01: Committed a test asserting transform_invoice/1's issuer/customer/totals.total survive (non-nil), locking the Phase-115 DATA fix as Commit 1 of the D-05 honest order (test-only diff, verified via git show --stat)
- [Phase ?]: 123-02: leading 1.2 -> 1.35 landed as the sole D-01 value change (colors byte-identical); measure.ex scales EVERY %Text block's height by leading (not just multi-line prose) which crashed Statement/Payslip themed render with :content_overflow -- fixed via a theme-gated header/footer geometry budget (case opts[:theme], mirroring palette/1 idiom), no-theme byte-identity fully preserved
- [Phase ?]: 123-03: retagged all 7 gallery rows to theme: Theme.default() (re-blesses all 7, not just leading, per the Big Finding); readme_hero S7 seam added; Certificate hierarchy checkpoint measured (ratio 1.27, visually confirmed still dominant, no fix needed); 3 new honesty findings (Invoice dark table illegibility, Ticket display/title hierarchy inversion, Payslip numeric wrap) discovered and deferred to Plan 05/WINDOWS.md rather than silently patched
- [Phase ?]: 123-04: guides/theming.md ships 3 executable from_brand/2 fences (D-04, guide fence IS the E2E test); theming.light gained proof-backed capabilities (from_brand_accent_seed/on_accent_readable_default/brand_theme_orthogonal); fixed pre-existing mix docs --warnings-as-errors break (Rendro.Color.validate/1 hidden-function doc reference, predates this phase) and a stale 7-vs-11 gallery-count test left over from 123-03
- [Phase ?]: Ticket honestly recorded passed:false (content_hierarchy 3, typographic_craft 3) per human sign-off -- themed uniform scale inverted the reference-code/placement-grid hierarchy; not flattened to true (D-05 anti-trap).
- [Phase ?]: Certificate recorded passed:true despite recipient/title ratio compressing 1.70->1.27 (themed) -- human visual sign-off confirmed recipient still unambiguous focal point; compression disclosed in SIGN-OFF.md, not hidden.

### Pending Todos

None yet.

### Blockers/Concerns

- **Watch (Phase 119):** the `Theme` public promotion will edit `public_api_contract_test.exs`'s hidden set — expect a deliberate red build until the manifest is regenerated and the tier tag applied. Grep for the second, plan-unlisted hidden-modules assertion.
- **Calibration open questions** (not architecture — locked recommendations in REQUIREMENTS.md): exact type-scale point sizes, `on_accent` luminance heuristic, legacy `:palette` preservation via `Map.merge`, `theming.light`/`theming.dark` as separate support rows, `density: :compact` shallow honoring.
- Plan 05 human sign-off must consider 3 new findings from 123-03: Invoice dark-mode table illegibility (invoice_dark), Ticket display/title hierarchy inversion (ticket/ticket_dark), Payslip numeric-cell wrap (payslip) -- WINDOWS.md ids 1-3

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| Presets/Catalog | Style-genre presets, preset fonts, public catalog, static configurator | Deferred to Milestone C (`SEED-004`) | v2.11 scoping |
| Studio | Live server-rendered theme playground | Deferred to Milestone D (`SEED-005`) | v2.11 scoping |
| Typography | Tabular figures / small-caps / OpenType features | Demand-gated (need new engine primitives) | v2.11 scoping |

## Session Continuity

Last session: 2026-07-28T20:55:50.231Z
Stopped at: Completed 123-05-PLAN.md
Resume file: None

## Next Steps

1. `/gsd-discuss-phase 121` — gather context for the light/dark background-fill mechanism: a role-derived full-page `:background` page-template region that repeats on every page (incl. overflow), giving every recipe dark for free, with the light default emitting no rect and staying byte-identical. (Watch WR-01 from Phase 120: Statement's closing-balance band text is not seamed and would be invisible on a dark background — seam it here.)
2. `/gsd-plan-phase 121` — skip discussion and plan directly.

## Performance Metrics

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 121 P01 | 25min | 2 tasks | 4 files |
| Phase 121 P04 | 3min | 2 tasks | 3 files |
| Phase 121 P02 | 12min | 2 tasks | 3 files |
| Phase 121 P03 | 20min | 2 tasks | 7 files |
| Phase 122 P01 | 18min | 2 tasks | 4 files |
| Phase 122 P02 | 32min | 3 tasks | 7 files |
| Phase 122 P03 | 9min | 3 tasks | 8 files |
| Phase 122 P04 | 4min | 2 tasks | 1 files |
| Phase 122 P05 | 14min | 3 tasks | 5 files |
| Phase 123 P01 | 2min | 2 tasks | 1 files |
| Phase 123 P02 | 30min | 2 tasks | 7 files |
| Phase 123 P03 | 26min | 3 tasks | 18 files |
| Phase 123 P04 | 14min | 3 tasks | 6 files |
| Phase 123 P05 | 6min | 2 tasks | 6 files |
