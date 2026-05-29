---
phase: 73-page-numbering-running-region-primitive
plan: "04"
subsystem: pipeline
tags: [elixir, pdf, paginate, running-region, suppression, page-numbering, tdd-green, PAGE-02]

requires:
  - phase: 73-03
    provides: "replace_page_numbers/3 with total param; apply_page_template/4 seam comment"

provides:
  - "Rendro.RunningContent struct with @enforce_keys [:fun] — per-page fn primitive (D-01/D-03)"
  - "Rendro.Section.suppress_on field with @type suppress_on :: nil | :first | {:pages, [pos_integer()]}"
  - "Rendro.page_number/1 helper producing Block{content: Text{content: 'Page {{page_number}} of {{total_pages}}'}}"
  - "evaluate_fn_blocks/3 in paginate.ex — calls RunningContent.fun per page with try/rescue"
  - "apply_suppression/3 in paginate.ex — resolves declarative selector before fn evaluation (D-07)"
  - "region_suppress_on map in compose.ex layout — carries suppress_on from sections to paginate stage"
  - "All PAGE-02 Wave 0 stubs GREEN; only D-11 determinism stubs remain RED"

affects:
  - "73-05: D-11 determinism tests consume the RunningContent fn primitive"
  - "74-76: Statement/Receipt/Certificate recipes use section(suppress_on: :first) and page_number/1"

tech-stack:
  added: []
  patterns:
    - "RunningContent fn evaluation: Enum.flat_map with try/rescue on each block matching %Rendro.RunningContent{fun: fun}"
    - "Selector precedence: apply_suppression before evaluate_fn_blocks before replace_page_numbers in pipeline"
    - "D-08 iron rule: apply_suppression returns [] for suppressed pages but maybe_validate_region_fit uses region.height"
    - "region_suppress_on map: built in compose.ex from sections with suppress_on != nil, threaded via layout map"
    - "Error surfacing: raising fn caught, re-raised as Rendro.Error.from_stage(:paginate, {:running_content_error, ...})"

key-files:
  created:
    - lib/rendro/running_content.ex
  modified:
    - lib/rendro/section.ex
    - lib/rendro.ex
    - lib/rendro/pipeline/compose.ex
    - lib/rendro/pipeline/paginate.ex
    - test/rendro/flow_test.exs
    - test/rendro/pipeline/paginate_test.exs

key-decisions:
  - "Region suppress_on carried through compose.ex layout map as region_suppress_on: %{region_name => suppress_on_value}; accessed in apply_page_template/4 via Map.get(layout, :region_suppress_on, %{})"
  - "evaluate_fn_blocks/3 returns flat list — RunningContent fn returns list of blocks which are spliced in-place; nil/[] returns empty (visual suppression via fn)"
  - "Raising fn re-raised as Rendro.Error struct (not returned as tuple) for consistent error propagation through the pipeline throw/catch pattern"
  - "apply_suppression/3 has pass-through _ clause for unknown selector shapes (forward-compat, T-73-05)"
  - "flow_layout/1 path does not need region_suppress_on since it has no sections; Map.get with default %{} handles both paths"

patterns-established:
  - "suppression pipeline order: apply_suppression/3 → evaluate_fn_blocks/3 → replace_page_numbers/3 → anchor_region_blocks/3"
  - "compose.ex layout map extension: add parallel keys (region_suppress_on) alongside region_blocks when adding per-region metadata"

requirements-completed:
  - PAGE-02

duration: 3min
completed: "2026-05-29"
---

# Phase 73 Plan 04: PAGE-02 RunningContent Primitive, suppress_on, page_number/1

**`Rendro.RunningContent` fn primitive with per-page evaluation, `Section.suppress_on` declarative selector, and `Rendro.page_number/1` token-sugar helper — all PAGE-02 Wave 0 stubs GREEN**

## Performance

- **Duration:** ~3 min
- **Started:** 2026-05-29T16:17:16Z
- **Completed:** 2026-05-29T16:20:31Z
- **Tasks:** 2
- **Files modified:** 6 (+ 1 created)

## Accomplishments

- Created `lib/rendro/running_content.ex`: `%Rendro.RunningContent{fun: fn}` struct with `@enforce_keys [:fun]` and `@type t` — the per-page function primitive (D-01/D-03)
- Extended `lib/rendro/section.ex`: added `suppress_on: nil` field, `@type suppress_on :: nil | :first | {:pages, [pos_integer()]}`, widened `content:` typespec to include `RunningContent.t()`
- Added `Rendro.page_number/1` to `lib/rendro.ex`: sugar producing `%Block{content: %Text{content: "Page {{page_number}} of {{total_pages}}"}}` with optional `:format` override
- Added `region_suppress_on` map to `lib/rendro/pipeline/compose.ex` layout (built from sections with non-nil `suppress_on`)
- Wired `evaluate_fn_blocks/3` and `apply_suppression/3` into `apply_page_template/4` at the Plan 03 seam comment; selector checked BEFORE fn call (D-07 precedence)
- Suppression returns `[]` for rendering but `maybe_validate_region_fit` still uses `region.height` (D-08 iron rule preserved)
- Implemented all 4 Wave 0 stubs: fn evaluation, suppression body_capacity, suppress_on:first, body-no-overlap

