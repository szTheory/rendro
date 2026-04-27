---
phase: 6
slug: pipeline-telemetry-contract
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-26
last_updated: 2026-04-27
---

# Phase 6 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir) |
| **Config file** | `mix.exs`, `test/test_helper.exs` |
| **Quick run command** | `mix test test/rendro/telemetry_test.exs test/rendro/pipeline/` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~3.4 seconds (measured at phase close) |

---

## Sampling Rate

- **After every task commit:** Run quick command (telemetry + pipeline tests)
- **After every plan wave:** Run full suite (`mix test`)
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 20 seconds (actual: ~3.4 s)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 06-01-T1 | 01 | 1 | OBS-01 | T-06-01 | telemetry stage_names contract pinned with `:validate` | unit (telemetry) | `mix test test/rendro/telemetry_test.exs --exclude pending_full_pipeline --exclude pending_unified_schema` | exists | green |
| 06-01-T2 | 01 | 1 | OBS-02 | T-06-01,T-06-02 | unified D-11 stop_meta + page_count preserved on error path (MINOR-15) | unit (telemetry) | `mix test test/rendro/telemetry_test.exs --exclude pending_full_pipeline` | exists | green |
| 06-01-T3 | 01 | 1 | OBS-01 | T-06-03 | `Rendro.Error.from_stage(:validate, ...)` clauses for 3 reasons | unit (error) | `mix test test/rendro/error_test.exs` | exists | green |
| 06-02-T1 | 02 | 2 | OBS-01,CORE-01 | T-06-05 | `Validate.run/2` happy + 3 error reasons + parser-DoS regression | unit (stage) | `mix test test/rendro/pipeline/validate_test.exs` | created Plan 02 | green |
| 06-02-T2 | 02 | 2 | OBS-01,CORE-01 | T-06-05 | `:validate` span wired into `run_stages/3`; deterministic-mode regex fix | integration | `mix test test/rendro/telemetry_test.exs --exclude pending_full_pipeline` | exists | green |
| 06-02-T3 | 02 | 2 | (docs) | — | `CHANGELOG.md` exists per Keep-a-Changelog v1.1.0 | docs | `grep -F '## [0.1.0] - Unreleased' CHANGELOG.md` | created Plan 02 | green |
| 06-03-T1 | 03 | 3 | OBS-01,CORE-01 | T-06-12 | canonical stage order in code (`:build → :compose → :measure → :paginate → :render → :validate`) | unit (telemetry) | `mix test test/rendro/telemetry_test.exs` | exists | green |
| 06-03-T2 | 03 | 3 | CORE-01 | T-06-09,T-06-10,T-06-11 | responsibility shuffle + page-2 D-04 regression | unit (stage) | `mix test test/rendro/pipeline/` | exists | green |
| 06-03-T3 | 03 | 3 | (gate) | T-06-09 | Threadline adapter unaffected (D-20) | integration | `mix test test/rendro/adapters/threadline_test.exs` | exists | green |
| 06-phase | — | — | (gate) | — | Full Rendro suite green from clean compile, no `--exclude` | full | `mix clean && mix compile --warnings-as-errors && mix test` | exists | green |

---

## Wave 0 Requirements

- [x] `test/rendro/pipeline/validate_test.exs` — new file for `:validate` stage unit tests (D-06, D-07, D-09) — created in Plan 02 Task 1
- [x] No new framework install required — ExUnit is the standard project test runner

*All other test infrastructure already exists (`test/rendro/telemetry_test.exs`, `test/rendro/pipeline/{compose,measure,paginate}_test.exs`, `test/rendro/adapters/threadline_test.exs`).*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| — | — | — | — |

*All phase behaviors have automated verification — telemetry events, stop_meta schema, stage order, error-path metrics, and `:validate` PDF structural checks are all observable via ExUnit + `:telemetry_test_handler`.*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 20s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved
