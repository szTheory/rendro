---
phase: 85-deterministic-raster-lane
plan: "06"
subsystem: adapter
tags: [pdfium, raster, support-matrix, docs-contract, validator, security]

requires:
  - plan: 85-02
    provides: Pdfium.render/2 adapter implementation
  - plan: 85-03
    provides: raster evidence vocabulary and support matrix section

provides:
  - GUI-viewer row schema restricted to manual, pdfium-cli, and pdfjs-dist evidence kinds
  - Promotion-complete validator aligned with the GUI-viewer-only evidence vocabulary
  - Docs-contract mutation test proving pdfium-render is rejected on GUI-viewer rows
  - Pdfium.render/2 page-range validation before command execution
  - Numeric page ordering for rendered PNG collection
  - Fail-closed private temp PDF writes using exclusive file creation

affects:
  - 85-05 real raster snapshot evidence
  - 86-self-proving-launch-artifacts
  - support matrix truthfulness checks

tech-stack:
  added: []
  patterns:
    - "Engine-only raster evidence remains top-level support_matrix raster.evidence, not GUI-viewer viewer_row metadata."
    - "Pdfium.render/2 validates untrusted argv-shaped options before executable discovery or command execution."
    - "Rendered page files are ordered by parsed numeric page suffix instead of lexicographic path order."

key-files:
  created: []
  modified:
    - priv/schemas/support_matrix.schema.json
    - lib/rendro/viewer_evidence/validator.ex
    - test/docs_contract/raster_claims_test.exs
    - lib/rendro/adapters/pdfium.ex
    - test/rendro/adapters/pdfium_test.exs

key-decisions:
  - "pdfium-render is engine-only raster evidence and is not valid for GUI-viewer promotion rows."
  - "Invalid pages: values return {:error, {:invalid_option, :pages, \"must be a page range like \\\"1-3,5\\\"\"}} before the command runner can execute."
  - "Private raster input writes now rely on [:exclusive] without deleting an existing path first."

patterns-established:
  - "Mutate a real production support matrix row in docs-contract tests when proving structural guardrails."
  - "Sort pdfium output files by parsed page number when converting page_*.png files into returned binaries."

requirements-completed: [RAST-01, RAST-02, RAST-03]

metrics:
  duration: 9 min
  completed: 2026-06-11
---

# Phase 85 Plan 06: Raster Boundary and Adapter Hardening Summary

**GUI-viewer evidence vocabulary narrowed back to viewer-only values, with Pdfium.render/2 hardened against page-range injection, page-order drift, and contradictory private-file overwrites**

## Performance

- **Duration:** 9 min
- **Started:** 2026-06-11T15:01:07Z
- **Completed:** 2026-06-11T15:09:26Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments

- Removed `pdfium-render` from the shared GUI-viewer row schema enum and from `@viewer_kinds`, while preserving the top-level `raster.evidence.viewer_kind` value.
- Added a docs-contract mutation test that changes `forms.viewers.adobe_acrobat_reader.viewer_kind` to `pdfium-render` and proves both schema validation and promotion validation reject it.
- Hardened `Pdfium.render/2` by validating `pages:` against the planned page-range grammar before command execution.
- Changed PNG collection to sort `page_*.png` files by numeric suffix, so `page_10.png` is returned after `page_2.png`.
- Removed the `File.rm(path)` pre-delete from private temp PDF writes so `[:exclusive]` remains a real fail-closed guard.

## Task Commits

Each task was committed atomically:

1. **Task 1: Remove pdfium-render from GUI-viewer row schema and promotion validator** - `22e198d` (fix)
2. **Task 2: Add structural regression tests for the pdfium-render GUI-row boundary** - `8957e4b` (test)
3. **Task 3: Harden Pdfium.render/2 page ranges, page ordering, and private writes** - `e2ba854` (fix)

## Files Created/Modified

- `priv/schemas/support_matrix.schema.json` - Restricts `viewer_row.viewer_kind` to `manual`, `pdfium-cli`, and `pdfjs-dist`.
- `lib/rendro/viewer_evidence/validator.ex` - Aligns `@viewer_kinds` with GUI-viewer-only row values and documents the raster boundary.
- `test/docs_contract/raster_claims_test.exs` - Adds a real-row mutation test for the schema and promotion validator boundary.
- `lib/rendro/adapters/pdfium.ex` - Validates page ranges, sorts PNGs numerically, and keeps exclusive private writes fail-closed.
- `test/rendro/adapters/pdfium_test.exs` - Covers invalid page-range rejection without runner invocation and numeric page ordering.

## Decisions Made

- `pdfium-render` remains valid only in the top-level raster evidence object. It must not validate any `*.viewers.*` promotion row.
- The page-range grammar is intentionally strict: positive page numbers, optional ranges, comma-separated, no zero, whitespace, or flag-shaped values.
- Existing-file collisions in the private tmp dir are treated as anomalous and should fail through `File.write(..., [:exclusive])`, not be silently deleted.

## Deviations from Plan

None - plan executed exactly as written.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope change.

## Issues Encountered

None.

## Verification Results

All plan verification commands passed:

- `mix test test/docs_contract/raster_claims_test.exs test/docs_contract/viewer_evidence_claims_test.exs test/rendro/adapters/pdfium_test.exs` - 33 tests, 0 failures.
- `mix test` - 12 doctests, 4 properties, 1085 tests, 0 failures, 11 excluded.
- `grep -F '"enum": ["manual", "pdfium-cli", "pdfjs-dist"]' priv/schemas/support_matrix.schema.json` - matched.
- `grep -n '@viewer_kinds ~w(manual pdfium-cli pdfjs-dist)' lib/rendro/viewer_evidence/validator.ex` - matched.
- `grep -n '"viewer_kind": "pdfium-render"' priv/support_matrix.json` - matched top-level raster evidence.
- `grep -n "Enum.sort_by" lib/rendro/adapters/pdfium.ex` - matched.
- `grep -n "File.rm(path)" lib/rendro/adapters/pdfium.ex && exit 1 || exit 0` - confirmed absent.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 85-05 can now build the real raster snapshot lane against a hardened adapter path and a truthful evidence vocabulary boundary.

## Self-Check

Files exist:

- `priv/schemas/support_matrix.schema.json` - FOUND
- `lib/rendro/viewer_evidence/validator.ex` - FOUND
- `test/docs_contract/raster_claims_test.exs` - FOUND
- `lib/rendro/adapters/pdfium.ex` - FOUND
- `test/rendro/adapters/pdfium_test.exs` - FOUND

Commits exist:

- `22e198d` - Task 1
- `8957e4b` - Task 2
- `e2ba854` - Task 3

## Self-Check: PASSED

---
*Phase: 85-deterministic-raster-lane*
*Completed: 2026-06-11*
