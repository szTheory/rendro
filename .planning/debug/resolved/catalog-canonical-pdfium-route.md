---
status: resolved
trigger: "Plan 130-10 canonical catalog generation cannot run because the approved pinned pdfium-cli executable is Linux-only and unavailable on the macOS canonical checkout"
created: 2026-08-20
updated: 2026-08-21
---

# Debug Session: Catalog Canonical PDFium Route

## Symptoms

### Expected behavior

After exact human evidence is current, Plan 130-10 invokes one successful canonical catalog writer using the approved pinned PDFium executable, reproduces all 32 reviewed candidate identities exactly, and publishes atomically.

### Actual behavior

Task 1 completed and committed current evidence. The first canonical generation attempt failed before staging or publishing artifacts with `{:missing_executable, "pdfium-cli"}` because the approved binary is Linux-only and the canonical checkout runs on macOS.

### Error messages

`mix rendro.catalog.gen` returned `Catalog generation failed: {:missing_executable, "pdfium-cli"}`. No canonical catalog artifacts were published.

### Timeline

Observed on 2026-08-20 during Plan 130-10 after the exact-SHA candidate, final review reconciliation, human review, and atomic launch publication had completed. CI already contains a SHA-verified PDFium v0.11.0 Linux install path and candidate route.

### Reproduction

Run `mix rendro.catalog.gen` from the canonical macOS checkout without a compatible `pdfium-cli` on PATH.

## Scope Constraints

- Do not install or accept an unpinned renderer, weaken renderer/hash identity, rerender human evidence, fabricate scores, or run a second uncontrolled canonical writer.
- Preserve Task 1 commit `047d04c`, all 12 exact reviewed records, the candidate manifest, and the 32-cell literal order.
- Treat the failed pre-staging invocation separately from the required single successful canonical publication, and record both truthfully.
- Prefer a purpose-built exact-SHA CI route using the already approved pinned Linux executable, with artifact download, complete identity verification, and one canonical publication boundary.
- No new public API, dependency, recipe, preset, catalog entry, score, or claim scope.
- User has standing permission for recommended in-scope routing, CI launch, and exact-SHA evidence actions; do not ask for routine authorization.

## Current Focus

hypothesis: canonical generation cannot run on the canonical macOS checkout because `Rendro.Catalog.generate/1` requires PDFium before it creates staging, while CI provisions the approved Linux binary but only recognizes the candidate-review ref; an exact-SHA canonical CI ref and artifact handoff fixes both necessary conditions without changing core rendering.
test: add a guarded canonical CI route and a contract test that requires the full-SHA ref, pinned renderer verification, exactly one canonical invocation, artifact staging, and excludes it from required CI; then run the focused contract test.
expecting: the new route will be available only on a matching SHA-bound push, generate one 32-cell canonical bundle on Linux, run its read-only check, and upload a bounded artifact for local identity verification and publication.
next_action: archive this verified debug-route record; executor-owned canonical assets and Plan 130-10 summary remain outside debug scope.
bug_class: bohrbug
reasoning_checkpoint:
  hypothesis: "The macOS failure is caused by the conjunction of a Linux-only approved PDFium executable and the absence of a post-review CI route that can run the only permitted canonical writer."
  confirming_evidence:
    - "The local command returns {:missing_executable, \"pdfium-cli\"}; generate/1 calls with_pdfium before creating canonical staging."
    - "CI installs and SHA-checks pdfium-cli on ubuntu-latest, but its Phase 130 route only invokes rendro.catalog.candidate on gsd/phase-130-catalog-review-<sha>."
    - "The canonical generator stages all 32 cells and atomically publishes only after generation and rubric projection succeed."
  falsification_test: "If the workflow cannot restrict a canonical run to a full-SHA ref, verify the pinned executable, generate exactly once, run catalog.check, and upload the bounded output without entering required CI, this route does not address the root cause."
  fix_rationale: "A new exact-SHA advisory CI route moves the sole successful writer to the platform where the approved renderer is available, leaves reviewer-owned evidence read-only, and exports only the generated bundle for separately verified local publication."
  blind_spots: "This workspace cannot execute the Linux-only renderer or observe the remote artifact until the route commit is pushed and CI finishes; identity comparison after download remains required."
  candidate_causes:
    - "code: Rendro.Catalog.generate/1 correctly requires an executable before staging, so no local fallback exists."
    - "config: ci.yml has no canonical Phase 130 full-SHA route after reviewer evidence becomes current."
    - "environment: the approved pinned pdfium-cli is Linux-only and unavailable on the macOS checkout."
    - "data: the retained candidate manifest has all 32 ordered identities; Task 1 changed only reviewer evidence, not renderer input."
  and_gate: "yes — the reported failure requires both the macOS/Linux executable mismatch and the missing CI handoff; either a compatible local binary or a canonical CI route would remove the block."
tdd_checkpoint:

