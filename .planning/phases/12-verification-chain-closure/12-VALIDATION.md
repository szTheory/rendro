---
phase: 12
slug: verification-chain-closure
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-28
---

# Phase 12 — Validation Strategy

> Per-phase validation contract for verification-chain closure work.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + Mix task integration commands |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test` |
| **Full suite command** | `mix verify` |
| **Estimated runtime** | ~60-180 seconds depending on deps/example compile |

---

## Sampling Rate

- **After every task commit:** Run the narrowest relevant command (`mix verify`, example compile, or workflow readback).
- **After every plan wave:** Run `mix verify`.
- **Before `$gsd-verify-work`:** Run `mix verify` from a clean worktree or equivalent clean proof surface.
- **Max feedback latency:** 180 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 12-01-01 | 01 | 1 | QUAL-01, QUAL-03 | T-12-01 | committed workflow reflects actual hosted verification steps and does not over-claim proof | workflow/integration | `rg -n "mix ci|examples/phoenix_example|mix compile" .github/workflows/ci.yml` | ✅ | ⬜ pending |
| 12-01-02 | 01 | 1 | QUAL-03 | T-12-01 | CI example step fetches deps and exercises the example path explicitly | integration | `cd examples/phoenix_example && mix deps.get && mix compile` | ✅ | ⬜ pending |
| 12-02-01 | 02 | 2 | QUAL-05 | T-12-02 | `mix verify` runs deterministic and advisory lanes to completion before exiting non-zero | integration | `mix verify` | ✅ | ⬜ pending |
| 12-02-02 | 02 | 2 | QUAL-01, QUAL-05 | T-12-02 | deterministic lane failures are reported without suppressing advisory-lane output | integration | `mix verify` plus output inspection | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] No new test framework work expected; existing Mix/ExUnit surfaces are sufficient.
- [ ] Verification should use a clean committed proof surface to avoid dirty-worktree false negatives.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Hosted CI run proves committed workflow behavior | QUAL-01, QUAL-03 | GitHub Actions execution is external to local shell | Review the committed `.github/workflows/ci.yml`, then confirm the hosted run executes `mix ci` and the Phoenix example step on PR/push once the phase is implemented |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or explicit command/readback proof
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all missing hosted-proof references
- [ ] No watch-mode flags
- [ ] Feedback latency < 180s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
