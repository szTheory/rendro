---
phase: 131
slug: adoption-snapshot-phoenix-newcomer-proof
# status lifecycle: draft (seeded by plan-phase) -> validated (set by validate-phase)
status: validated
nyquist_compliant: true
wave_0_complete: true
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
| **Quick run command** | `mix test test/scripts/public_release_verifier_test.exs test/scripts/phoenix_clean_room_proof_test.exs test/docs_contract/launch_execution_claims_test.exs test/docs_contract/phoenix_newcomer_contract_test.exs test/docs_contract/adoption_evidence_contract_test.exs test/guardrails/required_checks_contract_test.exs --max-failures 1` |
| **Full suite command** | `mix ci.fast` |
| **Estimated runtime** | ~10 seconds for focused deterministic tests and ~1 minute for `mix ci.fast`; public-source and live-server proof is separately advisory |

---

## Sampling Rate

- **After every task commit:** Run the focused ExUnit command above for the edited boundary.
- **After every plan wave:** Run `mix ci.fast`.
- **Before `$gsd-verify-work`:** The deterministic full suite must be green and the separately labeled advisory release/public-journey record must be complete.
- **Max feedback latency:** 30 seconds for deterministic feedback; network and release evidence is not part of this bound.

---

## Per-Task Verification Map

| Tasks | Plans | Requirements | Behavioral evidence | Automated verification | Classification |
|---|---|---|---|---|---|
| 131-01-T1/T2; 131-11-T1/T2 | 01, 11 | SIGNAL-02–05 | Dated bounded snapshot, unavailable-is-not-zero semantics, exclusive one-writer publication, truthful empty states, package binding | `adoption_evidence_contract_test.exs`, `adoption_claims_test.exs` | COVERED |
| 131-02-T1 | 02 | JOURNEY-01–02 | Exact-one protected workflow version parsing and multiline-incident rejection | `required_checks_contract_test.exs` | COVERED |
| 131-03-T1; 131-04-T1/T2/T3; 131-05-T1/T2/T3; 131-06-T1/T2/T3 | 03–06 | JOURNEY-01–02, JOURNEY-04 | Private-candidate, no-tag, FIFO, timeout, complete-audit, and immutable failed-release contracts | Release preflight, verifier, workflow, and guardrail suites | COVERED / HISTORICAL |
| 131-07-T1/T2; 131-08-T1/T2; 131-09-T1/T2/T3 | 07–09 | JOURNEY-01–02, JOURNEY-04 | Exact v1.3.4 candidate, protected publication, archive/docs identities, four immutable incidents | Preflight, public verifier, launch, and required-check contracts | COVERED |
| 131-10-T1/T2 | 10 | JOURNEY-01–04 | Exact-public Phoenix isolation, app-owned document, adapter response, dual HTTP facts, bounded evidence | `phoenix_clean_room_proof_test.exs`, `phoenix_newcomer_contract_test.exs` | COVERED |
| 131-12-T1; 131-13-T1 | 12–13 | JOURNEY-01–02, JOURNEY-04 | Immutable HexDocs identity and race-safe prerequisite publication | Launch-execution and public-verifier contracts | COVERED |
| 131-14-T1/T2; 131-18-T1/T2/T3 | 14, 18 | JOURNEY-01–02, JOURNEY-04 | Fresh exact control authorization, protected-main dispatch, durable candidate binding, current verifier output | Launch-execution, verifier, and canonical-prerequisite checks | COVERED |
| 131-16-T1 | 16 | JOURNEY-01–04 | One canonical prerequisite passes both validators; legacy and malformed bindings fail closed | Combined public-verifier and clean-room suite | COVERED |
| 131-17-T1/T2 | 17 | JOURNEY-01–04 | Fresh exact-public Phoenix run, matching ConnCase/loopback PDF facts, cleanup, evidence hashes, deterministic/advisory separation | Authoritative focused suite and `mix ci.fast` | COVERED |

---

## Wave 0 Requirements

- [x] `test/docs_contract/adoption_evidence_contract_test.exs` — sidecar schema, retrieval/decision enums, threshold arithmetic, bounded metadata, package binding.
- [x] `test/docs_contract/phoenix_newcomer_contract_test.exs` — README/snippet/harness/manifest/no-leakage contracts.
- [x] `test/scripts/phoenix_clean_room_proof_test.exs` — pure command, path, lock, timeout, redaction, and result helper tests.
- [x] Release, generator, tutorial, and preflight contracts — completed through the retained exact v1.3.4 candidate, protected-release verifier, and `mix ci.fast` evidence.
- [x] Live publish, registry, and endpoint observations remain advisory and are retained as bounded evidence rather than deterministic CI authority.

---

## Advisory and Manual Evidence

| Behavior | Requirements | Current evidence | Classification |
|---|---|---|---|
| Dated public adoption observation | SIGNAL-02–05 | Plan 131-01 retained the 2026-08-21 bounded sidecar; offline schema, decision, concurrency, and package contracts remain deterministic | ADVISORY OBSERVATION + COVERED CONTRACT |
| Exact v1.3.4 protected publication and HexDocs binding | JOURNEY-01–02, JOURNEY-04 | Release run `32763039854`; HexDocs run `32898926521`; protected-main control `f9b63246029396f76c443c5750aad42a3004081b`; canonical verifier record retained | EXECUTED EXTERNAL EVIDENCE |
| Public-Hex Phoenix journey | JOURNEY-01–04 | Fresh Plan 131-17 evidence resolves Rendro 1.3.4 and records matching ConnCase/loopback PDF facts with cleanup `removed` | ADVISORY OBSERVATION + COVERED CONTRACT |
| Future revalidation | all | Re-run live observers only when current external state is relevant; never substitute live observations for deterministic CI or repeat irreversible publication | MANUAL / ADVISORY ONLY |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verification or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verification.
- [x] Wave 0 covers all missing references.
- [x] No watch-mode flags.
- [x] Deterministic feedback latency is under 30 seconds.
- [x] Live external claims remain explicitly advisory and are never substituted by offline tests.
- [x] Cross-contract prerequisite provenance is consistent between verifier, retained prerequisite, and clean-room gate.

