---
phase: 73-page-numbering-running-region-primitive
plan: "02"
subsystem: pipeline
tags: [elixir, pdf, paginate, measure, body_capacity, page-numbering, running-region]

requires:
  - phase: 73-01
    provides: "Wave 0 RED stubs: body_capacity == 504 in measure_test, flow_layout fallback stub in paginate_test"

provides:
  - "Fixed body_capacity/1 in measure.ex — geometric overlap-aware subtraction of header/footer region heights"
  - "Fixed flow_layout/1 body_capacity in paginate.ex — derives header/footer heights from template.regions"
  - "PAGE-03 Wave 0 stubs GREEN: body_capacity == 504 and flow_layout fallback"

affects:
  - "73-03: total_pages threading (reads body_capacity via layout)"
  - "73-04: suppression and fn-evaluation (uses same flow_layout/1 layout map)"
  - "74-76: recipes that rely on non-zero header/footer regions not overlapping body content"

tech-stack:
  added: []
  patterns:
    - "Geometric overlap check for header/footer subtraction: only subtract region height when it physically overlaps the body region (body_y + body_h >= footer_y for footer; body_y < header_y + header_h for header)"
    - "Nil-region guard: if region, do: region.height || 0, else: 0"
    - "flow_layout/1 uses Enum.find(template.regions, &(&1.name == :header/:footer)) to derive heights"

key-files:
  created: []
  modified:
    - lib/rendro/pipeline/measure.ex
    - lib/rendro/pipeline/paginate.ex
    - test/rendro/pipeline/paginate_test.exs

key-decisions:
  - "D-04 geometric overlap check (deviation from plan's simple body_h - header_h - footer_h): subtract header/footer heights only when they physically overlap the body region, preserving correctness for templates where body is already explicitly positioned below the header and above the footer"
  - "Both fix sites committed atomically in one commit (Pitfall 1 prevention)"

patterns-established:
  - "body_capacity geometric subtraction: check body_y < header_y + header_h (strict) for header; body_y + body_h >= footer_y for footer; only subtract when overlap exists"
  - "flow_layout/1 fallback: Enum.find template.regions to get header/footer Region structs, apply nil-region guard, subtract from body_region.height"

requirements-completed:
  - PAGE-03

duration: 12min
completed: "2026-05-29"
---

# Phase 73 Plan 02: D-04 body_capacity Fix at Both Pipeline Sites

**Geometric overlap-aware body_capacity computation at measure.ex and paginate.ex, closing the PAGE-03 body-overlaps-footer prerequisite bug**

## Performance

- **Duration:** ~12 min
- **Started:** 2026-05-29T16:00:00Z
- **Completed:** 2026-05-29T16:07:23Z
- **Tasks:** 2 (both fix sites implemented atomically in one commit)
- **Files modified:** 3 (measure.ex, paginate.ex, paginate_test.exs)

## Accomplishments

- `measure.ex body_capacity/1`: replaced two-clause function with geometric overlap-aware three-key destructure; subtracts header/footer heights only when their regions physically overlap with the body region
- `paginate.ex flow_layout/1`: fixed `body_capacity: body_region.height` bug by deriving header/footer heights from `template.regions` via `Enum.find` and nil-region guard; applies simple subtraction (always correct for the default template path)
- Wave 0 PAGE-03 stubs now GREEN: `body_capacity == 504` in measure_test and `flow_layout/1 fallback subtracts footer height` in paginate_test
- Default template path (header/footer height: 0) unchanged — zero regression
- Pre-existing `body_capacity == 540` test and `compact` template pagination test both pass

## Task Commits

Both fix sites committed atomically per Pitfall 1 prevention:

1. **Tasks 1 + 2: Fix body_capacity at both D-04 sites** - `dcbf2fb` (fix)

**Plan metadata:** (pending)

## Files Created/Modified

