---
status: awaiting_human_verify
trigger: "authorize-purpose-built-candidate-artifact-route 411cdcafa5d3090f3d0ec144c0cba59d991ba99f"
created: 2026-08-20
updated: 2026-08-20
---

# Debug Session: Phase 130 Candidate Artifact Route

## Symptoms

### Expected behavior

Plan 130-04 obtains a complete, exact-source-SHA and pinned-PDFium candidate evidence batch from a successful evidence-producing job: one 32-cell candidate artifact, one fixed twelve-image final-review artifact, and one separate four-proof multipage artifact.

### Actual behavior

Exact run `32413888347` at source SHA `411cdcafa5d3090f3d0ec144c0cba59d991ba99f` successfully completed candidate generation, raster review, staging, and all three uploads, but its aggregate advisory job later failed on unrelated pre-existing launch-artifact drift. The uploaded candidate artifacts therefore have not been accepted or downloaded.

### Error messages

The aggregate job failed in `Check Launch Artifacts` due to launch source/PDF/PNG hash drift after candidate uploads succeeded. Candidate-specific stages reported success.

### Timeline

Observed on 2026-08-20 after the candidate generator, multipage collection, final-subset extraction, and artifact-layout contracts were repaired and proven through successive exact-SHA runs.

### Reproduction

Run the current aggregate advisory job at exact ref `gsd/phase-130-catalog-review-411cdcafa5d3090f3d0ec144c0cba59d991ba99f`. Candidate evidence completes and uploads, then the unrelated launch-artifact check makes the overall job unsuccessful.

## Scope Constraints

- Build the smallest unmerged, purpose-built candidate-only route in an isolated worktree/branch derived from exact source SHA `411cdcafa5d3090f3d0ec144c0cba59d991ba99f`.
- Keep route-code provenance separate from rendered-source provenance and verify both exactly.
- Reuse the existing candidate command, payload contract, tagged raster test, pinned PDFium v0.11.0 executable SHA, and three-way artifact separation; do not copy or weaken their logic.
- Require exactly 32 candidate PNGs and one candidate manifest, exactly twelve final PNGs, exactly four separate multipage proofs, safe paths, complete output hashes, and provenance binding source SHA, route SHA/ref, run/job/artifact identities, renderer version, and executable pin.
- Run only candidate-evidence checks required by Plan 130-04; exclude unrelated launch-artifact checks without weakening canonical required CI.
- Push and execute only the specifically authorized isolated route; fail closed on ref/source/pin/job/artifact/inventory ambiguity.
- Do not merge the route, modify main production/workflow files, accept artifacts from failed run `32413888347`, mutate canonical assets/rubric/SIGN-OFF, publish candidate output, or touch detached launch staging.

## Current Focus

