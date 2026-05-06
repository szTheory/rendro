---
phase: 49
plan: 01
subsystem: curated-link-annotation-surface
tags:
  - links
  - validation
  - pdf-annotations
dependency_graph:
  requires:
    - 48-02
  provides:
    - Explicit `Rendro.link/2` authored boundary
    - Validate-stage curated link semantics
  affects:
    - lib/rendro.ex
    - lib/rendro/block.ex
    - lib/rendro/link.ex
    - lib/rendro/rules/check_links.ex
    - lib/rendro/pipeline/validate.ex
    - test/rendro_builders_test.exs
    - test/rendro/rules/check_links_test.exs
    - test/rendro/pipeline/validate_test.exs
tech_stack:
  added:
    - Elixir stdlib `URI.new/1`
  patterns:
    - Explicit interactive authored nodes
    - Validate-stage typed tuple aggregation
    - Block-owned geometry preservation
key_files:
  created:
    - lib/rendro/link.ex
    - lib/rendro/rules/check_links.ex
    - test/rendro/rules/check_links_test.exs
  modified:
    - lib/rendro.ex
    - lib/rendro/block.ex
    - lib/rendro/pipeline/validate.ex
    - test/rendro_builders_test.exs
    - test/rendro/pipeline/validate_test.exs
decisions:
  - Keep link authoring block-local through `%Rendro.Link{}` instead of hidden attrs or generic annotation dictionaries.
  - Accept only explicit `uri:` and `page:` target variants at the builder boundary.
  - Enforce URI scheme, host, page-range, and form-field conflict rules in `Rendro.Pipeline.Validate`.
metrics:
  completed_at: 2026-05-05T00:00:00Z
  duration: approx. 20m
  task_commits: 4
  files_changed: 8
---

# Phase 49 Plan 01: Curated Link Annotation Surface Summary

Explicit curated link authoring now exists as a narrow block wrapper with validate-stage rejection of malformed URI and page targets before any writer work begins.

## Completed Work

- Added `%Rendro.Link{content, target}` and `Rendro.link/2`, preserving outer `%Rendro.Block{}` geometry and pagination flags while accepting exactly one explicit target variant: `uri:` or `page:`.
- Updated the block type surface to acknowledge link content as a first-class authored node.
- Added `Rendro.Rules.CheckLinks` and wired it into `Rendro.Pipeline.Validate` so invalid URI shapes, unsupported schemes, out-of-range page targets, and `%Rendro.FormField{}`-wrapped links fail with typed tuples in the existing aggregate error envelope.
- Added RED/GREEN coverage for the builder boundary and validate-stage semantics.

## Task Commits

- `5344c96` `test(49-01): add failing link builder coverage`
- `47a69cf` `feat(49-01): add explicit authored link builder`
- `93bf686` `test(49-01): add failing link validation coverage`
- `b06e6ec` `feat(49-01): validate curated link semantics`

## Deviations from Plan

None - plan executed exactly as written.

## TDD Gate Compliance

- Task 1 RED and GREEN commits are present.
- Task 2 RED and GREEN commits are present.

## Known Stubs

None detected in the files changed for this plan.

## Threat Flags

None. The change stayed within the planned public builder and validate-stage trust boundaries.

## Verification

- `mix test test/rendro_builders_test.exs`
- `mix test test/rendro/rules/check_links_test.exs test/rendro/pipeline/validate_test.exs`
- `mix test test/rendro_builders_test.exs test/rendro/rules/check_links_test.exs test/rendro/pipeline/validate_test.exs`

## Self-Check: PASSED

- Summary file exists at `.planning/phases/49-curated-link-annotation-surface/49-01-SUMMARY.md`.
- Commit `5344c96` exists in git history.
- Commit `47a69cf` exists in git history.
- Commit `93bf686` exists in git history.
- Commit `b06e6ec` exists in git history.
