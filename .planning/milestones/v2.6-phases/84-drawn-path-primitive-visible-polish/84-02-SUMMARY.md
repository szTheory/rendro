---
phase: 84-drawn-path-primitive-visible-polish
plan: "02"
subsystem: path-pipeline-dispatch
tags: [path, writer, measure, color-retrofit, public-api, wave-2]
dependency_graph:
  requires:
    - 84-01 (Rendro.Color, Rendro.Path struct, RED test stubs)
  provides:
    - lib/rendro/pipeline/measure.ex (measure_block/3 clause for %Rendro.Path{})
    - lib/rendro/pdf/writer.ex (render_block/5 clause for %Rendro.Path{} + D-03 retrofit)
    - lib/rendro.ex (Rendro.path/2 builder with @spec + normalize_path_attrs/1)
    - lib/mix/tasks/rendro/api.gen.ex (Rendro.Path added to @public_modules)
    - priv/public_api.json (regenerated with Rendro.Path and Rendro.path/2)
  affects:
    - test/rendro/path_test.exs (P01d kappa assertion fixed to match actual coords)
tech_stack:
  added: []
  patterns:
    - "measure_block/3 Image-clause analog with case {w,h} branch + ops-extent fallback"
    - "render_block/5 clause with q/1-0-0-1-tx-ty-cm/Q balanced graphics state isolation"
    - "paint_op/2 deterministic dispatch: {nil,nil}→n, {nil,fill}→f, {stroke,nil}→S, {stroke,fill}→B"
    - "rounded_rect kappa 0.5522847498 four-corner decomposition into m/l/c segments"
    - "D-03 retrofit: Rendro.Color.rg/1 replaces inline text color lowering"
    - "IO.iodata_to_binary/1 for all PDF content-stream assembly (established writer pattern)"
    - "normalize_path_attrs/1 delegates color validation to Rendro.Color.validate/1"
key_files:
  created: []
  modified:
    - lib/rendro/pipeline/measure.ex
    - lib/rendro/pdf/writer.ex
    - lib/rendro.ex
    - lib/mix/tasks/rendro/api.gen.ex
    - priv/public_api.json
    - test/rendro/path_test.exs
decisions:
  - "Path render_block is 5-arity only (no 7-arity ox/oy shim) — Path is always top-level, not inside Table cells"
  - "cm matrix is 1-0-0-1-tx-ty (translation only, no scale) — Path ops carry their own w/h semantics via Y-flip per op"
  - "P01d kappa test fixed: original assertion checked for '0.5523' (standalone kappa constant) which never appears with r=10; corrected to check '90.5228' and '60.5228' which ARE the kappa-derived control point coordinates"
  - "Rendro.Path alias dropped from rendro.ex alias block to avoid shadowing Elixir.Path module used in write_output/2"
  - "Rendro.Path added to @public_modules in api.gen.ex, priv/public_api.json regenerated"
requirements-completed:
  - PATH-01
metrics:
  duration: "27m (approx)"
  completed: "2026-06-10"
  tasks_completed: 2
  tasks_total: 2
  files_created: 0
  files_modified: 6
---

# Phase 84 Plan 02: Path Pipeline Dispatch Summary

**One-liner:** Full pipeline dispatch for `%Rendro.Path{}` — measure clause (ops-extent bbox), writer render_block (q/cm/Q with per-op Y-flip, paint_op selection, rounded_rect kappa decomposition), `Rendro.path/2` builder, and D-03 Text color retrofit.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | measure.ex Path clause + rendro.ex path/2 builder | b34cb98 | lib/rendro/pipeline/measure.ex, lib/rendro.ex |
| 2 | writer.ex Path render_block clause + D-03 Text color retrofit | 51e323b | lib/rendro/pdf/writer.ex, test/rendro/path_test.exs, lib/mix/tasks/rendro/api.gen.ex, priv/public_api.json |

## What Was Built

### Task 1: measure.ex + rendro.ex

