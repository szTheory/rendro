---
phase: 06-pipeline-telemetry-contract
plan: 03
subsystem: pipeline-orchestration
tags: [elixir, pipeline, refactor, layout, telemetry, pagination]
requires:
  - lib/rendro/pipeline.ex
  - lib/rendro/pipeline/compose.ex
  - lib/rendro/pipeline/measure.ex
  - lib/rendro/pipeline/paginate.ex
  - test/rendro/telemetry_test.exs
  - test/rendro/pipeline/compose_test.exs
  - test/rendro/pipeline/measure_test.exs
  - test/rendro/pipeline/paginate_test.exs
provides:
  - "Rendro.Pipeline.run_stages/3 with-chain in canonical order: build → compose → measure → paginate → render → validate"
  - ":max_pages policy guard runs AFTER :paginate and BEFORE :render (D-10)"
  - "Rendro.Pipeline.Compose owns normalize_row/1 (D-02); no y-stacking, no metrics"
  - "Rendro.Pipeline.Measure is a pure metric pass over already-normalized rows (D-03); idempotent"
  - "Rendro.Pipeline.Paginate owns y-stacking via stack_block_y/1 with per-page cursor reset (D-04)"
  - "page-2 first content block y resets to page margin_top, never inheriting from page-1 last block"
  - "all 6 :pending_full_pipeline tags removed from telemetry_test.exs; canonical stage-order assertion is live"
affects:
  - "test/rendro/flow_test.exs — table flow tests (Compose now also normalizes doc.content)"
  - "lib/rendro/adapters/threadline.ex — verified unaffected (D-20)"
  - "Phase 11 — reserves the locked telemetry contract for verification reconstruction"
tech-stack:
  added: []
  patterns:
    - "Stage responsibility map (assemble tree → measure → paginate-with-y-stacking) matches CSS/WeasyPrint/TeX/Typst/ReportLab/react-pdf-Yoga industry idiom"
    - "Per-page y-cursor reset via Enum.map(&stack_block_y/1) at the end of paginate_flow/1's pages pipeline"
    - "Unconditional y override in flow context (matches commit 093f32c original); Block default `y: 0` makes `||` fallthrough unsafe for stacking"
    - "Compose normalizes BOTH doc.pages and doc.content so Paginate's table cell stacker never sees raw binaries"
key-files:
  created: []
  modified:
    - lib/rendro/pipeline.ex
    - lib/rendro/pipeline/compose.ex
    - lib/rendro/pipeline/measure.ex
    - lib/rendro/pipeline/paginate.ex
    - test/rendro/pipeline/paginate_test.exs
    - test/rendro/telemetry_test.exs
    - .planning/phases/06-pipeline-telemetry-contract/06-VALIDATION.md
key-decisions:
  - "[Rule 1 - Bug] stack_block_y/1 unconditionally assigns current_y instead of `block.y || current_y`. Block defaults `y: 0` (truthy), so the `||` fallthrough that exists in the post-Phase-4 compose code froze every flow block at y=0; we restore the original 093f32c override semantic so flow content stacks vertically. Fixed-position pages (where users set explicit y) bypass this helper because Paginate.run/1 returns them unchanged."
  - "[Rule 1 - Bug] Compose now normalizes doc.content as well as doc.pages. Without this, flow tables (rows of bare strings) crash in Paginate.stack_table_cells/1 attempting %{cell | x: x, y: y} on a binary. The plan only specified content-pages normalization for Compose, but D-02 says Compose is the single owner of normalize_row, which means content-side tables must be normalized here too."
patterns-established:
  - "Page-level y-stacking always lives in Paginate, never Compose"
  - "Telemetry stage start order is now an enforced contract (no `:pending_full_pipeline` opt-out)"
requirements-completed: [OBS-01, CORE-01]
metrics:
  duration_min: 14
  completed: 2026-04-27
---

# Phase 06 Plan 03: Pipeline Telemetry Contract — Wave 3 Stage Reorder + Responsibility Shuffle Summary

