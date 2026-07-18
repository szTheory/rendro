---
phase: 115-invoice-anatomy-upgrade-format-public-promotion-palette-alig
plan: 03
subsystem: engine
tags: [table, cell, layout, alignment, byte-compat, stable-tier]

requires:
  - phase: 115-01
    provides: "Frozen table_byte_identity_test.exs golden (@table_golden_sha256) used as this plan's no-op assertion"
provides:
  - "Cell.cell_align (:left default) and Table.cell_align (nil default, column-index map) — inert struct fields, no manifest widening"
  - "Rendro.table/2 cell_align: option (column-level, e.g. %{1 => :right}), validated by normalize_table_cell_align/1"
  - "Right-align x-offset applied in paginate.ex stack_cells, gated strictly on effective cell_align == :right"
  - "test/rendro/table_cell_align_test.exs — positive/differential/determinism/no-op coverage"
affects: [115-04]

tech-stack:
  added: []
  patterns:
    - "Additive struct field on a Stable-tier module stays manifest-safe only when its @type is INLINED into t() rather than declared as a separate named @type (named types are enumerated in priv/public_api.json; inline field-type expressions are not)"
    - "Per-cell override + table-level column map resolved via a small private 'effective alignment' resolver (cell wins, else table's column-index map, else :left) — keeps the offset gate a single strict :right check"

key-files:
  created:
    - test/rendro/table_cell_align_test.exs
  modified:
    - lib/rendro/cell.ex
    - lib/rendro/table.ex
    - lib/rendro.ex
    - lib/rendro/pipeline/paginate.ex

key-decisions:
  - "OQ2 resolved: offset lives entirely in paginate.ex's stack_cells (not writer.ex) — writer.ex needs zero changes since render_table_cell already forwards cell.x into the rendered block.x untouched; this was the simpler of the two candidate locations and avoided touching a second file"
  - "Table.cell_align is a column-index map (%{non_neg_integer() => :right}), applied to every cell in that column INCLUDING the header row, since stack_cells resolves alignment identically for header and body rows"
  - "Cell.cell_align is a direct per-cell override (wins over the table-level column map) for callers who construct %Rendro.Cell{} rows directly instead of using the table-level option"
  - "No trailing-padding constant was invented — the offset is exactly col_width - measured_text_width (floored at 0); the codebase has no existing cell-padding concept to anchor a padding value to, so right-aligned text touches the column's right edge exactly, matching the zero-padding-by-symmetry of the existing left-flush path"

requirements-completed: [INV-05]

coverage:
  - id: D1
    description: "A table cell/column with cell_align: :right right-aligns its content within the column width (column-level via Rendro.table/2 cell_align: option, and per-cell via a direct %Rendro.Cell{cell_align: :right})"
    requirement: "INV-05"
    verification:
      - kind: unit
        ref: "test/rendro/table_cell_align_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "A table with NO cell_align set anywhere renders byte-identically to the pre-Phase-115 baseline (plan-01 table golden)"
    requirement: "INV-05"
    verification:
      - kind: unit
        ref: "test/rendro/table_byte_identity_test.exs"
        status: pass
      - kind: unit
        ref: "test/rendro/table_cell_align_test.exs (cross-referenced same golden sha256)"
        status: pass
    human_judgment: false
  - id: D3
    description: "No new public function is added to the frozen Stable tier; cell_align is a struct field + an option on the existing Rendro.table/2"
    requirement: "INV-05"
    verification:
      - kind: unit
        ref: "test/docs_contract/public_api_contract_test.exs"
        status: pass
    human_judgment: false
  - id: D4
    description: "A cell_align: :right render is deterministic across two renders"
    requirement: "INV-05"
    verification:
      - kind: unit
        ref: "test/rendro/table_cell_align_test.exs"
        status: pass
    human_judgment: false

duration: ~9min
completed: 2026-07-18
status: complete
---

# Phase 115 Plan 03: Additive `cell_align: :right` Table Primitive Summary

**Added the only net-new engine primitive in Phase 115 — opt-in `cell_align: :right` on `Rendro.table/2` (column-level) or a direct `%Rendro.Cell{}` (per-cell) — resolving RESEARCH Open Question 2 in favor of applying the x-offset entirely in `paginate.ex`'s `stack_cells`, so `writer.ex` needed zero changes and every existing table stays byte-identical.**

