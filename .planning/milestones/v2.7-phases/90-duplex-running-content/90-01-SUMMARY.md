---
phase: 90-duplex-running-content
plan: 01
subsystem: pagination
tags: [elixir, pagination, running-content, duplex, public-api]

requires:
  - phase: 89-page-context-primitive
    provides: section-local page context and PAGE token substitution
provides:
  - Physical odd/even running-region filtering via `Rendro.section(only_on: :odd | :even)`
  - Compose-time validation for malformed `only_on` and `page_numbering`
  - Per-entry running-region metadata that preserves legacy header/footer behavior
affects: [page-context, pdfjs-advisory-proof-lane, docs-claims-release-hygiene]

tech-stack:
  added: []
  patterns:
    - Per-section running-region metadata is re-paired with measured region blocks by block count.
    - Running-region filters run before callbacks and PAGE token replacement.

key-files:
  created:
    - .planning/phases/90-duplex-running-content/90-01-SUMMARY.md
  modified:
    - lib/rendro/section.ex
    - lib/rendro/pipeline/compose.ex
    - lib/rendro/pipeline/paginate.ex
    - test/rendro_builders_test.exs
    - test/rendro/pipeline/compose_test.exs
    - test/rendro/pipeline/paginate_test.exs
    - test/rendro/flow_test.exs
    - priv/public_api.json
    - .planning/REQUIREMENTS.md

key-decisions:
  - "only_on is intentionally limited to nil, :odd, and :even."
  - "only_on parity is physical page parity, not section-local parity."
  - "Compose raises ArgumentError for malformed section options to match existing suppress_on validation behavior."

patterns-established:
  - "Per-entry running-region filters: suppress_on and only_on live on normalized entries, not only region-wide maps."
  - "Measured running entries: pagination re-pairs region_entries with measured region_blocks by original block count."

requirements-completed: [DUP-01, DUP-02, DUP-03]

duration: 5min
completed: 2026-06-13
---

# Phase 90: Duplex Running Content Summary

**Physical odd/even running content with section-local PAGE tokens and compose-time option validation**

## Performance

- **Duration:** ~5 min implementation after planning
- **Started:** 2026-06-13T02:41:55Z
- **Completed:** 2026-06-13T02:46:47Z
- **Tasks:** 3
- **Files modified:** 10

## Accomplishments

- Added `Rendro.Section.only_on/0` and `%Rendro.Section{only_on: nil}` for `Rendro.section(only_on: :odd | :even)`.
- Added Compose validation for invalid `only_on` and `page_numbering`, before rendering can produce misleading output.
- Preserved per-section running-region metadata so odd and even footers targeting the same region can coexist.
- Updated Paginate to evaluate `only_on` against physical page parity before `RunningContent` callback evaluation and PAGE token replacement.
- Added regression coverage for combined odd/even duplex content with section-local tokens after a page-numbering restart.
- Regenerated `priv/public_api.json` so `Rendro.Section.only_on/0` is part of the public API manifest.

## Task Commits

1. **Task 1: Add Section.only_on and compose-time validation** - `5f79814`
2. **Task 2: Apply physical parity filters per running-region entry** - `59d292c`
3. **Task 3: Regenerate API manifest, verify, and summarize** - `ec44a8f`

**Plan metadata:** `2996063`

## Files Created/Modified

- `lib/rendro/section.ex` - Added `only_on` field and type.
- `lib/rendro/pipeline/compose.ex` - Added section option validation and `region_entries` metadata.
- `lib/rendro/pipeline/paginate.ex` - Added per-entry running-region filtering by physical parity.
- `test/rendro_builders_test.exs` - Covered `Rendro.section(only_on: :odd)`.
- `test/rendro/pipeline/compose_test.exs` - Covered entry metadata and invalid option errors.
- `test/rendro/pipeline/paginate_test.exs` - Covered odd/even footers, suppression composition, and section-token parity after restart.
- `test/rendro/flow_test.exs` - Covered render-level odd/even footer behavior.
- `priv/public_api.json` - Regenerated public API manifest with `only_on/0`.

## Decisions Made

- Kept `Rendro.section/1` as a thin `struct!` builder and put value validation in Compose so manually built structs are covered too.
- Kept the existing conflicting `suppress_on` region rule for backward compatibility while using per-entry `only_on` for duplex variants.
- Kept recto/verso, blank-page insertion, and public `Rendro.PageContext` out of scope.

## Deviations from Plan

None - the plan executed as written. The formatter adjusted one compose test after full-suite verification; focused tests were rerun after formatting.

## Issues Encountered

- `mix format --check-formatted` initially failed on one long test struct literal in `test/rendro/pipeline/compose_test.exs`. Running `mix format` fixed it, and `mix format --check-formatted` then passed.
- Existing suite noise remains: stale Apple Preview evidence warning, adapter module redefinition warnings in docs/public API tests, and telemetry local function notices. These did not fail tests.

## Verification

- `mix test test/rendro_builders_test.exs test/rendro/pipeline/compose_test.exs` -> 50 tests, 0 failures
- `mix test test/rendro/pipeline/paginate_test.exs test/rendro/flow_test.exs` -> 50 tests, 0 failures
- `mix test test/rendro_builders_test.exs test/rendro/pipeline/compose_test.exs test/rendro/pipeline/paginate_test.exs test/rendro/flow_test.exs` -> 100 tests, 0 failures
- `mix test test/rendro/public_api/manifest_test.exs test/docs_contract/public_api_contract_test.exs` -> 14 tests, 0 failures
- `mix test` -> 12 doctests, 4 properties, 1171 tests, 0 failures (11 excluded)
- `mix format --check-formatted` -> passed

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 91 can add the pinned PDF.js advisory proof lane without touching the new core duplex API. Phase 92 can document page context and duplex running content with exact tested scope: physical odd/even running headers/footers, not recto/verso, blank-page insertion, TOC, outlines, or global text shaping.

## Self-Check: PASSED

- DUP-01: passed through odd/even footer tests and rendered PDF regression.
- DUP-02: passed through combined odd/even plus section-local token test after restart.
- DUP-03: passed through Compose validation tests for invalid `only_on` and `page_numbering`.

---
*Phase: 90-duplex-running-content*
*Completed: 2026-06-13*