**Lands the canonical `:build → :compose → :measure → :paginate → :render → :validate` stage order in `Rendro.Pipeline.run_stages/3` and shuffles responsibilities so Compose owns `normalize_row/1`, Measure is a pure metric pass, and Paginate owns y-stacking with per-page cursor reset — closing BLOCKER-05 and the latent D-04 page-2 y-inheritance bug, with the Threadline adapter verified unaffected (D-20).**

## Performance

- **Duration:** ~14 min (plus reading + diagnosis time)
- **Started:** 2026-04-27T10:54:18Z (worktree spawn)
- **Completed:** 2026-04-27T11:08:00Z (final verification clean)
- **Tasks:** 3 of 3
- **Files modified:** 7 (4 lib, 2 test, 1 validation doc)
- **Commits:** 5 (test/feat/test/feat/docs)

## Accomplishments

- **Closed BLOCKER-05.** `Rendro.Pipeline.run_stages/3` now executes stages in canonical order: `:build → :compose → :measure → :paginate → :max_pages-guard → :render → :validate`.
- **Closed D-04 latent bug.** Page-2 remainder rows in flow content now have y-coordinates relative to page 2's `margin_top` instead of inheriting page-1's last-block bottom y. Asserted by a new regression test.
- **Locked the architectural responsibility map.** `Compose` is now the single owner of `normalize_row/1`; `Measure` operates only on pre-normalized rows and stays pure-metric/idempotent; `Paginate` owns the `current_y` cursor.
- **Removed all 6 `:pending_full_pipeline` tags.** The full canonical telemetry contract is asserted live; `mix test` runs without exclusions.
- **D-20 verified.** `mix test test/rendro/adapters/threadline_test.exs` passes 8/8 unchanged after the stage reorder — adapter subscribes to top-level `[:rendro, :render, :*]` only, isolated from stage-event surface changes.
- **VALIDATION.md sign-off.** `nyquist_compliant: true`, `wave_0_complete: true`, all 6 sign-off boxes ticked, per-task verification map populated with 10 rows across all three plans + a phase-gate row, `Approval: approved`.

## Task Commits

Each task was committed atomically with TDD discipline (RED → GREEN where applicable):

1. **Task 1 RED — Remove `:pending_full_pipeline` tags** — `14f534e` `test(06-03): remove :pending_full_pipeline tags to expose stage-order failure`
2. **Task 1 GREEN — Reorder `run_stages/3`** — `c177311` `feat(06-03): reorder run_stages to canonical D-01 stage order`
3. **Task 2 RED — Add D-04 regression test** — `ae3bd63` `test(06-03): add D-04 page-2 remainder y-inheritance regression test`
4. **Task 2 GREEN — Responsibility shuffle (Compose/Measure/Paginate)** — `8d7a2b2` `feat(06-03): shuffle responsibilities — Compose owns normalize_row, Paginate owns y-stacking`
5. **Task 3 — Validation sign-off** — `f649b8c` `docs(06-03): mark phase 06 validation strategy approved + nyquist-compliant`

_Note: Task 3 had no separate RED gate — it is a documentation + verification task whose `<verify>` step covers full-suite green._

## Files Created/Modified

