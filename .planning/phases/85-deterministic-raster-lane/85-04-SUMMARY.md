---
phase: 85-deterministic-raster-lane
plan: "04"
subsystem: ci
tags: [ci, github-actions, guardrails, docs-contract, raster, advisory-lane, pdfium]

requires:
  - plan: 85-02
    provides: render/2 implementation (pdfium adapter)
  - plan: 85-03
    provides: raster section in support_matrix.json, tests 1 and 5 green

provides:
  - raster-advisory GitHub Actions job (graph-disconnected, continue-on-error: true, pdfium-cli v0.11.0 sha256-pinned)
  - raster-advisory in advisory_contexts (NOT required_contexts) in priv/guardrails/required_status_checks.json
  - Raster claims lane entry in scripts/verify_docs.exs (15 total lanes)
  - All 6 raster_claims_test.exs tests green (RAST-01c, RAST-03a, RAST-03b, RAST-03c, RAST-03d, verify_docs registration)
  - Phase 85 complete — all RAST-01..03 requirements satisfied

affects:
  - 86-self-proving-launch-artifacts (Phase 85 dependency unblocked)
  - All 4 required engine lanes verified isolated from raster-advisory failures

tech-stack:
  added: []
  patterns:
    - "Advisory CI job pattern: no needs:, continue-on-error: true, advisory_contexts only (not required_contexts)"
    - "sha256sum --check for binary download verification in CI (T-85-07 supply chain mitigation)"
    - "Advisory lane registration pattern: ci.yml job + advisory_contexts entry + verify_docs.exs lane entry + docs-contract test un-skip"

key-files:
  created: []
  modified:
    - .github/workflows/ci.yml
    - priv/guardrails/required_status_checks.json
    - scripts/verify_docs.exs
    - test/docs_contract/raster_claims_test.exs
    - test/guardrails/required_checks_contract_test.exs

key-decisions:
  - "raster-advisory is advisory-only: not in required_contexts, graph-disconnected, continue-on-error:true — download failure cannot block engine merges (RAST-02)"
  - "pdfium-cli v0.11.0 pinned with SHA256 b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a — T-85-07 supply chain mitigation"
  - "Lane count bumped 14->15 in required_checks_contract_test.exs as a Rule 1 auto-fix (the count guard must track all registered lanes)"

metrics:
  duration: 3min
  completed: 2026-06-11
---

# Phase 85 Plan 04: Advisory CI Lane & Docs-Contract Closure Summary

**raster-advisory CI job added (graph-disconnected, sha256-pinned pdfium-cli v0.11.0, advisory_contexts only); all 6 raster_claims_test.exs tests green; mix test exits 0 (1082 tests, 0 failures)**

## Performance

- **Duration:** 3 min
- **Started:** 2026-06-11T00:22:09Z
- **Completed:** 2026-06-11T00:25:XX Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Added `raster-advisory` job to `.github/workflows/ci.yml` between `example-phoenix` and `viewer-evidence-live-proof`:
  - `continue-on-error: true` (prevents download failures from creating red CI signal for contributors)
  - No `needs:` key (graph-disconnected — cannot block required engine lanes)
  - `Install pdfium-cli (pinned)` step with SHA256 verification (`sha256sum --check`)
  - `Mix Raster Bless: false` env variable; runs `mix test --include raster_snapshot`
- Appended `raster-advisory` entry to `advisory_contexts` in `priv/guardrails/required_status_checks.json` (not in `required_contexts`)
- Added `{"Raster claims lane", ["test", "test/docs_contract/raster_claims_test.exs"]}` to `scripts/verify_docs.exs` lane list (now 15 lanes total)
- Un-skipped tests 4 and 6 in `test/docs_contract/raster_claims_test.exs` — all 6 tests now green
- Updated `required_checks_contract_test.exs` lane count assertion: 14 → 15 (Rule 1 auto-fix)

## Task Commits

Each task was committed atomically:

1. **Task 1: Add raster-advisory job to ci.yml** - `47d0405` (feat)
2. **Task 2: Register raster-advisory in guardrails + add Raster claims lane** - `a396a95` (feat)

## Files Created/Modified

