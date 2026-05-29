---
phase: 74-statement-recipe
verified: 2026-05-29T15:00:00Z
status: gaps_found
score: 4/4 roadmap success criteria verified (with qualified notes on 2 review findings)
overrides_applied: 0
gaps:
  - truth: "Top-level :closing_balance caller assertion is validated via Decimal.equal?/2 as the moduledoc promises"
    status: failed
    reason: "maybe_validate_closing_balance!/1 only type-checks the value — a wrong Decimal closing_balance (e.g. Decimal.new(\"99999.99\") against a derived 1000.00) is silently accepted. Reproduced in code. The moduledoc line 33 states 'validated via Decimal.equal?/2 when present'; the implementation at lines 679–701 contains no Decimal.equal?/2 call. summary.closing_balance IS validated (line 714) making this an inconsistency, not a deliberate choice. Bears directly on D-06 correctness contract claim in review WR-01."
    artifacts:
      - path: "lib/rendro/recipes/statement.ex"
        issue: "maybe_validate_closing_balance!/1 has no Decimal.equal?/2 check. Falls through to the catch-all `defp maybe_validate_closing_balance!(_data), do: :ok` for any %Decimal{} value regardless of correctness."
    missing:
      - "Add Decimal.equal?/2 comparison in maybe_validate_closing_balance!/1 after the type-guard clauses, matching the approach in maybe_validate_summary!/1 (lines 713–724)."
  - truth: "Rendro.measure_rows/4 is a safe public API with no descending-range bug reachable through it"
    status: failed
    reason: "CR-01 confirmed: do_build_grid/4 in measure.ex line 286 uses `for c <- 0..(col_count - 1)` without an explicit step. When col_count==0 this produces the range 0..-1 which is a descending range in Elixir, emitting a runtime deprecation warning and building a spurious {r,-1} grid entry. Reproduced: `Rendro.Pipeline.Measure.measure_rows(doc, [[], []], 400, [])` emits 'Range.new/2 ... default to a step of -1' warning. This is reachable through the documented public `Rendro.measure_rows/4` builder. Will become a hard error in a future Elixir release."
    artifacts:
      - path: "lib/rendro/pipeline/measure.ex"
        issue: "Line 286: `for c <- 0..(col_count - 1)` — missing `//1` explicit step. When col_count==0 this generates a descending range [0, -1] instead of an empty list."
    missing:
      - "Change line 286 to `for c <- 0..(col_count - 1)//1` OR add an early return when col_count==0. Apply the same fix to the `r` range at line 285 for defense-in-depth (`for r <- 0..(length(rows) - 1)//1`)."
---

# Phase 74: Statement Recipe Verification Report

**Phase Goal:** A caller with account transaction data can generate a multi-page billing statement
with correct "Page X of Y" footers and carried-forward / brought-forward balances — all via
`Rendro.Recipes.Statement`

