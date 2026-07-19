---
phase: 118-rubric-gated-demonstration-set-gallery-docs-closure
verified: 2026-07-19T00:00:00Z
status: gaps_found
score: 3/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "SHOW-01 / SC1 — each family×domain demo passes the rubric (content_hierarchy = 5, other cores ≥ 4, both gates pass)"
    status: failed
    reason: "All six recorded demo scores in priv/quality/rubric_scores.json have passed:false. Per the deliberate D-11 honesty decision, scores were recorded truthfully and none reaches the gate. The demonstration set was rendered and scored, but the roadmap SC and requirement text both require the demos to PASS the rubric — that clause is unmet. Phase 118 is the final phase of milestone v2.10, so this is not deferrable to a later phase; the findings note remediation reaches back into 118-03/118-04 (transform/recipe/fixture) scope."
    artifacts:
      - path: "priv/quality/rubric_scores.json"
        issue: "6 score entries, every one passed:false. Closest is payslip-aurora-live (content_hierarchy=5 but three cores at 3). invoice-acme-phoenix-saas is under-built (IA/CH/DF=2): render shows no issuer/customer block, no total/amount-due, money as $79.0."
      - path: "lib/rendro/examples_data.ex"
        issue: "bare_money/1 uses Decimal.to_float (line ~191) for the legacy invoice price path, producing the $79.0 one-decimal money defect the invoice justification cites."
    missing:
      - "Improve transform_invoice/recipe composition so the invoice renders parties + totals with amount-due dominant over a realistic handful of lines (fixes the biggest gap)"
      - "Add a dominant key-fact element to statement (closing balance), receipt (total), certificate (recipient), de-crowd payslip earnings/deductions table, size ticket to content"
      - "Re-render (118-05 gen) and re-score honestly so demos clear content_hierarchy=5 / cores≥4 / gates"
      - "OR accept an override rescoping SHOW-01 to 'honestly scored, gaps surfaced' (developer decision — see note below)"
      - "REQUIREMENTS.md marks SHOW-01 as [x] Complete; this is inaccurate while no demo passes — reconcile the checkbox to the actual state"
---

# Phase 118: Rubric-gated demonstration set, gallery & docs closure — Verification Report

**Phase Goal:** Close the milestone with a rubric-PASSING family×domain demonstration set, regenerated gallery/artifacts (with S6 tags), and reconciled docs/support so every new family and claim is proof-backed and no accessibility overclaim is made.
**Verified:** 2026-07-19
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

The phase delivered the demonstration infrastructure, the re-blessed gallery, and the reconciled/honest docs — but the central goal word ("rubric-PASSING") is not achieved: none of the six demos clears the rubric gate. This was a deliberate, honest D-11 outcome (scores were recorded truthfully, never inflated), but the goal and SHOW-01 both require passing demos, so the phase goal is not fully met.

### Observable Truths (roadmap Success Criteria)

| # | Truth | Status | Evidence |
| --- | ------- | ---------- | -------------- |
| SC1 (SHOW-01) | Family×domain matrix rendered via recipes+escape hatch, each demo citing DOMAIN.md **and passing the rubric** (hierarchy=5, core≥4, gates), scores appended to manifest (S5) | ✗ FAILED | Rendered ✓ (7 gallery renders), cites DOMAIN.md ✓ (all 6 cited, files exist, demo_cites_domain_md_test green), scores appended ✓ (6 schema-valid entries, arithmetic-consistent). **Passing the rubric ✗ — all six `passed:false` in priv/quality/rubric_scores.json.** |
| SC2 (SHOW-02) | recipes.md, branding.md, first_invoice.livemd, phoenix_example updated to demonstrate upgraded Invoice + new families, claims bounded to evidence | ✓ VERIFIED | 118-07 updated all four surfaces; full docs_contract lane green (104 tests in verified subset, 0 failures); claims bounded, no generated-block edits |
| SC3 (SHOW-03) | gallery/ + artifacts.json regenerated via `mix rendro.launch_artifacts.gen` to realistic renders w/ matching SHA-256; artifacts.json gains S6 theme/mode/preset tags | ✓ VERIFIED | `mix rendro.launch_artifacts.check` → "Launch artifacts VERIFIED" (zero drift). artifacts.json has 7 entries, each carrying png_sha256 + source_pdf_sha256 and theme/mode/preset keys |
| SC4 (SHOW-04) | support_matrix.json + README reconciled, every new family/claim proof-backed, no tagged-PDF/PDF-UA accessibility claim (production-grade guarded) | ✓ VERIFIED | demonstration_set row proof-backed with boundaries marking reader_quality_rubric_pass / visual_polish_claim / accessibility_conformance_claim as unsupported; D-14 tripwire present + self-tested (teeth); payslip/ticket rows present |

