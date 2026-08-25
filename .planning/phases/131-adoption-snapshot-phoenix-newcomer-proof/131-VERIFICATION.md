---
phase: 131-adoption-snapshot-phoenix-newcomer-proof
verified: 2026-08-25T15:43:00Z
status: gaps_found
score: 2/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: passed
  previous_score: 4/4
  gaps_closed: []
  gaps_remaining:
    - "The retained public prerequisite and clean-room consumer carry legacy package-only HexDocs provenance instead of the current trusted workflow-dispatch candidate binding."
  regressions:
    - "The previous passed report treated a local hardened workflow as sufficient although the authoritative prerequisite and remote protected main still use the legacy route."
gaps:
  - truth: "A newcomer in a clean Phoenix environment can follow public discovery material to install the public Rendro package, select the canonical Swiss/light Invoice, and customize it using the documented preset/configurator path without a repository checkout or warm dependency cache."
    status: partial
    reason: "The public-package, Swiss/light, and no-leakage mechanics are present, but the sole authoritative prerequisite is legacy package-only provenance that the current verifier rejects. The remote protected main does not contain the hardened workflow necessary to create a current trusted prerequisite."
    artifacts:
      - path: ".planning/phases/131-adoption-snapshot-phoenix-newcomer-proof/131-PUBLIC-PREREQUISITE.json"
        issue: "Records protected_release_publish/push/Release to Hex and no hexdocs_candidate_binding; it cannot be emitted by scripts/verify_public_release.exs:779-871."
      - path: "scripts/phoenix_clean_room_proof.exs"
        issue: "validate_prerequisite/1 accepts only the obsolete protected_release_publish route, so it authorizes a record outside the current verifier contract."
      - path: ".github/workflows/hexdocs.yml"
        issue: "The local hardened workflow is not published to origin/main; remote main lacks its candidate-input, immutable-SHA, and binding-artifact controls."
    missing:
      - "Publish the trusted HexDocs control workflow to protected remote main. (external authority/action)"
      - "Run a successful protected-main HexDocs workflow_dispatch for the sealed v1.3.4 candidate and retain its hexdocs-candidate-binding artifact. (external authority/action)"
      - "Regenerate 131-PUBLIC-PREREQUISITE.json through the current verifier using that run and binding."
      - "Update the clean-room gate and tests to require hexdocs_workflow_dispatch plus the durable candidate binding, then rerun the proof and retain regenerated journey evidence."
  - truth: "That clean Phoenix application responds through the optional Phoenix adapter with a successful application/pdf response whose bytes begin %PDF-, and the recorded journey states the exact versions, commands, results, and any repairs limited to existing handoffs."
    status: partial
    reason: "The retained ConnCase and loopback facts show 200/application/pdf/%PDF-, but the record was accepted under the obsolete prerequisite route. Under the current verifier contract the journey is not authoritatively bound to a trusted protected-main HexDocs dispatch and candidate artifact."
    artifacts:
      - path: "priv/journey_evidence/phoenix_clean_room_1.3.4.json"
        issue: "Contains successful bounded HTTP observations, but its prerequisite_sha points to a prerequisite that lacks current workflow-dispatch provenance and durable binding."
      - path: "test/scripts/phoenix_clean_room_proof_test.exs"
        issue: "The accepted fixture requires protected_release_publish and explicitly rejects workflow_dispatch at lines 314-333."
    missing:
      - "After the authoritative prerequisite and consumer contract are updated, rerun the clean-room proof so the retained response evidence is bound to the new provenance. (external public package/Docs state is required)"
---

# Phase 131: Adoption Snapshot & Phoenix Newcomer Proof Verification Report

