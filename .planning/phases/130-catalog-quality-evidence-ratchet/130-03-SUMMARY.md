---
phase: 130-catalog-quality-evidence-ratchet
plan: "03"
subsystem: catalog-review-ci
tags: [elixir, catalog, ci, pdfium, provenance]
requires:
  - phase: 130-01
    provides: repaired public supplied-theme recipe hierarchy
  - phase: 130-02
    provides: repaired Certificate, Payslip, and Ticket supplied-theme hierarchy
provides:
  - Pure candidate-only final and multipage payload classification
  - Immutable full-SHA-bound Phase 130 advisory CI route
affects: [130-04, 130-05, catalog-quality-evidence]
tech-stack:
  added: []
  patterns:
    - Validate candidate review identity without file I/O or PDFium before pinned rendering
    - Bind advisory evidence refs to the exact pushed 40-character commit SHA
key-files:
  created:
    - dev/rendro/catalog_review_payload.ex
    - test/rendro/catalog_review_payload_contract_test.exs
  modified:
    - test/rendro/catalog_raster_review_test.exs
    - test/guardrails/required_checks_contract_test.exs
    - .github/workflows/ci.yml
key-decisions:
  - "The twelve D-21 page-one identities and four multipage proofs are separate immutable payloads."
  - "Only gsd/phase-130-catalog-review-<40 lowercase hex equal to GITHUB_SHA may produce the advisory artifacts."
metrics:
  duration: 6m
  completed: 2026-08-20
  tasks: 2
  files: 5
status: complete
---

# Phase 130 Plan 03: Candidate Payload and Immutable CI Summary

**Pure candidate-manifest validation and an exact-SHA advisory CI contract, with PDFium realization reserved for the later pinned candidate run.**

## Performance

- **Duration:** 6m
- **Started:** 2026-08-20T02:01:52Z
- **Completed:** 2026-08-20T02:07:37Z
- **Tasks:** 2/2
- **Files created/modified:** 5

## Accomplishments

- Added `Rendro.CatalogReviewPayload.classify/2`, a dev-only pure seam that accepts only the canonical twelve candidate cells in light-then-dark order and keeps four Invoice/Statement multipage proofs separate.
- Bound every review identity to its catalog ID, mode, candidate PNG hash, complete source-PDF hash, renderer version/SHA, commit SHA, and run ID; malformed, stale, unsafe, reordered, duplicate, extra, or quality-bearing input fails closed.
- Refactored the tagged raster test to consume the future candidate manifest and write only separated `final` and `multipage` review directories during the pinned lane.
- Added a phase-narrow CI route that requires `gsd/phase-130-catalog-review-<40 lowercase hex>` and verifies that suffix equals `GITHUB_SHA`, then uploads candidate, final, and multipage artifacts independently.

## Task Commits

1. **Task 1: Drive one canonical pair from the candidate manifest into the separated payload** — `b1047a7` (RED test), `5ad5a3b` (GREEN implementation)
2. **Task 2: Bind the advisory route to the exact full commit SHA** — `521fc39` (RED test), `af3f8ff` (GREEN implementation)

## Verification

- `mix format --check-formatted dev/rendro/catalog_review_payload.ex test/rendro/catalog_review_payload_contract_test.exs test/rendro/catalog_raster_review_test.exs test/guardrails/required_checks_contract_test.exs` — pass.
- `mix test test/rendro/catalog_review_payload_contract_test.exs test/guardrails/required_checks_contract_test.exs --max-failures 1` — pass (22 tests).
- `mix test test/rendro/catalog_raster_review_test.exs --max-failures 1` — tagged test deliberately excluded (0 executed, 1 excluded); PDFium rendering remains reserved for Plan 04's pinned candidate run.
- `git diff --check` — pass.

## TDD Gate Compliance

- PASS — each behavior-adding task has a failing `test(130-03)` commit followed by its `feat(130-03)` implementation commit.

## Decisions Made

- Candidate classification is a pure, file-I/O-free boundary and does not read canonical catalog assets, mutate evidence, or project quality data.
- The advisory lane stages only temporary candidate/review artifacts and remains graph-disconnected from required deterministic CI.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Threat Flags

None. The only new trust surfaces are the plan-declared candidate-manifest and git-ref boundaries, both covered by fail-closed identity and full-SHA checks.

## Next Phase Readiness

Plan 04 can implement the candidate generator against the pure payload contract. It must not run the tagged PDFium test until its exact candidate bundle and pinned renderer are available.

## Self-Check: PASSED

- Created payload module and untagged contract test exist.
- Task commits `b1047a7`, `5ad5a3b`, `521fc39`, and `af3f8ff` exist in git history.
