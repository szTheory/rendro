---
phase: 125
fixed_at: 2026-08-16T22:25:46-04:00
review_path: /Users/jon/projects/rendro/.planning/phases/125-foundation-curated-fonts-style-genre-presets-brand-fixtures/125-REVIEW.md
iteration: 3
findings_in_scope: 1
fixed: 1
skipped: 0
status: all_fixed
---

# Phase 125: Code Review Fix Report

**Fixed at:** 2026-08-16T22:25:46-04:00
**Source review:** `/Users/jon/projects/rendro/.planning/phases/125-foundation-curated-fonts-style-genre-presets-brand-fixtures/125-REVIEW.md`
**Iteration:** 3

**Summary:**
- Findings in scope: 1
- Fixed: 1
- Skipped: 0

## Fixed Issues

### WR-01: [WARNING] PDFium tests race the pinned raster contract through global state

**Files modified:** `test/rendro/adapters/pdfium_test.exs`
**Commit:** 9fc667c
**Applied fix:** Made `Rendro.Adapters.PdfiumTest` synchronous. Tests that exercise application-configured/default provenance now temporarily clear and restore the caller-provided provenance environment override; the override test restores its exact prior value on exit. This prevents the adapter suite from erasing the pinned raster lane's external configuration.

## Verification Notes

- Tier 1: Re-read the changed module, confirmed the synchronous ExUnit case and exact environment restoration helpers; `mix format --check-formatted test/rendro/adapters/pdfium_test.exs` and `git diff --check` passed.
- Pinned runner: `/private/tmp/rendro-pdfium-Riomtw/pdfium-cli` SHA-256 was `b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a`, matching `priv/pdfium_pin.json`; wrapper version was `pdfium version v0.11.0`.
- Combined regression lane: `PATH=/private/tmp/rendro-pdfium-Riomtw/bin:$PATH RENDRO_PDFIUM_PROVENANCE_CLI=/private/tmp/rendro-pdfium-Riomtw/pdfium-cli mix test --include raster_snapshot test/rendro/adapters/pdfium_test.exs test/rendro/theme/preset_raster_snapshot_test.exs` passed repeatedly (six successful executions; the fully reported run: 10 tests, 0 failures).
- `mix test` passed: 12 doctests, 8 properties, 1,732 tests, 0 failures (27 excluded).
- `mix ci.fast` passed: formatting, package build, compile, test, docs, Credo, and Dialyzer completed successfully.

---

_Fixed: 2026-08-16T22:25:46-04:00_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 3_
