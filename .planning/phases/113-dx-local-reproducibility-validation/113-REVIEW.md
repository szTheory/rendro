---
phase: 113-dx-local-reproducibility-validation
reviewed: 2026-07-10T22:39:53Z
depth: standard
files_reviewed: 23
files_reviewed_list:
  - .github/workflows/ci.yml
  - CONTRIBUTING.md
  - README.md
  - lib/rendro/pdf/writer.ex
  - lib/rendro/pipeline/paginate.ex
  - lib/rendro/rules/check_ids.ex
  - mix.exs
  - test/docs_contract/pdfjs_advisory_claims_test.exs
  - test/guardrails/required_checks_contract_test.exs
  - test/mix/tasks/ci_alias_contract_test.exs
  - test/rendro/fragmentable_test.exs
  - test/rendro/integration/cross_references_integration_test.exs
  - test/rendro/integration/outlines_integration_test.exs
  - test/rendro/pdf/writer_test.exs
  - test/rendro/pipeline/measure_test.exs
  - test/rendro/pipeline/paginate_test.exs
  - test/rendro/recipes_facade_drift_test.exs
  - test/rendro/rules/check_ids_test.exs
  - test/support/docs_contract.ex
  - test/support/docs_contract_test.exs
  - test/support/hex_build_cache.ex
  - test/support/hex_build_cache_test.exs
  - test/test_helper.exs
findings:
  critical: 4
  warning: 0
  info: 0
  total: 4
status: resolved
resolved: 2026-07-10T22:51:26Z
---

# Phase 113: Code Review Report

**Reviewed:** 2026-07-10T22:39:53Z
**Depth:** standard
**Files Reviewed:** 23
**Status:** resolved

## Summary

Reviewed the Phase 113 DX/local reproducibility scope for CI semantics, Mix alias parity, validation guardrails, PDF anchor/outlines behavior, and supply-chain issues. The review found four critical issues; all four have been fixed and re-verified.

## Resolution

- CR-01 fixed by removing the job-level `matrix.primary` condition and moving PR secondary-version suppression to step-level conditions that `actionlint` accepts.
- CR-02 fixed by making `ci-success` depend only on `test` and `integration-proofs`, matching `priv/guardrails/required_status_checks.json`.
- CR-03 fixed by checksum-verifying `pdfium-cli` in `integration-proofs` and installing Python proof tooling through `scripts/proof_requirements.txt` with `--require-hashes`.
- CR-04 fixed by collecting nested table anchor/outline coordinates with cell offsets and converting author-space `/XYZ` destinations into PDF-space coordinates during serialization.

Verification after fixes:

- `actionlint .github/workflows/ci.yml`
- `mix test test/rendro/pdf/writer_test.exs test/rendro/pipeline/paginate_test.exs test/rendro/integration/cross_references_integration_test.exs test/guardrails/required_checks_contract_test.exs`
- `python3 -m venv /tmp/... && pip install --require-hashes -r scripts/proof_requirements.txt`

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Job-Level Matrix Condition Makes `ci.yml` Invalid

**File:** `.github/workflows/ci.yml:23`

**Issue:** The `test` job uses `matrix.primary` in a job-level `if`:

```yaml
if: github.event_name != 'pull_request' || matrix.primary == true
```

GitHub evaluates `jobs.<job_id>.if` before applying `strategy.matrix`, so the `matrix` context is unavailable there. Local `actionlint .github/workflows/ci.yml` confirms this with: `context "matrix" is not allowed here`. This can prevent the workflow from running, so the split CI gate is not a valid remote reproduction of the local aliases.

**Fix:** Remove the job-level matrix condition. Split the secondary version into its own job with a normal event-level guard, or allow the matrix to expand and keep matrix-dependent conditions only on steps:

```yaml
jobs:
  test:
    runs-on: ubuntu-latest
    # primary Elixir/OTP lane only

  test-secondary:
    if: github.event_name != 'pull_request'
    runs-on: ubuntu-latest
    # secondary Elixir/OTP lane
```

