---
phase: 135-test-ci-cd-simplification
reviewed: 2026-08-27T20:40:37Z
depth: standard
files_reviewed: 15
files_reviewed_list:
  - dev/rendro/catalog_evidence_bundle.ex
  - dev/rendro/catalog_evidence_parity.ex
  - test/rendro/catalog_evidence_bundle_test.exs
  - test/rendro/catalog_evidence_parity_test.exs
  - test/docs_contract/phase_135_test_inventory_contract_test.exs
  - test/rendro/recipes/themed_render_smoke_test.exs
  - test/rendro/recipes/payslip_opts_threading_test.exs
  - test/rendro/recipes/certificate_typography_test.exs
  - .github/workflows/catalog-evidence.yml
  - .github/workflows/CATALOG-EVIDENCE.md
  - test/docs_contract/catalog_evidence_runbook_test.exs
  - test/guardrails/required_checks_contract_test.exs
  - scripts/verify_docs.exs
  - scripts/README.md
  - .github/workflows/ci.yml
findings:
  critical: 4
  warning: 1
  info: 0
  total: 5
status: issues_found
---

# Phase 135: Code Review Report

**Reviewed:** 2026-08-27T20:40:37Z
**Depth:** standard
**Files Reviewed:** 15
**Status:** issues_found

## Summary

The phase has good static pinning and topology checks, and the focused suite (60 tests), workflow lint, and documentation runner pass. However, the claimed control-plane, exact-SHA, and parity guarantees are not enforced at their trust boundaries. A candidate commit can rewrite the later control-plane execution, and both the comparator and committed parity ledger accept evidence that does not satisfy the required route-specific semantic facts. The documented primary dispatch commands also send a literal invalid SHA.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01 [BLOCKER]: Untrusted candidate code can overwrite the trusted control plane

**File:** `.github/workflows/catalog-evidence.yml:79`
**Issue:** The workflow executes arbitrary Mix tasks and tests from `CANDIDATE_DIR` (lines 79-126) on the same runner, with both `CONTROL_DIR` and `RUNNER_TEMP` exposed in the job environment. A candidate can write to `${CONTROL_DIR}`, replace the PDFium executable, pre-create/symlink `${RUNNER_TEMP}/rendro-catalog-evidence`, or otherwise alter the files and tools used by the subsequent control-plane `mix run` at lines 128-170. Separate checkout paths and `persist-credentials: false` do not provide filesystem/process isolation.

**Fix:** Execute candidate generation in a real isolation boundary (for example, a separately provisioned job/container with no control checkout and an artifact-only handoff), then have a fresh control-plane job download and validate only that artifact. At minimum, do not run candidate code before the control checkout is freshly materialized and integrity-verified, and do not share writable runner paths; this is not a sufficient replacement for isolation.

### CR-02 [BLOCKER]: Bundle validation accepts incorrect review payload cardinalities

**File:** `dev/rendro/catalog_evidence_bundle.ex:219`
**Issue:** Review payload counts are accepted when merely positive (lines 219-228). Only canonical count `32` is constrained. Consequently a self-consistent bundle can claim one candidate/final/multipage/preset item where the contract requires `32/12/4/12`; checksum validation only confirms the wrong files and manifest agree with each other. This defeats the stated fail-closed bounded-count evidence contract.

**Fix:** Define the expected count alongside each closed role and require it during both `build/4` and `validate/2`, e.g. `"candidate/catalog.json" => 32`, `"final-review/final.json" => 12`, `"multipage-review/multipage.json" => 4`, and `"preset-review/preset.json" => 12`. Parse/validate the role payloads as needed so the count is derived from their actual records rather than trusted metadata.

### CR-03 [BLOCKER]: The parity comparator does not implement route-specific normalization or semantics

**File:** `dev/rendro/catalog_evidence_parity.ex:7`
**Issue:** `route` is only validated (lines 9-14); it never selects a legacy layout, expected roles, expected counts, or reviewer applicability. The equality predicate simply compares caller-supplied `payloads` maps (lines 51-62), whose only validation is sorted unique names, a SHA-shaped string, and a positive count (lines 109-117). The supplied test fixture demonstrates the gap: every one of the four routes uses the same one-item `"catalog"` payload (test line 74) and passes. Thus malformed or incomplete evidence can be declared parity, and the four-route cutover has no executable semantic proof.

**Fix:** Make every route map to an explicit legacy extractor and generic-role schema. Load/validate the actual manifests and payload files, compute per-file SHA-256 values, require the exact route-specific role/count set and reviewer rule, and compare that normalized result. Add negative tests for an incorrect role set/count for each route, not only mutations to a pre-normalized fixture.

### CR-04 [BLOCKER]: The parity ledger contract permits fabricated `matched` evidence

**File:** `test/docs_contract/phase_135_test_inventory_contract_test.exs:25`
**Issue:** The ledger test verifies row order, status vocabulary, and only that all candidate-SHA cells are equal (lines 25-32). It does not require a lowercase 40-character candidate SHA, nonempty/valid run URLs, run IDs/attempts, artifact identities, upload digests, renderer facts, normalized hashes, action/permission facts, or a successful comparator result. Replacing all four rows with empty transport/authority columns, any shared value, and `matched` still satisfies this test, allowing the committed matrix to authorize deletion without the evidence it claims to record.

**Fix:** Parse each matrix column into typed facts; validate full SHA, URL, positive attempts, artifact identity, SHA-256 transport digest, renderer/pin/permission facts, and exact normalized route records. For `matched`, require a durable comparator output (or independently recompute it from retained input evidence) and reject incomplete fields. Add mutation tests for each required field and for a false `matched` status.

## Warnings

### WR-01 [WARNING]: Runbook dispatches the literal word `FULL_SHA`

**File:** `.github/workflows/CATALOG-EVIDENCE.md:21`
**Issue:** Both documented dispatch commands use `candidate_sha=FULL_SHA` (lines 21 and 32) instead of shell expansion. The workflow rejects that value because it is not a 40-character lowercase hexadecimal SHA, so the primary maintainer path fails immediately. The same section later correctly uses `${FULL_SHA}` in a Git command, confirming this is not intentional notation.

**Fix:** Use a quoted shell expansion in both commands:

```bash
gh workflow run catalog-evidence.yml -f "candidate_sha=${FULL_SHA}" -f operation=review
```

Also correct the identity check at lines 92-93: candidate SHA and checked-out HEAD must match; the control SHA is a distinct default-branch control-plane identity and must not be described as the requested candidate identity.

---

_Reviewed: 2026-08-27T20:40:37Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_

## Fix Resolution (Iteration 1)

- CR-01: fixed in `6843e03`
- CR-02: fixed in `a39ff7e`
- CR-03: fixed in `2d67ab7`
- CR-04: resolved fail-closed in `135-parity-comparator-record.json`; archive digests were verified and only canonical parity matched
- WR-01: fixed in `e473936`
