---
phase: 84-drawn-path-primitive-visible-polish
plan: "03"
subsystem: table-borders-decoration
tags: [table, borders, writer, normalize, header-fill, wave-3]
dependency_graph:
  requires:
    - 84-01 (Rendro.Color, RED test stubs)
    - 84-02 (Path pipeline dispatch, wave-2 baseline)
  provides:
    - lib/rendro/table.ex (three new flat fields: borders/border_style/header_fill + @type t)
    - lib/rendro.ex (normalize_table_attrs extension: borders canonicalization + color validation)
    - lib/rendro/pdf/writer.ex (table_decoration/3 + do_table_decoration/3 + guarded prepend)
    - test/rendro/table_borders_test.exs (rewritten fixtures + normalization tests)
  affects:
    - test/rendro/deterministic_test.exs (no regressions — borders: :none byte-identical baseline preserved)
tech_stack:
  added: []
  patterns:
    - "normalize_borders/1: flat_map expand shorthands + uniq + sort → canonical list regardless of input order"
    - "table_decoration/3 early-exit guard: returns '' when borders inert + header_fill nil (D-15 Pitfall 3)"
    - "do_table_decoration/3: header fill → stroke setup → outer rect → h_rules → v_rules wrapped in q/Q"
    - "render_h_rule_with_span_check/5: chunk_by unspanned columns → single m/l per contiguous run (draw-once)"
    - "render_v_rule_with_span_check/9: chunk_by unspanned rows → single m/l per contiguous run (draw-once)"
    - "_grid_layout nil guard: draws unconditionally when grid absent (T-84-09 mitigation)"
    - "Pitfall 3 guard: if decoration == '' do cells_content else decoration <> newline <> cells_content"
key_files:
  created: []
  modified:
    - lib/rendro/table.ex
    - lib/rendro.ex
    - lib/rendro/pdf/writer.ex
    - test/rendro/table_borders_test.exs
decisions:
  - "normalize_borders/1 converts single atoms to [atom] then flat_map+uniq+sort — ensures :all and [:all,:outer] produce identical [:columns,:outer,:rows]"
  - "expand_table_borders/1 in writer.ex handles :all/:grid/:none shorthands for tables constructed directly via struct! (bypassing normalize_table_attrs)"
  - "stroke setup (RG + w) emitted once before outer+rules — not repeated per segment"
  - "Interior rules use _grid_layout span suppression; nil guard falls back to unconditional draw"
  - "Test fixtures rewritten from struct!-based (broke pipeline font validation) to Rendro.table/2 + Rendro.flow"
requirements-completed:
  - PATH-02
metrics:
  duration: "approx 45m"
  completed: "2026-06-10"
  tasks_completed: 2
  tasks_total: 2
  files_created: 0
  files_modified: 4
---

# Phase 84 Plan 03: Table Borders & Decoration Summary

**One-liner:** Opt-in table borders/rules/header-fill via three new flat struct fields, set-canonicalized borders normalization, and a draw-once `table_decoration/3` helper with rowspan/colspan-aware suppression and Pitfall 3 stray-newline guard.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | table.ex new fields + rendro.ex normalize_table_attrs extension | db15965 | lib/rendro/table.ex, lib/rendro.ex, test/rendro/table_borders_test.exs |
| 2 | writer.ex table_decoration helper + guarded prepend | 5ec5d6d | lib/rendro/pdf/writer.ex |

## What Was Built

### Task 1: table.ex + rendro.ex

**`lib/rendro/table.ex`** — three new flat fields added after `decoration_break`:
- `borders: :none` — accepts atom or list; default inert
- `border_style: nil` — accepts `%{color, width, dash}` map; nil → built-in hairline
- `header_fill: nil` — accepts `{r,g,b}` tuple; nil → no band
- `@type borders` and `@type t` updated with new field types

