---
phase: 85-deterministic-raster-lane
plan: "05"
subsystem: testing
tags: [raster, pdfium, golden-snapshot, docs-contract, support-matrix]

requires:
  - plan: 85-02
    provides: Pdfium.render/2 adapter implementation
  - plan: 85-04
    provides: raster-advisory CI lane wiring
  - plan: 85-06
    provides: hardened Pdfium.render/2 adapter and corrected pdfium-render evidence boundary

provides:
  - Render-backed raster snapshot test for test/fixtures/forms_support_fixture.pdf
  - Committed SHA-256 PNG reference for forms_support_fixture page 1
  - Support matrix raster evidence bound to the committed PNG hash
  - Docs-contract test requiring raster evidence hash/file consistency
  - Empty-PNG safeguards in golden compare and bless helper paths

affects:
  - 86-self-proving-launch-artifacts
  - launch artifact gallery raster generation
  - advisory raster CI evidence

tech-stack:
  added: []
  patterns:
    - "Raster snapshot tests render real fixture PDF bytes through Pdfium.render/2 and compare committed SHA-256 refs."
    - "Blessing remains CI-gated through MIX_RASTER_BLESS=true plus GITHUB_ACTIONS=true."
    - "Support matrix raster evidence stores fixture, ref, and png_sha256 fields that are checked by docs-contract tests."

key-files:
  created:
    - priv/raster_refs/forms_support_fixture/page_1.sha256
  modified:
    - test/rendro/adapters/pdfium_raster_snapshot_test.exs
    - priv/support_matrix.json
    - test/docs_contract/raster_claims_test.exs

key-decisions:
  - "The forms support fixture is the first committed raster golden reference for the advisory lane."
  - "Missing raster ref files now fail the included raster snapshot test instead of causing a skip."
  - "The support matrix byte_deterministic_on_pinned_container claim is backed by an executable hash assertion."

patterns-established:
  - "Golden PNG refs live under priv/raster_refs/<fixture>/page_<n>.sha256."
  - "Raster evidence matrix values must equal the trimmed committed ref file contents."

requirements-completed: [RAST-02, RAST-03]

metrics:
  duration: 8 min
  completed: 2026-06-11
---

# Phase 85 Plan 05: Render-Backed Raster Snapshot Summary

**Real Pdfium.render/2 snapshot lane for `forms_support_fixture.pdf`, with a committed pinned-container SHA-256 ref and support-matrix evidence bound to that exact hash**

## Performance

- **Duration:** 8 min
- **Started:** 2026-06-11T15:10:30Z
- **Completed:** 2026-06-11T15:18:22Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Replaced the hollow `@tag raster_snapshot` branch with a real test that reads `test/fixtures/forms_support_fixture.pdf`, calls `Pdfium.render(pdf, dpi: 150, pages: "1")`, verifies one PNG, and routes that PNG through `assert_or_bless/2`.
- Strengthened `assert_golden_hashes/2` and `bless_refs/2` so empty PNG lists fail with explicit messages instead of passing through zero iterations.
- Fixed the bless-guard test to restore prior `MIX_RASTER_BLESS` and `GITHUB_ACTIONS` values.
- Generated and committed `priv/raster_refs/forms_support_fixture/page_1.sha256` with digest `73e33ed6c6d68e461b4317f0551f9ae8f8225b28cf7e0eebcf88fa45d09b8deb`.
- Added `fixture`, `ref`, and `png_sha256` fields to top-level `raster.evidence` in `priv/support_matrix.json`.
- Added a docs-contract test proving the support matrix points at the committed ref and stores the exact trimmed hash.

## Task Commits

Each task was committed atomically:

1. **Task 1: Replace the hollow snapshot test with a real render-backed assertion** - `f88a2ef` (test)
2. **Task 2: Generate and commit the pinned-container golden hash ref** - `7fad151` (test)
3. **Task 3: Bind raster matrix evidence to the committed PNG hash** - `5366a62` (test)

## Files Created/Modified