**Phase Goal:** Maintainers have a dated, source-backed adoption decision and newcomers can independently go from Rendro’s public discovery path to a customized, verified Swiss/light Invoice PDF in a clean Phoenix application.
**Verified:** 2026-08-25T15:43:00Z
**Status:** gaps_found
**Re-verification:** Yes — post-security-audit re-verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A dated adoption-review entry contains public Hex source/raw totals and qualifying demand/contributor reviews; unavailable evidence is not counted as zero. | ✓ VERIFIED | `ADOPTION.md` links `priv/adoption_evidence/2026-08-21.json`; the existing adoption contracts cover the bounded source projection and unavailable-as-nontriggering behavior. |
| 2 | The adoption ledger records family and conjunctive composite HOLD/ACCUMULATING/TRIGGER decisions without outreach, telemetry, or polling. | ✓ VERIFIED | `ADOPTION.md` and `scripts/adoption_snapshot.exs` retain the pull-based decision model and a dated `HOLD` record. |
| 3 | A clean Phoenix newcomer can use public discovery to install, select, and customize Swiss/light Invoice without checkout or warm-cache leakage. | ✗ FAILED | The mechanics are implemented, but the clean-room authorization chain is stale: the authoritative prerequisite uses `protected_release_publish` while the current verifier only accepts `hexdocs_workflow_dispatch` with a durable candidate binding. |
| 4 | The clean app serves adapter-generated PDF bytes and retains exact, bounded journey evidence. | ✗ FAILED | The retained JSON has 200/PDF facts, but this roadmap criterion includes the recorded journey. Its authorizing prerequisite is outside the current trusted provenance contract, so the current record cannot certify the journey. |

**Score:** 2/4 truths verified (0 present, behavior-unverified)

## Contradiction Resolution

This is a real contract contradiction, independently confirmed from current source—not merely an audit assertion.

- `scripts/verify_public_release.exs:793-871` accepts only `hexdocs_workflow_dispatch`, requires `workflow_dispatch`/`HexDocs`, a protected-main control reference, and a binding whose `control_sha` equals the authoritative workflow run `headSha`.
- The authoritative [131-PUBLIC-PREREQUISITE.json](/Users/jon/projects/rendro/.planning/phases/131-adoption-snapshot-phoenix-newcomer-proof/131-PUBLIC-PREREQUISITE.json) instead says `protected_release_publish`, `push`, and `Release to Hex`, and contains no `hexdocs_candidate_binding`.
- `scripts/phoenix_clean_room_proof.exs:60-84` accepts precisely that legacy record; [phoenix_clean_room_proof_test.exs](/Users/jon/projects/rendro/test/scripts/phoenix_clean_room_proof_test.exs:314) confirms the obsolete `workflow_dispatch` record is rejected.
- The focused verifier test deliberately rejects the legacy route, while the focused clean-room test accepts it. Both tests passing proves the incompatibility; it does not close it.
- Read-only remote inspection shows `origin/main` at `6c56d390…`, and its HexDocs workflow lacks the local hardened workflow’s candidate inputs, immutable SHA predicate, protected-ref condition, and `hexdocs-candidate-binding` upload. A protected-main run of that hardened workflow therefore cannot yet have generated the required record.