## Task Commits

1. **Task 1: RunningContent struct, Section.suppress_on, page_number/1 helper** - `b6a9538` (feat)
2. **Task 2: fn evaluation and suppression wired into apply_page_template/4** - `d2d5500` (feat)

## Files Created/Modified

- `/Users/jon/projects/rendro/lib/rendro/running_content.ex` — New: `%Rendro.RunningContent{fun: fn}` struct with enforce_keys and typespec
- `/Users/jon/projects/rendro/lib/rendro/section.ex` — Added `suppress_on: nil` field, `@type suppress_on`, widened content typespec
- `/Users/jon/projects/rendro/lib/rendro.ex` — Added `page_number/1` helper after `section/1`
- `/Users/jon/projects/rendro/lib/rendro/pipeline/compose.ex` — Added `region_suppress_on` map to layout (from sections)
- `/Users/jon/projects/rendro/lib/rendro/pipeline/paginate.ex` — Added `evaluate_fn_blocks/3`, `apply_suppression/3`, wired both into `apply_page_template/4`
- `/Users/jon/projects/rendro/test/rendro/flow_test.exs` — Implemented suppress_on:first and body-no-overlap stubs
- `/Users/jon/projects/rendro/test/rendro/pipeline/paginate_test.exs` — Implemented fn-eval and suppression-body_capacity stubs

## Decisions Made

**region_suppress_on carried via layout map:** Rather than threading suppress_on through the block list (impossible without metadata) or adding a new field to Region structs (over-engineering), the `region_suppress_on` map is built in `compose.ex` alongside `region_blocks` and stored on the layout map. `apply_page_template/4` reads it with `Map.get(layout, :region_suppress_on, %{})` — the `%{}` default makes the `flow_layout/1` fallback path (no sections, no compose) work transparently.

**Raising fn surfaced via re-raise (not return tuple):** The paginate stage uses a `throw/catch` pattern for errors (`{:error, :content_overflow, details}`). Returning error tuples from `evaluate_fn_blocks` would require collecting and threading them through `Enum.flat_map` then filtering — complex and divergent from project style. Instead, a raised `Rendro.Error` is re-raised inside `evaluate_fn_blocks` which propagates naturally through the existing `catch {:error, ...}` in `paginate_flow/1`.

**pass-through `_` clause in apply_suppression:** Per T-73-05, unknown selector shapes silently render all blocks. This is intentional forward-compat behavior matching the plan's threat model disposition of `accept` for T-73-05.

## Deviations from Plan

None — plan executed exactly as written. The `evaluate_fn_blocks/3` name in the plan maps to a `Enum.flat_map`-based implementation (not an `Enum.map` then filter approach). The re-raise error pattern was chosen over tuple surfacing for pipeline consistency, which is within the Claude's Discretion allowance for error handling.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- All PAGE-02 stubs GREEN; only 4 D-11 determinism stubs remain RED (Plan 05 scope)
- `Rendro.RunningContent`, `Rendro.page_number/1`, and `Section.suppress_on` are public API surfaces ready for recipes 74–76
- Plan 73-05 (determinism tests) can proceed: `RunningContent` fn primitive and suppression are available

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: fn-exception | lib/rendro/pipeline/paginate.ex | Per-page fn raises: caught in evaluate_fn_blocks/3, re-raised as Rendro.Error — T-73-04 mitigated |

## Known Stubs

None — all implementation complete. D-11 determinism stubs in `test/rendro/deterministic_test.exs` remain RED by design (Plan 05 scope).

## Self-Check: PASSED

- [x] `lib/rendro/running_content.ex` exists — `b6a9538` confirmed
- [x] `lib/rendro/section.ex` has `suppress_on` — `b6a9538` confirmed
- [x] `lib/rendro.ex` has `page_number/1` — `b6a9538` confirmed
- [x] `lib/rendro/pipeline/paginate.ex` has `evaluate_fn_blocks` — `d2d5500` confirmed
- [x] `mix test test/rendro_builders_test.exs test/rendro/pipeline/paginate_test.exs test/rendro/flow_test.exs` — 83 tests, 0 failures
- [x] `mix test` full suite — 741 tests, 4 failures (D-11 stubs only, as expected)
- [x] `mix compile` exits 0
- [x] D-08 verified: body_capacity equal with/without suppression (test in paginate_test.exs)
- [x] D-07 verified: apply_suppression before evaluate_fn_blocks in pipeline