| File | Change |
|------|--------|
| `lib/rendro/pipeline.ex` | `run_stages/3` `with`-chain reordered: `:compose` now runs between `:build` and `:measure`; `validate_policy(:pages)` placement preserved between `:paginate` and `:render` (D-10). `@moduledoc` rewritten — drops the temporary "compose and measure inverted" caveat from Plan 02 and gains a paragraph describing the dual-policy guard placement (`:max_pages` inline post-paginate vs. `:max_bytes` inside `:validate`). |
| `lib/rendro/pipeline/compose.ex` | Y-stacking `Enum.reduce(blocks, {[], 0}, ...)` and the `compose_row/4` helper REMOVED. `compose_block/1` for `%Rendro.Table{}` simplified to ONLY normalize header/rows. `normalize_row/1` MOVED IN verbatim from `measure.ex`. `Compose.run/1` extended to also normalize `doc.content` (flow path) — without this, table flow tests crash because Paginate's new cell stacker would see raw binaries. `@moduledoc` rewritten to mark Compose as logical-tree-only (no metrics, no y-coordinates). |
| `lib/rendro/pipeline/measure.ex` | `normalize_row/1` REMOVED entirely. The table `measure_block` clause now consumes pre-normalized rows directly (`measure_row(table.header, font)` / `measure_row(&1, font)`). Idempotent metric pass preserved. `@moduledoc` rewritten to call out Compose as the upstream normalizer. |
| `lib/rendro/pipeline/paginate.ex` | `paginate_flow/1` `pages` pipeline gains a final `\|> Enum.map(&stack_block_y/1)` step. New private helpers: `stack_block_y/1` (the per-page y-cursor reduce — `starting_y = margin_top \|\| 0`), `stack_table_cells/1` (header + rows internal y-stacking for tables), `stack_table_cells/1` fallthrough for non-tables, `stack_cells/3` (per-row x-stacking). The fixed-position path (`pages != []`) returns the doc unchanged — explicit user-set x/y preserved. `@moduledoc` rewritten to describe per-page reset semantics. |
| `test/rendro/pipeline/paginate_test.exs` | New `describe "y-stacking with per-page reset (D-04 regression)"` block with one test that builds a 50-line flow doc, runs build → compose → measure → paginate, and asserts (a) ≥2 pages emitted, (b) `page2_min_y < page1_max_y`, (c) `page2_min_y <= page2.margin_top + 50` (page 2 first block near page top). |
| `test/rendro/telemetry_test.exs` | All 6 `@tag :pending_full_pipeline` lines removed. Tag inventory comment block at the top updated to record retirement under Phase 6 Plan 03. The 6 newly live tests are: `"all 6 pipeline stages emit start and stop events"`, `"total event count: 6 stages + 1 top-level = 14 (7 start + 7 stop)"`, `"each stage start event has the correct stage name"`, `"stages after the failed stage do not emit events"`, `"events fire in pipeline stage order"`, `"each stage start fires before its stop"`. |
| `.planning/phases/06-pipeline-telemetry-contract/06-VALIDATION.md` | `nyquist_compliant: false → true`; `wave_0_complete: false → true`. Per-Task Verification Map populated with 10 rows (3 plans × 3 tasks + phase-gate row). All 6 sign-off checkboxes ticked. `Approval: pending → approved`. |

## Decisions Made

- **Unconditional y override in flow stacking.** The plan template specified `y = block.y || current_y` for `stack_block_y/1`, but `Block` defaults `y: 0` (truthy in Elixir), so `||` always selects `block.y` and freezes every flow block at y=0. Switched to unconditional `current_y` assignment in the per-page reduce (`%{block | y: current_y}`), matching the original commit `093f32c` design that worked before a Phase-4-era regression flipped the override into a `||` fallthrough. The fixed-position API path (`pages != []`) doesn't go through `stack_block_y/1`, so user-set explicit y values still pass through unchanged.
- **Compose normalizes `doc.content` as well as `doc.pages`.** D-02 puts Compose as the single owner of `normalize_row/1`. Flow tables live in `doc.content`, not `doc.pages`, when Compose runs (pagination has not yet split). Extending `Compose.run/1` to map over both fields is the natural extension; the alternative (re-introducing normalization inside Paginate or Measure) would violate D-02.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `stack_block_y/1` `block.y || current_y` froze flow blocks at y=0**
- **Found during:** Task 2 GREEN — running the new D-04 regression test after applying the responsibility shuffle.
- **Issue:** Plan-specified `y = block.y || current_y` always selected `block.y` because `%Rendro.Block{}` defaults `y: 0` (truthy). All 50 flow blocks ended up with `y == 0` on both pages, the regression test's `page2_min_y < page1_max_y` failed (both = 0), and the `page2_min_y <= margin_top + 50` check would also have been wrong if reached. The same regression existed in the older `compose_page/1` y-stacking (post-Phase-4 commit `34ada7b`); the original commit `093f32c` worked correctly with `%{block | y: current_y}` (unconditional override).
- **Fix:** Changed `stack_block_y/1` body to use unconditional override matching `093f32c`:
  ```elixir
  Enum.reduce(blocks, {[], starting_y}, fn block, {acc, current_y} ->
    stacked_block = stack_table_cells(%{block | y: current_y})
    next_y = current_y + (block.height || 0)
    {acc ++ [stacked_block], next_y}
  end)
  ```
  Fixed-position pages bypass this helper (`Paginate.run/1` returns `pages != []` docs unchanged), so user-supplied explicit y values are still preserved.
