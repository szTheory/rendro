---
phase: 68
slug: viewer-evidence-schema-mix-task-and-docs-contract-lane
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-28
validated: 2026-05-28
---

# Phase 68 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19.5) |
| **Config file** | `mix.exs` test alias |
| **Quick run command** | `mix test test/rendro/viewer_evidence/ test/mix/tasks/viewer_evidence_task_test.exs` |
| **Full suite command** | `mix docs.contract` |
| **Estimated runtime** | ~5 seconds (phase tests); ~5 seconds (full docs.contract) |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/rendro/viewer_evidence/ test/mix/tasks/viewer_evidence_task_test.exs`
- **After every plan wave:** Run `mix test test/docs_contract/viewer_evidence_claims_test.exs`
- **Before `/gsd-verify-work`:** `mix docs.contract` must be green (8/8 lanes)
- **Max feedback latency:** 5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 68-01-01 | 01 | 1 | MATRIX-01, MATRIX-03 | T-68-01-01 | JSV validates production matrix; walker enumerates 26 cells | unit | `mix test test/rendro/viewer_evidence/` | ✅ | ✅ green |
| 68-01-02 | 01 | 1 | MATRIX-02, GUARDRAIL-03 | T-68-01-01 | Frontmatter schema validates template; forbidden keys rejected | unit | `mix test test/rendro/viewer_evidence/` | ✅ | ✅ green |
| 68-02-01 | 02 | 2 | RECIPE-02 | T-68-02-02 | Mix task list/validate/missing exit codes and --json | integration | `mix test test/mix/tasks/viewer_evidence_task_test.exs` | ✅ | ✅ green |
| 68-03-01 | 03 | 3 | RECIPE-04, GUARDRAIL-01, GUARDRAIL-03, GUARDRAIL-04 | T-68-03-01–03 | Docs-contract lane catches tier-B violations | integration | `mix test test/docs_contract/viewer_evidence_claims_test.exs` | ✅ | ✅ green |
| 68-03-02 | 03 | 3 | GUARDRAIL-03 | — | Eighth lane registered in verify_docs.exs | unit | `mix run scripts/verify_docs.exs` (via `mix docs.contract`) | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

### Requirement Coverage

| Requirement | Test file(s) | Status |
|-------------|--------------|--------|
| MATRIX-01 | `validator_test.exs` (explicit_deferral schema), `viewer_evidence_claims_test.exs` | COVERED |
| MATRIX-02 | `validator_test.exs` (frontmatter schema, template) | COVERED |
| MATRIX-03 | `validator_test.exs` (Tier-A JSV, production matrix), docs-contract tier-A | COVERED |
| RECIPE-02 | `viewer_evidence_task_test.exs` (7 tests) | COVERED |
| RECIPE-04 | `viewer_evidence_claims_test.exs` (promotion/orphan/deferral) | COVERED |
| GUARDRAIL-01 | `validator_test.exs` (lint), `viewer_evidence_claims_test.exs` | COVERED |
| GUARDRAIL-03 | `validator_test.exs`, `viewer_evidence_claims_test.exs`, lane registration | COVERED |
| GUARDRAIL-04 | `validator_test.exs` (lint), `viewer_evidence_claims_test.exs` | COVERED |

---

## Wave 0 Requirements

- [x] `test/rendro/viewer_evidence/validator_test.exs` — MATRIX-01/02/03, GUARDRAIL-01/03/04 (28 tests)
- [x] `test/mix/tasks/viewer_evidence_task_test.exs` — RECIPE-02 (7 tests)
- [x] `test/docs_contract/viewer_evidence_claims_test.exs` — RECIPE-04, GUARDRAIL-01/03/04 (14 tests)
- [x] `test/support/viewer_evidence/fixtures/` — violation snippets for tier-B tests
- [x] `mix deps.get` — jsv + yaml_elixir dev/test deps installed

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Operator smoke on unchanged matrix | RECIPE-02 | Human-readable table formatting (not asserted in ExUnit) | Run `mix rendro.viewer_evidence list`; confirm 26 rows (5 supported, 21 unverified, 0 deferral) |
| Matrix unchanged at phase end | ROADMAP SC5 | Git diff check outside test suite | `git diff priv/support_matrix.json` must be empty |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-05-28

---

## Validation Audit 2026-05-28

| Metric | Count |
|--------|-------|
| Gaps found | 0 (planning artifact drift only) |
| Resolved | 0 |
| Escalated | 0 |

**Evidence:** `mix test` on phase paths — 49 tests, 0 failures; `mix docs.contract` — 8/8 lanes PASS.
