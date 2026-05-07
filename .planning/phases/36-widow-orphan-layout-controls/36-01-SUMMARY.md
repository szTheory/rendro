---
phase: 36
plan: 01
subsystem: layout
tags: [widows, orphans, text, measure]
dependency_graph:
  requires: []
  provides: [widow_orphan_schema]
  affects: [measure_pipeline]
tech_stack:
  added: []
  patterns: [struct_propagation]
key_files:
  created: []
  modified:
    - lib/rendro/text.ex
    - test/rendro/text_test.exs
    - lib/rendro/pipeline/measured_text.ex
    - lib/rendro/pipeline/measure.ex
    - test/rendro/pipeline/measure_test.exs
decisions:
  - Keep default widows/orphans as 2 to match standard typographic defaults.
metrics:
  duration: 5m
  completed_date: 2026-05-04
---

# Phase 36 Plan 01: Widow/Orphan Layout Controls Schema Summary

Update core schemas and the measure pipeline to carry widow and orphan configuration.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None

## Self-Check: PASSED
