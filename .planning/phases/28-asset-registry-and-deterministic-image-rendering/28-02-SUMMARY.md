---
phase: 28-asset-registry-and-deterministic-image-rendering
plan: 02
subsystem: pipeline/measure
tags: [image, measure, deterministic]
requires: ["28-01-PLAN"]
provides: ["Image constraints and measurement logic"]
affects: ["lib/rendro/image.ex", "lib/rendro/component.ex", "lib/rendro/pipeline/measure.ex"]
tech-stack:
  added: []
  patterns: ["Component Image Helper", "Aspect-ratio Measurement"]
key-files:
  created:
    - lib/rendro/image.ex
    - test/rendro/component_test.exs
  modified:
    - lib/rendro/component.ex
    - lib/rendro/pipeline/measure.ex
    - test/rendro/pipeline/measure_test.exs
key-decisions:
  - "Decided to enforce constraint dimensions (width, height, or fit) in `Rendro.Component.image/2` to ensure determinism during layout."
  - "Decided to measure missing dimensions in `Rendro.Pipeline.Measure` utilizing the logical_name linked to the asset registry for intrinsic bounds extraction."
metrics:
  duration_minutes: 10
  tasks_completed: 2
  files_modified: 5
---

# Phase 28 Plan 02: Image Layout Component and Constraint Measurement Summary

This plan introduces the Image AST structure and wire it into the measurement pipeline to deterministically calculate missing boundaries using their registered intrinsic constraints.

## Deviations from Plan
None - plan executed exactly as written.

## Known Stubs
None.

## Threat Flags
None.
