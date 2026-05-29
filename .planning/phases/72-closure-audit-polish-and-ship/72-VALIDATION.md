---
phase: 72
slug: closure-audit-polish-and-ship
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-05-29
---

# Phase 72 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19.5) |
| **Config file** | `mix.exs` test alias + `mix.exs` `:ci` alias |
| **Quick run command** | `mix test test/guardrails/ test/docs_contract/viewer_evidence_claims_test.exs` |
| **Full suite command** | `mix ci` |
| **Estimated runtime** | ~120 seconds (full CI parity) |

---

## Sampling Rate

- **After every task commit:** Run targeted test file(s) listed in task verify map
- **After every plan wave:** Run `mix test test/guardrails/` + `mix rendro.viewer_evidence validate` + `mix rendro.viewer_evidence validate --strict`
- **Before `/gsd-verify-work`:** Full `mix ci` must be green; live branch audit run once at close
- **Max feedback latency:** 180 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 72-01-01 | 01 | 1 | GUARDRAIL-02 | T-72-01 / — | Baseline JSON lists four required contexts | unit | `mix test test/guardrails/required_checks_contract_test.exs` | ❌ W1 | ⬜ pending |
| 72-01-02 | 01 | 1 | GUARDRAIL-02 | T-72-02 / — | ci.yml job names match baseline | unit | `mix test test/guardrails/required_checks_contract_test.exs` | ❌ W1 | ⬜ pending |
| 72-01-03 | 01 | 1 | GUARDRAIL-02 | T-72-03 / — | Live audit script exits 0 with token | integration | `GITHUB_TOKEN=... mix run scripts/audit_branch_protection.exs` | ❌ W1 | ⬜ pending |
| 72-02-01 | 02 | 2 | GUARDRAIL-02 | — | `--strict` fatal on stale `recorded_at` | unit | `mix test test/rendro/viewer_evidence/` | ❌ W2 | ⬜ pending |
| 72-02-02 | 02 | 2 | GUARDRAIL-02 | — | Default validate advisory for staleness | unit | `mix rendro.viewer_evidence validate` exits 0 | ✅ | ⬜ pending |
| 72-02-03 | 02 | 2 | GUARDRAIL-02 | — | VERIFICATION captures CLI + audit outputs | manual | Review `72-VERIFICATION.md` | ❌ W2 | ⬜ pending |
| 72-03-01 | 03 | 3 | GUARDRAIL-02 | — | Docs-contract lane 8 green | unit | `mix test test/docs_contract/viewer_evidence_claims_test.exs` | ✅ | ⬜ pending |
| 72-03-02 | 03 | 3 | GUARDRAIL-02 | — | CHANGELOG/mix.exs at 0.3.1 | unit | `mix test test/docs_contract/` | ✅ | ⬜ pending |
| 72-03-03 | 03 | 3 | GUARDRAIL-02 | — | Release preflight green | integration | `mix run scripts/release_preflight_proof.exs --current-version-tag` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. New test directories created in Wave 1:

- [ ] `test/guardrails/required_checks_contract_test.exs` — GUARDRAIL-02 offline contract
- [ ] `priv/guardrails/required_status_checks.json` — committed baseline

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Live GitHub branch protection audit | GUARDRAIL-02 | Requires `GITHUB_TOKEN` with admin read; not in default `mix ci` | Run `scripts/audit_branch_protection.exs` at close; paste normalized JSON in `72-VERIFICATION.md` |
| Trust-sensitive spot-check rows | GUARDRAIL-02 | Human audit packet, not duplicated matrix | Verify ~8–12 named cells in VERIFICATION against evidence files |
| Hex publish `v0.3.1` | Ship closure | Tag-triggered workflow | Tag after preflight; confirm hex.pm version |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 180s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
