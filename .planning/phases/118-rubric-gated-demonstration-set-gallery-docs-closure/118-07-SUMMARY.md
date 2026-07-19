---
phase: 118-rubric-gated-demonstration-set-gallery-docs-closure
plan: 07
subsystem: testing
tags: [docs-contract, support-matrix, tripwire, accessibility, claims-integrity, elixir, exunit]

# Dependency graph
requires:
  - phase: 118-05
    provides: re-blessed 7-tile gallery (realistic renders) + generated README/recipes blocks
  - phase: 118-06
    provides: six honest rubric self-scores (all below the gate, D-11) — the honesty ceiling for doc claims
provides:
  - D-14 accessibility-overclaim tripwire test scanning README.md + guides/**/*.md
  - guides/recipes.md Realistic Example Library section + Payslip & Ticket recipe sections
  - guides/branding.md realistic-invoice-fixture branding story
  - guides/livebook/first_invoice.livemd full-anatomy invoice + fixture-load section
  - examples/phoenix_example/README.md realistic-library reference (honest, no route overclaim)
  - priv/support_matrix.json demonstration_set row (proof-backed, honesty boundaries)
  - README.md Canonical-recipes bullet extended to payslips + tickets
affects: [milestone-audit, docs-update, future-recipe-phases]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Co-occurrence tripwire: showcase-term list AND accessibility-standard-term list gate per public doc; honest rubric-gate vocabulary (logical reading order) deliberately excluded"
    - "Proof-backed support-matrix row: every claim resolves to an on-disk test/evidence pointer; boundaries explicitly disclaim what is NOT claimed"
    - "Guides use elixir-schematic fences for illustrative code so the verified-fence contract (tagged + evaluable) stays intact"

key-files:
  created:
    - test/docs_contract/accessibility_overclaim_test.exs
  modified:
    - scripts/verify_docs.exs
    - guides/recipes.md
    - guides/branding.md
    - guides/livebook/first_invoice.livemd
    - examples/phoenix_example/README.md
    - priv/support_matrix.json
    - README.md
    - test/docs_contract/recipes_claims_test.exs
    - test/guardrails/required_checks_contract_test.exs

key-decisions:
  - "Did NOT add 'production-grade'/'beautiful'/rubric-pass wording anywhere: all six demos are below the rubric gate (118-06), so any quality claim would be an overclaim. Claims are bounded to 'demonstrated + rendered deterministically'."
  - "Added a demonstration_set support-matrix row whose boundaries explicitly mark reader_quality_rubric_pass / visual_polish_claim / accessibility_conformance_claim as unsupported — encoding the honesty ceiling as machine-checked data."
  - "Referenced the internal @moduledoc false Rendro.Examples / Rendro.ExamplesData helpers in guides (as the plan required) but framed them as internal loaders for the shipped demonstration set, pointing users to the public build-your-own-data path."
  - "Phoenix example README references payslip/ticket as library families but explicitly states the app does NOT expose them as routes (the router has only 5 recipe routes) — no unbacked route claim."

patterns-established:
  - "D-14 tripwire: self-tested co-occurrence predicate (positive + negative cases) proves the guard has teeth rather than passing vacuously."

requirements-completed: [SHOW-02, SHOW-04]

coverage:
  - id: D1
    description: "D-14 accessibility-overclaim tripwire test scans README.md + guides/**/*.md and fails when showcase wording co-occurs with a tagged-PDF/PDF-UA/screen-reader/accessibility-conformance claim"
    requirement: "SHOW-04"
    verification:
      - kind: unit
        ref: "test/docs_contract/accessibility_overclaim_test.exs (15 tests, incl. positive/negative predicate self-tests)"
        status: pass
    human_judgment: false
  - id: D2
    description: "guides/recipes.md, guides/branding.md, first_invoice.livemd, examples/phoenix_example demonstrate the realistic example library + new Payslip/Ticket families with evidence-bounded claims and no edits inside generated-block markers"
    requirement: "SHOW-02"
    verification:
      - kind: unit
        ref: "test/docs_contract/recipes_contract_test.exs + branding_contract_test.exs + launch_artifacts_claims_test.exs (drift contract) — full docs_contract lane 293 tests pass"
        status: pass
    human_judgment: false
  - id: D3
    description: "priv/support_matrix.json + README reconciled: payslip/ticket rows resolve to evidence; demonstration_set row is proof-backed with honesty boundaries; README recipes bullet lists new families"
    requirement: "SHOW-04"
    verification:
      - kind: unit
        ref: "test/docs_contract/recipes_claims_test.exs (demonstration_set claim-backing describe block) + viewer_evidence_claims_test.exs (matrix schema structure)"
        status: pass
    human_judgment: false

# Metrics
duration: 11min
completed: 2026-07-19
status: complete
---

# Phase 118 Plan 07: Rubric-Gated Demonstration Set — Docs Closure Summary

**D-14 accessibility-overclaim tripwire authored test-first, then the guides/Livebook/phoenix_example and support_matrix/README reconciled to demonstrate the realistic example library + new Payslip/Ticket families — every claim proof-backed, no accessibility overclaim, and no quality/rubric-pass claim (all six demos are honestly below the rubric gate per 118-06).**

## Performance

- **Duration:** 11 min
- **Started:** 2026-07-19T17:18:38Z
- **Completed:** 2026-07-19T17:30:04Z
- **Tasks:** 3 (+1 deviation fix)
- **Files modified:** 9 (1 created, 8 modified)

