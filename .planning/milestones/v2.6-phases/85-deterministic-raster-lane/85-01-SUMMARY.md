---
phase: 85-deterministic-raster-lane
plan: "01"
subsystem: testing
tags: [elixir, exunit, pdfium, raster, snapshot-testing, docs-contract]

requires:
  - phase: 84-drawn-path-primitive-visible-polish
    provides: completed Phase 84 for correct context; Phase 85 is parallel to 83/84

provides:
  - ExUnit raster_snapshot tag registered in test_helper.exs (excluded from default mix test)
  - pdfium_raster_snapshot_test.exs with bless-guard unit test (RAST-02b) and tag-excluded hash-equality fast-path stub
  - pdfium_test.exs extended with @tag :skip render/2 missing-executable stub (T-85-01; un-skip in Plan 02)
  - raster_claims_test.exs with 6 docs-contract assertions (3 passing in Wave 0, 3 @tag :skip RED stubs for Plan 03)
  - priv/pdfium_pin.json with v0.11.0 version and verified sha256 hash
  - priv/raster_refs/.gitkeep establishing the git-tracked hash ref store directory

affects:
  - 85-02 (render/2 implementation — un-skip T-85-01 test, fill in stub)
  - 85-03 (schema sync — un-skip RED raster_claims tests, add raster section to support_matrix.json)
  - 86-self-proving-launch-artifacts (depends on raster lane being complete)

tech-stack:
  added: []
  patterns:
    - "raster_snapshot ExUnit tag exclusion (excluded by default in test_helper.exs, included with --include raster_snapshot)"
    - "bless-guard: MIX_RASTER_BLESS=true raises unless GITHUB_ACTIONS=true (prevents laptop-local hash generation)"
    - "@tag :skip RED stubs: test stubs compile but do not execute until implementation lands in later plan"
    - "docs-contract stub pattern with @tag :skip on RED assertions (Wave 0 Nyquist discipline)"

key-files:
  created:
    - test/rendro/adapters/pdfium_raster_snapshot_test.exs
    - test/docs_contract/raster_claims_test.exs
    - priv/pdfium_pin.json
    - priv/raster_refs/.gitkeep
  modified:
    - test/test_helper.exs
    - test/rendro/adapters/pdfium_test.exs

key-decisions:
  - "Used @tag :skip (not @tag :pending) for RED Wave 0 tests — :pending is not configured in test_helper.exs exclude list; :skip is the built-in ExUnit mechanism"
  - "Added @tag :skip to 3 raster_claims tests that cannot pass until Plan 03 implements support_matrix.json raster section, guardrails advisory entry, and verify_docs.exs lane registration — ensures mix test exits 0 as required"
  - "pdfium_pin.json uses v0.11.0 with the verified sha256 b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a (RESEARCH.md VERIFIED, downloaded and sha256sum computed 2026-06-10)"

patterns-established:
  - "Pattern: Wave 0 Nyquist test scaffolding — all test stubs exist before any implementation; RED stubs compile and are @tag :skip so mix test exits 0"
  - "Pattern: raster_snapshot ExUnit tag for live pdfium-cli tests excluded from default mix test"

requirements-completed:
  - RAST-01
  - RAST-02
  - RAST-03

duration: 4min
completed: 2026-06-11
---

# Phase 85 Plan 01: Wave 0 Snapshot Harness Summary

**Wave 0 test scaffolding: raster_snapshot tag registered, bless-guard unit test, pdfium pin file with v0.11.0 sha256, and 6-assertion docs-contract stub (3 passing, 3 RED @tag :skip for Plan 03)**

## Performance

- **Duration:** 4 min
- **Started:** 2026-06-11T00:05:53Z
- **Completed:** 2026-06-11T00:09:28Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Registered `raster_snapshot: true` in ExUnit exclude list so `mix test` never attempts pdfium-cli invocation
- Created `pdfium_raster_snapshot_test.exs` with bless-guard unit test covering RAST-02b (raises outside GITHUB_ACTIONS) and hash-equality fast-path stub tagged `@tag raster_snapshot: true`
- Created `raster_claims_test.exs` with 6 docs-contract assertions: pin file test and GUI-viewer boundary test pass immediately; 3 RED stubs (support matrix raster section, advisory_contexts entry, verify_docs lane) are `@tag :skip` pending Plan 03
- Seeded `priv/pdfium_pin.json` with the verified v0.11.0 sha256 hash from RESEARCH.md
- Established `priv/raster_refs/` as a git-tracked directory via `.gitkeep`