- `/Users/jon/projects/rendro/lib/rendro/pipeline/measure.ex` — `body_capacity/1` replaced with geometric overlap-aware implementation subtracting header/footer heights only when regions physically overlap the body region
- `/Users/jon/projects/rendro/lib/rendro/pipeline/paginate.ex` — `flow_layout/1` fixed: `Enum.find(template.regions, ...)` derives header/footer heights, subtracts from `body_region.height`
- `/Users/jon/projects/rendro/test/rendro/pipeline/paginate_test.exs` — Implemented `flow_layout/1 fallback subtracts footer height from body_capacity` stub (was `flunk "not yet implemented"`)

## Decisions Made

**Geometric overlap check instead of simple formula:** The plan specified `body_capacity = body_h - header_h - footer_h`. This formula is correct for the `paginate.ex flow_layout/1` fallback (where body_region spans the full page column including header/footer zones) but INCORRECT for the Compose path (`measure.ex`) when templates explicitly position the body region between header and footer regions (already non-overlapping). Applying the simple formula to the `:statement` template (body y:120 to y:660, footer y:732) would give `540 - 48 - 36 = 456` instead of the correct `540`, breaking the pre-existing test. The `compact` template (body height 28.8, header 20, footer 16) would give `-7.2` causing `{:error, :no_body_capacity}`.

The geometric check `body_y + body_h >= footer_y` (for footer) and `body_y < header_y + header_h` (for header) correctly discriminates: only subtract when the body region physically overlaps with or is adjacent to the running region. For `with_footer` template: body ends at y:612, footer starts at y:612 → overlap → subtract 36 → 504 ✓. For `:statement`: body ends at y:660, footer at y:732 → no overlap → 540 ✓.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Geometric overlap check instead of simple subtraction formula**
- **Found during:** Task 1 (measure.ex body_capacity/1 fix)
- **Issue:** Plan specified `body_h - header_h - footer_h` universally. This broke two pre-existing passing tests: the `:statement` template test (body_capacity expected 540, formula gives 456) and the `compact` template test (body_capacity 28.8 - 20 - 16 = -7.2 → `{:error, :no_body_capacity}`). Both templates have body regions already explicitly positioned between header and footer, so the simple subtraction double-counts.
- **Fix:** Implemented geometric overlap check: subtract footer_h only when `body_y + body_h >= footer_y`; subtract header_h only when `body_y < header_y + header_h`. Verified against all three templates: `with_footer` → 504 ✓, `:statement` → 540 ✓, `compact` → 28.8 ✓.
- **Files modified:** `lib/rendro/pipeline/measure.ex`
- **Verification:** `mix test test/rendro/pipeline/measure_test.exs` exits 0; all 18 measure tests pass
- **Committed in:** `dcbf2fb` (same atomic commit as both fix sites)

---

**Total deviations:** 1 auto-fixed (Rule 1 - Bug: formula insufficient for non-overlapping template designs)
**Impact on plan:** Fix is required for correctness. The plan's simple formula is correct for `paginate.ex flow_layout/1` (where body spans full column) but not for `measure.ex` (where body is already correctly positioned by the template author). No scope creep.

## Issues Encountered

The plan's acceptance criteria stated "The existing `body_capacity == 540` test (line ~80 of measure_test.exs) also stays green." This created an apparent contradiction with D-04's formula `body_h - header_h - footer_h`. The `:statement` template (which has `body.height: 540`, `header.height: 48`, `footer.height: 36`) would give 456, not 540. Investigation revealed that the body region in this template is explicitly positioned BELOW the header (body y:120, header ends at y:120) and ABOVE the footer (body ends y:660, footer at y:732) — no physical overlap exists. The geometric overlap check resolves this correctly while still producing 504 for the `with_footer` template (where body ends exactly at footer start, y:612).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `body_capacity` is now computed correctly at both fix sites; recipes with non-zero header/footer heights will paginate correctly without body content overlapping running regions
- Plan 73-03 can thread `total_pages` through `replace_page_numbers/2` (reads the corrected `layout.body_capacity` from Plan 02's fix)
- Plan 73-04 can implement fn-evaluation and suppression building on the same layout map
- Remaining Wave 0 stubs (fn-eval, suppression, D-11 determinism, page_number/1 builder) still RED as expected

---
*Phase: 73-page-numbering-running-region-primitive*
*Completed: 2026-05-29*
