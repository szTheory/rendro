---
phase: 83
plan: 04
subsystem: text-shaping
tags: [shaper, cluster-boundary, measure, property-test, hyg-03, tdd, streamdata]
dependency_graph:
  requires:
    - phase: 83-01
      provides: "Rendro.Text.Shaper behaviour + Shaper.Simple with cluster: 0 placeholder"
    - phase: 83-02
      provides: "Unicode migration (bidi.ex + ScriptTags)"
    - phase: 83-03
      provides: "measure.ex error propagation + from_stage wrapping for shaping_required"
  provides:
    - "split_graphemes/4: run-shaping with cluster-boundary breaking (no more per-grapheme Shaper.shape/3 call)"
    - "glyphs_to_cluster_runs/4: Simple path (cluster=0) zips graphemes/glyphs; HarfBuzz path groups by cluster byte offset"
    - "StreamData property test: per-grapheme width sum == per-run width under Shaper.Simple (D-12)"
    - "CHANGELOG.md [Unreleased]: HYG-03 re-bless event documented (no goldens changed — D-13)"
    - "HYG-03 requirement delivered: split_graphemes shapes runs, not individual graphemes"
  affects:
    - 83-05
    - 87-comparison-page
    - 88-launch-execution
tech_stack:
  added: []
  patterns:
    - "Font-homogeneous run accumulation via append_font_run/3 (already existed for measure_text_into_runs)"
    - "Bidi.split_runs/1 re-invoked on sub-text to determine script for shaping opts in split_graphemes"
    - "Dual-path glyphs_to_cluster_runs: cluster=0 simple zip (Shaper.Simple) vs cluster=byte-offset group (HarfBuzz)"
    - "StreamData property test with `use ExUnitProperties` + `StreamData.string(:ascii)` generator"
key_files:
  created: []
  modified:
    - lib/rendro/pipeline/measure.ex
    - test/rendro/text/shaper_test.exs
    - CHANGELOG.md
key_decisions:
  - "glyphs_to_cluster_runs detects Simple vs HarfBuzz path by checking whether all cluster values are 0 — avoids coupling to module identity"
  - "Script determination in split_graphemes reuses Bidi.split_runs/1 on each font-homogeneous run text — preserves single-classification-source rule (D-08)"
  - "No golden files re-blessed: Latin/Shaper.Simple path is byte-identical by construction (property test proves it); no HarfBuzz golden fixtures exist in the suite"
patterns_established:
  - "Per-grapheme shaping in line-break fallback (split_graphemes) is the authoritative fix site for HYG-03; measure_text_into_runs was already run-based"
  - "Cluster-boundary run structs have the same shape as measure_text_into_runs output — line-break accumulator cond logic is unchanged"
requirements-completed: [HYG-03]
duration: ~30min
completed: "2026-06-10"
---

# Phase 83 Plan 04: Cluster-Boundary split_graphemes + Property Test Summary

**split_graphemes/4 in measure.ex rewritten to shape font-homogeneous runs (not individual graphemes), glyphs_to_cluster_runs/4 helper handles Simple vs HarfBuzz cluster-boundary paths, StreamData property test formally proves per-grapheme == per-run width invariant under Shaper.Simple, and CHANGELOG.md records the D-13 re-bless event (no golden changes needed).**

## Performance

- **Duration:** ~30 min
- **Started:** 2026-06-10T16:35:00Z
- **Completed:** 2026-06-10T17:02:57Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Removed the per-grapheme `Rendro.Text.Shaper.shape(font, grapheme)` call from `split_graphemes/4` — the HYG-03 bug site
- Rewrote `split_graphemes/4` to: (1) resolve font per grapheme into font-homogeneous runs via `append_font_run/3`; (2) shape each run at once via `Rendro.Text.Shaper.shape(font, run_text, script: script)`; (3) convert glyph list to per-cluster run structs via `glyphs_to_cluster_runs/4`; (4) apply the existing max_width line-break accumulator unchanged
- Added `glyphs_to_cluster_runs/4` private helper: detects Shaper.Simple path (cluster=0 for all glyphs) via `Enum.all?`, zips graphemes with glyphs 1:1; detects HarfBuzz path (varied cluster values), groups by cluster byte offset and reconstructs text segments using `binary_part/3`
- Bidi script tag for shaping determined by re-invoking `Rendro.Text.Bidi.split_runs/1` on each font-run text — preserves the single-classification-source rule (D-08), same approach as `measure_text_into_runs`
- Added `use ExUnitProperties` to `shaper_test.exs` and a StreamData property test asserting `per_run_total == per_grapheme_total` for random ASCII strings under Shaper.Simple (D-12). Uses a built_in font with varied widths for 32–126 ASCII codepoints
- Documented the D-13 re-bless event in `CHANGELOG.md [Unreleased]`: no golden files changed (Latin/Simple path is byte-identical by construction; no HarfBuzz golden fixtures exist)

