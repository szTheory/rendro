---
phase: 06-pipeline-telemetry-contract
plan: 02
subsystem: pipeline-validation
tags: [elixir, pipeline, validation, pdf, telemetry, security]
requires:
  - lib/rendro/pipeline.ex
  - lib/rendro/pipeline/build.ex
  - lib/rendro/pipeline/render.ex
  - lib/rendro/error.ex
  - lib/rendro/document.ex
provides:
  - "Rendro.Pipeline.Validate.run/2 (PDF binary + Document) with structural sanity, page-count parity, max_bytes enforcement"
  - "[:rendro, :pipeline, :validate, :start | :stop | :exception] telemetry events emitted on every render"
  - "max_bytes_exceeded errors attributed to :validate stage instead of :render"
  - "CHANGELOG.md at repo root per Keep-a-Changelog v1.1.0"
affects:
  - "lib/rendro/pipeline.ex — run_stages/3 with-chain extended; validate_policy(:bytes) removed"
  - "test/rendro/telemetry_test.exs — adds 2 ordering tests asserting :validate fires after :render"
  - "test/rendro/policy_test.exs — still passes; max_bytes_exceeded reason unchanged, attribution moves silently"
  - "test/rendro/adapters/threadline_test.exs — D-20 partial verification: still 8/8 green"
tech-stack:
  added: []
  patterns:
    - "Identity-on-success stage pattern: Validate.run/2 returns {:ok, pdf_binary} unchanged so the with-chain stays single-threaded (RESEARCH.md Pitfall 2)"
    - "Bounded non-backtracking regex for parser-DoS mitigation (T-06-05): ~r{/Type\\s+/Pages.*?/Count\\s+(\\d+)}s with structural-check short-circuit before regex"
    - "Two-direction regex fallback to handle deterministic-mode key sorting (/Count before /Type /Pages)"
key-files:
  created:
    - lib/rendro/pipeline/validate.ex
    - test/rendro/pipeline/validate_test.exs
    - CHANGELOG.md
    - .planning/phases/06-pipeline-telemetry-contract/deferred-items.md
  modified:
    - lib/rendro/pipeline.ex
    - test/rendro/telemetry_test.exs
key-decisions:
  - "Bug fixed inline (Rule 1): page-count regex was direction-sensitive; deterministic mode sorts dict keys alphabetically so /Count appears BEFORE /Type /Pages. parse_page_count/1 now tries both orderings; reverse regex bounded by [^>] to prevent unbounded scanning"
  - "Plan 03's compose↔measure swap intentionally NOT done here (Plan 02 only adds :validate at the END of the still-buggy chain); :pending_full_pipeline tags retained on 6 telemetry tests until Plan 03"
  - "Pre-existing mix format failures in 5 unrelated files logged to deferred-items.md; out of scope per executor scope-boundary rule"
metrics:
  duration_min: 12
  completed: 2026-04-27
requirements_marked_complete: []
requirements_partial: [OBS-01, CORE-01]
threat_flags: []
---

# Phase 06 Plan 02: Pipeline Telemetry Contract — Wave 2 Validate Summary

**One-liner:** Wires the trailing `:validate` stage into the pipeline with three identity-on-success checks (PDF structural sanity, page-count parity, `:max_bytes` enforcement), closing BLOCKER-04 and absorbing the inline `validate_policy(:bytes)` clause into the new stage.

## What Shipped

### Closed
- **BLOCKER-04** (missing `:validate` event). Every successful render now emits `[:rendro, :pipeline, :validate, :start]` and `[:rendro, :pipeline, :validate, :stop]` after `[:rendro, :pipeline, :render, :stop]`. Two new ordering tests in `test/rendro/telemetry_test.exs` lock this contract.

### Wired
- **`Rendro.Pipeline.Validate.run/2`** — new module at `lib/rendro/pipeline/validate.ex`. Performs three checks in order via an internal `with`-chain:
  1. **Structural sanity** — `%PDF-` header present, `%%EOF` trailer present.
  2. **Page-count parity** — PDF `/Type /Pages` object's `/Count N` matches `length(doc.pages)`. Robust to both writer modes (default order: `/Type /Pages...Count`; deterministic order: `/Count...Type /Pages`).
  3. **`:max_bytes` policy** — `byte_size(pdf) <= policies[:max_bytes]` when set; absorbed from the deleted inline clause per D-07.3.
- **`Rendro.Pipeline.run_stages/3`** — `Validate` added to the `alias` list; new trailing `with`-chain step `{:ok, pdf_binary} <- span(:validate, base_meta, fn -> Validate.run(pdf_binary, doc) end, doc)`. The inline `validate_policy(:bytes, ...)` clause AND its private function definition are deleted.
- **`@moduledoc`** updated with a NOTE block clarifying that the canonical compose↔measure order lands in Plan 03 (the buggy order is preserved in this wave; only `:validate` is added at the end).

