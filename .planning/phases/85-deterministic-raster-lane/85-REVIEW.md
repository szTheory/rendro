---
phase: 85-deterministic-raster-lane
reviewed: 2026-06-11T15:25:00Z
depth: standard
files_reviewed: 14
files_reviewed_list:
  - .github/workflows/ci.yml
  - lib/rendro/adapters/pdfium.ex
  - lib/rendro/viewer_evidence/validator.ex
  - priv/guardrails/required_status_checks.json
  - priv/pdfium_pin.json
  - priv/raster_refs/forms_support_fixture/page_1.sha256
  - priv/schemas/support_matrix.schema.json
  - priv/support_matrix.json
  - scripts/verify_docs.exs
  - test/docs_contract/raster_claims_test.exs
  - test/guardrails/required_checks_contract_test.exs
  - test/rendro/adapters/pdfium_raster_snapshot_test.exs
  - test/rendro/adapters/pdfium_test.exs
  - test/test_helper.exs
findings:
  critical: 0
  warning: 0
  info: 0
  total: 0
status: clean
---

# Phase 85: Code Review Report

**Reviewed:** 2026-06-11T15:25:00Z
**Depth:** standard
**Status:** clean

## Summary

Phase 85 now has no open code-review findings.

The prior blockers from the initial 2026-06-10 review are closed:

- **CR-01 raster snapshot lane hollow:** Closed. `test/rendro/adapters/pdfium_raster_snapshot_test.exs` now reads `test/fixtures/forms_support_fixture.pdf`, calls `Pdfium.render/2`, asserts one PNG, and compares/blesses the rendered PNG through `assert_or_bless/2`. The committed ref at `priv/raster_refs/forms_support_fixture/page_1.sha256` backs `priv/support_matrix.json` raster evidence.
- **CR-02 pdfium-render allowed on GUI rows:** Closed. `priv/schemas/support_matrix.schema.json` and `lib/rendro/viewer_evidence/validator.ex` now restrict GUI-viewer row `viewer_kind` values to `manual`, `pdfium-cli`, and `pdfjs-dist`; `test/docs_contract/raster_claims_test.exs` mutates a real GUI row to prove schema and promotion validation reject `pdfium-render`.
- **Adapter warnings WR-01, WR-02, WR-05:** Closed. `Pdfium.render/2` validates page ranges before executable lookup, returns PNGs in numeric page order, and no longer deletes the private input path before opening it with `[:exclusive]`.
- **Snapshot env warning WR-03:** Closed. The bless-guard test restores prior `MIX_RASTER_BLESS` and `GITHUB_ACTIONS` values.

## Review Finding Remediated During This Gate

### Fixed: raster tmp-dir names were only unique within one BEAM VM

**File:** `lib/rendro/adapters/pdfium.ex`

**Issue:** `make_tmp_dir_for_raster/0` used `System.unique_integer/1` in `System.tmp_dir!()`. That is unique within one VM, but two separate Mix/BEAM processes can both create `rendro-raster-1`, causing `:eexist` or cross-process cleanup/mount races.

**Fix:** Commit `349dd2d` changes tmp-dir creation to use an 8-byte random hex suffix, `File.mkdir/1`, and bounded retry on `:eexist`.

**Verification:**

- `mix test test/rendro/adapters/pdfium_test.exs` - 5 tests, 0 failures.
- `PATH="/tmp/rendro-pdfium-shim:$PATH" MIX_RASTER_BLESS=false mix test --include raster_snapshot test/rendro/adapters/pdfium_raster_snapshot_test.exs` - 2 tests, 0 failures.

## Open Findings

None.

## Residual Risk

- The committed PNG hash was generated with the SHA-verified linux/amd64 `pdfium-cli v0.11.0` binary invoked through Docker from the local host. The raster bytes are from the pinned Linux binary, but GitHub Actions should still be allowed to exercise the same lane on `ubuntu-latest` after this branch is pushed.
- The advisory raster lane remains intentionally non-blocking (`continue-on-error: true` and advisory context only), so evidence drift surfaces without blocking required engine lanes.

## Recommendation

Proceed to phase-level verification.