### CR-02: `ci-success` Makes an Advisory Example Job Part of the Required Gate

**File:** `.github/workflows/ci.yml:319`

**Issue:** `ci-success` depends on `example-phoenix`, and the `Pass`/`Enforce strict checks` steps fail the gate when any needed job fails or is cancelled. `example-phoenix` is not `continue-on-error`, while `priv/guardrails/required_status_checks.json` marks it as an advisory context and `mix ci` only runs `ci.fast` plus `ci.proofs`. This means local `mix ci` is not actually reproducing the required branch gate, and a supposedly non-required example-app failure can block `ci-success`.

**Fix:** If `example-phoenix` is advisory, remove it from `ci-success.needs` or explicitly exempt advisory job results from the strict check. If it is intended to be required, update `mix ci`, `CONTRIBUTING.md`, and the guardrail baseline/tests so local reproduction includes the example app.

```yaml
ci-success:
  if: always()
  needs: [test, integration-proofs]
```

### CR-03: Required Proof CI Installs Mutable External Tools Without Integrity Pinning

**File:** `.github/workflows/ci.yml:258`

**Issue:** The required `integration-proofs` job downloads and executes `pdfium-cli` with `curl`, `chmod +x`, and `sudo mv` but does not verify a checksum. The same job also installs `certomancer`, `pyHanko`, and `pyHanko-cli` from PyPI without version or hash pins at line 268. This is both a supply-chain gap and a reproducibility gap in the required merge proof lane.

**Fix:** Mirror the pinned advisory install pattern for `pdfium-cli`, and install Python proof tooling from a committed lock/requirements file with exact versions and hashes.

```yaml
- name: Install pdfium-cli (pinned)
  run: |
    EXPECTED_SHA256="<sha256-for-selected-asset>"
    curl -fsSL -o pdfium-cli "https://github.com/klippa-app/pdfium-cli/releases/download/v0.10.3/pdfium-webassembly-linux-amd64"
    echo "${EXPECTED_SHA256}  pdfium-cli" | sha256sum --check
    chmod +x pdfium-cli
    sudo mv pdfium-cli /usr/local/bin/pdfium-cli

- name: Install Python Dependencies
  run: |
    python3 -m pip install --upgrade pip
    python3 -m pip install --require-hashes -r scripts/proof_requirements.txt
```

### CR-04: Anchor and Outline Destinations Serialize Author Coordinates, Not PDF Coordinates

**File:** `lib/rendro/pipeline/paginate.ex:141`

**Issue:** Anchor and outline destinations are collected as `[page_idx, :XYZ, block.x, block.y, nil]` using author-space coordinates. `Rendro.PDF.Writer` then serializes those values directly into `/Dest` arrays at `lib/rendro/pdf/writer.ex:1036` and `lib/rendro/pdf/writer.ex:2550`. The rest of the writer converts author-space blocks into PDF user space by adding margins and flipping Y, so internal links/outlines point to the wrong physical location. Nested table anchors are worse: `collect_row_anchors/3` drops the stacked cell `x/y` and records only the nested block's local `x/y` (`lib/rendro/pipeline/paginate.ex:163-175`), which the test currently codifies at `test/rendro/pipeline/paginate_test.exs:1531-1534`.

**Fix:** Store final page-space/PDF-space destinations after table cells have been stacked, including cell offsets and page margins. Either collect PDF coordinates directly in pagination or convert in the writer using the target page dimensions and margins. Then update the cross-reference and outline integration tests to assert the converted destination coordinates rather than raw authored `x/y`.

```elixir
pdf_x = page.margin_left + page_x
pdf_y = page.height - (page.margin_top + page_y)
Map.put(acc, id, [page_idx, :XYZ, pdf_x, pdf_y, nil])
```

---

_Reviewed: 2026-07-10T22:39:53Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
