---
status: resolved
trigger: "authorize-purpose-built-launch-artifact-route 2463749d2b877c4761f2b7bf3a25dd1e8673a9bd"
created: 2026-08-20
updated: 2026-08-20
---

# Debug Session: Phase 130 Launch Artifact Route

## Symptoms

### Expected behavior

Phase 130 Plan 130-08 obtains a complete, provenance-bound launch-family artifact rendered under the exact pinned PDFium binary from source commit `2463749d2b877c4761f2b7bf3a25dd1e8673a9bd` with the two explicitly approved dark golden transitions applied only in ephemeral staging.

### Actual behavior

Existing exact-SHA CI checks out pristine main. The two approved golden transitions intentionally live only in detached staging, so CI fails the two dark golden assertions and launch-artifact static contract before it can upload a complete launch batch.

### Error messages

Exact-SHA CI run `32383924719`, advisory job `96473606713`, verified pinned PDFium and then reported the two stale dark golden assertions plus stale launch identities. No complete launch artifact was uploaded.

### Timeline

Observed on 2026-08-20 after all preset-raster reference drift was reviewed and repaired. Main is clean at the authorized source SHA; detached launch staging is at the same source SHA with exactly the two approved golden modifications.

### Reproduction

Run the current advisory workflow from exact source SHA `2463749d2b877c4761f2b7bf3a25dd1e8673a9bd`. It operates on pristine source goldens rather than the approved detached-staging inputs, so the required launch generation path cannot complete.

## Scope Constraints

- Build the smallest purpose-built route on unmerged branch `gsd/diagnostic-launch-route-246374` in `/Users/jon/projects/rendro/tmp/phase130-launch-artifact-route`.
- The route must explicitly check out source SHA `2463749d2b877c4761f2b7bf3a25dd1e8673a9bd`; workflow/route code provenance is separate from rendered-source provenance.
- Verify pristine old golden hashes, apply only the two approved new hashes inside the ephemeral runner, and verify the exact two-file pre-generation diff.
- Verify PDFium v0.11.0 binary SHA-256 `b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a` before rendering.
- Generate and upload the complete launch family plus a deterministic manifest binding source SHA, route SHA/ref, run/job/artifact identity, old/new golden hashes, exact changed-path inventory, and every output hash.
- Do not merge the route, change main, modify canonical references/evidence, approve launch quality, or touch the detached launch-staging worktree.
- Fail closed on every source/ref/hash/path/provenance mismatch.

## Current Focus

hypothesis: the existing CI workflow checks the pristine exact-source checkout, while its static launch-artifact contract expects the two deliberately detached golden transitions; a separate dual-provenance route can verify the pristine inputs then make only those transitions in an ephemeral checkout.
test: add an isolated `workflow_dispatch`/route-branch workflow that separately checks out the fixed source commit, verifies the pristine hashes, changes only the approved two golden files, regenerates/checks the launch family under the verified PDFium binary, and stages a provenance-bound artifact.
expecting: workflow validation and local static tests will show that the route is independent of `ci.yml`, never modifies canonical checkout state, and encodes the exact two validated transitions.
next_action: session resolved; retain the independently verified diagnostic artifact for the intended Plan 130-08 review, without merging the route or altering canonical state.
reasoning_checkpoint:
  hypothesis: "CI's pristine exact-source checkout causes the two intended dark golden assertions and launch artifact manifest to be stale because the approved replacements exist only in detached staging."
  confirming_evidence:
    - "The current advisory lane executes `mix rendro.launch_artifacts.check` directly in its checkout."
    - "The untouched source SHA contains certificate/dark=df9703…cdb1 and statement/dark=aca316…3ec9, while the detached launch staging worktree differs in exactly those files with approved values acb99d…07d1 and a971a8…eab6."
  falsification_test: "If the detached staging diff contained another path, or if the source checkout already contained either approved value, then a two-path ephemeral transition would not model the reported failure."
  fix_rationale: "A new non-required workflow keeps canonical CI checks pristine while explicitly creating a separately checked-out, source-pinned ephemeral input state for launch generation."
  blind_spots: "The GitHub run cannot be executed until the route branch is pushed; local verification can prove workflow structure and source task behavior but not GitHub artifact upload semantics."
  candidate_causes:
    - "code: the existing workflow has no explicit dual-provenance staging step before its launch-artifact check."
    - "data: canonical source goldens intentionally retain old hashes while the reviewed launch input requires two new hashes."
    - "environment: PDFium was already pinned and verified in the failing run, so renderer-version drift is not supported by evidence."
  and_gate: "yes — the failure requires both the existing pristine-only workflow behavior and the deliberately separate approved golden inputs; removing either condition eliminates this exact mismatch."
