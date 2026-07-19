---
phase: 117-edge-case-stress-matrix
plan: 05
subsystem: testing
tags: [edge-cases, error-contract, typed-errors, rtl, pagination, regression-lock]
requires:
  - "test/support/edge_fixtures.ex (117-02): overflow_document/0, tall_row_document/0, rtl_default_font_document/0, rtl_shaping_required_document/0"
  - "lib/rendro/pipeline/paginate.ex: check_overflow!/4 + table-row-overflow branch (READ-ONLY assertion targets)"
  - "lib/rendro/pipeline/measure.ex: {:unsupported_glyph, _} halt path (READ-ONLY)"
  - "lib/rendro/text/shaper/simple.ex: {:shaping_required, script, hint} gate (READ-ONLY)"
  - "lib/rendro/error.ex: next_step/2 + why/2 for both stages (READ-ONLY)"
provides:
  - "Rendro.EdgeErrorMatrixTest — EDGE-02 typed-error assertion matrix (4 error-shape tests + 2 D-06 regression locks + 1 coverage-discipline test)"
affects:
  - "test/rendro/edge_error_matrix_test.exs"
tech-stack:
  added: []
  patterns:
    - "D-07 assertion idiom: match %Rendro.Error{} struct first, assert stage/reason precisely, assert next/why as SUBSTRINGS — never on raw internal tuples, never on full prose equality"
    - "D-06 negative regression lock via refute match?({:ok, _}, ...) — turns silent-mis-render risk into a hard-failing test"
key-files:
  created:
    - "test/rendro/edge_error_matrix_test.exs"
  modified: []
decisions:
  - "Zero lib/ edits — all three pipeline paths already produce correct, public, typed %Rendro.Error{} shapes (live-probe verified this session)"
  - "@error_cases is a lightweight 4-entry exhaustiveness marker, NOT a second full @matrix — engine-level granularity per D-08"
metrics:
  duration: ~1 min
  completed: 2026-07-19
status: complete
---

# Phase 117 Plan 05: EDGE-02 Typed-Error Assertion Matrix Summary

Locked EDGE-02's "errors-as-product, never silent" contract for the three hardest edge inputs (overflow, tall-row, RTL) as 7 tests asserting live-probe-verified typed `%Rendro.Error{}` shapes — zero `lib/` changes, `async: true`, no pdfium dependency.

## What Was Built

`test/rendro/edge_error_matrix_test.exs` (`Rendro.EdgeErrorMatrixTest`, `async: true`), consuming the 4 error fixtures shipped by 117-02:

- **`describe "EDGE-02: overflow and tall-row (D-05)"`** (2 tests)
  - Plain oversized block → `%Rendro.Error{stage: :paginate, reason: :content_overflow}`, exact frozen "does not auto-fit" `next`, `is_map(details.block)`.
  - Single tall row → the SAME typed stage/reason via the distinct row-overflow branch, identifying the offending row (`is_number(details.row_height)`, `> 0`) with `refute Map.has_key?(details, :block)` — proving both entry points into `:content_overflow` are genuinely exercised, never silent truncation.
- **`describe "EDGE-02: RTL refusal, both paths (D-06)"`** (4 tests)
  - Hebrew under default shaper → `{:unsupported_glyph, char}` at `:measure` (single grapheme), `next =~ "fallback font"`.
  - Arabic under glyph-capable/shaping-incapable font → `{:shaping_required, :arab, hint}` at `:measure`, `hint` binary, `next =~ "shaping adapter"`, `why =~ ":arab"`.
  - Two `refute match?({:ok, _}, ...)` regression locks — the highest-value assertions here: they turn "Rendro could someday silently render Hebrew/Arabic LTR" into a hard-failing test (T-117-05-01 mitigation).
- **`describe "EDGE-02: coverage discipline (D-08)"`** (1 test) — asserts the `@error_cases` marker holds exactly the 4 engine-level representative inputs, documenting that this module is deliberately NOT per-family.

## Live-Probe Verification (this session)

Confirmed exact shapes before writing assertions:

| Fixture | stage/reason | key detail |
|---------|--------------|------------|
| overflow | `{:paginate, :content_overflow}` | `details.block = %{x, y, width, height: 5000}` |
| tall_row | `{:paginate, :content_overflow}` | `details.row_height = 3153.6`, no `:block` key |
| rtl_default | `{:measure, {:unsupported_glyph, "ש"}}` | `next =~ "fallback font"` |
| rtl_shaping | `{:measure, {:shaping_required, :arab, hint}}` | `next =~ "shaping adapter"`, `why =~ ":arab"` |

## Deviations from Plan

None — plan executed exactly as written. All assertions matched the live-probed shapes; no `lib/` change was needed.

Minor sequencing note (not a deviation): the `@error_cases` module attribute was introduced with its consuming test in Task 2 (rather than left unused after Task 1) to keep the Task 1 commit warning-free. The final file matches the plan's intent exactly.

## Threat Surface

No new runtime surface. Test-only; consumes the already-shipped public error contract (`%Rendro.Error{}`, `Rendro.render/2`) exactly as any external caller could. Threat register mitigations T-117-05-01 (RTL silent-mis-render) and T-117-05-02 (error contract drift) are realized by the `refute match?` locks and the substring-based (not prose-equality) assertions respectively.

## Verification

```
mix test test/rendro/edge_error_matrix_test.exs
7 tests, 0 failures
```

## Commits

- `c5c27c9` test(117-05): overflow + tall-row typed :content_overflow (D-05)
- `5242a76` test(117-05): RTL refusal modes + D-06 regression lock + coverage guard

## Self-Check: PASSED

- FOUND: test/rendro/edge_error_matrix_test.exs
- FOUND: commit c5c27c9
- FOUND: commit 5242a76
- Zero `lib/` changes confirmed (`git diff HEAD~2 --name-only | grep '^lib/'` → empty)
