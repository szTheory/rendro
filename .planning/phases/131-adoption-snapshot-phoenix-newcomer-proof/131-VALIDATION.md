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
| **Quick run command** | `mix test test/scripts/release_preflight_proof_test.exs test/mix/tasks/release_preflight_test.exs test/guardrails/required_checks_contract_test.exs test/mix/tasks/rendro_gen_theme_test.exs test/mix/tasks/rendro_gen_theme_fresh_consumer_test.exs test/scripts/public_release_verifier_test.exs --max-failures 1` before public verification; Plan 10 creates and then adds `test/docs_contract/phoenix_newcomer_contract_test.exs test/scripts/phoenix_clean_room_proof_test.exs` |
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
| 131-W0-02 | 10 | 0 | JOURNEY-01, JOURNEY-02, JOURNEY-04 | T-131-60, T-131-62 | Public-package proof rejects path/Git/workspace/cache leakage and retains no payload | docs contract | `mix test test/docs_contract/phoenix_newcomer_contract_test.exs` | ✅ | ✅ green |
| 131-W0-03 | 10 | 0 | JOURNEY-01, JOURNEY-03, JOURNEY-04 | T-131-61, T-131-63 | Harness isolates run state, bounds process lifetime, and validates captured response metadata | unit | `mix test test/scripts/phoenix_clean_room_proof_test.exs` | ✅ | ✅ green |
| 131-ADV-01 | 01 | advisory | SIGNAL-02, SIGNAL-03, SIGNAL-04, SIGNAL-05 | T-131-01 | One read-only public snapshot retains allowlisted metadata only | advisory external | Named adoption snapshot command from Plan 131-01 | ❌ | ⬜ pending |
| 131-REL-PARSER | 02 | 2 | JOURNEY-01, JOURNEY-02 | T-131-08, T-131-14 | Both protected workflow parsers select exactly one `@version` declaration, fail on zero/multiple declarations, and independently reproduce the failed v1.3.0 multiline case | contract | `mix test test/guardrails/required_checks_contract_test.exs --max-failures 1` | ✅ | ⬜ pending |
| 131-REL-CANDIDATE-131 | 03 | 3 | JOURNEY-01, JOURNEY-02 | T-131-06, T-131-08 | Historical exact 1.3.1 private checks passed, but immutable tag/run 32539594278 failed before publication and cannot satisfy the public prerequisite | historical deterministic | Plan 131-03 evidence plus debug session `release-preflight-theme-hang.md` | ✅ | ✅ historical-only |
| 131-REL-CANDIDATE-132 | 04 | 4 | JOURNEY-01, JOURNEY-02 | T-131-34 | Historical private v1.3.2 proof omitted security audits; immutable tag/run 32586098785 failed complete preflight and cannot satisfy the public prerequisite | historical deterministic/advisory | Plan 131-04 evidence plus resolved debug session `v132-preflight-exit-one.md` | ✅ | ✅ historical-only |
| 131-REL-COMPLETE-AUDIT | 05-09 | 5-9 | JOURNEY-01 | T-131-35, T-131-37, T-131-52, T-131-57 | Candidate mode rejects CI/audit bypasses and complete exact-SHA preflight includes repeated CI, both audits, tutorial boundary, package/docs, and cleanup | contract/integration | Named complete candidate-SHA preflight in Plans 131-08 and 131-09 | ✅ historical / ⬜ v1.3.4 |
| 131-REL-FIFO | 04-09 | 4-9 | JOURNEY-01 | T-131-39, T-131-55, T-131-57 | Open-silent FIFO stdin completes through its internal Skipped assertion without an overwrite prompt | deterministic regression | Named FIFO command in Plans 131-08 and 131-09 | ✅ | ⬜ pending |
| 131-REL-TIMEOUT | 04-09 | 4-9 | JOURNEY-01 | T-131-39, T-131-52 | `.github/workflows/release.yml` retains `validate-and-dry-run.timeout-minutes: 45` and `publish.timeout-minutes: 15` | contract | `mix test test/guardrails/required_checks_contract_test.exs --max-failures 1` | ✅ | ⬜ pending |
| 131-REL-NO-TAG | 04-09 | 4-9 | JOURNEY-01, JOURNEY-02 | T-131-36, T-131-54, T-131-57 | Exact-SHA detached proof asserts HEAD equality, invokes no tag command, and leaves complete local/remote tag-ref snapshots unchanged | contract/integration | `mix test test/scripts/release_preflight_proof_test.exs test/mix/tasks/release_preflight_test.exs --max-failures 1` plus named exact-SHA proof | ✅ | ⬜ pending |
| 131-REL-CANDIDATE-133 | 05,06 | 5,6 | JOURNEY-01, JOURNEY-02, JOURNEY-04 | T-131-35, T-131-36, T-131-37, T-131-38 | Historical exact 1.3.3 candidate passed complete proof but immutable run 32596108284 failed only at the redundant standalone unauthenticated Hex dry run | historical deterministic/advisory | Plan 131-05/06 evidence plus `.planning/debug/v133-hex-dry-run.md` | ✅ | ✅ historical-only |
| 131-REL-LEAST-PRIVILEGE | 07 | 7 | JOURNEY-01, JOURNEY-04 | T-131-52, T-131-53 | Candidate contains bbe75d2; complete credential-free preflight is the sole dry-run validation gate and only actual protected publish receives HEX_API_KEY | contract | `mix test test/guardrails/required_checks_contract_test.exs test/mix/tasks/release_preflight_test.exs --max-failures 1` | ✅ | ⬜ pending |
| 131-REL-CANDIDATE-134 | 07,08 | 7,8 | JOURNEY-01, JOURNEY-02, JOURNEY-04 | T-131-52, T-131-54, T-131-55 | Every existing 1.3.4 release-bearing exact-version, package/docs, workflow, verifier, and incident surface is committed before exact-SHA capture; detached complete proof leaves refs unchanged and permits only control records afterward; clean-room artifacts remain post-verifier Plan-10 work | contract/integration | Named full private candidate command from Plan 131-08 | ❌ | ⬜ pending |
| 131-ADV-REL-134 | 09 | advisory | JOURNEY-01, JOURNEY-02, JOURNEY-04 | T-131-56, T-131-57, T-131-58, T-131-59 | Fresh approval precedes one v1.3.4 tag; protected release+Hex succeeds before candidate-bound HexDocs and atomic verifier | advisory external | Named protected run/dispatch/verifier commands from Plan 131-09 | ❌ | ⬜ pending |
| 131-ADV-02 | 10 | advisory | JOURNEY-01, JOURNEY-02, JOURNEY-03, JOURNEY-04 | T-131-60, T-131-61, T-131-62, T-131-63 | Exact public `rendro` 1.3.4 resolves in a fresh generated app and returns a valid PDF through ConnCase and loopback HTTP; all four older failed tags/runs remain incident evidence only | advisory external | Named exact 1.3.4 clean-room harness command from Plan 131-10 | ✅ | ❌ red — repaired single attempt failed closed at isolated `phx_new` archive-source audit; both bounded failures retained |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/docs_contract/adoption_evidence_contract_test.exs` — sidecar schema, retrieval/decision enums, threshold arithmetic, bounded metadata, package binding.
- [ ] `test/docs_contract/phoenix_newcomer_contract_test.exs` — README/snippet/harness/manifest/no-leakage contracts.
- [ ] `test/scripts/phoenix_clean_room_proof_test.exs` — pure command, path, lock, timeout, redaction, and result helper tests.
- [ ] `test/guardrails/required_checks_contract_test.exs` — exact-one release-version extraction plus release validation/publish 45/15-minute timeout contracts.
- [ ] `test/mix/tasks/rendro_gen_theme_test.exs` — exact noninteractive conflict regression using `Mix.Shell.Process`, with adjacent fresh-consumer coverage.
- [ ] `test/mix/tasks/release_preflight_test.exs` — candidate-SHA HEAD parity without weakening ordinary protected exact-tag parity.
- [ ] `test/scripts/release_preflight_proof_test.exs` — exact-SHA detached worktree, no tag command, HEAD equality, unchanged tag-ref snapshot, and cleanup.
- [ ] `test/scripts/public_release_verifier_test.exs` — exact-1.3.3 candidate validation and immutable v1.3.0/v1.3.1/v1.3.2 incident history with exact run/job/absence facts.
- [ ] Complete-audit regression — candidate mode rejects CI/security bypasses and exercises repeated CI, `mix hex.audit`, and `mix deps.audit` before candidate approval.
- [ ] Least-privilege release regression — no standalone workflow Hex dry-run step, no `HEX_API_KEY` in validation, complete preflight retained, and `HEX_API_KEY` present only on actual protected publish.
- [ ] Tutorial-tooling boundary — root Livebook/config coupling and new audit ignores are absent while the packaged guide executes through the isolated ephemeral verifier.
- [ ] Keep live publish, Hex/GitHub retrieval, package resolution, and endpoint execution out of default deterministic CI; invoke them only through named advisory procedures.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Authorize and publish public Rendro 1.3.4 | JOURNEY-01 | Tagging and Hex publication are irreversible external mutations requiring fresh exact-candidate human approval | Inspect the final private 1.3.4 candidate containing bbe75d2 after complete exact-SHA/no-tag preflight with focused/FIFO/full CI/docs/package/tutorial/both-audit proof and unchanged complete refs; only approval naming the exact SHA plus tag, Hex, and HexDocs together authorizes new `v1.3.4`. Never retry or mutate v1.3.0 through v1.3.3. |
| Verify public registry, package contents, HexDocs, and failed-release history | JOURNEY-01, JOURNEY-02 | Public infrastructure is temporally variable and cannot be claimed by offline CI | After protected publication, query exact 1.3.4 Hex/archive/HexDocs/source/symbol facts and retain exact new run/job IDs. Also prove v1.3.0 through v1.3.2 retain their recorded identities and v1.3.3 tag object `c96bf205d7216cdcf4846a0f24a312f9c1c75b0f` still peels to `cfc58a81865e060351ce33d98f5e52de8cd198d9`, run `32596108284`/jobs `97087204354` and `97088652899` retain failed/skipped conclusions, and Hex/HexDocs 1.3.0 through 1.3.3 remain absent. |
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

**Approval:** D-35 recovery planned for exact v1.3.4; immutable v1.3.3 incident remains failed with no HexDocs dispatch or public prerequisite.