- **Files modified:** `lib/rendro/pipeline/paginate.ex`
- **Verification:** D-04 regression test passes; all 4 paginate tests + 6 flow tests + 35 pipeline-stage tests + 32 telemetry tests green.
- **Committed in:** `8d7a2b2` (Task 2 GREEN).

**2. [Rule 1 - Bug] `Compose.run/1` did not normalize flow-content tables**
- **Found during:** Task 2 GREEN — running `mix test test/rendro/flow_test.exs` after the responsibility shuffle.
- **Issue:** `flow_test.exs` "flow document with table" and "table splitting and header repetition" tests crashed with `(BadMapError) expected a map, got: "Col A"` from `Paginate.stack_cells/3`. Root cause: flow tables sit in `doc.content`, not `doc.pages`. `Compose.run/1` mapped only over `doc.pages` (per the plan), so flow-content table rows reached Paginate as raw `[["A1", "B1"], ...]` binaries. When the new `stack_table_cells/1` helper tried `%{cell | x: x, y: y}` on the binary `"Col A"`, it raised.
- **Fix:** Extended `Compose.run/1` to also `Enum.map(content, &compose_block/1)`:
  ```elixir
  def run(%Rendro.Document{pages: pages, content: content} = doc) do
    composed_pages = Enum.map(pages, &compose_page/1)
    composed_content = Enum.map(content, &compose_block/1)
    {:ok, %{doc | pages: composed_pages, content: composed_content}}
  end
  ```
- **Files modified:** `lib/rendro/pipeline/compose.ex`
- **Verification:** All 6 flow tests green (including table-related and table-splitting). All 217 suite tests green.
- **Committed in:** `8d7a2b2` (Task 2 GREEN).

---

**Total deviations:** 2 auto-fixed (both Rule 1 bug fixes — `stack_block_y` y-override semantic, and Compose content-normalization gap)
**Impact on plan:** Both auto-fixes were necessary to satisfy the plan's stated behavior contract (page-2 reset, table flow tests passing). No scope creep; both changes stay within the pipeline files the plan declared modifying.

## Issues Encountered

- During Task 2 RED, the D-04 regression test failed as expected — but with `page1_max_y == page2_min_y == 0` rather than the expected "y values inherit incorrectly from page 1." This surfaced the underlying `Block.y` default (`0` not `nil`) issue early, leading directly to the Rule 1 fix above. Net: the RED gate was useful even though the failure mode was different than the plan author predicted.
- `mix format --check-formatted` flagged 5 pre-existing unformatted files (already documented in `.planning/phases/06-pipeline-telemetry-contract/deferred-items.md` from Plan 02). Per-file format check on Phase 06 files is green: `mix format --check-formatted lib/rendro/pipeline.ex lib/rendro/pipeline/compose.ex lib/rendro/pipeline/measure.ex lib/rendro/pipeline/paginate.ex test/rendro/pipeline/paginate_test.exs test/rendro/telemetry_test.exs` exits 0.

## Authentication Gates

None.

## Test Inventory

### New tests (this plan)

| File | New describe block | Test count |
|------|-------------------|------------|
| `test/rendro/pipeline/paginate_test.exs` | `"y-stacking with per-page reset (D-04 regression)"` | 1 |

### Tests un-tagged (now live without `--exclude`)

| Test (in `test/rendro/telemetry_test.exs`) | Was tagged | Now passes |
|--------------------------------------------|-----------|------------|
| `"all 6 pipeline stages emit start and stop events"` | `:pending_full_pipeline` | yes |
| `"total event count: 6 stages + 1 top-level = 14 (7 start + 7 stop)"` | `:pending_full_pipeline` | yes |
| `"each stage start event has the correct stage name"` | `:pending_full_pipeline` | yes |
| `"stages after the failed stage do not emit events"` | `:pending_full_pipeline` | yes |
| `"events fire in pipeline stage order"` | `:pending_full_pipeline` | yes |
| `"each stage start fires before its stop"` | `:pending_full_pipeline` | yes |

