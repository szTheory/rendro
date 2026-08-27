---
phase: 131
fixed_at: 2026-08-25T22:10:00Z
review_path: /Users/jon/projects/rendro/.planning/phases/131-adoption-snapshot-phoenix-newcomer-proof/131-REVIEW.md
iteration: 3
findings_in_scope: 5
fixed: 5
skipped: 0
status: all_fixed
---

# Phase 131: Code Review Fix Report

**Fixed at:** 2026-08-25T22:10:00Z
**Source review:** `/Users/jon/projects/rendro/.planning/phases/131-adoption-snapshot-phoenix-newcomer-proof/131-REVIEW.md`
**Iteration:** 3

**Summary:**

- Findings in scope: 5
- Fixed: 5
- Skipped: 0

## Fixed Issues

### CR-01: Verified record does not bind the public tarball to the sealed candidate tarball

**Files modified:** `scripts/verify_public_release.exs`, `test/scripts/public_release_verifier_test.exs`
**Commit:** 7282163
**Status:** reviewer false positive corrected
**Applied fix:** Removed the raw outer-archive equality check. Hex's API checksum authenticates the downloaded archive; canonical manifest and normalized metadata bind its semantic payload to the sealed candidate. Regression coverage now proves distinct outer archive bytes are accepted only when those canonical payloads match.

### CR-02: Public-release verification accepts a skipped or failed publish job

**Files modified:** `scripts/verify_public_release.exs`, `test/scripts/public_release_verifier_test.exs`
**Commit:** ea25703
**Applied fix:** The verifier now requires a numeric publish-job ID and a successful publish conclusion; regression cases cover skipped, failed, and missing-ID records.

### WR-01: The claimed clean-room result is not executed by any reviewed CI gate

**Files modified:** `.github/workflows/release.yml`, `test/guardrails/required_checks_contract_test.exs`
**Commit:** 7b52c6d
**Applied fix:** Added a bounded, explicitly advisory release job that runs the Phoenix clean-room proof against the immutable prerequisite, rejects non-success/non-cleanup results, and uploads the fresh evidence artifact. The job remains separate from required deterministic checks; the corrected semantic archive check preserves the valid immutable prerequisite.

### WR-02: Cleanup claims process removal although process-tree termination is a no-op

**Files modified:** `scripts/phoenix_clean_room_proof.exs`, `test/scripts/phoenix_clean_room_proof_test.exs`, `.github/workflows/release.yml`, `priv/journey_evidence/phoenix_clean_room_1.3.4.json`, `priv/journey_evidence/phoenix_clean_room_1.3.4.md`, `.planning/phases/131-adoption-snapshot-phoenix-newcomer-proof/131-VALIDATION.md`
**Commit:** 1b34dec
**Applied fix:** Replaced the ambiguous cleanup claim with `workspace_removed`, emitted only after cleanup succeeds and the workspace no longer exists. Evidence, CI, and contracts now state that this covers disposable application/workspace, dependencies, caches, build output, lock, and payload removal—not process-tree verification.

### CR-01 (iteration 3): Advisory proof root is rejected on GitHub runners

**Files modified:** `.github/workflows/release.yml`, `test/guardrails/required_checks_contract_test.exs`
**Commit:** 36843f2
**Applied fix:** Moved `PROOF_ROOT` to a unique `/tmp/rendro-phoenix-clean-room-${{ github.run_id }}-${{ github.run_attempt }}` path, outside the runner home directory rejected by `create_root/1`. The guardrail also rejects a `runner.temp` proof root; `PROOF_OUTPUT` remains in `runner.temp`.

---

_Fixed: 2026-08-25T22:10:00Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 3_
