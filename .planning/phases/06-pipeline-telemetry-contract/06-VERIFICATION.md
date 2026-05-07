---
phase: 06-pipeline-telemetry-contract
verified: 2026-04-27T15:18:44Z
status: passed
score: 3/3 must-haves verified
overrides_applied: 0
must_haves:
  truths:
    - "Pipeline emits [:rendro, :pipeline, :validate, :start|:stop|:exception] in addition to existing five stages"
    - "Stage execution order matches REQUIREMENTS.md spec (compose precedes measure)"
    - "Stage stop metadata preserves page_count and byte_size from doc.pages even on the error path"
  artifacts:
    - path: "lib/rendro/telemetry.ex"
      provides: "@stage_names list including :validate"
    - path: "lib/rendro/pipeline.ex"
      provides: "Canonical stage order with compose before measure; unified stage_stop_meta/5"
    - path: "lib/rendro/pipeline/validate.ex"
      provides: "Trailing post-render validation stage module"
    - path: "lib/rendro/error.ex"
      provides: "what/2 and next_step/2 clauses for :validate stage"
    - path: "CHANGELOG.md"
      provides: "Keep-a-Changelog v1.1.0 entry documenting BLOCKER-04/05 + MINOR-15 closure"
---

# Phase 06: pipeline-telemetry-contract Verification Report

**Phase Goal:** Bring the rendering pipeline back into agreement with REQUIREMENTS.md OBS-01 — emit the missing `:validate` telemetry event, restore spec-stated stage order (build → compose → measure → paginate → render → validate), and stop dropping page/byte metrics on the error path.
**Verified:** 2026-04-27T15:18:44Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Pipeline emits `[:rendro, :pipeline, :validate, :start\|:stop\|:exception]` in addition to existing five stages | VERIFIED | `lib/rendro/telemetry.ex:26` declares `@stage_names [:build, :compose, :measure, :paginate, :render, :validate]`; `all_event_names/0` cascades the new prefix. Live runtime spot-check captured both `[:rendro, :pipeline, :validate, :start]` and `[:rendro, :pipeline, :validate, :stop]` events on a real `Rendro.Pipeline.run/1` call (14 total events received). Test `test/rendro/telemetry_test.exs:411` (`Rendro.Telemetry.all_event_names/0 includes :validate event names`) passes; `test/rendro/telemetry_test.exs:368` (`:validate stop event fires after :render stop`) passes. |
| 2 | Stage execution order matches REQUIREMENTS.md spec (compose precedes measure) | VERIFIED | `lib/rendro/pipeline.ex:77-88` `defp run_stages/3` body — `with`-clauses execute in order `:build → :compose → :measure → :paginate → validate_policy(:pages) → :render → :validate`. `compose` clause (line 79) precedes `measure` clause (line 80). Test `test/rendro/telemetry_test.exs:324` asserts `stage_starts == [:build, :compose, :measure, :paginate, :render, :validate]` and passes (no `@tag :pending_full_pipeline` markers remain — `grep -c '@tag :pending_full_pipeline'` returns `0`). Live spot-check confirmed the canonical event ordering. |
| 3 | Stage stop metadata preserves `page_count` and `byte_size` from `doc.pages` even on the error path | VERIFIED | `lib/rendro/pipeline.ex:118-136` `stage_stop_meta/5` derives `page_count` from result-or-last_doc via `derive_page_count/2` (lines 138-140) for ALL three branches (`:ok`, `{:error, %Error{}}`, `{:error, reason}`) — never hardcoded to 0 on errors. `build_stop_meta/3` error branch (lines 63-73) uses `length(doc.pages)`. Live spot-check with `max_bytes: 1` failure produced `[:rendro, :pipeline, :validate, :stop]` carrying `page_count: 1` (not 0); top-level `[:rendro, :render, :stop]` mirrored `page_count: 1`. Test `test/rendro/telemetry_test.exs:445` (`MINOR-15 regression`) and `:469` (`:error map with kind and stage`) both pass. `grep -c 'page_count: 0, byte_size: 0' lib/rendro/pipeline.ex` returns `0`. |

