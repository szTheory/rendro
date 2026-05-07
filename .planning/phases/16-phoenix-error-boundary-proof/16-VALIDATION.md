---
phase: 16
slug: phoenix-error-boundary-proof
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-28
updated: 2026-04-28
---

# Phase 16 — Validation Strategy

> Per-phase validation contract for the Phoenix Error Boundary Proof.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/rendro/adapters/phoenix_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~5-10 seconds |

---

## Sampling Rate

- After every task commit: run the Phoenix boundary suite `mix test test/rendro/adapters/phoenix_test.exs`.
- Before `$gsd-verify-work`: run the full test suite `mix test`.
- Max feedback latency: 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 16-01-01 | 01 | 1 | OBS-03 | T-16-01 | Phoenix adapter returns structured JSON 500 when format is json, and text 500 when format is not json, without exposing internal reason terms. | unit | `mix test test/rendro/adapters/phoenix_test.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ mixed*

---

## Wave 0 Requirements

- [x] `test/rendro/adapters/phoenix_test.exs` exists and is ready to host the new conn-boundary proof for error paths.
- [x] Deterministic `:content_overflow` failure path is available for testing without timeouts.

---

## Manual-Only Verifications

None. The proof relies entirely on the committed ExUnit test suite.

---

## Validation Sign-Off

- [x] All tasks have automated verification coverage
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all proof surfaces referenced in `16-VERIFICATION.md`
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** automated coverage complete; ready for implementation.
