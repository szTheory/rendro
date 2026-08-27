---
phase: 135-test-ci-cd-simplification
reviewed: 2026-08-27T21:10:00Z
depth: deep
files_reviewed: 10
files_reviewed_list:
  - .github/workflows/catalog-evidence.yml
  - .github/workflows/CATALOG-EVIDENCE.md
  - dev/rendro/catalog_evidence_bundle.ex
  - dev/rendro/catalog_evidence_parity.ex
  - test/guardrails/required_checks_contract_test.exs
  - test/rendro/catalog_evidence_bundle_test.exs
  - test/rendro/catalog_evidence_parity_test.exs
  - test/docs_contract/phase_135_test_inventory_contract_test.exs
  - .planning/phases/135-test-ci-cd-simplification/135-test-inventory.md
  - .planning/phases/135-test-ci-cd-simplification/135-parity-comparator-record.json
findings:
  critical: 3
  warning: 1
  info: 0
  total: 4
status: issues_found
---

# Phase 135: Code Review Report — Iteration 2

**Reviewed:** 2026-08-27T21:10:00Z
**Depth:** deep, focused re-review of CR-01 through CR-04 and WR-01
**Files Reviewed:** 10
**Status:** issues_found

## Summary

CR-02 is fixed: every closed bundle role now has an exact expected count, and both build and validation derive it from the payload records. The candidate and control jobs no longer share a runner, but CR-01 remains open because the purported control workflow is not bound to the default branch. CR-03 and CR-04 also remain open: the comparator accepts pre-normalized caller data instead of extracting legacy/generic layouts, while the retained record is neither a typed transport contract nor a reproducible derivation of the inventory statuses. The SHA interpolation in the dispatch commands is fixed, but the runbook's control-plane description is now stale.

Focused verification passed: `mix test test/rendro/catalog_evidence_bundle_test.exs test/rendro/catalog_evidence_parity_test.exs test/docs_contract/phase_135_test_inventory_contract_test.exs test/guardrails/required_checks_contract_test.exs test/docs_contract/catalog_evidence_runbook_test.exs --max-failures 1` (39 tests) and `actionlint .github/workflows/catalog-evidence.yml`.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01 [BLOCKER]: The control-plane workflow is still selected from the dispatch ref, not the trusted default branch

**File:** `.github/workflows/catalog-evidence.yml:88-97`
**Issue:** The control job defines `CONTROL_SHA` as `${{ github.sha }}` and checks out that same value. A `workflow_dispatch` run may be started against a selected ref; no condition or immutable lookup requires that ref/SHA to be the repository default branch. Therefore a candidate-controlled branch can supply the workflow definition and the `dev/rendro/catalog_evidence_bundle.ex` control helper that this job executes. Splitting candidate generation and packaging into separate runners prevents shared-filesystem attacks, but does not establish the required untrusted-candidate/trusted-default-control boundary.

**Fix:** Make dispatch select only a trusted default-branch workflow/control commit, then obtain and verify that default-branch commit through a trusted mechanism before running the helper. Reject any run whose workflow ref is not the default branch, and use the verified default-branch SHA for the control checkout. Add a guardrail fixture proving a non-default dispatch ref cannot become `CONTROL_SHA`. Preserve the separate artifact handoff and additionally allowlist the downloaded handoff's fixed regular files before consuming it, rejecting extra entries and symlinks.

### CR-03 [BLOCKER]: Route schemas are not route-specific legacy/generic extraction or normalization

**File:** `dev/rendro/catalog_evidence_parity.ex:20-35`
**Issue:** `compare/3` receives two already-shaped maps and only verifies that their caller-provided `payloads` list matches a route schema (lines 123-128). It never opens a legacy archive/manifest or generic bundle, maps legacy names/layouts into semantic roles, computes SHA-256 values, or applies a route-specific extractor. The tests confirm this limitation: they construct identical synthetic maps for each side (test lines 77-126), not retained Phase 126/127/130 layouts. In particular, the Phase 126 six-preset legacy set cannot be normalized and compared with the selected six presets from the generic 12-preset role, and Phase 127/130 legacy naming/layout differences have no executable normalization.

**Fix:** Change the boundary to accept retained artifact roots (or parsed raw artifact records with source paths), implement one explicit extractor/normalizer per route, and compute the normalized role/id/hash/count values from file bytes. Define Phase 126 as the selected six IDs from the generic 12-record preset payload, and define the Phase 127 and Phase 130 legacy-to-generic name/layout mappings explicitly. Test each route with its real retained layout plus negative controls for a renamed, missing, extra, and hash-changed record.

### CR-04 [BLOCKER]: The durable record cannot reproduce or substantiate the matrix's parity statuses

**File:** `.planning/phases/135-test-ci-cd-simplification/135-parity-comparator-record.json:4-21`
**Issue:** The record retains only a run-ID-to-archive-digest map and four untyped status/reason strings. It has no per-route legacy/generic run URL, attempt, artifact identity, renderer facts, action/permission facts, raw/normalized role records, or comparator input/output. Consequently it cannot validate the typed transport facts or reproducibly derive a route's `matched`/`mismatch` status. It also directly contradicts the inventory: the inventory declares `phase127_catalog_review` and `phase130_review` `matched`, while this record says both are `mismatch` (lines 18-19). The current docs-contract test only checks row order, status vocabulary, and a shared candidate string (test lines 25-32), so it does not stop this contradiction.

**Fix:** Define a versioned durable comparator-record schema keyed by route. For each side retain and validate typed run URL/ID/attempt, artifact identity, upload digest, candidate/HEAD, renderer, control facts, and normalized semantic evidence. Record the comparator's deterministic output and reasons derived from those retained normalized records; reject an inventory row unless its status and normalized digest exactly agree with that route record. Add mutation tests for every transport fact, each normalized role/count/hash, a falsified status, and an inventory/record disagreement. Do not retire legacy routes until all four route records reproduce `matched`.

## Warnings

### WR-01 [WARNING]: Runbook still describes a superseded two-tree control model and promises absent transport facts

**File:** `.github/workflows/CATALOG-EVIDENCE.md:7-10, 96-97, 118-120`
**Issue:** The runbook says the job checks out two separate trees and packages candidate output in the control tree. The revised workflow instead runs candidate generation and control packaging in distinct jobs/runners with an artifact handoff. It also tells operators that the summary/manifest contain an Artifact URL and Archive digest, but the revised workflow removed the summary step and does not place those transport values in the manifest. The SHA dispatch expansion and candidate-vs-HEAD identity sentence are corrected, but this stale identity/transport microcopy violates the project's documentation-as-contract convention.

**Fix:** Describe the actual two-job, artifact-only handoff; explain that the candidate and control runners are separate; and either restore a post-upload summary with the upload outputs or remove the claim and document the supported retrieval path. Extend the docs contract to pin this job topology and the actual location of each promised transport fact.

---

_Reviewed: 2026-08-27T21:10:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: deep, focused re-review_