tdd_checkpoint:

## Evidence

- timestamp: 2026-08-20
  checked: debug knowledge base and the authorized route worktree
  found: no prior knowledge-base entry exists; the authorized worktree is clean on branch `gsd/diagnostic-launch-route-246374` at exact source SHA `2463749d2b877c4761f2b7bf3a25dd1e8673a9bd`.
  implication: there is no prior-resolution candidate to assume, and the route can be implemented without reconciling pre-existing local changes.

- timestamp: 2026-08-20
  checked: CI references to PDFium and launch artifacts
  found: `.github/workflows/ci.yml` installs PDFium v0.11.0 using a SHA-256 guard and later invokes `mix rendro.launch_artifacts.check`; the current failure route therefore appears to be a deterministic source/input provenance mismatch rather than a renderer version ambiguity.
  implication: leading bug class is `bohrbug`; test the workflow/source boundary and exact staging diff before changing behavior.

- timestamp: 2026-08-20
  checked: detached launch-staging worktree against the source-pinned route worktree
  found: the detached worktree is dirty in exactly `priv/goldens/certificate/dark.sha256` and `priv/goldens/statement/dark.sha256`; their transitions are `df9703ee72be0fa78d2fab8f064ca93eb70b4699801372ff9c24513aa5c4cdb1` → `acb99d40fc68d365d1c6b158e2cf335325563307e1828c90f39bd2a95aff07d1` and `aca31620062efd25c21d74c855d9ba50e65777a35068afc86387efe415063ec9` → `a971a8a7395ebbb3e1af9c54e236483c969a90b222af1a6fdedfccead587eab6`.
  implication: the root cause is confirmed as a two-condition code/data provenance mismatch (bug class `bohrbug`); the supported minimal fix is an isolated CI route rather than a canonical reference change.

- timestamp: 2026-08-20
  checked: new route workflow syntax and local launch-artifact claims test setup
  found: `git diff --check` and the available GitHub Actions workflow linter succeeded; the local ExUnit command could not start because this isolated worktree has no fetched Mix dependencies.
  implication: workflow syntax is currently valid, and dependency installation is the required next step before source-contract verification can be assessed.

- timestamp: 2026-08-20
  checked: locally installed source-contract suites
  found: `test/guardrails/required_checks_contract_test.exs` passed, while the launch-artifact static contract failed on this macOS host with source-PDF hash drift for ten entries (including light and unrelated dark entries), not the two approved golden paths.
  implication: the local renderer environment cannot be used as a faithful regression oracle; the route's Ubuntu runner regenerates and verifies in the exact pinned PDFium lane before its source-contract suite executes.

- timestamp: 2026-08-20
  checked: workflow diff and GitHub Actions syntax
  found: the only route-worktree change is the new branch-scoped workflow, `git diff --check` passes, and `actionlint` passes.
  implication: the fix is minimal and structurally valid; the remaining verification is the one authorized remote route execution.

- timestamp: 2026-08-20
  checked: remote route run `32385327402`, job `96478302481`
  found: the route failed closed in `Verify pinned source is pristine` before modifying source or rendering. The workflow compared each file's hash (which includes its trailing newline) with `printf '%s'` of the expected value (which omitted it); the later direct content checks confirm the expected files are newline-terminated.
  implication: the initial route implementation has a deterministic self-verification defect, not a source-SHA or PDFium mismatch. Correct the expected-value digest to use `printf '%s\\n'` and repeat the remote route.