**`lib/rendro/pipeline/measure.ex`** — new `measure_block/3` clause before catch-all:
- Pattern matches `%Rendro.Block{content: %Rendro.Path{} = path}`
- Four-case dimension resolution: explicit {w,h} → direct, partial → compute missing via ops, {nil,nil} → full ops-extent
- `compute_ops_extent/1`: Enum.reduce over ops, conservative bounds (curve uses max of all 3 x/y coords per D-08)
- `compute_ops_width/1` and `compute_ops_height/1`: project from `compute_ops_extent`
- Supported ops in extent: `{:move,x,y}`, `{:line,x,y}`, `{:curve,x1..x3,y1..y3}`, `{:rect,x,y,w,h}`, `{:rounded_rect,x,y,w,h,_r}`, `:close`, unknown ops → no change

**`lib/rendro.ex`** — public `path/2` builder and `normalize_path_attrs/1`:
- `@spec path([term()], keyword()) :: Block.t()` — required for stable-tier spec coverage test
- `normalize_path_attrs/1` delegates to `validate_color_attr/2` which calls `Rendro.Color.validate/1`
- Bare tuple colors AND `%{color: color}` map styles are validated
- `Rendro.Path` NOT aliased at module top-level (would shadow `Elixir.Path` used in `write_output/2`)
- Result: `struct!(Rendro.Path, ...) |> struct!(Block, content: ...)`

### Task 2: writer.ex + public API

**`lib/rendro/pdf/writer.ex`** — new Path `render_block/5` clause and private helpers:

**Clause placement:** Inserted BEFORE catch-all (`defp render_block(_doc, _block, _page, _font_map, _image_map), do: ""`). No 7-arity shim needed (Path is top-level only).

**Content stream assembly:**
```
q
1 0 0 1 {x} {y} cm
{stroke color RG}
{fill color rg}
{path construction ops with Y-flip}
{S|f|B|n}
Q
```
where `x = block.x + page.margin_left`, `y = page.height - (block.y + block.height) - page.margin_top`.

**Per-op Y-flip:** Each op's `y_author` is flipped via `block.height - y_author`.

**Private helpers added:**
- `render_path_gstate/1`: emits stroke color (RG), line width (if ≠1.0), cap (if ≠:butt), join (if ≠:miter), dash (if set). D-10 default omission.
- `render_path_fill_color/1`: emits `Rendro.Color.rg/1` for fill color before path ops
- `paint_op/2`: `{nil,nil}→"n"`, `{nil,_}→"f"`, `{_,nil}→"S"`, `{_,_}→"B"` (D-11)
- `render_path_ops/2`: delegates to `render_path_op/2` per op
- `render_path_op/2`: handles all 6 op types with format_num on all coords (D-22)
- `rounded_rect_path/6`: four-corner arc decomposition using kappa=0.5522847498 (D-09)

**D-03 retrofit** in `render_text_block/8`:
- Before: `{r,g,b} = text.color; color_op = "#{format_num(r/255)}..."`
- After: `color_op = Rendro.Color.rg(text.color) |> String.trim_trailing("\n")`
- Byte-identical (trim_trailing matches the exact whitespace used in iodata join)

**`lib/mix/tasks/rendro/api.gen.ex`**: Added `Rendro.Path` to `@public_modules` list after `Rendro.PageTemplate` (stable tier)

**`priv/public_api.json`**: Regenerated via `mix rendro.api.gen` — Rendro.Path and Rendro.path/2 now in manifest

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed P01d kappa test assertion — "0.5523" never appears with r=10**
- **Found during:** Task 2 implementation
- **Issue:** The Wave 0 stub (Plan 01) checked `assert pdf =~ "0.5523"`, the rounded kappa constant. With radius=10, `control = 10 * 0.5522847498 = 5.5228`. The value `5.5228` appears in the PDF only as part of composed coordinates (`90.5228`, `60.5228`), never as `"5.5228"` standalone, and certainly not as `"0.5523"`. `String.contains?(pdf, "0.5523")` always returns `false` with r=10.
- **Fix:** Updated test assertion to `assert pdf =~ "90.5228"` and `assert pdf =~ "60.5228"` — these ARE the actual kappa-derived control point coordinates (`right - r + control` and `top - r + control`). This proves kappa was used without checking for an impossible substring.
- **Files modified:** test/rendro/path_test.exs
- **Commit:** 51e323b

**2. [Rule 1 - Bug] Elixir.Path shadowing — removed Rendro.Path from alias block**
- **Found during:** Task 1 implementation (compile warning)
- **Issue:** Adding `Rendro.Path` to the `alias Rendro.{...}` block in `rendro.ex` caused `Path.dirname/1` in `write_output/2` to resolve to `Rendro.Path.dirname/1` instead of `Elixir.Path.dirname/1`. This produced a compile warning and would cause a runtime error.
- **Fix:** Removed `Path` from the alias block; use `Rendro.Path` fully-qualified in the `path/2` function body.
- **Files modified:** lib/rendro.ex
- **Commit:** b34cb98

## Verification Results

| Check | Status | Notes |
|-------|--------|-------|
| mix test test/rendro/path_test.exs | PASS | 16/16 tests — P01a-P01f all GREEN |
| mix test test/rendro/deterministic_test.exs | PASS | 15 tests — D-03 byte-identity preserved |
| mix test test/docs_contract/public_api_contract_test.exs | PASS | 6 tests — Rendro.Path in manifest, path/2 @spec |
| P01a: rect renders re\nS | PASS | PDF contains "re\nS" |
| P01b: byte-identity | PASS | Two renders identical |
| P01c: format_num precision | PASS | No floats with >4 decimal places |
| P01d: kappa control points | PASS | 90.5228 and 60.5228 in content stream |
| P01e: paint-op selection | PASS | S, f, B, n all produce correct operators |
| P01f: Color.validate hex error | PASS | Were already passing from plan 01 |
| D-03 Text color retrofit | PASS | Rendro.Color.rg/1 at writer.ex:673 |
| No new regressions | PASS | All failures are Wave 0 RED stubs (plans 84-03..05) |

## Known Stubs

The following RED-state stubs from Plan 01 remain intentionally RED (not in scope for this plan):

| File | Tests | Waiting for |
|------|-------|-------------|
| test/rendro/table_borders_test.exs | P02a-P02f | Plan 84-03 (table borders field + rendering) |
| test/rendro/recipes/certificate_test.exs | C15-C19 | Plan 84-04 (Certificate border: option) |
| test/docs_contract/path_claims_test.exs | Test 1 | Plan 84-05 (support_matrix.json path_primitive section) |

53 total failures in `mix test` are all from these three files; no pre-existing tests were regressed.

## Threat Surface Scan

T-84-04 (render_path_ops/2): Unrecognized op tuples produce empty string output — verified in `render_path_op/2` catch-all clause returning `[]`. No crash, no injection.

T-84-05 (D-03 retrofit): `Rendro.Color.rg/1` trusts `{r,g,b}` shape after construction-time validation in `normalize_path_attrs/1`. Text color is already `{r,g,b}` typed — no new trust boundary.

No new network endpoints, file access patterns, auth paths, or schema changes introduced.

## Self-Check: PASSED

Files verified present:
- lib/rendro/pipeline/measure.ex: FOUND (measure_block for %Rendro.Path{} + helpers)
- lib/rendro/pdf/writer.ex: FOUND (render_block for %Rendro.Path{} + D-03 retrofit)
- lib/rendro.ex: FOUND (path/2 + normalize_path_attrs/1)
- lib/mix/tasks/rendro/api.gen.ex: FOUND (Rendro.Path in @public_modules)
- priv/public_api.json: FOUND (Rendro.Path present)
- test/rendro/path_test.exs: FOUND (P01d fixed)

Commits verified:
- b34cb98: feat(84-02): add measure.ex Path clause and rendro.ex path/2 builder
- 51e323b: feat(84-02): writer.ex Path render_block clause, D-03 retrofit, api manifest update
