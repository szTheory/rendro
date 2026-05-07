---
phase: 16-phoenix-error-boundary-proof
plan: 01
subsystem: adapters
tags:
  - phoenix
  - error-handling
  - json
  - api-boundary
requires: []
provides:
  - Format-aware error responses in Phoenix adapter (JSON/Text)
affects:
  - lib/rendro/adapters/phoenix.ex
  - test/rendro/adapters/phoenix_test.exs
tech_stack_added: []
tech_stack_patterns:
  - Phoenix format negotiation via `Phoenix.Controller.get_format/1`
  - Explicit mapping of structured error payload to JSON
key_files_created: []
key_files_modified:
  - lib/rendro/adapters/phoenix.ex
  - test/rendro/adapters/phoenix_test.exs
key_decisions:
  - "Explicitly map stable envelope fields (what, where, why, next, stage, render_id) instead of directly encoding `Rendro.Error` to prevent internal leakage (`reason`, `details`)."
  - "Use `try..rescue` block around `Phoenix.Controller.get_format(conn)` to safely fallback to text format if format resolution fails."
metrics:
  duration: 2
  completed_date: "2026-04-28"
---

# Phase 16 Plan 01: Phoenix Format-Aware Error Response Summary

Implement Phoenix format-aware error handling to securely return a structured JSON response for API requests and text fallback for others.

## TDD Gate Compliance
- `test(16-01): add failing test for Phoenix adapter JSON error response` (RED)
- `feat(16-01): implement Phoenix format-aware error response` (GREEN)

## Deviations from Plan

- None - plan executed exactly as written, with minor assertion fixes to align with true error field values.

## Threat Flags

None.
## Self-Check: PASSED