**Score:** 3/4 truths verified (0 present, behavior-unverified)

### Supporting Truths (plan must-haves) — mostly verified

| Truth | Status | Evidence |
| ----- | ------ | -------- |
| 5 new fixtures validate against generalized examples.schema.json | ✓ VERIFIED | examples_schema_contract_test.exs 3 tests, 0 failures; schema 283L |
| Fixtures use Decimal-safe money as strings, fictional-only, S4 brand slot | ✓ VERIFIED | payslip.json money as "4200.00" etc; fictional (Jordan Vega/Aurora Live), masked ID; `brand:{logo:null}` |
| Each of 5 new domains has DOMAIN.md w/ 4 required headings; per-domain contract | ✓ VERIFIED | 6 DOMAIN.md present; domain_md_contract_test green |
| transform_<family>/1 for 6 families, Decimal-typed maps | ✓ VERIFIED | examples_data_test green; transforms present for all families |
| Rendro.ExamplesData @moduledoc false, absent from public_api.json | ✓ VERIFIED | grep ExamplesData in priv/public_api.json → 0 matches; public_api_contract_test green |
| LaunchArtifacts sources tiles from priv/examples via Examples+ExamplesData (D-06); 7 tiles in fixed order; S6 keys | ✓ VERIFIED | launch_artifacts.check VERIFIED; artifacts.json 7 ordered entries w/ S6 keys |
| 6 demo entries schema-valid, computed `passed`, justifications, domain_md citation; demo_ids disjoint from stress fixtures | ✓ VERIFIED | rubric_manifest_contract_test green (asserts passed?/2 arithmetic); 6 distinct family-domain-business ids |
| Money coerced faithfully (never Decimal.to_integer) | ⚠️ PARTIAL | No to_integer; but legacy invoice path uses Decimal.to_float → `$79.0` money defect (feeds SC1 failure, not a standalone blocker) |

### Deferred Items

None. Phase 118 is the final phase of milestone v2.10 (114–118); the SHOW-01 remediation is not scheduled in any later phase and the findings place it in prior-plan (118-03/118-04) scope. It is a real gap, not deferred.

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | ----------- | ------ | ------- |
| priv/examples/{statement,receipt,certificate,payslip,ticket}/*.json | 5 new fixtures | ✓ VERIFIED | All present, schema-valid |
| priv/examples/*/DOMAIN.md | 6 DOMAIN.md | ✓ VERIFIED | All present, contract green |
| lib/rendro/examples_data.ex | 6-family transform | ✓ VERIFIED | 197L, tests green |
| lib/rendro/launch_artifacts.ex | 7 tiles + S6 | ✓ VERIFIED | 1148L, check VERIFIED |
| assets/rendro/artifacts.json | 7 entries + hashes + S6 | ✓ VERIFIED | 152L, 7 entries, S6 keys, hashes |
| assets/rendro/gallery/*.png | 7 renders incl payslip/ticket | ✓ VERIFIED | 7 PNGs present |
| priv/quality/rubric_scores.json | 6 honest score entries | ⚠️ HONEST-BUT-FAILING | 6 entries present + arithmetic-valid, but all passed:false → SC1 gap |
| test/docs_contract/accessibility_overclaim_test.exs | D-14 tripwire | ✓ VERIFIED | 103L, self-tested predicate (teeth) |
| priv/support_matrix.json | reconciled + demonstration_set | ✓ VERIFIED | demonstration_set row w/ honesty boundaries |

### Key Link Verification

| From | To | Via | Status |
| ---- | --- | --- | ------ |
| LaunchArtifacts build_source_document | Rendro.Examples → ExamplesData.transform → Recipes.*.document | D-06 single data source | ✓ WIRED (check VERIFIED) |
| rubric_scores entries | passed?/2 arithmetic | rubric_manifest_contract_test | ✓ WIRED (green; computes passed:false honestly) |
| score entries | DOMAIN.md paths on disk | demo_cites_domain_md_test | ✓ WIRED (D-05 green, all 6 paths exist) |
| accessibility_overclaim_test | README.md + guides/**/*.md | D-14 co-occurrence scan | ✓ WIRED (green, self-tested) |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Gallery/artifacts zero-drift | `mix rendro.launch_artifacts.check` | "Launch artifacts VERIFIED" | ✓ PASS |
| SHOW-01/02/04 docs contracts | `mix test` (6 contract files) | 104 tests, 0 failures | ✓ PASS |
| Fixture schema validation | `mix test examples_schema_contract_test.exs` | 3 tests, 0 failures | ✓ PASS |
| Demos pass rubric gate | inspect rubric_scores.json `passed` | all 6 = false | ✗ FAIL (SC1) |

