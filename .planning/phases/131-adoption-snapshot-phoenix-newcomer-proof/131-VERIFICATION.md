---
phase: 131-adoption-snapshot-phoenix-newcomer-proof
verified: 2026-08-25T14:10:00Z
status: gaps_found
score: 2/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "A dated adoption snapshot can be written exactly once under concurrent execution, leaving one complete authoritative target and no temporary artifacts."
    status: failed
    reason: "The phase's own parallel-writer ExUnit contract fails twice: it observed zero successful writers where exactly one is required. Direct reproduction also leaves losing .tmp files behind."
    artifacts:
      - path: "scripts/adoption_snapshot.exs"
        issue: "write_snapshot/2 does not reliably meet its concurrent exclusive-write/cleanup contract in the test environment."
      - path: "test/docs_contract/adoption_evidence_contract_test.exs"
        issue: "The test at line 68 currently fails (0 successful writers, expected 1)."
    missing:
      - "Make concurrent writing deterministically yield one :ok, target_exists for all losers, and remove loser temporary files; add/retain a passing parallel regression."
  - truth: "The approved exact v1.3.4 candidate is the only commit that can publish HexDocs for the recovery release."
    status: failed
    reason: "The workflow accepts dispatcher-controlled candidate_commit_sha and release_ref values. It compares the input only to github.sha, not to the sealed approved SHA or peeled v1.3.4 tag, so another valid 1.3.4 commit can publish docs."
    artifacts:
      - path: ".github/workflows/hexdocs.yml"
        issue: "publish-hexdocs condition/identity check at lines 66-86 lacks an immutable approved-SHA and peeled-tag binding."
    missing:
      - "Bind workflow dispatch and checkout to immutable release evidence and add a negative contract test for a different valid 1.3.4 commit."
  - truth: "The named public verifier atomically writes a VERIFIED prerequisite without overwriting an authoritative target."
    status: failed
    reason: "ensure_safe_output/1 performs a check-then-act existence test; File.rename/2 can replace a target created before the rename. The documented no-overwrite/single-writer contract is therefore false."
    artifacts:
      - path: "scripts/verify_public_release.exs"
        issue: "Lines 1033-1049 use File.exists?/1 followed by File.rename/2, permitting a concurrent target overwrite."
    missing:
      - "Use an exclusive no-replace publish operation (for example a synced temp file plus :file.make_link/2) and test two competing writers."
  - truth: "Phase-modified adoption ledger contains no untracked completion-debt markers."
    status: failed
    reason: "ADOPTION.md, a Phase 131 artifact, contains unreferenced TBD markers at lines 81 and 87."
    artifacts:
      - path: "ADOPTION.md"
        issue: "Unreferenced TBD markers remain in the contributor/rejected-contributor tables."
    missing:
      - "Replace the markers with truthful empty-state text or attach a formal follow-up reference."
---

# Phase 131: Adoption Snapshot & Phoenix Newcomer Proof Verification Report

**Phase Goal:** Maintainers have a dated, source-backed adoption decision and newcomers can independently go from Rendro’s public discovery path to a customized, verified Swiss/light Invoice PDF in a clean Phoenix application.
**Verified:** 2026-08-25T14:10:00Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A dated, source-backed adoption-review entry is readable. | ✓ VERIFIED | `ADOPTION.md` links the packaged `2026-08-21.json`; sidecar records Hex query/totals plus bounded issue and merged-PR reviews, with all three retrieval statuses AVAILABLE. |
| 2 | Ledger exposes family and composite HOLD/ACCUMULATING/TRIGGER decisions without treating unavailable evidence as zero. | ✓ VERIFIED | Sidecar records demand HOLD, downloads ACCUMULATING, contributor HOLD, and composite HOLD/minimum-family rule; `unavailable_family/2` has no raw totals and is non-triggerable. |
| 3 | Public discovery can be trusted to select the approved exact public package/docs source and customize the Swiss/light Invoice without checkout/cache leakage. | ✗ FAILED | The clean-room harness/evidence are substantive, but HexDocs publishing is not actually bound to the sealed candidate; CR-01 invalidates the phase's candidate-bound public-docs prerequisite. |
| 4 | The recorded clean Phoenix journey has exact versions/commands and a successful adapter PDF response. | ✗ FAILED | The retained evidence contains both 200/application/pdf/%PDF- observations, but the prerequisite writer's check-then-rename race invalidates its claimed atomic, no-overwrite authoritative-record guarantee (CR-02). |

