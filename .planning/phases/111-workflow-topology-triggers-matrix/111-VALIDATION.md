---
phase: 111
slug: workflow-topology-triggers-matrix
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-16
updated: 2026-07-10
---

# Phase 111 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `111-RESEARCH.md` → Validation Architecture. The validation
> surface is the modified `.github/workflows/ci.yml` file and the passing
> guardrail test.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19.5 / OTP 28 built-in) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `grep -nE "<assertion>" .github/workflows/ci.yml` (YAML smoke) |
| **Full suite command** | `mix test test/guardrails/required_checks_contract_test.exs` |
| **Estimated runtime** | grep smokes ~instant; ExUnit guardrail ~5s |

---

## Sampling Rate

- **After every task commit:** Run the task's `grep` assertion (YAML lines) or the guardrail test.
- **After every plan wave:** Spot-check modified `ci.yml` structure.
- **Before `/gsd:verify-work`:** The guardrail test must pass, all grep assertions must pass, and manual inspection confirms matrix policies.
- **Max feedback latency:** < 5 seconds.

---

## Per-Task Verification Map

| Req ID | Behavior | Test Type | Automated Command | File Exists |
|--------|----------|-----------|-------------------|-------------|
| FLOW-01 | Merge live-proof jobs | smoke | `grep -nE "integration-proofs:\|needs: test" .github/workflows/ci.yml` | ✅ W1 |
| FLOW-01 | Merge advisory jobs | smoke | `grep -nE "advisory-checks:\|continue-on-error: true" .github/workflows/ci.yml` | ✅ W1 |
| FLOW-02 | Concurrency cancellation | smoke | `grep -nE "concurrency:\|cancel-in-progress:" .github/workflows/ci.yml` | ✅ W1 |
| FLOW-03/04 | Matrix and triggers | manual | inspect `.github/workflows/ci.yml` for pull_request vs schedule triggers | ✅ W2 |
| FLOW-05 | Summary gate job exists | smoke | `grep -nE "ci-success:\|if: always\(\)" .github/workflows/ci.yml` | ✅ W1 |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Inspect `test/guardrails/required_checks_contract_test.exs` and ensure it is updated to reflect the new `ci-success` job or merged steps correctly without breaking.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Matrix evaluation logic | FLOW-04 | Logic for running lint once vs matrix is complex to grep | Confirm `ci.yml` correctly runs lint only on primary matrix version. |
| Workflow triggers logic | FLOW-03 | Hard to parse full YAML tree via grep | Confirm PR gate vs push-to-main vs nightly schedule are correctly defined. |

---

## Validation Sign-Off

- [x] All tasks have a `grep`/inspection verify or a Wave 0 dependency
- [x] Sampling continuity: no 3 consecutive tasks without an automated verify
- [x] Wave 0 covers guardrail test inspection
- [x] No watch-mode flags
- [x] Feedback latency < 5s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-07-10 from `111-VERIFICATION.md`.

## Validation Audit 2026-07-10

| Metric | Count |
|--------|-------|
| Gaps found | 1 |
| Resolved | 1 |
| Escalated/manual-only | 0 |

The validation file was still marked draft even though `111-VERIFICATION.md` passed. This audit reconciles the frontmatter and sign-off with the existing verification evidence.
