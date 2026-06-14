---
phase: 99-cross-references-validation
plan: 01
subsystem: cross-references
tags:
  - links
  - validation
  - anchors
dependency_graph:
  requires: []
  provides:
    - "{:anchor, id} link target primitive"
    - "link anchor validation against doc.metadata.anchors"
  affects:
    - lib/rendro/link.ex
    - lib/rendro.ex
    - lib/rendro/rules/check_links.ex
tech_stack:
  added: []
  patterns: []
key_files:
  created: []
  modified:
    - lib/rendro/link.ex
    - lib/rendro.ex
    - lib/rendro/rules/check_links.ex
    - test/rendro/rules/check_links_test.exs
    - test/rendro_builders_test.exs
decisions:
  - "Anchor link target is normalized into a tuple {:anchor, String.t()} similar to :uri and :page targets."
  - "CheckLinks rule directly queries doc.metadata.anchors map, which is already accumulated in a prior Pipeline stage, ensuring the pipeline's validate stage deterministically halts on broken anchor links."
metrics:
  duration: 2m
  completed_date: "2024-05-18"
---

# Phase 99 Plan 01: Cross-References Validation Summary

Add `:anchor` link primitive to explicit links and ensure they strictly validate against accumulated document anchors.

## Deviations from Plan

None - plan executed exactly as written.

## Deferred Issues

- Test failure in `Rendro.RecipesFacadeDriftTest` (Expected Rendro.Recipes.invoice/1 to be exported) is an out-of-scope pre-existing issue.

## Threat Flags

None found.

## Known Stubs

None found.## Self-Check: PASSED
