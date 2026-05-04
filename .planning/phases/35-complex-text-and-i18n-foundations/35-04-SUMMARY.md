---
phase: "35"
plan: "04"
subsystem: "pdf"
tags:
  - "font-fallback"
  - "harfbuzz"
  - "tests"
dependency_graph:
  requires: ["35-03"]
  provides: ["font-fallback-resolution"]
  affects: ["rendro", "pdf"]
tech_stack:
  added: []
  patterns: []
key_files:
  created: ["lib/rendro/pdf/cid_font.ex"]
  modified:
    - "lib/rendro/text/bidi.ex"
    - "lib/rendro/text/shaper.ex"
    - "lib/rendro/pdf/writer.ex"
    - "test/rendro/deterministic_test.exs"
    - "test/rendro/pipeline/measure_test.exs"
    - "test/rendro/pipeline/paginate_test.exs"
    - "test/rendro/text/shaper_test.exs"
key_decisions:
  - "Implemented exact HarfBuzz widths for accurate text measurement."
  - "Adjusted layout and wrapping tests to account for the narrower and more precise HarfBuzz character widths, forcing wrap points appropriately."
metrics:
  duration_minutes: 10
  tasks_completed: 4
  tasks_total: 4
  files_changed: 8
  test_pass_rate: 100
---

# Phase 35 Plan 04: Fallback Font Resolution Summary

Exact HarfBuzz width and fallback testing adjustments to ensure proper text layouts.

## Completed Work
1. Addressed remaining font fallback measurements in Shaper and Bidi pipeline.
2. Repaired exact tests reflecting narrower precise text-width derivations from HarfBuzz vs native estimates.
3. Updated PDF writing to accurately render Bidi output natively in fallback modes.
4. Passed all PDF generator flow testing end-to-end to ensure layout parity.

## Deviations from Plan
### Auto-fixed Issues
**1. [Rule 1 - Bug] Text wrap expectations failed due to HarfBuzz precision**
- **Found during:** Testing
- **Issue:** The built-in vs embedded fonts tests were no longer wrapping on width `150` because HarfBuzz reported the B612 font was narrower than expected.
- **Fix:** Reduced explicit container test widths to `100` to correctly assert deterministic text flow behavior natively.
- **Files modified:** `test/rendro/pipeline/paginate_test.exs`, `test/rendro/deterministic_test.exs`
- **Commit:** e861120

## Self-Check: PASSED
- [x] All 425 unit tests pass locally.
- [x] All required test and implementation modules committed individually.
- [x] Documentation matches new test behaviors.