### Pending (Plan 03)
- **BLOCKER-05** (compose↔measure swap). The `with`-chain still has measure before compose; Plan 03 will reorder. Six telemetry tests retain `@tag :pending_full_pipeline` for the duration.
- **D-04 latent bug fix** (page-2 remainder y-inheritance). Plan 03 absorbs y-stacking into Paginate.
- **D-20 final verification** (Threadline adapter unaffected). Partial verification done here (8/8 green); full re-run in Plan 03.

## Tasks

| # | Task | Commits | TDD Gate |
|---|------|---------|----------|
| 1 | Create `Rendro.Pipeline.Validate` module + 14 unit tests | `6bfed08` (RED), `170f25b` (GREEN) | RED→GREEN |
| 2 | Wire Validate into `Pipeline.run_stages`; remove inline validate_policy(:bytes); add 2 telemetry ordering tests; fix deterministic-mode regex bug (Rule 1) | `fccb7a0` | n/a (Task 1 covers TDD gate for Validate; Task 2 adds wiring + bug fix) |
| 3 | Author root CHANGELOG.md per Keep-a-Changelog v1.1.0 (D-18) | `defdc45` | n/a |

## Files Modified

| File | Change |
|------|--------|
| `lib/rendro/pipeline/validate.ex` | NEW. 84 lines. `defmodule Rendro.Pipeline.Validate` with `@spec run(binary(), Rendro.Document.t()) :: {:ok, binary()} \| {:error, atom()}`, three private check helpers (`check_structural/1`, `check_page_count/2`, `check_max_bytes/2`), and a two-direction page-count parser (`parse_page_count/1` → `match_count_after_pages/1` → `match_count_before_pages/1` fallback). PDF header/trailer literals as module attributes. |
| `test/rendro/pipeline/validate_test.exs` | NEW. 139 lines. 14 tests across 5 describe blocks: happy path (3), `:structural_corruption` (3 incl. T-06-05 regression for parser-DoS), `:page_count_mismatch` (3 incl. deterministic-mode regression), `:max_bytes_exceeded` (3), guard clauses (2). Test 1MB adversarial binary structurally rejected in <100ms; tests are async-safe. |
| `lib/rendro/pipeline.ex` | `@moduledoc` gains a NOTE block explaining the deferred compose↔measure swap. `alias` line extended with `Validate`. `run_stages/3` `with`-chain gains trailing `span(:validate, ...)` clause. The inline `validate_policy(:bytes, pdf_binary, policies, base_meta)` clause is REMOVED from the chain; its `defp` function definition is REMOVED entirely. `defp validate_policy(:pages, ...)` is preserved (D-10). |
| `test/rendro/telemetry_test.exs` | Two new tests appended to the `event ordering` describe block: `":validate stop event fires after :render stop"` and `":validate start event fires after :render stop"`. Both pass immediately because the orchestrator now emits the new prefix. The 6 pre-existing `@tag :pending_full_pipeline` tests remain pending (Plan 03 unblocks). |
| `CHANGELOG.md` | NEW. Root-level Keep-a-Changelog v1.1.0 file with `## [0.1.0] - Unreleased` section: `### Added` for `:validate` events + module + Error clauses; `### Changed (BREAKING)` for stage order, max_pages attribution, max_bytes attribution, unified stop_meta schema; `### Notes` for the no-bridge-period rationale. References BLOCKER-04, BLOCKER-05, MINOR-15. |
| `.planning/phases/06-pipeline-telemetry-contract/deferred-items.md` | NEW. Logs 5 pre-existing `mix format --check-formatted` failures in unrelated files (threadline.ex, mailglass.ex, recipes.ex, mix/tasks/verify.ex, policy_test.exs) as out-of-scope per executor scope-boundary rule. |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Page-count regex broke in deterministic mode**
- **Found during:** Task 2 verification (`mix test test/rendro/telemetry_test.exs --exclude pending_full_pipeline` reported a `MatchError` in `deterministic flag deterministic: true when option set` test, surfacing a `:page_count_mismatch` from the new `:validate` stage).
- **Issue:** The plan-pinned regex `~r{/Type\s+/Pages.*?/Count\s+(\d+)}s` requires `/Type /Pages` to appear BEFORE `/Count` in the rendered binary. In deterministic mode, `lib/rendro/pdf/object.ex:47-49` alphabetizes dict keys, so `/Count` (C) precedes `/Type` (T) within the same `<<...>>` object. Forward-only regex returns `nil`; `parse_page_count/1` falls back to `0`; mismatch fires for every deterministic render.
- **Fix:** Kept the plan-pinned forward regex as-is (acceptance criterion intact) and added a fallback `match_count_before_pages/1` that captures `/Count N` followed within a single dict body (`[^>]*?` keeps the search bounded to one object — preserves T-06-05 mitigation discipline) by `/Type /Pages`. Wrapped both in `parse_page_count/1` via `cond do result = match_count_after_pages(...) -> result; result = match_count_before_pages(...) -> result; true -> 0 end`.
- **Files modified:** `lib/rendro/pipeline/validate.ex`, `test/rendro/pipeline/validate_test.exs` (added regression test "succeeds when deterministic-mode writer sorts /Count before /Type /Pages" with binary-position invariant assertion).
- **Commit:** `fccb7a0`.

