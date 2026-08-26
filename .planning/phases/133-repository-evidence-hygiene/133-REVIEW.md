---
phase: 133-repository-evidence-hygiene
reviewed: 2026-08-26T22:55:32Z
depth: standard
files_reviewed: 52
files_reviewed_list:
  - .github/workflows/release.yml
  - dev/mix/tasks/quality/hygiene.ex
  - dev/rendro/repository_evidence.ex
  - dev/rendro/repository_hygiene.ex
  - evidence/releases/v1.3.4/journey/index.json
  - evidence/releases/v1.3.4/journey/journey-001.json
  - evidence/releases/v1.3.4/journey/journey-001.md
  - evidence/releases/v1.3.4/journey/journey-002.json
  - evidence/releases/v1.3.4/journey/journey-002.md
  - evidence/releases/v1.3.4/journey/journey-003.json
  - evidence/releases/v1.3.4/journey/journey-003.md
  - evidence/releases/v1.3.4/journey/journey-004.json
  - evidence/releases/v1.3.4/journey/journey-004.md
  - evidence/releases/v1.3.4/journey/journey-005.json
  - evidence/releases/v1.3.4/journey/journey-005.md
  - evidence/releases/v1.3.4/journey/journey-006.json
  - evidence/releases/v1.3.4/journey/journey-006.md
  - evidence/releases/v1.3.4/journey/journey-007.json
  - evidence/releases/v1.3.4/journey/journey-008.json
  - evidence/releases/v1.3.4/journey/journey-008.md
  - evidence/releases/v1.3.4/journey/journey-009.json
  - evidence/releases/v1.3.4/journey/journey-009.md
  - evidence/releases/v1.3.4/manifest.json
  - evidence/releases/v1.3.4/public_prerequisite.json
  - evidence/releases/v1.3.4/release_identity.json
  - evidence/releases/v1.3.4/validation.json
  - mix.exs
  - priv/pdfjs_observations/bench_rendro_invoice.json
  - priv/pdfjs_observations/schema.json
  - priv/quality/package-members-v1.json
  - priv/schemas/release_evidence_attempt.schema.json
  - priv/schemas/release_evidence_identity.schema.json
  - priv/schemas/release_evidence_journey_index.schema.json
  - priv/schemas/release_evidence_manifest.schema.json
  - priv/schemas/release_evidence_prerequisite.schema.json
  - priv/schemas/release_evidence_validation.schema.json
  - scripts/README.md
  - scripts/pdfjs_observer/observe.mjs
  - scripts/phoenix_clean_room_proof.exs
  - scripts/verify_public_release.exs
  - test/docs_contract/comparison_claims_test.exs
  - test/docs_contract/dx_local_reproducibility_claims_test.exs
  - test/docs_contract/pdfjs_advisory_claims_test.exs
  - test/docs_contract/phoenix_newcomer_contract_test.exs
  - test/fixtures/pdfjs-rendro.pdf
  - test/guardrails/required_checks_contract_test.exs
  - test/mix/tasks/ci_alias_contract_test.exs
  - test/quality/repository_hygiene_test.exs
  - test/rendro/comparison_test.exs
  - test/scripts/phoenix_clean_room_proof_test.exs
  - test/scripts/public_release_verifier_test.exs
  - test/scripts/repository_evidence_test.exs
findings:
  critical: 1
  warning: 3
  info: 0
  total: 4
status: issues_found
---

# Phase 133: Code Review Report

**Reviewed:** 2026-08-26T22:55:32Z
**Depth:** standard
**Files Reviewed:** 52
**Status:** issues_found

## Summary

The new repository evidence and hygiene paths were reviewed with the project’s pure-core, advisory-boundary, and documentation-contract conventions. The hygiene command and focused test suite execute, but the release advisory cannot report a successful proof, evidence loading leaves the claimed journey chain unverified, and the hygiene/documentation contracts have coverage gaps.

## Critical Issues

### CR-01: Successful Phoenix clean-room proofs crash while constructing evidence

**File:** `scripts/phoenix_clean_room_proof.exs:418`
**Issue:** `options.prerequisite` is always the atom `:capsule` (the only value produced by `parse_options/1`), but `sha256/1` at line 861 unconditionally passes its argument to `File.read!/1`. A proof that reaches the success branch therefore raises `File.Error` for `:capsule`; the outer rescue turns the run into failure. The release workflow consequently can never produce fresh successful advisory evidence even when every clean-room check passes.
**Fix:** Hash the verified capsule file (or the canonical encoded prerequisite facts), rather than the option sentinel. For example, make `read_prerequisite/1` return the resolved path alongside its facts and call `sha256(path)`, or replace the field with a deterministic digest of `JSON.encode!(prerequisite)`.

## Warnings

### WR-01: Journey-index loading does not validate the journey records it claims

**File:** `dev/rendro/repository_evidence.ex:34-45`
**Issue:** Loading `:journey_index` validates only the manifest and `journey/index.json`. It never resolves the IDs in `entries`, verifies that they map one-for-one and in-order to manifest `journey_attempt` records, checks their digests/schemas/release bindings, or verifies explanatory-sidecar digests. Thus a capsule can pass `load_role(:journey_index)` while its retained journey evidence is missing, altered, or unrelated to the index, defeating the stated digest-bound provenance boundary.
**Fix:** Add a journey-specific validation step after loading the index: resolve every listed ID from manifest records, enforce exact ordered correspondence and uniqueness, validate each JSON digest/schema/release binding, and validate any referenced Markdown sidecar as a confined regular file with its declared SHA-256.

### WR-02: Hygiene’s archive-consumer gate does not inspect tracked shell sources

**File:** `dev/rendro/repository_hygiene.ex:178-180`
**Issue:** `operational_source?/1` excludes `.sh` and `.bash`, although `executable_script?/1` explicitly treats shell scripts as tracked operational helpers. A new shell helper can therefore read `.planning/phases/…` and evade `check_operational_sources/1`, bypassing the repository’s no-runtime-evidence/planning-consumer boundary.
**Fix:** Include `sh` and `bash` in the operational-source extension regex and add a test containing a shell archive reference, e.g. `scripts/example.sh => 'cat .planning/phases/131-old/131-FACTS.md'`.

### WR-03: The documented Phoenix helper command is rejected by the helper

**File:** `scripts/README.md:28`
**Issue:** The inventory declares `--prerequisite PATH` as a supported invocation, but `parse_options/1` accepts only no arguments, `--output PATH`, and the two `--output/--root` orderings (lines 308-326 of `phoenix_clean_room_proof.exs`). Following the documented command immediately returns `:invalid_arguments`. This violates the project rule that documentation claims are contracts.
**Fix:** Either restore a safe, validated `--prerequisite PATH` option and use it consistently, or update the inventory to document the capsule-only interface actually implemented.

---

_Reviewed: 2026-08-26T22:55:32Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