Accordingly, **JOURNEY-03**, **JOURNEY-04**, and roadmap success criterion 4 are not achieved under truthful current contracts. JOURNEY-01 and JOURNEY-02 are likewise blocked because the claimed clean public path depends on the same invalid prerequisite; their install/customization mechanics remain present but not authoritatively certified.

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `scripts/adoption_snapshot.exs` and dated adoption sidecar | Bounded source-backed decision | ✓ VERIFIED | Substantive exclusive writer and bounded evidence contract remain wired to `ADOPTION.md`. |
| `.github/workflows/hexdocs.yml` | Protected workflow-dispatch candidate binding | ⚠️ PARTIAL | Local workflow is substantive and records binding after publish, but the remote protected control plane lacks these controls. |
| `scripts/verify_public_release.exs` | Current trusted prerequisite verifier | ✓ VERIFIED | Its validation is substantive and fail-closed for legacy provenance. |
| `131-PUBLIC-PREREQUISITE.json` | Current verifier-emitted authoritative record | ✗ STALE / UNTRUSTED | Its legacy provenance and absent binding fail the current verifier’s required shape. |
| `scripts/phoenix_clean_room_proof.exs` | Clean-room consumer of the authoritative prerequisite | ✗ WIRED TO LEGACY CONTRACT | It wires successful journey execution to `protected_release_publish`, rather than the verifier’s current `hexdocs_workflow_dispatch` binding. |
| `priv/journey_evidence/phoenix_clean_room_1.3.4.json` | Bounded, provenance-authorized 200/PDF journey evidence | ✗ STALE AUTHORIZATION | The response facts are substantive, but their prerequisite hash identifies the incompatible record. |
| `scripts/verify_hexdocs_release_identity.sh` | Plan-12 local identity predicate | ⚠️ MISSING | Declared by `131-12-PLAN.md`, absent from the codebase. The workflow inlines an identity predicate, so this is not the root goal failure but is a plan-artifact deviation. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| local HexDocs workflow | sealed candidate | immutable SHA, peeled tag, detached checkout before secret use | ✓ WIRED LOCALLY | `.github/workflows/hexdocs.yml:68-150` contains the intended predicate and artifact upload. |
| protected remote main | local hardened HexDocs workflow | published control workflow | ✗ NOT WIRED | `git show origin/main:.github/workflows/hexdocs.yml` exposes only the legacy dispatch surface; hardened markers are absent. |
| current public verifier | authoritative prerequisite | workflow-dispatch facts plus candidate binding | ✗ NOT WIRED | Current verifier rejects the committed record’s legacy provenance. |
| authoritative prerequisite | clean-room journey | `validate_prerequisite/1` | ✗ WRONG CONTRACT | Consumer accepts legacy `protected_release_publish`; test asserts that it rejects `workflow_dispatch`. |
| clean-room response facts | retained journey evidence | bounded ConnCase and loopback projection | ⚠️ DATA PRESENT, AUTHORIZATION INVALID | JSON contains two valid 200/application/pdf/%PDF- observations, but the upstream prerequisite is invalid under current contract. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| adoption ledger | dated decision facts | packaged public-source projection | Yes | ✓ FLOWING |
| public prerequisite | HexDocs provenance | legacy release run facts | No—does not satisfy current verifier’s workflow-dispatch/binding schema | ✗ STATIC LEGACY |
| clean-room journey JSON | prerequisite hash and HTTP facts | retained isolated run | HTTP facts: yes; trusted upstream provenance: no | ✗ HOLLOW AUTHORIZATION |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Legacy release provenance is rejected by the hardened verifier | `mix test test/scripts/public_release_verifier_test.exs:57` | passed | ✓ PASS |
| Clean-room gate accepts only the legacy prerequisite and rejects workflow-dispatch provenance | `mix test test/scripts/phoenix_clean_room_proof_test.exs:314` | passed | ✓ PASS — proves incompatible consumer contract |
| Local HexDocs identity workflow contract is structurally present | `mix test test/docs_contract/launch_execution_claims_test.exs:125` | passed | ✓ PASS (local only) |
| Combined focused suite | `mix test test/scripts/public_release_verifier_test.exs test/scripts/phoenix_clean_room_proof_test.exs test/docs_contract/launch_execution_claims_test.exs test/docs_contract/phoenix_newcomer_contract_test.exs --max-failures 1` | 34 tests before an unrelated cleanup-root failure | ✗ FAIL — `PhoenixCleanRoomProofTest` at line 94 observed `:unsafe_or_nonempty_root`; this does not weaken the provenance blocker, but must be rechecked during remediation. |

### Probe Execution