### Out-of-scope (NOT auto-fixed)

**Pre-existing `mix format --check-formatted` failures in 5 unrelated files**
- **Files:** `lib/rendro/adapters/threadline.ex`, `lib/rendro/adapters/mailglass.ex`, `lib/rendro/recipes.ex`, `lib/mix/tasks/verify.ex`, `test/rendro/policy_test.exs`.
- **Verification:** Confirmed pre-existing via `git stash && mix format --check-formatted` (same 5 files reported with all Phase 06 changes removed).
- **Action:** Logged to `.planning/phases/06-pipeline-telemetry-contract/deferred-items.md`. Per-file format check on Phase 06 files only is green (`mix format --check-formatted lib/rendro/pipeline.ex lib/rendro/pipeline/validate.ex test/rendro/pipeline/validate_test.exs test/rendro/telemetry_test.exs` exits 0).
- **Why deferred:** Executor scope boundary rule — only auto-fix issues DIRECTLY caused by current task changes.

## Authentication Gates

None.

## Test Inventory

### New tests in `test/rendro/pipeline/validate_test.exs` (14 total)

| # | Describe | Test |
|---|----------|------|
| 1 | run/2 — happy path | returns {:ok, pdf} unchanged for a well-formed 1-page render |
| 2 | run/2 — happy path | returns {:ok, pdf} unchanged for a well-formed 2-page render |
| 3 | run/2 — happy path | is idempotent — same result on repeated calls |
| 4 | run/2 — :structural_corruption | returns {:error, :structural_corruption} when binary lacks %PDF- header |
| 5 | run/2 — :structural_corruption | returns {:error, :structural_corruption} when binary lacks %%EOF trailer |
| 6 | run/2 — :structural_corruption | structural check rejects giant non-PDF binaries quickly (T-06-05 regression) |
| 7 | run/2 — :page_count_mismatch | returns {:error, :page_count_mismatch} when /Count != length(doc.pages) |
| 8 | run/2 — :page_count_mismatch | returns {:error, :page_count_mismatch} when /Type /Pages object is missing entirely |
| 9 | run/2 — :page_count_mismatch | succeeds when deterministic-mode writer sorts /Count before /Type /Pages (Rule 1 regression test) |
| 10 | run/2 — :max_bytes_exceeded | returns {:error, :max_bytes_exceeded} when byte_size > policy limit |
| 11 | run/2 — :max_bytes_exceeded | returns {:ok, pdf} when max_bytes is nil |
| 12 | run/2 — :max_bytes_exceeded | returns {:ok, pdf} when byte_size <= max_bytes |
| 13 | run/2 — guard clauses | raises FunctionClauseError when first arg is not a binary |
| 14 | run/2 — guard clauses | raises FunctionClauseError when second arg is not a Document |

### New tests in `test/rendro/telemetry_test.exs` (2 total)

| Test | Purpose |
|------|---------|
| `:validate stop event fires after :render stop` | Asserts `validate_stop_idx > render_stop_idx` in the collected event names list, proving the new event prefix lands AFTER the existing `:render` prefix. |
| `:validate start event fires after :render stop` | Asserts `validate_start_idx > render_stop_idx`, proving the validate span opens only after render completes. |

## Verification Commands Run

| Command | Exit | Notes |
|---------|------|-------|
| `mix compile --warnings-as-errors` | 0 | Clean compile after each task |
| `mix format --check-formatted lib/rendro/pipeline.ex lib/rendro/pipeline/validate.ex test/rendro/pipeline/validate_test.exs test/rendro/telemetry_test.exs` | 0 | Per-file format check on Phase 06 files |
| `mix test test/rendro/pipeline/validate_test.exs` | 0 | 14 tests, 0 failures |
| `mix test test/rendro/policy_test.exs` | 0 | 3 tests, 0 failures (max_bytes attribution moved to :validate; assertion only checks `reason: :max_bytes_exceeded`, unchanged) |
| `mix test test/rendro/adapters/threadline_test.exs` | 0 | 8 tests, 0 failures — D-20 partial verification |
| `mix test test/rendro/telemetry_test.exs --exclude pending_full_pipeline` | 0 | 26 tests, 0 failures, 6 excluded |
| `mix test --exclude pending_full_pipeline` | 0 | 3 properties, 210 tests, 0 failures, 6 excluded |

