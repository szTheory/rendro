---
phase: 87-comparison-page-livebook
plan: 03
subsystem: docs-contract
tags: [comparison-guide, generated-blocks, benchmark-citations, docs-contract]

requires:
  - phase: 87-01
    provides: Comparison manifest contract and claim registry
  - phase: 87-02
    provides: Real benchmark manifest and raw artifacts
provides:
  - HexDocs comparison guide titled "Generating PDFs in Elixir without Chrome"
  - Manifest-backed generated fit, results, and evidence blocks
  - Docs-contract tests for generated block freshness, claim citations, section order, and overclaim guards
affects: [exdoc, readme, advisory-ci, launch-content]

tech-stack:
  added: []
  patterns:
    - Human-authored guide prose wraps generated manifest-backed tables
    - Public benchmark citations use visible [bench:CMP-*] markers
    - Docs contracts enforce exact generated block equality instead of trusting manual edits

key-files:
  created:
    - guides/comparison.md
  modified:
    - lib/rendro/comparison.ex
    - test/rendro/comparison_test.exs
    - test/docs_contract/comparison_claims_test.exs

key-decisions:
  - "The public guide leads with fit guidance and generated measured tables, not a winner chart."
  - "The warm-pool timing row stays visible as a comparator posture and is bounded by manifest claim scope."
  - "Uncited comparative phrases are rejected line-by-line unless the same line carries a valid [bench:CMP-*] citation."

patterns-established:
  - "Comparison generated blocks have marker equality tests matching Phase 86 launch artifact drift checks."
  - "Guide structure, exact fit sentences, and limitation copy are docs-contract enforced."
  - "Benchmark evidence summaries include run metadata, comparator versions, host/container metadata, per-result median/p95/sample counts, and raw artifact paths."

requirements-completed: [CMP-02]

duration: 14 min
completed: 2026-06-11
---

# Phase 87 Plan 03: Comparison Guide Summary

**Benchmark-bound HexDocs comparison guide with generated tables and citation/overclaim contracts**

## Performance

- **Duration:** 14 min
- **Started:** 2026-06-11T21:19:00Z
- **Completed:** 2026-06-11T21:32:58Z
- **Tasks:** 3
- **Files modified:** 4

## Accomplishments

- Extended `Rendro.Comparison` generated blocks so the evidence block includes run metadata, comparator versions, host/container details, result summaries, and raw artifact paths.
- Added `guides/comparison.md` with the required title, seven-section structure, fair fit copy for Rendro/ChromicPDF/Typst, visible limitation copy, and generated blocks sourced from the committed benchmark manifest.
- Hardened the comparison docs-contract lane to enforce generated block equality, claim citation coverage, required guide structure/copy, and uncited comparative/banned phrase guards.

## Task Commits

Each task was committed atomically:

1. **Task 1: Generate comparison guide blocks from the benchmark manifest** - `a757eca` (feat)
2. **Task 2: Create the comparison guide with generated blocks and fair framing** - `4344f68` (docs)
3. **Task 3: Harden docs-contract claim binding and overclaim guards** - `bdaf3e0` (test)

**Plan metadata:** pending in this commit

## Files Created/Modified

- `guides/comparison.md` - Public comparison guide with exact generated blocks and fair fit framing.
- `lib/rendro/comparison.ex` - Richer evidence block generation and result metadata helpers.
- `test/rendro/comparison_test.exs` - Determinism and generated block metadata coverage.
- `test/docs_contract/comparison_claims_test.exs` - Generated block equality, citation, section, copy, and overclaim guard tests.

## Decisions Made

- Kept guide prose concise and human-authored while generated tables/evidence remain machine-produced from `bench/results/comparison.json`.
- Cited the Rendro no-browser-runtime fit sentence with `[bench:CMP-RUNTIME-BURDEN]`; avoided `no Chrome runtime` wording outside citation-guarded contexts.
- Preserved exact section names and fit sentences from the Phase 87 UI/spec contract.

## Deviations from Plan

None - plan executed as written.

## Issues Encountered

- The first docs-contract test run had a test bug using `in` against a string. Fixed it to use `=~` for string containment.

## User Setup Required

None.

## Verification

- `mix test test/rendro/comparison_test.exs` - passed, 16 tests.
- `mix test test/docs_contract/comparison_claims_test.exs` - passed, 7 tests.
- `mix run scripts/verify_docs.exs` - passed, all 17 docs-contract lanes.
- `git diff --check` - passed.

## Next Phase Readiness

Plan 05 can now wire `guides/comparison.md` and the Livebook notebook into README, ExDoc extras, package contents, and advisory CI. The guide is already bound to the committed benchmark manifest and docs-contract lane.

## Self-Check: PASSED

- `guides/comparison.md` has the exact required H1 and H2 order.
- Generated fit/results/evidence blocks exactly equal `Rendro.Comparison` output for the committed manifest.
- Every public manifest claim appears in the guide and every `[bench:CMP-*]` citation resolves.
- Required limitation copy and alternative-fit praise are present.
- Banned hype/attack phrases and uncited comparative phrases are guarded by tests.

---
*Phase: 87-comparison-page-livebook*
*Completed: 2026-06-11*
