---
phase: 19-deterministic-text-flow-and-break-semantics
plan: 03
subsystem: docs
tags: [elixir, pdf, text-flow, rendering, docs-contract, pagination]
requires:
  - phase: 19
    provides: deterministic wrapped-text measurement and keep/break pagination from plans 01 and 02
provides:
  - measured wrapped lines serialized as explicit PDF text operations
  - public render proofs for wrapped flow text and break directives
  - truthful README and integration guidance for Phase 19 semantics and exclusions
affects: [phase-19, phase-20, phase-22, rendering-contract, docs-contract]
tech-stack:
  added: []
  patterns: [measured-line PDF serialization, measured-text placeholder replacement, truthful docs boundaries]
key-files:
  created: []
  modified:
    - lib/rendro/pdf/writer.ex
    - lib/rendro/pipeline/paginate.ex
    - test/rendro/pdf/writer_test.exs
    - test/rendro/flow_test.exs
    - README.md
    - guides/integrations.md
    - test/docs_contract/readme_doctest_test.exs
key-decisions:
  - "Rendered PDF text now serializes the measured line list directly instead of reconstructing paragraphs inside the writer."
  - "README examples teach the Phase 19 block-and-text flow path with explicit break semantics and narrow exclusions."
patterns-established:
  - "Measured flow text emits one `Tj` per upstream line with deterministic line offsets."
  - "Page-number placeholder replacement must update measured-text carriers as well as raw text blocks."
requirements-completed: [LAY-06, LAY-09]
duration: 6 min
completed: 2026-04-29
---

# Phase 19 Plan 03: Wrapped Render Truth and Public Semantics Summary

**Measured wrapped flow text now renders as explicit per-line PDF operations, with public examples and docs that describe Phase 19 keep/break semantics without overstating paragraph support.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-04-29T19:45:10Z
- **Completed:** 2026-04-29T19:50:53Z
- **Tasks:** 2
- **Files modified:** 7

## Accomplishments

- Taught `Rendro.PDF.Writer` to serialize `%Rendro.Pipeline.MeasuredText{}` line-by-line using deterministic vertical offsets instead of collapsing back to the original paragraph string.
- Added writer and flow-level regression coverage proving wrapped flow text renders as multiple `Tj` operations and keeps page counts stable across identical deterministic renders.
- Rewrote the README flow guidance around `Rendro.flow/2`, `Rendro.block/2`, `Rendro.text/2`, and page templates/regions, while documenting break semantics and explicit Phase 19 exclusions.

## Task Commits

Each task was committed atomically:

1. **Task 1: Serialize measured wrapped lines explicitly in the PDF writer** - `4224f83` (feat)
2. **Task 2: Publish truthful Phase 19 examples and boundaries** - `67a6ccd` (docs)

## Files Created/Modified

- `lib/rendro/pdf/writer.ex` - renders measured wrapped lines as separate PDF text operations with deterministic offsets.
- `lib/rendro/pipeline/paginate.ex` - preserves page-number placeholder replacement for measured header/footer blocks.
- `test/rendro/pdf/writer_test.exs` - proves a wrapped measured block emits multiple `Tj` operations.
- `test/rendro/flow_test.exs` - proves wrapped flow rendering and measured header/footer behavior through the public render path.
- `README.md` - documents width-constrained flow authoring, break directives, long-token fallback, and Phase 19 exclusions.
- `guides/integrations.md` - frames keep/break semantics as core-library behavior rather than adapter behavior.
- `test/docs_contract/readme_doctest_test.exs` - keeps the README docs-contract fence list aligned with the new compile-backed examples.

## Decisions Made

- The writer consumes the measured line payload directly so render output cannot diverge from measurement-time wrapping decisions.
- Public examples stay on the existing builder API and page-template surface rather than introducing any paragraph DSL or adapter-specific semantics.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Restored page-number replacement for measured header/footer text**
- **Found during:** Task 1 (Serialize measured wrapped lines explicitly in the PDF writer)
- **Issue:** `replace_page_numbers/2` only handled `%Rendro.Text{}` blocks, so once measured headers and footers were stored as `%Rendro.Pipeline.MeasuredText{}` the placeholder substitution stopped applying.
- **Fix:** Updated `Paginate` to replace page numbers inside both the measured source text and the stored wrapped line list.
- **Files modified:** `lib/rendro/pipeline/paginate.ex`, `test/rendro/flow_test.exs`
- **Verification:** `mix test test/rendro/pdf/writer_test.exs test/rendro/flow_test.exs`
- **Committed in:** `4224f83`

---

**Total deviations:** 1 auto-fixed (1 Rule 1 bug)
**Impact on plan:** The fix was required to keep the existing measured-text path truthful. No scope expansion beyond Phase 19 rendering correctness.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `LAY-06` is now evidenced through measured render output, public flow tests, and README examples.
- Phase 20 can build richer table behavior on top of a render path that now honors the exact measured wrapped lines.
- Phase 22 can lift these semantics into broader recipes without reopening Phase 19’s scope boundary.

## Self-Check: PASSED

- Found `.planning/phases/19-deterministic-text-flow-and-break-semantics/19-03-SUMMARY.md`
- Found commit `4224f83`
- Found commit `67a6ccd`
