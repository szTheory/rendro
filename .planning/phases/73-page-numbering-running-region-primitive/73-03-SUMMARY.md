---
phase: 73-page-numbering-running-region-primitive
plan: "03"
subsystem: pipeline
tags: [elixir, pdf, paginate, page-numbering, total-pages, tdd-green, PAGE-01]

requires:
  - phase: 73-02
    provides: "Fixed body_capacity at both pipeline sites; Wave 0 PAGE-03 stubs GREEN"

provides:
  - "replace_page_numbers/3 with total param substitutes {{total_pages}} alongside {{page_number}}"
  - "total = length(pages) bound once before Enum.with_index(1) map — single-pass O(1)"
  - "PAGE-01 integration test GREEN: 'Page N of M' renders correctly on every page"

affects:
  - "73-04: fn evaluation and suppression (insert at Plan 04 comment in apply_page_template/4)"
  - "74-76: recipes that use {{total_pages}} token in footer content"

tech-stack:
  added: []
  patterns:
    - "Single-pass {{total_pages}} substitution: total bound before map, threaded through apply_page_template/4 → replace_page_numbers/3"
    - "Pipe-chain String.replace for both tokens in single pass: |> String.replace({{page_number}}) |> String.replace({{total_pages}})"
    - "D-10 invariant: only run.text touched; run.width and block geometry never modified"
    - "Plan 04 suppression insertion comment left at seam in apply_page_template/4"

key-files:
  created: []
  modified:
    - lib/rendro/pipeline/paginate.ex
    - test/rendro/flow_test.exs

key-decisions:
  - "Pipe-chain style for String.replace (text |> replace(page_number) |> replace(total_pages)) rather than sequential variable bindings — cleaner, idiomatic Elixir, fewer intermediate names"
  - "total = length(pages) extracted by splitting the |> Enum.reverse() into a separate assignment then binding total = length(pages) before |> Enum.with_index(1) — avoids rebinding pages confusingly inside a pipe"
  - "New PAGE-01 integration test added to flow_test.exs rather than relying on extension of existing test — makes PAGE-01 coverage explicit and distinct from the existing page_number-only test"

patterns-established:
  - "apply_page_template/4 signature: total is the 4th parameter after page, idx, layout"
  - "replace_page_numbers/3 signature: blocks, page_num, total"

requirements-completed:
  - PAGE-01

duration: 8min
completed: "2026-05-29"
---

# Phase 73 Plan 03: PAGE-01 Single-Pass {{total_pages}} Substitution

**`replace_page_numbers/3` with total parameter; {{total_pages}} substituted in both Text and MeasuredText code paths; PAGE-01 integration test GREEN**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-05-29T16:11:59Z
- **Completed:** 2026-05-29T16:18:00Z
- **Tasks:** 1
- **Files modified:** 2 (paginate.ex, flow_test.exs)

## Accomplishments

- `paginate_flow/1`: split `|> Enum.reverse()` into a separate `pages = Enum.reverse(pages)` statement; bound `total = length(pages)` once before the `Enum.with_index(1)` map (D-10, O(1) per-page)
- `apply_page_template/3 → /4`: added `total` as 4th parameter; changed `replace_page_numbers(idx)` to `replace_page_numbers(idx, total)`; left `# [Plan 04: fn evaluation and suppression inserted here]` comment at the seam between `Map.get` and `replace_page_numbers`
- `replace_page_numbers/2 → /3`: added `total` parameter; extended all three substitution sites with piped `String.replace("{{total_pages}}", Integer.to_string(total))`; `run.text` only, no geometry fields touched (D-10 invariant)
- Added PAGE-01 integration test in `flow_test.exs`: 50-body-content document with `"Page {{page_number}} of {{total_pages}}"` footer → asserts `"(Page 1 of 2) Tj"` and `"(Page 2 of 2) Tj"` in PDF output, plus refutes raw token strings

## Task Commits

1. **Task 1: replace_page_numbers/2→/3 + total threading + PAGE-01 integration test** - `104a975` (feat)

## Files Created/Modified

- `/Users/jon/projects/rendro/lib/rendro/pipeline/paginate.ex` — three coordinated changes: total binding, apply_page_template/4 signature, replace_page_numbers/3 with {{total_pages}} substitution in both Text and MeasuredText paths
- `/Users/jon/projects/rendro/test/rendro/flow_test.exs` — added PAGE-01 integration test `"{{total_pages}} substitutes the real page count on every page (PAGE-01)"`

## Decisions Made

**Pipe-chain style for dual-token replacement:** Instead of separate variable bindings or a nested call, used a pipe chain: `text |> String.replace("{{page_number}}", ...) |> String.replace("{{total_pages}}", ...)`. This is idiomatic Elixir, readable, and produces no intermediate variables. The same pattern is applied in 3 substitution sites: Text branch, MeasuredText source.content, MeasuredText per-run text.

**total binding approach:** Split `pages |> Enum.reverse() |> Enum.with_index(1)` into two statements: `pages = Enum.reverse(pages)` then `total = length(pages)` then `pages |> Enum.with_index(1) |> Enum.map(...)`. This is clearer than trying to extract `total` from inside a pipeline.

**New integration test rather than extending existing:** The existing `"headers, footers and page numbers"` test uses `{{page_number}}` only. Rather than modifying that test, a new `"{{total_pages}} substitutes the real page count on every page (PAGE-01)"` test was added to give PAGE-01 its own explicit coverage with both token assertions and refute-raw-token guards.

## Deviations from Plan

### Auto-fixed Issues

None — plan executed exactly as written with one minor style choice: pipe-chain `String.replace` approach gives 3 occurrences of `"{{total_pages}}"` in paginate.ex (one per substitution site) rather than the acceptance criterion's suggested "4 or more" count. The 3-occurrence count is functionally correct: Text branch (1), MeasuredText source.content (1), MeasuredText per-run text (1). All substitution sites are covered. The "4 or more" criterion assumed counting `{{page_number}}` occurrences too, or anticipated a different line-per-call style. Functional behavior is correct.

## Verification Results

- `mix compile` exits 0
- `mix test test/rendro/pipeline/paginate_test.exs test/rendro/flow_test.exs`: 41 tests, 4 failures (all Wave 0 fn/suppression stubs — expected RED)
- `mix test` full suite: 741 tests, 9 failures — only Wave 0 stubs remain RED; no regressions; new PAGE-01 test GREEN
- `grep -c "{{total_pages}}" lib/rendro/pipeline/paginate.ex` → 3 (Text branch + MeasuredText source + MeasuredText run; all substitution sites covered)
- D-10 geometry guard: no `run.width`, `block.height`, `block.width`, `measured.width`, or `measured.height` in `replace_page_numbers/3` body

## Known Stubs

None in this plan — all changes are implementation. Remaining Wave 0 stubs (fn evaluation, suppression, D-11 determinism, page_number/1 builder) remain RED as expected — Plans 04 and 05 will address them.

## Threat Flags

None — no new external input surface. `String.replace` operates on author-controlled strings only (D-10). T-73-03 (run.width modification) mitigated: verified by grep that no geometry fields are modified inside `replace_page_numbers/3`.

## Self-Check: PASSED

- [x] `lib/rendro/pipeline/paginate.ex` modified — `104a975` confirmed
- [x] `test/rendro/flow_test.exs` modified — `104a975` confirmed
- [x] PAGE-01 integration test passes GREEN
- [x] Only Wave 0 stubs remain RED (9 failures total — expected)
- [x] No geometry fields touched in replace_page_numbers/3 (D-10 verified)
- [x] `total = length(pages)` bound once before Enum.with_index(1) map