## Evidence

- timestamp: 2026-08-20
  checked: Phase-0 semantic and keyword knowledge-base recall
  found: MemPalace CLI is unavailable; the only knowledge-base entry concerns source-PDF manifest ordering and has no two-token match with the missing macOS PDFium executable route.
  implication: no prior resolution is a candidate hypothesis; use deterministic reproduction and CI-route inspection.
- timestamp: 2026-08-20
  checked: repository status, recent history, and catalog/PDFium references
  found: Task 1 evidence is committed as 047d04c; the active debug session is the sole untracked file. CI already contains pinned PDFium installation and both candidate and canonical catalog invocations.
  implication: the symptom is deterministic and environment/platform-specific; preserve the committed evidence and inspect the exact existing CI contracts before proposing a route.
- timestamp: 2026-08-20
  checked: `Rendro.Catalog.generate/1`, its failure test, and the Phase 130 CI job
  found: `generate/1` invokes `with_pdfium/2` before cleanup or staging; its focused test confirms a missing executable leaves committed artifacts and reviewer evidence untouched. The advisory Linux job verifies the pinned PDFium SHA but only accepts `gsd/phase-130-catalog-review-<40-hex-SHA>` and invokes `mix rendro.catalog.candidate`.
  implication: the local failure is fail-closed by design, and the missing post-review canonical CI route—not generator behavior—is the controllable defect.
- timestamp: 2026-08-20
  checked: current candidate artifact and generator publication implementation
  found: `tmp/phase130-candidate/candidate-manifest.json` has 32 ordered cells with the approved v0.11.0 renderer pin; the canonical writer produces all cells in staging and swaps both catalog directory and manifest with rollback on error.
  implication: CI can safely produce one bounded bundle, then a separate artifact-download identity comparison can gate its one local publication boundary.
- timestamp: 2026-08-20
  checked: focused CI route contract after adding the canonical route
  found: `mix test test/guardrails/required_checks_contract_test.exs --max-failures 1` passed (20 tests). The route only accepts `gsd/phase-130-catalog-canonical-<40-hex-SHA>`, compares it to `GITHUB_SHA`, verifies the installed executable digest against `priv/pdfium_pin.json`, invokes `mix rendro.catalog.gen` once, runs `mix rendro.catalog.check`, and uploads a 32-cell asset bundle plus payload checksums. The required `test` job contains none of the canonical-route markers.
  implication: the configuration fix is locally verified; the remaining unobservable evidence is the Linux CI run and the downloaded artifact's complete equality with the retained candidate manifest.
- timestamp: 2026-08-20
  checked: candidate/canonical-focused test suite before any canonical writer was launched
  found: `mix test test/rendro/catalog_test.exs test/docs_contract/catalog_quality_contract_test.exs test/docs_contract/rubric_manifest_contract_test.exs --max-failures 1` fails in the pre-existing catalog artifact guard because the committed canonical manifest hashes and projection intentionally remain stale until Plan 130-10's one successful canonical generation.
  implication: this is not caused by the CI-route patch and is the expected pre-publication state; it cannot be used as an adjacent green signal until the exact-SHA CI artifact is verified and atomically published.
- timestamp: 2026-08-21
  checked: exact-SHA route commit and remote ref
  found: "Committed the isolated CI route as 002d42adfec74a1f2fd2ba824d1623fb33c92891 and pushed gsd/phase-130-catalog-canonical-002d42adfec74a1f2fd2ba824d1623fb33c92891; git ls-remote resolves that ref to the identical full SHA. GitHub Actions run 32434769523 is executing the advisory-checks job and has already passed its pinned PDFium installation step."
  implication: the remote invocation satisfies the route's full-SHA branch/ref precondition; only the actual one-writer generation result and downloaded-artifact identity comparison remain.
- timestamp: 2026-08-21
  checked: full workflow status while advisory-checks remains in progress
  found: "The required test matrix failed before tests: OTP 25 cannot install Elixir 1.19.0, and the primary format step reports pre-existing formatting drift in test/docs_contract/rubric_manifest_contract_test.exs. Neither changed CI file nor the new guardrail test appears in the formatter diff."
  implication: these whole-workflow failures are independent of the graph-disconnected advisory canonical route and do not invalidate its pending artifact evidence; do not alter unrelated source during this debug session.
- timestamp: 2026-08-21
  checked: GitHub Actions run 32434769523 advisory canonical boundary and downloaded `phase-130-catalog-canonical` artifact
  found: "The pinned PDFium install, exactly one canonical generation, catalog check, 32-cell staging assertion, and artifact upload each passed. The artifact binds run 32434769523 and SHA 002d42adfec74a1f2fd2ba824d1623fb33c92891 to PDFium v0.11.0 / b1e7f3dd8d6c77e0eb8e67c6a33de4efa5de9f38d87263c151acb88994ae160a. All 33 artifact checksum entries verify; candidate and canonical manifests have the same 32 literal IDs/order, renderer pin, PNG/source-PDF hashes, safe paths, dimensions, and page counts, with zero mismatches."
  implication: the sole Linux canonical writer produced the exact reviewed candidate identity set; local publication may proceed without rerendering.
