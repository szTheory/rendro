---
phase: 131
slug: adoption-snapshot-phoenix-newcomer-proof
# status lifecycle: draft (seeded by plan-phase) -> validated (set by validate-phase)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-21
---

# Phase 131 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir 1.19.5 / OTP 28) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/docs_contract/adoption_evidence_contract_test.exs test/docs_contract/phoenix_newcomer_contract_test.exs test/scripts/phoenix_clean_room_proof_test.exs` |
| **Full suite command** | `mix ci.fast` |
| **Estimated runtime** | ~30 seconds for focused deterministic tests; public-source and live-server proof is separately advisory |

---

## Sampling Rate

- **After every task commit:** Run the focused ExUnit command above for the edited boundary.
- **After every plan wave:** Run `mix ci.fast`.
- **Before `$gsd-verify-work`:** The deterministic full suite must be green and the separately labeled advisory release/public-journey record must be complete.
- **Max feedback latency:** 30 seconds for deterministic feedback; network and release evidence is not part of this bound.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 131-W0-01 | 01 | 0 | SIGNAL-02, SIGNAL-03, SIGNAL-04, SIGNAL-05 | T-131-01 | Evidence is bounded, typed, and never converts unavailable retrieval into zero | contract/unit | `mix test test/docs_contract/adoption_evidence_contract_test.exs` | ❌ W0 | ⬜ pending |
| 131-W0-02 | 05 | 0 | JOURNEY-01, JOURNEY-02, JOURNEY-04 | T-131-02 | Public-package proof rejects path/Git/workspace/cache leakage and retains no payload | docs contract | `mix test test/docs_contract/phoenix_newcomer_contract_test.exs` | ❌ W0 | ⬜ pending |
| 131-W0-03 | 05 | 0 | JOURNEY-01, JOURNEY-03, JOURNEY-04 | T-131-03 | Harness isolates run state, bounds process lifetime, and validates captured response metadata | unit | `mix test test/scripts/phoenix_clean_room_proof_test.exs` | ❌ W0 | ⬜ pending |
| 131-ADV-01 | 01 | advisory | SIGNAL-02, SIGNAL-03, SIGNAL-04, SIGNAL-05 | T-131-01 | One read-only public snapshot retains allowlisted metadata only | advisory external | Named adoption snapshot command from Plan 131-01 | ❌ | ⬜ pending |
| 131-REL-PARSER | 02 | 2 | JOURNEY-01, JOURNEY-02 | T-131-08, T-131-14 | Both protected workflow parsers select exactly one `@version` declaration, fail on zero/multiple declarations, and independently reproduce the failed v1.3.0 multiline case | contract | `mix test test/guardrails/required_checks_contract_test.exs --max-failures 1` | ✅ | ⬜ pending |
| 131-REL-CANDIDATE | 03 | 3 | JOURNEY-01, JOURNEY-02 | T-131-06, T-131-08 | Exact 1.3.1 version/docs/package/verifier/candidate facts pass focused tests, CI, preflight, dry-run, package/docs, and tag checks without external mutation | contract/integration | Named full private candidate command from Plan 131-03 | ✅ | ⬜ pending |
| 131-ADV-REL | 04 | advisory | JOURNEY-01, JOURNEY-02 | T-131-05, T-131-06, T-131-08 | Fresh exact-candidate approval immediately precedes protected v1.3.1 Hex/HexDocs mutation and fail-closed public verification | advisory external | Named protected release, candidate-bound HexDocs, and public verifier commands from Plan 131-04 | ❌ | ⬜ pending |
| 131-ADV-02 | 05 | advisory | JOURNEY-01, JOURNEY-02, JOURNEY-03, JOURNEY-04 | T-131-09, T-131-13, T-131-15 | Exact public `rendro` 1.3.1 resolves in a fresh generated app and returns a valid PDF through ConnCase and loopback HTTP; run 32513353551 remains failed incident evidence | advisory external | Named exact 1.3.1 clean-room harness command from Plan 131-05 | ❌ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/docs_contract/adoption_evidence_contract_test.exs` — sidecar schema, retrieval/decision enums, threshold arithmetic, bounded metadata, package binding.
- [ ] `test/docs_contract/phoenix_newcomer_contract_test.exs` — README/snippet/harness/manifest/no-leakage contracts.
- [ ] `test/scripts/phoenix_clean_room_proof_test.exs` — pure command, path, lock, timeout, redaction, and result helper tests.
- [ ] `test/guardrails/required_checks_contract_test.exs` — exact-one release-version extraction, including the former multiline input and zero/multiple-declaration failures.
- [ ] Keep live publish, Hex/GitHub retrieval, package resolution, and endpoint execution out of default deterministic CI; invoke them only through named advisory procedures.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Authorize and publish public Rendro 1.3.1 | JOURNEY-01 | Tagging and Hex publication are irreversible external mutations requiring a fresh exact-candidate human approval | Inspect the fully validated private 1.3.1 candidate and immutable v1.3.0 failure evidence; stop at the new blocking checkpoint; only after explicit exact-SHA approval push v1.3.1 through the protected tag workflow and dispatch candidate-bound HexDocs. Never retry or mutate v1.3.0. |
| Verify public registry, package contents, HexDocs, and failed-release history | JOURNEY-01, JOURNEY-02 | Public infrastructure is temporally variable and cannot be claimed by offline CI | After protected publication, query exact 1.3.1 Hex/archive/HexDocs/source/symbol facts and retain exact run IDs. Also prove v1.3.0 still peels to `3d014b8194782fc29bc685c0d5e84e4adc64b2c3`, run `32513353551` remains failed, and Hex/HexDocs 1.3.0 remain absent. |
| Execute one bounded adoption snapshot | SIGNAL-02, SIGNAL-03, SIGNAL-04, SIGNAL-05 | Hex/GitHub availability and public activity are live advisory observations | Run the named one-shot snapshot procedure once; inspect retrieval statuses, raw bounded facts, family decisions, and weakest-link composite; commit only the sidecar and human index. |
| Execute the public-Hex Phoenix journey | JOURNEY-01, JOURNEY-02, JOURNEY-03, JOURNEY-04 | Fresh dependency resolution and a real loopback listener depend on live external/local state | Run the harness from an empty isolated run root; inspect its source-leakage audits, ConnCase output, loopback response contract, manifest, and transcript; retain no app/cache/PDF/process artifacts. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verification or Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verification.
- [ ] Wave 0 covers all missing references.
- [ ] No watch-mode flags.
- [ ] Deterministic feedback latency is under 30 seconds.
- [ ] Live external claims remain explicitly advisory and are never substituted by offline tests.
- [ ] `nyquist_compliant: true` set in frontmatter after execution evidence exists.

**Approval:** pending