Step 7c: SKIPPED — no Phase 131 probe scripts were declared or discovered.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| SIGNAL-02 | 131-01, 131-11 | Dated Hex download snapshot with source and raw totals | ✓ SATISFIED | Dated sidecar and adoption contracts remain present and wired. |
| SIGNAL-03 | 131-01, 131-11 | Qualifying demand issue review | ✓ SATISFIED | Bounded review and decision remain recorded. |
| SIGNAL-04 | 131-01, 131-11 | Qualifying non-maintainer contribution review | ✓ SATISFIED | Bounded review and decision remain recorded. |
| SIGNAL-05 | 131-01, 131-11 | Source-backed composite decision; unavailable is not zero | ✓ SATISFIED | Ledger and snapshot preserve separate unavailable/HOLD behavior. |
| JOURNEY-01 | 131-02–10, 131-12 | Clean public package install without checkout/cache | ✗ BLOCKED | Install checks exist, but the authoritative journey prerequisite cannot be produced/accepted under the current provenance contract. |
| JOURNEY-02 | 131-02–10, 131-12 | Discover/select/customize Swiss/light Invoice | ✗ BLOCKED | Documentation and configurator mechanics exist, but the public journey’s trust chain is invalid. |
| JOURNEY-03 | 131-10 | Optional Phoenix adapter serves valid PDF | ✗ BLOCKED | Retained response facts exist but are not bound to a current trusted prerequisite. |
| JOURNEY-04 | 131-04–10, 131-13 | Exact versions, commands, results, and bounded repairs | ✗ BLOCKED | Journey evidence exists, but its prerequisite lacks the verifier-required durable binding. |

All eight requirements are claimed by phase plans; none are orphaned. No later milestone phase specifically addresses this provenance migration, so no gap is deferred.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `scripts/phoenix_clean_room_proof.exs` | 60-84 | Legacy-only prerequisite predicate | 🛑 BLOCKER | Allows a record current verifier refuses, disconnecting the journey from trusted public provenance. |
| `test/scripts/phoenix_clean_room_proof_test.exs` | 314-333 | Test locks legacy acceptance and dispatch rejection | 🛑 BLOCKER | Passing coverage protects the wrong contract. |
| `131-PUBLIC-PREREQUISITE.json` | provenance fields | Legacy push/package provenance; no candidate binding | 🛑 BLOCKER | Cannot serve as the current authoritative journey prerequisite. |
| `scripts/verify_hexdocs_release_identity.sh` | — | Missing planned artifact | ⚠️ WARNING | Local workflow has inline logic; restore shared predicate or correct the plan/contract deliberately. |

## Gaps Summary

One root-cause blocker invalidates the public-journey evidence chain: migration to the hardened HexDocs workflow was completed only locally and in the verifier, not in the authoritative remote workflow, prerequisite, or clean-room consumer.

Required sequence:

1. Publish the trusted HexDocs control workflow to protected remote `main` **(requires repository/protected-branch authority)**.
2. Run successful protected-main `HexDocs` `workflow_dispatch` for sealed candidate `f03c78bab54efe1cd1596d51cf3f28193232e2a3` / `v1.3.4` and retain `hexdocs-candidate-binding` **(requires workflow/environment/HexDocs publishing authority)**.
3. Regenerate `131-PUBLIC-PREREQUISITE.json` through the current verifier from that authoritative run and binding.
4. Change `PhoenixCleanRoomProof.validate_prerequisite/1` and its tests to require `hexdocs_workflow_dispatch` plus the complete durable binding; do not retain a legacy fallback.
5. Rerun the clean-room proof and retain replacement journey evidence bound to the regenerated prerequisite **(requires live public package/Docs availability)**.
6. Re-run focused contracts, including the cleanup-root failure observed in the combined suite, then repeat security and phase verification.

This is an **Escalation Gate**: steps 1–2 and the live evidence in step 5 require external repository, workflow, and publishing authority. Automated code changes alone cannot truthfully close the gap.

_Verified: 2026-08-25T15:43:00Z_
_Verifier: the agent (gsd-verifier)_
