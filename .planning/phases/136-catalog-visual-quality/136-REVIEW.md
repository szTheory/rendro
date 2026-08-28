---
phase: 136-catalog-visual-quality
reviewed: 2026-08-28T17:46:52Z
depth: standard
files_reviewed: 21
files_reviewed_list:
  - .github/workflows/CATALOG-EVIDENCE.md
  - .github/workflows/catalog-evidence.yml
  - dev/rendro/catalog.ex
  - dev/rendro/catalog_evidence_bundle.ex
  - lib/rendro/recipes/invoice.ex
  - lib/rendro/recipes/payslip.ex
  - lib/rendro/recipes/statement.ex
  - lib/rendro/recipes/ticket.ex
  - priv/quality/SIGN-OFF.md
  - test/docs_contract/catalog_evidence_runbook_test.exs
  - test/docs_contract/rubric_manifest_contract_test.exs
  - test/rendro/catalog_evidence_bundle_test.exs
  - test/rendro/catalog_review_payload_contract_test.exs
  - test/rendro/catalog_test.exs
  - test/rendro/recipes/invoice_opts_threading_test.exs
  - test/rendro/recipes/invoice_test.exs
  - test/rendro/recipes/payslip_byte_identity_test.exs
  - test/rendro/recipes/payslip_test.exs
  - test/rendro/recipes/statement_test.exs
  - test/rendro/recipes/ticket_byte_identity_test.exs
  - test/rendro/recipes/ticket_test.exs
findings:
  critical: 7
  warning: 2
  info: 0
  total: 9
status: issues_found
---

# Phase 136: Code Review Report

**Reviewed:** 2026-08-28T17:46:52Z
**Depth:** standard
**Files Reviewed:** 21
**Status:** issues_found

## Summary

The phase is not shippable. The deterministic review operation is currently impossible for the declared six-target scope, the canonical operation rejects the real catalog in two separate checks, and the trusted control job does not semantically bind candidate-controlled payloads to the provenance it publishes. Additional blockers include a valid-data Payslip crash, advisory evidence blocking deterministic candidate generation, false baseline provenance, and a rollback path that can delete canonical assets.

Verification performed during review:

- Rendering all 32 source PDFs and comparing them with the committed manifest found only five changed source-PDF identities; `ticket--aurora-live--brutalist--light` is byte-stable despite being required in the six-item changed set.
- Building a canonical evidence bundle from the real `assets/rendro/catalog.json` returned `{:error, [:invalid_payload_counts]}`.
- Calling the sequential Payslip profile with a valid line whose optional `:ytd` is omitted raised `KeyError` at `money_column_width/4`.
- The selected existing suite completed with 222 tests and 0 failures, demonstrating that these failure modes are not covered by the current tests.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Trusted control accepts semantically forged candidate payloads

**Classification:** BLOCKER

**Files:** `/Users/jon/projects/rendro/.github/workflows/catalog-evidence.yml:143`, `/Users/jon/projects/rendro/dev/rendro/catalog_evidence_bundle.ex:246-250`, `/Users/jon/projects/rendro/test/rendro/catalog_evidence_bundle_test.exs:172-211`

**Issue:** Candidate code controls every task that creates the four review payloads. The default-branch control job checks only filenames, byte size, and collection counts, while `CatalogEvidenceBundle` likewise treats a payload as valid when it merely has 32 `cells`, 12 `images`, or four checksum-looking lines. It never binds the candidate payload's internal commit, renderer, IDs, paths, or hashes to the dispatch SHA and trusted pin. The positive unit test proves the gap by successfully validating arbitrary `item-1` through `item-32` records with none of the catalog contract fields. The control job then writes `candidate_sha`, `checked_out_head`, and renderer provenance from trusted environment values around those untrusted bytes, producing a fully validated bundle that can falsely attribute stale or fabricated evidence to the requested candidate.

**Fix:** In the trusted checkout, parse and validate each payload against closed schemas and exact ordered IDs. Bind every internal candidate SHA and renderer identity to `CANDIDATE_SHA` and the trusted PDFium pin; validate all cell/image paths and lowercase hashes; cross-check final-review records against candidate cells; require the exact multipage IDs and filenames. Record checked-out candidate HEAD from a workflow-owned fact rather than assigning it from the request. Replace the arbitrary-item positive test with real contract-shaped fixtures and add forged/stale payload rejection tests.

### CR-02: The canonical operation always rejects the real catalog

**Classification:** BLOCKER

**Files:** `/Users/jon/projects/rendro/.github/workflows/catalog-evidence.yml:73`, `/Users/jon/projects/rendro/dev/rendro/catalog_evidence_bundle.ex:322-330`, `/Users/jon/projects/rendro/test/rendro/catalog_evidence_bundle_test.exs:189-211`

**Issue:** The workflow checks `jq 'length' assets/rendro/catalog.json` against 32, but the catalog is a top-level object whose 32 records live under `cells`. If that check is corrected, bundle validation still routes `canonical/catalog.json` through `json_record_count(path, "images")`, so the real catalog returns `:invalid_payload_counts`. The test masks both production mismatches by constructing a fake canonical payload with an `images` collection.

**Fix:** Change the workflow assertion to `jq '.cells | length'`. Give `canonical/catalog.json` its own `record_count` clause using `"cells"`, and make the canonical test use the real catalog shape (or `cells_json(32)`) plus a regression test that packages `assets/rendro/catalog.json`.

### CR-03: The six-target scope cannot pass because one required target is byte-stable

**Classification:** BLOCKER

**Files:** `/Users/jon/projects/rendro/dev/rendro/catalog.ex:91-98`, `/Users/jon/projects/rendro/dev/rendro/catalog.ex:1061-1077`, `/Users/jon/projects/rendro/priv/quality/SIGN-OFF.md:150-169`

