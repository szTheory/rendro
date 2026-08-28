---
phase: 136-catalog-visual-quality
reviewed: 2026-08-27T00:00:00-04:00
depth: standard
files_reviewed: 20
files_reviewed_list:
  - .github/workflows/CATALOG-EVIDENCE.md
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
  critical: 1
  warning: 0
  info: 0
  total: 1
status: issues_found
---

# Phase 136: Code Review Report

**Reviewed:** 2026-08-27T00:00:00-04:00
**Depth:** standard
**Files Reviewed:** 20
**Status:** issues_found

## Summary

The profile threading and recipe changes preserve the intended dev-only identity boundary, and the targeted test set passes (304 tests). However, the newly emphasized evidence-validation lane does not validate the trusted control or PDFium-pin identities it tells operators to rely on. A self-consistent but forged bundle can therefore validate and be reviewed as exact evidence.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Evidence validation accepts forged control and renderer provenance

**Classification:** BLOCKER

**File:** `dev/rendro/catalog_evidence_bundle.ex:156-166`

**Issue:** `validate_manifest/2` only checks that `control.workflow_sha` has SHA syntax and that the renderer has a syntactically valid version, digest, and positive DPI. It never compares the control SHA to a caller-supplied/trusted control identity (or the checkout actually running the validator), and `valid_renderer?/1` at lines 261-264 never compares version/digest to `priv/pdfium_pin.json`. Checksums prove only that the bundle is internally self-consistent: an attacker or stale/misrouted artifact can change its control SHA and renderer values, recompute `checksums.sha256`, and still receive `:ok`.

The new runbook makes this exploitable operationally: it directs reviewers to run this validator before interpreting images and even supplies `git checkout --detach CONTROL_SHA` from the bundle-derived control identity at `.github/workflows/CATALOG-EVIDENCE.md:79-91`. That creates a circular trust chain rather than verifying the control-plane checkout and pinned PDFium executable promised by the Phase 136 evidence contract.

**Fix:** Make trusted identities explicit validator inputs (or derive the control SHA from a pre-established trusted checkout), reject a control SHA that differs from that value or from the actual detached `HEAD`, and compare renderer version/digest to the trusted checkout's `priv/pdfium_pin.json`. Do not source the checkout revision from the downloaded bundle. Add negative tests that mutate the control SHA and renderer version/digest while recomputing all bundle checksums, and assert validation fails.

```elixir
def validate(output_root, operation, expected_control_sha) do
  pin = "priv/pdfium_pin.json" |> File.read!() |> JSON.decode!()

  with {:ok, manifest} <- read_manifest(output_root),
       :ok <- validate_manifest(operation, manifest, expected_control_sha, pin),
       :ok <- validate_files(output_root, manifest),
       :ok <- validate_checksums(output_root, manifest) do
    :ok
  end
end

# validate_manifest must require:
# manifest["control"]["workflow_sha"] == expected_control_sha
# manifest["renderer"]["version"] == pin["version"]
# manifest["renderer"]["binary_sha256"] == pin["sha256"]
```

---

_Reviewed: 2026-08-27T00:00:00-04:00_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
