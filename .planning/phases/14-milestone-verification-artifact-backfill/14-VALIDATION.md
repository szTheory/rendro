---
phase: 14
slug: milestone-verification-artifact-backfill
status: ready
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-28
---

# Phase 14 — Validation Strategy

> Per-phase validation contract for artifact-only milestone verification backfill.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Existing Mix/ExUnit proof commands plus shell consistency checks over planning artifacts |
| **Config file** | `mix.exs`, `.planning/REQUIREMENTS.md`, existing `07`-`13` phase artifacts |
| **Quick run command** | `mix test` against the smallest current proof surface referenced by the task, plus `rg`/`python3` consistency checks |
| **Full suite command** | Task-specific Mix proofs for Phases 07-11 plus final `REQUIREMENTS.md` consistency comparison against the new verification artifacts and the Phase 13 `QUAL-04` override |
| **Estimated runtime** | ~60-180 seconds depending on the targeted proof surface |

---

## Sampling Rate

- **After every task commit:** Run the narrowest current proof command cited by that task, plus an artifact integrity check over the files just changed.
- **After every plan wave:** Run the verification commands for every plan in that wave and confirm the new/updated artifact files exist.
- **Before `$gsd-verify-work`:** Run the final `REQUIREMENTS.md` consistency comparison against `07-VERIFICATION.md` through `11-VERIFICATION.md`, plus `13-VERIFICATION.md` for `QUAL-04`.
- **Max feedback latency:** 180 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 14-01-01 | 01 | 1 | ADPT-01, ADPT-02, ADPT-03, OBS-03, QUAL-03 | T-14-01 / T-14-03 | Phase 07 verification cites live Phoenix proof and later hosted-CI evidence truthfully, and summary metadata is extraction-safe. | unit + artifact | `mix test test/rendro/adapters/phoenix_test.exs` plus `rg` on `07-VERIFICATION.md`, `07-VALIDATION.md`, `07-01-SUMMARY.md` | ✅ | ⬜ pending |
| 14-01-02 | 01 | 1 | ADPT-04, ADPT-05, OBS-02, OBS-04 | T-14-02 / T-14-03 | Phase 08 verification cites current bounded-async, metrics-correlation, and timeout-policy proof without reopening runtime scope, and summary metadata is extraction-safe. | unit + artifact | `mix test test/rendro/pipeline_test.exs test/rendro/adapters/threadline_test.exs test/rendro/adapters/oban/render_worker_test.exs` plus `rg` on `08-VERIFICATION.md`, `08-VALIDATION.md`, `08-01-SUMMARY.md` for `## Requirement: ADPT-04`, `ADPT-05`, `OBS-02`, and `OBS-04` | ✅ | ⬜ pending |
| 14-02-01 | 02 | 1 | QUAL-01, QUAL-02, QUAL-03, QUAL-04, QUAL-05 | T-14-04 / T-14-05 / T-14-06 | Phase 09 re-verification is anchored to current Phase 12/13 proof surfaces and records the automated synthetic-tag closure for `QUAL-04`. | mix-task + artifact | `mix test test/mix/tasks/verify_test.exs test/mix/tasks/ci_alias_contract_test.exs test/mix/tasks/docs_contract_task_test.exs test/mix/tasks/release_preflight_test.exs test/scripts/release_preflight_proof_test.exs && mix docs.contract` plus `rg` on `09-VERIFICATION.md`, `09-VALIDATION.md`, `09-01-SUMMARY.md`, `09-02-SUMMARY.md` | ✅ | ⬜ pending |
| 14-03-01 | 03 | 2 | ADPT-05, QUAL-04 | T-14-07 / T-14-09 | Phase 10 verification and validation reflect actual recipe closure while keeping release-only proof truthful. | unit + artifact | `mix test test/rendro/adapters/mailglass_test.exs test/rendro/adapters/accrue_test.exs` plus `rg` on `10-VERIFICATION.md`, `10-VALIDATION.md`, `10-01-SUMMARY.md`, `10-02-SUMMARY.md` | ✅ | ⬜ pending |
| 14-03-02 | 03 | 2 | ADPT-05 | T-14-08 | Stale Phase 05 recipe evidence no longer claims an unresolved manual Mailglass wrapper checkpoint after Phase 10 closure. | artifact | `rg -n "automated regression|passed: 1|pending: 0" .planning/phases/05-early-ecosystem-recipes/05-VERIFICATION.md .planning/phases/05-early-ecosystem-recipes/05-HUMAN-UAT.md` | ✅ | ⬜ pending |
| 14-04-01 | 04 | 3 | ADPT-01, ADPT-02, ADPT-03, ADPT-04, OBS-03, QUAL-01, QUAL-02, QUAL-03, QUAL-04, QUAL-05 | T-14-11 | Phase 11 verification preserves the mixed outcomes already described by the reconstructed phase instead of inflating them to all-complete metadata. | integration + artifact | `mix test test/rendro_builders_test.exs test/rendro/integration_test.exs test/rendro/flow_test.exs test/rendro/metadata_test.exs test/rendro/error_test.exs test/rendro/telemetry_test.exs test/rendro/policy_test.exs test/rendro/adapters/phoenix_test.exs test/rendro/adapters/oban/render_worker_test.exs test/rendro/adapters/threadline_test.exs` plus `rg` on `11-VERIFICATION.md`, `11-VALIDATION.md`, `11-01-SUMMARY.md` | ✅ | ⬜ pending |
| 14-04-02 | 04 | 3 | ADPT-01, ADPT-02, ADPT-03, ADPT-04, ADPT-05, OBS-02, OBS-03, OBS-04, QUAL-01, QUAL-02, QUAL-03, QUAL-04, QUAL-05 | T-14-10 / T-14-12 | Final summary metadata key normalization and `REQUIREMENTS.md` sync are derived from finished verification verdicts only, with authoritative-source precedence and recomputed totals enforced. | artifact consistency | `python3` comparison between authoritative verification sources (`07`, `08`, `09`, `10`, `11`, plus `13` for `QUAL-04`) and `REQUIREMENTS.md` rows/totals, plus `rg` over normalized `requirements_completed` keys in `12-*` and `13-*` summaries | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] No new runtime tests are required; Phase 14 consumes existing proof surfaces only.
- [x] Each task already has at least one passing automated command or artifact-consistency check.
- [x] The final `REQUIREMENTS.md` sync is deferred until after `07-VERIFICATION.md` through `11-VERIFICATION.md` all exist.

---

## Manual-Only Verifications

None. The remaining `QUAL-04` proof is automated through the synthetic exact-tag helper and the dedicated CI `release-proof` job.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verification paths
- [x] Sampling continuity: no 3 consecutive tasks without automated verification
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 180s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** ready for execution
