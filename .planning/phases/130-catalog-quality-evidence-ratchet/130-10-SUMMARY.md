---
phase: 130-catalog-quality-evidence-ratchet
plan: "10"
subsystem: catalog-quality-evidence
tags: [catalog, pdfium, provenance, quality]
requires: [130-05, 130-06]
provides: [candidate-identical-canonical-catalog, truthful-quality-projection]
affects: [130-11, 131]
tech-stack:
  added: []
  patterns: [exact-SHA CI canonical writer, artifact identity verification]
key-files:
  created: [.planning/phases/130-catalog-quality-evidence-ratchet/130-10-SUMMARY.md]
  modified: [assets/rendro/catalog, assets/rendro/catalog.json]
decisions:
  - "The sole successful canonical writer ran in the approved pinned-PDFium CI lane; local publication only materialized its verified artifact."
metrics:
  failed_attempt_count: 1
  successful_generation_count: 1
  generation_count: 1
  tasks: 2
status: complete
---

# Phase 130 Plan 10: Canonical Catalog Publication Summary

## Result

- `failed_attempt_count: 1` — the macOS invocation exited before staging/publication because `pdfium-cli` was unavailable.
- `successful_generation_count: 1`
- `generation_count: 1`
- Canonical writer: GitHub Actions run `32434769523`, advisory job `advisory-checks`, exact-SHA ref `gsd/phase-130-catalog-canonical-002d42adfec74a1f2fd2ba824d1623fb33c92891`.
- Renderer: `pdfium-cli` `v0.11.0`, SHA-256 `b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a`.

## Reproduction Evidence

- The CI route accepted only a branch suffix equal to `GITHUB_SHA`, verified the installed executable digest, ran `mix rendro.catalog.gen` once, then passed `mix rendro.catalog.check`.
- Its bounded artifact contains `assets/rendro/catalog.json` and exactly 32 PNGs. All 33 artifact checksum entries verify.
- Candidate and canonical manifests have identical literal 32-cell order, IDs, renderer pin/version, PNG hashes, source-PDF hashes, safe paths, dimensions, and page counts.
- All 12 scored projections exactly match the current reviewer-owned rubric; its Task 1 SHA-256 remains `ba175666b656ad17a5967043f50945595c3a50bc9a6669517ba42a8e3eb660d6`.
- Local publication copied only this verified artifact through the canonical staging paths and one backup-and-rollback transaction; it did not invoke any renderer. The published files are byte-identical to the artifact.

## Verification

- `mix rendro.catalog.check` — pass (`Catalog VERIFIED`)
- Focused catalog, quality, and rubric contracts — pass (95 tests, 0 failures)
- Human reviewer files `priv/quality/rubric_scores.json` and `priv/quality/SIGN-OFF.md` — unchanged

## Unrelated CI State

The whole CI run remains red for pre-existing repository conditions: formatting drift in `test/docs_contract/rubric_manifest_contract_test.exs` and an unsupported OTP 25 / Elixir 1.19.0 matrix pairing. The graph-disconnected canonical advisory steps all passed.

## Deviations from Plan

**1. [Rule 3 - Blocking environment] Routed the sole successful writer through the approved CI PDFium lane.**
- **Found during:** Task 2
- **Issue:** The approved executable is Linux-only and absent on the macOS checkout; the local invocation failed before staging or publication.
- **Fix:** Validated the exact-SHA CI artifact after its single canonical writer run, then materialized only its verified contents through the canonical staging/rollback boundary.
- **Verification:** 33 checksums, literal 32-cell identity equality, `mix rendro.catalog.check`, and 95 focused tests passed.

## Known Stubs

None.

## Self-Check: PASSED

- All 32 catalog cells are present, uniquely ordered, and pass the catalog check.
- Task commits `265369a`, `047d04c`, and the canonical publication commit are present.
