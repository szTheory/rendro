---
phase: 49
plan: 03
subsystem: curated-link-annotation-surface
tags:
  - links
  - pdf-annotations
  - determinism
dependency_graph:
  requires:
    - 49-01
    - 49-02
  provides:
    - Deterministic `/Link` annotation serialization through the existing page `/Annots` seam
    - Direct `/Dest [page_ref /Fit]` and narrow `/A << /S /URI /URI (...) >>` output proof
  affects:
    - lib/rendro/pdf/writer.ex
    - test/rendro/pdf/writer_test.exs
    - test/rendro/deterministic_test.exs
tech_stack:
  added: []
  patterns:
    - Reuse page annotation seam without generic annotation dictionaries
    - Delegate `%Rendro.Link{}` visible rendering back into normal writer/resource collection paths
    - Lock deterministic PDF proof with substring ordering checks
key_files:
  created: []
  modified:
    - lib/rendro/pdf/writer.ex
    - test/rendro/pdf/writer_test.exs
    - test/rendro/deterministic_test.exs
decisions:
  - Allocate link annotations as page-scoped indirect objects alongside existing widget annotations instead of introducing a second annotation pipeline.
  - Serialize internal links as direct `/Dest [page_ref /Fit]` arrays and external links as narrow URI action dictionaries only.
  - Keep deterministic proof structural by asserting link annotation order and visible linked content bytes without widening into viewer-behavior claims.
metrics:
  completed_at: 2026-05-05T00:00:00Z
  duration: approx. 24m
  task_commits: 4
  files_changed: 3
---

# Phase 49 Plan 03: Curated Link Annotation Surface Summary

Curated links now serialize as deterministic PDF `/Link` annotations through the existing page `/Annots` seam while preserving the normal visible render output for wrapped text and table content.

## Completed Work

- Extended `Rendro.PDF.Writer` to collect paginated `%Rendro.Link{}` fragments, allocate one annotation object per fragment, and append those refs to the existing page `/Annots` array beside any widget annotations.
- Kept the annotation surface narrow: external links emit `/A << /S /URI /URI (...) >>` with authored URI bytes preserved, and internal links emit direct same-document `/Dest [page_ref /Fit]` arrays without named destinations or generic action dictionaries.
- Restored link-wrapped content to the standard writer path for rendering and resource collection so linked text, measured text fragments, tables, and linked assets continue to render with their existing font/image handling.
- Added structural writer proof for URI links, page destinations, fragment-per-page annotations, visible text/table continuity, and deterministic ordering/byte identity for linked output.

## Task Commits

- `7a74f9e` `test(49-03): add failing link annotation writer coverage`
- `eba9019` `feat(49-03): emit curated link annotations from writer`
- `ec07a83` `test(49-03): add failing link determinism coverage`
- `48cdf93` `test(49-03): lock deterministic link annotation output`

## Deviations from Plan

None - plan executed exactly as written.

## TDD Gate Compliance

- Task 1 RED and GREEN commits are present.
- Task 2 RED and GREEN commits are present.

## Known Stubs

None detected in the files changed for this plan.

## Threat Flags

None. The change stayed within the planned page-annotation trust boundary and did not introduce generic annotation dictionaries, raw actions, or broader destination surfaces.

## Verification

- `mix test test/rendro/pdf/writer_test.exs`
- `mix test test/rendro/pdf/writer_test.exs test/rendro/deterministic_test.exs`

## Self-Check: PASSED

- Summary file exists at `.planning/phases/49-curated-link-annotation-surface/49-03-SUMMARY.md`.
- Commit `7a74f9e` exists in git history.
- Commit `eba9019` exists in git history.
- Commit `ec07a83` exists in git history.
- Commit `48cdf93` exists in git history.