## Acceptance Criteria Spot-Checks

```
$ grep -F 'alias Rendro.Pipeline.{Build, Compose, Measure, Paginate, Render, Validate}' lib/rendro/pipeline.ex
  alias Rendro.Pipeline.{Build, Compose, Measure, Paginate, Render, Validate}

$ grep -F 'span(:validate, base_meta, fn -> Validate.run(pdf_binary, doc) end, doc)' lib/rendro/pipeline.ex
           span(:validate, base_meta, fn -> Validate.run(pdf_binary, doc) end, doc) do

$ grep -c -F 'defp validate_policy(:bytes' lib/rendro/pipeline.ex
0

$ grep -c -F 'validate_policy(:bytes,' lib/rendro/pipeline.ex
0

$ grep -c -F 'defp validate_policy(:pages' lib/rendro/pipeline.ex
1

$ grep -F ':validate stop event fires after :render stop' test/rendro/telemetry_test.exs
    test ":validate stop event fires after :render stop" do

$ grep -c -F 'defmodule Rendro.Pipeline.Validate do' lib/rendro/pipeline/validate.ex
1

$ grep -F '@spec run(binary(), Rendro.Document.t())' lib/rendro/pipeline/validate.ex
  @spec run(binary(), Rendro.Document.t()) :: {:ok, binary()} | {:error, atom()}

$ grep -F 'def run(pdf_binary, %Rendro.Document{} = doc) when is_binary(pdf_binary)' lib/rendro/pipeline/validate.ex
  def run(pdf_binary, %Rendro.Document{} = doc) when is_binary(pdf_binary) do

$ grep -c -E '^[[:space:]]+test "' test/rendro/pipeline/validate_test.exs
14

$ wc -l < lib/rendro/pipeline/validate.ex
84

$ [ -f CHANGELOG.md ] && echo "FOUND"
FOUND

$ grep -F '## [0.1.0] - Unreleased' CHANGELOG.md
## [0.1.0] - Unreleased

$ grep -F 'compose → measure → paginate → render → validate' CHANGELOG.md
- Pipeline stage execution order now matches the documented architecture: `build → compose → measure → paginate → render → validate`. ...
```

## Carry-Forward to Plan 03

- **`@tag :pending_full_pipeline` tests still pending (6).** Plan 03 unblocks all six by reordering `run_stages/3` to canonical `build → compose → measure → paginate → render → validate` order:
  - `"all 6 pipeline stages emit start and stop events"`
  - `"total event count: 6 stages + 1 top-level = 14 (7 start + 7 stop)"`
  - `"each stage start event has the correct stage name"`
  - `"stages after the failed stage do not emit events"`
  - `"events fire in pipeline stage order"`
  - `"each stage start fires before its stop"`
- **`Rendro.Pipeline.run_stages/3` `@moduledoc` NOTE block** documents the temporary inversion; Plan 03 must remove the NOTE block when it lands the canonical order.
- **`compose ↔ measure` swap, D-04 latent y-stacking bug fix, D-20 full Threadline re-verification** are all Plan 03 territory.
- **Page-count regex robustness:** the new `match_count_before_pages/1` fallback was added to handle deterministic mode; Plan 03 should not need to revisit unless the writer's serialization format changes again.

## Self-Check: PASSED

**Files claimed:**
- `lib/rendro/pipeline/validate.ex` — FOUND (created)
- `test/rendro/pipeline/validate_test.exs` — FOUND (created)
- `lib/rendro/pipeline.ex` — FOUND (modified)
- `test/rendro/telemetry_test.exs` — FOUND (modified)
- `CHANGELOG.md` — FOUND (created)
- `.planning/phases/06-pipeline-telemetry-contract/deferred-items.md` — FOUND (created)

**Commits claimed (all in `git log`):**
- `6bfed08` test(06-02): add failing tests for Rendro.Pipeline.Validate
- `170f25b` feat(06-02): implement Rendro.Pipeline.Validate trailing stage
- `fccb7a0` feat(06-02): wire :validate stage into Rendro.Pipeline run_stages
- `defdc45` docs(06-02): add CHANGELOG.md per Keep-a-Changelog v1.1.0 (D-18)

All claims verified.