**Verified:** 2026-05-29T15:00:00Z
**Status:** gaps_found
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths (Roadmap Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| SC-1 | `Rendro.Recipes.Statement.document/2` accepts a data map and returns a renderable `%Rendro.Document{}` — no template authoring required | VERIFIED | `lib/rendro/recipes/statement.ex` line 231 defines `def document(data, opts \\ [])`. V1 test suite (5 tests) passes, including smoke render `{:ok, pdf}` with valid `%PDF-` binary output. |
| SC-2 | Multi-page statement shows correct carried-forward at bottom of each non-final page and brought-forward at top of each subsequent page, pre-computed in `sections/2` | VERIFIED | `body_section/2` (line 270) owns per-page chunking via `Rendro.measure_rows/4` (line 291). CF/BF injection confirmed at lines 331–358. V3/V4/V5/V6 tests pass (9 tests). Balance continuity invariant `BF[N+1] == CF[N]` confirmed by test and by code tracing `prev_balance` lookup at line 321. |
| SC-3 | Three-rung escape hatch (`document/2`, `page_template/1`, `sections/2`) available and consistent with `Rendro.Recipes.Invoice` | VERIFIED | All three functions are public with `@spec` and `@doc`. V9 test suite (6 tests) passes. `page_template/1` and `sections/2` callable independently without `document/2`. Region roles `[:body, :footer, :header]` match Invoice (asserted in test). |
| SC-4 | "Page X of Y" in running footer using PAGE primitive; correct page count on every page including last | VERIFIED | `footer_section/2` (line 438) wires `Rendro.page_number(page_number_opts)` into footer region `:footer`. Footer height = 24pt (non-zero, line 170). V7 tests pass (5 tests): "Page 1 of 1", "Page 1 of 2"/"Page 2 of 2", "Page 1 of 3"/"Page 3 of 3" all confirmed. No `{{page_number}}`/`{{total_pages}}` tokens remain in rendered PDF. |

**Score:** 4/4 roadmap success criteria VERIFIED

---

### Plan-Level Must-Have Truths

#### Plan 74-01

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Recipe can ask engine for header height and per-row heights via engine's OWN measurement | VERIFIED | `Rendro.measure_rows/4` (lib/rendro.ex:321) delegates to `Measure.measure_rows/4` which calls `measure_table/3` — the same path as `measure_block/3` Table branch. |
| 2 | `:decimal` declared as core dep | VERIFIED | `mix.exs` line 47: `{:decimal, "~> 2.3"}` confirmed. |
| 3 | Measurement helper is read-only | VERIFIED | `Measure.measure_rows/4` returns `{:ok, {header_h, row_heights}}`; does not mutate doc. `measure_rows_test.exs` 4 tests pass asserting read-only and engine-identity. |

#### Plan 74-02

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Decimal renders as grouped currency `$1,234.50`, parentheses for negatives, deterministic | VERIFIED | `lib/rendro/format.ex` money/1: Decimal.round → grouped → `$`-prefix → parens for negatives. 22 tests pass. |
| 2 | Date renders as ISO `YYYY-MM-DD`, deterministic | VERIFIED | `date/1` delegates to `Date.to_iso8601/1`. |
| 3 | Five default labels available | VERIFIED | `@labels` module attribute at line 34; `label/1` confirmed for all five atoms. |
| 4 | No locale/runtime deps | VERIFIED | `grep -v '^#' lib/rendro/format.ex | grep -cE 'Cldr|Gettext|ex_money|System\.|:os\.'` returns 0. |

#### Plan 74-03

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `document/2` accepts bare atom-keyed data map, returns renderable `%Rendro.Document{}` | VERIFIED | See SC-1 above. |
| 2 | `validate_data!/1` raises `ArgumentError` on missing required keys, non-Decimal amounts, caller-supplied per-line `:balance`, malformed period | VERIFIED | Validation clauses present at lines 484–701. V8 tests (7 tests) confirm each case. |
| 3 | Running balance computed as exact Decimal fold | VERIFIED | `fold_balance/2` at line 457 uses `Decimal.add/2` in `Enum.map_reduce`. |
| 4 | Footer running region carries ONLY Page X of Y, non-zero height | VERIFIED | `footer_section/2` line 444: `[Rendro.page_number(page_number_opts)]`. Footer height = 24pt (> 0). |
| 5 | Three-rung escape hatch structurally consistent with Invoice | VERIFIED | See SC-3. |

#### Plan 74-04

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Multi-page page count equals `ceil(rows / per-page capacity)` | VERIFIED | V2 tests cover 0, 1, cap-1, cap, cap+1, 2*cap+1 boundary row counts. All pass. |
| 2 | Carried-forward is last body row of each non-final page; brought-forward is first body row after page 1 | VERIFIED | CF at line 334–336; BF at line 341–343. V3/V4 tests pass. |
| 3 | CF suppressed on last page; BF suppressed on page 1 | VERIFIED | Guard `if idx < last_page_idx` (CF) and `if idx > 0` (BF). V5 tests pass. |
| 4 | Running balance continuous across breaks | VERIFIED | `prev_balance` from `pages[idx-1].balance_at_break` at line 322. V6 tests pass. |
| 5 | Page X of Y on every page with correct Y | VERIFIED | See SC-4. |
| 6 | Realistic large statement renders without `:content_overflow`; deterministic | VERIFIED | Load-bearing tests (10 pages) pass. V10 byte-identical determinism tests (3 tests) pass. |

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `mix.exs` | `:decimal ~> 2.3` declared core dep | VERIFIED | Line 47: `{:decimal, "~> 2.3"}` |
| `lib/rendro.ex` | `Rendro.measure_rows/4` public, read-only, with `@spec` and `@doc` | VERIFIED | Lines 319–331: spec returns `{number(), [number()]}`, doc contains "read-only" |
| `lib/rendro/pipeline/measure.ex` | Public `measure_rows/4` projection delegating to `measure_table/3` | VERIFIED | Lines 161–168: public function. `measure_table/3` is the shared private function. |
| `lib/rendro/format.ex` | Pure deterministic `Rendro.Format` module with `money/1`, `date/1`, `label/1` | VERIFIED | 147 lines, defmodule `Rendro.Format`, all three public functions with `@spec`. |
| `lib/rendro/recipes/statement.ex` | Three-rung recipe with document/2, page_template/1, sections/2, chunking, CF/BF | VERIFIED | 763 lines. All public functions present with `@spec`. CF/BF injection wired. |
| `test/rendro/measure_rows_test.exs` | Tests proving helper mirrors engine measurement and is read-only | VERIFIED | 4 tests, 0 failures. Asserts exact height equality vs engine. |
| `test/rendro/format_test.exs` | Tests for all Format behaviors and determinism | VERIFIED | 8 doctests + 14 tests, 0 failures. |
| `test/rendro/recipes/statement_test.exs` | V1..V10 + overflow + determinism + page-grouping tests | VERIFIED | 49 tests, 0 failures. Covers all plan acceptance criteria. |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `lib/rendro.ex measure_rows/4` | `lib/rendro/pipeline/measure.ex` | `Measure.measure_rows/4` call | VERIFIED | Line 323: `Pipeline.Measure.measure_rows(document, rows, width, table_opts)` |
| `lib/rendro/recipes/statement.ex footer_section/2` | `Rendro.page_number/1` | footer section content | VERIFIED | Line 444: `[Rendro.page_number(page_number_opts)]` |
| `lib/rendro/recipes/statement.ex balance fold` | `Decimal` | `Decimal.add/2` in fold_balance/2 | VERIFIED | Line 460: `Decimal.add(bal, amt)` |
| `lib/rendro/recipes/statement.ex body_section/2` | `Rendro.measure_rows/4` | chunk rows by engine heights (D-09) | VERIFIED | Line 291: `Rendro.measure_rows(formatted_rows, @content_width, doc_for_measure, table_opts)` |
| `lib/rendro/recipes/statement.ex per-page blocks` | `break_before: true` | D-10 page break | VERIFIED | Line 357: `Rendro.block(table, break_before: idx > 0)` |
| `lib/rendro/format.ex money/1` | `Decimal` | `Decimal.round/abs/negative?` | VERIFIED | Lines 69–73: `Decimal.round`, `Decimal.abs`, `Decimal.negative?` |

---

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|--------------|--------|--------------------|--------|
| `statement.ex body_section/2` | `rows_with_balance` | `fold_balance/2` via `Decimal.add/2` | Yes — exact Decimal fold | FLOWING |
| `statement.ex body_section/2` | `{header_h, row_heights}` | `Rendro.measure_rows/4` via `measure_table/3` | Yes — engine font metrics | FLOWING |
| `statement.ex footer_section/2` | `Rendro.page_number/1` | PAGE primitive from Phase 73 | Yes — resolved at render time | FLOWING |
| `format.ex money/1` | formatted string | `Decimal.round/abs/negative?` + private grouping helpers | Yes — exact Decimal operations | FLOWING |

---

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Single-page smoke render | `Rendro.render(Statement.document(data))` returns `{:ok, pdf}` | `true` | PASS |
| WR-01 wrong closing_balance accepted | `Statement.document(%{..., closing_balance: Decimal.new("99999.99"), lines: []})` | No raise — silently accepted | FAIL (see gaps) |
| CR-01 descending range warning | `Measure.measure_rows(doc, [[], []], 400, [])` | Emits "Range.new/2 ... step of -1" warning | FAIL (see gaps) |
| Statement 49 tests all pass | `mix test test/rendro/recipes/statement_test.exs` | 49 tests, 0 failures | PASS |
| Format 22 tests pass | `mix test test/rendro/format_test.exs` | 8 doctests + 14 tests, 0 failures | PASS |
| measure_rows 4 tests pass | `mix test test/rendro/measure_rows_test.exs` | 4 tests, 0 failures | PASS |
| Compile clean | `mix compile --warnings-as-errors` | Exits 0 | PASS |

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| STMT-01 | 74-01, 74-02, 74-03, 74-04 | `document/2` generates statement from data map | SATISFIED | `document/2` public, accepts map, returns renderable `%Rendro.Document{}`. Single-page and multi-page renders pass. |
| STMT-02 | 74-01, 74-03, 74-04 | Multi-page with CF/BF running balance in data-assembly | SATISFIED (qualified) | Core CF/BF logic verified. Balance fold is exact Decimal. However: WR-01 means the optional `:closing_balance` *assertion* is documented as validated but is only type-checked. The actual running balance computation is correct. |
| STMT-03 | 74-03, 74-04 | Three-rung escape hatch consistent with Invoice | SATISFIED | `document/2`, `page_template/1`, `sections/2` all present, public, with `@spec`. Region roles match Invoice. V9 tests confirm independent callability. |
| STMT-04 | 74-03, 74-04 | PAGE primitive for "Page X of Y" running footer | SATISFIED | Footer region 24pt non-zero. `Rendro.page_number/1` wired in `footer_section/2`. V7 tests confirm correct page numbers on all pages. |

No orphaned requirements: STMT-01..04 are the only Phase 74 requirements in REQUIREMENTS.md. All four are claimed in plans and verified.

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `lib/rendro/pipeline/measure.ex` | 286 | `for c <- 0..(col_count - 1)` — no explicit `//1` step | BLOCKER | When `col_count==0`, produces descending range `0..-1` → runtime deprecation warning + spurious `{r,-1}` grid cell. Reachable through public `Rendro.measure_rows/4`. Will be a hard error in future Elixir. |
| `lib/rendro/recipes/statement.ex` | 679–701 | `maybe_validate_closing_balance!/1` accepts any `%Decimal{}` without value check | BLOCKER | Moduledoc (line 33) documents "validated via `Decimal.equal?/2` when present" but implementation only type-checks. A caller supplying a wrong `:closing_balance` has it silently accepted. |
| `lib/rendro/recipes/statement.ex` | 293–297 | `capacity = @body_height - @header_height - @footer_height` double-subtracts | WARNING | `@body_height` already nets out header/footer once. Recipe packs 35 rows/page where engine can fit 38 (~8% over-paginates). Conservative but wastes space. The comment is factually wrong about `body_capacity/1` overlap logic. |
| `lib/rendro/recipes/statement.ex` | 505–523 | `:account` shape is unvalidated | WARNING | A non-map `:account` causes `BadMapError` in `header_section/2` instead of an instructive `ArgumentError`. Inconsistent with the recipe's errors-as-product contract. |
| `lib/rendro/recipes/statement.ex` | 376–383 | Comment says "median/mean or conservative max"; code uses arithmetic mean only | INFO | Misleading comment. No correctness impact for uniform row heights used by the recipe. |
| `lib/rendro/recipes/statement.ex` | 380 | Magic number `14.4` (unexplained fallback row height) | INFO | Should be a named module attribute with derivation comment (`12 * 1.2 = default_size * line_height`). |
| `lib/rendro/recipes/statement.ex` | 705–711 | `Enum.map_reduce/3` result discarded with `_ = rows` in `maybe_validate_summary!/1` | INFO | Should be `Enum.reduce/3`; the map accumulator is wasted. No behavioral impact. |

No `TBD`, `FIXME`, or `XXX` markers found in any Phase 74 files.

---

### Full-Suite Test Regression Assessment

`mix test` (full suite) currently reports 48 failures. **None are caused by Phase 74 work.** The failures fall into three pre-existing categories:

1. **Time-based staleness failure (viewer evidence):** `priv/support_matrix.json` has a viewer recorded on 2025-11-29 — exactly 181 days ago today (threshold: 180 days). This test was passing when the phase was executed on 2026-05-29 at approximately 18:00 UTC (the boundary), and was identified as a pre-existing concern in the 74-02 SUMMARY deferred-items.

2. **Telemetry service not started:** `Rendro.Text.ShaperTest` and `Rendro.Adapters.ThreadlineTest` (22 failures) require the Telemetry application to be running; they fail with `:gen_server.call(:telemetry_handler_table, ...)` exits. These test files were last modified in Phase 37 / Phase 15 — well before Phase 74.

3. **Docs-contract integration tests (25 failures):** `integrations_claims_test.exs` and `integrations_contract_test.exs` fail due to the same telemetry/app-startup issue. Last modified in Phase 72 and Phase 69.

All 67 Phase 74 tests (49 statement + 14 format + 4 measure_rows = 67) pass: `mix test test/rendro/recipes/statement_test.exs test/rendro/format_test.exs test/rendro/measure_rows_test.exs` → **67 tests, 0 failures**.

---

### Gaps Summary

Two gaps block the gap list (both flagged by code review, independently confirmed in codebase):

**Gap 1 — BLOCKER: CR-01 descending-range bug in `measure.ex`**

`do_build_grid/4` line 286 uses `for c <- 0..(col_count - 1)` without an explicit `//1` step. When `col_count == 0` (rows with no cells, no header, no columns), this produces a descending range `0..-1` that:
- Emits a runtime deprecation warning (confirmed in spot-check)
- Builds a spurious `{r, -1}` entry in the grid map
- Is reachable through the documented public API `Rendro.measure_rows/4`

The Statement recipe itself always passes 4 columns and never hits this path, so the recipe's own tests pass. However this is a correctness/safety defect in a new public API surface introduced in this phase. The fix is trivial: add `//1` to both range comprehensions.

**Gap 2 — BLOCKER: WR-01 `:closing_balance` type-checked but not value-validated**

`maybe_validate_closing_balance!/1` (lines 679–701) only type-checks the caller-supplied `:closing_balance`. A wrong `%Decimal{}` value falls through to the catch-all `do: :ok` with no error. The moduledoc (line 33) and the `validate_data!/1` comment (line 481) both state this field is "validated via `Decimal.equal?/2` when present" — this is false. The value check is present for `summary.closing_balance` (line 714) but absent for the top-level key, making this an inconsistency. A caller who supplies a wrong closing balance believes it will be caught; it will not.

These two gaps are independent and both fixable with small, targeted changes. The four ROADMAP success criteria are functionally achieved — the recipe generates correct multi-page statements end-to-end — but the codebase ships a public API with a pending deprecation-to-error timebomb (CR-01) and a documented-but-unimplemented validation contract (WR-01).

---

_Verified: 2026-05-29T15:00:00Z_
_Verifier: Claude (gsd-verifier)_
