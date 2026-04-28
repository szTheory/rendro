---
phase: 15
slug: async-policy-injection-timeout-audit-closure
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-28
---

# Phase 15 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit on Elixir 1.19.5 |
| **Config file** | none — default Mix/ExUnit setup |
| **Quick run command** | `mix test test/rendro/adapters/oban/render_worker_test.exs test/rendro/adapters/threadline_test.exs test/rendro/telemetry_test.exs test/docs_contract/integrations_claims_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~5 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/rendro/adapters/oban/render_worker_test.exs test/rendro/adapters/threadline_test.exs test/rendro/telemetry_test.exs test/docs_contract/integrations_claims_test.exs`
- **After every plan wave:** Run `mix test`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 15-01-01 | 01 | 0 | ADPT-04 | T-15-01 | Worker validates required Oban fields and rejects invalid or unknown policy input with typed failures. | unit | `mix test test/rendro/adapters/oban/render_worker_test.exs` | ✅ | ✅ green |
| 15-01-02 | 01 | 1 | ADPT-04, OBS-04 | T-15-01 / T-15-03 | Worker injects only missing `max_pages`, `max_bytes`, and `timeout` into document policies before render. | unit/integration | `mix test test/rendro/adapters/oban/render_worker_test.exs test/rendro/policy_test.exs` | ✅ / ✅ | ✅ green |
| 15-02-01 | 02 | 1 | OBS-04 | T-15-02 | Timeout emits a terminal top-level `[:rendro, :render, :stop]` with stable error metadata and no dangling render span. | telemetry | `mix test test/rendro/telemetry_test.exs` | ✅ | ✅ green |
| 15-02-02 | 02 | 1 | ADPT-05, OBS-04 | T-15-02 | Threadline forwards timeout failures under `:render_failed` with timeout subtype metadata preserved. | integration | `mix test test/rendro/adapters/threadline_test.exs test/docs_contract/integrations_claims_test.exs` | ✅ | ✅ green |
| 15-03-01 | 03 | 2 | ADPT-04, ADPT-05, OBS-04 | T-15-01 / T-15-02 / T-15-03 | Guides and contract tests match the final bounded-async and timeout-audit behavior truthfully. | docs contract | `mix test test/docs_contract/integrations_claims_test.exs` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/rendro/adapters/oban/render_worker_test.exs` — worker-path proof for policy injection, unknown-key rejection, and typed invalid-input failures
- [x] `test/rendro/telemetry_test.exs` — timeout-specific top-level lifecycle proof asserting start + synthetic stop
- [x] `test/rendro/adapters/threadline_test.exs` — timeout audit assertions for `:render_failed` and subtype metadata
- [x] `test/docs_contract/integrations_claims_test.exs` — flip the timeout limitation proof into timeout closure proof

---

## Manual-Only Verifications

All phase behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 10s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** passed
