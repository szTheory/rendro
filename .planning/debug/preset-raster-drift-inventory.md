---
status: resolved
trigger: "authorize-complete-preset-drift-inventory afd30724a00a2c7b08faeb84752d5f04beae0e97"
created: 2026-08-20
updated: 2026-08-20
---

# Debug Session: Complete Preset Raster Drift Inventory

## Symptoms

### Expected behavior

The exact-SHA pinned-PDFium lane passes every preset raster reference before Phase 130 launch generation begins.

### Actual behavior

After the reviewed `swiss/dark` reference repair, exact-SHA CI run `32379222629`, advisory job `96458000243`, verified PDFium v0.11.0 and then stopped on a `humanist/light` preset-raster mismatch. The failing lane does not expose the actual hash and stops before launch artifact production.

### Error messages

`pinned PDFium page-one hash mismatch for humanist/light`

### Timeline

Observed on 2026-08-20 at main commit `afd30724a00a2c7b08faeb84752d5f04beae0e97` while resuming Phase 130 Plan 130-08. A prior `swiss/dark` mismatch was traced to an intentional recipe change without a reviewed reference refresh.

### Reproduction

Run the immutable preset-raster advisory lane on ref `gsd/phase-130-catalog-review-afd30724a00a2c7b08faeb84752d5f04beae0e97`, commit `afd30724a00a2c7b08faeb84752d5f04beae0e97`, with PDFium v0.11.0 binary SHA-256 `b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a`.

## Scope Constraints

- Inventory every preset-raster mismatch in one diagnostic run; do not stop after the first mismatch.
- Diagnostic behavior must preserve canonical assertions as failing and must not weaken, skip, reorder, or auto-bless any gate.
- Upload an exact manifest and PNG for every mismatching matrix row, including expected and actual SHA-256 values plus full run/job/artifact provenance.
- Make diagnostic edits only in `/Users/jon/projects/rendro/tmp/phase130-preset-drift-inventory` on unmerged branch `gsd/diagnostic-preset-inventory-afd307` based exactly on `afd30724a00a2c7b08faeb84752d5f04beae0e97`.
- Do not modify main, `/Users/jon/projects/rendro/tmp/phase130-launch-reconcile`, any canonical raster reference, golden, launch artifact, catalog asset/score, rubric evidence, SIGN-OFF, recipe, preset, API, or dependency.
- Stop for one consolidated human review after all mismatches are proven and downloaded.

## Current Focus

hypothesis: multiple preset references may be stale after intentional Phase 130 recipe changes; the current fail-fast assertion reveals only the first mismatching row
test: run a diagnostic-only test mode that evaluates all twelve rows, records mismatch data and PNGs, then fails after the loop; stage/upload this payload before a dedicated nonzero CI step
expecting: the diagnostic ref yields an artifact with every mismatching row and exact renderer/run provenance, while all non-diagnostic refs retain their current fail-fast test behavior
next_action: resolved — the exact-SHA authorized reference batch was applied and committed on main
reasoning_checkpoint:
  hypothesis: per-row ExUnit assertions stop preset raster execution at the first stale reference, because an assertion raises before later matrix rows can render or report their hashes.
  confirming_evidence:
    - The test calls assert_or_bless_page_one_hash inside its for-loop after rendering each row.
    - The reported CI failure names the second tested row with drift (humanist/light) and provides no later-row data.
  falsification_test: A diagnostic run that defers the assertion but retains the same pinned renderer completes all twelve rows and produces mismatch records beyond humanist/light; if it still aborts at that row, the assertion is not the controlling mechanism.
  fix_rationale: A branch-gated diagnostic mode changes only failure aggregation: it neither changes rendering, reference reads, pin validation, ordering, or blessing, and exits nonzero whenever any collected hash differs.
  blind_spots: The full mismatch set and artifact transport are not yet observed in GitHub Actions; local macOS rendering cannot validate the Linux-pinned hashes.
  candidate_causes:
    - code: the current per-row assertion is intentionally fail-fast and cannot produce a complete inventory.
    - data: one or more committed reference hashes may be stale after Phase 130 recipe changes.
    - environment: PDFium executable drift could cause the observed mismatch, but the prior CI run reported the exact pinned binary verified.
  and_gate: no — fail-fast control flow alone explains the incomplete inventory; stale reference data explains mismatches but is not required to explain why only the first mismatch is reported.
tdd_checkpoint:

## Evidence

- timestamp: 2026-08-20
  checked: authorized diagnostic worktree branch/base/status and existing CI/test implementation
  found: branch gsd/diagnostic-preset-inventory-afd307 is clean at afd30724a00a2c7b08faeb84752d5f04beae0e97; the preset test renders twelve rows but asserts each hash inside the loop, so the first drift aborts collection. The existing CI pin installer verifies SHA-256 b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a.
  implication: a diagnostic-only branch gate can use the same renderer while deferring only diagnostic mismatch assertion until all twelve rows have been evaluated; canonical behavior can remain unchanged for every other ref.

