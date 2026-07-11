---
phase: 113
slug: dx-local-reproducibility-validation
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-16
updated: 2026-07-10
---

# Phase 113 — Validation Strategy

> Retroactive Nyquist validation for DX, local reproducibility, and C1 validation reporting.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit + docs-contract guardrails |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/docs_contract/dx_local_reproducibility_claims_test.exs test/mix/tasks/ci_alias_contract_test.exs` |
| **Full suite command** | `mix ci.fast` |
| **Estimated runtime** | focused tests ~5s; `mix ci.fast` ~12s warm from Phase 113 evidence |

---

## Sampling Rate

- **After alias or workflow edits:** Run `mix test test/mix/tasks/ci_alias_contract_test.exs test/guardrails/required_checks_contract_test.exs`.
- **After README or CONTRIBUTING edits:** Run `mix test test/docs_contract/dx_local_reproducibility_claims_test.exs`.
- **After validation metric edits:** Run the docs-contract lane and inspect `113-METRICS.md` for local/remote evidence boundaries.
- **Before milestone close:** Run `mix ci.fast` and collect remote GitHub Actions metrics after the C1 commits are pushed.
- **Max feedback latency:** focused checks < 10s; full local fast gate < 60s on warm PLTs.

---

## Requirement Verification Map

| Requirement | Behavior | Test Type | Automated Command | Evidence File | Status |
|-------------|----------|-----------|-------------------|---------------|--------|
| DX-01 | Local deterministic gate is represented by `mix ci.fast`; full proof parity divergence is documented. | docs + alias contract | `mix test test/docs_contract/dx_local_reproducibility_claims_test.exs test/mix/tasks/ci_alias_contract_test.exs` | `CONTRIBUTING.md`, `mix.exs` | green 2026-07-10 |
| DX-02 | Contributor docs map required checks and seeded ExUnit reproduction to scoped local commands. | docs contract | `mix test test/docs_contract/dx_local_reproducibility_claims_test.exs` | `CONTRIBUTING.md` | green 2026-07-10 |
| DX-03 | CI failure logs are split into actionable step names and slowest-test summaries. | guardrail + docs contract | `mix test test/guardrails/required_checks_contract_test.exs test/docs_contract/dx_local_reproducibility_claims_test.exs` | `.github/workflows/ci.yml` | green 2026-07-10 |
| DX-04 | README badge targets `ci-success`. | docs contract | `mix test test/docs_contract/dx_local_reproducibility_claims_test.exs` | `README.md` | green 2026-07-10 |
| VAL-01 | Local before/after evidence is recorded and remote metrics are not claimed before post-push CI data exists. | docs contract + manual remote evidence | `mix test test/docs_contract/dx_local_reproducibility_claims_test.exs`; `gh run list --workflow=ci.yml` after push | `113-METRICS.md` | local green; remote pending |
| VAL-02 | Steady-state target pipeline is documented as PR/main/nightly/release/docs lanes. | docs contract | `mix test test/docs_contract/dx_local_reproducibility_claims_test.exs` | `113-METRICS.md` | green 2026-07-10 |

---

## Wave 0 Requirements

Existing infrastructure covers the phase:

- [x] `test/docs_contract/dx_local_reproducibility_claims_test.exs` validates DX docs, metric truthfulness, README badge, and UAT completion.
- [x] `test/mix/tasks/ci_alias_contract_test.exs` validates scoped Mix alias structure and preferred test environments.
- [x] `test/guardrails/required_checks_contract_test.exs` validates CI workflow topology and required check names.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Post-push GitHub Actions p50/p95 and cache hit rates | VAL-01 | GitHub cache/timing behavior only exists after these local commits run remotely. | Push the C1 commits to a CI-triggering branch or main, collect at least three green `ci.yml` runs with `gh run view`, then update `113-METRICS.md` and the milestone audit. |

---

## Validation Sign-Off

- [x] All tasks have automated verification or an explicit manual-only external evidence requirement.
- [x] Sampling continuity: every Phase 113 plan has a focused verification command.
- [x] Wave 0 covers all local validation references.
- [x] No watch-mode flags.
- [x] Feedback latency < 60s for focused checks and local fast gate.
- [x] `nyquist_compliant: true` set in frontmatter for local/structural validation coverage.

**Approval:** approved 2026-07-10 for local validation; remote `VAL-01` evidence remains a milestone gate.

---

## Validation Audit 2026-07-10

| Metric | Count |
|--------|-------|
| Gaps found | 2 |
| Resolved | 1 |
| Escalated/manual-only | 1 |

Resolved: the placeholder validation template was replaced with a concrete requirement-to-command map. Escalated/manual-only: remote GitHub Actions metrics for `VAL-01`, which cannot be generated from local state.
