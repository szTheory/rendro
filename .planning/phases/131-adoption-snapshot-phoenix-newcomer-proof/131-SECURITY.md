---
phase: 131-adoption-snapshot-phoenix-newcomer-proof
audited: 2026-08-25
status: secured
asvs_level: 1
block_on: high
threats_total: 54
threats_closed: 54
threats_open: 0
register_authored_at_plan_time: true
---

# Security Audit — Phase 131

## Threat Register

| Plan | Threat ID | Severity | Disposition | Status | Evidence |
|---|---|---:|---|---|---|
| 01 | T-131-01 | high | mitigate | CLOSED | Adoption normalization, canonical digest, exclusive writer: `scripts/adoption_snapshot.exs:145-160,268-314`; contracts `test/docs_contract/adoption_evidence_contract_test.exs:48-159`. |
| 01 | T-131-02 | high | mitigate | CLOSED | Bounded sidecar schema and negative secret/path fixture: `scripts/adoption_snapshot.exs:78-88,226-244`; `test/docs_contract/adoption_evidence_contract_test.exs:161-189`. |
| 01 | T-131-03 | medium | mitigate | CLOSED | Dated sidecar linked and contract-bound: `ADOPTION.md:9,112`; `test/docs_contract/adoption_evidence_contract_test.exs:161-189`. |
| 01 | T-131-04 | low | accept | ACCEPTED | See Accepted Risks: bounded one-shot retrieval; no daemon, retry loop, or polling. |
| 02 | T-131-14 | high | mitigate | CLOSED | Exact-one version parser in both protected workflows: `.github/workflows/release.yml:32-45`; `.github/workflows/hexdocs.yml:96-103`. |
| 02 | T-131-08 | high | mitigate | CLOSED | Both workflow consumers structurally covered: `test/guardrails/required_checks_contract_test.exs:494-528`. |
| 03 | T-131-08 | critical | mitigate | CLOSED | Immutable incident constants and validators: `scripts/verify_public_release.exs:15-30,931-1077`. |
| 03 | T-131-06 | high | mitigate | CLOSED | Candidate/tag/run binding validation: `scripts/verify_public_release.exs:90-146,731-749`. |
| 03 | T-131-07 | high | mitigate | CLOSED | Validation is credential-free; secrets scoped to protected publish: `.github/workflows/release.yml:12-77`. |
| 04 | T-131-16 | critical | mitigate | CLOSED | Read-only immutable incident collection and validation: `scripts/verify_public_release.exs:354-415,931-1077`. |
| 04 | T-131-17 | high | mitigate | CLOSED | 45/15-minute release job bounds: `.github/workflows/release.yml:12-56`. |
| 04 | T-131-18 | high | mitigate | CLOSED | Detached candidate HEAD equality: `scripts/release_preflight_proof.exs:172-200`. |
| 04 | T-131-19 | medium | mitigate | CLOSED | Candidate proof commands/results retained: `131-RELEASE-CANDIDATE.md:26-57`. |
| 04 | T-131-31 | critical | mitigate | CLOSED | Candidate mode snapshots tag refs before/after; no candidate tag command: `scripts/release_preflight_proof.exs:172-200`. |
| 05 | T-131-34 | high | mitigate | CLOSED | v1.3.2 exact tag/run/job validation: `scripts/verify_public_release.exs:976-1020`. |
| 05 | T-131-35 | critical | mitigate | CLOSED | Candidate mode rejects CI/security-audit bypasses: `scripts/release_preflight_proof.exs:60-85`; `test/mix/tasks/release_preflight_test.exs:319-324`. |
| 05 | T-131-36 | critical | mitigate | CLOSED | Candidate identity, detached HEAD, ref snapshot controls: `scripts/release_preflight_proof.exs:172-200`. |
| 05 | T-131-37 | high | mitigate | CLOSED | Exact public dependency/lock enforcement: `scripts/phoenix_clean_room_proof.exs:86-110,558-564`; `test/scripts/phoenix_clean_room_proof_test.exs:335-369`. |
| 05 | T-131-38 | high | mitigate | CLOSED | Exact candidate/version/archive checks: `scripts/verify_public_release.exs:90-146,755-777`. |
| 05 | T-131-39 | medium | mitigate | CLOSED | Protected workflow timeouts: `.github/workflows/release.yml:12-56`. |
| 06 | T-131-40 | critical | mitigate | CLOSED | Explicit human approval boundary: `131-RELEASE-CANDIDATE.md:82-88`. |
| 06 | T-131-41 | critical | mitigate | CLOSED | No-tag detached proof and ref snapshots: `scripts/release_preflight_proof.exs:172-200`. |
| 06 | T-131-42 | critical | mitigate | CLOSED | Workflow/event/head/job identity checks: `scripts/verify_public_release.exs:99-146,307-350`. |
| 06 | T-131-43 | high | mitigate | CLOSED | Bounded record retains tag, runs, archive and verifier facts: `scripts/verify_public_release.exs:1126-1188`. |
| 06 | T-131-44 | high | mitigate | CLOSED | Secrets only in protected publishing steps: `.github/workflows/release.yml:53-77`; `.github/workflows/hexdocs.yml:114-126`. |
| 06 | T-131-45 | high | mitigate | CLOSED | Exact failed-history revalidation: `scripts/verify_public_release.exs:354-415,931-1077`. |
| 07 | T-131-52 | critical | mitigate | CLOSED | Required ancestor and exact candidate record: `131-RELEASE-CANDIDATE.md:2-10`. |
| 07 | T-131-53 | high | mitigate | CLOSED | Credential-free validation and secret-only actual publication: `.github/workflows/release.yml:12-77`. |
| 07 | T-131-54 | high | mitigate | CLOSED | Exact version/candidate/archive/HexDocs checks: `scripts/verify_public_release.exs:90-146,755-813`. |
| 07 | T-131-55 | high | mitigate | CLOSED | Immutable incident validation: `scripts/verify_public_release.exs:931-1077`. |
| 08 | T-131-52 | critical | mitigate | CLOSED | Required ancestor / exact candidate identity record: `131-RELEASE-CANDIDATE.md:2-10`. |
| 08 | T-131-54 | critical | mitigate | CLOSED | Detached HEAD and complete ref snapshots: `scripts/release_preflight_proof.exs:172-200`. |
| 08 | T-131-55 | critical | mitigate | CLOSED | Candidate proof accepts no audit bypass: `scripts/release_preflight_proof.exs:60-85`. |
| 08 | T-131-56 | high | mitigate | CLOSED | Candidate command/results and control-only delta: `131-RELEASE-CANDIDATE.md:51-57,82-88`. |
| 09 | T-131-56 | critical | mitigate | CLOSED | Exact human approval boundary: `131-RELEASE-CANDIDATE.md:82-88`. |
| 09 | T-131-57 | critical | mitigate | CLOSED | Repeat no-tag/ref-snapshot proof: `scripts/release_preflight_proof.exs:172-200`. |
| 09 | T-131-58 | critical | mitigate | CLOSED | Protected environment secret placement: `.github/workflows/release.yml:53-77`. |
| 09 | T-131-59 | critical | mitigate | CLOSED | Protected-main `HexDocs` dispatch binds the control SHA, detached candidate, peeled tag, workflow identity, and run ID; the verifier and clean-room consumer require the same complete binding and reject legacy package-only provenance: `.github/workflows/hexdocs.yml:79-150`; `scripts/verify_public_release.exs:793-871`; `scripts/phoenix_clean_room_proof.exs:60-110`. |
| 10 | T-131-60 | high | mitigate | CLOSED | Exact VERIFIED v1.3.4 prerequisite, Hex lock, no path/Git source: `scripts/phoenix_clean_room_proof.exs:60-110`. |
| 10 | T-131-61 | high | mitigate | CLOSED | Disposable root, host env clearing, source audits: `scripts/phoenix_clean_room_proof.exs:298-320,410-426,504-523`. |
| 10 | T-131-62 | high | mitigate | CLOSED | Allowlisted/redacted journey projection: `scripts/phoenix_clean_room_proof.exs:121-148,852-864`; negative fixture `test/scripts/phoenix_clean_room_proof_test.exs:371-405`. |
| 10 | T-131-63 | high | mitigate | CLOSED | Loopback-only bind, bounded attempts, server stop, cleanup: `scripts/phoenix_clean_room_proof.exs:584-597,657-819`. |
| 10 | T-131-64 | medium | mitigate | CLOSED | Bounded advisory versions/commands/results: `scripts/phoenix_clean_room_proof.exs:369-400`. |
| 11 | T-131-11-01 | high | mitigate | CLOSED | Exclusive no-replace link writer and synchronized race test: `scripts/adoption_snapshot.exs:149-161,268-314`; `test/docs_contract/adoption_evidence_contract_test.exs:121-159`. |
| 11 | T-131-11-02 | medium | mitigate | CLOSED | Cleanup on success/loser/error: `scripts/adoption_snapshot.exs:153-161,268-299`; `test/docs_contract/adoption_evidence_contract_test.exs:83-119`. |
| 11 | T-131-11-03 | low | accept | ACCEPTED | See Accepted Risks: explicit dated empty-state text remains sidecar-bound. |
| 12 | T-131-12-01 | high | mitigate | CLOSED | Immutable dispatch-input equality and trusted checkout: `.github/workflows/hexdocs.yml:80-103`. |
| 12 | T-131-12-02 | high | mitigate | CLOSED | Tag fetch/peel and detached candidate HEAD check: `.github/workflows/hexdocs.yml:86-95`. |
| 12 | T-131-12-03 | high | mitigate | CLOSED | Identity gate occurs before secret validation/publish: `.github/workflows/hexdocs.yml:80-126`. |
| 12 | T-131-12-04 | medium | mitigate | CLOSED | Same-version alternate candidate rejection: `test/scripts/public_release_verifier_test.exs:71-105`. |
| 13 | T-131-13-01 | high | mitigate | CLOSED | Synced exclusive temp plus no-replace hard-link: `scripts/verify_public_release.exs:1095-1124`; race test `test/scripts/public_release_verifier_test.exs:284-324`. |
| 13 | T-131-13-02 | high | mitigate | CLOSED | Full validation precedes exclusive commit: `scripts/verify_public_release.exs:32-40,90-156`. |
| 13 | T-131-13-03 | medium | mitigate | CLOSED | Unique temp and unconditional cleanup: `scripts/verify_public_release.exs:1095-1112`. |
| 13 | T-131-13-04 | medium | mitigate | CLOSED | Fresh byte-identical check-existing/no-rewrite behavior: `scripts/verify_public_release.exs:160-175`; `test/scripts/public_release_verifier_test.exs:252-265`. |