hypothesis: the corrected safe-path predicate removed the first staging failure, but a distinct staging assertion now fails after candidate generation and tagged raster review, before any artifact upload.
test: replace only the two malformed jq selectors with parenthesized left operands, then actionlint and re-run the isolated route; safe paths must be accepted while traversal and wrong-prefix paths remain selected as invalid.
expecting: `Cannot index boolean with string "png_path"` disappears, the safe-path contract stays fail-closed, and a new isolated run reaches all three uploads and terminal success.
next_action: retain the isolated verification directory and provide the verified run/job/artifact identities and local paths to Plan 130-04 for independent human/workflow review; do not merge the isolated route or accept any failed-run artifacts.
reasoning_checkpoint:
  hypothesis: "The staging step in run 32416452965 crashes because jq parses `(.png_path | startswith(...)) | not or (.png_path | contains(...))` as a pipeline whose later `.png_path` lookup receives the preceding boolean; grouping the complete left operand of `or` keeps both path predicates evaluated against the manifest object."
  confirming_evidence:
    - "The exact failed staging log reports `Cannot index boolean with string \"png_path\"` at the candidate-manifest safe-path selector, after generation and raster-review succeeded."
    - "A sanitized local safe-path JSON reproduces the identical jq error with the current selector; the parenthesized selector accepts safe input and selects traversal and wrong-prefix input."
  falsification_test: "If the parenthesized selector still throws on a safe manifest path, or fails to select a traversal/wrong-prefix path, this hypothesis is false."
  fix_rationale: "Parenthesizing only the left boolean operand restores jq's intended expression boundary without weakening the prefix or traversal rejection contract."
  blind_spots: "Local selector tests do not prove the complete GitHub runner staging, upload, or artifact download behavior; a new successful isolated run and fresh verifier remain required."
  candidate_causes:
    - "code: jq operator precedence in the route's two safe-path selectors changes the input from an object to a boolean before the second `.png_path` access (confirmed)."
    - "config: the route's staging expression is unique to the isolated workflow and was not covered by an end-to-end artifact staging test before dispatch (contributing gap)."
    - "environment: GitHub Actions runner or PDFium pin failure is refuted for run 32416452965 because pin verification, generation, and tagged raster review passed."
  and_gate: "no — the malformed selector alone deterministically causes the staging crash; the missing route-level test explains why it escaped but is not needed to trigger the failure."
  hypothesis: "The aggregate advisory job fails acceptance because Check Launch Artifacts runs after independent candidate uploads; a standalone workflow that checks out source 411cdcafa5d3090f3d0ec144c0cba59d991ba99f separately from its route commit removes only that coupling while preserving candidate evidence controls."
  confirming_evidence:
    - "Run 32413888347 completed candidate generation, tagged raster review, staging, and all three uploads before Check Launch Artifacts failed on unrelated drift."
    - "The current advisory workflow runs candidate steps under the exact full-SHA guard, then unconditionally runs Check Launch Artifacts in the same job."
    - "The isolated workflow reuses the same candidate command, tagged test, pin SHA, and counts while its only changed file is a new route workflow."
  falsification_test: "If the standalone route cannot independently prove source SHA, route SHA, PDFium executable SHA, each required count, hash inventory, and three uploads, or if it changes canonical CI/asset/reviewer state, this hypothesis is false."
  fix_rationale: "A new branch-only workflow replaces aggregate-job coupling with a narrow job whose source checkout is immutable and whose route checkout remains independently recorded; it does not relax the candidate generator, raster contract, pin, or inventory gates."
  blind_spots: "Static validation cannot prove GitHub Actions execution or artifact-download integrity; those require the isolated pushed run and post-download verifier."
  candidate_causes:
    - "code: the aggregate advisory workflow's unconditional launch-artifact check converts an otherwise successful candidate route into a failed job (confirmed)."
    - "config: no dedicated candidate-only job exists with an independent terminal status (confirmed)."
    - "environment: pinned PDFium could still fail or differ in the new runner, which is unconfirmed until the exact executable SHA is checked in the new run."
  and_gate: "no — the documented aggregate-job coupling alone fully explains why a successful candidate payload was not accepted; the new route still independently verifies the environment pin rather than assuming it."
bug_class: bohrbug
reasoning_checkpoint:
tdd_checkpoint:

## Evidence

- timestamp: 2026-08-20
  checked: active worktrees and current source identity
  found: main is exactly at 411cdcafa5d3090f3d0ec144c0cba59d991ba99f; existing isolated worktrees are launch/reconcile, preset-drift, and swiss-dark diagnostics at different commits, so none is eligible for the candidate-only route.
  implication: a new isolated worktree/branch from the exact source SHA is necessary; existing launch staging must remain untouched.

- timestamp: 2026-08-20
  checked: MemPalace and durable debug knowledge base
  found: no MemPalace result or knowledge-base entry was available for this symptom.
  implication: no prior resolution is being treated as a hypothesis candidate.

- timestamp: 2026-08-20
  checked: Plan 130-04, CI advisory job, candidate Mix task, raster-review contract, and PDFium pin
  found: the candidate command and tagged raster test already enforce a 32-cell candidate manifest, 12 final PNGs, 4 multipage PNGs, and PDFium v0.11.0 SHA b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a; their existing route is embedded in advisory-checks, which always later runs Check Launch Artifacts.
  implication: the exact candidate contract can be reused verbatim in a dedicated workflow, while the aggregate launch check is demonstrably the unrelated coupling point and must not be copied.

- timestamp: 2026-08-20
  checked: isolated worktree creation and purpose-built workflow static lint
  found: `tmp/phase130-candidate-evidence-route` is a fresh branch from source SHA `411cdcafa5d3090f3d0ec144c0cba59d991ba99f`; the only proposed change is `.github/workflows/phase130-candidate-evidence.yml`, and `actionlint` plus `git diff --check` pass.
  implication: the route can now be validated against the repository's CI contract tests and committed without affecting main or the detached launch worktree.

