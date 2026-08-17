---
phase: 125-foundation-curated-fonts-style-genre-presets-brand-fixtures
plan: 01
subsystem: theming
tags: [theme, presets, fonts, deterministic-pdf]
requires: []
provides: [strict-swiss-preset, explicit-curated-font-registration]
affects: [theme, invoice-rendering, hex-package]
tech-stack:
  added: []
  patterns: [pure-theme-values, document-owned-font-registry, explicit-registration]
key-files:
  created:
    - lib/rendro/theme/presets.ex
    - priv/fonts/inter/Inter-Regular.ttf
    - priv/fonts/jetbrains-mono/JetBrainsMono-Regular.ttf
    - test/rendro/theme/presets_test.exs
  modified:
    - lib/rendro/theme.ex
    - mix.exs
decisions:
  - Theme.preset/2 is a narrow delegation; the preset registry and font paths remain private to Rendro.Theme.Presets.
  - Swiss font roles register explicitly against each caller-owned document and reject unequal role collisions.
metrics:
  duration: 2m
  completed: 2026-08-17
  tasks_completed: 1
  files_changed: 6
status: complete
coverage:
  - id: D1
    description: Strict Swiss preset construction, dark resolution, and actionable invalid-input errors.
    requirement: PRESET-01
    verification:
      - kind: unit
        ref: test/rendro/theme/presets_test.exs#preset/2
        status: pass
    human_judgment: false
  - id: D2
    description: Explicit, isolated Inter and JetBrains Mono registration with idempotence and collision protection.
    requirement: FONT-04
    verification:
      - kind: integration
        ref: test/rendro/theme/presets_test.exs#register_fonts/2
        status: pass
    human_judgment: false
  - id: D3
    description: Un-themed Invoice output remains byte-identical after preset support was added.
    requirement: PRESET-05
    verification:
      - kind: integration
        ref: test/rendro/recipes/invoice_byte_identity_test.exs
        status: pass
    human_judgment: false
---

# Phase 125 Plan 01: Swiss Preset Tracer Summary

**Strict Swiss theme construction with explicit, document-owned Inter and JetBrains Mono registration that renders deterministic Invoice PDFs.**

## Accomplishments

- Added the public `Rendro.Theme.preset/2` façade with a strict canonical Swiss boundary, exact D-10 tokens, required accent, deterministic color handling, and dark-mode application last.
- Added `Rendro.Theme.Presets.register_fonts/2`, which uses `Application.app_dir/2` descriptors, preserves typed omission errors, permits exact repeat registration, rejects collisions, and leaves separate documents isolated.
- Vendored official Inter 4.1 and JetBrains Mono 2.304 static Regular TrueType faces, and added `priv/fonts` to the Hex package allowlist.
- Proved the entire caller path — preset → Invoice document → explicit registration → deterministic render — while preserving the frozen un-themed Invoice byte golden.

## Verification

- `mix test test/rendro/theme/presets_test.exs test/rendro/recipes/invoice_byte_identity_test.exs --max-failures 1` — passed (8 tests, 0 failures).
- `mix format --check-formatted` — passed.
- `mix hex.build --unpack` — passed; unpacked package contains both curated TTF files.
- SHA-256 verified: Inter `40d692fce188e4471e2b3cba937be967878f631ad3ebbbdcd587687c7ebe0c82`; JetBrains Mono `a0bf60ef0f83c5ed4d7a75d45838548b1f6873372dfac88f71804491898d138f`.

## Decisions Made

- Kept `theme.ex` registry-inert with exactly one readable delegation; token tables, paths, and collision behavior live in the private Presets module.
- Matched registration idempotence against the exact normalized descriptor, never overwriting caller-owned conflicting roles.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed an invalid remote function guard during green implementation.**
- **Found during:** Task 1
- **Issue:** `Keyword.keyword?/1` is not legal in a guard.
- **Fix:** Moved keyword-list validation into the function body while retaining the strict contract.
- **Files modified:** `lib/rendro/theme/presets.ex`
- **Commit:** ebde2bc

## Self-Check: PASSED

- Required source, test, and both vendored font files exist.
- RED (`af2ef5d`) and GREEN (`ebde2bc`) commits are present in git history.
