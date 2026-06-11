---
phase: 86-self-proving-launch-artifacts
plan: 05
subsystem: docs
tags: [launch-artifacts, gallery, manual, raster-advisory, docs-contract]
requires:
  - phase: 86-self-proving-launch-artifacts
    provides: 86-01 advisory guardrails
  - phase: 86-self-proving-launch-artifacts
    provides: 86-02 static docs proof
  - phase: 86-self-proving-launch-artifacts
    provides: 86-03 curated launch fixtures
  - phase: 86-self-proving-launch-artifacts
    provides: 86-04 launch copy and manual source
provides:
  - Final generated launch gallery, manual, manifest, and docs blocks
  - Pinned pdfium advisory verification evidence
  - Required static docs-contract and full CI proof
affects: [phase-86, assets, readme, guides, ci, docs-contract]
tech-stack:
  added: []
  patterns:
    - Required docs-contract checks prove source/manual/docs/package bytes without pdfium.
    - Advisory raster checks run with pinned pdfium v0.11.0 outside required CI.
key-files:
  created:
    - .planning/phases/86-self-proving-launch-artifacts/86-05-SUMMARY.md
  modified:
    - assets/rendro/artifacts.json
    - assets/rendro/gallery/invoice.png
    - assets/rendro/gallery/branded_invoice.png
    - assets/rendro/gallery/statement.png
    - assets/rendro/gallery/receipt_report.png
    - assets/rendro/gallery/certificate.png
    - assets/rendro/manual.pdf
    - README.md
    - guides/recipes.md
    - lib/rendro/launch_artifacts.ex
    - lib/mix/tasks/rendro/launch_artifacts/gen.ex
    - lib/mix/tasks/rendro/launch_artifacts/check.ex
    - scripts/verify_docs.exs
    - .github/workflows/ci.yml
    - mix.exs
    - test/rendro/launch_artifacts_test.exs
    - test/docs_contract/launch_artifacts_claims_test.exs
    - test/guardrails/required_checks_contract_test.exs
key-decisions:
  - "Use a local Docker shim for the pinned Linux amd64 pdfium-cli on macOS, preserving the exact pinned renderer version and SHA check."
  - "Treat the launch artifacts as self-proving only through generated manifest/docs/package/static checks; PNG regeneration remains advisory."
patterns-established:
  - "Generated launch artifacts are regenerated from source and verified by static hashes before advisory raster comparison."
  - "Visual blockers are closed through source fixes and regeneration, not by hand-editing manifest hashes or PNG metadata."
requirements-completed: [GAL-01, GAL-02, GAL-03]
duration: 16min
completed: 2026-06-11
---

# Phase 86 Plan 05: Final Launch Artifact Generation Summary

**Final gallery PNGs, `manual.pdf`, `artifacts.json`, README block, and HexDocs recipe block are regenerated and verified.**

## Performance

- **Duration:** 16 min
- **Started:** 2026-06-11T18:16:00Z
- **Completed:** 2026-06-11T18:31:48Z
- **Tasks:** 3
- **Files modified:** 19

## Accomplishments

- Regenerated five launch gallery PNGs, `assets/rendro/manual.pdf`, `assets/rendro/artifacts.json`, README generated block, and `guides/recipes.md` generated block.
- Verified the manifest has schema version `1`, exactly five gallery entries in order `invoice`, `branded_invoice`, `statement`, `receipt_report`, `certificate`, and manual SHA-256 `a9f1a241c3fb331ad5522d905af8acf26d9848b8862cb9a6f3e4033c3ee1dc94`.
- Fixed BrandedInvoice launch rendering so `Rendro, Inc.` and invoice metadata remain readable while preserving the logo and table polish.
- Preserved paginated table cell offsets so generated launch tables render cell content at the measured table position.
- Wired Mix generation/check tasks, package assets, ExDoc assets/style, docs verification, and CI advisory launch-artifact surfaces.
- Hardened docs-contract lane assertions so formatted docs-lane command tuples remain covered by required tests.
- Cleared formatter, Credo, and Dialyzer findings found by final `mix ci`.

## Visual Review

- `invoice.png` - visible launch-only row/outer table rules and warm header band.
- `branded_invoice.png` - readable heading, no overlapped or split letters, visible logo, visible table polish.
- `statement.png` - row/outer table rules and warm header band without dense full-grid treatment.
- `receipt_report.png` - row/outer table rules and warm header band without dense full-grid treatment.
- `certificate.png` - landscape certificate with visible Path-backed keyline frame.
- `manual.pdf` - `pdfinfo` reports 8 A4 pages; `pdftotext` confirmed `Rendro manual - Page X of 8` footers plus fit/boundary and determinism/path proof pages.

