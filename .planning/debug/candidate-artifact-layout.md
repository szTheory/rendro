---
status: resolved
trigger: "authorize-candidate-artifact-layout-investigation-and-fix"
created: 2026-08-20
updated: 2026-08-20
---

# Debug Session: Candidate Artifact Layout

## Symptoms

### Expected behavior

After the exact-SHA candidate and raster-review tests pass, the advisory workflow stages one complete artifact containing the 32-cell candidate bundle, fixed twelve-image final review payload, four separate multipage proofs, hashes, and provenance, then uploads it.

### Actual behavior

Authorized run `32411304227` passed exact ref/SHA binding, pinned PDFium, 32-cell candidate generation, and the twelve-image final-review payload. Artifact staging then referenced a candidate directory that the generator had not created, so every upload was skipped.

### Error messages

`find: ‘tmp/phase130-candidate/catalog’: No such file or directory`

### Timeline

Observed on 2026-08-20 at commit `737bfb5e21faeda367e2698ce7e208fcab8b54d9`, after the multipage manifest and final-subset validation defects were fixed and their CI stages passed.

### Reproduction

Run exact ref `gsd/phase-130-catalog-review-737bfb5e21faeda367e2698ce7e208fcab8b54d9` at commit `737bfb5e21faeda367e2698ce7e208fcab8b54d9`. In advisory job `96562103955`, artifact staging executes `find` against `tmp/phase130-candidate/catalog` after all generation/review tests pass, but that path is absent.

## Scope Constraints

- Identify the actual candidate output layout and the workflow's declared staging/upload layout before editing either side.
- Establish which layout is consistent with Plan 130-04's fixed-root candidate manifest/path contracts and principle of least surprise.
- Add a regression test that runs or faithfully exercises the complete post-generation staging inventory: 32 candidate PNGs, one manifest, twelve final PNGs, four separate multipage proofs, hashes, and provenance.
- Apply only the minimal proven layout/staging fix; preserve private dev-only scope, fixed roots, atomic generation, fail-closed behavior, safe paths, and exact ordering.
- Keep canonical assets, rubric scores, SIGN-OFF evidence, and detached launch staging byte-identical.
- Do not push a new ref, launch CI, accept/download artifacts, or publish candidate output. Stop at a fresh exact-SHA checkpoint.

## Current Focus

hypothesis: the workflow's artifact-staging shell assumes a `catalog/` directory that diverges from the candidate generator's validated manifest-relative output layout.
test: compare generator publication paths, candidate manifest paths, raster-review consumers, and every artifact-staging command; reproduce the entire expected file-set assertion locally in a focused contract test.
expecting: one stale hard-coded directory assumption in the workflow or one inconsistent generator root, with the manifest/path contracts determining the correct minimal repair.
next_action: create a fresh exact-SHA candidate checkpoint for CI validation; do not reuse the failed artifact run
reasoning_checkpoint:
tdd_checkpoint:

## Evidence

- timestamp: 2026-08-20; exact job `96562103955` checked out the full-SHA route at `737bfb5e21faeda367e2698ce7e208fcab8b54d9`, generated `tmp/phase130-candidate/candidate-manifest.json`, and passed its raster payload test before staging failed.
- timestamp: 2026-08-20; `Rendro.Catalog.build_cells/3` writes candidate cell PNGs from the fixed candidate root using each canonical asset path relative to `assets/rendro/catalog`; the 32 files are therefore under family directories at `tmp/phase130-candidate/`, not under `catalog/`.
- timestamp: 2026-08-20; candidate multipage proofs deliberately publish under `tmp/phase130-candidate/multipage/`; the workflow must exclude only that subtree when counting the 32-cell candidate inventory.
- timestamp: 2026-08-20; the raster-review test now verifies the complete candidate manifest plus 32 candidate PNG hashes, all four candidate multipage hashes, the 12 final PNG hashes and identity manifest, and the four rendered review-proof hashes with commit/run/renderer provenance.

## Eliminated

## Resolution

root_cause: the Phase 130 candidate-artifact staging step retained a stale `tmp/phase130-candidate/catalog` directory assumption even though atomic candidate generation publishes the fixed manifest-relative 32-cell layout directly under `tmp/phase130-candidate`.
fix: count candidate PNGs from the fixed candidate root while excluding only its intentional `multipage/` subtree; preserve the existing full-root copy layout and three separate uploads.
verification: `mix format --check-formatted test/rendro/catalog_raster_review_test.exs test/guardrails/required_checks_contract_test.exs`; `mix test test/guardrails/required_checks_contract_test.exs` (19 tests, 0 failures); `mix test test/rendro/catalog_raster_review_test.exs` (compiled, intentionally excluded locally because no pinned `pdfium-cli` is available); exact job log confirms candidate generation and raster review passed before the stale `catalog/` find failed.
files_changed: .github/workflows/ci.yml; test/guardrails/required_checks_contract_test.exs; test/rendro/catalog_raster_review_test.exs
