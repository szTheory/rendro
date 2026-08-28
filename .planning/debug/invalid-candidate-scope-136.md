---
status: awaiting_workflow
trigger: "Phase 136 exact-SHA review workflow run 33177154682 failed during candidate generation with :invalid_candidate_scope and produced zero artifacts"
created: 2026-08-28
updated: 2026-08-28
---

# Debug Session: Phase 136 Invalid Candidate Scope

## Symptoms

### Expected behavior

The existing Catalog Evidence workflow accepts the immutable Phase 136 candidate, proves that exactly the six named visual targets changed while the other 26 catalog cells remain byte-identical, and produces one closed `review` artifact for trusted-control validation and human review.

### Actual behavior

The authorized candidate ref resolves exactly to `d547bbfa60760d43f19a15372d88a2d159bfa327`, but workflow-dispatch run `33177154682` failed in candidate generation with `Candidate catalog generation failed: :invalid_candidate_scope`. The run produced zero artifacts, the trusted control job was skipped, and Plan 136-08 correctly stopped before image interpretation.

### Error messages

`Candidate catalog generation failed: :invalid_candidate_scope`

### Timeline

Observed on 2026-08-28 after Phase 136 Plans 01-07 completed, the exact candidate was published at `refs/heads/gsd/phase-136-candidate-d547bbfa6076`, and a new `review` operation was dispatched from control SHA `834a7d32101ab98258fcc5d4f2a3caccbbc1df5c`.

### Reproduction

Dispatch `.github/workflows/catalog-evidence.yml` with `operation=review` and `candidate_sha=d547bbfa60760d43f19a15372d88a2d159bfa327`, then inspect run `33177154682`. Candidate generation reaches the closed-handoff binding step and returns `:invalid_candidate_scope`; artifact count is zero.

## Scope Constraints

- Preserve the exact six-target boundary, 26 byte-identical controls, 32/20 catalog counts, and all dark `print_safety: false` values.
- Preserve deterministic/advisory authority separation; do not manufacture image review, scores, approval, or canonical eligibility.
- Diagnose whether the candidate truly changes out-of-scope cells or whether the candidate/control comparison uses a stale or incorrect baseline/checkout.
- Fix only the demonstrated cause, add a regression test first when behavior changes, and keep core pure with no new runtime dependency or public API.
- Do not mutate reviewer-owned scores, `SIGN-OFF.md`, or canonical assets as part of diagnosis.
- Do not force-update the published candidate ref or reuse failed run identities. Any fixed candidate must receive a new commit SHA and return to a fresh blocking-human publication decision.

## Current Focus

hypothesis: confirmed and fixed; the generic Ticket locator header fill makes the light target render differently while preserving the six-target and no-profile boundaries
test: local deterministic checks completed; a fresh exact-SHA candidate evidence dispatch must now be authorized separately by a human
expecting: a newly published candidate SHA will generate a candidate manifest with exactly the six ordered changes, then stop again at the pre-existing blocking-human evidence-intake gate
next_action: wait for fresh review run `33180320420` to finish; if successful, download only its bounded evidence artifact and validate it from a detached checkout of trusted control `834a7d32101ab98258fcc5d4f2a3caccbbc1df5c`, then stop at the blocking human visual-review gate
bug_class:
reasoning_checkpoint:
  hypothesis: "The light Brutalist ticket remains byte-stable because `atomic_equal_share` affects pagination-only cell metadata; adding a profile-gated locator header fill will create a visible, deterministic PDF delta for both already-allowlisted Ticket target IDs without changing geometry or controls."
  confirming_evidence:
    - "The exact candidate's real source-PDF comparison lists five changes and omits only `ticket--aurora-live--brutalist--light`."
    - "The ticket profile currently wraps cells in `%Rendro.Cell{split_policy: :atomic}` while its table has `borders: :none` and no other profile-gated render attribute."
    - "The new real-render regression test fails before the change with the same five-ID list."
  falsification_test: "After adding a profile-gated `header_fill`, the source-PDF regression must list exactly the six ordered targets; any changed control or unchanged light ticket refutes the fix."
  fix_rationale: "`header_fill` is rendered by the table writer but does not affect table dimensions, field order, or the no-profile path; it makes the existing locator labels visually distinct only where the generic profile is supplied by the two allowlisted catalog IDs."
  blind_spots: "Local macOS cannot execute the pinned Linux PDFium binary, so PNG hashes cannot be regenerated here; the deterministic source-PDF boundary and the existing pinned renderer workflow remain the available pre-dispatch checks."
  candidate_causes:
    - "code: ticket profile only changes pagination metadata, not rendered drawing operations"
    - "config: stale control baseline or scorer disposition mismatch"
  and_gate: "no; the baseline and disposition inputs are unchanged and independently verified, while the missing light source-PDF delta alone deterministically triggers the exact-six rejection"
tdd_checkpoint:

## Evidence

- timestamp: 2026-08-28T14:32:43Z
  checked: authorized exact-candidate publication and fresh default-branch review dispatch
  found: Local preflight resolved `c4ab6795c590049a1dfacadc7acf5c0f5ea675d5` exactly and the dedicated remote ref was absent. It was pushed without force to `refs/heads/gsd/phase-136-candidate-c4ab6795c590`. Exactly one fresh `review` dispatch was created from trusted default-branch control `834a7d32101ab98258fcc5d4f2a3caccbbc1df5c`: run `33180320420` (`Catalog Evidence`, `workflow_dispatch`, head branch `main`). Candidate generation is in progress; the failed run `33177154682` and its candidate ref were not reused.
  implication: The human-authorized immutable publication and dispatch boundary has been satisfied. Artifact download, trusted-control validation, and visual review remain blocked on successful completion of this new run.