## Task Commits

1. **Task 1: Regenerate final gallery/manual/manifest/docs blocks** - `93fafbb` (assets/docs), plus `a70e68e` (BrandedInvoice source fix)
2. **Task 2: Visual acceptance fixes** - `f62741f` (paginated table cell offsets), `a70e68e` (BrandedInvoice launch header)
3. **Task 3: Verification surfaces and final gates** - `101ec4f`, `1f80964`, `1e631f0`, `b5ef4bc`, `9c3b48c`, `4669167`

## Files Created/Modified

- `assets/rendro/artifacts.json` - Final gallery/manual manifest with source PDF, PNG, renderer, and manual hashes.
- `assets/rendro/gallery/*.png` - Final public launch previews.
- `assets/rendro/manual.pdf` - Final compact self-rendered proof manual.
- `README.md` - Final generated launch artifact block.
- `guides/recipes.md` - Final generated HexDocs gallery block.
- `lib/rendro/launch_artifacts.ex` - Final generation/static/raster/manual/source contract.
- `lib/mix/tasks/rendro/launch_artifacts/gen.ex` - Generation task.
- `lib/mix/tasks/rendro/launch_artifacts/check.ex` - Advisory no-write check task.
- `scripts/verify_docs.exs` - Required docs-contract lane coverage.
- `.github/workflows/ci.yml` - Advisory launch-artifact check wiring.
- `mix.exs` - Package and docs asset wiring.
- Tests under `test/rendro`, `test/docs_contract`, and `test/guardrails` - Static, package, source, and lane contract proof.

## Decisions Made

- Kept `mix ci` pdfium-free; the pinned pdfium renderer is used only by explicit generation/check commands and the advisory raster snapshot suite.
- Used `/tmp/rendro-pdfium-shim/pdfium-cli` to run the pinned Linux amd64 pdfium v0.11.0 binary under Docker on macOS after verifying its SHA-256 from `priv/pdfium_pin.json`.
- Fixed generated visual defects in source code and regenerated all artifacts rather than editing PNGs, PDFs, or hashes by hand.

## Deviations from Plan

- Local macOS could not execute the pinned Linux pdfium binary directly, so the advisory commands used a Docker shim for the same pinned binary.
- Final `mix ci` exposed unrelated formatter/Credo/Dialyzer cleanup required for a green required gate; those fixes were kept narrow and committed separately.

## Verification

- `jq -r '.manual.sha256 as $m | [.schema_version, (.gallery | length), (.gallery | map(.id) | join(",")), $m] | @tsv' assets/rendro/artifacts.json` - passed (`1`, `5`, required gallery order, manual SHA above)
- `mix run -e 'case Rendro.LaunchArtifacts.static_contract_errors() do [] -> IO.puts("static ok"); errors -> raise Enum.join(errors, "\n") end'` - passed
- `mix test test/rendro/launch_artifacts_test.exs` - passed, 5 tests
- `mix test test/docs_contract/launch_artifacts_claims_test.exs test/guardrails/required_checks_contract_test.exs test/docs_contract/raster_claims_test.exs` - passed, 31 tests
- `mix run scripts/verify_docs.exs` - passed
- `mix ci` - passed, including package build, tests, docs, Credo strict, and Dialyzer
- `test ! -f rendro-1.0.0.tar` - passed
- `mix rendro.launch_artifacts.check --pdfium /tmp/rendro-pdfium-shim/pdfium-cli` - passed
- `PATH="/tmp/rendro-pdfium-shim:$PATH" MIX_RASTER_BLESS=false mix test --include raster_snapshot test/rendro/adapters/pdfium_raster_snapshot_test.exs` - passed, 2 tests
- `git status --short` - only pre-existing unrelated planning files remain dirty; no generated tarball, unpacked package, or temporary raster files remain

## Issues Encountered

- The pinned pdfium binary is Linux amd64; direct execution on macOS returned `exec format error`. The Docker shim resolved this without changing the pinned binary or moving pdfium into required CI.
- BrandedInvoice initially rendered with split/overlapped heading text after launch fixture polish. The fix preserves font and logo registration while rendering launch header text with the default font for readability.
- `mix ci` initially stopped on a dead integer guard in `Rendro.Color.format_num/1`; the helper only receives floats from `/`, so the unreachable clause was removed.

## User Setup Required

None for required CI. Advisory local regeneration/checking needs the pinned pdfium CLI or an equivalent shim at an explicit path.

## Next Phase Readiness

Phase 86 is complete. The launch artifact surface is generated, hash-checked, visually accepted, packaged, documented, and isolated from required CI pdfium dependencies.

---
*Phase: 86-self-proving-launch-artifacts*
*Completed: 2026-06-11*
