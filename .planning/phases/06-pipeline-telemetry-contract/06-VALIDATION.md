---
phase: 6
slug: pipeline-telemetry-contract
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-26
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
| **Estimated runtime** | ~10–20 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick command (telemetry + pipeline tests)
- **After every plan wave:** Run full suite (`mix test`)
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 20 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD     | TBD  | TBD  | TBD         | —          | TBD             | TBD       | TBD               | TBD         | ⬜ pending |

> Populated by gsd-planner during plan generation; this row is a stub for the planner to expand against the per-plan task tables. The planner MUST add one row per task pulling from the requirements/automated commands declared in each plan.

---

## Wave 0 Requirements

- [ ] `test/rendro/pipeline/validate_test.exs` — new file for `:validate` stage unit tests (D-06, D-07, D-09)
- [ ] No new framework install required — ExUnit is the standard project test runner

*All other test infrastructure already exists (`test/rendro/telemetry_test.exs`, `test/rendro/pipeline/{compose,measure,paginate}_test.exs`, `test/rendro/adapters/threadline_test.exs`).*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| — | — | — | — |

*All phase behaviors have automated verification — telemetry events, stop_meta schema, stage order, error-path metrics, and `:validate` PDF structural checks are all observable via ExUnit + `:telemetry_test_handler`.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 20s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