**`lib/rendro.ex`** — `normalize_table_attrs/1` split into pipeline of sub-normalizers:
- `normalize_table_split_policy/1` (extracted from prior inline function)
- `normalize_table_borders/1` + `normalize_borders/1` private helper:
  - Single atom: wrap in list → flat_map expand → uniq → sort
  - List: each atom validated, flat_map expand → uniq → sort
  - Shorthand expansion: `:all → [:outer, :rows, :columns]`, `:grid → [:rows, :columns]`, `:none → []`
  - Invalid atom: raises `ArgumentError` "Unknown borders atom: ..."
- `normalize_table_border_style/1`: delegates `border_style.color` to `Rendro.Color.validate/1`
- `normalize_table_header_fill/1`: delegates `header_fill` to `Rendro.Color.validate/1`

**`test/rendro/table_borders_test.exs`** — rewritten from RED stubs with broken struct!-based fixtures:
- New fixtures use `Rendro.table/2` with raw string rows + `Rendro.flow/1`
- Tests cover: P02a (re+S), P02b (byte-identity no-borders), P02c (byte-identity :none), P02d ([:outer,:rows]), P02e (draw-once), P02f (header_fill rg+f)
- Normalization behavior tests: :all canonicalization, [:all,:outer] idempotence, :grid expansion, :none→[], invalid atom error, hex color rejection

### Task 2: writer.ex

**`lib/rendro/pdf/writer.ex`** — table_decoration helpers added at end of file:

**`table_decoration/3` guard** (D-15 Pitfall 3):
- `if borders in [:none, [], nil] and is_nil(header_fill), do: "", else: do_table_decoration/3`

**`do_table_decoration/3`** — full decoration pipeline:
1. Block origin: `bx = block.x + page.margin_left`, `by = page.height - (block.y + block.height) - page.margin_top`
2. `expand_table_borders/1` helper handles atom shorthands for direct-struct-construction paths
3. Header fill: `Rendro.Color.rg(header_fill) + re + f` for header band at top of table
4. Stroke setup: `Rendro.Color.rg_stroke(color) + format_num(width) w` once before all strokes
5. Outer border: `format_num(bx) format_num(by) format_num(total_w) format_num(total_h) re\n S`
6. Horizontal rules: `render_table_h_rules/7` — cumulative y boundaries, rowspan suppression, chunk_by
7. Vertical rules: `render_table_v_rules/7` — cumulative x boundaries, colspan suppression, chunk_by
8. Wrapped in `q\n ... Q\n` (graphics state isolation)
9. `IO.iodata_to_binary/1` finalization

**Modified Table `render_block/5`**:
- Added `= outer_block` binding to pattern match
- `cells_content` computed as before
- `decoration = table_decoration(table, page, outer_block)`
- Guard: `if decoration == "" do cells_content else decoration <> "\n" <> cells_content end`

**Span suppression logic**:
- Horizontal rules: `render_h_rule_with_span_check/5` — for boundary after row r, check if `cell_r.ref_r == cell_r1.ref_r` (rowspan crosses boundary) → suppress that column segment
- Vertical rules: `render_v_rule_with_span_check/9` — for boundary after col c, check if `cell_c.ref_c == cell_c1.ref_c` (colspan crosses boundary) → suppress that row segment
- Both use `Enum.chunk_by` to group contiguous unspanned segments into single `m/l` pairs (draw-once, not per-cell)
- `_grid_layout nil guard`: falls through to unconditional full-width/height line draw

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] normalize_borders single-atom path didn't sort the expansion result**
- **Found during:** Task 1 test verification
- **Issue:** When `borders: :all` (single atom), the original code called `expand_border_atom(:all)` returning `[:outer, :rows, :columns]` directly, bypassing the sort. Tests expected `[:columns, :outer, :rows]` (sorted alphabetically) but got `[:outer, :rows, :columns]`.
- **Fix:** Rewrote `normalize_borders/1` to always convert atoms to a list first, then flat_map+uniq+sort regardless of whether input was atom or list.
- **Files modified:** lib/rendro.ex
- **Commit:** db15965