- timestamp: 2026-08-20
  checked: isolated static and focused repository validation
  found: `mix deps.get && mix test test/guardrails/required_checks_contract_test.exs --max-failures 1`, `actionlint .github/workflows/phase130-candidate-evidence.yml`, and `git diff --check` passed; the route commit is `857fcfd0420b293fa09e0d888be0b336268989f9` and contains one new workflow file only.
  implication: route code is ready for the authorized isolated push; no canonical CI or evidence state was changed.

- timestamp: 2026-08-20
  checked: authorized isolated push and GitHub Actions dispatch
  found: only branch `gsd/phase130-candidate-route-411cdcafa5d3090f3d0ec144c0cba59d991ba99f` was pushed at route SHA `857fcfd0420b293fa09e0d888be0b336268989f9`; GitHub dispatched `Phase 130 Candidate Evidence Route` run `32415756514` with that route SHA.
  implication: acceptance now depends solely on the new candidate-evidence job's terminal result and a fresh artifact download; failed aggregate run `32413888347` remains excluded.

- timestamp: 2026-08-20
  checked: failed isolated run 32415756514 job 96576397498 logs
  found: route/source checkout, PDFium executable SHA, candidate generation, and tagged raster review all passed. Staging then failed before any upload with `jq: boolean (true) and string ("..") cannot have their containment checked`.
  implication: this is a deterministic route-only predicate precedence defect; no candidate artifact was uploaded or accepted, and the rendered-source candidate contract remains validated.

- timestamp: 2026-08-20
  checked: corrected predicate behavior, lint, isolated commit, and dispatch
  found: actionlint passes; the corrected predicate returns false for a safe candidate path and true for a traversal path. Only route workflow commit `fba0aeeccb96581bf4e3c7dbe7fb40ebde5c8e1b` was pushed, dispatching isolated run `32416452965`.
  implication: the retry preserves all prior source/pin/candidate contracts and changes only the staging verifier defect that prevented upload.

- timestamp: 2026-08-20
  checked: isolated run `32416452965` job `96578584954` during execution
  found: route identity, route checkout provenance, immutable rendered-source checkout, PDFium v0.11.0 executable SHA, and dependency setup completed successfully; candidate generation remains in progress and no artifact upload has occurred.
  implication: the failed aggregate run `32413888347` and failed first isolated run `32415756514` remain excluded; acceptance still requires this exact run's terminal success followed by a fresh three-artifact download.

- timestamp: 2026-08-20
  checked: terminal isolated run `32416452965` job `96578584954` and failed staging log
  found: candidate generation and tagged raster-review contracts passed, but staging failed before every upload with `jq: error (at tmp/phase130-candidate/candidate-manifest.json:1090): Cannot index boolean with string "png_path"`; the route/source identities in that log are route `fba0aeeccb96581bf4e3c7dbe7fb40ebde5c8e1b` and rendered source `411cdcafa5d3090f3d0ec144c0cba59d991ba99f`.
  implication: run `32416452965` is rejected and has no acceptable artifacts; the remaining defect is a second jq operator-precedence error in the safe-path selectors, not a candidate, raster, source, route, or PDFium failure.

- timestamp: 2026-08-20
  checked: sanitized jq selector reproduction, route-only static validation, and revert-and-reconfirm
  found: the prior selector reproduces the boolean-index error on a safe candidate path; after parenthesizing each complete left `or` operand, safe input is accepted and traversal/wrong-prefix input is rejected for both candidate and multipage prefixes. `actionlint`, `git diff --check`, and `mix test test/guardrails/required_checks_contract_test.exs --max-failures 1` pass. A route-worktree-only stash/revert reproduces the old error and popping it restores the passing selector.
  implication: the exact root cause is confirmed and the minimal two-expression fix causally removes it without weakening the safe-path gate.

- timestamp: 2026-08-20
  checked: isolated route-only commit and authorized push
  found: only `.github/workflows/phase130-candidate-evidence.yml` changed in route commit `30657d92cf8be49f30094c57aaf163b76bd0ad9c`, pushed to `gsd/phase130-candidate-route-411cdcafa5d3090f3d0ec144c0cba59d991ba99f`; main and all other worktrees were not modified.
  implication: a third isolated candidate route run is required for final artifact acceptance; runs `32413888347`, `32415756514`, and `32416452965` remain rejected.