**Issue:** `valid_candidate_diff/1` requires all six profile IDs to appear in `changed_scored`. However, the atomic-cell wrapper applied to `ticket--aurora-live--brutalist--light` does not change its deterministic rendered PDF; its source-PDF SHA remains the committed baseline SHA, and the same PDF plus pinned renderer necessarily yields the same PNG. Therefore that cell is classified `byte_stable`, and the exact declared candidate fails with `:invalid_candidate_scope`, matching the recorded remote failure. No review bundle can be produced from this implementation.

**Fix:** Make the declared scope truthful to byte behavior. Either remove the light ticket from the changed target set and update all closed counts/order contracts, or implement an intentional, approved visual change that actually changes its deterministic bytes. Do not manufacture hash drift merely to satisfy the count. Add an integration test that renders the actual six specs against the committed baseline instead of synthesizing changed hashes.

### CR-04: Advisory review state blocks deterministic evidence generation

**Classification:** BLOCKER

**File:** `/Users/jon/projects/rendro/dev/rendro/catalog.ex:1050-1077`

**Issue:** A changed target is placed in `changed_scored` only when its old rubric disposition is already `scored`; `valid_candidate_diff/1` then requires `changed_unscored: []`. Thus an intended target with no prior human score cannot even produce deterministic candidate evidence. This reverses the required lane order and violates the project contract that optional human feedback cannot block deterministic completion or explicit deferral.

**Fix:** Validate scope from bytes and target IDs independently of reviewer state: require `changed_scored ++ changed_unscored` (in canonical target order) to equal the target allowlist and require all controls to be byte-stable. Preserve the two buckets only as descriptive status. Add a test where one target has an unscored disposition and candidate generation still succeeds with that target marked review-required/unreviewed.

### CR-05: Sequential Payslip crashes on valid lines with omitted YTD

**Classification:** BLOCKER

**File:** `/Users/jon/projects/rendro/lib/rendro/recipes/payslip.ex:746-752,798-803`

**Issue:** Validation explicitly accepts an absent or nil `:ytd`, and the established paired layout renders it as blank. The new sequential profile instead dereferences `line.ytd` in both row construction and width measurement and passes it directly to the amount formatter. A valid line without the key raises `KeyError`; a present `ytd: nil` reaches an invalid formatter call.

**Fix:** Use `Map.get(line, :ytd)` and the existing `fmt_amount_or_blank/2` in both locations. Exclude blank tokens from width calculation or measure the empty string. Add sequential-profile tests for omitted and explicit-nil YTD and render both documents end to end.

### CR-06: Canonical rollback can delete the previously committed catalog

**Classification:** BLOCKER

**File:** `/Users/jon/projects/rendro/dev/rendro/catalog.ex:1131-1151`

**Issue:** The rollback branch unconditionally deletes `@asset_root` and `@manifest_path`, regardless of which preceding rename failed. If moving the existing asset root to its backup fails, rollback deletes the untouched original asset root. If the asset move succeeds but moving the manifest to backup fails, rollback deletes the untouched original manifest and has no manifest backup to restore. These error paths turn a publication failure into canonical data loss.

**Fix:** Track which moves completed and only delete newly installed targets or restore backups that were actually created. Prefer a small transactional helper with explicit states and checked rollback results. Add fault-injection tests for failure at each of the four rename steps and assert the original asset tree and manifest remain byte-identical.

### CR-07: Candidate manifest records a false baseline commit identity

**Classification:** BLOCKER

**File:** `/Users/jon/projects/rendro/dev/rendro/catalog.ex:297-306`

**Issue:** Candidate cells are compared with the previously committed canonical manifest, but `baseline_commit_sha` is set to the new candidate's `commit_sha`. Those are different evidence identities whenever a candidate changes any cell. The resulting manifest makes a false provenance claim precisely where operators need to distinguish baseline from candidate.

**Fix:** Persist a canonical generation/source commit in the canonical manifest and copy that independently validated value into candidate evidence. If the baseline commit cannot be established truthfully, omit or explicitly mark the field unsupported instead of assigning the candidate SHA. Add a test with distinct baseline and candidate SHAs.

## Warnings

### WR-01: Gallery download command is wrong for rerun attempts

**Classification:** WARNING

**File:** `/Users/jon/projects/rendro/.github/workflows/CATALOG-EVIDENCE.md:123-129`

**Issue:** The gallery artifact name hardcodes `attempt-1`, while the workflow names it with `github.run_attempt`. A successful rerun at attempt 2 or later cannot be downloaded with the documented command, and the docs contract currently locks in the wrong literal.

**Fix:** Introduce an explicit `RUN_ATTEMPT` placeholder (or obtain it from `gh run view`) and use `--attempt-${RUN_ATTEMPT}`. Update the docs contract to require the variable rather than `attempt-1`.

### WR-02: Malformed renderer pin crashes `build/4` outside its return contract

**Classification:** WARNING

**File:** `/Users/jon/projects/rendro/dev/rendro/catalog_evidence_bundle.ex:357-364`

**Issue:** `renderer/1` pattern-matches `{:ok, pin} = read_renderer_pin()`. A missing or malformed pin raises `MatchError`, even though `build/4` promises `:ok | {:error, [atom()]}` and the validator already has a structured `:invalid_renderer_pin` error.

**Fix:** Read and validate the pin in the `build/4` `with` chain, pass it into manifest writing, and return `{:error, [:invalid_renderer_pin]}`. Add missing-file, malformed-JSON, invalid-version, and invalid-digest tests.

---

_Reviewed: 2026-08-28T17:46:52Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