**Current status:** All eight Phase 131 requirements are covered. The canonical prerequisite records `hexdocs_workflow_dispatch` provenance and a durable candidate binding; both validators accept it and reject the legacy route. Immutable v1.3.0–v1.3.3 incidents remain historical failures.

## Historical Nyquist Reconciliation — 2026-08-25

The initial audit found two gaps: retained journey facts lacked an anti-drift
contract, and the verifier/consumer prerequisite contracts disagreed. The first
was covered by commit `30682e7`. Plans 131-18, 131-16, and 131-17 then produced a
current protected-main HexDocs binding, aligned both validators, rejected the
legacy route, and refreshed the bounded clean-room evidence. The earlier
BLOCKED/NONCOMPLIANT verdict and red rows are historical and fully superseded.

| Historical gap | Closure evidence | Current status |
|---|---|---|
| Retained dual-HTTP evidence could drift | Deterministic docs contract decodes the record and checks exact public identity, source/cleanup facts, bounded commands, both HTTP outcomes, and retained hashes | RESOLVED |
| Verifier and clean-room consumer accepted different prerequisite provenance | Current canonical fixture passes both validators; legacy/missing/mismatched bindings fail closed; fresh evidence binds to the current prerequisite SHA | RESOLVED |

## Validation Audit — 2026-08-26

The State A audit read all 17 executable plans and summaries, mapped every task
and all eight requirement IDs to behavioral tests, and checked the current
verification/security reports. No missing or partial current coverage remains.

### Requirement-to-Test Map

| Requirement | Phase tasks | Behavioral evidence | Classification |
|---|---|---|---|
| SIGNAL-02 | 131-01-T1/T2, 131-11-T1 | Exact Hex totals/classification, unavailable semantics, exclusive writer, bounded sidecar/package contracts | COVERED |
| SIGNAL-03 | 131-01-T1/T2, 131-11-T2 | Empty/malformed demand review, bounded candidate evidence, ledger binding | COVERED |
| SIGNAL-04 | 131-01-T2, 131-11-T2 | Contributor review, exclusions, and truthful empty-state contracts | COVERED |
| SIGNAL-05 | 131-01-T1/T2, 131-11-T1 | Unavailable-is-not-zero and weakest-link composite decision contracts | COVERED |
| JOURNEY-01 | 131-02–10, 131-12, 131-14, 131-16–18 | Exact public install, protected release/binding, isolated Hex resolution, source/cache audits | COVERED |
| JOURNEY-02 | 131-02–10, 131-12, 131-14, 131-16–18 | README discovery and canonical Invoice / Swiss / `#2C6BED` / light customization | COVERED |
| JOURNEY-03 | 131-10, 131-16, 131-17 | Adapter response plus matching ConnCase/loopback PDF facts and failure paths | COVERED |
| JOURNEY-04 | 131-04–10, 131-13–18 | Exact versions, commands, run/binding identities, hashes, bounded repairs, and anti-drift contracts | COVERED |

### Current Evidence

| Check | Result |
|---|---|
| Focused Phase 131 suite | PASS — 99 tests, 0 failures on 2026-08-26 |
| Full deterministic lane | PASS — 12 doctests, 8 properties, 1,917 tests, 0 failures; docs, Credo, and Dialyzer green on 2026-08-26 |
| Goal verification | PASS — 5/5 must-haves, 0 unverified behaviors, 0 remaining gaps |
| Security audit | SECURED — 54/54 threats mitigated or accepted, 0 open |
| Current prerequisite | `hexdocs_workflow_dispatch`, run `32898926521`, protected-main control `f9b63246029396f76c443c5750aad42a3004081b`, sealed candidate `f03c78bab54efe1cd1596d51cf3f28193232e2a3` |
| Current evidence hashes | Prerequisite `eba7b5003ad35830a44723d6e3e6ec4adfb59ce9586b17f67c4c5c1cc39f84b8`; JSON `a59706f89b4c4226c184509457856d1bd75474a495efaf6427e396307d3a2bfd`; transcript `971539bdeec59b73ab354494fd77f5ea16e5b469bfaa89d3374a17fc720da9c7` |

Replacement journey JSON SHA-256:
  `a59706f89b4c4226c184509457856d1bd75474a495efaf6427e396307d3a2bfd`

Replacement journey transcript SHA-256:
  `971539bdeec59b73ab354494fd77f5ea16e5b469bfaa89d3374a17fc720da9c7`

The focused suite and `mix ci.fast` are deterministic contracts. Public package
resolution, Phoenix generation, and loopback observations remain explicitly
advisory evidence bound to the canonical prerequisite; they do not inflate CI
claims.

### Audit Trail

| Metric | Count |
|---|---:|
| Current gaps found | 0 |
| Current gaps resolved | 0 |
| Historical gaps reconciled | 2 |
| Escalated | 0 |
| Skipped | 0 |

No tests or implementation files were added by this audit. `wave_0_complete`,
the task map, and sign-off now reflect the already-executed Plan 131 closure.
