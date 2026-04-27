---
phase: 06-pipeline-telemetry-contract
plan: 01
subsystem: pipeline-telemetry
tags: [elixir, telemetry, observability, pipeline, contract, schema]
requires:
  - lib/rendro/telemetry.ex
  - lib/rendro/pipeline.ex
  - lib/rendro/error.ex
  - test/rendro/telemetry_test.exs
  - test/rendro/error_test.exs
provides:
  - "Rendro.Telemetry.stage_names/0 returns 6 stages including :validate"
  - "Rendro.Telemetry.all_event_names/0 includes [:rendro, :pipeline, :validate, :start | :stop | :exception]"
  - "Unified Rendro.Pipeline.stage_stop_meta/5 emitting D-11 schema"
  - "Rendro.Pipeline.build_stop_meta/3 mirrors stage schema (D-16)"
  - "Rendro.Error.from_stage(:validate, reason, ctx) for 3 new reasons"
affects:
  - "test/rendro/telemetry_test.exs — 6 pre-existing tests tagged @pending_full_pipeline (Plan 03 unblocks)"
  - "test/support/telemetry_helper.ex — auto-subscribes to :validate events via all_event_names/0 (no edit)"
tech-stack:
  added: []
  patterns:
    - "Single unified stop_meta builder per Keathley telemetry conventions (optional :error key on :stop)"
    - "Stable D-11 stop schema across success and error paths"
    - "Error-path page_count derivation from latest doc state (closes MINOR-15)"
key-files:
  created: []
  modified:
    - lib/rendro/telemetry.ex
    - lib/rendro/pipeline.ex
    - lib/rendro/error.ex
    - test/rendro/telemetry_test.exs
    - test/rendro/error_test.exs
key-decisions:
  - "Apply D-19 with :pending_full_pipeline tag strategy: contract assertions live in code from Wave 1; Plans 02/03 remove tags as their waves land"
  - "Apply assumption A1 (RESEARCH.md): include :validate in derive_byte_size/2 alongside :render so future :validate stop events report real bytes — no contract regression, simple one-clause addition"
  - "Apply assumption A2 (RESEARCH.md): map error.kind => error.reason in :error stop_meta map (Rendro.Error has :reason, not :kind)"
  - "Retain defensive defp next_step(:render, :max_bytes_exceeded) clause per RESEARCH.md A4 — small surface, future-proof against attribution drift"
metrics:
  duration_min: 5
  completed: 2026-04-27
requirements_marked_complete: []
requirements_partial: [OBS-01, OBS-02]
threat_flags: []
---

# Phase 06 Plan 01: Pipeline Telemetry Contract — Wave 1 Plumbing Summary

**One-liner:** Reserves the `:validate` event prefix surface, unifies stage stop_meta into a single D-11/D-14 builder closing MINOR-15, and adds `Rendro.Error` `:validate` clauses — all without touching pipeline orchestration order or stage logic.

## What Shipped

### Closed
- **MINOR-15** (error-path metric loss). Both `stage_stop_meta/5` and `build_stop_meta/3` now derive `page_count` from the latest known doc state (`length(doc.pages)`) on the error path, never the hardcoded `0`. Verified by the `MINOR-15 regression` test (`test/rendro/telemetry_test.exs`).

### Reserved
- **OBS-01 contract surface (partial).** `Rendro.Telemetry.stage_names/0` and `all_event_names/0` now expose `:validate` event names (`[:rendro, :pipeline, :validate, :start | :stop | :exception]`) so dashboards and the test helper can subscribe ahead of the actual stage emission. Wiring of the `:validate` span lands in Plan 02; the spec stage order lands in Plan 03.

### D-11 Unified Stop Schema (live as of this plan)
Every `[:rendro, :pipeline, *, :stop]` event and the top-level `[:rendro, :render, :stop]` event now carry the same seven keys:

```
%{
  render_id:     String.t(),
  document_type: :pdf,
  deterministic: boolean(),
  stage:         atom(),
  status:        :ok | :error,
  page_count:    non_neg_integer(),
  byte_size:     non_neg_integer()
}
```

On `status: :error`, the stop_meta also carries `:error => %{kind: error.reason, stage: error.stage}` (D-14, mapping `kind` → `Rendro.Error.reason` per A2).

