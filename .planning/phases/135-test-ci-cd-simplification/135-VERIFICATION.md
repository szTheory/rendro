---
phase: 135-test-ci-cd-simplification
verified: 2026-08-27T21:46:09Z
status: passed
score: 13/13 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 12/13
  gaps_closed:
    - "Phase 135 terminal validation now passes the active governance/UAT gate."
  gaps_remaining: []
  regressions: []
---

# Phase 135: Test & CI/CD Simplification Verification Report

**Phase Goal:** Rendro's tests and automation are easier to understand and maintain without weakening behavior coverage, trust boundaries, or the authoritative CI contract.
**Verified:** 2026-08-27T21:46:09Z
**Status:** passed
**Re-verification:** Yes — after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Consolidated recipe coverage is traceable to preserved behavior, failure mode, oracle, negative control, and focused command. | ✓ VERIFIED | `135-test-inventory.md` has exactly the two ordered recipe rows; the inventory contract rejects missing, reordered, extra, and invalid rows. |
| 2 | The retained Payslip owner detects the broken fallback contract while distinct options, byte, and typography contracts remain. | ✓ VERIFIED | `themed_render_smoke_test.exs:72-117` asserts the exact `{:unknown_text_font, :payslip_sans}` result after the one-field registry mutation; focused recipe tests passed. |
| 3 | The evidence bundle is schema-v1, role-closed, count/hash/path/SHA fail-closed, and keeps review approval out of candidate evidence. | ✓ VERIFIED | `CatalogEvidenceBundle.build/4`/`validate/2` enforce literal role counts (32/12/4/12/32), SHA/HEAD equality, regular safe payloads, checksums, and authority fields; negative-control tests passed. |
| 4 | Route parity normalizes the four legacy/generic mappings, requires route-specific role/cardinality/hash facts, and independently validates per-side provenance. | ✓ VERIFIED | `CatalogEvidenceParity` has four explicit extractors and schema-v2 sealed-record validation; tests reject malformed/misbound provenance, scalar roles, duplicate IDs, changed hashes, and cardinality drift. |
| 5 | `Catalog Evidence` is a purpose-named manual, read-only, exact-SHA workflow with pinned renderer/actions and bounded artifact-only control isolation. | ✓ VERIFIED | `.github/workflows/catalog-evidence.yml` is `workflow_dispatch` only, validates 40-lowercase-hex input, uses two credential-free SHA-pinned checkouts on separate jobs/runners, validates PDFium, bounds the handoff to five regular files/20 MiB, and produces the sole 30-day evidence bundle. |
| 6 | The four Phase 126/127/130 routes proved parity on one candidate SHA before retirement. | ✓ VERIFIED | The sealed record and 16-column inventory bind all rows to `643e407508d744d11b919a8af929855d06e608d4`; live GitHub queries confirm all six distinct runs succeeded and artifact API digests match all eight recorded artifacts. |
| 7 | Legacy routes are absent only after the matched matrix, while ordinary CI retains deterministic/proof/advisory separation and sole `ci-success`. | ✓ VERIFIED | Cutover `8a2292f` changes only `ci.yml` and the route-absence contract; guardrails verify the unchanged trigger set, required `ci-success` needs, no generic-evidence dependency, lane boundaries, read-only permissions, and pinned actions. |
| 8 | Current workflow-adjacent documentation supports dispatch, retrieval, validation, authority limits, local reproduction, and recovery without phase-plan consultation. | ✓ VERIFIED | `CATALOG-EVIDENCE.md`, its docs contract, `scripts/README.md` link, and `scripts/verify_docs.exs` lane all passed. |
| 9 | TEST-01 is satisfied. | ✓ VERIFIED | Inventory rows, fail-first mutation controls, and their focused contracts passed. |
| 10 | TEST-02 is satisfied. | ✓ VERIFIED | Only the evidence-backed duplicate was removed; focused replacement, opts, typography, and deterministic-byte owners passed. |
| 11 | CI-01 through CI-05 are satisfied. | ✓ VERIFIED | Workflow, bundle, parity record, CI topology, trust-boundary tests, current runbook, and live remote evidence establish each requirement. |
| 12 | Remote payload parity does not claim visual approval or Phase 136 visual quality. | ✓ VERIFIED | Bundle authority fields and current runbook explicitly limit evidence to advisory transport; Phase 136 is named as visual-review owner. |
| 13 | The terminal Phase 135 validation artifact passes the active governance/UAT gate. | ✓ VERIFIED | Commit `f569fc2` replaces the ambiguous generic legend with a terminal-green statement; fresh `mix quality.governance` passes 12 Elixir and 10 Node governance tests, and `mix quality.uat 135 --check` exits 0. |

**Score:** 13/13 truths verified (0 present, behavior-unverified)

## Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `dev/rendro/catalog_evidence_bundle.ex` | Closed evidence-bundle authority | ✓ VERIFIED | 419 substantive lines; invoked by focused tests and trusted control job. |
| `dev/rendro/catalog_evidence_parity.ex` | Four-route normalization and sealed parity validation | ✓ VERIFIED | 469 substantive lines; route-specific extractors and sealed-record/inventory projection are exercised by tests. |
| `.github/workflows/catalog-evidence.yml` | Isolated manual exact-SHA evidence workflow | ✓ VERIFIED | 142 lines; parsed by guardrails and linted with `actionlint`. |
| `135-parity-comparator-record.json` | Durable schema-v2 four-route record | ✓ VERIFIED | Sealed record contains four matched routes, one SHA, typed transport facts, and eight live-confirmed artifact digests. |
| `135-test-inventory.md` | Bounded test inventory and exact 16-column parity projection | ✓ VERIFIED | Contract enforces IDs, ordering, every column, and one-cell mutation rejection. |
| `.github/workflows/CATALOG-EVIDENCE.md` | Current operator runbook | ✓ VERIFIED | Contract-tested and listed from `scripts/README.md`; docs verifier passes. |
| `135-VALIDATION.md` | Terminal validation evidence | ✓ VERIFIED | `f569fc2` makes the terminal-green audit state unambiguous to active governance scanning. |

## Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Focused bundle tests | `CatalogEvidenceBundle` | Positive and malformed-input controls | WIRED | 70-test focused Phase 135 invocation passed. |
| Focused parity/inventory tests | sealed schema-v2 record and inventory | Route facts, all 16 cells, mutation controls | WIRED | All focused controls pass and record facts project exactly into the ledger. |
| Candidate generation | trusted control job | One bounded Actions artifact handoff | WIRED | Separate jobs/runners; download is constrained to regular files, count, size, and closed filenames before bundle build. |
| Catalog Evidence | ordinary CI | Deliberate graph disconnection | WIRED | `catalog-evidence` only needs candidate generation; it is absent from `ci-success.needs`. |
| Runbook | docs verifier/helper index | Registered docs-contract lane and README link | WIRED | `mix run scripts/verify_docs.exs` completed all 28 lanes. |

## Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Catalog Evidence workflow | bounded `handoff` | Detached candidate job outputs | Candidate manifests/checksums/PDFium pin are generated, then regular-file/size/count/name validated in a fresh control job | ✓ FLOWING |
| Evidence bundle | manifest payload facts | Validated candidate handoff | Role records are parsed and counts recomputed from payload bytes; hashes are recomputed before upload | ✓ FLOWING |
| Parity inventory | 16 row cells | Sealed schema-v2 record | Rows are mechanically projected from verified route facts, not static display data | ✓ FLOWING |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Phase 135 deterministic contracts and test owners | `mix test …phase-135 focused files… --max-failures 1` | 70 tests, 0 failures | ✓ PASS |
| Workflow syntax | `actionlint .github/workflows/catalog-evidence.yml .github/workflows/ci.yml` | Exit 0 | ✓ PASS |
| Documentation claims | `mix run scripts/verify_docs.exs` | 28 lanes passed | ✓ PASS |
| UAT terminal evidence | `mix quality.uat --all --check` | Exit 0 | ✓ PASS |
| Full deterministic CI | `mix ci.fast` | Exit 0; compile, tests, Credo, Dialyzer completed | ✓ PASS |
| Active governance | `mix quality.governance` | 12 Elixir tests and 10 Node governance tests passed | ✓ PASS |

## Remote Parity Evidence

| Route | Legacy run | Generic run | Candidate SHA | Artifact evidence | Status |
| --- | --- | --- | --- | --- | --- |
| `phase126_preset_review` | 33110485344 | 33110490597 | `643e407508d744d11b919a8af929855d06e608d4` | Both run success/head SHA and recorded digests confirmed through GitHub API | ✓ VERIFIED |
| `phase127_catalog_review` | 33110486826 | 33110490597 | same | Both run success/head SHA and recorded digests confirmed through GitHub API | ✓ VERIFIED |
| `phase130_review` | 33110489293 | 33110490597 | same | Three legacy artifact digests plus generic digest confirmed through GitHub API | ✓ VERIFIED |
| `phase130_canonical` | 33110490906 | 33110492328 | same | Both run success/head SHA and recorded digests confirmed through GitHub API | ✓ VERIFIED |

## Requirements Coverage

| Requirement | Source Plan | Status | Evidence |
| --- | --- | --- | --- |
| TEST-01 | 135-01 | ✓ SATISFIED | Bounded inventory, strict schema/order contract, and mutation-style negative controls pass. |
| TEST-02 | 135-01 | ✓ SATISFIED | Retained Payslip owner proves failure; distinct opts/byte/typography behavior remains focused-test covered. |
| CI-01 | 135-01, 135-02 | ✓ SATISFIED | Exact-SHA manual workflow, PDFium pin, closed bundle, credential-free checkouts, read-only permissions, and no repository mutation. |
| CI-02 | 135-01, 135-03 | ✓ SATISFIED | Four route-specific matched records on one SHA; live run and all eight artifact digests independently confirmed. |
| CI-03 | 135-02, 135-03 | ✓ SATISFIED | `ci-success` remains the sole authoritative aggregate and the deterministic/proof/advisory topology is contract-checked. |
| CI-04 | 135-01, 135-02, 135-03 | ✓ SATISFIED | Read-only/pinned actions, credential-free checkouts, no secrets/caches/writes/bridge in evidence workflow, and bounded untrusted handoff. |
| CI-05 | 135-02 | ✓ SATISFIED | Current adjacent runbook, deterministic docs contract, helper link, reproduction and recovery commands pass. |

`REQUIREMENTS.md` still renders CI-02 as an unchecked checkbox while its traceability table calls it Complete. This is a tracking inconsistency, not a lack of CI-02 implementation evidence; it was not edited during verification.

## Anti-Patterns Found

No blocking anti-patterns found. No `TBD`, `FIXME`, `XXX`, placeholder implementation, unsupported abstraction, mutable action reference, credential persistence, secret/cache/write bridge, legacy-route resurrection, or unresolved terminal-state marker remains in the phase implementation surfaces.

---

_Verified: 2026-08-27T21:46:09Z_
_Verifier: the agent (gsd-verifier)_
