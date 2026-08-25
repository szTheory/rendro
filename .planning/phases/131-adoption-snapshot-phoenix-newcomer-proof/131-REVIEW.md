---
phase: 131-adoption-snapshot-phoenix-newcomer-proof
reviewed: 2026-08-25T13:48:20Z
depth: standard
files_reviewed: 11
files_reviewed_list:
  - .github/workflows/hexdocs.yml
  - .github/workflows/release.yml
  - priv/adoption_evidence/2026-08-21.json
  - scripts/adoption_snapshot.exs
  - scripts/verify_public_release.exs
  - test/docs_contract/adoption_claims_test.exs
  - test/docs_contract/adoption_evidence_contract_test.exs
  - test/docs_contract/launch_execution_claims_test.exs
  - test/guardrails/required_checks_contract_test.exs
  - test/mix/tasks/release_preflight_test.exs
  - test/scripts/public_release_verifier_test.exs
findings:
  critical: 2
  warning: 1
  info: 0
  total: 3
status: issues_found
---

# Phase 131: Code Review Report

**Reviewed:** 2026-08-25T13:48:20Z
**Depth:** standard
**Files Reviewed:** 11
**Status:** issues_found

## Summary

The adoption snapshot itself fails closed on unavailable network data, and the focused test suite passes (65 tests). However, the release controls do not provide the claimed immutable candidate binding: the HexDocs publisher trusts operator-supplied values, and the public-verification record can overwrite a concurrently created target despite its explicit no-overwrite contract.

## Critical Issues

### CR-01: HexDocs publication is not bound to the sealed candidate

**File:** `.github/workflows/hexdocs.yml:66-86`
**Issue:** `candidate_commit_sha == github.sha` only proves that the dispatcher typed the SHA of the ref selected for that dispatch. Both values are operator-controlled, and neither is checked against the sealed approved SHA (`f03c78...`) or the `v1.3.4` tag's peeled commit. A dispatcher can select any commit that still declares version `1.3.4`, supply that commit as the input, and publish its documentation under the already-published package version. This breaks package/docs provenance and contradicts the “exact approved candidate” control.
**Fix:** Bind the job to immutable evidence. For this recovery release, compare the input and checked-out `HEAD` to the approved SHA and verify `refs/tags/v1.3.4^{}` resolves to it; for future releases, obtain the candidate SHA from a protected signed/immutable release record rather than a free-form dispatch input. Add a negative workflow/contract test for a different valid `1.3.4` commit.

### CR-02: Public verifier can overwrite a target created after its preflight check

**File:** `scripts/verify_public_release.exs:1038-1049`
**Issue:** `ensure_safe_output/1` checks nonexistence before `atomic_write/2`, but `File.rename/2` replaces an existing destination on Unix. A competing process can create the output after the check and before line 1044, causing the verifier to overwrite an existing authoritative record even though `write_verified/2` promises `output must not already exist`. This is a data-loss risk and invalidates the single-writer claim.
**Fix:** Create the record through an exclusive no-replace operation. For example, write and fsync a temp file, then use `:file.make_link/2` to link it to the final path (as `AdoptionSnapshot.write_snapshot/2` does), treating `:eexist` as an error and removing the temp file. Add a parallel-writer test that asserts exactly one verifier write succeeds and the losing writer cannot replace the result.

## Warnings

### WR-01: Snapshot accepts impossible calendar dates

**File:** `scripts/adoption_snapshot.exs:45-46`
**Issue:** The date check validates only the `YYYY-MM-DD` shape. Inputs such as `2026-02-31` and `2026-99-99` are accepted and then written as authoritative review dates, making dated evidence misleading and breaking chronological consumers.
**Fix:** Parse the value with `Date.from_iso8601/1` and accept only `{:ok, _}`; retain the existing error message for invalid dates. Add tests for an invalid day and month.

---

_Reviewed: 2026-08-25T13:48:20Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
