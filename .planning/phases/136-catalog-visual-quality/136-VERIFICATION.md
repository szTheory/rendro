---
phase: 136-catalog-visual-quality
verified: 2026-08-28T00:00:00Z
status: gaps_found
score: 2/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "Exact-SHA pinned-renderer evidence and human review give each target hierarchy 5 and every other scored visual dimension at least 4; any miss remains truthfully unpromoted."
    status: failed
    reason: "The candidate d547bbfa60760d43f19a15372d88a2d159bfa327 is not remote-reachable. Run 33139093669 failed before checkout and bundle creation; no validated bundle or six named target reviews exists."
    artifacts:
      - path: "priv/quality/SIGN-OFF.md"
        issue: "Explicitly records all six Phase 136 targets as unreviewed and unpromoted."
      - path: "priv/quality/rubric_scores.json"
        issue: "Contains the previous Phase 130 evidence, including sub-threshold target dimensions, rather than new candidate-bound review records."
    missing:
      - "Publish the exact candidate object to a remote-reachable ref."
      - "Dispatch and validate one exact-SHA review bundle, then record six complete named reviews with the frozen threshold results."
  - truth: "Every changed record is traceable through source SHA, renderer identity, artifact hashes, human review, and canonical publication provenance."
    status: failed
    reason: "No Phase 136 candidate artifact exists to bind these fields. Canonical assets are intentionally unchanged and the six records are canonical-ineligible."
    artifacts:
      - path: "test/docs_contract/rubric_manifest_contract_test.exs"
        issue: "The tested current outcome is canonical_ineligible for missing validated bundle and reviewer records."
    missing:
      - "Validated exact candidate artifact identities and six complete reviewer-owned records before canonical materialization."
---

# Phase 136: Catalog Visual Quality Verification Report

**Phase Goal:** The six scored cells with current visual gaps meet the frozen rubric through exact, reviewable evidence without expanding catalog scope or dark-mode claims.
**Verified:** 2026-08-28T00:00:00Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Only Corporate Classic Invoice dark, Minimal Mono Statement dark, Swiss Payslip light/dark, and Brutalist Ticket light/dark receive visual treatment. | ✓ VERIFIED | `dev/rendro/catalog.ex` has a six-entry literal `@visual_target_profiles` map with exactly those IDs and passes only generic profile data to recipes; 115 catalog/evidence contract tests passed. |
| 2 | Each target has current exact-SHA pinned-renderer evidence and named review at hierarchy 5 and all other visual dimensions >=4. | ✗ FAILED | `git ls-remote origin d547…327` returned no matching remote object. `SIGN-OFF.md` records run `33139093669` failed before checkout/bundle creation and all six targets are unreviewed/unpromoted. No score can be inferred from code or older evidence. |
| 3 | The catalog remains 32 cells, 20 explicitly unscored, and dark output remains screen-only with `print_safety: false`. | ✓ VERIFIED | `rubric_manifest_contract_test.exs` asserts 32/20 and false dark print safety; current focused test run passed. The target recipes retain profile-only dark styling, not new print/accessibility/viewer claims. |
| 4 | Every changed target record is bound to exact source, renderer, artifact, review, and canonical-publication provenance. | ✗ FAILED | There is no Phase 136 closed review bundle or target review record. The tested outcome is `:canonical_ineligible`; assets and catalog manifest remain deliberately unchanged. |

