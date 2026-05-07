---
phase: "21-break-diagnostics-and-pagination-proofs"
plan: 1
subsystem: "layout-diagnostics"
tags: ["diagnostics", "pagination", "observability"]
requires: ["20-table-layout-maturity"]
provides: ["diagnostic tracking for breaks and splits"]
affects: ["Rendro.Pipeline.Paginate", "Rendro.Document"]
tech-stack:
  added: []
  patterns: ["Changeset-like accumulation of diagnostics"]
key-files:
  created: []
  modified:
    - lib/rendro/document.ex
    - lib/rendro/pipeline/paginate.ex
    - test/rendro/document_test.exs
    - test/rendro/pipeline/paginate_test.exs
decisions:
  - Added a `diagnostics` list to `Rendro.Document` to accumulate pagination info without raising exceptions or spamming telemetry.
metrics:
  duration: 1
  completed_date: "2026-04-29T21:19:08Z"
---

# Phase 21 Plan 01: Diagnostic Pagination Tracking Summary

Implement structured diagnostics to the document pipeline to make non-fatal layout decisions transparent and observable.

## Execution Outcomes

- Added a `diagnostics: []` field to `%Rendro.Document{}`.
- Refactored `Rendro.Pipeline.Paginate` to accumulate `diagnostics` during the recursion of block layout instead of throwing or swallowing edge cases.
- Recorded `:table_split` events when tables span across pages.
- Recorded `:keep_rule_break` events when elements are pushed to a new page due to keep-with-next or keep-together.
- Also fixed several formatting issues automatically detected by `mix format` in related files like Oban workers, tests, and Release Preflight scripts.

## Deviations from Plan

None.

## Known Stubs

None.

## Threat Flags

None.

## Self-Check: PASSED