### D-09 Error Strings
`Rendro.Error.from_stage(:validate, reason, ctx)` now returns properly populated structs for three reasons:
- `:structural_corruption` → `next` mentions `"PDF header/trailer missing"` and asks for a bug report.
- `:page_count_mismatch` → `next` mentions `"Rendered page count diverged"` and asks for a bug report.
- `:max_bytes_exceeded` → `next` references the `:max_bytes` policy limit.

The `where` field auto-derives to `Rendro.Pipeline.Validate` via the existing `Macro.camelize/1` plumbing — no `from_stage/3` edit required.

## Tasks

| # | Task | Commits | TDD Gate |
|---|------|---------|----------|
| 1 | Add `:validate` to `@stage_names`; rewrite test contract for new shape | `d94ff88` (RED), `5b032e5` (GREEN) | RED→GREEN |
| 2 | Unify `stage_stop_meta` into D-11/D-12/D-13/D-14 builder; update `build_stop_meta/3` for D-16 | `eaf3649` (RED), `e4f5b7c` (GREEN) | RED→GREEN |
| 3 | Add `Rendro.Error` `what`/`next_step` clauses for `:validate` | `67371c1` (RED), `117f449` (GREEN) | RED→GREEN |

## Files Modified

| File | Change |
|------|--------|
| `lib/rendro/telemetry.ex` | `@stage_names` extended to 6 entries (`:validate` appended). Cascades through `@event_prefixes`, `event_prefixes/0`, `stage_names/0`, `all_event_names/0`. |
| `lib/rendro/pipeline.ex` | `@moduledoc` order updated to `build -> compose -> measure -> paginate -> render -> validate` (canonical contract per D-01; orchestrator stays in old order until Plan 03). `build_stop_meta/3` rewritten for D-12/D-14/D-16 (both branches use `length(doc.pages)`; error branch adds `:error` map). `span/4` replaced with simpler delegation to single `stage_stop_meta/5`. New `derive_page_count/2` (3 clauses) and `derive_byte_size/2` (3 clauses including pre-emptive `:validate` per A1). Old 3-clause `stage_stop_meta/3` removed. |
| `lib/rendro/error.ex` | Added `defp what(:validate, _)` clause before catch-all. Added 3 `defp next_step(:validate, ...)` clauses between existing `:render :timeout` and `:render _reason` fallback. Defensive `:render :max_bytes_exceeded` clause retained per A4. |
| `test/rendro/telemetry_test.exs` | 5 stage-iterator literals updated from old order to D-01 spec order. 6 tests tagged `@tag :pending_full_pipeline` (await Plan 03). New `describe "stage_names contract (Phase 6 OBS-01)"` block (2 tests, live now). New `describe "unified stop_meta schema (Phase 6 D-11)"` block (3 tests, live now after Task 2). Tag inventory comment block at top of module. |
| `test/rendro/error_test.exs` | New `describe "from_stage/3 with stage :validate (Phase 6 D-09)"` block (4 tests). |

## Deviations from Plan

None. Plan 06-01 was executed exactly as written, including all assumptions noted in RESEARCH.md (A1, A2, A4) which CONTEXT.md flagged as Claude's Discretion.

## Authentication Gates

None.

## Tag Inventory (handoff to Plans 02 and 03)

These tests are tagged `@tag :pending_full_pipeline` and currently excluded from `mix test --exclude pending_full_pipeline`. Plan 03's executor must remove the `@tag` line above each as the `:validate` emission and stage reorder land:

| Test (in `test/rendro/telemetry_test.exs`) | Reason |
|-------------------------------------------|--------|
| `"all 6 pipeline stages emit start and stop events"` | Asserts `:validate` start+stop emit; needs Plan 02 wiring + Plan 03 reorder |
| `"total event count: 6 stages + 1 top-level = 14 (7 start + 7 stop)"` | Counts go from `6` → `7` once `:validate` emits |
| `"each stage start event has the correct stage name"` | Iterates over 6 stages including `:validate` |
| `"stages after the failed stage do not emit events"` | Iterates over 5 stages including `:validate` (excludes `:build`) |
| `"events fire in pipeline stage order"` | Asserts the full canonical 6-stage order |
| `"each stage start fires before its stop"` | Iterates over 6 stages including `:validate` |