**Score:** 2/4 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `dev/rendro/catalog.ex` | Exact six-ID dev-only selection and generic profile threading | ✓ VERIFIED | Six literal IDs; `source_document_for/1` calls `recipe_options/2`, which supplies `presentation_profile` only when selected. |
| `lib/rendro/recipes/{invoice,statement,payslip,ticket}.ex` | Generic target rendering treatment without catalog identity | ✓ VERIFIED | Profile predicates consume only semantic/ledger/locator keys; recipe source contains no target catalog IDs. |
| `dev/rendro/catalog_evidence_bundle.ex` | Fail-closed trusted bundle validation | ✓ VERIFIED | `validate/3` requires an independent control SHA, checked-out control match, renderer pin, identities, role/count and checksum validation; relevant tests passed. |
| `.github/workflows/catalog-evidence.yml` | Exact-SHA, read-only pinned-renderer evidence path | ✓ VERIFIED | Dispatch input validates full SHA; candidate HEAD is checked and the control job validates a closed handoff under `contents: read`. |
| `priv/quality/SIGN-OFF.md` | Truthful Phase 136 review record or explicit deferral | ✓ VERIFIED (deferral) | Records the unavailable exact SHA, no image interpretation/score/approval, all six unreviewed/unpromoted cells, and a bounded next action. It does not constitute the missing review evidence. |
| `test/docs_contract/rubric_manifest_contract_test.exs` | Eligibility/no-write contract | ✓ VERIFIED | It asserts exact missing-bundle/reviewer reasons and rejects malformed eligible evidence; focused tests passed. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- |
| `dev/rendro/catalog.ex` | recipes | generic `presentation_profile` option | WIRED | Target selector maps only exact IDs and strips identity to generic data before `document/2`. |
| workflow | bundle validator | independently supplied control SHA and checked-in PDFium pin | WIRED | Workflow uses `validate(..., CONTROL_SHA)` after control checkout; validator rejects mismatched control/check-out/pin. |
| review intake | canonical publication | complete exact review eligibility | NOT_WIRED BY DESIGN | Current evidence state correctly selects `canonical_ineligible` and forbids canonical writing. This is safe but proves the desired review-to-publication link has not occurred. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Catalog recipe selection | `presentation_profile` | exact ID lookup in dev catalog map | Yes, for six selected IDs only | ✓ FLOWING |
| Evidence validation | manifest/control/pin identities | downloaded closed bundle plus trusted control checkout and checked-in `pdfium_pin.json` | Yes when a bundle exists; no bundle was produced for this candidate | ⚠️ EXPLICITLY UNAVAILABLE |
| Canonical eligibility | target review records | validated closed review record | No current source | ✗ DISCONNECTED BY MISSING EVIDENCE |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Catalog scope, evidence, review and eligibility contracts | `mix test test/rendro/catalog_test.exs test/rendro/catalog_evidence_bundle_test.exs test/rendro/catalog_review_payload_contract_test.exs test/docs_contract/rubric_manifest_contract_test.exs test/docs_contract/catalog_evidence_runbook_test.exs test/docs_contract/catalog_quality_contract_test.exs --max-failures 1` | 115 tests, 0 failures | ✓ PASS |
| Target recipe contracts | `mix test` over Invoice, Statement, Payslip, and Ticket Phase 136 recipe test files | 195 tests, 0 failures | ✓ PASS |
| Canonical state reflects changed source without an unauthorized write | `mix rendro.catalog.check` | Reports source-PDF hash drift for five target cells and suggests generation; no writer was run | ✓ PASS — confirms the documented ineligible/no-write state |
| Candidate is remote-reachable for review | `git ls-remote origin d547bbfa60760d43f19a15372d88a2d159bfa327` | No matching ref/object returned | ✗ FAIL |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| CATALOG-10 | 136-01, 136-06 | Scope visual work to the exact six target cells | ✓ SATISFIED | Six exact profile-map IDs and target-set mutation contracts; no canonical write. |
| CATALOG-11 | 136-02 through 136-06 | Current exact evidence and qualified target visual scores | ✗ BLOCKED | No exact candidate bundle or human reviews; previous Phase 130 scores remain historical and include sub-threshold target dimensions. |
| CATALOG-12 | 136-01 through 136-06 | Preserve 32/20 boundary and screen-only dark mode | ✓ SATISFIED | Exact count/type/print-safety tests pass; all dark scored records retain boolean false. |
| CATALOG-13 | 136-05, 136-06 | Bind changed records to complete exact provenance and canonical publication | ✗ BLOCKED | Fail-closed validator and no-write eligibility are implemented, but the required candidate artifact/review/canonical provenance has not been produced. |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| None in Phase 136 implementation/evidence files | — | No unreferenced `TBD`, `FIXME`, or `XXX` marker found | — | — |

### Explicit Deferral (Verified, Not a Pass)

The repository handles unavailable advisory evidence correctly: it does not create a score, approval, promotion, or dark-mode claim from absence. `SIGN-OFF.md` gives the exact candidate/run failure and next action, and eligibility tests require canonical ineligibility and no write. This satisfies the project’s deterministic/advisory separation, but it does not make the roadmap’s current-review and complete-provenance truths true.

No later roadmap phase specifically delivers the missing exact candidate review; Phase 137 only requires that unavailable advisory evidence be stated explicitly. The two failures are therefore not deferred out of this phase’s gap set.

### Gaps Summary

The phase successfully implemented bounded repairs and a fail-closed evidence path, but its stated outcome—six targets meeting the frozen rubric through current, exact, reviewable evidence—has not occurred. The blocking prerequisite is external and precisely known: make candidate `d547bbfa60760d43f19a15372d88a2d159bfa327` remote-reachable, rerun the exact review lane, validate the generated closed bundle, and record six complete named evaluations. Only then can the system determine pass/miss honestly and, if qualified, create canonical publication provenance.

---

_Verified: 2026-08-28T00:00:00Z_
_Verifier: the agent (gsd-verifier)_