- `.github/workflows/ci.yml` — Added `raster-advisory` job (31 lines, between example-phoenix and viewer-evidence-live-proof)
- `priv/guardrails/required_status_checks.json` — Appended raster-advisory entry to advisory_contexts (9 lines)
- `scripts/verify_docs.exs` — Added Raster claims lane entry (now 15 lanes total)
- `test/docs_contract/raster_claims_test.exs` — Removed @tag :skip from tests 4 and 6; updated comments
- `test/guardrails/required_checks_contract_test.exs` — Updated lane count assertion 14 → 15; updated test description

## Decisions Made

- **Advisory-only registration:** raster-advisory is in `advisory_contexts` exclusively — RAST-02 requires that pdfium download failures never block the four required engine lanes (`test`, `signing-live-proof`, `release-proof`, `long-lived-live-proof`).
- **pdfium-cli v0.11.0 vs v0.10.3:** The viewer-evidence-live-proof job retains v0.10.3 (unchanged); raster-advisory uses v0.11.0 from `priv/pdfium_pin.json`. Intentionally separate versions in separate jobs.
- **Lane count bump as Rule 1 fix:** The `required_checks_contract_test.exs` lane count guard (14 == 14) failed when the 15th lane was added. Updated count to 15 and description to name the raster claims lane.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] required_checks_contract_test.exs lane count assertion failed**
- **Found during:** Task 2 verification (`mix test` full suite)
- **Issue:** `test/guardrails/required_checks_contract_test.exs` asserted `length(lane_entries) == 14`. Adding the Raster claims lane (the 15th entry) caused this guardrail test to fail with `left: 15, right: 14`.
- **Fix:** Updated the count assertion to `== 15` and updated the test description to name the raster claims lane.
- **Files modified:** test/guardrails/required_checks_contract_test.exs
- **Commit:** a396a95

## Verification Results

All plan verification commands passed:

- `mix test test/docs_contract/raster_claims_test.exs` — 6 tests, 0 failures
- `mix test` (full suite) — 1082 tests, 0 failures (11 excluded: live/raster_snapshot)
- `python3 yaml.safe_load(ci.yml)` — OK
- `python3 guardrails JSON check` — raster-advisory in advisory_contexts, absent from required_contexts — OK
- `grep "Raster claims lane" scripts/verify_docs.exs` — 1 match
- `continue-on-error: true` present in ci.yml raster-advisory job
- No `needs:` key under raster-advisory (only in comment)
- SHA256 `b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a` present in install step

## Known Stubs

None. All 6 `raster_claims_test.exs` tests are active and green. The `pdfium_raster_snapshot_test.exs` snapshot tests remain `@tag :skip` with `@tag :raster_snapshot` (excluded from normal `mix test`; they run only in the raster-advisory CI job).

## Threat Surface Scan

No new network endpoints, auth paths, or file access patterns introduced beyond what the plan specified. Supply chain mitigations:
- T-85-07: `sha256sum --check` in the pdfium-cli install step (WASM binary, sandboxed)
- T-85-11: `continue-on-error: true` + no `needs:` + NOT in `required_contexts` (DoS isolation)
- T-85-12: `raster_claims_test.exs` test 3 asserts "raster-advisory" not in `required_contexts` on every `mix test` run

## Phase 85 Completion

All four plans complete. Phase 85 success criteria satisfied:

1. `raster-advisory` CI job: graph-disconnected, `continue-on-error: true`, pdfium-cli v0.11.0 sha256-pinned — DONE
2. `raster-advisory` in `advisory_contexts`, absent from `required_contexts` — DONE
3. All 6 `raster_claims_test.exs` tests pass — DONE
4. `mix test` (full suite) exits 0 — DONE
5. RAST-01 (render/2), RAST-02 (advisory isolation), RAST-03 (guardrails verified by docs-contract) all satisfied — DONE

## Self-Check

Files exist:
- `.github/workflows/ci.yml` — FOUND (modified)
- `priv/guardrails/required_status_checks.json` — FOUND (modified)
- `scripts/verify_docs.exs` — FOUND (modified)
- `test/docs_contract/raster_claims_test.exs` — FOUND (modified)
- `test/guardrails/required_checks_contract_test.exs` — FOUND (modified)

Commits exist:
- `47d0405` — Task 1 (ci.yml)
- `a396a95` — Task 2 (guardrails + verify_docs + test un-skip)

## Self-Check: PASSED

---
*Phase: 85-deterministic-raster-lane*
*Completed: 2026-06-11*
