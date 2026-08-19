---
phase: 125-foundation-curated-fonts-style-genre-presets-brand-fixtures
plan: 04
subsystem: testing
tags: [themes, curated-fonts, certificate, deterministic-pdf]
requires:
  - phase: 125-03
    provides: Curated genre tokens and explicit font registration bridge
provides:
  - Certificate compose-time metrics from the exact curated font descriptors
  - Deterministic genre/mode/recipe render matrix
affects: [phase-125-verification, preset-catalog]
tech-stack:
  added: []
  patterns: [private curated metric seam, deterministic render matrix]
key-files:
  created: [test/rendro/theme/preset_render_matrix_test.exs]
  modified: [lib/rendro/theme/presets.ex, lib/rendro/recipes/certificate.ex, lib/rendro/recipes/receipt.ex, priv/public_api.json]
key-decisions:
  - "Certificate preflights only the four Rendro-owned role descriptors before explicit document registration."
  - "The matrix is PDFium-independent and proves repeat-byte equality through Rendro.render/2."
patterns-established:
  - "Curated compose-time metrics use Presets.metric_font!/1 and retain Helvetica compatibility unchanged."
requirements-completed: [PRESET-04, PRESET-05, PRESET-06, FONT-04]
coverage:
  - id: D1
    description: Certificate resolves curated metrics before the explicit registration bridge.
    requirement: FONT-04
    verification:
      - kind: integration
        ref: test/rendro/recipes/certificate_typography_test.exs
        status: pass
    human_judgment: false
  - id: D2
    description: Twelve deterministic genre/mode rows cover the seven recipe families and repeat-byte rendering.
    requirement: PRESET-04
    verification:
      - kind: integration
        ref: test/rendro/theme/preset_render_matrix_test.exs
        status: pass
    human_judgment: false
metrics:
  duration: 18min
  completed: 2026-08-16
status: complete
---

# Phase 125 Plan 04: Curated Certificate Metrics and Render Matrix Summary

**Certificate now measures against the exact curated font face it later embeds, with deterministic genre/mode rendering coverage across the recipe corpus.**

## Performance

- **Duration:** 18min
- **Tasks:** 2/2
- **Files modified:** 6

## Accomplishments

- Added a narrow, undocumented curated metric resolver for Certificate while retaining default Helvetica byte identity and public pipe order.
- Added a fixed 12-row deterministic matrix for six genres in light/dark modes, all seven recipes, explicit registration, typed omissions, and repeated render equality.
- Regenerated the API manifest to include the already-public `Rendro.Theme.preset/2` contract.

## Task Commits

1. **Task 1: Make Certificate use the exact curated descriptor for metrics** — `8a8d3b5` (feat)
2. **Task 2: Prove the fixed deterministic preset/render matrix** — `2487fcf` (test)

## Files Created/Modified

- `lib/rendro/theme/presets.ex` — curated descriptor metric resolver.
- `lib/rendro/recipes/certificate.ex` — exact curated centering and vertical metrics.
- `test/rendro/recipes/certificate_typography_test.exs` — compose-before-register regression coverage.
- `test/rendro/theme/preset_render_matrix_test.exs` — deterministic matrix coverage.
- `lib/rendro/recipes/receipt.ex` — reserves a themed header line budget.
- `priv/public_api.json` — records `Theme.preset/2`.

## Decisions Made

- Kept metric resolution inside the hidden Presets implementation surface; `Rendro.Theme` received no additional API.
- Kept the matrix fully deterministic and independent of PDFium/raster artifacts.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Themed Receipt header could overflow with Humanist metrics**
- **Found during:** Task 2
- **Fix:** Reserve the actual themed title/customer/date line budget while keeping no-theme geometry unchanged.
- **Files modified:** `lib/rendro/recipes/receipt.ex`
- **Verification:** Matrix and Receipt byte-identity tests pass.
- **Committed in:** `2487fcf`

**2. [Rule 2 - Contract drift] Public API manifest omitted `Theme.preset/2`**
- **Found during:** Task 2 verification
- **Fix:** Regenerated `priv/public_api.json` from the checked public module surface.
- **Files modified:** `priv/public_api.json`
- **Verification:** `mix rendro.api.gen` and focused deterministic suite pass.
- **Committed in:** `2487fcf`

## Issues Encountered

None remaining.

## Next Phase Readiness

The curated Certificate seam and deterministic matrix are ready for phase verification and later raster evidence work.

## Self-Check: PASSED

- Verified task commits `8a8d3b5` and `2487fcf` exist.
- Verified all created and modified implementation/test files exist.
