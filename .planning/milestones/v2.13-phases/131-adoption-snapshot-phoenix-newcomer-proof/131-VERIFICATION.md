---
phase: 131-adoption-snapshot-phoenix-newcomer-proof
verified: 2026-08-25T22:02:10Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 4/5
  gaps_closed:
    - "131-VALIDATION.md now publishes the current SHA-256 identities of both retained journey artifacts."
    - "A deterministic docs-contract test recomputes both hashes and prevents future evidence/validation drift."
  gaps_remaining: []
  regressions: []
---

# Phase 131: Adoption Snapshot & Phoenix Newcomer Proof Verification Report

**Phase Goal:** Maintainers have a dated, source-backed adoption decision and newcomers can independently go from Rendro’s public discovery path to a customized, verified Swiss/light Invoice PDF in a clean Phoenix application.
**Verified:** 2026-08-25T22:02:10Z
**Status:** passed
**Re-verification:** Yes — all prior gaps closed

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A dated adoption-review entry contains public Hex source/raw totals and qualifying demand/contributor reviews; unavailable evidence is not counted as zero. | ✓ VERIFIED | `ADOPTION.md` binds the 2026-08-21 review to `priv/adoption_evidence/2026-08-21.json`; the sidecar records Hex totals, source URLs/digests, bounded demand/contributor reviews, and `AVAILABLE` retrieval states. |
| 2 | The adoption ledger records family and conjunctive `HOLD`/`ACCUMULATING`/`TRIGGER` decisions without outreach, telemetry, or polling. | ✓ VERIFIED | The sidecar records demand `HOLD`, downloads `ACCUMULATING`, contributor `HOLD`, and composite `HOLD` under the minimum-family rule; `ADOPTION.md` retains the pull-based policy. |
| 3 | A newcomer can use public discovery to install public Rendro, select the canonical Swiss/light Invoice, and customize it without checkout or warm-cache leakage. | ✓ VERIFIED | Both prerequisite validators accept the current record; retained isolated evidence records exact public Hex Rendro 1.3.4, source audit `public_hex_exact_1.3.4`, and Invoice / Swiss / `#2C6BED` / light selection. Public Hex currently returns v1.3.4. |
| 4 | The clean Phoenix app serves adapter-generated PDF bytes and retains exact bounded journey facts. | ✓ VERIFIED | The journey JSON has matching ConnCase/loopback `200`, `application/pdf`, attachment `invoice.pdf`, nonempty, PDF-magic observations; transcript names `Rendro.Adapters.Phoenix`. Focused tests exercise response and error/timeout paths. |
| 5 | The validation record provides current exact identities for the retained journey evidence. | ✓ VERIFIED | `131-VALIDATION.md` publishes JSON `a59706f8…` and transcript `971539bd…`; direct SHA-256 calculation matches both, and the docs contract recomputes them. |