- timestamp: 2026-08-21
  checked: downloaded canonical quality projections against current Task 1 rubric evidence
  found: "The artifact has 12 scored cells and zero projection mismatches against all 32 current catalog dispositions. The current rubric SHA-256 and Task 1 commit 047d04c version are both ba175666b656ad17a5967043f50945595c3a50bc9a6669517ba42a8e3eb660d6."
  implication: the artifact derives display-only quality state from the approved unchanged human evidence and does not author or alter that evidence.
- timestamp: 2026-08-21
  checked: local publication transaction
  found: "Copied the already verified CI artifact only to assets/rendro/catalog.staging and assets/rendro/catalog.json.staging, confirmed 32 staged PNGs and the pinned manifest, then performed one backup-and-rollback publication transaction to assets/rendro/catalog and assets/rendro/catalog.json. No renderer was invoked locally; pre-publication copies are retained only as exact rollback backups pending read-only verification."
  implication: the sole successful canonical writer remains the SHA-bound Linux CI invocation; the local step only materialized its verified output atomically.
- timestamp: 2026-08-21
  checked: published artifact and focused acceptance checks
  found: "The published catalog directory and manifest are byte-identical to the downloaded CI artifact. `mix rendro.catalog.check` returned Catalog VERIFIED; `mix test test/rendro/catalog_test.exs test/docs_contract/catalog_quality_contract_test.exs test/docs_contract/rubric_manifest_contract_test.exs --max-failures 1` passed 95 tests with 0 failures; rubric_scores.json and SIGN-OFF.md remain unchanged. Rollback copies were moved to /tmp/rendro-canonical-prepublication.ho9WfP rather than deleted."
  implication: the original missing-executable symptom is resolved through one verified canonical CI generation and controlled publication; end-to-end user workflow confirmation is the final required signal.
- timestamp: 2026-08-21
  checked: intended-workflow human verification
  found: "The 32 canonical identities exactly match the already human-reviewed candidate. The user accepted byte-for-byte candidate equality plus the completed review as intended-workflow verification; no further visual judgment is needed."
  implication: end-to-end verification is complete. Retain the handoff evidence: GitHub Actions run 32434769523, SHA 002d42adfec74a1f2fd2ba824d1623fb33c92891, 33 verified checksum entries, the 32-cell zero-mismatch comparison, and 95 focused tests passing.

## Eliminated

## Resolution

root_cause: "The approved renderer is Linux-only on a macOS canonical checkout, and ci.yml lacks an exact-SHA post-review canonical-generation route even though its advisory Linux job already installs and hash-verifies that renderer."
fix: "Added an isolated `gsd/phase-130-catalog-canonical-<full-SHA>` advisory CI route that uses the existing SHA-verified Linux PDFium executable, generates once, checks the catalog, and uploads only the canonical asset bundle with an inventory; added a contract test for that boundary. Published only the downloaded verified bundle via the existing canonical staging/rollback boundary."
verification: |
  target_test: {result: pass, suite: "mix test test/guardrails/required_checks_contract_test.exs --max-failures 1"}
  mutation_check: {result: skipped, reason_if_skipped: "No Stryker configuration exists for this Elixir/GitHub Actions contract test."}
  no_op_deletion: {result: pass, deletion_justified_by_rca: false, evidence: "Diff adds a tightly guarded CI path and a regression contract; no behavior is deleted or bypassed."}
  adjacent_tests: {result: pass, suites_run: ["mix rendro.catalog.check", "mix test test/rendro/catalog_test.exs test/docs_contract/catalog_quality_contract_test.exs test/docs_contract/rubric_manifest_contract_test.exs --max-failures 1"], evidence: "Catalog VERIFIED; 95 tests, 0 failures."}
  revert_and_reconfirm: {result: pass, evidence: "The direct remote counterfactual ran at run 32434769523: full-SHA guard, pinned executable digest, one canonical generation, read-only check, 32-cell staging, and artifact upload all passed before local materialization."}
  artifact_identity: {result: pass, evidence: "All 33 artifact checksums passed; candidate/canonical 32-cell identity comparison had zero mismatches; locally published files are byte-identical to the verified artifact."}
  intended_workflow_human_verify: {result: pass, evidence: "User confirmed the 32 canonical identities exactly match the reviewed candidate and accepted byte-for-byte equality plus completed human review as sufficient; no new visual review required."}
  guardrail_verdict: accepted
files_changed: [.github/workflows/ci.yml, test/guardrails/required_checks_contract_test.exs, assets/rendro/catalog.json, assets/rendro/catalog]
