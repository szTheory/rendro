---
phase: 94
slug: docs-warning-hygiene
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-13
---

# Phase 94 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built-in Elixir) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/docs_contract/public_api_contract_test.exs` |
| **Full suite command** | `mix test` |
| **Docs build command** | `mix docs` |
| **Docs enforcement command** | `mix docs --warnings-as-errors` |
| **Estimated runtime** | ~5 seconds (contract test); ~10s (`mix docs`) |

---

## Sampling Rate

- **After every task commit:** `mix docs 2>&1 | grep -c "^    warning:"` → should output `0`; `mix test test/docs_contract/public_api_contract_test.exs`
- **After every plan wave:** Same plus `mix docs --warnings-as-errors` (exit 0)
- **Before `/gsd:verify-work`:** `mix docs --warnings-as-errors` green; full `mix test` green
- **Max feedback latency:** ~15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 94-01-* | 01 | 1 | HYG-01 | — | N/A | smoke | `mix docs 2>&1 \| grep -c "^    warning:"` → `0` | ✅ | ⬜ pending |
| 94-01-* | 01 | 1 | HYG-01 | — | N/A | smoke | `mix docs --warnings-as-errors` exit 0 | ✅ | ⬜ pending |
| 94-01-* | 01 | 1 | HYG-01 | — | N/A | unit | `mix test test/docs_contract/public_api_contract_test.exs` | ✅ | ⬜ pending |
| 94-02-* | 02 | 2 | HYG-02 | — | N/A | unit | `grep "@staleness_days 180" lib/rendro/viewer_evidence/validator.ex` | ✅ | ⬜ pending |
| 94-02-* | 02 | 2 | HYG-02 | — | N/A | inspection | staleness message contains remediation cmd + advisory note + guide pointer | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements.* `test/docs_contract/public_api_contract_test.exs` covers the HYG-01 contract side; the `mix docs` zero-warning check is a smoke command. HYG-02 validations are string/content inspections. No new test files needed.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Staleness message wording (remediation cmd, advisory-outside-`--strict` note, guide pointer) | HYG-02 | String content, not runtime behavior | Read `staleness_warnings/1` message in `lib/rendro/viewer_evidence/validator.ex` |
| Guide lifecycle section present and legible | HYG-02 | Prose content verification | Read `guides/viewer_evidence.md` for the staleness-lifecycle section |

*Threshold preservation (`@staleness_days 180`) is grep-verifiable and therefore automated above.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
