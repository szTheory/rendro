---
phase: 135-test-ci-cd-simplification
reviewed: 2026-08-27T22:30:00Z
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
  - .planning/phases/135-test-ci-cd-simplification/135-REVIEW-3.md
findings:
  critical: 0
  warning: 1
  info: 0
  total: 1
status: issues_found
---

# Phase 135: Code Review Report — Iteration 4

**Reviewed:** 2026-08-27T22:30:00Z
**Depth:** deep, clean-room re-review at `e70b7c9`
**Files Reviewed:** 12
**Status:** issues_found

## Summary

All findings from reviews 1–3 are resolved in the current implementation. The candidate and control execution boundary is separated and default-branch-bound; bundle payload counts are validated from records; route-specific parity normalization is implemented; sealed route-side candidate identities are bound to the root candidate; and the inventory test compares all 16 cells to the typed sealed-record projection, including ordered artifact arrays and `reviewer_required`.

Focused verification passed: 43 tests across the Phase 135 bundle, parity, inventory, workflow guardrail, and runbook contracts; `actionlint .github/workflows/catalog-evidence.yml` also passed.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01 [WARNING]: Malformed retained evidence raises instead of failing closed

**File:** `dev/rendro/catalog_evidence_parity.ex:199-201, 437-447`
**Issue:** The extractor and sealed-record validator accept externally supplied decoded maps, but they access record fields before proving that each list member is a map. For example, replacing a retained route role with `[42]` causes `verify_record/2` to raise `FunctionClauseError` in `Access.get/3` through `Enum.uniq_by(records, & &1["id"])` (line 440), rather than returning its declared `{:error, [...]}` result. Likewise, a JSON payload whose `images` array contains a scalar crashes at line 200. This violates the module's documented fail-closed evidence boundary and makes malformed artifacts abort an operator validation run.

**Fix:** Validate the shape of every list member before field access, then perform duplicate and cardinality checks. For example:

```elixir
defp valid_records?(records) when is_list(records) and records != [] do
  Enum.all?(records, &valid_record_entry?/1) and
    length(Enum.uniq_by(records, & &1["id"])) == length(records)
end

defp valid_records?(_), do: false

defp valid_record_entry?(%{"id" => id, "sha256" => sha}),
  do: is_binary(id) and id != "" and is_binary(sha) and Regex.match?(@sha, sha)
defp valid_record_entry?(_), do: false
```

Make `json_role/3` similarly reject non-map entries before reading `id`/`sha256`, and add malformed scalar-entry tests for both raw-root comparison and `verify_record/2`.

---

_Reviewed: 2026-08-27T22:30:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: deep_