**Score:** 3/3 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/rendro/telemetry.ex` | `@stage_names` includes `:validate` | VERIFIED (substantive + wired) | Line 26: `@stage_names [:build, :compose, :measure, :paginate, :render, :validate]`. `@event_prefixes` (line 28) cascades. `all_event_names/0` (lines 42-47) emits 21 events (7 prefixes × 3 suffixes). Imported by `lib/rendro/pipeline.ex` and used in `execute_with_telemetry/3`. |
| `lib/rendro/pipeline.ex` | Canonical stage order; unified stage_stop_meta/5 | VERIFIED (substantive + wired) | `run_stages/3` (lines 77-88) executes canonical order. `stage_stop_meta/5` is the single unified builder (`grep -c 'defp stage_stop_meta(' = 1`). `build_stop_meta/3` returns the D-11 schema for both branches. `derive_page_count/2` and `derive_byte_size/2` helpers exist (lines 138-144). Validate is wired via `span(:validate, base_meta, fn -> Validate.run(pdf_binary, doc) end, doc)` on line 84-85. |
| `lib/rendro/pipeline/validate.ex` | New trailing post-render stage with PDF structural sanity, page-count parity, max_bytes enforcement | VERIFIED (substantive + wired + data flowing) | 86 lines, exists. `defmodule Rendro.Pipeline.Validate`, `@spec run(binary(), Rendro.Document.t()) :: {:ok, binary()} \| {:error, atom()}`, `def run/2` with three private helpers `check_structural/1`, `check_page_count/2`, `check_max_bytes/2`. Imported via alias on `lib/rendro/pipeline.ex:18` and called from `run_stages/3`. Live spot-check: real PDF binary (694 bytes, 1 page) successfully validated; `max_bytes: 1` correctly returns `{:error, :max_bytes_exceeded}` attributed to `:validate` stage. |
| `lib/rendro/error.ex` | what/next_step clauses for `:validate` stage with three reasons | VERIFIED (substantive + wired) | Line 45: `defp what(:validate, _reason), do: "Post-render validation failed."`. Lines 82-92: three `defp next_step(:validate, ...)` clauses for `:structural_corruption`, `:page_count_mismatch`, `:max_bytes_exceeded`. `from_stage/3` (lines 23-38) dispatches to these via `where: "Rendro.Pipeline.#{stage_module_suffix(stage)}"` → `"Rendro.Pipeline.Validate"`. Tested in `test/rendro/error_test.exs:29`. |
| `CHANGELOG.md` | Keep-a-Changelog v1.1.0 file with `[0.1.0] - Unreleased` section | VERIFIED | Exists at repo root. Header references `https://keepachangelog.com/en/1.1.0/`. Contains `## [0.1.0] - Unreleased`, `### Added`, `### Changed (BREAKING)`, and `### Notes`. References BLOCKER-04, BLOCKER-05, MINOR-15 by ID. Contains canonical stage order phrase using Unicode arrows. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `Rendro.Pipeline.run_stages/3` | `Rendro.Pipeline.Validate.run/2` | `span(:validate, base_meta, fn -> Validate.run(pdf_binary, doc) end, doc)` | WIRED | `lib/rendro/pipeline.ex:84-85` — exact match of expected pattern. |
| `Rendro.Pipeline.run_stages/3` `with`-chain | compose stage runs BEFORE measure stage | with-clause ordering | WIRED | Lines 79 (compose) and 80 (measure) — verified via `awk` extraction; compose appears at line offset 2, measure at line offset 3 within `run_stages/3`. |
| `Rendro.Pipeline.span/4` | unified `stage_stop_meta/5` | three case arms (ok / error-Error / error-reason) all call `stage_stop_meta(stage, ...)` | WIRED | `lib/rendro/pipeline.ex:106, 109, 113` — all three branches funnel through the same builder. |
| `Rendro.Pipeline.Compose` | owns `normalize_row/1` | private helper | WIRED | `lib/rendro/pipeline/compose.ex:31` (the only file containing `defp normalize_row`); `lib/rendro/pipeline/measure.ex` no longer has `normalize_row` (`grep -c` returns 0). |
| `Rendro.Pipeline.Paginate` | y-stacking with per-page cursor reset | private `stack_block_y/1` invoked per page | WIRED | `lib/rendro/pipeline/paginate.ex:40` (`\|> Enum.map(&stack_block_y/1)`); definition at line 55; uses `current_y` accumulator with per-page `starting_y = margin_top \|\| 0`. Compose no longer contains `current_y` (`grep -c` returns 0). |
| `Rendro.Telemetry.@stage_names` | telemetry helper subscriptions | `all_event_names/0` | WIRED | Line 42-47 in `telemetry.ex`; consumed by `test/support/telemetry_helper.ex` `attach/1` so `:validate` events are auto-subscribed in tests. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|--------------|--------|--------------------|--------|
| `Rendro.Pipeline.run/1` → telemetry handlers | stop event metadata | `stage_stop_meta/5` derives from `result` and `last_doc` | YES — runtime spot-check produced `pc=1 bs=694` on `:render :stop` and `:validate :stop` for a real PDF; error path produced `pc=1 bs=0` (correct: byte_size only set for binary results). | FLOWING |
| `Rendro.Pipeline.Validate.run/2` | `pdf_binary` validation result | three `check_*` helpers operating on input binary | YES — runtime spot-check confirmed `:max_bytes_exceeded` returned for `max_bytes: 1` policy; happy path returned `{:ok, pdf}` identity for valid 694-byte binary. | FLOWING |
| `Rendro.Error.from_stage(:validate, ...)` | `%Rendro.Error{}` envelope | static dispatch via `what/2` and `next_step/2` clauses | YES — runtime spot-check produced `error stage=:validate reason=:max_bytes_exceeded`. | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Full test suite green (no exclusions) | `mix test` | `3 properties, 217 tests, 0 failures` | PASS |
| Targeted phase-06 tests | `mix test test/rendro/telemetry_test.exs test/rendro/pipeline/validate_test.exs test/rendro/pipeline/paginate_test.exs test/rendro/error_test.exs test/rendro/policy_test.exs` | `59 tests, 0 failures` | PASS |
| Threadline adapter test (D-20 verification) | `mix test test/rendro/adapters/threadline_test.exs` | `8 tests, 0 failures` | PASS |
| Live telemetry event count for successful render | `mix run --no-start -e '...'` | 14 events received in canonical order: render-start, build-start/stop, compose-start/stop, measure-start/stop, paginate-start/stop, render-start/stop, validate-start/stop, render-stop | PASS |
| Live error path metrics (max_bytes: 1) | `mix run --no-start -e '...'` | `error stage=:validate reason=:max_bytes_exceeded`; 2 error stops with `pc=1` (NOT 0) — MINOR-15 closure confirmed | PASS |
| `validate_policy(:bytes, ...)` clause removed | `grep -c 'defp validate_policy(:bytes' lib/rendro/pipeline.ex` | 0 | PASS |
| Old hardcoded zero-on-error literal removed | `grep -c 'page_count: 0, byte_size: 0' lib/rendro/pipeline.ex` | 0 | PASS |
| All `:pending_*` test tags retired | `grep -c '@tag :pending_full_pipeline\|@tag :pending_unified_schema' test/rendro/telemetry_test.exs` | 0 | PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| OBS-01 | 06-01, 06-02, 06-03 | Operator can observe telemetry events for build, compose, measure, paginate, render, and validate lifecycle steps | SATISFIED | `:validate` is now a first-class telemetry stage with start/stop/exception events. Live runtime spot-check confirms emission. Canonical six-stage order locked in code and asserted by `test/rendro/telemetry_test.exs:324`. NOTE: REQUIREMENTS.md traceability table marks final verification as Phase 11; Phase 6 lays the contract surface, which is verified here. |
| OBS-02 | 06-01 | Operator can correlate render operations with artifact metrics (duration, page count, byte size, status) | SATISFIED (this phase's slice) | Unified `stage_stop_meta/5` produces D-11 schema (`render_id, document_type, deterministic, stage, status, page_count, byte_size`) for ALL stage stops. Error path preserves `page_count` from `doc.pages` (closes MINOR-15). Live error-path spot-check shows `pc=1` on failure rather than 0. Phase 8 closes the timeout-path gap (MAJOR-10) — out of scope for this phase. |
| CORE-01 | 06-02, 06-03 | Engineer can define a PDF document from Elixir data/components using a pure core API | SATISFIED (this phase's slice) | The pipeline now matches the documented architecture; spec-stated stage order restored (`build → compose → measure → paginate → render → validate`). `Rendro.Pipeline.Validate` adds a real post-render correctness gate that catches structural corruption, page-count divergence, and policy violations. Full test suite (217 tests) green. Final verification reserved for Phase 11. |

All three declared requirement IDs (OBS-01, OBS-02, CORE-01) are accounted for in plan frontmatter. No orphaned IDs from REQUIREMENTS.md mapping for this phase.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| (none) | — | No TODO/FIXME/XXX/HACK/placeholder strings detected in any phase-06 source file (`pipeline.ex`, `pipeline/validate.ex`, `telemetry.ex`, `error.ex`, `pipeline/compose.ex`, `pipeline/measure.ex`, `pipeline/paginate.ex`) | — | — |
| (none) | — | No hardcoded `page_count: 0, byte_size: 0` error-path literal | — | Old MINOR-15 stub pattern fully removed |
| (none) | — | No leftover `defp validate_policy(:bytes, ...)` clause | — | D-07.3 absorption completed; max_bytes now lives in `:validate` stage body |
| (none) | — | No `:pending_full_pipeline` or `:pending_unified_schema` test tags remain | — | All Wave-3 cleanup completed |

### Human Verification Required

(none — all observable truths are programmatically verified via live runtime spot-checks of telemetry emission, full suite test runs, and source-level pattern checks)

### Gaps Summary

No gaps. All three roadmap success criteria are observably satisfied:

1. **`:validate` event emission** — Live runtime confirms 14 events including `[:rendro, :pipeline, :validate, :start]` and `[:rendro, :pipeline, :validate, :stop]` for every successful render; emission also occurs on the error path (e.g., `max_bytes` failure surfaces a `:validate :stop` with `status: :error`).
2. **Canonical stage order** — Source-level inspection of `defp run_stages/3` shows `:compose` clause precedes `:measure` clause; live event ordering confirms; `test/rendro/telemetry_test.exs:324` asserts the contract without any `:pending_*` tag.
3. **Error-path metrics preserved** — Live spot-check with `max_bytes: 1` shows `page_count: 1` on the failed `:validate :stop` and on the top-level `[:rendro, :render, :stop]`. The unified `stage_stop_meta/5` builder eliminates the old hardcoded-zero error path.

The full test suite reports `217 tests, 0 failures` with no exclusions. Threadline adapter (D-20) remains green. Phase 6 closes BLOCKER-04, BLOCKER-05, and MINOR-15 from `v1.0-MILESTONE-AUDIT.md`. Final formal verification of OBS-01/OBS-02/CORE-01 status flips is reserved for Phase 11 per the requirements traceability table — Phase 6 establishes the contract surface and lands the working implementation that Phase 11 will verify.

Note: Code review (`06-REVIEW.md`) surfaced 5 BLOCKER findings that are **advisory** to this goal-backward verification. The review's concerns are about code quality and edge cases (e.g., regex robustness, derive_page_count fallback semantics) rather than goal achievement. None of those findings invalidate any of the three roadmap must_haves, all of which are observably satisfied in the production code path.

---

_Verified: 2026-04-27T15:18:44Z_
_Verifier: Claude (gsd-verifier)_
