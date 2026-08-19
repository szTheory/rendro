---
phase: 127-public-example-catalog-quality-ratchet
plan: 05
subsystem: catalog-quality-closure
tags: [catalog, rubric, pdfium, provenance, validation]
requires:
  - phase: 127-04
    provides: twelve bounded human review records and multipage observations
provides:
  - twelve hash-bound scored-false flagship dispositions
  - truthful 32-cell public quality projection
  - completed deterministic/advisory closure and removed evidence refs
affects: [128, 129]
tech-stack:
  added: []
  patterns: [reviewer-owned dispositions, derived three-state projection, pinned advisory provenance]
key-files:
  created: [.planning/phases/127-public-example-catalog-quality-ratchet/127-05-SUMMARY.md]
  modified: [priv/quality/rubric_scores.json, priv/quality/SIGN-OFF.md, assets/rendro/catalog.json, test/docs_contract/rubric_manifest_contract_test.exs, .planning/phases/127-public-example-catalog-quality-ratchet/127-VALIDATION.md]
key-decisions:
  - "Keep all twelve provisional human verdicts false and project them as needs_work."
  - "Use the exact SHA-verified Linux PDFium advisory job rather than treating a macOS ARM execution failure as equivalent evidence."
  - "Delete all nine Phase 127 isolated evidence refs only after full-SHA verification and advisory closure."
requirements-completed: [CATALOG-01, CATALOG-02, CATALOG-03, CATALOG-04]
duration: 30m
completed: 2026-08-18
status: complete
---

# Phase 127 Plan 05: Quality Ratchet Closure Summary

The public 32-cell catalog now truthfully distinguishes twelve scored-but-needs-work flagships from twenty explicitly unscored cells, with all evidence identity and advisory provenance closed.

## Accomplishments

- Transcribed the twelve committed Plan 04 human records verbatim in substance, preserving their exact PNG/PDF identities, `passed: false` outcomes, and bounded justifications.
- Left all six legacy `scores[]` entries and all twenty reasoned-unscored catalog records unchanged.
- Regenerated the derived public projection semantics: 12 `needs_work`, 20 `unscored`, and no `passes`; rubric detail remains private.
- Added a checked-in contract asserting the 12/20 split, per-record threshold recomputation, canonical registry-order projection, and `needs_work` label.
- Completed the validation map and proved 32 PNGs, no public PDFs/trailing PNGs, exact D-10 preview copy, exact D-25 dark/null-light disclosures, package/core isolation, and truthful scope boundaries.

## Verification

- Focused catalog/manifest/quality/guardrail suite: 106 tests, 0 failures.
- Full deterministic suite: 1,779 tests, 0 failures (28 excluded).
- `mix ci.fast`: 1,779 tests, 0 failures; Credo found no issues; Dialyzer reported 0 errors; Hex build completed.
- Static catalog join, exact 32/12/20 cardinalities, D-10, D-25, asset absence, and public-API/package-boundary audits: passed.
- Exact pinned advisory evidence: [run 32088308311](https://github.com/szTheory/rendro/actions/runs/32088308311), [advisory job 95565301370](https://github.com/szTheory/rendro/actions/runs/32088308311/job/95565301370), successful. It installed PDFium `v0.11.0` with SHA-256 `b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a`, generated/reviewed/staged the 32/16 evidence payload, and passed `mix rendro.catalog.check`.

The overall remote workflow is red only from pre-existing unrelated jobs: its Elixir 1.19.0/OTP 25 matrix setup is incompatible, and the separate dependency audit failed. The required OTP 28/Elixir 1.19.5 test job and the catalog advisory job both passed; no catalog evidence is inferred from the aggregate workflow result.

## Evidence Ref Cleanup

Each ref was re-resolved to its recorded full SHA before deletion, then `git ls-remote --exit-code --heads` proved it absent. The final wildcard query returned zero Phase 127 catalog-bless refs.

| Ref | Verified SHA | Run | Result |
|---|---|---:|---|
| `gsd/phase-127-catalog-bless-f24f19f32dc3` | `f24f19f32dc3717ab92dcd1f6a6325a437b4848c` | 32079289456 | deleted, absent |
| `gsd/phase-127-catalog-bless-9f2d2551d699` | `9f2d2551d699d9af7762b283b8bb87e68da0b893` | 32079891632 | deleted, absent |
| `gsd/phase-127-catalog-bless-4394c8ee75ac` | `4394c8ee75ac1f59b39a18a90b8779988083daad` | 32080463323 | deleted, absent |
| `gsd/phase-127-catalog-bless-3016cd1f5f17` | `3016cd1f5f1758384803e08515d40e56a9afecc0` | 32082280090 | deleted, absent |
| `gsd/phase-127-catalog-bless-1d872e4df1db` | `1d872e4df1dbc0b61cc16ccc57b442ff6374f234` | 32082874361 | deleted, absent |
| `gsd/phase-127-catalog-bless-16818db494e0` | `16818db494e00c3b2d9a2c5b7820f1b3ed7d5c93` | 32083414414 | deleted, absent |
| `gsd/phase-127-catalog-bless-9479ee24801d` | `9479ee24801db5e9075705a88da66737fd55fc3d` | 32083898604 | deleted, absent |
| `gsd/phase-127-catalog-bless-2f8d20303ffe` | `2f8d20303ffe7999688e3320b9d38a486bd9db95` | 32084695699 | deleted, absent |
| `gsd/phase-127-catalog-bless-40a2576a3629` | `40a2576a3629d8bd6d92717e7e482fa45edb5fd7` | 32088308311 | deleted, absent |

## Decisions Made

- A completed human review is not approval: every flagship remains visible as `Scored — needs work`.
- Dark preview boundary language remains mode-derived and independent from the quality projection.
- The PDFium lane is advisory and hash-pinned; it does not broaden the catalog into a PDF viewer, print, accessibility, PDF/UA, WCAG, or production-readiness claim.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking environment] Used the existing exact-SHA GitHub advisory lane for PDFium verification.**
- **Found during:** Task 1/2
- **Issue:** The project pin is a Linux amd64 executable and cannot execute on this macOS ARM host; Linux/amd64 Erlang emulation also could not initialize its terminal driver.
- **Fix:** Verified the binary SHA locally, then ran the repository's isolated pinned advisory workflow and accepted only its successful exact-renderer job.
- **Files modified:** None for this environment-only routing.
- **Commit:** `40a2576`

## Known Stubs

None.

## Self-Check: PASSED

- Task commit `40a2576` exists and all listed changed files exist.
- The completed validation record exists with `nyquist_compliant: true`.
- The nine recorded remote evidence refs are absent after deletion.
