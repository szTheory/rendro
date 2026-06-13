---
phase: 83-claim-accuracy-shaping-hygiene
plan: 03
subsystem: text-shaping
tags: [shaper, error-propagation, measure, error-clauses, hyg-02, tdd]
dependency_graph:
  requires:
    - phase: 83-01
      provides: "Rendro.Text.Shaper behaviour + Shaper.Simple + HarfBuzz adapter with {:shaping_required, script, hint} error format"
  provides:
    - "error.ex: why/2 and next_step/2 clauses for {:shaping_required, script, hint} and {:shaping_required, script}"
    - "measure.ex: from_stage(:measure, reason) wrapping for shaping_required errors in measure_block"
    - "measure_test.exs: HYG-02 integration test for Arabic text → structured Rendro.Error"
    - "HYG-02 requirement delivered: Arabic/complex script rendering returns deterministic instructive error"
  affects:
    - 83-04
    - 83-05
    - 88-launch-execution
tech_stack:
  added: []
  patterns:
    - "from_stage wrapping at measure_block level for shaping_required errors — colocates error struct creation with the specific error path, upstream of pipeline.ex span()"
    - "Fake font injection via %{source: :embedded, pdf_font: %Rendro.PDF.Font{source: :built_in}} descriptor for async-safe integration tests without Arabic font files"
    - "HarfBuzz adapter built-in font delegation as test leverage — no shaper config override needed in HYG-02 test"
key_files:
  created: []
  modified:
    - lib/rendro/error.ex
    - lib/rendro/pipeline/measure.ex
    - test/rendro/error_test.exs
    - test/rendro/pipeline/measure_test.exs
    - test/rendro/i18n_test.exs
key_decisions:
  - "Remove I18n analyzer early-bail from measure_block/3 Text path; shaper gate (shaping_required) replaces it with superior actionable error including config fix line"
  - "Add from_stage wrapping only for shaping_required errors in measure_block else clause, preserving raw tuples for other error paths (unsupported_glyph, missing_asset, grid_too_large) — existing tests rely on raw tuples"
  - "HYG-02 test uses fake built-in font with Arabic codepoints in widths map to pass font resolution, stays async: true by leveraging HarfBuzz→Simple delegation"
patterns_established:
  - "Shaper-level complex-script gate is the authoritative fence; I18n pre-flight checks are redundant when the shaper already handles the same error class with better messages"
  - "from_stage wrapping can be added selectively at the measure_block level for specific error reasons without breaking tests that rely on raw tuples from other error paths"
requirements-completed: [HYG-02]
duration: 45min
completed: "2026-06-10"
---

# Phase 83 Plan 03: shaping_required Error Clauses + HYG-02 Integration Summary

**error.ex gains four clauses (2 why + 2 next_step) for {:shaping_required, script, hint}, measure.ex wraps shaping_required errors via from_stage at measure_block level, and HYG-02 integration test confirms Arabic text returns a structured Rendro.Error from Measure.run/1**

## Performance

- **Duration:** ~45 min
- **Started:** 2026-06-10T17:00:00Z
- **Completed:** 2026-06-10
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added `why/2` and `next_step/2` clauses to `error.ex` for both `{:shaping_required, script, hint}` (uses hint verbatim) and `{:shaping_required, script}` (Code.ensure_loaded? branch) — three-arg before two-arg per compiler shadowing rule
- Removed redundant I18n analyzer early-bail from `measure_block/3` Text path; the shaper gate in Shaper.Simple is now the authoritative complex-script fence with superior error messages (names script + config fix line)
- Added `from_stage(:measure, reason)` wrapping in `measure_block` else clause for `shaping_required` errors so `Measure.run/1` returns a `%Rendro.Error{}` directly (not a raw tuple)
- Added HYG-02 integration test asserting Arabic text via a fake Arabic-capable built-in font → `{:error, %Rendro.Error{stage: :measure, reason: {:shaping_required, :arab, _}}}` from `Measure.run/1`

## Task Commits

Each task was committed atomically:

1. **Task 1: Add shaping_required error clauses to error.ex** - `8b695b5` (feat)
2. **Task 2: Soften hard-match sites in measure.ex + HYG-02 integration test** - `18fb740` (feat)

## Files Created/Modified

- `lib/rendro/error.ex` — Added 4 new clauses: `why/2` × 2 and `next_step/2` × 2 for `:shaping_required` reason
- `lib/rendro/pipeline/measure.ex` — Removed I18n analyzer early-bail; added `from_stage` wrapping for shaping_required errors in measure_block else clause
- `test/rendro/error_test.exs` — Added 2 TDD tests for shaping_required why/next_step behavior
- `test/rendro/pipeline/measure_test.exs` — Added HYG-02 integration test (Arabic text → structured Rendro.Error) + Latin passthrough test
- `test/rendro/i18n_test.exs` — Updated Arabic test assertion to match new error path ({:unsupported_glyph} instead of {:unsupported_script}) since font resolution fails before shaper for default Helvetica

## Decisions Made