- timestamp: 2026-08-28
  checked: workflow binding, exact candidate history, and candidate/control diffs for baseline manifest and reviewer rubric
  found: The workflow checks out the requested immutable SHA before candidate generation. `d547bbf` descends from control SHA `834a7d3`; neither `assets/rendro/catalog.json` nor `priv/quality/rubric_scores.json` differs between those refs. All six allowlisted IDs are `scored`.
  implication: The failure is not explained by a stale catalog baseline, a changed reviewer disposition, or dispatch resolving the wrong candidate commit. It must be the candidate's rendered cell classification.

- timestamp: 2026-08-28
  checked: `candidate_manifest/6`, `valid_candidate_diff/1`, and the Phase 136 recipe diff
  found: `valid_candidate_diff/1` admits only an ordered list of the six scored targets, no changed-unscored IDs, and the 26 ordered controls as byte-stable. The candidate adds generic presentation profiles in `Catalog` and uses them in Invoice, Statement, Payslip, and Ticket recipes.
  implication: A local candidate generation can distinguish an accidental non-target rendering change from an allowlisted target that did not render differently.

- timestamp: 2026-08-28
  checked: exact `d547bbf` candidate source-PDF SHA-256 values compared to its unchanged `assets/rendro/catalog.json` baseline
  found: The changed IDs are invoice Corporate Classic dark, statement Minimal Mono dark, payslip Swiss light and dark, and ticket Brutalist dark. `ticket--aurora-live--brutalist--light` remains byte-identical. Its `atomic_equal_share` profile only changes `Rendro.Cell.split_policy`, which does not alter this one-row light catalog rendering; the dark ticket changes independently through `stub_colors`.
  implication: The candidate is rejected correctly. The demonstrated defect is a missing rendered delta for one required target, and the existing synthetic classifier test did not exercise real catalog source PDFs.

- timestamp: 2026-08-28
  checked: red regression test `real catalog target profiles change exactly the six allowlisted source PDFs`
  found: Before the fix it failed with the five-ID actual set, omitting only `ticket--aurora-live--brutalist--light`.
  implication: The test directly reproduces the production candidate-scope failure rather than merely exercising synthetic hash substitutions.

- timestamp: 2026-08-28
  checked: target-scoped Ticket header-fill fix and related catalog/Ticket tests
  found: The generic atomic locator profile now sets `header_fill: colors.surface`; no-profile Ticket tables still receive `nil`. The real source-PDF regression and 39 Ticket structural/determinism tests pass (40 tests total).
  implication: The formerly byte-stable light Ticket target now changes through a rendered table operation while the profile preserves the same equal-share locator geometry.

- timestamp: 2026-08-28
  checked: full catalog suite, `mix ci.fast`, format/diff checks, and revert-and-reconfirm
  found: All 19 catalog tests and `mix ci.fast` passed; formatting and `git diff --check` passed. Reverting the three fix files restored the five-ID failure (light Ticket omitted), and reapplying restored the green exact-six regression. No Stryker configuration exists in this Elixir project.
  implication: The patch is additive and target-scoped, the driving regression is causal, and adjacent deterministic behavior remains green. A local macOS execution cannot run the pinned Linux PDFium binary, so final raster/evidence validation remains the intentionally separate authorized workflow step.

## Eliminated

## Resolution

root_cause: `ticket--aurora-live--brutalist--light` is in the exact six-target allowlist but its new atomic-cell profile has no output effect in the one-row catalog fixture, so it remains byte-stable and fails the closed exact-six diff predicate.
fix: Add a profile-gated `header_fill: colors.surface` to the Ticket locator table and a real rendered-source-PDF exact-six regression test; retain the existing generic atomic-cell profile, geometry, and no-profile behavior.
verification:
  target_test: {result: pass, suite: "mix test test/rendro/catalog_test.exs:205 --max-failures 1"}
  mutation_check: {result: skipped, reason_if_skipped: "no Stryker or equivalent mutation configuration exists for this Elixir project", mutant_killed: null}
  no_op_deletion: {result: pass, deletion_justified_by_rca: false, evidence: "33 additions and 2 replacements; no behavior deletion or assertion weakening"}
  adjacent_tests: {result: pass, suites_run: ["mix test test/rendro/catalog_test.exs --max-failures 1", "mix test test/rendro/recipes/ticket_test.exs test/rendro/recipes/ticket_byte_identity_test.exs --max-failures 1", "mix ci.fast"]}
  revert_and_reconfirm: {result: pass, bug_returned_on_revert: true, fixed_on_reapply: true, evidence: "reverted source comparison returned five IDs; reapplying made the exact-six regression pass"}
  guardrail_verdict: accepted
  local_renderer_boundary: "Pinned PDFium Linux binary cannot execute on macOS; no artifact or image interpretation was performed locally."
files_changed:
  - lib/rendro/recipes/ticket.ex
  - test/rendro/catalog_test.exs
  - test/rendro/recipes/ticket_test.exs
