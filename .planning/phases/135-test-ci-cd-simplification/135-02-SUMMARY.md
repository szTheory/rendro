---
phase: 135-test-ci-cd-simplification
plan: "02"
subsystem: ci-cd
tags: [github-actions, catalog-evidence, docs-contract, security]
requires:
  - phase: 135-test-ci-cd-simplification
    provides: Catalog evidence bundle builder and parity contracts from Plan 01
provides:
  - Manual, exact-SHA, least-privilege Catalog Evidence workflow
  - One adjacent runbook with deterministic documentation enforcement
  - Parsed workflow and ordinary-CI topology contracts
affects: [phase-135-plan-03, phase-136-catalog-visual-quality]
tech-stack:
  added: []
  patterns: [manual workflow_dispatch, separate control/candidate checkouts, manifest-rooted artifact, docs-contract lane]
key-files:
  created:
    - .github/workflows/catalog-evidence.yml
    - .github/workflows/CATALOG-EVIDENCE.md
    - test/docs_contract/catalog_evidence_runbook_test.exs
  modified:
    - test/guardrails/required_checks_contract_test.exs
    - scripts/verify_docs.exs
    - scripts/README.md
decisions:
  - Catalog Evidence is standalone workflow_dispatch-only evidence transport, not an ordinary-CI or ci-success dependency.
  - The default-branch control checkout packages and validates detached candidate output before the sole upload.
metrics:
  duration: 16m
  completed: 2026-08-27
  tasks_completed: 2
  files_changed: 6
status: complete
---

# Phase 135 Plan 02: Catalog Evidence Workflow and Runbook Summary

Delivered a read-only manual exact-SHA catalog-evidence lane with one 30-day manifest-rooted bundle and a contract-tested maintainer runbook.

## Tasks Completed

1. **Lock workflow security and topology contracts before implementation**
   - Added parsed YAML assertions for manual dispatch inputs, immutable action pins, separate credential-free checkouts, literal candidate HEAD binding, one upload, and unchanged `ci-success` topology.
   - Implemented `.github/workflows/catalog-evidence.yml` with `review` and `canonical` closed operations, pinned PDFium verification, and control-plane bundle validation.
   - Commits: `a7f67ec`, `93e3182`.

2. **Publish the one current runbook and verify every operator job**
   - Added the workflow-adjacent runbook covering dispatch, retrieval, validation, authority limits, deterministic reproduction, and recovery for maintainer, reviewer, Phase 136, and SRE/security roles.
   - Registered one `Catalog evidence runbook lane` and linked it from the helper inventory.
   - Commits: `b58ed76`, `fb0872c`.

## Verification

- `actionlint .github/workflows/catalog-evidence.yml` — passed.
- `mix test test/guardrails/required_checks_contract_test.exs test/docs_contract/catalog_evidence_runbook_test.exs --max-failures 1` — passed (32 tests).
- `mix run scripts/verify_docs.exs` — passed (28 docs-contract lanes, including Catalog evidence runbook).
- `mix format --check-formatted` — passed.
- `mix ci.fast` — passed.
- `git diff --exit-code e764d0a HEAD -- .github/workflows/ci.yml priv/guardrails/required_status_checks.json` — passed; ordinary CI and required-status config are unchanged.

## Decisions Made

- Keep catalog evidence graph-disconnected from ordinary CI and the sole `ci-success` authority.
- Treat the default-branch checkout as the control plane; only it builds and validates the upload bundle from untrusted candidate output.
- Keep status textual and authoritative in the bundle/runbook; remote renderer evidence remains separate from Phase 136 visual judgment.

## Deviations from Plan

### Auto-fixed Issues

1. **[Rule 1 - Bug] Normalize parsed CI trigger-key order in the topology contract**
   - **Found during:** Task 1
   - **Issue:** YAML maps do not preserve source key order, so the new unchanged-CI assertion incorrectly expected an ordered list.
   - **Fix:** Sorted parsed trigger keys before comparing the fixed trigger set.
   - **Files modified:** `test/guardrails/required_checks_contract_test.exs`
   - **Verification:** Focused guardrail suite passed.
   - **Commit:** `93e3182`

**Total deviations:** 1 auto-fixed (Rule 1).
**Impact:** Test-only correction; the locked CI topology remains unchanged.

## Known Stubs

None.

## Self-Check

PASSED

- Confirmed all six created/modified workflow, runbook, test, and documentation files exist.
- Confirmed task commits `a7f67ec`, `93e3182`, `b58ed76`, and `fb0872c` exist in Git history.
- Re-ran the focused workflow/docs contract suites, `actionlint`, docs runner, formatting check, and `mix ci.fast` in this execution.
