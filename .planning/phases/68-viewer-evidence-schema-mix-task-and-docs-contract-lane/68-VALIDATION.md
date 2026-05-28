---
phase: 68
slug: viewer-evidence-schema-mix-task-and-docs-contract-lane
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-28
---

# Phase 68 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19.5) |
| **Config file** | `mix.exs` test alias |
| **Quick run command** | `mix test test/rendro/viewer_evidence/` |
| **Full suite command** | `mix docs.contract` |
| **Estimated runtime** | ~120 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/rendro/viewer_evidence/ test/mix/tasks/viewer_evidence_task_test.exs`
- **After every plan wave:** Run `mix test test/docs_contract/viewer_evidence_claims_test.exs`
- **Before `/gsd-verify-work`:** `mix docs.contract` must be green (8/8 lanes)
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 68-01-01 | 01 | 1 | MATRIX-01, MATRIX-03 | — | JSV validates production matrix | unit | `mix test test/rendro/viewer_evidence/` | ❌ W0 | ⬜ pending |
| 68-01-02 | 01 | 1 | MATRIX-02 | — | Frontmatter schema validates template | unit | `mix test test/rendro/viewer_evidence/` | ❌ W0 | ⬜ pending |
| 68-02-01 | 02 | 2 | RECIPE-02 | — | Mix task list/validate/missing exit codes | integration | `mix test test/mix/tasks/viewer_evidence_task_test.exs` | ❌ W0 | ⬜ pending |
| 68-03-01 | 03 | 3 | RECIPE-04, GUARDRAIL-01, GUARDRAIL-03, GUARDRAIL-04 | — | Docs-contract lane catches violations | integration | `mix test test/docs_contract/viewer_evidence_claims_test.exs` | ❌ W0 | ⬜ pending |
| 68-03-02 | 03 | 3 | GUARDRAIL-03 | — | Eighth lane registered in verify_docs.exs | unit | `mix run scripts/verify_docs.exs` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/rendro/viewer_evidence/validator_test.exs` — stubs for MATRIX-01/02/03
- [ ] `test/mix/tasks/viewer_evidence_task_test.exs` — stubs for RECIPE-02
- [ ] `test/docs_contract/viewer_evidence_claims_test.exs` — stubs for RECIPE-04, GUARDRAIL-01/03/04
- [ ] `test/support/viewer_evidence/fixtures/` — violation snippets for tier-B tests
- [ ] `mix deps.get` — install jsv + yaml_elixir dev/test deps

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Operator smoke on unchanged matrix | RECIPE-02 | Human-readable table formatting | Run `mix rendro.viewer_evidence list`; confirm 26 rows (5 supported, 21 unverified, 0 deferral) |
| Matrix unchanged at phase end | ROADMAP SC5 | Git diff check | `git diff priv/support_matrix.json` must be empty |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
