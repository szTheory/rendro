---
phase: 75-receipt-report-and-certificate-recipes-support-contract
plan: "03"
subsystem: recipes
tags: [certificate, recipe, geometry-derived, landscape, branding, tdd]
dependency_graph:
  requires: ["75-01"]
  provides: ["Rendro.Recipes.Certificate", "test/rendro/recipes/certificate_test.exs"]
  affects: ["mix.exs groups_for_modules"]
tech_stack:
  added: []
  patterns:
    - geometry-derived coordinates via Rendro.PageSize.resolve/2
    - optional branding (D-08) — unbranded is valid, malformed raises
    - three-rung escape hatch (document/2, page_template/1, sections/2)
    - errors-as-product validate_data!/1 with What/Where/Why/Next
    - body length guard for DoS mitigation (T-75-03-01)
key_files:
  created:
    - lib/rendro/recipes/certificate.ex
    - test/rendro/recipes/certificate_test.exs
  modified:
    - mix.exs
decisions:
  - "align: :center removed — Rendro.Text struct does not support alignment; text flows naturally in body region (Rule 1 auto-fix)"
  - "Certificate added to mix.exs groups_for_modules Canonical Recipes alongside Invoice, BrandedInvoice, Statement, Receipt"
metrics:
  duration: "~4 minutes"
  completed_date: "2026-05-29"
  tasks: 1
  files: 3
---

# Phase 75 Plan 03: Certificate Recipe Summary

Geometry-derived landscape certificate recipe with optional branding, TDD-proven via C1..C13.

## What Was Built

**`lib/rendro/recipes/certificate.ex`** — `Rendro.Recipes.Certificate` three-rung recipe:
- `document/2`: validates data, resolves page geometry, optionally registers brand assets, assembles document
- `page_template/1`: calls `Rendro.PageSize.resolve/2` to get `{pw, ph}`, derives all region coords as expressions over `pw`/`ph`/margins — zero hardcoded numerics
- `sections/2`: single-page; returns `[body_section(data, opts, template)]`
- Default: A4-landscape (D-05); portrait reachable via `orientation: :portrait`
- Branding optional (D-08): `data.brand` with atom `font_name`/`logo_name` registers font+image; `nil` brand passes; malformed brand raises `ArgumentError`
- Body length guard: `byte_size(data.body) > 2000` raises (T-75-03-01 DoS mitigation)

**`test/rendro/recipes/certificate_test.exs`** — 22 tests covering C1..C13:
- C1: basic render → `%Rendro.Document{}`; `{:ok, pdf}` binary starting with `%PDF-`
- C2: no unresolved tokens; content blocks present
- C3: A4-landscape body width == 841.89 - 144 = 697.89 (within 0.01)
- C4: A4 and US-Letter landscape both render without overflow
- C5: body widths differ between sizes (proves geometry-derived, not hardcoded)
- C6: default `page_template()` has `width > height` (landscape)
- C7: portrait opt-in `height > width`
- C8: branded certificate registers `:brand_heading` font and `:company_logo` image
- C9: unbranded certificate renders without error
- C10: `brand.font_name: "not_atom"` raises `ArgumentError ~r/brand/`
- C11: two renders with `deterministic: true` → byte-identical
- C12: `page_template/1` and `sections/2` callable without `document/2`
- C13: missing `:title`/`:recipient`/`:date` each raises `ArgumentError`

## Verification Gates

- `mix test test/rendro/recipes/certificate_test.exs` → 22 tests, 0 failures
- `grep -nE "595\.28|841\.89|451\.28|697\.89" lib/rendro/recipes/certificate.ex` → no matches (CERT-02)
- `mix compile --warnings-as-errors` → clean
- Statement + Receipt regression: 94 tests, 0 failures

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed `align: :center` from `Rendro.text/2` calls**
- **Found during:** GREEN phase implementation
- **Issue:** `Rendro.Text` struct has no `:align` field. Using `align: :center` in `Rendro.text/2` attrs causes `KeyError` at struct construction time. The RESEARCH.md/PATTERNS.md referenced this feature but it doesn't exist in the engine.
- **Fix:** Removed `align: :center` from all six `Rendro.text/2` calls in `body_section/3`. Text flows naturally within the body region (`:flow` anchor, full content width).
- **Files modified:** `lib/rendro/recipes/certificate.ex`
- **Commit:** `05a7800`

**2. [Rule 2 - Missing critical functionality] Unused `_content_w` pattern**
- **Found during:** GREEN phase — `template` was passed to `body_section/3` per plan but after removing `align: :center`, `content_w` computation still uses the template correctly as a geometry-derived value. Kept the computation to demonstrate CERT-02 compliance (geometry derived from template, not constants).

## TDD Gate Compliance

- RED gate: commit `4ced9b0` — `test(75-03): add failing tests C1..C13 for Certificate recipe (RED)`
- GREEN gate: commit `05a7800` — `feat(75-03): implement Rendro.Recipes.Certificate (GREEN)`

## Self-Check: PASSED

Files created:
- `lib/rendro/recipes/certificate.ex` — EXISTS
- `test/rendro/recipes/certificate_test.exs` — EXISTS

Commits:
- `4ced9b0` — RED phase test file
- `05a7800` — GREEN phase implementation + mix.exs update