**Score:** 2/4 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `scripts/adoption_snapshot.exs` | Bounded one-shot observer and exclusive writer | ✗ FAILED | Exists and is substantive; concurrent write test fails and losing temporary files remain in direct reproduction. |
| `priv/adoption_evidence/2026-08-21.json` | Immutable dated adoption snapshot | ✓ VERIFIED | Bounded schema, source/query/raw totals or candidate counts, and matching HOLD composite. |
| `ADOPTION.md` | Human-readable adoption decision | ⚠️ WARNING | Correctly links sidecar and decision; unreferenced `TBD` debt markers at lines 81 and 87 trip the debt-marker gate. |
| `.github/workflows/hexdocs.yml` | Candidate-bound protected docs publication | ✗ FAILED | Workflow is substantive but not immutably candidate/tag bound. |
| `scripts/verify_public_release.exs` | No-overwrite atomic public prerequisite writer | ✗ FAILED | Writer exists and validates facts but its final write can overwrite a concurrently created target. |
| `scripts/phoenix_clean_room_proof.exs` | Isolated exact-public Phoenix proof | ✓ VERIFIED | Checks no path/Git/workspace source, generates app-owned Invoice/Swiss/light document, invokes `Rendro.Adapters.Phoenix.render_pdf/3`, and records bounded facts. |
| `priv/journey_evidence/phoenix_clean_room_1.3.4.json` | Bounded dual-HTTP evidence | ✓ VERIFIED | Exact 1.3.4, candidate SHA, versions, commands, source audit, ConnCase/loopback 200/PDF facts, and cleanup are present; no payload/path/PID fields. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `ADOPTION.md` | adoption sidecar | dated relative link and matching decisions | ✓ WIRED | Link and exact 2026-08-21 HOLD decision match. |
| adoption writer | dated output | exclusive write | ✗ NOT WIRED | Parallel-writer contract fails; the output link is not reliably exclusive/clean. |
| protected Hex release | HexDocs dispatch | immutable candidate binding | ✗ NOT WIRED | Input equals dispatch SHA only; workflow never verifies approved SHA or peeled tag. |
| public verifier | prerequisite JSON | exclusive no-overwrite write | ✗ NOT WIRED | `File.rename/2` replaces a race-created target. |
| clean-room generated controller | Phoenix adapter | `render_pdf/3` response | ✓ WIRED | Generated controller template calls the adapter and the evidence records both HTTP probes. |
| loopback facts | journey JSON | allowlisted projection | ✓ WIRED | Harness projects only bounded facts; retained JSON has status/content type/filename/magic/cleanup rather than body/process data. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `ADOPTION.md` | family/composite decisions | `priv/adoption_evidence/2026-08-21.json` | Actual retained Hex and GitHub response projections | ✓ FLOWING |
| clean-room journey JSON | ConnCase and loopback facts | generated consumer plus bounded loopback probe | Actual recorded 200/PDF/magic facts | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Phase adoption, workflow, public-verifier, and Phoenix deterministic contracts | `mix test test/docs_contract/adoption_evidence_contract_test.exs test/docs_contract/phoenix_newcomer_contract_test.exs test/scripts/phoenix_clean_room_proof_test.exs test/scripts/public_release_verifier_test.exs test/guardrails/required_checks_contract_test.exs --max-failures 1` | Failed in 0.3s: parallel writer expected 1 success, got 0. | ✗ FAIL |
| Adoption parallel writer regression | `mix test test/docs_contract/adoption_evidence_contract_test.exs:68 --trace` | Failed again: expected 1 success, got 0. | ✗ FAIL |
| Independent direct parallel writer reproduction | `mix run -e ...Task.async_stream(write_snapshot/2)...` | One direct run obtained one target but left three losing `.tmp-*` artifacts. | ✗ FAIL |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| SIGNAL-02 | 131-01 | Dated Hex download snapshot with source and raw totals | ✓ SATISFIED | Sidecar has Hex API source/query and `all: 3149`, `week: 182`. |
| SIGNAL-03 | 131-01 | Qualifying demand issue review | ✓ SATISFIED | Bounded GitHub issue query and AVAILABLE zero-candidate HOLD record. |
| SIGNAL-04 | 131-01 | Qualifying non-maintainer contribution review | ✓ SATISFIED | Bounded merged-PR query and AVAILABLE zero-candidate HOLD record. |
| SIGNAL-05 | 131-01 | Source-backed family/composite decision; unavailable is not zero | ✓ SATISFIED | Ledger and sidecar distinguish retrieval from decisions and record weakest-link HOLD. |
| JOURNEY-01 | 131-02–10 | Install public package cleanly without checkout/cache | ⚠️ BLOCKED | Harness/evidence prove the recorded run, but CR-01 leaves the public docs publication path mutable rather than exact-candidate bound. |
| JOURNEY-02 | 131-02–10 | Discover/select/customize Swiss/light Invoice | ⚠️ BLOCKED | Formatter/harness source is present, but CR-01 invalidates claimed immutable public-docs provenance. |
| JOURNEY-03 | 131-10 | Phoenix adapter returns valid PDF | ✓ SATISFIED | ConnCase and loopback evidence both show 200, `application/pdf`, attachment, nonempty body, `%PDF-`. |
| JOURNEY-04 | 131-04–10 | Record exact versions, commands, results, and bounded repairs | ⚠️ BLOCKED | Values are retained, but CR-02 means the asserted no-overwrite authoritative prerequisite record is not race-safe. |

All eight phase requirements appear in PLAN frontmatter; none are orphaned.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `ADOPTION.md` | 81 | `TBD` | 🛑 BLOCKER | Phase-modified artifact contains an unreferenced debt marker. |
| `ADOPTION.md` | 87 | `TBD` | 🛑 BLOCKER | Phase-modified artifact contains an unreferenced debt marker. |
| `scripts/adoption_snapshot.exs` | 45-46 | Shape-only date regex | ⚠️ WARNING | Impossible calendar dates can be published as authoritative review dates; current `2026-08-21` sidecar itself is valid. |

## Disconfirmation Pass

- Partial requirement: JOURNEY-02 has a strong clean-room harness, but the workflow that makes its public-docs source authoritative accepts untrusted dispatch inputs.
- Misleading test: `public_release_verifier_test.exs` proves sequential overwrite refusal, not a competing-writer race; it therefore passes while the promised single-writer behavior is false.
- Uncovered error path: adoption date validation has no `Date.from_iso8601/1` check or impossible-date test.

## Gaps Summary

The static adoption decision and recorded Phoenix response evidence exist, but the phase’s trust boundary is not achieved. A concurrent adoption write currently fails its regression contract and leaks temp files. More importantly, the release/docs pipeline does not enforce its claimed immutable-candidate provenance, and the public prerequisite writer can overwrite an authoritative record in a race. No later milestone phase exists to defer these gaps to.

_Verified: 2026-08-25T14:10:00Z_
_Verifier: the agent (gsd-verifier)_
