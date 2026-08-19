---
phase: 126-carryover-polish-dark-mode-legibility-hierarchy-decision-gol
plan: 03
subsystem: ci-raster-evidence
tags: [github-actions, pdfium, raster, provenance, guardrails]
requires:
  - phase: 126-01
    provides: themed recipe repairs
  - phase: 126-02
    provides: deterministic golden and typography proof
provides:
  - fail-closed pinned CI raster blessing evidence for six affected preset rows
affects: [126-04, 126-05]
tech-stack:
  added: []
  patterns: [step-scoped advisory adapter comparison, exact-ref CI provenance, six-file artifact fence]
key-files:
  created: []
  modified:
    - .github/workflows/ci.yml
    - test/guardrails/required_checks_contract_test.exs
    - priv/raster_refs/presets/swiss/light.sha256
    - priv/raster_refs/presets/corporate_classic/dark.sha256
    - priv/raster_refs/presets/editorial/dark.sha256
    - priv/raster_refs/presets/minimal_mono/dark.sha256
    - priv/raster_refs/presets/humanist/dark.sha256
    - priv/raster_refs/presets/brutalist/dark.sha256
decisions:
  - Keep only the legacy adapter comparison non-blocking; preset blessing, staging, manifest creation, and upload fail closed.
  - Accept artifacts only from one successful advisory-checks job with exact push/ref/SHA and matching manifest, never from whole-workflow success.
metrics:
  duration: 18m
  completed: 2026-08-17
  tasks_completed: 2
  files_modified: 8
status: complete
---

# Phase 126 Plan 03: Pinned Raster Evidence Recovery Summary

**A fail-closed exact-ref PDFium evidence handoff refreshed only six repaired preset raster hashes and produced six full-size review PNGs.**

## Accomplishments

- Moved the legacy adapter raster comparator's `continue-on-error` from the `advisory-checks` job to that step alone, with `MIX_RASTER_BLESS: "false"` pinned.
- Guarded the workflow contract so preset blessing, staging, and upload cannot be failure-masked, and the required deterministic `test` job cannot bless rasters.
- Imported exactly six CI-produced preset reference hashes and copied exactly six stable-row, full-size PNGs to `tmp/rendro_phase126_review` for Plan 126-04's sequential visual review.
- Auto-approved Task 2's blocking human-verify checkpoint under the configured `workflow.auto_advance: true` / `_auto_chain_active: true` policy after automated provenance validation.

## Verification

- `mix format --check-formatted test/guardrails/required_checks_contract_test.exs` — passed.
- Focused deterministic suite including guardrails, Invoice, Ticket, Payslip, all typography contracts, preset accent golden, and preset render matrix — passed (200 tests).
- Exact artifact manifest matched CI SHA `a00f1b0540602b8ba8937ce1b7e55ba0cba48b13`, run `31997957937`, PDFium `v0.11.0`, and executable SHA `b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a` from `priv/pdfium_pin.json`.
- Manifest payload contained exactly the six declared hash paths and six named review PNGs; each imported reference is one lowercase 64-character SHA-256 line, and the preset reference diff contains no other path.

## CI Evidence

### Retained failed attempt

- `retained_ci_ref: gsd/phase-126-raster-bless-242f2c304b1f`
- Ref/SHA/run: `gsd/phase-126-raster-bless-242f2c304b1f` / `242f2c304b1fd714ed6ca09c6879170856ac8132` / [31996940001](https://github.com/szTheory/rendro/actions/runs/31996940001).
- Whole-run conclusion: `failure`. The `advisory-checks` adapter compare-only step failed on absent legacy edge references; preset, staging, and upload were skipped. No hashes or PNGs were imported.
- Other non-success jobs: `security-audit` failure, both `test` matrix jobs failure, `ci-success` failure, and `integration-proofs` skipped.

### Accepted evidence attempt

- `retained_ci_ref: gsd/phase-126-raster-bless-a00f1b054060`
- Ref/SHA/run: `gsd/phase-126-raster-bless-a00f1b054060` / `a00f1b0540602b8ba8937ce1b7e55ba0cba48b13` / [31997957937](https://github.com/szTheory/rendro/actions/runs/31997957937).
- Whole-run conclusion: `failure` (disclosed only; not the artifact predicate).
- Exact `advisory-checks` job: one job for the exact SHA, conclusion `success`. Adapter compare-only `success`; preset blessing `success`; staging `success`; upload `success`.
- Manifest validation: passed for exact run ID, commit SHA, pinned PDFium version/executable SHA, six declared hashes, and six review PNGs.
- Unrelated non-success jobs: `test (25, 1.19.0, false)` failure during Setup Beam, `security-audit` failure, `ci-success` failure, and `integration-proofs` skipped. `test (28, 1.19.5, true)` and `example-phoenix` succeeded.

Both retained refs remain on origin through Plan 126-04, as required for later cleanup.

## Decisions Made

- Treat the graph-disconnected adapter comparison as advisory at step scope only; a successful preset artifact requires all evidence-producing steps to complete successfully.
- Keep legacy edge reference absence disclosed rather than creating, blessing, or importing those out-of-scope files.

## Deviations from Plan

None - the revised recovery contract executed as written.

## Known Stubs

None.

## Next Phase Readiness

Plan 126-04 can review the six full-size PNGs in `tmp/rendro_phase126_review` after confirming this provenance handoff. Both guarded CI refs are retained for Plan 126-05 cleanup.

## Self-Check: PASSED

- Task commits `a00f1b0` and `21bf9b2` exist.
- All eight modified tracked files exist; ephemeral manifest and six review PNGs exist locally.
