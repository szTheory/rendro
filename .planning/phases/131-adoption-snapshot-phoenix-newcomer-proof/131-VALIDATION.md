---
phase: 131
slug: adoption-snapshot-phoenix-newcomer-proof
# status lifecycle: draft (seeded by plan-phase) -> validated (set by validate-phase)
status: validated
nyquist_compliant: true
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
| 131-W0-02 | 10 | 0 | JOURNEY-01, JOURNEY-02, JOURNEY-04 | T-131-60, T-131-62 | Public-package mechanics reject path/Git/workspace/cache leakage, but the prerequisite provenance is legacy | docs contract | `mix test test/docs_contract/phoenix_newcomer_contract_test.exs` | ✅ | ⚠️ partial |
| 131-W0-03 | 10 | 0 | JOURNEY-01, JOURNEY-03, JOURNEY-04 | T-131-61, T-131-63 | Harness validates response metadata, but accepts a verifier-incompatible legacy prerequisite | unit | `mix test test/scripts/phoenix_clean_room_proof_test.exs` | ✅ | ⚠️ partial |
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
| 131-ADV-REL-134 | 09 | advisory | JOURNEY-01, JOURNEY-02, JOURNEY-04 | T-131-56, T-131-57, T-131-58, T-131-59 | Public record is legacy package-only provenance and lacks the required candidate binding | advisory external | Current-verifier regeneration is required | ❌ | ❌ blocker |
| 131-ADV-02 | 10 | advisory | JOURNEY-01, JOURNEY-02, JOURNEY-03, JOURNEY-04 | T-131-60, T-131-61, T-131-62, T-131-63 | Retained 200/PDF facts are useful but were authorized by the legacy prerequisite, not the current durable workflow-dispatch contract | advisory external | Regenerate prerequisite, update consumer gate, then rerun clean-room proof | ✅ | ⚠️ partial |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/docs_contract/adoption_evidence_contract_test.exs` — sidecar schema, retrieval/decision enums, threshold arithmetic, bounded metadata, package binding.
- [x] `test/docs_contract/phoenix_newcomer_contract_test.exs` — README/snippet/harness/manifest/no-leakage contracts.
- [x] `test/scripts/phoenix_clean_room_proof_test.exs` — pure command, path, lock, timeout, redaction, and result helper tests.
- [x] Release, generator, tutorial, and preflight contracts — completed through the retained exact v1.3.4 candidate, protected-release verifier, and `mix ci.fast` evidence.
- [x] Live publish, registry, and endpoint observations remain advisory and are retained as bounded evidence rather than deterministic CI authority.

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

- [x] All tasks have `<automated>` verification or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verification.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Deterministic feedback latency is under 30 seconds.
- [x] Live external claims remain explicitly advisory and are never substituted by offline tests.
- [ ] Cross-contract prerequisite provenance is consistent between verifier, retained prerequisite, and clean-room gate (blocked by T-131-59).

**Current status:** The retained prerequisite records legacy `protected_release_publish`/`push` provenance and no durable candidate binding. It must not be described as atomically VERIFIED by the current verifier, and the clean-room proof it authorized is not current-contract coverage. Immutable v1.3.0-v1.3.3 incidents remain historical failures.

## Nyquist Audit — 2026-08-25

**Superseded result:** This earlier audit found one evidence-drift gap and added
useful coverage, but it did not compare the verifier and consumer prerequisite
contracts. See the reconciliation below; Phase 131 is currently noncompliant.
The audit started adversarially: the
retained Phoenix result was only existence-checked, so its claimed dual-HTTP
PDF facts could have drifted independently of the harness tests. The new
contract decodes the retained record and requires exact public identity,
isolated-source/cleanup facts, bounded command history, and identical
ConnCase/loopback `200 application/pdf invoice.pdf nonempty %PDF-` facts.

| Test infrastructure | Evidence |
|---|---|
| Framework | ExUnit via `mix test` |
| Focused command | `mix test test/docs_contract/adoption_evidence_contract_test.exs test/docs_contract/phoenix_newcomer_contract_test.exs test/docs_contract/launch_execution_claims_test.exs test/scripts/phoenix_clean_room_proof_test.exs test/scripts/public_release_verifier_test.exs test/guardrails/required_checks_contract_test.exs --max-failures 1` |
| Focused result | 91 tests, 0 failures (2026-08-25) |
| Full deterministic suite | Previously recorded: 12 doctests, 8 properties, 1,908 tests, 0 failures via `mix ci.fast` |

### Requirement-to-Test Map

| Requirement | Phase tasks | Behavioral evidence | Classification |
|---|---|---|---|
| SIGNAL-02 | 131-01-T1/T2, 131-11-T1 | Exact Hex totals/classification, unavailable semantics, exclusive writer, bounded sidecar/package contracts in `adoption_evidence_contract_test.exs` | COVERED |
| SIGNAL-03 | 131-01-T1/T2, 131-11-T2 | Empty/malformed demand review, bounded candidate evidence, ledger binding in adoption contracts | COVERED |
| SIGNAL-04 | 131-01-T2, 131-11-T2 | Contributor bounded-candidate/empty-state and decision contracts | COVERED |
| SIGNAL-05 | 131-01-T1/T2, 131-11-T1 | Unavailable-is-not-zero and weakest-link composite contracts | COVERED |
| JOURNEY-01 | 131-02–10, 131-12 | Install/isolation mechanics are covered, but the retained prerequisite cannot be emitted by the current verifier | PARTIAL / BLOCKED |
| JOURNEY-02 | 131-02–10, 131-12 | Discovery/customization mechanics are covered, but their authoritative journey handoff is legacy provenance | PARTIAL / BLOCKED |
| JOURNEY-03 | 131-10-T1/T2 | Adapter and retained dual-HTTP facts are covered, but the evidence was authorized through verifier-incompatible provenance | PARTIAL / BLOCKED |
| JOURNEY-04 | 131-04–10, 131-13 | Version/result mechanics are covered, but the retained prerequisite/journey record is not bound to the current durable workflow contract | PARTIAL / BLOCKED |

### Per-Task Audit Map

| Tasks | Requirement scope | Automated verification | Classification |
|---|---|---|---|
| 131-01-T1/T2; 131-11-T1/T2 | SIGNAL-02–05 | `test/docs_contract/adoption_evidence_contract_test.exs`, `adoption_claims_test.exs` | COVERED |
| 131-02-T1 | JOURNEY-01, JOURNEY-02 | `test/guardrails/required_checks_contract_test.exs` | COVERED |
| 131-03-T1; 131-04-T1/T2/T3; 131-05-T1/T2/T3 | JOURNEY-01, JOURNEY-02, JOURNEY-04 | Release preflight/verifier/guardrail contracts and recorded detached proof | COVERED |
| 131-06-T1/T2/T3; 131-09-T1/T2/T3 | JOURNEY-01, JOURNEY-02, JOURNEY-04 | Verifier contracts are hardened, but retained public evidence is legacy and cannot satisfy them | PARTIAL / BLOCKED |
| 131-07-T1/T2; 131-08-T1/T2; 131-12-T1 | JOURNEY-01, JOURNEY-02, JOURNEY-04 | Public-release verifier, HexDocs identity, launch-execution and workflow guardrail contracts | COVERED |
| 131-10-T1/T2 | JOURNEY-01–04 | Harness/evidence tests pass independently but encode the legacy route | PARTIAL / BLOCKED |
| 131-13-T1 | JOURNEY-04 | `public_release_verifier_test.exs` competing-writer/no-overwrite regression | COVERED |

### Manual-Only / Advisory Boundaries

| Behavior | Requirement | Status | Reason |
|---|---|---|---|
| Re-query Hex/GitHub adoption data | SIGNAL-02–05 | Advisory-only revalidation | Public data changes; the committed snapshot and its offline grammar are automated. |
| Re-run a fresh public Phoenix installation and loopback server | JOURNEY-01–04 | Blocked remediation | Required after a current-verifier prerequisite is produced and the consumer gate rejects legacy provenance. |
| Repeat publication/approval actions | JOURNEY-01, JOURNEY-04 | Do not automate | These are irreversible external mutations; the existing public record is tested read-only. |

### Sign-Off and Audit Trail

| Metric | Count |
|---|---:|
| Gaps found | 2 |
| Resolved | 1 |
| Escalated | 1 |
| Skipped | 0 |

- Added and executed `retained clean-room result proves the exact public PDF journey with dual HTTP facts`.
- Test commit: `30682e7` (`test(phase-131): verify retained clean-room PDF journey evidence`).
- No implementation files were modified. The pre-existing dirty `131-VERIFICATION.md` was preserved and is not part of this audit's commit.

## Security and Re-Verification Reconciliation — 2026-08-25

**Verdict: BLOCKED / NONCOMPLIANT.** `131-SECURITY.md` leaves critical
T-131-59 open and `131-VERIFICATION.md` reports 2/4 observable truths. The
current verifier accepts only `hexdocs_workflow_dispatch` with a
`workflow_dispatch` HexDocs run and a durable `hexdocs_candidate_binding` whose
`control_sha` equals that run's `headSha`. The authoritative prerequisite instead
contains `protected_release_publish`, `push`, `Release to Hex`, and no binding;
`PhoenixCleanRoomProof.validate_prerequisite/1` accepts precisely this obsolete
record. Passing separate tests therefore prove contradictory contracts, not an
integrated journey.

| Gap | Requirements | Classification | Required remediation |
|---|---|---|---|
| Missing verifier-to-consumer integration assertion | JOURNEY-01–04 | MISSING / BLOCKER | After implementation remediation, add a single test that builds a current-verifier-valid fixture with `hexdocs_workflow_dispatch`, `workflow_dispatch`, `HexDocs`, and a durable binding, then asserts both `Rendro.PublicReleaseVerifier.validate/1 == :ok` and `Rendro.PhoenixCleanRoomProof.validate_prerequisite/1 == :ok`; mutate it to legacy `protected_release_publish`/missing binding and assert both reject it. |
| Authoritative prerequisite and retained journey evidence use obsolete provenance | JOURNEY-01–04 | IMPLEMENTATION/EVIDENCE BLOCKER | Publish the hardened HexDocs workflow to protected `origin/main`; obtain the successful protected-main dispatch and binding artifact; regenerate `131-PUBLIC-PREREQUISITE.json` through the current verifier; update the clean-room gate/tests; rerun the clean-room proof and retain regenerated bounded evidence. |

The test committed in `30682e7` remains useful: it protects the retained JSON's
dual-HTTP facts from drift. It is insufficient to authenticate those facts to
the verifier's current provenance contract. No intentionally failing test was
added to `main`.

## Plan 131-17 Current-Prerequisite Closure — 2026-08-25T21:29:03Z

The legacy-provenance reconciliation above is historical. Plans 131-18 and
131-16 produced the current prerequisite/consumer contract; this plan reran
the disposable Phoenix consumer against that prerequisite and refreshed the
advisory evidence without changing deterministic contracts.

| Check | Result |
|---|---|
| Current prerequisite validators | PASS — `Rendro.PhoenixCleanRoomProof.validate_prerequisite/1` and `verify_public_release.exs --check-existing` accepted the canonical record. |
| Fresh clean-room journey | PASS — exact public Rendro `1.3.4`; Phoenix `1.8.13`, Plug `1.20.3`, Bandit `1.12.5`, Phoenix installer `1.8.5`; ConnCase and loopback both recorded 200 / `application/pdf` / attachment `invoice.pdf` / nonempty / PDF magic. |
| Focused cross-contract suite | PASS — 94 tests, 0 failures: public verifier, clean-room, launch execution, newcomer documentation, adoption evidence, and required-check guardrails. |
| Cleanup-root regression | PASS — 1 test, 0 failures at `phoenix_clean_room_proof_test.exs:94`; the prior `:unsafe_or_nonempty_root` observation does not recur. |
| `mix ci.fast` | PASS — format, Hex build, compile warnings-as-errors, deterministic test lane, docs warnings-as-errors, Credo strict, and Dialyzer. |

### Current identities

- Canonical prerequisite SHA-256: `eba7b5003ad35830a44723d6e3e6ec4adfb59ce9586b17f67c4c5c1cc39f84b8`
- HexDocs run: `32898926521`; control SHA:
  `f9b63246029396f76c443c5750aad42a3004081b`; binding: protected-main
  `workflow_dispatch` for candidate
  `f03c78bab54efe1cd1596d51cf3f28193232e2a3` and tag `v1.3.4`.
- Replacement journey JSON SHA-256:
  `b2715b88f3828335fa3ac962009b4d1f37f22246caffc58cc886ab821cca2bc3`
- Replacement journey transcript SHA-256:
  `777ba87f63c63faecd1d52207fab76053c027e521e0097b19727dcc62b0a6b47`

### Classification and next gate

The focused suite and `mix ci.fast` are deterministic contracts. The public
package resolution, Phoenix generation, and loopback observations are
explicitly advisory evidence; they are bounded to the prerequisite and do not
inflate CI claims. Cross-contract provenance and the Nyquist gate are green
for this execution. Fresh GSD security and goal verification remain the next
independent audits for the prior `T-131-59` report and 2/4 goal report.
