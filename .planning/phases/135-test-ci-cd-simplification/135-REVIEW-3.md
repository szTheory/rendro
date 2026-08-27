---
phase: 135-test-ci-cd-simplification
reviewed: 2026-08-27T21:11:37Z
depth: deep
files_reviewed: 12
files_reviewed_list:
  - .github/workflows/catalog-evidence.yml
  - .github/workflows/CATALOG-EVIDENCE.md
  - dev/rendro/catalog_evidence_bundle.ex
  - dev/rendro/catalog_evidence_parity.ex
  - test/rendro/catalog_evidence_bundle_test.exs
  - test/rendro/catalog_evidence_parity_test.exs
  - test/docs_contract/phase_135_test_inventory_contract_test.exs
  - test/guardrails/required_checks_contract_test.exs
  - test/docs_contract/catalog_evidence_runbook_test.exs
  - .planning/phases/135-test-ci-cd-simplification/135-parity-comparator-record.json
  - .planning/phases/135-test-ci-cd-simplification/135-test-inventory.md
  - .planning/phases/135-test-ci-cd-simplification/135-REVIEW-2.md
findings:
  critical: 1
  warning: 0
  info: 0
  total: 1
status: issues_found
---

# Phase 135: Code Review Report — Iteration 3

**Reviewed:** 2026-08-27T21:11:37Z
**Depth:** deep, final focused re-review through `db58fa9`
**Files Reviewed:** 12
**Status:** issues_found

## Summary

The prior workflow-boundary findings are resolved: the control job is limited to a default-branch dispatch, checks out the dispatch SHA immutably, and validates a bounded regular-file-only handoff from a separate candidate runner. Exact bundle counts are derived from payloads, the extractors encode the requested route shapes, and the runbook now describes the two-job topology and the artifact API digest path.

One blocker remains in the retired-route evidence contract. Schema-v2 accepts valid-looking but unrelated per-side provenance, while the inventory contract verifies only the final status column. A stale or fabricated candidate identity and transport facts can therefore coexist with a `matched` route and an apparently authoritative inventory.

Focused verification passed:

- `mix test test/rendro/catalog_evidence_bundle_test.exs test/rendro/catalog_evidence_parity_test.exs test/docs_contract/phase_135_test_inventory_contract_test.exs test/guardrails/required_checks_contract_test.exs test/docs_contract/catalog_evidence_runbook_test.exs --max-failures 1` — 38 tests, 0 failures.
- `actionlint .github/workflows/catalog-evidence.yml` — passed.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01 [BLOCKER]: Sealed parity provenance and inventory facts are not bound to the compared candidate

**File:** `dev/rendro/catalog_evidence_parity.ex:36-45, 242-257`; `test/docs_contract/phase_135_test_inventory_contract_test.exs:26-41`

**Issue:** `verify_record/2` validates each transport field only by shape. It never requires a route side's `transport.candidate_sha` to equal the top-level sealed `transport.candidate_sha`, its opposing side's candidate SHA, or the candidate SHA represented in the inventory row. The inventory test in turn checks only that its candidate-SHA cells are all equal and that its status cells equal the record status; it does not derive and compare the URLs, runs/attempts, artifact identities, archive digests, renderer, checkout/permission facts, or normalized role/count/hash cells from the schema-v2 record.

This is executable, not hypothetical: changing only `routes.phase127_catalog_review.legacy.transport.candidate_sha` to another syntactically valid 40-character SHA still returns `{:ok, ...}` and `matched` from `verify_record/2`. Likewise, replacing every inventory candidate SHA with the same unrelated SHA, or falsifying its transport/normalization text, still passes the current inventory contract. The record can consequently claim parity for artifacts from different candidates and the committed inventory can display false provenance while retaining a mechanically derived content status. That violates the phase's typed per-side provenance, inventory-consistency, and mutation-resistance requirements.

**Fix:** Make the sealed record use one canonical candidate identity and enforce it in `verify_record/2`: require the root transport and both sides of every route to carry exactly that SHA (and, where intended, bind run/artifact references to their route-side transport). Expose a canonical serializer/digest for each route's normalized roles and transport facts. Update the inventory contract to parse each row and require every column to equal the corresponding typed record fact and derived normalized digest, rather than comparing only status. Add negative tests that mutate one route-side candidate SHA and each inventory provenance/normalization column; each must fail validation.

---

_Reviewed: 2026-08-27T21:11:37Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: deep_