## Closed Finding

### T-131-59 — Public identity provenance is not carried into the authoritative prerequisite

**Severity:** critical  
**Disposition:** mitigate  
**Status:** CLOSED

The verifier requires a protected-main, separately checked-out candidate artifact and durable binding whose `control_sha` equals the authoritative HexDocs run `headSha`:

- `scripts/verify_public_release.exs:779-871`
- `.github/workflows/hexdocs.yml:68-103,128-150`

The regenerated `131-PUBLIC-PREREQUISITE.json` now records the current route:

- `hexdocs_provenance: "hexdocs_workflow_dispatch"`
- `hexdocs_event: "workflow_dispatch"`
- `hexdocs_name: "HexDocs"`
- complete `hexdocs_candidate_binding` for control SHA `f9b63246029396f76c443c5750aad42a3004081b`, candidate `f03c78bab54efe1cd1596d51cf3f28193232e2a3`, tag `v1.3.4`, and run `32898926521`

The clean-room gate requires that same `workflow_dispatch` provenance and complete binding, with no legacy fallback:

- `scripts/phoenix_clean_room_proof.exs:60-82`
- `test/scripts/phoenix_clean_room_proof_test.exs:314-333`

The authoritative prerequisite was emitted by the hardened verifier and proves the declared control-ref, artifact-identity, tag, and durable-binding chain. Deterministic tests reject legacy package-only provenance and malformed or mismatched bindings.