## Accomplishments
- Authored the D-14 tripwire (`accessibility_overclaim_test.exs`) test-first so it actively guarded the subsequent doc edits; it scans README + all guides and self-tests its co-occurrence predicate (positive + negative) so it cannot pass vacuously.
- Updated all four SHOW-02 doc surfaces to demonstrate the realistic library via `Rendro.Examples`/`Rendro.ExamplesData`, including the previously-undocumented Payslip and Ticket recipe families, with every claim bounded to a support-matrix row / recipe test / fixture.
- Reconciled `support_matrix.json` (new proof-backed `demonstration_set` row with explicit honesty boundaries) and README (recipes bullet extended to payslips + tickets), keeping every claim resolvable to on-disk evidence.
- Full docs-contract lane (293 tests) and full suite (1553 tests) green; no edits inside any generated-block marker.

## Task Commits

1. **Task 1: D-14 accessibility-overclaim tripwire (test-first)** — `d441e2b` (test)
2. **Task 2: demonstrate realistic library + new families in guides** — `beda356` (docs)
3. **Task 3: reconcile support_matrix + README (proof-backed)** — `1632c31` (docs)
4. **Deviation fix: track D-14 lane in lane-count guardrail** — `bed094d` (test)

**Plan metadata:** committed separately with SUMMARY/STATE/ROADMAP.

## Files Created/Modified
- `test/docs_contract/accessibility_overclaim_test.exs` — NEW. D-14 tripwire: showcase-term × accessibility-standard-term co-occurrence guard over README + guides, with predicate self-tests.
- `scripts/verify_docs.exs` — Registered the tripwire as a curated docs-contract lane.
- `guides/recipes.md` — Added "Realistic Example Library" section + Payslip and Ticket recipe sections (support-matrix-backed capability tables), outside generated markers.
- `guides/branding.md` — Added the realistic-invoice-fixture branding story (elixir-schematic, preserving the exact 4 verified fences).
- `guides/livebook/first_invoice.livemd` — Upgraded the invoice to full anatomy (issuer/customer/due_date/terms/Decimal totals) mirroring the shipped fixture; added a `Rendro.Examples` fixture-load section.
- `examples/phoenix_example/README.md` — Referenced the realistic library + Payslip/Ticket families honestly (no route claims the router does not back).
- `priv/support_matrix.json` — Added the `demonstration_set` row (families incl. payslip+ticket, deterministic-source-PDF + per-family DOMAIN.md capabilities, resolvable evidence pointers, unsupported-boundary honesty).
- `README.md` — Extended the Canonical-recipes bullet (prose, outside generated markers) to include payslips and tickets.
- `test/docs_contract/recipes_claims_test.exs` — Backed the `demonstration_set` claim (present+supported, new families listed, evidence resolves, boundaries disclaim rubric-pass/polish/accessibility).
- `test/guardrails/required_checks_contract_test.exs` — Updated the docs-contract lane-count guardrail 25→26 for the new lane.

## Decisions Made
- Bounded every claim to "demonstrated + rendered deterministically" and never to quality/beauty/rubric-pass — the 118-06 honesty ceiling (all six demos below the gate) makes any polish claim an overclaim.
- Encoded that honesty ceiling as machine-checked data: `demonstration_set.boundaries` marks `reader_quality_rubric_pass`, `visual_polish_claim`, and `accessibility_conformance_claim` as `unsupported`, and a contract test asserts it.
- Used `elixir-schematic` fences for all new illustrative code so the verified-fence contracts (recipes.md evaluable-fence lane; branding.md exact-4-fence guard) stay intact.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Docs-contract lane-count guardrail broke on the new lane**
- **Found during:** Task 1 (registering the D-14 lane in `scripts/verify_docs.exs`)
- **Issue:** `RequiredChecksContractTest` snapshots the exact curated lane count (`== 25`); registering the tripwire lane raised it to 26, failing the guardrail. (Surfaced only in the full-suite run, not the docs_contract lane.)
- **Fix:** Updated the guardrail to expect 26 and added an assertion for the new "Accessibility overclaim tripwire lane".
- **Files modified:** test/guardrails/required_checks_contract_test.exs
- **Verification:** `mix test test/guardrails/required_checks_contract_test.exs` (16 tests) + full suite (1553 tests) green.
- **Committed in:** `bed094d`

---

**Total deviations:** 1 auto-fixed (1 bug). **Impact:** Necessary to keep the guardrail consistent with the intentional lane addition. No scope creep.

## Issues Encountered
- **Pre-existing `mix format` debt (out of scope, deferred).** `mix format --check-formatted` (part of `mix ci.fast`) is RED on 10 files that 118-07 did not touch (Phase 116 ticket work, 118-04/05 launch-artifacts, edge-matrix tests). All 9 files 118-07 changed are individually format-clean. Logged to `deferred-items.md`; a dedicated formatting pass is owed by the owning phase. Because of this pre-existing debt, `mix ci.fast` is not fully green independent of this plan; the docs-contract lane, full test suite, `mix docs --warnings-as-errors`, and `mix credo --strict` are all green.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Milestone docs surface (SHOW-02) and proof-backed-claims contract (SHOW-04) are closed for v2.10.
- The D-14 tripwire now guards every future doc edit repo-wide against accessibility overclaim.
- Open follow-ups (not blockers for this plan): the deferred `mix format` pass, and the 118-06 remediation path if the team later wants the demos to actually clear the rubric gate.

## Self-Check: PASSED

- Created file present: `test/docs_contract/accessibility_overclaim_test.exs`
- Reconciled manifest present with new row: `priv/support_matrix.json` (`demonstration_set`)
- All task commits present: `d441e2b`, `beda356`, `1632c31`, `bed094d`

---
*Phase: 118-rubric-gated-demonstration-set-gallery-docs-closure*
*Completed: 2026-07-19*