- Remove I18n analyzer early-bail in favor of shaper gate — the I18n analyzer returned `{:unsupported_script, :rtl_required}` without config fix hints; the shaper gate returns `{:shaping_required, :arab, hint}` with the exact `config :rendro, shaper: Rendro.Adapters.HarfBuzz` line. The shaper gate is strictly superior.
- Add `from_stage` wrapping selectively (only for `shaping_required`) in `measure_block` else clause rather than at `Measure.run/1` boundary — existing tests rely on raw tuples for `{:unsupported_glyph, ...}`, `{:missing_asset, ...}`, and `:grid_too_large`. Selective wrapping preserves all existing tests while delivering the HYG-02 structured error requirement.
- HYG-02 test stays `async: true` by using a fake built-in font struct injected via `%{source: :embedded, pdf_font: %Rendro.PDF.Font{source: :built_in}}` descriptor — HarfBuzz adapter delegates `:built_in` source fonts to Simple, triggering the shaping_required gate without requiring Arabic font files or shaper config overrides.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] I18n analyzer early-bail blocked the shaper-level error path**
- **Found during:** Task 2 (HYG-02 integration test)
- **Issue:** `Rendro.I18n.Analyzer.analyze/1` fires BEFORE `wrap_text` is called in `measure_block/3`, returning `[%{type: :unsupported_script, reason: :rtl_required}]` for Arabic text. This causes `measure_block` to return `{:error, {:unsupported_script, :rtl_required}}` without ever reaching the shaper. The plan's test asserted `{:shaping_required, :arab, _hint}` which requires the shaper path. The I18n error message also lacks the config fix hint.
- **Fix:** Removed the `[] <- Rendro.I18n.Analyzer.analyze(text.content)` guard and `[%{type: :unsupported_script, ...} | _] ->` else clause from `measure_block/3`. The shaper gate (Shaper.Simple returning `{:shaping_required, script, hint}`) is the authoritative complex-script fence. Updated `i18n_test.exs` to expect `{:unsupported_glyph, _char}` (the actual error when using Helvetica with Arabic text — font resolution fails first, which is correct behavior for a font-not-configured scenario).
- **Files modified:** `lib/rendro/pipeline/measure.ex`, `test/rendro/i18n_test.exs`
- **Verification:** `mix test` — 978 tests, 0 failures
- **Committed in:** `18fb740` (Task 2 commit)

**2. [Rule 1 - Bug] I18n analyzer reported inferior error for Arabic text with default font**
- **Found during:** Task 2 diagnosis
- **Issue:** The existing `i18n_test.exs` test asserted `error.reason == {:unsupported_script, :rtl_required}`. After removing the I18n analyzer early-bail, Arabic text with Helvetica (default font, no Arabic glyphs) returns `{:unsupported_glyph, "م"}` because `Font.has_glyph?` fails first in font resolution.
- **Fix:** Updated `i18n_test.exs` to assert `{:unsupported_glyph, _char}` and `error.next =~ "fallback font"`. This is the correct, honest test: with the default Helvetica font, Arabic characters are unsupported glyphs. Users wanting Arabic text need both an Arabic font AND the HarfBuzz adapter.
- **Files modified:** `test/rendro/i18n_test.exs`
- **Committed in:** `18fb740` (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (both Rule 1 - Bug)
**Impact on plan:** Both fixes necessary for correctness. Removed an inferior pre-filter in favor of the authoritative shaper gate. No scope creep.

## Issues Encountered

- The plan assumed Arabic text would flow directly to the shaper, but the `I18n.Analyzer` pre-flight was not mentioned in the plan or research. It fired first and blocked the shaper-level error. Diagnosis required tracing the code path; resolution was to remove the now-redundant pre-filter.
- The HYG-02 test required a fake font with Arabic codepoints since no Arabic test font is available in the project fixtures. Solution: inject a pre-built `%Rendro.PDF.Font{source: :built_in}` via an embedded descriptor with `pdf_font:` field, which the FontRegistry's `to_pdf_font/2` clause accepts directly.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- HYG-02 is complete: Arabic/complex-script text with the default shaper returns a deterministic instructive `%Rendro.Error{stage: :measure}` with config fix in `error.next`
- `error.ex` `why/2` and `next_step/2` clauses for `shaping_required` are in place for both 3-arg and 2-arg forms
- Both hard-match `{:ok, glyphs} = Rendro.Text.Shaper.shape(...)` sites in measure.ex are replaced (done in Plan 83-01 Rule 3; this plan adds the error-wrapping layer on top)
- Concerns: The I18n analyzer module (`lib/rendro/i18n/analyzer.ex`) is now dead code — it is no longer called from anywhere in `lib/`. Can be removed in a cleanup pass or left as dormant reference material.

## Threat Flags

No new network endpoints, auth paths, file access patterns, or schema changes introduced. All error messages name internal script atoms and static config snippets — no user-controlled content in error construction.

## Self-Check: PASSED

Files exist:
- lib/rendro/error.ex ✓
- lib/rendro/pipeline/measure.ex ✓
- test/rendro/error_test.exs ✓
- test/rendro/pipeline/measure_test.exs ✓
- test/rendro/i18n_test.exs ✓

Commits exist:
- 8b695b5 ✓ (Task 1: error.ex clauses)
- 18fb740 ✓ (Task 2: measure.ex + HYG-02 test)

Verification:
- `grep -n "= Rendro.Text.Shaper.shape" lib/rendro/pipeline/measure.ex` → no output ✓
- `mix test test/rendro/pipeline/measure_test.exs` → 25 tests, 0 failures ✓
- `mix test test/rendro/error_test.exs` → 27 tests, 0 failures ✓
- `mix test` → 978 tests, 0 failures ✓