### Requirements Coverage

| Requirement | Source Plan | Status | Evidence |
| ----------- | ---------- | ------ | -------- |
| SHOW-01 | 118-01,02,03,06 | ✗ BLOCKED | Demonstration set rendered/cited/scored, but no demo passes the rubric. REQUIREMENTS.md marks it Complete — inaccurate. |
| SHOW-02 | 118-07 | ✓ SATISFIED | Four doc surfaces demonstrate upgraded Invoice + new families, claims bounded |
| SHOW-03 | 118-03,04,05 | ✓ SATISFIED | Gallery/artifacts.json regenerated, S6 tags, check VERIFIED |
| SHOW-04 | 118-07 | ✓ SATISFIED | support_matrix + README reconciled, proof-backed, D-14 tripwire guards overclaim |

All 4 phase requirement IDs accounted for in PLAN frontmatter and REQUIREMENTS.md (lines 51–54, 103–106). No orphaned requirements.

### Anti-Patterns Found

| File | Pattern | Severity | Impact |
| ---- | ------- | -------- | ------ |
| ~10 files from earlier phases | `mix format --check-formatted` red | ℹ️ Info | Pre-existing debt (Phase 116/118-04/05, edge-matrix), NOT introduced by 118-07; logged in deferred-items.md. Not attributed to this phase. |

### Human Verification Required

None strictly required — the SHOW-01 gap is programmatically observable (all `passed:false`). However, a developer decision is needed on remediation path (see Gaps Summary).

### Gaps Summary

The phase delivered everything except its headline outcome. Infrastructure, gallery re-bless (SC3), docs closure (SC2), and proof-backed/honest support reconciliation (SC4) are all fully verified with green contracts and a zero-drift `launch_artifacts.check`. The honesty discipline is exemplary: 118-06 recorded six truthful rubric scores and 118-07 encoded the "no rubric-pass claim" ceiling as machine-checked data.

But the phase goal and SHOW-01 both explicitly require a **rubric-PASSING** demonstration set, and all six demos score `passed:false`. The largest miss is the invoice demo (under-built: no parties/totals rendered, $79.0 money defect); the others are clean but do not make their one key fact visually dominant enough for content_hierarchy=5. Because Phase 118 closes milestone v2.10, there is no later phase to absorb this, and the fix reaches back into 118-03/118-04 transform/recipe/fixture scope.

**This may be an intentional descope.** If the team accepts "demos honestly scored, gaps surfaced (D-11)" as the delivered outcome rather than "demos pass," add an override to this file's frontmatter to convert SC1 to PASSED (override):

```yaml
overrides:
  - must_have: "SHOW-01 each family×domain demo passes the rubric (hierarchy 5, core 4, gates)"
    reason: "D-11 honesty: demos scored truthfully below the gate; passing demos deferred as separate recipe/transform remediation. Milestone closes with the honest manifest as the deliverable."
    accepted_by: "{your name}"
    accepted_at: "{ISO timestamp}"
```

Also reconcile REQUIREMENTS.md line 51 (SHOW-01 currently `[x] Complete`) with the actual state.

---

_Verified: 2026-07-19_
_Verifier: Claude (gsd-verifier)_