**2. [Rule 1 - Bug] Test fixtures in table_borders_test.exs used struct!-based construction that broke pipeline font validation**
- **Found during:** Task 1 test run (pre-existing in the RED stub file created by Plan 01)
- **Issue:** The stub test created `%Rendro.Table{}` directly with `%Rendro.Row{}` structs. The pipeline's `validate_table_row_fonts` called `Enum.reduce_while` over a `%Rendro.Row{}` struct, which doesn't implement `Enumerable`, raising `Protocol.UndefinedError`.
- **Fix:** Rewrote all test fixtures to use `Rendro.table/2` with plain string row data and `Rendro.flow/1` for document creation. Added normalization behavior tests (borders atom validation, :all/:grid/:none canonicalization, color validation).
- **Files modified:** test/rendro/table_borders_test.exs
- **Commit:** db15965

## Verification Results

| Check | Status | Notes |
|-------|--------|-------|
| mix test test/rendro/table_borders_test.exs | PASS | 19/19 tests — P02a-P02f + 9 normalization tests GREEN |
| mix test test/rendro/deterministic_test.exs | PASS | 3 properties, 16 tests — byte-identity baseline preserved |
| mix test test/rendro/table_test.exs | PASS | 3 tests — no regressions |
| P02a: borders: :all → re + S | PASS | PDF contains "re" and " S\n" |
| P02b: no borders → byte-identical | PASS | Two renders identical |
| P02c: borders: :none → byte-identical | PASS | Same as no-borders baseline |
| P02d: [:outer, :rows] → S present | PASS | Outer + horizontal rules drawn |
| P02e: draw-once | PASS | S operator present without doubling |
| P02f: header_fill → rg + f | PASS | rg and "f\n" in content stream |
| borders: :all canonicalization | PASS | → [:columns, :outer, :rows] |
| borders: [:all, :outer] idempotence | PASS | Same as borders: :all |
| borders: :grid expansion | PASS | → [:columns, :rows] |
| borders: :unknown_atom error | PASS | ArgumentError with valid atoms listed |
| hex color rejection (header_fill) | PASS | ArgumentError mentioning "hex" |
| hex color rejection (border_style) | PASS | ArgumentError mentioning "hex" |
| Full suite | 9 failures | All pre-existing RED stubs (C15-C20 certificate, path_claims, API manifest) |

## Known Stubs

None — plan goal achieved. All P02a-P02f tests are GREEN. Pre-existing RED stubs from Plans 84-04 and 84-05 remain in their respective files and are not in scope for this plan.

## Threat Surface Scan

T-84-07 (normalize_table_attrs borders validation): Closed allowlist implemented via `validate_border_atom!/1`; unknown atoms raise `ArgumentError` with valid atoms listed. Color validation delegates to `Rendro.Color.validate/1` with its hex-footgun error message.

T-84-08 (table_decoration with large table): Accepted — gridline computation is O(rows*cols) on developer-supplied data.

T-84-09 (_grid_layout nil guard): Implemented — `is_nil(grid)` check in both `render_table_h_rules/7` and `render_table_v_rules/7` falls through to unconditional full-width/height line draw. No crash.

No new network endpoints, auth paths, file access patterns, or schema changes introduced.

## Self-Check: PASSED

Files verified present:
- lib/rendro/table.ex: FOUND (borders/border_style/header_fill fields + @type t)
- lib/rendro.ex: FOUND (normalize_borders/1 + normalize_table_border_style/1 + normalize_table_header_fill/1)
- lib/rendro/pdf/writer.ex: FOUND (table_decoration/3 + do_table_decoration/3 + modified render_block)
- test/rendro/table_borders_test.exs: FOUND (rewritten with 19 tests)

Commits verified:
- db15965: feat(84-03): table.ex new fields + normalize_table_attrs extension
- 5ec5d6d: feat(84-03): writer.ex table_decoration helper + guarded prepend
