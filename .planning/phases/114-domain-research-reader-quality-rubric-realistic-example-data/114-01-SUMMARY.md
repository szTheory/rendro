---
phase: 114-domain-research-reader-quality-rubric-realistic-example-data
plan: 01
subsystem: infra
tags: [bench, fixtures, typst, comparison, determinism, priv-examples]

# Dependency graph
requires:
  - phase: 87-comparison-benchmark
    provides: The pinned invoice_v1 comparison harness + recorded raw evidence (bench/results/raw/*.json)
provides:
  - "priv/examples/invoice/acme-phoenix-saas/invoice.json — the de-quarantined realistic Invoice fixture, now living in the shared example-data library (byte-identical to its former bench-only location)"
  - "Repointed bench comparison consumers (run.exs, invoice_rendro.exs, invoice_typst.typ, comparison.json) — proven behavior-preserving via sha256 render diff"
affects: [114-03, 114-04, 114-05, 114-07, invoice-anatomy, examples-loader]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Provable no-op file move: git mv verified byte-identical against the last-committed git blob (sha256), then repoint consumers, then prove downstream output byte-identity (fresh render sha256 == recorded benchmark PDF sha256) — because mix rendro.comparison.check never re-reads the fixture (Pitfall 2)."
    - "Typst --input path passed as Path.expand(@fixture_path) (absolute) so resolution is independent of the compiling .typ file's own directory."

key-files:
  created:
    - priv/examples/invoice/acme-phoenix-saas/invoice.json
  modified:
    - bench/comparison/run.exs
    - bench/comparison/fixtures/invoice_rendro.exs
    - bench/comparison/fixtures/invoice_typst.typ
    - bench/results/comparison.json

key-decisions:
  - "Kept the move strictly verbatim — zero content edits. Money-string normalization and the S4 brand/logo slot are deferred to Plan 114-03's separate commit (per RESEARCH.md Pitfall 6); conflating them would make the no-op unprovable."
  - "Passed the Typst data-path as an absolute Path.expand(@fixture_path) rather than a bare filename, since the fixture no longer lives next to invoice_typst.typ."
  - "Left the historical `data-path=invoice_data.json` command strings inside the hash-locked bench/results/raw/typst_cli.json untouched — they are recorded evidence, verified by comparison.check's raw_sha256, and must not change."

patterns-established:
  - "Pattern 1: De-quarantine = byte-identical git mv + consumer repoint + downstream-output byte-identity proof, not merely 'the check stays green'."

requirements-completed: [EXL-04]

coverage:
  - id: D1
    description: "Realistic invoice fixture de-quarantined into priv/examples/invoice/acme-phoenix-saas/invoice.json, byte-identical to its former bench-only location."
    requirement: "EXL-04"
    verification:
      - kind: other
        ref: "shasum -a 256 comparison: git show HEAD:bench/comparison/fixtures/invoice_data.json vs priv/examples/invoice/acme-phoenix-saas/invoice.json => BYTE_IDENTICAL (b364c9c2...)"
        status: pass
    human_judgment: false
  - id: D2
    description: "All three hardcoded bench consumers repointed; fresh Rendro render remains sha256-identical to the recorded benchmark PDF, proving zero rendering drift."
    requirement: "EXL-04"
    verification:
      - kind: integration
        ref: "mix rendro.comparison.check => VERIFIED; RENDRO_BENCH_OUTPUT render sha256 == bench/results/raw/rendro.json output_pdf.sha256 (e629d371...) => BYTE_IDENTICAL_PDF"
        status: pass
    human_judgment: false

# Metrics
duration: 1min
completed: 2026-07-11
status: complete
---

# Phase 114 Plan 01: De-quarantine invoice fixture into priv/examples (provable no-op) Summary

**The realistic invoice fixture was moved verbatim from `bench/comparison/fixtures/invoice_data.json` into the shared `priv/examples/invoice/acme-phoenix-saas/invoice.json` library, with every consumer repointed and behavior-preservation proven two ways: a byte-identical sha256 blob diff and a fresh Rendro render matching the already-recorded benchmark PDF hash.**

## Performance

- **Duration:** ~1 min
- **Started:** 2026-07-11T04:34:00Z
- **Completed:** 2026-07-11T04:35:02Z
- **Tasks:** 2
- **Files modified:** 5 (1 created via move, 4 edited)

## Accomplishments
- De-quarantined the invoice fixture via `git mv` — byte-identical to the last-committed blob (sha256 `b364c9c2...`), git records it as a pure rename (0 insertions/0 deletions).
- Repointed all three hardcoded consumers (`run.exs @fixture_path`, `invoice_rendro.exs` literal path, `invoice_typst.typ` default) plus the non-hash-bearing `comparison.json` `scenario.fixture` doc string.
- Supplied the explicit EXL-04 proof that Pitfall 2 warned was missing: `mix rendro.comparison.check` stays green AND a fresh render is sha256-identical (`e629d371...`) to `bench/results/raw/rendro.json`'s recorded `output_pdf.sha256`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Verbatim de-quarantine move (byte-identical proof)** - `6ecb4f6` (chore)
2. **Task 2: Repoint the three hardcoded consumer paths + prove render byte-identity** - `47ee0b5` (chore)

**Plan metadata:** _(docs commit — see final commit)_

## Files Created/Modified
- `priv/examples/invoice/acme-phoenix-saas/invoice.json` - The de-quarantined realistic Invoice fixture (moved verbatim; content unchanged this plan).
- `bench/comparison/run.exs` - `@fixture_path` repointed; Typst `--input data-path=` now uses `Path.expand(@fixture_path)` (absolute).
- `bench/comparison/fixtures/invoice_rendro.exs` - `File.read!` literal path repointed.
- `bench/comparison/fixtures/invoice_typst.typ` - `default:` fallback path repointed (accuracy only; `run.exs` always supplies `--input`).
- `bench/results/comparison.json` - `scenario.fixture` documentation string updated to the new path (non-hash-bearing field).

## Decisions Made
- Move kept strictly verbatim; money/brand normalization deferred to Plan 114-03 (Pitfall 6) to keep the no-op provable.
- Typst path passed absolute via `Path.expand` since the fixture no longer sits beside the `.typ` file.
- Historical `data-path=invoice_data.json` strings inside the hash-locked `bench/results/raw/typst_cli.json` deliberately left untouched (recorded evidence, verified by `raw_sha256`).

## Deviations from Plan
None - plan executed exactly as written.

## Issues Encountered
None. (The `git add` of the already-deleted old path errored harmlessly because `git mv` had already staged the rename; the commit captured the rename correctly — confirmed as a 0/0 pure rename.)

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- The shared `priv/examples/invoice/acme-phoenix-saas/invoice.json` location is now the single source of truth for the realistic Invoice fixture, ready for Plan 114-03 (money-string normalization + S4 brand/logo slot) and Plan 114-04 (`Rendro.Examples` loader).
- No blockers.

## Self-Check: PASSED
- FOUND: priv/examples/invoice/acme-phoenix-saas/invoice.json
- FOUND commit: 6ecb4f6
- FOUND commit: 47ee0b5

---
*Phase: 114-domain-research-reader-quality-rubric-realistic-example-data*
*Completed: 2026-07-11*