**Score:** 5/5 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `scripts/adoption_snapshot.exs` + dated sidecar | Source-backed adoption decision | ✓ VERIFIED | Substantive dated projection wired to `ADOPTION.md`; adoption contracts pass. |
| `.github/workflows/hexdocs.yml` | Protected-main workflow-dispatch candidate binding | ✓ VERIFIED | Remote `origin/main` contains protected dispatch, exact tag/candidate checks, detached checkout, and binding upload. |
| `131-PUBLIC-PREREQUISITE.json` | Current verifier-emitted authoritative record | ✓ VERIFIED | Both validators accept its binding of candidate `f03c78b…`, control `f9b632…`, run `32898926521`, and `v1.3.4`. |
| `scripts/phoenix_clean_room_proof.exs` | Fail-closed clean-room consumer | ✓ VERIFIED | Accepts only current workflow-dispatch provenance and exact durable binding; legacy/mutated paths are rejected by tests. |
| `priv/journey_evidence/phoenix_clean_room_1.3.4.json` and `.md` | Bounded dual-HTTP journey evidence | ✓ VERIFIED | Current hashes are `a59706f8…` and `971539bd…`; JSON prerequisite SHA matches the canonical prerequisite. |
| `131-VALIDATION.md` | Current validation/evidence identities | ✓ VERIFIED | Lines 205–208 match both retained files and are protected by the deterministic docs contract. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| protected remote main | HexDocs dispatch | hardened control workflow | ✓ WIRED | `origin/main` is `f9b63246029396f76c443c5750aad42a3004081b`, matching the prerequisite control SHA. |
| GitHub run | public prerequisite | workflow-dispatch metadata + candidate binding | ✓ WIRED | Public API reports run `32898926521` completed/successful, `workflow_dispatch`, `HexDocs`, `main`, and head SHA `f9b632…`, all matching the record. |
| public verifier | clean-room consumer | shared canonical fixture | ✓ WIRED | Focused suite proves shared acceptance and rejection of legacy/malformed mutations. |
| prerequisite | clean-room journey | prerequisite SHA before isolated dependency operation | ✓ WIRED | Journey references current prerequisite hash `eba7b500…`. |
| journey evidence | validation identity record | SHA-256 entries + deterministic contract | ✓ WIRED | Direct hashes and named docs-contract test agree. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| adoption ledger | dated decisions/raw totals | immutable adoption sidecar | Yes | ✓ FLOWING |
| public prerequisite | release, HexDocs run, candidate binding | GitHub/Hex facts validated by `Rendro.PublicReleaseVerifier` | Yes | ✓ FLOWING |
| clean-room evidence | prerequisite hash, exact versions, dual HTTP facts | isolated public-Hex Phoenix run | Yes | ✓ FLOWING |
| validation identity section | journey JSON/transcript hashes | retained evidence files | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Validation hashes are recomputed from retained evidence | `mix test test/docs_contract/phoenix_newcomer_contract_test.exs:107 --max-failures 1` | 1 test, 0 failures | ✓ PASS |
| Phase 131 deterministic contracts | Focused verifier, clean-room, workflow, discovery, adoption, and guardrail suite | 107 tests, 0 failures | ✓ PASS |
| Authoritative HexDocs identity | GitHub Actions run `32898926521` API query | success; dispatch; `HexDocs`; main; `f9b632…` | ✓ PASS |
| Public package availability | Hex release API v1.3.4 query | returned v1.3.4, not retired | ✓ PASS |
| Full deterministic CI | `mix ci.fast` | Fresh evidence: 12 doctests, 8 properties, 1917 tests, 0 failures (28 excluded), docs, Credo, Dialyzer | ✓ PASS |

### Probe Execution

Step 7c: SKIPPED — no Phase 131 `probe-*.sh` scripts are declared or discovered. Applicable recurring facts are covered by deterministic tests/CI; public package and workflow facts were checked directly as bounded advisory evidence.

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| SIGNAL-02 | 131-01, 131-11 | Dated Hex download snapshot with source and raw totals | ✓ SATISFIED | Current dated sidecar/ledger and passing adoption contracts. |
| SIGNAL-03 | 131-01, 131-11 | Qualifying demand issue review | ✓ SATISFIED | Bounded issue review and explicit availability/zero distinction. |
| SIGNAL-04 | 131-01, 131-11 | Qualifying non-maintainer contribution review | ✓ SATISFIED | Bounded merged-PR review and exclusions. |
| SIGNAL-05 | 131-01, 131-11 | Source-backed family/composite decision; unavailable is not zero | ✓ SATISFIED | Family and weakest-link composite decisions are recorded. |
| JOURNEY-01 | 131-02–10, 131-12, 131-14, 131-16–18 | Clean public package install without checkout/cache | ✓ SATISFIED | Public release, trusted prerequisite, isolated source-audit contracts, and retained external evidence agree. |
| JOURNEY-02 | 131-02–10, 131-12, 131-14, 131-16–18 | Discover/select/customize Swiss/light Invoice | ✓ SATISFIED | Discovery contracts and generated Invoice/Swiss/#2C6BED/light evidence pass. |
| JOURNEY-03 | 131-10, 131-16, 131-17 | Optional Phoenix adapter serves valid PDF | ✓ SATISFIED | Dual HTTP facts and response/error contracts pass. |
| JOURNEY-04 | 131-04–10, 131-13–18 | Exact versions, commands, results, bounded repairs | ✓ SATISFIED | Current journey, prerequisite, validation identities, and anti-drift contract agree. |

All eight requirement IDs declared by the 17 plan frontmatters are accounted for; none are orphaned.

### Anti-Patterns Found

None. No unresolved `TBD`, `FIXME`, or `XXX` markers were found in the re-verified closure files. The public/external clean-room lane remains explicitly advisory and separate from deterministic required CI checks.

---

_Verified: 2026-08-25T22:02:10Z_
_Verifier: the agent (gsd-verifier)_