- `test/rendro/adapters/pdfium_raster_snapshot_test.exs` - Renders the forms fixture through `Pdfium.render/2`, compares/blesses real PNG output, fails on empty PNG lists, and restores env vars.
- `priv/raster_refs/forms_support_fixture/page_1.sha256` - Committed lowercase SHA-256 ref for the rendered page 1 PNG.
- `priv/support_matrix.json` - Adds raster evidence `fixture`, `ref`, and `png_sha256` fields.
- `test/docs_contract/raster_claims_test.exs` - Adds the matrix/ref hash consistency assertion.

## Decisions Made

- The first golden snapshot uses the existing `test/fixtures/forms_support_fixture.pdf` fixture and page range `"1"` at 150 DPI.
- Missing refs are treated as failures in non-bless mode. This is intentional: the advisory lane must fail on evidence drift or missing evidence rather than skip.
- The matrix claim remains top-level raster evidence. No GUI-viewer row receives `viewer_kind: "pdfium-render"`.

## Deviations from Plan

None - plan scope and artifacts match the plan.

**Total deviations:** 0 auto-fixed.
**Impact on plan:** No scope change.

## Issues Encountered

- A full linux/amd64 Elixir container bless run installed and SHA-verified `pdfium-cli v0.11.0`, but the BEAM test process segfaulted during dependency compilation under Docker Desktop emulation.
- Recovery path: ran the actual ExUnit snapshot test on the host BEAM with a temporary `pdfium-cli` shim first in `PATH`. The shim invoked the SHA-verified linux/amd64 `pdfium-cli v0.11.0` binary inside Docker for the render command. The generated PNG bytes therefore came from the pinned Linux pdfium binary, and `Pdfium.render/2` was still the code path that produced the ref.
- An initial verification batch ran the positive raster lane and missing-ref negative check concurrently. That created an artificial race because the negative check temporarily moved the ref while the positive check was reading it. All verification commands were rerun sequentially and passed.

## Verification Results

All plan verification commands passed after sequential rerun:

- `mix test test/rendro/adapters/pdfium_raster_snapshot_test.exs` - 1 test, 0 failures, 1 excluded.
- `PATH="/tmp/rendro-pdfium-shim:$PATH" GITHUB_ACTIONS=true MIX_RASTER_BLESS=true mix test --include raster_snapshot test/rendro/adapters/pdfium_raster_snapshot_test.exs` - 2 tests, 0 failures; generated the committed ref.
- `grep -Eq '^[0-9a-f]{64}$' priv/raster_refs/forms_support_fixture/page_1.sha256` - matched.
- `PATH="/tmp/rendro-pdfium-shim:$PATH" MIX_RASTER_BLESS=false mix test --include raster_snapshot test/rendro/adapters/pdfium_raster_snapshot_test.exs` - 2 tests, 0 failures.
- Missing-ref negative check: temporarily moved `page_1.sha256`; non-bless raster snapshot failed with `File.Error`, then the ref was restored.
- `mix test test/docs_contract/raster_claims_test.exs` - 8 tests, 0 failures.
- `mix run -e 'File.read!("priv/support_matrix.json") |> JSON.decode!()'` - parsed successfully.
- `mix test` - 12 doctests, 4 properties, 1086 tests, 0 failures, 11 excluded.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 85 now has all six plan summaries on disk. The raster lane can be re-verified at phase level with the advisory snapshot evidence, schema boundary, and support matrix hash contract in place.

## Self-Check

Files exist:

- `test/rendro/adapters/pdfium_raster_snapshot_test.exs` - FOUND
- `priv/raster_refs/forms_support_fixture/page_1.sha256` - FOUND
- `priv/support_matrix.json` - FOUND
- `test/docs_contract/raster_claims_test.exs` - FOUND

Commits exist:

- `f88a2ef` - Task 1
- `7fad151` - Task 2
- `5366a62` - Task 3

## Self-Check: PASSED

---
*Phase: 85-deterministic-raster-lane*
*Completed: 2026-06-11*