### Phase 6 cumulative test totals (after this plan)

- Full Rendro suite: **3 properties, 217 tests, 0 failures** in 3.4 s.
- New telemetry tests added across Phase 6: 8 (5 in Plan 01, 2 in Plan 02, 0 here — Plan 03 only un-tagged existing tests).
- New `:validate` stage tests: 14 (Plan 02).
- New regression tests: 1 in Plan 01 (MINOR-15 page_count), 1 in Plan 02 (deterministic-mode regex), 1 in Plan 03 (D-04 page-2 reset).
- Tags retired: 6 `:pending_full_pipeline` (this plan).

## Verification Commands Run

| Command | Exit | Notes |
|---------|------|-------|
| `mix compile --warnings-as-errors` | 0 | Clean compile after each task |
| `mix format --check-formatted lib/rendro/pipeline.ex` | 0 | Per-file format check after Task 1 |
| `mix format --check-formatted lib/rendro/pipeline/{compose,measure,paginate}.ex test/rendro/pipeline/paginate_test.exs test/rendro/telemetry_test.exs` | 0 | Per-file format check after Task 2 |
| `mix test test/rendro/telemetry_test.exs` (after Task 1) | 0 | 32 tests, 0 failures |
| `mix test test/rendro/pipeline/` (after Task 2) | 0 | 35 tests, 0 failures (compose 3, measure 4, paginate 4 incl. D-04, validate 14, build 6, render 4) |
| `mix test test/rendro/flow_test.exs` (after Task 2) | 0 | 6 tests, 0 failures |
| `mix clean && mix compile --warnings-as-errors && mix test` (Task 3) | 0 | 3 properties, 217 tests, 0 failures (3.4 s) |
| `mix test test/rendro/adapters/threadline_test.exs --trace` (Task 3 D-20) | 0 | 8 tests, 0 failures — adapter unaffected |
| `mix test test/rendro/policy_test.exs --trace` (Task 3) | 0 | 3 tests, 0 failures (max_pages still attributed to `:paginate`; max_bytes attributed to `:validate`) |

## Acceptance Criteria Spot-Checks

```
$ awk '/defp run_stages/,/^  end/' lib/rendro/pipeline.ex | grep -nE 'span\(:(compose|measure),'
3:         {:ok, doc} <- span(:compose, base_meta, fn -> Compose.run(doc) end, doc),
4:         {:ok, doc} <- span(:measure, base_meta, fn -> Measure.run(doc) end, doc),

$ awk '/defp run_stages/,/^  end/' lib/rendro/pipeline.ex | grep -nE 'span\(:(paginate|render),|validate_policy\(:pages'
5:         {:ok, doc} <- span(:paginate, base_meta, fn -> Paginate.run(doc) end, doc),
6:         :ok <- validate_policy(:pages, doc, policies, base_meta),
7:         {:ok, pdf_binary} <- span(:render, base_meta, fn -> Render.run(doc) end, doc),

$ grep -c -F '@tag :pending_full_pipeline' test/rendro/telemetry_test.exs
0

$ grep -c -F 'defp normalize_row' lib/rendro/pipeline/compose.ex
1

$ grep -c -F 'normalize_row' lib/rendro/pipeline/measure.ex
0

$ grep -c -F 'current_y' lib/rendro/pipeline/compose.ex
0

$ grep -c -F 'Enum.reduce(blocks, {[], 0}' lib/rendro/pipeline/compose.ex
0

$ grep -c -F 'current_y' lib/rendro/pipeline/paginate.ex
5

$ grep -c -F 'defp stack_block_y(' lib/rendro/pipeline/paginate.ex
1

$ grep -c -F 'D-04 regression' test/rendro/pipeline/paginate_test.exs
1

$ grep -F 'compose -> measure -> paginate -> render -> validate' lib/rendro/pipeline.ex
  Orchestrates the render pipeline: build -> compose -> measure -> paginate -> render -> validate.

$ grep -q "nyquist_compliant: true" .planning/phases/06-pipeline-telemetry-contract/06-VALIDATION.md && echo OK
OK

$ grep -q "Approval:.*approved" .planning/phases/06-pipeline-telemetry-contract/06-VALIDATION.md && echo OK
OK
```