## Task Commits

Each task was committed atomically:

1. **Task 1: Extend pdfium_test.exs + create pdfium_raster_snapshot_test.exs** - `af40349` (test)
2. **Task 2: Create raster_claims_test.exs stubs + priv/pdfium_pin.json** - `c266461` (test)

## Files Created/Modified

- `test/test_helper.exs` - Added `raster_snapshot: true` to ExUnit.configure exclude list
- `test/rendro/adapters/pdfium_test.exs` - Added `@tag :skip` render/2 missing-executable stub (T-85-01)
- `test/rendro/adapters/pdfium_raster_snapshot_test.exs` - New: bless-guard unit test + @tag raster_snapshot hash-equality fast-path stub + private helpers (assert_golden_hashes/2, bless_refs/2, assert_or_bless/2)
- `priv/raster_refs/.gitkeep` - New: git-tracked placeholder for future hash refs
- `priv/pdfium_pin.json` - New: v0.11.0 pdfium-webassembly-linux-amd64 pin with verified sha256
- `test/docs_contract/raster_claims_test.exs` - New: 6-assertion docs-contract stubs (3 passing, 3 @tag :skip RED state)

## Decisions Made

- **@tag :skip for RED stubs (not @tag :pending):** The `:pending` tag is not in the test_helper.exs exclude list, so `@tag :pending` does not prevent test execution. Used `@tag :skip` (built-in ExUnit mechanism) to ensure `mix test` exits 0 while preserving the RED stubs that Plan 03 will un-skip.
- **6 docs-contract tests with inline Wave state comments:** Each test has a clear comment indicating whether it passes in Plan 01 or which plan implements the backing artifact.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Switched @tag :pending to @tag :skip for RED test stubs**
- **Found during:** Task 2 (raster_claims_test.exs creation)
- **Issue:** The plan specified `@tag :pending` to gate RED Wave 0 tests, but `:pending` is not configured in the ExUnit exclude list in `test_helper.exs` — `mix test` ran the tests and produced 3 failures, failing the success criterion of `mix test` exits 0
- **Fix:** Used `@tag :skip` instead (built-in ExUnit mechanism that always excludes), matching the same pattern used for the render/2 stub in `pdfium_test.exs`
- **Files modified:** test/docs_contract/raster_claims_test.exs
- **Verification:** `mix test` exits 0 with 0 failures (4 skipped, 11 excluded)
- **Committed in:** c266461 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 3 — blocking: wrong tag mechanism prevented mix test from passing)
**Impact on plan:** Single-line fix per test; no scope change. All Wave 0 success criteria satisfied.

## Issues Encountered

None beyond the @tag :pending vs @tag :skip deviation documented above.

## Known Stubs

The following stubs are intentional Wave 0 placeholders — they will be un-skipped in the specified later plans:

| File | Stub | Plan to un-skip |
|------|------|-----------------|
| `test/rendro/adapters/pdfium_test.exs:22` | `@tag :skip render/2 missing-executable test` | Plan 02 (after render/2 implemented) |
| `test/docs_contract/raster_claims_test.exs:5` | `@tag :skip "support matrix has raster section"` | Plan 03 (after support_matrix.json raster section added) |
| `test/docs_contract/raster_claims_test.exs:35` | `@tag :skip "advisory lane is in advisory_contexts"` | Plan 03 (after guardrails JSON updated) |
| `test/docs_contract/raster_claims_test.exs:50` | `@tag :skip "docs verification script includes raster claims lane"` | Plan 03 (after verify_docs.exs updated) |

These stubs exist so that `mix test` exits 0 in Wave 0 while all test infrastructure is in place before implementation.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries introduced in this plan. The files are test infrastructure and a config file.

## Next Phase Readiness

- Plan 02 can proceed: `pdfium_raster_snapshot_test.exs` stub tests exist; `pdfium_test.exs` has the @tag :skip render/2 test ready to un-skip after `Rendro.Adapters.Pdfium.render/2` is implemented
- Plan 03 can proceed: `raster_claims_test.exs` has the 3 @tag :skip RED stubs ready to un-skip after `support_matrix.json`, `required_status_checks.json`, and `scripts/verify_docs.exs` are updated

---
*Phase: 85-deterministic-raster-lane*
*Completed: 2026-06-11*
