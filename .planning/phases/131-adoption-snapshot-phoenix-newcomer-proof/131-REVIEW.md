---
phase: 131-adoption-snapshot-phoenix-newcomer-proof
reviewed: 2026-08-25T21:37:34Z
depth: standard
files_reviewed: 15
files_reviewed_list:
  - .github/workflows/hexdocs.yml
  - .github/workflows/release.yml
  - priv/adoption_evidence/2026-08-21.json
  - priv/journey_evidence/phoenix_clean_room_1.3.4.json
  - priv/journey_evidence/phoenix_clean_room_1.3.4.md
  - scripts/adoption_snapshot.exs
  - scripts/phoenix_clean_room_proof.exs
  - scripts/verify_public_release.exs
  - test/docs_contract/adoption_claims_test.exs
  - test/docs_contract/adoption_evidence_contract_test.exs
  - test/docs_contract/launch_execution_claims_test.exs
  - test/guardrails/required_checks_contract_test.exs
  - test/mix/tasks/release_preflight_test.exs
  - test/scripts/phoenix_clean_room_proof_test.exs
  - test/scripts/public_release_verifier_test.exs
findings:
  critical: 2
  warning: 2
  info: 0
  total: 4
status: issues_found
---

# Phase 131: Code Review Report

**Reviewed:** 2026-08-25T21:37:34Z
**Depth:** standard
**Files Reviewed:** 15
**Status:** issues_found

## Summary

The reviewed code has solid unit coverage for its projections and several useful fail-closed checks, but it does not substantiate the claimed release identity end-to-end. In particular, a `VERIFIED` prerequisite can be written for a different archive than the sealed candidate, and it can be written even when the tagged release's publish job was skipped. The clean-room evidence is also only exercised through unit doubles; neither reviewed workflow runs the real isolated consumer proof, and process cleanup is not actually implemented.

The targeted test command passed (54 tests), but its fixtures encode the missing release checks and its clean-room tests do not execute the live harness.

## Critical Issues

### CR-01: Verified record does not bind the public tarball to the sealed candidate tarball

**File:** `scripts/verify_public_release.exs:755`
**Issue:** `validate_public_archive_identity/1` verifies only that `sealed_archive_sha256` is syntactically a digest. It compares the downloaded archive to Hex's API checksum and compares derived manifest/metadata digests to the candidate record, but never compares `public_archive_sha256` with `sealed_archive_sha256`. The existing fixture deliberately gives those fields different values (`d...` versus `c...`) and is accepted. An archive can therefore be declared `VERIFIED` despite its sealed candidate byte digest not matching the artifact obtained from Hex.

**Fix:** Require an exact equality check and add a regression test that mutates only `sealed_archive_sha256`:

```elixir
with :ok <- valid_digest?(facts["sealed_archive_sha256"], "sealed archive SHA-256 is invalid"),
     :ok <- equal?(
       facts["public_archive_sha256"],
       facts["sealed_archive_sha256"],
       "public archive SHA-256 does not match the sealed candidate"
     ),
     :ok <- equal?(facts["public_archive_sha256"], facts["hex_api_checksum"], ...)
do
  :ok
end
```

### CR-02: Public-release verification accepts a skipped or failed publish job

**File:** `scripts/verify_public_release.exs:117`
**Issue:** `validate/1` checks the `validate-and-dry-run` job ID and conclusion, then proceeds directly to archive verification. It never validates `release_publish_job_id` or `release_publish_job_conclusion`, although collection records both fields. A workflow may conclude successfully when its publish job is skipped, allowing a separately existing Hex package to make the record appear to prove that this release workflow published the candidate.

**Fix:** Validate that the collected publish job has a numeric ID and a `"success"` conclusion before accepting public archive facts; add tests for `"skipped"`, `"failure"`, and a missing ID.

```elixir
:ok <- valid_numeric?(facts["release_publish_job_id"], "release publish job ID must be numeric"),
:ok <- equal?(
  facts["release_publish_job_conclusion"],
  "success",
  "release publish job did not conclude successfully"
),
```

## Warnings

### WR-01: The claimed clean-room result is not executed by any reviewed CI gate

**File:** `.github/workflows/release.yml:47`
**Issue:** The release workflow runs `mix ci` and `mix release.preflight`, while the HexDocs workflow similarly runs documentation checks; neither invokes `scripts/phoenix_clean_room_proof.exs`. The JSON/Markdown success evidence is static, and the included tests use injected runners, synthetic ports, and fixtures rather than the actual Phoenix installation path. Thus a green CI build does not establish that the recorded newcomer journey remains reproducible without conversational UAT.

**Fix:** Add a bounded, explicitly advisory CI job that invokes the proof with the immutable public prerequisite and uploads its bounded result. If live external access must remain advisory, make that designation visible in the workflow and fail the job when the proof cannot produce a fresh success record; keep the deterministic unit tests separate.

### WR-02: Cleanup claims process removal although process-tree termination is a no-op

**File:** `scripts/phoenix_clean_room_proof.exs:842`
**Issue:** `terminate_process_tree/1` always returns `:ok`. `run_bounded/5` can brutally stop only its BEAM task (not reliably the external `mix` process), and `stop_server/1` signals only the immediate `env` process. Descendant processes can survive while `cleanup_root/1` removes the directory and the evidence is marked `"cleanup": "removed"`. This contradicts the retained evidence's claim that process state was removed and can contaminate later runs.

**Fix:** Start external commands and the endpoint in their own process group/session, retain the group PID, and terminate/reap the full group on every timeout/finalizer path. Mark cleanup as failed unless all tracked processes have exited before the root is removed. Add an integration test that starts a child process and proves it is no longer alive after both success and timeout cleanup.

---

_Reviewed: 2026-08-25T21:37:34Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
