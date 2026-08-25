---
phase: 131
fixed_at: 2026-08-25T15:26:01Z
review_path: /Users/jon/projects/rendro/.planning/phases/131-adoption-snapshot-phoenix-newcomer-proof/131-REVIEW.md
iteration: 3
findings_in_scope: 1
fixed: 1
skipped: 0
status: all_fixed
---

# Phase 131: Code Review Fix Report

**Fixed at:** 2026-08-25T15:26:01Z
**Source review:** `/Users/jon/projects/rendro/.planning/phases/131-adoption-snapshot-phoenix-newcomer-proof/131-REVIEW.md`
**Iteration:** 3

**Summary:**
- Findings in scope: 1
- Fixed: 1
- Skipped: 0

## Fixed Issues

### CR-01: Durable binding control SHA must match the authoritative HexDocs run

**Files modified:** `scripts/verify_public_release.exs`, `test/scripts/public_release_verifier_test.exs`
**Commit:** 6025104
**Applied fix:** The durable binding's `control_sha` now must exactly match GitHub's HexDocs workflow-run `headSha`. The detached artifact SHA remains independently bound to the sealed candidate, so a protected control SHA may still differ from the candidate SHA. Added a fail-closed regression test that asserts the precise mismatch error.

---

_Fixed: 2026-08-25T15:26:01Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 3_
