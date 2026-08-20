---
status: awaiting_human_verify
trigger: "authorize-candidate-final-payload-investigation-and-fix"
created: 2026-08-20
updated: 2026-08-20
---

# Debug Session: Candidate Final Review Payload

## Symptoms

### Expected behavior

The exact-SHA Phase 130 candidate CI route validates the fixed 32-cell candidate, four separately identified multipage proofs, and exactly twelve final review PNGs, then uploads one provenance-bound artifact for Plan 130-04.

### Actual behavior

Authorized run `32396085824` bound the correct ref/SHA, generated the candidate, and passed pinned-PDFium setup, but `Rendro.CatalogRasterReviewTest` rejected the final review payload before artifact staging.

### Error messages

`{:error, :invalid_final_payload}`

All candidate/final/multipage artifact staging and upload steps were skipped. No artifact was accepted or downloaded.

### Timeline

Observed on 2026-08-20 after commit `349f16c3cd3d58349b33b58094b65ff9a0ef6f13` added the previously missing four-entry `multipage` manifest collection. The earlier run `32391789813` had failed before this point because the collection was absent.

### Reproduction

Run the exact ref `gsd/phase-130-catalog-review-349f16c3cd3d58349b33b58094b65ff9a0ef6f13` at commit `349f16c3cd3d58349b33b58094b65ff9a0ef6f13` through the pinned candidate evidence job; candidate generation and PDFium setup pass, then the tagged raster review test returns `{:error, :invalid_final_payload}`.

## Scope Constraints

- Diagnose the precise violated final-payload field or invariant from source and exact-run evidence.
- Add a regression test that reproduces the failure without accepting a generic error as sufficient evidence.
- Apply only the minimal proven contract fix within Plan 130-04's private dev-only candidate route.
- Preserve fixed roots, atomic publication, fail-closed cleanup, exact 32-cell order, four separate multipage proofs, and exactly twelve final review images.
- Keep canonical assets, rubric scores, SIGN-OFF evidence, and detached launch staging byte-identical.
- Do not push a new ref or launch CI; stop at a fresh exact-SHA authorization checkpoint.

## Current Focus

hypothesis: `validate_cells/2` incorrectly equates the full 32-cell candidate input with the 12 final IDs, so a correctly generated candidate is rejected before the classifier can extract its fixed final subset.
test: validate the literal registry order and every candidate cell before extracting `@final_ids` in order; rerun the focused suite, including a stale non-final cell.
expecting: the full 32-cell fixture becomes green while malformed/reordered/missing/extra and stale non-final candidates remain rejected.
next_action: await authorization for a fresh exact-SHA Phase 130 candidate CI run; do not launch CI or alter candidate/reviewer artifacts locally.
bug_class: bohrbug
reasoning_checkpoint:
  hypothesis: "`validate_cells/2` causes `:invalid_final_payload` because it compares all 32 generated candidate IDs to a 12-ID final-review subset instead of validating the fixed registry and extracting that subset."
  confirming_evidence:
    - "Exact run 32396085824 generated the candidate successfully, then failed at the first classify assertion before any final-review write."
    - "`generate_candidate/1` builds every `Catalog.catalog_specs/0` entry (32), while `validate_cells/2` requires the input ID list to equal `@final_ids` (12)."
    - "The focused 32-cell contract fixture fails red with exactly `{:error, :invalid_final_payload}`."
  falsification_test: "If the full 32-cell fixture still returns `:invalid_final_payload` after registry validation plus ordered subset extraction, or if malformed/missing/reordered candidates become accepted, this hypothesis is false."
  fix_rationale: "The correction preserves fail-closed validation of the full literal registry and the existing selected-cell identity checks, while creating the required twelve-image payload from the valid complete candidate."
  blind_spots: "Pinned PDFium rendering cannot run locally; the pure classifier contract and CI log cover the pre-render failure only."
  candidate_causes:
    - "code: full input is compared to final-subset IDs rather than selected after fixed-registry validation (confirmed)."
    - "data: malformed or reordered candidate input could trigger the same aggregate error (refuted by successful generator path and red fixture using valid generated shape)."
    - "environment: pinned PDFium/CI identity mismatch (refuted for this failure because validation fails before any rendering and the run passed pin setup)."
  and_gate: "no — the single code comparison mismatch deterministically produces the symptom with an otherwise valid candidate."
reasoning_checkpoint:
tdd_checkpoint:

## Evidence

- timestamp: 2026-08-20
  checked: repository-wide references to `:invalid_final_payload`
  found: the error originates in the private dev-only `dev/rendro/catalog_review_payload.ex` and is raised by `Rendro.CatalogRasterReviewTest`; Plan 130-03 specifies strict twelve-entry payload and separate four-entry multipage validation.
  implication: this is a deterministic data-shape/API-contract candidate (Bohrbug), so source-level contract tracing is the appropriate first test.

- timestamp: 2026-08-20
  checked: exact CI run `32396085824` logs and candidate generator/classifier source
  found: the pinned advisory job generated its candidate successfully, then the tagged test received `{:error, :invalid_final_payload}` before writing review output. `generate_candidate/1` builds the full literal 32-cell registry, whereas `validate_cells/2` currently requires its input IDs to equal the distinct 12-item `@final_ids` list.
  implication: the failure is deterministic and is fully explained by a code-level full-candidate-versus-final-subset contract mismatch; a renderer pin or CI environment mismatch cannot produce this precise pre-render validation error.

- timestamp: 2026-08-20
  checked: focused agent-authored regression `extracts the fixed final payload from one complete 32-cell candidate manifest`
  found: before any production-code change, the exact full-candidate fixture fails with `right: {:error, :invalid_final_payload}`.
  implication: the regression reproduces the reported failure using the candidate shape required by the contract, rather than merely asserting a generic error.

- timestamp: 2026-08-20
  checked: first minimal registry-extraction implementation against existing malformed-input cases
  found: selection succeeds, but an existing stale-mode case on the first non-final cell is accepted because the interim implementation validates only the selected twelve cells.
  implication: full-registry ordering alone is insufficient; the contract must keep identity validation over all 32 candidate cells before emitting the twelve-item review payload.

## Eliminated

## Resolution

root_cause: `validate_cells/2` treats the full 32-cell candidate as if it must be the 12-item final subset; it rejects a valid generated candidate instead of first enforcing the fixed 32-cell registry and then extracting the ordered final review subset.
fix:
  `classify/2` now validates the complete ordered 32-cell catalog, validates every candidate identity, then extracts only the fixed ordered twelve-entry final review payload.
verification:
  target_test:
    result: pass
    suite: mix test test/rendro/catalog_review_payload_contract_test.exs
    observed: 3 tests, 0 failures
  mutation_check:
    result: skipped
    reason_if_skipped: no Stryker or mutation-test configuration is present in the Elixir project
  no_op_deletion:
    result: pass
    observed: minimal additive extraction/validation diff; no behavior deletion or short-circuiting
  adjacent_tests:
    result: pass
    suites_run:
      - mix test test/rendro/catalog_test.exs test/rendro/catalog_review_payload_contract_test.exs
    observed: 16 tests, 0 failures
  revert_and_reconfirm:
    result: pass
    bug_returned_on_revert: true
    fixed_on_reapply: true
    observed: restoring the prior classifier made the focused 32-cell regression fail again with `:invalid_final_payload`; reapplying the fix restored 3/3 passing
  guardrail_verdict: accepted
  commit: 737bfb5 fix(130-04): extract final payload from candidate
files_changed:
  - dev/rendro/catalog_review_payload.ex
  - test/rendro/catalog_review_payload_contract_test.exs
