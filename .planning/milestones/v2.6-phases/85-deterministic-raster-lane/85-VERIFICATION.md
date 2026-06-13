---
phase: 85-deterministic-raster-lane
verified: 2026-06-11T15:30:00Z
status: passed
score: 9/9 must-haves verified
gaps: []
human_verification: []
requirements:
  RAST-01: passed
  RAST-02: passed
  RAST-03: passed
---

# Phase 85: Deterministic Raster Lane — Verification Report

**Phase Goal:** Deterministic Raster Lane — `Pdfium.render/2`, golden-PNG snapshot harness, advisory CI lane, honest `pdfium-render` evidence vocabulary.
**Verified:** 2026-06-11T15:30:00Z
**Status:** passed
**Re-verification:** Yes — gap closure plans 85-05 and 85-06 executed.

## Goal Achievement

All nine observable truths are verified.

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `Pdfium.render/2` exists, accepts PDF binary + opts, and returns PNG binaries or error tuples. | VERIFIED | `lib/rendro/adapters/pdfium.ex` implements `render/2`; `mix test test/rendro/adapters/pdfium_test.exs` passes. |
| 2 | Missing pdfium executable returns `{:error, {:missing_executable, "pdfium-cli"}}`. | VERIFIED | `test/rendro/adapters/pdfium_test.exs` covers the missing executable path. |
| 3 | Snapshot harness exercises `Pdfium.render/2` with a real fixture PDF. | VERIFIED | `test/rendro/adapters/pdfium_raster_snapshot_test.exs` reads `test/fixtures/forms_support_fixture.pdf`, calls `Pdfium.render(pdf, dpi: 150, pages: "1")`, and passes the rendered PNG to `assert_or_bless/2`. |
| 4 | `raster-advisory` CI job is graph-disconnected, non-blocking, and sha256-pinned. | VERIFIED | `.github/workflows/ci.yml` has no `needs:` for `raster-advisory`, uses `continue-on-error: true`, downloads pdfium-cli v0.11.0, and verifies SHA-256. |
| 5 | `raster-advisory` is advisory-only and absent from required contexts. | VERIFIED | `priv/guardrails/required_status_checks.json`; `raster_claims_test.exs` asserts absence from `required_contexts` and presence in `advisory_contexts`. |
| 6 | `viewer_kind: "pdfium-render"` remains a distinct top-level raster evidence vocabulary value. | VERIFIED | `priv/support_matrix.json` top-level `raster.evidence.viewer_kind` remains `pdfium-render`. |
| 7 | GUI-viewer rows do not carry `pdfium-render`. | VERIFIED | Existing parsed JSON docs-contract guard remains active and green. |
| 8 | Schema and promotion validator structurally reject `pdfium-render` on GUI-viewer rows. | VERIFIED | `support_matrix.schema.json` enum and `@viewer_kinds` exclude `pdfium-render`; mutation test proves schema and validator reject a real `forms.viewers.adobe_acrobat_reader` row changed to `pdfium-render`. |
| 9 | `byte_deterministic_on_pinned_container: "supported"` is backed by an executing assertion. | VERIFIED | `priv/raster_refs/forms_support_fixture/page_1.sha256` is committed; included raster snapshot test passes in non-bless mode and fails when the ref is temporarily removed; matrix `png_sha256` equals the committed ref. |

## Required Artifacts

| Artifact | Status | Details |
|----------|--------|---------|
| `lib/rendro/adapters/pdfium.ex` | VERIFIED | `render/2` validates DPI/pages, writes private temp input, invokes list-form pdfium args, sorts PNGs by page number, and uses random temp dir suffixes with bounded collision retry. |
| `test/rendro/adapters/pdfium_raster_snapshot_test.exs` | VERIFIED | Real render-backed snapshot proof; empty PNG lists fail; bless guard restores env vars. |
| `priv/raster_refs/forms_support_fixture/page_1.sha256` | VERIFIED | Contains one lowercase SHA-256 digest: `73e33ed6c6d68e461b4317f0551f9ae8f8225b28cf7e0eebcf88fa45d09b8deb`. |
| `priv/support_matrix.json` | VERIFIED | Raster evidence includes `fixture`, `ref`, and `png_sha256` matching the committed ref. |
| `priv/schemas/support_matrix.schema.json` | VERIFIED | GUI-viewer row enum is exactly `["manual", "pdfium-cli", "pdfjs-dist"]`. |
| `lib/rendro/viewer_evidence/validator.ex` | VERIFIED | `@viewer_kinds` is exactly `~w(manual pdfium-cli pdfjs-dist)`. |
| `.github/workflows/ci.yml` | VERIFIED | Advisory raster lane remains non-blocking and installs the pinned pdfium binary. |
| `scripts/verify_docs.exs` | VERIFIED | Raster claims lane is registered and passes through the full docs-contract script. |

## Requirement Coverage

| Requirement | Status | Evidence |
|-------------|--------|----------|
| RAST-01 | PASSED | `Pdfium.render/2` exists, is unit-tested, validates page ranges before command execution, and returns PNGs in numeric page order. |
| RAST-02 | PASSED | Render-backed golden snapshot test exists, committed ref exists, non-bless raster snapshot passes with the ref and fails without it, and CI lane remains advisory-only. |
| RAST-03 | PASSED | `pdfium-render` is top-level raster evidence only; schema, validator, and docs-contract mutation tests prevent GUI-viewer row promotion with engine-only evidence. |

## Verification Commands

All commands passed unless explicitly noted as an expected negative check:

- `mix test test/docs_contract/raster_claims_test.exs test/docs_contract/viewer_evidence_claims_test.exs test/rendro/adapters/pdfium_test.exs` — 34 tests, 0 failures.
- `PATH="/tmp/rendro-pdfium-shim:$PATH" MIX_RASTER_BLESS=false mix test --include raster_snapshot test/rendro/adapters/pdfium_raster_snapshot_test.exs` — 2 tests, 0 failures.
- Missing-ref negative check — temporarily moved `priv/raster_refs/forms_support_fixture/page_1.sha256`; non-bless raster snapshot failed with `File.Error`, then the ref was restored.
- `mix test` — 12 doctests, 4 properties, 1086 tests, 0 failures, 11 excluded.
- `mix run scripts/verify_docs.exs` — all 15 docs-contract lanes passed, including Raster claims lane.
- `gsd-sdk query verify.schema-drift 85` — `drift_detected: false`.
- `gsd-sdk query verify.codebase-drift 85` — skipped, no structural map configured.

## Notes

The committed PNG hash was generated by running the actual ExUnit snapshot test with a temporary `pdfium-cli` shim. The shim invoked the SHA-verified linux/amd64 `pdfium-cli v0.11.0` binary inside Docker for the render command, so the raster bytes came from the pinned Linux binary while `Pdfium.render/2` remained the code path under test.

## Gaps

None.

## Human Verification Required

None.

---
_Verified: 2026-06-11T15:30:00Z_
_Verifier: Codex (inline execute-phase verifier)_
