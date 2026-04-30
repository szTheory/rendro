---
phase: 22-authoring-ergonomics-and-canonical-recipes
plan: 01
subsystem: api
tags: [elixir, document, builder, pipeline, struct]

# Dependency graph
requires: []
provides:
  - "Rendro.Document.new/0 — returns an empty Document struct"
  - "Rendro.Document.new/1 — creates Document from keyword options"
  - "Rendro.Document.put_metadata/2 — replaces document metadata"
  - "Rendro.Document.add_template/2 — appends a PageTemplate to the document"
  - "Rendro.Document.set_template/2 — sets the active page_template name"
  - "Rendro.Document.add_section/2 — appends a Section to the document"
  - "Rendro.Document.put_options/2 — merges options into the document"
affects:
  - 22-02
  - 22-03

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Pipeline builder pattern on Document struct (mirroring Plug.Conn / Ecto.Changeset ergonomics)"
    - "AST-based struct assertions in ExUnit tests instead of binary PDF assertions"

key-files:
  created: []
  modified:
    - lib/rendro/document.ex
    - test/rendro/document_test.exs

key-decisions:
  - "Expose pipeline builder API directly on Rendro.Document module to keep function discovery co-located with the struct definition"
  - "Use append semantics (list ++ [item]) for add_template/2 and add_section/2 to preserve insertion order"
  - "Use Map.merge/2 for put_options/2 to allow incremental option accumulation over multiple pipe stages"

patterns-established:
  - "Pipeline builder: Document.new() |> put_metadata() |> add_template() |> set_template() |> add_section() |> put_options()"
  - "AST testing: assert on %Rendro.Document{} field values rather than rendered PDF binary"

requirements-completed:
  - LAY-12

# Metrics
duration: 5min
completed: 2026-04-30
---

# Phase 22 Plan 01: Pipeline Builder API Summary

**Pipeable builder API on Rendro.Document enabling dynamic document composition via new/0, put_metadata/2, add_template/2, set_template/2, add_section/2, and put_options/2**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-04-30T11:40:00Z
- **Completed:** 2026-04-30T11:42:33Z
- **Tasks:** 1 (TDD: RED + GREEN)
- **Files modified:** 2

## Accomplishments

- Builder API implemented as pure struct transformation functions on `Rendro.Document`, matching Plug.Conn / Ecto.Changeset ergonomics
- 8 new unit tests covering all builder functions plus a full pipe composition test; all 11 document tests green
- Full `@spec` and `@doc` annotations on every builder function; `@moduledoc` updated with usage example

## Task Commits

1. **Task 1: Add Pipeline Builder API to Rendro.Document (RED)** - `be66084` (test)
2. **Task 1: Add Pipeline Builder API to Rendro.Document (GREEN)** - `a5ee8f6` (feat)

## Files Created/Modified

- `lib/rendro/document.ex` - Added `new/0`, `new/1`, `put_metadata/2`, `add_template/2`, `set_template/2`, `add_section/2`, `put_options/2` with specs and docs
- `test/rendro/document_test.exs` - Added 8 AST-based tests for the builder API in a new `"pipeline builder API"` describe block

## Decisions Made

- Builder functions live in `Rendro.Document` directly (not a separate `Rendro.Document.Builder` module) for co-location and simpler imports
- `add_template/2` and `add_section/2` use `list ++ [item]` to preserve insertion order, which matters for template/section lookup by the pipeline stages
- `put_options/2` uses `Map.merge/2` so multiple `put_options` calls accumulate keys without requiring the caller to hold interim state

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Builder API is live and test-covered; Phase 22 Plan 02 can reference `Rendro.Document.new/0` and the builder chain as the canonical document construction path in recipes and examples
- No blockers

---
*Phase: 22-authoring-ergonomics-and-canonical-recipes*
*Completed: 2026-04-30*

## Self-Check: PASSED

- `lib/rendro/document.ex` — FOUND
- `test/rendro/document_test.exs` — FOUND
- RED commit `be66084` — FOUND
- GREEN commit `a5ee8f6` — FOUND
- `mix test test/rendro/document_test.exs` — 11 tests, 0 failures
- `mix test` — 298 tests, 0 failures
