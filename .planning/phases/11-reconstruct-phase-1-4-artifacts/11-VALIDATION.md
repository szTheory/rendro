---
phase: 11
slug: reconstruct-phase-1-4-artifacts
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-28T09:31:55Z
---

# Phase 11 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + StreamData |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test` |
| **Full suite command** | `mix test` plus `mix compile --no-optional-deps --warnings-as-errors`, `mix run scripts/verify_docs.exs`, `mix verify`, `mix release.preflight` |
| **Estimated runtime** | ~90 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test` plus the smallest requirement-specific command set for the slice under reconstruction.
- **After every plan wave:** Run the affected proof commands and the relevant reconstructed verification artifact checks.
- **Before `$gsd-verify-work`:** Full phase proof set must be complete.
- **Max feedback latency:** 90 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 11-01-01 | 01 | 1 | CORE-01, CORE-02, CORE-05, OBS-01, OBS-03 | T-11-01 / T-11-02 | Phase 1 verdicts cite executable proof only and immediately sync owned traceability rows | integration + unit + docs parity | `mix test test/rendro_test.exs test/rendro/deterministic_test.exs test/rendro/telemetry_test.exs test/rendro/error_test.exs` | ✅ | ✅ green |
| 11-01-02 | 01 | 1 | CORE-03, CORE-04, LAY-01, LAY-02, LAY-03, LAY-04, LAY-05 | T-11-01 / T-11-02 | Phase 2 verdicts cite fixed/flow/layout proof only and immediately sync owned traceability rows | integration + docs parity | `mix test test/rendro/flow_test.exs test/rendro/integration_test.exs test/rendro/metadata_test.exs test/rendro/error_test.exs test/rendro/pipeline/paginate_test.exs` | ✅ | ✅ green |
| 11-01-03 | 01 | 1 | ADPT-01, ADPT-02, ADPT-03, ADPT-04, OBS-02, OBS-04 | T-11-03 / T-11-05 / T-11-02 | Optional-adapter and Phoenix boundary claims stay truthful, Task 3 creates `test/rendro/adapters/phoenix_test.exs`, and owned traceability rows sync immediately | compile + unit + endpoint/conn + docs parity | `mix compile --no-optional-deps --warnings-as-errors && mix test test/rendro/adapters/phoenix_test.exs test/rendro/adapters/oban/render_worker_test.exs test/rendro/adapters/threadline_test.exs test/rendro/pipeline_test.exs test/rendro/policy_test.exs test/rendro/telemetry_test.exs` | ✅ | ✅ green |
| 11-01-04 | 01 | 1 | QUAL-01, QUAL-02, QUAL-03, QUAL-04, QUAL-05 | T-11-04 / T-11-02 | CI/release claims come from runnable command/workflow proof; Task 4 must create a temporary clean checkout/worktree at current `HEAD`, run quality commands there, and only accept mixed outcomes when `04-VERIFICATION.md` records matching Partial/Blocked statuses before row sync | mix tasks + docs parity | `git worktree add --detach <tmp> HEAD && (cd <tmp> && mix ci && mix run scripts/verify_docs.exs && mix verify && mix release.preflight) with non-zero exits mapped truthfully in 04-VERIFICATION.md; example app compile also runs from <tmp>/examples/phoenix_example` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Task 3 created `test/rendro/adapters/phoenix_test.exs` before its verification command ran.
- [x] Task 4 established a temporary clean checkout/worktree at current `HEAD` before deriving `QUAL-01` and `QUAL-05` verdicts.
- [x] The phase finished with an explicit mixed quality verdict; later exact-tag proof moved to Phase 13 and no longer leaves Phase 11 validation internally inconsistent.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Tagged release happy path | QUAL-04 | Exact git tag and publish dry-run conditions may not exist in a planning workspace | Run `mix release.preflight` from a correctly tagged clean checkout and record the result in `04-VERIFICATION.md`. |
| CI-backed example app proof if workflow evidence remains unclear | QUAL-03 | Local compile may exist without equivalent workflow execution evidence | Inspect the CI workflow/job evidence and record `Done`, `Partial`, or `Blocked` truthfully in `04-VERIFICATION.md`. |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or explicit Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 90s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-04-28 after post-execution reconciliation
