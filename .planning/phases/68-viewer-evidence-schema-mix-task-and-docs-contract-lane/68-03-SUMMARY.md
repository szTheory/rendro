---
phase: 68-viewer-evidence-schema-mix-task-and-docs-contract-lane
plan: 03
subsystem: testing
tags: [docs-contract, viewer-evidence, jsv, exunit]

requires:
  - phase: 68-01
    provides: JSON schemas and Matrix walker
  - phase: 68-02
    provides: Validator, Mix task, tier-B fixtures
provides:
  - Eighth docs-contract lane (viewer_evidence_claims_test.exs)
  - verify_docs.exs registration for cross-family viewer evidence enforcement
affects: [phase-69, phase-70]

tech-stack:
  added: []
  patterns:
    - "Cross-family docs-contract lane calls shared Validator — no duplicated lint/schema logic"
    - "Tier-A production pass + tier-B fixture violations in one lane module"

key-files:
  created:
    - test/docs_contract/viewer_evidence_claims_test.exs
  modified:
    - scripts/verify_docs.exs

key-decisions:
  - "Lane registration tests use @describetag :lane_registration; committed with verify_docs tuple in task 2"
  - "Orphan tier-B case writes transient priv/viewer_evidence/forms/orphan_test.md with on_exit cleanup"
  - "Staleness remains warning-only in run_full; docs-contract does not fail on stale recorded_at (D-17)"

patterns-established:
  - "Viewer evidence semantic-claims lane mirrors protection/embedded-artifact registration assertions"

requirements-completed: [RECIPE-04, GUARDRAIL-01, GUARDRAIL-03, GUARDRAIL-04]

duration: 12min
completed: 2026-05-28
---

# Phase 68 Plan 03: Docs-Contract Lane Summary

**Eighth docs-contract lane enforces viewer-evidence recording discipline via shared Validator, with tier-A production pass and tier-B violation fixtures for RECIPE-04 and GUARDRAIL-01/03/04.**

## Performance

- **Duration:** ~12 min
- **Started:** 2026-05-28T00:00:00Z
- **Completed:** 2026-05-28T00:12:00Z
- **Tasks:** 3 completed
- **Files modified:** 2

## Accomplishments

- Added `Rendro.DocsContract.ViewerEvidenceClaimsTest` with production tier-A checks (JSV structure, orphan scan, `_template.md`, staleness non-blocking).
- Tier-B negative cases call `Validator` / `Lint` directly: supported-without-evidence, deferral vocabulary, evidence body secrets/paths/PEM/images, byte budget, orphan detection, forbidden `compliance_tier` key.
- Registered eighth lane in `scripts/verify_docs.exs`; `mix docs.contract` runs 8/8 lanes green.

## Task Commits

1. **Task 1: Cross-family docs-contract test module** — `e0204e6` (test)
2. **Task 2: Register eighth lane in verify_docs.exs** — `30c9a09` (feat)
3. **Task 3: Regression sweep** — `94c1066` (chore)

## Verification Results

| Check | Result |
|-------|--------|
| `mix test test/docs_contract/viewer_evidence_claims_test.exs` | 14 tests, 0 failures |
| `mix docs.contract` | `Docs contract VERIFIED!` (8 lanes) |
| Prior lanes (forms/protection/signing/embedded_artifact) | 16 tests, 0 failures |
| `git diff priv/support_matrix.json` | empty (unchanged) |
| `.github/workflows/ci.yml` contains `viewer-evidence` | false (unchanged) |
| `mix rendro.viewer_evidence missing` | exit 1, 21 unverified cells |
| `mix rendro.viewer_evidence list --json` | `"total": 26` |
| `mix rendro.viewer_evidence validate` | exit 0 (structural pass + legacy warnings) |

## Operator Smoke (expected after Phase 68)

```
mix rendro.viewer_evidence list --json   # "total": 26 (5 supported legacy, 21 unverified)
mix rendro.viewer_evidence missing       # exit 1 — 21 silent unverified cells
mix rendro.viewer_evidence validate      # exit 0 — JSV OK; warnings for 5 legacy supported
mix docs.contract                        # 8/8 lanes PASS
```

## Files Created/Modified

- `test/docs_contract/viewer_evidence_claims_test.exs` — Cross-family viewer evidence docs-contract lane
- `scripts/verify_docs.exs` — Eighth lane tuple after Protection lane

## Decisions Made

None beyond plan — followed embedded-artifact lane registration pattern and shared Validator delegation.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Self-Check: PASSED

- Key files exist on disk
- All acceptance criteria verified via automated commands above
- `priv/support_matrix.json` and `.github/workflows/ci.yml` untouched

## Next Phase Readiness

Phase 68 plans 01–03 complete. Ready for Phase 69 (operator recipe + first cell end-to-end).

---
*Phase: 68-viewer-evidence-schema-mix-task-and-docs-contract-lane*
*Completed: 2026-05-28*