- timestamp: 2026-08-20
  checked: terminal isolated run `32417257428` and job `96581121473`
  found: the run completed successfully at route SHA `30657d92cf8be49f30094c57aaf163b76bd0ad9c`; source and route checkout provenance, PDFium v0.11.0 executable SHA verification, candidate generation, tagged raster review, staging, and all three uploads succeeded.
  implication: this is the sole eligible route run; aggregate failed run `32413888347` and isolated failed runs `32415756514` / `32416452965` remain excluded.

- timestamp: 2026-08-20
  checked: remote artifact inventory and fresh isolated artifact download
  found: run `32417257428` exposes exactly three non-expired artifacts — candidate `9424562803` (`phase-130-candidate-route-candidate`), final `9424563354` (`phase-130-candidate-route-final`), and multipage `9424563918` (`phase-130-candidate-route-multipage`) — each bound by GitHub to run `32417257428` and route SHA `30657d92cf8be49f30094c57aaf163b76bd0ad9c`. Only those three were downloaded to `/private/tmp/rendro-phase130-candidate-verify.uGvtvB`.
  implication: no artifact from a failed or ambiguous run entered the verification location.

- timestamp: 2026-08-20
  checked: downloaded candidate, final, and multipage artifact inventories, complete hashes, safe paths, manifests, and provenance
  found: every `inventory.sha256` verifies and exactly enumerates the downloaded files; file counts are candidate 35 total / 32 PNG, final 15 total / 12 PNG, and multipage 7 total / 4 PNG. Candidate-manifest and final identity-manifest SHA lists exactly match all local PNG hashes; all manifest paths are prefix-constrained and traversal-free. Every provenance file binds route SHA `30657d92cf8be49f30094c57aaf163b76bd0ad9c`, route ref `gsd/phase130-candidate-route-411cdcafa5d3090f3d0ec144c0cba59d991ba99f`, rendered source SHA `411cdcafa5d3090f3d0ec144c0cba59d991ba99f`, run `32417257428` attempt `1`, job `candidate-evidence`, repository `szTheory/rendro`, its exact artifact name, renderer `pdfium-cli` version `v0.11.0`, and both pin/executable SHA `b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a`.
  implication: the artifact batch passes all required local fail-closed identity, inventory, hash, safe-path, dual-provenance, renderer, and PDFium-pin checks and is ready for Plan 130-04 handoff.

## Eliminated

## Resolution

root_cause: The isolated route's two jq safe-path selectors evaluated a later `.png_path` lookup against the boolean result of `not` because the full left operands of `or` were not parenthesized, causing deterministic staging failure before uploads.
fix:
  add a dedicated branch-only `Phase 130 Candidate Evidence Route` that separately checks out route SHA and rendered source SHA, proves PDFium v0.11.0 executable SHA, reuses candidate generation plus the tagged raster-review test, and uploads independently inventoried candidate/final/multipage artifacts.
  parenthesize the complete left operands of both jq safe-path `or` expressions so jq evaluates the second `.png_path` predicate against each manifest object rather than the boolean result of `not`.
files_changed:
  - tmp/phase130-candidate-evidence-route/.github/workflows/phase130-candidate-evidence.yml
verification:
  target_test: {result: pass, evidence: "sanitized safe path accepted; traversal and wrong-prefix paths rejected for both selector prefixes"}
  mutation_check: {result: skipped, reason_if_skipped: "Stryker is not configured for this Elixir/GitHub Actions workflow"}
  no_op_deletion: {result: pass, deletion_justified_by_rca: true, evidence: "two parentheses-only expression boundaries preserve and restore prefix/traversal checks"}
  adjacent_tests: {result: pass, suites_run: ["actionlint .github/workflows/phase130-candidate-evidence.yml", "mix test test/guardrails/required_checks_contract_test.exs --max-failures 1", "GitHub run 32417257428 candidate generation + tagged raster review + staging + uploads"]}
  revert_and_reconfirm: {result: pass, bug_returned_on_revert: true, fixed_on_reapply: true, evidence: "route-worktree stash/revert reproduced boolean-index jq error; restore passed focused selector checks"}
  artifact_acceptance: {result: pass, run: "32417257428", job: "96581121473", artifacts: ["9424562803", "9424563354", "9424563918"], verification_root: "/private/tmp/rendro-phase130-candidate-verify.uGvtvB"}
  guardrail_verdict: accepted