**Verified remediation:** Plans 131-16, 131-17, and 131-18 regenerated the authoritative prerequisite through the protected-main `HexDocs` `workflow_dispatch`, aligned both validators on the same binding contract, and refreshed the bounded journey evidence. The 2026-08-25 re-audit verified 84 focused tests with zero failures.

## Accepted Risks

| Threat ID | Rationale | Existing Controls |
|---|---|---|
| T-131-04 | Public source retrieval is intentionally a one-shot advisory operation. An unavailable source records `UNAVAILABLE`/`HOLD`; it is not converted to zero and cannot trigger a decision. A retry daemon or polling service is outside this library's scope. | Bounded CLI invocation and unavailable handling: `scripts/adoption_snapshot.exs:171-208`; non-triggering contract: `test/docs_contract/adoption_evidence_contract_test.exs:21-28`. |
| T-131-11-03 | A zero-candidate contributor result is a truthful, bounded observational state, not a candidate identity or authorization assertion. The ledger and sidecar bind that state to a date/source/digest. | Explicit sidecar/ledger binding: `ADOPTION.md:9,112`; empty-state and no-debt contracts: `test/docs_contract/adoption_evidence_contract_test.exs:161-197`. |

## Unregistered Flags

None. No Phase 131 execution summary contains a `## Threat Flags` section.

## Security Audit 2026-08-25

| Metric | Count |
|---|---:|
| Threats found | 54 |
| Mitigated/accepted | 53 |
| Blocking open | 1 |
| Non-blocking open | 0 |

At this initial audit point, phase advancement remained blocked pending T-131-59 remediation and re-audit.

## Security Audit 2026-08-25 — Re-audit

| Metric | Count |
|---|---:|
| Threats found | 54 |
| Mitigated/accepted | 54 |
| Blocking open | 0 |
| Non-blocking open | 0 |

T-131-59 is closed by the protected-main workflow-dispatch candidate binding, verifier/consumer parity, canonical prerequisite, and deterministic legacy-rejection coverage. Phase advancement is no longer security-blocked.