## Task Commits

Each task was committed atomically:

1. **Task 1: StreamData property test for per-grapheme == per-run width** - `476092d` (test)
2. **Task 2: Rewrite split_graphemes + CHANGELOG re-bless entry** - `4bfa5cf` (feat)

## Files Created/Modified

- `test/rendro/text/shaper_test.exs` — Added `use ExUnitProperties`; added property test with ASCII font fixture and `StreamData.string(:ascii, min_length: 1)` generator (D-12)
- `lib/rendro/pipeline/measure.ex` — Rewrote `split_graphemes/4`; added `glyphs_to_cluster_runs/4` helper; removed per-grapheme `Shaper.shape/3` call (HYG-03 fix)
- `CHANGELOG.md` — Added `[Unreleased]` section with HYG-03 fix description and D-13 re-bless event (no goldens changed)

## Decisions Made

- Use cluster=0 detection to distinguish Simple vs HarfBuzz path in `glyphs_to_cluster_runs` — avoids module-identity coupling and works correctly if another Simple-style adapter ever uses cluster=0
- Re-invoke `Bidi.split_runs/1` on each font-homogeneous sub-text in `split_graphemes` to determine script — this is the right behavior because `split_graphemes` is called on arbitrary word chunks that may cross script boundaries; re-running Bidi on each font run is cheap (single-word strings) and correct
- No script parameter threading through `split_chunk`/`wrap_chunks`/`wrap_segment` call chain — would require 4 signature changes for marginal benefit (Bidi re-classification on small strings is correct and cheap)

## Deviations from Plan

None — plan executed exactly as written. The algorithm described in the `<action>` block was implemented faithfully. The property test used an ASCII font fixture with varied per-codepoint widths (rather than Helvetica's sparse widths map) to give the property generator more varied coverage.

## Known Stubs

None.

## Threat Flags

No new network endpoints, auth paths, file access patterns, or schema changes introduced. `glyphs_to_cluster_runs` uses `binary_part/3` on string bytes that were already shaped by the shaper — no user-controlled content reaches binary slicing without first passing through font resolution and shaping.

## Final Verification

```
mix test test/rendro/text/shaper_test.exs → 1 property, 9 tests, 0 failures
mix test test/rendro/deterministic_test.exs → 3 properties, 12 tests, 0 failures
mix test test/rendro/text/ test/rendro/pipeline/ → 1 property, 123 tests, 0 failures
mix test → 12 doctests, 4 properties, 1006 tests, 0 failures (10 excluded)
grep "Shaper.shape.*grapheme\|shape(font, grapheme)" lib/rendro/pipeline/measure.ex → no output
```

## Self-Check: PASSED

Files exist:
- lib/rendro/pipeline/measure.ex ✓
- test/rendro/text/shaper_test.exs ✓
- CHANGELOG.md ✓

Commits exist:
- 476092d ✓ (Task 1: property test)
- 4bfa5cf ✓ (Task 2: split_graphemes rewrite + CHANGELOG)

Verification:
- `grep -n "Shaper.shape.*grapheme\|shape(font, grapheme)" lib/rendro/pipeline/measure.ex` → no output ✓
- Property test in shaper_test.exs passes ✓
- All deterministic goldens pass (no re-bless required) ✓
- `mix test` → 1006 tests, 0 failures ✓