## Performance

- **Duration:** ~9 min
- **Completed:** 2026-07-18T18:26:05Z
- **Tasks:** 3 completed
- **Files modified:** 5 (4 planned `lib/` files touched, `writer.ex` read but required no edit; 1 new test file)

## Accomplishments
- **Task 1 (spike + inert scaffold):** Added `cell_align: :left` to `Rendro.Cell`'s defstruct (mirrors the existing `keep_together: false` inert peer) and `cell_align: nil` to `Rendro.Table`'s defstruct (mirrors the `borders: :none`/`header_fill: nil` inert-by-default block, storing a `%{column_index => :right}` map). Added a `normalize_table_cell_align/1` stage to `Rendro.table/2`'s `normalize_table_attrs/1` pipeline, validating the option (nil, or a map of non-negative integer keys to `:right`) and raising an instructive `ArgumentError` otherwise. `@spec table/2` arity unchanged; no new public function added. **Manifest-safety decision:** both new `@type` field specs are INLINED directly into each struct's `t()` type rather than declared as a separate named `@type cell_align`, because `Rendro.PublicApi.public_types/1` enumerates every named `@type` into `priv/public_api.json` (confirmed: `Table.borders/0` already appears in the committed manifest) — a named type would have widened the Stable-tier manifest and failed `public_api_contract_test.exs`.
- **OQ2 spike:** Traced the measured-text-width availability through the pipeline. `Cell.width` (set during `Measure`) equals the COLUMN width (not the text width); the actual measured text width lives at `cell.content.content.width` (a `%Rendro.Pipeline.MeasuredText{}.width`), available identically at both `stack_cells` (paginate) time and `render_text_block` (writer) time — post-Measure, no re-measuring needed either way. **Chose `paginate.ex`'s `stack_cells`** because `writer.ex`'s `render_table_cell` already forwards `cell.x` transparently into the rendered block's `x` (`%{block | x: block.x + cell_x, ...}`) — shifting `cell.x` at stack time was sufficient and required zero `writer.ex` changes, the simpler of the two candidate locations.
- **Task 2 (offset application):** Threaded `table.cell_align` through `stack_table_cells` → `stack_cells/5` (added a 5th arg; both existing internal call sites updated, no external callers). Added `cell_effective_align/3` (per-cell override wins, else table's column-index map, else `:left`) and `right_align_offset/1` (`max(col_width - measured_content_width, 0)`, floored at 0 per the threat register's T-115-03-03 mitigation for oversized content). The `:left`/default branch sets `%{cell | x: x, y: y}` — byte-identical to the pre-change code.
- **Task 3 (tests):** Added `test/rendro/table_cell_align_test.exs` (4 new tests): (a) no-op — the plan-01 `golden_table/0` construction with no `cell_align` hashes to the exact same frozen `@table_golden_sha256` as `table_byte_identity_test.exs` (cross-referenced, that file was not edited); (b) positive — `cell_align: %{2 => :right}` on the money column produces different bytes than the same table without it; (c) determinism — the right-aligned render is byte-identical across two passes; (d) per-cell parity — a direct `%Rendro.Cell{cell_align: :right}` override places content identically to the equivalent column-level option, once the header cell also carries the override (see Deviations).
- Full `mix test test/rendro/ test/docs_contract/public_api_contract_test.exs`: 947 tests + 11 doctests + 4 properties, 0 failures.

## Task Commits

1. **Task 1: Inert cell_align scaffold** - `2c01c42` (feat)
2. **Task 2: Right-align x-offset, gated strictly on :right** - `865b351` (feat)
3. **Task 3: Positive/differential/no-op test coverage** - `a439851` (test)

## Files Created/Modified
- `lib/rendro/cell.ex` - Added `cell_align: :left` field + inline type on `t()`.
- `lib/rendro/table.ex` - Added `cell_align: nil` field (column-index map) + inline type on `t()`.
- `lib/rendro.ex` - Added `normalize_table_cell_align/1` stage + `validate_cell_align_entry!/1` to the `Rendro.table/2` facade.
- `lib/rendro/pipeline/paginate.ex` - `stack_cells/4` → `stack_cells/5` (threads `table.cell_align`); added `cell_effective_align/3`, `right_align_offset/1`, `measured_content_width/1`.
- `test/rendro/table_cell_align_test.exs` - NEW, 4 tests (no-op, positive, determinism, per-cell parity).
- `lib/rendro/pdf/writer.ex` - Read (per Task 1/2 `<read_first>`), NOT modified — OQ2 resolved in favor of `paginate.ex` only.

