---
phase: 131-adoption-snapshot-phoenix-newcomer-proof
plan: "12"
subsystem: release-controls
tags: [hexdocs, release, workflow, security, provenance]
requires:
  - phase: 131-10
    provides: Sealed v1.3.4 candidate and public prerequisite evidence.
provides:
  - Trusted-workflow-only immutable HexDocs identity gate for v1.3.4.
  - Regression coverage rejecting another commit that declares version 1.3.4.
affects: [hexdocs, release]
tech-stack:
  added: []
  patterns: [immutable workflow constants, peeled annotated-tag binding, fail-closed pre-secret gate]
key-files:
  created: []
  modified:
    - .github/workflows/hexdocs.yml
    - test/docs_contract/launch_execution_claims_test.exs
key-decisions:
  - "Keep sealed candidate f03c78bab54efe1cd1596d51cf3f28193232e2a3 immutable; the candidate checkout remains the HexDocs source."
  - "Place the release identity predicate inline in the trusted workflow rather than in a candidate-contained script."
requirements-completed: [JOURNEY-01, JOURNEY-02]
metrics:
  tasks_completed: 1
  files_modified: 2
status: complete
---

# Phase 131 Plan 12: Immutable HexDocs Release Identity Summary

**Protected HexDocs publication now accepts only the sealed candidate, checkout, dispatch identity, and peeled `v1.3.4` tag bound to `f03c78bab54efe1cd1596d51cf3f28193232e2a3`.**

## Accomplishments

- Changed the protected job to check out the immutable approved SHA, never a dispatcher-controlled ref.
- Added an inline, fail-closed identity predicate before any secret validation or publishing. It fetches and peels `v1.3.4`, then requires `GITHUB_SHA`, both dispatcher assertions, checkout `HEAD`, peeled tag, and the single `@version` declaration to agree.
- Reworked the deterministic contract around the trusted inline workflow predicate and proved that another real `1.3.4` commit is rejected in every identity position.

## Verification

- `mix test test/docs_contract/launch_execution_claims_test.exs --max-failures 1` — pass (9 tests, 0 failures).
- `mix format --check-formatted test/docs_contract/launch_execution_claims_test.exs` — pass.
- Detached candidate-worktree replay of the inline predicate — pass for the approved SHA and fail for another real `1.3.4` commit (`d6608fc40b6e0d62214458f4e1c9718eb9349575`).
- Workflow structural check — pass: immutable checkout, explicit tag fetch/peel, all identity assertions, no candidate-contained predicate script, and identity gate preceding secret validation/publish.

## Task Commits

1. **RED: external predicate contract** — `55f8908` (test)
2. **Checkpoint decision contract adjustment** — `d6608fc` (test)
3. **GREEN: trusted inline immutable gate** — `bec0999` (fix)
4. **Contract formatting** — `df160e9` (style)

## Files Modified

- `.github/workflows/hexdocs.yml` — fixed-SHA checkout and pre-secret identity/tag/version predicate.
- `test/docs_contract/launch_execution_claims_test.exs` — inline workflow contract and same-version alternate-commit regression.

## Decisions Made

- The sealed candidate remains immutable and is still the source checkout for publication.
- The predicate is workflow-controlled because a new script cannot be required to exist in an already-sealed candidate checkout.

## Deviations from Plan

### Checkpoint-authorized decision

**1. [Rule 4 - Architecture] Moved the identity predicate into the trusted workflow**
- **Found during:** Task 1 decision checkpoint.
- **Issue:** The planned new `scripts/verify_hexdocs_release_identity.sh` cannot be present in the immutable approved candidate checkout without changing the candidate identity.
- **Fix:** Removed the impossible script artifact requirement and made the trusted workflow own the fixed constants, tag fetch/peel, and all identity comparisons.
- **Files modified:** `.github/workflows/hexdocs.yml`, `test/docs_contract/launch_execution_claims_test.exs`.
- **Verification:** Focused contract suite, detached candidate replay, and structural pre-secret ordering check passed.
- **Commits:** `d6608fc`, `bec0999`, `df160e9`.

**Total deviations:** 1 checkpoint-authorized architectural adjustment. **Impact:** Preserves immutable release provenance while strengthening the protected workflow boundary.

## Self-Check: PASSED

- Required workflow and contract files exist.
- RED, checkpoint adjustment, GREEN, and formatting commits `55f8908`, `d6608fc`, `bec0999`, and `df160e9` exist in git history.
- No `scripts/verify_hexdocs_release_identity.sh` artifact was created.