## Stage Responsibility Map (final state)

| Stage | Responsibility | Owns |
|-------|---------------|------|
| `:build` | Validate + normalize document struct | `pages != []` xor `content != []` invariant |
| `:compose` | Logical-tree assembly | `normalize_row/1`; both `doc.pages` and `doc.content` traversal |
| `:measure` | Pure metric pass | `width \|\| Font.text_width(...)`, `height \|\| size * 1.2`; idempotent |
| `:paginate` | Page assignment + y-stacking | `paginate_flow/1` reduce, `apply_page_template/4`, `stack_block_y/1` (per-page cursor reset, D-04) |
| `:max_pages` guard | Inline policy check | `validate_policy(:pages, ...)` between `:paginate` and `:render` (D-10) |
| `:render` | PDF binary serialization | `PDF.Writer.render/2` |
| `:validate` | Post-render structural sanity + max_bytes | `Validate.run/2` (D-06/D-07/D-09) |

## Phase 6 Closure (audit findings)

- **BLOCKER-04** (missing `:validate` event) — closed by Plan 02 wiring.
- **BLOCKER-05** (compose ↔ measure inversion) — closed by **this plan** (Task 1 reorder).
- **MINOR-15** (error-path metric loss — `page_count: 0`) — closed by Plan 01 unified `stage_stop_meta/5`.
- **D-04 latent bug** (page-2 remainder y-inheritance) — closed by **this plan** (Task 2 `stack_block_y/1` per-page reset, regression test pinned).

The OBS-01 / OBS-02 / CORE-01 telemetry contract surface is now fully live and reserved for Phase 11 verification reconstruction.

## Next Phase Readiness

- Pipeline orchestration is wired to canonical order; downstream phases (08 Oban worker, 07 Phoenix adapter) can rely on the stable D-11 stop schema and the 6-stage event surface without compatibility shims.
- Threadline adapter integration confirmed unaffected (D-20) — top-level `[:rendro, :render, :*]` event payload structure unchanged.
- No carry-forward blockers from this plan. The 5 pre-existing `mix format --check-formatted` failures in unrelated files (already documented in `deferred-items.md`) remain out-of-scope per the executor scope-boundary rule.

## Self-Check: PASSED

**Files claimed (all FOUND):**
- `lib/rendro/pipeline.ex` — modified (run_stages reordered, moduledoc rewritten)
- `lib/rendro/pipeline/compose.ex` — modified (normalize_row added, y-stacking removed, content traversal added)
- `lib/rendro/pipeline/measure.ex` — modified (normalize_row removed, table measure simplified, moduledoc rewritten)
- `lib/rendro/pipeline/paginate.ex` — modified (stack_block_y/1 + helpers added; paginate_flow pipeline gains final stack_block_y mapping; moduledoc rewritten)
- `test/rendro/pipeline/paginate_test.exs` — modified (D-04 regression describe block appended)
- `test/rendro/telemetry_test.exs` — modified (6 :pending_full_pipeline tags removed; tag inventory comment updated)
- `.planning/phases/06-pipeline-telemetry-contract/06-VALIDATION.md` — modified (nyquist_compliant: true; per-task map populated; sign-off approved)

**Commits claimed (all in `git log`):**
- `14f534e` test(06-03): remove :pending_full_pipeline tags to expose stage-order failure
- `c177311` feat(06-03): reorder run_stages to canonical D-01 stage order
- `ae3bd63` test(06-03): add D-04 page-2 remainder y-inheritance regression test
- `8d7a2b2` feat(06-03): shuffle responsibilities — Compose owns normalize_row, Paginate owns y-stacking
- `f649b8c` docs(06-03): mark phase 06 validation strategy approved + nyquist-compliant

All claims verified.

---
*Phase: 06-pipeline-telemetry-contract*
*Completed: 2026-04-27*