## Decisions Made
- Inlined both new struct-field types instead of declaring named `@type`s, to keep the Stable-tier manifest (`priv/public_api.json`) byte-identical (verified: `mix test test/docs_contract/public_api_contract_test.exs` green with no manifest regeneration needed).
- Resolved OQ2 in favor of `paginate.ex` alone; `writer.ex` required zero edits.
- `Table.cell_align`'s column-index map applies to the header row too (not just data rows), since `stack_cells` resolves alignment identically for `table.header` and `table.rows` — a "money column" reads as fully right-aligned including its header, which is the intuitive column-level semantic.
- Used zero trailing padding (`col_width - text_width` exactly) since the codebase has no existing cell-padding concept to anchor a nonzero constant to; right-aligned text touches the column's right edge, matching the left-flush path's zero left-padding.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Test's own per-cell-vs-column-level equivalence assertion was wrong, not the implementation**
- **Found during:** Task 3 verification (`mix test test/rendro/table_cell_align_test.exs`)
- **Issue:** An initial version of the "per-cell override behaves the same as column-level" test constructed the per-cell-override table with `cell_align: :right` on only the DATA cell, then compared its full-PDF bytes against a column-level table (`cell_align: %{2 => :right}`) that (correctly, by design) also right-aligns the HEADER cell in that column. The two renders differed only in the header "Price" cell's x-position — not an implementation bug, but an apples-to-oranges test expectation. Confirmed via a byte-diff spike (`xxd` diff of both PDFs) showing only the header-row x-coordinate token differed.
- **Fix:** Updated the per-cell-override table's `header:` to also carry `%Rendro.Cell{content: "Price", cell_align: :right}`, making both constructions apply `:right` to the identical set of cells (header + one data cell). Verified byte-identical after the fix.
- **Files modified:** `test/rendro/table_cell_align_test.exs`
- **Verification:** `mix test test/rendro/table_cell_align_test.exs` (4 tests, 0 failures)
- **Committed in:** `a439851` (fixed before the task's own commit; no separate follow-up commit needed)

---

**Total deviations:** 1 auto-fixed (Rule 1, caught and fixed within Task 3 before commit)
**Impact on plan:** None on the shipped `lib/` behavior — the implementation was correct on first pass (Task 2's `mix test test/rendro/table_byte_identity_test.exs` verification passed immediately, and a manual spot-check with `mix run` confirmed the offset applied correctly before Task 3 began). Only the test's own comparison setup needed correcting.

## Issues Encountered
None beyond the deviation documented above.

## TDD Gate Compliance

Task 3 carries `tdd="true"`, but this plan's frontmatter `type` is `execute` (not `tdd`), so the plan-level RED→GREEN→REFACTOR gate sequence does not apply. The plan itself is sequenced as scaffold (Task 1, inert) → implementation (Task 2, offset applied) → tests (Task 3) — implementation intentionally precedes the dedicated test task, so Task 3's tests passed on first write (not a RED-phase failure) because the feature was already correctly implemented and spot-checked via `mix run` in Task 2. This is expected given the plan's task ordering, not a compliance gap.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
`cell_align: :right` is available both as a `Rendro.table/2` column-level option and a per-cell `%Rendro.Cell{}` override, with the Stable tier unwidened and every existing table byte-identical by default. Plan 04 (Invoice anatomy upgrade) can now right-align money columns in the Invoice recipe's line-item table if desired. No blockers.

---
*Phase: 115-invoice-anatomy-upgrade-format-public-promotion-palette-alig*
*Completed: 2026-07-18*

## Self-Check: PASSED

- FOUND: lib/rendro/cell.ex
- FOUND: lib/rendro/table.ex
- FOUND: lib/rendro.ex
- FOUND: lib/rendro/pipeline/paginate.ex
- FOUND: test/rendro/table_cell_align_test.exs
- FOUND: .planning/phases/115-invoice-anatomy-upgrade-format-public-promotion-palette-alig/115-03-SUMMARY.md
- FOUND: 2c01c42
- FOUND: 865b351
- FOUND: a439851