- timestamp: 2026-08-20
  checked: diagnostic implementation and local structural validation
  found: the diagnostic branch alone now invokes an inventory environment that records only mismatching PNGs and a hash manifest after all rows; CI verifies the installed binary SHA against priv/pdfium_pin.json, packages run/job/artifact provenance, uploads before a final nonzero mismatch gate. mix format accepted the Elixir source, git diff --check passed, and ci.yml parses as YAML; the guardrail test cannot run locally because the worktree has no fetched Elixir dependencies.
  implication: the controlled CI run is the required execution test for both the precise Linux PDFium output and artifact provenance.

- timestamp: 2026-08-20
  checked: diagnostic worktree commit
  found: only .github/workflows/ci.yml and test/rendro/theme/preset_raster_snapshot_test.exs were committed as eed5166f3ed01e3be578491596e7c3fd60c925ee on gsd/diagnostic-preset-inventory-afd307.
  implication: the unmerged branch is ready to trigger its exact branch-gated diagnostic lane without touching canonical references, recipes, presets, or launch assets.

- timestamp: 2026-08-20
  checked: pushed diagnostic branch and CI dispatch
  found: origin accepted eed5166f3ed01e3be578491596e7c3fd60c925ee and created CI run 32381349135 for that exact head SHA; the run is queued.
  implication: the next direct evidence will come from the pinned advisory job rather than an unpinned local renderer.

- timestamp: 2026-08-20
  checked: advisory job execution in CI run 32381349135
  found: the existing adapter snapshot step succeeded; the diagnostic full-inventory test failed as intended after collection, and its artifact staging/upload steps both succeeded before the dedicated final drift-failure step exited nonzero.
  implication: the failure is truthful and the uploaded artifact is available for exact mismatch/provenance verification.

- timestamp: 2026-08-20
  checked: downloaded artifact 9411223598 (preset-raster-drift-inventory)
  found: manifest.json binds commit eed5166f3ed01e3be578491596e7c3fd60c925ee, run 32381349135 attempt 1, advisory-checks, artifact preset-raster-drift-inventory, PDFium v0.11.0, and SHA-256 b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a. It records 12 matrix rows and 8 mismatches; all eight named PNGs are present and their downloaded SHA-256 values equal their manifest actual_sha256 values.
  implication: humanist (light,dark), editorial (light,dark), minimal_mono (light,dark), and brutalist (light,dark) have proven stale-reference drift under the exact pin. Swiss (light,dark) and corporate_classic (light,dark) are the four matching rows by matrix complement.

- timestamp: 2026-08-20
  checked: exact-SHA authorization `authorize-preset-reference-batch 2e1efe46479df724f756b2a8901a0a556dc97bda88eef3b5b2fc95da14f2aee4` against `tmp/phase130-preset-drift-inventory/tmp/diagnostic-inventory-32381349135/test-manifest.json`
  found: the manifest has exactly eight mismatch rows from CI run 32381349135, advisory job artifact 9411223598, generated by diagnostic commit eed5166f3ed01e3be578491596e7c3fd60c925ee using PDFium v0.11.0 pinned to SHA-256 b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a. Before applying, all eight canonical reference files equaled their expected_sha256 values and each downloaded PNG equaled its actual_sha256 value. Consolidated human review authorized precisely these eight transitions.
  implication: only the proven stale references for humanist, editorial, minimal_mono, and brutalist (both light and dark) may be refreshed; swiss and corporate_classic remain unchanged.

- timestamp: 2026-08-20
  checked: authorized main-checkout reference refresh
  found: applied exactly the eight manifest expected_sha256 -> actual_sha256 transitions, with no diagnostic commit merge/cherry-pick and no product, CI, test-instrumentation, recipe, preset, launch, catalog, rubric, or sign-off changes.
  implication: the Linux-pinned raster lane now compares the eight reviewed rows against its captured expected output, while canonical test behavior remains unchanged.

## Eliminated

## Resolution

root_cause: Eight canonical preset-raster reference hashes were stale after intentional Phase 130 recipe changes; fail-fast test control flow previously obscured the complete mismatch set.
fix: Applied the exactly authorized expected_sha256 -> actual_sha256 refresh to the eight humanist, editorial, minimal_mono, and brutalist light/dark reference files only.
verification: Manifest SHA-256 2e1efe46479df724f756b2a8901a0a556dc97bda88eef3b5b2fc95da14f2aee4 was rechecked; its eight current reference values matched expected_sha256 and its downloaded PNG hashes matched actual_sha256 before the transition. Focused deterministic and guardrail tests plus git diff checks were run locally after the update; the authoritative pinned-PDFium evidence remains CI run 32381349135 / artifact 9411223598.
files_changed: [priv/raster_refs/presets/humanist/light.sha256, priv/raster_refs/presets/humanist/dark.sha256, priv/raster_refs/presets/editorial/light.sha256, priv/raster_refs/presets/editorial/dark.sha256, priv/raster_refs/presets/minimal_mono/light.sha256, priv/raster_refs/presets/minimal_mono/dark.sha256, priv/raster_refs/presets/brutalist/light.sha256, priv/raster_refs/presets/brutalist/dark.sha256, .planning/debug/preset-raster-drift-inventory.md]