- timestamp: 2026-08-20
  checked: corrected remote route run `32385410822`, job `96478573018`, at route commit `c2a6ce1411388b3be1aa8fd86308105e644ee194`
  found: all thirteen route steps passed: source and route provenance verification, exact two-path staging, pinned PDFium validation, generation/check, source-contract tests, complete artifact assembly, and upload. GitHub uploaded non-expired artifact `phase130-launch-artifact-32385410822-1` (artifact ID `9412909590`, 3,248,496 bytes).
  implication: the minimal route produces the requested complete provenance-bound artifact without modifying main or the detached staging worktree.

- timestamp: 2026-08-20
  checked: independently downloaded artifact `phase130-launch-artifact-32385410822-1` (ID `9412909590`) from completed-success run `32385410822`, job `96478573018`, into `/Users/jon/projects/rendro/tmp/phase130-launch-artifact-route/tmp/verified-launch-artifact-32385410822`
  found: GitHub run metadata, artifact metadata, and `provenance.json` consistently bind route branch `gsd/diagnostic-launch-route-246374`, route commit `c2a6ce1411388b3be1aa8fd86308105e644ee194`, source SHA `2463749d2b877c4761f2b7bf3a25dd1e8673a9bd`, run ID `32385410822`, artifact name, PDFium v0.11.0, and binary SHA-256 `b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a`. The route commit has the source SHA as its parent and changes only `.github/workflows/phase130-launch-artifact-route.yml`. The pinned source contains the approved old values; the artifact contains exactly the approved new certificate and statement dark values. `provenance.json` SHA-256 is `806dbcc4c9473f835d0c0415734b3b46e00214aefaa49e12ba906be12751fe0a`.
  implication: route/source/rendering provenance independently agrees with the artifact manifest.

- timestamp: 2026-08-20
  checked: full downloaded artifact inventory and `shasum -a 256 -c output-hashes.sha256`
  found: all 55 manifest-listed files validate; the sorted manifest path set equals the sorted on-disk hashed-file set with no additions or omissions. The artifact contains 57 total files: those 55 content files plus `output-hashes.sha256` and `provenance.json`.
  implication: the downloaded artifact is complete and internally hash-consistent for the route's declared inventory.

## Eliminated

- hypothesis: the pinned source checkout did not resolve to the required SHA
  evidence: checkout completed and the failure is explained by the pre-existing newline mismatch in the next hash assertion; the direct content assertions were designed to validate the same source values.
  timestamp: 2026-08-20

## Eliminated

## Resolution

root_cause: Existing exact-SHA CI ran against pristine goldens while the reviewed launch input required exactly two separate dark-golden transitions; the missing dual-provenance staging route caused the launch artifact contract to fail.
fix: Added an unmerged, branch-scoped workflow that separately checks out the exact source SHA, verifies and applies only the two approved dark golden values in its ephemeral checkout, verifies the pinned PDFium binary, regenerates/checks launch artifacts, and uploads output hashes plus provenance.
verification:
  target_test: {result: skipped, reason_if_skipped: "No agent-authored test can execute a GitHub Actions workflow locally; route includes its own pinned-source acceptance checks."}
  mutation_check: {result: skipped, reason_if_skipped: "Stryker is not configured for GitHub Actions YAML."}
  no_op_deletion: {result: pass, deletion_justified_by_rca: false}
  adjacent_tests: {result: pass, suites_run: ["test/guardrails/required_checks_contract_test.exs"]}
  revert_and_reconfirm: {result: skipped, reason_if_skipped: "The observable reproduction requires the remote runner; removal would remove the only new route, so a local reversal cannot produce a meaningful route execution."}
  remote_route: {result: pass, run: "32385410822", job: "96478573018", artifact: "phase130-launch-artifact-32385410822-1", artifact_id: "9412909590"}
  guardrail_verdict: accepted
files_changed:
  - .github/workflows/phase130-launch-artifact-route.yml