`@tag :pending_unified_schema` was introduced AND removed within this plan (Task 1 introduced the tag, Task 2 removed it once `stage_stop_meta` was unified). No remaining occurrences (`grep -c '@tag :pending_unified_schema' test/rendro/telemetry_test.exs` returns `0`).

## Verification Commands Run

| Command | Exit | Notes |
|---------|------|-------|
| `mix compile --warnings-as-errors` | 0 | Clean compile after each task |
| `mix format --check-formatted` | 0 | Whole tree clean |
| `mix format --check-formatted lib/rendro/pipeline.ex lib/rendro/error.ex lib/rendro/telemetry.ex test/rendro/telemetry_test.exs test/rendro/error_test.exs` | 0 | Per-file confirmation |
| `mix test test/rendro/telemetry_test.exs --exclude pending_full_pipeline --exclude pending_unified_schema` (after Task 1) | 0 | 21 tests, 0 failures, 9 excluded |
| `mix test test/rendro/telemetry_test.exs --exclude pending_full_pipeline` (after Task 2) | 0 | 24 tests, 0 failures, 6 excluded |
| `mix test test/rendro/error_test.exs` (after Task 3) | 0 | 6 tests, 0 failures |
| `mix test test/rendro/adapters/threadline_test.exs` | 0 | 8 tests, 0 failures — D-20 partial (full re-run lives in Plan 03 once stages reorder) |
| `mix test test/rendro/policy_test.exs` | 0 | 3 tests, 0 failures — `:max_bytes_exceeded` still attributed to `:render` (correct: Plan 02 moves it) |
| `mix test --exclude pending_full_pipeline` (final) | 0 | 3 properties, 194 tests, 0 failures, 6 excluded |

## Acceptance Criteria Spot-Checks

```
$ grep -F '@stage_names [:build, :compose, :measure, :paginate, :render, :validate]' lib/rendro/telemetry.ex
  @stage_names [:build, :compose, :measure, :paginate, :render, :validate]

$ grep -c -F 'defp stage_stop_meta(' lib/rendro/pipeline.ex
1

$ grep -c -F 'defp derive_page_count(' lib/rendro/pipeline.ex
3

$ grep -c -F 'defp derive_byte_size(' lib/rendro/pipeline.ex
3

$ grep -c -F 'page_count: 0, byte_size: 0' lib/rendro/pipeline.ex
0

$ grep -c -F 'defp what(:validate' lib/rendro/error.ex
1

$ grep -c -F 'defp next_step(:validate' lib/rendro/error.ex
3

$ grep -c -F 'defp next_step(:render, :max_bytes_exceeded)' lib/rendro/error.ex
1

$ grep -c -F '@tag :pending_unified_schema' test/rendro/telemetry_test.exs
0

$ grep -c -F '[:build, :measure, :paginate, :compose, :render]' test/rendro/telemetry_test.exs
0
```

## Carry-Forward to Plans 02 / 03

- **Plan 02** (`Rendro.Pipeline.Validate` module + max_bytes absorption): Will land the actual span emission. Once the `:validate` span fires, `derive_byte_size(:validate, pdf)` already returns real bytes (A1 pre-emption); no further `pipeline.ex` edits expected for the byte_size signal.
- **Plan 03** (responsibility shuffle + stage reorder + final `with` chain): Removes the 6 `@tag :pending_full_pipeline` lines listed above. Updates `pipeline.ex` `run_stages/3` to canonical order. Re-runs Threadline + policy tests as part of D-20 final verification.

## Self-Check: PASSED

**Files claimed:**
- `lib/rendro/telemetry.ex` — FOUND (modified)
- `lib/rendro/pipeline.ex` — FOUND (modified)
- `lib/rendro/error.ex` — FOUND (modified)
- `test/rendro/telemetry_test.exs` — FOUND (modified)
- `test/rendro/error_test.exs` — FOUND (modified)

**Commits claimed (all in `git log`):**
- `d94ff88` test(06-01): add failing telemetry contract tests
- `5b032e5` feat(06-01): add :validate to telemetry stage_names
- `eaf3649` test(06-01): activate unified stop_meta schema tests (RED)
- `e4f5b7c` feat(06-01): unify stage_stop_meta builder
- `67371c1` test(06-01): add failing :validate stage error tests
- `117f449` feat(06-01): add Rendro.Error :validate clauses

All claims verified.
